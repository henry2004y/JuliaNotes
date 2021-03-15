@def title = "Interoperability"
@def hascode = true
@def rss = "Introduction to interoperability in Julia"
@def rss_title = "Julia interoperability"
@def rss_pubdate = Date(2020, 11, 8)

# Interoperability

## Python

I have encountered tons of issues calling Python in Julia, or vice versa. You are lucky if you succeed in the first attempt!

```julia-repl
julia> ENV["PYTHON"]="~/anaconda3/bin/python"
```

I had several times of "no backend GUI for matplotlib" issue after installing the PyJulia package in Python for using Julia. The problem was solved by entering

```julia-repl
julia> ENV["PYTHON"]=""; Pkg.build("PyCall")
```

Online someone mentioned setting

```julia-repl
julia> ENV[``MPLBACKEND''] = ``tkagg''
julia> using PyPlot
```

However, that does not work for me.
There seems to be some version and dependency issues when mixing Python and Julia.

It is possible to pass Python and Julia objects back and forth. Some are just done for you, for example Numpy arrays are identical to native Julia types; some needs a little bit of extra work, like a self-defined Python class object. All the Python package wrappers demonstrate how to do this properly.

Calling Julia from Python is also achieved with PyJulia. I would say it is still not in a very good shape (because Julia users don't care about calling from Python, and Python users don't want to bother with Julia).

## C

Check out [JuliaCalls](https://github.com/henry2004y/JuliaCalls).

## Fortran

Julia calls C is pretty straightforward, but it was a pain for the first time calling Fortran. Basically there are two types of obstacles:

* Julia is a rapidly evolving language, so syntax changes very quickly.
* There are much fewer examples on the Internet than, say, PyCall.

Despite all of these, I made it work initially in Julia 1.1. The idea is to see if I can directly call BATL library from Julia, as a first step of rewriting BATSRUS.