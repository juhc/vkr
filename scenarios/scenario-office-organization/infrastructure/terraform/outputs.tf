# Terraform outputs для сценария офисной организации

output "web_server_ip" {
  value       = module.web_server.vm_ip_addresses[0]
  description = "IP адрес веб-сервера"
}

output "mail_server_ip" {
  value       = module.mail_server.vm_ip_addresses[0]
  description = "IP адрес почтового сервера"
}

output "dns_server_ip" {
  value       = module.dns_server.vm_ip_addresses[0]
  description = "IP адрес DNS сервера"
}

output "file_server_ip" {
  value       = module.file_server.vm_ip_addresses[0]
  description = "IP адрес файлового сервера"
}

output "db_server_ip" {
  value       = module.db_server.vm_ip_addresses[0]
  description = "IP адрес сервера базы данных"
}

output "backup_server_ip" {
  value       = module.backup_server.vm_ip_addresses[0]
  description = "IP адрес сервера резервного копирования"
}

output "monitoring_server_ip" {
  value       = module.monitoring_server.vm_ip_addresses[0]
  description = "IP адрес сервера мониторинга"
}

output "dev_server_ip" {
  value       = module.dev_server.vm_ip_addresses[0]
  description = "IP адрес сервера разработки"
}

output "test_server_ip" {
  value       = module.test_server.vm_ip_addresses[0]
  description = "IP адрес сервера тестирования"
}

output "cicd_server_ip" {
  value       = module.cicd_server.vm_ip_addresses[0]
  description = "IP адрес CI/CD сервера"
}

output "jump_server_ip" {
  value       = module.jump_server.vm_ip_addresses[0]
  description = "IP адрес jump-сервера"
}

# Файл для генерации Ansible инвентаря
output "ansible_inventory" {
  value = <<-EOT
    # Автоматически сгенерированный Ansible инвентарь
    # Время генерации: ${timestamp()}
    
    all:
      children:
        dmz_servers:
          hosts:
            web-server:
              ansible_host: ${module.web_server.vm_ip_addresses[0]}
            mail-server:
              ansible_host: ${module.mail_server.vm_ip_addresses[0]}
            dns-server:
              ansible_host: ${module.dns_server.vm_ip_addresses[0]}
        
        internal_servers:
          hosts:
            file-server:
              ansible_host: ${module.file_server.vm_ip_addresses[0]}
            db-server:
              ansible_host: ${module.db_server.vm_ip_addresses[0]}
            backup-server:
              ansible_host: ${module.backup_server.vm_ip_addresses[0]}
            monitoring-server:
              ansible_host: ${module.monitoring_server.vm_ip_addresses[0]}
        
        development_servers:
          hosts:
            dev-server:
              ansible_host: ${module.dev_server.vm_ip_addresses[0]}
            test-server:
              ansible_host: ${module.test_server.vm_ip_addresses[0]}
            ci-cd-server:
              ansible_host: ${module.cicd_server.vm_ip_addresses[0]}
        
        management_servers:
          hosts:
            jump-server:
              ansible_host: ${module.jump_server.vm_ip_addresses[0]}
  EOT
  description = "Ansible инвентарь в формате YAML"
}

