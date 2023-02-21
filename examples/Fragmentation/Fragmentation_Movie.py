#!/usr/bin/env python3
"""
 Copyright 2023 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
 This file is part of Swiftest.
 Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
 of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with Swiftest. 
 If not, see: https://www.gnu.org/licenses. 
"""

"""
Generates and runs a set of Swiftest input files from initial conditions with the SyMBA integrator. All simulation 
outputs are stored in the subdirectory named after their collisional regime. 

Inputs
_______
None.

Output
------
collisions.log   : An ASCII file containing the information of any collisional events that occured.
collisions.nc    : A NetCDF file containing the collision output.
data.nc          : A NetCDF file containing the simulation output.
encounters.nc    : A NetCDF file containing the encounter output.
init_cond.nc     : A NetCDF file containing the initial conditions for the simulation.
param.00...0.in  : A series of parameter input files containing the parameters for the simulation at every output stage.
param.in         : An ASCII file containing the inital parameters for the simulation.
param.restart.in : An ASCII file containing the parameters for the simulation at the last output. 
swiftest.log     : An ASCII file containing the information on the status of the simulation as it runs.
collision.mp4    : A movie file named after the collisional regime depicting the collision.

"""

import swiftest
import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from scipy.spatial.transform import Rotation as R

# ----------------------------------------------------------------------------------------------------------------------
# Define the names and initial conditions of the various fragmentation simulation types
# ----------------------------------------------------------------------------------------------------------------------
available_movie_styles = ["disruption_headon", "disruption_off_axis", "supercatastrophic_headon", "supercatastrophic_off_axis","hitandrun_disrupt", "hitandrun_pure", "merge", "merge_spinner"]
movie_title_list = ["Head-on Disruption", "Off-axis Disruption", "Head-on Supercatastrophic", "Off-axis Supercatastrophic", "Hit and Run w/ Runner Disruption", "Pure Hit and Run", "Merge", "Merge crossing the spin barrier"]
movie_titles = dict(zip(available_movie_styles, movie_title_list))
num_movie_frames = 1000

# These initial conditions were generated by trial and error
names = ["Target","Projectile"]
pos_vectors = {"disruption_headon"         : [np.array([1.0, -5.0e-05, 0.0]),
                                              np.array([1.0,  5.0e-05 ,0.0])],
              "disruption_off_axis"        : [np.array([1.0, -5.0e-05, 0.0]),
                                              np.array([1.0,  5.0e-05 ,0.0])], 
               "supercatastrophic_headon":   [np.array([1.0, -5.0e-05, 0.0]),
                                              np.array([1.0,  5.0e-05, 0.0])],
               "supercatastrophic_off_axis": [np.array([1.0, -5.0e-05, 0.0]),
                                              np.array([1.0,  5.0e-05, 0.0])],
               "hitandrun_disrupt"         : [np.array([1.0, -4.2e-05, 0.0]),
                                              np.array([1.0,  4.2e-05, 0.0])],
               "hitandrun_pure"            : [np.array([1.0, -4.2e-05, 0.0]),
                                              np.array([1.0,  4.2e-05, 0.0])],
               "merge"                      : [np.array([1.0, -5.0e-05, 0.0]),
                                              np.array([1.0,  5.0e-05 ,0.0])],
               "merge_spinner"               : [np.array([1.0, -5.0e-05, 0.0]),
                                              np.array([1.0,  5.0e-05 ,0.0])]                
               }

vel_vectors = {"disruption_headon"         : [np.array([ 0.00,  6.280005, 0.0]),
                                              np.array([ 0.00,  3.90,     0.0])],
               "disruption_off_axis"       : [np.array([ 0.00,  6.280005, 0.0]),
                                              np.array([ 0.05,  3.90,     0.0])],
               "supercatastrophic_headon":   [np.array([ 0.00,  6.28,     0.0]),
                                              np.array([ 0.00,  4.28,     0.0])],
               "supercatastrophic_off_axis": [np.array([ 0.00,  6.28,     0.0]),
                                              np.array([ 0.05,  4.28,     0.0])],
               "hitandrun_disrupt"         : [np.array([ 0.00,  6.28,     0.0]),
                                              np.array([-1.45, -6.28,     0.0])],
               "hitandrun_pure"            : [np.array([ 0.00,  6.28,     0.0]),
                                              np.array([-1.52, -6.28,     0.0])],
               "merge"                     : [np.array([ 0.04,  6.28,     0.0]),
                                              np.array([ 0.05,  6.18,     0.0])],
               "merge_spinner"             : [np.array([ 0.04,  6.28,     0.0]),
                                              np.array([ 0.05,  6.18,     0.0])] 
               }

