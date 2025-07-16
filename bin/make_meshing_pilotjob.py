#!/usr/bin/env python
import argparse
from qcg.pilotjob.api.manager import LocalManager
from qcg.pilotjob.api.job import Jobs

def get_inputs():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--samples",
        required=True,
        # type=str,
        nargs="+",
        # action='append',
        help="sample names",
    )
    parser.add_argument(
        "--path-to-mesh",
        required=True,
        type=str,
        help="path to mesh directory in each sample folder",
    )
    return parser.parse_args()

if __name__ == "__main__":
    args = get_inputs()

    num_iters = len(args.samples)
    print("samples", args.samples, "num", num_iters)

    manager = LocalManager()
    print('available resources: ', manager.resources())
    assert manager.resources()["total_cores"] > 1
    
    jobs = Jobs().add(script=f'cd sample${{it}}/{args.path_to_mesh} ; python coil_target_remesher.py ; cd -', stdout='job.out.${it}', iteration=num_iters)
    job_ids = manager.submit(jobs)
    print('submited jobs: ', str(job_ids))

    manager.wait4all()

    job_info = manager.info(job_ids)
    print('job detailed information: ', job_info)

    manager.finish()
