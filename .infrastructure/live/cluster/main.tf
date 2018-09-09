provider "digitalocean" {
  token = "${var.DO_TOKEN}"
}

module "cluster" {
  source = "../../modules/cluster"

  DO_MASTERCOUNT = "${var.DO_MASTERCOUNT}"
  DO_SIZE = "${var.DO_SIZE}"
  DO_PRIVKEY = "${var.DO_PRIVKEY}"
  DO_PUBKEY_PLAIN = "${var.DO_PUBKEY_PLAIN}"
  DO_REGION = "${var.DO_REGION}"
  DO_TOKEN = "${var.DO_TOKEN}"
  DO_KEYFINGERPRINT = "${var.DO_KEYFINGERPRINT}"
  DO_WORKERCOUNT = "${var.DO_WORKERCOUNT}"

  AWS_SECRETKEY = "${var.AWS_SECRETKEY}"
  AWS_ACCESSKEY = "${var.AWS_ACCESSKEY}"

}
