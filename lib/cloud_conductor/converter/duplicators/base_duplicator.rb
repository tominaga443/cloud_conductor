# -*- coding: utf-8 -*-
# Copyright 2014 TIS Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
module CloudConductor
  class Converter
    module Duplicators
      class BaseDuplicator # rubocop:disable ClassLength
        COPYABLE_RESOURCES = [
          'AWS::EC2::Instance',
          'AWS::EC2::NetworkInterface',
          'AWS::EC2::Subnet',
          'AWS::EC2::SubnetRouteTableAssociation',
          'AWS::EC2::EIP',
          'AWS::EC2::EIPAssociation',
          'AWS::EC2::Volume',
          'AWS::EC2::VolumeAttachment',
          'AWS::CloudFormation::WaitConditionHandle',
          'AWS::CloudFormation::WaitCondition'
        ]

        def initialize(resources, options)
          @resources = resources
          @options = options
        end

        def replace_properties(resource)
          resource
        end

        # copied_resource_mapping_table = { original_name: copy_name, ... }
        def copy(source_name, copied_resource_mapping_table = {}, options = {})
          return { source_name => @resources[source_name] } if already_copied? source_name, copied_resource_mapping_table

          copy_name = "#{source_name}#{@options[:CopyNum]}"
          copied_resource_mapping_table[source_name] = copy_name

          copied_resource = @resources[source_name].deep_dup
          roles = @options[:Role].split(',') + ['all']
          contain_resources = @resources.select(&contain?(source_name))
          associated_resources = collect_resources_associated_with(copied_resource).merge contain_resources

          associated_resources.each do |resource_name, resource|
            next unless roles.any? { |role| resource_name.upcase.starts_with? role.upcase }
            duplicator = create_duplicator(resource['Type'])
            if duplicator.copyable?(resource)
              copied_associated_resource = duplicator.copy(resource_name, copied_resource_mapping_table, options)
              @resources.merge! copied_associated_resource
            end
          end

          { copy_name => post_copy(copied_resource_mapping_table, copied_resource) }
        end

        def copyable?(resource)
          COPYABLE_RESOURCES.include? resource['Type']
        end

        private

        def already_copied?(source_name, copied_resource_mapping_table)
          return true if copied_resource_mapping_table.keys.include? source_name
          return true if copied_resource_mapping_table.values.include? source_name
          return true if @resources[source_name]['Metadata'] && @resources[source_name]['Metadata']['Copied']
          false
        end

        def add_copied_flag(resource)
          resource['Metadata'] = {} unless resource['Metadata']
          resource['Metadata']['Copied'] = true

          resource
        end

        def post_copy(copied_resource_mapping_table, resource)
          resource = replace_associated_resources(resource, copied_resource_mapping_table)
          resource = replace_properties(resource)
          resource = add_copied_flag(resource)
          resource
        end

        def create_duplicator(resource_type)
          duplicator_name = "#{resource_type.split('::').last}Duplicator"
          duplicator_name = 'BaseDuplicator' unless Duplicators.const_defined? duplicator_name
          Duplicators.const_get(duplicator_name).new(@resources, @options)
        end

        # rubocop:disable CyclomaticComplexity, PerceivedComplexity
        def contain_name_in_element?(source_name, element)
          return false unless element.respond_to?(:each)

          if element.is_a?(Hash)
            return true if source_name == element[:Ref]
            return true if element[:'Fn::GetAtt'] && source_name == element[:'Fn::GetAtt'].first
            return true if element[:DependsOn] && element[:DependsOn].include?(source_name)
          end

          element = element.values if element.respond_to?(:values)
          element.any? do |child_element|
            contain_name_in_element?(source_name, child_element)
          end
        end
        # rubocop:enable CyclomaticComplexity, PerceivedComplexity

        def contain?(source_name)
          ->(_, resource) { contain_name_in_element?(source_name, resource) }
        end

        def collect_names_associated_with(element)
          return [] unless element.respond_to?(:each)

          names = element.inject([]) do |s, child_element|
            s + collect_names_associated_with(child_element)
          end

          if element.is_a?(Hash)
            names << element['Ref'] if element.keys.first == 'Ref'
            names << element['Fn::GetAtt'].first if element.keys.first == 'Fn::GetAtt'
            names << element['DependsOn'] if element.keys.include?('DependsOn')
          end
          names.flatten
        end

        def collect_resources_associated_with(resource)
          @resources.slice(*collect_names_associated_with(resource).flatten.uniq)
        end

        def replace_ref(original_name, copy_name, element)
          return unless element.respond_to?(:each)

          element['Ref'] = copy_name if element.is_a?(Hash) && element['Ref'] == original_name

          element = element.values if element.respond_to?(:values)
          element.each do |child_element|
            replace_ref(original_name, copy_name, child_element)
          end
        end

        # rubocop:disable CyclomaticComplexity
        def replace_get_att(original_name, copy_name, element)
          return unless element.respond_to?(:each)

          if element.is_a?(Hash) && element['Fn::GetAtt']
            new_get_att = element['Fn::GetAtt'].map do |get_att|
              (get_att == original_name && copy_name) || get_att
            end
            element['Fn::GetAtt'] = new_get_att
            return
          end

          element = element.values if element.respond_to?(:values)
          element.each do |child_element|
            replace_get_att(original_name, copy_name, child_element)
          end
        end
        # rubocop:enable CyclomaticComplexity

        def replace_depends_on(original_name, copy_name, element)
          depends = element['DependsOn']

          return unless depends

          if depends.is_a? String
            element['DependsOn'] = copy_name if depends == original_name
            return
          end

          new_depends = depends.map do |depend|
            (depend == original_name && copy_name) || depend
          end
          element['DependsOn'] = new_depends
        end

        def replace_associated_resources(resource, copied_resource_mapping_table)
          copied_resource_mapping_table.each do |original_name, copy_name|
            replace_ref(original_name, copy_name, resource)
            replace_get_att(original_name, copy_name, resource)
            replace_depends_on(original_name, copy_name, resource)
          end

          resource
        end
      end
    end
  end
end