rot_vectors = {"disruption_headon"         : [np.array([0.0, 0.0, 1.0e5]),
                                              np.array([0.0, 0.0, -5e5])],
               "disruption_off_axis":        [np.array([0.0, 0.0, 2.0e5]),
                                              np.array([0.0, 0.0, -1.0e5])],
               "supercatastrophic_headon":   [np.array([0.0, 0.0, 1.0e5]),
                                              np.array([0.0, 0.0, -5.0e5])],
               "supercatastrophic_off_axis": [np.array([0.0, 0.0, 1.0e5]),
                                              np.array([0.0, 0.0, -1.0e4])],
               "hitandrun_disrupt"         : [np.array([0.0, 0.0, 0.0]),
                                              np.array([0.0, 0.0, 1.0e5])],
               "hitandrun_pure"            : [np.array([0.0, 0.0, 0.0]),
                                              np.array([0.0, 0.0, 1.0e5])],
               "merge"                     : [np.array([0.0, 0.0, 0.0]),
                                              np.array([0.0, 0.0, 0.0])],
               "merge_spinner"             : [np.array([0.0, 0.0, -1.2e6]),
                                              np.array([0.0, 0.0, 0.0])],
               }

body_Gmass = {"disruption_headon"        : [1e-7, 1e-9],
             "disruption_off_axis"       : [1e-7, 1e-9],
             "supercatastrophic_headon"  : [1e-7, 1e-8],
             "supercatastrophic_off_axis": [1e-7, 1e-8],
             "hitandrun_disrupt"         : [1e-7, 7e-10],
             "hitandrun_pure"            : [1e-7, 7e-10],
             "merge"                     : [1e-7, 1e-8],
             "merge_spinner"             : [1e-7, 1e-8] 
               }

tstop = {"disruption_headon"         : 2.0e-3,
         "disruption_off_axis"       : 2.0e-3,
         "supercatastrophic_headon"  : 2.0e-3,
         "supercatastrophic_off_axis": 2.0e-3,
         "hitandrun_disrupt"         : 2.0e-4,
         "hitandrun_pure"            : 2.0e-4,
         "merge"                     : 5.0e-3,
         "merge_spinner"             : 5.0e-3,
         }

nfrag_reduction = {"disruption_headon" : 1.0,
         "disruption_off_axis"         : 1.0,
         "supercatastrophic_headon"    : 1.0,
         "supercatastrophic_off_axis"  : 1.0,
         "hitandrun_disrupt"           : 1.0,
         "hitandrun_pure"              : 1.0,
         "merge"                       : 1.0,
         "merge_spinner"               : 1.0,
         }

density = 3000 * swiftest.AU2M**3 / swiftest.MSun
GU = swiftest.GMSun * swiftest.YR2S**2 / swiftest.AU2M**3
body_radius = body_Gmass.copy()
for k,v in body_Gmass.items():
    body_radius[k] = [((Gmass/GU)/(4./3.*np.pi*density))**(1./3.) for Gmass in v]

body_radius["hitandrun_disrupt"] = [7e-6, 3.25e-6] 
body_radius["hitandrun_pure"] = [7e-6, 3.25e-6] 

# ----------------------------------------------------------------------------------------------------------------------
# Define the animation class that will generate the movies of the fragmentation outcomes
# ----------------------------------------------------------------------------------------------------------------------


