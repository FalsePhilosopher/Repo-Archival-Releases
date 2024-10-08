# Repo-Archival-Rleases
If you have a large repo and a lot of large submodules then doing a `git clone --recursive` job will download the sometimes hefty baggage of the .git folder with it. For example this repo is 167kb in size, if you strip the .git folder and zstd compress it the release archive is 6kb. That is a 96.41% reduction in size and some people might not have the bandwidth or data allowance to download 7GB worth of a repo and all it's submodules, so it's in their interest to download a 2GB archive instead. So for those end users it would be ideal if there was an already .git folder stripped and compressed archive they could download with a BLAKE3 or SHA256 sums included for the archive and it's contents along with a download script they can filelessly execute to download the archive against a SHA256 sum, extract the archive and do a BLAKE3 or SHA256 check sum on the contents.

The release script will update your repo, then copy it to a release folder, rm the .git folder, run a BLAKE3 and SHA256 check, compress the folder, do a SHA256 sum on the folder and update the checksum values in the notes.md, dl.sh, and dl.ps1 scripts. From there your users can use fileless script execution method of downloading, extracting, and hash checking the archive.

Github has a 2GB file limit on release files, so the single file release currently included works and I am working on a larger then 2GB multi auto release/multi download version.

The windows download script is untested, I tested the SHA256.ps1 script on powershell for linux. So both SHA256.ps1 and dl.ps1 need to be tested on a win machine before they can be pushed to production.
