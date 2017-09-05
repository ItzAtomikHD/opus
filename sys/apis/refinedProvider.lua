local class      = require('class')
local Util       = require('util')
local Peripheral = require('peripheral')
local itemDB     = require('itemDB')

local RefinedProvider = class()

local keys = { 
  'damage',
  'displayName',
  'maxCount',
  'maxDamage',
  'name',
  'nbtHash',
}

function RefinedProvider:init(args)
  local defaults = {
    items = { },
    name = 'refinedStorage',
  }
  Util.merge(self, defaults)
  Util.merge(self, args)

  local controller = Peripheral.getByType('refinedstorage:controller')
  if controller then
    Util.merge(self, controller)
  end
end
 
function RefinedProvider:isValid()
  return not not self.listAvailableItems
end

function RefinedProvider:isOnline()
  return self.getNetworkEnergyStored() > 0
end

function RefinedProvider:getCachedItemDetails(item)
  local key = { item.name, item.damage, item.nbtHash }

  local detail = itemDB:get(key)
  if not detail then
    detail = self.findItem(item)
    if detail then
      local meta
      pcall(function() meta = detail.getMetadata() end)
      if not meta then
        return
      end
      Util.merge(detail, meta)
      detail.lname = detail.displayName:lower()

      local t = { }
      for _,k in pairs(keys) do
        t[k] = detail[k]
      end

      detail = t
      itemDB:add(key, detail)
    end
  end
  if detail then
    return Util.shallowCopy(detail)
  end
end

function RefinedProvider:listItems()
  local items = { }
  local list

  pcall(function()
    list = self.listAvailableItems()
  end)

  if list then

    local throttle = Util.throttle()

    for _,v in pairs(list) do
      local item = self:getCachedItemDetails(v)
      if item then
        item.display_name = item.displayName
        item.id = v.name
        item.count = v.count
        item.qty = v.count
        table.insert(items, item)
      end
      throttle()
    end
    itemDB:flush()
  end

  return items
end

function RefinedProvider:getItemInfo(fingerprint)

  local key = { fingerprint.name, fingerprint.damage, fingerprint.nbtHash }

  local item = itemDB:get(key)
  if not item then
    return self:getCachedItemDetails(fingerprint)
  end

  local detail = self.findItem(item)
  if detail then
    item.count = detail.count
    item.qty = detail.count
    return item
  end
end

function RefinedProvider:isCrafting(item)
  for _,task in pairs(self.getCraftingTasks()) do
    local output = task.getPattern().outputs[1]
    if output.name == item.name and 
       output.damage == item.damage and 
       output.nbtHash == item.nbtHash then
      return true
    end
  end
  return false
end

function RefinedProvider:craft(item, qty)
  local detail = self.findItem(item)
  if detail then
    return detail.craft(qty)
  end
end

function RefinedProvider:craftItems(items)
  return false
end

function RefinedProvider:provide(item, qty, slot)
end
 
function RefinedProvider:extract(slot, qty)
--  self.pushItems(self.direction, slot, qty)
end

function RefinedProvider:insert(slot, qty)
--  self.pullItems(self.direction, slot, qty)
end

return RefinedProvider
