
# These only works from jonasfj.github.com/realtime-codemirror-example/
APPID    = "908797014622"
CLIENTID = "908797014622-31tl0h44jidpu71ficem41rudn0uqp6l.apps.googleusercontent.com"

# These only works from localhost:3335
#APPID    = "908797014622"
#CLIENTID = '908797014622.apps.googleusercontent.com'

_client = null
_editor = null
$ ->
  _editor = CodeMirror document.getElementById("editor"),
    mode:           "gfm"
    lineNumbers:    true
    lineWrapping:   true
    readOnly:       true
  _editor.setValue("")
  _editor.setSize("100%", "400")
  
  _client = new rtclient.RealtimeLoader
    appId:                  APPID
    clientId:               CLIENTID
    authButtonElementId:    'btn-auth'
    autoCreate:             false
    defaultTitle:           "New real-time code-mirror session"
    initializeModel:        initializeModel
    onFileLoaded:           loadModel
  
  # Create button click
  $('#btn-create').click ->
    return      if $('#btn-create').hasClass 'disabled'
    $('#btn-create').addClass 'disabled'
    $('#btn-open').addClass 'disabled'
    $('#btn-share').addClass 'disabled'
    _client.createNewFileAndRedirect()
    
  # Open button click
  $('#btn-open').click ->
    return      if $('#btn-open').hasClass 'disabled'
    $('#btn-auth').addClass 'disabled'
    $('#btn-create').addClass 'disabled'
    $('#btn-open').addClass 'disabled'
    $('#btn-share').addClass 'disabled'
    google.load 'picker', '1', callback: ->
      token = gapi.auth.getToken().access_token
      view = new google.picker.View(google.picker.ViewId.DOCS)
      view.setMimeTypes("application/vnd.google-apps.drive-sdk." + APPID)
      picker = new google.picker.PickerBuilder()
        .enableFeature(google.picker.Feature.NAV_HIDDEN)
        .setAppId(APPID)
        .setOAuthToken(token)
        .addView(view)
        .addView(new google.picker.DocsUploadView())
        .setCallback(openCallback)
        .build()
      picker.setVisible(true)
  
  # Share button click
  $('#btn-share').click ->
    return      if $('#btn-share').hasClass 'disabled'
    alert("Share doesn't work without HTTPS, just used drive.google.com to change share settings!")
    #s = new gapi.drive.share.ShareClient(APPID)
    #s.setItemIds([rtclient.params['fileId']])
    #s.showSettingsDialog()

  # Try for auto authentication, or wait for user to click authenticate
  $('#btn-auth').removeClass 'disabled'
  _client.start ->
    $('#btn-auth').addClass 'disabled'
    $('#btn-create').removeClass 'disabled'
    $('#btn-open').removeClass 'disabled'

openCallback = (data) ->
  if data.action is google.picker.Action.PICKED
    fileId = data.docs[0].id
    rtclient.redirectTo(fileId, _client.authorizer.userId)

# Initialize model
initializeModel = (model) ->
  markdown = model.createString('Hello Realtime World!\n=====================\n');
  model.getRoot().set('markdown', markdown);

# Load model
_markdown = null
loadModel = (doc) ->
  # Get file name, update it whenever it's changed
  gapi.client.load 'drive', 'v2', ->
    request = gapi.client.drive.files.get(fileId: rtclient.params['fileId'])
    $('#doc-name').attr('disabled', '');
    request.execute (resp) ->
      $('#doc-name').val resp.title
      $('#doc-name').removeAttr 'disabled'
      $('#doc-name').change ->
        $('#doc-name').attr('disabled', '')
        renameRequest = gapi.client.drive.files.patch
          fileId:   rtclient.params['fileId'],
          resource: 
            title:  $('#doc-name').val()
        renameRequest.execute (resp) ->
          $('#doc-name').val resp.title
          $('#doc-name').removeAttr 'disabled'
          
  # Enable share button
  $('#btn-share').removeClass 'disabled'
  
  # Get markdown collaborative string from root element
  _markdown = doc.getModel().getRoot().get('markdown')
  
  # Enable editing
  _editor.setOption('readOnly', false)
  _editor.setValue _markdown.getText()

  # Setup code synchronization
  synchronize(_editor, _markdown)

pos2str = ({line, ch}) -> line + ":" + ch

# Activate code synchronization
synchronize = (editor, markdown) ->
  ignore_change = false
  editor.on 'beforeChange', (editor, changeObj) ->
    return if ignore_change
    from  = editor.indexFromPos(changeObj.from)
    to    = editor.indexFromPos(changeObj.to)
    text  = changeObj.text.join('\n')
    if to - from > 0
      console.log "markdown.removeRange(#{from}, #{to})"
      markdown.removeRange(from, to)
    if text.length > 0
      console.log "markdown.insertString(#{from}, '#{text}')"
      markdown.insertString(from, text)
  markdown.addEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, (e) ->
    return if e.isLocal
    from  = editor.posFromIndex(e.index)
    ignore_change = true
    console.log "editor.replaceRange('#{e.text}', #{pos2str from}, #{pos2str from})"
    editor.replaceRange(e.text, from, from)
    ignore_change = false
  markdown.addEventListener gapi.drive.realtime.EventType.TEXT_DELETED, (e) ->
    return if e.isLocal
    from  = editor.posFromIndex(e.index)
    to    = editor.posFromIndex(e.index + e.text.length)
    ignore_change = true
    console.log "editor.replaceRange('', #{pos2str from}, #{pos2str to})"
    editor.replaceRange("", from, to)
    ignore_change = false


