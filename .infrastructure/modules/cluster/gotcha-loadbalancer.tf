resource "digitalocean_droplet" "gotcha-loadbalancer" {
  image = "ubuntu-16-04-x64"
  name = "gotcha-loadbalancer"
  region = "${var.DO_REGION}"
  size = "${var.DO_SIZE}"
  private_networking = true
  ssh_keys = [
    "${var.DO_KEYFINGERPRINT}"
  ]
  depends_on = [
    "digitalocean_droplet.gotchamaster-final",
    "digitalocean_domain.gotchadomain-main"
  ]

  connection {
    user = "root"
    type = "ssh"
    private_key = "${file(var.DO_PRIVKEY)}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",

      # when creating the DigitalOcean domain via terraform (see gotcha-domain.tf), we are forced to enter an ip_address - even though
      # it is not required within the DigitialOcean API. This is a bug in terraform which will be fixed in the upcoming release
      # (see https://github.com/terraform-providers/terraform-provider-digitalocean/pull/122
      # / https://github.com/terraform-providers/terraform-provider-digitalocean/issues/134)
      # here we are updating the dummy 127.0.0.1 - IP-address with the real IP of the load balancer droplet
      "apt-get install jq -y",
      "LOADBALANCER_A_RECORD_ID=$(curl -sX GET https://api.digitalocean.com/v2/domains/${digitalocean_domain.gotchadomain-main.name}/records -H \"Authorization: Bearer ${var.DO_TOKEN}\" | jq -c '.domain_records[] | select(.type | contains(\"A\")) | select(.data | contains(\"127.0.0.1\"))'.id)",
      "curl -X PUT -H \"Content-Type: application/json\" -H \"Authorization: Bearer ${var.DO_TOKEN}\" -d '{\"data\":\"${self.ipv4_address}\"}' \"https://api.digitalocean.com/v2/domains/${digitalocean_domain.gotchadomain-main.name}/records/$LOADBALANCER_A_RECORD_ID\"",
      "apt-get update -y",
      "apt-get install haproxy -y",
      "printf \"\n\nfrontend http\n\tbind ${self.ipv4_address}:80\n\treqadd X-Forwarded-Proto:\\ http\n\tdefault_backend web-backend\n\" >> /etc/haproxy/haproxy.cfg",
      "printf \"\n\nbackend web-backend\" >> /etc/haproxy/haproxy.cfg",
      "printf \"\n\tserver gotchamaster00 ${digitalocean_droplet.gotchamaster-first.ipv4_address}:80 check\" >> /etc/haproxy/haproxy.cfg",
      "printf \"\n\tserver gotchamaster-final ${digitalocean_droplet.gotchamaster-final.ipv4_address}:80 check\" >> /etc/haproxy/haproxy.cfg",
    ]
  }

}

resource "null_resource" "gotcha-master-ips-adder" {
  count = "${var.DO_MASTERCOUNT - 2}"
  triggers {
    loadbalancer_id = "${digitalocean_droplet.gotcha-loadbalancer.id}"
  }
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file(var.DO_PRIVKEY)}"
    timeout = "2m"
    host = "${digitalocean_droplet.gotcha-loadbalancer.ipv4_address}"
  }
  depends_on = ["digitalocean_droplet.gotcha-loadbalancer"]

  provisioner "remote-exec" {
    inline = [
      "printf \"\n\tserver ${format("gotchamaster%02d", count.index + 1)} ${element(digitalocean_droplet.gotchamaster.*.ipv4_address, count.index)}:80 check\" >> /etc/haproxy/haproxy.cfg",
      "/etc/init.d/haproxy restart"
    ]
  }

}