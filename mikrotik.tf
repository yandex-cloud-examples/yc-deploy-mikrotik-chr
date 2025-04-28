# ==================================
# Mikrotik Cloud Hosted Router (CHR)
# ==================================

# Build init config
locals {
  init_config = templatefile("chr-init.tpl", {
    CHR_NAME      = var.chr_name
    ADMIN_NAME    = var.admin_name
    ADMIN_SSH_KEY = chomp(file("${var.admin_key_file}"))
    ADMIN_PASS    = substr(base64sha256(plantimestamp()), 5, 12)
  })
}

resource "local_file" "init_config" {
  content  = local.init_config
  filename = "init.cfg"
}

data "yandex_compute_image" "vm_image" {
  folder_id = length(var.chr_image_folder_id) == 0 ? var.folder_id : var.chr_image_folder_id
  image_id  = var.chr_image_id
}

resource "yandex_compute_instance" "chr_vm" {
  folder_id   = var.folder_id
  name        = var.chr_name
  hostname    = var.chr_name
  platform_id = "standard-v3"
  zone        = var.zone_id
  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_image.id
    }
  }

  network_interface {
    subnet_id          = var.vpc_subnet_id
    ip_address         = var.chr_ip
    nat                = true
    security_group_ids = [yandex_vpc_security_group.chr_sg.id]
  }

  metadata = {
    # For debug purpose only
    serial-port-enable = 1
  }
}

data "yandex_vpc_subnet" "vpc_subnet" {
  subnet_id = var.vpc_subnet_id
}

resource "yandex_vpc_security_group" "chr_sg" {
  folder_id  = var.folder_id
  name       = "chr-sg"
  network_id = data.yandex_vpc_subnet.vpc_subnet.network_id

  ingress {
    description    = "icmp"
    protocol       = "ICMP"
    v4_cidr_blocks = tolist(flatten([join("", [var.seed_ip, "/32"]), var.allowed_ip_list]))
  }

  ingress {
    description    = "ssh"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = tolist(flatten([join("", [var.seed_ip, "/32"]), var.allowed_ip_list]))
  }

  ingress {
    description    = "winbox"
    protocol       = "TCP"
    port           = 8291
    v4_cidr_blocks = tolist(flatten([join("", [var.seed_ip, "/32"]), var.allowed_ip_list]))
  }

  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "init" {
  provisioner "local-exec" {
    command = <<-CMD
    scp -o ConnectTimeout=180 -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' init.cfg admin@${yandex_compute_instance.chr_vm.network_interface[0].nat_ip_address}:init.cfg

    ssh -o ConnectTimeout=180 -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' admin@${yandex_compute_instance.chr_vm.network_interface[0].nat_ip_address} '/import init.cfg'
    CMD
  }
  depends_on = [
    yandex_compute_instance.chr_vm
  ]

  lifecycle {
    ignore_changes = all
  }
}

output "connection-string" {
  value = "ssh ${var.admin_name}@${yandex_compute_instance.chr_vm.network_interface[0].nat_ip_address}"
}
