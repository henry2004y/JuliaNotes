@def title = "Types"
@def hascode = true
@def rss = "Introduction to base Julia types"
@def rss_title = "Julia Types"
@def rss_pubdate = Date(2020, 11, 6)

@def tags = ["syntax", "code", "image"]

# Basic Types

\toc

##

Numbers

Numerical operators

### Tuples

Tuples are one of the simplest data types and data structures in Julia. They can have any length and can contain any kind of value --- but they are immutable. Once created, a tuple cannot be modified. A tuple can be created using the literal tuple notation, by wrapping the comma-separated values within brackets.

In order to define a one-element tuple, we must not forget the trailing comma:

```julia 
(1,) 
```

But it's OK to leave off the parenthesis:

```julia 
'e', 2
```

Besides, there are also named tuples. A named tuple represents a tuple with labeled items. We can access the individual components by label or by index:
```julia
skills = (language = "Julia", version = v"1.0")
skills.language # "Julia"
skills[1] # "Julia" 
```

Tuple provides an elegant way of swapping the values of two variables without creating a temporary variable:

```julia
a, b = b, a
```

Tuple also makes multiple return values from functions available.

### Arrays

An array is a data structure (and the corresponding type) that represents an ordered collection of elements. More specifically, in Julia, an array is a collection of objects stored in a multi-dimensional grid. Arrays can have any number of dimensions and are defined by their type and number of dimensions.

