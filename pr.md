# reproduction

we can use the following dockerfile, let's say `example.dockerfile`:

```
FROM python AS base

RUN pip install requests && \
  echo all done

FROM alpine
RUN apk add openssh-client
CMD ["/usr/bin/sh"]
```

then we
- can open the file in nvim,
- navigate to the `FROM` keyword on line 6, and
- run `:Inspect`

(or use the following almost-one-liner for faster iteration:)

```
nvim --headless +6 example.dockerfile -c "lua local ft=vim.bo.filetype; local
  p=vim.treesitter.get_parser(0,ft); p:parse(true); vim.schedule(function() local
  o=vim.api.nvim_exec2('Inspect',{output=true}); io.write(o.output..'\n'); vim.cmd('q') end)"
```

and we get the output

```
Treesitter
  - @keyword.dockerfile links to Keyword   priority: 100   language: dockerfile
  - @variable.parameter.bash links to @variable.parameter   priority: 100   language: bash
```

where the second item in the list shouldn't be there.

with the fix we (i.e. copilot) proposes, it's gone! and the syntax highlighting
is all good ^^

## explanation

i have tried to understand as much as i could of the change based on
explanations from copilot, but this is my first PR in treesitter, and i cannot
claim to understand the parsing or the concepts or anything much really... so
feel free to shoot it down / make suggestions or corrections : )

digging deeper and trying to get copilot to explain moar, apparently it is
something to do with ranges of nodes in the bash AST, and with the old version
of the query, you got one node spanning from the first to the last run command.
this can be confirmed with the script `bash-ast.sh`:

```
#!/usr/bin/env bash
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
```

which can be used like

```
bash-ast.sh example.dockerfile
```


## history

the current code state was introduced in commit
d8bf42b2621f5af274ccd4ac3f742caea04723b4, and i cannot say if that broke it or
not, as i don't understand enough about the language or if there were parser
changes... but using the older version

```
((shell_command) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-children))
```

also causes syntax bleed.
