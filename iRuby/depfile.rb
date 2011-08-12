require 'yaml'

CFG = YAML.load_file('config.yaml') unless defined? CFG
DW = CFG['depwriter'] unless defined? DW

# A module for the depwriter that abstracts away the file writing tasks
module Depfile
  # will need these later for aggregation/minification step
  @tp_deps = []
  @our_deps = []
  
  def self.write_dev_file(matched)
    # open a file for writing
    out = File.open(DW['bootstrap'], 'w') do |deps|
      matched.each_value {|dep|
        len = DW['rm_dir'].size
        if len > 0 and not dep.is_cdn
          st = dep.filename.index(DW['rm_dir'])
          fn = dep.filename.slice(st + len, dep.filename.size)
        else
          # no section to remove
          fn = dep.filename
        end
        deps.puts "I.define('#{fn}', #{dep.get_provides}, #{dep.get_requires});"
      }
    end
  end
  
  def self.write_pro_file(matched, re_requires)
    # we are in production. organize our deps by type
    matched.each_value {|dep|
      if dep.is_cdn
        # pass
      elsif dep.is_vendor
        @tp_deps.push(dep)
      else
        # use requires to order this array properly
        # before minification
        if @our_deps.length == 0
          insert_at = nil
        else
          @our_deps.each_with_index {|d, i|
            # provides is an array as well
            for p in dep.provides
              if d.requires.include? p
                puts "#{d.filename} requires #{p}"
                insert_at = i
                break
              end
            end
          }
        end
        if insert_at.nil?
          @our_deps.push(dep)
        else
          @our_deps.insert(insert_at, dep)
        end
      end
    }
    # now write the file
    out = File.open(DW['min_file_name'], 'w') do |deps|
      deps.puts "// Third party scripts\n"
      @tp_deps.each{|b|
        deps.puts "#{b.txt}\n"
      }
      deps.puts "// Our scripts\n"
      @our_deps.each{|c|
        tmp = ''
        # we need to remove all require() calls from our deps
        # this could be done in Dependencies for DRYness
        c.txt.each_line {|line|
          if not re_requires.match(line)
            tmp += line
          end
        }
        c.txt = tmp
        c.minify(deps)
      }
    end
  end
end
