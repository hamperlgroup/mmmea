# mmmea

General

The Fiji macro is used for single cell fluorescence characterization from microscopy images. It will extract single cell information regarding the size, position, and fluorescence signal in all channels. Additionally, it can measure fluorescence colocalization and count foci. The macro is compatible with any image extension but has only been tested on .lif, .ims, and .tiff files. The macro is also compatible with XY and XYZ images. When using a Z stack, the macro does not work in 3D but can work on projections, on all Z planes individually, or identify a focal plane for specified measurements.
To run an automated analysis, a few parameters need to be specified by the user. This requires some manual testing and visual inspection/validation of the selected parameters. A test function is available to test how certain combination of parameters affects the image analysis. Important parameters in this regard are how to properly segment nuclei, how to threshold positive signal for colocalization analysis, and how to threshold foci detection.
