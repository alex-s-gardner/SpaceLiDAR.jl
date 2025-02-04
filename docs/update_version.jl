# Post script to run to generate a mike compatible json file
# from the javascripts versions file generated by Documenter.
# This enables a version dropdown to be present in all documentation.
using JSON

versions = read("versions.js", String)
re = r"DOC_VERSIONS\s?=\s?\[([^][]*)]"
m = match(re, versions)
if m === nothing
    error("Can't parse versions.js correctly")
else
    group = String(m.captures[1])
    group = replace(group, "\n" => "")
    group = replace(group, "\"" => "")
    group = replace(group, " " => "")
    json = []
    for version in split(group, ",")
        if length(version) > 0
            push!(json,Dict(
                "version" => version,
                "title" => version,
                "aliases" => []
            ))
        end
    end
end
write("versions.json", JSON.json(json))
