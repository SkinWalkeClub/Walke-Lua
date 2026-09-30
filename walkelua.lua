local M = {}
M._VERSION = "1.0.0"
M._AUTHOR = "Weegee_MLG / Skin Walke Team"

local sub, byte, find, rep = string.sub, string.byte, string.find, string.rep
local ins, cat = table.insert, table.concat

local KW = {}
for w in ("and break do else elseif end false for function if in local nil not or repeat return then true until while"):gmatch("%S+") do KW[w] = true end

local function isDigit(c) return c >= "0" and c <= "9" end
local function isHex(c) return (c >= "0" and c <= "9") or (c >= "a" and c <= "f") or (c >= "A" and c <= "F") end
local function isAlpha(c) return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_" end
local function isAlnum(c) return isAlpha(c) or isDigit(c) end

local function lex(s)
	local t, i, n, ln = {}, 1, #s, 1
	local function err(m) error("lex " .. ln .. ": " .. m, 0) end
	local function longBracket()
		local j = i + 1
		local eq = 0
		while sub(s, j, j) == "=" do eq = eq + 1 j = j + 1 end
		if sub(s, j, j) ~= "[" then return nil end
		j = j + 1
		if sub(s, j, j) == "\n" then ln = ln + 1 j = j + 1 end
		local close = "]" .. rep("=", eq) .. "]"
		local e = find(s, close, j, true)
		if not e then err("unterminated long bracket") end
		local body = sub(s, j, e - 1)
		for _ in body:gmatch("\n") do ln = ln + 1 end
		local raw = sub(s, i, e + #close - 1)
		i = e + #close
		return raw, body
	end
	while i <= n do
		local c = sub(s, i, i)
		if c == "\n" then ln = ln + 1 i = i + 1
		elseif c == " " or c == "\t" or c == "\r" then i = i + 1
		elseif c == "-" and sub(s, i + 1, i + 1) == "-" then
			if sub(s, i + 2, i + 2) == "[" then
				local save = i
				i = i + 2
				local raw = longBracket()
				if not raw then i = save + 2 while i <= n and sub(s, i, i) ~= "\n" do i = i + 1 end end
			else
				i = i + 2
				while i <= n and sub(s, i, i) ~= "\n" do i = i + 1 end
			end
		elseif c == "[" and (sub(s, i + 1, i + 1) == "[" or sub(s, i + 1, i + 1) == "=") then
			local save, sln = i, ln
			local raw = longBracket()
			if raw then t[#t + 1] = { k = "str", v = raw, line = sln }
			else i = save t[#t + 1] = { k = "sym", v = "[", line = ln } i = i + 1 end
		elseif c == '"' or c == "'" then
			local q, j = c, i + 1
			while j <= n do
				local d = sub(s, j, j)
				if d == "\\" then j = j + 2
				elseif d == q then break
				elseif d == "\n" then err("unterminated string")
				else j = j + 1 end
			end
			if j > n then err("unterminated string") end
			t[#t + 1] = { k = "str", v = sub(s, i, j), line = ln }
			i = j + 1
		elseif c == "`" then
			local j, depth = i + 1, 0
			while j <= n do
				local d = sub(s, j, j)
				if d == "\\" then j = j + 2
				elseif d == "{" then depth = depth + 1 j = j + 1
				elseif d == "}" then if depth > 0 then depth = depth - 1 end j = j + 1
				elseif d == "`" and depth == 0 then break
				elseif d == "\n" then ln = ln + 1 j = j + 1
				else j = j + 1 end
			end
			if j > n then err("unterminated backtick string") end
			t[#t + 1] = { k = "str", v = sub(s, i, j), line = ln }
			i = j + 1
		elseif isDigit(c) or (c == "." and isDigit(sub(s, i + 1, i + 1))) then
			local j = i
			if c == "0" and (sub(s, i + 1, i + 1) == "x" or sub(s, i + 1, i + 1) == "X") then
				j = i + 2
				while j <= n and (isHex(sub(s, j, j)) or sub(s, j, j) == "_" or sub(s, j, j) == ".") do j = j + 1 end
				if sub(s, j, j) == "p" or sub(s, j, j) == "P" then j = j + 1 if sub(s, j, j) == "+" or sub(s, j, j) == "-" then j = j + 1 end while j <= n and isDigit(sub(s, j, j)) do j = j + 1 end end
			else
				while j <= n and (isDigit(sub(s, j, j)) or sub(s, j, j) == "_" or sub(s, j, j) == ".") do j = j + 1 end
				if sub(s, j, j) == "e" or sub(s, j, j) == "E" then j = j + 1 if sub(s, j, j) == "+" or sub(s, j, j) == "-" then j = j + 1 end while j <= n and isDigit(sub(s, j, j)) do j = j + 1 end end
			end
			t[#t + 1] = { k = "num", v = sub(s, i, j - 1), line = ln }
			i = j
		elseif isAlpha(c) then
			local j = i
			while j <= n and isAlnum(sub(s, j, j)) do j = j + 1 end
			local w = sub(s, i, j - 1)
			t[#t + 1] = { k = KW[w] and "kw" or "name", v = w, line = ln }
			i = j
		else
			local three = sub(s, i, i + 2)
			local two = sub(s, i, i + 1)
			if three == "..." or three == "..=" then t[#t + 1] = { k = "sym", v = three, line = ln } i = i + 3
			elseif two == ".." or two == "==" or two == "~=" or two == "<=" or two == ">=" or two == "::" or two == "->" or two == "+=" or two == "-=" or two == "*=" or two == "/=" or two == "%=" or two == "^=" then
				t[#t + 1] = { k = "sym", v = two, line = ln } i = i + 2
			else
				t[#t + 1] = { k = "sym", v = c, line = ln } i = i + 1
			end
		end
	end
	t[#t + 1] = { k = "eof", v = "<eof>", line = ln }
	return t
end
M.lex = lex

local COMPOUND = { ["+="] = 1, ["-="] = 1, ["*="] = 1, ["/="] = 1, ["%="] = 1, ["^="] = 1, ["..="] = 1 }
local BINPRI = {
	["or"] = { 1, 1 }, ["and"] = { 2, 2 },
	["<"] = { 3, 3 }, [">"] = { 3, 3 }, ["<="] = { 3, 3 }, [">="] = { 3, 3 }, ["~="] = { 3, 3 }, ["=="] = { 3, 3 },
	[".."] = { 5, 4 }, ["+"] = { 6, 6 }, ["-"] = { 6, 6 },
	["*"] = { 7, 7 }, ["/"] = { 7, 7 }, ["%"] = { 7, 7 }, ["^"] = { 10, 9 },
}
local UNARY = 8

local function parse(toks)
	local p = 1
	local function pk() return toks[p] end
	local function nx() local t = toks[p] p = p + 1 return t end
	local function is(k, v) local t = toks[p] return t.k == k and (v == nil or t.v == v) end
	local function isv(v) return toks[p].v == v end
	local function err(m) error("parse " .. toks[p].line .. ": " .. m .. " near '" .. tostring(toks[p].v) .. "'", 0) end
	local function accept(k, v) if is(k, v) then return nx() end end
	local function expect(k, v) if not is(k, v) then err("expected " .. (v or k)) end return nx() end

	local expr, block

	local function name() local t = expect("name") return { k = "name", v = t.v } end

	local function explist()
		local l = { expr() }
		while accept("sym", ",") do l[#l + 1] = expr() end
		return l
	end

	local function tablecons()
		expect("sym", "{")
		local fs = {}
		while not is("sym", "}") do
			if is("sym", "[") then
				nx()
				local key = expr()
				expect("sym", "]")
				expect("sym", "=")
				fs[#fs + 1] = { t = "k", key = key, val = expr() }
			elseif is("name") and toks[p + 1].k == "sym" and toks[p + 1].v == "=" then
				local nm = nx().v
				nx()
				fs[#fs + 1] = { t = "r", name = nm, val = expr() }
			else
				fs[#fs + 1] = { t = "v", val = expr() }
			end
			if not (accept("sym", ",") or accept("sym", ";")) then break end
		end
		expect("sym", "}")
		return { k = "table", fs = fs }
	end

	local funcbody

	local function primary()
		if accept("sym", "(") then
			local e = expr()
			expect("sym", ")")
			return { k = "paren", e = e }
		end
		if is("name") then return name() end
		err("unexpected symbol")
	end

	local function args()
		if is("sym", "(") then
			nx()
			local a = {}
			if not is("sym", ")") then a = explist() end
			expect("sym", ")")
			return a
		elseif is("str") then
			return { { k = "str", v = nx().v } }
		elseif is("sym", "{") then
			return { tablecons() }
		end
		err("function arguments expected")
	end

	local function suffixed()
		local e = primary()
		while true do
			if accept("sym", ".") then
				e = { k = "index", o = e, key = expect("name").v, dot = true }
			elseif accept("sym", "[") then
				local key = expr()
				expect("sym", "]")
				e = { k = "index", o = e, ekey = key }
			elseif is("sym", ":") then
				nx()
				local m = expect("name").v
				e = { k = "mcall", o = e, m = m, args = args() }
			elseif is("sym", "(") or is("str") or is("sym", "{") then
				e = { k = "call", o = e, args = args() }
			else
				break
			end
		end
		return e
	end

	local function simple()
		local t = pk()
		if t.k == "num" then nx() return { k = "num", v = t.v } end
		if t.k == "str" then nx() return { k = "str", v = t.v } end
		if t.k == "kw" and t.v == "nil" then nx() return { k = "nil" } end
		if t.k == "kw" and t.v == "true" then nx() return { k = "true" } end
		if t.k == "kw" and t.v == "false" then nx() return { k = "false" } end
		if t.k == "sym" and t.v == "..." then nx() return { k = "vararg" } end
		if t.k == "sym" and t.v == "{" then return tablecons() end
		if t.k == "kw" and t.v == "function" then nx() return funcbody(false) end
		return suffixed()
	end

	local function isunop() local t = pk() return (t.k == "kw" and t.v == "not") or (t.k == "sym" and (t.v == "-" or t.v == "#")) end

	local function subexpr(limit)
		local e
		if isunop() then
			local op = nx().v
			e = { k = "unop", op = op, e = subexpr(UNARY) }
		else
			e = simple()
		end
		while true do
			local t = pk()
			local op = (t.k == "sym" or t.k == "kw") and t.v or nil
			local pri = op and BINPRI[op]
			if not pri or pri[1] <= limit then break end
			nx()
			e = { k = "binop", op = op, l = e, r = subexpr(pri[2]) }
		end
		return e
	end

	expr = function() return subexpr(0) end

	funcbody = function(named)
		expect("sym", "(")
		local ps, va = {}, false
		if not is("sym", ")") then
			repeat
				if accept("sym", "...") then va = true break end
				ps[#ps + 1] = expect("name").v
			until not accept("sym", ",")
		end
		expect("sym", ")")
		local b = block()
		expect("kw", "end")
		return { k = "function", ps = ps, va = va, body = b, named = named }
	end

	local function funcname()
		local e = { k = "name", v = expect("name").v }
		while accept("sym", ".") do e = { k = "index", o = e, key = expect("name").v, dot = true } end
		local method
		if accept("sym", ":") then method = expect("name").v end
		return e, method
	end

	local function statement()
		local t = pk()
		if t.k == "sym" and t.v == ";" then nx() return nil end
		if t.k == "sym" and t.v == "::" then
			nx() local nm = expect("name").v expect("sym", "::") return { k = "label", v = nm }
		end
		if t.k == "kw" then
			local v = t.v
			if v == "if" then
				nx()
				local clauses = {}
				local c = expr() expect("kw", "then")
				clauses[1] = { cond = c, body = block() }
				while is("kw", "elseif") do nx() local c2 = expr() expect("kw", "then") clauses[#clauses + 1] = { cond = c2, body = block() } end
				local els
				if accept("kw", "else") then els = block() end
				expect("kw", "end")
				return { k = "if", clauses = clauses, els = els }
			elseif v == "while" then
				nx() local c = expr() expect("kw", "do") local b = block() expect("kw", "end")
				return { k = "while", cond = c, body = b }
			elseif v == "do" then
				nx() local b = block() expect("kw", "end") return { k = "do", body = b }
			elseif v == "for" then
				nx()
				local n1 = expect("name").v
				if is("sym", "=") then
					nx() local a = expr() expect("sym", ",") local b = expr()
					local c
					if accept("sym", ",") then c = expr() end
					expect("kw", "do") local body = block() expect("kw", "end")
					return { k = "fornum", var = n1, a = a, b = b, c = c, body = body }
				else
					local names = { n1 }
					while accept("sym", ",") do names[#names + 1] = expect("name").v end
					expect("kw", "in")
					local es = explist()
					expect("kw", "do") local body = block() expect("kw", "end")
					return { k = "forin", names = names, es = es, body = body }
				end
			elseif v == "repeat" then
				nx() local b = block() expect("kw", "until") local c = expr()
				return { k = "repeat", body = b, cond = c }
			elseif v == "function" then
				nx() local nm, method = funcname() local f = funcbody(true)
				return { k = "funcstat", name = nm, method = method, f = f }
			elseif v == "local" then
				nx()
				if accept("kw", "function") then
					local nm = expect("name").v
					return { k = "localfunc", name = nm, f = funcbody(true) }
				end
				local names = { expect("name").v }
				while accept("sym", ",") do names[#names + 1] = expect("name").v end
				local es
				if accept("sym", "=") then es = explist() end
				return { k = "local", names = names, es = es }
			elseif v == "return" then
				nx()
				local es
				if not (is("kw", "end") or is("kw", "else") or is("kw", "elseif") or is("kw", "until") or is("eof") or is("sym", ";")) then es = explist() end
				accept("sym", ";")
				return { k = "return", es = es }
			elseif v == "break" then nx() return { k = "break" }
			end
		end
		if t.k == "name" and t.v == "goto" and toks[p + 1].k == "name" then
			nx() return { k = "goto", v = nx().v }
		end
		if t.k == "name" and t.v == "continue" and not (toks[p + 1].k == "sym" and (toks[p + 1].v == "=" or toks[p + 1].v == "." or toks[p + 1].v == ":" or toks[p + 1].v == "[" or toks[p + 1].v == "(" or toks[p + 1].v == ",")) then
			nx() return { k = "continue" }
		end
		local e = suffixed()
		if is("sym", "=") or is("sym", ",") then
			local lhs = { e }
			while accept("sym", ",") do lhs[#lhs + 1] = suffixed() end
			expect("sym", "=")
			return { k = "assign", lhs = lhs, es = explist() }
		end
		local cop = pk()
		if cop.k == "sym" and COMPOUND[cop.v] then
			nx()
			return { k = "compound", op = cop.v, lhs = e, e = expr() }
		end
		if e.k ~= "call" and e.k ~= "mcall" then err("syntax error (expected statement)") end
		return { k = "callstat", e = e }
	end

	block = function()
		local stmts = {}
		while true do
			local t = pk()
			if t.k == "eof" or (t.k == "kw" and (t.v == "end" or t.v == "else" or t.v == "elseif" or t.v == "until")) then break end
			local s = statement()
			if s then stmts[#stmts + 1] = s end
			if s and s.k == "return" then break end
		end
		return stmts
	end

	local b = block()
	if not is("eof") then err("unexpected token") end
	return b
end
M.parse = parse

local function printer(opts)
	opts = opts or {}
	local ind = opts.indent or "    "
	local out = {}
	local function w(s) out[#out + 1] = s end
	local function pad(d) return rep(ind, d) end

	local E, stmts, S

	local function elist(l)
		local o = {}
		for i = 1, #l do o[i] = E(l[i]) end
		return cat(o, ", ")
	end

	local function ftable(t, d)
		if #t.fs == 0 then return "{}" end
		local simpleN = 0
		local ok = true
		for _, f in ipairs(t.fs) do
			if f.t ~= "v" then ok = false end
			local vk = f.val.k
			if vk == "table" or vk == "function" then ok = false end
		end
		if ok and #t.fs <= 4 then
			local o = {}
			for _, f in ipairs(t.fs) do o[#o + 1] = E(f.val) end
			return "{ " .. cat(o, ", ") .. " }"
		end
		local o = { "{\n" }
		local sv = dlevel
		dlevel = d + 1
		for _, f in ipairs(t.fs) do
			local line
			if f.t == "v" then line = E(f.val)
			elseif f.t == "r" then line = f.name .. " = " .. E(f.val)
			else line = "[" .. E(f.key) .. "] = " .. E(f.val) end
			o[#o + 1] = pad(d + 1) .. line .. ",\n"
		end
		dlevel = sv
		o[#o + 1] = pad(d) .. "}"
		return cat(o)
	end

	local dlevel = 0

	E = function(e)
		local k = e.k
		if k == "num" or k == "str" or k == "name" then return e.v end
		if k == "nil" then return "nil" end
		if k == "true" then return "true" end
		if k == "false" then return "false" end
		if k == "vararg" then return "..." end
		if k == "paren" then return "(" .. E(e.e) .. ")" end
		if k == "binop" then return E(e.l) .. " " .. e.op .. " " .. E(e.r) end
		if k == "unop" then
			local sp = e.op == "not" and " " or ""
			return e.op .. sp .. E(e.e)
		end
		if k == "index" then
			if e.dot then return E(e.o) .. "." .. e.key end
			return E(e.o) .. "[" .. E(e.ekey) .. "]"
		end
		if k == "call" then return E(e.o) .. "(" .. elist(e.args) .. ")" end
		if k == "mcall" then return E(e.o) .. ":" .. e.m .. "(" .. elist(e.args) .. ")" end
		if k == "table" then return ftable(e, dlevel) end
		if k == "function" then
			local va = e.va and (#e.ps > 0 and ", ..." or "...") or ""
			return "function(" .. cat(e.ps, ", ") .. va .. ")\n" .. stmts(e.body, dlevel + 1) .. pad(dlevel) .. "end"
		end
		return "--[[?]]"
	end

	stmts = function(list, d)
		local o = {}
		local prevD = dlevel
		dlevel = d
		for _, s in ipairs(list) do
			o[#o + 1] = pad(d) .. S(s, d) .. "\n"
		end
		dlevel = prevD
		return cat(o)
	end

	S = function(s, d)
		local k = s.k
		if k == "local" then
			local r = "local " .. cat(s.names, ", ")
			if s.es then r = r .. " = " .. elist(s.es) end
			return r
		elseif k == "assign" then
			local ls = {}
			for i = 1, #s.lhs do ls[i] = E(s.lhs[i]) end
			return cat(ls, ", ") .. " = " .. elist(s.es)
		elseif k == "compound" then
			return E(s.lhs) .. " " .. s.op .. " " .. E(s.e)
		elseif k == "callstat" then
			return E(s.e)
		elseif k == "do" then
			return "do\n" .. stmts(s.body, d + 1) .. pad(d) .. "end"
		elseif k == "while" then
			return "while " .. E(s.cond) .. " do\n" .. stmts(s.body, d + 1) .. pad(d) .. "end"
		elseif k == "repeat" then
			return "repeat\n" .. stmts(s.body, d + 1) .. pad(d) .. "until " .. E(s.cond)
		elseif k == "if" then
			local r = {}
			for i, c in ipairs(s.clauses) do
				r[#r + 1] = (i == 1 and "if " or (pad(d) .. "elseif ")) .. E(c.cond) .. " then\n" .. stmts(c.body, d + 1)
			end
			if s.els then r[#r + 1] = pad(d) .. "else\n" .. stmts(s.els, d + 1) end
			r[#r + 1] = pad(d) .. "end"
			return cat(r)
		elseif k == "fornum" then
			local h = "for " .. s.var .. " = " .. E(s.a) .. ", " .. E(s.b) .. (s.c and (", " .. E(s.c)) or "")
			return h .. " do\n" .. stmts(s.body, d + 1) .. pad(d) .. "end"
		elseif k == "forin" then
			return "for " .. cat(s.names, ", ") .. " in " .. elist(s.es) .. " do\n" .. stmts(s.body, d + 1) .. pad(d) .. "end"
		elseif k == "funcstat" then
			local nm = E(s.name) .. (s.method and (":" .. s.method) or "")
			local va = s.f.va and (#s.f.ps > 0 and ", ..." or "...") or ""
			return "function " .. nm .. "(" .. cat(s.f.ps, ", ") .. va .. ")\n" .. stmts(s.f.body, d + 1) .. pad(d) .. "end"
		elseif k == "localfunc" then
			local va = s.f.va and (#s.f.ps > 0 and ", ..." or "...") or ""
			return "local function " .. s.name .. "(" .. cat(s.f.ps, ", ") .. va .. ")\n" .. stmts(s.f.body, d + 1) .. pad(d) .. "end"
		elseif k == "return" then
			if s.es then return "return " .. elist(s.es) end
			return "return"
		elseif k == "break" then return "break"
		elseif k == "continue" then return "continue"
		elseif k == "goto" then return "goto " .. s.v
		elseif k == "label" then return "::" .. s.v .. "::"
		end
		return "--[[?stmt]]"
	end

	return function(ast) dlevel = 0 return stmts(ast, 0) end
end

function M.beautify(src, opts)
	if sub(src, 1, 3) == "\239\187\191" then src = sub(src, 4) end
	local ast = parse(lex(src))
	return (printer(opts)(ast):gsub("[ \t]+\n", "\n"))
end

function M.safe(src, opts)
	local ok, r = pcall(M.beautify, src, opts)
	if ok then return r end
	return src, r
end

return M
