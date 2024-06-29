--[[----------------------------------------------------------------------------
                Gemini Automod - Spanish Prompts
----------------------------------------------------------------------------]]--

local PromptTable = PromptTable or { ["gamemodes"] = {} }
local PromptFunctions = PromptFunctions or {}

--[[------------------------
    Prompt Template
------------------------]]--

PromptTable["template"] = [[Eres un modelo de lenguaje dedicado al modo de juego Garry's Mod a continuación se te mostrara el contexto que debes saber para tener una conversación con el usuario.
# Actual modo de juego: $GAMEMODE$

## Descripcion:
$DESCRIPTION$

## Objetivo:
$OBJECTIVE$

## Comportamiento de los jugadores:
$BEHAVIOR$

## Reglas del modo de juego:
$GAMEMODE_RULES$

## Mecanicas Conocidas:
$MECHANICS$

## Mapas/Entornos:
$GAMEMODE_MAPS$

# Reglas e Informacion del Servidor:
Las siguientes reglas no forman parte del modo de juego, sino que son parte del servidor en donde estas siendo ejecutado, las reglas son las siguientes:
```
$ALL_SERVER_INFO$

$ALL_SERVER_RULES$
```

# Registros del juego
$LOGS$

# Respuesta
Antes de responder al usuario, debes tomar en cuenta estos criterios:
$RESPONSE$

Despues de este texto estar el mensaje del usuario:
$USER_PROMPT$]]

--[[------------------------
   Gamemodes Descriptions
------------------------]]--

PromptTable["gamemodes"]["default"] = {
    ["GAMEMODE"] = "Ningún Modo de Juego Conocido",
    ["DESCRIPTION"] = [[El siguiente modo de juego no tiene ningun objetivo conocido, por lo que es recomendable aplicar las reglas y descripciones del modo de juego Sandbox.
El modo de juego Sandbox es un modo de juego donde los jugadores pueden hacer lo que quieran, como construir, pelear, usar armas, usar herramientas, usar entidades y vehiculos, entre otras cosas. Este modo de juego se resume en una caja de arena donde los jugadores pueden hacer lo que quieran, siempre y cuando no rompan las reglas establecidas por el servidor o por el administrador del servidor.]],
    ["OBJECTIVE"] = [[No hay ningun objetivo conocido, por lo que se recomienda aplicar las reglas y descripciones del modo de juego Sandbox.]],
    ["BEHAVIOR"] = [[El comportamiento de los jugadores no esta establecido, por lo que se asumira que los jugadores pueden hacer lo que quieran, siempre y cuando no rompan las reglas establecidas por el propio servidor.]],
    ["GAMEMODE_RULES"] = {
        "Las unicas reglas conocidas son las reglas establecidas por el servidor, por lo que se recomienda seguir las reglas establecidas por el servidor o por el administrador del servidor.",
    },
    ["MECHANICS"] = {
        "Construcción de estructuras",
        "Peleas entre jugadores",
        "Uso de armas y herramientas",
        "Uso de entidades y vehiculos"
    },
    ["GAMEMODE_MAPS"] = [[El entorno o los mapas seleccionados por este modo de juego no tienen un objetivo conocido, por lo que se asumira los mapas como entornos de construcción (Con lugares abiertos o cerrados) o peleas entre jugadores.]],
}

