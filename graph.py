'''
Created on Aug 25, 2021
@author: varikmp
'''

import sys
import matplotlib.pyplot as plt
import matplotlib as mpl
import plotly.graph_objects as go
import pandas as pd
import numpy as np
import pandas as pd
from pandas.api.types import is_string_dtype
from pandas.api.types import is_numeric_dtype

config = dict()
config['report_file'] = 'deltas.csv'

def plot_single(report_file, field):
    plot_multiple(report_file, fields = [field])

# plot the graph from the report file
def plot_multiple(report_file, fields = None, image_file = None):
    df = pd.read_csv(report_file)
    df['TimeSteps'] = np.arange(0, len(df))
    
    if fields is None:
        fields = df.columns
    else:
        metrics = []
        for field in fields:
            if field[:-1] in list(df.columns):
                metrics.append(field[:-1])

    for metric in metrics:
        if is_numeric_dtype(df[metric]):
            lower_bound = df[metrics[0]].min()
            upper_bound = df[metrics[0]].max()
    
    for metric in metrics:
        if is_numeric_dtype(df[metric]):
            # plot the line segments
            plt.plot(df['TimeSteps'], df[metric], label=metric)
            # update the boundary
            min_value = df[metric].min()
            max_value = df[metric].max()
            if lower_bound > min_value:
                lower_bound = min_value
            if upper_bound < max_value:
                upper_bound = max_value
    
    # https://newbedev.com/how-to-remove-frame-from-matplotlib-pyplot-figure-vs-matplotlib-figure-frameon-false-problematic-in-matplotlib
    ax = plt.gca()
    ax.spines["top"].set_visible(False)
    ax.spines["bottom"].set_visible(False)
    ax.spines["left"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.set_facecolor('#e5ecf6')
    ax.xaxis.tick_bottom()
    ax.yaxis.tick_left()
    
    # https://jakevdp.github.io/PythonDataScienceHandbook/04.10-customizing-ticks.html
    #ax.yaxis.set_major_locator(plt.LinearLocator(numticks=9))
    #ax.yaxis.set_major_locator(plt.MultipleLocator(base=5))
    
    #plt.ylabel(y_axis)

    if len(fields) > 1:
        plt.legend()
        plt.title('Container Profiler')
    else:
        plt.title(fields[0])
    plt.ylabel('Runtime (in centiseconds)')
    plt.xlabel('Time Steps (in seconds)')

    ax.set_xlim(xmin=0, xmax=len(df)-1)
    ax.set_ylim(ymin=lower_bound, ymax=upper_bound)
    
    # linestyle = '-', '--', '-.', ':', 'None', ' ', '', 'solid', 'dashed', 'dashdot', 'dotted'
    plt.grid(color = 'white', linestyle = 'solid', linewidth = 1)
    plt.grid(True)
    
    if image_file is not None:
        plt.savefig(image_file, bbox_inches='tight', dpi=100, transparent=False)
    else:
        plt.show()
    plt.clf()

if __name__ == '__main__':
    
#     delta_file = sys.argv[0]
#     config_file = sys.argv[1]
    delta_file = "deltas.csv"
    config_file = "graph.ini"
    image_file = "graph.png"

    file = open(config_file, "r")
    metrics = [metric for metric in file.readlines()]
    
    #plot_single(delta_file, 'vCpuTime')
    plot_multiple(delta_file, fields = metrics)




