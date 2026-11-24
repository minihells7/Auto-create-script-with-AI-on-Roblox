local Ring = {}
function Ring.new(cap)
	cap = math.max(1, math.floor(tonumber(cap) or 1))
	return { cap = cap, head = 1, tail = 1, count = 0,
			 pushed = 0, dropped = 0, popped = 0, cleared = 0, slots = {} }
end
function Ring.push(r, item)
	r.pushed = r.pushed + 1
	if r.count >= r.cap then
		r.dropped = r.dropped + 1
		return false
	end
	r.slots[r.head] = item
	r.head = r.head % r.cap + 1
	r.count = r.count + 1
	return true
end
function Ring.pop(r)
	if r.count == 0 then return nil end
	local item = r.slots[r.tail]
	r.slots[r.tail] = nil
	r.tail = r.tail % r.cap + 1
	r.count = r.count - 1
	r.popped = r.popped + 1
	return item
end
function Ring.clear(r)
	r.cleared = r.cleared + r.count
	r.count = 0
	r.head = 1
	r.tail = 1
	r.slots = {}
end
function Ring.invariantOk(r)
	return r.pushed - r.dropped - r.popped - r.cleared == r.count
end
