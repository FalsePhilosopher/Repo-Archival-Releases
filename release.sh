#!/bin/bash
# https://github.com/FalsePhilosopher/Repo-Archival-Releases
# This script automates the process of creating monthly releases for a github repo.
# Dependencies: b3sum (https://github.com/BLAKE3-team/BLAKE3) and zstd.
# This setup requires SHA256.ps1, dl.ps1, dl.sh, notes.md and your repo all in the same parent folder aka the WORKING_DIR.
# Make sure to set the remote repo for gh in your repo with 
#gh repo set-default username/repo

# --- Cron Job Setup ---
# 1. Open your crontab editor by running crontab -e
# 2. Add the following line to the crontab to schedule the script to run automatically.
# Monthly (at midnight on the first day of every month):
#0 0 1 * * /path/to/this/script.sh
# Weekly (at midnight every Sunday):
#0 0 * * 0 /path/to/this/script.sh
# Daily (at midnight every day):
#0 0 * * * /path/to/this/script.sh


#!/bin/bash

SIGN="Y"    # Set SIGN to "Y" or "N" for GPG signing
REPO='sample-name'
WORKING_DIR="/sample/path/to/parent/folder/"

RELEASE_VERSION=$(date +"%d-%m-%y")   #DD-MM-YY
RELEASE_TAG="$RELEASE_VERSION"
DISPLAY_LABEL="Release $RELEASE_VERSION"

BASE_FOLDER="$WORKING_DIR/Releases"
RELEASE_FOLDER="$BASE_FOLDER/$RELEASE_VERSION"
SHDL="$RELEASE_FOLDER/dl.sh"
PS1DL="$RELEASE_FOLDER/dl.ps1"
NOTES="$RELEASE_FOLDER/notes.md"
ARCHIVE="$RELEASE_FOLDER/$REPO.tar.zst"
SIG="$ARCHIVE.sig"
LOG="$RELEASE_FOLDER/$RELEASE_VERSION.log"

