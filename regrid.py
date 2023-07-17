#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Regrid ocean data from native grid to 1x1 regular lat x lon grid using bilinear 
regridding.
"""

import os
import xarray as xr
import xesmf as xe
import dask
from glob import glob

def regrid_and_save(file, out_ds, wgts_dir):
    model_name = os.path.basename(file).split('_')[2]
    weight_file = os.path.join(weights_dir, f'wgts_conservative_{model_name}.nc')
    regridded_file = file.replace('.nc', '_gr.nc')

    # Check if regridded file already exists
    if not os.path.exists(regridded_file):
        ds = xr.open_dataset(file, chunks={"time": 10})

        # Rename latitude and longitude coordinates
        ds = ds.rename({"latitude": "lat", "longitude": "lon"})

        # Check if weights file exists
        if os.path.exists(weight_file):
            regridder = xe.Regridder(ds, out_ds, 'bilinear', 
                                     filename=weight_file, 
                                     ignore_degenerate=True, 
                                     reuse_weights=True)
        else:
            regridder = xe.Regridder(ds, out_ds, 'bilinear', 
                                     filename=weight_file, 
                                     ignore_degenerate=True, 
                                     reuse_weights=False)

        ds_regridded = regridder(ds)
        ds_regridded.to_netcdf(regridded_file)

data_dir = '/scratch/groups/earlew/yuchen/cmip6/piControl/Oann/so'
weights_dir = '/scratch/groups/earlew/yuchen/cmip6/ocean_grids'
os.makedirs(weights_dir, exist_ok=True)

files = sorted(glob(os.path.join(data_dir, '*.nc')))
files = [file for file in files if '_gr' not in file]

# Define target grid (1x1 degree)
out_ds = xe.util.grid_global(1, 1)

for file in files:
    print(f'processing {file}')
    regrid_and_save(file, out_ds, weights_dir)