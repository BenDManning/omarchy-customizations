-- Use the touchscreen-enabled slurp build for Omarchy screenshots.
local slurp_dir = os.getenv("HOME") .. "/.local/lib/omarchy-touchscreen"

hl.unbind("PRINT")
o.bind("PRINT", "Screenshot", 'env PATH="' .. slurp_dir .. ':$PATH" omarchy-capture-screenshot')
