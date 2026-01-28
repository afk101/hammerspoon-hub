local M = {}
local Utils = require("packages.utils")

-- 将快捷键对象存储在模块表 M 中，防止被垃圾回收机制清理导致快捷键失效
-- 读取配置并绑定快捷键
local env = Utils.loadEnv()
local mods, key = Utils.parseShortcut(env["UPLOAD_SHORTCUT"])

-- 如果未配置或解析失败，使用默认快捷键 Cmd + Alt + X
if not mods or not key then
    mods = {"cmd", "alt"}
    key = "X"
end

M.uploadHotkey = hs.hotkey.bind(mods, key, function()
  -- 1. 获取剪切板中的文件路径
  local filePath = Utils.get_file_path_from_clipboard()
  if not filePath then
    hs.alert.show("❌Please check the Clipboard")
    return
  end

  -- 2. 显示开始上传的提示
  hs.alert.show("⏳Uploading: " .. filePath)

  -- 3. 准备执行上传脚本的参数
  local scriptPath = hs.configdir .. "/packages/upload/upload.js"
  local nodePath = Utils.findNodePath()

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
