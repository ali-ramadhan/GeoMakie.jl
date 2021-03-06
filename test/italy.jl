using Makie, GeoMakie
using GeoMakie.GeoJSON

# Acquire data
states = download("https://github.com/openpolis/geojson-italy/raw/master/geojson/limits_IT_provinces.geojson")
states_bytes = read(states)
geo = GeoJSONTables.read(states_bytes)

states_str = read(states, String)
using JSON

geo = GeoJSON.dict2geo(JSON.parse(states_str))

mesh(geo, strokecolor = :blue, strokewidth = 1, color = (blue, 0.5), shading = false)

polys = AbstractPlotting.convert_arguments(AbstractPlotting.Mesh, geo)

geoms = geo |> GeoInterface.features .|> GeoInterface.geometry

sc = Scene(; scale_plot = false)
meshes = GeoMakie.toMeshes.(geoms)
poly!.(meshes; shading = :false, color = (:blue, 0.5), strokecolor = :blue, strokewidth = 2)

AbstractPlotting.current_scene()
