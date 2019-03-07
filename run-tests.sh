#!/usr/bin/env bash

set -euo pipefail

test_iterations=${1}
tarball=${2}
test_suite=${3}
jepsen_args=()

function init_jepsen_args {
	jepsen_args=(--ha-storage-dir hdfs:///flink
	--job-running-healthy-threshold 10
	--test-spec "test-specs/${1}"
	--nodes-file ~/nodes
	--tarball ${tarball}
	--username admin
	--ssh-private-key ~/.ssh/id_rsa)
}

function run_yarn_session_tests {
	init_jepsen_args yarn-session.edn
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-task-managers
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers
	lein run test "${jepsen_args[@]}" --nemesis-gen fail-name-node-during-recovery
}

function run_yarn_job_tests {
	init_jepsen_args yarn-job.edn
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-task-managers
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers
	lein run test "${jepsen_args[@]}" --nemesis-gen fail-name-node-during-recovery
}

function run_yarn_job_kill_tm_tests {
	init_jepsen_args yarn-job.edn
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-single-task-manager
}

function run_mesos_session_tests {
	init_jepsen_args mesos-session.edn
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-task-managers
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers
	lein run test "${jepsen_args[@]}" --nemesis-gen fail-name-node-during-recovery
}

function run_standalone_session_tests {
	init_jepsen_args standalone-session.edn
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers --client-gen cancel-jobs
}

for i in $(seq 1 ${1})
do
	echo "Executing run #${i} of ${test_iterations}"
	case ${test_suite} in
		yarn-session)
			run_yarn_session_tests
			;;
		yarn-job)
			run_yarn_job_tests
			;;
		yarn-job-kill-tm)
			run_yarn_job_kill_tm_tests
			;;
		mesos-session)
			run_mesos_session_tests
			;;
		standalone-session)
			run_standalone_session_tests
			;;
		all)
			run_yarn_session_tests
			run_yarn_job_tests
			run_yarn_job_kill_tm_tests
			run_mesos_session_tests
			run_standalone_session_tests
			;;
		*)
			echo "Unknown test suite: ${test_suite}"
			exit 1
			;;
	esac
	echo
done
