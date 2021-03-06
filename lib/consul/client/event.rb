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
module Consul
  class Client
    class Event
      def initialize(faraday)
        @faraday = faraday
      end

      def fire(name, payload = nil, filter = {})
        @faraday.params[:node] = filter[:node].join('|') if filter[:node]
        @faraday.params[:service] = filter[:service].join('|') if filter[:service]
        @faraday.params[:tag] = filter[:tag].join('|') if filter[:tag]

        response = @faraday.put("event/fire/#{name}", payload)
        return nil unless response.success?

        JSON.parse(response.body)['ID']
      end
    end
  end
end
