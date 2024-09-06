class ApplicationController < ActionController::Base
  around_action :switch_locale
  before_action :set_app_name
  before_action :set_meta_tags
  attr_accessor :app_name

  def set_app_name
    @app_name = 'Shoe Sensei'
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(User)
      admin_url
    else
      raise 'Attempted log in s not of type User'
    end
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    if locale == 'admin'
      redirect_to admin_path
      return
    end
    I18n.with_locale(locale, &action)

    # Infer user local if explicit local not provided
    # logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
    # locale = extract_locale_from_accepted_language_header
    # logger.debug  "* Locale set to #{locale}"
    # I18n.with_locale(locale, &action)
  end

  def set_meta_tags
    @meta_tags = {
      title: @app_name,
      description: I18n.t('site_default_description'),
      google_tag: true
    }
  end

  private

  def extract_locale_from_accepted_language_header
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z1]{2}/).first
  end
end
