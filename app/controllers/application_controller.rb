# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ApplicationControllerMethods
  include ActionView::Helpers::SanitizeHelper

  before_action :handle_two_factor_authentication,
                if: proc {
                  (defined? current_user &&
                            current_user&.totp_enabled?)
                }, except: %i[record_not_found logo favicon]
  before_action :check_sso_redirection
  before_action :authenticate_user!, unless: :devise_controller?,
                                     except: %i[record_not_found logo favicon]
  

  def generate_code
    self.code = gen_code
  end

  private

  def check_if_exits(hash_code)
    User.find_by(secure_hex: hash_code).nil?
  end

  def gen_code
    generated_code = SecureRandom.hex(5)
    hash_code = Digest::MD5.hexdigest generated_code
    gen_code unless check_if_exits(hash_code)
    hash_code
  end  
end
