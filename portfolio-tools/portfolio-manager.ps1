$ErrorActionPreference = "Stop"

$ToolDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ToolDir
$IndexPath = Join-Path $Root "index.html"
$TaDir = Join-Path $Root "technical-art"
$AssetRoot = Join-Path $Root "assets\technical-art"

$PostsJson = Join-Path $TaDir "posts.json"
$PostsJs = Join-Path $TaDir "posts.js"
$PostsCss = Join-Path $TaDir "posts.css"
$PostCss = Join-Path $TaDir "post.css"

$StyleTag = '<link rel="stylesheet" href="technical-art/posts.css?v=2" />'
$ScriptTag = '<script src="technical-art/posts.js?v=2" defer></script>'

function Pause-Portfolio {
    Write-Host ""
    [void](Read-Host "Press Enter to continue")
}

function Read-YesNo {
    param(
        [string]$Prompt,
        [bool]$Default = $false
    )

    $suffix = if ($Default) { " [Y/n]" } else { " [y/N]" }
    $answer = (Read-Host ($Prompt + $suffix)).Trim().ToLowerInvariant()

    if ([string]::IsNullOrWhiteSpace($answer)) {
        return $Default
    }

    return @("y", "yes") -contains $answer
}

function Read-Value {
    param(
        [string]$Prompt,
        [string]$Default = "",
        [bool]$Required = $false
    )

    while ($true) {
        $label = $Prompt
        if (-not [string]::IsNullOrWhiteSpace($Default)) {
            $label += " [$Default]"
        }

        $value = (Read-Host $label).Trim()

        if ([string]::IsNullOrWhiteSpace($value) -and -not [string]::IsNullOrWhiteSpace($Default)) {
            return $Default
        }

        if (-not [string]::IsNullOrWhiteSpace($value) -or -not $Required) {
            return $value
        }

        Write-Host "This field is required." -ForegroundColor Yellow
    }
}

function Read-Multiline {
    param(
        [string]$Title,
        [bool]$Required = $false
    )

    while ($true) {
        Write-Host ""
        Write-Host $Title -ForegroundColor Cyan
        Write-Host "Type your text. Enter a single . on its own line when finished."

        $lines = New-Object System.Collections.Generic.List[string]

        while ($true) {
            $line = Read-Host ">"
            if ($line.Trim() -eq ".") {
                break
            }
            $lines.Add($line)
        }

        $text = ($lines -join "`n").Trim()

        if (-not $Required -or -not [string]::IsNullOrWhiteSpace($text)) {
            return $text
        }

        Write-Host "This section cannot be empty." -ForegroundColor Yellow
    }
}

function ConvertTo-Slug {
    param([string]$Text)

    $slug = $Text.Trim().ToLowerInvariant()
    $slug = [regex]::Replace($slug, "[^a-z0-9]+", "-")
    $slug = $slug.Trim("-")

    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "post"
    }

    return $slug
}

