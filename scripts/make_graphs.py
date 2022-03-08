from cProfile import label
import os
from turtle import pos, position, width
import numpy

import matplotlib.pyplot as pyplot

RESULTS_FOLDER = "/home/patch_of_scotland/Documents/Docker/docker-slurm/scripts/results"
GRAPH_PATH = "/home/patch_of_scotland/Documents/Docker/docker-slurm/slurm_overheads_highlighted_laptop.pdf"
SCHEDULE_TEXT = 'Avergae schedule time: '
EXECUTION_TEXT = 'Average execution time: '

if __name__ == '__main__':
    scheduling_results = {}
    execution_results = {}

    for run_type in os.listdir(RESULTS_FOLDER):
        scheduling_results[run_type] = []
        execution_results[run_type] = []
        run_type_path = os.path.join(RESULTS_FOLDER, run_type)

        for job_count in os.listdir(run_type_path):
            results_path = os.path.join(run_type_path, job_count, 'results.txt')
            with open(results_path, 'r') as f_in:
                data = f_in.readlines()

            scheduling_duration = 0
            execution_duration = 0            
            for line in data:
                if SCHEDULE_TEXT in line:
                    scheduling_duration = int(line.replace(SCHEDULE_TEXT, ''))
                elif EXECUTION_TEXT in line:
                    execution_duration = int(line.replace(EXECUTION_TEXT, ''))
                    
            scheduling_results[run_type].append((job_count, scheduling_duration))
            execution_results[run_type].append((job_count, execution_duration))

            scheduling_results[run_type].sort(key=lambda y: int(y[0]))
            execution_results[run_type].sort(key=lambda y: int(y[0]))
    
    print(scheduling_results)

    pyplot.figure(1, figsize=(12, 6), dpi=250)
    for run_type in os.listdir(RESULTS_FOLDER):
        scheduling_x = numpy.asarray([int(i[0]) for i in scheduling_results[run_type]])
        scheduling_y = numpy.asarray([int(i[1]) for i in scheduling_results[run_type]])

        execution_x = numpy.asarray([int(i[0]) for i in execution_results[run_type]])
        execution_y = numpy.asarray([int(i[1]) for i in execution_results[run_type]])

        combined_x = scheduling_x
        combined_y = scheduling_y + execution_y

        print(scheduling_x)
        print(scheduling_y)

        sls = 'dotted'
        if run_type in ['sbatch', 'srun']:
            sls = 'solid'

        els = 'dotted'
        if run_type in ['']:
            els = 'solid'

        kls = 'dotted'
        if run_type in ['sbatch_sequential']:
            kls = 'solid'

        pyplot.plot(scheduling_x, scheduling_y, linestyle=sls, label=f'scheduling {run_type}')
        pyplot.plot(execution_x, execution_y, linestyle=els, label=f'execution {run_type}')
        pyplot.plot(combined_x, combined_y, linestyle=kls, label=f'combined {run_type}')

    pyplot.xlabel("Amount of jobs scheduled")
    pyplot.ylabel("Time taken (seconds)")
    pyplot.title("Slurm sheduling overheads")

    handles, labels = pyplot.gca().get_legend_handles_labels()
#    legend_order = [2, 0, 5, 3, 4, 1]
#    pyplot.legend([handles[i] for i in legend_order], [labels[i] for i in legend_order], loc=(0.04, 0.65))
    pyplot.legend()

    pyplot.savefig(GRAPH_PATH, format='pdf', dpi=250, width=100, height=10)
#    pyplot.show()
