# Github Cli  - Comamnds for GitHub

Trocar de conta | gh auth switch 
Trocar de conta | gh auth switch -u your-username 
Login account | gh auth login 
makes HTTPS git operation (clone, push, pull ) | gh auth setup-git 
straight forward cloning from repo | gh repo list --limit 100 | fzf | awk '{print $1}' | xargs -I {} gh repo clone {}
creating a repo in github | gh repo create <name of the repo> --private --source=. --remote=origin --push
