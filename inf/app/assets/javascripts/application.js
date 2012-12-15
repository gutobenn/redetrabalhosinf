// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .
//= require bootstrap

// TokenInput Settings
// Thanks to http://loopj.com/jquery-tokeninput/
$(function() {
	$("#project_tag_tokens").tokenInput( "/tags.json", {
		theme: "facebook"
		,preventDuplicates: true
		,hintText: "Digite tags para adicionar..."
		,noResultsText: "Sem resultados - pressione ENTER para adicionar"
		,searchingText: "Procurando por tags semelhantes..."
		,animateDropdown: false
		,allowFreeTagging: true // Enables the user to insert tags that weren't found. Later validation is done on the Controller for creating the tags within the BD.
	});	
});

// Function used within forms for deleting uploaded files.
// Remember to: (1) create a hidden field holding a boolean value
// 				(2) pass into this function the ID of the field of the previous step
//				(3) handle this hidden field value on Update call of your controller
function deleteUploadedField(fieldName)
{
	if(confirm('Tem certeza?')) {
		$("#" + fieldName).val('true');
		$('form').submit();
		return false;			
	}
}

// Character counters.
// Thanks to http://bampa.se/2011/01/simple-jquery-character-counter/
$('#project_description').live('keyup keydown', function(e) {
  var maxLen = 1500;
  var left = maxLen - $(this).val().length;
  $('#char-count').html(left);
});
$('#person_about').live('keyup keydown', function(e) {
  var maxLen = 1000;
  var left = maxLen - $(this).val().length;
  $('#char-count').html(left);
});