scriptVersion="20230405_MMMEA_v3.3";

//tested on ImageJ version 1.53o

//plugins needed to be downloaded and put in the plugin folder of fiji:
 
//-TurboReg_.jar (http://bigwww.epfl.ch/thevenaz/turboreg/)
 
//-HyperStackReg_.class (https://github.com/ved-sharma/HyperStackReg)
//-EzColocalization_.jar (https://github.com/DrHanLim/EzColocalization)

//update sites that need to be added to the ImageJ Updater (Help/Update.../Manage update sites:
//Stardist -https://sites.imagej.net/StarDist/
//Bio-Formats -https://sites.imagej.net/Bio-Formats/
//Stardist needs a trained model .zip file to work

//Read in a folder and process every images with a specific extention (.ims;.lif) (.lif files will read in all the series)
//option to work on a Z stack or on the focal plane defined by the plane with the highest variance on a specific channel
//To note: working on a Z stack do not allow the attribution of different ROIs through the stack to single cells. It works best if there is only 1 cell per field
//Segment nuclei using standard ImageJ Thresholding algorithms or by using Stardist and a Stardist-trained model
//Measure all ROIs for size, position and fluorescence in all channels
//option to measure the number of Foci in specific channels using the Find Maxima function of ImageJ
//option to measure the colocalization (TOS, PCC, SRCC, ICQ, MCC) between two channels using the EZcolocalization plugin
//Compile the results in a single .txt file with every variable separated by a comma (can be opened in excel as a .csv)

//All variables are user defined and compiled in a log.csv file for traceability
//option to start an analysis by loading all variables from a previous log.csv file

//possibility to work in batch mode or in test mode (only 3 images)

//option to remove images with high intensity pixels from the analysis (pixels above the 3/4 of the pixel depth of the image)
//option to remove the camera background by removing a fixed pixel value or by removing the modal value
//option to add channels from another image and to align it to the previous image using a fixed pixel offset or by channel registration using a common channel
 
//common channel registration: (if in both image the same channel have been acquired, it can be used for alignment)

//For segmentation of nuclei, option to segment using a single nuclei staining channel or an artificial channel made by adding two channels together in order to mimic a DNA staining signal
//For segmentation of nuclei, option to work on a filtered image (median filter or gaussian blur) in order to facilitate the segmentation
//2022.02.09: Added the option to apply a gamma filter before segmentation in order to increase nuclei signal to noise. Useful for when nuclei signal is abnormally low
//After segmentation, nuclei can be filtered out of the analysis based on their size, on their IntDen, on their fluorescence coefficient of variation or on if they are in focus on the selected focal plane
 
//option to save the ROIs before and after the segmented ROIs have been filtered
//option to save a .TIFF image of the image which would correspond to the image with the added channels and with its background substracted
//option to make a .png montage of the image

//When measuring colocalization, option to measure the colocalization between an additionnal pair of channels
//When measuring colocalization, option to work with the channels RAW signals, a thresholded image using standard ImageJ Thresholding algorithms or a thresholded image using the Find Maxima function
 
//using RAW signals will make EZcolocalization use the Coste' algorithm to threshold what are positive anof the current analyzed ROId negative pixels
//Using a thresholded image will decide prior to EZcolocalization what are positive and negative pixels
//Thresholding using the Find Maxima will make only the detected Foci being positive pixels.
 
//Of note, the Find Maxima thresholding only work on single Z and uses the "Maxima Within Tolerance" output which is not perfect and not the whole Foci
 
//When measuring colocalization, option to save the channel pairs on which colocalization were measure, if thresholded images were used, save an image of the thresholded channel pairs

//patch notes:
//20220211_MMMEA_v2.2
//fixed channel alignment by channel registration of the AddCh function to work on nFocus instead of Hyperstack.
//it avoids the problem of bad cropping when the registration is unequal from Zplane to Zplane
//20220218_MMMEA_v2.3
//fixed channel alignment by pixel offset of the AddCh function to work on nFocus instead of Hyperstack.
//fixed channel alignment by pixel offset of the AddCh function to work when the secondary image has only 1 channel
//20220530_MMMEA_v2.4
//fixed the "Remove_Image_with_satured_pixels" function that was not working
//20220530_MMMEA_v2.5
//added a line to remove the automatic split channel option of Bio-Format at the end of the macro
//20230112_MMEA_v2.6
//In the EZcolocalization function, in the options that uses "masks" and "maxima finder", modified the code line "dividing" the mask images by 255 to include "stack" in order to work with allZ
//Also added a ROI update loop before running the EZcolocalization plugin in case ROI have been modified or added manually and contain channels and/or timepoint properties, which messes with the plugin
//20230223_MMMEA_v3.0
//modified the import function to be easier to add new stuff
//the macro now check if folder and file names have spaces in them and if yes it replaces them with underscore
//added some comment lines to facilitate code reading
//removed the imgNumber variable that was useless
//changed "controlpicture" for "pngtile image"
//added the ability to modify the number of images to process in testmode
//added the option to check in folder recursively or not
//when checking recursively, ignore the result folder
//changed some variable name (previous sCount, previousSlice)
//changed the way to update Zplanes of ROIs
//added the choice to work on a projection (max, sum, SD, median, mean projections)
//added the possibility to do background substraction by Rolling Ball;
//added the possibility to save 1 image each X images (pngtile, ROI pre/postg filter, Tiff, Mask images)
//separated the EZcolocalization function in 2 (to separate the measurment of an additional EZcoloc in a different function). Diminish the number of variable to transfer to the function
//EZcolocalization function now do not save the ROIzip file. The saving of the ROizip file now happen outside the function
//20230309_MMMEA_v3.1
//fixed the coloredROIimage function to adjust size of images depending on starting image format (works now on 2048*2048 images)
//made the result and the EZcolocalization images open outside of the screen to reduce interference with other computer work
//20230405_MMMEA_v3.2
//fixed the standardize ROI naming section to remove NaN values generated when using a Z projection
//20230405_MMMEA_v3.3
//really fixed the standardize ROI naming section when using a Z projection

// -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ---settings---settings---settings---settings---settings---settings---settings---settings---settings---settings---settings---settings---settings---settings---settings---settings---
// -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// clear log window
print("\\Clear");

// get date and time
// this will be used to calculate run time and other things
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

// make arrays expandable
setOption("ExpandableArrays", true);

//set measurments values
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");
setOption("Display label", true);
//if it is true, it breaks EZcolocalization
setOption("BlackBackground", false);
//make the progress bar rainbow
setTool("angle");

//to gain access to supplementary functions of Bio-format like get the series count ( useful for .lif files)
run("Bio-Formats Macro Extensions");

// -----------------
// pre-set variables
// -----------------

// define ExperimentID, which will be used in results.txt as row/line ID
experimentID = ""+toString(year)+"_"+toString(month+1)+"_"+toString(dayOfMonth)+"-"+toString(hour)+"_"+toString(minute);

//create array that lists colors in the same order used by "merge channels"
colorArray = newArray("Red","Green","Blue","Gray","Cyan","Magenta","Yellow");

//used to know how many time the code passed through the measurment section
//used to create the headline of the result file only once
loopcount = 0;

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ---user defined variables---user defined variables---user defined variables---user defined variables---user defined variables---user defined variables---user defined variables---
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// ask user to set parameters in settings menu
print("Please set settings in the separate window and click ok:");

// create settings-dialog boxes
// by changing values after the comma inside brackets per line, presets can be changed here

//Dialog box 0/5 get the choice to import inputs from the log.csv file from a previous analysis
Dialog.create("Settings 1/5:");
Dialog.addCheckbox("Import parameters from a previous analysis?", false);
Dialog.show();

// get choice to import inputs from the log.csv file from a previous analysis
Import = Dialog.getCheckbox();

// -------------------
// Import variables...
// -------------------

