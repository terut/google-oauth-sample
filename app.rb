require 'faraday'
require 'json'
class App < Sinatra::Base

  CONFIG = {
    client_id: "foo",
    client_secret: "bar",
    scope: "https://www.googleapis.com/auth/analytics.readonly",
    redirect_url: "http://localhost:9292/callback"
  }

  get "/" do
    haml :index
  end

  # if you retake refresh_token, you must set approval_prompt=force.
  get "/authorize" do
    q = [
      "response_type=code", 
      "client_id=#{CONFIG[:client_id]}",
      "redirect_uri=#{CONFIG[:redirect_url]}",
      "scope=#{CONFIG[:scope]}",
      #"approval_prompt=force",
      "access_type=offline"
    ]

    url = "https://accounts.google.com/o/oauth2/auth?#{q.join("&")}"
     
    redirect url
  end

  get "/callback" do
    q = {
      code: params[:code],
      client_id: CONFIG[:client_id],
      client_secret: CONFIG[:client_secret],
      redirect_uri: CONFIG[:redirect_url],
      grant_type: "authorization_code"
    }

    conn = connection("https://accounts.google.com")

    res = conn.post "/o/oauth2/token", q
    auth = JSON.parse(res.body) 

    session[:auth] = auth

    redirect '/'
  end

  get "/refresh" do
    q = {
      refresh_token: "aaa",
      client_id: CONFIG[:client_id],
      client_secret: CONFIG[:client_secret],
      grant_type: "refresh_token"
    }

    conn = connection("https://accounts.google.com")

    res = conn.post "/o/oauth2/token", q
    auth = JSON.parse(res.body) 

    session[:auth] = auth
    
    redirect "/"
  end

  get '/analytics' do
    conn = connection("https://www.googleapis.com")

    params = {
      "ids" => "ga:777",
      "metrics" => "ga:visits,ga:bounces",
      "start-date" => "2010-03-26",
      "end-date" => "2012-04-26",
    }

    auth = session[:auth]

    res = conn.get  do |req|
      req.url "/analytics/v3/data/ga", params
      req.headers[:Authorization] = "Bearer #{auth['access_token']}"
    end

    @data = JSON.parse(res.body)

    haml :analytics
  end

  private
  def connection(url)
    conn = Faraday.new(url: url) do |builder|
      builder.request  :url_encoded
      builder.response :logger
      builder.adapter  :net_http
    end
  end
end
