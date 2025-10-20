# Git - Version Control

## Basic Operations
Stage all changes | git add .
Stage specific file | git add <file>
Commit with message | git commit -m "message"
Commit and stage | git commit -am "message"
Push to origin | git push origin main
Pull from origin | git pull origin main
Check status | git status
View commit history | git log --oneline
Clone repository | git clone <url>

## Branching
Create new branch | git checkout -b <branch-name>
Switch branch | git checkout <branch-name>
List all branches | git branch -a
Merge branch | git merge <branch-name>
Delete local branch | git branch -d <branch-name>
Delete remote branch | git push origin --delete <branch-name>
Rename current branch | git branch -M <new-name>

## Undoing Changes
Undo last commit (keep changes) | git reset --soft HEAD~1
Undo last commit (discard changes) | git reset --hard HEAD~1
Unstage file | git reset HEAD <file>
Discard local changes | git checkout -- <file>
Stash changes | git stash
Apply stashed changes | git stash pop
List stashes | git stash list
Drop stash | git stash drop

## Remote & Sync
Add remote | git remote add origin <url>
View remotes | git remote -v
Force push (rewrite history) | git push origin main --force
Fetch without merge | git fetch origin
Sync fork with upstream | git fetch upstream && git merge upstream/main

## Fixing Mistakes
Remove from tracking (keep local) | git rm --cached <file>
Remove all from tracking | git rm -r --cached .
Fix .gitignore after commit | git rm -r --cached . && git add . && git commit -m "Fix gitignore"
Amend last commit | git commit --amend -m "new message"
Revert a commit | git revert <commit-hash>

## Viewing & Comparing
View diff of unstaged changes | git diff
View diff of staged changes | git diff --cached
View file history | git log --follow <file>
Show commit details | git show <commit-hash>
View changes in last commit | git show HEAD

## Configuration
Set username | git config --global user.name "Name"
Set email | git config --global user.email "email"
View all config | git config --list
Set default branch | git config --global init.defaultBranch main
