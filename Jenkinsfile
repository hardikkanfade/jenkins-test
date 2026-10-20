pipeline {
    agent any

    stages {
        stage('Install Dependencies') {
            steps {
                bat 'npm ci'
            }
        }

        stage('Build Application') {
            steps {
                bat 'npm run build'
            }
        }

        stage('Archive Build') {
            steps {
                archiveArtifacts artifacts: 'build/**', fingerprint: true
            }
        }

        stage('Start Application') {
            steps {
                bat 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\start-jenkins-server.ps1'
            }
        }
    }

    post {
        success {
            echo 'React app is running at http://localhost:3000 on the Jenkins machine.'
        }
        failure {
            echo 'Pipeline failed. Check the stage logs for details.'
        }
    }
}
