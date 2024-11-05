// params for uq-toolkit
params.uqpath = "/lustre/scafellpike/local/HT04544/sht09/jxw92-sht09/projects/uq-toolkit"
params.basedir_path = "${params.uqpath}/run_case1_thermomechanicalcube/basedir/"
params.uqconfig_name = "config*.jsonc"
params.uqconfig_fullpath = "${params.basedir_path}/../${params.uqconfig_name}"
params.numsamples = 10

// params for using moose
params.solver_name = "combined-opt"
params.moose_cpus = 32

// parameters for getting POD data
params.fieldname = "temperature"
params.num_pod_modes = 2
params.exodus_name = "*_out.e"
params.surrogate_train_iter = 4000

// params for workflow
params.path_to_save_model = "."
params.path_to_save_moosedata = "."
params.mooseuq_on = false
params.trainxgb_on = false

include { MOOSEUQ } from "./workflows/moose-uq.nf"
include { POD_XGB_SURROGATE } from "./workflows/train-surrogate.nf"

workflow {
    if (params.mooseuq_on) {
        MOOSEUQ()
        moose_sims_done = MOOSEUQ.out
    }
    else {
        moose_sims_done = true
    }
    
    if (params.trainxgb_on) {
        POD_XGB_SURROGATE(moose_sims_done)
    }
}
