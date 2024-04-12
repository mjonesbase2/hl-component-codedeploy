CfhighlanderTemplate do
  Name 'codedeploy'
  Description "codedeploy - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true
    ComponentParam 'AutoscalingGroup'
  end


end