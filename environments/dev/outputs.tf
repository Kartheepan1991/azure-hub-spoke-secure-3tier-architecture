# ============================================================
# OUTPUTS — Dev Environment
# ============================================================
# These values are printed after 'terraform apply' completes.
# Very useful for knowing what was deployed and how to access it.
# ============================================================

# ── Networking ────────────────────────────────────────────────
output "hub_vnet_id" {
  description = "Hub VNet Resource ID"
  value       = module.hub_vnet.vnet_id
}

output "firewall_public_ip" {
  description = "Azure Firewall outbound public IP"
  value       = module.firewall.firewall_public_ip
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP (next hop for UDRs)"
  value       = module.firewall.firewall_private_ip
}

# ── VM Private IPs ────────────────────────────────────────────
output "web_vm_private_ip" {
  description = "Web tier VM private IP — connect via Bastion"
  value       = module.vm_web.private_ip_address
}

output "app_vm_private_ip" {
  description = "App tier VM private IP — APIM backend"
  value       = module.vm_app.private_ip_address
}

output "data_vm_private_ip" {
  description = "Data tier VM private IP"
  value       = module.vm_data.private_ip_address
}

# ── Quick Test Guide (shown after apply) ─────────────────────
output "test_instructions" {
  description = "How to test the deployment"
  value = <<-EOT
  =============================================
  TEST YOUR DEPLOYMENT:
  =============================================
  1. RDP into Web VM via Azure Bastion (Portal):
     VM: ${module.vm_web.vm_name}
     Private IP: ${module.vm_web.private_ip_address}
     Username: azureadmin (from tfvars)

  2. From Web VM browser → test App tier:
     http://${module.vm_app.private_ip_address}/
     http://${module.vm_app.private_ip_address}/api/hello

  3. From App VM browser → test Data tier:
     http://${module.vm_data.private_ip_address}/

  4. Verify Firewall is routing traffic:
     Azure Portal → Firewall → Logs

  5. Destroy when done (saves cost!):
     terraform destroy
  =============================================
  EOT
}
