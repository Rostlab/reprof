#!/bin/bash


echo "### best results###"
scripts/sort_results.pl 2 data/results/*.result | head -n 20

echo "### errorlog ###"
cat data/grid/*.e*

echo "### qusage ###"
qusage

echo "### properly finished nets ###"
cat data/results/*.result | grep -c END