if (Import) {

       // set directory to the log.csv file to import
	print("Please select the directory to the log.csv file needed to be imported:");
	ImportDir = getDirectory("Please select the directory to the log.csv file needed to be imported::");
	Importcsv = ImportDir+"log.csv";

	//set the new Experiment Identifier
	Dialog.create("Settings:");
	Dialog.addString("Experiment Identifier:","Experiment1");
	Dialog.addCheckbox("Analyse images in subfolders?", false);
	Dialog.addCheckbox("Batch mode", false);
	Dialog.addCheckbox("Test mode", false);
	Dialog.addString("Test mode, number of images","3");
	Dialog.show();

	//Get the Experiment Identifier. Needed to name results files
	ExpIdent = Dialog.getString();
	//get the choice of measuring images in subfolders
	rec = Dialog.getCheckbox();
	// get batch mode status
	batch = Dialog.getCheckbox();
	// get test mode status
	testMode = Dialog.getCheckbox();
	// number of files to process if test-mode is active
	tn = Dialog.getString();
	//Read in the log.csv and define the variables
	Table.open(Importcsv);

	//make an array of the values of the log.csv table used to import user defined variable
	ImportArray = "";
	for (row = 0; row < Table.size; row++) {
		value = Table.getString("value", row);
		ImportArray = Array.concat(ImportArray,value);
	}

	//fill in the variable with the content of the ImportArray
	//first row to import is the 8th
	pos=8;
	filetype = ImportArray[pos];
	pos = pos+1;
	allZ = ImportArray[pos];
	pos = pos+1;
	FocalChannel = ImportArray[pos];
	pos = pos+1;
	seg = ImportArray[pos];
	pos = pos+1;
	Coloc = ImportArray[pos];
	pos = pos+1;
	FociCount = ImportArray[pos];
	pos = pos+1;
	AddCh = ImportArray[pos];
	pos = pos+1;
	Satur = ImportArray[pos];
	pos = pos+1;
	BS = ImportArray[pos];
	pos = pos+1;
	BSmethod = ImportArray[pos];
	pos = pos+1;
	BSvalue = ImportArray[pos];
	pos = pos+1;
	RBradius = ImportArray[pos];
	pos = pos+1;
	ThreshStrategy = ImportArray[pos];
	pos = pos+1;
	ThreshChannelString = ImportArray[pos];
	ThreshChannelArray = num2array(ThreshChannelString,";");
	pos = pos+1;
	FilterChoice = ImportArray[pos];
	pos = pos+1;
	Filter = ImportArray[pos];
	pos = pos+1;
	FilterPixelRadius = ImportArray[pos];
		pos = pos+1;
	ThreshMet = ImportArray[pos];
	pos = pos+1;
	wtshed = ImportArray[pos];
	pos = pos+1;
	threshexclude = ImportArray[pos];
	pos = pos+1;
	pathToStardistModel = ImportArray[pos];
	pos = pos+1;
	probThresh = ImportArray[pos];
	pos = pos+1;
	overlapThresh = ImportArray[pos];
	pos = pos+1;
	starexclude = ImportArray[pos];
	pos = pos+1;
	SecfileDir = ImportArray[pos];
	pos = pos+1;
	secImageChannels = ImportArray[pos];
	secImagechannelsArray = Array.getSequence(secImageChannels+1);
	secImagechannelsArray = Array.deleteValue(secImagechannelsArray, 0);
	pos = pos+1;
	AddChannelList = ImportArray[pos];
	AddImageChannelArray = num2array(AddChannelList,";");
	pos = pos+1;
	Alignment = ImportArray[pos];
	pos = pos+1;
	AlignmentMeth = ImportArray[pos];
	pos = pos+1;
	Xoffset = ImportArray[pos];
	pos = pos+1;
	Yoffset = ImportArray[pos];
	pos = pos+1;
	Alignmentfirstchannel = ImportArray[pos];
	pos = pos+1;
	Alignmentsecondchannel = ImportArray[pos];
	pos = pos+1;
	ROIminarea = ImportArray[pos];
	pos = pos+1;
	ROImaxarea = ImportArray[pos];
	pos = pos+1;
	IntDenFilterChoice = ImportArray[pos];
	pos = pos+1;
	IntDenFilterChannelString = ImportArray[pos];
	IntDenFilterChannelArray = num2array(IntDenFilterChannelString,";");
	pos = pos+1;
	IntDenFilterOperatorList = ImportArray[pos];
	IntDenFilterOperatorArray = num2array(IntDenFilterOperatorList,";");
	pos = pos+1;
	IntDenFilterThreshList = ImportArray[pos];
	IntDenFilterThreshArray = num2array(IntDenFilterThreshList,";");
	pos = pos+1;
	CVFilterChoice = ImportArray[pos];
	pos = pos+1;
	CVFilterChannelList = ImportArray[pos];
	CVFilterChannelArray = num2array(CVFilterChannelList,";");
	pos = pos+1;
	CVFilterOperatorList = ImportArray[pos];
	CVFilterOperatorArray = num2array(CVFilterOperatorList,";");
	pos = pos+1;
	CVFilterThreshList = ImportArray[pos];
	CVFilterThreshArray = num2array(CVFilterThreshList,";");
	pos = pos+1;
	outofFocusROIfilterchoice = ImportArray[pos];
	pos = pos+1;
	Zdifferential = ImportArray[pos];
	pos = pos+1;
	Ratiolimit = ImportArray[pos];
	pos = pos+1;
	outofFocusROIChannel = ImportArray[pos];
	pos = pos+1;
	dows = ImportArray[pos];
	pos = pos+1;
	EZChannelsString = ImportArray[pos];
	EZChannelsArray = num2array(EZChannelsString,";");
	if (Coloc) {
		ch1 = substring(EZChannelsString, 0, 1);
		ch2 = substring(EZChannelsString, 2);
	} else {
		ch1 = "";
		ch2 = "";
	}
	pos = pos+1;
	EZmeth1 = ImportArray[pos];
	pos = pos+1;
	threshMeth1 = ImportArray[pos];
	pos = pos+1;
	prominence1 = ImportArray[pos];
	pos = pos+1;
	EZmeth2 = ImportArray[pos];
	pos = pos+1;
	threshMeth2 = ImportArray[pos];
	pos = pos+1;
	prominence2 = ImportArray[pos];
	pos = pos+1;
	addEZ = ImportArray[pos];
	pos = pos+1;
	EZaddChannelsString = ImportArray[pos];
	EZaddChannelsArray = num2array(EZaddChannelsString,";");
	if (Coloc) {
		if (addEZ) {
			addch1 = substring(EZaddChannelsString, 0, 1);
			addch2 = substring(EZaddChannelsString, 2);
		} else {
			addch1 = "";
			addch2 = "";
		}
	}
	pos = pos+1;
	addEZmeth1 = ImportArray[pos];
	pos = pos+1;
	addthreshMeth1 = ImportArray[pos];
	pos = pos+1;
	addprominence1 = ImportArray[pos];
	pos = pos+1;
	addEZmeth2 = ImportArray[pos];
	pos = pos+1;
	addthreshMeth2 = ImportArray[pos];
	pos = pos+1;
	addprominence2 = ImportArray[pos];
	pos = pos+1;
	cfcString = ImportArray[pos];
	cfcArray = num2array(cfcString,";");
	pos = pos+1;
	PromString = ImportArray[pos];
	PromArray = num2array(PromString,";");
	pos = pos+1;
	saveinterval = ImportArray[pos];
	pos = pos+1;
	ROIprezip = ImportArray[pos];
	pos = pos+1;
	ROIpostzip = ImportArray[pos];
	pos = pos+1;
	Tiff = ImportArray[pos];
	pos = pos+1;
	png = ImportArray[pos];
	pos = pos+1;
	montageString = ImportArray[pos];
	montageArray = num2array(montageString,";");
	pos = pos+1;
	Grayscale = ImportArray[pos];
	pos = pos+1;
	colorString = ImportArray[pos];
	colorChoices = num2array(colorString,";");
	pos = pos+1;
	MontageMinString = ImportArray[pos];
	MontageMinArray = num2array(MontageMinString,";");
	pos = pos+1;
	MontageMaxString = ImportArray[pos];
	MontageMaxArray = num2array(MontageMaxString,";");
	pos = pos+1;
	autoBC = ImportArray[pos];
	pos = pos+1;
	MergeString = ImportArray[pos];
	MergeArray = num2array(MergeString,";");
	pos = pos+1;
	pngtileROIs = ImportArray[pos];
	pos = pos+1;
	ScaleBar = ImportArray[pos];
	pos = pos+1;
	Masks = ImportArray[pos];
	pos = pos+1;
	proj = ImportArray[pos];

	// set the new working directory
	print("Please select a working directory:");
	workingDir = getDirectory("Please select a working directory:");

	//check if there are spaces in the workingDir and replaces the spaces by underscore
	if (indexOf(workingDir, " ") >= 0) {
		workingDir2 = replace(workingDir, " ", "_");
		File.rename(workingDir, workingDir2);
		workingDir = workingDir2;
	}

	//list all files of interest in workingDir
	filePaths = list_files(workingDir, filetype, rec);
	//sort arrays in alphabetic order, sometimes imagej is reading in the files in the incorrect order
	//important for the AddChannel function
	Array.sort(filePaths);

	// if no files are identified, delete results folder and terminate script
	if (filePaths.length == 0) {
		exit("No files found: Script terminated!");
	} else {
		// inform user how many files of interest have been identified
		print("Files identified: "+filePaths.length);
	}

	//Identify path to secondary images if option selected
	if (AddCh) {

		//get the path to secondary images with channel(s) to be adTable.getString("value", 28);ded
		print("Please select the path to secondary images with channel(s) to be added:");
		SecfileDir = getDirectory("Choose Secondary images Path");

		//check if there are spaces in the SecfileDir and replaces the spaces by underscore
		if (indexOf(SecfileDir, " ") >= 0) {
			SecfileDir2 = replace(SecfileDir, " ", "_");
			File.rename(SecfileDir, SecfileDir2);
			SecfileDir = SecfileDir2;
		}

		//list all secondary images used to add channels
		SecfilePaths = list_files(SecfileDir, filetype, rec);
		//sort arrays in alphabetic order, sometimes imagej is reading in the files in the incorrect order
		//important for the AddChannel function
		Array.sort(SecfilePaths);
		if (SecfilePaths.length != filePaths.length) {
			print("Unequal number of images and secondary images");
			exit;
		}
	}
// -----------------------
// ... or define variables
// -----------------------

// -----------------------

//If variables are not imported, define variables in dialog boxes
} else {

	//Dialog box 1/5 get the general inputs about image types, channels and measurment needed
	Dialog.create("Settings 1/5:");
	Dialog.addString("Experiment Identifier:","Experiment1");
	Dialog.addString("file type (ex.: .ims, .lif, .tiff):", ".ims");
	Dialog.addCheckbox("Analyse images in subfolders?", false);
	Dialog.addMessage("***ROI identification on all Z is not a 3D ROI identification***");
	Dialog.addMessage("***ROI identification on all Z do not link single nuclei ROIs across the Z planes,***");
	Dialog.addMessage("***this make it hard to attribute ROIs to cells but it works great when only one cell is present per field***");
	allZ= newArray("all Z", "focal plane", "max proj", "sum proj", "mean proj", "SD proj", "median proj");
	Dialog.addRadioButtonGroup("identify ROIs on all Zplanes or on focal plane?", allZ, 1, 2, "focal plane");
	Dialog.addNumber("Focal Plane Identification Channel:", 1);
	Dialog.addChoice("nucleus segmentation using:", newArray("Stardist","Thresholding"), "Stardist");
	Dialog.addCheckbox("Colocalization analysis", false);
	Dialog.addCheckbox("FociCount analysis", false);
	Dialog.addCheckbox("Batch mode", false);
	Dialog.addCheckbox("Test mode", false);
	Dialog.addString("Test mode, number of images","3");
	Dialog.show();

	//Get the Experiment Identifier. Needed to name results files
	ExpIdent = Dialog.getString();
	//get the image file extension
	filetype = Dialog.getString();
	//get the choice of measuring images in subfolders
	rec = Dialog.getCheckbox();
	//get the choice to work on all Zplanes or on the focal plane
	allZ = Dialog.getRadioButton();
	//get the channel for focal plane identification
	FocalChannel = Dialog.getNumber();
	//get the choice of segmentation method
	seg = Dialog.getChoice();
	//get the choice for Colocalization analysis
	Coloc = Dialog.getCheckbox();
	//get the choice for FociCount analysis
	FociCount = Dialog.getCheckbox();
	// get batch mode status
	batch = Dialog.getCheckbox();
	// get test mode status
	testMode = Dialog.getCheckbox();
	// number of files to process if test-mode is active
	tn = Dialog.getString();

	// set working directory
	print("Please select a working directory:");
	workingDir = getDirectory("Please select a working directory:");

	//check if there are spaces in the workingDir and replaces the spaces by underscore
	if (indexOf(workingDir, " ") >= 0) {
		workingDir2 = replace(workingDir, " ", "_");
		File.rename(workingDir, workingDir2);
		workingDir = workingDir2;
	}

	//list all files of interest in workingDir
	filePaths = list_files(workingDir, filetype, rec);
	//sort arrays in alphabetic order, sometimes imagej is reading in the files in the incorrect order
	//important for the AddChannel function
	Array.sort(filePaths);

	// if no files are identified, delete results folder and terminate script
	if (filePaths.length == 0) {
		exit("No files found: Script terminated!");
	} else {
		// inform user how many files of interest have been identified
		print("Files identified: "+filePaths.length);
	}

	//get the Stardist trained models
	if (seg == "Stardist") {
		print("Please select the path to stardist models:");
		StardistDir = getDirectory("Choose Stardist Path");

		//check if there are spaces in the StardistDir and replaces the spaces by underscore
		if (indexOf(StardistDir, " ") >= 0) {
			StardistDir2 = replace(StardistDir, " ", "_");
			File.rename(StardistDir, StardistDir2);
			StardistDir = StardistDir2;
		}

		// non recursively list all stardist model zip-files in stardist_model folder
		stardistModelPaths = list_files(StardistDir, ".zip", false);
		// extract model file names and write into array
		// initialize array, arrays have been set to be expandable already
		stardistModelNames = newArray("none available");
		// only continue writing stardistModelNames if there are any paths available
		if (stardistModelPaths.length != 0){
			for (i = 0; i < stardistModelPaths.length; i++) {
				// get index of last file separator within filepath
				index = lastIndexOf(stardistModelPaths[i], File.separator);
				stardistModelNames[i] = substring(stardistModelPaths[i], index+1);
			}
		}
	}

	//Dialog box 2/5 get the information about pretreatments and segmentation
	//Two different boxes depending on the choice of segmentation method

	if (seg=="Thresholding") {

		Dialog.create("Settings 2/5:");
		Dialog.addMessage("-------------------- Pre-segmentation treatments --------------------");
		Dialog.addCheckbox("Add an additionnal channel to images", false);
		Dialog.addCheckbox("Remove image with high intensity pixels (>75% of the pixel depth)?", false);
		Dialog.addCheckbox("Remove camera background?", true);
		BSmet = newArray("Fixed Value","Modal Value Substraction","Rolling Ball" );
		Dialog.addRadioButtonGroup("Camera background substraction method?", BSmet, 1, 2, "Modal Value Substraction");
		Dialog.addNumber("If Fixed value substraction what is the pixel value to be substracted?:", 500);
		Dialog.addNumber("If Rolling Ball BG substraction what is the pixel radius to be used?:", 50);
		Dialog.addMessage("-------------------- ROI Segmentation settings --------------------");
		Thresh = newArray("one","two" );
		Dialog.addRadioButtonGroup("Segment ROIs on 1 or 2 channel", Thresh, 1, 2, "one");
		Dialog.addString("Segment ROIs using which channel(s) (;):","1");
		Dialog.addCheckbox("Segment ROIs on a filtered image", true);
		Dialog.addChoice("which filter?", newArray("Median","Gaussian Blur","Gamma"), "median");
		Dialog.addNumber("with a pixel radius/sigma/value of? :", 15);
		Dialog.addChoice("Thresholding method for ROIs segmentation", newArray("Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"), "Otsu");
		Dialog.addCheckbox("Watershed", true);
		Dialog.addCheckbox("Exclude ROIs on edge", true);
		Dialog.show();

		//get the choice for adding an additional channel
		AddCh = Dialog.getCheckbox();
		//get choice of satured pixel images removal
		Satur = Dialog.getCheckbox();
		//get choice of Background substraction
		BS = Dialog.getCheckbox();
		// get the choice of Camera background substraction method
		BSmethod = Dialog.getRadioButton();
		//If Fixed value substraction, what is the pixel value to be substracted
		BSvalue = Dialog.getNumber();
		//If Rolling Ball BG substraction what is the pixel radius to be used?
		RBradius = Dialog.getNumber();
		// get number of channel used for ROI selection
		ThreshStrategy = Dialog.getRadioButton();
		//get the channel(s) used for the ROI segmentation
		ThreshChannelString = Dialog.getString();
		ThreshChannelArray = num2array(ThreshChannelString,";");
		//Get the choice of using a filtered image for thresholding
		FilterChoice = Dialog.getCheckbox();
		//Get the type of filter to apply
		Filter = Dialog.getChoice();
		//Get the pixel radius to use with the filter
		FilterPixelRadius = Dialog.getNumber();
		//Get choice of thresholding method
		ThreshMet = Dialog.getChoice();
		//Get choice of Whatershed
		wtshed = Dialog.getCheckbox();
		// get if ROIs on edge should be excluded
		threshexclude = Dialog.getCheckbox();
	} else {
		ThreshMet = "";
		wtshed = "";
		threshexclude = "";
	}

	if (seg=="Stardist") {

		Dialog.create("Settings 2/5:");
		Dialog.addMessage("-------------------- Pre-segmentation treatments --------------------");
		Dialog.addCheckbox("Add an additionnal channel to images", false);
		Dialog.addMessage("** Adding an additional channel is not yet adapted for .lif file***");
		Dialog.addCheckbox("Remove image with high intensity pixels (>75% of the pixel depth)?", false);
		Dialog.addCheckbox("Remove camera background?", true);
		BSmet = newArray("Fixed Value","Modal Value Substraction","Rolling Ball" );
		Dialog.addRadioButtonGroup("Camera background substraction method?", BSmet, 1, 2, "Modal Value Substraction");
		Dialog.addNumber("If Fixed value substraction what is the pixel value to be substracted?:", 500);
		Dialog.addNumber("If Rolling Ball BG substraction what is the pixel radius to be used?:", 50);
		Dialog.addMessage("-------------------- ROI Segmentation settings --------------------");
		Thresh = newArray("one","two" );
		Dialog.addRadioButtonGroup("SegmentROIs  on 1 or 2 channel", Thresh, 1, 2, "one");
		Dialog.addString("Segment ROIs using which channel(s) (;):","1");
		Dialog.addCheckbox("Segment ROIs on a filtered image", true);
		Dialog.addChoice("which filter?", newArray("Median","Gaussian Blur","Gamma"), "median");
		Dialog.addNumber("with a pixel radius/sigma/value of? :", 5);
		Dialog.addChoice("Segment ROIs with which Stardist model:", stardistModelNames);
		Dialog.addNumber("Stardist Prob./score threshold:", 0.45);
		Dialog.addNumber("Stardist Overlap threshold:", 0);
		Dialog.addCheckbox("Exclude ROIs on edge", true);
		Dialog.show();

		//get the choice for adding an additional channel
		AddCh = Dialog.getCheckbox();
		//get choice of satured pixel images removal
		Satur = Dialog.getCheckbox();
		//get choice of Background substraction
		BS = Dialog.getCheckbox();
		// get the choice of Camera background substraction method
		BSmethod = Dialog.getRadioButton();
		//If Fixed value substraction, what is the pixel value to be substracted
		BSvalue = Dialog.getNumber();
		//If Rolling Ball BG substraction what is the pixel radius to be used?
		RBradius = Dialog.getNumber();
		// get number of channel used for ROI selection
		ThreshStrategy = Dialog.getRadioButton();
		//get the channel(s) used for the ROI seg	mentation
		ThreshChannelString = Dialog.getString();
		ThreshChannelArray = num2array(ThreshChannelString,";");
		//Get the choice of using a filtered image for thresholding
		FilterChoice = Dialog.getCheckbox();
		//Get the type of filter to apply
		Filter = Dialog.getChoice();
		//Get the pixel radius to use with the filter
		FilterPixelRadius = Dialog.getNumber();
		// get filepath to stardist modelfile
		model = Dialog.getChoice();
		// combine choice with pathToStardistModelFolder to get a valid filepath to model file
		pathToStardistModel = StardistDir+model;
		// get probability/score threshold - higher values lead to fewer segmented objects, but will likely avoid false positives.
		probThresh = Dialog.getNumber();
		// get overlap threshold - higher values allow segmented objects to overlap substantially.
		overlapThresh = Dialog.getNumber();
		// get if ROIs on edge should be excluded
		starexclude = Dialog.getCheckbox();
	} else  {
		model = "";
		pathToStardistModel = "";
		probThresh = "";
		overlapThresh = "";
		starexclude = "";
	}

	if (AddCh) {
		//Dialog box 2b/5 get the information for adding an additional Channel to the images
		Dialog.create("Settings 2b/5:");
		Dialog.addMessage("-------------------- Channel Addition settings --------------------");
		Dialog.addMessage("***The images with the channel(s) to be added need to be in a seperate subfolder***");
		Dialog.addMessage("***The images with the channel(s) to be added can be named differently***");
		Dialog.addMessage("***This function needs an equal number of primary images and secondary images***");
		Dialog.addMessage("***The primary and secondary images need to have been acquired in the same order***");
		Dialog.addNumber("How many channel have the secondary image?", 1);
		Dialog.addString("Which channels from the secondary image should be added? (;)", "1");
		Dialog.addCheckbox("Align the added channels?", false);
		AlignMet = newArray("pixel offset","common channel registration" );
		Dialog.addRadioButtonGroup("Align using which method?", AlignMet, 1, 2, "common channel registration");
		Dialog.addMessage("-------------------- Pixel Offset --------------------");
		Dialog.addMessage("***from -100 to 100 pixels***");
		Dialog.addMessage("***negative values offset the image to the left and to the top***");
		Dialog.addNumber("Pixel offset in X:", -100);
		Dialog.addNumber("Pixel offset in Y:", -100);
		Dialog.addMessage("-------------------- Common Channel Registration --------------------");
		Dialog.addNumber("Which channel to use on the first image?", 2);
		Dialog.addNumber("Which channel to use on the image with the channel to be added?", 2);
		Dialog.show();

		print("Please select the path to secondary images with channel(s) to be added:");
		SecfileDir = getDirectory("Choose Secondary images Path");

		//check if there are spaces in the SecfileDir and replaces the spaces by underscore
		if (indexOf(SecfileDir, " ") >= 0) {
			SecfileDir2 = replace(SecfileDir, " ", "_");
			File.rename(SecfileDir, SecfileDir2);
			SecfileDir = SecfileDir2;
		}

		//list all secondary images used to add channels
		SecfilePaths = list_files(SecfileDir, filetype, rec);
		//sort arrays in alphabetic order, sometimes imagej is reading in the files in the incorrect order
		//important for the AddChannel function
		Array.sort(SecfilePaths);
		if (SecfilePaths.length != filePaths.length) {
			print("Unequal number of images and secondary images");
			exit;
		}
		// get the number of channels in the second image for the addChannel function
		secImageChannels = Dialog.getNumber();
		secImagechannelsArray = Array.getSequence(secImageChannels+1);
		secImagechannelsArray = Array.deleteValue(secImagechannelsArray, 0);
		// get the list of channels from the second image to add in the addChannel function
		AddChannelList = Dialog.getString();
		AddImageChannelArray = num2array(AddChannelList,";");
		//get the choice for alignment of the two images for the addChannel function using a common channel
		Alignment = Dialog.getCheckbox();
		// get the method of alignment chosen
		AlignmentMeth = Dialog.getRadioButton();
		//Get the X offset
		Xoffset = Dialog.getNumber();
		//Get the Y offset
		Yoffset = Dialog.getNumber();
		//Which channel to use on the first image for the alignment function
		Alignmentfirstchannel = Dialog.getNumber();
		//Which channel to use on the second image for the alignment function
		Alignmentsecondchannel = Dialog.getNumber();
	} else {
		SecfileDir = "";
		secImageChannels = "";
		secImagechannelsArray = "";
		secImagechannelsArray = "";
		AddChannelList = "";
		AddImageChannelArray = "";
		Alignment = "";
		AlignmentMeth = "";
		Xoffset = "";
		Yoffset = "";
		Alignmentfirstchannel = "";
		Alignmentsecondchannel = "";
	}

	//Dialog box 3/5 get the information about ROI filters before analysis

	Dialog.create("Settings 3/5:");
	Dialog.addMessage("-------------------- Filters settings --------------------");
	Dialog.addNumber("ROI minimum size:", 30);
	Dialog.addNumber("ROI minimum size:", 450);
	Dialog.addCheckbox("Filter on IntDen?", false);
	Dialog.addString("on which channel(s) (;)", "1;2;3");
	Dialog.addMessage("                             ***if you want to keep ROIs above a value, select '>' ***");
	Dialog.addString("> or <? (one sign per channel separated by ';')", "<;<;>");
	Dialog.addString("IntDen Threshold(s) (one value per channel separated by ';')", "50000;4235;7000");
	Dialog.addCheckbox("Filter on Coefficient of Variation (CV)?", false);
	Dialog.addString("on which channel(s) (;)", "1");
	Dialog.addString("> or <? (one sign per channel separated by ';')", "<");
	Dialog.addString("CV threshold(s) (;):", "0.7");
	Dialog.addCheckbox("Filter for out of focus ROIs", false);
	Dialog.addNumber("check position of plane using how many Z:", 1);
	Dialog.addNumber("maximal ratio tolerated for IntDen of plane/over or under planes:", 1.20);
	Dialog.addNumber("using which channel:", 3);
	Dialog.show();

	//get ROI minimal size threshold value
	ROIminarea = Dialog.getNumber();
	//get ROI maximal size threshold value
	ROImaxarea = Dialog.getNumber();

	//get choice of filtering based on IntDen
	IntDenFilterChoice = Dialog.getCheckbox();
	//get list of channels to filter based on IntDen
	IntDenFilterChannelString = Dialog.getString();
	IntDenFilterChannelArray = num2array(IntDenFilterChannelString,";");
	//get array of mathematical operator to use to filter based on IntDen
	IntDenFilterOperatorList = Dialog.getString();
	IntDenFilterOperatorArray = num2array(IntDenFilterOperatorList,";");
	//get list of thresholds to use to filter based on IntDen
	IntDenFilterThreshList = Dialog.getString();
	IntDenFilterThreshArray = num2array(IntDenFilterThreshList,";");

	//get choice of filtering based on CV
	CVFilterChoice = Dialog.getCheckbox();
	//get list of channels to filter based on CV
	CVFilterChannelList = Dialog.getString();
	CVFilterChannelArray = num2array(CVFilterChannelList,";");
	//get array of mathematical operator to use to filter based on CV
	CVFilterOperatorList = Dialog.getString();
	CVFilterOperatorArray = num2array(CVFilterOperatorList,";");
	//get list of thresholds to use to filter based on IntDen
	CVFilterThreshList = Dialog.getString();
	CVFilterThreshArray = num2array(CVFilterThreshList,";");

	//get choice to filter out nuclei that are out of focus
	outofFocusROIfilterchoice = Dialog.getCheckbox();
	//get Zdifferential value used in outofFocusROI filter
	Zdifferential = Dialog.getNumber();
	//get IntDen Z ratios threshold value
	Ratiolimit = Dialog.getNumber();
	//get which channel is used in outofFocusROI filter
	outofFocusROIChannel = Dialog.getNumber();

	//Dialog box 4/5 get the information for the analysis
	//Two different boxes depending on the choice of analysis wanted

	if (Coloc) {
		Dialog.create("Settings 4/5:");
		Dialog.addMessage("-------------------- EZ colocalization setting --------------------");
		Dialog.addCheckbox("Whatershed in EZ colocalization?", false);
		Dialog.addString("Channels to measure (;):","2;3");
		Dialog.addMessage("***Mask method create a mask out of ther signal and multiply it with the RAW image,***");
		Dialog.addMessage("***in this way, the positive pixels have their correct Int. Value but negative pixels have a value of 0.***");
		Dialog.addMessage("***For Masks, use Moments for PolIIpS2 in mESCS, and Otsu for EdU in mESCs***");
		Dialog.addChoice("measurment with first channel using", newArray("RAW","Mask","MaximaFinder"), "Mask" );
		Dialog.addChoice("If using Mask for first channel, use this method", newArray("Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"), "Otsu");
		Dialog.addNumber("If using MaximaFinder for first channel, use Foci count prominence:", 700);
		Dialog.addChoice("measurment with second channel using", newArray("RAW","Mask","MaximaFinder"), "Mask");
		Dialog.addChoice("If using Mask for second channel, use this method", newArray("Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"), "Moments");
		Dialog.addNumber("If using MaximaFinder for second channel, use Foci count prominence:", 1500);
		Dialog.addMessage("--------------------------------------------------------------------");
		Dialog.addCheckbox("Measure colocalization with an additionnal channel?", false);
		Dialog.addString("Channels to measure (;):","1;3");
		Dialog.addChoice("measurment with first channel using", newArray("RAW","Mask","MaximaFinder"), "RAW" );
		Dialog.addChoice("If using Mask for first channel, use this method", newArray("Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"), "Otsu");
		Dialog.addNumber("If using MaximaFinder for first channel, use Foci count prominence:", 700);
		Dialog.addChoice("measurment with second channel using", newArray("RAW","Mask","MaximaFinder"), "Mask");
		Dialog.addChoice("If using Mask for second channel, use this method", newArray("Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"), "Moments");
		Dialog.addNumber("If using MaximaFinder for second channel, use Foci count prominence:", 1500);
		Dialog.show();

		//get choice of whatershed in EZ
		dows = Dialog.getCheckbox();
		//get channels to measure with EZcolocalization
		EZChannelsString = Dialog.getString();
		EZChannelsArray = num2array(EZChannelsString,";");
		ch1 = substring(EZChannelsString, 0, 1);
		ch2 = substring(EZChannelsString, 2);
		//get kind of image used to measure coloc. for first channel
		EZmeth1 = Dialog.getChoice();
		//get thresholding method for Channel 1
		threshMeth1 = Dialog.getChoice();
		//get prominence value for MaximaFinder for first channel
		prominence1 = Dialog.getNumber();
		//get kind of image used to measure coloc. for second channel
		EZmeth2 = Dialog.getChoice();
		//get thresholding method for Channel 2
		threshMeth2 = Dialog.getChoice();
		//get prominence value for MaximaFinder for second channel
		prominence2 = Dialog.getNumber();

		//get choice to measure an additionnal channel
		addEZ = Dialog.getCheckbox();
		//get additionnal channels to measure with EZcolocalization
		EZaddChannelsString = Dialog.getString();
		EZaddChannelsArray = num2array(EZaddChannelsString,";");
		addch1 = substring(EZaddChannelsString, 0, 1);
		addch2 = substring(EZaddChannelsString, 2);
		//get kind of image used to measure coloc. for first additionnal channel
		addEZmeth1 = Dialog.getChoice();
		//get thresholding method for additionnal Channel 1
		addthreshMeth1 = Dialog.getChoice();
		//get prominence value for MaximaFinder for additionnal first channel
		addprominence1 = Dialog.getNumber();
		//get kind of image used to measure coloc. for additionnal second channel
		addEZmeth2 = Dialog.getChoice();
		//get thresholding method for additionnal Channel 2
		addthreshMeth2 = Dialog.getChoice();
		//get prominence value for MaximaFinder for additionnal second channel
		addprominence2 = Dialog.getNumber();
	} else {
		dows = "";
		EZChannelsString = "";
		EZChannelsArray = "";
		ch1 = "";
		ch2 = "";
		EZmeth1 = "";
		threshMeth1 = "";
		prominence1 = "";
		EZmeth2 = "";
		threshMeth2 = "";
		prominence2 = "";
		addEZ = "";
		EZaddChannelsString = "";
		EZaddChannelsArray = "";
		addch1 = "";
		addch2 = "";
		addEZmeth1 = "";
		addthreshMeth1 = "";
		addprominence1 = "";
		addEZmeth2 = "";
		addthreshMeth2 = "";
		addprominence2 = "";
	}

		if (FociCount) {
		Dialog.create("Settings 4/5:");
		Dialog.addMessage("------------------------Foci count-------------------------------");
		Dialog.addString("Count foci in which channel(s)? (;):", "2");
		Dialog.addString("Foci count prominences for each channels in order (;):","700");
		Dialog.show();

		// channel for foci count
		cfcString = Dialog.getString();
		cfcArray = num2array(cfcString,";");
		// set noise level for find maxima function that is used to identify foci per roi
		// additional parameters can be added within the code
		// you can find a good explanation by Michael Schmid here: https://forum.image.sc/t/new-maxima-finder-menu-in-fiji/25504/5
		PromString = Dialog.getString();
		PromArray = num2array(PromString,";");
	} else {
		cfcString = "";
		cfcArray = "";
		PromString = "";
		PromArray = "";
	}

	//Dialog box 5/5 get the information for the saving of images
	Dialog.create("Settings 5/5:");
	Dialog.addNumber("Create/Save 1 image each X image of each of the selected types below X=", 1);
	Dialog.addMessage("-----------------------------------------------------------------------------");
	Dialog.addCheckbox("Save ROIs BEFORE applying filters?", false);
	Dialog.addCheckbox("Save ROIs AFTER applying filters?", false);
	Dialog.addMessage("-----------------------------------------------------------------------------");
	Dialog.addCheckbox("Save an adjusted Tiff file?", false);
	Dialog.addMessage("-----------------------------------------------------------------------------");
	Dialog.addCheckbox("Create a .png tile image", true);
	Dialog.addString("Set channels to show in order (;):", "1;2;3");
	Dialog.addCheckbox("All Channels in Grayscale?", false);
	Dialog.addMessage("1=Red 2=Green 3=Blue 4=Gray 5=Cyan 6=Magenta 7=Yellow");
	Dialog.addMessage("***Do not use Gray(4)***");
	Dialog.addString("Set color per channel in order (;):", "1;2;5");
	Dialog.addString("Set lower grey scale limits (;):","400;400;400");
	Dialog.addString("Set upper grey scale limits (;):","1000;1000;1000");
	Dialog.addCheckbox("Ignore upper and lower limits and instead use automatic brightness and contrast", false);
	Dialog.addString("Set channels to show in the merge (;):", "2;3");
	Dialog.addCheckbox("Draw ROIs onto .png tile images", true);
	Dialog.addCheckbox("Draw a scale Bar onto .png tile images", true);
	Dialog.addMessage("---------------------------For Colocalization---------------------------------");
	Dialog.addCheckbox("If Mask were used for EZcolocalization, save a tiff of the masks?", true);
	Dialog.addMessage("---------------------------For Projections---------------------------------");
	Dialog.addCheckbox("If a projection was used, save a tiff of the proj?", true);
	Dialog.show();

	//get the saving interval (save one image each X image)
	saveinterval = Dialog.getNumber();
	//get choice of saving ROIs zip file
	ROIprezip = Dialog.getCheckbox();
	//get choice of saving ROIs zip file
	ROIpostzip = Dialog.getCheckbox();
	//get choice of making a TIFF file
	Tiff = Dialog.getCheckbox();
	//check if png tile pictures should be created
	png = Dialog.getCheckbox();
	//get channels to show in montage
	montageString = Dialog.getString();
	montageArray = num2array(montageString,";");
	//get choice of using grayscale only in montage
	Grayscale = Dialog.getCheckbox();
	//get color choices
	colorString = Dialog.getString();
	colorChoices = num2array(colorString,";");
	// array of min and max values for pngtile pictures
	MontageMinString = Dialog.getString();
	MontageMinArray = num2array(MontageMinString,";");
	MontageMaxString = Dialog.getString();
	MontageMaxArray = num2array(MontageMaxString,";");
	//check if auto B&C should be used instead of fixed Min and Max Grey scale values
	autoBC = Dialog.getCheckbox();
	//get channels to show in the Merge image of the montage
	MergeString = Dialog.getString();
	MergeArray = num2array(MergeString,";");
	//check if pngtile picture should include outlines of ROIs
	pngtileROIs = Dialog.getCheckbox();
	//check if pngtile picture should include a scalebar
	ScaleBar = Dialog.getCheckbox();
	//get choice of saving the masks
	Masks = Dialog.getCheckbox();
	//get choice of saving the projections
	proj = Dialog.getCheckbox();
}

