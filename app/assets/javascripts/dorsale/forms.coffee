$(document).on "ready page:load", ->
  $("button.reset").click ->
    form = $(this).parents("form")

    form.find("select option:first-child").map ->
      this.selected = true

    form.find("input").map ->
      return if this.type.match(/submit|hidden|button/)
      this.value = $(this).data("default-value") || ""

    form.find("textarea").map ->
      this.value = $(this).data("default-value") || ""

    form.find("select").map ->
      this.selectize.clear() if this.selectize

  # Referer with anchor
  $("form").submit ->
    return if this.method.toUpperCase() == "GET"
    return if $(this).find("[name=back_url]").length > 0

    input       = document.createElement("input")
    input.type  = "hidden"
    input.name  = "back_url"
    input.value = location.href
    $(this).append(input)

  # Fake file input (bootstrap style)
  $(".form-group.upload").map ->
    $(this).find("label").map ->
      this.dataset.defaultValue = $(this).html()

    $(this).find("input").change ->
      if this.value != ""
        $(this).parents(".upload").find("label").html(this.value)
      else
        $(this).parents(".upload").find("label").map ->
          $(this).html(this.dataset.defaultValue)
