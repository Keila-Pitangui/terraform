resource "random_string" "random" {
  length           = 5
  special          = false
  numeric = true
  lower = true
  upper = false
}

# Create a new Web Droplet 
resource "digitalocean_droplet" "terraform_droplet" {
  image   = "ubuntu-22-04-x64"
  name    = "terraform-doplet-${random_string.random.result}"
  region  = "nyc2"
  size    = "s-1vcpu-1gb"
  backups = true
  backup_policy {
    plan    = "weekly"
    weekday = "TUE"
    hour    = 8
  }
}

# Create a new container registry
resource "digitalocean_container_registry" "terraform_container" {
  name                   = "terraform-container-${random_string.random.result}"
  subscription_tier_slug = "starter"
}

output "registry_endpoint" {
  value = digitalocean_container_registry.terraform_container.endpoint
}

resource "digitalocean_database_cluster" "mysql" {
  name       = "terraform-database-dluster-${random_string.random.result}"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = "nyc2"
  node_count = 1

maintenance_window {
    day  = "monday"
    hour = "02:00"
  }
 }


# Observability
resource "digitalocean_monitor_alert" "cpu_alert" {
  alerts {
    email = ["kmpitangui@gmail.com"]
    slack {
      channel = "Production Alerts"
      url     = "https://app.slack.com/huddle/T09Q14F37E3/C09QL52DJ2G"
    }
  }
  window      = "5m"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = 95
  enabled     = true
  entities    = [digitalocean_droplet.terraform_droplet.id]
  description = "Alert about high CPU utilization average (over 95%)"
}


resource "digitalocean_monitor_alert" "load_alert" {
  alerts {
    email = ["kmpitangui@gmail.com"]
    slack {
      channel = "Production Alerts"
      url     = "https://app.slack.com/huddle/T09Q14F37E3/C09QL52DJ2G"
    }
  }
  window      = "5m"
  type        = "v1/insights/droplet/memory_utilization_percent"
  compare     = "GreaterThan"
  value       = 5.0 # Exemplo: Alerta se a carga média for maior que 5.0
  enabled     = true
  entities    = [digitalocean_droplet.terraform_droplet.id]
  description = "Alert about high Load Average 5min"
}

# Firewall
resource "digitalocean_firewall" "terraform_firewall" {
  name = "terraform-firewall-${random_string.random.result}"

  droplet_ids = [digitalocean_droplet.terraform_droplet.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["192.168.1.0/24", "2002:1:2::/48"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_loadbalancer" "public" {
  name   = "terraform-loadbalance-${random_string.random.result}"
  region = "nyc2"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.terraform_droplet.id]
}