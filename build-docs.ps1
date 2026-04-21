$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Join-Path $root 'src'
$docsDir = Join-Path $root 'docs'
$assetsDir = Join-Path $docsDir 'assets'

$pages = @(
    @{
        Source = 'join-renew-profile-ux-rules.md'
        Output = 'index.html'
        Aliases = @('join-renew-profile-ux-rules.html')
        NavTitle = 'Profile, Join and Renew'
        Description = 'Main components from the Profile Join and Renew user flow.'
    }
    @{
        Source = 'join-landing-flow-images.md'
        Output = 'join-landing-flow-images.html'
        NavTitle = 'Join Landing'
        Description = 'Screenshot walkthrough for the join landing experience.'
    }
    @{
        Source = 'join-stu-flow-images.md'
        Output = 'join-stu-flow-images.html'
        NavTitle = 'Join STU'
        Description = 'Student join flow screenshots.'
    }
    @{
        Source = 'join-fm-flow-images.md'
        Output = 'join-fm-flow-images.html'
        NavTitle = 'Join FM'
        Description = 'Full member join flow screenshots.'
    }
    @{
        Source = 'join-suppt-flow-images.md'
        Output = 'join-suppt-flow-images.html'
        NavTitle = 'Join SUPPT'
        Description = 'Support member join flow screenshots.'
    }
    @{
        Source = 'join-nm-flow-images.md'
        Output = 'join-nm-flow-images.html'
        NavTitle = 'Join NM'
        Description = 'Non-member join flow screenshots.'
    }
    @{
        Source = 'renew-stu-flow-images.md'
        Output = 'renew-stu-flow-images.html'
        NavTitle = 'Renew STU'
        Description = 'Student renewal flow screenshots.'
    }
    @{
        Source = 'renew-fm-flow-images.md'
        Output = 'renew-fm-flow-images.html'
        NavTitle = 'Renew FM'
        Description = 'Full member renewal flow screenshots.'
    }
    @{
        Source = 'renew-suppt-flow-images.md'
        Output = 'renew-suppt-flow-images.html'
        NavTitle = 'Renew SUPPT'
        Description = 'Support member renewal flow screenshots.'
    }
    @{
        Source = 'renew-ret-flow-images.md'
        Output = 'renew-ret-flow-images.html'
        NavTitle = 'Renew RET'
        Description = 'Retired member renewal flow screenshots.'
    }
    @{
        Source = 'cart.md'
        Output = 'cart.html'
        NavTitle = 'Cart'
        Description = 'Functional walkthrough for the current cart UI.'
    }
)

$linkMap = @{}
foreach ($page in $pages) {
    $linkMap[$page.Source] = $page.Output
}

