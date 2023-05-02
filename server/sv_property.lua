Property = {
    property_id = nil,
    propertyData = nil,
    playersInside = {},  -- src
    playersDoorbell = {}, -- src

    PlayerEnter = function (self, src)
        self.playersInside[src] = true
        TriggerClientEvent('ps-housing:client:enterProperty', src, self.property_id)
        if next(self.playersDoorbell) then
            TriggerClientEvent("ps-housing:client:updateDoorbellPool", src, self.property_id, self.playersDoorbell)
            if self.playersDoorbell[src] then
                self.playersDoorbell[src] = nil
            end
        end
    end,

    AddToDoorbellPoolTemp = function (self, src)
        self.playersDoorbell[src] = true
        for k, v in pairs(self.playersInside) do
            TriggerClientEvent('QBCore:Notify', k, "Someone is at the door.", "success")
            TriggerClientEvent("ps-housing:client:updateDoorbellPool", k, self.property_id, self.playersDoorbell)
        end
        TriggerClientEvent('QBCore:Notify', src, "Ringing Doorbell.", "success")
        SetTimeout(30000, function ()
            if self.playersDoorbell[src] then
                self.playersDoorbell[src] = nil
                TriggerClientEvent('QBCore:Notify', src, "No one answered the door.", "error")
            end
            for k, v in pairs(self.playersInside) do
                TriggerClientEvent("ps-housing:client:updateDoorbellPool", k, self.property_id, self.playersDoorbell)
            end
        end)
    end,

    PlayerLeave = function (self, src)
        self.playersInside[src] = nil
    end,

    CheckForAccess = function (self, citizenid)
        for i = 1, #self.propertyData.has_access do
            if self.propertyData.has_access[i] == citizenid then
                return true
            end
        end
        return false
    end,

    UpdateFurnitures = function (self, furnitures)
        self.propertyData.furnitures = furnitures
        MySQL.update("UPDATE properties SET furnitures = @furnitures WHERE property_id = @property_id", {
            ["@furnitures"] = json.encode(furnitures),
            ["@property_id"] = self.property_id
        })
        TriggerClientEvent('ps-housing:client:updateProperty', -1, self.propertyData)
    end,

    UpdateLabel = function (self, data)
        local label = data.label
        local realtorSrc = data.realtorSrc
        if self.propertyData.label == label then return end
        self.propertyData.label = label
        MySQL.update("UPDATE properties SET label = @label WHERE property_id = @property_id", {
            ["@label"] = label,
            ["@property_id"] = self.property_id
        })
        print("Changed Label of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,

    UpdateDescription = function (self, data)
        local description = data.description
        local realtorSrc = data.realtorSrc
        if self.propertyData.description == description then return end
        self.propertyData.description = description
        MySQL.update("UPDATE properties SET description = @description WHERE property_id = @property_id", {
            ["@description"] = description,
            ["@property_id"] = self.property_id
        })
        print("Changed Description of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,

    UpdatePrice = function (self, data)
        local price = data.price
        local realtorSrc = data.realtorSrc
        if self.propertyData.price == price then return end
        self.propertyData.price = price
        MySQL.update("UPDATE properties SET price = @price WHERE property_id = @property_id", {
            ["@price"] = price,
            ["@property_id"] = self.property_id
        })
        print("Changed Price of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,

    UpdateForSale = function (self, data)
        local forsale = data.forsale
        local realtorSrc = data.realtorSrc
        self.propertyData.for_sale = forsale
        MySQL.update("UPDATE properties SET for_sale = @for_sale WHERE property_id = @property_id", {
            ["@for_sale"] = forsale and 1 or 0,
            ["@property_id"] = self.property_id
        })
        print("Changed For Sale of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,

    UpdateShell = function (self, data)
        local shell = data.shell
        local realtorSrc = data.realtorSrc
        if self.propertyData.shell == shell then return end
        self.propertyData.shell = shell
        MySQL.update("UPDATE properties SET shell = @shell WHERE property_id = @property_id", {
            ["@shell"] = shell,
            ["@property_id"] = self.property_id
        })
        print("Changed Shell of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,

    UpdateOwner = function (self, data)
        local targetSrc = data.targetSrc
        local realtorSrc = data.realtorSrc
        local targetPlayer  = QBCore.Functions.GetPlayer(tonumber(targetSrc))
        local PlayerData = targetPlayer.PlayerData
        local bank = PlayerData.money.bank
        local citizenid = PlayerData.citizenid

        if bank < self.propertyData.price then
            TriggerClientEvent('QBCore:Notify', targetSrc, 'You do not have enough money in your bank account', 'error')
            return
        end

        self.propertyData.owner = citizenid
        MySQL.update("UPDATE properties SET owner_citizenid = @owner_citizenid, for_sale = @for_sale WHERE property_id = @property_id", {
            ["@owner_citizenid"] = citizenid,
            ["@for_sale"] = 0,
            ["@property_id"] = self.property_id
        })
        TriggerClientEvent("ps-housing:client:updateProperty", -1, self.propertyData) -- Update all clients here because it doesnt update by itself
        TriggerClientEvent('QBCore:Notify', targetSrc, 'You have bought the property for $'..self.propertyData.price, 'success')
    end,

    UpdateImgs = function (self, data)
        local imgs = data.imgs
        local realtorSrc = data.realtorSrc
        self.propertyData.imgs = imgs
        MySQL.update("UPDATE properties SET extra_imgs = @extra_imgs WHERE property_id = @property_id", {
            ["@extra_imgs"] = json.encode(imgs),
            ["@property_id"] = self.property_id
        })
        print("Changed Imgs of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,

    UpdateDoor = function (self, data)
        local door = data.door
        local realtorSrc = data.realtorSrc
        local newData = {
            x = math.floor(door.x * 100) / 100,
            y = math.floor(door.y * 100) / 100,
            z = math.floor(door.z * 100) / 100,
            h = math.floor(door.h * 100) / 100,
            length = door.length or 1.5,
            width = door.width or 2.2,
            locked = door.locked or false,
        }
        self.propertyData.door_data = newData
        MySQL.update("UPDATE properties SET door_data = @data WHERE property_id = @property_id", {
            ["@data"] = json.encode(newData),
            ["@property_id"] = self.property_id
        })
        print("Changed Door of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,

    UpdateHas_access = function (self, data)
        local has_access = data.has_access
        local src = data.src
        self.propertyData.has_access = has_access
        MySQL.update("UPDATE properties SET has_access = @has_access WHERE property_id = @property_id", {
            ["@has_access"] = json.encode(has_access), --Array of cids
            ["@property_id"] = self.property_id
        })
        print("Changed Has Access of property with id: " .. self.property_id, "by: " .. GetPlayerName(src))
    end,

    UpdateGarage = function (self, data)
        local garage = data.garage
        local realtorSrc = data.realtorSrc
        local newData = {}
        if data ~= nil then 
            newData = {
                x = math.floor(garage.x * 100) / 100,
                y = math.floor(garage.y * 100) / 100,
                z = math.floor(garage.z * 100) / 100,
                h = math.floor(garage.h * 100) / 100,
                length = garage.length or 3.0,
                width = garage.width or 5.0,
            }
        end
        self.propertyData.garage_data = newData
        MySQL.update("UPDATE properties SET garage_data = @garageCoords WHERE property_id = @property_id", {
            ["@garageCoords"] = json.encode(newData),
            ["@property_id"] = self.property_id
        })
        print("Changed Garage of property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,

    DeleteProperty = function (self, data)
        local realtorSrc = data.realtorSrc
        MySQL.Async.execute("DELETE FROM properties WHERE property_id = @property_id", {
            ["@property_id"] = self.property_id
        }, function (rowsChanged)
            if rowsChanged > 0 then
                print("Deleted property with id: " .. self.property_id, "by: " .. GetPlayerName(data.realtorSrc))
            end
        end)
        TriggerClientEvent("ps-housing:client:deleteProperty", -1, self.property_id)
        print("Deleted property with id: " .. self.property_id, "by: " .. GetPlayerName(realtorSrc))
    end,
}

function Property:new(propertyData)
    local obj = {}
    obj.propertyData = propertyData
    obj.property_id = propertyData.property_id
    obj.playersInside = {}
    setmetatable(obj, self)
    self.__index = self

    return obj
end

local function getCitizenid(src)
    local Player = QBCore.Functions.GetPlayer(src)
    local PlayerData = Player.PlayerData
    local citizenid = PlayerData.citizenid
    return citizenid, PlayerData, Player
end

RegisterNetEvent('ps-housing:server:enterProperty', function (property_id)
    local src = source
    local property = PropertiesTable[property_id]
    if not property then return end
    local citizenid = getCitizenid(src)
    
    if property.propertyData.owner == citizenid or property:CheckForAccess(citizenid) then
        property:PlayerEnter(src)
        return
    end
    property:AddToDoorbellPoolTemp(src)
    TriggerClientEvent('QBCore:Notify', src, "Ringing Doorbell.", "success")
end)

RegisterNetEvent('ps-housing:server:leaveProperty', function (property_id)
    local src = source
    local property = PropertiesTable[property_id]
    if not property then return end
    property:PlayerLeave(src)
end)

-- When player presses doorbell, owner can let them in and this is what is triggered (didnt know what else to name it)
RegisterNetEvent("ps-housing:server:doorbellAnswer", function (data) 
    local src = source
    local targetSrc = data.targetSrc
    local property = PropertiesTable[data.property_id]
    if not property then return end
    local ownerCitizenid = getCitizenid(src)
    if property.propertyData.owner ~= ownerCitizenid then return end
    property:PlayerEnter(targetSrc)
end)

RegisterNetEvent("ps-housing:server:buyFurniture", function(property_id, items, price)
    local src = source
    local citizenid, PlayerData, Player = getCitizenid(src)
    local property = PropertiesTable[property_id]
    if not property then return end
    if not property:CheckForAccess(citizenid) then return end
    local price = tonumber(price)
    if price > PlayerData.money.bank then
        TriggerClientEvent('QBCore:Notify', src, "You do not have enough money!", "error")
        return
    end
    Player.Functions.RemoveMoney('bank', price, "bought furniture")
    property:UpdateFurnitures(items)
    TriggerClientEvent('QBCore:Notify', src, "You bought furniture for $" .. price, "success")
end)

RegisterNetEvent("ps-housing:server:addAccess", function(property_id, srcToAdd)
    local src = source
    local citizenid = getCitizenid(src)
    local property = PropertiesTable[property_id]
    if not property.propertyData.owner == citizenid then
        -- hacker ban or something
        TriggerClientEvent('QBCore:Notify', src, "You are not the owner of this property!", "error")
        return
    end
    local has_access = property.propertyData.has_access
    local srcToAdd = tonumber(srcToAdd)
    local TargetCitizenid = getCitizenid(srcToAdd)
    if not property:CheckForAccess(TargetCitizenid) then
        has_access[#has_access+1] = TargetCitizenid
        property:UpdateHas_access(has_access)
        TriggerClientEvent('QBCore:Notify', src, "You added access to " .. GetPlayerName(srcToAdd), "success")
        TriggerClientEvent('QBCore:Notify', srcToAdd, "You got access to " .. property.propertyData.label, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "This person already has access to this property!", "error")
    end
end)

RegisterNetEvent("ps-housing:server:removeAccess", function(property_id, srcToRemove)
    local src = source
    local citizenid = getCitizenid(src)
    local property = PropertiesTable[property_id]
    if not property.propertyData.owner == citizenid then
        -- hacker ban or something
        TriggerClientEvent('QBCore:Notify', src, "You are not the owner of this property!", "error")
        return
    end
    local has_access = property.propertyData.has_access
    local srcToRemove = tonumber(srcToRemove)
    local TargetCitizenid = getCitizenid(srcToRemove)
    if property:CheckForAccess(TargetCitizenid) then
        for i = 1, #has_access do
            if has_access[i] == TargetCitizenid then
                table.remove(has_access, i)
                break
            end
        end 
        property:UpdateHas_access(has_access)
        TriggerClientEvent('QBCore:Notify', src, "You removed access from " .. GetPlayerName(srcToRemove), "success")
        TriggerClientEvent('QBCore:Notify', srcToRemove, "You lost access to " .. property.propertyData.label, "error")
    else
        TriggerClientEvent('QBCore:Notify', src, "This person does not have access to this property!", "error")
    end
end)