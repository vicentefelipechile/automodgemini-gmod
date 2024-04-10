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
    </head>
    <body>
        <script type="text/javascript">%s</script>
        <script type="text/javascript">%s</script>
        <script type="text/javascript">%s</script>
        <script type="text/javascript">%s</script>
        <script type="text/javascript">%s</script>

        <div id="editor">%s</div>

        <script>
            var editor = ace.edit("editor");
            editor.setTheme("ace/theme/monokai");
            editor.session.setMode("ace/mode/markdown");
        </script>
    </body>
</html>
]]