pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'hardikkanfade/youtube-clone'
        DOCKER_TAG = "${env.BRANCH_NAME ?: (env.GIT_BRANCH ?: 'build').replace('origin/', '')}-${env.BUILD_NUMBER}"
        DOCKER_CLI = 'C:\\Users\\Hardik kanfade\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe'
    }

    stages {
        stage('Verify Docker') {
            steps {
                echo 'Checking Docker access from the Jenkins agent...'
                bat 'whoami'
                bat 'if exist "%DOCKER_CLI%" (echo Docker CLI found) else (echo Docker CLI not found at configured path & exit /b 1)'
                bat '"%DOCKER_CLI%" version'
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
                bat '"%DOCKER_CLI%" build -t %DOCKER_IMAGE%:%DOCKER_TAG% .'
            }
        }

        stage('Docker Push') {
            when {
                branch 'main'
            }
            steps {
                echo 'Pushing Docker image to registry...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    bat 'echo %DOCKER_PASS%| "%DOCKER_CLI%" login -u "%DOCKER_USER%" --password-stdin'
                    bat '"%DOCKER_CLI%" push %DOCKER_IMAGE%:%DOCKER_TAG%'
                    bat '"%DOCKER_CLI%" tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest'
                    bat '"%DOCKER_CLI%" push %DOCKER_IMAGE%:latest'
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying application...'
                bat '"%DOCKER_CLI%" stop youtube-clone 2>NUL || exit /b 0'
                bat '"%DOCKER_CLI%" rm youtube-clone 2>NUL || exit /b 0'
                bat '"%DOCKER_CLI%" run -d --name youtube-clone -p 3000:3000 %DOCKER_IMAGE%:latest'
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
