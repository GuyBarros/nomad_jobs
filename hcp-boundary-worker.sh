export NOMAD_ADDR=https://nomad.guystack.guy.aws.sbx.hashicorpdemo.com:4646
export NOMAD_TOKEN=41f03dcc-ab80-6790-54b6-81586c11a9a2
export HCP_BOUNDARY_CLUSTER_ID=22793585-a579-493f-a519-5a1859b58742

nomad job run  -var="hcp_boundary_cluster_id=${HCP_BOUNDARY_CLUSTER_ID}" hcp-boundary-worker.nomad
