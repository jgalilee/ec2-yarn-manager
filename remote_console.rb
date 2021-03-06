require 'net/ssh'
require 'net/scp'

class RemoteConsole

  def self.connect_with(instance, options={})
    return RemoteConsole.new(instance, options)
  end

  def run(*commands)
    commands.each do |command|
      result = begin
        @ssh.exec!(command)
      rescue SystemCallError, Timeout::Error => e
        sleep(1) and retry
      rescue StandardError => e
        yield :error, e and return
      end
      yield :success, result
    end
  end

  def upload(local_path, remote_path)
    @ssh.scp.upload!(local_path, remote_path) do |ch, name, sent, total|
      yield "#{name}: #{sent}/#{total}" if block_given?
    end
  end

protected

  def initialize(ip_address, options={})
    @ip_address = ip_address
    user = options.delete :user
    @ssh ||= Net::SSH.start(ip_address, user, options)
  end

end