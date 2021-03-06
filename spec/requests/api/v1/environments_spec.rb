describe API do
  include ApiSpecHelper
  include_context 'default_api_settings'

  describe 'EnvironmentAPI' do
    before { environment }

    describe 'GET /environments' do
      let(:method) { 'get' }
      let(:url) { '/api/v1/environments' }
      let(:result) { format_iso8601([environment]) }

      context 'not_logged_in' do
        it_behaves_like('401 Unauthorized')
      end

      context 'normal_account', normal: true do
        it_behaves_like('403 Forbidden')
      end

      context 'administrator', admin: true do
        it_behaves_like('200 OK')
      end

      context 'project_owner', project_owner: true do
        it_behaves_like('200 OK')
      end

      context 'project_operator', project_operator: true do
        it_behaves_like('200 OK')
      end
    end

    describe 'GET /environments/:id' do
      let(:method) { 'get' }
      let(:url) { "/api/v1/environments/#{environment.id}" }
      let(:result) { format_iso8601(environment) }

      context 'not_logged_in' do
        it_behaves_like('401 Unauthorized')
      end

      context 'normal_account', normal: true do
        it_behaves_like('403 Forbidden')
      end

      context 'administrator', admin: true do
        it_behaves_like('200 OK')
      end

      context 'project_owner', project_owner: true do
        it_behaves_like('200 OK')
      end

      context 'project_operator', project_operator: true do
        it_behaves_like('200 OK')
      end
    end

    describe 'POST /environments' do
      let(:method) { 'post' }
      let(:url) { '/api/v1/environments' }
      let(:params) do
        FactoryGirl.attributes_for(:environment,
                                   system_id: system.id,
                                   blueprint_id: blueprint.id,
                                   candidates_attributes: [{
                                     cloud_id: cloud.id,
                                     priority: 10
                                   }],
                                   stacks_attributes: [{
                                     name: 'test',
                                     template_parameters: '{}',
                                     parameters: '{}'
                                   }]
        )
      end
      let(:result) do
        params.except(:candidates_attributes, :stacks_attributes, :platform_outputs).merge(
          id: Fixnum,
          created_at: String,
          updated_at: String,
          status: 'PENDING',
          application_status: 'NOT_DEPLOYED',
          ip_address: nil
        )
      end

      before do
        allow_any_instance_of(Environment).to receive(:create_stacks).and_return(true)
      end

      context 'not_logged_in' do
        it_behaves_like('401 Unauthorized')
      end

      context 'normal_account', normal: true do
        it_behaves_like('403 Forbidden')
      end

      context 'administrator', admin: true do
        it_behaves_like('202 Accepted')
      end

      context 'project_owner', project_owner: true do
        it_behaves_like('202 Accepted')
      end

      context 'project_operator', project_operator: true do
        it_behaves_like('202 Accepted')
      end
    end

    describe 'PUT /environments/:id' do
      let(:method) { 'put' }
      let(:url) { "/api/v1/environments/#{environment.id}" }
      let(:params) do
        {
          'name' => 'new_name',
          'description' => 'new_description'
        }
      end
      let(:result) do
        environment.as_json.merge(params).merge(
          'created_at' => environment.created_at.iso8601(3),
          'updated_at' => String
        )
      end

      before do
        allow_any_instance_of(Environment).to receive(:create_stacks).and_return(true)
      end

      context 'not_logged_in' do
        it_behaves_like('401 Unauthorized')
      end

      context 'normal_account', normal: true do
        it_behaves_like('403 Forbidden')
      end

      context 'administrator', admin: true do
        it_behaves_like('200 OK')
      end

      context 'project_owner', project_owner: true do
        it_behaves_like('200 OK')
      end

      context 'project_operator', project_operator: true do
        it_behaves_like('200 OK')
      end
    end

    describe 'DELETE /environments/:id' do
      let(:method) { 'delete' }
      let(:url) { "/api/v1/environments/#{new_environment.id}" }
      let(:new_environment) { FactoryGirl.create(:environment, system: system, blueprint: blueprint, candidates_attributes: [{ cloud_id: cloud.id, priority: 10 }]) }

      before do
        allow_any_instance_of(Environment).to receive(:destroy_stacks).and_return(true)
      end

      context 'not_logged_in' do
        it_behaves_like('401 Unauthorized')
      end

      context 'normal_account', normal: true do
        it_behaves_like('403 Forbidden')
      end

      context 'administrator', admin: true do
        it_behaves_like('204 No Content')
      end

      context 'project_owner', project_owner: true do
        it_behaves_like('204 No Content')
      end

      context 'project_operator', project_operator: true do
        it_behaves_like('204 No Content')
      end
    end

    describe 'POST /environments/:id/rebuild' do
      let(:method) { 'post' }
      let(:url) { "/api/v1/environments/#{environment.id}/rebuild" }
      let(:params) do
        {
          'blueprint_id' => blueprint.id,
          'description' => 'new_description',
          'switch' => true
        }
      end
      let(:result) do
        environment.as_json.merge(params.except('switch')).merge(
          'id' => Fixnum,
          'created_at' => String,
          'updated_at' => String,
          'name' => /#{environment.name}-*/,
          'ip_address' => nil
        )
      end

      before do
        allow_any_instance_of(Environment).to receive(:create_stacks).and_return(true)
      end

      context 'not_logged_in' do
        it_behaves_like('401 Unauthorized')
      end

      context 'normal_account', normal: true do
        it_behaves_like('403 Forbidden')
      end

      context 'administrator', admin: true do
        it_behaves_like('202 Accepted')
      end

      context 'project_owner', project_owner: true do
        it_behaves_like('202 Accepted')
      end

      context 'project_operator', project_operator: true do
        it_behaves_like('202 Accepted')
      end
    end
  end
end
