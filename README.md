#I.js 'Prelude' Edition
#### Synchronous Javascript dependency manager  
A 2 mode dependency management system that allows for an eloquent require and provide syntax in 
development, then strips, minifies and concatonates all dependencies for production.
__Development__ mode features a familiar *I.provide(...)* and *I.require(...)* API
that resolves each files dependencies before injecting script tags into the dom.
__Production__ mode strips the *require(...)* calls from your scripts and minifies
and concatonates them all into a single file.

###Why 'Prelude' Edition?
This was my original forray into a dependency manager that allowed for a Ruby or Python-esque
script development style (require 'foo' or import 'bar'). I wanted a Dojo or Google Closure style 
system decoupled from a parent library. After spending much time hacking on the async version
found in the [I repo](http://www.github.com/robrobbins/I) I kept finding reasons to use the more traditional 
'concatonate-to-a-single-file' for production method I started with. 

##Quick and Dirty Tour Pt1.

###I.Provide(name)

    I.provide('Foo.bar');

Creates this global level nested object:

    window.Foo {
        bar:{}    
    }

###I.Require(something)

    I.require('jquery');

Will append a script tag to the DOM in a blocking manner:

    <script src='path-to-jquery'></script>


###Depwriter.rb

This is a Ruby utility program which reads your source code
recursively, starting at your root directory looking for I.provide(...) 
and I.require(...) statements. At any point in your development just run:

	depwriter.rb
	
From your editor of choice (or a terminal) and a file *bootstrap.js* will be 
auto-generated and placed beside *i.js*. __i.js__ already knows to load this 
file and uses it to fill lookup tables that it keeps internally in order
to resolve a scripts dependencies. 

###Third Party, Plugin and CDN-Hosted Libraries
In the case of third-party libraries (jquery for example) that do not contain
I.provide() / I.require() statements I have included the ability to identify 
directories which hold scripts that you want added as dependencies regardless.
Any scripts found in those folders will be added as *providers*. You can then
require them by their script name minus the extension:

	I.require('jquery')
	
Would resolve correctly to the directory you placed *jquery.js* in if you 
identified the directory (via the config.yaml file) to *depwriter.js* and ran it.

####CDN Support
The *config.yaml* file has an entry for CDN-hosted libraries. It's a simple hash
which has the 'provided' name as keys and 'paths' as values:

	cdn_hosted:
    'jQuery': 'http://code.jquery.com/jquery-1.6.1.min.js'

This way any calls to:

	I.require('jQuery')
	
Will know how to resolve. Note that what you will be requiring in scripts that
depend on the CDN-hosted library needs to match the key (note the capital Q).

####Plugin Support
Some third party scripts rely on other scripts but you wouldn't want to have to
modify their source. For example jQuery plugins obviously rely on jQuery. Any
scripts found in the *plugin_dirs* (see config.yaml) will be treated the same as
files found in the *ven_dirs* (again, see config.yaml) with one exception. The 
value stored along with their key (the directory itself) will be inserted as a dependency
for them. This will keep the plugins from trying to initalize before their 
'parent' object is ready

###Demaxification?
A.K.A minification. __i.js__ when placed in 'production' mode will minify all
of your dependencies and place them into a single script. The name of this file 
id identified by the __config.yaml__ variable *min_file_name*.

###Blog Posts / Screencasts coming

I'll do some eventually.	
