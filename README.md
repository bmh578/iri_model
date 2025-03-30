# Fortran-C Binding Example

This project demonstrates how to create a Fortran shared library and use it from a C program.

## Project Structure

```
fortran_c_binding/
├── src/
│   ├── fortran/     # Fortran source files
│   └── c/           # C source files
├── include/         # C header files
├── lib/            # Shared library output
├── build/          # C program binary output
└── test/           # Test files (if needed)
```

## Prerequisites

- gfortran (GNU Fortran compiler)
- gcc (GNU C compiler)
- make

## Building the Project

To build the project, simply run:

```bash
make
```

This will:
1. Compile the Fortran code into a shared library (`lib/libexample.so`)
2. Compile the C program that uses the library (`build/main`)

## Running the Program

After building, you can run the program with:

```bash
./build/main
```

## Cleaning

To clean the build files:

```bash
make clean
```

## How it Works

1. The Fortran code (`src/fortran/example.f90`) defines a simple function `add_numbers` that is exposed to C using the `bind(c)` attribute.
2. The C header file (`include/example.h`) declares the interface to the Fortran function.
3. The C program (`src/c/main.c`) includes the header and calls the Fortran function.
4. The Makefile handles the compilation and linking process. 