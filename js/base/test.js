I.provide('base.test');
I.require('jQuery');
I.require('bgiframe');
I.require('dimensions');
I.require('delegate');
I.require('tooltip');
I.require('RML');
I.require('base.awesome');


$(document).ready(function() {
	// setup a method to call when tooltips are ready
	base.test.tooltips = function() {
		this.show('So, mouse over the "What\'s this for? thing"');
		$("#hovered").tooltip({ 
			bodyHandler: function() { 
				return RML.p("ITS FOR A TOOLTIP!!!");
			}, 
			showURL: false
	  });
	};

	base.test.show = function(str) {
		// show stuff in the textarea
		var ta = $('#ta_output');
		curr_val = [ta.val()];
		curr_val.push(str);
		ta.val(curr_val.join('\n'));
	};
	
	base.test.show('jQuery, plugins and RML are loaded and parsed now');
		// the required ra.js script provided these
	base.test.show(base.awesome.hello());
	
	$('#btn_tt').click(function() {
		base.test.show('All dependencies are loaded and parsed');
		base.test.tooltips();
	});
	
});