// ------------------------
// create folders and files
// ------------------------

// create directory for results in the workingDir
// define path of results folder
resDir = workingDir+ExpIdent+"_MMMEAresults_"+toString(year)+"_"+toString(month+1)+"_"+toString(dayOfMonth)+"_"+toString(hour)+"_"+toString(minute)+File.separator;
// create results folder
File.makeDirectory(resDir);

// create log file with all user defined variables
// define path to file
logFilePath = resDir+"log.csv";
//write into log file
File.append("parameter, value", logFilePath);
File.append("data of analysis,"+dayOfMonth+"/"+(month+1)+"/"+year+" "+hour+":"+minute+":"+second, logFilePath);
File.append("Script-version,"+scriptVersion,logFilePath);
File.append("Experiment Identifier,"+ExpIdent, logFilePath);
File.append("Batch mode used?,"+batch, logFilePath);
File.append("Test mode used?,"+testMode, logFilePath);
File.append("Test mode used on how many images?,"+tn, logFilePath);
File.append("Analyzed images in subfolders?,"+rec, logFilePath);
File.append("File extension,"+filetype, logFilePath);
File.append("Analysis on all Zplanes or on a single focal plane,"+allZ, logFilePath);
File.append("Channel used for Focal Plane identification,"+FocalChannel, logFilePath);
File.append("Method of nuclei segmentation used,"+seg, logFilePath);
File.append("Colocalization analysis?,"+Coloc, logFilePath);
File.append("FociCount analysis?,"+FociCount, logFilePath);
File.append("Add additionnal channel(s)?,"+AddCh, logFilePath);
File.append("Remove images with too high intensity pixels?,"+Satur, logFilePath);
File.append("Remove Background?,"+BS, logFilePath);
File.append("If remove background selected Camera background substraction method used,"+BSmethod, logFilePath);
File.append("If Fixed value substraction what is the pixel value to be substracted?,"+BSvalue, logFilePath);
File.append("If Rolling Ball BG substraction what is the pixel radius used?,"+RBradius, logFilePath);
File.append("number of channel used for ROI selection?,"+ThreshStrategy, logFilePath);
File.append("channel(s) used for the ROI segmentation?,"+ThreshChannelString, logFilePath);
File.append("use a filtered image for thresholding?,"+FilterChoice, logFilePath);
File.append("type of filter to apply,"+Filter, logFilePath);
File.append("pixel radius/sigma/value to use with the filter,"+FilterPixelRadius, logFilePath);
File.append("THRESHOLDING:thresholding method,"+ThreshMet, logFilePath);
File.append("THRESHOLDING:Whatershed?,"+wtshed, logFilePath);
File.append("THRESHOLDING:ROIs on edge should be excluded?,"+threshexclude, logFilePath);
File.append("STARDIST:path To the Stardist Model used,"+pathToStardistModel, logFilePath);
File.append("STARDIST:probability/score threshold used by Stardist,"+probThresh, logFilePath);
File.append("STARDIST:overlap threshold used by Stardist,"+overlapThresh, logFilePath);
File.append("STARDIST:ROIs on edge should be excluded?,"+starexclude, logFilePath);
File.append("ADDCH:Directry where secondary images were taken,"+SecfileDir, logFilePath);
File.append("ADDCH:number of channels in the second image for the addChannel function,"+secImageChannels, logFilePath);
File.append("ADDCH:list of channels from the second image to add in the addChannel function,"+AddChannelList, logFilePath);
File.append("ADDCH:Align the images for the addChannel function?,"+Alignment, logFilePath);
File.append("ADDCH:Align images using which method?,"+AlignmentMeth, logFilePath);
File.append("ADDCH:if alignment by pixel offset align using a X offset of?,"+Xoffset, logFilePath);
File.append("ADDCH:if alignment by pixel offset align using a y offset of?,"+Yoffset, logFilePath);
File.append("ADDCH:if alignment by registration which channel to use on the first image for the alignment function,"+Alignmentfirstchannel, logFilePath);
File.append("ADDCH:if alignment by registration which channel to use on the second image for the alignment function,"+Alignmentsecondchannel, logFilePath);
File.append("FILTERS:ROI minimal size threshold value,"+ROIminarea, logFilePath);
File.append("FILTERS:ROI maximal size threshold value,"+ROImaxarea, logFilePath);
File.append("FILTERS:filtering based on IntDen?,"+IntDenFilterChoice, logFilePath);
File.append("FILTERS:list of channels to filter based on IntDen,"+IntDenFilterChannelString, logFilePath);
File.append("FILTERS:list of mathematical operator to use to filter based on IntDen,"+IntDenFilterOperatorList, logFilePath);
File.append("FILTERS:list of thresholds to use to filter based on IntDen,"+IntDenFilterThreshList, logFilePath);
File.append("FILTERS:filtering based on CV?,"+CVFilterChoice, logFilePath);
File.append("FILTERS:list of channels to filter based on CV,"+CVFilterChannelList, logFilePath);
File.append("FILTERS:list of mathematical operator to use to filter based on CV,"+CVFilterOperatorList, logFilePath);
File.append("FILTERS:list of thresholds to use to filter based on CV,"+CVFilterThreshList, logFilePath);
File.append("FILTERS:filter out nuclei that are out of focus?,"+outofFocusROIfilterchoice, logFilePath);
File.append("FILTERS:Zdifferential value used in outofFocusROI filter,"+Zdifferential, logFilePath);
File.append("FILTERS:IntDen Z ratios threshold value,"+Ratiolimit, logFilePath);
File.append("FILTERS:channel used in outofFocusROI filter,"+outofFocusROIChannel, logFilePath);
File.append("COLOC:use whatershed in EZcolocalization,"+dows, logFilePath);
File.append("COLOC:channels to measure with EZcolocalization,"+EZChannelsString, logFilePath);
File.append("COLOC:kind of preprocessing before measure coloc. for first channel,"+EZmeth1, logFilePath);
File.append("COLOC:if mask is selected thresholding method for Channel 1,"+threshMeth1, logFilePath);
File.append("COLOC:if Find Maxima is selected prominence for Channel 1,"+prominence1, logFilePath);
File.append("COLOC:kind of preprocessing before measure coloc. for second channel,"+EZmeth2, logFilePath);
File.append("COLOC:if mask is selected thresholding method for Channel 2,"+threshMeth2, logFilePath);
File.append("COLOC:if Find Maxima is selected prominence for Channel 1,"+prominence2, logFilePath);
File.append("COLOC:measure an additionnal coloc between other channels?,"+addEZ, logFilePath);
File.append("COLOC2:channels to measure with EZcolocalization,"+EZaddChannelsString, logFilePath);
File.append("COLOC2:kind of preprocessing before measure coloc. for first channel,"+addEZmeth1, logFilePath);
File.append("COLOC2:if mask is selected thresholding method for Channel 1,"+addthreshMeth1, logFilePath);
File.append("COLOC2:if Find Maxima is selected prominence for Channel 1,"+addprominence1, logFilePath);
File.append("COLOC2:kind of preprocessing before measure coloc. for second channel,"+addEZmeth2, logFilePath);
File.append("COLOC2:if mask is selected thresholding method for Channel 2,"+addthreshMeth2, logFilePath);
File.append("COLOC2:if Find Maxima is selected prominence for Channel 1,"+addprominence2, logFilePath);
File.append("FOCICOUNT:channels to count Foci,"+cfcString, logFilePath);
File.append("FOCICOUNT:prominence(s) used in the Find Maxima Function,"+PromString, logFilePath);
File.append("SAVE:1 image saved each X image of each of the selected types?,"+saveinterval, logFilePath);
File.append("SAVE:save ROIs before applying filters?,"+ROIprezip, logFilePath);
File.append("SAVE:save ROIs after applying filters?,"+ROIpostzip, logFilePath);
File.append("SAVE:save a tiff file of processed images?,"+Tiff, logFilePath);
File.append("SAVE a tile .png image?:,"+png, logFilePath);
File.append("SAVE:channels to show in montage:,"+montageString, logFilePath);
File.append("SAVE:use grayscale only in montage?:,"+Grayscale, logFilePath);
File.append("SAVE:order of color choices matching the order of channels,"+colorString, logFilePath);
File.append("SAVE:min values of the channels histograms,"+MontageMinString, logFilePath);
File.append("SAVE:max values of the channels histograms,"+MontageMaxString, logFilePath);
File.append("SAVE:use auto B&C instead of fixed min and max values?,"+autoBC, logFilePath);
File.append("SAVE:channels to show in the Merge image of the montage,"+montageString, logFilePath);
File.append("SAVE:include outlines of ROIs in the .png?,"+pngtileROIs, logFilePath);
File.append("SAVE:include a scalebar in the .png?,"+ScaleBar, logFilePath);
File.append("SAVE:save the coloc. channels?,"+Masks, logFilePath);
File.append("SAVE:save the projection?,"+proj, logFilePath);

//create a ROIzip folder to save ROIs in the resDir
ROIzipDir = resDir+"ROI"+File.separator;
File.makeDirectory(ROIzipDir);

// create results.txt to save results in the resDir
resultsFilePath = resDir+ExpIdent+"_MMMEAresults.txt";

if(ROIprezip) {
	// create a ROIprezip folder within the ResDir to save ROIs before applying filters if option selected
	ROIprezipDir = resDir+"ROI_pre_filters"+File.separator;
	File.makeDirectory(ROIprezipDir);
}

if(ROIpostzip) {
	// create a ROIpostzip folder within the ResDir to save ROIs after applying filters if option selected
	ROIpostzipDir = resDir+"ROI_post_filters"+File.separator;
	File.makeDirectory(ROIpostzipDir);
}

if(Coloc) {
	if (Masks) {
		// create a MaskImage folder within the ResDir to save the masks used in EZcolocalization if option selected
		MaskImageDir = resDir+"EZcolocalization_Masks"+File.separator;
		File.makeDirectory(MaskImageDir);
	} else {
		//The variable need to exist for the EZcolocalization function
		MaskImageDir ="";
	}
}

if (Tiff) {
	// create a Tiff folder within the ResDir to save a tiff version of the image containing the background substraction (if selected), added channels (if selected)
	TiffDir = resDir+"Tiff"+File.separator;
	File.makeDirectory(TiffDir);
}

