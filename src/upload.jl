
#####
#Uploaders

export put_file, put_jld

"""
`container` can either be be just a container name, or a pseudofolder path
"""
function put_file(serv, container::String, name::String, fname::String; verbose::Bool=false)
    uo = service[:SwiftUploadObject](fname, object_name=name)
    async_put = serv[:upload](container, [uo]) 
    responses = collect(async_put)
    if verbose
        show_responses(responses)
    end
    ret = responses[end]
    ret["success"] || error(ret["error"])
    ret
end

"""Note: this reads out the `fp` IO to the end"""
function put_file(serv, container::String, name::String, fp::IO; verbose::Bool=false)
    mktempdir() do tdir
        fname = joinpath(tdir, name)
        open(fname,"w") do fp_inner
            write(fp_inner, readbytes(fp))
        end
        put_file(serv, container, name, fname; verbose=verbose)
    end
end

"""Save data as a a JLD file, and upload to Swift"""
function put_jld(serv, container::String, name::String; data...)
    mktempdir() do tdir
        fname = joinpath(tdir, name)
        save(File(format"JLD", fname), Base.Flatten(((string(name), val) for (name,val) in data))...)
        put_file(serv, container, name, fname)
    end
end

