Generating synthetic casino slot floor event data

# Preparing to generate
Need to compute session data from event data before anything else. This code not included here as it isn't mine. Maintain naming convention of par structures: 'par[methodName].mat' for ease of setting paths later on. Valid method names are 'UnifOcc', 'ProbUpdate', 'AddX', and 'MLE'.

## prep.m
Loads in data in a struct array format that is segmented by machine number. Assumes each struct element has fields 'machineNumber', 'eventCode', 'patronID', 'CI_meter', 'CO_meter", 'games_meter', and 'time' where the 'time' field is in a datenum format. User should do preliminary cleaning according to the format of the raw data. Place the full or relative path to the semi-raw data inside the first load command. This script does some additional processing to make the data structure compatible with the code that will compute the probability matrices and distributions. Saves the processed event data in 'EVD_datGen.mat'. Saves preliminary parameter structure in 'par0.mat'.

## buildTransitionMatrices_Launcher.m
Build the probability matrices according to the Uniform Occupancy method. Set scratch directories and number of processes (NCores) to use in the setup function at the bottom of the file. Each process calls buildTransMat.m.

## joinAndSaveTransMat.m
Run once all processes in buildTransitionMactrices_Launcher.m have completed. This will collate the results of each process and compute other probability distributions. par.converterCoordinationFile must match fullfile(par.scratch_transMat, par.converterCoordinationFile) from buildTransitionMatrices_Launcher.m.

## buildTransMatProbUpdate_Launcher.m
Build the probability matrices according to the Probability Update method. Set scratch directores and number of processes to use in the setup function at the bottom. Each process calls buildTransMatProbUpdate.m. Requires that both buildTransitionMatrices_Launcher.m and joinAndSaveTransMat.m have been run as many quantities are reused. par.parFilename must point to the par structure created by running buildTransitionMatrices_Launcher.m and joinAndSaveTransMat.m in sequence.

## joinAndSaveTransMatProbUpdate.m
Run once all processes in buildTransMatProbUpdate_Launcher have completed. This will collate the results of each process.

## buildTransMatOtherMethods.m
No setup function so need to set paths to event data and uniform occupancy par structure in the first two load commands. ctrl-f for save commands to find where new par structures are being saved. Builds probability matrices according to the Add-x and MLE methods.

# Generating Data
Maintain naming convention of generated event data 'EVDGen_[Multi|Single][methodName][modifier].mat' where [modifier] is customizable.

## generateData_Launcher.m
Code has capability to generate data with multiple processes, but the viability of the end result isn't well known so it is recommended that NCores be set to 1. Set par.methodName to the name of the probability matrix estimation method, par.filenameModifier to your desired filename modifier. Set par.params.numIters to the number of iterations you want the simulation to run for and par.params.J to the number of players allowed in the simulation at once. par.EVDFilename is the filename of the processed event data produced by prep.m. Each process calls generate.m.

# joinAndSaveEVD.m
Collates results from the processes created by generateData_Launcher.m Does some additional processing and saves in the desired location. Check that par.converterCoordinationFile at bottom matches the location where the coordination file was saved in generateData_Launcher.m.
