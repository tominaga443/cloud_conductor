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
  module Patches
    class AddNetworkInterface < Patch
      include PatchUtils

      def initialize
      end

      def ensure(template, _parameters)
        template[:Resources] ||= {}
        template
      end

      def apply(template, _parameters)
        template = template.deep_dup

        security_group = template[:Resources].select(&type?('AWS::EC2::SecurityGroup'))
        subnet = template[:Resources].select(&type?('AWS::EC2::Subnet'))

        fail 'Subnet was not found' if subnet.empty?

        network_interface = JSON.parse <<-EOS
          {
            "NIC" : {
              "Type" : "AWS::EC2::NetworkInterface",
              "Properties" : {
                "SubnetId" : { "Ref" : "#{ subnet.keys[0] }" }
              }
            }
          }
        EOS
        network_interface = network_interface.with_indifferent_access

        unless security_group.empty?
          network_interface[:NIC][:Properties][:GroupSet] = [{ Ref: security_group.keys[0] }]
        end

        template[:Resources].update network_interface

        template
      end
    end
  end
end
