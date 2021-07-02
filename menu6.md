@def title = "Issues and Tricks"
@def hascode = true
@def rss = "Issues and tricks"
@def rss_title = "Julia issues and tricks"
@def rss_pubdate = Date(2020, 11, 8)

\toc

# Issues and Tricks

Here is a nice [blog: 7 Julia Gotcha](https://www.juliabloggers.com/7-julia-gotchas-and-how-to-handle-them/) for some basic and easily ignored tips.


* The dot operator `.` stands in the heart of array operations. As the language evolves after Julia 1.0, there are more restrictions on the usage of dots. `.` in Julia is just a shorthand for the `broadcast` function. Consider the following example:

```julia-repl
exp.(sin.(cos.(log.(1:100))))
```

The preceding code is fused into an operation similar to the following:

```julia-repl
broadcast(v -> exp(sin(cos(log(v)))), 1:100)
```

The consequence is that there is only one allocation of memory to produce the final result of the operation. In standard scripting languages, each step of the computation would typically use up new memory. This is both computationally inefficient and memory expensive. Such seemingly minor details make Julia shine in numerical computing applications.

I am so used to the MATLAB style of vectorization, so I usually write the code like

```julia-repl
julia> lat.f[1,1,:] = (w[1]+w[3])*T[1] .- lat.f[3,1,:]
```

Actually in MATLAB you don't even need the dot operation for plus and minus. However, in Julia any fusion operation requires the explicit dot operation, even the equal sign! So the above example may not be optimal as you would expect: it is a copy instead of in-place operation!

The correct one should be:

```julia-repl
julia> lat.f[1,1,:] .= (w[1]+w[3])*T[1] .- lat.f[3,1,:]
```

See an elegant and detailed [description to the dot operations](https://julialang.org/blog/2017/01/moredots) by Steven Johnson, a professor at MIT.

* By default, a plot will not show up automatically inside a function. It is only displayed when it's returned. Otherwise, you can use, e.g., `display(plot(f, -3, 3))` to show the plot.

* The differential equation solver packages are extremely powerful. Read existing availability before you jump into writing your own version!

* If the string also includes quotes, we can escape these by prefixing them with a backslash:

```julia-repl
julia> "Beta is Latin for \"still doesn't work\"."
```

However, escaping can get messy, so there's a much better way of dealing with this --- by using triple quotes """...""".

```julia-repl
julia> """Beta is Latin for "still doesn't work"."""
```

Within triple quotes, it is no longer necessary to escape the single quotes. However, make sure that the single quotes and the triple quotes are separated --- or else the compiler will get confused:

```julia-repl
julia> """Beta is Latin for "still doesn't work"""" 
syntax: cannot juxtapose string literal 
```

The triple quotes come with some extra special power when used with multiline text. First, if the opening """ is followed by a newline, this newline is stripped from the string. Also, whitespace is preserved but the string is dedented to the level of the least-indented line:

```julia-repl
julia> """ 
                  Hello 
           Look 
    Here"""

julia> print(ans) 
Hello 
Look 
Here 
```

The previous snippet illustrates how the first line is stripped and the whitespace is preserved—but the indentation starts with the least indented line (the space in front of 'Here' was removed).

* Concatanating strings
Strings can be concatenated with an asterisk operator `*`, but this ONLY works for strings. To deal with other types, use string function:

```julia-repl
julia> string(greeting, ", ", username)
"Good morning, 9543794"
julia> string(2, " and ", 3) 
"2 and 3"
```

There is also a `String` method (with capital S). Remember that in Julia names are case-sensitive, so string and String are two different things. For most purposes we'll need the `lowercase` function.

* Interpolating strings
When creating longer, more complex strings, concatenation can be noisy and error-prone. For such cases, we're better off using the `$` symbol to perform variable interpolation into strings:

```julia-repl
julia> username = "Adrian" 
julia> greeting = "Good morning" 
julia> "$greeting, $username" 
"Good morning, Adrian"
```

More complex expressions can be interpolated by wrapping them into `$(...)`:

```julia-repl
julia> "$(uppercase(greeting)), $(reverse(username))" 
"GOOD MORNING, nairdA" 
```

Just like the string function, interpolation takes care of converting the values to strings:

```julia-repl
julia> "The sum of 1 and 2 is $(1 + 2)" 
"The sum of 1 and 2 is 3"
```

* `varinfo()` is approximately equal to `whos` in MATLAB. SOME IDEs now have support for showing the variables in the current scope, which is extremely helpful.

* Julia has alias. For instance, the `Int` type will reflect that, as it's just an alias to either `Int32` or `Int64`:

```julia-repl
julia> @show Int 
Int = Int64 
```

* `@which` can be used to show which method is actually being called with Julia's multi-dispatch system.

* To find out what methods are defined for a function, use `methods()`:

* An easy way to load CSV/TSV file into Julia is by using the `readdlm` function, which is available in the `DelimitedFiles` module. If you use `skipstart` only, then an array is returned; if instead you use `header=true`, this would change the return type of the function invocation to a tuple of `(data_cells, header_cells)`. This is an old module, with fast but limited functionality support. For more advanced reading, you can use [CSV.jl](https://github.com/JuliaData/CSV.jl) package. This will return a `DataFrame` object instead of array.

* We can check if a value is missing by using the `ismissing` function.

* Unfortunately, transposing doesn't work smoothly for all kinds of matrices in Julia 1.1 yet, and the recommended way is to do this via `permutedims` (especially for a mixture of types).

* If the REPL output is too wide, it will omit some of the `DataFrame` columns. To get Julia to display all the columns, you can use the `showall` function.

* In some parts of the code, you can avoid temporary memory allocation by `@view`. For example, if we want to pick a submatrix from A, we can do

```julia-repl
julia> block = A[i-1:i+1,j-1:j+1] # allocate temporary var
julia> block = @view A[i-1:i+1,j-1:j+1] # no allocation
```

* In operations like setting array slice values, e.g. `a[1:3,1] = [1,2,3]`, the right hand side creates a temporary vector. One way to avoid it is by setting each element separately. I don't know if there are better ways.

* The macro `@code_native` shows the assembly code.

* Do-Block: the `do x` syntax creates an anonymous function with argument `x` and passes it as the first argument to the preceding function. The implementation of do-block syntax is mind-refreshing and elegant.

* `rand` and `rand!` has the ability to pick a random value from a given data. The latter one with exclamation mark can fill random value into a given data array.

* Julia uses `im` for indicating imaginary numbers.

* The equivalent of `linspace` in Julia is `range(a, stop = b, length = c) |> collect`.

* Adding `;` in square bracket can change the return type to an array as you would expect. For example,
```julia-repl
julia> x = [1:10]
1-element Array{UnitRange{Int64},1}:
 1:10
julia> x = [1:10;]
10-element Array{Int64,1}:
```

* `$` can be used to protect the functions that we do not want to broadcast, when used together with `@`.

* Often, especially in performance-critical code, we want to squeeze the maximum speed out of Julia. If you are working with arrays, the `@inbounds` macro can be used to significantly reduce access time to the elements. The drawback is that you have to be sure that you are not trying to access an out-of-bounds location. The index boundary check can be turned off also by adding the `--check-bounds=no` flag to Julia. Also note the [scope of `@inbounds`](https://stackoverflow.com/questions/38901275/inbounds-propagation-rules-in-julia). In short, this macro effects all the index checking inside for loops, but not functions that are not inlined. The propagation of turning off inbound checking requires extra commands.

If you are developing a function in which you want to allow its user to disable bounds checking, you can use the `@boundscheck` macro. Here is an example function definition from `base/bitarray.jl`:

```julia-repl
@inline function getindex(B::BitArray, i::Int)
    @boundscheck checkbounds(B, i)
    unsafe_bitgetindex(B.chunks, i)
end
```

This annotation will only have an effect if the function, `getindex` in this case, is inlined into a caller. Therefore, the `@inline` macro is used at the beginning of its definition.

* A symbol is used to represent a variable in metaprogramming. Once you have symbols as a data type, of course, it becomes tempting to use them for other things, like as hash keys. But that's an incidental, opportunistic usage of a data type that has another primary purpose. Potentially using symbols over strings can speed up your Dict operations!

* There are some general rules in the [Plot.jl](https://github.com/JuliaPlots/Plots.jl) package that are useful to remember. For any matrix input, each column represents a data series and each row represents a data point. No matter it is x, y, labels, etc..

* There is a macro called `@debug`, which only evaluates the statements after when debug logging is enabled. The level of logging can be selected by an environment variable `JULIA_DEBUG`.

* Take advantage of one-line functions for your work. For example, to search for all the files with keywords in the directory, you can do

```julia-repl
julia> searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
```

* In some cases, `ifelse` can improve performance from `?` due to the avoid of branches.

* There is a pipeline operator in Julia, similar to Bash:

```julia-repl
julia> trunc(-1.5) |> typeof
```

In this way, we can change some operations into a more readable form.

* If you really care about performance, try the `@fastmath` macro.

* For the common loops, using `for i in 1:length(A)` is fine and equivalent to `for i in eachindex(A)`. However, if A is an `abstractArray` that may be a `subArray` (view of array) that includes some non-continuous indexing, using `eachindex` is better.

* MATLAB `squeeze` is equivalent to `dropdims` in Julia. However, improper use of `dropdims` may lead to 0-dimension arrays. There is a quite extensive discussion online about why exactly the same implementation of `squeeze` in Julia is not a good idea.

* Julia has macros defined in package like Cascadia and [LaTeXStrings](https://github.com/stevengj/LaTeXStrings.jl):

```julia-repl
using Cascadia
sm = sel''#content.mw-body''
L''\alpha''
```

* I once had a task of finding all the missing numbers in a sequence 0:2000. There are many ideas, but in Julia the simplest one is using Set, combining with the `setdiff` function.

* Since 2018, `Statistics` package is moved out of `stdlib` into `StatsBase` package, but it still maintains the acronym.

* The `using` statement is not allowed inside functions. If you really want to do it, add a `@eval` in the front of `using`.

* Julia has this concept of partial application, which allows you to write functions like `filter(>(0), a)` instead of `filter(x->x>0, a)`.

## Type Stability

If there is one thing that has a direct and massive impact on the performance of Julia code, it's the type system. And the most important thing about it is to write code that is **type-stable**. Type stability means that the type of a variable (including the return value of a function) must not vary with time or under different inputs. Understanding how to leverage type stability is key to writing fast software. Now that we know how to measure our code's execution time, we can see the effect of type instability with a few examples.

Let's take this innocent-looking function, for example:

```julia-repl
julia> function f1() 
           x = 0 
 
           for i in 1:10 
               x += sin(i) 
           end 
            
           x 
       end 
f1 (generic function with 1 method)
```

There's nothing fancy about it. We have a variable, `x`, which is initialized to 0 --- and then a loop from 1 to 10, where we add the `sin` of a number to `x`. And then we return `x`. Nothing to see, right? Well, actually, quite the contrary --- a few bad things, performance-wise, are happening here. And they all have to do with type instability.

Julia provides a great tool for inspecting and diagnosing code for type-related issues --- the `@code_warntype` macro. Here's what we get when we use it with our `f1` function:

```julia-repl
julia> @code_warntype f1() 
```

Check for the output, especially the color coding parts. As you might expect, green is good and red is bad. The problems are with `Body::Union{Float64, Int64}` on the first line, `(#4 => 0, #14 => %29)::Union{Float64, Int64}` on line 12, and 
`(#13 => %29, \#4 => 0)::Union{Float64, Int64}` on the penultimate line.

On the first line, the `Body::Union{Float64, Int64}`, as well as on the penultimate line, `::Union{Float64, Int64}`, tell us the same thing --- the function returns a `Union{Float64, Int64}`, meaning that the function can return either a Float or an Integer. This is textbook type instability and bad news for performance. Next, on line 12, something has a type of `Union{Float64, Int64}` and this value is then returned as the result of the function. In case you're wondering, that something is `x`.

The problem is that we unsuspectingly initialized `x` to 0, an Integer. However, the `sin` function will return a Float. Adding a Float to an Integer will result in a Float, causing the type of `x` to change accordingly. Thus, `x` has two types during the execution of the function, and since we return `x`, our function is also type-unstable.

Granted, understanding the output of `@code_warntype` is not easy, although it does get easier with time. However, we can make our job easier by using the super-useful [Traceur.jl](https://github.com/JunoLab/Traceur.jl) package. It provides a `@trace` macro, which generates human-friendly information. Let's add it and try it out; you'll appreciate it:

```julia-repl
(IssueReporter) pkg> add Traceur 
julia> using Traceur 
julia> @trace f1() 
┌ Warning: x is assigned as Int64 
└ @ REPL[94]:2 
┌ Warning: x is assigned as Float64 
└ @ REPL[94]:4 
┌ Warning: f1 returns Union{Float64, Int64} 
└ @ REPL[94]:2 
1.4111883712180104
```

How cool is that? Crystal clear! 

With this feedback in mind, we can refactor our code into a new `f2` function:

```julia-repl
julia> function f2() 
           x = 0.0 
 
           for i in 1:10 
                  x += sin(i) 
           end 
 
           x 
       end 
f2 (generic function with 1 method) 
 
julia> @trace f2() 
1.4111883712180104
```

Awesome, nothing to report! No news is good news!

Now, we can benchmark `f1` and `f2` to see the result of our refactoring:

```julia-repl
julia> @btime f1() 
  129.413 ns (0 allocations: 0 bytes) 
1.4111883712180104 
 
julia> @btime f2() 
  79.241 ns (0 allocations: 0 bytes) 
1.4111883712180104
```

## Avoid Memory Allocation

### Using array views to avoid memory allocation

### Static arrays

In the current implementation, working with large `StaticArrays` puts a lot of stress on the compiler, and becomes slower than `Base.Array` as the size increases. A very rough rule of thumb is that you should consider using a normal Array for arrays larger than 100 elements. 

### Heap vs stack

Remember tha mutable objects like arrays are allocated on the heap, while immutable objects like tuple and static arrays are allocated on the stack. This will cause performance differences especially inside loop kernels!

## Benchmarking tools

Given its focus on performance, it should come as no surprise that both core Julia and the ecosystem provide a variety of tools for inspecting our code, looking for bottlenecks and measuring runtime and memory usage. One of the simplest is the `@time` macro. It takes an expression and then prints its execution time, number of allocations, and the total number of bytes the execution caused to be allocated, before returning the result of the expression. For example, note the following:

```julia-repl
julia> @time [x for x in 1:1_000_000]; 
  0.031727 seconds (55.85 k allocations: 10.387 MiB)
```

Generating an array of one million integers by iterating from one to one million takes 0.03 seconds. Not bad, but what if I told you that we can do better --- much better? We just committed one of the cardinal sins of Julia—code should not be run (nor benchmarked) in the global scope. So, rule one --- always wrap your code into functions.

The previous snippet can easily be refactored as follows:

```julia-repl
julia> function onetomil()  
            [x for x in 1:1_000_000]
       end 
onetomil (generic function with 1 method) 
```

Now, the benchmark is as follows:

```julia-repl
julia> @time onetomil();
  0.027002 seconds (65.04 k allocations: 10.914 MiB) 
```

All right, that's clearly faster --- but not much faster. However, what if we run the benchmark one more time?

```julia-repl
julia> @time onetomil();
  0.002413 seconds (6 allocations: 7.630 MiB) 
```

Wow, that's an order of magnitude faster! So, what gives?

Julia uses a just-in-time (JIT) compiler; that is, a function is compiled in real time when it is invoked for the first time. So, our initial benchmark also included the compilation time. This brings us to the second rule --- don't benchmark the first run.

The best way to accurately measure the performance of a piece of code, thus, would be to execute it multiple times and then compute the mean. There is a great tool, specially designed for this use case, called `BenchmarkTools`. Let's add it and give it a try:

```julia-repl
julia> using BenchmarkTools 
julia> @benchmark onetomil() 
BenchmarkTools.Trial: 
  memory estimate:  7.63 MiB 
  allocs estimate:  2 
  -------------- 
  minimum time:     1.373 ms (0.00% GC) 
  median time:      1.972 ms (0.00% GC) 
  mean time:        2.788 ms (34.06% GC) 
  maximum time:     55.129 ms (96.23% GC) 
  -------------- 
  samples:          1788 
  evals/sample:     1 
```

We can also use the more compact `@btime` macro, which has an output similar to `@time`, but executes an equally comprehensive benchmark:

```julia-repl
julia> @btime onetomil(); 
  1.363 ms (2 allocations: 7.63 MiB
```

[BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/manual.md) exposes a very rich API and it's worth getting to know it well.

For packages, there is a helper library [PkgBenchmark](https://github.com/JuliaCI/PkgBenchmark.jl) which let you define a suite of tests for benchmark. However, this timing really depends not only on the code itself, but also the testing environment, machine and setup.

One more thing to keep in mind here: timing by itself is very tricky. If doing inappropriately, you may only end up in timing the part you don't want (e.g. garbbage collection). Check the advices by experts!

## Common Misunderstandings

Now you may have the impression that writing Julia code is like writing a static-typed language: the performance is gained by specifying every single argument of the functions. This is not true! Type assertions in function arguments are mainly used to control multiple dispatch, which has nothing to do with performance. To get performance in Julia the important hint is not annotating with types, but achieving type stability. This simply means that upon executing a piece of code, the variable types don't change.

There is an excellent explanation to this on StackOverFlow.


## Issues

* Differences between assignment, copy and deepcopy for mutable and immutable objects.

```julia
a = ones(3)
b = a
b[1] = 2.0
```

then `a` will also change. However, if you assign `b` to another type

```julia
a = ones(3)
b = a
b = 2
```

then `a` will not change.

One common misunderstanding from C users is pass-by-reference/value. Julia behaves the same as in Python. For example,

```julia-repl
julia> a = 1
julia> b = a
julia> b = 2
julia> a
```

what do you expect for the value of a? Because a is immutable, it will not change from 1 to 2! However, the following

```julia-repl
julia> a = [1,2]
julia> b = a
julia> b[1] = 2
julia> a
```

is different, because array is mutable object. Therefore the value of a should be `[2,2]`.

* Arrays and vectors are tricky. Be careful about singleton dimensions!

```julia-repl
julia> a = ["1","2"]
julia> a = ["1" "2"]
julia> a = ["1";"2"]
julia> reshape(a,:,1)
julia> reshape(a,1,:)
```
* `reshape` function does not allocate new memory! The indexes can only be Int64 on a 64bit machine and Int32 on a 32bit machine. See the [reason](https://github.com/JuliaLang/julia/issues/311) behind this decision by Stefan and Jeff.
* Object and reference needs special attention. Strings are immutable, therefore you cannot do operations like 

```julia-repl
julia> a = "hello"; a[2] = "a"
```

On the other hand, arrays are mutable, which makes it important to distinguish between aliasing and copying. For example,
```julia-repl
julia> a = [1,2,3]; b = a; b[1] = 42; println(a)
```

will also change the values of `a`. The slicing operation `[:]` means copying, and the heavy memory usage compared to in-place manipulations is probably one of the reasons Julia encourages de-vectorized code. However, I am not entirely sure about what will be happening if the dot syntax is used together with slicing.
As a side note, MATLAB uses "lazy copy" strategy.

* If I define a macro and execute the script again after the first one, it always says `invalid redefinition of constant ...`.

* syntax: invisible character `\u2060`.
This happens once when I was using unicode. `\u2060` is called word joiner.

* I once encountered an error when using the ODE solvers. It turned out that the problem is I do not set the initial conditions with the correct types...

* For a container-like thing, Julia used to have `type` keyword, but it is removed after version 0.7. Now only `struct` is used.

* Strings can be treated as a list of characters, so we can index into them--- that is, access the character at a certain position in the word. It is important to notice that indexing via a singular value returns a `Char`, while indexing via a range returns a `String` (remember, for Julia these are two completely different things).

* In Julia, string literals are encoded using UTF-8. UTF-8 is a variable-width encoding, meaning that not all characters are represented using the same number of bytes. For example, ASCII characters are encoded using a single byte--- but other characters can use up to four bytes. This means that not every byte index into a UTF-8 string is necessarily a valid index for a corresponding character. If you index into a string at such an invalid byte index, an error will be thrown. Here is what I mean:

```julia-repl
julia> str = "Søren Kierkegaard was a Danish Philosopher" 
julia> str[1] 
'S': ASCII/Unicode U+0053 (category Lu: Letter, uppercase)
julia> str[2] 
'ø': Unicode U+00f8 (category Ll: Letter, lowercase) 
julia> str[3] 
StringIndexError("Søren Kierkegaard was a Danish Philosopher", 3)
julia> str[4] 
'r': ASCII/Unicode U+0072 (category Ll: Letter, lowercase) 
```

* MySQL is too prone to error on my Mac. The API is not good enough for a stable development for a rookie like me.

* It is worth remembering that `transpose` creates a thin wrapper around the original array. This means that if we modify the transposed matrix, the original will also be modified!

* Declare a global variable `const` does not mean you cannot change the values. It just means that you can no longer reassign the variable but if it refers to a mutable value, you can modify the value. In other words, the type and size of the variable is set, but not the values it stores. (Actually what I found is that you can assign it to other variables, but Julia will give you a warning. According to the manuals, this is mainly for performance reasons.)

* Recursion with dynamic programming: a key idea is called **memoization**. Compare the following two versions of calculating Fibonacci sequence:

```julia-repl
# Classical version                                                             
function fib(n)
   if n == 0
      return 0
   elseif n == 1
      return 1
   else
      return fib(n-1) + fib(n-2)
   end
end

# Memoized version                                                              
const known = Dict(0=>0, 1=>1)

function fibonacci(n)
   if n ∈ keys(known)
      return known[n]
   else
      res = fibonacci(n-1) + fibonacci(n-2)
      known[n] = res
      return res
   end
end
```

The second version is much faster than the first classical version because of the reuse of already known values.
There is a library for implementing a macro for memoization.
Similarly in Python, there is a decorator from functools for the same purpose.

* Julia 1.0 does not support `copy!`, but it does in Julia 1.1+. As a workaround, you can use `a .= b` instead of `copy!(a,b)`. Note that `a = b` won't work here if `a` is immutable.

* Once I wanted to create an array of arrays and append items to each later on. This was what I did:

```julia-repl
julia> a = Vector{Vector{Int}}(undef,2)
julia> push!(a[1],1)
ERROR: UndefRefError: access to undefined reference
```

An even more strange thing happened for `fill`:

```julia-repl
julia> a = fill(Int[],2)
julia> push!(a[1],1)
```

Guess what I got? All the arrays are identical, which means that they are actually referred to the same memory allocation! This can only be avoided if I set each to a different value:

```julia-repl
julia> a[1] = [1]
```

Then `a[1]` is detached, but `a[2]` and `a[3]` are still pointing to the same memory allocation! What I ended up doing is:

```julia-repl
julia> for i=1:length(a) a[i] = [] end
```

This behavior is so weird! Be careful about all the related functions like `zeros,ones`.

* for loops not inside functions (e.g. in REPL) does not inherit the variables from global scope.

* There are many issues in 3D visualzation in Plots.jl. For example, zlabel is not working at all, as of Julia 1.2.

* pyplot backend issue. In Juno on Windows, by default matplotlib uses a ploting backend with no gui, making it impossible to show figures directly. The solution is to add `gcf()` to the end of your code.

* The `Plot.jl` library of Julia is not mature yet as of Julia 1.0. For example, the equal x,y,z range has no effect; the z label has some issue; the name for label and legend is confusing; the resolution of the figure changes depending on the way you execute the code; the size of the figure adjustment does not work. I had a much better experience with `PyPlot` package directly. It is identical to the Python version (except the enforced double quote) and very similar to a MATLAB user.

* I falled into the issue of installing `PyPlot.jl` again on Raspberry Pi, ARM 64 bit version Ubuntu. Tried all the possible solutions, but nothing helped.

* Be careful with filename `test.jl`, because it may conflict with the built-in test functions!

* Do you know how to pass C function as arguments in Julia?

* When I was developing the [IDL.jl](https://github.com/henry2004y/IDL.jl) package, I encountered an issue with REPL during testing:

```julia-repl
ERROR: LoadError: InitError: UndefVarError: active_repl not defined
```

This `active_repl` is actually a global variable for the current active REPL you are using. If you are in the testing environment, there's no active repl, so the above error raises up. The simple solution is to return the function before touching this line, or just create an instance with empty fields.

* In function arguments definition, `func(a::Bool=true)` is different from `func(a=true)` in that if you have `func(1)` the former version will return error for you. This might be better for error checking.

* During the surface flux integral, I used the `quantile!` function from the `Statistics` package to check the outlier data points. By the exclamation mark `!` itself you can guess that it changes the input argument, which is not what I want. The correct one to use is `quantile`.

As similar mistakes happen so many time, I need to warn myself again: follow the principle coding rules is the best way to avoid mistakes. Things will accumulate, either good or bad.

* As of Julia 1.5, there is no way to switch off asserts in the code. Hopefully this feature will be added in the future.

* The package management system still needs to be improved. Compatibility issues happen from time to time if I have already installed many packages.

* Requires.jl is an amazing pkg that aims at solving the conditional dependency issue in the pkgs! I have applied it to Vlasiator.jl already, and it works like magic.

* Be careful with dictionaries, especially in performance-critical part. In my reimplementation of the classical Vlasov 1D-1V solver from C++, it is 3 times slower than C++ when dictionary is used to store variables and 2 time faster than C++ when dictionary is avoided.

* Over-constraining argument types is considered as an antipattern in Julia. The key reason for specifying argument types in Julia is multi-dispatch. In fact, specifying argument types for many functions does not improve performance, which is a common misunderstanding of Julia's JIT compiler. See more discussions [here](https://www.oxinabox.net/2020/04/19/Julia-Antipatterns.html).

* To import a main module function into a submodule:
```julia
module SuperModule
   # Define `foo()` but don't give it any methods yet
   function foo end
      
   # You can put this into SubModule.jl and do 
   # include("SubModule.jl") here, but I'm including 
   # it inline for this simple example.
   module SubModule1
     # Explicitly indicate that this is the *same* foo as in SuperModule
     import ..foo
           
     foo(x::Int) = println("hello Int")
   end

   module SubModule2
     import ..foo
     
     foo(x::Float64) = println("hello Float64")
   end
end
```
Remember that the imported functions must be defined before the submodules, otherwise Julia will warn you with "not found".

* In Julia, generally there is no issue of memory fragmentation for array of structs, just as in C. On the contrary, for Java each class contains header.

* Low level optimization: [MuladdMacro](https://github.com/SciML/MuladdMacro.jl). LLVM sometimes cannot generate optimal machine code as in GCC or intel. However, there are some hack packages in Julia for these low level instructions.