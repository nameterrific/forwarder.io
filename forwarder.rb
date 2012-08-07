require 'sinatra'
require 'public_suffix'


get '/' do
  if request.host == "forwarder.io" or request.host.end_with?(".dev")
    erb :index
  else
    redirect to("http://forwarder.io/nothing") unless forwarder(request.host)
  end
end

get '/nothing' do
  erb :nothing
end


get '/:hostname' do
  redirect to("http://forwarder.io/nothing") unless forwarder(params[:hostname])
end

def sanitize(hostname)
  hostname.gsub(/[^a-zA-Z1-9.+-_]/, '')
end

def forwarder(hostname)
  hostname = sanitize(hostname)
  domain = PublicSuffix.parse(hostname).domain
  records = %x[dig +short #{hostname} TXT].split("\n")
  records += %x[dig +short #{domain} TXT].split("\n") if hostname.include? "www"
  records.each do |record|
    segments = record.delete('"').downcase.split(" ", 3)
    if segments[0] == "forwarder.io"
      if segments[2] and (segments[2].include? "-p" or segments[2].include? "--permanent")
        status_code = 301
      else
        status_code = 307
      end
     redirect to(segments[1], status_code) 
     return true
    end
  end
  return false
end

# forwarder.io http://url.to/redirect [-p|--permanent] 