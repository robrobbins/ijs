/**
 * @fileOverview Base file for the i javascript libray
 * @author <a href="www.github.com/robrobbins">Rob Robbins</a>
 * @version 0.1.0
 */

/**
 * @namespace Global container of the i library.	Checks to if i is
 * already defined in the current scope before assigning to prevent
 * overwrite if i.js is loaded more than once.
 */
var I = I || {};
/**
 * @define {boolean} Used for the compiler of choice. Written to true when your
 * sources have been minified and combined
 */
I.amCompiled = false;
/**
 * Path for included scripts
 * @type {string}
 */
I.basePath = 'js';
/**
 * Reference for the current document.
 */
I.doc = document;
/**
 * Builds an object structure for the provided namespace path,
 * ensuring that names that already exist are not overwritten. For
 * example:
 * "a.b.c" -> a = {};a.b={};a.b.c={};
 * Used by X.provide
 * @param {string} name name of the object that this file defines.
 * @param {*=} obj the object to expose at the end of the path.
 * @param {Object=} scope The object to add the path to; default
 * is X.global.
 * @private
 */
I._exportPath = function(name, obj, scope) {
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
 * Returns an object based on its fully qualified external name.	If you are
 * using a compilation pass that renames property names beware that using this
 * function will not find renamed properties.
 * @param {string} name The fully qualified name.
 * @param {Object=} scope The object within which to look. Default is I.global.
 * @return {Object} The object or, if not found, null.
 */
I.getObjectByName = function(name, scope) {
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
 * A hook for the compiler to override basePath
 * @type {string|undefined}
 */
I.global.BASE_PATH = '';
/**
 * An object whose keys are the provided namespace of a third-party
 * dependency and whose values are the path to that file. These paths
 * can be local or hosted via cdn. The I.basePath var is not used here
 * so specify the relative path to the file
 * @type {Object}
 */
I.include = {
	'jQuery': 'http://code.jquery.com/jquery-1.6.1.min.js',
	'bgiframe': 'js/plugins/bgiframe.js',
	'delegate': 'js/plugins/delegate.js',
	'dimensions': 'js/plugins/dimensions.js',
	'tooltip': 'js/plugins/tooltip.js',
	'RML': 'js/plugins/rml.js'
};
/**
 * Creates object stubs for a namespace. When present in a file, I.provide
 * also indicates that the file defines the indicated object.
 * @param {string} name name of the object that this file defines
 */
I.provide = function(name) {
	if(!this.amCompiled) {
		// Ensure that the same namespace isn't provided twice.
		if(this.getObjectByName(name) && !this._ns[name]) {
				throw Error('Namespace "' + name + '" already declared.');
		}
		var namespace = name;
		while ((namespace = namespace.substring(0, namespace.lastIndexOf('.')))) {
			this._ns[namespace] = true;
		}
	}
	this._exportPath(name);
};
/**
 * Implements a system for the dynamic resolution of dependencies.
 * These will be removed when compiled
 * @param {string} module to include, in the form foo.bar.baz
 */
I.require = function(ns) {
	// allow for an array to be passed
	if(typeof ns !== 'string') {
		for(var n; n = ns.shift(); ) {
			this.require(n);
		}
		return;
	}
	var deps = this._dependencies;
	// if the object already exists we do not need do do anything
	if (!this.amCompiled) {
		if (this.getObjectByName(ns)) {
			return;
		}
		this._included[this._setPath(ns)] = true;
		this._writeScripts();
	}
};

if(!I.amCompiled) {
	/**
	 * This object is used to keep track of dependencies and other data that is
	 * used for loading scripts
	 * @private
	 * @type {Object}
	 */
	I._dependencies = {
	visited: {},
	written: {} // used to keep track of script files we have written
	};
	/**
	 * Using the 'convention over configuration' approach a provided namespace
	 * 'site.foo' is expected to resolve to a physical file at
	 * basePath/site/foo.js
	 * @param {string} path In the form foo.bar
	 * @return {?string} Url corresponding to the path.
	 * @private
	 */
	I._setPath = function(ns) {
		// check for third party
		if(ns in this.include) return this.include[ns];
		var arr = ns.split('.');
		arr.unshift(this.basePath);
		return arr.join('/') + '.js';
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
	 * Resolves dependencies based on the dependencies added using addDependency
	 * and calls _writeScriptTag in the correct order.
	 * @private
	 */
	I._writeScripts = function() {
		// the scripts we need to write this time
		var scripts = [];
		var seenScript = {};
		var deps = this._dependencies;

		/** @private */ function visitNode(path) {
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
			if(!(path in seenScript)) {
				seenScript[path] = true;
				scripts.push(path);
			}
		} // end visitNode
		for(var path in this._included) {
			if(!deps.written[path]) {
				visitNode(path);
			}
		}
		for(var i = 0; i < scripts.length; i++) {
			if(scripts[i]) {
				this._writeScriptTag(scripts[i]);
			} else {
				throw Error('Undefined script input');
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
		// TODO envi isHTml()
		if(!this._dependencies.written[src]) {
			this._dependencies.written[src] = true;
			this.doc.write('<script type="text/javascript" src="' + src + 
				'"></' + 'script>');
		}
	};
}