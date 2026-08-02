module FailsToPrecompile

# Deliberately fails to precompile, so the persistent-tasks probe cannot load its
# wrapper. Used to check that the probe reports the precompilation failure instead
# of silently claiming the package holds a persistent task.
error("FailsToPrecompile fails to precompile on purpose")

end # module FailsToPrecompile
