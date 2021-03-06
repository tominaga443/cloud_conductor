CHANGELOG
=========

## version 1.0.2 (2015/05/14)

  - Fix the vulnerability of OS command injection.
  - Change type of columns, which are expected to input long sentence, from string to text.
  - Move log_level setting from config/config.rb to config/environments/[environment].rb.
  - Move application domain column from application_histories to applications.
  - Remove unnecessary API.
  - Add error log of CloudFormation/Heat.
  - Add packer log.
  - Add packer settings to specify instance_type/flavor_name.
  - Delete snapshot when deregister image.

## version 1.0.1 (2015/04/16)

  - Use same salt on rebuilded environment.
  - Move event log nodes to under event nodes in consul key-value store to simplify event nodes structure.
  - Use PostgreSQL instead of SQLite3.

## version 1.0.0 (2015/03/27)

  - DB schema has been redesigned. This is not compatible with previous versions. Please build a new environment.
  - Add authentication and authorization features.
  - Support encrypted path to communicate CloudConductor and builded environment.
  - Scale-out feature is now available as limited to the part of the pattern.
  - Migrate from Sinatra to Rails.

## version 0.3.5 (2015/03/16)

  - Update AMI images to latest base image.

## version 0.3.4 (2015/03/02)

  - Fix version of fog gem to 1.27.x.
  - Fix version of aws-sdk gem to 1.x.

## version 0.3.2 (2014/12/24)

  - Switch from zabbixapi to red-tux/zbxapi to support any versions of Zabbix.
  - Reduce unnecessary logs.
  - Remove chef_status from response of system list to improve latency.
  - Remove computed parameter from response of `/systems/:id/parameters`.
  - Remove composite primary key on candidates table.
  - Ensure to remove temporary files.
  - Brush up patches that is contained in OpenStack converter.
  - Modify name of images that created on AWS or OpenStack.
  - Fill base ami-id when create patterns automatically.
  - Improve speed of specs on System model.
  - Extract converter to cloudconductor/cfn-converter gem.
  - Destroy stacks in order that prefer optional pattern to platform pattern.
  - Use rspec3 instead of rspec2 when execute specs.
  - Allow hyphen character in name of cloud.
  - Rename table name from targets to base_images.

## version 0.3.0 (2014/10/31)

  - Redesigned of system provisioning architecture over patterns
  - Coordinate with external DNS services
  - Coordinate with external monitoring system

## version 0.2.2 (2014/05/22)

  - Fix markup for code block in README.md

## version 0.2.1 (2014/04/21)

  - Add environment variables CONDUCTOR_ROOT and CORE_PORT to specify unicorn working directory and listen port
  - Fix github repository url
  - Fix volume attach and format process
  - Fix SSH error handling and application deploy process
  - Fix script shebang
  - Modify rake task in order to support ActiveRecord 4.1.0
  - Support Rubocop 0.20.1 and refactor code
  - Stabilize gem package version

## version 0.2.0 (2014/03/25)

  - First release of CloudConductor which realize hybrid cloud management and automated deployment.

