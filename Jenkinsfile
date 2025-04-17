pipeline {
    agent any

    environment {
        DOCKER_IMAGE = '409784048198.dkr.ecr.eu-north-1.amazonaws.com/vetri'
        REPO_URL = 'https://github.com/VETRI9876/Docker-Trivy-ECR-EC2.git'
        EC2_INSTANCE_IP = '13.53.127.142'
        AWS_REGION = 'eu-north-1'
        ECR_REPO_NAME = 'vetri'
        SSH_KEY = credentials('KEY_PAIR') // Jenkins SSH key credential
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
                        sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@13.53.127.142 << 'EOF'
                        aws ecr get-login-password --region eu-north-1 | sudo docker login --username AWS --password-stdin 409784048198.dkr.ecr.eu-north-1.amazonaws.com/vetri

                        sudo docker pull 409784048198.dkr.ecr.eu-north-1.amazonaws.com/vetri:latest

                        CONTAINER_ID=$(sudo docker ps -q --filter ancestor=409784048198.dkr.ecr.eu-north-1.amazonaws.com/vetri:latest)
                        if [ ! -z "$CONTAINER_ID" ]; then
                            sudo docker stop $CONTAINER_ID
                            sudo docker rm $CONTAINER_ID
                        fi

                        sudo docker run -d -p 8085:80 409784048198.dkr.ecr.eu-north-1.amazonaws.com/vetri:latest
                        EOF
                        '''
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
