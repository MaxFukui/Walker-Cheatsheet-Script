# venv - Python Virtual Environments

~ Built into Python 3.3+, no extra install needed (python3 -m venv)

## Create & Activate
Create a virtual environment | python3 -m venv <env_name>
Create with specific python | python3.<X> -m venv <env_name>
Activate (bash/zsh) | source <env_name>/bin/activate
Activate (fish) | source <env_name>/bin/activate.fish
Activate (Windows cmd) | <env_name>\Scripts\activate.bat
Activate (Windows PowerShell) | <env_name>\Scripts\Activate.ps1
Deactivate | deactivate

## Inspect
Show python path (confirm venv active) | which python
Show python version | python --version
Show pip path | which pip

## Packages
Install package | pip install <package_name>
Install from requirements | pip install -r requirements.txt
Save installed packages | pip freeze > requirements.txt
List installed packages | pip list

## Remove
Delete environment | rm -rf <env_name>

## Common Examples
Create env without pip | python3 -m venv <env_name> --without-pip
Create env without pip seed packages | python3 -m venv <env_name> --without-scm-ignore-files
Recreate env from scratch | python3 -m venv <env_name> --clear
Copy instead of symlink (Windows-friendly) | python3 -m venv <env_name> --copies
