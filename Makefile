# Compiler settings
FC = gfortran
CC = gcc

# Directories
SRC_FORTRAN = src/fortran
SRC_C = src/c
INCLUDE = include
LIB = lib
BUILD = build

# Flags
FFLAGS = -fPIC -shared
CFLAGS = -I$(INCLUDE) -L$(LIB) -Wl,-rpath,$(LIB)

# Targets
all: $(LIB)/libexample.so $(BUILD)/main

# Build Fortran shared library
$(LIB)/libexample.so: $(SRC_FORTRAN)/example.f90
	@mkdir -p $(LIB)
	$(FC) $(FFLAGS) -o $@ $<

# Build C program
$(BUILD)/main: $(SRC_C)/main.c $(LIB)/libexample.so
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -o $@ $< -lexample

clean:
	rm -rf $(LIB)/* $(BUILD)/*

.PHONY: all clean 