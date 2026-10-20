pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'hardikkanfade/youtube-clone'
        DOCKER_TAG = "${env.BRANCH_NAME ?: (env.GIT_BRANCH ?: 'build').replace('origin/', '')}-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Verify Docker') {
            steps {
                echo 'Checking Docker access from the Jenkins agent...'
                bat 'whoami'
                bat 'where docker'
                bat 'docker version'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                bat 'npm ci'
            }
        }

        stage('Build Application') {
            steps {
                echo 'Building React production bundle...'
                bat 'npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                bat 'docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% .'
            }
        }

        stage('Docker Push') {
            when {
                branch 'main'
            }
            steps {
                echo 'Pushing Docker image to registry...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    bat 'echo %DOCKER_PASS%| docker login -u "%DOCKER_USER%" --password-stdin'
                    bat 'docker push %DOCKER_IMAGE%:%DOCKER_TAG%'
                    bat 'docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest'
                    bat 'docker push %DOCKER_IMAGE%:latest'
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying application...'
                bat 'docker stop youtube-clone 2>NUL || exit /b 0'
                bat 'docker rm youtube-clone 2>NUL || exit /b 0'
                bat 'docker run -d --name youtube-clone -p 3000:3000 %DOCKER_IMAGE%:latest'
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
