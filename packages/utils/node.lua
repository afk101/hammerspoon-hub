local Constants = require("config.constants")
local Env = require("packages.utils.env")
local M = {}

-- 查找系统中 Node.js 可执行文件的路径
function M.findNodePath()
    -- 1. 优先尝试从 .env 文件读取 NODE_PATH
    local env = Env.loadEnv()
    if env["NODE_PATH"] and hs.fs.attributes(env["NODE_PATH"]) then
        return env["NODE_PATH"]
    end

    -- 2. 尝试常见的默认路径
    local paths = Constants.DEFAULT_NODE_PATHS

    -- 遍历路径列表，检查文件是否存在
    for _, p in ipairs(paths) do
        if hs.fs.attributes(p) then
            return p -- 找到存在的路径即返回
        end
    end
    return "node" -- 如果都没找到，尝试直接使用命令名（依赖环境变量）
end

return M
