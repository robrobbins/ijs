/**
 * @fileOverview Base file for the i javascript libray
 * @author <a href="www.github.com/robrobbins">Rob Robbins</a>
 * @version 0.1.0
 */

/**
 * @namespace Global container of the i library.  Checks to if i is
 * already defined in the current scope before assigning to prevent
 * overwrite if i.js is loaded more than once.
 */
var I = I || {};
/**
 * @define {boolean} Used for the compiler of choice. Written to true when your
 * sources have been minified and combined
 */
I.amInProduction = false;
/**
 *
 */
I.define = function(path, provides, requires) {
  if (!this.amInProduction) {
    var provide, require;
    var deps = this._dependencies;
    for (var i = 0; provide = provides[i]; i++) {
      deps.nameToPath[provide] = path;
      if (!(path in deps.pathToNames)) {
        deps.pathToNames[path] = {};
      }
      deps.pathToNames[path][provide] = true;
    }
    for (var j = 0; require = requires[j]; j++) {
      if (!(path in deps.requires)) {
        deps.requires[path] = {};
      }
      deps.requires[path][require] = true;
    }
  }
};
/**
 * Reference for the current document.
 */
I.doc = document;
/**
 * Builds an object structure for the provided namespace path,
 * ensuring that names that already exist are not overwritten. For
 * example:
 * "a.b.c" -> a = {};a.b={};a.b.c={};
 * Used by I.provide
 * @param {string} name name of the object that this file defines.
 * @param {*=} obj the object to expose at the end of the path.
 * @param {Object=} scope The object to add the path to; default
 * is I.global.
 * @private
 */
I._exportNamespace = function(name, obj, scope) {
  var parts = name.split('.');
  var cur = scope || this.global;

  // fix for Internet Explorer's strange behavior
  if (!(parts[0] in cur) && cur.execScript) {
    cur.execScript('var ' + parts[0]);
  }
  // Certain browsers cannot parse code in the form for((a in b); c;);
  // This pattern is produced by the JSCompiler when it collapses the
  // statement above into the conditional loop below. To prevent this from
  // happening, use a for-loop and reserve the init logic as below.
  // Parentheses added to eliminate strict JS warning in Firefox.
  for (var part; parts.length && (part = parts.shift());) {
    if (!parts.length && obj) {
      // last part and we have an object; use it
      cur[part] = obj;
    } else if (cur[part]) {
      cur = cur[part];
    } else {
      cur = cur[part] = {};
    }
  }
};
/**
 * Returns an object based on its fully qualified external name.  If you are
 * using a compilation pass that renames property names beware that using this
 * function will not find renamed properties.
 * @param {string} name The fully qualified name.
 * @param {Object=} scope The object within which to look. Default is I.global.
 * @return {Object} The object or, if not found, null.
 */
I.getNamespace = function(name, scope) {
  var parts = name.split('.');
  var cur = scope || this.global;
  for (var part; part = parts.shift(); ) {
    if (cur[part]) {
      cur = cur[part];
    } else {
      return null;
    }
  }
  return cur;
};
/**
 * Reference for the current context. Except of special cases it will be 'window'
 */
I.global = this;
/**
 * Creates object stubs for a namespace. When present in a file, I.provide
 * also indicates that the file defines the indicated object.
 * @param {string} name name of the object that this file defines
 */
I.provide = function(name) {
  if(!this.amInProduction) {
    // Ensure that the same namespace isn't provided twice.
    if(this.getNamespace(name) && !this._ns[name]) {
        throw Error('Namespace "' + name + '" already defined.');
    }
    var namespace = name;
    while ((namespace = namespace.substring(0, namespace.lastIndexOf('.')))) {
      this._ns[namespace] = true;
    }
  }
  this._exportNamespace(name);
};
/**
 * Implements a system for the dynamic resolution of dependencies.
 * These will be removed when compiled
 * @param {string} module to include, in the form foo.bar.baz
 */