if (png) {
	// create a pngtilepicture folder within the ResDir if option selected
	pngDir = resDir+"png_Tile_Picture"+File.separator;
	File.makeDirectory(pngDir);
}

if (allZ != "all Z") {
	if (allZ != "focal plane") {
		if (proj) {
			// create a projection folder within the ResDir if option selected
			projDir = resDir+"projection_tiff"+File.separator;
			File.makeDirectory(projDir);
		}
	}
}

// -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ---START---START---START---START---START---START---START---START---START---START---START---START---START---START---START---START---START---START---START---START---START---START---
// -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// toggle batch mode
if (batch) {
	setBatchMode(true);
} else {
	setBatchMode(false);
}

// toggle test mode
// if active, set number of files that will be processed to pre-set variable: tn
if (testMode) {
	// if tn is smaller than actual number of files set numberOfFiles to tn
	//activate testmode
	if (tn < filePaths.length) {
		numberOfFiles = tn;
	// if tn is bigger than the actual number of files set numberOfFiles to the actual number of files
	//ignore testmode
	} else {
		numberOfFiles = filePaths.length;
	}
	//if testmode is not selected,
	//set numberOfFiles to the actual number of files
} else {
	numberOfFiles = filePaths.length;
}

// get the starting time to calculate total running time at the end of the script
t1 = getTime();
//duplicate the numberOfFiles variable in another variable
//redundant but useful for correcting the number of files to process when working with .lif files (because they have series)
timeNumber = numberOfFiles;
//initialize imagecount, it counts the number of images processed. It is used to calculate total running time at the end of the script
imagecount = 0;


// --------------------------
// open image, start the loop
// --------------------------

