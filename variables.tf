variable "TFE_ORGANIZATION"{
    description = "The name of the Demostack workspacewhich you want the nomad jobs to run in"
    default = "emea-se-playground-2019"
}
variable "DEMOSTACK_WORKSPACE"{
    description = "The name of the Demostack workspacewhich you want the nomad jobs to run in"
    default = "Guy-AWS-Demostack"
}

variable "nomad_node"{
    description = "the hostname of the nomad node you want to run vault-ssh-helper from"
    default = "server-0.eu-guystack.guy.aws.hashidemos.io"
}