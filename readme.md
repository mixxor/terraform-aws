# Terraform examples


## EC2 SSH Access and Kubernetes Configuration

## Generating an SSH Access Key for AWS EC2

To generate an SSH access key for your EC2 instance, use the following command:

```sh
ssh-keygen -t rsa -b 2048 -f mykey
```

This command creates a new SSH key, using the provided filename `mykey` which you can then use to connect to your EC2 instance.

## Connecting to an AWS EC2 Instance

Replace `PUBLIC-IP` with the public IP address of your EC2 instance.

For an AWS Linux instance, use:

```sh
ssh -i mykey ec2-user@PUBLIC-IP
```

For an Ubuntu instance, use:

```sh
ssh -i mykey ubuntu@PUBLIC-IP
```

## Viewing Cloud-Init Output Log in EC2

To check the initialization logs of your EC2 instance, run:

```sh
cat /var/log/cloud-init-output.log
```

## Kubernetes Configuration with AWS EKS

Update your Kubernetes configuration with the AWS CLI:

```sh
aws eks update-kubeconfig --region region-code --name my-cluster
```

Make sure to replace `region-code` with your actual AWS region code and `my-cluster` with the name of your EKS cluster.

## Launching a Temporary Interactive Shell in Kubernetes

To start a temporary interactive shell within your Kubernetes cluster, use:

```sh
sudo kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot
```

This command uses the `nicolaka/netshoot` image to run a temporary shell for troubleshooting or quick commands execution within the cluster.