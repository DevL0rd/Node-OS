local isSaving = false

local money_storage_path = "etc/money/storage.cfg"
local balance_forwarding_patch = "etc/money/balance_forwarding.cfg"

-- Add initialization log for Money service
nodeos.logging.info("MoneyService", "Initializing money service")

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
        nodeos.logging.debug("MoneyService", "Saving balance forwarding configuration")
        saveTable(balance_forwarding_patch, balance_forwarding)
        isSaving = false
    end
end

if os.getComputerID() == nodeos.settings.settings.master then
    nodeos.logging.info("MoneyService", "Initializing master money server")
    if fs.exists(money_storage_path) then
        nodeos.logging.debug("MoneyService", "Loading existing money storage")
        money_storage = loadTable(money_storage_path)
    else
        nodeos.logging.debug("MoneyService", "Creating new money storage")
        money_storage = {}
        saveMoney()
    end

    if fs.exists(balance_forwarding_patch) then
        nodeos.logging.debug("MoneyService", "Loading existing balance forwarding configuration")
        balance_forwarding = loadTable(balance_forwarding_patch)
    else
        nodeos.logging.debug("MoneyService", "Creating new balance forwarding configuration")
        balance_forwarding = {}
        saveBalanceForwarding()
    end

    function listen_getBalance()
        nodeos.logging.debug("MoneyService", "Starting balance request listener")
        while true do
            local senderID, msg = nodeos.net.receive("NodeOS_getBalance")
            accID = senderID
            if balance_forwarding[senderID] then
                accID = balance_forwarding[accID]
                nodeos.logging.debug("MoneyService", "Forwarding balance request from #" .. senderID .. " to #" .. accID)
            end
            if not money_storage[accID] then
                nodeos.logging.info("MoneyService", "Creating new account for #" .. accID)
                money_storage[accID] = 0
                saveMoney()
            end
            nodeos.logging.debug("MoneyService",
                "Computer #" .. senderID .. " requested balance - balance: " .. money_storage[accID])
            nodeos.net.respond(senderID, msg.token, {
                success = true,
                balance = money_storage[accID],
                forwarding = balance_forwarding[senderID] or false
            })
        end
    end

    nodeos.createProcess(listen_getBalance, { isService = true, title = "listen_getBalance" })


    function listen_setBalance()
        nodeos.logging.debug("MoneyService", "Starting set balance listener")
        while true do
            local senderID, msg = nodeos.net.receive("NodeOS_setBalance")
            if nodeos.net.getPairedClients()[senderID] then -- check for admin
                nodeos.logging.info("MoneyService",
                    "Admin #" .. senderID .. " setting balance of #" .. msg.data.id .. " to " .. msg.data.amount)
                money_storage[msg.data.id] = msg.data.amount
                saveMoney()
            else
                nodeos.logging.warn("MoneyService", "Non-admin computer #" .. senderID .. " attempted to set balance")
            end
        end
    end

    nodeos.createProcess(listen_setBalance, { isService = true, title = "listen_setBalance" })

    function listen_connectBalance()
        nodeos.logging.debug("MoneyService", "Starting connect balance listener")
        while true do
            local senderID, msg = nodeos.net.receive("NodeOS_connectBalance")
            id = msg.data.id
            if balance_forwarding[id] then
                id = balance_forwarding[id]
            end
            nodeos.logging.info("MoneyService", "Connecting balance of #" .. senderID .. " to #" .. id)
            balance_forwarding[senderID] = id
            saveBalanceForwarding()
            -- move the money to the new account
            if not money_storage[id] then
                money_storage[id] = 0
            end
            if not money_storage[senderID] then
                money_storage[senderID] = 0
            end
            nodeos.logging.info("MoneyService",
                "Transferring " .. money_storage[senderID] .. " from #" .. senderID .. " to #" .. id)
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
        nodeos.logging.debug("MoneyService", "Starting transfer listener")
        while true do
            local senderID, msg = nodeos.net.receive("NodeOS_transfer")
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
                nodeos.logging.warn("MoneyService", "Invalid transfer amount from #" .. senderID)
                nodeos.net.respond(senderID, msg.token, {
                    success = false,
                    message = "Invalid amount!"
                })
            elseif accID == id then
                nodeos.logging.warn("MoneyService", "Computer #" .. senderID .. " attempted to transfer to self")
                nodeos.net.respond(senderID, msg.token, {
                    success = false,
                    message = "You can't transfer money to yourself!"
                })
            elseif money_storage[accID] < msg.data.amount then
                nodeos.logging.warn("MoneyService", "Computer #" .. senderID .. " has insufficient funds for transfer")
                nodeos.net.respond(senderID, msg.token, {
                    success = false,
                    message = "Insufficient funds!"
                })
            else
                msg.data.amount = math.floor(msg.data.amount * 100) / 100
                nodeos.logging.info("MoneyService",
                    "Transfer of " .. msg.data.amount .. " from #" .. accID .. " to #" .. id)
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
        nodeos.logging.debug("MoneyService", "Starting money accrual process")
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
    nodeos.logging.info("MoneyService", "Initializing client money service")
    function listen_receiveTransferNotice()
        nodeos.logging.debug("MoneyService", "Starting transfer notification listener")
        while true do
            local senderID, msg = nodeos.net.receive("NodeOS_receiveTransferNotice")
            nodeos.logging.info("MoneyService", "Received " .. msg.amount .. " from #" .. msg.id)
            -- nodeos.graphics.print("You received " .. msg.amount .. " from " .. msg.id, "green")
            -- do something later.
            nodeos.notifications.push("Received Money!", "You received " .. msg.amount .. " from " .. msg.id, "green")
        end
    end

    nodeos.createProcess(listen_receiveTransferNotice, { isService = true, title = "listen_receiveTransferNotice" })
end
