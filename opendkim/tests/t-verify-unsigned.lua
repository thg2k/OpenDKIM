-- $Id: t-verify-unsigned.lua,v 1.4 2010/06/01 05:01:55 cm-msk Exp $

-- Copyright (c) 2009, 2010, The OpenDKIM Project.  All rights reserved.

-- unsigned message test
-- 
-- Confirms that an unsigned message produces the correct result

mt.echo("*** unsigned message")

-- try to start the filter
binpath = mt.getcwd() .. "/.."
if os.getenv("srcdir") ~= nil then
	mt.chdir(os.getenv("srcdir"))
end
mt.startfilter(binpath .. "/opendkim", "-x", "t-verify-unsigned.conf")
mt.sleep(2)

-- try to connect to it
conn = mt.connect("inet:12345@localhost")
if conn == nil then
	error "mt.connect() failed"
end

-- send connection information
-- mt.negotiate() is called implicitly
if mt.conninfo(conn, "localhost", "127.0.0.1") ~= nil then
	error "mt.conninfo() failed"
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error "mt.conninfo() unexpected reply"
end

-- send envelope macros and sender data
-- mt.helo() is called implicitly
mt.macro(conn, SMFIC_MAIL, "j", "t-verify-revoked")
if mt.mailfrom(conn, "user@example.com") ~= nil then
	error "mt.mailfrom() failed"
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error "mt.mailfrom() unexpected reply"
end

-- send headers
-- mt.rcptto() is called implicitly
if mt.header(conn, "From", "user@example.com") ~= nil then
	error "mt.header(From) failed"
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error "mt.header(From) unexpected reply"
end
if mt.header(conn, "Date", "Tue, 22 Dec 2009 13:04:12 -0800") ~= nil then
	error "mt.header(Date) failed"
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error "mt.header(Date) unexpected reply"
end
if mt.header(conn, "Subject", "Signing test") ~= nil then
	error "mt.header(Subject) failed"
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error "mt.header(Subject) unexpected reply"
end

-- send EOH
if mt.eoh(conn) ~= nil then
	error "mt.eoh() failed"
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error "mt.eoh() unexpected reply"
end

-- send body
if mt.bodystring(conn, "This is a test!\r\n") ~= nil then
	error "mt.bodystring() failed"
end
if mt.getreply(conn) ~= SMFIR_SKIP then
	error "mt.bodystring() unexpected reply"
end

-- end of message; let the filter react
if mt.eom(conn) ~= nil then
	error "mt.eom() failed"
end
if mt.getreply(conn) ~= SMFIR_ACCEPT then
	error "mt.eom() unexpected reply"
end

-- verify that an Authentication-Results header field got added
if not mt.eom_check(conn, MT_HDRINSERT, "Authentication-Results") and
   not mt.eom_check(conn, MT_HDRADD, "Authentication-Results") then
	error "no Authentication-Results added"
end
ar = mt.getheader(conn, "Authentication-Results", 0)
if string.find(ar, "dkim=none", 1, true) == nil then
	error "incorrect DKIM result"
end