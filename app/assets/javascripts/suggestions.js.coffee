# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on "page:change", ->
  $('.voteBtn').click (event) ->
    snackId = (this.id)
    $.ajax 'suggestions/vote' , 
      type: "GET",
      dataType: "JSON",
      data: 
        snackRefId: snackId
      asnyc: false,
      success: (data) ->
        console.log(data.votes)
        console.log('#lblvote_'+snackId)
        $('#lblvote_'+snackId).text(data.votes)
