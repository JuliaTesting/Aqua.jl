"""
    PkgWithoutUndocumentedNames
"""
module PkgWithoutUndocumentedNames

"""
    documented_function
"""
function documented_function end

"""
    DocumentedStruct
"""
struct DocumentedStruct end

export documented_function, DocumentedStruct

end  # module
