--[[----------------------------------------------------------------------------
                            Gemini Automod - Spanish Gemini
----------------------------------------------------------------------------]]--

local GeminiPhrases = {
    ["BlockReason.BLOCK_REASON_UNSPECIFIED"] = "La peticion ha sido bloqueada por una razon no especificada.",
    ["BlockReason.SAFETY"] = "La peticion ha sido bloqueada por razones de seguridad.",
    ["BlockReason.OTHER"] = "La peticion ha sido bloqueada por una razon desconocida.",

    ["FinishReason.FINISH_REASON_UNSPECIFIED"] = "La peticion ha sido bloqueada por una razon no especificada.",
    ["FinishReason.MAX_TOKENS"] = "La cantidad maxima de tokens especificada en la peticion ha sido alcanzada.",
    ["FinishReason.RECITATION"] = "La peticion ha sido bloqueada por motivos de recitación.",
    ["FinishReason.SAFETY"] = "La peticion ha sido bloqueada por los filtros seguridad.",
    ["FinishReason.STOP"] = "Punto de parada natural del modelo o secuencia de parada proporcionada.",
    ["FinishReason.OTHER"] = "La peticion ha sido bloqueada por razones desconocidas.",

    ["SafetySetting.BLOCK_NONE"] = "Mostrar siempre el contenido.",
    ["SafetySetting.BLOCK_ONLY_HIGH"] = "Bloquear cuando haya alto riesgo de que el contenido sea inapropiado.",
    ["SafetySetting.BLOCK_MEDIUM_AND_ABOVE"] = "Bloquear cuando haya mediano y alto riesgo de que el contenido sea inapropiado.",
    ["SafetySetting.BLOCK_LOW_AND_ABOVE"] = "Bloquear cuando haya bajo, mediano y alto riesgo de que el contenido sea inapropiado.",

    ["Gemini.Requested"] = "Se ha realizado la petición a Gemini.",
    ["Gemini.Error"] = "Fallo al realizar la petición a Gemini.",
    ["Gemini.Error.Reason"] = "No se pudo realizar la petición a Gemini. Razón: %s",
    ["Gemini.Error.NoPermission"] = "No tienes permisos para realizar esta acción.",
    ["Gemini.Error.Failed"] = "No se pudo realizar la peticion a Gemini: %s",
    ["Gemini.Error.FailedRequest"] = "La peticion tuvo un error en el proceso.",
    ["Gemini.Error.TooBig"] = "El tamaño de la respuesta es demasiado grande para ser enviado al cliente.",
    ["Gemini.Error.Blocked"] = "La peticion fue bloqueada por el Gemini, verifica la configuracion de seguridad.",
    ["Gemini.Error.Safety"] = "La peticion fue bloqueada por el sistema de seguridad de Gemini.",
    ["Gemini.Error.ServerError"] = "Error en el servidor de Gemini, espera un momento e intenta de nuevo.",
    ["Gemini.Error.RateLimit"] = "Se ha alcanzado el limite de peticiones a Gemini, espera un momento e intenta de nuevo.",

    ["Gemini.NoLogs"] = "No hay registros para mostrar.",
}

return GeminiPhrases