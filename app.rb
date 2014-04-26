require 'gollum/app'
require 'digest/sha1'

class App < Precious::App
  User = Struct.new(:name, :email, :password_hash, :can_write)

  before /^\/(edit|create|delete|livepreview|revert|rename)/ do
    authenticate!
    authorize_write!
  end

  helpers do
    def authenticate!
      @_auth ||=  Rack::Auth::Basic::Request.new(request.env)
      if @_auth.provided?
      end
      if @_auth.provided? && @_auth.basic? && @_auth.credentials &&
        @user = detected_user(@_auth.credentials)
        return @user
      else
        response['WWW-Authenticate'] = %(Basic realm="Proteollum Wiki")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorize_write!
      throw(:halt, [403, "Forbidden\n"]) unless @user.can_write
    end

    def users
      @_users ||= settings.authorized_users.map {|u| User.new(*u) }
    end

    def detected_user(credentials)
      users.detect do |u|
        [u.email, u.password_hash] ==
        [credentials[0], Digest::SHA1.hexdigest(credentials[1])]
      end
    end
  end

  def commit_message
    {
      :message => params[:message],
      :name => @user.name,
      :email => @user.email
    }
  end
end