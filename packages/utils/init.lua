local M = {}

-- 定义需要加载的子模块列表
local modules = {
    "packages.utils.env",
    "packages.utils.node",
    "packages.utils.shortcut",
    "packages.utils.text",
    "packages.utils.clipboard"
}

-- 动态导出所有子模块的函数
for _, module_name in ipairs(modules) do
    local module = require(module_name)
    for k, v in pairs(module) do
        M[k] = v
    end
end

return M
