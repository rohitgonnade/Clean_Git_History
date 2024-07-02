# Remove large blob files from Git history to reduce history size
This automated script aims to minimize Git history by removing references to untracked dangling files. Additionally, it addresses AWS CodeCommit issues by repacking Git history into smaller chunks with a maximum size of 1GB.

It uses tool [git_filter_repo](https://github.com/newren/git-filter-repo/tree/main) to rewrite history.

## Motivation

- It's typical for Git repositories to contain large files, whether unintentionally or intentionally. However, even after untracking a file or directory, the Git repository's history isn't reduced. This script aims to automate the process of reducing Git history by permanently removing such files from the repository's history.
- AWS CodeCommit has 2 GB size limit for single file. Occasionly Git creates single .pack file which can go beyond the size limit. 

## Usage
.\Powershell\CleanGitHistory.ps1 -RepoPath <path> -PathsToRemove <paths> [-Aggressive <yes|no>] [-Help]

 This script assumes user knows path of the blob which were removed from Git. 
 -PathsToRemove : relative paths to the RepoPath

## Working
- The script accepts the path to the Git repository and an array of paths to remove as parameters.
- Get the script's directory and constructs the virtual environment path relative to the script's location.
- Check if Python is installed and creates a virtual environment if it doesn't already exist.
- Activates the virtual environment.
- Installs git-filter-repo if it's not already installed.
- Checks if the specified path is a valid Git repository by ensuring the presence of the .git directory.
- Navigates to the specified repository path.
- Constructs a single command to pass all paths to git filter-repo at once.
- Runs git filter-repo to remove all specified paths from the Git history.- 
- Deactivates the virtual environment.
- Expires reflogs and cleans up references.
- Removes any backup references and logs.
- Performs garbage collection.
- Repacks with max-size = 1Gb