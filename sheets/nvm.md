# NVM - Node Version Manager

Install specific Node version | nvm install <version>
Install latest LTS version | nvm install --lts
Use specific Node version | nvm use <version>
Use latest LTS version | nvm use --lts
Set default Node version | nvm alias default <version>
List installed Node versions | nvm ls
List available Node versions | nvm ls-remote
Show current Node version | nvm current
Uninstall Node version | nvm uninstall <version>
Run command with specific version | nvm exec <version> <command>
Show path to Node installation | nvm which <version>
Install Node from .nvmrc file | nvm install
Use Node version from .nvmrc file | nvm use
Reinstall packages from previous version | nvm reinstall-packages <version>
Set version for current shell only | nvm run <version> <command>
Display NVM version | nvm --version
Clear NVM cache | nvm cache clear
Show installed versions with aliases | nvm ls --no-colors
Migrate packages to new version | nvm install <new> --reinstall-packages-from=<old>
Init NVM| source /usr/share/nvm/init-nvm.sh
