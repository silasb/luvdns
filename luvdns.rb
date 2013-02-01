require 'sequel'
require 'oj'
require 'sinatra/base'
require 'tmpdir'

settings = YAML.load_file(File.expand_path('../config/settings.yml', __FILE__))

DB = Sequel.connect(settings['database'])

if Sinatra::Base.development?
  DB.create_table :domains do
    primary_key :id
    String :name
  end

  DB.create_table :records do
    primary_key :id
    Integer :domain_id
    String :type
    String :name
    String :content
  end
end

require File.expand_path('../app/models/record', __FILE__)
require File.expand_path('../app/models/domain', __FILE__)
require File.expand_path('../app/models/zone', __FILE__)

class LuvDNS < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  before '/update' do
    halt unless request.ip == '127.0.0.1'
  end

  post '/update' do
    params = Oj.load(request.body.read)

    id = params.delete 'id'
    zone = params['zone']

    Zone.new(id, zone)

    200
  end

  before '/post-commit-hook' do
    next unless Sinatra::Base.production?
    gh_ips = %w(207.97.227.253 50.57.128.197 108.171.174.178 50.57.231.61)
    halt 403 unless gh_ips.include? request.ip
  end

  post '/post-commit-hook' do
    push = Oj.load(params[:payload])

    url = push['repository']['url']
    name = push['repository']['name']

    pid = fork do
      dir = Dir.mktmpdir

      STDIN.reopen "/dev/null"
      STDOUT.reopen "/dev/null", "a"
      STDERR.reopen "/dev/null", "a"

      localhost_with_port = "http://localhost:#{ENV['PORT']}/update"

      begin
        FileUtils.cd(dir) do
          luvdns = File.expand_path('../updater/bin/luvdns', __FILE__)
          `git clone #{url} #{name}`
          `cd #{name} && #{luvdns} #{localhost_with_port}`
        end
      ensure
        FileUtils.remove_entry_secure dir
      end

      exit!
    end

    Process.detach(pid)

    200
  end
end
