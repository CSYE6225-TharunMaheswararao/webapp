variable "db_user" {
  default = "default_user"
}

variable "db_password" {
  default = "default_password"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_account_file" {
  description = "GCP Service Account Key File"
  type        = string
  default     = "gcp-key.json"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "custom-webapp-ubuntu-24"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-04b4f1a9cf54c11d0" # Ensure this is the correct Ubuntu 24.04 AMI ID
  ssh_username  = "ubuntu"
  profile       = "a4githubactions"
}

source "googlecompute" "gcp_ubuntu" {
  project_id       = var.gcp_project_id
  account_file     = var.gcp_account_file # Using GitHub Secrets
  source_image     = "ubuntu-2404-lts"
  machine_type     = "e2-medium"
  zone             = "us-east1-b"
  image_name       = "custom-webapp-gcp"
}

build {
  sources = [
    "source.amazon-ebs.ubuntu",
    "source.googlecompute.gcp_ubuntu"
  ]

  provisioner "file" {
    source      = "./webapp.zip" # ✅ Ensure it matches the GitHub Actions path
    destination = "/tmp/webapp.zip"
  }

  provisioner "file" {
    source      = "./webapp.service" # Ensure this is correct
    destination = "/tmp/webapp.service"
  }

  provisioner "file" {
    source      = "./app/scripts/create_user.sh"
    destination = "/tmp/create_user.sh"
  }

  provisioner "file" {
    source      = "./app/scripts/system_setup.sh"
    destination = "/tmp/system_setup.sh"
  }

  provisioner "file" {
    source      = "./app/scripts/mysql_setup.sh"
    destination = "/tmp/mysql_setup.sh"
  }

  provisioner "file" {
    source      = "./app/scripts/app_setup.sh"
    destination = "/tmp/app_setup.sh"
  }

  provisioner "file" {
    source      = "./app/scripts/systemd_setup.sh"
    destination = "/tmp/systemd_setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/*.sh",
      "export DB_USER=${var.db_user}",
      "export DB_PASSWORD=${var.db_password}",
      "echo 'DB_USER is ' $DB_USER", # Debugging: Check if variable is set
      "echo 'DB_PASSWORD is ' $DB_PASSWORD",
      "sudo /tmp/create_user.sh",
      "sudo /tmp/system_setup.sh",
      "sudo DB_USER=${var.db_user} DB_PASSWORD=${var.db_password} /tmp/mysql_setup.sh",
      "sudo /tmp/app_setup.sh",
      "sudo /tmp/systemd_setup.sh",
      "sudo systemctl restart webapp.service"
    ]
  }
}