function Assert-InsideRoot {
    param(
        [string] $BasePath,
        [string] $CandidatePath
    )

    $resolvedBase = [System.IO.Path]::GetFullPath($BasePath)
    $resolvedCandidate = [System.IO.Path]::GetFullPath($CandidatePath)

    if (-not $resolvedCandidate.StartsWith($resolvedBase, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to write outside the workspace: $resolvedCandidate"
    }
}

function Convert-MarkdownLinks {
    param([string] $Html)

    $updated = $Html
    foreach ($sourceName in $linkMap.Keys) {
        $targetName = $linkMap[$sourceName]
        $escapedSource = [Regex]::Escape("./$sourceName")
        $updated = [Regex]::Replace($updated, "href=""$escapedSource""", "href=""./$targetName""")
    }

    $updated = [Regex]::Replace(
        $updated,
        'href="(https?://[^"]+)"',
        'href="$1" target="_blank" rel="noreferrer"'
    )

    return $updated
}

function Get-TitleFromMarkdown {
    param([string] $Markdown)

    $match = [Regex]::Match($Markdown, '(?m)^#\s+(.+?)\s*$')
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return 'Documentation'
}

function New-SiteHtml {
    param(
        [hashtable] $Page,
        [string] $Title,
        [string] $BodyHtml
    )

    $safeTitle = [System.Net.WebUtility]::HtmlEncode($Title)
    $primaryPages = @($pages | Where-Object { $_.Output -in @('index.html', 'cart.html') })
    $screenPages = @($pages | Where-Object { $_.Output -notin @('index.html', 'cart.html') })

    $primaryNavItems = foreach ($navPage in $primaryPages) {
        $isActive = $navPage.Output -eq $Page.Output
        $className = if ($isActive) { 'nav-link active' } else { 'nav-link' }
        $description = [System.Net.WebUtility]::HtmlEncode($navPage.Description)
        $navTitle = [System.Net.WebUtility]::HtmlEncode($navPage.NavTitle)

        @"
<a class="$className" href="./$($navPage.Output)">
  <span class="nav-title">$navTitle</span>
  <span class="nav-description">$description</span>
</a>
"@
    }

    $screenNavItems = foreach ($navPage in $screenPages) {
        $isActive = $navPage.Output -eq $Page.Output
        $className = if ($isActive) { 'nav-link active' } else { 'nav-link' }
        $description = [System.Net.WebUtility]::HtmlEncode($navPage.Description)
        $navTitle = [System.Net.WebUtility]::HtmlEncode($navPage.NavTitle)

        @"
<a class="$className" href="./$($navPage.Output)">
  <span class="nav-title">$navTitle</span>
  <span class="nav-description">$description</span>
</a>
"@
    }

    $primaryNavHtml = ($primaryNavItems -join [Environment]::NewLine)
    $screenNavHtml = ($screenNavItems -join [Environment]::NewLine)

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$safeTitle</title>
  <link rel="stylesheet" href="./assets/site.css" />
</head>
<body>
  <div class="page-shell">
    <aside class="sidebar">
      <a class="brand" href="./index.html">CDHA Web Discovery</a>
      <p class="sidebar-copy">Main components and user flows for the CDHA website.</p>
      <nav class="nav-list" aria-label="Documentation">
$primaryNavHtml
        <div class="nav-divider"></div>
        <section class="nav-section" aria-label="Website Screens">
          <p class="nav-section-title">Website Screens</p>
$screenNavHtml
        </section>
      </nav>
    </aside>
    <main class="content">
      <article class="markdown-body">
$BodyHtml
      </article>
    </main>
  </div>
</body>
</html>
"@
}

$siteCss = @"
:root {
  color-scheme: light;
  --bg: #f4efe7;
  --panel: rgba(255, 252, 247, 0.92);
  --panel-strong: #fffdf8;
  --ink: #1f2933;
  --muted: #5f6c7b;
  --line: #dbcdb8;
  --accent: #9f4d1d;
  --accent-soft: #f3dfcc;
  --shadow: 0 20px 60px rgba(57, 40, 20, 0.12);
}

* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  min-height: 100vh;
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
  color: var(--ink);
  background:
    radial-gradient(circle at top left, rgba(208, 126, 62, 0.22), transparent 28%),
    linear-gradient(180deg, #fbf7f1 0%, var(--bg) 100%);
}

a {
  color: var(--accent);
}

img {
  max-width: 100%;
  height: auto;
  border-radius: 14px;
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
  background: #fff;
}

.page-shell {
  display: grid;
  grid-template-columns: minmax(260px, 320px) minmax(0, 1fr);
  min-height: 100vh;
}

.sidebar {
  position: sticky;
  top: 0;
  align-self: start;
  height: 100vh;
  padding: 32px 24px;
  display: flex;
  flex-direction: column;
  border-right: 1px solid rgba(159, 77, 29, 0.14);
  background: rgba(253, 249, 243, 0.82);
  backdrop-filter: blur(12px);
  overflow: hidden;
}

.brand {
  display: inline-block;
  margin-bottom: 12px;
  font-size: 1.4rem;
  font-weight: 700;
  text-decoration: none;
  color: var(--ink);
}

.sidebar-copy {
  margin: 0 0 24px;
  color: var(--muted);
  line-height: 1.5;
}

.nav-list {
  display: grid;
  gap: 10px;
  min-height: 0;
  overflow-y: auto;
  padding-right: 6px;
}

.nav-divider {
  height: 1px;
  margin: 6px 0 2px;
  background: rgba(159, 77, 29, 0.18);
}

.nav-section {
  display: grid;
  gap: 10px;
}

.nav-section-title {
  margin: 6px 4px 0;
  font-size: 0.8rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--muted);
}

