# Remove large blob files from Git history to reduce history size


## Motivation
It's typical for Git repositories to contain large files, whether unintentionally or intentionally. However, even after untracking a file or directory, the Git repository's history isn't reduced. This script aims to automate the process of reducing Git history by permanently removing such files from the repository's history.

## Usage
.\CleanGitHistory.ps1 -RepoPath "C:\Path\To\Your\Repo" -PathsToRemove "Resources/3D Models", "Another/Path", "Yet/Another/Path"


## Working
- The script accepts the path to the Git repository and an array of paths to remove as parameters.
- Get the script's directory and constructs the virtual environment path relative to the script's location.
- Check if Python is installed and creates a virtual environment if it doesn't already exist.
- Activates the virtual environment.
- Installs git-filter-repo if it's not already installed.
- Checks if the specified path is a valid Git repository by ensuring the presence of the .git directory.
- Navigates to the specified repository path.
- Constructs a single command to pass all paths to git filter-repo at once.
- Runs git filter-repo to remove all specified paths from the Git history.
- Expires reflogs and cleans up references.
- Removes any backup references and logs.
- Performs garbage collection to repack the repository.
- Deactivates the virtual environment.