process findPOD {
    publishDir "${params.path_to_save_model}", mode: "copy"
    cpus 1
    time '20m'

    input:
    val ready

    debug true
    /* -path-to-samples could be an input? */
    output:
    path "pod_data"

    script:
    """
    python ${params.uqpath}/python/find_pod_modes.py \
        --path-to-samples ${params.path_to_save_moosedata} \
        -o pod_data \
        --exodus-name ${params.results_name}.e \
        --csvname ${params.results_name}.csv \
        --num-modes ${params.num_pod_modes} \
        --fieldname ${params.fieldname} \
        --nozero --steady-state
    """
}

process trainSurrogate {
    publishDir "${params.path_to_save_model}", mode: 'copy'
    cpus 1

    time '30m'

    input:
    path pod_dir

    output:
    path 'my_gpr.skops'

    script:
    """
    python ${params.uqpath}/python/train_surrogate.py \
        -c ${params.uqconfig_fullpath} \
        --path-to-samples ${params.path_to_save_moosedata} \
        --pod-dir ${pod_dir}/ \
        -ne ${params.surrogate_train_iter} \
        --save-model --steady-state
    """
}

workflow POD_SURROGATE {
    take:
    ready

    main:
    /* assumes $MOOSE_DIR environment variable is set */
    findPOD(ready) 
    trainSurrogate(findPOD.out)
}

workflow.onComplete {
    println "Pipeline completed at $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
