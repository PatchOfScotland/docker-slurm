timestamp() {
        date +"%s"
}

echo "$(timestamp)" > "/scripts/results/run.txt"

for ((n=0; n<100; n++));do
	srun /scripts/job.sh $n
done

echo "$(timestamp)" >> "/scripts/results/run.txt"
