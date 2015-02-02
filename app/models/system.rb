class System < ActiveRecord::Base
  belongs_to :project
  has_many :applications, dependent: :destroy
  has_many :environments, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