// per file:
for (k = 0; k < numberOfFiles; k++) {

	// close all open images, just in case
	close("*");
	roiManager("reset");

	//to save images each X images, we need to determine if the current image is the X image
	//to do so, divide the image number by X
	saveintervalratio = (imagecount+1)/saveinterval;
	//then we need the closest integer of this value.
	saveintervalinteger = parseInt(saveintervalratio);
	//If the image is the Xth image. saveintervalratio will be equal to saveintervalinteger
	//if this image is the Xth image, save the selected images
	if (saveintervalratio == saveintervalinteger) {
		imgSave = 1;
	} else {
		imgSave = 0;
	}

	//check if there are spaces in the filePath[k] and replaces the spaces by underscore
	if (indexOf(filePaths[k], " ") >= 0) {
		file2 = replace(filePaths[k], " ", "_");
		File.rename(filePaths[k], file2);
		filePaths[k] = file2;
	}

	// get filename (what is between the last file separator of the path and the file extension)
	index1 = lastIndexOf(filePaths[k], File.separator);
	index2 = lastIndexOf(filePaths[k], filetype);
	fileName = substring(filePaths[k], index1+1,index2 );

	//.lif files are handled in a specific way because an image file may contain several images in the form of series
	if (filetype == ".lif") {
		//Get the number of series in the image
		Ext.setId(filePaths[k]);
		Ext.getSeriesCount(seriesCount);
   		sCount=seriesCount;
   		//at the first .lif image file processed, adjust the number of files used to calculate time to take in consideration series
   		//it takes in consideration that all .ims files have the same amount of series
   		//if the number of series per .lif file is different, it will get corrected later
   		if (k == 0) {
   			timeNumber = numberOfFiles * sCount;
   			//for the first .lif file, there is no previoussCount, so make previoussCount = sCount
   			//previous sCount is used to correct the number of files to be analyzed in the case that each .lif file dont have the same amount of series
   			previoussCount = sCount;
   		}

   		//if the number of series of the new .lif file is different from the previous one
   		if (sCount != previoussCount) {
			//correct the estimated number of images to be processed
   			timecorrection = sCount - previoussCount;
   			timeNumber = timeNumber + timecorrection;
   			//overwrite the previoussCount variable
   			previoussCount = sCount;
   		}
   	}

	//If the filetype is not .lif, use sCount=1 to open only first serie
   	if (filetype != ".lif"){
   		//sCount=1 will make it open only the first serie
		sCount = 1;
		//duplicate the fileName variable
		//The script works with the imgName variable
		//we need to have those two variables to be able to handle .lif files who have series
		imgName = fileName;
   	}

   	// open file using bio-formats and split channels (supposed to help with memory leakage)
   	// for .lif, loop through the series, for other filetypes, open only first serie
   	for (p = 1; p <= sCount; p++) {
		run("Bio-Formats", "open="+filePaths[k]+" autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT series_"+p);
		if (filetype == ".lif") {
			Ext.setSeries(p-1);
	   		Ext.getSeriesName(seriesName);
   			serie = seriesName;
			imgName = fileName+"_"+serie;
			imgName = replace(imgName, "/", "_");
		}

		//merge the channels back into a hyperstack
		//by creating a string that extend itself by looping through the opened images
		options = "";
		//for all opened images, in a loop, select them, rename them in order C-1, C-2, etc.,
		for (j = 0; j < nImages; j++) {
   			selectImage(j+1);
  			rename("C-" + (j+1));
  			//ids is the name of the image
  			ids = getTitle();
  			//b is the number (1,2,3,etc.)
  			b = j+1;
  			//extend the loop that will say c1=C-1 c2=C-2 etc...)
  			options = options+"c"+b+"="+ids+" ";
		}
		//add "create at the end of the option loop that will be used to merge all channels
		options = options+"create";
		//merge all channels
		run("Merge Channels...", options);
		Stack.setDisplayMode("color");
		rename("Hyperstack");
		getDimensions(width, height, channels, slices, frames);
		//get the number of channels in the image and create an array of the channels
		chNumb = channels;
		channelsArray = Array.getSequence(chNumb+1);
		channelsArray = Array.deleteValue(channelsArray, 0);
		//get the number of Zplane
		ZplaneNumber = slices;

		//hide the Results table off screen
		if (imagecount == 0) {
			run("Measure");
			selectWindow("Results");
			Table.setLocationAndSize((screenWidth+100), (screenHeight+100), 500, 200);
		}
		//Table.setLocationAndSize(100, 100, 500, 200);

// ------------------------
// find plain in best focus
// ------------------------

		//to work on a single Z plane
		if (allZ == "focal plane") {

			if (AddCh) {
				//if channels need to be added to the stack and
				//if the channel used to find focal plane is in the secondary image, open this image and use it to identify focal plane
				if (FocalChannel > chNumb) {
						//identify which channel to use in the secondary image
						FocalChannel = parseInt(FocalChannel);
						NewFocalChannel = FocalChannel-chNumb;
						FocalChannel = NewFocalChannel;
						//open secondary image
						run("Bio-Formats", "open="+SecfilePaths[k]+" autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_p");
						rename("Hyperstack-2");
						selectWindow("Hyperstack-2");
						//use user define channel to search for best focus plane based on highest variance focal plane
						nFocus = find_focus_plane(FocalChannel);
						selectWindow("Hyperstack-2");
						close();
				}
			}

			//use user define channel to search for best focus plane based on highest variance focal plane
			nFocus = find_focus_plane(FocalChannel);
			// copy slice in best focus
			//nFocus is the slice number of best focused slice
			selectWindow("Hyperstack");
			run("Duplicate...", "title=nFocus duplicate slices="+nFocus);

		} else {

			//to work on all Z, duplicate Hyperstack and name it nFocus to allow the script to work on the stack
			selectWindow("Hyperstack");
			run("Duplicate...", "title=nFocus duplicate");
			//give a value to the nFocus parameter
			//this number is useless but some functions need this variable so we create a useless one
			nFocus = 1;
		}

		//to work on a projection, this would be done later in the macro, after background substraction

// -----------------------
// add additional channels
// -----------------------

		//to add channels from a different image
		//possibility to align the added channels

		//NoReg is 0, if the function was not able to align channels, NoReg will be 1.
		NoReg = 0;
		if(AddCh) {
			NoReg = AddChannel(SecfilePaths[k],Alignmentfirstchannel,Alignmentsecondchannel,AddImageChannelArray,AddChannelList,channelsArray,secImageChannels,ZplaneNumber,Alignment,AlignmentMeth,Xoffset,Yoffset);
			//correct the numbers of channels
			//adjust the array of channels with the number of channels in the images after the addChannel function
			NewChannels = chNumb + AddImageChannelArray.length;
			NewChannelsArray = Array.getSequence(NewChannels+1);
			NewChannelsArray = Array.deleteValue(NewChannelsArray, 0);
			chNumb = NewChannels;
			//keep the information of "channelsArray" into a new variable
			//needed for the reassignment of Zplanes to ROIs in the "Save ROIs pre filters", "Save ROIs post filters", and in the "Save ROIs" of the EZ function
			OriginalChannelsArray = channelsArray;
			channelsArray = NewChannelsArray;
		}
		//duplicate the "channelsArray" in "OriginalChannelsArray"
		//to make the "Save ROIs pre filters", "Save ROIs post filters", and in the "Save ROIs" of the EZ function consistent with or without the AddCh function
		OriginalChannelsArray = channelsArray;
		//if the function was not able to align channels, take note of it in the log.csv file and skip the image
		if (NoReg > 0) {
			File.append(imgName+" unable to align channels by registration", logFilePath);
		} else {

// ----------------------------------
// Remove image with high intensity pixels
// ----------------------------------

			//Too high intensity pixels can influence the thresholding of the images, leading to the loss of low intensity pixels
			//Removing images with too high intensity pixels remove artefacts due to incorrect thresholding
			//the function remove images that have pixels above the 3/4 of the maximal image pixel depth
			//3/4 of the max pixel depth is an arbitrary threshold

			//sat variable is set at 0, the function will make sat=1 if it identify high intensity pixels
			sat = 0;
			//if option selected, run the function
			if (Satur) {
				sat = SaturRemov();
			}
			//if there is high intensity pixels, note the image in the log.csv and skip the image
			if (sat > 0) {
				File.append(imgName+" removed from analysis because of too high intensity pixels", logFilePath);
			} else {

// -----------------------------------------------
// substract modal value of each Z of each channel
// -----------------------------------------------

				//Remove the background noise of the camera if option selected
				if (BS) {
					modalSub(BSmethod,BSvalue,RBradius);
				}


// -----------------------------------------------
// projections
// -----------------------------------------------

				//to work on a projection
				if (allZ == "max proj") {
					//proj value is used to identify if a projection of any kind has been used. proj value used in the "Standardize ROI names" section
					pr = 1;
					selectWindow("nFocus");
					close();
					selectWindow("Hyperstack");
					run("Z Project...", "projection=[Max Intensity]");					
					rename("nFocus");
					nFocus = 1;
					if (proj) {
						// save projection image
						run("Duplicate...", "duplicate");
						saveAs("Tiff", projDir+imgName+"_projection.tiff");
						close();
					}
				}

				if (allZ == "sum proj") {
					//proj value is used to identify if a projection of any kind has been used. proj value used in the "Standardize ROI names" section
					pr = 1;
					selectWindow("nFocus");
					close();
					selectWindow("Hyperstack");
					run("Z Project...", "projection=[Sum Slices]");
					rename("nFocus");
					nFocus = 1;
					if (proj) {
						// save projection image
						saveAs("Tiff", projDir+imgName+"_projection.tiff");
						close();
					}
				}

				if (allZ == "mean proj") {
					//proj value is used to identify if a projection of any kind has been used. proj value used in the "Standardize ROI names" section
					pr = 1;
					selectWindow("nFocus");
					close();
					selectWindow("Hyperstack");
					run("Z Project...", "projection=[Average Intensity]");
					rename("nFocus");
					nFocus = 1;
					if (proj) {
						// save projection image
						saveAs("Tiff", projDir+imgName+"_projection.tiff");
						close();
					}
				}

				if (allZ == "SD proj") {
					//proj value is used to identify if a projection of any kind has been used. proj value used in the "Standardize ROI names" section
					pr = 1;
					selectWindow("nFocus");
					close();
					selectWindow("Hyperstack");
					run("Z Project...", "projection=[Standard Deviation]");
					rename("nFocus");
					nFocus = 1;
					if (proj) {
						// save projection image
						saveAs("Tiff", projDir+imgName+"_projection.tiff");
						close();
					}
				}

				if (allZ == "median proj") {
					//proj value is used to identify if a projection of any kind has been used. proj value used in the "Standardize ROI names" section
					pr = 1;
					selectWindow("nFocus");
					close();
					selectWindow("Hyperstack");
					run("Z Project...", "projection=[Median]");
					rename("nFocus");
					nFocus = 1;
					if (proj) {
						// save projection image
						saveAs("Tiff", projDir+imgName+"_projection.tiff");
						close();
					}
				}

// ----------------------------------
// Select Channel(s) for Segmentation
// ----------------------------------

				//choice of segmenting on a single nuclei staining channel or on an artificial channel maded by addind the signals from 2 channels to mimic a nuclei staining channel
				//if segmenting using a single channel (normal way)
				if (ThreshStrategy == "one"){
					//extract the channel needed for segmentation
					selectWindow("nFocus");
					for (j = 0; j < ThreshChannelArray.length; j++) {
						selectWindow("nFocus");
						run("Duplicate...", "title=SegCh duplicate channels="+ThreshChannelArray[j]);
					}

				//if segmenting using more than one channel (to mimic a nuclei dye)
				} else {
					//extract the channels needed for segmentation
					for (j = 0; j < ThreshChannelArray.length; j++) {
						selectWindow("nFocus");
						run("Duplicate...", "title="+j+" duplicate channels="+ThreshChannelArray[j]);
					}
					//make an artificial channel by adding the two images
					imageCalculator("Add create stack", "0","1");
					selectWindow("Result of 0");
					rename("SegCh");

					//close unnecessary images
					selectWindow("0");
					close();
					selectWindow("1");
					close();
				}

// ---------------------------------
// Apply Filters before Segmentation
// ---------------------------------

				//prior to segmentation, pre filter the segmentation channels to facilitate segmentation
				if (FilterChoice) {
					//different filters have different words used in their commandline. save this info in the "a" variable
					if (Filter == "Median") {
						a = "radius";
					}
					if (Filter == "Gaussian Blur") {
						a = "sigma";
					}
					if (Filter == "Gamma") {
						a = "value";
					}
					run(Filter+"...", a+"="+FilterPixelRadius+" stack");
				}

// -----------------
// Segment Nuclei...
// -----------------

				// reset ROI manager, just in case
				roiManager("reset");
				// select segCh
				selectWindow("SegCh");

// -----------------
//...by thresholding
// -----------------

				// check if segmentation by thresholding was chosen
				if (seg == "Thresholding"){
					// define ROIs by thresholding
					def_ROI_by_thresholding(ThreshMet, wtshed, threshexclude);
				}

// --------------
// ...by stardist
// --------------

				// check if segmentation by Stardist was chosen
				if (seg == "StarDist"){
					// define ROIs using stardist
					stardist(probThresh, overlapThresh, pathToStardistModel, starexclude);
				}

// ---------------------------------
// verify if there is at least 1 ROI
// ---------------------------------

				run("Select None");
				nROIs = roiManager("count");

				//if no ROIs were detected, take note of the image in the log.-csv file and skip the image
				if (nROIs == 0){
					File.append(imgName+" removed from analysis, no ROI detected", logFilePath);
				} else {

// --------------------
// save ROIs pre-filter
// --------------------

					run("Select None");
					//if the option was selected, save an image of the ROIs and save the ROI.zip file to access the ROI manager
					//useful to troubleshoot filtering
					if(ROIprezip) {
						if (imgSave == 1) {
							if (allZ == "focal plane") {
								// ROIs are assign on the nFocus image (not the Zstack), as such, they lose the information of which Zplane they are from
								//reassign Zplane value to the ROIs and save the ROIs
								nROIs = roiManager("count");
								selectImage("Hyperstack");
								run("Select None");
								for (i = nROIs-1; i >= 0; i--) {
									roiManager("Select", i);
									//assign nFocus as the Z position of the ROIs
									run("Properties... ", "position=1,"+nFocus+",1");
									//save the ROImanager pre-filter
									roiManager("Save", ROIprezipDir+imgName+"_plane"+nFocus+"_RoiSet.zip");
									run("Select None");
								}
								//save ROIs as an image in which each ROIs have a different colors
								coloredROIimage();
								selectWindow("labels");
								// save ROI image
								saveAs("Tiff", ROIprezipDir+imgName+".tiff");
								close();
							} else {
								//if working with a stack or a projection, no need to reassign Zplanes, just save the ROImanager
								roiManager("Save", ROIprezipDir+imgName+"_RoiSet.zip");
							}
						}
					}

// ---------------------
// apply filters on ROIs
// ---------------------

					run("Select None");
					nROIs = roiManager("count");
						if (nROIs >= 1){
							run("Select None");
							ROIsizefilter(ROIminarea, ROImaxarea);
						}

					
					if (IntDenFilterChoice) {
						run("Select None");
						nROIs = roiManager("count");
						if (nROIs >= 1){
							IntDenfilter(IntDenFilterChannelArray, IntDenFilterOperatorList, IntDenFilterThreshArray);
							}
					}


					if (CVFilterChoice) {
						run("Select None");
						nROIs = roiManager("count");
						if (nROIs >= 1){
							CVfilter(CVFilterChannelArray, CVFilterOperatorList, CVFilterThreshArray);
						}
					}

					if (outofFocusROIfilterchoice) {
						run("Select None");
						nROIs = roiManager("count");
						if (nROIs >= 1){
							//Remove the background noise of the camera if option selected
							if (BS) {
								selectWindow("Hyperstack");
								run("Select None");
								modalSub(BSmethod,BSvalue,RBradius);
							}
							ROIZpositionfilter(outofFocusROIChannel, nFocus, Zdifferential, Ratiolimit, ZplaneNumber);
						}
					}

					//if no ROI left, note it in the log.csv file and skip the image
					nROIs = roiManager("count");
					if (nROIs == 0){
						File.append(imgName+" removed from analysis, no ROI after filtering", logFilePath);
					} else {

// ----------------------
// save ROIs post-filters
// ----------------------

						if(ROIpostzip) {
							run("Select None");
							if (imgSave == 1) {
								if (allZ == "focal plane") {
									// ROIs are assign on nFocus, as such, they lose the information of which Zplane they are from
									//reassign Zplane value to the ROIs and save the ROIs
									nROIs = roiManager("count");
									selectImage("Hyperstack");
									run("Select None");
									for (i = nROIs-1; i >= 0; i--) {
										roiManager("Select", i);
										//assign nFocus as the Z position of the ROIs
										run("Properties... ", "position=1,"+nFocus+",1");
										//save the ROImanager post-filter
										roiManager("Save", ROIpostzipDir+imgName+"_plane"+nFocus+"_RoiSet.zip");
										run("Select None");
									}
									//save ROIs as an image in which each ROI have a different color
									coloredROIimage();
									selectWindow("labels");
									// save ROI image
									saveAs("Tiff", ROIpostzipDir+imgName+".tiff");
									close();
								} else {
									//if working with a stack or a projection, no need to reassign Zplanes, just save the ROImanager
									roiManager("Save", ROIpostzipDir+imgName+"_RoiSet.zip");
								}
							}
						}


// ---------------------------------------------------
// measure colocalization with EZcolocalization plugin
// ---------------------------------------------------

						if (Coloc) {
							//set global scaling. need it to use ROImanager for cell identification input in EZ colocalization
							run("Properties...", "global");

							nROIs = roiManager("count");
							if (nROIs>=1){
								EZ(ch1, ch2, EZmeth1, threshMeth1, prominence1, EZmeth2, threshMeth2, prominence2, Masks, MaskImageDir, imgName, dows, ROIminarea, ROImaxarea, ExpIdent, logFilePath, imgSave);
							}

							if (addEZ == 1) {
								secEZ(addch1, addch2, addEZmeth1, addthreshMeth1, addprominence1, addEZmeth2, addthreshMeth2, addprominence2, Masks, MaskImageDir, imgName, dows, ROIminarea, ROImaxarea, ExpIdent, logFilePath, imgSave);
							}
						}

// -----------------------------------------------------------------------------
// Standardize ROI names (important because EZcolocalization modifies ROI names)
// -----------------------------------------------------------------------------

						nROIs = roiManager("count");
						if (nROIs>=1) {
							if (Coloc) {

								//EZcolocalization already renamed ROIs with the following nomenclature
								//image 1: cell 1
								//image numbers refers to the Zplane
								//cell numbers refers to the numbering of the ROIs on that Zplane
								//keep this numenclature

							//else, convert the ROI list to match this nomenclature to allow standardization and cross analysis
							} else {

								//if using a Z projection, use a Zplane value of 1 by default and just number the cells
								if (pr == 1) {
									//initialize the cell numbering at 0
									cell = 0;
									for (i = 0; i < nROIs; i ++) {
										cell = cell + 1;
										roiManager("Select", i);
										roiManager("Rename", "image 1: cell "+cell);					
									}
										
								} else {
									
									//Get the Zplane of the first ROI to track changes in Z planes to be able to change the "image" number in the ROI naming
									roiManager("Select", 0);
									roiManager("Measure");
									PreviousSlice = getResult("Slice");
									//initialize the cell numbering at 0
									cell = 0;
	
									for (i = 0; i < nROIs; i ++) {
										//Get the Zplane of the ROI
										roiManager("Select", i);
										roiManager("Measure");
										Slice = getResult("Slice");
										//if the Zplane is the same as the previous ROI, add 1 to the cell number,
										//if not, reinitialize the cell numbering at 1 and actualize the PreviousSlice parameter
										if (Slice == PreviousSlice) {
											cell = cell + 1;
										} else {
											PreviousSlice = Slice;
											cell = 1;
										}

										roiManager("Rename", "image "+Slice+": cell "+cell);
									}
								}
							}

							if (allZ == "focal plane") {

								// ROIs are assign on nFocus, as such, they lose the information of which Zplane they are from
								//reassign Zplane value to the ROIs and save the ROIs
								selectImage("Hyperstack");
								for (i = nROIs-1; i >= 0; i--) {
									roiManager("Select", i);

									//assign nFocus as the Z position of the ROIs
									run("Properties... ", "position=1,"+nFocus+",1");
								}
							}

							//save the ROImanager
							roiManager("Save", ROIzipDir+imgName+"_RoiSet.zip");

// ------------------------------------
// Measure standard parameters per ROIs
// ------------------------------------

							//The headline of the result file cannot be created before the first image is opened to get the number of channels (in case channels are added)
							//for that reason the headline is created here and not in the "create folders and files" part of the code.
							//To create the headline only once, count the number of time the code loop through this part and create the headline only the first time
							if (loopcount == 0) {
								// open results.txt
								results = File.open(resultsFilePath);
								// construct headline for results.txt
								// add columns for size and position of ROIs
								headline = "ExperimentID,Image,ROIname,Z,ROI,area,Xcentroid,Ycentroid,XcenterOfMass,YcenterOfMass,Perimeter,XBoundingRectangle,YBoundingRectangle,FitEllipse_Width,FitEllipse_Height,FeretDiameter,Roundness,Solidity";

								//add columns for fluorescence measurements per channel
								for ( j = 0; j < channelsArray.length; j++) {
									headline = headline+",c"+channelsArray[j]+"_mean"+",c"+channelsArray[j]+"_SD"+",c"+channelsArray[j]+"_median"+",c"+channelsArray[j]+"_mode"+",c"+channelsArray[j]+"_min"+",c"+channelsArray[j]+"_max"+",c"+channelsArray[j]+"_IntDen"+",c"+channelsArray[j]+"_skewness"+",c"+channelsArray[j]+"_kurtosis";
								}

								if (FociCount) {
									// add columns for foci count per channel
									for ( j = 0; j < cfcArray.length; j++) {
										headline = headline+",c"+cfcArray[j]+"_FociCount";
									}
								}

								if (Coloc) {
									// add columns for Coloc Measurment
									headline = headline+",c"+ch1+"_c"+ch2+"_TOS(linear)"+",c"+ch1+"_c"+ch2+"_TOS(log2)"+",c"+ch1+"_c"+ch2+"_PCC"+",c"+ch1+"_c"+ch2+"_SRCC"+",c"+ch1+"_c"+ch2+"_ICQ"+",c"+ch1+"_c"+ch2+"_M1"+",c"+ch1+"_c"+ch2+"_M2";
									headline = headline+",c"+ch2+"_c"+ch1+"_TOS(linear)"+",c"+ch2+"_c"+ch1+"_TOS(log2)"+",c"+ch2+"_c"+ch1+"_PCC"+",c"+ch2+"_c"+ch1+"_SRCC"+",c"+ch2+"_c"+ch1+"_ICQ"+",c"+ch2+"_c"+ch1+"_M1"+",c"+ch2+"_c"+ch1+"_M2";
									if (addEZ) {
										headline = headline+",c"+addch1+"_c"+addch2+"_TOS(linear)"+",c"+addch1+"_c"+addch2+"_TOS(log2)"+",c"+addch1+"_c"+addch2+"_PCC"+",c"+addch1+"_c"+addch2+"_SRCC"+",c"+addch1+"_c"+addch2+"_ICQ"+",c"+addch1+"_c"+addch2+"_M1"+",c"+addch1+"_c"+addch2+"_M2";
										headline = headline+",c"+addch2+"_c"+addch1+"_TOS(linear)"+",c"+addch2+"_c"+addch1+"_TOS(log2)"+",c"+addch2+"_c"+addch1+"_PCC"+",c"+addch2+"_c"+addch1+"_SRCC"+",c"+addch2+"_c"+addch1+"_ICQ"+",c"+addch2+"_c"+addch1+"_M1"+",c"+addch2+"_c"+addch1+"_M2";
									}
								}

								//write headline into results.txt
								print(results,headline);
								//close results file
								File.close(results);
							}
							loopcount = loopcount +1;


							//redundant with how testMode works but in case of working with .lif with series, it will stop the script after "tn" series and not "tn" image file
							if (testMode) {
								if (loopcount == tn) {
									print("testMode finished");
									exit;
								}
							}

							selectWindow("nFocus");
							// count number of ROIs listed in ROI manager
							nROIs = roiManager("count");
							//initialize arrays for each fluorescence measured parameter
							MeanArray = newArray(channelsArray.length);
							SDArray = newArray(channelsArray.length);
							MedianArray = newArray(channelsArray.length);
							ModeArray = newArray(channelsArray.length);
							minArray = newArray(channelsArray.length);
							maxArray = newArray(channelsArray.length);
							IntDenArray = newArray(channelsArray.length);
							skewnessArray = newArray(channelsArray.length);
							kurtosisArray = newArray(channelsArray.length);
							//initialize arrays for Foci Count parameter
							if (FociCount) {
								FociArray = newArray(cfcArray.length);
							}

							// get the parameters for each ROI:
							for (i = 0; i < nROIs; i ++) {
								// select ROI
								roiManager("select", i);

								if (allZ == "All Z") {
									//Isolate Zplane and ROI number from the ROI name
									ROIName = Roi.getName;
									sep = indexOf(ROIName, ":");
									Z = substring(ROIName, 5, sep);
									sep = sep+6;
									C = substring(ROIName, sep);
								//when working in a single Z file, the Z plane in the file name is always 1, get the Zplane from the nFocus variable instead
								} else {
									//Isolate Zplane and ROI number from the ROI name
									ROIName = Roi.getName;
									sep = indexOf(ROIName, ":");
									sep = sep+6;
									C = substring(ROIName, sep);
									Z = nFocus;
								}

								// clear Results window
								run("Clear Results");
								// measure
								roiManager("Measure");

								// get the ROI size and position results
								Slice = getResult("Slice");
								Area = getResult("Area");
								Xcentroid = getResult("X");
								Ycentroid = getResult("Y");
								XcenterOfMass = getResult("XM");
								YcenterOfMass = getResult("YM");
								Perimeter = getResult("Perim.");
								XBoundingRectangle = getResult("BX");
								YBoundingRectangle = getResult("BY");
								FitEllipse_Width = getResult("Width");
								FitEllipse_Height = getResult("Height");
								FeretDiameter = getResult("Feret");
								Roundness = getResult("Round");
								Solidity = getResult("Solidity");

								// clear Results window
								run("Clear Results");

								//get the fluorescence results
								// per selected channel:
								for (j = 0; j < channelsArray.length; j++) {
									// select channel
									Stack.setChannel(channelsArray[j]);

									// clear Results window
									run("Clear Results");
									// measure
									run("Measure");

									// get results and save in arrays
									MeanArray[j] = getResult("Mean");
									SDArray[j] = getResult("StdDev");
									MedianArray[j] = getResult("Median");
									ModeArray[j] = getResult("Mode");
									minArray[j] = getResult("Min");
									maxArray[j] = getResult("Max");
									IntDenArray[j] = getResult("IntDen");
									skewnessArray[j] = getResult("Skew");
									kurtosisArray[j] = getResult("Kurt");
								}

// -----------------------------------------
// count Foci using the 'Maxima Finder' tool
// -----------------------------------------

								if (FociCount) {
									// initialize array that will hold foci count measurements
									resFociArray = newArray(cfcArray.length);

									// per selected channel:
									for (j = 0; j < cfcArray.length; j++) {
										// select channel
										Stack.setChannel(cfcArray[j]);
										// clear Results window
										run("Clear Results");
										// count maxima within roi (foci)
										run("Find Maxima...", "prominence="+PromArray[j]+" output=[Count]");

										// get results and save in arrays
										FociArray[j] = getResult("Count");
									}
								}

// -----------------------------
// save Coloc results in strings
// -----------------------------

								//results are extracted from the generated result windows by EZcolocalization
								if (Coloc) {
									if (Table.size(ExpIdent+"_ch1ch2") >=1) {
										selectWindow(ExpIdent+"_ch1ch2");
										ch1ch2TOSlin = Table.getString("TOS(linear)", i);
										ch1ch2TOSlog = Table.getString("TOS(log2)", i);
										ch1ch2PCC = Table.getString("PCC", i);
										ch1ch2SRCC = Table.getString("SRCC", i);
										ch1ch2ICQ = Table.getString("ICQ", i);
										ch1ch2M1 = Table.getString("M1", i);
										ch1ch2M2 = Table.getString("M2", i);
									} else {
										ch1ch2TOSlin = "NA";
										ch1ch2TOSlog = "NA";
										ch1ch2PCC = "NA";
										ch1ch2SRCC = "NA";
										ch1ch2ICQ = "NA";
										ch1ch2M1 = "NA";
										ch1ch2M2 = "NA";
									}

									if (Table.size(ExpIdent+"_ch2ch1") >=1) {
										selectWindow(ExpIdent+"_ch2ch1");
										ch2ch1TOSlin = Table.getString("TOS(linear)", i);
										ch2ch1TOSlog = Table.getString("TOS(log2)", i);
										ch2ch1PCC = Table.getString("PCC", i);
										ch2ch1SRCC = Table.getString("SRCC", i);
										ch2ch1ICQ = Table.getString("ICQ", i);
										ch2ch1M1 = Table.getString("M1", i);
										ch2ch1M2 = Table.getString("M2", i);
									} else {
										ch2ch1TOSlin = "NA";
										ch2ch1TOSlog = "NA";
										ch2ch1PCC = "NA";
										ch2ch1SRCC = "NA";
										ch2ch1ICQ = "NA";
										ch2ch1M1 = "NA";
										ch2ch1M2 = "NA";
									}

									if (addEZ) {

										if (Table.size(ExpIdent+"_addch1addch2") >=1) {
											selectWindow(ExpIdent+"_addch1addch2");
											addch1addch2TOSlin = Table.getString("TOS(linear)", i);
											addch1addch2TOSlog = Table.getString("TOS(log2)", i);
											addch1addch2PCC = Table.getString("PCC", i);
											addch1addch2SRCC = Table.getString("SRCC", i);
											addch1addch2ICQ = Table.getString("ICQ", i);
											addch1addch2M1 = Table.getString("M1", i);
											addch1addch2M2 = Table.getString("M2", i);
										} else {
											addch1addch2TOSlin = "NA";
											addch1addch2TOSlog = "NA";
											addch1addch2PCC = "NA";
											addch1addch2SRCC = "NA";
											addch1addch2ICQ = "NA";
											addch1addch2M1 = "NA";
											addch1addch2M2 = "NA";
										}

										if (Table.size(ExpIdent+"_addch2addch1") >=1) {
											selectWindow(ExpIdent+"_addch2addch1");
											addch2addch1TOSlin = Table.getString("TOS(linear)", i);
											addch2addch1TOSlog = Table.getString("TOS(log2)", i);
											addch2addch1PCC = Table.getString("PCC", i);
											addch2addch1SRCC = Table.getString("SRCC", i);
											addch2addch1ICQ = Table.getString("ICQ", i);
											addch2addch1M1 = Table.getString("M1", i);
											addch2addch1M2 = Table.getString("M2", i);
										} else {
											addch2addch1TOSlin = "NA";
											addch2addch1TOSlog = "NA";
											addch2addch1PCC = "NA";
											addch2addch1SRCC = "NA";
											addch2addch1ICQ = "NA";
											addch2addch1M1 = "NA";
											addch2addch1M2 = "NA";
										}
									}
								}

// ----------------------
// write into results.txt
// ----------------------

								// build a string containing the shape parameters of the current analyzed ROI
								resString1 = "";
								resString1 = resString1+","+Area+","+Xcentroid+","+Ycentroid+","+XcenterOfMass+","+YcenterOfMass+","+Perimeter+","+XBoundingRectangle+","+YBoundingRectangle+","+FitEllipse_Width+","+FitEllipse_Height+","+FeretDiameter+","+Roundness+","+Solidity;

								// build a string containing the Fluorescence parameters of the current analyzed ROI
								resString2 = "";
								for ( j = 0; j < MeanArray.length; j++) {
					 		   		//resString = resString+","+AreaArray[j]+","+XcentroidArray[j]+","+YcentroidArray[j]+","+XcenterArray[j]+","+YcenterArray[j]+","+Perimeter[j]+","+XBoundingRectangle[j]+","+YBoundingRectangle[j]+","+FitEllipse_Width[j]+","+FitEllipse_Height[j]+","+FeretDiameter[j];
									resString2 = resString2+","+MeanArray[j]+","+SDArray[j]+","+MedianArray[j]+","+ModeArray[j]+","+minArray[j]+","+maxArray[j]+","+IntDenArray[j]+","+skewnessArray[j]+","+kurtosisArray[j];
								}

								//concatenate shape and fluorescence strings
								resString = "";
								resString = resString+resString1+resString2;

								if (FociCount) {
									// build a string containing the FociCount parameters of the current analyzed ROI
									for ( j = 0; j < resFociArray.length; j++) {
										resString3 = "";
										resString3 = resString3+","+FociArray[j];
										//concatenate FociCount parameters with resString
										resString = resString+resString3;
									}
								}
								if (Coloc) {
									// build a string containing the Coloc parameters of the current analyzed ROI
									resString4 = "";
									resString4 = resString4+","+ch1ch2TOSlin+","+ch1ch2TOSlog+","+ch1ch2PCC+","+ch1ch2SRCC+","+ch1ch2ICQ+","+ch1ch2M1+","+ch1ch2M2;
									resString4 = resString4+","+ch2ch1TOSlin+","+ch2ch1TOSlog+","+ch2ch1PCC+","+ch2ch1SRCC+","+ch2ch1ICQ+","+ch2ch1M1+","+ch2ch1M2;
									if (addEZ) {
										//add to the coloc string the results from the additionnal Coloc analysis
										resString4 = resString4+","+addch1addch2TOSlin+","+addch1addch2TOSlog+","+addch1addch2PCC+","+addch1addch2SRCC+","+addch1addch2ICQ+","+addch1addch2M1+","+addch1addch2M2;
										resString4 = resString4+","+addch2addch1TOSlin+","+addch2addch1TOSlog+","+addch2addch1PCC+","+addch2addch1SRCC+","+addch2addch1ICQ+","+addch2addch1M1+","+addch2addch1M2;
									}
									//concatenate Coloc parameters with resString
									resString = resString+resString4;
								}

								// append measurements to results.txt
								File.append(ExpIdent+","+imgName+","+ROIName+","+Z+","+C+resString, resultsFilePath);
							}
						}


						//close unnecessary windows
						if (Coloc) {
							if(isOpen(ExpIdent+"_ch1ch2")){
								selectWindow(ExpIdent+"_ch1ch2");
								wait(100);
								run("Close");
							}
							if(isOpen(ExpIdent+"_ch2ch1")){
								selectWindow(ExpIdent+"_ch2ch1");
								wait(100);
								run("Close");
							}
							if (addEZ) {
								if(isOpen(ExpIdent+"_addch1addch2")){
									selectWindow(ExpIdent+"_addch1addch2");
									wait(100);
									run("Close");
								}
								if(isOpen(ExpIdent+"_addch2addch1")){
									selectWindow(ExpIdent+"_addch2addch1");
									wait(100);
									run("Close");
								}
							}
						}

// --------------------------
// save an adjusted tiff file
// --------------------------

						if (Tiff){
							if (imgSave == 1) {
								tiff(channelsArray, resDir, imgName, TiffDir);
							}
						}

// ----------------------
// save a .png tile image
// ----------------------


						if (png){
							if (imgSave == 1) {
								pngtile(colorChoices,colorArray,MontageMinArray,MontageMaxArray,pngtileROIs,imgName,resDir,pngDir,allZ,montageArray,MergeArray,Grayscale,autoBC);
							}
						}
					}
				}
			}
		}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---1 IMAGE DONE---
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		//count the number of images done
		imagecount = imagecount +1;

		//remove global scaling
		run("Properties...", false);

		// tidy up: close all image windows
		close("*");
		roiManager("reset");
		run("Collect Garbage");
		run("Clear Results");

		// show files processed and estimate remaining run time
		t2 = getTime();
		// ((t2 - t1) / (imagecount)) ---> time spent so far/ number of images processed so far ---> time spent per images
		//(timeNumber - (imagecount)) ---> total number of images to process - number of image already processed
		// ((t2 - t1) / (imagecount)) * (timeNumber - (imagecount)) ---> number of time to process 1 image * number of images remaining ---> number of time left
		duration = ((t2 - t1) / (imagecount)) * (timeNumber - (imagecount)) / 60000;
		if (k == 0) {
			print("-/-");
		}
		// return files processed and estimated remaining run time
		print("\\Update:"+(imagecount)+"/"+timeNumber+"; Estimated remaining run time: "+duration+" min");
	}
}