def encounter_combiner(sim):
    """
    Combines simulation data with encounter data to produce a dataset that contains the position,
    mass, radius, etc. of both. It will interpolate over empty time values to fill in gaps.
    """

    # Only keep a minimal subset of necessary data from the simulation and encounter datasets
    keep_vars = ['name','rh','vh','Gmass','radius','rot']
    data = sim.data[keep_vars]
    enc = sim.encounters[keep_vars].load()

    # Remove any encounter data at the same time steps that appear in the data to prevent duplicates
    t_not_duplicate = ~data['time'].isin(enc['time'])
    data = data.sel(time=t_not_duplicate)
    tgood=enc.time.where(~np.isnan(enc.time),drop=True)
    enc = enc.sel(time=tgood)

    # The following will combine the two datasets along the time dimension, sort the time dimension, and then fill in any time gaps with interpolation
    ds = xr.combine_nested([data,enc],concat_dim='time').sortby("time").interpolate_na(dim="time", method="akima")
    
    # Rename the merged Target body so that their data can be combined
    tname=[n for n in ds['name'].data if names[0] in n]
    nottname=[n for n in ds['name'].data if names[0] not in n]
    dslist = []
    for n in tname:
        dsnew = ds.sel(name=n)
        dsnew['name'] = names[0]
        dslist.append(dsnew)

    newds = xr.merge(dslist,compat="no_conflicts") 
    ds = xr.combine_nested([ds.sel(name=nottname),newds],concat_dim="name")
   
    # Interpolate in time to make a smooth, constant time step dataset 
    # Add a bit of padding to the time, otherwise there are some issues with the interpolation in the last few frames.
    smooth_time = np.linspace(start=ds.time[0], stop=ds.time[-1], num=int(1.2*num_movie_frames))
    ds = ds.interp(time=smooth_time)
    ds['rotangle'] = xr.zeros_like(ds['rot'])
    ds['rot'] = ds['rot'].fillna(0.0)

    return ds

def center(Gmass, x, y):
    x = x[~np.isnan(x)]
    y = y[~np.isnan(y)]
    Gmass = Gmass[~np.isnan(Gmass)]
    x_com = np.sum(Gmass * x) / np.sum(Gmass)
    y_com = np.sum(Gmass * y) / np.sum(Gmass)
    return x_com, y_com 
class AnimatedScatter(object):
    """An animated scatter plot using matplotlib.animations.FuncAnimation."""

    def __init__(self, sim, animfile, title, style, nskip=1):
        self.sim = sim
        self.ds = encounter_combiner(sim)
        self.npl = len(self.ds['name']) - 1
        self.title = title
        self.body_color_list = {'Initial conditions': 'xkcd:windows blue',
                      'Disruption': 'xkcd:baby poop',
                      'Supercatastrophic': 'xkcd:shocking pink',
                      'Hit and run fragmention': 'xkcd:blue with a hint of purple',
                      'Central body': 'xkcd:almost black'}

        # Set up the figure and axes...
        self.figsize = (4,4)
        self.fig, self.ax = self.setup_plot()
        self.ani = animation.FuncAnimation(self.fig, self.update_plot, init_func=self.init_func, interval=1, frames=range(0,num_movie_frames,nskip), blit=True)
        self.ani.save(animfile, fps=60, dpi=300, extra_args=['-vcodec', 'libx264'])
        print(f"Finished writing {animfile}")

    def setup_plot(self):
        fig = plt.figure(figsize=self.figsize, dpi=300)
        plt.tight_layout(pad=0)

        # Calculate the distance along the y-axis between the colliding bodies at the start of the simulation.
        # This will be used to scale the axis limits on the movie.
        rhy1 = self.sim.data['rh'].sel(name=names[0],space='y').isel(time=0).values[()]
        rhy2 = self.sim.data['rh'].sel(name=names[1],space='y').isel(time=0).values[()]

        scale_frame =   abs(rhy1) + abs(rhy2)
        if "hitandrun" in style:
           scale_frame *= 2
           
        ax = plt.Axes(fig, [0.1, 0.1, 0.8, 0.8])
        self.ax_pt_size = self.figsize[0] *  72 / scale_frame  * 0.7
        ax.set_xlim(-scale_frame, scale_frame)
        ax.set_ylim(-scale_frame, scale_frame)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_xlabel("x")
        ax.set_ylabel("y")
        ax.set_title(self.title)
        fig.add_axes(ax)

        return fig, ax
    
    def init_func(self):
        self.artists = [] 
        aarg = self.vec_props('xkcd:beige')
        for i in range(self.npl):
            self.artists.append(self.ax.annotate("",xy=(0,0),**aarg)) 
        
        self.artists.append(self.ax.scatter([],[],c='k', animated=True, zorder=10))
        return self.artists

    def update_plot(self, frame):
        # Define a function to calculate a reference frame for the animation
        # This will be based on the initial velocity of the Target body

        t, Gmass, rh, radius, rotangle = next(self.data_stream(frame))
        x_ref, y_ref = center(Gmass, rh[:,0], rh[:,1]) 
        rh = np.c_[rh[:,0] - x_ref, rh[:,1] - y_ref]
        self.artists[-1].set_offsets(rh)
        point_rad = radius * self.ax_pt_size
        self.artists[-1].set_sizes(point_rad**2)
        
        sarrowend, sarrowtip = self.spin_arrows(rh, rotangle, 1.1*radius) 
        for i, s in enumerate(self.artists[:-1]):
            self.artists[i].set_position(sarrowtip[i])
            self.artists[i].xy = sarrowend[i]
        
        return self.artists

    def data_stream(self, frame=0):
        while True:
            t = self.ds.isel(time=frame)['time'].values[()]
            
            if frame > 0:
                dsold = self.ds.isel(time=frame-1)
                told = dsold['time'].values[()]
                dt = t - told
                self.ds['rotangle'][dict(time=frame)] = dsold['rotangle'] + dt * dsold['rot']
            
            ds = self.ds.isel(time=frame)
            ds = ds.where(ds['name'] != "Sun", drop=True)
            radius = ds['radius'].values
            Gmass = ds['Gmass'].values
            rh = ds['rh'].values
            rotangle = ds['rotangle'].values

            yield t, Gmass, rh, radius, rotangle
            
    def spin_arrows(self, rh, rotangle, rotlen):
        px = rh[:, 0]
        py = rh[:, 1]
        sarrowend = []
        sarrowtip = []
        for i in range(rh.shape[0]):
            endrel = np.array([0.0, -rotlen[i],  0.0])
            tiprel = np.array([0.0, rotlen[i], 0.0])
            r = R.from_rotvec(rotangle[i,:], degrees=True)
            endrel = r.apply(endrel)
            tiprel = r.apply(tiprel)
            send = (px[i] + endrel[0], py[i] + endrel[1])
            stip = (px[i] + tiprel[0], py[i] + tiprel[1])
            sarrowend.append(send)
            sarrowtip.append(stip)
        return sarrowend, sarrowtip
    
    def vec_props(self, c):
        arrowprops = {
            'arrowstyle': '-',
            'linewidth' : 1,
        }

        arrow_args = {
            'xycoords': 'data',
            'textcoords': 'data',
            'arrowprops': arrowprops,
            'annotation_clip': True,
            'zorder': 100,
            'animated' : True
        }
        aarg = arrow_args.copy()
        aprop = arrowprops.copy()
        aprop['color'] = c
        aarg['arrowprops'] = aprop
        aarg['color'] = c
        return aarg    
    
