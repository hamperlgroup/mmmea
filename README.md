# mmmea

ABOUT

The Fiji macro is used for single cell fluorescence characterization from microscopy images. It will extract single cell information regarding the size, position, and fluorescence signal in all channels. Additionally, it can measure fluorescence colocalization and count foci. The macro is compatible with any image extension but has only been tested on .lif, .ims, and .tiff files. The macro is also compatible with XY and XYZ images. When using a Z stack, the macro does not work in 3D but can work on projections, on all Z planes individually, or identify a focal plane for specified measurements.

To run an automated analysis, a few parameters need to be specified by the user. This requires some manual testing and visual inspection/validation of the selected parameters. A test function is available to test how certain combination of parameters affects the image analysis. Important parameters in this regard are how to properly segment nuclei, how to threshold positive signal for colocalization analysis, and how to threshold foci detection.

TUTORIAL



PREREQUISITE

ImageJ (or Fiji) must be installed to use the plugin.

To use the macro, you need to first make sure you run the latest Fiji version (Help/Update ImageJ…) (last tested version was v1.54c) and download the macro (MMMEA.ijm). The macro can be called in Fiji (Plugins/Macros/Run…). 

The macro uses pre-existing plugins in some of its function which need to be installed:

•	To open images, the macro uses Bio-formats which needs to be added to the list of update sites of Fiji (Help/Update…/Manage update sites).

•	If ROI segmentation is done via Stardist, Stardist also needs to be added to the list of update sites.

•	If ROI segmentation is done via Stardist, a Stardist model is needed.

•	To measure colocalization, the macro uses the EZcolocalization plugin. The plugin can be downloaded from https://github.com/DrHanLim/EzColocalization and moved to the plugin folder of Fiji.

•	If additional channels need to be added and aligned to the original images, the macro uses the turboreg and hyperstackreg tools that can be downloaded from http://bigwww.epfl.ch/thevenaz/turboreg/ and https://github.com/ved-sharma/HyperStackReg and moved to the plugin folder of Fiji.

KNOWN ISSUES

• when making a png montage, selecting the grey color breaks the code for unknown reason.

• the png montage function can be glitchy and will sometime skip adding ROI borders for example.

AUTHORS

Maxime Lalonde, main author
Manuel Trauner, contributor
Andreas Ettinger, contributor



HOW TO CITE






