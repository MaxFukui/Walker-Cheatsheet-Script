# Github Cli 

gh auth switch | Trocar de conta 
gh auth switch -u your-username | Trocar de conta
gh auth login | Login account
gh auth setup-git | makes HTTPS git operation (clone, push, pull)
straight forward cloning from repo | gh repo list --limit 100 | fzf | awk '{print $1}' | xargs -I {} gh repo clone {}
