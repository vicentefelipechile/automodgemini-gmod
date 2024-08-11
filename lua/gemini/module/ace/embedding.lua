return [[
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>ACE in Action</title>
        <style type="text/css" media="screen">
            #editor { 
                position: absolute;
                top: 0;
                right: 0;
                bottom: 0;
                left: 0;
            }
        </style>

        <meta charset="utf-8">
    </head>
    <body style="background-color: #232323;">
        <script type="text/javascript"> $AceScript$ </script>
        <script type="text/javascript"> $Extension$ </script>
        <script type="text/javascript"> $Theme$ </script>
        <script type="text/javascript"> $Mode$ </script>
        
        <div id="editor">$InitialValue$</div>
        
        <script>
            var editor = ace.edit("editor")
            let editorcontentenabled = true
            
            editor.setTheme("ace/theme/monokai")
            editor.session.setMode("ace/mode/markdown")
            
            editor.setOptions({
                readOnly: $ReadOnly$,
                enableBasicAutocompletion: true,
                enableLiveAutocompletion: true,
                wrap: true
            })
            
            function SetEditorContent(content) {
                // get the current position
                const pos = editor.session.selection.toJSON()

                editor.setValue(content)

                // set the position
                editor.session.selection.fromJSON(pos)
            }

            function TriggerEditorContent() {
                const content = editor.getValue()
                gmod.TriggerEditorContent(content)
            }

            // On change event
            editor.on("change", function() {
                if (!editorcontentenabled) {return};
                gmod.EditorTextChanged(editor.getValue())
            })
        </script>

        <script type="text/javascript"> $GmodScript$ </script>
        <script type="text/javascript">
            function SetEditorOption(Option, Value) {
                editor.setOption(Option, Value)
            }

            function GetEditorContent(toIndex) {
                gmod.SetContentTextTable(toIndex, editor.getValue())
            }
        </script>
    </body>
</html>
]]