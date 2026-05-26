param()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command python -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw "Python 3 is required to build the docs. Install python3 and run build-docs.py or build-docs.sh."
}

$pythonPath = $python.Path
if (-not $pythonPath) {
    $pythonPath = $python.Source
}

& $pythonPath (Join-Path $scriptDir 'build-docs.py')
