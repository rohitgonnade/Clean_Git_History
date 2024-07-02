# .\CleanGitHistory.ps1 -RepoPath "C:\Path\To\Your\Repo" -PathsToRemove "Resources/3D Models", "Another/Path", "Yet/Another/Path" -Aggressive yes

param (
    [string]$RepoPath,
    [string[]]$PathsToRemove,
    [string]$Aggressive = "no",
    [switch]$Help
)

# Function to display help message
function Show-Help {
    Write-Host "Usage: .\CleanGitHistory.ps1 -RepoPath <path> -PathsToRemove <paths> [-Aggressive <yes|no>] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -RepoPath        The path to the Git repository."
    Write-Host "  -PathsToRemove   An array of paths to be removed from the Git history."
    Write-Host "  -Aggressive      (Optional) Set to 'yes' to perform aggressive garbage collection. Default is 'no'. Aggressive can be very time consuming depending upon the sie of Git repo."
    Write-Host "  -Help            Display this help message."
    Write-Host ""
    Write-Host "Description:"
    Write-Host "  This automated script aims to minimize Git history by removing references to untracked dangling files."
    Write-Host "  Additionally, it addresses AWS CodeCommit issues by repacking Git history into smaller chunks with a maximum size of 1GB."
}

# Display help message if -Hselp is specified
if ($Help) {
    Show-Help
    exit
}

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
if ($Aggressive -eq "yes") {
    git gc --prune=now --aggressive
} else {
    git gc --prune=now
}

# Verify object counts
Write-Host "Verifying object counts..."
git count-objects -v


Write-Host "Git history has been successfully cleaned and repacked."

Write-Host "Now repacking with max-size = 1Gb"
git repack -a -d --depth=250 --window=250 --max-pack-size=1g

Set-Location $scriptDir