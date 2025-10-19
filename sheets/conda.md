# Conda - Environment & Package Management

Create new environment | conda create -n <env_name> python=<version>
List all environments | conda env list
Activate environment | conda activate <env_name>
Deactivate environment | conda deactivate
Remove environment | conda env remove -n <env_name>
Clone environment | conda create -n <new_env> --clone <old_env>
Export env to file | conda env export > environment.yml
Create env from file | conda create -f environment.yml
List installed packages | conda list
Install package | conda install <package_name>
Install from channel | conda install -c <channel> <package_name>
Install specific version | conda install <package_name>=<version>
Remove package | conda remove <package_name>
Update package | conda update <package_name>
Update all packages | conda update --all
Search for package | conda search <package_name>
Show conda info | conda info
Show conda version | conda --version
View conda configuration | conda config --show
Add channel | conda config --add channels <channel_name>
