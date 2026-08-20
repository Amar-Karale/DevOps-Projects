@Library('Shared') _

pipeline {
    agent { label 'spy' }

    environment {
        SONAR_HOME      = tool 'Sonar'
        TRIVY_EXIT_CODE = '0' // Change to 1 to make HIGH/CRITICAL findings fail the build.
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Docker image tag for frontend')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Docker image tag for backend')
        string(name: 'VITE_API_PATH', defaultValue: '', description: 'Public backend API URL')
    }

    stages {
        stage('Validate Parameters') {
            steps {
                script {
                    if (!params.FRONTEND_DOCKER_TAG?.trim() ||
                        !params.BACKEND_DOCKER_TAG?.trim() ||
                        !params.VITE_API_PATH?.trim()) {
                        error('FRONTEND_DOCKER_TAG, BACKEND_DOCKER_TAG and VITE_API_PATH must be provided.')
                    }
                }
            }
        }

        stage('Workspace Cleanup') {
            steps { cleanWs() }
        }

        stage('Git: Code Checkout') {
            steps {
                script {
                    code_checkout('https://github.com/Amar-Karale/DevOps-Projects.git', 'master')
                }
            }
        }

        stage('Trivy: Filesystem Scan') {
            steps {
                sh '''
                    set -e
                    trivy fs \
                      --scanners vuln,misconfig,secret \
                      --severity HIGH,CRITICAL \
                      --ignore-unfixed \
                      --exit-code "$TRIVY_EXIT_CODE" \
                      .
                '''
            }
        }

        stage('OWASP: Dependency Check') {
            steps { script { owasp_dependency() } }
        }

        stage('SonarQube: Code Analysis') {
            steps { script { sonarqube_analysis('Sonar', 'wanderlust', 'wanderlust') } }
        }

        stage('SonarQube: Code Quality Gates') {
            steps { script { sonarqube_code_quality() } }
        }

        stage('Configure Frontend Build') {
            steps {
                dir('frontend') {
                    sh 'printf "VITE_API_PATH=\\\"%s\\\"\\n" "$VITE_API_PATH" > .env.docker'
                }
            }
        }

        stage('Docker: Build Images') {
            steps {
                script {
                    dir('backend') {
                        docker_build('wanderlust-backend-beta', params.BACKEND_DOCKER_TAG, 'amarkarale')
                    }
                    dir('frontend') {
                        docker_build('wanderlust-frontend-beta', params.FRONTEND_DOCKER_TAG, 'amarkarale')
                    }
                }
            }
        }

        stage('Trivy: Container Image Scan') {
            steps {
                sh """
                    set -e
                    trivy image \\
                      --scanners vuln,misconfig,secret \\
                      --severity HIGH,CRITICAL \\
                      --ignore-unfixed \\
                      --exit-code ${TRIVY_EXIT_CODE} \\
                      amarkarale/wanderlust-backend-beta:${params.BACKEND_DOCKER_TAG}

                    trivy image \\
                      --scanners vuln,misconfig,secret \\
                      --severity HIGH,CRITICAL \\
                      --ignore-unfixed \\
                      --exit-code ${TRIVY_EXIT_CODE} \\
                      amarkarale/wanderlust-frontend-beta:${params.FRONTEND_DOCKER_TAG}
                """
            }
        }

        stage('Docker: Push to DockerHub') {
            steps {
                script {
                    docker_push('wanderlust-backend-beta', params.BACKEND_DOCKER_TAG, 'amarkarale')
                    docker_push('wanderlust-frontend-beta', params.FRONTEND_DOCKER_TAG, 'amarkarale')
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: '*.xml', followSymlinks: false
            build job: 'Wanderlust-CD', parameters: [
                string(name: 'FRONTEND_DOCKER_TAG', value: params.FRONTEND_DOCKER_TAG),
                string(name: 'BACKEND_DOCKER_TAG', value: params.BACKEND_DOCKER_TAG)
            ]
        }
    }
}
