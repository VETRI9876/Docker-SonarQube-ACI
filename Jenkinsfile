pipeline {
    agent any

    environment {
        DOCKER_IMAGE = '409784048198.dkr.ecr.eu-north-1.amazonaws.com/vetri'
        REPO_URL = 'https://github.com/VETRI9876/Jenkins-Docker-Trivy-ECR-EC2.git'
        EC2_INSTANCE_IP = '51.20.93.114'
        AWS_REGION = 'eu-north-1'
        ECR_REPO_NAME = 'vetri'
        SSH_KEY = credentials('KEY_PAIR') 
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
                    sshagent(credentials: ['KEY_PAIR']) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_INSTANCE_IP} '
                            aws ecr get-login-password --region ${AWS_REGION} | sudo docker login --username AWS --password-stdin ${DOCKER_IMAGE} &&
                            sudo docker pull ${DOCKER_IMAGE}:latest &&
                            CONTAINER_ID=\$(sudo docker ps -q --filter ancestor=${DOCKER_IMAGE}:latest)
                            if [ ! -z "\$CONTAINER_ID" ]; then
                                sudo docker stop \$CONTAINER_ID &&
                                sudo docker rm \$CONTAINER_ID
                            fi
                            sudo docker run -d -p 8090:5000 ${DOCKER_IMAGE}:latest
                        '
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -af || true'
        }
    }
}
