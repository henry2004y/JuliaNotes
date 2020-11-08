abstract type Pet end
struct Dog <: Pet
    name::String
end
struct Cat <: Pet
    name::String
end

function encounter(a::Pet, b::Pet)
    verb = meets(a,b)
    println("$(a.name) meets $(b.name) and $verb")
end

meets(a::Dog, b::Dog) = "sniffs"
meets(a::Dog, b::Cat) = "chases"
meets(a::Cat, b::Dog) = "hisses"
meets(a::Cat, b::Cat) = "slinks"

fido = Dog("Fido")
rex  = Dog("Rex")
whiskers = Cat("Whiskers")
spots = Cat("Spots")

encounter(fido, rex)
encounter(fido, whiskers)
encounter(whiskers, rex)
encounter(whiskers, spots)
