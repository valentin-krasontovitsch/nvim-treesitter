#!/usr/bin/env bash
# Usage: ./get-bash-ast.sh <file>
# Prints the bash injection AST node ranges for a given file, useful for
# reproducing / confirming the injection.combined cross-RUN highlighting bleed.
FILE="${1:?Usage: $0 <file>}"

nvim --headless +1 "$FILE" -c "lua
local ft = vim.bo.filetype
local parser = vim.treesitter.get_parser(0, ft)
parser:parse(true)

io.write('=== BASH PARSER TREES ===\n')
local bash = parser:children()['bash']
if bash then
  local trees = bash:trees()
  io.write(string.format('number of bash trees: %d\n', #trees))
  for ti, tree in ipairs(trees) do
    local root = tree:root()
    local sr, sc, er, ec = root:range()
    io.write(string.format('\ntree %d root: row %d col %d -> row %d col %d\n', ti, sr, sc, er, ec))
    for i = 0, root:named_child_count()-1 do
      local child = root:named_child(i)
      local csr, csc, cer, cec = child:range()
      io.write(string.format('  node [%s]: row %d col %d -> row %d col %d  text=%q\n',
        child:type(), csr, csc, cer, cec,
        vim.treesitter.get_node_text(child, 0)))
    end
  end
else
  io.write('no bash child parser found\n')
end
vim.cmd('q')"
