class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :authentication_keys => [:login]

  devise :omniauthable, :omniauth_providers => [:facebook, :github, :vkontakte, :twitter]

   # Virtual attribute for authenticating by either username or email
   # This is in addition to a real persisted field like 'username'
   attr_accessor :login

   def self.find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions.to_hash).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
      elsif conditions.has_key?(:username) || conditions.has_key?(:email)
        where(conditions.to_hash).first
      end
    end

    validate :validate_username

    def validate_username
      if User.where(email: username).exists?
        errors.add(:username, :invalid)
      end
    end

    def self.from_omniauth(auth)
      if User.where(email: auth.info.email).exists?
        user = User.where(email: auth.info.email).first
        user.provider = auth.provider
        user.uid = auth.uid
        user.password = Devise.friendly_token[0,20]
        user.name = auth.info.name  # assuming the user model has a name
        user.image = auth.info.image # assuming the user model has an image
        return user
      else
        User.where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
          user.email = auth.info.email
          user.password = Devise.friendly_token[0,20]
          user.name = auth.info.name  # assuming the user model has a name
          user.image = auth.info.image # assuming the user model has an image
        end
      end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

end
