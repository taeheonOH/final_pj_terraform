resource "aws_ebs_volume" "final-ebs-volume" {
  availability_zone = "ap-northeast-2c"
  size              = 20

  tags = {
    Name = "final-ebs-volume"
  }
}

resource "aws_volume_attachment" "final-ebs-volume" {
    device_name = "/dev/sdb"
    volume_id   = "${aws_ebs_volume.final-ebs-volume.id}"
    instance_id = "${aws_instance.final-ec2-pub-c-control.id}"
  }

resource "aws_efs_file_system" "final-efs" {
  creation_token = "final"
  tags = {
    Name = "final-efs"
  }
}
 
resource "aws_efs_mount_target" "final-efs-mount-target" {
    file_system_id = "${aws_efs_file_system.final-efs.id}"
    subnet_id      = "${aws_subnet.final-sub-pub-a.id}"
}