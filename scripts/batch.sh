timestamp() {
        date +"%s"
}

echo "$(timestamp)" > "/scripts/results/batch.txt"

for ((n=0; n<100; n++));do
	sbatch /scripts/job.sh $n
done

echo "$(timestamp)" >> "/scripts/results/batch.txt"