.nav-link {
  display: block;
  padding: 14px 16px;
  text-decoration: none;
  border: 1px solid transparent;
  border-radius: 16px;
  color: var(--ink);
  background: transparent;
  transition: transform 140ms ease, border-color 140ms ease, background 140ms ease;
}

.nav-link:hover,
.nav-link:focus-visible {
  transform: translateY(-1px);
  border-color: rgba(159, 77, 29, 0.24);
  background: rgba(255, 255, 255, 0.72);
}

.nav-link.active {
  border-color: rgba(159, 77, 29, 0.32);
  background: var(--accent-soft);
}

.nav-title {
  display: block;
  font-weight: 700;
  margin-bottom: 4px;
}

.nav-description {
  display: block;
  color: var(--muted);
  font-size: 0.92rem;
  line-height: 1.4;
}

.content {
  padding: 32px;
}

.markdown-body {
  width: min(1100px, 100%);
  margin: 0 auto;
  padding: 40px;
  border: 1px solid rgba(159, 77, 29, 0.12);
  border-radius: 28px;
  background: var(--panel);
  box-shadow: var(--shadow);
}

.markdown-body h1,
.markdown-body h2,
.markdown-body h3 {
  color: #15202b;
}

.markdown-body p,
.markdown-body li,
.markdown-body td,
.markdown-body th {
  line-height: 1.65;
}

.markdown-body table {
  width: 100%;
  border-collapse: collapse;
  margin: 24px 0;
  overflow: hidden;
  border-radius: 16px;
  background: var(--panel-strong);
}

.markdown-body th,
.markdown-body td {
  padding: 12px 14px;
  text-align: left;
  vertical-align: top;
  border: 1px solid var(--line);
}

.markdown-body th {
  background: #f7eee4;
}

.markdown-body code {
  padding: 0.14rem 0.35rem;
  border-radius: 8px;
  background: #f2e5d5;
}

.markdown-body blockquote {
  margin: 24px 0;
  padding: 4px 18px;
  border-left: 4px solid var(--accent);
  background: rgba(243, 223, 204, 0.35);
}

@media (max-width: 960px) {
  .page-shell {
    grid-template-columns: 1fr;
  }

  .sidebar {
    position: static;
    height: auto;
    border-right: 0;
    border-bottom: 1px solid rgba(159, 77, 29, 0.14);
  }

  .content {
    padding: 20px;
  }

  .markdown-body {
    padding: 24px;
    border-radius: 20px;
  }
}
"@

Assert-InsideRoot -BasePath $root -CandidatePath $docsDir
Assert-InsideRoot -BasePath $root -CandidatePath $assetsDir

if (Test-Path $docsDir) {
    Remove-Item -LiteralPath $docsDir -Recurse -Force
}

New-Item -ItemType Directory -Path $docsDir | Out-Null
New-Item -ItemType Directory -Path $assetsDir | Out-Null

[System.IO.File]::WriteAllText((Join-Path $assetsDir 'site.css'), $siteCss, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $docsDir '.nojekyll'), '', [System.Text.Encoding]::UTF8)

Get-ChildItem -Path $sourceDir -File |
    Where-Object { $_.Extension -in '.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp' } |
    ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $docsDir $_.Name)
    }

foreach ($page in $pages) {
    $sourcePath = Join-Path $sourceDir $page.Source
    $markdown = Get-Content -LiteralPath $sourcePath -Raw
    $title = Get-TitleFromMarkdown -Markdown $markdown
    $bodyHtml = (ConvertFrom-Markdown -InputObject $markdown).Html
    $bodyHtml = Convert-MarkdownLinks -Html $bodyHtml
    $html = New-SiteHtml -Page $page -Title $title -BodyHtml $bodyHtml

    $outputPath = Join-Path $docsDir $page.Output
    Assert-InsideRoot -BasePath $root -CandidatePath $outputPath
    [System.IO.File]::WriteAllText($outputPath, $html, [System.Text.Encoding]::UTF8)

    foreach ($alias in ($page.Aliases | Where-Object { $_ })) {
        $aliasPath = Join-Path $docsDir $alias
        Assert-InsideRoot -BasePath $root -CandidatePath $aliasPath
        [System.IO.File]::WriteAllText($aliasPath, $html, [System.Text.Encoding]::UTF8)
    }
}

Write-Host "Generated static site in $docsDir"
