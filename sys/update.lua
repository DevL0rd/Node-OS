update_threads = {}

function update_thread()
    while true do
        --save caches
        for k, v in pairs(update_threads) do
            v()
        end
        os.sleep(10)
    end
end