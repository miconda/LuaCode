-- The RawMessage class that represents plan email messages.

RawMessage = {}

RawMessage._mt = {}
setmetatable(RawMessage, RawMessage._mt)

function RawMessage.new(self, message)
    _check_required(message, 'string')

    local object = {}

    object._type = 'rawmessage'

    for key, value in pairs(RawMessage) do
        if (type(value) == 'function') then
            object[key] = value
        end
    end

    object._mt = {}
    setmetatable(object, object._mt)

    object._message = message

    object._eohpos  = nil
    object._eohval  = nil
    object._eohlen  = nil
    object._bodypos = nil
    object._flags = nil
    object._size = nil
    object._date = nil

    return object
end

function RawMessage.get_message(self)
    return self._message
end

function RawMessage._update_eohpos(self)
	if self._eohlen == 4 then
		self._eohpos = string.find(self._message, "\r\n\r\n")
	else
		self._eohpos = string.find(self._message, "\n\n")
	end
end

function RawMessage._set_eoh(self)
	local pos = string.find(self._message, "\n")
	local prev = string.sub(self._message, pos-1, pos-1)
	if(prev=="\r") then
		self._eohpos = string.find(self._message, "\r\n\r\n")
		self._eohval = "\r\n"
		self._eohlen = 4
		self._bodypos = self._eohpos + 4
	else
		self._eohpos = string.find(self._message, "\n\n")
		self._eohval = "\n"
		self._eohlen = 2
		self._bodypos = self._eohpos + 2
	end
end

function RawMessage.get_eohpos(self)
	if self._eohpos == nil then
		self:_set_eoh()
	end
	return self._eohpos
end

function RawMessage.get_eohval(self)
	if self._eohval == nil then
		self:_set_eoh()
	end
	return self._eohval
end

function RawMessage.get_bodypos(self)
	if self._bodypos == nil then
		self:_set_eoh()
	end
	return self._bodypos
end

function RawMessage.set_flags(self, flags)
    _check_required(flags, 'table')
	
	self._flags = flags
end


function RawMessage.reset_flags(self)
	self._flags = nil
end

function RawMessage.get_flags(self)
	return self._flags
end

function RawMessage.get_flags_string(self)
	if self._flags == nil then
		return ''
	end
	return table.concat(self._flags, ' ')
end

function RawMessage.set_date(self, date)
    _check_required(date, 'string')

	self._date = date
end

function RawMessage.get_date(self)
	if self._date == nil then
		return ''
	end
	return self._date
end

function RawMessage.get_size(self)
	if self._size == nil then
		self._size = self._message:len()
	end
	return self._size
end

function RawMessage.add_header(self, hdr)
	eohpos = self:get_eohpos()
	eohval = self:get_eohval()
	self._message = string.sub(self._message, 1, eohpos)..eohval..hdr..string.sub(self._message, eohpos)
	self:_update_eohpos()
	return true
end

function RawMessage.set_header(self, hname, hbody)
	eohpos = self:get_eohpos()
	eohval = self:get_eohval()
	pstart = string.find(self._message, hname..": ", 1, true);
	if not pstart then
		return self:add_header(hname..": "..hbody)
	end
	if pstart > eohpos then
		return self:add_header(hname..": "..hbody)
	end
	pend = string.find(self._message, eohval, pstart)
	if not pend then
		return self:add_header(hname..": "..hbody)
	end
	if pos==1 then
		self._message = hname..": "..hbody..string.sub(self._message, pend)
	else
		self._message = string.sub(self._message, 1, pstart-1)..hname..": "..hbody..string.sub(self._message, pend)
	end
	self:_update_eohpos()
	return true
end

function RawMessage.prefix_header(self, hname, hbody)
	eohpos = self:get_eohpos()
	eohval = self:get_eohval()
	pstart = string.find(self._message, hname..": ", 1, true);
	if not pstart then
		return true
	end
	if pstart > eohpos then
		return true
	end
	pstart = pstart + string.len(hname) + 1;
	self._message = string.sub(self._message, 1, pstart)..hbody..string.sub(self._message, pstart+1)
	self:_update_eohpos()
	return true
end

function RawMessage.suffix_header(self, hname, hbody)
	eohpos = self:get_eohpos()
	eohval = self:get_eohval()
	pstart = string.find(self._message, hname..": ", 1, true);
	if not pstart then
		return true
	end
	if pstart > eohpos then
		return true
	end
	pend = string.find(self._message, eohval, pstart)
	if not pend then
		return true
	end
	self._message = string.sub(self._message, 1, pend-1)..hbody..string.sub(self._message, pend)
	self:_update_eohpos()
end


RawMessage._mt.__call = RawMessage.new
RawMessage._mt.__index = function () end
RawMessage._mt.__newindex = function () end
