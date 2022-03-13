repeats=$1
jobs_counts=(10 20 30 40 50 60 70 80 90 100 125 150 175 200 250 300 400 500)

schedule_duration="Scheduling duration: "
execution_duration="Execution duration: "

# Timestamp function
timestamp() {
        date +"%s"
}

mean() {
        list=("$@")
        ((sum=0))
        for i in "${list[@]}";
        do
                ((sum+=$i))
        done;
        echo $(($sum/${#list[@]}))
}

make_dir() {
        if [ ! -d $1 ]
        then
                mkdir $1
        fi
}

wait_for_end() {
        queue_length=0
        while [ $queue_length != "1" ]
        do
                sleep 1
                queue_length=$(squeue | wc -l)
        done;
}

run_test() {
        test_dir="${results_dir}/$1"
        make_dir $test_dir

        jobs_count_dir="${test_dir}/${jobs_count}"
        make_dir $jobs_count_dir

        run_dir="${jobs_count_dir}/$2"
        make_dir $run_dir

        jobs_dir="${run_dir}/jobs"
        make_dir $jobs_dir

        start_time=$(timestamp)
        echo "Start scheduling: ${start_time}" > "${run_dir}/meta.txt"

        jobs=$3
        for ((n=0; n<(($3)); n++));
        do
                $1 -Q --output=/dev/null --error=/dev/null /scripts/job.sh "${jobs_dir}/${n}.txt"
        done;

        end_sch_time=$(timestamp)
        echo "End scheduling: ${end_sch_time}" >> "${run_dir}/meta.txt"
        wait_for_end
        end_exe_time=$(timestamp)
        echo "End execution: ${end_exe_time}" >> "${run_dir}/meta.txt"

        echo "${schedule_duration}$((${end_sch_time}-${start_time}))" >> "${run_dir}/meta.txt"
        echo "${execution_duration}$((${end_exe_time}-${end_sch_time}))" >> "${run_dir}/meta.txt"

        ((job_counter+=$3))

        echo "Completed scheduling run $2 for ${1} $3 jobs ${job_counter}/$4 ($(( 200*${job_counter}/$4 - 100*${job_counter}/$4 ))% after $(($(timestamp)-${runtime_start}))s)"

        # Cleanup to prevent too many files accumulating
        cat ${jobs_dir}/*.txt > "${run_dir}/raw.txt"
        rm -r ${jobs_dir}
}

run_sequential_test() {
        test_dir="${results_dir}/$1_sequential"
        make_dir $test_dir

        jobs_count_dir="${test_dir}/${jobs_count}"
        make_dir $jobs_count_dir

        run_dir="${jobs_count_dir}/$2"
        make_dir $run_dir

        jobs_dir="${run_dir}/jobs"
        make_dir $jobs_dir

        start_time=$(timestamp)
        echo "Start scheduling: ${start_time}" > "${run_dir}/meta.txt"

        jobs=$3
        $1 -Q --output=/dev/null --error=/dev/null /scripts/sequential.sh 0 $(($3-1)) $1 "${jobs_dir}/X.txt"

        end_sch_time=$(timestamp)
        echo "End scheduling: ${end_sch_time}" >> "${run_dir}/meta.txt"
        wait_for_end
        end_exe_time=$(timestamp)
        echo "End execution: ${end_exe_time}" >> "${run_dir}/meta.txt"

        echo "${schedule_duration}$((${end_sch_time}-${start_time}))" >> "${run_dir}/meta.txt"
        echo "${execution_duration}$((${end_exe_time}-${end_sch_time}))" >> "${run_dir}/meta.txt"

        ((job_counter+=$3))

        sleep $(($3/10))

        echo "Completed scheduling run $2 for $1_sequential $3 jobs ${job_counter}/$4 ($(( 200*${job_counter}/$4 - 100*${job_counter}/$4 ))% after $(($(timestamp)-${runtime_start}))s)"

        # Cleanup to prevent too many files accumulating
        cat ${jobs_dir}/*.txt > "${run_dir}/raw.txt"
        rm -r ${jobs_dir}
}


collate_results() {
        echo "collating $2 runs of $3 $1 jobs"
        jobs_count_dir="${results_dir}/$1/$3"

        durations=()
        executions=()
        for ((run=0 ; run<$2 ; run++));
        do
                meta_file="${jobs_count_dir}/$run/meta.txt"
                duration=$(grep "${schedule_duration}" ${meta_file}|cut -d' ' -f 3)
                durations+=(${duration})
                execution=$(grep "${execution_duration}" ${meta_file}|cut -d' ' -f 3)
                executions+=(${execution})
        done;

        collated_meta_file="${jobs_count_dir}/results.txt"

        echo "Avergae schedule time: $(mean ${durations[@]})" > $collated_meta_file
        echo "Average execution time: $(mean ${executions[@]})" >> $collated_meta_file

        echo "Schedule times: ${durations[@]}" >> $collated_meta_file
        echo "Execution times: ${executions[@]}" >> $collated_meta_file
}

# Setup results dir if not present
results_dir="results"
make_dir $results_dir

requested_jobs=0
for ((run=0 ; run<$repeats ; run++));
do
        for jobs_count in ${jobs_counts[@]};
        do
                ((requested_jobs+=$jobs_count*3))
        done;
done;

echo "requested jobs: ${requested_jobs}" 

runtime_start=$(timestamp)
job_counter=0
for ((run=0 ; run<$repeats ; run++));
do
        for jobs_count in ${jobs_counts[@]};
        do
                # Run srun tests
                run_test "srun" $run $jobs_count $requested_jobs

                # run sbatch tests
                run_test "sbatch" $run $jobs_count $requested_jobs

                # Only sbatch here as srun will block and never complete
                run_sequential_test "sbatch" $run $jobs_count $requested_jobs
        done;
done;

for jobs_count in ${jobs_counts[@]};
do
        # Run srun tests
        collate_results "srun" $repeats $jobs_count

        # run sbatch tests
        collate_results "sbatch" $repeats $jobs_count

        collate_results "sbatch_sequential" $repeats $jobs_count

done;
