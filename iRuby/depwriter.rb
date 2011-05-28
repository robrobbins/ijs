require 'yaml'
require './utils.rb'
require './dependencies.rb'
require './depfile.rb'

# you are here...
I_AM = File.expand_path($PROGRAM_NAME)
I_RUBY_DIR = File.dirname(I_AM)
# load our config file
CFG = YAML.load_file('config.yaml') unless defined? CFG
# vars for this script
DW = CFG['depwriter'] unless defined? DW
re_requires = Dependencies.re_requires
# move to root and begin
Dir.chdir(DW['i_root'])
Utils.expand_directories(DW['search_ext'])
# rip through the files looking for provides() / requires(),
# third-party, cdn hosted and framework plugins
Dependencies.build_from_files(Utils.source_files)
Dependencies.add_third_party(Utils.source_files, DW['ven_dirs'])
Dependencies.add_cdn(DW['cdn_hosted'])
Dependencies.add_plugins(Utils.source_files, DW['plugin_dirs'])
# put the hash together
Dependencies.build_matched_hash
if Dependencies.resolve_deps
  puts "All depencies resolved, writing bootstrap file. Moving to 'i_dir'"
  # get the deps
  matched = Dependencies.matched
  Dir.chdir(DW['i_dir'])
  # what environment are we targeting?
  if DW['environment'] == 'development'
    Depfile.write_dev_file(matched)
    puts "bootstrap.js written, modifying i.js"
    Utils.mod_i()
    puts "i.js in #{DW['environment']} mode, moving back to iRuby directory"
    Dir.chdir(I_RUBY_DIR)
  else
    Depfile.write_pro_file(matched, re_requires)
    puts "minified file written, modifying i.js"
    Utils.mod_i()
    puts "i.js in #{DW['environment']} mode, moving back to #{I_RUBY_DIR}"
    Dir.chdir(I_RUBY_DIR)
  end
else
  puts "Fail!"
end