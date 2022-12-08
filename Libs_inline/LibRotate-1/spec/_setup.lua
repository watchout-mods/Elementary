function strjoin(sep, ...)
	print("TODO: avoid the call to this function");
	local args = {...};
	for i=1, #args do
		args[i] = tostring(args[i]);
	end
	return table.concat(args, sep);
end

function tostringall(...)
	print("FIXME: remove the call to this function");
	local args = {...};
	for i=1, #args do
		args[i] = tostring(args[i]);
	end
	return unpack(args);
end

require("spec/LibStub");
require("LibRotate-1");

return LibStub("LibRotate-1");