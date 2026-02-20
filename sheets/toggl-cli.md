# Toggl CLI (Rust) - Time Tracking

Authenticate with API token | toggl auth
Logout and clear credentials | toggl logout
Start interactive time entry | toggl start
Start with description | toggl start "Task description"
Stop current timer | toggl stop
Show current running entry | toggl current
Show running entry (alias) | toggl running
Continue last entry | toggl continue
List time entries | toggl list
List entries with fzf picker | toggl list --fzf
Start with fzf picker | toggl start --fzf
Manage auto-tracking config | toggl config
Change directory before command | toggl -C /path/to/dir <command>
Use custom proxy | toggl --proxy http://proxy:port <command>
Use fzf for all pickers | toggl --fzf <command>
Show help | toggl --help
Show version | toggl --version
Help for specific command | toggl help <subcommand>
