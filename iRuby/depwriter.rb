require 'yaml'
require './utils.rb'
require './dependencies.rb'

# you are here...
I_AM = File.expand_path($PROGRAM_NAME)
I_RUBY_DIR = File.dirname(I_AM)
# load our config file
CFG = YAML.load_file('config.yaml') unless defined? CFG
# vars for this script
DW = CFG['depwriter']
# move to root and begin
Dir.chdir(DW['i_root'])

Utils.expandDirectories(DW['search_ext'], DW['exc_dirs'])
# rip through the files looking for provides() / requires()
# third-party, cdn hosted and framework plugins
Dependencies.build_from_files(Utils.source_files)
Dependencies.add_third_party(Utils.source_files, DW['ven_dirs'])
Dependencies.add_cdn(DW['cdn_hosted'])
Dependencies.add_plugins(Utils.source_files, DW['plugin_dirs'], DW['plugin_dep'])

# put the hash together
Dependencies.build_matched_hash
if Dependencies.resolve_deps
  puts "All depencies resolved, writing deps file. Moving to #{DW['i_dir']}"
  # get the deps
  matched = Dependencies.matched 
  Dir.chdir(DW['i_dir'])
  # open a file for writing
  out = File.open('bootstrap.js', 'w') do |deps|
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
  puts "deps.js written, moving back to #{I_RUBY_DIR}"
  Dir.chdir(I_RUBY_DIR)
else
  puts "Fail!"
end