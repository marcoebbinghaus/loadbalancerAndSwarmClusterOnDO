resource "digitalocean_domain" "gotchadomain-main" {
  name       = "gotcha-app.de"
  ip_address = "127.0.0.1"
}