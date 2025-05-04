# Compiler settings
FC = gfortran
CC = gcc

# Directories
SRC_FORTRAN = src/fortran
SRC_C = src/c
INCLUDE = include
BUILD_LIB = lib
INSTALL_LIB = /usr/lib
BUILD = build
GFORTRAN_LIB = /usr/lib/gcc/x86_64-linux-gnu/11

# Flags
FFLAGS = -fPIC -shared -std=legacy -ffixed-form -ffixed-line-length-80
CFLAGS = -I$(INCLUDE) -L$(INSTALL_LIB) -L$(GFORTRAN_LIB) -L$(BUILD_LIB)

# Fortran file names
FORTRAN_FILES := irifun.for irisub.for iritec.for iridreg.for igrf.for \
                 cira.for iriflip.for irirtam.for iritest.for

# Fortran source files
FORTRAN_SOURCES := $(addprefix $(SRC_FORTRAN)/iri2016/,$(FORTRAN_FILES))
FORTRAN_OBJECTS = $(FORTRAN_SOURCES:.for=.o)

# Targets
all: $(BUILD_LIB)/libiri2016.so $(BUILD)/main $(BUILD)/plot_results

install: all
	sudo cp $(BUILD_LIB)/libiri2016.so $(INSTALL_LIB)/

# Build Fortran shared library
$(BUILD_LIB)/libiri2016.so: $(FORTRAN_OBJECTS)
	@mkdir -p $(BUILD_LIB)
	$(FC) $(FFLAGS) -o $@ $^

# Build C programs
$(BUILD)/main: $(SRC_C)/main.c $(BUILD_LIB)/libiri2016.so
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -o $@ $(SRC_C)/main.c -liri2016 -lgfortran

# Build plotting program
$(BUILD)/plot_results: $(SRC_C)/plot_results.c
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -o $@ $(SRC_C)/plot_results.c

# Compile Fortran 77 files
%.o: %.for 
	$(FC) $(FFLAGS) -c $< -o $@

$(FORTRAN_SOURCES): download_data 

# Download data files
download_data: 
	@echo "Setting up data files for IRI model..."
	@mkdir -p $(BUILD)
	@cd scripts && ./download_iri.sh

clean:
	rm -rf $(BUILD_LIB)/* $(BUILD)/* $(SRC_FORTRAN)/*

.PHONY: all clean install download_data