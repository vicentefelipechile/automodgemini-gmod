--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Google Cloud Module
----------------------------------------------------------------------------]]--

local EndPointString = "https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/%s:streamGenerateContent"

--[[------------------------
     Google Cloud Zones
------------------------]]--

local GCLOUD_ZONES = {
    ["africa-south1"] = "Johannesburg, South Africa",
    ["asia-east1"] = "Changhua County, Taiwan, APAC",
    ["asia-east2"] = "Hong Kong, APAC",
    ["asia-northeast1"] = "Tokyo, Japan, APAC",
    ["asia-northeast2"] = "Osaka, Japan, APAC",
    ["asia-northeast3"] = "Seoul, South Korea, APAC",
    ["asia-south1"] = "Mumbai, India, APAC",
    ["asia-southeast1"] = "Jurong West, Singapore, APAC",
    ["asia-southeast2"] = "Jakarta, Indonesia, APAC",
    ["australia-southeast1"] = "Sydney, Australia, APAC",
    ["australia-southeast2"] = "Melbourne, Australia, APAC",
    ["europe-central2"] = "Warsaw, Poland, Europe",
    ["europe-north1"] = "Hamina, Finland, Europe",
    ["europe-southwest1"] = "Madrid, Spain, Europe",
    ["europe-west1"] = "St. Ghislain, Belgium, Europe",
    ["europe-west2"] = "London, England, Europe",
    ["europe-west3"] = "Frankfurt, Germany, Europe",
    ["europe-west4"] = "Eemshaven, Netherlands, Europe",
    ["europe-west6"] = "Zurich, Switzerland, Europe",
    ["europe-west8"] = "Milan, Italy, Europe",
    ["europe-west9"] = "Paris, France, Europe",
    ["europe-west12"] = "Turin, Italy, Europe",
    ["me-central1"] = "Doha, Qatar, Middle East",
    ["me-central2"] = "Dammam, Saudi Arabia, Middle East",
    ["me-west1"] = "Tel Aviv, Israel, Middle East",
    ["northamerica-northeast1"] = "Montréal, Québec, North America",
    ["northamerica-northeast2"] = "Toronto, Ontario, North America",
    ["southamerica-east1"] = "Osasco, São Paulo, Brazil, South America",
    ["southamerica-west1"] = "Santiago, Chile, South America",
    ["us-central1"] = "Council Bluffs, Iowa, North America",
    ["us-east1"] = "Moncks Corner, South Carolina, North America",
    ["us-east4"] = "Ashburn, Virginia, North America",
    ["us-east5"] = "Columbus, Ohio, North America",
    ["us-south1"] = "Dallas, Texas, North America",
    ["us-west1"] = "The Dalles, Oregon, North America",
    ["us-west2"] = "Los Angeles, California, North America",
    ["us-west3"] = "Salt Lake City, Utah, North America",
    ["us-west4"] = "Las Vegas, Nevada, North America",
}

local function IsAvailableZone(zone)
    return GCLOUD_ZONES[zone] ~= nil
end

--[[------------------------
        Configuration
------------------------]]--

Gemini:CreateConfig("LocationID", "GoogleCloud", IsAvailableZone, "us-central1", true)
Gemini:CreateConfig("ProjectID", "GoogleCloud", Gemini.VERIFICATION_TYPE.string, "YOUR_PROJECT_ID", true)
Gemini:CreateConfig("ModelID", "GoogleCloud", Gemini.VERIFICATION_TYPE.string, "YOUR_MODEL_ID", true)

--[[------------------------
       Main Functions
------------------------]]--

function Gemini:CloudGetEndPoint()
    return string.format(
        EndPointString,
        self:GetConfig("LocationID"),
        self:GetConfig("ProjectID"),
        self:GetConfig("LocationID"),
        self:GetConfig("ModelID")
    )
end