resource "aws_iam_role" "wanderlust_ec2" {
  name = "wanderlust-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "Wanderlust"
  }
}

resource "aws_iam_role_policy_attachment" "wanderlust_ssm" {
  role       = aws_iam_role.wanderlust_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "wanderlust_ec2" {
  name = "wanderlust-ec2-profile"
  role = aws_iam_role.wanderlust_ec2.name
}
