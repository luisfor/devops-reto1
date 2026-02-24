pipeline {
    agent any

    stages {
        stage('Checkout Repo') {
            steps {
                checkout scm
            }
        }
        stage('Run Tests (Flask & Wiremock)') {
            steps {
                sh 'bash run_tests.sh'
            }
        }
    }
}
