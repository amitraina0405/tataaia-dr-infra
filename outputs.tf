output "primary_vpc_id" { value = aws_vpc.primary.id }
output "dr_vpc_id" { value = aws_vpc.dr.id }
output "primary_nlb_dns" { value = aws_lb.primary_nlb.dns_name }
output "dr_nlb_dns" { value = aws_lb.dr_nlb.dns_name }
output "rds_primary_endpoint" { value = aws_db_instance.primary.address }
output "rds_dr_replica_endpoint" { value = aws_db_instance.dr_replica.address }