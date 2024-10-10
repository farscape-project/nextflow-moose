# Nextflow pipeline for creating and then launching MOOSE UQ jobs

This repository currently builds on the example1 from [UQ-toolkit](https://github.com/farscape-project/uq-toolkit). 

A current caveat for running on Scafell Pike is that the [meshing script](https://github.com/farscape-project/uq-toolkit/blob/main/run_case1_thermomechanicalcube/basedir/mesh.sh) must be run offline and uploaded to the `basedir`, since the GCLIB version required by gmsh is not available on Scafell Pike.

## Usage

Below we detail the steps for running a Nextflow+MOOSE pipeline. To enable getting started easier, we will assume the user has a suitable directory set as `$MYWORKDIR` which could be any of the following: `$HOME`, `$LUSTRE`, `$SCRATCH` or another desired path.

### Prerequisities

We assume the user has a python3 installation with commonly-used modules such as numpy, matplotlib and scipy. Load your environment and install the following additional modules (if not already), which UQ-toolkit depends on:
```bash
pip install hjson UQpy
```

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

One should also have a MOOSE executable installed and copied to `bin/` (in the same directory as your workflow file):
```bash
git clone https://github.com/farscape-project/nextflow-moose.git $MYWORKDIR/nextflow-moose
cd $MYWORKDIR/nextflow-moose
mkdir bin
cp $MYWORKDIR/moose/module/combined/combined-opt bin/ # can be replaced with another MOOSE executable
cd -
```
and a python installation with dependencies for UQ-toolkit installed, as well as UQ-toolkit itself downloaded.
```bash
# download and set path to UQ-toolkit
git clone https://github.com/farscape-project/uq-toolkit.git $MYWORKDIR/uq-toolkit
cd $MYWORKDIR/uq-toolkit
export UQKITPATH=$PWD
```

For the examples, you can use the following paths in uq-toolkit
```bash
export pipelineBasedirPATH=$UQKITPATH/run_case1_thermomechanicalcube/basedir/
export uqConfigPATH=$pipelineBasedirPATH/config_thermomech.jsonc
```

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
