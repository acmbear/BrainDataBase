function s_out = traverse_struct(func, s_in)
s_out = s_in;
fnames = fieldnames(s_in);
for fn = 1 : length(fnames)
    s_out.(fnames{fn}) = func(s_in.(fnames{fn}));
end