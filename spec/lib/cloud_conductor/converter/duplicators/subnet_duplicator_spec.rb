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
      describe SubnetDuplicator do
        before do
          @resource = {
            'Subnet1' => {
              'Type' => 'AWS::EC2::Subnet',
              'Properties' => {
                'AvailabilityZone' => 'ap-southeast-2a',
                'CidrBlock' => '10.0.1.0/24',
                'VpcId' => { 'Ref' => 'VPC' }
              }
            }
          }
          @options = {
            AvailabilityZone: ['ap-southeast-2a', 'ap-southeast-2b'],
            CopyNum: 2
          }
          @subnet_duplicator = SubnetDuplicator.new(@resource.with_indifferent_access, @options)
        end

        describe '#replace_properties' do
          it 'return template to updated for AvailabilityZone property and CidrBlock property' do
            resource = @resource.deep_dup

            expect(resource['Subnet1']['Properties']['AvailabilityZone']).to eq('ap-southeast-2a')
            expect(resource['Subnet1']['Properties']['CidrBlock']).to eq('10.0.1.0/24')

            @subnet_duplicator.replace_properties(resource.values.first)

            expect(resource['Subnet1']['Properties']['AvailabilityZone']).to eq('ap-southeast-2b')
            expect(resource['Subnet1']['Properties']['CidrBlock']).to eq('10.0.2.0/24')
          end
        end

        describe '#copy' do
          before do
            @copied_resource_mapping_table = {
              'old_dummy_name' => 'new_old_name'
            }
          end

          it 'call BaseDuplicator#copy method if Subnet can copy' do
            allow_any_instance_of(BaseDuplicator).to receive(:copy)

            expect(@subnet_duplicator.copy('dummy_name', @copied_resource_mapping_table, {}))
          end

          it 'do not do anything if Subnet have already been copied' do
            expect(@subnet_duplicator.copy('old_dummy_name', @copied_resource_mapping_table, {})).to eq('old_dummy_name' => nil)
          end

          it 'update copied_resource_mapping_table' do
            resources = {
              'Subnet1' => {
                'Type' => 'AWS::EC2::Subnet',
                'Properties' => {
                  'AvailabilityZone' => 'ap-southeast-2a',
                  'CidrBlock' => '10.0.1.0/24',
                  'VpcId' => { 'Ref' => 'VPC' }
                }
              },
              'Subnet2' => {
                'Type' => 'AWS::EC2::Subnet',
                'Properties' => {
                  'AvailabilityZone' => 'ap-southeast-2b',
                  'CidrBlock' => '10.0.2.0/24',
                  'VpcId' => { 'Ref' => 'VPC' }
                }
              }
            }

            subnet_duplicator = SubnetDuplicator.new(resources.with_indifferent_access, @options)

            copied_resource_mapping_table = {}

            subnet_duplicator.copy('Subnet1', copied_resource_mapping_table, {})
            expect(copied_resource_mapping_table['Subnet1']).to eq('Subnet2')
          end
        end
      end
    end
  end
end
