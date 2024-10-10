#!/bin/bash

rm -rf work output_setupjobs results
nextflow run moose-cube.nf -profile sfpSKLoffline --basedirpath /lustre/scafellpike/local/HT04544/sht09/jxw92-sht09/projects/uq-toolkit/run_case1_thermomechanicalcube/basedir/ --uqconfigpath /lustre/scafellpike/local/HT04544/sht09/jxw92-sht09/projects/uq-toolkit/run_case1_thermomechanicalcube/config_thermomech.jsonc --numsamples 5 -bg > my_log_file.txt

