module PersistentTask

const t = Ref{Any}()
__init__() = t[] = Timer(0.1; interval=1)   # create a persistent `Timer` `Task`

end # module PersistentTask
