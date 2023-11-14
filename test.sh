#!/bin/bash

WARMUP=25000
SIMULATION=25000

scriptName=$(basename "$0")
scriptName="${scriptName%.*}"

# Paths
TRACE_PATH="/media/mee/3504bd20-a1ae-4c35-8f04-4d4cee1fce5a/home/mee/SEM1_STUFF/gap"
RESULTS_PATH="./results/$scriptName"

# Traces
declare -a benchmarkTraces=(
	bc-0.trace.gz
	# bc-0.trace.gz   bfs-10.trace.gz  cc-13.trace.gz  pr-10.trace.gz  sssp-10.trace.gz
	# bc-12.trace.gz  bfs-14.trace.gz  cc-14.trace.gz  pr-14.trace.gz  sssp-14.trace.gz
	# bc-3.trace.gz   bfs-3.trace.gz   cc-5.trace.gz   pr-3.trace.gz   sssp-3.trace.gz
	# bc-5.trace.gz   bfs-8.trace.gz   cc-6.trace.gz   pr-5.trace.gz   sssp-5.trace.gz
)

initialize() {
	echo "=== Running script : $scriptName ==="
	# Ensure the results path exist
	mkdir -p "$RESULTS_PATH"
	echo "Results Path: $RESULTS_PATH"
	echo "Trace Path: $TRACE_PATH"
}

clean() {
	rm -rf $RESULTS_PATH/* >/dev/null 2>&1
	make clean &>/dev/null
}

build_config() {
	echo "=== Building config: $1 ==="
	
	echo "cleaning ... DONE"
	./config.sh configs/$1 &>$RESULTS_PATH/outConfig
	if [ $? -ne 0 ]; then
		echo "Config failed: $1, see output at $RESULTS_PATH/outConfig"
		exit 1
	fi
	echo "config ... DONE"
	echo -n "build ..."
	make -j 8 &>$RESULTS_PATH/outBuild
	if [ $? -ne 0 ]; then
		echo "Build failed: $1, see output at $RESULTS_PATH/outBuild"
		exit 1
	fi
	echo " DONE"
}

run_traces() {
	runTag=$1
	echo "=== Running $runTag ==="
	for trace in "${benchmarkTraces[@]}"; do
		echo -n "Running trace: $trace ..."
		traceOut="${RESULTS_PATH}/${runTag}_${trace}.out"
		traceStatOut="${RESULTS_PATH}/${runTag}_${trace}_stats.json"
		traceStatOutLog="${RESULTS_PATH}/${runTag}_${trace}_trace.json"
		PROFILER_LOG_PATH="$traceStatOutLog" ./bin/champsim --json "$traceStatOut" --warmup_instructions $WARMUP --simulation_instructions $SIMULATION "$TRACE_PATH/$trace" &> $traceOut
		if [ $? -ne 0 ]; then
			echo "Trace failed: $trace, see log at $traceOut"
			exit 1
		fi
		echo " DONE"
	done
	echo "=== === === === === ==="
}

initialize
clean
build_config baseline.json
run_traces