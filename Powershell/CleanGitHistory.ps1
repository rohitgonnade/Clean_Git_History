# .\CleanGitHistory.ps1 -RepoPath "C:\Path\To\Your\Repo" -PathsToRemove "Resources/3D Models", "Another/Path", "Yet/Another/Path"

param (
    [string]$RepoPath,
    [string[]]$PathsToRemove
)

# Function to display a message and exit the script
function ExitWithMessage($message) {
    Write-Host $message
    exit
}

# Get the script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$venvPath = Join-Path $scriptDir "venv"
$activateScript = Join-Path $venvPath "Scripts/Activate.ps1"

# Check if Python is installed
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    ExitWithMessage "Python is not installed. Please install Python and try again."
}

# Check if virtual environment exists
if (-not (Test-Path $activateScript)) {
    Write-Host "Creating virtual environment..."
    python -m venv $venvPath
}

# Activate the virtual environment
Write-Host "Activating virtual environment..."
& $activateScript

# Install git-filter-repo if it's not already installed
if (-not (Get-Command git-filter-repo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing git-filter-repo..."
    pip install git-filter-repo
}
# Check if the specified path is a valid git repository
if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    ExitWithMessage "The specified path is not a valid git repository. Please provide the correct path to your git repository."
}

# Navigate to the repository path
Set-Location $RepoPath

# Build the paths argument for git-filter-repo 
$pathsArgument = ($PathsToRemove | ForEach-Object { "--path '$_'" }) -join " "

# Run git-filter-repo to remove the specified paths
$command = "python -m git_filter_repo $pathsArgument --invert-paths --force"
Write-Host "Running git-filter-repo with the command: $command"
Invoke-Expression $command


# Deactivate the virtual environment
Write-Host "Deactivating virtual environment..."
deactivate


# Expire reflogs and clean up references
Write-Host "Expiring reflogs and cleaning up references..."
git reflog expire --expire=now --all
git for-each-ref --format="%(refname)" refs/original/ | ForEach-Object { git update-ref -d $_ }

# Remove remote logs
Write-Host "Removing remote logs..."
Remove-Item -Recurse -Force .git/logs/

# Perform garbage collection
Write-Host "Performing garbage collection..."
git gc --prune=now

# Verify object counts
Write-Host "Verifying object counts..."
git count-objects -v

Write-Host "Git history has been successfully cleaned and repacked."

Set-Location $scriptDir