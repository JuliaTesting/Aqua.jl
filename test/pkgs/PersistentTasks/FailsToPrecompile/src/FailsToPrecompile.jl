module FailsToPrecompile

# Fail during precompilation so the persistent-task check hits its
# precompilation-error branch instead of loading the package successfully.
error("Intentional precompilation failure for testing Aqua's persistent-task check")

end
