output "webserver_url" {
  value = format("http://%s", aws_instance.this.public_ip)
}