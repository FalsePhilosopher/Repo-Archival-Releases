#!/bin/bash
USER='Sample'
REPO='Sample'
Link='https://github.com/$USER/$REPO/releases/latest/download/$REPO.tar.zst'
SHA256='4f07311951cb281362c57583e9fff62d67d84a89'
KEY="XXXXXXXXXXXXXXXXX"
KEY_SERVER="keyserver.ubuntu.com"
# https://github.com/FalsePhilosopher/Repo-Archival-Releases

obtainium() {
  # Ask if the user wants to GPG verify the download
  read -p "IF AND ONLY IF the repo admin offers GPG signed releases, do you want to GPG verify the download? (y/n): " VERIFY_DOWNLOAD

  if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not found. Checking aria2c..."
    if ! command -v aria2c &> /dev/null; then
      echo "aria2c could not be found. Please install either GitHub CLI or aria2c." && sleep 20
      exit 1
    else
      echo "Using aria2c to download"
      
      if [[ "$VERIFY_DOWNLOAD" == "y" || "$VERIFY_DOWNLOAD" == "Y" ]]; then
        # Download both the file and its signature for verification
        aria2c --checksum=sha-256=$SHA256 $Link
        aria2c $Link.sig
      else
        # Regular download without signature
        aria2c --checksum=sha-256=$SHA256 $Link
      fi
    fi
  else
    echo "Using GitHub CLI to download"
    
    if [[ "$VERIFY_DOWNLOAD" == "y" || "$VERIFY_DOWNLOAD" == "Y" ]]; then
      # Download both the file and its signature for verification
      gh release download -p '*.tar.zst' -p '*.tar.zst.sig' -R $USER/$REPO
    else
      # Regular download without signature
      gh release download -p '*.tar.zst' -R $USER/$REPO
    fi
  fi
}

GPG() {
# Check if the public key is already in the keyring
if ! gpg --list-keys "$KEY" &>/dev/null; then
    echo "Public key not found in keyring. Importing key from $KEY_SERVER"
    gpg --keyserver "$KEY_SERVER" --recv-keys "$KEY"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to import the public key."
        exit 1
    fi
  else
    echo "Public key already exists in keyring."
fi
# If GPG verification is chosen, verify the signature
if [[ "$VERIFY_DOWNLOAD" == "y" || "$VERIFY_DOWNLOAD" == "Y" ]]; then
    echo "Verifying the download with GPG..."
    gpg --verify "$REPO".tar.zst.sig "$REPO".tar.zst

    if [[ $? -eq 0 ]]; then
      echo "Download verified successfully."
    else
      echo "GPG verification failed."
    fi
  else
    echo "Skipping GPG verification."
fi
}

check() {
  if ! command -v b3sum &> /dev/null; then
    echo "b3sum not found. Checking sha256sum"
    if ! command -v sha256sum &> /dev/null; then
      echo "sha256sum could not be found. Please install b3sum or sha256sum." && sleep 20
      exit 1
    else
      echo "Using sha256sum for verification"
      sha256sum -c SHA256 && echo "All checksums ok" || echo "checksum failure"

    fi
  else
    echo "Using b3sum for verification"
    b3sum -c B3.SUM && echo "All checksums ok" || echo "checksum failure"

  fi
}

if ! command -v zstd &> /dev/null
then
    echo "zstd could not be found, please install it." && sleep 20
    exit 1
fi

cd /tmp/ || { echo "Failed to change directory to /tmp/"; exit 1; }

obtainium
GPG

echo "Extracting $REPO.tar.zst"
if tar --use-compress-program="zstd -d -T0" -xvf "$REPO.tar.zst" --directory "$HOME/Downloads"; then
  echo "Successfully extracted $REPO.tar.zst"
  rm "$REPO.tar.zst"
else
  echo "Failed to extract $REPO.tar.zst" && exit 1
fi

cd "$HOME/Downloads/$REPO/" || { echo "Failed to change to $REPO directory"; exit 1; }

check

echo "All done"
