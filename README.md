# Physics
This code retrieves the main fluxes and variables required for the East Antarctic Atlantis model from the ACCESS hidrodynamics model.

## Overview
The code consists of several steps to process the input data and create the necessary outputs for the EA model. Below is a summary of the main steps:

### Step 1: Reading the box information
The function reads the box information from a Bathymetric Geographic Model (BGM) file, including the number of boxes, faces, box IDs, centroids, areas, vertices, and interfaces.

### Step 2: Setting up global variables
The function assigns values to various global variables used throughout the code, such as face IDs, neighboring layers, face points, and depth levels.

### Step 3: Running the model and saving results
The function runs the model and saves the transport data for each year. It iterates over the input files containing U and V velocities and calculates the transport between layers using the provided parameters. The results are stored in temporary files.

### Step 4: Combining transport data
The function loads the temporary transport data files for each year and combines them into a single matrix, along with the corresponding time information.

### Step 5: Writing transport data to a NetCDF file
The combined transport data is written to a NetCDF file, including the box connectivity, transport values, and time information.

### Step 6: Retrieving variable data by layer
The function retrieves variable data (such as water velocity, salinity, and temperature) from input files, calculates averages by layer, and stores the results in temporary files.

### Step 7: Combining variable data
The function loads the temporary variable data files for each variable and combines them into a single matrix, along with the corresponding time information.

### Step 8: Writing variable data to a NetCDF file
The combined variable data is written to a NetCDF file, including the box IDs, variable values, and time information.

**Note:** The specific file paths and iteration details in this code are provided as examples and may need to be adjusted for your specific use case.
