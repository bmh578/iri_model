# IRI-2016 Model Fortran-C Project

This project demonstrates how to integrate the International Reference Ionosphere (IRI-2016) Fortran model with a C application. It provides a working example of creating a Fortran shared library that can be called from C code, with visualizations of the ionospheric parameters.

## Overview

The International Reference Ionosphere (IRI) is an empirical standard model of the ionosphere, providing monthly averages of electron density, electron temperature, ion temperature, ion composition, and several other parameters in the altitude range from 50 km to 2000 km. This project:

1. Downloads the IRI-2016 Fortran source code and required data files
2. Compiles the Fortran code into a shared library
3. Provides C bindings to call the IRI model functions
4. Implements a C application that runs the model and generates visualizations

## Project Structure

```
fortran_c_binding/
├── src/                # Source code directory
│   ├── fortran/        # Fortran source files (IRI-2016 model)
│   └── c/              # C source files (main.c and plot_results.c)
├── include/            # C header files (iri.h)
├── lib/                # Shared library output (libiri2016.so)
├── build/              # Executables and data files
├── scripts/            # Download and utility scripts
└── test/               # Test files (if needed)
```

## Prerequisites

This project requires the following dependencies:

- **Fortran Compiler**: gfortran (GNU Fortran compiler)
- **C Compiler**: gcc (GNU C compiler)
- **Build Tools**: make
- **Plotting**: gnuplot (for visualization)
- **Utilities**: wget (for downloading data files)

### Installing Dependencies

#### On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install gfortran gcc make gnuplot wget
```

#### On macOS (using Homebrew):
```bash
brew install gcc make gnuplot wget
```

#### On Windows:
Use Windows Subsystem for Linux (WSL) with Ubuntu, or use MinGW/MSYS2 to install the required packages.

## Building the Project

Follow these steps to build and run the project:

### 1. Clone the Repository

If you haven't already cloned the repository:

```bash
git clone <repository-url>
cd fortran_c_binding
```

### 2. Download the IRI-2016 Model and Data Files

Run the download script to fetch all necessary Fortran source files and data files:

```bash
cd scripts
chmod +x download_iri.sh
./download_iri.sh
cd ..
```

This script will:
- Download IRI-2016 Fortran source files to `src/fortran/iri2016/`
- Download required data files (coefficients, indices) to the `build/` directory
- Make necessary adjustments to the source files for proper compilation

#### Note on Fortran Source Files

You can provide your own Fortran files for the IRI model instead of using the download script. The script checks if files exist before downloading, so it won't override your files if they're already present. However, if you do use `download_iri.sh`, be aware of the following operations it performs on downloaded files:

1. **Cleaning Fortran Files**: The script cleans all downloaded Fortran files to ensure compatibility with modern compilers:
   ```bash
   # Removes text beyond column 72 which might cause compilation issues
   sed -i 's/\(^.\{72\}\).*/\1/' "$file"
   ```
   This is necessary because traditional Fortran 77 has a strict 80-column format, with columns 73-80 reserved for line numbers and other information. Removing content beyond column 72 prevents potential compilation errors.

2. **Modifications to irifun.for**: The script makes specific modifications to `irifun.for` to ensure successful compilation:
   ```bash
   # Splits common blocks to prevent naming conflicts
   sed -i 's|common /igrz/aig,arz,iymst,iymend|common /igrz/iymst,iymend\n       common /agrz/aig,arz|g' "$FORTRAN_DIR/irifun.for"
   sed -i 's|common	/igrz/ionoindx,indrz,iymst,iymend|common /igrz/iymst,iymend\n       common /agrz/ionoindx,indrz|g' "$FORTRAN_DIR/irifun.for"
   ```
   These modifications split common blocks in `irifun.for` to prevent naming conflicts during compilation.

The second modification only applies if `irifun.for` was actually downloaded by the script (i.e., it didn't already exist). If you provide your own Fortran files, you may need to make similar modifications manually if compilation fails.

### 3. Compile the Project

Use the provided Makefile to compile the Fortran shared library and C applications:

```bash
make
```

This will:
- Compile the Fortran code into a shared library (`lib/libiri2016.so`)
- Compile the main C program (`build/main`)
- Compile the plotting utility (`build/plot_results`)

If you encounter permission issues for shared library installation:

```bash
sudo make install
```

## Running the IRI Model

### 1. Run the Main Application

The main application runs the IRI model with predefined parameters and saves the output to a CSV file:

```bash
./build/main
```

Default model parameters in `main.c`:
- Geographic coordinates: 37.8°N, 75.4°W
- Date: October 10, 2017, 11:00 UTC
- Height range: 600-800 km with 10 km steps

You can modify these parameters in `src/c/main.c` and recompile if needed.

### 2. Generate Visualizations

After running the main application, use the plotting utility to generate visualizations:

```bash
./build/plot_results
```

This will create several PNG files in the build directory:

1. `electron_density_profile.png` - Electron density vs. height
2. `f2_layer_parameters.png` - F2 layer parameters (NmF2, HmF2, TeF2)
3. `e_layer_parameters.png` - E layer parameters (NmE, HmE, TeE)
4. `bottomside_parameters.png` - Bottomside parameters (B0, B1)
5. `electron_temperature_profile.png` - Electron temperature profiles
6. `f2e_density_ratio.png` - Ratio of F2 to E layer electron densities

## Model Output

The IRI model produces two main output arrays:

1. **OUTF** (in C: `a[1000][20]`): Contains height profiles for 20 different parameters
2. **OARR** (in C: `b[100]`): Contains various single-value parameters

The main.c program saves the height-dependent values to `output.csv` and prints key parameters to the terminal.

## Modifying the Model Parameters

To run the model with different input parameters:

1. Edit `src/c/main.c` to modify the input values:
   - `lat`, `lon` - Geographic coordinates (degrees)
   - `iy` - Year
   - `mmdd` - Month and day (MMDD format)
   - `dhour` - Hour (UTC + 25, local time + 0)
   - `heibeg`, `heiend`, `heistp` - Height range and step size (km)
   - `jf` array - Model switches (controls which models to use)

2. Recompile the project:
   ```bash
   make
   ```

3. Run the model and generate plots:
   ```bash
   ./build/main
   ./build/plot_results
   ```

## How the Fortran-C Binding Works

This project demonstrates three key aspects of Fortran-C interoperability:

1. **Shared Library Creation**: The Fortran code is compiled into a shared library (`libiri2016.so`)
2. **C Header Interface**: The `include/iri.h` header defines the interface to the Fortran functions
3. **Array Mapping**: Proper mapping between Fortran's column-major and C's row-major array layouts

The main interface functions are:
- `readapf107_()` - Reads solar flux data
- `read_ig_rz_()` - Reads ionosonde and sunspot number data
- `iri_sub_()` - The main IRI model subroutine

## Troubleshooting

### Library Not Found

If you encounter an error like "error while loading shared libraries: libiri2016.so":

```bash
sudo make install
# Or set the LD_LIBRARY_PATH manually:
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/lib
```

### Missing Data Files

If the model fails due to missing data files, run the download script again:

```bash
cd scripts
./download_iri.sh
cd ..
```

Ensure all required data files are in the `build/` directory.

### Gnuplot Not Found

If plotting fails with "Could not open pipe to gnuplot", install gnuplot:

```bash
# Ubuntu/Debian
sudo apt install gnuplot

