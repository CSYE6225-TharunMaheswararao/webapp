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
}

variable "ssh_username" {
  description = "SSH username for connecting to instances"
  type        = string
  default     = "ubuntu"
}

variable "db_name" {
  description = "SSH username for connecting to instances"
  type        = string
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "custom-webapp-ubuntu-24-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-04b4f1a9cf54c11d0" # Ensure this is the correct Ubuntu 24.04 AMI ID
  ssh_username  = var.ssh_username
  profile       = "a4githubactions"

  # Extra Debugging
  communicator = "ssh"
  ssh_timeout  = "20m"
}

source "googlecompute" "gcp_ubuntu" {
  ssh_username     = var.ssh_username
  project_id       = var.gcp_project_id
  credentials_json = file(var.gcp_account_file)
  source_image     = "ubuntu-2404-noble-amd64-v20250214"
  image_family     = "ubuntu-2404-lts-amd64"
  machine_type     = "e2-medium"
  zone             = "us-east1-b"
  image_name       = "custom-webapp-gcp-{{timestamp}}"
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
    source      = "./app/scripts/app_setup.sh"
    destination = "/tmp/app_setup.sh"
  }

  provisioner "file" {
    source      = "./app/scripts/systemd_setup.sh"
    destination = "/tmp/systemd_setup.sh"
  }

  provisioner "file" {
    source      = "./amazon-cloudwatch-agent.json"
    destination = "/tmp/amazon-cloudwatch-agent.json"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
      "sudo mv /tmp/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
    ]
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
      "echo 'Installing CloudWatch Agent dependencies...'",
      "sudo apt-get update -y",
      "sudo apt-get install -y libc6", # Ensure base dependencies
      "echo 'Downloading CloudWatch Agent...'",
      "wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb || { echo 'Download failed'; exit 1; }",
      "ls -lh /tmp/amazon-cloudwatch-agent.deb", # Verify download
      "echo 'Installing CloudWatch Agent...'",
      "sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb || { echo 'Fixing dependencies...'; sudo apt-get install -f -y; sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb; }",
      "rm -f /tmp/amazon-cloudwatch-agent.deb",
      "sudo systemctl enable amazon-cloudwatch-agent || { echo 'Failed to enable CloudWatch Agent'; exit 1; }",
      "sudo systemctl start amazon-cloudwatch-agent || { echo 'Failed to start CloudWatch Agent'; exit 1; }",      # Start the agent
      "sudo systemctl status amazon-cloudwatch-agent || { echo 'CloudWatch Agent status check failed'; exit 1; }", # Verify it's running
      "command -v /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl && echo 'CloudWatch Agent installed successfully' || { echo 'CloudWatch Agent binary not found'; exit 1; }",
      # Test StatsD by sending a test metric
      "echo 'Testing StatsD by sending a test metric...'",
      "echo 'CSYE6225.WebApp.test.metric:1|c' | nc -u -w1 localhost 8125 || { echo 'Failed to send test metric to StatsD'; exit 1; }",
      "chmod +x /tmp/app_setup.sh",
      "sudo DB_NAME=${var.db_name} DB_USER=${var.db_user} DB_PASSWORD=${var.db_password} /tmp/app_setup.sh",
      "sudo /tmp/systemd_setup.sh",
      "sudo systemctl restart webapp.service"
    ]
  }
}