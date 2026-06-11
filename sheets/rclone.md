# Rclone - Cloud Storage CLI

~ Configure a remote first with: rclone config (interactive setup)
~ Use <remote>: prefix to refer to a configured remote (e.g. gd:)

## Setup
Configure a new remote | rclone config
List configured remotes | rclone listremotes
Show remote info | rclone about <remote>:

## File Operations
Upload file to remote | rclone copy <file> <remote>:<path>
Download file from remote | rclone copy <remote>:<path> <file>
List remote directory | rclone ls <remote>:<path>
List dirs on remote | rclone lsd <remote>:<path>
Delete remote file | rclone delete <remote>:<path>/<file>

## Sync (like git push/pull)
~ copy is safest: never deletes, only adds/updates
Push local to remote (safe) | rclone copy <local_dir> <remote>:<path>
Pull remote to local (safe) | rclone copy <remote>:<path> <local_dir>
Two-way sync (safe) | rclone bisync <local_dir> <remote>:<path>
~ sync deletes files on destination not present in source — know what you're doing
Push and mirror to remote | rclone sync <local_dir> <remote>:<path>
Dry run before syncing | rclone sync <local_dir> <remote>:<path> --dry-run
Sync but keep deleted files | rclone sync <local_dir> <remote>:<path> --backup-dir <remote>:trash

## Check (like git status)
Check local vs remote diff | rclone check <local_dir> <remote>:<path>

## Mount
Mount remote as local dir | rclone mount <remote>:<path> <mountpoint>
Mount in background | rclone mount <remote>:<path> <mountpoint> --daemon
