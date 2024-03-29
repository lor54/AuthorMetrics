require 'open-uri'
require 'tempfile'

class User < ApplicationRecord
  has_many :follows, class_name: 'Follow', foreign_key: 'user'
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :omniauthable, omniauth_providers: [:google_oauth2]

  has_one_attached :avatar
  after_commit :add_default_avatar, on: %i[create update]

  def avatar_thumbnail
    if avatar.attached?
      avatar.variant(resize_to_fill: [200, nil]).processed
    else
      "/default_profile.jpg"
    end
  end

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data['email']).first
  
    # Uncomment the section below if you want users to be created if they don't exist
    unless user
      user = User.create(
        name: data['name'],
        email: data['email'],
        password: Devise.friendly_token[0, 20],
        provider: access_token.provider,
        uid: access_token.uid
      )
  
      # Scarica l'immagine dall'URL e la salva come file temporaneo
      tempfile = Tempfile.new(['avatar', '.jpg'])
      tempfile.binmode
      tempfile.write URI.open(data['image']).read
      tempfile.rewind
  
      # Aggiungi l'immagine dell'avatar all'allegato 'avatar'
      user.avatar.attach(io: tempfile, filename: 'avatar.jpg')
  
      # Chiudi e rimuovi il file temporaneo
      tempfile.close
      tempfile.unlink
    end
    user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.google_data"] && session["devise.google_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  private

  def add_default_avatar
    unless avatar.attached?
      avatar.attach(
        io: File.open(
          Rails.root.join(
            'app', 'assets', 'images', 'default_profile.jpg'
          )
        ), filename: 'default_profile.jpg',
        content_type: 'image/jpg'
      )
    end
  end

end
