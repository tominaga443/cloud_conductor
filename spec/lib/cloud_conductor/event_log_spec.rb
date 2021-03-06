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
  describe EventLog do
    before do
      response = {
        'event/4ee5d2a6-853a-21a9-7463-ef1866468b76/host1' => {
          'event_id' => '4ee5d2a6-853a-21a9-7463-ef1866468b76',
          'type' => 'configure',
          'return_code' => '0',
          'started_at' => '2014-12-16T14:44:07+0900',
          'finished_at' => '2014-12-16T14:44:09+0900'
        },
        'event/4ee5d2a6-853a-21a9-7463-ef1866468b76/host2' => {
          'event_id' => '4ee5d2a6-853a-21a9-7463-ef1866468b76',
          'type' => 'configure',
          'return_code' => '0',
          'started_at' => '2014-12-16T14:44:07+0900',
          'finished_at' => '2014-12-16T14:44:09+0900'
        },
        'event/4ee5d2a6-853a-21a9-7463-ef1866468b76/host1/log' => 'Dummy consul event log1',
        'event/4ee5d2a6-853a-21a9-7463-ef1866468b76/host2/log' => 'Dummy consul event log2'
      }

      @event_log = EventLog.new(response)
    end

    describe '#id' do
      it 'return event id that is contained result' do
        expect(@event_log.id).to eq('4ee5d2a6-853a-21a9-7463-ef1866468b76')
      end
    end

    describe '#name' do
      it 'return event name that is contained result' do
        expect(@event_log.name).to eq('configure')
      end
    end

    describe '#nodes' do
      it 'return nodes that contain result of each host' do
        nodes = @event_log.nodes
        expect(nodes).to be_is_a(Array)
        expect(nodes.size).to eq(2)
        expect(nodes.first).to eq(
          hostname: 'host1',
          return_code: 0,
          started_at: DateTime.new(2014, 12, 16, 14, 44, 7, 'JST'),
          finished_at: DateTime.new(2014, 12, 16, 14, 44, 9, 'JST'),
          log: 'Dummy consul event log1'
        )
      end
    end

    describe 'finished?' do
      it 'return true if event on all hosts are finished' do
        expect(@event_log.finished?).to be_truthy
      end

      it 'return false if any event has not been finished' do
        @event_log.nodes.first[:return_code] = nil

        expect(@event_log.finished?).to be_falsey
      end
    end

    describe 'success?' do
      it 'return true if event on all hosts are succeeded' do
        expect(@event_log.success?).to be_truthy
      end

      it 'return false if any event has not been finished' do
        @event_log.nodes.first[:return_code] = nil

        expect(@event_log.success?).to be_falsey
      end

      it 'return false if any event has occurred error' do
        @event_log.nodes.first[:return_code] = 1

        expect(@event_log.success?).to be_falsey
      end
    end

    describe '#as_json' do
      it 'return Hash that contains aggregated event' do
        result = @event_log.as_json(detail: true)
        expect(result).to be_is_a(Hash)
        expect(result.keys).to eq(%i(id type finished succeeded results))
        expect(result[:id]).to eq('4ee5d2a6-853a-21a9-7463-ef1866468b76')
        expect(result[:type]).to eq('configure')
        expect(result[:succeeded]).to be_truthy
        expect(result[:finished]).to be_truthy
      end

      it 'doesn\'t contains individual result when detail is false' do
        result = @event_log.as_json(detail: false)
        expect(result[:results]).to be_nil
      end

      it 'contains individual result when detail is true' do
        result = @event_log.as_json(detail: true)
        expect(result[:results]).to be_is_a(Array)
        expect(result[:results].size).to eq(2)

        expect(result[:results][0]).to be_is_a(Hash)
        expect(result[:results][0][:hostname]).to eq('host1')
        expect(result[:results][0][:return_code]).to eq(0)
        expect(result[:results][0][:started_at]).to eq('2014-12-16T14:44:07.000+09:00')
        expect(result[:results][0][:finished_at]).to eq('2014-12-16T14:44:09.000+09:00')
        expect(result[:results][0][:log]).to eq('Dummy consul event log1')
      end
    end
  end
end
