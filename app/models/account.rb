class Account < ActiveRecord::Base
  
  has_many :personas, :dependent => :destroy, :order => 'id ASC'
  has_many :sites, :dependent => :destroy

  validates_presence_of :login
  validates_length_of :login, :within => 3..40
  validates_uniqueness_of :login, :case_sensitive => false
  validates_format_of :login, :with => /^[A-Za-z0-9_-]+$/
  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false
  validates_format_of :email, :with => /(^([^@\s]+)@((?:[-_a-z0-9]+\.)+[a-z]{2,})$)|(^$)/i
  validates_presence_of :password, :if => :password_required?
  validates_presence_of :password_confirmation, :if => :password_required?
  validates_length_of :password, :within => 6..40, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?
  
  before_save   :encrypt_password
  
  attr_accessible :login, :email, :password, :password_confirmation
  attr_accessor :password
  attr_writer :recently_created
  
  def to_param
    login
  end
  
  def recently_created?
    @recently_created
  end
  
  # Authenticates a user by their login name and password.
  # Returns the user or nil.
  def self.authenticate(login, password)
    if a = find(:first, :conditions => ['login = ? and enabled = ?', login, true]) # need to get the salt
      if a.authenticated?(password)
        a.last_authenticated_at = Time.now
        a.save(false)
        a
      end
    end
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end
  
  def authenticated?(password)
    encrypt(password) == crypted_password
  end
  
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token = nil
    save(false)
  end

  def forgot_password!
    @forgotten_password = true
    self.make_password_reset_code
    self.save
  end
  
  # First update the password_reset_code before setting the
  # reset_password flag to avoid duplicate email notifications.
  def reset_password
    update_attribute(:password_reset_code, nil)
    @reset_password = true
  end  
  
  def recently_forgot_password?
    @forgotten_password
  end

  def recently_reset_password?
    @reset_password
  end
  
  def disable!
    update_attribute(:enabled, false)
  end
  
  protected
  
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
    
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  def make_password_reset_code
    self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
end
