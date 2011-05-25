require 'set'
require './dependant.rb'
require './demaximizer.rb'

module Dependencies
# a list of dependency objects
  @all = []
  # these have provide / require statements
  @matched = {}
  # how the dependencies should be loaded
  @req_attr = {}
  # namespaces which have been found
  @resolved = []
  # regexes for finding our statements
  @re_requires = Regexp.new('I\.require\s*\(\s*[\'\"]([^\)]+)[\'\"]\s*\)')
  @re_provides = Regexp.new('I\.provide\s*\(\s*[\'\"]([^\)]+)[\'\"]\s*\)')

  def self.build_from_files(files)
    # make sure there are no dupes in the files array
    sources = Set.new(files)
    #iterate through the array
    sources.each {|file|
      # make a dependant instance
      dep = Dependant.new(file)
      # should we push this one?
      is_dep = false
      # open the file and read it
      puts "opening #{file}"
      f = File.open(file)
      # save this so we can minify it later
      dep.txt = f.read
      f.close
      # iterate each line and look for statements
      dep.txt.each_line {|line|
        if data = @re_provides.match(line)
          is_dep = true
          data.captures.each {|i|
            dep.provides_push(i)
          }
        elsif mdata = @re_requires.match(line)
          is_dep = true
          mdata.captures.each {|i|
            dep.requires_push(i)
          }
        end
      }
      @all.push(dep) if is_dep
    }
  end

  def self.add_plugins(files, plugin_dirs)
    # if the file is in the plugin_dir, remove its .js extension and use
    # that as the provided namespace
    sources = Set.new(files)
    sources.each {|file|
      dep = Dependant.new(file)
      # for aggregation to a single file later
      # TODO we could strip the comments
      puts "opening plugin #{file}"
      f = File.open(file)
      dep.txt = f.read
      f.close
      dep.is_vendor = true
      if plugin_dirs.include? File.dirname(file)
        dep.provides_push(File.basename(file, '.js'))
        dep.requires_push(plugin_dirs[File.dirname(file)])
        @all.unshift(dep)
      end
    }
  end
  
  def self.add_third_party(files, ven_dirs)
    # if the file is in the ven_dir, remove its .js extension and use
    # that as the provided namespace
    sources = Set.new(files)
    sources.each {|file|
      dep = Dependant.new(file)
      # for aggregation to a single file later
      # TODO we could strip the comments
      puts "opening plugin #{file}"
      f = File.open(file)
      dep.txt = f.read
      f.close
      dep.is_vendor = true
      # ven_dir should have been hashed already
      if ven_dirs.include? File.dirname(file)
        dep.provides_push(File.basename(file, '.js'))
        @all.unshift(dep)
      end
    }
  end
  
  def self.add_cdn(cdns)
    # will not use source_files as we don't have them
    cdns.each {|k, v|
      # v should be the actual URI of the dependency
      dep = Dependant.new(v)
      dep.is_cdn = true
      # it provides a namespace object
      dep.provides_push(k)
      @all.unshift(dep)
    }
  end

  def self.build_matched_hash
    @all.each { |dep|
      puts "found #{dep.filename}"
      dep.provides.each {|ns|
        puts "it provides #{ns}"
        # dont provide the same ns more than once
        if @matched[ns].nil?
          # {namespace: dependency}
          puts "assigning #{ns} to matched hash"
          @matched[ns] = dep
        else
          puts "#{@hash[ns]} already provided by #{ns}"
        end
      }
    }
    # @matched.each {|k,v| puts "#{k}: #{v}"}
  end

  def self.resolve_deps
    @matched.each_value { |dep|
      dep.requires.each { |req|
        puts "Resolving required namespace #{req}"
        if result = resolve_req(req)
          puts result
        else
          puts "Missing provider for #{req}"
          return false
        end
      }
    }
    return true
  end

  def self.resolve_req(req)
    #require must be a file we know about
    if @resolved.include? req
      return "#{req} already resolved"
    elsif @matched.include? req
      @resolved.push(req)
      return "#{req} is provided by #{@matched[req]}"
    else
      return nil
    end
  end

  def self.all
    @all
  end

  def self.matched
    @matched
  end
  
  # depwriter will re-use this in production mode
  def self.re_requires
    @re_requires
  end
end