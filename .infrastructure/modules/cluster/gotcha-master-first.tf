resource "digitalocean_droplet" "gotchamaster-first" {
  image = "ubuntu-16-04-x64"
  name = "gotchamaster00"
  region = "${var.DO_REGION}"
  size = "${var.DO_SIZE}"
  private_networking = true
  ssh_keys = [
    "${var.DO_KEYFINGERPRINT}"
  ]

  connection {
    user = "root"
    type = "ssh"
    private_key = "${file(var.DO_PRIVKEY)}"
    timeout = "2m"
  }

  provisioner "local-exec" {
    command = "echo \"${self.ipv4_address_private}\" ${self.name} >> hosts.txt"
  }

  provisioner "file" {
    source = "../../../docker-compose.yml"
    destination = "/root/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      #glusterFS installation (server)
      "sleep 10",
      "echo ${var.DO_PUBKEY_PLAIN} > ~/.ssh/authorized_keys",
      "echo $(cat ~/.ssh/authorized_keys)",
      "apt-get update",
      "apt-get install python3 -y",
      "apt-get install glusterfs-server -y",

      #docker
      "apt-get install apt-transport-https ca-certificates curl software-properties-common -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "apt-get update",
      "apt-get install docker-ce -y",
      "usermod -aG docker `whoami`",
      "curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose",

      "mkdir /index-volume",
      "mkdir /crawler-volume",

      "docker swarm init --advertise-addr ${self.ipv4_address}",
      "docker swarm join-token --quiet manager > /root/gotchamaster-token",
      "docker swarm join-token --quiet worker > /root/gotchaworker-token",
      "docker network create --driver=overlay gotcha-net",
    ]
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no root@${self.ipv4_address}:/root/gotchamaster-token ./gotchamaster-token"
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no root@${self.ipv4_address}:/root/gotchaworker-token ./gotchaworker-token"
  }

}