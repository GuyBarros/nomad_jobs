job "batchjob" {
  datacenters = ["dc1"]
  type = "batch"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "windows"
  }

// to dispatch this job use nomad job dispatch -meta TTL=60 batchjob  payload.json
  parameterized {
    payload       = "required"
    meta_required = ["TTL"] #ttl is the amount of time this batch job will run for before it gets executed
  }

  group "clients1" {
    count = 1
    task "callexe" {

     

 template {
        data = <<EOH
        param(
            $TTL
            )
          start local/repo/dotnet-batch-service.exe
          ping 127.0.0.1 -n $TTL
          taskkill /im dotnet-batch-service.exe /f
        EOH
        destination = "local/runbatch.ps1"
      }

      driver = "raw_exec"
       resources {
        cpu    = 1000
        memory = 256
        }

 
        artifact {
           source   = "git::https://github.com/GuyBarros/dotnet-batch-service"
            destination = "local/repo"
           
         }

        config {
         command = "powershell.exe"
           args = ["local/runbatch.ps1   ${NOMAD_META_TTL}"] 
         }

    }

  }

}
