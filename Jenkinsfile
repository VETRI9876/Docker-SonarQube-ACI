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
                    writeFile file: 'key.pem', text: "${SSH_KEY}"
                    sh 'chmod 400 key.pem'

                    sh """
                    ssh -o StrictHostKeyChecking=no -i key.pem ec2-user@${EC2_INSTANCE_IP} << EOF
                    docker pull ${DOCKER_IMAGE}:latest
                    docker ps -q --filter ancestor=${DOCKER_IMAGE}:latest | xargs -r docker stop
                    docker ps -a -q --filter ancestor=${DOCKER_IMAGE}:latest | xargs -r docker rm
                    docker run -d -p 80:80 ${DOCKER_IMAGE}:latest
                    EOF
                    """

                    sh 'rm -f key.pem'
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -af'
        }
    }
}
