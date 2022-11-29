"""
 Copyright 2022 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
 This file is part of Swiftest.
 Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
 of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with Swiftest. 
 If not, see: https://www.gnu.org/licenses. 
"""

#!/usr/bin/env python3
"""
Generates a movie of a fragmentation event from set of Swiftest output files.

Inputs
_______
param.in : ASCII text file
    Swiftest parameter input file.
out.nc   : NetCDF file
    Swiftest output file.

Returns
-------
fragmentation.mp4 : mp4 movie file
    Movie of a fragmentation event.
"""

import swiftest
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from pathlib import Path

print("Select a fragmentation movie to generate.")
print("1. Head-on disruption")
print("2. Off-axis supercatastrophic")
print("3. Hit and run")
print("4. All of the above")
user_selection = int(input("? "))

available_movie_styles = ["disruption_headon", "supercatastrophic_off_axis", "hitandrun"]
movie_title_list = ["Head-on Disrutption", "Off-axis Supercatastrophic", "Hit and Run"]
movie_titles = dict(zip(available_movie_styles, movie_title_list))

# These initial conditions were generated by trial and error
pos_vectors = {"disruption_headon"         : [np.array([1.0, -1.807993e-05, 0.0]),
                                              np.array([1.0,  1.807993e-05 ,0.0])],
               "supercatastrophic_off_axis": [np.array([1.0, -4.2e-05,      0.0]),
                                              np.array([1.0,  4.2e-05,      0.0])],
               "hitandrun"                 : [np.array([1.0, -4.2e-05,      0.0]),
                                              np.array([1.0,  4.2e-05,      0.0])]
               }

vel_vectors = {"disruption_headon"         : [np.array([-2.562596e-04,  6.280005, 0.0]),
                                              np.array([-2.562596e-04, -6.280005, 0.0])],
               "supercatastrophic_off_axis": [np.array([0.0,            6.28,     0.0]),
                                              np.array([1.0,           -6.28,     0.0])],
               "hitandrun"                 : [np.array([0.0,            6.28,     0.0]),
                                              np.array([-1.5,          -6.28,     0.0])]
               }

rot_vectors = {"disruption_headon"         : [np.array([0.0, 0.0, 0.0]),
                                              np.array([0.0, 0.0, 0.0])],
               "supercatastrophic_off_axis": [np.array([0.0, 0.0, -6.0e4]),
                                              np.array([0.0, 0.0, 1.0e5])],
               "hitandrun"                 : [np.array([0.0, 0.0, 6.0e4]),
                                              np.array([0.0, 0.0, 1.0e5])]
               }

body_Gmass = {"disruption_headon"        : [1e-7, 1e-10],
             "supercatastrophic_off_axis": [1e-7, 1e-8],
             "hitandrun"                 : [1e-7, 7e-10]
               }

density = 3000 * swiftest.AU2M**3 / swiftest.MSun
GU = swiftest.GMSun * swiftest.YR2S**2 / swiftest.AU2M**3
body_radius = body_Gmass.copy()
for k,v in body_Gmass.items():
    body_radius[k] = [((Gmass/GU)/(4./3.*np.pi*density))**(1./3.) for Gmass in v]

if user_selection > 0 and user_selection < 4:
   movie_styles = [available_movie_styles[user_selection-1]]
else:
   print("Generating all movie styles")
   movie_styles = available_movie_styles.copy()

# Define a function to calculate the center of mass of the system.
def center(xhx, xhy, xhz, Gmass):
    x_com = np.sum(Gmass * xhx) / np.sum(Gmass)
    y_com = np.sum(Gmass * xhy) / np.sum(Gmass)
    z_com = np.sum(Gmass * xhz) / np.sum(Gmass)
    return x_com, y_com, z_com

def animate(i,ds,movie_title):

    # Calculate the position and mass of all bodies in the system at time i and store as a numpy array.
    xhx = ds['xhx'].isel(time=i).dropna(dim='name').values
    xhy = ds['xhy'].isel(time=i).dropna(dim='name').values
    xhz = ds['xhx'].isel(time=i).dropna(dim='name').values
    Gmass = ds['Gmass'].isel(time=i).dropna(dim='name').values[1:]  # Drop the Sun from the numpy array.

    # Calculate the center of mass of the system at time i. While the center of mass relative to the
    # colliding bodies does not change, the center of mass of the collision will move as the bodies
    # orbit the system center of mass.
    x_com, y_com, z_com = center(xhx, xhy, xhz, Gmass)

    # Create the figure and plot the bodies as points.
    fig.clear()
    ax = fig.add_subplot(111)
    ax.set_title(movie_title)
    ax.set_xlabel("xhx")
    ax.set_ylabel("xhy")
    ax.set_xlim(x_com - scale_frame, x_com + scale_frame)
    ax.set_ylim(y_com - scale_frame, y_com + scale_frame)
    ax.grid(False)
    ax.set_xticks([])
    ax.set_yticks([])

    ax.scatter(xhx, xhy, s=(5000000000 * Gmass))

    plt.tight_layout()

for style in movie_styles:
    param_file = Path(style) / "param.in"

    movie_filename = f"{style}.mp4"

    # Pull in the Swiftest output data from the parameter file and store it as a Xarray dataset.
    sim = swiftest.Simulation(param_file=param_file, rotation=True, init_cond_format = "XV", compute_conservation_values=True)
    sim.add_solar_system_body("Sun")
    sim.add_body(Gmass=body_Gmass[style], radius=body_radius[style], xh=pos_vectors[style], vh=vel_vectors[style], rot=rot_vectors[style])

    # Set fragmentation parameters
    minimum_fragment_gmass = 0.2 * body_Gmass[style][1] # Make the minimum fragment mass a fraction of the smallest body
    gmtiny = 0.99 * body_Gmass[style][1] # Make GMTINY just smaller than the smallest original body. This will prevent runaway collisional cascades
    sim.set_parameter(fragmentation = True, gmtiny=gmtiny, minimum_fragment_gmass=minimum_fragment_gmass)
    sim.run(dt=1e-8, tstop=1.e-5)

    # Calculate the number of frames in the dataset.
    nframes = int(sim.data['time'].size)

    # Calculate the distance along the y-axis between the colliding bodies at the start of the simulation.
    # This will be used to scale the axis limits on the movie.
    scale_frame = abs(sim.data['xhy'].isel(time=0, name=1).values) + abs(sim.data['xhy'].isel(time=0, name=2).values)

    # Set up the figure and the animation.
    fig, ax = plt.subplots(figsize=(4,4))
    # Generate the movie.
    ani = animation.FuncAnimation(fig, animate, fargs=(sim.data, movie_titles[style]), interval=1, frames=nframes, repeat=False)
    ani.save(movie_filename, fps=60, dpi=300, extra_args=['-vcodec', 'libx264'])