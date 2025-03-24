process checkMooseExists {
    // currently unused
    executor "local"

    output:
    eval("${params.solver_name} -h")
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

process newGeometry {
    memory '20 GB'

    input:
    path dirname

    output:
    val true, emit: finished

    shell:
    """
    cd sample*/${params.meshdirname}
    python coil_target_remesher.py
    cd -
    """
}

process runJobs {
    publishDir "${params.path_to_save_moosedata}", mode: 'copy'
    cpus params.moose_cpus
    memory '20 GB'

    input:
    path dirname
    val ready // dummy variable to check `newGeometry` process complete

    output:
    val true, emit: finished

    /* 
        Note: this expects ${params.solver_name} executable to be in !{projectDir}/bin 
    */
    shell:
    """
    cd sample*
    mpirun -n ${params.moose_cpus} ${params.solver_name} -i ${params.moose_inputfile}
    cd -
    """
}

workflow MOOSEUQ {
    main:
    // set up sample directories
    setupJobs() 

    if (params.remesh){
        // generate mesh with cubit and VacuumMesher
        newGeometry(setupJobs.out.sample_names.flatten())
        // run MOOSE
        runJobs(setupJobs.out.sample_names.flatten(), newGeometry.out.finished)
    }
    else {
        runJobs(setupJobs.out.sample_names.flatten(), true)
    }
    
    emit:
    runJobs.out.finished.collect()
}

workflow.onComplete {
    println "Pipeline completed at $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
