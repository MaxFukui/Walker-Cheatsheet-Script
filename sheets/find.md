# find - Search for Files and Directories

## Basics
Find by name (case sensitive) | find <path> -name "<pattern>"
Find by name (case insensitive) | find <path> -iname "<pattern>"
Find in current directory | find . -name "<pattern>"
Find only files | find <path> -type f -name "<pattern>"
Find only directories | find <path> -type d -name "<pattern>"
Find symlinks | find <path> -type l

## Filter by Time
Modified in last N days | find <path> -mtime -<N>
Modified more than N days ago | find <path> -mtime +<N>
Accessed in last N minutes | find <path> -amin -<N>
Modified in last N minutes | find <path> -mmin -<N>
Newer than reference file | find <path> -newer <reference_file>

## Filter by Size
Files larger than size | find <path> -size +<100M>
Files smaller than size | find <path> -size -<1k>
Empty files or directories | find <path> -empty

## Filter by Permissions/Owner
Files with specific permissions | find <path> -perm <755>
Files owned by user | find <path> -user <username>
Files owned by group | find <path> -group <groupname>
Executable files | find <path> -perm -u+x

## Limit Depth
Limit search depth | find <path> -maxdepth <N> -name "<pattern>"
Skip top level (search subdirs only) | find <path> -mindepth 1 -name "<pattern>"

## Actions
Delete matching files | find <path> -name "<pattern>" -delete
Run command on each match | find <path> -name "<pattern>" -exec <command> {} \;
Run command once for all matches | find <path> -name "<pattern>" -exec <command> {} +
Run command with confirmation | find <path> -name "<pattern>" -ok <command> {} \;
Print matches with details | find <path> -name "<pattern>" -ls

## Combine Conditions
~ Use -a (and, default), -o (or), ! / -not (negation), and \( \) for grouping
Match either pattern | find <path> \( -name "<pattern1>" -o -name "<pattern2>" \)
Exclude pattern | find <path> ! -name "<pattern>"
Exclude directory from search | find <path> -path "<dir>" -prune -o -name "<pattern>" -print

## Common Examples
Find and remove .pyc files | find . -name "*.pyc" -delete
Find files modified today | find . -mtime -1 -type f
Find large files over 100MB | find . -type f -size +100M
Find empty directories | find . -type d -empty
Count matching files | find . -name "<pattern>" | wc -l
