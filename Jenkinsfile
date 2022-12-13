pipeline {
  agent any
  triggers {
    githubPush()
  }
  environment {
    TF_IN_AUTOMATION = 'true'
    ANSIBLE_HOST_KEY_CHECKING = 'False'
  }
  stages {
    stage('Test') {
      steps {
        dir('src/api') {
          // Delete test container if it already exists
          sh 'npm run db:stop 2> /dev/null || true'

          // Setup and run tests
          sh 'npm ci'
          sh 'npm run db:start'
          sh 'npm run test'
          sh 'npm run db:stop'
        }
      }
    }
    stage('Init') {
      steps {
        dir('infrastructure/application') {
          sh 'terraform init -no-color'
        }
      }
    }
    stage('Plan') {
      steps {
        dir('infrastructure/application') {
          sh 'export TF_LOG=1'
          sh 'terraform plan -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
      }
    }
    stage ('Validate Apply') {
      when {
        beforeInput true
        branch "main"
      }
      input {
        message "Do you want to apply this plan?"
        ok "Apply this plan."
      }
      steps {
        echo 'Apply Accepted'
      }
    }
    stage ('Apply') {
      steps {
        dir('infrastructure/application') {
          sh 'terraform apply -no-color -auto-approve -var-file="$BRANCH_NAME.tfvars"'
        }
      }
    }
    stage ('Build Application Container') {
      steps {
        dir ('infrastructure/application') {
          script {
            env.AWS_ACCOUNT_ID = sh(script: 'terraform output -json account_id | jq -r .', returnStdout: true).trim()
            env.REPO_NAME = sh(script: 'terraform output -json application_image_repo_name | jq -r .', returnStdout: true).trim()
          }
        }

        dir('src/api') {
          sh '''
            aws ecr get-login-password --region us-west-2 | \\
            docker login \\
            --username AWS \\
            --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com"
            docker build -t "$REPO_NAME" .
            docker tag "${REPO_NAME}:latest" "${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/${REPO_NAME}:latest"
            docker push "${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/${REPO_NAME}:latest"'''
        }
      }
    }
    stage('Set Ansible Inventory') {
      steps {
        dir('infrastructure/application') {
          sh 'echo [main] > aws_hosts'
          sh '''printf \\
            "\\n$(terraform output -json instance_public_dns_list | jq -r \'.[]\')" \\
            >> aws_hosts'''
        }

        sh 'cp infrastructure/application/aws_hosts application_hosts'
      }
    }
    stage('Update Application Server') {
      steps {
        ansiblePlaybook(credentialsId: 'application-ssh-key', inventory: 'application_hosts', playbook: 'playbooks/application.yml')
      }
    }
  }
  post {
    success {
      echo 'Success'
    }
    failure {
      echo 'Failure'
    }
    aborted {
      echo 'Aborted'
    }
  }
}
