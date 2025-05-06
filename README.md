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

The application will:
1. Run the IRI-2016 model with the default parameters
2. Generate output data in `build/output.csv`
3. Display key ionospheric parameters in the terminal

Default model parameters in `main.c`:
- Geographic coordinates: 37.8°N, 75.4°W
- Date: March 3, 2021, 11:00 UTC
- Height range: 600-800 km with 10 km steps

You can modify these parameters in `src/c/main.c` and recompile if needed.

### 2. Generate Visualizations

After running the main application, use the plotting utility to generate visualizations:

```bash
./build/plot_results
```

This will create several PNG files in the `build` directory initially, and when running with Docker, these files are automatically moved to the `/app/plots` directory:

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
docker run --name iri-run -v $(pwd)/output:/app/plots iri2016-model
```

This command:
- Creates a container named `iri-run`
- Mounts the `output` directory from your local machine to the `/app/plots` directory in the container
- Runs the main program and generates all plots automatically
- Saves the output files (PNG plots and CSV data) to your local `output` directory

> **IMPORTANT**: All output plots and data files are generated inside the container in the `/app/plots` directory. To access these files on your local machine, you must either use volume mounting as shown above or copy the files using docker cp as shown in the "Accessing Generated Plots" section below.

#### 3. Run Interactively

To explore the container environment, make modifications, or run commands manually:

```bash
docker run -it --name iri-interactive iri2016-model /bin/bash
```

From within the container, you can:
- Run the application directly: `cd /app/build && ./main`
- Generate plots: `cd /app/build && ./plot_results`
- Modify and rebuild the code: `cd /app && make clean && make`
- Explore the file structure and data files

#### 4. Mount Local Files for Development

To work on the source code files from your host machine while using the container for building and running:

```bash
docker run -it --name iri-dev -v $(pwd)/src:/app/src -v $(pwd)/output:/app/build iri2016-model /bin/bash
```

This mounts your local `src` directory to the container's `/app/src` directory, allowing you to edit files locally while building and running in the container.

#### 5. Accessing the Generated Plots

After running the container, the generated plots and data files need to be transferred to your local machine.

**Method 1: Using Volume Mounts (Recommended)**

When running the container with a volume mount as shown in step 2 above, all files will automatically appear in your local `output` directory:

```bash
# Create a local output directory if it doesn't exist
mkdir -p output

# Run the container with the volume mount
docker run --name iri-run -v $(pwd)/output:/app/plots iri2016-model

# Check your local output directory
ls -la output
```

You'll find these files in your local output directory:
- `electron_density_profile.png`
- `f2_layer_parameters.png`
- `e_layer_parameters.png`
- `bottomside_parameters.png`
- `electron_temperature_profile.png`
- `f2e_density_ratio.png`
- `output.csv`

**Method 2: Using Docker CP for Permission Issues**

If you encounter permission issues with volume mounts (which can happen on certain systems), you can use `docker cp` to copy the output files from the container instead:

```bash
# First run the container without volume mounts
docker run --name iri-run iri2016-model

# Copy the output files from the container to your local machine
# The files will be in the /app/plots directory in the container
docker cp iri-run:/app/plots/electron_density_profile.png ./
docker cp iri-run:/app/plots/f2_layer_parameters.png ./
docker cp iri-run:/app/plots/output.csv ./

# To copy all files at once
mkdir -p ./output
docker cp iri-run:/app/plots/. ./output/
# Then you can filter just the PNG files if needed
find ./output -name "*.png" -maxdepth 1
```

This approach avoids permission issues entirely as it simply copies the files after they've been generated, rather than trying to write directly to a mounted volume.

### Advantages of Using Docker

- **Zero Configuration**: Everything works out of the box without installing dependencies
- **Consistent Environment**: The same environment regardless of your host operating system
- **Reproducible Results**: Always get the same output for the same input parameters
- **Isolated Environment**: Won't affect your system's libraries or configurations

### Docker Troubleshooting

#### Missing Data Files
If you encounter errors about missing data files:
- Ensure the container has all necessary files in `/app/build`
- The download script might have failed to retrieve some files
- You can re-run the container with a fresh build: `docker build --no-cache -t iri2016-model .`

#### Library Path Issues
If you encounter library loading issues:
- The Dockerfile sets the `LD_LIBRARY_PATH` to include `/usr/lib`
- You can verify this in the container with: `echo $LD_LIBRARY_PATH`
- If needed, manually set it: `export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH`

#### Building or Compilation Issues
If you encounter compilation issues:
- Run `make clean` before rebuilding: `cd /app && make clean && make`
- Check library dependencies with: `ldd /app/lib/libiri2016.so`
- Verify that all source files were downloaded correctly

#### Container Won't Start or Crashes
If the container fails to start or crashes:
- Check Docker logs: `docker logs iri-run`
- Try running in interactive mode to see error messages: `docker run -it iri2016-model /bin/bash`
- Check if your system has enough resources allocated to Docker

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

### Using Custom Scripts

For more advanced use cases, you can create custom scripts to run with specific parameters:

1. Create a script in your project (e.g., `run_custom.sh`):
```bash
#!/bin/bash
# Example custom run script
cd /app
make clean
make
cd build
# Run with custom arguments or process results in a specific way
./main
./plot_results
# Process or analyze results
```

2. Make it executable: 
```bash
chmod +x run_custom.sh
```

3. Run your container with this script:
```bash
docker run --rm -v $(pwd)/run_custom.sh:/app/run_custom.sh -v $(pwd)/output:/app/build iri2016-model /app/run_custom.sh
```

This approach allows for automation of complex workflows while maintaining the benefits of containerization.

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