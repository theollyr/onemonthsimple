require 'encryption'

class User < ActiveRecord::Base
  PASSWORD_FORMAT = /\A
    (?=.{6,})          # Must contain 6 or more characters
    (?=.*\d)           # Must contain a digit
    (?=.*[a-z])        # Must contain a lower case character
    (?=.*[A-Z])        # Must contain an upper case character
    (?=.*[[:^alnum:]]) # Must contain a symbol
  /x

  attr_accessible :email, :first_name, :last_name, :user_id, :password, :password_confirmation
  validates :password, :presence => true,
                       :confirmation => true,
                       :length => {:within => 6..40},
                       :on => :create,
                       :if => :password,
                       :format => { with: PASSWORD_FORMAT }

  validates_presence_of :email
  validates_uniqueness_of :email
  validates_format_of :email, :with => /.+@.+\..+/i
  attr_accessor :skip_user_id_assign
  attr_accessor :skip_hash_password
  before_save :assign_user_id, :on => :create
  before_save :hash_password
  has_one :retirement, :foreign_key => :user_id, :primary_key => :user_id, :dependent => :destroy
  has_one :paid_time_off, :foreign_key => :user_id, :primary_key => :user_id, :dependent => :destroy
  has_one :work_info, :foreign_key => :user_id, :primary_key => :user_id, :dependent => :destroy
  has_many :performance, :foreign_key => :user_id, :primary_key => :user_id, :dependent => :destroy
  has_many :messages, :foreign_key => :receiver_id, :primary_key => :user_id, :dependent => :destroy
  has_many :pay, :foreign_key => :user_id, :primary_key => :user_id, :dependent => :destroy
  before_create { generate_token(:auth_token) }

  def build_benefits_data
    build_retirement(POPULATE_RETIREMENTS.shuffle.first)
    build_paid_time_off(POPULATE_PAID_TIME_OFF.shuffle.first).schedule.build(POPULATE_SCHEDULE.shuffle.first)
    build_work_info(POPULATE_WORK_INFO.shuffle.first)
    work_info.build_key_management(:iv => SecureRandom.hex(32))
    performance.build(POPULATE_PERFORMANCE.shuffle.first)
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  private

  def self.authenticate(email, password)
    auth = nil
    user = find_by_email(email)
    if user && user.password == BCrypt::Engine.hash_secret(password, user.password_salt)
      auth = user
    else
      raise "Incorrect Username or Password!"
    end
    return auth
  end

  def assign_user_id
    unless @skip_user_id_assign.present? || self.user_id.present?
      user = User.order("user_id").last
      uid = user.user_id.to_i + 1 if user && user.user_id && !(User.exists?(:user_id => "#{user.user_id.to_i + 1}"))
      self.user_id = uid.to_s if uid
    end
  end

  def hash_password
    unless @skip_hash_password == true
      if password.present?
        self.password_salt = BCrypt::Engine.generate_salt
        self.password = BCrypt::Engine.hash_secret(self.password, self.password_salt)
      end
    end
  end

  def generate_token(column)
    begin
      self[column] = Encryption.encrypt_sensitive_value(self.user_id)
    end while User.exists?(column => self[column])
  end
end
