I.provide('site.test');
I.require(['jQuery','RML','site.awesome','tooltip','bgiframe','delegate',
	'dimensions']);


I.amDefined(['jQuery','RML','site.awesome','tooltip','bgiframe','delegate',
	'dimensions'], function($,rml,awe) {
	// setup a method to call when tooltips are ready
	site.test.tooltips = function() {
		this.show('So, mouse over the "What\'s this for? thing"');
		$("#hovered").tooltip({ 
			bodyHandler: function() { 
				return "ITS FOR A TOOLTIP!!!";
			}, 
			showURL: false
	  });
	};

	site.test.show = function(str) {
		// show stuff in the textarea
		var ta = $('#ta_output');
		curr_val = [ta.val()];
		curr_val.push(str);
		ta.val(curr_val.join('\n'));
	};
	
	site.test.show('jQuery and RML are loaded and parsed now');
		// the required ra.js script provided these
	site.test.show(awe.hello());
	
	$('#btn_tt').click(function() {
		site.test.show('All dependencies are loaded and parsed');
		site.test.tooltips();
	});
	
});
