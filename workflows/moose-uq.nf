process findMoose {
    debug true

    executor "local"

    output:
    eval("${params.solver_name} -h")

    shell:
    """
    mkdir -p !{projectDir}/bin
    if [ -f !{projectDir}/bin/${params.solver_name} ]; then
        echo "solver in bin"
    else
        echo "copying solver"
        cp $MOOSE_DIR/modules/*/${params.solver_name} !{projectDir}/bin/
    fi
    """
}

process setupJobs {
    publishDir "${params.path_to_save_moosedata}", pattern: "*.json", mode: "copy"
    cpus 1
    time '10m'

    debug true

    output:
    path 'sample*', emit: sample_names
    path 'uq_log_*.json', emit: uqlog

    script:
    """
    python ${params.uqpath}/python/setup_uq_run.py -c ${params.uqconfig_fullpath} -b ${params.basedir_path} -n ${params.numsamples} > log_setup_uq.txt
    """
}

process runJobs {
    publishDir "${params.path_to_save_moosedata}", mode: 'copy'
    cpus params.moose_cpus

    input:
    val dirname
    val solver_found

    output:
    path 'sample*', emit: sample_names
    val true, emit: finished

    /* 
        Note: this expects ${params.solver_name} executable to be in !{projectDir}/bin 
    */
    script:
    """
    cp -r $dirname/ .
    cd sample*
    mpirun -n ${params.moose_cpus} ${params.solver_name} -i cube_thermal_mechanical.i > logRun
    cd -
    """
}

workflow MOOSEUQ {
    main:
    /* assumes $MOOSE_DIR environment variable is set */
    findMoose()

    setupJobs() 
    
    /* 
        run moose simulations to get all data (exodus, csv etc)
        findMoose.out is dummy variable to create dependence on findMoose
    */
    runJobs(setupJobs.out.sample_names.flatten(), findMoose.out)
    
    emit:
    runJobs.out.finished.collect()
}

workflow.onComplete {
    println "Pipeline completed at $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
