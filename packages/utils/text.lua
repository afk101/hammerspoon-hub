local M = {}

-- 辅助函数：将十六进制转换为字符
function M.hex_to_char(x)
  return string.char(tonumber(x, 16))
end

-- 辅助函数：URL 解码（将 %XX 形式的编码转换回普通字符）
function M.unescape(url)
  return url:gsub("%%(%x%x)", M.hex_to_char)
end

return M
