params.uqpath = "/lustre/scafellpike/local/HT04544/sht09/jxw92-sht09/projects/uq-toolkit"
params.basedir_path = "${params.uqpath}/run_case1_thermomechanicalcube/basedir/"
params.uqconfig_name = "config*.jsonc"
params.uqconfig_fullpath = "${params.basedir_path}/../${params.uqconfig_name}"
params.numsamples = 10
params.fieldname = "temperature"
params.num_pod_modes = 2
params.exodus_name = "*_out.e"
params.workflow_type = "mooseuq"
params.path_to_save_model = "."
params.path_to_save_moosedata = "."
params.surrogate_train_iter = 4000

include { MOOSEUQ } from "./workflows/moose-uq.nf"
include { POD_XGB_SURROGATE } from "./workflows/train-surrogate.nf"

workflow {
    if (params.workflow_type == "mooseuq") {
        MOOSEUQ()
    }
    else if (params.workflow_type == "trainxgb") {
        POD_XGB_SURROGATE()
    }
}