// -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---FINISH SCRIPT---
// -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//close all open windows except log
//print total run time

// tidy up:
//close all non image windows except log
list = getList("window.titles");
//exclude log from being closed
list = Array.delete(list, "Log");
if (list.length >= 1) {
	for (i = 0; i < list.length; i++) {
		winame = list[i];
   		selectWindow(winame);
		wait(100);
   		run("Close");
	}
}

//remove the automatic split channel option of Bio-Format
run("Bio-Formats", "open="+filePaths[0]+" autoscale color_mode=Default split_channels=false view=Hyperstack stack_order=XYCZT series_"+p);

//close all image windows, just in case
close("*");

// print total run time
t3 = getTime();
duration = (t3 - t1) / 60000;
//finally return total run time
print("Total run time: "+duration+" min");
//append total run time to log
File.append("Number of files processed: "+numberOfFiles, logFilePath);
File.append("Total run time: "+duration+" min", logFilePath);

// let user know that the script has finished
print("Done!");











// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// ---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---FUNCTIONS---
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// --------------------
// function:  listFiles
// --------------------

function list_files(dir, type, rec) {
	// INPUT: folder path as string and file type ending as string, boolean if recursive
	// OUTPUT: array
	// EXAMPLE: array = list_files("folder/path", ".ims", true);
	// recursively identify filpaths of filetype ("type") in "dir" and write into array

	// make arrays expandable
	setOption("ExpandableArrays", true);
	// initialize array
	arr = newArray(0);
	// get list of paths in root dir
	list = getFileList(dir);
	// loop through and identify subfolders
	for (i = 0; i < list.length; i++) {
		// write current path
		currentPath = dir+list[i];
		// exchange "/" with os-specific separator
		currentPath = replace(currentPath, "/", File.separator);
		// if path ends with wanted ending
		if (endsWith(currentPath, type)) {
		// add currentPath to array
		arr[arr.length] = currentPath;
		// if recursive continue
		} else if (rec) {
			// if identified as folder, continue
			if (endsWith(currentPath, File.separator)) {
				if (indexOf(currentPath, "MMMEAresults") <= 0) {
					// apply original function to the subfolder and save in arr2
           			arr2 = list_files(""+currentPath, type, true);
           			// append arr2 to arr
           			arr = Array.concat(arr, arr2);
				}
			}
		}
    }
    // finally return array
    return arr;
}

// -------------------
// function: num2array
// -------------------

function num2array(str,delim) {
	// INPUT: string
	// OUTPUT: array
	// convert sequence of numbers writen as string ("str") to array according to delimiter ("delim")
	arr = split(str,delim);
	for(i=0; i<arr.length;i++) {
		arr[i] = parseInt(arr[i]);
	}
    // finally return array
	return arr;
}


// --------------------------
// function: find_focus_plane
// --------------------------

function find_focus_plane(FocalChannel) {
	// INPUT: Hyperstack
	// OUTPUT: Zplane number in focus as integer
	// find z-plane in focus using the max. relative variance

	// pre-set variables
	nFocus=0;
	relVar = 0;
	relVarNew = 0;
	// for each z-plane:
	Stack.setChannel(FocalChannel);
	for (i = 1; i < nSlices + 1; i++) {
		// select z-plane
		Stack.setSlice(i);
		// get mean and standard deviation of plane
		getRawStatistics(mean, std);
		// check if mean is bigger than 0, which could happen if image is mostly black
		if (mean > 0){
			// calculate relative variance
			relVar = (std*std)/mean;
			// if relVar is bigger than previous calculated relVar:
			if (relVar > relVarNew) {
				// save relVar in relVarNew
				relVarNew = relVar;
				// write current Zplane number into nFocus
				nFocus = i;
			}
		}
	}
	// return nFocus as integer
	return nFocus;
}

// ------------------------------------------
// function: Remove_Image_with_high_intensity_pixels
// ------------------------------------------

function SaturRemov() {
	// INPUT: image with any amount of channels
	// OUTPUT: sat variable
	//sat = 0 by default, if a channel have high intensity pixel, sat = sat+1
	//an image with sat >0 is an image with high intensity pixel
	//high intensity pixels are defined arbitrarly by pixel above 3/4 of the maximal pixel intensity value based on the bit depth of the image

	//VARIABLES: channelsArray: Array of the channels of the image


	// pre-set variables
	sat = 0;
	//calculate the maximal pixel depth based on the number of bit of the image
	//I put the maximal allowed value at 3/4 of the max pixel depth arbitrarly
	bitDepth();
	maxdepth=(Math.pow(2, bitDepth))/4*3;

	for (j = 0; j < channelsArray.length; j++) {
		Stack.setChannel(j);
		//check the maximal pixel value of the image in each channel
		run("Measure");
		depthMax = getResult("Max");
		//if maximal pixel value is above maximal allowed value, modify the "sat" parameter
		if (depthMax > maxdepth) {
			sat = sat + 1;
		}
	}
	//return the "sat" parameter to decide if image is rejected or not outside of the function
	return sat;
}

// -------------------------------
// function: substract modal value
// -------------------------------

function modalSub(BSmethod,BSvalue,RBradius) {
	// INPUT: Hyperstack, stack or image
	// OUTPUT: Hyperstack, stack or image with background substracted
	// multiple options to substract background

	//VARIABLE: BSmethod: define the method selected for background substraction (choice of "Fixed Value", "Modal Value Substraction"
	//	        BSvalue: for BSmethod = "Fixed Value", need the pixel value to substract on each channel/Zplane
	//			RBradius: for BSmethod = "Rolling Ball", need the rolling ball pixel radius to be used
	
	if(BSmethod == "Fixed Value") {
		// do background substration on entire hyperstack
		for (i = 1; i <= nSlices; i++) {
			setSlice(i);
			//substract a fixed pixel value to the image to remove the background
			run("Subtract...", "value=" + BSvalue);
		}
	}

	if(BSmethod == "Modal Value Substraction") {
		// do background substration on entire hyperstack
		for (i = 1; i <= nSlices; i++) {
			setSlice(i);
			//get the modal value which represent the camera background
			run("Measure");
			mode = getResult("Mode");
			//substract the modal value to the image to remove the background
			run("Subtract...", "value=" + mode);
		}
	}

	if(BSmethod == "Rolling Ball") {
		// do background substration on entire hyperstack
		for (i = 1; i <= nSlices; i++) {
			setSlice(i);
			//use the Rolling Ball method of Background Substraction using a pixel Radius
			run("Subtract Background...", "rolling="+RBradius+" stack");
		}
	}
}

// -------------------------------------------------------------------------------------
// function: Add Channel to stack. Used to add SirDNA that was stained after acquisition
// -------------------------------------------------------------------------------------

function AddChannel(secondaryimagepath,Alignmentfirstchannel,Alignmentsecondchannel,AddImageChannelArray,AddChannelList,channelsArray,secImageChannels,ZplaneNumber,Alignment,AlignmentMeth,Xoffset,Yoffset) {

	// pre-set variables
	//allow to skip image if unable to align by registration
	NoReg = 0;

	//open secondary image
	run("Bio-Formats", "open="+secondaryimagepath+" autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_p");
	rename("Hyperstack-2");
	if (allZ == "focal plane") {
		getDimensions(width, height, channels, slices, frames);
		//get the number of channels
		ChNumber2 = channels;
		if(channels == 1) {
	    	run("Make Substack...", "  slices="+nFocus);
	    	rename("nFocus-2");
	    } else {
			run("Duplicate...", "title=nFocus-2 duplicate slices="+nFocus);
	    }
	} else {
		run("Duplicate...", "title=nFocus-2 duplicate");
	}

	selectWindow("nFocus-2");
	getDimensions(width, height, channels, slices, frames);
	//get the number of Zplane
	ZplaneNumber2 = slices;

	if (Alignment){
		if (AlignmentMeth == "common channel registration") {

			//duplicate channel to be used for alignment from primary image and name it with a zero(for the future loop)
			selectWindow("nFocus");
			run("Duplicate...", "title=first0 duplicate channels="+Alignmentfirstchannel);

			//create a number of copies of the primary image alignment channel equal to the number of channels in the secondary image needed to be aligned +1 (for the channel used for alignment)
			//because it needs an equal number of channels from primary and from secondary images
			c = AddImageChannelArray.length+1;
			for ( j = 0; j < AddImageChannelArray.length; j++) {
				b=j+1;
				run("Duplicate...", "title=first"+b+" duplicate channels="+Alignmentfirstchannel);
			}

			//merge the duplicated channels back into a stack
			//by creating a string that extend itself
			options = "";
			for (j = 0; j < c; j++) {
   				b = j+1;
  				options = options+"c"+b+"="+"first"+j+" ";
			}
			options = options+"create";
			run("Merge Channels...", options);
			Stack.setDisplayMode("color");
			rename("first");


			selectWindow("nFocus-2");
			//need a list of channels, starting with the channel used for alignment, followed by the channel(s) needed to be added
			n= "";
			n = n + Alignmentsecondchannel + ";"+AddChannelList;
			//need the list to separate channels by commas and not semicomma to work with 'make substack' function
			n = replace(n, ";", ",");
			//extract the listed channels from the stack
			run("Make Substack...", "channels="+n);
			rename("second");

			//concatenate the two stacks (from primary and from secondary image) that have the same number of channels
			run("Concatenate...", "open image1=first image2=second image3=[-- None --]");
			rename("concatenated");

			//convert the concatenated stack in a hyperstack where first is a timeframe and second is a timeframe
			run("Stack to Hyperstack...", "order=xyczt(default) channels="+c+" slices="+ZplaneNumber2+" frames=2 display=Color");
			//Align West to Kanye using the user defined channel which is the first channel of the duplicated stacks
			run("HyperStackReg ", "transformation=Translation channel1");

			if(isOpen("concatenated-registered")){

				selectWindow("concatenated-registered");
				//extract the channels to be added from the aligned hyperstack (extract everything except channel 1 from the timeframe 2 of the hyperstack)
				run("Duplicate...", "title=ToAdd duplicate channels=2-"+c+" frames=2");

				//close unnecessary created images
				selectWindow("concatenated");
				close();
				selectWindow("concatenated-registered");
				close();

				//merge the aligned channel(s) with the original image
				//by creating a string that extend itself
				selectWindow("nFocus");
				run("Split Channels");
				options = "";
				//write the part of the string that merge the primary image channels
				for ( j = 0; j < channelsArray.length; j++) {
		   			b = j+1;
		  			options = options+"c"+b+"="+"C"+b+"-nFocus"+" ";
				}
				//add to the merge string the channels to be added

				//get the channel position where to start adding
				c = channelsArray.length+1;

				//if only 1 channel to be added
				if (AddImageChannelArray.length ==1) {
					//add the channel to the merge function
					options = options+"c"+c+"=ToAdd create";
					run("Merge Channels...", options);
					Stack.setDisplayMode("color");
					rename("nFocus");
				} else {
					//if multiple channel to be added
					selectWindow("ToAdd");
					run("Split Channels");
					for ( j = 0; j < AddImageChannelArray.length; j++) {
		   				b = c+j;
	   					d = j+1;
	  					options = options+"c"+b+"="+"C"+d+"-ToAdd"+" ";
					}
					options = options+"create";
					run("Merge Channels...", options);
					Stack.setDisplayMode("color");
					rename("nFocus");
				}

				//crop the images to remove the misaligned part of the image
				run("Duplicate...", "title=Crop duplicate channels="+c);

				//identify the the black part of the image to be cropped out by thresholding
				bitDepth();
				maxdepth=(Math.pow(2, bitDepth))-1;
				setThreshold(1, maxdepth);
				setOption("BlackBackground", true);
				run("Convert to Mask", "method=Default background=Dark black");
				run("Create Selection");
				//get the new height and width of the image
				run("Measure");
				NewWidth = getResult("Width");
				NewHeight = getResult("Height");
				//convert width and height in pixels number of pixels
				getPixelSize(unit, pixelWidth, pixelHeight);
				NewWidth = NewWidth/pixelWidth;
				NewHeight = NewHeight/pixelHeight;
				//get the corner from which to originate the crop
				Xcoord = getResult("FeretX");
				Ycoord = getResult("FeretY");
				//crop
				selectWindow("nFocus");
				run("Select All");
				run("Specify...", "width="+NewWidth+" height="+NewHeight+" x="+Xcoord+" y="+Ycoord);
				run("Crop");
				selectWindow("Crop");
				close();
				run("Select None");
				setOption("BlackBackground", false);

			} else {
				//if unable to align by registration, skip the image and take note of it in log file
				NoReg = 1;
			}
		}

		if (AlignmentMeth == "pixel offset") {

			selectWindow("nFocus-2");
			run("Duplicate...", "title=ToAdd duplicate");

			selectWindow("ToAdd");
			run("Translate...", "x="+Xoffset+" y="+Yoffset+" interpolation=None stack");

			//merge the new channel(s) with the original image
			//by creating a string that extend itself
			selectWindow("nFocus");
			run("Split Channels");
			options = "";
			//write the part of the string that merge the primary image channels
			for ( j = 0; j < channelsArray.length; j++) {
	   			b = j+1;
	  			options = options+"c"+b+"="+"C"+b+"-nFocus"+" ";
			}

			//add the channels to be added to the merge string

			//get the channel position where to start adding
			c = channelsArray.length+1;

			//if there is only 1 channel in the image
			if (secImageChannels ==1) {
				//add the channel to the merge function
				options = options+"c"+c+"=ToAdd create";
				run("Merge Channels...", options);
				Stack.setDisplayMode("color");
				rename("nFocus");
			} else {
				//if multiple channel are present
				//need the list of channels to add separated by commas and not semicomma
				n= replace(AddChannelList, ";", ",");
				selectWindow("ToAdd");
				run("Make Substack...", "channels="+n);
				selectWindow("ToAdd");
				close();
				selectWindow("ToAdd-1");
				rename("ToAdd");
				run("Split Channels");
				for ( j = 0; j < AddImageChannelArray.length; j++) {
   					b = c+j;
   					d = j+1;
  					options = options+"c"+b+"="+"C"+d+"-ToAdd"+" ";
				}
				options = options+"create";
				run("Merge Channels...", options);
				Stack.setDisplayMode("color");
				rename("nFocus");

				//crop the images to remove the misaligned part of the image
				//get the new height and width of the image
				getDimensions(width, height, channels, slices, frames);
				NewWidth=width-abs(Xoffset);
				NewHeight=height-abs(Yoffset);
				//get the corner from which to originate the crop
				Xsign = substring(Xoffset, 0, 1);
				if (Xsign == "-") {
					Xcoord = 0;
				} else {
					Xcoord = abs(Xoffset);
				}
				Ysign = substring(Yoffset, 0, 1);
				if (Ysign == "-") {
					Ycoord = 0;
				} else {
					Ycoord = abs(Yoffset);
				}
				//crop
				run("Select All");
				run("Specify...", "width="+NewWidth+" height="+NewHeight+" x="+Xcoord+" y="+Ycoord);
				run("Crop");
				run("Select None");
			}
		}
	} else {

		selectWindow("nFocus-2");
		run("Duplicate...", "title=ToAdd duplicate");
		selectWindow("nFocus-2");
		close();

		//merge the new channel(s) with the original image
		//by creating a string that extend itself
		selectWindow("nFocus");
		run("Split Channels");
		options = "";
		//write the part of the string that merge the primary image channels
		for ( j = 0; j < channelsArray.length; j++) {
   			b = j+1;
  			options = options+"c"+b+"="+"C"+b+"-nFocus"+" ";
		}

		//add the channels to be added to the merge string

		//get the channel position where to start adding
		c = channelsArray.length+1;

		//if there is only 1 channel in the image
		if (secImageChannels ==1) {
			//add the channel to the merge function
			options = options+"c"+c+"=ToAdd create";
			run("Merge Channels...", options);
			Stack.setDisplayMode("color");
			rename("nFocus");
		} else {
			//if multiple channel are present
			//need the list of channels to add separated by commas and not semicomma
			n= replace(AddChannelList, ";", ",");
			selectWindow("ToAdd");
			run("Make Substack...", "channels="+n);
			selectWindow("ToAdd");
			close();
			selectWindow("ToAdd-1");
			rename("ToAdd");
			run("Split Channels");
			for ( j = 0; j < AddImageChannelArray.length; j++) {
   				b = c+j;
   				d = j+1;
  				options = options+"c"+b+"="+"C"+d+"-ToAdd"+" ";
			}
			options = options+"create";
			run("Merge Channels...", options);
			Stack.setDisplayMode("color");
			rename("nFocus");
		}
	}

	//close unnecessary created images
	selectWindow("Hyperstack-2");
	close();
	selectWindow("nFocus-2");
	close();

	return NoReg;

}

