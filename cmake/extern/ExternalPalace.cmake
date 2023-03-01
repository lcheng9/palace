# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

#
# Build Palace
#

# Force build order
if(PALACE_WITH_GSLIB)
  set(PALACE_DEPENDENCIES gslib)
else()
  set(PALACE_DEPENDENCIES petsc)
endif()

set(PALACE_OPTIONS ${PALACE_SUPERBUILD_DEFAULT_ARGS})
list(APPEND PALACE_OPTIONS
  "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
  "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
  "-DPALACE_WITH_OPENMP=${PALACE_WITH_OPENMP}"
  "-DPALACE_WITH_GSLIB=${PALACE_WITH_GSLIB}"
  "-DPALACE_WITH_SUPERLU=${PALACE_WITH_SUPERLU}"
  "-DPALACE_WITH_STRUMPACK=${PALACE_WITH_STRUMPACK}"
  "-DPALACE_WITH_MUMPS=${PALACE_WITH_MUMPS}"
  "-DPALACE_WITH_SLEPC=${PALACE_WITH_SLEPC}"
  "-DPALACE_WITH_ARPACK=${PALACE_WITH_ARPACK}"
  "-DPALACE_WITH_INTERNAL_JSON=ON"
  "-DPALACE_WITH_INTERNAL_FMT=ON"
  "-DPALACE_WITH_INTERNAL_MFEM=ON"
  "-DANALYZE_SOURCES_CLANG_TIDY=${ANALYZE_SOURCES_CLANG_TIDY}"
  "-DANALYZE_SOURCES_CPPCHECK=${ANALYZE_SOURCES_CPPCHECK}"
  "-DPETSC_DIR=${CMAKE_INSTALL_PREFIX}"
  "-DARPACK_DIR=${CMAKE_INSTALL_PREFIX}"
)
if(PALACE_WITH_STRUMPACK OR PALACE_WITH_MUMPS OR PALACE_WITH_ARPACK)
  list(APPEND PALACE_OPTIONS
    "-DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}"
    "-DCMAKE_Fortran_FLAGS=${CMAKE_Fortran_FLAGS}"
  )
endif()

# Configure MFEM dependencies
list(APPEND PALACE_OPTIONS
  "-DMETIS_LIBRARIES=${METIS_LIBRARIES}"
  "-DMETIS_INCLUDE_DIRS=${METIS_INCLUDE_DIRS}"
  "-DHYPRE_DIR=${CMAKE_INSTALL_PREFIX}"
  "-DHYPRE_REQUIRED_LIBRARIES=${BLAS_LAPACK_LIBRARIES}"
)
if(PALACE_WITH_SUPERLU OR PALACE_WITH_STRUMPACK)
  list(APPEND PALACE_OPTIONS
    "-DParMETIS_DIR=${CMAKE_INSTALL_PREFIX}"
  )
endif()

# Need to pass gfortran (or similar) dependency to C++ linker for MFEM link line
if(PALACE_WITH_STRUMPACK OR PALACE_WITH_MUMPS)
  if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      set(STRUMPACK_MUMPS_GFORTRAN_LIBRARY gfortran)
    else()
      find_library(STRUMPACK_MUMPS_GFORTRAN_LIBRARY
        NAMES gfortran
        PATHS ${CMAKE_Fortran_IMPLICIT_LINK_DIRECTORIES}
        NO_DEFAULT_PATH
        REQUIRED
      )
    endif()
  elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel|IntelLLVM")
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Intel|IntelLLVM")
      message(FATAL_ERROR "Intel Fortran compiler detected but not compatible without \
Intel C++ compiler for MUMPS and STRUMPACK dependencies")
    endif()
    set(STRUMPACK_MUMPS_GFORTRAN_LIBRARY ifport$<SEMICOLON>ifcore)
  endif()
endif()

# Configure SuperLU_DIST
if(PALACE_WITH_SUPERLU)
  set(SUPERLU_REQUIRED_PACKAGES "ParMETIS" "METIS" "MPI")
  if(PALACE_WITH_OPENMP)
    list(APPEND SUPERLU_REQUIRED_PACKAGES "OpenMP")
  endif()
  string(REPLACE ";" "$<SEMICOLON>" SUPERLU_REQUIRED_PACKAGES "${SUPERLU_REQUIRED_PACKAGES}")
  list(APPEND PALACE_OPTIONS
    "-DSuperLUDist_DIR=${CMAKE_INSTALL_PREFIX}"
    "-DSuperLUDist_REQUIRED_PACKAGES=${SUPERLU_REQUIRED_PACKAGES}"
    "-DSuperLUDist_REQUIRED_LIBRARIES=${BLAS_LAPACK_LIBRARIES}"
  )