function Escape-Html {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Convert-TextToParagraphs {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $groups = [regex]::Split($Text.Trim(), "(\r?\n){2,}")
    $result = New-Object System.Collections.Generic.List[string]

    foreach ($group in $groups) {
        if ([string]::IsNullOrWhiteSpace($group)) {
            continue
        }

        $clean = (($group -split "\r?\n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join " "
        if ($clean) {
            $result.Add("<p>$(Escape-Html $clean)</p>")
        }
    }

    return $result -join "`n"
}

function Convert-TextToSteps {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $items = New-Object System.Collections.Generic.List[string]

    foreach ($line in ($Text -split "\r?\n")) {
        $clean = $line.Trim()

        if ([string]::IsNullOrWhiteSpace($clean)) {
            continue
        }

        $clean = [regex]::Replace($clean, "^\s*(?:[-*]|\d+[.)])\s*", "")
        $items.Add("<li>$(Escape-Html $clean)</li>")
    }

    if ($items.Count -eq 0) {
        return ""
    }

    return "<ol>`n$($items -join "`n")`n</ol>"
}

function Invoke-Git {
    param([string[]]$Arguments)

    $output = & git @Arguments 2>&1
    $code = $LASTEXITCODE

    return @{
        Code = $code
        Text = ($output | Out-String).Trim()
    }
}

function Test-GitSafety {
    Write-Host ""
    Write-Host "--- Repository safety check ---" -ForegroundColor Cyan

    $gitDir = Join-Path $Root ".git"

    if (-not (Test-Path $gitDir)) {
        Write-Host "No .git folder found. Git sync checks are disabled." -ForegroundColor Yellow
        return Read-YesNo "Continue anyway?" $true
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git is not available in PATH." -ForegroundColor Yellow
        return Read-YesNo "Continue without Git checks?" $true
    }

    Push-Location $Root
    try {
        $branch = Invoke-Git @("branch", "--show-current")
        if ($branch.Code -eq 0) {
            Write-Host ("Current branch: " + $branch.Text)
        }

        $status = Invoke-Git @("status", "--porcelain")
        if ($status.Code -ne 0) {
            Write-Host "Could not read Git status." -ForegroundColor Red
            return $false
        }

        if (-not [string]::IsNullOrWhiteSpace($status.Text)) {
            Write-Host ""
            Write-Host "You have uncommitted changes:" -ForegroundColor Yellow
            Write-Host $status.Text
            Write-Host ""
            Write-Host "Nothing will be pulled, reset, or discarded."
            Write-Host "The manager will work on exactly these current local files."
            return Read-YesNo "Continue with the dirty working tree?" $false
        }

        $fetch = Invoke-Git @("fetch", "origin", "--quiet")
        if ($fetch.Code -ne 0) {
            Write-Host ("Could not fetch origin: " + $fetch.Text) -ForegroundColor Yellow
            return Read-YesNo "Continue with the current local branch?" $true
        }

        $upstream = Invoke-Git @("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
        if ($upstream.Code -ne 0 -or [string]::IsNullOrWhiteSpace($upstream.Text)) {
            Write-Host "No upstream branch configured. Using local files."
            return $true
        }

        $counts = Invoke-Git @("rev-list", "--left-right", "--count", ("HEAD..." + $upstream.Text))
        if ($counts.Code -eq 0 -and -not [string]::IsNullOrWhiteSpace($counts.Text)) {
            $parts = $counts.Text -split "\s+"

            if ($parts.Count -ge 2) {
                $ahead = [int]$parts[0]
                $behind = [int]$parts[1]

                Write-Host ("Compared with " + $upstream.Text + ": $ahead ahead, $behind behind.")

                if ($behind -gt 0) {
                    if (-not (Read-YesNo "Pull latest changes with git pull --ff-only?" $true)) {
                        Write-Host "Cancelled so a post is not generated against an outdated branch." -ForegroundColor Yellow
                        return $false
                    }

                    $pull = Invoke-Git @("pull", "--ff-only")
                    if ($pull.Code -ne 0) {
                        Write-Host ("Pull failed: " + $pull.Text) -ForegroundColor Red
                        return $false
                    }

                    Write-Host $pull.Text
                }
            }
        }

        return $true
    }
    finally {
        Pop-Location
    }
}

function Backup-Index {
    if (-not (Test-Path $IndexPath)) {
        return
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path $ToolDir ("backups\" + $stamp)
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item $IndexPath (Join-Path $backupDir "index.html") -Force
}

function Write-RuntimeFiles {
    New-Item -ItemType Directory -Path $TaDir -Force | Out-Null
    New-Item -ItemType Directory -Path $AssetRoot -Force | Out-Null

    Set-Content -Path $PostsJs -Value $script:PostsJsText -Encoding UTF8
    Set-Content -Path $PostsCss -Value $script:PostsCssText -Encoding UTF8
    Set-Content -Path $PostCss -Value $script:PostCssText -Encoding UTF8

    if (-not (Test-Path $PostsJson)) {
        Set-Content -Path $PostsJson -Value "[]" -Encoding UTF8
    }
}

function Install-HomepageIntegration {
    if (-not (Test-Path $IndexPath)) {
        throw "Could not find index.html. Keep portfolio-tools inside the repository root."
    }

    Write-RuntimeFiles

    $source = Get-Content $IndexPath -Raw -Encoding UTF8
    $original = $source

    # Replace an older Technical Art stylesheet/script reference instead of
    # adding duplicates when the cache-busting version changes.
    $stylePattern = '<link[^>]*technical-art/posts\.css[^>]*>'
    $scriptPattern = '<script[^>]*technical-art/posts\.js[^>]*>\s*</script>'

    if ([regex]::IsMatch($source, $stylePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $source = [regex]::Replace(
            $source,
            $stylePattern,
            $StyleTag,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }
    else {
        $headIndex = $source.ToLowerInvariant().IndexOf("</head>")

        if ($headIndex -lt 0) {
            throw "index.html does not contain </head>."
        }

        $source = $source.Insert($headIndex, "  $StyleTag`r`n")
    }

    if ([regex]::IsMatch($source, $scriptPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $source = [regex]::Replace(
            $source,
            $scriptPattern,
            $ScriptTag,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }
    else {
        $bodyIndex = $source.ToLowerInvariant().LastIndexOf("</body>")

        if ($bodyIndex -lt 0) {
            throw "index.html does not contain </body>."
        }

        $source = $source.Insert($bodyIndex, "  $ScriptTag`r`n")
    }

    if ($source -ne $original) {
        Backup-Index
        Set-Content -Path $IndexPath -Value $source -Encoding UTF8
        Write-Host "Installed/repaired Technical Art post integration." -ForegroundColor Green
    }
    else {
        Write-Host "Technical Art post integration is already installed." -ForegroundColor Green
    }
}

function Get-Posts {
    if (-not (Test-Path $PostsJson)) {
        return @()
    }

    try {
        $raw = Get-Content $PostsJson -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return @()
        }

        $parsed = $raw | ConvertFrom-Json

        if ($null -eq $parsed) {
            return @()
        }

        if ($parsed -is [System.Array]) {
            return @($parsed)
        }

        return @($parsed)
    }
    catch {
        return @()
    }
}

function Save-Posts {
    param([object[]]$Posts)

    New-Item -ItemType Directory -Path $TaDir -Force | Out-Null

    $items = @($Posts)

    if ($items.Count -eq 0) {
        Set-Content -Path $PostsJson -Value "[]" -Encoding UTF8
        return
    }

    # ConvertTo-Json emits a bare object when there is only one item.
    # Build the outer array explicitly so posts.json always has the same shape.
    $serialized = @(
        $items | ForEach-Object {
            $_ | ConvertTo-Json -Depth 10 -Compress
        }
    )

    $json = "[`r`n  " + ($serialized -join ",`r`n  ") + "`r`n]"
    Set-Content -Path $PostsJson -Value $json -Encoding UTF8
}

function Copy-PortfolioFile {
    param(
        [string]$SourceText,
        [string]$DestinationBase,
        [string[]]$AllowedExtensions
    )

    $sourceText = $SourceText.Trim().Trim('"')

    if ([string]::IsNullOrWhiteSpace($sourceText)) {
        return ""
    }

    $source = $sourceText

    if (-not [System.IO.Path]::IsPathRooted($source)) {
        $source = Join-Path (Get-Location) $source
    }

    $source = [System.IO.Path]::GetFullPath($source)

    if (-not (Test-Path $source -PathType Leaf)) {
        Write-Host ("File not found; skipped: " + $source) -ForegroundColor Yellow
        return ""
    }

    $extension = [System.IO.Path]::GetExtension($source).ToLowerInvariant()

    if ($AllowedExtensions -notcontains $extension) {
        Write-Host ("Unsupported file type; skipped: " + $extension) -ForegroundColor Yellow
        return ""
    }

    $destination = $DestinationBase + $extension
    $destinationDir = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null

    Copy-Item $source $destination -Force

    $relative = $destination.Substring($Root.Length).TrimStart("\")
    Write-Host ("Copied: " + $relative) -ForegroundColor Green

    return [System.IO.Path]::GetFileName($destination)
}

function Get-YouTubeId {
    param([string]$Value)

    $value = $Value.Trim()

    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    if ($value -match "^[A-Za-z0-9_-]{6,}$") {
        return $value
    }

    try {
        $uri = [Uri]$value
        $host = $uri.Host.ToLowerInvariant()

        if ($host.StartsWith("www.")) {
            $host = $host.Substring(4)
        }

        if ($host -eq "youtu.be") {
            return $uri.AbsolutePath.Trim("/").Split("/")[0]
        }

        if ($host.Contains("youtube.com")) {
            if ($uri.AbsolutePath -eq "/watch") {
                $query = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                return $query["v"]
            }

            $parts = $uri.AbsolutePath.Trim("/").Split("/")
            if ($parts.Count -ge 2 -and @("embed", "shorts", "live") -contains $parts[0]) {
                return $parts[1]
            }
        }
    }
    catch {
    }

    return $null
}

function Get-AnalyticsSnippet {
    if (-not (Test-Path $IndexPath)) {
        return ""
    }

    $source = Get-Content $IndexPath -Raw -Encoding UTF8
    $match = [regex]::Match($source, "G-[A-Z0-9]{6,}")

    if (-not $match.Success) {
        return ""
    }

    $id = $match.Value

    return @"
  <!-- Google tag (gtag.js) -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=$id"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', '$id');
  </script>
"@
}

function New-OptionalSection {
    param(
        [string]$Label,
        [string]$Body
    )

    if ([string]::IsNullOrWhiteSpace($Body)) {
        return ""
    }

    return @"
    <section class="ta-article-block">
      <p class="ta-kicker">$(Escape-Html $Label)</p>
      <div class="ta-prose">$Body</div>
    </section>
"@
}

function New-TechnicalArtPost {
    if (-not (Test-GitSafety)) {
        Write-Host "No changes were made." -ForegroundColor Yellow
        return
    }

    Install-HomepageIntegration

    $posts = @(Get-Posts)
    $title = Read-Value "Post title" "" $true
    $suggestedSlug = ConvertTo-Slug $title
    $slug = ConvertTo-Slug (Read-Value "URL slug" $suggestedSlug $true)

    foreach ($post in $posts) {
        if ($post.slug -eq $slug) {
            Write-Host ("A post named '" + $slug + "' already exists.") -ForegroundColor Red
            return
        }
    }

    $postDir = Join-Path $TaDir $slug

    if (Test-Path $postDir) {
        Write-Host ("Folder already exists: technical-art\" + $slug) -ForegroundColor Red
        return
    }

    $category = Read-Value "Type/category" "Unity Tool"
    $excerpt = Read-Multiline "Short homepage-card description" $true
    $tagsRaw = Read-Value "Tags, comma separated" "Unity, Technical Art"
    $tags = @($tagsRaw.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $date = Read-Value "Date" (Get-Date -Format "yyyy-MM-dd")

    $postAssetDir = Join-Path $AssetRoot $slug
    New-Item -ItemType Directory -Path $postAssetDir -Force | Out-Null

    Write-Host ""
    Write-Host "Demo type" -ForegroundColor Cyan
    Write-Host "1. YouTube"
    Write-Host "2. Local video"
    Write-Host "3. No demo yet"

    $demoChoice = Read-Value "Choose" "1"
    $demoType = "none"
    $demoValue = ""

    if ($demoChoice -eq "1") {
        $video = Read-Value "YouTube URL or video ID"
        $videoId = Get-YouTubeId $video

        if (-not [string]::IsNullOrWhiteSpace($videoId)) {
            $demoType = "youtube"
            $demoValue = $videoId
        }
        elseif (-not [string]::IsNullOrWhiteSpace($video)) {
            Write-Host "Could not recognize that YouTube link. Demo left empty." -ForegroundColor Yellow
        }
    }
    elseif ($demoChoice -eq "2") {
        $path = Read-Value "Local .mp4/.webm/.ogg path"
        $copied = Copy-PortfolioFile $path (Join-Path $postAssetDir "demo") @(".mp4", ".webm", ".ogg")

        if (-not [string]::IsNullOrWhiteSpace($copied)) {
            $demoType = "local"
            $demoValue = $copied
        }
    }

    $coverPath = Read-Value "Cover image path (optional)"
    $coverFile = Copy-PortfolioFile $coverPath (Join-Path $postAssetDir "cover") @(".png", ".jpg", ".jpeg", ".webp", ".avif")

    $overview = Read-Multiline "Overview / what did you create?" $true
    $problem = Read-Multiline "Problem / why did you make it?"
    $process = Read-Multiline "How did you create it? Technical approach."
    $usage = Read-Multiline "Usage steps (one step per line)"
    $details = Read-Multiline "Technical details / APIs / implementation notes"
    $result = Read-Multiline "Result / learnings"
    $sourceUrl = Read-Value "GitHub/source link (optional)"

    if (-not [string]::IsNullOrWhiteSpace($sourceUrl) -and
        $sourceUrl -notmatch "^https?://") {
        Write-Host "Source link must start with http:// or https://. Ignoring this value." -ForegroundColor Yellow
        $sourceUrl = ""
    }

    if (Read-YesNo "Copy gallery screenshots now?" $false) {
        Write-Host "Enter image paths one at a time. Leave blank when finished."

        $shot = 1

        while ($true) {
            $path = (Read-Host ("shot-" + $shot)).Trim().Trim('"')

            if ([string]::IsNullOrWhiteSpace($path)) {
                break
            }

            $copied = Copy-PortfolioFile $path (Join-Path $postAssetDir ("shot-" + $shot)) @(".png", ".jpg", ".jpeg", ".webp", ".avif")

            if (-not [string]::IsNullOrWhiteSpace($copied)) {
                $shot++
            }
        }
    }

    $published = Read-YesNo "Publish the homepage card now?" $true

    if ($demoType -eq "youtube") {
        $demoHtml = @"
      <div class="ta-demo-frame">
        <iframe
          src="https://www.youtube-nocookie.com/embed/$(Escape-Html $demoValue)"
          title="$(Escape-Html $title) demo"
          loading="lazy"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          referrerpolicy="strict-origin-when-cross-origin"
          allowfullscreen></iframe>
      </div>
"@
    }
    elseif ($demoType -eq "local") {
        $demoHtml = @"
      <div class="ta-demo-frame">
        <video controls preload="metadata" playsinline>
          <source src="../../assets/technical-art/$(Escape-Html $slug)/$(Escape-Html $demoValue)">
        </video>
      </div>
"@
    }
    else {
        $demoHtml = @"
      <div class="ta-demo-placeholder">
        <strong>Demo coming soon</strong>
        <span>Add a demo later using the Portfolio Manager or place a local video in the media folder.</span>
      </div>
"@
    }

    $sourceButton = ""

    if (-not [string]::IsNullOrWhiteSpace($sourceUrl)) {
        $sourceButton = '<a class="ta-button ta-button-secondary" href="' +
            (Escape-Html $sourceUrl) +
            '" target="_blank" rel="noreferrer">View source</a>'
    }

    $tagHtml = (($tags | ForEach-Object { "<span>$(Escape-Html $_)</span>" }) -join "")

    $overviewSection = New-OptionalSection "Overview" (Convert-TextToParagraphs $overview)
    $problemSection = New-OptionalSection "The problem" (Convert-TextToParagraphs $problem)
    $processSection = New-OptionalSection "How I built it" (Convert-TextToParagraphs $process)
    $usageSection = New-OptionalSection "Usage" (Convert-TextToSteps $usage)
    $detailsSection = New-OptionalSection "Technical notes" (Convert-TextToParagraphs $details)
    $resultSection = New-OptionalSection "Result and learnings" (Convert-TextToParagraphs $result)

    $page = $script:PostTemplate
    $replacements = @{
        "{{ANALYTICS}}" = Get-AnalyticsSnippet
        "{{TITLE}}" = Escape-Html $title
        "{{EXCERPT}}" = Escape-Html ($excerpt -replace "\r?\n", " ")
        "{{CATEGORY}}" = Escape-Html $category
        "{{DATE}}" = Escape-Html $date
        "{{TAGS}}" = $tagHtml
        "{{SLUG}}" = Escape-Html $slug
        "{{DEMO}}" = $demoHtml
        "{{OVERVIEW}}" = $overviewSection
        "{{PROBLEM}}" = $problemSection
        "{{PROCESS}}" = $processSection
        "{{USAGE}}" = $usageSection
        "{{DETAILS}}" = $detailsSection
        "{{RESULT}}" = $resultSection
        "{{SOURCE_BUTTON}}" = $sourceButton
    }

    foreach ($key in $replacements.Keys) {
        $page = $page.Replace($key, [string]$replacements[$key])
    }

    New-Item -ItemType Directory -Path $postDir -Force | Out-Null
    Set-Content -Path (Join-Path $postDir "index.html") -Value $page -Encoding UTF8

    $mediaReadme = @"
Media for $title

Recognized files:
  cover.png / cover.jpg / cover.webp
  demo.mp4 / demo.webm
  shot-1.png
  shot-2.png
  ...
  shot-20.png

The gallery probes webp, png, jpg, jpeg, and avif automatically.
"@

    Set-Content -Path (Join-Path $postAssetDir "README.txt") -Value $mediaReadme -Encoding UTF8

    $newPost = [PSCustomObject]@{
        title = $title
        slug = $slug
        category = $category
        excerpt = ($excerpt -replace "\r?\n", " ").Trim()
        tags = $tags
        date = $date
        published = $published
        cover = $coverFile
    }

    $all = @($posts) + @($newPost)
    $all = @($all | Sort-Object date -Descending)
    Save-Posts $all

    Write-Host ""
    Write-Host "Post created successfully." -ForegroundColor Green
    Write-Host ("Page : technical-art\" + $slug + "\index.html")
    Write-Host ("Media: assets\technical-art\" + $slug + "\")
    Write-Host ("Card : " + $(if ($published) { "published" } else { "draft" }))

    Show-GitStatus
}

function Show-Posts {
    $posts = @(Get-Posts)

    if ($posts.Count -eq 0) {
        Write-Host ""
        Write-Host "No Technical Art posts yet."
        return
    }

    Write-Host ""
    Write-Host "Technical Art posts" -ForegroundColor Cyan
    Write-Host ("-" * 70)

    $number = 1

    foreach ($post in $posts) {
        $state = if ($post.published -ne $false) { "PUBLISHED" } else { "DRAFT" }
        Write-Host ("{0,2}. [{1,-9}] {2} -> /technical-art/{3}/" -f $number, $state, $post.title, $post.slug)
        $number++
    }
}

function Toggle-Post {
    $posts = @(Get-Posts)

    if ($posts.Count -eq 0) {
        Write-Host "No posts found."
        return
    }

    Show-Posts
    $value = Read-Value "Post number"

    try {
        $index = [int]$value - 1

        if ($index -lt 0 -or $index -ge $posts.Count) {
            throw "Invalid"
        }
    }
    catch {
        Write-Host "Invalid selection." -ForegroundColor Yellow
        return
    }

    $posts[$index].published = -not ($posts[$index].published -ne $false)
    Save-Posts $posts

    $state = if ($posts[$index].published) { "published" } else { "hidden from homepage" }
    Write-Host ($posts[$index].title + ": " + $state) -ForegroundColor Green
}

function Remove-Post {
    $posts = @(Get-Posts)

    if ($posts.Count -eq 0) {
        Write-Host "No posts found."
        return
    }

    Show-Posts
    $value = Read-Value "Post number to remove"

    try {
        $index = [int]$value - 1

        if ($index -lt 0 -or $index -ge $posts.Count) {
            throw "Invalid"
        }
    }
    catch {
        Write-Host "Invalid selection." -ForegroundColor Yellow
        return
    }

    $post = $posts[$index]

    if (-not (Read-YesNo ("Remove '" + $post.title + "' from the post registry?") $false)) {
        return
    }

    $remaining = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt $posts.Count; $i++) {
        if ($i -ne $index) {
            $remaining.Add($posts[$i])
        }
    }

    Save-Posts @($remaining)

    if (Read-YesNo "Also delete its generated page?" $false) {
        Remove-Item (Join-Path $TaDir $post.slug) -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Read-YesNo "Also delete its media folder?" $false) {
        Remove-Item (Join-Path $AssetRoot $post.slug) -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Removed." -ForegroundColor Green
}

function Show-GitStatus {
    $gitDir = Join-Path $Root ".git"

    if (-not (Test-Path $gitDir) -or -not (Get-Command git -ErrorAction SilentlyContinue)) {
        return
    }

    Push-Location $Root
    try {
        $status = Invoke-Git @("status", "--short")

        if ($status.Code -eq 0) {
            Write-Host ""
            Write-Host "Git changes:" -ForegroundColor Cyan

            if ([string]::IsNullOrWhiteSpace($status.Text)) {
                Write-Host "  No changes."
            }
            else {
                Write-Host $status.Text
            }
        }
    }
    finally {
        Pop-Location
    }
}

function Get-ContentType {
    param([string]$Path)

    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        ".html" { return "text/html; charset=utf-8" }
        ".css" { return "text/css; charset=utf-8" }
        ".js" { return "application/javascript; charset=utf-8" }
        ".json" { return "application/json; charset=utf-8" }
        ".svg" { return "image/svg+xml" }
        ".png" { return "image/png" }
        ".jpg" { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".webp" { return "image/webp" }
        ".avif" { return "image/avif" }
        ".gif" { return "image/gif" }
        ".ico" { return "image/x-icon" }
        ".mp4" { return "video/mp4" }
        ".webm" { return "video/webm" }
        ".pdf" { return "application/pdf" }
        default { return "application/octet-stream" }
    }
}

function Start-Preview {
    $port = 8000
    $prefix = "http://localhost:$port/"

    $listener = New-Object System.Net.HttpListener

    try {
        $listener.Prefixes.Add($prefix)
        $listener.Start()
    }
    catch {
        Write-Host ("Could not start preview on " + $prefix) -ForegroundColor Red
        Write-Host $_.Exception.Message
        return
    }

    Write-Host ""
    Write-Host ("Preview running at " + $prefix) -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop."
    Start-Process $prefix

    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $requestPath = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath)
            $relative = $requestPath.TrimStart("/").Replace("/", "\")

            if ([string]::IsNullOrWhiteSpace($relative)) {
                $relative = "index.html"
            }

            $fullPath = [System.IO.Path]::GetFullPath((Join-Path $Root $relative))
            $rootFull = [System.IO.Path]::GetFullPath($Root)

            if (-not $fullPath.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                $context.Response.StatusCode = 403
                $context.Response.Close()
                continue
            }

            if (Test-Path $fullPath -PathType Container) {
                $fullPath = Join-Path $fullPath "index.html"
            }

            if (-not (Test-Path $fullPath -PathType Leaf)) {
                $context.Response.StatusCode = 404
                $bytes = [Text.Encoding]::UTF8.GetBytes("404 - Not Found")
                $context.Response.ContentType = "text/plain; charset=utf-8"
                $context.Response.ContentLength64 = $bytes.Length
                $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
                $context.Response.Close()
                continue
            }

            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $context.Response.StatusCode = 200
            $context.Response.ContentType = Get-ContentType $fullPath
            $context.Response.ContentLength64 = $bytes.Length
            $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            $context.Response.Close()
        }
    }
    finally {
        $listener.Stop()
        $listener.Close()
    }
}

function Show-TechnicalArtMenu {
    while ($true) {
        Clear-Host
        Write-Host "============================================"
        Write-Host " Rishabh Portfolio Manager - Technical Art"
        Write-Host "============================================"
        Write-Host ""
        Write-Host "1. Add post"
        Write-Host "2. List posts"
        Write-Host "3. Publish / hide post"
        Write-Host "4. Remove post"
        Write-Host "5. Install / repair homepage integration"
        Write-Host "0. Back"

        $choice = (Read-Host ">").Trim()

        switch ($choice) {
            "1" {
                try {
                    New-TechnicalArtPost
                }
                catch {
                    Write-Host ""
                    Write-Host ("Error: " + $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Portfolio
            }
            "2" {
                Show-Posts
                Pause-Portfolio
            }
            "3" {
                Toggle-Post
                Pause-Portfolio
            }
            "4" {
                Remove-Post
                Pause-Portfolio
            }
            "5" {
                if (Test-GitSafety) {
                    try {
                        Install-HomepageIntegration
                        Show-GitStatus
                    }
                    catch {
                        Write-Host ("Error: " + $_.Exception.Message) -ForegroundColor Red
                    }
                }
                Pause-Portfolio
            }
            "0" {
                return
            }
        }
    }
}

$script:PostsJsText = @'
(() => {
  const section = document.querySelector('#technical-art');
  if (!section) return;

  const showreels = section.querySelector('.showreel-grid');
  const anchor = showreels || section.querySelector('.section-heading') || section;

  const escapeHtml = (value = '') =>
    String(value).replace(/[&<>"']/g, ch => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    })[ch]);

  const extensions = ['webp', 'png', 'jpg', 'jpeg', 'avif'];

  function resolveCover(img, slug, preferred) {
    const candidates = [];

    if (preferred) {
      candidates.push(`assets/technical-art/${slug}/${preferred}`);
    }

    extensions.forEach(ext => {
      candidates.push(`assets/technical-art/${slug}/cover.${ext}`);
      candidates.push(`assets/technical-art/${slug}/shot-1.${ext}`);
    });

    let cursor = 0;

    const next = () => {
      if (cursor >= candidates.length) {
        img.removeAttribute('src');
        img.closest('.ta-post-card-media')?.classList.add('is-placeholder');
        return;
      }

      img.src = candidates[cursor++];
    };

    img.addEventListener('error', next);
    next();
  }

  fetch('technical-art/posts.json', { cache: 'no-store' })
    .then(response => response.ok ? response.json() : [])
    .then(data => {
      const posts = (
        Array.isArray(data)
          ? data
          : (data && typeof data === 'object' ? [data] : [])
      ).filter(post => post && post.published !== false);

      if (!posts.length) return;

      document.querySelector('.ta-posts-home')?.remove();

      const block = document.createElement('div');
      block.className = 'ta-posts-home reveal';

      block.innerHTML = `
        <div class="ta-posts-heading">
          <div>
            <p class="eyebrow">Tools & Breakdowns</p>
            <h3>Technical Art Posts</h3>
          </div>
          <p>Tools, shaders, workflows, and technical breakdowns.</p>
        </div>
        <div class="ta-post-grid"></div>
      `;

      const grid = block.querySelector('.ta-post-grid');

      posts.forEach(post => {
        const tags = (post.tags || [])
          .slice(0, 4)
          .map(tag => `<span>${escapeHtml(tag)}</span>`)
          .join('');

        const card = document.createElement('a');
        card.className = 'ta-post-card';
        card.href = `technical-art/${encodeURIComponent(post.slug)}/`;

        card.innerHTML = `
          <div class="ta-post-card-media">
            <img alt="" loading="lazy" decoding="async">
            <span class="ta-post-card-type">${escapeHtml(post.category || 'Technical Art')}</span>
          </div>
          <div class="ta-post-card-copy">
            <h4>${escapeHtml(post.title)}</h4>
            <p>${escapeHtml(post.excerpt || '')}</p>
            <div class="ta-post-card-tags">${tags}</div>
            <strong>Read breakdown <span aria-hidden="true">-></span></strong>
          </div>
        `;

        grid.appendChild(card);
        resolveCover(card.querySelector('img'), post.slug, post.cover);
      });

      if (showreels) {
        showreels.insertAdjacentElement('afterend', block);
      } else if (anchor !== section) {
        anchor.insertAdjacentElement('afterend', block);
      } else {
        section.appendChild(block);
      }

      if (window.IntersectionObserver) {
        const observer = new IntersectionObserver(entries => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              entry.target.classList.add('is-visible');
              observer.unobserve(entry.target);
            }
          });
        }, { threshold: 0.08 });

        observer.observe(block);
      } else {
        block.classList.add('is-visible');
      }
    })
    .catch(error => {
      console.warn('Technical Art posts could not be loaded.', error);
    });
})();
'@

$script:PostsCssText = @'
.ta-posts-home {
  margin-top: clamp(2.5rem, 6vw, 5rem);
}
.ta-posts-heading {
  display: flex;
  justify-content: space-between;
  align-items: end;
  gap: 1.5rem;
  margin-bottom: 1.4rem;
}
.ta-posts-heading h3 {
  margin: .2rem 0 0;
  font-family: "Fredoka", "Space Grotesk", sans-serif;
  font-size: clamp(1.65rem, 3vw, 2.35rem);
}
.ta-posts-heading > p {
  max-width: 35rem;
  margin: 0;
  opacity: .72;
}
.ta-post-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: clamp(1rem, 2.5vw, 1.5rem);
}
.ta-post-card {
  display: grid;
  grid-template-columns: minmax(150px, .8fr) 1.2fr;
  min-height: 250px;
  overflow: hidden;
  color: inherit;
  text-decoration: none;
  border: 3px solid var(--ink, #23313a);
  border-radius: 28px;
  background: var(--paper, #fff8e8);
  box-shadow: 7px 8px 0 rgba(35,49,58,.14);
  transition: transform .22s ease, box-shadow .22s ease;
}
.ta-post-card:nth-child(3n+2) {
  background: #e8f5ff;
}
.ta-post-card:nth-child(3n+3) {
  background: #fff0dd;
}
.ta-post-card:hover {
  transform: translateY(-5px) rotate(-.35deg);
  box-shadow: 10px 12px 0 rgba(35,49,58,.16);
}
.ta-post-card-media {
  min-height: 100%;
  position: relative;
  overflow: hidden;
  background:
    radial-gradient(circle at 25% 28%, #ffd25d 0 12%, transparent 13%),
    linear-gradient(145deg, #a6d8ef, #85c98b);
}
.ta-post-card-media img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.ta-post-card-media.is-placeholder img {
  display: none;
}
.ta-post-card-type {
  position: absolute;
  left: .8rem;
  top: .8rem;
  padding: .35rem .7rem;
  border-radius: 999px;
  background: rgba(255,248,232,.94);
  border: 2px solid var(--ink, #23313a);
  font-size: .72rem;
  font-weight: 800;
}
.ta-post-card-copy {
  display: flex;
  flex-direction: column;
  padding: clamp(1rem, 2vw, 1.45rem);
}
.ta-post-card-copy h4 {
  margin: 0;
  font-family: "Fredoka", "Space Grotesk", sans-serif;
  font-size: clamp(1.25rem, 2vw, 1.7rem);
}
.ta-post-card-copy p {
  margin: .65rem 0 1rem;
  line-height: 1.55;
  opacity: .76;
}
.ta-post-card-tags {
  display: flex;
  flex-wrap: wrap;
  gap: .4rem;
  margin-top: auto;
  margin-bottom: .85rem;
}
.ta-post-card-tags span {
  padding: .28rem .58rem;
  border-radius: 999px;
  background: rgba(255,255,255,.6);
  border: 1.5px solid rgba(35,49,58,.22);
  font-size: .72rem;
  font-weight: 700;
}
.ta-post-card-copy strong {
  font-size: .86rem;
}
@media (max-width: 980px) {
  .ta-post-grid {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 620px) {
  .ta-posts-heading {
    align-items: flex-start;
    flex-direction: column;
  }
  .ta-post-card {
    grid-template-columns: 1fr;
  }
  .ta-post-card-media {
    min-height: 190px;
  }
}
'@

$script:PostCssText = @'
body.ta-article-page {
  background: var(--paper, #fff8e8);
  color: var(--ink, #23313a);
}
.ta-article-shell {
  width: min(1100px, calc(100% - 2rem));
  margin: 0 auto;
  padding: clamp(1rem, 3vw, 2rem) 0 5rem;
}
.ta-back {
  display: inline-flex;
  gap: .55rem;
  align-items: center;
  color: inherit;
  text-decoration: none;
  font-weight: 800;
  margin: .5rem 0 2rem;
}
.ta-article-hero {
  position: relative;
  overflow: hidden;
  border: 3px solid var(--ink, #23313a);
  border-radius: 34px;
  background: linear-gradient(135deg, #bde4f5, #fff0ad 55%, #a9d995);
  box-shadow: 9px 11px 0 rgba(35,49,58,.14);
  padding: clamp(2rem, 7vw, 5rem);
}
.ta-article-hero::after {
  content: "";
  position: absolute;
  width: 190px;
  height: 190px;
  border-radius: 50%;
  background: #ffd35c;
  right: -45px;
  top: -55px;
  opacity: .82;
}
.ta-article-hero > * {
  position: relative;
  z-index: 1;
}
.ta-kicker {
  margin: 0 0 .55rem;
  text-transform: uppercase;
  letter-spacing: .12em;
  font-size: .76rem;
  font-weight: 900;
}
.ta-article-hero h1 {
  max-width: 780px;
  margin: 0;
  font-family: "Fredoka", "Space Grotesk", sans-serif;
  font-size: clamp(2.4rem, 7vw, 5.8rem);
  line-height: .98;
}
.ta-article-lede {
  max-width: 700px;
  font-size: clamp(1rem, 2vw, 1.2rem);
  line-height: 1.65;
  margin: 1rem 0 0;
}
.ta-meta-row,
.ta-tag-row,
.ta-hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: .6rem;
  margin-top: 1.15rem;
}
.ta-meta-row span,
.ta-tag-row span {
  border: 2px solid var(--ink, #23313a);
  background: rgba(255,255,255,.58);
  border-radius: 999px;
  padding: .4rem .72rem;
  font-size: .78rem;
  font-weight: 800;
}
.ta-button {
  display: inline-flex;
  align-items: center;
  padding: .72rem 1rem;
  border-radius: 999px;
  border: 2px solid var(--ink, #23313a);
  color: inherit;
  text-decoration: none;
  font-weight: 900;
  background: #fff;
}
.ta-button-secondary {
  background: #cfeecf;
}
.ta-demo-wrap {
  margin-top: clamp(2rem, 5vw, 4rem);
}
.ta-demo-frame,
.ta-demo-placeholder {
  overflow: hidden;
  border: 3px solid var(--ink, #23313a);
  border-radius: 28px;
  background: #172129;
  box-shadow: 7px 8px 0 rgba(35,49,58,.14);
}
.ta-demo-frame {
  aspect-ratio: 16 / 9;
}
.ta-demo-frame iframe,
.ta-demo-frame video {
  width: 100%;
  height: 100%;
  display: block;
  border: 0;
}
.ta-demo-placeholder {
  min-height: 260px;
  display: grid;
  place-content: center;
  text-align: center;
  gap: .45rem;
  color: #fff;
  padding: 2rem;
}
.ta-demo-placeholder strong {
  font-family: "Fredoka", sans-serif;
  font-size: 1.5rem;
}
.ta-content-grid {
  display: grid;
  gap: 1.2rem;
  margin-top: clamp(2rem, 5vw, 4rem);
}
.ta-article-block {
  border: 3px solid var(--ink, #23313a);
  border-radius: 26px;
  background: #fffdf4;
  padding: clamp(1.3rem, 3vw, 2.2rem);
  box-shadow: 6px 7px 0 rgba(35,49,58,.1);
}
.ta-article-block:nth-child(3n+2) {
  background: #eaf7ff;
}
.ta-article-block:nth-child(3n+3) {
  background: #eef8df;
}
.ta-prose {
  max-width: 800px;
  line-height: 1.75;
}
.ta-prose p:first-child {
  margin-top: 0;
}
.ta-prose p:last-child {
  margin-bottom: 0;
}
.ta-prose li {
  margin-bottom: .65rem;
}
.ta-gallery-wrap {
  margin-top: 3rem;
}
.ta-gallery-wrap h2 {
  font-family: "Fredoka", sans-serif;
  font-size: clamp(1.8rem, 4vw, 2.6rem);
}
.ta-gallery {
  display: grid;
  grid-template-columns: repeat(2, minmax(0,1fr));
  gap: 1rem;
}
.ta-gallery figure {
  display: none;
  margin: 0;
  overflow: hidden;
  border: 3px solid var(--ink, #23313a);
  border-radius: 22px;
  background: #dce8e9;
}
.ta-gallery figure.loaded {
  display: block;
}
.ta-gallery img {
  display: block;
  width: 100%;
  height: auto;
}
@media (max-width: 680px) {
  .ta-gallery {
    grid-template-columns: 1fr;
  }
  .ta-article-shell {
    width: min(100% - 1rem, 1100px);
  }
}
'@

$script:PostTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="{{EXCERPT}}" />
  <meta property="og:type" content="article" />
  <meta property="og:title" content="{{TITLE}} | Rishabh Jain" />
  <meta property="og:description" content="{{EXCERPT}}" />
  <meta property="og:url" content="https://artrishabh.github.io/technical-art/{{SLUG}}/" />
  <link rel="canonical" href="https://artrishabh.github.io/technical-art/{{SLUG}}/" />
  <link rel="icon" href="../../assets/favicon.svg" type="image/svg+xml" />
  <title>{{TITLE}} | Rishabh Jain</title>

  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=Nunito+Sans:wght@400;600;700;800&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet" />

  <link rel="stylesheet" href="../../styles.css" />
  <link rel="stylesheet" href="../../portfolio-expansion.css" />
  <link rel="stylesheet" href="../../cozy-theme.css" />
  <link rel="stylesheet" href="../post.css" />
{{ANALYTICS}}
</head>
<body class="ta-article-page">
  <main class="ta-article-shell">
    <a class="ta-back" href="../../#technical-art">
      <span aria-hidden="true">&larr;</span>
      Technical Art
    </a>

    <header class="ta-article-hero">
      <p class="ta-kicker">{{CATEGORY}}</p>
      <h1>{{TITLE}}</h1>
      <p class="ta-article-lede">{{EXCERPT}}</p>
      <div class="ta-meta-row">
        <span>{{DATE}}</span>
      </div>
      <div class="ta-tag-row">{{TAGS}}</div>
      <div class="ta-hero-actions">{{SOURCE_BUTTON}}</div>
    </header>

    <section class="ta-demo-wrap" aria-label="Project demo">
{{DEMO}}
    </section>

    <div class="ta-content-grid">
{{OVERVIEW}}
{{PROBLEM}}
{{PROCESS}}
{{USAGE}}
{{DETAILS}}
{{RESULT}}
    </div>

    <section class="ta-gallery-wrap">
      <p class="ta-kicker">Gallery</p>
      <h2>Project images</h2>
      <div class="ta-gallery" data-gallery-root></div>
    </section>
  </main>

  <script src="../../cozy-theme.js"></script>

  <script>
  (() => {
    const root = document.querySelector('[data-gallery-root]');
    if (!root) return;

    const extensions = ['webp', 'png', 'jpg', 'jpeg', 'avif'];

    for (let i = 1; i <= 20; i++) {
      const figure = document.createElement('figure');
      const img = document.createElement('img');

      img.alt = '{{TITLE}} screenshot ' + i;
      img.loading = 'lazy';

      figure.appendChild(img);
      root.appendChild(figure);

      let extIndex = 0;

      const next = () => {
        if (extIndex >= extensions.length) {
          figure.remove();
          return;
        }

        img.src =
          '../../assets/technical-art/{{SLUG}}/shot-' +
          i +
          '.' +
          extensions[extIndex++];
      };

      img.addEventListener(
        'load',
        () => figure.classList.add('loaded'),
        { once: true }
      );

      img.addEventListener('error', next);
      next();
    }

    setTimeout(() => {
      if (!root.querySelector('.loaded')) {
        root.closest('.ta-gallery-wrap')?.remove();
      }
    }, 1800);
  })();
  </script>
</body>
</html>
'@

if (-not (Test-Path $IndexPath)) {
    Write-Host "Portfolio Manager is in the wrong location." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected:"
    Write-Host "  <your-repo>\portfolio-tools\portfolio-manager.ps1"
    Write-Host ""
    Write-Host ("Could not find: " + $IndexPath)
    Pause-Portfolio
    exit 1
}

while ($true) {
    Clear-Host

    Write-Host "============================================"
    Write-Host " Rishabh Portfolio Manager"
    Write-Host "============================================"
    Write-Host ""
    Write-Host "1. Technical Art"
    Write-Host "2. Preview website locally"
    Write-Host "3. Git status"
    Write-Host "0. Exit"

    $choice = (Read-Host ">").Trim()

    switch ($choice) {
        "1" {
            Show-TechnicalArtMenu
        }
        "2" {
            Start-Preview
            Pause-Portfolio
        }
        "3" {
            Show-GitStatus
            Pause-Portfolio
        }
        "0" {
            exit 0
        }
    }
}
