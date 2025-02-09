pipeline {
    agent any
    environment {
        REGISTRY = "index.docker.io/v1/"
        IMAGE_NAME = "ykaz1291/backend-api"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}", "--network=host -f docker/Dockerfile .")
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${REGISTRY}", "dockerhub-credentials") {
                        dockerImage.push()
                    }
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
