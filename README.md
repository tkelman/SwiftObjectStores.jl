# SwiftObjectStores

[![Build Status](https://travis-ci.org/oxinabox/SwiftObjectStores.jl.svg?branch=master)](https://travis-ci.org/oxinabox/SwiftObjectStores.jl)

[![Coverage Status](https://coveralls.io/repos/oxinabox/SwiftObjectStores.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/oxinabox/SwiftObjectStores.jl?branch=master)

[![codecov.io](http://codecov.io/github/oxinabox/SwiftObjectStores.jl/coverage.svg?branch=master)](http://codecov.io/github/oxinabox/SwiftObjectStores.jl?branch=master)

>Swift is a highly available, distributed, eventually consistent object/blob store. Organizations can use Swift to store lots of data efficiently, safely, and cheaply.


Makes [Open Stack Swift Object Stores](http://docs.openstack.org/developer/swift/) available from within Julia.
This package wraps the Python Swift Client, but makes significant changes in terms of interface.


The implementation makes significant uses of temporary files.
It is thus desirable to ensure your `TMPDIR` is set to be on a RAM disk.
In most modern unixen, this is done by adding `export TMPDIR=/dev/shm` to your `.bashrc` or similar.
The package will work fine without this -- and depending on your OS may effectively use a RAM disk anyway.


As is the Open Stack fasion, the package will default to reading your various username and password from enviroment variables.
If you want to make use of this feature, you should  `source ~/openrc.sh` or similar, before starting julia (Or Jupyter).



## Examples of use:

In all these examples, assume we have already loaded the package, and set up a server description:

```julia
julia> using SwiftObjectStores
julia> serv = SwiftService()
```
This constructs the default server connection description.
Reading the server URL, and your identity information from the enviroment variables.

## Using Storing and Retrieving arbitary data objects via JLD

We expose the capacity for storing, and retieving arbitary julia object, through JLD.

We store them, by name and to value, using keyword arguents
```julia
julia> put_jld(serv, "testing-out-swift-container", "usefulobject"; data = rand(Complex128, 10), note="Stored some random numbers for later")
```

As when using JLD on files, we can retrieve each field one at a time:

```julia
julia>get_jld(serv, "testing-out-swift-container", "usefulobject", "note")

"Stored some random numbers for later"

julia>get_jld(serv, "testing-out-swift-container", "usefulobject", "data")

10-element Array{Complex{Float64},1}:
0.37839+0.805684im
0.300178+0.318451im
0.240708+0.331851im
0.0149401+0.806278im
0.416414+0.825936im
0.63335+0.239163im
0.661586+0.242519im
0.640306+0.611966im
0.538004+0.123092im
0.749919+0.861574im
```

or all at once:

```julia
julia>get_jld(serv, "testing-out-swift-container", "usefulobject")

Dict{String,Any} with 2 entries:
    "note" => "Stored some random numbers for later"
    "data" => Complex{Float64}[0.37839+0.805684im,0.300178+0.318451im,0.240708+0.…
```

### Get a file, and perform a loading operation on it
Use [RData.jl](https://github.com/JuliaStats/RData.jl/) to load a RData file off the object store.
Using the container `ResearchData`, the pseudodir `simulated`, and the object name `sim-100000.RData`.
Note that the pseudodir is part of the object name -- pseudodir's are not real, just convention in the key value store.

```julia
julia> using RData
julia> data = get_file(serv, "ResearchData", "simulated/sim-100000.RData") do fn
    load(fn)
end
```

## Management:

### Deleting object, and containers

Delete an object in a container:

```julia
julia> delete(serv, "testing-out-swift-container", "usefulobject")
```

Delete the container itself:

```julia
julia> delete(serv, "testing-out-swift-container")
```



### Listing Containers

the `list` command gives a dictionary, where the keys are the names of the containers, and the values contain information about each.

```julia
julia> SwiftObjectStores.list(serv) |> keys

Base.KeyIterator for a Dict{String,Dict{Any,Any}} with 11 entries. Keys:
  "testing-out-swift-container_segments"
  "ResearchData"
  "testing-out-swift-container"
```

Notice, segment containers are also listed. 
