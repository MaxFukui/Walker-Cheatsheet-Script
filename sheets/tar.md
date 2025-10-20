# tar - Archive Extraction

Extract tar archive | tar -xf <archive.tar>
Extract tar.gz archive | tar -xzf <archive.tar.gz>
Extract tar.bz2 archive | tar -xjf <archive.tar.bz2>
Extract tar.xz archive | tar -xJf <archive.tar.xz>
Extract to specific directory | tar -xf <archive.tar> -C <directory>
Extract specific file from archive | tar -xf <archive.tar> <file>
Extract with verbose output | tar -xvf <archive.tar>
List contents without extracting | tar -tf <archive.tar>
List contents verbosely | tar -tvf <archive.tar>
Extract and keep permissions | tar -xpf <archive.tar>
Extract gz archive to specific dir | tar -xzf <archive.tar.gz> -C <directory>
Extract bz2 archive to specific dir | tar -xjf <archive.tar.bz2> -C <directory>
Extract matching pattern | tar -xf <archive.tar> --wildcards '<pattern>'
Extract excluding pattern | tar -xf <archive.tar> --exclude='<pattern>'
Extract and preserve ownership | tar -xpf <archive.tar> --same-owner
Extract newer files only | tar -xf <archive.tar> --keep-newer-files
Auto-detect compression type | tar -xaf <archive>
Extract with progress indicator | tar -xvf <archive.tar> --checkpoint=1000
