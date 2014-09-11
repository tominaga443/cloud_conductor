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
    sequence(:name) { |n| "stack-#{n}" }
    template_parameters '{}'
    parameters '{}'
    pattern { create(:pattern) }

    after(:build) do
      System.skip_callback :save, :before, :create_stack
      System.skip_callback :save, :before, :enable_monitoring
      System.skip_callback :save, :before, :update_dns
    end

    after(:create) do
      System.set_callback :save, :before, :create_stack, if: -> { status == :NOT_CREATED }
      System.set_callback :save, :before, :enable_monitoring, if: -> { monitoring_host_changed? }
      System.set_callback :save, :before, :update_dns, if: -> { ip_address }
    end

    before(:create) do |system|
      system.add_cloud create(:cloud_aws), 1
    end
  end
end
