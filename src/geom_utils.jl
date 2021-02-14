using ArchGDAL; const AG = ArchGDAL
using Distances
using TypedTables

function linpol(ax, bx, ay, by, x)
    # ax, bx = sort([ax, bx])
    factor = (x - ax) / (bx - ax)
    ay + (by - ay) * factor
end

function z_along_line(line, point)
    x = AG.getx(point, 0)
    # point left of line, take first z
    fx, fy, fz = AG.getpoint(line, 0)
    lx, ly, lz = AG.getpoint(line, AG.ngeom(line) - 1)
    fx, lx = sort([fx, lx])
    if x <= fx
        return fz
    elseif x >= lx
        return lz
    else
        for i ∈ 1:AG.ngeom(line) - 2
            xa, ay, za = AG.getpoint(line, i)
            xb, by, zb = AG.getpoint(line, i + 1)
            if xa < x < xb || xa > x > xb
                return linpol(xa, xb, za, zb, x)
            end
        end
    end
    0.
end

"""Split a linestring if the next point is further than `distance`.
Not using Haversine here, as we want to split on meridians and such."""
function splitline(line::AG.IGeometry, distance=1.)
    points = [AG.getpoint(line, i - 1) for i in 1:AG.ngeom(line)]
    splits = Vector{Int}([0])
    for i ∈ 1:length(points) - 1
        d = Euclidean()(points[i][1:2], points[i + 1][1:2])
        if d > distance
            push!(splits, i)
        end
    end
    if length(splits) == 1
        return line
    else
        lines = Vector{Vector{Tuple{Float64,Float64,Float64}}}()
        push!(splits, length(points))
        @info splits
        for i ∈ 1:length(splits) - 1
            line = points[splits[i] + 1:splits[i + 1]]
            push!(lines, line)
        end
        return AG.createmultilinestring(lines)
    end
end

function splitline(table::TypedTables.Table, distance=1.)
    rows = Vector{NamedTuple}()
    for row in table
        geom = splitline(row.geom, distance)
        if AG.getgeomtype(geom) == AG.GDAL.wkbMultiLineString25D
            for i in 1:AG.ngeom(geom)
                push!(rows, merge(row, (geom = AG.getgeom(geom, i - 1),)))
            end
        else
            push!(rows, merge(row, (geom = geom,)))
        end
    end
    Table(rows)
end
