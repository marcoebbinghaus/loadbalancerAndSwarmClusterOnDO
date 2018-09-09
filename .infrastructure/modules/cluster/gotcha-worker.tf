resource "digitalocean_droplet" "gotchaworker" {
  image = "ubuntu-16-04-x64"
  name = "${format("gotchaworker%02d", count.index + 1)}"
  count = "${var.DO_WORKERCOUNT}"
  region = "${var.DO_REGION}"
  size = "${var.DO_SIZE}"
  depends_on = ["digitalocean_droplet.gotchamaster-final"]
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

  provisioner "file" {
    source = "./gotchaworker-token"
    destination = "/tmp/swarm-token"
  }

  provisioner "remote-exec" {
    inline = [
      #docker
      "apt-get install apt-transport-https ca-certificates curl software-properties-common -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "apt-get update",
      "apt-get install docker-ce -y",
      "usermod -aG docker `whoami`",
      "curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose",

      "docker swarm join --token `cat /tmp/swarm-token` ${digitalocean_droplet.gotchamaster-first.ipv4_address}:2377"
    ]
  }

}