PromptTable["gamemodes"]["sandbox"] = {
    ["GAMEMODE"] = "Sandbox",
    ["DESCRIPTION"] = [[El modo de juego Sandbox es un modo de juego donde los jugadores pueden hacer lo que quieran, como construir, pelear, usar armas, usar herramientas, usar entidades y vehiculos, entre otras cosas. Este modo de juego se resume en una caja de arena donde los jugadores pueden hacer lo que quieran, siempre y cuando no rompan las reglas establecidas por el servidor o por el administrador del servidor.]],
    ["OBJECTIVE"] = [[El Sandbox no tiene ningun objetivo, los jugadores solo haran lo que quieran como construir o matarse entre si.]],
    ["BEHAVIOR"] = [[El comportamiento de los jugadores cambia dependiendo de la situacion, por ejemplo si los jugadores desean construir, estos se comportaran de manera pacifica, pero si los jugadores desean pelear, estos se comportaran de manera agresiva.]],
    ["GAMEMODE_RULES"] = {
        "Las reglas del Sandbox son establecidas por el servidor o por el administrador del servidor, por lo que se recomienda seguir las reglas establecidas por el servidor o por el administrador del servidor.",
    },
    ["MECHANICS"] = {
        "Construcción de estructuras",
        "Peleas entre jugadores",
        "Uso de armas y herramientas",
        "Uso de entidades y vehiculos",
        "Noclip (Volar por el mapa)"
    },
    ["GAMEMODE_MAPS"] = [[El entorno o los mapas seleccionados son por lo general de mundo abierto o tambien son estructuras diseñadas para explorar y construir. La mayoría de estos mapas tienen una estetica como una ciudad, un campo de pasto verde o incluso lugares abstractos.]],
}

