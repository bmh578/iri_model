#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h> 
#include "iri.h"

int main()
{

    // Initialize IRI model data files (reads apf107.dat and ig_rz.dat)
    readapf107_();
    read_ig_rz_();

    // --- IRI Model Input Parameters ---
    int jmag = 0;         // Use geographic coordinates (0) or geomagnetic (1)
    float lat = 37.8;     // Geographic latitude (degrees)
    float lon = -75.4;    // Geographic longitude (degrees)
    int iy = 2021;        // Year
    int mmdd = 0303;      // Month and day (MMDD format), or negative day-of-year (-DDD)
    float dhour = 11.0 + 25;   // Hour (decimal); add 25 for UTC, 0 for local time
    float heibeg = 600.0; // Start height (km)
    float heiend = 800.0; // End height (km)
    float heistp = 10.0;  // Height step (km)

    // --- Output Array Declarations (Matching Fortran Expectations) ---
    // OUTF(20, 1000) in Fortran -> a[1000][20] in C (column-major mapping)
    // Stores height profiles for 20 parameters.
    float a[1000][20];
    // OARR(100) in Fortran -> b[100] in C
    // Stores various single-value parameters.
    float b[100];

    // Initialize output arrays (good practice)
    // Initialize 'a' (OUTF)
    for (int i = 0; i < 1000; i++) {
        for (int j = 0; j < 20; j++) {
            a[i][j] = 0.0f;
        }
    }
    // Initialize 'b' (OARR) - Set to -1.0 as per iritest.for example
    for (int i = 0; i < 100; i++) {
        b[i] = -1.0f;
    }

    // --- IRI Model Control Switches (JF array) ---
    // Fortran expects JF(1:50). C array jf[51] used (index 0 unused).
    // 1 = true (ON), 0 = false (OFF)
    int jf[51];
    // Initialize all switches to ON (true) by default
    for (int i = 1; i <= 50; i++) {
        jf[i] = 1;
    }

    // Set specific switches to OFF (false) based on standard IRI defaults
    // (See irisub.for comments for details on each switch)
    jf[4] = 0;   // B0, B1 - use standard model
    jf[5] = 0;   // foF2 - use CCIR model
    jf[6] = 0;   // Ni - use RBV-10 & TBT-15 models
    jf[21] = 0;  // Ion drift computed: OFF
    jf[23] = 0;  // Te model: Use standard (not TBT-2012)
    jf[28] = 0;  // Spread-F probability computed: OFF
    jf[29] = 0;  // F1 probability model: Use standard
    jf[30] = 0;  // Topside Te/Ne correlation: Use standard
    jf[33] = 0;  // Auroral boundary model: OFF
    jf[35] = 0;  // foE storm model: OFF
    jf[39] = 0;  // hmF2 model: Use AMTB
    jf[40] = 0;  // hmF2 model: Use Shubin (overridden by jf[39]=1) -> Set OFF
    jf[47] = 0;  // Use Corrected Geomagnetic Coordinates (CGM): OFF

    // --- Call the Fortran IRI Subroutine ---
    // Pass addresses of variables. Note jf[1] is passed for JF(1:50).
    // a[0][0] passes the start of the 2D array for OUTF.
    printf("Calling iri_sub_...\n");
    iri_sub_(&jf[1], &jmag, &lat, &lon, &iy, &mmdd, &dhour,
             &heibeg, &heiend, &heistp, &a[0][0], b);
    printf("iri_sub_ call finished.\n");

    // Calculate number of height steps before the loop
    int num_rows_outf = (int)((heiend - heibeg) / heistp) + 1;

    // Divide column 0 by 1.0e6 to convert from m^-3 to cm^-3
    // for the output array 'a' (OUTF)
    for (int i = 0; i < num_rows_outf; i++) {
        a[i][0] /= 1.0e6; // Convert to cm^-3 
    }

    // Open CSV file for writing
    FILE *outf_file = fopen("output.csv", "w");
    if (outf_file == NULL) {
        fprintf(stderr, "Error opening file for writing.\n");
        return 1;
    }
    // Write header line
    fprintf(outf_file, "Height (km),");
    // Create array of strings for parameter names
    const char *param_names[20] = {
        "Ne (cm^-3)", "NmF2 (cm^-3)", "HmF2 (km)", "TeF2 (K)",
        "NmE (cm^-3)", "HmE (km)", "TeE (K)", "NeE (cm^-3)",
        "B0 (km)", "B1", "B2", "B3", "B4", "B5", "B6",
        "B7", "B8", "B9", "B10", "B11"
    };
    for (int j = 0; j < 20; j++) {
        fprintf(outf_file, "%s,", param_names[j]);
    }
    fprintf(outf_file, "\n");
    // Write data rows
    for (int i = 0; i < num_rows_outf; i++) {
        float current_height = heibeg + i * heistp;
        fprintf(outf_file, "%d", (int)current_height);
        // Write all 20 parameters for this height
        for (int j = 0; j < 20; j++) {
            fprintf(outf_file, ",%d", (int)(a[i][j] + 0.5f));
        }
        fprintf(outf_file, "\n");
    }
    fclose(outf_file);

    // --- Accessing Output Data ---
    // Example: Print selected values from 'b' (OARR array)
    printf("\nSelected values from output array 'b' (OARR):\n");
    // Indices are C-style (0-based), comments show corresponding Fortran index (1-based)
    printf("  OARR(1) (NmF2 / m^-3): %e\n", b[0]);    // NMF2
    printf("  OARR(2) (HmF2 / km): %f\n", b[1]);      // HMF2
    printf("  OARR(5) (NmE / m^-3): %e\n", b[4]);     // NME
    printf("  OARR(6) (HmE / km): %f\n", b[5]);       // HME
    printf("  OARR(10) (B0 / km): %f\n", b[9]);       // B0 thickness parameter
    printf("  OARR(33) (Rz12): %f\n", b[32]);         // 12-month running mean sunspot number
    printf("  OARR(34) (Covington Index): %f\n", b[33]); // Covington index (F10.7 daily adjusted)
    printf("  OARR(35) (B1): %f\n", b[34]);           // B1 parameter
    printf("  OARR(39) (IG12): %f\n", b[38]);         // 12-month running mean Ionosonde Global index
    printf("  OARR(41) (F10.7 daily): %f\n", b[40]);  // Daily F10.7 solar flux
    printf("  OARR(46) (F10.7_81): %f\n", b[45]);     // 81-day running mean F10.7

    // Example: Print Electron Density profile from 'a' (OUTF array, column 1)
    printf("\nElectron Density profile from 'a' (OUTF(*, 1)):\n");

    for (int i = 0; i < num_rows_outf; i++) {
        float electron_density_m3 = a[i][0]; // OUTF(i+1, 1) in Fortran indexing
        float current_height = heibeg + i * heistp;
        // Convert from m^-3 to cm^-3 for display
        float electron_density_cm3 = electron_density_m3 / 1.0e6f;
        printf("  Height: %.1f km, Ne: %.3e /cm^3\n",
               current_height, electron_density_cm3);
    }

    return 0;
}