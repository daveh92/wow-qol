print("|cff00ff00=== Whatsup masafaka? Camden Baby! ===|r")

local keywordInvite = "!inv"
local keywordLead = "!lead"

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("CHAT_MSG_PARTY")

SLASH_QOLHELP1 = "/qol"
SlashCmdList["QOLHELP"] = function()
    print("|cff00ff00=== AutoInvite Addon Befehlsübersicht ===|r")
    print("|cffccccccWhisper-/Party-Befehle (nur Freunde):|r")
    print("  !inv    - Einladung in die Gruppe")
    print("  !lead   - Übertrage Gruppenleiterrolle an Sender (wenn in Gruppe und du Leiter bist)")
    print("|cffccccccSlash-Befehle (ohne Freundeslisten-Beschränkung):|r")
    print("  /inv NAME    - Lade Spieler mit Namen NAME in die Gruppe ein")
    print("  /lead POS    - Übertrage Gruppenleiterrolle an Partymitglied an Position POS (0=du, 1-4 Gruppenmitglieder)")
    print("|cff00ff00==============================================|r")
end

local function IsFriendByName(name)
    for i = 1, C_FriendList.GetNumFriends() do
        local friendName = C_FriendList.GetFriendInfo(i)
        if friendName and Ambiguate(friendName, "none") == name then
            return true
        end
    end
    return false
end

local function TryInvite(name)
    -- Slash-Befehl lädt auch Spieler ein, die nicht in Freundesliste sind
    if not IsInGroup() then
        InviteUnit(name)
        print("|cff00ff00[AutoInvite]|r Lade " .. name .. " in die Gruppe ein.")
    else
        local num = GetNumGroupMembers()
        local maxGroupSize = IsInRaid() and 40 or 5
        if num < maxGroupSize then
            InviteUnit(name)
            print("|cff00ff00[AutoInvite]|r Lade " .. name .. " in die Gruppe ein.")
        else
            print("|cffff0000[AutoInvite]|r Gruppe ist voll, kann " .. name .. " nicht einladen.")
        end
    end
end

local function TryPromoteByName(name)
    if IsInGroup() and UnitIsGroupLeader("player") then
        if UnitInParty(name) or UnitInRaid(name) then
            PromoteToLeader(name)
            print("|cff00ff00[AutoInvite]|r " .. name .. " ist jetzt Gruppenleiter.")
        else
            print("|cffff0000[AutoInvite]|r " .. name .. " ist nicht in deiner Gruppe.")
        end
    else
        print("|cffff0000[AutoInvite]|r Du bist nicht Gruppenleiter.")
    end
end

local function TryPromoteByPartyIndex(index)
    if not IsInGroup() then
        print("|cffff0000[AutoInvite]|r Du bist in keiner Gruppe.")
        return
    end
    if not UnitIsGroupLeader("player") then
        print("|cffff0000[AutoInvite]|r Du bist nicht Gruppenleiter.")
        return
    end

    -- Party-Index von 1-4, 0 ist Spieler selbst, 5 ist z.B. keine echte Partyposition (außer Raid)
    -- In WoW ist Party-UnitID: "party1" bis "party4" (bis zu 5 Leute in Gruppe, Spieler ist "player")
    local unit = nil
    if index == 0 then
        unit = "player" -- du selbst
    elseif index >= 1 and index <= 4 then
        unit = "party"..index
    else
        print("|cffff0000[AutoInvite]|r Ungültige Partyposition. Nutze 0 bis 4.")
        return
    end

    if UnitExists(unit) then
        local name = UnitName(unit)
        PromoteToLeader(name)
        print("|cff00ff00[AutoInvite]|r " .. name .. " (Partyposition " .. index .. ") ist jetzt Gruppenleiter.")
    else
        print("|cffff0000[AutoInvite]|r An Position " .. index .. " ist kein Spieler in der Gruppe.")
    end
end

frame:SetScript("OnEvent", function(self, event, msg, sender)
    sender = Ambiguate(sender, "none")
    local msgLower = msg:lower()

    if not IsFriendByName(sender) then
        -- Nur bei Whisper & Party Nachrichten
        return
    end

    if msgLower == keywordInvite then
        TryInvite(sender)
        return
    end

    if msgLower == keywordLead then
        TryPromoteByName(sender)
        return
    end
end)

-- Slash Befehle registrieren
SLASH_AUTOINVITEINV1 = "/inv"
SlashCmdList["AUTOINVITEINV"] = function(msg)
    local name = msg:match("^(%S+)$")
    if name then
        TryInvite(name)
    else
        print("|cffffff00[AutoInvite]|r Benutze: /inv NAME")
    end
end

SLASH_AUTOINVITELEAD1 = "/lead"
SlashCmdList["AUTOINVITELEAD"] = function(msg)
    local index = tonumber(msg)
    if index then
        TryPromoteByPartyIndex(index)
    else
        print("|cffffff00[AutoInvite]|r Benutze: /lead POSITION (0-4, 0 = Du)")
    end
end
