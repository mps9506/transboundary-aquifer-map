library(sf)
library(dplyr)
library(ggplot2)
library(scico)
library(rnaturalearth)
library(elevatr)
library(raster)
library(rayshader)


aquifers <- read_sf("data/a__2021_TBA_GGIS_utf8.shp")
countries <- ne_countries(scale = "large", country = c("United States of America", "Mexico"),
                          returnclass = "sf")

aquifers %>%
  as_tibble() %>%
  distinct(SOURCE) -> sources

aquifers <- aquifers %>%
  filter(SOURCE %in% c("Sanchez et al., 2018", "Sanchez and Rodriguez, 2021", "Sanchez and Rodriguez, 2021Sanchez and Rodriguez, 2021"))
# geometry isn't valid, need to fix in sf
aquifers <- st_make_valid(aquifers)

### should try a different elevation source ###

## get elevation raster
elevation <- elevatr::get_elev_raster(aquifers,
                                      src = "srtm15plus")

## get extent
map_extent <- extent(elevation)

## convert elevation raster to rayshader compatible matrix
e_mat <- raster_to_matrix(elevation)


aquifer_overlay <- generate_polygon_overlay(aquifers, extent = map_extent, heightmap = e_mat)
sphere_shade_overlay <- sphere_shade(e_mat, texture = 'imhof1', 
                                     zscale = 1, colorintensity = 5)
lambert_shadow_overlay <- lamb_shade(e_mat, zscale = 10)
text_shadow_overlay <- texture_shade(e_mat, detail = 2/10, contrast = 9, brightness = 11)

e_mat %>%
  height_shade(texture = scico(256, palette = "oleron")) %>%
  add_overlay(aquifer_overlay) %>%
  add_overlay(sphere_shade_overlay, alphalayer=0.5) %>%
  add_shadow(lambert_shadow_overlay, 0.7) %>%
  add_shadow(text_shadow_overlay, 0.5) %>%
  #add_water(detect_water(e_mat), color = "imhof1") %>%
  plot_3d(e_mat,
          zscale = 15,
          water = TRUE)
