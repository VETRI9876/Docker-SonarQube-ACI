pipeline {
    agent any

    environment {
        DOCKER_IMAGE = '409784048198.dkr.ecr.eu-north-1.amazonaws.com/vetri'
        REPO_URL = 'https://github.com/VETRI9876/Docker-Trivy-ECR-EC2.git'
        EC2_INSTANCE_IP = '13.53.127.142'  // Replace with actual IP
        AWS_REGION = 'eu-north-1'
        ECR_REPO_NAME = 'vetri'
        SSH_KEY = credentials('KEY_PAIR') // Ensure this exists in Jenkins credentials as a Secret Text
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: "${REPO_URL}", branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }

        stage('Run Tests with Pytest') {
            steps {
                script {
                    sh 'pytest > result.log; tail -n 10 result.log'
                }
            }
        }

        stage('Scan Docker Image with Trivy') {
            steps {
                script {
                    sh 'trivy image ${DOCKER_IMAGE}'
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${DOCKER_IMAGE}
                    docker tag ${DOCKER_IMAGE}:latest ${DOCKER_IMAGE}:latest
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Save the private key to a file
                    writeFile file: 'key.pem', text: "${env.SSH_KEY}"
                    sh 'chmod 400 key.pem'

                    // SSH into EC2 and deploy the container
                    sh """
                    ssh -o StrictHostKeyChecking=no -i key.pem ec2-user@${EC2_INSTANCE_IP} << 'EOF'
                    docker pull ${DOCKER_IMAGE}:latest
                    docker stop \$(docker ps -q --filter ancestor=${DOCKER_IMAGE}:latest) || true
                    docker run -d -p 80:80 ${DOCKER_IMAGE}:latest
                    EOF
                    """

                    // Clean up private key file
                    sh 'rm -f key.pem'
                }
            }
        }
    }

    post {
        always {
            node {
                sh 'docker system prune -af'
            }
        }
    }
}