copy() {
    echo "Copying files to $RELEASE_FOLDER" | tee -a "$LOG"
    cd "$WORKING_DIR" || { echo "Failed to return to working directory." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    cp -r "$REPO" "$RELEASE_FOLDER" && sleep 10 && echo "Copying $REPO complete." | tee -a "$LOG" || { echo "Failed to copy $REPO folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    cp SHA256.ps1 "$RELEASE_FOLDER/$REPO" && echo "SHA256.ps1 copying complete." | tee -a "$LOG" || { echo "Failed to copy SHA256.ps1 to $REPO folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    cp dl.sh "$RELEASE_FOLDER" && echo "dl.sh copying complete." | tee -a "$LOG" || { echo "Failed to copy dl.sh." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    cp dl.ps1 "$RELEASE_FOLDER" && echo "dl.ps1 copying complete." | tee -a "$LOG" || { echo "Failed to copy dl.ps1." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    cp notes.md "$RELEASE_FOLDER" && echo "notes.md copying complete." | tee -a "$LOG" || { echo "Failed to copy notes.md." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
}

trim() {
    cd "$RELEASE_FOLDER/$REPO" || { echo "Failed to navigate to $REPO release repo folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    echo "Trimming .git folder" | tee -a "$LOG"
    rm -rf .git && sleep 10 && echo "Release folder git history removed." | tee -a "$LOG" || { echo "Failed to remove release repo folder git history." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
}

check() {
    echo "Calculating BLAKE3 checksums..." | tee -a "$LOG"
    find -type f \( -not -name "B3.SUM" \) -exec b3sum '{}' \; >> B3.SUM && echo "BLAKE3 checksum complete." | tee -a "$LOG" || { echo "BLAKE3 checksum error." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    echo "Calculating SHA256 checksums..." | tee -a "$LOG"
    find -type f \( -not -name "SHA256" \) -exec sha256sum '{}' \; >> SHA256 && sleep 10 && echo "SHA256 checksum complete." | tee -a "$LOG" || { echo "SHA256 checksum error." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    # trimming of the SHA256 checksum is necessary to make it *nix/powershell compatible
    sed 's/[.][/]//1' -i SHA256 && echo "SHA256 checksum trimming complete." | tee -a "$LOG" || { echo "SHA256 checksum trimming error." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
}

sign() {
if [[ "$SIGN" == "y" || "$SIGN" == "Y" ]]; then
    echo "Signing the release"
    cd "$RELEASE_FOLDER" || { echo "Failed to navigate to release folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
    gpg --sign "$ARCHIVE" && echo "$ARCHIVE signed successfully." | tee -a "$LOG" || { echo "Failed to sign $ARCHIVE." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
else
    echo "Skipping GPG signing." | tee -a "$LOG"
fi
}

gh_release () {
echo "Creating Github release" | tee -a "$LOG"
cd "$WORKING_DIR/$REPO" || { echo "Failed to navigate back to $REPO repo folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }

if [[ "$SIGN" == "y" || "$SIGN_RELEASE" == "Y" ]]; then
    echo "Pushing signed release"
    gh release create "$RELEASE_TAG" --title "$RELEASE_TAG" --notes-file "$NOTES" --latest "$ARCHIVE" "$SIG" "$SHDL" "$PS1DL" && echo "GitHub release created successfully." | tee -a "$LOG" || { echo "Failed to create signed GitHub release." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
else
    gh release create "$RELEASE_TAG" --title "$RELEASE_TAG" --notes-file "$NOTES" --latest "$ARCHIVE" "$SHDL" "$PS1DL" && echo "GitHub release created successfully." | tee -a "$LOG" || { echo "Failed to create GitHub release." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
fi
}


mkdirs() {
if [ ! -d "$BASE_FOLDER" ]; then
    mkdir "$BASE_FOLDER"
fi
mkdir -p "$RELEASE_FOLDER"
echo "Script started at $(date)" > "$LOG"
}

mkdirs || { echo "Failed to create folders. Is your WORKING_DIR setup properly? Do you have R/W permissions?"; sleep 20; exit 1; }
if ! command -v zstd &> /dev/null
then
    echo "zstd could not be found, please install it." && sleep 20
    exit 1
fi
if ! command -v gh &> /dev/null
then
    echo "gh could not be found, please install it." && sleep 20
    exit 1
fi

cd "$WORKING_DIR/$REPO" || { echo "Failed to navigate to $REPO repo folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "Pulling repo updates" | tee -a "$LOG"
gh repo sync && echo "Pulling updates complete." | tee -a "$LOG" || { echo "Failed to update $REPO repo." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }

copy
cd "$RELEASE_FOLDER/$REPO" || { echo "Failed to navigate to $REPO release folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "Trimming .git folder" | tee -a "$LOG"
rm -rf .git && sleep 10 && echo "Git history removed." | tee -a "$LOG" || { echo "Failed to remove git history." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }

check
cd "$RELEASE_FOLDER" || { echo "Failed to navigate to release folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "Compressing $REPO release folder." | tee -a "$LOG"
tar --use-compress-program "zstd -T0 -19" -cvf "$REPO.tar.zst" "$REPO" && sleep 30 && echo "$REPO release folder compression complete." || { echo "Failed to compress $REPO release folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
sign

echo "Generating SHA256 checksum for $REPO archive..." | tee -a "$LOG"
sha256sum "$RELEASE_FOLDER/$REPO.tar.zst" > "$RELEASE_FOLDER/SHA256" && sleep 15 && echo "Generating SHA256 complete." | tee -a "$LOG" || { echo "Failed to generate SHA256 checksum." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "Removing $REPO release folder." | tee -a "$LOG"
rm -rf "$RELEASE_FOLDER/$REPO" && sleep 15 && echo "Removing $REPO release folder complete." | tee -a "$LOG" || { echo "Failed to remove Flipper release folder." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }

echo "Updating SHA256 values in files" | tee -a "$LOG"
TMP_HASH_FILE=$(mktemp /tmp/hash.XXXXXX) || { echo "Failed to create temporary hash file." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
cat "$RELEASE_FOLDER/SHA256" | sed 's/ .*//' > "$TMP_HASH_FILE" || { echo "Failed to extract hash from SHA256 file." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
LATEST_HASH=$(<"$TMP_HASH_FILE") || { echo "Failed to retrieve latest SHA256 hash." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "Expected hash value" | tee -a "$LOG"
cat "$RELEASE_FOLDER/SHA256" | tee -a "$LOG"
sed -i "4s/.*/SHA256='$LATEST_HASH'/" "$SHDL" || { echo "Failed to update SHA256 in dl.sh." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "dl.sh SHA256 value." | tee -a "$LOG"
sed -n '4p' $SHDL | tee -a "$LOG"
sed -i "2s/.*/\$SHA256 = \"$LATEST_HASH\"/" "$PS1DL" || { echo "Failed to update SHA256 in dl.ps1." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "dl.ps1 SHA256 value" | tee -a "$LOG"
sed -n '2p' $PS1DL | tee -a "$LOG"
sed -i "2s/.*/SHA256=$LATEST_HASH/" "$NOTES" || { echo "Failed to update SHA256 in notes.md." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "notes.md SHA256 value" | tee -a "$LOG"
sed -n '2p' $NOTES | tee -a "$LOG"
rm "$TMP_HASH_FILE" || { echo "Failed to remove temporary hash file." | tee -a "$LOG"; echo "Script errored at $(date)" | tee -a "$LOG"; exit 1; }
echo "SHA256 values updated." | tee -a "$LOG" && sleep 5

gh_release
echo "Script finished sucessfully at $(date)" | tee -a "$LOG"
