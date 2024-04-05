Resources:
  EventBridgeRule:
    Type: AWS::Events::Rule
    Properties:
      Name: ${name}
      Description: Capture all CloudTrail events
      EventPattern: ${event_pattern}
      State: ${rule_state}
      Targets:
        - Id: ${name}
          Arn: ${target_event_bus_arn}
          RoleArn: !Sub "arn:aws:iam::$${AWS::AccountId}:role/${name}"
