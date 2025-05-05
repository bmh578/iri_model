#!/bin/bash

# Script to download files from the IRI-2016 model
# Usage: ./download_iri_files.sh

# Create directories for the downloaded files
FORTRAN_DIR="../src/fortran/iri2016"
BUILD_DIR="../build"
IGRF_DIR="$BUILD_DIR"
MCSAT_DIR="$BUILD_DIR"
INDICES_DIR="$BUILD_DIR"
CCIR_DIR="$BUILD_DIR"
URSI_DIR="$BUILD_DIR"
mkdir -p "$FORTRAN_DIR" "$BUILD_DIR"
echo "Created directories: $FORTRAN_DIR and $BUILD_DIR"

# Base URLs
IRI_URL="https://irimodel.org/IRI-2016"
INDICES_URL="https://irimodel.org/indices"
COMMON_URL="https://irimodel.org/COMMON_FILES"

# Function to download files
download_file() {
    local filename="$1"
    local url="$2"
    local target_dir="$3"
    
    echo "Downloading: $filename"
    if wget -q --show-progress -P "$target_dir" "$url"; then
        echo "Successfully downloaded: $filename"
        return 0
    else
        echo "Failed to download: $filename"
        return 1
    fi
}

# Function to clean Fortran source files
clean_fortran_file() {
    local file="$1"
    echo "Cleaning Fortran file: $file"
    # Remove comments after column 72 that might cause continuation issues
    sed -i 's/\(^.\{72\}\).*/\1/' "$file"
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

# Track if irifun.for was downloaded
IRIFUN_DOWNLOADED=false

# Download Fortran files
echo "Starting downloads of Fortran files from $IRI_URL"
for file in "${FOR_FILES[@]}"; do
    if [ -f "$FORTRAN_DIR/$file" ]; then
        echo "File $file already exists, skipping download"
    else
        if download_file "$file" "${IRI_URL}/${file}" "$FORTRAN_DIR"; then
            clean_fortran_file "$FORTRAN_DIR/$file"
            if [ "$file" = "irifun.for" ]; then
                IRIFUN_DOWNLOADED=true
            fi
        fi
    fi
done

# Find and replace for irifun.for only if it was downloaded
if [ "$IRIFUN_DOWNLOADED" = true ]; then
    echo "Applying necessary modifications to irifun.for for proper compilation"
    sed -i 's|common /igrz/aig,arz,iymst,iymend|common /igrz/iymst,iymend\n       common /agrz/aig,arz|g' "$FORTRAN_DIR/irifun.for"
    sed -i 's|common	/igrz/ionoindx,indrz,iymst,iymend|common /igrz/iymst,iymend\n       common /agrz/ionoindx,indrz|g' "$FORTRAN_DIR/irifun.for"
else
    echo "Note: Using existing irifun.for without modifications."
    echo "If compilation fails, you may need to manually modify common blocks in irifun.for."
fi

# Download dgrf files from 1945 to 2015 in steps of 5 years
echo "Starting downloads of dgrf coefficient files from $IRI_URL"
for year in $(seq 1945 5 2015); do
    filename="dgrf${year}.dat"
    if [ -f "$IGRF_DIR/$filename" ]; then
        echo "File $filename already exists, skipping download"
    else
        download_file "$filename" "${IRI_URL}/${filename}" "$IGRF_DIR"
    fi
done

# Download additional IGRF files
echo "Starting downloads of additional IGRF coefficient files from $IRI_URL"
for filename in "igrf2020.dat" "igrf2020s.dat"; do
    if [ -f "$IGRF_DIR/$filename" ]; then
        echo "File $filename already exists, skipping download"
    else
        download_file "$filename" "${IRI_URL}/${filename}" "$IGRF_DIR"
    fi
done

# Download MCSAT files (month+10)
echo "Starting downloads of MCSAT coefficient files from $IRI_URL"
for month in $(seq 11 22); do
    filename="mcsat${month}.dat"
    if [ -f "$MCSAT_DIR/$filename" ]; then
        echo "File $filename already exists, skipping download"
    else
        download_file "$filename" "${IRI_URL}/${filename}" "$MCSAT_DIR"
    fi
done

# Download index files
echo "Starting downloads of index files from $INDICES_URL"
for filename in "ig_rz.dat" "apf107.dat"; do
    if [ -f "$INDICES_DIR/$filename" ]; then
        echo "File $filename already exists, skipping download"
    else
        download_file "$filename" "${INDICES_URL}/${filename}" "$INDICES_DIR"
    fi
done

# Download CCIR and URSI files (month+10)
echo "Starting downloads of CCIR and URSI coefficient files from $COMMON_URL"
for month in $(seq 11 22); do
    # Download CCIR files
    filename="ccir${month}.asc"
    if [ -f "$CCIR_DIR/$filename" ]; then
        echo "File $filename already exists, skipping download"
    else
        download_file "$filename" "${COMMON_URL}/${filename}" "$CCIR_DIR"
    fi
    
    # Download URSI files
    filename="ursi${month}.asc"
    if [ -f "$URSI_DIR/$filename" ]; then
        echo "File $filename already exists, skipping download"
    else
        download_file "$filename" "${COMMON_URL}/${filename}" "$URSI_DIR"
    fi
done

echo "Download process completed."
echo "Fortran files are stored in $FORTRAN_DIR"
echo "All data files (IGRF, MCSAT, index, CCIR, and URSI files) are stored in $BUILD_DIR"