// ----------------------------------------------
// function: define_ROI_by_thresholding
// ----------------------------------------------

function def_ROI_by_thresholding(ThreshMet, wtshed, threshexclude) {
	// INPUT: 2D-image
	// OUTPUT: Define ROIs by thresholding, then add to ROI manager

	// create mask
	setAutoThreshold(ThreshMet+" dark stack");
	run("Make Binary", "method="+ThreshMet+" background=Dark black");
	//Make Binary when you have a stack doesn't invert LUT and the rest of the steps need ROI to be Black
	if (allZ == "all Z") {
		run("Invert LUT");
	}
	run("Fill Holes", "stack");
	run("Despeckle", "stack");

	// check if watershed is enabled
	if (wtshed) {
		run("Watershed", "stack");
	}

	// add ROIs to ROI manager if required critera are met
	// check if edge ROIs should be excluded
	if (threshexclude) {
	selectWindow("SegCh");
	run("Analyze Particles...", "size="+ROIminarea+"-"+ROImaxarea+" exclude clear include add stack");
	} else {
	selectWindow("SegCh");
	run("Analyze Particles...", "size="+ROIminarea+"-"+ROImaxarea+" clear include add stack");
	}
	close("SegCh");
}

// ----------------------------------------------
// function: stardist
// ----------------------------------------------

function stardist(probThresh, overlapThresh, pathToStardistModel, starexclude){
	// INPUT: 2D-image
	// OUTPUT: Add ROIs to the ROI manager
	// probThreh: Probability/score threshold - higher values lead to fewer segmented objects, but will likely avoid false positives.
	// nmsThresh: Overlap threshold - higher values allow segmented objects to overlap substantially.
	// to install stardist:
	// https://imagej.net/StarDist
	// help -> update -> manage update sites -> check: CSBDeep, StarDist

	//replace '\' by '/' in the pathToStardistModel argument to allow insertion in the stardist macro line
	pathToStardistModel = replace(pathToStardistModel, File.separator, "/");

	//STARDIST do not work with Zslices but work with timeframes
	//convert Zslices in timeframes
	if (allZ == "all Z") {
		run("Properties...", "channels=1 slices=1 frames="+ZplaneNumber);
		run("Properties...", "global");
	}

	// use stardist to identify nuclei/ROIs
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'SegCh', 'modelChoice':'Model (.zip) from File', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'"+probThresh+"', 'nmsThresh':'"+overlapThresh+"', 'outputType':'ROI Manager', 'modelFile':'"+pathToStardistModel+"', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

	// check if edge ROIs should be excluded
	if (starexclude) {
		// count number of ROIs identified
		nROIs = roiManager("count");
		// for each ROI check if it touches edges
  		for (i=nROIs-1; i>=0; i--) {
    		roiManager("select", i);
     		getSelectionBounds(x, y, w, h);
     		// if it touches edge, delete
     		if (x<=0||y<=0||x+w>=getWidth||y+h>=getHeight) {
        		roiManager("delete");
  			}
  		}
	}
	// deselect all ROIs
	roiManager("deselect");
	// close 2D-image, since it is no longer needed
	close("SegCh");
}

// ------------------------------------
// function: colored ROI image creation
// ------------------------------------

//save ROIs as an image in which each ROI have a different color
function coloredROIimage() {
	
	n = roiManager("count");
	selectWindow("nFocus");
    w=getWidth();	
    h=getHeight();
	newImage("labels", "16-bit black", w, h, 1);
	selectWindow("labels");
	run("RGB Color");
	for(l=0; l<n; l++){
		roiManager("select",l);
		k = random();
		k1 = k*255;
		k2 = abs(k1);
		m = random();
		m1 = m*255;
		m2 = abs(m1);
		g = random();
		g1 = g*255;
		g2 = abs(g1);
		setColor(k2, m2, g2);
		fill();
	}
}

// -----------------------------------------------
// function: filter ROI based on Channel(s) IntDen
// -----------------------------------------------

function IntDenfilter(IntDenFilterChannelArray, IntDenFilterOperatorList, IntDenFilterThreshArray) {

	// initializing variables for loop below
	IntDen = 0;

	nROIs = roiManager("count");
	if (nROIs>=1){
	selectWindow("nFocus");

		//loop through the selected channel(s) for filtering
		for ( j = 0; j < IntDenFilterChannelArray.length; j++) {

			nROIs = roiManager("count");
			if (nROIs>=1){
				ch=j+1;
				//select the channel
				Stack.setChannel(ch);

				//loop through the ROi(s)
				for (i = nROIs-1; i >= 0; i--) {
					roiManager("Select", i);

					//measure the IntDen
					run("Measure");
					IntDen = getResult("IntDen");

					//Isolate the correct Operator matching the channel filter
					sub = replace(IntDenFilterOperatorList, ";", "");
					sub = substring(sub, j, j+1);

					//compare IntDen with threshold with the appropriate Operator (> or <) and delete ROI if criteria not met
					if (sub == "<") {
						if ( IntDen > IntDenFilterThreshArray[j] ) {
							roiManager("Select", i);
							roiManager("Delete");
						}
					}
					if (sub == ">") {
						if ( IntDen < IntDenFilterThreshArray[j] ) {
							roiManager("Select", i);
							roiManager("Delete");
						}
					}
				}
			}
		}
	}
}

// -------------------------------------------
// function: filter ROI based on channel(s) CV
// -------------------------------------------

function CVfilter(CVFilterChannelArray, CVFilterOperatorList, CVFilterThreshArray) {

	// initializing variables for loop below
	SD = 0;
	mean = 0;
	CV = 0;

	nROIs = roiManager("count");
	if (nROIs>=1){
	selectWindow("nFocus");

		//loop through the selected channel(s) for filtering
		for ( j = 0; j < CVFilterChannelArray.length; j++) {

			nROIs = roiManager("count");
			if (nROIs>=1){
				ch=j+1;
				//select the channel
				Stack.setChannel(ch);

				//loop through the ROi(s)
				for (i = nROIs-1; i >= 0; i--) {
					roiManager("Select", i);

					//calculate the CV
					run("Measure");
					mean = getResult("Mean");
					SD = getResult("StdDev");
					CV = SD/mean;

					//Isolate the correct Operator matching the channel filter
					sub = replace(CVFilterOperatorList, ";", "");
					sub = substring(sub, j, j+1);

					//compare IntDen with threshold with the appropriate Operator (> or <) and delete ROI if criteria not met
					if (sub == "<") {
						if ( CV > CVFilterThreshArray[j] ) {
							roiManager("Select", i);
							roiManager("Delete");
						}
					}
					if (sub == ">") {
						if ( CV < CVFilterThreshArray[j] ) {
							roiManager("Select", i);
							roiManager("Delete");
						}
					}
				}
			}
		}
	}
}

// --------------------------------------
// function: filter ROI based on ROI size
// --------------------------------------

function ROIsizefilter(ROIminarea, ROImaxarea) {

	// initializing variables for loop below
	ROIarea = 0;

	nROIs = roiManager("count");
	if (nROIs>=1){
		selectWindow("nFocus");

		// loop throught ROIs to measure area in each one
		for (i = nROIs-1; i >= 0; i--) {
			roiManager("Select", i);
			run("Measure");
			ROIarea = getResult("Area");

			//if ROI is below threshold, remove ROI
			if (ROIarea < ROIminarea ) {
				 roiManager("Select", i);
				 roiManager("delete");
			}
			//if ROI is below threshold, remove ROI
			if (ROIarea > ROImaxarea ) {
				 roiManager("Select", i);
				 roiManager("delete");
			}
		}
	}
}

// --------------------------------------------------------------------------------------------
// function: filter ROI based on if the ROI is in focus at nFocus
// --------------------------------------------------------------------------------------------

//measure the intensity in the HyperStack above and under the current Z
//delete ROI if the IntDen at the current Z is significantly lower than above or below (out of focus)
//to delete ROIs that are not in the middle of the nucleus

function ROIZpositionfilter(outofFocusROIChannel, nFocus, Zdifferential, Ratiolimit, ZplaneNumber) {

	// initializing variables for loop below
	ROIintensity = 0;
	ROIintensityOver = 0;
	ROIintensityUnder = 0;
	OverRatio = 0;
	UnderRatio = 0;
	zOver = nFocus+Zdifferential;
	zUnder = nFocus-Zdifferential;

	nROIs = roiManager("count");
	if (nROIs>=1){
		selectWindow("Hyperstack");
		run("Select None");
		Stack.setChannel(outofFocusROIChannel);
		// loop throught ROIs to measure intensity above and under of each one
		for (i = nROIs-1; i >= 0; i--) {
			//deleted will become 1 once an ROI is deleted. Needed later in the function. Resets for each ROI.
			deleted = 0;
			roiManager("Select", i);
			Stack.setSlice(nFocus);
			run("Measure");
			ROIintensity = getResult("IntDen");

			//find the Z limit for this function
			//(if the nFocus is the 1st Zplane, do not check for Zplanes below)
			//z1 is the upper Zstack limit and z2 is the lower Zstack limit that allow measurements in this function
			z1 = ZplaneNumber-Zdifferential;
			z2 = Zdifferential;
			if (nFocus <z1) {
				Stack.setSlice(zOver);
				run("Measure");
				ROIintensityOver = getResult("IntDen");
			}
			if (nFocus > z2) {
				Stack.setSlice(zUnder);
				run("Measure");
				ROIintensityUnder = getResult("IntDen");
			}

			//Compare the intensity at nFocus with the intensity above and under
			OverRatio = ROIintensityOver/ROIintensity;
			UnderRatio = ROIintensityUnder/ROIintensity;

			//if Ratios are above threshold, remove ROI
			if (nFocus <z1) {
				if (OverRatio > Ratiolimit) {
					roiManager("Select", i);
					roiManager("delete");
					//deleted becomes 1 to avoid the cases where the function would want to delete an ROI because over Over and Under Ratios
					deleted = 1;
				}
			}
			if (deleted == 0) {
				if (nFocus > z2) {
					if (UnderRatio > Ratiolimit) {
						roiManager("Select", i);
						roiManager("delete");
					}
				}
			}
		}
	}
}

// --------------------------------------------------------------------------------------------
// Function: EZcolocalization
// --------------------------------------------------------------------------------------------

//measure the colocalization between the signal of two channels using the EZcolocalization plugin
//the colocalization can be evaluated using the RAW signal, a mask done by standard thresholding methods, or using the 'find maxima' function

function EZ(ch1, ch2, EZmeth1, threshMeth1, prominence1, EZmeth2, threshMeth2, prominence2, Masks, MaskImageDir, imgName, dows, ROIminarea, ROImaxarea, ExpIdent, logFilePath, imgSave) {

	//extract the channel 1 used for colocalization evaluation
	selectWindow("nFocus");
	run("Select None");
	run("Duplicate...", "title=ch1 duplicate channels="+ch1);

	//make a mask out of the RAW signal and multiply it with the RAW image if option selected
	//this way, positive pixels have their original Int. value but negative pixels have a value of zero
	if(EZmeth1 == "Mask") {
		selectWindow("ch1");
		rename("RAW1");
		run("Duplicate...", "title=Mask1 duplicate");

		// threshold
		selectWindow("Mask1");
		setAutoThreshold(threshMeth1+" dark stack");
		// create mask
		run("Convert to Mask", "method="+threshMeth1+" background=Default");

		//change the pixel value of positive pixels to 1 to allow to keep RAW pixel Int. values of positive pixels
		run("Divide...", "value=255.000 stack");
		//multiply the RAW image with the Mask image
		imageCalculator("Multiply create stack", "RAW1","Mask1");

		//close unnecessary images
		selectWindow("RAW1");
		run("Close");
		selectWindow("Mask1");
		run("Close");
		selectWindow("Result of RAW1");
		rename("ch1");
	}

	//use the 'find maxima' tool to identify foci and multiply the result with the RAW image if option selected
	//this way, foci keep their original Int. value but negative pixels have a value of zero
	if(EZmeth1 == "MaximaFinder") {
		selectWindow("ch1");
		rename("RAW1");

		//identify foci
		run("Find Maxima...", "prominence="+prominence1+" output=[Maxima Within Tolerance]");
		rename("Maxima1");

		//change the pixel value of positive pixels to 1 to allow to keep RAW pixel Int. values of positive pixels
		run("Divide...", "value=255.000 stack");
		//multiply the RAW image with the "Find Maxima" image
		imageCalculator("Multiply create stack", "RAW1","Maxima1");

		//close unnecessary images
		selectWindow("RAW1");
		run("Close");
		selectWindow("Maxima1");
		run("Close");
		selectWindow("Result of RAW1");
		rename("ch1");
	}

	//extract the channel 2 used for colocalization evaluation
	selectWindow("nFocus");
	run("Select None");
	run("Duplicate...", "title=ch2 duplicate channels="+ch2);

	//make a mask out of the RAW signal and multiply it with the RAW image if option selected
	//this way, positive pixels have their original Int. value but negative pixels have a value of zero
	if(EZmeth2 == "Mask") {
		selectWindow("ch2");
		rename("RAW2");

		run("Duplicate...", "title=Mask2 duplicate");

		// threshold
		selectWindow("Mask2");
		setAutoThreshold(threshMeth2+" dark stack");
		// create mask
		run("Convert to Mask", "method="+threshMeth2+" background=Default");

		//change the pixel value of positive pixels to 1 to allow to keep RAW pixel Int. values of positive pixels
		run("Divide...", "value=255.000 stack");
		//multiply the RAW image with the Mask image
		imageCalculator("Multiply create stack", "RAW2","Mask2");

		//close unnecessary images
		selectWindow("RAW2");
		run("Close");
		selectWindow("Mask2");
		run("Close");
		selectWindow("Result of RAW2");
		rename("ch2");
	}

	//use the 'find maxima' tool to identify foci and multiply the result with the RAW image if option selected
	//this way, foci keep their original Int. value but negative pixels have a value of zero
	if(EZmeth2 == "MaximaFinder") {
		selectWindow("ch2");
		rename("RAW2");

		//identify foci
		run("Find Maxima...", "prominence="+prominence2+" output=[Maxima Within Tolerance]");
		rename("Maxima2");

		//change the pixel value of positive pixels to 1 to allow to keep RAW pixel Int. values of positive pixels
		run("Divide...", "value=255.000 stack");
		//multiply the RAW image with the "Find Maxima" image
		imageCalculator("Multiply create stack", "RAW2","Maxima2");

		//close unnecessary images
		selectWindow("RAW2");
		run("Close");
		selectWindow("Maxima2");
		run("Close");
		selectWindow("Result of RAW2");
		rename("ch2");
	}

	if (Masks) {
		if (imgSave == 1) {
			//save masks
			selectWindow("ch1");
			run("16-bit");
			selectWindow("ch2");
			run("16-bit");
			run("Merge Channels...", "c1=ch1 c2=ch2 create keep");
			Stack.setChannel(1);
			run("Enhance Contrast", "saturated=0.35");
			run("Red");
			Stack.setChannel(2);
			run("Enhance Contrast", "saturated=0.35");
			run("Green");
			saveAs("tiff", MaskImageDir+imgName+"_"+ch1+"-"+ch2+"_masks.tiff");
			close();
		}
	}

	//for when working with allZ, if ROIs are manually modified or manually added using the an Hyperstack, the positions og the modified/added ROIs,
	//contains channels and timepoint info but the unmodified ones only contain channels since they were theresholded using a stack and not a hyperstack.
	//This affects EZcolocalization. To ensure correct EZcolocalization, update the properties of ROIs on a stack and not Hyperstack.
	selectWindow("ch1");
	nROIs = roiManager("count");
	for (i = nROIs-1; i >= 0; i--) {
		roiManager("Select", i);
		roiManager("Update");
	}

	//get the number of Rois before EZcolocalization
	//used to remove the duplication of ROIs by EZcolocalization
	nROIs = roiManager("count");
	// EzColoc ch1 vs ch2
	//run EZcolocalization plugin
	if (dows == 0) {
		run("EzColocalization ", "reporter_1_(ch.1)=ch1 reporter_2_(ch.2)=ch2 cell_identification_input=[ROI Manager] alignthold4=default filter1=area range1="+ROIminarea+"-"+ROImaxarea+" tos metricthold1=costes' allft-c1-1=10 allft-c2-1=10 pcc metricthold2=costes' allft-c1-2=10 allft-c2-2=10 srcc metricthold3=costes' allft-c1-3=10 allft-c2-3=10 icq metricthold4=costes' allft-c1-4=10 allft-c2-4=10 mcc metricthold5=costes' allft-c1-5=10 allft-c2-5=10 average_signal roi(s)");
	} else {
		 run("EzColocalization ", "reporter_1_(ch.1)=ch1 reporter_2_(ch.2)=ch2 cell_identification_input=[ROI Manager] alignthold4=default dows filter1=area range1="+ROIminarea+"-"+ROImaxarea+" tos metricthold1=costes' allft-c1-1=10 allft-c2-1=10 pcc metricthold2=costes' allft-c1-2=10 allft-c2-2=10 srcc metricthold3=costes' allft-c1-3=10 allft-c2-3=10 icq metricthold4=costes' allft-c1-4=10 allft-c2-4=10 mcc metricthold5=costes' allft-c1-5=10 allft-c2-5=10 average_signal roi(s)");
	}
	if(isOpen("Metric(s) of ROI Manager")) {
		//rename result window to be able to retrieve data later
		selectWindow("Metric(s) of ROI Manager");
		Table.setLocationAndSize((screenWidth+100), (screenHeight+100), 500, 200);
		Table.rename("Metric(s) of ROI Manager", ExpIdent+"_ch1ch2");
	} else {
		//if there is no output from EZcolocalization, take note of it
		File.append(imgName+" ch1-ch2 coloc analysis not done, EZcolocalization unable to quantify colocalization ", logFilePath);
	}

	// EzColoc ch2 vs ch1
	//run EZcolocalization plugin
	if (dows == 0) {
		run("EzColocalization ", "reporter_1_(ch.1)=ch2 reporter_2_(ch.2)=ch1 cell_identification_input=[ROI Manager] alignthold4=default filter1=area range1="+ROIminarea+"-"+ROImaxarea+" tos metricthold1=costes' allft-c1-1=10 allft-c2-1=10 pcc metricthold2=costes' allft-c1-2=10 allft-c2-2=10 srcc metricthold3=costes' allft-c1-3=10 allft-c2-3=10 icq metricthold4=costes' allft-c1-4=10 allft-c2-4=10 mcc metricthold5=costes' allft-c1-5=10 allft-c2-5=10 average_signal");
	} else {
		run("EzColocalization ", "reporter_1_(ch.1)=ch2 reporter_2_(ch.2)=ch1 cell_identification_input=[ROI Manager] alignthold4=default dows filter1=area range1="+ROIminarea+"-"+ROImaxarea+" tos metricthold1=costes' allft-c1-1=10 allft-c2-1=10 pcc metricthold2=costes' allft-c1-2=10 allft-c2-2=10 srcc metricthold3=costes' allft-c1-3=10 allft-c2-3=10 icq metricthold4=costes' allft-c1-4=10 allft-c2-4=10 mcc metricthold5=costes' allft-c1-5=10 allft-c2-5=10 average_signal");
	}
	if(isOpen("Metric(s) of ROI Manager")) {
		//rename result window to be able to retrieve data later
		selectWindow("Metric(s) of ROI Manager");		
		Table.setLocationAndSize((screenWidth+100), (screenHeight+100), 500, 200);
		Table.rename("Metric(s) of ROI Manager", ExpIdent+"_ch2ch1");
	} else {
		//if there is no output from EZcolocalization, take note of it
		File.append(imgName+" ch2-ch1 coloc analysis not done, EZcolocalization unable to quantify colocalization ", logFilePath);
	}

	//close unnecessary images
	selectWindow("ch1");
	close();
	selectWindow("ch2");
	close();

	//remove duplicated ROIs
	//after EZcolocalization, the ROIs are duplicated. EZnROIs gets the number of ROIs after duplication
	//EZcolocalization rename ROIs with the following nomenclature
	//image 1: cell 1
	//image numbers refers to the Zplane
	//cell numbers refers to the numbering of the ROIs on that Zplane
	//we keep that nomenclature
	EZnROIs = roiManager("count");
	//if the number of ROIs is 1, that mean that the 1 ROI was not analysed by EZcolocalization, or else we would have 2 ROI (duplication)
	if (EZnROIs>=2) {

		//to remove the first set of ROI labels and keep the ROI labels of EZcolocalization,
		//start at the nROIs (number of ROIs before duplication), and delete ROIs before
		for (i = nROIs-1; i >= 0; i--) {
			roiManager("Select", i);
			roiManager("Delete");
		}
	} else {
		//if the number of ROIs is 1, that mean that the 1 ROI was not analysed by EZcolocalization, or else we would have 2 ROI (duplication)
		if (EZnROIs==1) {
			roiManager("Select", 0);
			roiManager("Delete");
		}
	}
}

