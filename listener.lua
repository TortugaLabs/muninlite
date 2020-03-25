--
-- Simple LUA written listener for running munin-lite
-- on a OpenWRT distro without inetd
--

listen = "*"
port = 8080
command = "uptime"
bg = false

for i = 1, #arg do
  if arg[i] == "-L" then
    listen = "*"
  elseif arg[i]:sub(1,2) == "-l" then
    listen = arg[i]:sub(3)
  elseif arg[i]:sub(1,2) == "-p" then
    port = tonumber(arg[i]:sub(3))
  elseif arg[i] == "-D" then
    bg = true
  elseif arg[i] == "-no-D" then
    bg = false
  else
    command = arg[i]
  end
end

local nixio = require("nixio")

--~ print("Binding (" .. command .. ") to " ..listen.. "' and port " ..port.. "...")

s = assert(nixio.bind(listen, port))
s:listen(5)
i, p = s:getsockname()
assert(i, p)

--~ print("Waiting connection from talker on " .. i .. ":" .. p .. " (".. s:fileno() ..")...")

if bg then
  -- running in the background...
  p = nixio.fork()
  if p ~= 0 then
    -- parent process...
    print("Running PID " .. p .. " in the background")
    os.exit(0)
  end
end

while 1 do
  c = s:accept()
  assert(c)
  peer, port = c:getpeername()
  --~ print("Connected. " .. peer .. ":" .. port)
  p = nixio.fork()
  if p == 0 then
    s:close()
    nixio.dup(c, nixio.stdin)
    nixio.dup(c, nixio.stdout)
    nixio.dup(c, nixio.stderr)
    c:close()

    -- nixio.exec(command)
    os.execute(command)
    os.exit(0)
  else
    c:close()
  end
  -- Reap stuff

  repeat
    a = nixio.waitpid(-1,"nohang")
  until a  
end
