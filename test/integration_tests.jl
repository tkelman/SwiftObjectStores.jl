using SwiftObjectStores
using SwiftObjectStores.stat
using Base.Test
using JLD
import PyCall.PyError

const serv = SwiftService(
	# Note that we will read ENV["OS_PASSWORD"] and ENV["OS_USERNAME"]
	# CI needs to set those
    auth_url =  "https://keystone.rc.nectar.org.au:5000/v2.0/",
    tenant_name = "UWA_SEMANTIC_VECTORS", 
    #It is a little scary that I am testing in the same Tanant as I am using for my actual research
)
const container_name = "swift.jl-testing"

if haskey(SwiftObjectStores.list(serv), container_name)
    warn("Past test left mess. Deleting " * container_name * " for use in testing")
    delete(serv,container_name)    
end


@testset "PreCreate" begin
    @test_throws PyError stat(serv, container_name)  # container should not exist
end



@testset "Stream User Path" begin
    const obj_name = "eg1buffer"
    
    eg_text = "The Julia Language: A fresh approach to technical computing. λ=x²"
    @test put_file(serv, container_name, obj_name, IOBuffer(eg_text)) != nothing
    get_file(serv, container_name, obj_name) do fp
        @test readstring(fp) == eg_text
    end
    
    @test Dict(stat(serv, container_name)["items"])["Objects"] == "1"
    @test stat(serv, container_name, obj_name) !=nothing
    
    @test delete(serv,container_name, obj_name)!=nothing
    @test stat(serv, container_name, obj_name)["success"] == false 
    @test stat(serv, container_name, "eg1buffer")["error"][:http_status] == 404
end;


@testset "File User Path" begin
    const obj_name = "eg2file"
    const file_name = joinpath(dirname(@__FILE__), "eg2file.txt")
    open(file_name, "w") do fp
        println(fp, """
        Call me Ishmael. Some years ago- never mind how long precisely- 
        having little or no money in my purse, and nothing particular to interest me on shore,
        I thought I would sail about a little and see the watery part of the world. 
        It is a way I have of driving off the spleen and regulating the circulation. 
        """)
    end
    
    @test put_file(serv, container_name, obj_name, file_name) != nothing
    @test validate_file(serv, container_name, obj_name, file_name) 
end


@testset "File User Path with PseudoDir" begin
    const obj_name = "eg2file"
    const file_name = joinpath(dirname(@__FILE__), "eg3file.txt")
    open(file_name, "w") do fp
        println(fp, """
        There now is your insular city of the Manhattoes,
        belted round by wharves as Indian isles by coral reefs 
        - commerce surrounds it with her surf. 
        Right and left, the streets take you waterward. 
        Its extreme downtown is the battery, 
        where that noble mole is washed by waves,
        and cooled by breezes, 
        which a few hours previous were out of sight of land.
        Look at the crowds of water-gazers there
        """)
    end
    
    @test put_file(serv, container_name*"/psubdir", obj_name, file_name) != nothing
    @test validate_file(serv, container_name*"/psubdir", obj_name, file_name) 
end


immutable Mt
    m::String
    v::Int64
end

@testset "JLD" begin
    const obj_name = "eg2jld"
    val = Mt("Hello Dearest", 52)
    
    @test put_jld(serv, container_name, obj_name, mm=val) != nothing
    @test get_jld(serv, container_name, obj_name, "mm").m == val.m
    @test get_jld(serv, container_name, obj_name, "mm").v == val.v
end


@testset "Post_test" begin
    @test delete(serv,container_name)[end]["success"] == true
    @test_throws PyError stat(serv, container_name) 
    @test haskey(SwiftObjectStores.list(serv), container_name) == false
end;
