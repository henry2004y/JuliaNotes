# This file was generated, do not modify it. # hide
@time for i in (x^3 for x=1:1_000_000)
   i >= 1_000 && break 
   println(i) 
end