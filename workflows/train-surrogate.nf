process findPOD {
    publishDir "${params.path_to_save_model}", mode: "copy"
    cpus 1
    time '20m'

    debug true
    /* -path-to-samples could be an input? */
    output:
    path "pod_data"

    script:
    """
    python ${params.uqpath}/python/find_pod_modes.py \
        --path-to-samples ${NXF_FILE_ROOT}/results/ \
        --exodus-name ${params.exodus_name} \
        --num-modes ${params.num_pod_modes} \
        --fieldname ${params.fieldname} \
        --nozero 
    """
}

process trainXGBoost {
    publishDir "${params.path_to_save_model}", mode: 'copy'
    cpus 1

    time '30m'

    input:
    path pod_dir

    output:
    path 'xgb_model.*'

    script:
    """
    python ${params.uqpath}/python/train_xgb.py \
        -c ${params.uqconfig_fullpath} \
        --path-to-samples ${NXF_FILE_ROOT}/results/ \
        --pod-dir ${pod_dir}/ \
        -ne 1000 \
        --save-model
    """
}

workflow POD_XGB_SURROGATE {
    /* assumes $MOOSE_DIR environment variable is set */
    findPOD | trainXGBoost 
}

workflow.onComplete {
    println "Pipeline completed at $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}