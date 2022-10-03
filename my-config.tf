 variable "image-id" {
   type = string

 }
 ###################VM-SPECS######################
 resource "yandex_compute_instance" "vm-1" {
     name = "from-terraform-vm"
     platform_id = "standard-v1"
     zone = "ru-central1-a"
   
   boot_disk {
       initialize_params {
         image_id = var.image-id
     
     }
     }
   resources {
       cores  = 2
       memory = 2
  }

   network_interface {
       subnet_id = yandex_vpc_subnet.subnet-1.id
       nat       = true
  }

   metadata = {
       ssh-keys = "ubuntu:${file("~/.ssh/authorized_keys")}"
  }
}
#################NETWORK_SPECS########################
resource "yandex_vpc_network" "network-1" {
   name = "from-terraform-network"
 }
resource "yandex_vpc_subnet" "subnet-1" {
   name       = "from-terraform-subnet"
   zone       = "ru-central1-a"
   network_id = "${yandex_vpc_network.network-1.id}"
   v4_cidr_blocks = ["10.2.0.0/16"]
}
output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}
 
output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}


####################Postgresql#########################
resource "yandex_mdb_postgresql_cluster" "TerraPostgres" {
  name        = "PostgreSQL-from-Terraform"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.network-1.id

  config {
    version = 12
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 16
    }
    postgresql_config = {
      max_connections                   = 395
      enable_parallel_hash              = true
      vacuum_cleanup_index_scale_factor = 0.2
      autovacuum_vacuum_scale_factor    = 0.34
      default_transaction_isolation     = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries          = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 12
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.subnet-1.id
  }
}
