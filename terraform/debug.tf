output "master-user-data" {
  value = "${data.template_file.master-aws-launch-configuration-user-data.rendered}"
}

output "node-user-data" {
  value = "${data.template_file.nodes-aws-launch-configuration-user-data.rendered}"
}
