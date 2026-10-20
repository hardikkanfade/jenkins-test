pipeline {
    agent any

    environment {
        NODE_ENV = 'production'
        DOCKER_IMAGE = 'hardikkanfade/youtube-clone'
        DOCKER_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                sh 'npm ci'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running unit tests...'
                sh 'CI=true npm test -- --watch=false'
            }
        }

        stage('Build Application') {
            steps {
                echo 'Building React production bundle...'
                sh 'npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Docker Push') {
            when {
                branch 'main'
            }
            steps {
                echo 'Pushing Docker image to registry...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying application...'
                sh "docker stop youtube-clone || true"
                sh "docker rm youtube-clone || true"
                sh "docker run -d --name youtube-clone -p 3000:3000 ${DOCKER_IMAGE}:latest"
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo 'Build completed successfully.'
        }
        failure {
            echo 'Build failed. Please check logs.'
        }
    }
}
