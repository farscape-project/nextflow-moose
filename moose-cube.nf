params.uqpath = '/lustre/scafellpike/local/HT04544/sht09/jxw92-sht09/projects/uq-toolkit'
params.basedirpath = '/lustre/scafellpike/local/HT04544/sht09/jxw92-sht09/projects/workflow/nextflow/moose-cube-workflow/dev_thermocube/basedir'
params.uqconfigpath = '/lustre/scafellpike/local/HT04544/sht09/jxw92-sht09/projects/workflow/nextflow/moose-cube-workflow/dev_thermocube/config_thermomech.jsonc'
params.numsamples = 10

process setupJobs {
    publishDir "output_setupjobs", pattern: "*.json", mode: "copy"
    cpus 1
    time '10m'

    debug true

    output:
    path 'sample*', emit: sample_names
    path 'uq_log_*.json', emit: uqlog

    script:
    """
    python ${params.uqpath}/python/setup_uq_run.py -c ${params.uqconfigpath} -b ${params.basedirpath} -n ${params.numsamples} > log_setup_uq.txt
    """
}

process runJobs {
    publishDir "results", mode: 'copy'

    time '1h'

    debug true

    input:
    val dirname

    output:
    path 'sample*'

    /* 
        Note: this expects combined-opt executable to be in $PWD/bin 
    */
    script:
    """
    cp -r $dirname/ .
    cd sample*
    combined-opt -i cube_thermal_mechanical.i > logRun
    cd -
    """
}

workflow {
    setupJobs() 
    
    /* run moose simulations to get all data (exodus, csv etc) */
    runJobs(setupJobs.out.sample_names.flatten())
}

workflow.onComplete {
    println "Pipeline completed at $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
