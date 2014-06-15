class Conf
  include Singleton
  
  def initialize
    @conf = load_yaml 'conf.yaml'    
  end
  
  def get(*path)
    final = path.pop
    result = path.inject(@conf) do |value, path|
      if value.class == Hash
        value = @conf[path]
      end
    end
    result[final]
  end
  
private

  def load_yaml(filename)
    if File.exist? filename
      YAML.load_file(filename)
    else
      nil
    end
  end
  
end
