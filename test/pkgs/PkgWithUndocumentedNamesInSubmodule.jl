module PkgWithUndocumentedNamesInSubmodule

"""
    DocumentedStruct
"""
struct DocumentedStruct end

module SubModule

struct UndocumentedStruct end

end

end  # module
