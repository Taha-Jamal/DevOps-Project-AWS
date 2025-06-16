pipeline {
    agent any
      environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Setup SSH Key') {
            steps {
                script {
                    // Clean up any existing keys
                    sh 'rm -f jenkins_ssh_key jenkins_ssh_key.pub'
                    
                // Write the SSH private key with correct permissions
                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY_FILE')]) {
                        sh """
                            cp "\$SSH_KEY_FILE" jenkins_ssh_key
                            chmod 600 jenkins_ssh_key
                            ls -l jenkins_ssh_key
                        """
                    }
                    
                    // Write the SSH public key
                    withCredentials([file(credentialsId: 'jenkins_ssh_key_pub', variable: 'SSH_KEY_PUB_FILE')]) {
                        sh """
                            cp "\$SSH_KEY_PUB_FILE" jenkins_ssh_key.pub
                            chmod 644 jenkins_ssh_key.pub
                            ls -l jenkins_ssh_key.pub
                        """
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -no-color'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -no-color -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -no-color -auto-approve tfplan'
                }
            }
        }

        stage('Update Ansible Inventory') {
            steps {
                script {
                    dir('terraform') {
                        def publicIP = sh(
                            script: 'terraform output -raw public_ip',
                            returnStdout: true
                        ).trim()
                        
                        // Update Ansible inventory with the new IP
                        sh """
                            echo "[webserver]
${publicIP} ansible_user=ubuntu ansible_ssh_private_key_file=../jenkins_ssh_key" > ../ansible/inventory.ini
                        """
                    }
                }
            }
        }

        stage('Wait for SSH') {
            steps {
                script {
                    def publicIP = sh(
                        script: 'cd terraform && terraform output -raw public_ip',
                        returnStdout: true
                    ).trim()
                    
                    // Wait for SSH to become available
                    sh """
                        timeout 300 bash -c 'until ssh -o StrictHostKeyChecking=no -i jenkins_ssh_key ubuntu@${publicIP} echo Connected > /dev/null 2>&1; do sleep 5; done'
                    """
                }
            }
        }

        stage('Run Ansible') {
            steps {
                dir('ansible') {
                    sh 'ansible-playbook -i inventory.ini install_web.yml'
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    def publicIP = sh(
                        script: 'cd terraform && terraform output -raw public_ip',
                        returnStdout: true
                    ).trim()
                    
                    // Test the website
                    sh "curl -s -f http://${publicIP}"
                }
            }
        }
    }
    
    post {
        always {
            sh 'rm -f jenkins_ssh_key jenkins_ssh_key.pub'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
            dir('terraform') {
                sh 'terraform destroy -auto-approve || true'
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
