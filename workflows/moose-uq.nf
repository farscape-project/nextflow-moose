process setupJobs {
    publishDir "${params.path_to_save_moosedata}", mode: "copy"
    cpus 1
    time '60m'

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
    memory '40 GB'
	cpus 1

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

process newHTC {
    memory '4 GB'
	cpus 1

    input:
    path dirname

    output:
    val true, emit: finished

    shell:
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
	clusterOptions '--exclusive'

    input:
    path dirname
    val mesh_ready // dummy variable to check `newGeometry` process complete
    val htc_ready

    output:
    val true, emit: finished
    path "sample*/input/*.e", emit: exofiles // save all files for each case
	path "sample*/input/*.csv", emit: tabfiles

    /* 
        Note: this expects ${params.solver_name} executable to be in !{projectDir}/bin 
    */
    shell:
    """
    cd sample*
    mpirun -n ${params.moose_cpus} ${params.solver_name} -w -i ${params.moose_inputfile}
    cd -
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
