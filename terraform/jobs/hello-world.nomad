job "hello-world" {
  datacenters = ["dc1"]

  group "web" {
    count = 1

    network {
      port "http" {
        static = 80
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo"
        args = [
          "-listen", ":80",
          "-text", "Hello from Nomad on AWS, Now with Working CI/CD !"
        ]
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
