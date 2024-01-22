data "aws_ami" "image" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["${var.ami}"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "basic_vm" {
  ami           = data.aws_ami.image.id
  instance_type = var.instancetype
  key_name      = var.keyname
  subnet_id	= var.subnet
  get_password_data = "true"
}

output "password" {
  value = "${rsadecrypt(aws_instance.basic_vm.password_data, file("${var.keypath}"))}"
}