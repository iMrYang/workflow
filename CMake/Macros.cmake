

# aux_source_directory(${CMAKE_CURRENT_BINARY_DIR}/openssl PKG_SOURCES)
macro(isec_aux_source_directory dir variable)
    aux_source_directory(${dir} ${variable})

    file(GLOB _dir_path_list RELATIVE ${dir} ${dir}/*)
    foreach(_dir_path ${_dir_path_list})
        if(IS_DIRECTORY ${dir}/${_dir_path})
            aux_source_directory(${dir}/${_dir_path} ${variable})
        endif()
    endforeach()
endmacro()

macro(isec_aux_header_directory dir variable)
    file(GLOB_RECURSE ${variable} ${dir} "*.h")
endmacro()