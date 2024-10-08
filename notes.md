# Compressed Snapshot Releases
SHA256=5446978e0fa93f1feb97bfea2b67e502063c3d697ebc4fbbf01af8a212cde2e2
Link=https://github.com/Sample-User/Sample-Repo/releases/latest/download/Sample-Repo.tar.zst


Using `git clone --recursive` to download a large repo and all of it's submodules will download a lot of data with the .git folder and all it's baggage, with the .git folder stripped and the repo compressed with zstd it produces a much smaller footprint giving a significant saving's on bandwidth. Using the script below you can automatically download the release archive, extract it and run a hash check on the contents. 

## Windows users
Use your favorite package manger to instal 7zip/aria2c to your system.  

I would use chocolatey  
https://community.chocolatey.org/packages/aria2  
#install aria2 7zip  
choco install aria2 7zip

Or manually download and add to your to system environmental variables  
in Win10: type "env" in the search bar, click "Edit environmental variables", click on "environmental variables" again, and in the lower window look for "path" and in the window that opens, hit New to add a line and add the location of your aria2/7zip.

Then press the Windows key + r to open the run box and copy paste the link in to it and press enter to start the download script
```
powershell -Exec Bypass $pl = iwr https://github.com/Sample-User/Sample-Repo/releases/latest/download/dl.ps1?dl=1; invoke-expression $pl

```

You can manually download the script and run it instead of using the fileless execution method above.  
You can always just use Jdownloader and throw the SHA256 sum at it then manually extract it with 7zip and run SHA256.ps1 in a powershell window for a hash check.

---

## *nix users
Will either use [b3sum](https://github.com/BLAKE3-team/BLAKE3) or sha256sum for hash checking

There is an auto generated download script included in the release to download with either `gh` or `aria2c`, extract the contents to `$HOME/Downloads/` an hash checked and can be executed with 
```
wget -q -O - https://github.com/Sample-User/Sample-Repo/releases/latest/download/dl.sh | bash
```
If you don't care about the archive checksum an only the content checksums and want to save space can pipeline it to tar with
```
wget -qO- https://github.com/Sample-User/Sample-Repo/releases/latest/download/Sample-Repo.tar.zst | tar -xvf - --use-compress-program=unzstd && cd Sample-Repo && b3sum -c B3.SUM && echo "ALL OK" || echo "Something's fishy"
```
For archival download it to your NAS and pull/extract it with
```
ssh user@HostIP "cat /sample-location/Sample-Repo.tar.zst" | tar -xvf - --use-compress-program=unzstd
```
