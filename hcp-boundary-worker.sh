export NOMAD_ADDR=https://nomad.guystack.original.aws.hashidemos.io:4646
export NOMAD_TOKEN=fadf241a-9641-d99b-9bcb-c9b429ac018f
export HCP_BOUNDARY_CLUSTER_ID=8b08c225-2e05-418c-beb2-cf68333c9647

nomad job run  -var="hcp_boundary_cluster_id=${HCP_BOUNDARY_CLUSTER_ID}" hcp-boundary-worker.nomad