```julia
s = "abc";
t = [1,2,3];
zip(s,t)
for pair in zip(s,t) println(pair) end
collect(zip(s,t))
t = [(`a',1),(`b',2),(`c',3)];
for (letter,number) in t println(number,'' '', letter) end
```

If you need to traverse the elements of a sequence and their indices, you can use `enumerate`, like Python:

```julia
for (index, element) in enumerate("abc") println(index, " ", element) end
```

A one-dimensional array, also called a vector, can be easily defined using the array literal notation, the square brackets `[...]`:

```julia
[1, 2, 3]  
```

You can also constrain the type of the elements:

```julia
Float32[1, 2, 3, 4] 
```

A 2D array (i.e. matrix) can be initialized using the same array literal notation, but this time without the commas:

```julia
[1 2 3 4] 
```

We can add more rows using semicolons:

```julia
[1 2 3; 4 5 6; 7 8 9]
```

Julia comes with a multitude of functions that can construct and initialize arrays with different values, such as ```zeroes, ones, trues, falses, similar, rand, fill```, and more. To check your usage, type `?` in the Julia REPL.

#### Accessment

Array elements can be accessed by their index, passing in a value for each dimension. We can also pass a colon `:` to select all indices within the entire dimension --- or a range to define subselections.

Another option is an `Array` of Booleans to select elements at its true indices. Here we select the rows corresponding to the true values and the columns 3 to 5:

```julia
arr2d = rand(5,5); arr2d[[true, false, true, true, false], 3:5]
```

This is often seen in MATLAB codes.

#### Mutation

We can add more elements to the end of a collection by using the `push!` function. Similarly, we can remove elements from the end of an array using `pop!`. If we want to remove an element other than the last, we can use the `deleteat!` function, indicating the index that we want to be removed.

Finally, a word of warning when mutating arrays. In Julia, the arrays are passed to functions by reference. This means that the original array is being sent as the argument to the various mutating functions, and not its copy. Beware not to accidentally make unwanted modifications. Similarly, when assigning an array to a variable, a new reference is created, but the data is not copied. So for instance:

```julia
arr = [1,2,3]  
arr2 = arr 
pop!(arr2)  
arr2 # [1,2]
arr  # [1,2]
```

Assigning `arr` to `arr2` does not copy the values of `arr` into `arr2`, it only creates a new binding (a new name) that points to the original `arr` array. To create a separate array with the same values, we need to use the `copy` function:

```julia
arr2 = copy(arr) # [1,2]
```

However, later if you assign `arr2` to other values, `arr` will not change! 

#### Comprehension

Array comprehensions provide a very powerful way to construct arrays. It is similar to the previously discussed array literal notation, but instead of passing in the actual values, we use a computation over an iterable object.

An example will make it clear:

```julia
[x += 1 for x = 1:5] 
```
This can be read as: for each element `x` within the range `1` to `5`, compute `x+1` and put the resultant value in the array.

A more complicated example:

```julia
Float32[x += 1 for x = 1:10 if x/2 > 3]
```

But the superpower of the comprehensions is activated when they are used for creating **generators**. Generators can be iterated to produce values on demand, instead of allocating an array and storing all the values in advance. You'll see what that means in a second.

Generators are defined just like array comprehensions, but without the square brackets:

```julia
(x+=1 for x = 1:10) 
# Base.Generator{UnitRange{Int64},##41#42}(#41, 1:10)
```

They allow us to work with potentially infinite collections. Check the following example, where we want to print the numbers from one to one million with a cube less than or equal to `1\_000`. The handy `@time` macro is used for profiling:

```julia:./generator_bad.jl
@time for i in [x^3 for x=1:1_000_000] 
    i >= 1_000 && break 
    println(i) 
end
```

\output{./generator_bad.jl}

This computation uses significant resources, over 10 MB of memory and almost 60,000 allocations, because the comprehension creates the full array of one million items, despite the fact that we only iterate over its first nine elements.

Compare this with using a generator:

```julia:./generator.jl
@time for i in (x^3 for x=1:1_000_000)
   i >= 1_000 && break 
   println(i) 
end
```
 
\output{./generator.jl}

Less than 1 MB and a quarter of the number of allocations. The difference will be even more dramatic if we increase the number of elements in the array.

### Dictionaries

The dictionary, called `Dict`, is one of Julia's versatile data structures. It's an associative collection --- it associates keys with values. You can think of a `Dict` as a look-up table implementation --- given a single piece of information, the key, it will return the corresponding value.

`Pairs` are one of the building blocks of Julia and can be used, among other things, for creating dictionaries.
 The compiler will do its best to infer the type of the collection from the types of its parts.

In some instances, the automatic conversion works:

```julia
dx = Dict(1 => 11) 
dx[2.0] = 12 
```

Julia has silently converted 2.0 to the corresponding `Int` value. But that won't always work:

```julia
dx[2.4] = 12 # InexactError: Int64(Int64, 2.4) 
```

You can also specify and constrain the type of `Dict` upon constructing it, instead of leaving it up to Julia:

```julia
dd = Dict{String,Int}("x" => 2.0)
```

We can also use `Pairs` to create a `Dict`:

```julia
p1 = "a" => 1
p2 = Pair("b", 2)
Dict(p1, p2)
```

We can also use an `Array` of `Pair`:

```julia
Dict([p1, p2]) 
```

We can do the same with arrays of `tuples`:

```julia
Dict([("a", 5), ("b", 10)]) 
```

Finally, a Dict can be constructed using `comprehensions`:

```julia
using Dates 
Dict([x => Dates.dayname(x) for x = (1:7)])
```

Your output will be different as it's likely that the keys won't be ordered from 1 to 7. Dicts are _not_ ordered collections in Julia.

To avoid undefined key errors, we can check if the key exists in the first place:

```julia
haskey(d, :baz)
```

As an alternative, if we want to also get a default value when the key does not exist, we can use the following:

```julia
get(d, :baz, 0)
```

The `get` function has a more powerful twin, `get!`, which also stores the searched key into the `Dict`, using the default value:

```julia
get!(d, :baz, 100) 
```

Adding values to a `Dict` is routinely done using the square bracket notation (which is similar to indexing into it, while also performing an assignment).

Removing a key-value Pair is just a matter of invoking `delete!` (note the presence of the exclamation mark here too).

`merge`

`keys, values`, convert to array with `collect`


```julia
d = Dict(zip("abc",1:3))
for (key,value) in d println(key," ", value)
```

I have encountered the performance penalty involving dictionaries several times in Julia.
I feel like the type-inference does not work well with dictionaries when the values contain non-concrete types.
It would be better to learn about this!

#### Ordered dictionaries

If you ever need your dictionaries to stay ordered, you can use the `DataStructures` [package](https://github.com/JuliaCollections/DataStructures.jl), specifically the `OrderedDict`.


### Iterations

The simplest way to iterate over an array is with the `for` construct. If you also need the index while iterating, Julia exposes the `eachindex(yourarray)` iterator.

This is mostly seen in Python, and now some newer C++.

### Ranges

### Strings

#### Regular expressions

Regular expressions are used for powerful pattern-matching of substrings within strings. They can be used to search for a substring in a string, based on patterns --- and then to extract or replace the matches. Julia provides support for Perl-compatible regular expressions.

The most common way to input regular expressions is by using the so-called nonstandard string literals. These look like regular double-quoted strings, but carry a special prefix. In the case of regular expressions, this prefix is `r`. The prefix provides for a different behavior, compared to a normal string literal.

For example, in order to define a regular string that matches all the letters, we can use `r"[a-zA-Z]*"`.

Julia provides quite a few nonstandard string literals --- and we can even define our own if we want to. The most widely used are for regular expressions `r"..."`, byte array literals `b"..."`, version number literals `v"..."`, and package management commands `pkg"..."`.

Here is how we build a regular expression in Julia--- it matches numbers between 0 and 9:

```julia
reg = r"[0-9]+"
match(reg, "It was 1970") # RegexMatch("1970")
```

The nonstandard string literal has the type of `Regex`. This gives away the fact that there's also a `Regex` constructor available:

```julia
Regex("[0-9]+")
```

The behavior of the regular expression can be affected by using some combination of the flags `i`, `m`, `s`, and `x`. These modifiers must be placed right after the closing double quote mark:

```julia
match(r"it was", "It was 1970") # case-sensitive no match
match(r"it was"i, "It was 1970") # case-insensitive match
```

As you might expect, `i` performs a case-insensitive pattern match. Without the `i` modifier, match returns nothing --- a special value that does not print anything at the interactive prompt--- to indicate that the regex does not match the given string.

These are the available modifiers:

* `i`: case-insensitive pattern matching.
* `m`: treats string as multiple lines.
* `s`: treats string as single line.
* `x`: tells the regular expression parser to ignore most whitespace that is neither backslashed nor within a character class. You can use this to break up your regular expression into (slightly) more readable parts. The `#` character is also treated as a metacharacter introducing a comment, just as in ordinary code.


The `occursin` function is more concise if all we need is to check if a regex or a substring is contained in a string --- if we don't want to extract or replace the matches:

```julia
occursin(r"hello", "It was 1970") # false
occursin(r"19", "It was 1970")  # true
```

When a regular expression does match, it returns a `RegexMatch` object. These objects encapsulate how the expression matches, including the substring that the pattern matches and any captured substrings:

```julia
alice_in_wonderland = "Why, sometimes I've believed as many as six
impossible things before breakfast."
m = match(r"(\w+)+", alice_in_wonderland) # RegexMatch("Why", 1="Why")
```

The `\w` regex will match a word, so in this snippet we captured the first word, Why.

We also have the option to specify the index at which to start the search:

```julia
m = match(r"(\w+)+", alice_in_wonderland, 6) # RegexMatch("sometimes", 1="sometimes") 
```

Let's try something a bit more complex:

```julia
m = match(r"((\w+)(\s+|\W+))", alice_in_wonderland) # RegexMatch("Why, ", 1="Why, ", 2="Why", 3=", ")
```

The resultant `RegexMatch` object `m` exposes the following properties (or fields, in Julia's lingo):

* `m.match` (Why, ) contains the entire substring that matched.
* `m.captures` (an array of strings containing Why, Why, and , ) represents the captured substrings.
* `m.offset`, the offset at which the whole match begins (in our case 1).
* `m.offsets`, the offsets of the captured substrings as an array of integers (for our example being [1, 1, 4]).

Julia does not provide a `g` modifier, for a greedy or global match. If you need all the matches, you can iterate over them using `eachmatch()`, with a construct like the following:

```julia
for m in eachmatch(r"((\w+)(\s+|\W+))", alice_in_wonderland) 
   println(m) 
end 
```

Or, alternatively, we can put all the matches in a list using `collect()`:

```julia
collect(eachmatch(r"((\w+)(\s+|\W+))", alice_in_wonderland))
```

For more info about regular expressions, check the [official documentation](https://docs.julialang.org/en/stable/manual/strings/#Regular-Expressions-1).

#### Raw string literals

If you need to define a string that does not perform interpolation or escaping, for example to represent code from another language that might contain `$` and `` ` `` which can interfere with the Julia parser, you can use raw strings. They are constructed with `raw"..."` and create ordinary `String` objects that contain the enclosed characters exactly as entered, with no interpolation or escaping:

```julia
"This $will error out" # ERROR: UndefVarError: will not defined
```

Putting a `$` inside the string will cause Julia to perform interpolation and look for a variable called will:

```julia
raw"This $will work" # "This \$will work"
```

But by using a raw string, the `$` symbol will be ignored (or rather, automatically escaped, as you can see in the output).


## A bit more highlighting

Extension of highlighting for `pkg` an `shell` mode in Julia:

```julia-repl
(v1.4) pkg> add Franklin
shell> blah
julia> 1+1
(Sandbox) pkg> resolve
```