#!/bin/bash

# Script to download .for files from the IRI-2016 model
# Usage: ./download_iri_files.sh

# Create a directory for the downloaded files
DOWNLOAD_DIR="src/fortran/iri2016"
mkdir -p "$DOWNLOAD_DIR"
echo "Created directory: $DOWNLOAD_DIR"

# Base URL of the IRI-2016 model
BASE_URL="https://irimodel.org/IRI-2016"

# Function to download files
download_file() {
    local filename="$1"
    local url="${BASE_URL}/${filename}"
    
    echo "Downloading: $filename"
    if wget -q --show-progress -P "$DOWNLOAD_DIR" "$url"; then
        echo "Successfully downloaded: $filename"
    else
        echo "Failed to download: $filename"
    fi
}

# List of .for files that exist in the repository
FOR_FILES=(
    "irifun.for"
    "irisub.for"
    "iritec.for"
    "iridreg.for"
    "igrf.for"
    "cira.for"
    "iriflip.for"
    "irirtam.for"
    "iritest.for"
)

# Download each file
echo "Starting downloads from $BASE_URL"
for file in "${FOR_FILES[@]}"; do
    download_file "$file"
done

# Attempt to download iri.for (the main file) separately
download_file "iri.for"

echo "Download process completed. Files are stored in $DOWNLOAD_DIR"

# Count how many files were successfully downloaded
COUNT=$(ls -1 "$DOWNLOAD_DIR"/*.for 2>/dev/null | wc -l)
echo "Downloaded $COUNT .for files."