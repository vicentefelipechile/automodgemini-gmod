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
    <body>
        <script type="text/javascript"> $AceScript$ </script>
        <script type="text/javascript"> $Extension$ </script>
        <script type="text/javascript"> $Theme$ </script>
        <script type="text/javascript"> $Mode$ </script>
        <script type="text/javascript"> $Snippets$ </script>
        
        <div id="editor">$InitialValue$</div>
        
        <script>
            var editor = ace.edit("editor")
            
            editor.setTheme("ace/theme/monokai")
            editor.session.setMode("ace/mode/markdown")
            
            editor.setOptions({
                readOnly: $ReadOnly$,
                enableBasicAutocompletion: true,
                enableLiveAutocompletion: true,
                enableSnippets: true,
                wrap: true
            })
        </script>

        <script type="text/javascript"> $GmodScript$ </script>
    </body>
</html>
]]