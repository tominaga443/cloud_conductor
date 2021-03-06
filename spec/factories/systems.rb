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
FactoryGirl.define do
  factory :system, class: System do
    project
    sequence(:name) { |n| "system-#{n}" }
    domain 'example.com'
    description 'sample system'
    primary_environment_id nil

    before(:create) do
      System.skip_callback :save, :before, :update_dns
      System.skip_callback :save, :before, :enable_monitoring
    end

    after(:create) do
      System.set_callback :save, :before, :update_dns, if: -> { primary_environment && domain }
      System.set_callback :save, :before, :enable_monitoring, if: -> { primary_environment && domain && CloudConductor::Config.zabbix.enabled }
    end
  end
end
