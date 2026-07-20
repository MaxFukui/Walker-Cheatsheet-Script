local M = { tests = {} }

function M.test(name, fn)
    table.insert(M.tests, { name = name, fn = fn })
end

function M.equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") ..
            string.format("\nexpected: %s\nactual: %s", tostring(expected), tostring(actual)), 2)
    end
end

function M.truthy(value, message)
    if not value then error(message or "expected truthy value", 2) end
end

function M.run()
    local failed = 0
    for _, item in ipairs(M.tests) do
        local ok, err = pcall(item.fn)
        if ok then
            print("PASS " .. item.name)
        else
            failed = failed + 1
            io.stderr:write("FAIL " .. item.name .. "\n" .. err .. "\n")
        end
    end
    if failed > 0 then os.exit(1) end
end

return M
