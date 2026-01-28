local Constants = require("config.constants")
local M = {}

-- 读取 .env 文件配置
function M.loadEnv()
  local env = {}
  local envFile = hs.configdir .. "/.env"
  local f = io.open(envFile, "r")
  if f then
    for line in f:lines() do
      -- 忽略注释和空行
      if not line:match("^%s*#") and line:match("=") then
        local key, value = line:match("([^=]+)=(.*)")
        if key and value then
          -- 去除可能存在的空白字符和引号
          key = key:match("^%s*(.-)%s*$")
          value = value:match("^%s*(.-)%s*$")
          env[key] = value
        end
      end
    end
    f:close()
  end
  return env
end

-- 查找系统中 Node.js 可执行文件的路径
function M.findNodePath()
    -- 1. 优先尝试从 .env 文件读取 NODE_PATH
    local env = M.loadEnv()
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

-- 解析快捷键配置
-- 例如输入 "cmd+alt+X" 返回 {"cmd", "alt"}, "X"
function M.parseShortcut(str)
  if not str or str == "" then
    return nil, nil
  end

  local parts = {}
  for part in string.gmatch(str, "([^+]+)") do
    -- 去除前后空格
    local p = part:match("^%s*(.-)%s*$")
    if p and p ~= "" then
      table.insert(parts, p)
    end
  end

  if #parts < 1 then
    return nil, nil
  end

  -- 最后一个部分作为按键，前面的作为修饰键
  local key = table.remove(parts)
  local mods = parts

  return mods, key
end

return M
