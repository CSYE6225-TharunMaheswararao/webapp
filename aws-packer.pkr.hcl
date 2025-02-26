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
    source      = "/tmp/webapp.zip"  # ✅ Ensure it matches the GitHub Actions path
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
      "ls -lh /tmp/",  # ✅ Debugging: Check if webapp.zip exists
      "if [ ! -f /tmp/webapp.zip ]; then echo '❌ ERROR: webapp.zip is missing!'; exit 1; fi",
      "sudo apt-get install -y unzip",
      "sudo mkdir -p /opt/webapp",
      "sudo unzip -o /tmp/webapp.zip -d /opt/webapp",
      "sudo chmod -R 755 /opt/webapp",
      "sudo chown -R csye6225:csye6225 /opt/webapp"
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