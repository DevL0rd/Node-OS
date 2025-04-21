local isSaving = false

local money_storage_path = "etc/money/storage.cfg"
local balance_forwarding_patch = "etc/money/balance_forwarding.cfg"

function saveMoney()
    if not isSaving then
        isSaving = true
        saveTable(money_storage_path, money_storage)
        isSaving = false
    end
end

function saveBalanceForwarding()
    if not isSaving then
        isSaving = true
        saveTable(balance_forwarding_patch, balance_forwarding)
        isSaving = false
    end
end

if os.getComputerID() == nodeos.settings.settings.master then
    if fs.exists(money_storage_path) then
        money_storage = loadTable(money_storage_path)
    else
        saveMoney()
    end

    if fs.exists(balance_forwarding_patch) then
        balance_forwarding = loadTable(balance_forwarding_patch)
    else
        balance_forwarding = {}
        saveBalanceForwarding()
    end

    function listen_getBalance()
        while true do
            local senderID, msg = rednet.receive("NodeOS_getBalance")
            accID = senderID
            if balance_forwarding[senderID] then
                accID = balance_forwarding[accID]
            end
            if not money_storage[accID] then
                money_storage[accID] = 0
                saveMoney()
            end
            nodeos.net.respond(senderID, msg.token, {
                success = true,
                balance = money_storage[accID],
                forwarding = balance_forwarding[senderID] or false
            })
        end
    end

    nodeos.createProcess(listen_getBalance, { isService = true, title = "listen_getBalance" })


    function listen_setBalance()
        while true do
            local senderID, msg = rednet.receive("NodeOS_setBalance")
            if nodeos.net.getPairedClients()[senderID] then -- check for admin
                money_storage[msg.data.id] = msg.data.amount
                saveMoney()
            end
        end
    end

    nodeos.createProcess(listen_setBalance, { isService = true, title = "listen_setBalance" })

    function listen_connectBalance()
        while true do
            local senderID, msg = rednet.receive("NodeOS_connectBalance")
            id = msg.data.id
            if balance_forwarding[id] then
                id = balance_forwarding[id]
            end
            balance_forwarding[senderID] = id
            saveBalanceForwarding()
            -- move the money to the new account
            if not money_storage[id] then
                money_storage[id] = 0
            end
            if not money_storage[senderID] then
                money_storage[senderID] = 0
            end
            money_storage[id] = money_storage[id] + money_storage[senderID]
            -- remove the old account
            money_storage[senderID] = nil
            saveMoney()
            nodeos.net.respond(senderID, msg.token, {
                success = true
            })
        end
    end

    nodeos.createProcess(listen_connectBalance, { isService = true, title = "listen_connectBalance" })

    function listen_transfer()
        while true do
            local senderID, msg = rednet.receive("NodeOS_transfer")
            accID = senderID
            if balance_forwarding[senderID] then
                accID = balance_forwarding[accID]
            end

            id = msg.data.id
            if balance_forwarding[id] then
                id = balance_forwarding[id]
            end

            if not money_storage[accID] then
                money_storage[accID] = 0
            end
            if not money_storage[id] then
                money_storage[id] = 0
            end
            -- if not a number, user could send string
            if type(msg.data.amount) ~= "number" or msg.data.amount <= 0 then
                nodeos.net.respond(senderID, msg.token, {
                    success = false,
                    message = "Invalid amount!"
                })
            elseif accID == id then
                nodeos.net.respond(senderID, msg.token, {
                    success = false,
                    message = "You can't transfer money to yourself!"
                })
            elseif money_storage[accID] < msg.data.amount then
                nodeos.net.respond(senderID, msg.token, {
                    success = false,
                    message = "Insufficient funds!"
                })
            else
                msg.data.amount = math.floor(msg.data.amount * 100) / 100
                money_storage[accID] = money_storage[accID] - msg.data.amount
                money_storage[id] = money_storage[id] + msg.data.amount
                saveMoney()
                nodeos.net.respond(senderID, msg.token, {
                    success = true,
                    balance = money_storage[accID],
                    forwarding = balance_forwarding[senderID] or false
                })
                nodeos.net.emit("NodeOS_receiveTransferNotice", {
                    id = accID,
                    amount = msg.data.amount
                }, id, true) -- ignore the response
            end
        end
    end

    nodeos.createProcess(listen_transfer, { isService = true, title = "listen_transfer" })


    -- add 1 money to everyone's account every minute
    function addMoney()
        while true do
            for k, v in pairs(money_storage) do
                money_storage[k] = v + 1
            end
            saveMoney()
            sleep(60)
        end
    end

    nodeos.createProcess(addMoney, { isService = true, title = "accrue_money" })
else
    function listen_receiveTransferNotice()
        while true do
            local senderID, msg = rednet.receive("NodeOS_receiveTransferNotice")
            -- nodeos.graphics.print("You received " .. msg.amount .. " from " .. msg.id, "green")
            -- do something later.
            nodeos.notifications.push("Received Money!", "You received " .. msg.amount .. " from " .. msg.id, "green")
        end
    end

    nodeos.createProcess(listen_receiveTransferNotice, { isService = true, title = "listen_receiveTransferNotice" })
end
