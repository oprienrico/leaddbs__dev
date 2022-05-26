MATLAB Mex for a isosurface computation from voxel volume based on Dual Marching cubes algorithm.
This is can be used as substitute of isosuface and isocaps in matlab.
The resulting isosurface is topologically correct and manifold.

Based on the work of Roberto Grosso and Daniel Zint
https://link.springer.com/article/10.1007/s00371-021-02139-w
Github: https://github.com/rogrosso/tmc


Usage: 
bb_x: bounding box in mm for the X axis (two elememts, min and max)
bb_y: bounding box in mm for the Y axis (two elememts, min and max)
bb_z: bounding box in mm for the Z axis (two elememts, min and max)

voxel_volume: voxel volume (double values)
iso_value: value at which to compute the isosurface, specified as a scalar (double).

[vertices, faces]=eo_mdmc_mex(bb_x,bb_y,bb_z, voxel_volume, iso_value);