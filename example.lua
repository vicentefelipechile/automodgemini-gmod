{
    contents = {
        {
            parts = {
                {
                    text = "Eres un modelo de lenguaje que se encarga de que los jugadores no rompan las reglas del servidor de DarkRP, tu objetivo es analizar los eventos que ocurrieron con el jugador involucrado, luego debes dar un veredicto en base a los eventos observados.Los posibles veredictos son:- Culpable: Cuando el jugador es culpable de romper una o mas reglas del DarkRP- Inocente: El jugador no rompio ninguna regla del DarkRP- Sin veredicto: Los eventos mostrados son pocos o no tienen correlacion alguna"
                },
                {
                    text = [[input: Jugador - El jugador "LeagueForever" mato a "RocketForest" con el arma "AK-47" (weapon_ak47) a las 19:40:03
- El jugador "LeagueForever" respawneo a las 19:40:13
- El jugador "RocketForest" compro un arma "M4A1" (weapon_m4a1) a las 19:41:05
- El jugador "RocketForest" disparo el arma "AK-47" (weapon_ak47) a las 19:41:56
- El jugador "RocketForest" mato a "LeagueForever" con el arma "M4A1" a las 19:42:13]]
                },
                {
                    text = [[output: Veredicto Veredicto: Culpable
Razon: El jugador ha roto la regla de RDM y NLR]]
                },
                {
                    text = [[input: Jugador - El jugador "Jose" mato a "Martin" con el arma "USP" (weapon_usp) a las 07:43:40
  - El jugador "Martin" respawneo a las 07:43:57
  - El jugador "Martin" compro una puerta por "$200" a las 07:45:31
  - El jugador "Martin" compro una puerta por "$200" a las 07:45:33
  - El jugador "Martin" compro una puerta por "$200" a las 07:45:47
  - El jugador "Martin" compro un paquete de armas "AK-47" (weapon_ak47) a las 07:47:40
  - El jugador "Martin" recibio "$30.000" de "Jose" a las 07:52:03
  - El jugador "Jose" mato a "Martin" con el arma "AK-47" a las 07:52:09]]
                },
                {
                    text = [[output: Veredicto Veredicto: Inocente
Razon: El jugador "Jose" ha matado a "Martin" sin razon aparente, rompe la regla de RDM
Informacion extra: El jugador "Martin" solo compro una casa y abrio una armeria]]
                },
                {
                    text = [[input: Jugador - El jugador "Macpato" recibio "$40.000" de "Milky Crowley" a las 21:51:34
- El jugador "Milky Crowley" recogio el arma "AK-47" (weapon_ak47) del suelo 21:51:42
- El jugador "Milky Crowley" mato a "Macpato" con el arma "AK-47" (weapon_ak47) a las 21:51:44]]
      }, {
        text = "output: Veredicto Veredicto: Sin veredicto
  
  Razon: No se encuentra suficiente informacion para dar un veredicto"
      }, {
        text = "input: Jugador - El jugador "vicentefelipechile" respawneo a las 16:30:21
  - El jugador "Ghost" mato a "vicentefelipechile" con el arma "Minigun" (weapon_minigun) a las 16:35:24
  - El jugador "vicentefelipechile" respawneo a las 16:35:35
  - El jugador "Armando" recibio "$40.000" de "vicentefelipechile" a las 16:37:14
  - El jugador "vicentefelipechile" recogio el arma "Minigun" (weapon_minigun) del suelo a las 16:37:18
  - El jugador "vicentefelipechile" mato a "Ghost" a las 16:38:10"
      }, {
        text = "output: Veredicto Veredicto: Culpable
  
  Razon: El jugador ha roto las reglas de NLR y RDM al intentar vengarze"
      }, {
        text = "input: Jugador - El jugador "Macpato" recibio "$40.000" de "Milky Crowley" a las 21:51:34
  - El jugador "Milky Crowley" recogio el arma "AK-47" (weapon_ak47) del suelo 21:51:42
  - El jugador "Milky Crowley" mato a "Macpato" a las 21:51:44"
      }, {
        text = "output: Veredicto Veredicto: Culpable
  
  Razon: El jugador ha roto la regla de RDM al matar a "Macpato" sin razon aparente"
      }, {
        text = "input: Jugador - El jugador "Suprem" ha respawneado a las 23:40:21
  - El jugador "Suprem" compro una puerta por "$200" a las 23:44:35
  - El jugador "Suprem" compro una puerta por "$200" a las 23:44:37
  - El jugador "Suprem" compro una puerta por "$200" a las 23:45:03
  - El jugador "Suprem" compro una puerta por "$200" a las 23:44:07"
      }, {
        text = "output: Veredicto Veredicto: Sin veredicto
  
  Razon: No se encuentra suficiente informacion para dar un veredicto
  
  Informacion extra: El jugador solo compro una casa"
      }, {
        text = "input: Jugador "
      }, {
        text = "output: Veredicto "
      } }
    } },
    generationConfig = {
      temperature = 0.9,
      topK = 1,
      topP = 1,
      maxOutputTokens = 2048,
      stopSequences = { }
    },
    safetySettings = {
        {
            category = "HARM_CATEGORY_HARASSMENT",
            threshold = "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
            category = "HARM_CATEGORY_HATE_SPEECH",
            threshold = "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
            category = "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            threshold = "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
            category = "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold = "BLOCK_MEDIUM_AND_ABOVE"
        }
    }
  }