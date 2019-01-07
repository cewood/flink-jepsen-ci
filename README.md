# flink-jepsen-ci

This project is a collection of configuration files to run the flink-jepsen
test suite on a real cluster deployed on AWS EC2 instances.

## Usage

This repository is set up to allow you to run the Jepsen tests as part of a CI system, or interactively for local development/testing.

In both scenarios the Makefile is the method of performing these operations and should always be consulted first.

### Dependencies

The following dependencies are required to run these tests:

 - Access to an AWS account (being able to assume a role with policy _PowerUserAccess_ or _AdministratorAccess_ is probably easiest)
 - [Ansible](https://github.com/ansible/ansible)
 - [Boto](https://github.com/boto/boto)
 - [Make](https://www.gnu.org/software/make/)
 - [remind101/assume-role](https://github.com/remind101/assume-role)
 - [Terraform](https://github.com/hashicorp/terraform)

You need to configure your [AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).
Moreover, this project assumes that [named profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) called _testing_ is configured.
Find below example configurations.

Example `~/.aws/credentials`

	[default]
	aws_access_key_id = <KEY_ID>
	aws_secret_access_key = <ACCESS_KEY>

Example `~/.aws/config`

	[default]
	region = eu-central-1
	output = json
	
	[profile testing]
	role_arn = <ROLE_ARN> # e.g., arn:aws:iam::1234567890:role/example-role
	source_profile = default
	region = eu-central-1

Lastly, you will need the flink-jepsen sources and the test job, which are hosted in the Flink repository. The Flink sources should reside in a directory called `flink` within this project. You can symlink an existing clone of the Flink repository by issuing `ln -s /path/to/flink flink`. The test job jar should reside in `flink/flink-jepsen/bin` as described [here](https://github.com/apache/flink/tree/master/flink-jepsen#usage).

### Manually/interactive usage
This section describes how to run the tests against a custom [Flink build](https://ci.apache.org/projects/flink/flink-docs-master/flinkDev/building.html).

#### Building and hosting Flink binaries
Note that Jepsen expects the Flink binaries to be hosted under an internet accessible URL as a tarball.
The easiest would be to upload the Flink binaries to an AWS S3 bucket with *public-read* permissions.

#### Steps
1. Set things up first by issuing `make setup`. You only need to run this once.
For all subsequent test runs this step can be skipped.

1. Then apply the terraform configuration using `make apply`.
The command will finish with a summary of all relevant resources created by Terraform:

	```
	Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
	
	Outputs:
	
	Control Node public IP = 18.196.103.106
	DB Nodes =
	Private IP: 172.31.40.194
	Private DNS: ip-172-31-40-194.eu-central-1.compute.internal
	Public IP: 52.29.205.147
	
	Private IP: 172.31.40.63
	Private DNS: ip-172-31-40-63.eu-central-1.compute.internal
	Public IP: 52.59.249.47
	
	Private IP: 172.31.41.45
	Private DNS: ip-172-31-41-45.eu-central-1.compute.internal
	Public IP: 52.59.234.254
	
	Private IP: 172.31.41.69
	Private DNS: ip-172-31-41-69.eu-central-1.compute.internal
	Public IP: 3.121.239.196
	
	Private IP: 172.31.42.158
	Private DNS: ip-172-31-42-158.eu-central-1.compute.internal
	Public IP: 18.194.233.114
	HA Storage S3 Bucket = jepsen-flink-20190107094536584900000002
	```
1. Now run ansible on the new instances with `make ansible`.
This will set up the newly created EC2 instances (e.g., install Java, upload Jepsen test sources, etc),
and run the tests against a Flink build that is defined in the ansible playbook. Since we want to use a custom Flink build, we should abort by pressing _Ctrl + C_ when ansible starts running the tests. You can login to the control node by issuing `ssh -i id_rsa admin@18.196.103.106`. Once on the control node, you can run tests manually. For example, to run all tests twice, issue `./run-tests.sh 2 http://example.org/flink.tgz all`.

1. Then if you're finished, you can destroy the nodes with `make destroy`

1. Finally you can do a `make cleanup` if you like; removes the log/output files

### CI usage

Assuming that the dependencies have been taken care of already.

To run everything in a CI setup, simply run `make run` and it will do everything for you.

This includes retrieving a log of the output of the Ansible task in `run-tests.log` and the direct Jepsen output in a folder called `store` which contains a hierarchy of output pertaining to the various steps of the tests, and the node it was run on etc.
