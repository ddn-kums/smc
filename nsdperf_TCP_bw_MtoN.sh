#!/bin/bash

echo "Starting the nsdperf HSE TCP/IP Bandwidth Perf tests"

#CLIENT_NODES="srt007-e1"
#CLIENT_NODES="srt007-e0 srt008-e0 srt009-e0 srt010-e0 srt011-e0 srt012-e0"
#CLIENT_NODES="srt007-e1 srt008-e1 srt009-e1 srt010-e1 srt011-e1 srt012-e1"
#CLIENT_NODES="srt013-e0 srt014-e0 srt015-e0 srt016-e0 srt017-e0 srt018-e0"
CLIENT_NODES="srt013-e1 srt014-e1 srt015-e1 srt016-e1 srt017-e1 srt018-e1"
#SERVER_NODES="srt001-e1"
#SERVER_NODES="srt001-e0 srt002-e0 srt003-e0 srt004-e0 srt005-e0 srt006-e0"
#SERVER_NODES="srt001-e1 srt002-e1 srt003-e1 srt004-e1 srt005-e1 srt006-e1"
#SERVER_NODES="srt019-e0 srt020-e0 srt021-e0 srt022-e0 srt023-e0 srt024-e0"
SERVER_NODES="srt019-e1 srt020-e1 srt021-e1 srt022-e1 srt023-e1 srt024-e1"
SRVR_COUNT=6
TIME=60
#TIME=10
S_TIME=10
#MIN_BUFFSIZE=4096
MIN_BUFFSIZE=16777216
MAX_BUFFSIZE=16777216
THREADS=32
#PARALLEL_CONNECTIONS="1 2 4 6 8"
PARALLEL_CONNECTIONS="8"
SLEEPT=3
#MODE="final"
MODE="quick"

#nsdperf binary
NSDPERFC="/work/kums/benchmarks/nsdperf/nsdperf-x86"
NSDPERFS="/work/kums/benchmarks/nsdperf/nsdperf-x86"
NSDPERFL="/work/kums/benchmarks/nsdperf/nsdperf-x86"

#nsdperf infile
IF="/work/kums/benchmarks/nsdperf/scripts/nsdperf_TCP_HSE.in"


# NSDPERF IB TEST
# Launch nsdperf
for node in $CLIENT_NODES;
do
    ssh $node "$NSDPERFC -s </dev/null >/dev/null 2>&1 &"
    sleep $SLEEPT
done

for node in $SERVER_NODES;
do
    ssh $node "$NSDPERFS -s </dev/null >/dev/null 2>&1 &"
    sleep $SLEEPT
done

sleep $SLEEPT

echo "Performing nsdperf TCP/IP Stress Runs"

for conn in $PARALLEL_CONNECTIONS;
do
    OF="/work/kums/benchmarks/nsdperf/results/$MODE/nsdperf_HSE_P${conn}_MtoN.$SRVR_COUNT.out.`date +%F-%T`.txt"
    echo "nsdperf server mode started" | tee -a $OF

    for (( io_sz=$MIN_BUFFSIZE; io_sz <= $MAX_BUFFSIZE; io_sz *= 4)) 
    do
        #Populate infile
        echo client $CLIENT_NODES > $IF
        echo server $SERVER_NODES >> $IF
        echo buffsize $io_sz >> $IF
	echo threads $THREADS >> $IF
        echo ttime $TIME >> $IF
        echo parallel $conn >> $IF
	#echo verify on >> $IF
        echo status >> $IF
        echo test >> $IF
        echo quit >> $IF

       echo "Starting nsdperf TCP/IP test on: `date`" | tee -a $OF
       echo "nsdperf test parameters -  BUFFSIZE: $io_sz, TCP/IP socket count: $conn" | tee -a $OF
       $NSDPERFL -i $IF 2>&1 | tee -a $OF
       sleep $SLEEPT
    done
done
 
echo "nsdperf HSE TCP/IP Bandwidth Perf test complete: `date`"  |tee -a $OF

echo "Performing Single Socket Test and Terminating nsdperf server connections"
#Populate infile
echo client $CLIENT_NODES > $IF
echo server $SERVER_NODES >> $IF
echo buffsize $MAX_BUFFSIZE >> $IF
echo ttime $S_TIME >> $IF
echo threads $THREADS >> $IF
echo parallel 1 >> $IF
echo verify on >> $IF
echo status >> $IF
echo test >> $IF
echo killall >> $IF
echo quit >> $IF

OF="/work/kums/benchmarks/nsdperf/results/tmp/nsdperf_HSE_P1_MtoN.$SRVR_COUNT.out.`date +%F-%T`.txt"
$NSDPERFL -i $IF 2>&1 | tee -a $OF
sleep $SLEEPT