endif()

# Configure STRUMPACK
if(PALACE_WITH_STRUMPACK)
  set(STRUMPACK_REQUIRED_PACKAGES "ParMETIS" "METIS" "MPI" "MPI_Fortran")
  if(PALACE_WITH_OPENMP)
    list(APPEND STRUMPACK_REQUIRED_PACKAGES "OpenMP")
  endif()
  string(REPLACE ";" "$<SEMICOLON>" STRUMPACK_REQUIRED_PACKAGES "${STRUMPACK_REQUIRED_PACKAGES}")
  set(STRUMPACK_REQUIRED_LIBRARIES)
  if(NOT "${STRUMPACK_EXTRA_LIBRARIES}" STREQUAL "")
    list(APPEND STRUMPACK_REQUIRED_LIBRARIES ${STRUMPACK_EXTRA_LIBRARIES})
  endif()
  list(APPEND STRUMPACK_REQUIRED_LIBRARIES ${SCALAPACK_LIBRARIES} ${BLAS_LAPACK_LIBRARIES} ${STRUMPACK_MUMPS_GFORTRAN_LIBRARY})
  string(REPLACE ";" "$<SEMICOLON>" STRUMPACK_REQUIRED_LIBRARIES "${STRUMPACK_REQUIRED_LIBRARIES}")
  list(APPEND PALACE_OPTIONS
    "-DSTRUMPACK_DIR=${CMAKE_INSTALL_PREFIX}"
    "-DSTRUMPACK_REQUIRED_PACKAGES=${STRUMPACK_REQUIRED_PACKAGES}"
    "-DSTRUMPACK_REQUIRED_LIBRARIES=${STRUMPACK_REQUIRED_LIBRARIES}"
  )
endif()

# Configure MUMPS
if(PALACE_WITH_MUMPS)
  set(MUMPS_REQUIRED_PACKAGES "METIS" "MPI" "MPI_Fortran" "Threads")
  if(PALACE_WITH_OPENMP)
    list(APPEND MUMPS_REQUIRED_PACKAGES "OpenMP")
  endif()
  string(REPLACE ";" "$<SEMICOLON>" MUMPS_REQUIRED_PACKAGES "${MUMPS_REQUIRED_PACKAGES}")
  list(APPEND PALACE_OPTIONS
    "-DMUMPS_DIR=${CMAKE_INSTALL_PREFIX}"
    "-DMUMPS_REQUIRED_PACKAGES=${MUMPS_REQUIRED_PACKAGES}"
    "-DMUMPS_REQUIRED_LIBRARIES=${SCALAPACK_LIBRARIES}$<SEMICOLON>${BLAS_LAPACK_LIBRARIES}$<SEMICOLON>${STRUMPACK_MUMPS_GFORTRAN_LIBRARY}"
  )
endif()

# Configure GSLIB
if(PALACE_WITH_GSLIB)
  list(APPEND PALACE_OPTIONS
    "-DGSLIB_DIR=${CMAKE_INSTALL_PREFIX}"
  )
endif()

string(REPLACE ";" "; " PALACE_OPTIONS_PRINT "${PALACE_OPTIONS}")
message(STATUS "PALACE_OPTIONS: ${PALACE_OPTIONS_PRINT}")

include(ExternalProject)
ExternalProject_Add(palace
  DEPENDS           ${PALACE_DEPENDENCIES}
  SOURCE_DIR        ${CMAKE_SOURCE_DIR}/palace
  BINARY_DIR        ${CMAKE_BINARY_DIR}/palace-build
  INSTALL_DIR       ${CMAKE_INSTALL_PREFIX}
  PREFIX            ${CMAKE_BINARY_DIR}/palace-cmake
  BUILD_ALWAYS      TRUE
  DOWNLOAD_COMMAND  ""
  CONFIGURE_COMMAND cmake <SOURCE_DIR> "${PALACE_OPTIONS}"
  TEST_COMMAND      ""
)
