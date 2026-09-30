pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                // Usa el repo y la rama configurados en el job (SCM)
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Preparar entorno') {
            steps {
                sh 'flutter --version'
                // firebase_options.dart no está en el repo (.gitignore):
                // se inyecta desde una credencial "Secret file" de Jenkins
                withCredentials([file(credentialsId: 'firebase-options-dart', variable: 'FIREBASE_OPTIONS')]) {
                    sh 'cp "$FIREBASE_OPTIONS" lib/firebase_options.dart'
                }
                sh 'flutter pub get'
            }
        }

        stage('Análisis estático') {
            steps {
                sh 'flutter analyze --no-fatal-infos --no-fatal-warnings'
            }
        }

        stage('Pruebas unitarias') {
            steps {
                sh 'flutter test --machine > test-report.json'
            }
            post {
                always {
                    sh 'tojunit --input test-report.json --output junit.xml || true'
                    junit allowEmptyResults: true, testResults: 'junit.xml'
                }
            }
        }

        stage('Build Web') {
            steps {
                sh 'flutter build web --release'
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: 'build/web/**', fingerprint: true
            echo 'Pipeline ejecutado con éxito: build web archivado.'
        }
        failure {
            echo 'Pipeline fallido. Revisar la etapa en rojo y su log.'
        }
        always {
            // No dejar el archivo de Firebase en el workspace
            sh 'rm -f lib/firebase_options.dart'
        }
    }
}
