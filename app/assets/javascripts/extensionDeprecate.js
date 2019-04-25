$(document).on('opened', '[data-reveal]', function () {
  var settings =  {
    placeholder: 'Search for an asset',
    minimumInputLength: 3,
    width: '100%',
    ajax: {
      url: function () {
        return $(this).data('url');
      },
      dataType: 'json',
      quietMillis: 200,
      data: function (term, page) {
        return { q: term };
      },
      results: function (data, page) {
        return { results: data.items };
      },
    },
    id: function(object) {
      return [object.extension_owner, object.extension_name];
    },
    formatSelection: function(object, container) {
      return [object.extension_owner, object.extension_name].join('/');
    },
    formatResult: function(object, container) {
      return [object.extension_owner, object.extension_name].join('/');
    }
  }

  $('.extension-deprecate').select2(settings);

  $('.extension-deprecate').on("select2-selecting", function(e) {
    $('.submit-deprecation').prop('disabled', false);
  });
});
