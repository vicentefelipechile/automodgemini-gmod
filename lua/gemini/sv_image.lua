--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Image Module
----------------------------------------------------------------------------]]--

local ThirdParty = {
    ["url"] = "https://gcp.imagy.app/screenshot/createscreenshot",
    ["method"] = "POST",
    ["allowed_content"] = {
        ["image/png"] = true,
        ["image/jpeg"] = true,
    },
    ["error_index"] = "error",
    ["success_index"] = "fileUrl",
}

local PlayerRegEx = "^7656[0-9]{13,14}$"
-- 76561198969901383

--[[------------------------
       Util Functions
------------------------]]--

function Gemini:DownloadURL(url, filename)
    if not filename then
        filename = string.GetFileFromFilename(url)

        if not filename then
            self:Error("The first argument of Gemini:DownloadURL() must be a valid URL.", url, "string")
        end
    end

    local promise = Promise()
    HTTP({
        url = url,
        method = "GET",
        success = function(Code, Body, Headers)
            self:GetHTTPDescription(Code)

            local ContentType = Headers["Content-Type"]
            if ( ThirdParty["allowed_content"][ContentType] == nil ) then
                promise:Reject("The content type of the file is not allowed.", ContentType, "string")
                return
            end

            if Code == 200 then
                file.Write("gemini/images/" .. filename, Body)
                promise:Resolve(Body)
            end
        end,
        failed = function(reason)
            promise:Reject("The request to the third party service failed.", reason, "string")
        end
    })

    return promise
end

--[[------------------------
       Main Functions
------------------------]]--

function Gemini:ImagePoblate()
    file.CreateDir("gemini/images")
end

function Gemini:TakeScreenshotOfPlayer(ply)
    if isnumber(ply) then
        ply = tostring( ply )
    end

    if isstring(ply) then
        if not string.StartsWith(ply, "7656") then
            self:Error("The first argument of Gemini:TakeScreenshotOfPlayer() must be a valid SteamID64.", ply, "string")
        end
    else
        if not IsValid(ply) then
            self:Error("The first argument of Gemini:TakeScreenshotOfPlayer() must be a valid player.", ply, "player")
        elseif not ply:IsPlayer() then
            self:Error("The first argument of Gemini:TakeScreenshotOfPlayer() must be a player.", ply, "player")
        end
    end

    local PlayerSteamID64 = isstring(ply) and ply or ply:SteamID64()

    local PlayerURL = "https://steamcommunity.com/profiles/" .. PlayerSteamID64
    local Body = {
        ["url"] = PlayerURL,
        ["browserWidth"] = 1280,
        ["browserHeight"] = 700,
        ["fullPage"] = false,
        ["deviceScaleFactor"] = 1,
        ["format"] = "jpg",
    }

    local Headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
        ["User-Agent"] = "Garry's Mod Application (v1.0)"
    }

    HTTP({
        url = ThirdParty["url"],
        method = ThirdParty["method"],
        headers = Headers,
        type = "application/json",
        body = util.TableToJSON(Body),
        success = function(Code, BodyJSON, ResponseHeaders)
            self:GetHTTPDescription(Code)
            if ( Code >= 500 ) then return end

            local BodyResponse = util.JSONToTable(BodyJSON)

            if Code ~= 200 then
                local ErrorMessage = BodyResponse[ThirdParty["error_index"]]
                if not ErrorMessage then
                    self:Print("There was an error with the third party service. Error: No error message was provided.")
                else
                    self:Print("There was an error with the third party service. Error: " .. ErrorMessage)
                end

                return
            end

            local ImageURL = BodyResponse[ThirdParty["success_index"]]
            if not ImageURL then
                self:Print("The third party service did not return a valid image URL.", ImageURL, "string")
                return
            end

            local NewPromise = self:DownloadURL(ImageURL, PlayerSteamID64 .. ".jpg")
            NewPromise:Then(function(ImageData)
                -- Convert the image data into base64 and then compress it into "gemini/images/PLAYER.txt"
                local Base64Data = "data:image/jpg;base64," .. util.Base64Encode(ImageData)
                file.Write("gemini/images/" .. PlayerSteamID64 .. ".txt", Base64Data)

                local DataCompressed = util.Compress(Base64Data)
                file.Write("gemini/images/" .. PlayerSteamID64 .. "_compress.txt", DataCompressed)
            end):Catch(function(reason)
                self:Print("The request to the third party service failed.", reason)
            end)
        end,
        failed = function(reason)
            self:Error("The request to the third party service failed.", reason, "string")
        end
    })
end

concommand.Add("gemini_testimage", function(ply)
    Gemini:TakeScreenshotOfPlayer("76561198969901383")
end)