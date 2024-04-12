CloudFormation do

  IAM_Role("CodeDeployRole") do
      AssumeRolePolicyDocument ({
          Statement: [
              {
                  Effect: 'Allow',
                  Principal: {
                      Service: [
                          'codedeploy.us-east-1.amazonaws.com',
                          'codedeploy.us-west-2.amazonaws.com',
                          'codedeploy.eu-west-1.amazonaws.com',
                          'codedeploy.ap-southeast-2.amazonaws.com'
                      ]
                  },
                  Action: [ 'sts:AssumeRole' ]
              }
          ]
      })
      Path '/'
      Policies ([
          PolicyName: 'CodeDeployRole',
          PolicyDocument: {
              Statement: [
                  {
                      Effect: 'Allow',
                      Action: [
                          'autoscaling:CompleteLifecycleAction',
                          'autoscaling:DeleteLifecycleHook',
                          'autoscaling:DescribeAutoScalingGroups',
                          'autoscaling:DescribeLifecycleHooks',
                          'autoscaling:PutLifecycleHook',
                          'autoscaling:RecordLifecycleActionHeartbeat',
                          'ec2:DescribeInstances',
                          'ec2:DescribeInstanceStatus',
                          'tag:GetTags',
                          'tag:GetResources'
                      ],
                      Resource: '*'
                  }
              ]
          }
      ])
  end
  


  applications.each do |application|
      codedeploy_application_name=application['name']

      CodeDeploy_Application("#{codedeploy_application_name}CodeDeployApplication") do
          ApplicationName FnJoin('', [ Ref('EnvironmentName'), "-#{codedeploy_application_name}" ])
      end

      application['deployment_groups'].each do |deployment_group|
          codedeploy_deployment_group_name=deployment_group['name']
          codedeploy_deployment_config_name=deployment_group['deployment_config_name']
          rollbackConfig = {}
          if (deployment_group.has_key?('autoRollback'))
              rollbackConfig['Enabled'] = true
              if (deployment_group['autoRollback'].is_a?(Array))
                  rollbackConfig['Enabled'] = true
                  rollbackConfig['Events'] = deployment_group['autoRollback']
              else
                  rollbackConfig['Events'] = ['DEPLOYMENT_FAILURE', 'DEPLOYMENT_STOP_ON_ALARM', 'DEPLOYMENT_STOP_ON_REQUEST']
              end
          else
              rollbackConfig['Enabled'] = false
          end
          
          if !(deployment_group['autoScalingGroups'].nil?)
              CodeDeploy_DeploymentGroup("#{codedeploy_deployment_group_name}DeploymentGroup") do
                  DeploymentGroupName FnJoin('', [ Ref('EnvironmentName'), "-#{codedeploy_deployment_group_name}" ])
                  ApplicationName Ref("#{codedeploy_application_name}CodeDeployApplication")
                  AutoScalingGroups deployment_group['autoScalingGroups']
                  DeploymentConfigName "#{codedeploy_deployment_config_name}"
                  ServiceRoleArn FnGetAtt('CodeDeployRole','Arn')
                  AutoRollbackConfiguration rollbackConfig
              end
          end

      end if application.key?('deployment_groups')

  end if defined? applications

end