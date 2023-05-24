provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "eks-iam-role" {
  name = "tonycava-eks-iam-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}

resource "aws_eks_cluster" "tonycava-eks" {
  name     = "tonycava-cluster"
  role_arn = aws_iam_role.eks-iam-role.arn

  vpc_config {
    subnet_ids = [var.subnet_id_1, var.subnet_id_2]
  }

  depends_on = [
    aws_iam_role.eks-iam-role,
  ]
}

resource "aws_iam_role" "worker-nodes" {
  name = "tonycava-node-group"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker-nodes.name
}

resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.tonycava-eks.name
  node_group_name = "tonycava-workernodes"
  node_role_arn   = aws_iam_role.worker-nodes.arn
  subnet_ids      = [var.subnet_id_1, var.subnet_id_2]
  instance_types  = ["t2.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_s3_bucket" "terraform-state-storage-s3" {
  bucket = "tonycava-backend-bucket-test-fdsw"
}

resource "aws_s3_bucket_object" "file_upload" {
  bucket = aws_s3_bucket.terraform-state-storage-s3.id
  key    = "tf-state"
  source = "${path.module}/terraform.tfstate"
}