#!/usr/bin/env ruby
require 'thor'
require './cluster'

class Cli < Thor

  desc 'status',
    'Returns the status of the slaves and masters in the cluster.'
  method_option :scope, :type => :string, :aliases => "-s", :default => "all"
  def status
    @cluster = Cluster.instance
    scope = options[:scope].to_sym
    case scope
    when :all
      say @cluster.status.to_yaml
      exit 0
    when :masters
      say @cluster.status_of(@cluster.masters).to_yaml
      exit 0
    when :slaves
      say @cluster.status_of(@cluster.slaves).to_yaml
      exit 0
    else
      say "Invalid scope #{scope}"
      exit 1
    end
  end

  desc 'add NUMBER [slaves|masters]',
    'Adds a NUMBER of slaves or masters to the cluster.'
  def add(number, type)
    type = type.to_sym
    valid_types = [:slaves, :masters]
    unless valid_types.include? type
      say "Invalid type #{type}. Valid types are #{valid_types.join(', ')}."
      exit 1
    else
      @cluster = Cluster.instance
      @cluster.add(type, 2) do |status, tick, not_ready, requested|
        case status
        when :creating
          puts "Creating #{type}..."
        when :created
          puts "Created #{type}!"
        when :starting
          puts "##{tick}: Waiting for #{not_ready} of #{requested}..." 
        when :started
          puts "Ready!"
          puts "masters:"
          puts @cluster.generate_masters_file
          puts "#{type}:"
          puts @cluster.generate_slaves_file
        end
      end
      exit 0
    end
  end

  desc 'refresh master-id',
    'Refreshes the slaves and masters files on the root master node.'
  def refresh(master_id)

  end

end

Cli.start
