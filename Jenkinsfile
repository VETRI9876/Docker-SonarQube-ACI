pipeline {
    agent any

    environment {
        SONARQUBE_ENV = 'SonarQube'
        AZURE_RG = 'myResourceGroup'                     // Change to your Azure resource group
        AZURE_ACI = 'flask-docker-aci'                   // Name for your Azure Container Instance
        ACR_IMAGE = 'vetridocker.azurecr.io/flask-docker-app:latest'
        ACI_DNS = 'flaskdockerappvetri'                       // Must be unique globally
        ACI_PORT = '5000'
    }

    tools {
        python 'Python3'    // Jenkins Python installation
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/VETRI9876/Docker-SonarQube-ACI.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'pip install -r requirements.txt || pip install flask pytest'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'pytest test_app.py'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_SCANNER_OPTS = "-Dsonar.projectKey=flask-app -Dsonar.sources=."
            }
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh 'sonar-scanner'
                }
            }
        }

        stage('Deploy to Azure Container Instance') {
            steps {
                withCredentials([azureServicePrincipal('azure-credentials')]) {
                    sh '''
                        az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
                        
                        az container create \
                          --resource-group $AZURE_RG \
                          --name $AZURE_ACI \
                          --image $ACR_IMAGE \
                          --registry-login-server vetridocker.azurecr.io \
                          --registry-username $AZURE_CLIENT_ID \
                          --registry-password $AZURE_CLIENT_SECRET \
                          --dns-name-label $ACI_DNS-${BUILD_NUMBER} \
                          --ports $ACI_PORT \
                          --location eastus
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