// --------------------------------------------------------------------------------------------
// Function: second EZcolocalization
// --------------------------------------------------------------------------------------------

//measure the colocalization between the signal of two additionnal channels using the EZcolocalization plugin
//the colocalization can be evaluated using the RAW signal, a mask done by standard thresholding methods, or using the 'find maxima' function

function secEZ(addch1, addch2, addEZmeth1, addthreshMeth1, addprominence1, addEZmeth2, addthreshMeth2, addprominence2, Masks, MaskImageDir, imgName, dows, ROIminarea, ROImaxarea, ExpIdent, logFilePath, imgSave) {

	//extract the additionnal channel 1 used for colocalization evaluation
	selectWindow("nFocus");
	run("Select None");
	run("Duplicate...", "title=addch1 duplicate channels="+addch1);

	//make a mask out of the RAW signal and multiply it with the RAW image if option selected
	//this way, positive pixels have their original Int. value but negative pixels have a value of zero
	if(addEZmeth1 == "Mask") {
		selectWindow("addch1");
		rename("addRAW1");
		run("Duplicate...", "title=addMask1");

		// threshold
		selectWindow("addMask1");
		setAutoThreshold(addthreshMeth1+" dark stack");
		// create mask
		run("Convert to Mask", "method="+addthreshMeth1+" background=Default");

		//change the pixel value of positive pixels to 1 to allow to keep RAW pixel Int. values of positive pixels
		run("Divide...", "value=255.000 stack");
		//multiply the RAW image with the Mask image
		imageCalculator("Multiply create stack", "addRAW1","addMask1");

		//close unnecessary images
		selectWindow("addRAW1");
		run("Close");
		selectWindow("addMask1");
		run("Close");
		selectWindow("Result of addRAW1");
		rename("addch1");
	}

	//use the 'find maxima' tool to identify foci and multiply the result with the RAW image if option selected
	//this way, foci keep their original Int. value but negative pixels have a value of zero
	if(addEZmeth1 == "MaximaFinder") {
		selectWindow("addch1");
		rename("addRAW1");

		//identify foci
		run("Find Maxima...", "prominence="+addprominence1+" output=[Maxima Within Tolerance]");
		rename("addMaxima1");

		//change the pixel value of positive pixels to 1 to allow to keep RAW pixel Int. values of positive pixels
		run("Divide...", "value=255.000 stack");
		//multiply the RAW image with the "Find Maxima" image
		imageCalculator("Multiply create stack", "addRAW1","addMaxima");

		//close unnecessary images
		selectWindow("addRAW1");
		run("Close");
		selectWindow("addMaxima1");
		run("Close");
		selectWindow("Result of addRAW1");
		rename("addch1");
	}

	//extract the additionnal channel 2 used for colocalization evaluation
	selectWindow("nFocus");
	run("Select None");
	run("Duplicate...", "title=addch2 duplicate channels="+addch2);

	//make a mask out of the RAW signal and multiply it with the RAW image if option selected
	//this way, positive pixels have their original Int. value but negative pixels have a value of zero
	if(addEZmeth2 == "Mask") {
		selectWindow("addch2");
		rename("addRAW2");
		run("Duplicate...", "title=addMask2");

		// threshold
		selectWindow("addMask2");
		setAutoThreshold(addthreshMeth2+" dark stack");
		// create mask
		run("Convert to Mask", "method="+addthreshMeth2+" background=Default");

		//change the pixel value of positive pixels to 1 to allow to keep RAW pixel Int. values of positive pixels
		run("Divide...", "value=255.000 stack");
		//multiply the RAW image with the Mask image
		imageCalculator("Multiply create stack", "addRAW2","addMask2");

		//close unnecessary images
		selectWindow("addRAW2");
		run("Close");
		selectWindow("addMask2");
		run("Close");
		selectWindow("Result of addRAW2");
		rename("addch2");
	}

	//use the 'find maxima' tool to identify foci and multiply the result with the RAW image if option selected
	//this way, foci keep their original Int. value but negative pixels have a value of zero
	if(addEZmeth2 == "MaximaFinder") {
		selectWindow("addch2");
		rename("addRAW2");

		//identify foci
		run("Find Maxima...", "prominence="+addprominence2+" output=[Maxima Within Tolerance]");
		rename("addMaxima2");

		//change the pixel value of positive pixels to 1 to allow to keep RAW pixel Int. values of positive pixels
		run("Divide...", "value=255.000 stack");
		//multiply the RAW image with the "Find Maxima" image
		imageCalculator("Multiply create stack", "addRAW2","addMaxima2");

		//close unnecessary images
		selectWindow("addRAW2");
		run("Close");
		selectWindow("addMaxima2");
		run("Close");
		selectWindow("Result of addRAW2");
		rename("addch2");
	}

	if (Masks) {
		if (imgSave == 1) {
			//save masks
			selectWindow("addch1");
			run("16-bit");
			selectWindow("addch2");
			run("16-bit");
			run("Merge Channels...", "c1=addch1 c2=addch2 create keep");
			Stack.setChannel(1);
			run("Enhance Contrast", "saturated=0.35");
			run("Red");
			Stack.setChannel(2);
			run("Enhance Contrast", "saturated=0.35");
			run("Green");
			saveAs("tiff", MaskImageDir+imgName+"_"+addch1+"-"+addch2+"_masks.tiff");
			close();
		}
	}

	// EzColoc addch1 vs addch2
	//run EZcolocalization plugin
	if (dows == 0) {
		run("EzColocalization ", "reporter_1_(ch.1)=addch1 reporter_2_(ch.2)=addch2 cell_identification_input=[ROI Manager] alignthold4=default filter1=area range1="+ROIminarea+"-"+ROImaxarea+" tos metricthold1=costes' allft-c1-1=10 allft-c2-1=10 pcc metricthold2=costes' allft-c1-2=10 allft-c2-2=10 srcc metricthold3=costes' allft-c1-3=10 allft-c2-3=10 icq metricthold4=costes' allft-c1-4=10 allft-c2-4=10 mcc metricthold5=costes' allft-c1-5=10 allft-c2-5=10 average_signal");
	} else {
		run("EzColocalization ", "reporter_1_(ch.1)=addch1 reporter_2_(ch.2)=addch2 cell_identification_input=[ROI Manager] alignthold4=default dows filter1=area range1="+ROIminarea+"-"+ROImaxarea+" tos metricthold1=costes' allft-c1-1=10 allft-c2-1=10 pcc metricthold2=costes' allft-c1-2=10 allft-c2-2=10 srcc metricthold3=costes' allft-c1-3=10 allft-c2-3=10 icq metricthold4=costes' allft-c1-4=10 allft-c2-4=10 mcc metricthold5=costes' allft-c1-5=10 allft-c2-5=10 average_signal");
	}
	if(isOpen("Metric(s) of ROI Manager")){
		//rename result window to be able to retrieve data later
		selectWindow("Metric(s) of ROI Manager");
		Table.setLocationAndSize((screenWidth+100), (screenHeight+100), 500, 200);
		Table.rename("Metric(s) of ROI Manager", ExpIdent+"_addch1addch2");
	} else {
		//if there is no output from EZcolocalization, take note of it
		File.append(imgName+" addch1-addch2 coloc analysis not done, EZcolocalization unable to quantify colocalization ", logFilePath);
	}

	// EzColoc addch2 vs addch1
	//run EZcolocalization plugin
	if (dows == 0) {
		run("EzColocalization ", "reporter_1_(ch.1)=addch2 reporter_2_(ch.2)=addch1 cell_identification_input=[ROI Manager] alignthold4=default filter1=area range1="+ROIminarea+"-"+ROImaxarea+" tos metricthold1=costes' allft-c1-1=10 allft-c2-1=10 pcc metricthold2=costes' allft-c1-2=10 allft-c2-2=10 srcc metricthold3=costes' allft-c1-3=10 allft-c2-3=10 icq metricthold4=costes' allft-c1-4=10 allft-c2-4=10 mcc metricthold5=costes' allft-c1-5=10 allft-c2-5=10 average_signal");
	} else {
		run("EzColocalization ", "reporter_1_(ch.1)=addch2 reporter_2_(ch.2)=addch1 cell_identification_input=[ROI Manager] alignthold4=default dows filter1=area range1="+ROIminarea+"-"+ROImaxarea+" tos metricthold1=costes' allft-c1-1=10 allft-c2-1=10 pcc metricthold2=costes' allft-c1-2=10 allft-c2-2=10 srcc metricthold3=costes' allft-c1-3=10 allft-c2-3=10 icq metricthold4=costes' allft-c1-4=10 allft-c2-4=10 mcc metricthold5=costes' allft-c1-5=10 allft-c2-5=10 average_signal");
	}
	if(isOpen("Metric(s) of ROI Manager")) {
		//rename result window to be able to retrieve data later
		selectWindow("Metric(s) of ROI Manager");
		Table.setLocationAndSize((screenWidth+100), (screenHeight+100), 500, 200);
		Table.rename("Metric(s) of ROI Manager", ExpIdent+"_addch2addch1");
	} else {
		//if there is no output from EZcolocalization, take note of it
		File.append(imgName+" addch2-addch1 coloc analysis not done, EZcolocalization unable to quantify colocalization ", logFilePath);
	}

	//close unnecessary images
	selectWindow("addch1");
	close();
	selectWindow("addch2");
	close();
}

// ------------------------------------
// function: save an adjusted Tiff file
// ------------------------------------

function tiff(channelsArray, resDir, imgName, TiffDir) {

	selectImage("nFocus");
	run("Select None");
	roiManager("deselect");
	run("Duplicate...", "title=tiff duplicate");

	nROIs = roiManager("count");
	if (nROIs>=1){
		for (j = 0; j < channelsArray.length; j++) {
			Stack.setChannel(j+1);
			run("Enhance Contrast", "saturated=0.35");
		}
		saveAs("tiff", TiffDir+imgName);
		close();
	}
}

// --------------------------------------
// function: save a .png tile image
// --------------------------------------

function pngtile(colorChoices,colorArray,MontageMinArray,MontageMaxArray,pngtileROIs,imgName,resDir,pngDir,allZ,montageArray,MergeArray,Grayscale,autoBC) {

	//if allZ, work with focal plane for png montage
	if (allZ == "all Z"){
		selectImage("nFocus");
		rename("OG_nFocus");
		nFocus = find_focus_plane(FocalChannel);
		run("Duplicate...", "title=nFocus duplicate slices="+nFocus);
	}

	selectImage("nFocus");
	run("Select None");
	roiManager("Show None");

	// set channel colors to grayscal only if option is selected
	if (Grayscale) {
		Stack.setDisplayMode("grayscale");
	}

	for(j = 0; j < montageArray.length; j++) {
		//duplicate the channels selected to be in the montage
		selectImage("nFocus");
		run("Duplicate...", "title=Montage_ch"+montageArray[j]+" duplicate channels="+montageArray[j]);
		if (Grayscale == 0) {
			//give each channel its selected color
			a = colorChoices[j];
			run(colorArray[a-1]);
		}

		if (autoBC==0) {
			//set the histogram minimal and maximal values
			setMinAndMax(MontageMinArray[j], MontageMaxArray[j]);
		} else {
			//set the histogram minimal and maximal values using Enhance contrast
			run("Enhance Contrast", "saturated=0.35");
		}
	}

	//create a merge
	//only if images are not in grayscale

	if (Grayscale == 0) {

		//create an array of the colors number of the channels needed to be merged for the montage
		//Loop through the entries of the MergeArray and find the index(position) of the entries in the montageString
		//extract that index position from the colorString and create a new string made of only those
		MergeColorString = "";
 		for ( i = 0; i < MergeArray.length; i++) {
 			wait(100);
			a = MergeArray[i];
			m = indexOf(montageString, a);
			mm = substring(colorString, m, m+1);
			MergeColorString = MergeColorString+","+mm;
		}
		MergeColorString = substring(MergeColorString, 1);
 		MergeColorArray = num2array(MergeColorString,",");
		// write option string for merge function
		options = "";
 		for ( i = 0; i < MergeArray.length; i++) {
			b = MergeColorArray[i];
	 		options = options+"c"+b+"="+"Montage_ch"+MergeArray[i]+" ";
		}
		options = options+"create keep";
		// merge channels
	 	run("Merge Channels...", options);
	 	run("RGB Color");
		rename("Montage_merged");
	}


	roiManager("Set Color", "white");
	roiManager("Set Line Width", 3);

	//draw ROIs if option selected
	if (pngtileROIs) {

		if (allZ == "all Z"){
			indexes = "";
			for (i = 0; i < nROIs; i ++) {
				// select ROI
				roiManager("select", i);
				//Isolate Zplane from the ROI name
				ROIName = Roi.getName;
				sep = indexOf(ROIName, ":");
				Z = substring(ROIName, 6, sep);
				if (Z == nFocus) {
					indexes = indexes+","+i;
				}
			}
			indexesArray = num2array(indexes,",");
			for(j = 0; j < montageArray.length; j++) {
				//select window
				selectWindow("Montage_ch"+montageArray[j]);
				//draw ROIs
				roiManager("select", indexesArray);
				roiManager("combine");
				// flatten ROIs
				run("Flatten");
				wait(100);

				//close unflatten image
				selectWindow("Montage_ch"+montageArray[j]);
				close();
			}
			if (Grayscale == 0) {
				//select window
				selectImage("Montage_merged");
				//draw ROIs
				roiManager("select", indexesArray);
				roiManager("combine");
				// flatten ROIs
				run("Flatten");
				wait(100);

				rename("Montage_merged-1");
				selectWindow("Montage_merged");
				close();

			}
		} else {

			for(j = 0; j < montageArray.length; j++) {
				//select window
				selectWindow("Montage_ch"+montageArray[j]);
				//draw all ROIs
				roiManager("show all with labels");

				// flattenROIs
				run("Flatten");
				wait(100);

				//close unflatten image
				selectWindow("Montage_ch"+montageArray[j]);
				close();
			}
			if (Grayscale == 0) {
				//select window
				selectImage("Montage_merged");
				//draw all ROIs
				roiManager("show all with labels");

				// flatten ROIs
				run("Flatten");
				wait(100);

				rename("Montage_merged-1");
				selectWindow("Montage_merged");
				close();
			}
		}
	}

	//make montage
	run("Images to Stack", "name=Stack title=[] use");
	run("Make Montage...", "columns="+nSlices+" rows=1 scale=1 border=4");

	//add a scale bar if option selected
	if (ScaleBar){
		run("Scale Bar...", "width=10 height=10 thickness=10 font=30 color=White background=None location=[Lower Right] horizontal bold overlay");
		//flatten the scale bar
		run("Flatten");
		wait(100);
	selectWindow("Results");
	run("Close");
		//close unflatten image
		selectImage("Montage");
		close();
		selectImage("Montage-1");
		rename("Montage");
	}

	//save montage in pngDir
	selectImage("Montage");
	saveAs("png", pngDir+imgName+"_montage");
}