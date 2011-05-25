require 'yaml'
require './utils.rb'
require './dependencies.rb'

# you are here...
I_AM = File.expand_path($PROGRAM_NAME)
I_RUBY_DIR = File.dirname(I_AM)
# load our config file
CFG = YAML.load_file('config.yaml') unless defined? CFG
# vars for this script
DW = CFG['depwriter'] unless defined? DW
# will need these later for aggregation/minification step
tp_deps = []
our_deps = []
re_requires = Dependencies.re_requires
# move to root and begin
Dir.chdir(DW['i_root'])
# make sure we can get back to root
I_ROOT_ABS = File.expand_path(Dir.getwd)

Utils.expand_directories(DW['search_ext'])
# rip through the files looking for provides() / requires()
# third-party, cdn hosted and framework plugins
Dependencies.build_from_files(Utils.source_files)
Dependencies.add_third_party(Utils.source_files, DW['ven_dirs'])
Dependencies.add_cdn(DW['cdn_hosted'])
Dependencies.add_plugins(Utils.source_files, DW['plugin_dirs'])

# put the hash together
Dependencies.build_matched_hash
if Dependencies.resolve_deps
  puts "All depencies resolved, writing deps file. Moving to 'i_dir'"
  # get the deps
  matched = Dependencies.matched
  Dir.chdir(DW['i_dir'])
  # make sure we can get back here
  I_DIR_ABS = File.expand_path(Dir.getwd)
  # what environment are we targeting?
  if DW['environment'] == 'development'
    # open a file for writing
    out = File.open(DW['bootstrap'], 'w') do |deps|
      matched.each_value {|dep|
        len = DW['rm_dir'].size
        if len > 0
          st = dep.filename.index(DW['rm_dir'])
          fn = dep.filename.slice(st + len, dep.filename.size)
        else
          # no section to remove
          fn = dep.filename
        end
        deps.puts "I.define('#{fn}', #{dep.get_provides}, #{dep.get_requires});"
      }
    end
    puts "bootstrap.js written, modifying i.js"
    Utils.mod_i()
    puts "i.js in #{DW['environment']} mode, moving back to iRuby directory"
    Dir.chdir(I_RUBY_DIR)
  else
    # assume we are in production. organize our deps by type
    matched.each_value {|dep|
      if dep.is_cdn
        # pass
      elsif dep.is_vendor
        tp_deps.push(dep)
      else
        our_deps.push(dep)
      end
    }
    # we need to modify any master/layout pages and add script
    # tags for cdn-hosted dependencies since we don't physically
    # have these files.
    puts "moving to root"
    Dir.chdir(I_ROOT_ABS)
    # send the regex along so we can strip I.require calls from layout/master
    Utils.mod_layout(re_requires)
    puts "moving back to 'i_dir'"
    Dir.chdir(I_DIR_ABS)
    out = File.open(DW['min_file_name'], 'w') do |deps|
      deps.puts "// Third party scripts\n"
      tp_deps.each{|b|
        deps.puts "#{b.txt}\n"
      }
      deps.puts "// Our scripts\n"
      our_deps.each{|c|
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
    puts "minified file written, modifying i.js"
    Utils.mod_i()
    puts "i.js in #{DW['environment']} mode, moving back to #{I_RUBY_DIR}"
    Dir.chdir(I_RUBY_DIR)
  end
else
  puts "Fail!"
end