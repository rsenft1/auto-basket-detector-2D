# auto-basket-detector-2D
ImageJ macro scripts for analyzing fluorescent microscopy images: segmenting cells, divide into quadrants, and quantify innervation

# What is this repo for?
* This repo contains a number of scripts used in my paper for quantifying the pericellular basket-type innervation of fluorescently-labeled target cell soma
* These scripts work on 2D multichannel fluorescent images. They require a cell soma/cell marker channel (you could also use DAPI) and a fluorescent marker of innervation
    * Theoretically it could be brightfield, but it was made with fluorescence in mind.

# Macros/Scripts in repo (all are ImageJ macros written in the ImageJ macro language)
### Manual_cell_segmentation.ijm
* Performs user-assisted segmentation of cells using a magic wand tool
### Automatic_cell_segmentation.ijm
* Performs automatic segmentation of cells, specifically made with tiled images with uneven illumination in mind
### ROI_manual_remover.ijm
* Opens images and their associated ROIs from automatic or manual methods and allows the user to remove (or add, technically) ROIs
* Useful with the automatic method to correct for any inaccurate segmentation
### Quad_basket_quant.ijm
* Divides cell ROIs generated from previous two macros into quadrants
* Removes the center (to prevent a single bouton from being counted in all quadrants)
* Segments the innervation/fiber channel
* Quantifies the fiber area in each quadrant per cell
### Region_labeler.ijm
* Creates user-defined region ROIs for subregions within an image (e.g. cortical layer, hippocampal subfields)
### Region_analyzer.ijm
* Will sort cell ROIs from a previous manual or automatic segmentation method into the region ROIs made with Region_labeler.ijm
    
# How to cite this repo:
### If you want to use these scripts in your own research, please do! If you publish, please cite the original publication: Senft et al., 2020 (in press, more details added soon)

## If you experience any issues... Please feel free to raise it to me using the Issues section