I.require = function(ns) {
  if (!this.amInProduction) {
  // allow for an array to be passed
    if(typeof ns !== 'string') {
      for(var n; n = ns.shift(); ) {
        this.require(n);
      }
      return;
    }
    // if the object already exists we do not need do do anything
    if (this.getNamespace(ns)) {
      return;
    }
    var path = this._getPath(ns);
    if(path) {
      this._included[path] = true;
      this._resolveScripts();
    } else {
      throw Error('Undefined dependency' + ns);
    }
  }
};
if(I.amInProduction) {
  /**
   * Writes a script tag for the aggregated-minified production file.
   * @param {string} src Script source.
   * @private
   */
  I._writeScriptTag = function(src) {
    this.doc.write('<script type="text/javascript" src="' + src + 
      '"></' + 'script>');
  };
    // BEGIN DW-CDN
    // END DW-CDN 
  I._writeScriptTag('js/bootstrap.js');
} else {
  /**
   * This object is used to keep track of dependencies and other data that is
   * used for loading scripts
   * @private
   * @type {Object}
   */
  I._dependencies = {
    pathToNames: {},
    nameToPath: {},
    requires: {},
    visited: {},
    written: {}
  };
  /**
   * Looks at the dependency rules and tries to determine the script file that
   * provides a particular namespace.
   * @param {string} ns In the form foo.bar
   * @return {?string} path to the script, or null.
   * @private
   */
  I._getPath = function(ns) {
    if (ns in this._dependencies.nameToPath) {
      return this._dependencies.nameToPath[ns];
    } else {
      return null;
    }
  };
  /**
   * Object used to keep track of urls that have already been added. This
   * record allows the prevention of circular dependencies.
   * @type {Object}
   * @private
   */
  I._included = {};
  /**
   * Namespaces implicitly defined by provide. For example,
   * provide('X.foo.bar') implicitly declares
   * that 'X' and 'X.foo' must be namespaces.
   * @type {Object}
   * @private
   */
  I._ns = {};
  /**
   * Resolves dependencies based on the dependencies added using define()
   * and calls _writeScriptTag in the correct order.
   * @private
   */
  I._resolveScripts = function() {
    // the scripts we need to write this time
    var scripts = [];
    var seenScript = {};
    var deps = this._dependencies;

    /** @private */ function RFS(path) { // requires-first-search ;)
      if(path in deps.written) {
        return;
      }
      // we have already visited this one. We can get here if we have 
      // cyclic dependencies
      if(path in deps.visited) {
        if (!(path in seenScript)) {
          seenScript[path] = true;
          scripts.push(path);
        }
        return;
      }
      deps.visited[path] = true;
      
      if (path in deps.requires) {
        for (var requireName in deps.requires[path]) {
          if (requireName in deps.nameToPath) {
            RFS(deps.nameToPath[requireName]);
          } else if (!I.getNamespace(requireName)) {
            // If the required name is defined, we assume that this
            // dependency was bootstapped by other means. Otherwise,
            // throw an exception.
            throw Error('Undefined nameToPath for ' + requireName);
          }
        }
      }
      
      if(!(path in seenScript)) {
        seenScript[path] = true;
        scripts.push(path);
      }
    } // end RFS
    for(var path in this._included) {
      if(!deps.written[path]) {
        RFS(path);
      }
    }
    for(var i = 0; i < scripts.length; i++) {
      if(scripts[i]) {
        this._writeScriptTag(scripts[i]);
      } else {
        throw Error('Undefined script');
      }
    }
  };
  /**
   * Writes a script tag if, and only if, that script hasn't already been 
   * added to the document.  
   * @param {string} src Script source.
   * @private
   */
  I._writeScriptTag = function(src) {
    if(!this._dependencies.written[src]) {
      this._dependencies.written[src] = true;
      this.doc.write('<script type="text/javascript" src="' + src + 
        '"></' + 'script>');
    }
  };
  // auto set by depwriter
  I._writeScriptTag('js/bootstrap.js');
}
