#!/bin/bash

# Script to download files from the IRI-2016 model
# Usage: ./download_iri_files.sh

# Create directories for the downloaded files
FORTRAN_DIR="src/fortran/iri2016"
IGRF_DIR="data/igrf"
MCSAT_DIR="data/mcsat"
INDICES_DIR="data/indices"
CCIR_DIR="data/ccir"
URSI_DIR="data/ursi"
mkdir -p "$FORTRAN_DIR" "$IGRF_DIR" "$MCSAT_DIR" "$INDICES_DIR" "$CCIR_DIR" "$URSI_DIR"
echo "Created directories: $FORTRAN_DIR, $IGRF_DIR, $MCSAT_DIR, $INDICES_DIR, $CCIR_DIR, and $URSI_DIR"

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

# Download Fortran files
echo "Starting downloads of Fortran files from $IRI_URL"
for file in "${FOR_FILES[@]}"; do
    download_file "$file" "${IRI_URL}/${file}" "$FORTRAN_DIR"
done

# Download dgrf files from 1945 to 2015 in steps of 5 years
echo "Starting downloads of dgrf coefficient files from $IRI_URL"
for year in $(seq 1945 5 2015); do
    filename="dgrf${year}.dat"
    download_file "$filename" "${IRI_URL}/${filename}" "$IGRF_DIR"
done

# Download additional IGRF files
echo "Starting downloads of additional IGRF coefficient files from $IRI_URL"
download_file "igrf2020.dat" "${IRI_URL}/igrf2020.dat" "$IGRF_DIR"
download_file "igrf2020s.dat" "${IRI_URL}/igrf2020s.dat" "$IGRF_DIR"

# Download MCSAT files (month+10)
echo "Starting downloads of MCSAT coefficient files from $IRI_URL"
for month in $(seq 11 22); do
    filename="mcsat${month}.dat"
    download_file "$filename" "${IRI_URL}/${filename}" "$MCSAT_DIR"
done

# Download index files
echo "Starting downloads of index files from $INDICES_URL"
download_file "ig_rz.dat" "${INDICES_URL}/ig_rz.dat" "$INDICES_DIR"
download_file "apf107.dat" "${INDICES_URL}/apf107.dat" "$INDICES_DIR"

# Download CCIR and URSI files (month+10)
echo "Starting downloads of CCIR and URSI coefficient files from $COMMON_URL"
for month in $(seq 11 22); do
    # Download CCIR files
    filename="ccir${month}.asc"
    download_file "$filename" "${COMMON_URL}/${filename}" "$CCIR_DIR"
    
    # Download URSI files
    filename="ursi${month}.asc"
    download_file "$filename" "${COMMON_URL}/${filename}" "$URSI_DIR"
done

echo "Download process completed."
echo "Fortran files are stored in $FORTRAN_DIR"
echo "IGRF coefficient files are stored in $IGRF_DIR"
echo "MCSAT coefficient files are stored in $MCSAT_DIR"
echo "Index files are stored in $INDICES_DIR"
echo "CCIR coefficient files are stored in $CCIR_DIR"
echo "URSI coefficient files are stored in $URSI_DIR"

# Count how many files were successfully downloaded
FORTRAN_COUNT=$(ls -1 "$FORTRAN_DIR"/*.for 2>/dev/null | wc -l)
IGRF_COUNT=$(ls -1 "$IGRF_DIR"/dgrf*.dat 2>/dev/null | wc -l)
IGRF_ADD_COUNT=$(ls -1 "$IGRF_DIR"/igrf2020*.dat 2>/dev/null | wc -l)
MCSAT_COUNT=$(ls -1 "$MCSAT_DIR"/mcsat*.dat 2>/dev/null | wc -l)
INDICES_COUNT=$(ls -1 "$INDICES_DIR"/*.dat 2>/dev/null | wc -l)
CCIR_COUNT=$(ls -1 "$CCIR_DIR"/CCIR*.dat 2>/dev/null | wc -l)
URSI_COUNT=$(ls -1 "$URSI_DIR"/URSI*.dat 2>/dev/null | wc -l)
echo "Downloaded $FORTRAN_COUNT .for files, $IGRF_COUNT dgrf coefficient files, $IGRF_ADD_COUNT additional IGRF coefficient files, $MCSAT_COUNT MCSAT coefficient files, $INDICES_COUNT index files, $CCIR_COUNT CCIR coefficient files, and $URSI_COUNT URSI coefficient files."