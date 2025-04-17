pipeline {
    agent any

    environment {
        DOCKER_IMAGE = '409784048198.dkr.ecr.eu-north-1.amazonaws.com/vetri'
        REPO_URL = 'https://github.com/VETRI9876/Docker-Trivy-ECR-EC2.git'
        EC2_INSTANCE_IP = '13.53.127.142'
        AWS_REGION = 'eu-north-1'
        ECR_REPO_NAME = 'vetri'
        SSH_KEY = credentials('KEY_PAIR') // Jenkins secret text (PEM content)
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: "${REPO_URL}", branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:latest .'
            }
        }

        stage('Run Tests with Pytest (Inside Docker)') {
            steps {
                sh 'docker run --rm ${DOCKER_IMAGE}:latest pytest > result.log'
                sh 'tail -n 10 result.log'
            }
        }

        stage('Scan Docker Image with Trivy') {
            steps {
                sh 'trivy image ${DOCKER_IMAGE}:latest'
            }
        }

        stage('Push to ECR') {
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${DOCKER_IMAGE}
                docker push ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Use ssh-agent to load the SSH key
                    sshagent(credentials: ['KEY_PAIR']) {
                        // SSH login to EC2 (use 'ubuntu' as the user for Ubuntu-based AMIs)
                        sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_INSTANCE_IP} << EOF
                        # Authenticate with AWS ECR
                        aws ecr get-login-password --region ${AWS_REGION} | sudo docker login --username AWS --password-stdin ${DOCKER_IMAGE}
                        
                        # Pull the latest image from ECR
                        sudo docker pull ${DOCKER_IMAGE}:latest
                        
                        # Stop and remove any existing containers
                        sudo docker ps -q --filter ancestor=${DOCKER_IMAGE}:latest | xargs -r sudo docker stop
                        sudo docker ps -a -q --filter ancestor=${DOCKER_IMAGE}:latest | xargs -r sudo docker rm
                        
                        # Run the Docker container
                        sudo docker run -d -p 80:80 ${DOCKER_IMAGE}:latest
                        EOF
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up Docker images to free space
            sh 'docker system prune -af'
        }
    }
}