# macOS
brew install gnuplot
```

## Advanced Usage

### Running with Custom Datasets

You can replace the index files (`apf107.dat` and `ig_rz.dat`) in the `build/` directory with updated datasets from the [IRI website](https://irimodel.org/indices/).

### Extending the Model

The IRI-2016 model has many parameters that can be adjusted via the `jf` array in the `main.c` file. Refer to comments in `irisub.for` for details on each switch.

## Running with Docker

For the easiest way to run the IRI-2016 model, this project provides a Docker container that has all dependencies pre-installed and configured. This gives you a solution that works right out of the box, without needing to install any dependencies or configure your system.

### Prerequisites for Docker

- [Docker](https://www.docker.com/products/docker-desktop/) installed on your system

### Building and Running the Docker Container

#### 1. Build the Docker Image

From the root directory of the project:

```bash
docker build -t iri2016-model .
```

This command builds a Docker image named `iri2016-model` using the configuration in the provided `Dockerfile`. The process:
- Sets up a clean Ubuntu environment
- Installs all required dependencies (compilers, gnuplot, etc.)
- Downloads the IRI-2016 model and data files
- Compiles the Fortran library and C applications
- Configures the environment for running the model

#### 2. Run the Container

```bash
docker run --name iri-run -v $(pwd)/output:/app/build iri2016-model
```

This command:
- Creates a container named `iri-run`
- Mounts the `output` directory from your local machine to the `/app/build` directory in the container
- Runs the main program and generates all plots automatically
- Saves the output files to your local `output` directory

#### 3. Access the Generated Plots

After running the container, you'll find all generated PNG files in your local `output` directory:
- `electron_density_profile.png`
- `ionospheric_parameters.png`
- Other plot files as specified in the plotting program

#### Alternative: Using Docker CP for Permission Issues

If you encounter permission issues with volume mounts (which can happen on certain systems), you can use `docker cp` to copy the output files from the container instead:

```bash
# First run the container without volume mounts
docker run --name iri-run iri2016-model

# Copy the output files from the container to your local machine
# This works even if the container has stopped
docker cp iri-run:/app/build/electron_density_profile.png ./
docker cp iri-run:/app/build/ionospheric_parameters.png ./
docker cp iri-run:/app/build/output.csv ./

# To copy all PNG files at once
docker cp iri-run:/app/build/*.png ./output/
```

This approach avoids permission issues entirely as it simply copies the files after they've been generated, rather than trying to write directly to a mounted volume.

### Advantages of Using Docker

- **Zero Configuration**: Everything works out of the box without installing dependencies
- **Consistent Environment**: The same environment regardless of your host operating system
- **Reproducible Results**: Always get the same output for the same input parameters
- **Isolated Environment**: Won't affect your system's libraries or configurations

### Running with Custom Parameters

If you want to modify the model parameters, you can:

1. Create a custom Dockerfile that extends the base image and modifies the parameters
2. Mount the source files as volumes and modify them directly:

```bash
# Mount the source directory and run an interactive shell
docker run -it --name iri-custom -v $(pwd)/src:/app/src -v $(pwd)/output:/app/build iri2016-model /bin/bash

# Inside the container, modify the parameters and run the model
cd /app
nano src/c/main.c
make
cd build
./main
./plot_results
```

### Docker Container Internals

The Docker container has the following structure:
- `/app`: Main project directory
  - `/app/src`: Source code (Fortran and C)
  - `/app/include`: Header files
  - `/app/lib`: Compiled libraries
  - `/app/build`: Executables and data files (mounted to your host for output)
  - `/app/scripts`: Download and utility scripts

## References

- [IRI-2016 Official Website](https://irimodel.org/)
- [IRI-2016 Documentation](https://irimodel.org/IRI-2016/00readme.txt)
- [Bilitza, D. (2018). IRI the International Standard for the Ionosphere. Advances in Radio Science, 16, 1-11.](https://doi.org/10.5194/ars-16-1-2018)

## License

This project is distributed under the terms of the original IRI-2016 model's license. The IRI model is developed as an international project by the Committee on Space Research (COSPAR) and the International Union of Radio Science (URSI).