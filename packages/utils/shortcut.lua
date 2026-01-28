local M = {}

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
