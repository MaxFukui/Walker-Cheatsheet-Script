# tmux - Terminal Multiplexer

Create new session | tmux new -s <name>
Attach to session | tmux attach -t <name>
List sessions | tmux ls
Detach from session | Prefix + d
Kill session | tmux kill-session -t <name>
List all sessions (interactive) | Prefix + s
Switch to last session | Prefix + L
Switch to session | Prefix + :switch-client -t <name>
Create new window | Prefix + c
Rename window | Prefix + ,
Rename session | Prefix + :rename-session <name>
Next window | Prefix + n
Previous window | Prefix + p
List windows (interactive) | Prefix + w
Kill current window | Prefix + &
Move window to position | Prefix + :move-window -t <number>
Split pane horizontally | Prefix + "
Split pane vertically | Prefix + %
Navigate to next pane | Prefix + o
Navigate panes with arrows | Prefix + arrow keys
Show pane numbers | Prefix + q
Close current pane | Prefix + x
Kill pane | Prefix + :kill-pane
Resize pane | Prefix + Ctrl + arrow keys
Toggle pane zoom | Prefix + z
Swap panes | Prefix + :swap-pane -U
Break pane to new window | Prefix + !
Join pane from window | Prefix + :join-pane -s <window>.<pane>
Enter copy mode | Prefix + [
Paste buffer | Prefix + ]
List all key bindings | Prefix + ?
Show command prompt | Prefix + :
Reload config file | Prefix + :source-file ~/.tmux.conf
Set pane title | Prefix + :select-pane -T <title>
Respawn pane | Prefix + :respawn-pane
Capture pane to buffer | Prefix + :capture-pane
Save buffer to file | Prefix + :save-buffer <file>
