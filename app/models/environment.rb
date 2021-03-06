require 'open-uri'

class Environment < ActiveRecord::Base # rubocop:disable ClassLength
  belongs_to :system
  belongs_to :blueprint
  has_many :candidates, dependent: :destroy, inverse_of: :environment
  has_many :clouds, through: :candidates
  has_many :stacks, validate: false
  has_many :deployments, dependent: :destroy, inverse_of: :environment
  has_many :application_histories, through: :deployments
  accepts_nested_attributes_for :candidates

  attr_accessor :template_parameters, :user_attributes

  validates_presence_of :system, :blueprint, :candidates
  validates :name, presence: true, uniqueness: true
  validate do
    clouds = candidates.map(&:cloud)
    errors.add(:clouds, 'can\'t contain duplicate cloud in clouds attribute') unless clouds.size == clouds.uniq.size
  end
  validate do
    errors.add(:blueprint, 'status does not create_complete') unless blueprint.status == :CREATE_COMPLETE
  end

  before_save :create_or_update_stacks, if: -> { status == :PENDING }
  before_destroy do
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        destroy_stacks
      end
    end
  end

  after_initialize do
    self.template_parameters ||= '{}'
    self.user_attributes ||= '{}'
    self.platform_outputs ||= '{}'
    self.status ||= :PENDING
  end

  def create_or_update_stacks
    if (new_record? || blueprint_id_changed?) && stacks.empty?
      create_stacks
    elsif template_parameters != '{}' || user_attributes != '{}'
      update_stacks
    end
  end

  def create_stacks
    primary_cloud = candidates.sort.first.cloud
    cfn_parameters_hash = JSON.parse(template_parameters)
    user_attributes_hash = JSON.parse(user_attributes)
    blueprint.patterns.each do |pattern|
      stacks.build(
        cloud: primary_cloud,
        pattern: pattern,
        name: "#{system.name}-#{id}-#{pattern.name}",
        template_parameters: cfn_parameters_hash.key?(pattern.name) ? JSON.dump(cfn_parameters_hash[pattern.name]) : '{}',
        parameters: user_attributes_hash.key?(pattern.name) ? JSON.dump(user_attributes_hash[pattern.name]) : '{}'
      )
    end
  end

  def update_stacks
    cfn_parameters_hash = JSON.parse(template_parameters)
    user_attributes_hash = JSON.parse(user_attributes)
    stacks.each do |stack|
      if cfn_parameters_hash.key?(stack.pattern.name)
        new_template_parameters = JSON.dump(cfn_parameters_hash[stack.pattern.name])
      else
        new_template_parameters = '{}'
      end
      if user_attributes_hash.key?(stack.pattern.name)
        new_user_attributes = JSON.dump(user_attributes_hash[stack.pattern.name])
      else
        new_user_attributes = '{}'
      end
      stack.update!(template_parameters: new_template_parameters, parameters: new_user_attributes, status: :PENDING)
    end
  end

  def status
    super && super.to_sym
  end

  def application_status
    if latest_deployments.empty?
      :NOT_DEPLOYED
    elsif latest_deployments.any? { |deployment| deployment.status == 'ERROR' }
      :ERROR
    elsif latest_deployments.any? { |deployment| deployment.status == 'PROGRESS' }
      :PROGRESS
    elsif latest_deployments.all? { |deployment| deployment.status == 'DEPLOY_COMPLETE' }
      :DEPLOY_COMPLETE
    else
      :ERROR
    end
  end

  def basename
    name.sub(/-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, '')
  end

  def as_json(options = {})
    super({ methods: [:status, :application_status], except: :platform_outputs }.merge(options))
  end

  def dup
    environment = super

    basename = name.sub(/-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, '')
    environment.name = "#{basename}-#{SecureRandom.uuid}"
    environment.ip_address = nil
    environment.platform_outputs = '{}'
    environment.status = :PENDING

    environment.candidates = candidates.map(&:dup)
    environment.stacks = stacks.map(&:dup)
    environment.deployments = deployments.map(&:dup)

    environment
  end

  def consul
    fail 'ip_address does not specified' unless ip_address

    options = CloudConductor::Config.consul.options.save.merge(token: blueprint.consul_secret_key)
    Consul::Client.new(ip_address, CloudConductor::Config.consul.port, options)
  end

  def event
    fail 'ip_address does not specified' unless ip_address

    options = CloudConductor::Config.consul.options.save.merge(token: blueprint.consul_secret_key)
    CloudConductor::Event.new(ip_address, CloudConductor::Config.consul.port, options)
  end

  TIMEOUT = 1800
  def destroy_stacks
    return if stacks.empty?
    platforms = stacks.select(&:platform?)
    optionals = stacks.select(&:optional?)
    stacks.delete_all

    begin
      optionals.each(&:destroy)
      Timeout.timeout(TIMEOUT) do
        sleep 10 until optionals.all?(&stack_destroyed?)
      end
    rescue Timeout::Error
      Log.warn "Exceeded timeout while destroying stacks #{optionals}"
    ensure
      platforms.each(&:destroy)
    end
  end

  def latest_deployments
    deployments_each_application = deployments.group_by { |deployment| deployment.application_history.application_id }.values
    deployments_each_application.map do |deployments|
      deployments.sort_by(&:updated_at).last
    end
  end

  private

  def stack_destroyed?
    lambda do |stack|
      return true unless stack.exist?
      [:DELETE_COMPLETE, :DELETE_FAILED].include? stack.cloud.client.get_stack_status(stack.name)
    end
  end
end
