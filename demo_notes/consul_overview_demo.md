# Consul Demo

## Prerequisites

* Have access to a text editor.
* Have terraform 0.12 installed locally
* Have nomad 10 installed locally
* Deploy a DNS zone using the dns multicloud repository [here](https://github.com/lhaig/dns-multicloud)
* Deploy a primary and secondary hashistack using the demostack from Guy Barros [here](https://github.com/GuyBarros/terraform-aws-demostack).
* Clone the nomad_jobs repository from Guy Barros / Ricardo Oliveira [here](https://github.com/GuyBarros/nomad_jobs).
* Have Access to the *Life of a packet through Consul Service Mesh slides* produced by Christoph Puhl [Here](https://docs.google.com/presentation/d/1nV_PiPBEXmblLskLJKUxxMWWR1jfZxQseBuNoG_qP8M/edit?usp=sharing).

## Preparation

Deploy the stacks in the following order

1. dns-multicloud (grab the output of the DNS zoneID for the demostack deployment)
2. demostack (grab the server-0 output URL for use within the tfvars file for the demonstation)

Once your stacks are up you need to deploy some jobs using the runjobs.tf plan within the nomad_jobs repository:

Comment out all the jobs in the file except:

* nginx-pki ( This is used to test that the stack is working )
* Everything between the Monitoring Stack comments.

Create a teraform.tfvars file within the directory.

``` bash
DEMOSTACK_WORKSPACE="YOUR-AWS-Workspace" ( The workspace you deployed the demostack to.)
nomad_node="server-0.OUTPUT-FROM-DEMOSTACK.hashidemos.io" ( server-0 record you grabbed from the demostack)
```

Open 2 Browser windows and open the links for the primary in one and the secondary in the other.
The following list is the order in which each tab should be opened in the browser window.

* Consul
* Nomad
* Vault
* Fabio
* open one of the worker node urls provided in the demosack output (one for each Datacenter) To be used for count demo

Now run terraform apply to deploy:

* Prometheus
* Grafana

Due to a current bug in the plan, you need to run the job 2 times to complete the install. 

You will see 404 errors which is normal.

``` bash
cd nomad_jobs
terraform apply
```

Edit the consul-federation.nomad job and replace the server0

You will need to use the server-0 record from the secondary datacenter for this task


## Demonstration Script - Walk Through

Now just follow the flow of the steps below to explain each stage as you go through it.
Use the opportunity to introduce each of our products as you use them to complete this walkthrough.

## General UI walkthrough

Do a general walkthrough of the consul UI explaining as normal.

## Count Dashboard

In primary the datacenter complete the following steps.

* Uncomment the countapi job in the runjobs.tf file and apply it.
* Once the job has completed successfuly uncomment the countdashboard job and apply it.

### Single-DC Demonstration
Find the server that the UI is running on.

* Select the job in consul and see the server name in the service.
* Open the URL http://SERVERNAME.OUTPUT-FROM-DEMOSTACK.aws.hashidemos.io:9002/

Connect to the count server and then show it working.

* Discuss intentions andhow they work and fit in to the zero trust network.
* Next create a connection Intention to allow access to the API.
* * Test the URL again to show it working
* Next set the access to Deny
* * show the broken URL
* Set the access to allow again and show it working.

### Slides to visualise the traffic between the 2 containers

Use slide 39 - 46 of the slide deck to speak through the flow of data between the dashboard and the counter API
[Slide 39](https://docs.google.com/presentation/d/1nV_PiPBEXmblLskLJKUxxMWWR1jfZxQseBuNoG_qP8M/edit#slide=id.g606d39086c_0_183)

## Consul Federate

Discuss federation and how it benefits the customers teams using and runnig Consul.
Discuss how in the count example that the API will typically be a system of record in their on premises or master datacenter. Discuss how the dashboard application will be the system of engagement and could be made to be ephemeral for scale.

Open the second browser window. It is good to have the windows side by side so that it is easy to see when things change.

Show that the two clusters are not joined together by clicking on the name of the cluster and showing there is only one listed.

## Multi-DC Service Mesh

Use the slide deck from slide 75 - 77 to explain what prerequisites are needed for running in Multi DC mode

[Slide 75](https://docs.google.com/presentation/d/1nV_PiPBEXmblLskLJKUxxMWWR1jfZxQseBuNoG_qP8M/edit#slide=id.g606d39086c_0_521)

Show the topology example and explain the different parts.

### Federation

Explain how federation allows the operator / user to see have a single UI on the primary cluster to be able to manage their consul environment.

### Deploy consul-federation.nomad job

Open the consul-federation.nomad job in the editor and copy the content

Create a new job in nomad within the primary datacenter and execute this.

This is a good time to discuss some points about the different jobs that nomad could run.

Show from both datacenters one UI that all service are running.

## Consul Service Mesh

Use the slide deck from slide 92 - 104 to explain service to service sessions in Multi DC mode

[Slide 92](https://docs.google.com/presentation/d/1nV_PiPBEXmblLskLJKUxxMWWR1jfZxQseBuNoG_qP8M/edit#slide=id.g608368cd7c_0_692)

Walk through the process of traffic flow step by step.

### Multi-DC Demonstration

Stop count Dashboard job in nomad.

Copy the consul-gatewaty.nomad job and run it in each datacenter.

Show in the consul UI that yhe services have been deployed.

In the secondary datacenter run the consul-resolvers.nomad job. Explain thatthe resolver job is there to tell the servers in the secondary datacenter how to connect to the count-api backend.

edit the countdashboard.nomad job and make sure the secondary datacenter is listed in the datacenters variable.

Deploy the dashboard job in the secondary datacenter.

Open the service in the secondary datacenter consul and find the server it is running on.

Open the URL in the secondary browser and show that the dashboard is working.

Change the intention to disabled and sho the connection is blocked again.

## Grafana Monitoring

Default login for garfana admin : admin

Explain how using prometheus you can gather logs and metrics from consul, vault and nomad which will enable pushing these logs into the customers logging and monitoring solution.

### Prometheus

Open the prometheus URL on the primary datacenter web browser and show that the endpoint targets have been discovered

```bash
http://fabio.OUTPUT-FROM-DEMOSTACK.aws.hashidemos.io:9999/prometheus/targets

```

Open the Grafana dashboard and show how the data for consul is available in Garafana

```bash
http://fabio.OUTPUT-FROM-DEMOSTACK.aws.hashidemos.io:9999/grafana

```
