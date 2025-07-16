process setupJobs {
    publishDir "${params.path_to_save_moosedata}", mode: "copy"
    cpus 1
    time '60m'
    cache "lenient"

    output:
    path 'sample*', emit: sample_names
    path 'uq_log_*.json', emit: uqlog

    script:
    """
    python ${params.uqpath}/python/setup_uq_run.py -c ${params.uqconfig_fullpath} -b ${params.basedir_path} -n ${params.numsamples}
    """
}

process newGeometry {
    memory '20 GB'
	cpus 1
    cache "lenient"
    time "10m"

    input:
    path dirname

    output:
    val true, emit: finished

    script:
    """
    cd sample*/${params.meshdirname}
    python coil_target_remesher.py
    cd -
    """
}

process newHTC {
	executor 'local'
    memory '4 GB'
	cpus 1
    cache "lenient"

    input:
    path dirname

    output:
    val true, emit: finished

    script:
    """
    cd sample*/matprops
    python calc_heat_transfer_coeff_dittusboelter.py -j htc_params.jsonc
    cd -
    """
}

process runJobs {
    publishDir "${params.path_to_save_moosedata}", mode: 'copy'
    errorStrategy 'ignore'
    cpus params.moose_cpus
	time params.moose_sim_time
    memory '40 GB'
	//debug true
    cache "lenient"
	clusterOptions '--exclusive'

    input:
    path dirname
    val mesh_ready // dummy variable to check `newGeometry` process complete
    val htc_ready

    output:
    val true, emit: finished
    path "${dirname}/${params.results_name}.e", emit: exofiles // save all files for each case
	path "${dirname}/${params.results_name}.csv", emit: tabfiles

    script:
    """
    cd ${dirname}
    mpirun -n ${params.moose_cpus} ${params.solver_name} -w -i ${params.moose_inputfile}
    rm -rf .jitcache
    cd ..
    """
}

workflow MOOSEUQ {
    main:
    // set up sample directories
    def mesh_finished = false
    def htc_finished = false
    setupJobs() 

    if (params.remesh){
        // generate mesh with cubit and VacuumMesher
        newGeometry(setupJobs.out.sample_names.flatten())
        mesh_finished = newGeometry.out.finished
    }
    else {
        mesh_finished = true
    }

    if (params.newhtc){
        newHTC(setupJobs.out.sample_names.flatten())
        htc_finished = newHTC.out.finished
    }
    else {
        htc_finished = true

    }
    
    // run MOOSE
    runJobs(setupJobs.out.sample_names.flatten(), mesh_finished, htc_finished)
    emit:
    runJobs.out.finished.collect()
}

workflow.onComplete {
    println "Pipeline completed at $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
