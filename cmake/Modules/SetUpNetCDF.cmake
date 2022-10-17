# Find NetCDF if not already found
IF(NOT NETCDF_FOUND)
    ENABLE_LANGUAGE(C) # Some libraries need a C compiler to find 
    FIND_PACKAGE(netcdf REQUIRED)
    SET(NETCDF_FOUND TRUE CACHE INTERNAL "NETCDF was found" FORCE)
    SET(NETCDF_LIBRARIES ${NETCDF_LIBRARIES} CACHE INTERNAL "NETCDF LIBS" FORCE)
    #SET(NETCDFFORTRAN_FOUND TRUE CACHE INTERNAL "NETCDF-FORTRAN was found" FORCE)
    #SET(NETCDFFORTRAN_LIBRARIES ${NETCDFFORTRAN_LIBRARIES} CACHE INTERNAL "NETCDFFORTRAN LIBS" FORCE)
ENDIF(NOT NETCDF_FOUND)
