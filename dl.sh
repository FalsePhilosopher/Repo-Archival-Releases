#!/bin/bash
USER='FalsePhilosopher'
REPO='Repo-Archival-Rleases'
SHA256='4f07311951cb281362c57583e9fff62d67d84a89'
Link='https://github.com/$USER/$REPO/releases/latest/download/$REPO.tar.zst'
# https://github.com/FalsePhilosopher/Repo-Archival-Rleases
obtainium() {
  if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not found. Checking aria2c..."
    if ! command -v aria2c &> /dev/null; then
      echo "aria2c could not be found. Please install either GitHub CLI or aria2c." && sleep 20
      exit 1
    else
      echo "Using aria2c to download"
      aria2c --checksum=sha-256=$SHA256 $Link
    fi
  else
    echo "Using GitHub CLI to download"
    gh release download -p '$REPO.tar.zst' -R $USER/$REPO
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
      sha256sum -c SHA256
    fi
  else
    echo "Using b3sum for verification"
    b3sum -c B3.SUM
  fi
}

if ! command -v zstd &> /dev/null
then
    echo "zstd could not be found, please install it." && sleep 20
    exit 1
fi

cd /tmp/ || { echo "Failed to change directory to /tmp/"; exit 1; }

obtainium

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