PromptTable["gamemodes"]["darkrp"] = {
    ["GAMEMODE"] = "DarkRP",
    ["DESCRIPTION"] = [[DarkRP es un modo de juego basado en el modo de juego Sandbox, pero con la diferencia de que este modo de juego tiene un sistema de economia, trabajos, salarios, entre otras cosas. Este modo de juego es muy popular en Garry's Mod, ya que es un modo de juego que simula la vida real, por lo que los jugadores pueden simular tener una vida y dentro del contexto de que estan en un roleplay.]],
    ["OBJECTIVE"] = [[El objetivo de DarkRP es simular una vida real, por lo que los jugadores pueden hacer lo que quieran, pero siempre y cuando esten dentro del contexto de que estan en un roleplay.]],
    ["BEHAVIOR"] = [[El comportamiento de los jugadores depende del trabajo que tengan, por ejemplo si un jugador es policia, este se enfocara de buscar criminales o mantener el orden, pero si un jugador es un criminal, este se enfocara en robar casas o propiedades, tambien existen los trabajos civiles, que estos se enfocaran en trabajar para ganar dinero.]],
    ["GAMEMODE_RULES"] = {
        "RDM (Random Deathmatch): Matar a alguien sin razon alguna.",
        "NLR (New Life Rule): Esta regla es algo compleja, pero se resume en que si un jugador muere, este tiene que olvidar todo lo que paso antes de morir, por ejemplo si le han robado la casa, no puede volver inmediatamente o durante el robo.",
        "FailRP: Hacer algo que no tiene sentido o que no esta dentro del contexto de que estan en un roleplay, como un policia robando a un civil.",
        "Y tambien existen reglas establecidas por el servidor o por el administrador del servidor, por lo que se recomienda seguir las reglas establecidas por el servidor o por el administrador del servidor.",
    },
    ["MECHANICS"] = {
        "Casas y propiedades, se pueden comprar apuntando a una puerta y presionando la tecla 'F2'",
        "Trabajos y salarios, al escoger un trabajo, este te dara un salario cada cierto tiempo",
        "Sistema de economia, en este mundo existe el dinero, para ganar dinero, se puede trabajar o robar",
        "Policias y criminales, los policias pueden arrestar a los criminales y los criminales pueden robar casas y propiedades",
        "Vehiculos y entidades, algunos servidores permiten comprar vehiculos o entidades para moverse por el mapa",
        "Robo de casas y propiedades, los criminales pueden robar casas y propiedades, pero si un policia los ve, este puede arrestarlos"
    },
    ["GAMEMODE_MAPS"] = [[Los mapas preferiblemente son de ciudades o lugares urbanos, ya que estos mapas son los mas adecuados para simular una vida real. Los mapas pueden tener casas, tiendas, calles, estaciones policiales, entre otras cosas.]],
}

local ResponseCriteria = {
    "Evita respuestas extensas y solo responde de manera corta y precisa",
    "Si el usuario desea mas información, responderás de manera extensa",
    "Si el usuario te habla en otro idioma que no sea el español, responde en el idioma que te hablo el usuario",
    "No uses emojis",
    "Evita hacer resumenes despues del texto, por ejemplo \"En resumen...\" o \"Es importante saber...\" o \"Hay que aclarar que...\"",
}

--[[------------------------
    Prompt Functions
------------------------]]--

local function TableToList(Table)
    local List = ""
    for _, Value in ipairs(Table) do
        List = List .. "\n- " .. Value
    end
    return List
end

function PromptFunctions.GetResponseCriteria()
    return ResponseCriteria
end

function PromptFunctions.SetResponseCriteria(Criteria)
    if not istable(Criteria) then
        Gemini:Error("The first argument of PromptFunctions.SetResponseCriteria must be a table.", Criteria, "table")
    elseif ( #Criteria == 0 ) then
        Gemini:Error("The first argument of PromptFunctions.SetResponseCriteria must not be an empty table.", Criteria, "table")
    elseif not table.IsSequential(Criteria) then
        Gemini:Error("The first argument of PromptFunctions.SetResponseCriteria must be a sequential table.", Criteria, "table")
    end

    ResponseCriteria = Criteria
end

function PromptFunctions.GeneratePrompt(ServerInfo, ServerRules, UserMessage, Logs, Gamemode)
    if not isstring(ServerInfo) then
        Gemini:Error("The first argument of PromptFunctions.GeneratePrompt must be a string.", ServerInfo, "string")
    elseif ( #ServerInfo == 0 ) then
        Gemini:Error("The first argument of PromptFunctions.GeneratePrompt must not be an empty string.", ServerInfo, "string")
    end

    if not isstring(ServerRules) then
        Gemini:Error("The second argument of PromptFunctions.GeneratePrompt must be a string.", ServerRules, "string")
    elseif ( #ServerRules == 0 ) then
        Gemini:Error("The second argument of PromptFunctions.GeneratePrompt must not be an empty string.", ServerRules, "string")
    end

    local Prompt = PromptTable["template"]
    local GamemodePrompt = PromptTable["gamemodes"][Gamemode or engine.ActiveGamemode()] or PromptTable["gamemodes"]["default"]

    Prompt = Prompt:gsub("%$GAMEMODE%$", GamemodePrompt["GAMEMODE"])
    Prompt = Prompt:gsub("%$DESCRIPTION%$", GamemodePrompt["DESCRIPTION"])
    Prompt = Prompt:gsub("%$OBJECTIVE%$", GamemodePrompt["OBJECTIVE"])
    Prompt = Prompt:gsub("%$BEHAVIOR%$", GamemodePrompt["BEHAVIOR"])
    Prompt = Prompt:gsub("%$GAMEMODE_RULES%$", TableToList(GamemodePrompt["GAMEMODE_RULES"]))
    Prompt = Prompt:gsub("%$MECHANICS%$", TableToList(GamemodePrompt["MECHANICS"]))
    Prompt = Prompt:gsub("%$GAMEMODE_MAPS%$", GamemodePrompt["GAMEMODE_MAPS"])

    Prompt = Prompt:gsub("%$ALL_SERVER_INFO%$", ServerInfo)
    Prompt = Prompt:gsub("%$ALL_SERVER_RULES%$", ServerRules)
    Prompt = Prompt:gsub("%$RESPONSE%$", TableToList(ResponseCriteria))

    -- In case we only need the prompt
    if ( UserMessage == nil and Logs == nil ) then
        return Prompt
    end

    if not isstring(UserMessage) then
        Gemini:Error("The fourth argument of PromptFunctions.GeneratePrompt must be a string.", UserMessage, "string")
    elseif ( #UserMessage == 0 ) then
        Gemini:Error("The fourth argument of PromptFunctions.GeneratePrompt must not be an empty string.", UserMessage, "string")
    end

    Prompt = Prompt:gsub("%$LOGS%$", Logs or "No hay registros para mostrar.")
    Prompt = Prompt:gsub("%$USER_PROMPT%$", UserMessage)

    return Prompt
end

return PromptFunctions