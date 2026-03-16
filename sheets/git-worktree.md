# Git Worktree - Multiple branches simultaneously

~ A worktree is a second checkout of the same repo in a new folder on a different branch

## Setup
Create worktree + new branch | git worktree add <folder> -b <branch>
Create worktree from existing branch | git worktree add <folder> <branch>
List all worktrees | git worktree list
Remove a worktree | git worktree remove <folder>
Prune stale worktree refs | git worktree prune

## Daily Use
~ Work inside a worktree folder like any normal git repo
Switch branch inside worktree | git checkout <branch>
Create branch inside worktree | git checkout -b <branch>
~ You CANNOT checkout a branch already active in another worktree

## Workflow
Check current worktree status | git worktree list --porcelain
Merge worktree branch to main | git merge <branch>
Delete branch after merge | git branch -d <branch>
Remove worktree folder | git worktree remove <folder>

## Inspect
Show worktree details | git worktree list --porcelain
Check branch of a worktree | git -C <folder> branch --show-current
