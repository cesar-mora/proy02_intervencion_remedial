#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Creado Jul 13 09:44:13 2021

@autor: analistaup29
"""

# Objetivo: Realizar nearest matching para focalización.

# Importar librerias
import numpy as np
import pandas as pd
import geopandas as gpd 
import folium 
import shapely
from shapely.ops import nearest_points
from shapely.geometry import LineString

# Incluir ruta y descargar data a nivel de IE
route_bd_nivel_ie = '/Users/bran/Documents/GitHub/intervencion_remedial/data/clean/data_clean.dta'
bd_nivel_ie =    pd.read_stata(route_bd_nivel_ie)

# Mantenemos variables relevantes
bd_nivel_ie = bd_nivel_ie[["cod_mod_anexo","NLAT_IE","NLONG_IE",'ind_eib_lengua1', "ind_eib_lengua2","ind_lenguaje_ece_prim", "ind_mate_ece_prim","ind_lenguaje_ece_sec", "ind_mate_ece_sec", "D_NIV_MOD", "eib"]]

## Match Primaria

# Mantenemos a Primaria

# Generamos indicador de participación en ECE
bd_nivel_ie['ece'] = np.where(bd_nivel_ie['ind_lenguaje_ece_prim'].isnull(), 0, 1)

primaria = (bd_nivel_ie['D_NIV_MOD'] == 'Primaria')

bd_nivel_ie = bd_nivel_ie[primaria]

# Generamos bd para IIEE que no participaron y para las que participaron en ECE 2018 o 2019
no_ece = bd_nivel_ie["ece"] == 0
ece = bd_nivel_ie["ece"] == 1

bd_no_ece = bd_nivel_ie[no_ece]
bd_ece = bd_nivel_ie[ece]

# Convertimos bases de datos a GeoPandas
def create_gdf(df, x='NLONG_IE', y='NLAT_IE'): return gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df[y], df[x]), crs={'init':'EPSG:4326'})

no_ece_gdf = create_gdf(bd_no_ece)
ece_gdf = create_gdf(bd_ece)

# Visualizamos la data en un mapa
m = folium.Map([-11.8965667, -77.043225], 
               tiles="CartoDb dark_matter")
locs_ece = zip(ece_gdf.NLAT_IE, ece_gdf.NLONG_IE)
locs_no_ece = zip(no_ece_gdf.NLAT_IE, no_ece_gdf.NLONG_IE)
for location in locs_ece: 
    folium.CircleMarker(location=location, color="red", radius=4).add_to(m)
for location in locs_no_ece: 
    folium.CircleMarker(location=location, color="white", radius = 2).add_to(m)    

m.save("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/map_points_primaria.html")

# Realizamos el nearest neigbhor matching

# Definimos función para el cálculo del nearest neighbor
def calculate_nearest(row, destination, val, col="geometry"):
    dest_unary = destination["geometry"].unary_union
    nearest_geom = nearest_points(row[col], dest_unary)
    match_geom = destination.loc[destination.geometry == nearest_geom[1]]
    match_value = match_geom[val].to_numpy()[0]
    return match_value

# Generamos la geometría más cercana
no_ece_gdf["geom_cercano"] = no_ece_gdf.apply(calculate_nearest, destination=ece_gdf, val="geometry", axis=1)
no_ece_gdf["cod_mod_anexo_cercano"] = no_ece_gdf.apply(calculate_nearest, destination=ece_gdf, val="cod_mod_anexo", axis=1)

# Crear geometría LineString
no_ece_gdf['line'] = no_ece_gdf.apply(lambda row: LineString([row['geometry'], row['geom_cercano']]), axis=1)

# Crear geometría Geodataframe
line_gdf = no_ece_gdf[["cod_mod_anexo_cercano", "line"]].set_geometry('line')
line_gdf = line_gdf.geometry.map(lambda polygon: shapely.ops.transform(lambda x, y: (y, x), polygon)) # Swap x and y coordinates
line_gdf.crs = crs={"init":"epsg:4326"} # Determinar coordenada de referencia


# Guardamos variables
no_ece_gdf.to_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/no_ece_gdf_primaria.pkl")
line_gdf.to_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/line_gdf_primaria.pkl")

no_ece_gdf = pd.read_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/no_ece_gdf_primaria.pkl")
line_gdf = pd.read_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/line_gdf_primaria.pkl")

# Graficamos en mapa y exportamos

style_line = {'fillColor': '#004EFF', 'color': '#004EFF', "weight" : 4, 'lineColor': '#004EFF'}

m = folium.Map([-11.8965667, -77.043225],
               zoom_start = 12, 
               tiles="CartoDb dark_matter")
locs_ece = zip(ece_gdf.NLAT_IE, ece_gdf.NLONG_IE)
locs_no_ece = zip(no_ece_gdf.NLAT_IE, no_ece_gdf.NLONG_IE)
for location in locs_ece:
    folium.CircleMarker(location=location, color="red", radius=8).add_to(m)
for location in locs_no_ece:
    folium.CircleMarker(location=location, color="white", radius=4).add_to(m)
folium.GeoJson(line_gdf,style_function=lambda x:style_line).add_to(m)
m.save("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/map_points_with_line_primaria.html")

##### Exportar data

# Mantener codigo modular, anexo y codigo modular de IIEE cercana
nearest_neighbor = no_ece_gdf[["cod_mod_anexo","cod_mod_anexo_cercano"]]

# Realizar merge con data de ECE 
nearest_neighbor = pd.merge(left= nearest_neighbor, right= bd_ece, how = 'left', left_on = 'cod_mod_anexo_cercano', right_on = 'cod_mod_anexo')

# Cambiar nombres, mantener variables
nearest_neighbor = nearest_neighbor[["cod_mod_anexo_x","ece","ind_lenguaje_ece_prim", "ind_mate_ece_prim"]]
nearest_neighbor = nearest_neighbor.rename(columns={"cod_mod_anexo_x": "cod_mod_anexo", "ece": "ece_imputado", "ind_lenguaje_ece_prim": "ind_leng_prim_imp", "ind_mate_ece_prim": "ind_mate_prim_imp"})

# Exportar
nearest_neighbor.to_csv("/Users/bran/Documents/GitHub/intervencion_remedial/data/raw/imputacion_ece_primaria.csv")


## Match Secundaria

# Incluir ruta y descargar data a nivel de IE
route_bd_nivel_ie = '/Users/bran/Documents/GitHub/intervencion_remedial/data/clean/data_clean.dta'
bd_nivel_ie =    pd.read_stata(route_bd_nivel_ie)

# Mantenemos variables relevantes
bd_nivel_ie = bd_nivel_ie[["cod_mod_anexo","NLAT_IE","NLONG_IE",'ind_eib_lengua1', "ind_eib_lengua2","ind_lenguaje_ece_prim", "ind_mate_ece_prim","ind_lenguaje_ece_sec", "ind_mate_ece_sec", "D_NIV_MOD", "eib"]]


# Mantenemos a Secundaria

bd_nivel_ie['ece'] = np.where(bd_nivel_ie['ind_lenguaje_ece_sec'].isnull(), 0, 1)

secundaria = (bd_nivel_ie['D_NIV_MOD'] == 'Secundaria')

bd_nivel_ie = bd_nivel_ie[secundaria]

# Generamos bd para IIEE que no participaron y para las que participaron en ECE 2018 o 2019
no_ece = bd_nivel_ie["ece"] == 0
ece = bd_nivel_ie["ece"] == 1

bd_no_ece = bd_nivel_ie[no_ece]
bd_ece = bd_nivel_ie[ece]

# Convertimos bases de datos a GeoPandas
def create_gdf(df, x='NLONG_IE', y='NLAT_IE'): return gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df[y], df[x]), crs={'init':'EPSG:4326'})

no_ece_gdf = create_gdf(bd_no_ece)
ece_gdf = create_gdf(bd_ece)

# Visualizamos la data en un mapa
m = folium.Map([-11.8965667, -77.043225], 
               tiles="CartoDb dark_matter")
locs_ece = zip(ece_gdf.NLAT_IE, ece_gdf.NLONG_IE)
locs_no_ece = zip(no_ece_gdf.NLAT_IE, no_ece_gdf.NLONG_IE)
for location in locs_ece: 
    folium.CircleMarker(location=location, color="red", radius=4).add_to(m)
for location in locs_no_ece: 
    folium.CircleMarker(location=location, color="white", radius = 2).add_to(m)    

m.save("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/map_points_secundaria.html")

# Realizamos el nearest neigbhor matching

# Definimos función para el cálculo del nearest neighbor
def calculate_nearest(row, destination, val, col="geometry"):
    dest_unary = destination["geometry"].unary_union
    nearest_geom = nearest_points(row[col], dest_unary)
    match_geom = destination.loc[destination.geometry == nearest_geom[1]]
    match_value = match_geom[val].to_numpy()[0]
    return match_value

# Generamos la geometría más cercana
no_ece_gdf["geom_cercano"] = no_ece_gdf.apply(calculate_nearest, destination=ece_gdf, val="geometry", axis=1)
no_ece_gdf["cod_mod_anexo_cercano"] = no_ece_gdf.apply(calculate_nearest, destination=ece_gdf, val="cod_mod_anexo", axis=1)

# Crear geometría LineString
no_ece_gdf['line'] = no_ece_gdf.apply(lambda row: LineString([row['geometry'], row['geom_cercano']]), axis=1)

# Crear geometría Geodataframe
line_gdf = no_ece_gdf[["cod_mod_anexo_cercano", "line"]].set_geometry('line')
line_gdf = line_gdf.geometry.map(lambda polygon: shapely.ops.transform(lambda x, y: (y, x), polygon)) # Swap x and y coordinates
line_gdf.crs = crs={"init":"epsg:4326"} # Determinar coordenada de referencia


# Guardamos variables
no_ece_gdf.to_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/no_ece_gdf_secundaria.pkl")
line_gdf.to_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/line_gdf_secundaria.pkl")

no_ece_gdf = pd.read_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/no_ece_gdf_secundaria.pkl")
line_gdf = pd.read_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/line_gdf_secundaria.pkl")

# Graficamos en mapa y exportamos

style_line = {'fillColor': '#004EFF', 'color': '#004EFF', "weight" : 4, 'lineColor': '#004EFF'}

m = folium.Map([-11.8965667, -77.043225],
               zoom_start = 12, 
               tiles="CartoDb dark_matter")
locs_ece = zip(ece_gdf.NLAT_IE, ece_gdf.NLONG_IE)
locs_no_ece = zip(no_ece_gdf.NLAT_IE, no_ece_gdf.NLONG_IE)
for location in locs_ece:
    folium.CircleMarker(location=location, color="red", radius=8).add_to(m)
for location in locs_no_ece:
    folium.CircleMarker(location=location, color="white", radius=4).add_to(m)
folium.GeoJson(line_gdf,style_function=lambda x:style_line).add_to(m)
m.save("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/map_points_with_line_secundaria.html")

##### Exportar data

# Mantener codigo modular, anexo y codigo modular de IIEE cercana
nearest_neighbor = no_ece_gdf[["cod_mod_anexo","cod_mod_anexo_cercano"]]

# Realizar merge con data de ECE 
nearest_neighbor = pd.merge(left= nearest_neighbor, right= bd_ece, how = 'left', left_on = 'cod_mod_anexo_cercano', right_on = 'cod_mod_anexo')

# Cambiar nombres, mantener variables
nearest_neighbor = nearest_neighbor[["cod_mod_anexo_x","ece","ind_lenguaje_ece_sec", "ind_mate_ece_sec"]]
nearest_neighbor = nearest_neighbor.rename(columns={"cod_mod_anexo_x": "cod_mod_anexo", "ece": "ece_imputado", "ind_lenguaje_ece_sec": "ind_leng_sec_imp", "ind_mate_ece_sec": "ind_mate_sec_imp"})

# Exportar
nearest_neighbor.to_csv("/Users/bran/Documents/GitHub/intervencion_remedial/data/raw/imputacion_ece_secundaria.csv")

## Match EIB

# Incluir ruta y descargar data a nivel de IE
route_bd_nivel_ie = '/Users/bran/Documents/GitHub/intervencion_remedial/data/clean/data_clean.dta'
bd_nivel_ie =    pd.read_stata(route_bd_nivel_ie)

# Mantenemos variables relevantes
bd_nivel_ie = bd_nivel_ie[["cod_mod_anexo","NLAT_IE","NLONG_IE",'ind_eib_lengua1', "ind_eib_lengua2","ind_lenguaje_ece_prim", "ind_mate_ece_prim","ind_lenguaje_ece_sec", "ind_mate_ece_sec", "D_NIV_MOD", "eib"]]


# Mantenemos a eib

bd_nivel_ie['ece'] = np.where(bd_nivel_ie['ind_eib_lengua1'].isnull(), 0, 1)

eib = (bd_nivel_ie['eib'] == 1)

bd_nivel_ie = bd_nivel_ie[eib]

# Generamos bd para IIEE que no participaron y para las que participaron en ECE EIB
no_ece = bd_nivel_ie["ece"] == 0
ece = bd_nivel_ie["ece"] == 1

bd_no_ece = bd_nivel_ie[no_ece]
bd_ece = bd_nivel_ie[ece]

# Convertimos bases de datos a GeoPandas
def create_gdf(df, x='NLONG_IE', y='NLAT_IE'): return gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df[y], df[x]), crs={'init':'EPSG:4326'})

no_ece_gdf = create_gdf(bd_no_ece)
ece_gdf = create_gdf(bd_ece)

# Visualizamos la data en un mapa
m = folium.Map([-11.8965667, -77.043225], 
               tiles="CartoDb dark_matter")
locs_ece = zip(ece_gdf.NLAT_IE, ece_gdf.NLONG_IE)
locs_no_ece = zip(no_ece_gdf.NLAT_IE, no_ece_gdf.NLONG_IE)
for location in locs_ece: 
    folium.CircleMarker(location=location, color="red", radius=4).add_to(m)
for location in locs_no_ece: 
    folium.CircleMarker(location=location, color="white", radius = 2).add_to(m)    

m.save("/Users/bran/Desktop/map_points_eib.html")

# Realizamos el nearest neigbhor matching

# Definimos función para el cálculo del nearest neighbor
def calculate_nearest(row, destination, val, col="geometry"):
    dest_unary = destination["geometry"].unary_union
    nearest_geom = nearest_points(row[col], dest_unary)
    match_geom = destination.loc[destination.geometry == nearest_geom[1]]
    match_value = match_geom[val].to_numpy()[0]
    return match_value

# Generamos la geometría más cercana
no_ece_gdf["geom_cercano"] = no_ece_gdf.apply(calculate_nearest, destination=ece_gdf, val="geometry", axis=1)
no_ece_gdf["cod_mod_anexo_cercano"] = no_ece_gdf.apply(calculate_nearest, destination=ece_gdf, val="cod_mod_anexo", axis=1)

# Crear geometría LineString
no_ece_gdf['line'] = no_ece_gdf.apply(lambda row: LineString([row['geometry'], row['geom_cercano']]), axis=1)

# Crear geometría Geodataframe
line_gdf = no_ece_gdf[["cod_mod_anexo_cercano", "line"]].set_geometry('line')
line_gdf = line_gdf.geometry.map(lambda polygon: shapely.ops.transform(lambda x, y: (y, x), polygon)) # Swap x and y coordinates
line_gdf.crs = crs={"init":"epsg:4326"} # Determinar coordenada de referencia


# Guardamos variables
no_ece_gdf.to_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/no_ece_gdf_eib.pkl")
line_gdf.to_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/line_gdf_eib.pkl")

no_ece_gdf = pd.read_pickle("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/no_ece_gdf_eib.pkl")
line_gdf = pd.read_pickle("//Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/line_gdf_eib.pkl")

# Graficamos en mapa y exportamos

style_line = {'fillColor': '#004EFF', 'color': '#004EFF', "weight" : 4, 'lineColor': '#004EFF'}

m = folium.Map([-11.8965667, -77.043225],
               zoom_start = 12, 
               tiles="CartoDb dark_matter")
locs_ece = zip(ece_gdf.NLAT_IE, ece_gdf.NLONG_IE)
locs_no_ece = zip(no_ece_gdf.NLAT_IE, no_ece_gdf.NLONG_IE)
for location in locs_ece:
    folium.CircleMarker(location=location, color="red", radius=8).add_to(m)
for location in locs_no_ece:
    folium.CircleMarker(location=location, color="white", radius=4).add_to(m)
folium.GeoJson(line_gdf,style_function=lambda x:style_line).add_to(m)
m.save("/Users/bran/Documents/GitHub/intervencion_remedial/output/mapas/map_points_with_line_eib.html")

##### Exportar data

# Mantener codigo modular, anexo y codigo modular de IIEE cercana
nearest_neighbor = no_ece_gdf[["cod_mod_anexo","cod_mod_anexo_cercano"]]

# Realizar merge con data de ECE 
nearest_neighbor = pd.merge(left= nearest_neighbor, right= bd_ece, how = 'left', left_on = 'cod_mod_anexo_cercano', right_on = 'cod_mod_anexo')

# Cambiar nombres, mantener variables
nearest_neighbor = nearest_neighbor[["cod_mod_anexo_x","ece","ind_eib_lengua1", "ind_eib_lengua2"]]
nearest_neighbor = nearest_neighbor.rename(columns={"cod_mod_anexo_x": "cod_mod_anexo", "ece": "ece_imputado", "ind_eib_lengua1": "ind_eib_lengua1_imp", "ind_eib_lengua2": "ind_eib_lengua2_imp"})

# Exportar
nearest_neighbor.to_csv("/Users/bran/Documents/GitHub/intervencion_remedial/data/raw/imputacion_ece_eib.csv")
