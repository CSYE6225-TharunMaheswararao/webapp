variable "db_user" {
  default = "default_user"
}

variable "db_password" {
  default = "default_password"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "custom-webapp-ubuntu-24"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-04b4f1a9cf54c11d0" # Ensure this is the correct Ubuntu 24.04 AMI ID
  ssh_username  = "ubuntu"
  profile       = "a4githubactions"
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "file" {
    source      = "./webapp.zip"
    destination = "/tmp/webapp.zip"
  }

  # Upload setup.sh
  provisioner "file" {
    source      = "./app/scripts/setup.sh" # Ensure this file exists locally
    destination = "/tmp/setup.sh"
  }

  # Ensure file exists and execute it
  provisioner "shell" {
    inline = [
      "sudo sed -i 's/\r$//' /tmp/setup.sh", # Convert Windows line endings
      "sudo chmod +x /tmp/setup.sh",
      "export DB_USER=${var.db_user}",
      "export DB_PASSWORD=${var.db_password}",
      "echo 'DB_USER is ' $DB_USER", # Debugging: Check if variable is set
      "echo 'DB_PASSWORD is ' $DB_PASSWORD",
      "sudo DB_USER=${var.db_user} DB_PASSWORD=${var.db_password} /tmp/setup.sh"
    ]
  }
}