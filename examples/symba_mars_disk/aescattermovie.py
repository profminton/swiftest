#!/usr/bin/env python3
import swiftest 
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import animation
import matplotlib.colors as mcolors

titletext = "High M - High e"
radscale = 1000
RMars = 3389500.0
xmin = 1.0
xmax = 10.0
ymin = 1e-6
ymax = 1.0
framejump = 1
ncutoff = 1e20

class AnimatedScatter(object):
    """An animated scatter plot using matplotlib.animations.FuncAnimation."""
    def __init__(self, ds, param):

        frame = 0
        self.ds = ds
        self.nframes = int(ds['time'].size / framejump)
        self.Rcb = self.ds['radius'].sel(id=0, time=0).values
        self.ds = ds
        self.param = param
        self.clist = {'Initial conditions' : 'xkcd:faded blue',
                      'Disruption' : 'xkcd:marigold',
                      'Supercatastrophic' : 'xkcd:shocking pink',
                      'Hit and run fragment' : 'xkcd:baby poop green'}

        # Setup the figure and axes...
        fig = plt.figure(figsize=(8,4.5), dpi=300)
        plt.tight_layout(pad=0)
        # set up the figure
        self.ax = plt.Axes(fig, [0.1, 0.15, 0.8, 0.75])
        self.ax.set_xlim(xmin, xmax)
        self.ax.set_ylim(ymin, ymax)
        fig.add_axes(self.ax)
        self.ani = animation.FuncAnimation(fig, self.update, interval=1, frames=self.nframes, init_func=self.setup_plot, blit=True)
        #self.ani.save('aescatter.mp4', fps=30, dpi=300, extra_args=['-vcodec', 'libx264'])
        self.ani.save('aescatter.mp4', fps=30, dpi=300, extra_args=['-vcodec', 'mpeg4'])
        print('Finished writing aescattter.mp4')

    def scatters(self, pl, radmarker, origin):
        scat = []
        for key, value in self.clist.items():
            idx = origin == key
            s = self.ax.scatter(pl[idx, 0], pl[idx, 1], marker='o', s=radmarker[idx], c=value, alpha=0.75, label=key)
            scat.append(s)
        return scat

    def setup_plot(self):
        # First frame
        """Initial drawing of the scatter plot."""
        t, name, Gmass, radius, npl, pl, radmarker, origin = next(self.data_stream(0))

        # set up the figure
        self.ax.margins(x=10, y=1)
        self.ax.set_xlabel('Semi Major Axis ($R_{Mars}$)', fontsize='16', labelpad=1)
        self.ax.set_ylabel('Eccentricity', fontsize='16', labelpad=1)
        self.ax.set_yscale('log')

        self.title = self.ax.text(0.50, 1.05, "", bbox={'facecolor': 'w', 'alpha': 0.5, 'pad': 5}, transform=self.ax.transAxes,
                        ha="center", animated=True)

        self.title.set_text(f"{titletext} - Time = ${t / 24 / 3600:4.1f}$ days with ${npl:f}$ particles")
        slist = self.scatters(pl, radmarker, origin)
        self.s0 = slist[0]
        self.s1 = slist[1]
        self.s2 = slist[2]
        self.s3 = slist[3]
        self.ax.legend(loc='upper right')
        return self.s0, self.s1, self.s2, self.s3, self.title

    def data_stream(self, frame=0):
        while True:
            d = self.ds.isel(time=frame)

            d = d.where(d['radius'] < self.Rcb, drop=True)
            d['radmarker'] = (d['radius'] / self.Rcb) * radscale
            radius = d['radmarker'].values

            Gmass = d['Gmass'].values
            a = d['a'].values / self.Rcb
            e = d['e'].values
            name = d['id'].values
            npl = d['npl'].values[0]
            radmarker = d['radmarker']
            origin = d['origin_type'].values

            t = self.ds.coords['time'].values[frame]

            frame += 1
            yield t, name, Gmass, radius, npl, np.c_[a, e], radmarker, origin

    def update(self,frame):
        """Update the scatter plot."""
        t, name, Gmass, radius, npl, pl, radmarker, origin = next(self.data_stream(framejump * frame))

        self.title.set_text(f"{titletext} - Time = ${t / 24 / 3600:4.1f}$ days with ${npl:4.0f}$ particles")

        # We need to return the updated artist for FuncAnimation to draw..
        # Note that it expects a sequence of artists, thus the trailing comma.
        s = [self.s0, self.s1, self.s2, self.s3]
        for i, (key, value) in enumerate(self.clist.items()):
            idx = origin == key
            s[i].set_sizes(radmarker[idx])
            s[i].set_offsets(pl[idx,:])
            s[i].set_facecolor(value)

        self.s0 = s[0]
        self.s1 = s[1]
        self.s2 = s[2]
        self.s3 = s[3]
        return self.s0, self.s1, self.s2, self.s3, self.title,

sim = swiftest.Simulation(param_file="param.in")
sim.bin2xr()
print('Making animation')
anim = AnimatedScatter(sim.ds,sim.param)
print('Animation finished')
