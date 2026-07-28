# rsync - File Sync & Transfer

## Local
Copy directory locally | rsync -av <source>/ <dest>/
Sync (delete removed files) | rsync -av --delete <source>/ <dest>/
Dry run (preview changes) | rsync -av --dry-run <source>/ <dest>/
Copy single file | rsync -v <file> <dest>/

## Remote (push)
Push directory to server | rsync -avz <source>/ <user>@<host>:<dest>/
Push mascot assets to server | rsync -avz ~/Desktop/props_pe_na_rota_mascot/ <user>@<server_ip>:/path/to/incoming/
Push and delete removed files | rsync -avz --delete <source>/ <user>@<host>:<dest>/
Push with SSH key | rsync -avz -e "ssh -i <key.pem>" <source>/ <user>@<host>:<dest>/
Push on non-default SSH port | rsync -avz -e "ssh -p <port>" <source>/ <user>@<host>:<dest>/

## Remote (pull)
Pull directory from server | rsync -avz <user>@<host>:<source>/ <dest>/
Pull with SSH key | rsync -avz -e "ssh -i <key.pem>" <user>@<host>:<source>/ <dest>/

## Options
Compress during transfer | rsync -avz <source>/ <dest>/
Show progress per file | rsync -av --progress <source>/ <dest>/
Limit bandwidth (KB/s) | rsync -avz --bwlimit=<1000> <source>/ <dest>/
Exclude pattern | rsync -av --exclude='<*.log>' <source>/ <dest>/
Exclude multiple patterns | rsync -av --exclude={'<*.log>','<tmp/>'} <source>/ <dest>/
Resume partial transfers | rsync -av --partial <source>/ <dest>/
Checksum instead of timestamp | rsync -avc <source>/ <dest>/

~ Trailing slash on source matters: with slash = contents only, no slash = directory itself
~ -a = archive mode (recursive + preserve permissions/timestamps/symlinks)
~ -v = verbose, -z = compress, -n = dry run
