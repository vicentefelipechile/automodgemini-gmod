return [==[
const AceEditor = ace.edit("editor")
var gmod = gmod || {}

gmod.Copy = () => {
    const ranges = AceEditor.selection.getAllRanges()
    let AllText = ""

    for (let i = 0; i < ranges.length; i++) {
        AllText += AceEditor.session.getTextRange(ranges[i]) + "\n"
    }

    const FormatedText = AllText.substring(0, AllText.length - 1)
    gmod.SetClipboardText(FormatedText)
}

gmod.Cut = () => {
    gmod.Copy()
    AceEditor.session.replace(AceEditor.getSelectionRange(), "")
}

gmod.SaveServerInfoJS = () => {
    const Text = AceEditor.getValue()

    gmod.SaveServerInfoLua(Text)
}

gmod.SaveServerRulesJS = () => {
    const Text = AceEditor.getValue()

    gmod.SaveServerRulesLua(Text)
}

// Check if the function exists
if (typeof gmod.InfoFullyLoaded === "function") {
    gmod.InfoFullyLoaded()
}

if (typeof gmod.RulesFullyLoaded === "function") {
    gmod.RulesFullyLoaded()
}

]==]