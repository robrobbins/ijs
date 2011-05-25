require 'yaml'

CFG = YAML.load_file('config.yaml') unless defined? CFG
DW = CFG['depwriter'] unless defined? DW
# Our utility methods
module Utils
  @source_files = []
  @re_mode = Regexp.new('I\.amInProduction\s*=\s*([\w]+);')
  @re_write_script_tag = Regexp.new('I._writeScriptTag\([\'\"]([A-Za-z\/.-_]+)[\'\"]\);')
  @MODE_PRO = 'I.amInProduction = true;'
  @MODE_DEV = 'I.amInProduction = false;'
  @TAG_DEV = "I._writeScriptTag('#{DW['i_dir']}/#{DW['bootstrap']}');"
  @TAG_PRO = "I._writeScriptTag('#{DW['i_dir']}/#{DW['min_file_name']}');"
  
  def self.is_js_file(ref)
    #File.fnmatch('*.js', ref)
    File.extname(ref) == '.js'
  end
  
  def self.is_directory(ref)
    File.directory? ref
  end
  
  def self.source_files
    @source_files
  end
  
  # return a list of normalized paths from a given root directory
  # expanding any sub-directories found while recursively searching
  def self.expand_directories(search_ext)
    str = "**/*.{#{search_ext.join(',')}}"
    exc_dirs = 
    exc_files =  
    Dir.glob(str) { |ref|
      puts "found #{ref}"
      if DW['exc_files'].include? ref
        puts 'excluded'
      elsif DW['exc_dirs'].include? File.dirname(ref)
        puts 'excluded'
      else
        @source_files.push(ref)
      end
    }
  end
  
  def self.mod_i
    # read in the i.js file
    i_js = File.open('i.js', 'r')
    i_array = i_js.readlines("\n")
    i_js.close
    f = File.open('i.js', 'w') do |i|
      # modify where appropriate
      if DW['environment'] == 'development'
        i_array.each_with_index {|line, idx| 
          if @re_mode.match(line)
            i_array[idx] = line.sub(@re_mode, @MODE_DEV)
          elsif @re_write_script_tag.match(line)
            i_array[idx] = line.sub(@re_write_script_tag, @TAG_DEV)
          end
        }
      else
        # assume we are in production
        i_array.each_with_index {|line, idx| 
          if @re_mode.match(line)
            i_array[idx] = line.sub(@re_mode, @MODE_PRO)
          elsif @re_write_script_tag.match(line)
            i_array[idx] = line.sub(@re_write_script_tag, @TAG_PRO)
          end
        }
      end
      # overwrite the old i.js
      i.puts i_array.join('')
    end
  end
  
end