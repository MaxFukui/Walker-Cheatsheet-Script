# LazyVim - Neovim distro
Grep project root | <Space>/ or <Space>sg
Grep current working directory | <Space>sG
Grep word under cursor | <Space>sw
Grep exact text (escape regex chars) | rclpy\.shutdown\(\)
Grep loosely (skip special chars like parens) | rclpy.shutdown
Move through picker results | Ctrl-j / Ctrl-k, Enter to open
Send all matches to quickfix | Ctrl-q
Next / previous quickfix item | :cnext / :cprev (or ]q / [q)
Built-in grep, no plugins | :vimgrep /rclpy\.shutdown()/ **/*.py
Open quickfix list | :copen
List files matching pattern (shell) | rg -l 'rclpy\.shutdown\(\)'
