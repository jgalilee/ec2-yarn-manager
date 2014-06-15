require 'aws'
require 'net/http'
require 'net/ssh'
require 'yaml'
require 'singleton'

require './conf'

class Cluster
  include Singleton
  
  attr_accessor :conf, :ec2
  
  def initialize
    @conf = Conf.instance
    @ec2 = AWS::EC2.new
  end
  
  def masters
    instances_tagged_with(@conf.get(:tags, :cluster), @conf.get(:tags, :masters))
  end
  
  def slaves
    instances_tagged_with(@conf.get(:tags, :cluster), @conf.get(:tags, :slaves))
  end
  
  def add(type, n=1)
    add_nodes(type, n) { |*args| yield *args if block_given? }
  end
  
  def generate_masters_file
    ips = private_information_of(:running, masters) { |i| i.private_ip_address }
    generate_file_for 'masters', *ips
  end
  
  def generate_slaves_file
    ips = private_information_of(:running, slaves) { |i| i.private_ip_address }
    generate_file_for 'slaves', *ips
  end
  
  def status
    {
      :masters => status_of(masters),
      :slaves => status_of(slaves)
    }
  end

  def status_of(instances)
    overview_of(instances)
  end

private
  
  def add_nodes(type, n=1)
    timeout = @conf.get(:timeout).to_i.abs + 1
    yield :creating if block_given?
    instances = make_instances_from_scaffold(type, n)
    yield :created if block_given?
    i, j = n, -1
    begin
      if (j += 1) > 0
        yield :starting, j, i, n if block_given?
        sleep timeout
      end 
    end while (i = count_with_status(:pending, *instances)) > 0
    yield :started
    instances
  end

  def generate_file_for(filename, *lines)
    File.open(filename, 'w') do |file|
      lines.each do |line|
        file.puts line
      end
    end
  end

  def private_information_of(status, *instance_collections)
    AWS.memoize do
      result = instance_collections.collect do |set|
        if block_given?
          set.select { |i| i.status == status }.collect do |instance|
            yield instance
          end
        end
      end
      result.flatten
    end
  end

  def count_with_status(status, *instances)
    AWS.memoize do 
      instances.reduce(0) do |count, instance|
        if instance.status == status
          count = count + 1
        end
        count
      end
    end
  end

  def make_instances_from_scaffold(scaffold, n=1)
    scaffold = @conf.get(:scaffolds, scaffold)
    make_instances({ :count => n }.merge!(scaffold))
  end

  def make_instances(settings)
    AWS.memoize do
      tags = settings.delete :tags
      instances = [@ec2.instances.create(settings)].flatten
      if tags
        instances.each do |instance|
          tags.each do |tag|
            instance.tag(tag.keys.first, :value => tag[tag.keys.first])
          end
          instance
        end
      end
    end
  end
  
  def instances_tagged_with(tag, *values)
    AWS.memoize do
      @ec2.instances.with_tag(tag, *values)
    end
  end
  
  def overview_of(instances)
    instances.inject({}) do |hash, instance|
      hash[instance.id] = {
        :overview => instance,
        :security_groups => instance.security_groups.inject({}) { |h, i|
          h[i.id] = i 
          h
        }
      }
      hash
    end
  end
  
end
