local M = {}

-- 辅助函数：将十六进制转换为字符
local function hex_to_char(x)
  return string.char(tonumber(x, 16))
end

-- 辅助函数：URL 解码（将 %XX 形式的编码转换回普通字符）
local function unescape(url)
  return url:gsub("%%(%x%x)", hex_to_char)
end

-- 从剪切板获取文件路径的核心函数
local function get_file_path_from_clipboard()
  -- 方法 1: 使用 AppleScript 获取（这是获取 Finder 选中文件路径最可靠的方法）
  local script = [[
    try
      -- 尝试将剪切板内容转换为别名，再获取其 POSIX 路径（绝对路径）
      return POSIX path of (the clipboard as alias)
    on error
      -- 如果出错（例如剪切板不是文件），返回空字符串
      return ""
    end try
  ]]
  -- 执行 AppleScript
  local success, result = hs.osascript.applescript(script)
  -- 如果执行成功且结果不为空，则直接返回路径
  if success and result and result ~= "" then
      return result
  end

  -- 方法 2: 降级方案，尝试读取 URL（适用于某些拖拽或复制场景）
  local url = hs.pasteboard.readURL()

  if url then
      -- 如果返回的是 table（新版 Hammerspoon 可能会返回 NSURL 对象）
      if type(url) == "table" then
          -- 尝试从已知属性中提取路径
          if url.path then return url.path end
          if url.filePath then return url.filePath end
          -- 如果有 absoluteString，尝试解析 file:// 协议
          if url.absoluteString then
             local s = url.absoluteString
             if string.sub(s, 1, 7) == "file://" then
                 return unescape(s:sub(8))
             end
          end
      -- 如果返回的是字符串
      elseif type(url) == "string" then
          -- 检查是否以 file:// 开头
          if string.sub(url, 1, 7) == "file://" then
               local parts = hs.http.urlParts(url)
               if parts and parts.path then
                   -- 解码路径中的特殊字符（如空格被编码为 %20）
                   return unescape(parts.path)
               end
          end
      end
  end

  -- 如果所有方法都失败，返回 nil
  return nil
end

-- 辅助函数：读取 .env 文件配置
local function loadEnv()
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
local function findNodePath()
    -- 1. 优先尝试从 .env 文件读取 NODE_PATH
    local env = loadEnv()
    if env["NODE_PATH"] and hs.fs.attributes(env["NODE_PATH"]) then
        return env["NODE_PATH"]
    end

    -- 2. 尝试常见的默认路径
    local paths = {
        "/usr/local/bin/node",                               -- Intel Mac 常用路径
        "/opt/homebrew/bin/node",                            -- M1/M2 Mac 常用路径
        "/usr/bin/node"                                      -- 系统自带（通常较旧）
    }
    -- 遍历路径列表，检查文件是否存在
    for _, p in ipairs(paths) do
        if hs.fs.attributes(p) then
            return p -- 找到存在的路径即返回
        end
    end
    return "node" -- 如果都没找到，尝试直接使用命令名（依赖环境变量）
end

-- 将快捷键对象存储在模块表 M 中，防止被垃圾回收机制清理导致快捷键失效
-- 快捷键绑定: Cmd + Alt + X
M.uploadHotkey = hs.hotkey.bind({"cmd", "alt"}, "X", function()
  -- 1. 获取剪切板中的文件路径
  local filePath = get_file_path_from_clipboard()
  if not filePath then
    hs.alert.show("❌Please check the Clipboard")
    return
  end

  -- 2. 显示开始上传的提示
  hs.alert.show("⏳Uploading: " .. filePath)

  -- 3. 准备执行上传脚本的参数
  local scriptPath = hs.configdir .. "/packages/upload/upload.js"
  local nodePath = findNodePath()

  -- 4. 创建异步任务执行 Node.js 上传脚本
  local task = hs.task.new(nodePath, function(exitCode, stdOut, stdErr)
    -- 回调函数：当任务结束时执行
    if exitCode == 0 then
      -- 任务成功，尝试从输出中提取 URL
      -- 匹配模式 ###URL_START###...###URL_END###
      local url = stdOut:match("###URL_START###(.-)###URL_END###")

      if url and url ~= "" then
          -- 5. 提取成功：将 URL 写入剪切板并提示成功
          hs.pasteboard.setContents(url)
          hs.alert.show("⭐️Upload Success! URL copied.")
      else
          -- 脚本执行成功但没捕获到 URL（可能是输出格式不对）
          print("上传脚本输出: " .. stdOut)
          hs.alert.show("⚠️Upload finished but no URL returned")
      end
    else
      -- 任务失败（ExitCode 非 0）
      hs.alert.show("❌Upload Failed")
      print("上传错误日志: " .. stdErr)
    end
  end, {scriptPath, filePath}) -- 传递参数：脚本路径和文件路径

  -- 5. 启动任务
  if task then
      task:start()
  else
      hs.alert.show("Internal Error: Failed to create upload task")
  end
end)

return M
