require 'yaml'

CFG = YAML.load_file('config.yaml') unless defined? CFG
DW = CFG['depwriter'] unless defined? DW
# Our utility methods
module Utils
  @source_files = []
  @re_mode = Regexp.new('I\.amInProduction\s*=\s*([\w]+);')
  @re_write_script_tag = Regexp.new('I._writeScriptTag\([\'\"]([A-Za-z\/.-_]+)[\'\"]\);')
  @re_cdn_begin = Regexp.new('\/\/ BEGIN DW-CDN')
  @re_cdn_end = Regexp.new('\/\/ END DW-CDN')
  @MODE_PRO = 'I.amInProduction = true;'
  @MODE_DEV = 'I.amInProduction = false;'
  @TAG_DEV = ""
  @TAG_PRO = "I._writeScriptTag('#{DW['i_dir']}/#{DW['min_file_name']}');"
  
  def self.chk_tag_dev
    rm = DW['rm_dir']
    id = DW['i_dir']
    len = rm.size
    if len > 0
      adj = id.slice(id.index(rm)+len, id.size)
      @TAG_DEV = "I._writeScriptTag('#{adj}/#{DW['bootstrap']}');"
    else
      @TAG_DEV = "I._writeScriptTag('#{DW['i_dir']}/#{DW['bootstrap']}');"
    end
  end

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
    begin_cdn_idx = 0
    end_cdn_idx = 0
    # adjust TAG_DEV for rm_dir value if present
    chk_tag_dev()
    # read in the i.js file
    i_js = File.open(DW['i_v'], 'r')
    i_array = i_js.readlines("\n")
    i_js.close
    f = File.open(DW['i_v'], 'w') do |i|
      # modify where appropriate
      if DW['environment'] == 'development'
        i_array.each_with_index {|line, idx| 
          if @re_mode.match(line)
            i_array[idx] = line.sub(@re_mode, @MODE_DEV)
          elsif @re_write_script_tag.match(line)
            i_array[idx] = line.sub(@re_write_script_tag, @TAG_DEV)
          elsif @re_cdn_begin.match(line)
            begin_cdn_idx = idx
          elsif @re_cdn_end.match(line)
            end_cdn_idx = idx
          end
        }
        # delete the lines in between the *_cdn_idx if any
        i_array.slice!(begin_cdn_idx + 1, end_cdn_idx - (begin_cdn_idx + 1))
      else
        # assume we are in production
        i_array.each_with_index {|line, idx| 
          if @re_mode.match(line)
            i_array[idx] = line.sub(@re_mode, @MODE_PRO)
          elsif @re_write_script_tag.match(line)
            i_array[idx] = line.sub(@re_write_script_tag, @TAG_PRO)
          elsif @re_cdn_end.match(line)
            end_cdn_idx = idx            
          end
        }
        # place writeScript calls for the cdn-hosted deps, if any, before
        # the production file is written. Make sure to remove them if you
        # re-enter development mode from production
        if DW['cdn_hosted'].size > 0
          DW['cdn_hosted'].each {|k,v|
            i_array.insert(end_cdn_idx, "  I._writeScriptTag('#{v}');\n")
          }
        end
      end
      # overwrite the old i.js
      i.puts i_array.join('')
    end
  end
end
