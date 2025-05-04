FROM ubuntu:22.04

# Install necessary packages
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    gfortran \
    gcc \
    make \
    sudo \
    gnuplot \
    fonts-freefont-ttf \
    libcairo2 \
    libpango1.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directory structure
WORKDIR /app
RUN mkdir -p src/fortran/iri2016 src/c include lib build scripts

# Copy files
COPY Makefile ./
COPY scripts/download_iri.sh ./scripts/
COPY src/c/main.c ./src/c/
COPY src/c/plot_results.c ./src/c/
COPY include/iri.h ./include/

# Make download script executable
RUN chmod +x ./scripts/download_iri.sh

# Fix potential Windows line endings in shell script
RUN sed -i 's/\r$//' ./scripts/download_iri.sh

# Temporarily copy and replace irifun.for file
COPY src/fortran/iri2016/irifun.for ./src/fortran/iri2016/

# Build the library and executable
RUN make

# Make the library available system-wide
RUN make install

# Set environment variables
ENV LD_LIBRARY_PATH="/usr/lib"

# Cd into the build directory
WORKDIR /app/build

# Run the main program and generate plots when the container starts
CMD ["/bin/bash", "-c", "./main && ./plot_results && echo 'Plot files generated in the /app/build directory:' && ls -l *.png"]
