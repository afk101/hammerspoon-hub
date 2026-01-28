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

return M
