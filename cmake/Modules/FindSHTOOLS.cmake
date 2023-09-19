# Copyright 2023 - David Minton
# This file is part of Swiftest.
# Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with Swiftest. 
# If not, see: https://www.gnu.org/licenses. 

# - Finds the SHTOOLS library
FIND_PATH(SHTOOLS_INCLUDE_DIR NAMES shtools.h HINTS ENV SHTOOLS_HOME PATH_SUFFIXES include)
FIND_LIBRARY(SHTOOLS_LIBRARY NAMES libSHTOOLS.a HINTS ENV SHTOOLS_HOME PATH_SUFFIXES lib)
FIND_LIBRARY(SHTOOLS_LIBRARY_MP NAMES libSHTOOLS-mp.a HINTS ENV SHTOOLS_HOME PATH_SUFFIXES lib)

SET(SHTOOLS_FOUND TRUE)
MARK_AS_ADVANCED(SHTOOLS_LIBRARY SHTOOLS_LIBRARY_MP SHTOOLS_INCLUDE_DIR)
MESSAGE(STATUS "SHTOOLS library: ${SHTOOLS_LIBRARY}")
MESSAGE(STATUS "SHTOOLS OpenMP library: ${SHTOOLS_LIBRARY_MP}")
MESSAGE(STATUS "SHTOOLS include dir: ${SHTOOLS_INCLUDE_DIR}")