if __name__ == "__main__":

    print("Select a fragmentation movie to generate.")
    print("1. Head-on disruption")
    print("2. Off-axis disruption")
    print("3. Head-on supercatastrophic")
    print("4. Off-axis supercatastrophic")
    print("5. Hit and run with disruption of the runner")
    print("6. Pure hit and run")
    print("7. Merge")
    print("8. Merge crossing the spin barrier")
    print("9. All of the above")
    user_selection = int(input("? "))

    if user_selection > 0 and user_selection < 9:
        movie_styles = [available_movie_styles[user_selection-1]]
    else:
        print("Generating all movie styles")
        movie_styles = available_movie_styles.copy()

    for style in movie_styles:
        print(f"Generating {movie_titles[style]}")
        movie_filename = f"{style}.mp4"
        # Pull in the Swiftest output data from the parameter file and store it as a Xarray dataset.
        sim = swiftest.Simulation(simdir=style, rotation=True, init_cond_format = "XV", compute_conservation_values=True)
        sim.add_solar_system_body("Sun")
        sim.add_body(name=names, Gmass=body_Gmass[style], radius=body_radius[style], rh=pos_vectors[style], vh=vel_vectors[style], rot=rot_vectors[style])

        # Set fragmentation parameters
        minimum_fragment_gmass = 0.01 * body_Gmass[style][1] 
        gmtiny = 0.10 * body_Gmass[style][1] 
        sim.set_parameter(collision_model="fraggle", encounter_save="both", gmtiny=gmtiny, minimum_fragment_gmass=minimum_fragment_gmass, nfrag_reduction=nfrag_reduction[style])
        sim.run(dt=5e-4, tstop=tstop[style], istep_out=1, dump_cadence=0)

        print("Generating animation")
        anim = AnimatedScatter(sim,movie_filename,movie_titles[style],style,nskip=1)
