module PkgWithUndocumentedNames

"""
    documented_function
"""
function documented_function end

function undocumented_function end

"""
    DocumentedStruct
"""
struct DocumentedStruct end

struct UndocumentedStruct end

export documented_function, DocumentedStruct
export undocumented_function, UndocumentedStruct

end  # module
