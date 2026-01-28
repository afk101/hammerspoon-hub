local Text = require("packages.utils.text")
local M = {}

-- 从剪切板获取文件路径的核心函数
function M.get_file_path_from_clipboard()
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
                 return Text.unescape(s:sub(8))
             end
          end
      -- 如果返回的是字符串
      elseif type(url) == "string" then
          -- 检查是否以 file:// 开头
          if string.sub(url, 1, 7) == "file://" then
               local parts = hs.http.urlParts(url)
               if parts and parts.path then
                   -- 解码路径中的特殊字符（如空格被编码为 %20）
                   return Text.unescape(parts.path)
               end
          end
      end
  end

  -- 如果所有方法都失败，返回 nil
  return nil
end

return M
