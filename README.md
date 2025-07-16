# Nextflow pipeline for creating and then launching MOOSE UQ jobs

This repository currently builds on the example1 from [UQ-toolkit](https://github.com/farscape-project/uq-toolkit). 


## Usage

Below we detail the steps for running a Nextflow+MOOSE pipeline. 

### Dependencies

We assume the user has java/openjdk installed and loaded (to run nextflow). To use containers on HPC, singularity is required (which is commonly a loadable module). Otherwise, the main dependency is nextflow (installation details found below).

<details> <summary>Nextflow</summary>
Nextflow can be installed as shown below, note that it depends on Java >= 11.0.
```bash
cd $MYWORKDIR 
mkdir nextflow-build && cd nextflow-build
curl -s https://get.nextflow.io | bash
export PATH=$PWD:$PATH
```

when running in offline mode, as is typical of interactive sessions on compute nodes of many HPCs (such as Scafell Pike), you will be prompted to download the following file to the home directory of your *compute node* (not login node)
```bash
mkdir $MYWORKDIR/.nextflow/framework/24.04.4/ -p
cd $MYWORKDIR/.nextflow/framework/24.04.4/
wget https://www.nextflow.io/releases/v24.04.4/nextflow-24.04.4-one.jar
```
</details> 

### Running nextflow workflow

Once all prerequisites are installed, the nextflow pipeline can be launched like so:
```bash
nextflow run moose-cube.nf \
    -profile sfpSKLoffline \
    --uqpath $UQKITPATH \
    --basedirpath $pipelineBasedirPATH \
    --uqconfigpath $uqConfigPATH \
    --numsamples 5 \
    -bg > my_log_file.txt
```
