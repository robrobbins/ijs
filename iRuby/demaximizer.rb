# A Mixin that allows Dependant class instances to minify themselves
# via Closure compiler REST service. Using this API you could easily write
# a module to use a different service or a local tool as well.
require 'yaml'
require 'net/http'
require 'uri'

CFG = YAML.load_file('config.yaml') unless defined? CFG
DM = CFG['demaximizer'] unless defined? DM

module Demaximizer
  # write the minified js to the file and return it
  def minify(file)
    url = URI.parse(DM['url'])
    params = Hash.new
    params['js_code'] = @txt
    params['compilation_level'] = DM['comp_level']
    params['output_format'] = DM['output_format']
    params['output_info'] = DM['output_info']
    
    req = Net::HTTP::Post.new(url.path)
    # TODO privide a hook for setting headers via config
    req['Content-type'] = 'application/x-www-form-urlencoded'
    req.set_form_data(params)
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      file.puts res.body
      return file
    else
      res.error!
    end
  end
end
