'''
Created on Aug 25, 2021
@author: varikmp
'''

import sys
import matplotlib.pyplot as plt
#import plotly.graph_objects as go
import numpy as np
import pandas as pd
from pandas.api.types import is_string_dtype
from pandas.api.types import is_numeric_dtype

config = dict()
config['report_file'] = 'delta.csv'

def plot_single(report_file, group, key, image_dir):
    df = pd.read_csv(report_file)
    df['TimeSteps'] = np.arange(0, len(df))
    unit = group["unit"]
    fields = group["metrics"]
    
    for field in fields:
        metric = field[:-1]
        metric = metric.lstrip()
        if metric[0] == '#':
            continue
        if metric not in df.columns:
            print('Could not find the metric "{}"'.format(metric))
            continue
        if is_numeric_dtype(df[metric]):
            # plot the line segments
            plt.plot(df['TimeSteps'], df[metric], label=metric)

            ax = plt.gca()
            ax.spines["top"].set_visible(False)
            ax.spines["bottom"].set_visible(False)
            ax.spines["left"].set_visible(False)
            ax.spines["right"].set_visible(False)
            ax.set_facecolor('#e5ecf6')
            ax.xaxis.tick_bottom()
            ax.yaxis.tick_left()

            # print(metric)
            min_val = df[metric].min()
            max_val = df[metric].max()
            ax.set_xlim(xmin=0, xmax=len(df)-1)
            if min_val != max_val:
                ax.set_ylim(ymin=df[metric].min(), ymax=df[metric].max())

            plt.title(metric)
            plt.ylabel(unit)
            plt.xlabel('Time Steps')
        
            # linestyle = '-', '--', '-.', ':', 'None', ' ', '', 'solid', 'dashed', 'dashdot', 'dotted'
            plt.grid(color = 'white', linestyle = 'solid', linewidth = 1)
            plt.grid(True)
            plt.savefig('{}/{}'.format(image_dir, metric), bbox_inches='tight', dpi=100, transparent=False)
            plt.clf()

# plot the graph from the report file
def plot_multiple(report_file, group, key, idx, image_dir = None, fields = None):
    df = pd.read_csv(report_file)
    df['TimeSteps'] = np.arange(0, len(df))
    unit = group["unit"]
    fields = group["metrics"]
    
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

    plt.legend()
    plt.title(key)
    plt.ylabel(unit)
    plt.xlabel('Time Steps')

    ax.set_xlim(xmin=0, xmax=len(df)-1)
    ax.set_ylim(ymin=lower_bound, ymax=upper_bound)
    
    # linestyle = '-', '--', '-.', ':', 'None', ' ', '', 'solid', 'dashed', 'dashdot', 'dotted'
    plt.grid(color = 'white', linestyle = 'solid', linewidth = 1)
    plt.grid(True)
    
    if image_dir is not None:
        plt.savefig('{}/{}'.format(image_dir, "profiler_{}.png".format(idx)), bbox_inches='tight', dpi=100, transparent=False)
    else:
        plt.show()
    plt.clf()

if __name__ == '__main__':
    
    delta_file = "./delta.csv"
    config_file = "./graph.default.cfg"
    image_dir = "./"

    is_single_plot = None
    count = len(sys.argv)
    if count > 1:
        delta_file = sys.argv[1]
    if count > 2:
        image_dir = sys.argv[2]
    if count > 3:
        config_file = sys.argv[3]
    if count > 4:
        is_single_plot = sys.argv[4]

    group_name = "Unknown"
    metric_groups = {}
    metric_groups[group_name] = {}
    metric_groups[group_name]["unit"] = "Unspecified"
    metric_groups[group_name]["metrics"] = []
    with open(config_file, 'r') as infile:
        for line in infile:
            if line.startswith("###"):
                data = line[3:-1].split(",")
                group_name = data[0]
                metric_groups[group_name] = {}
                if len(data) > 1:
                    metric_groups[group_name]["unit"] = data[1]
                else:
                    metric_groups[group_name]["unit"] = "Unspecified"
                metric_groups[group_name]["metrics"] = []
            elif line.startswith("#"):
                continue
            else:
                metric_groups[group_name]["metrics"].append(line)
    metric_groups.pop("Unknown", None)

    if is_single_plot is not None:
        for key in metric_groups.keys():
            plot_single(delta_file, metric_groups[key], key, image_dir)
    else:
        for idx, key in enumerate(metric_groups.keys()):
            plot_multiple(delta_file, metric_groups[key], key, idx, image_dir)

