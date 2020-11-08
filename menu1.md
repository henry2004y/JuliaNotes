@def title = "Common Questions"
@def hascode = true
@def date = Date(2020, 11, 6)
@def rss = "Common questions concerning the language as rookies"

@def tags = ["syntax", "code"]

# Language Features

\toc

## Multiple-dispatch and function overloading

One of the most common questions people ask when first learning Julia is: what is the difference between multiple-dispatch and function overloading? Here is a nice example for demonstrating the difference.

\input{julia}{/_assets/scripts/overload.jl} <!--_-->

which gives:
\output{/_assets/scripts/overload.jl} <!--_-->

The translation to C++:
\input{C++}{/_assets/scripts/overload.cpp} <!--_-->

which gives:
\input{C++}{/_assets/scripts/output/overload.txt}

## Objects

Like Python, everything is an object. Objects can be mutable or immutable, depending on if they can be modified after creation or not.


### Objects passing behavior

Indeed it is confusing to distinguish between pass-by-value, pass-by-reference, and pass-by-sharing. The behavior of Julia is similar to Python, but different from C. Briefly speaking, mutable and immutable objects behave differently, and it is often the immutable objects like `tuple` or `struct` that cause issues. Check [this Python course](https://www.python-course.eu/passing_arguments.php#:~:text=Correctly%20speaking%2C%20Python%20uses%20a,like%20call%2Dby%2Dvalue.) for details.

Previously I had some misunderstandings about Julia functions, especially about the argument passing behaviour. Strictly speaking, Julia is **call-by-value where the value is a reference**, or **call-by-sharing**, as used by most languages. This means that even without a "!" mark, the arrays are passed-by-reference, and scalars are passed-by-value. The exclamation mark `!` is just a convention for programmers to notify that a function may change the arguments, but it does not necessarily do anything to force it.

A common mistake/bug is that you assign part of an array to another variable, and modify the other one.

The confusion stems from this: assignment and mutation are not the same thing. Quoted from Steven on StackOverFlow:

* Assignment. Assignment looks like `x = ...` --- what's left of the `=` is an identifier, i.e. a variable name. Assignment changes which object the variable `x` refers to (this is called a variable binding). It does not mutate any objects at all.

* Mutation. There are two typical ways to mutate something in Julia: `x.f = ...` --- what's left of the `=` is a field access expression; `x[i] = ...` --- what's left of the `=` is an indexing expression. Currently, field mutation is fundamental --- that syntax can only mean that you are mutating a structure by changing its field. This may change. Array mutation syntax is not fundamental --- `x[i] = y` means `setindex!(x, y, i)` and you can either add methods to `setindex!` or locally change which generic function `setindex!`. Actual array assignment is a builtin --- a function implemented in C (and for which we know how to generate corresponding LLVM code).

Mutation changes the values of objects; it doesn't change any variable bindings. After doing either of the above, the variable `x` still refers to the same object it did before; that object may have different contents, however. In particular, if that object is accessible from some other scope –-- say the function that called one doing the mutation --- then the changed value will be visible there. But no bindings have changed --- all bindings in all scopes still refer to the same objects.

You'll note that in this explanation I never once talked about mutability or immutability. That's because it has nothing to do with any of this --- mutable and immutable objects have exactly the same semantics when it comes to assignment, argument passing, etc. The only difference is that if you try to do `x.f = ...` when x is immutable, you will get an error.

## Type conversion and variable definition

Julia inference system is smart enough to output
```julia
5 / 2
```
as
```julia
2.5
```

As a common potential issue for dynamic languages, due to the lack of requirement of variable definition, implicit type conversion as well as surprising temporary memory allocation of intermediate variables may happen and is hard to debug/optimize. This is really a double-edge sword, so be careful to make good use of it!

## Unicode support

As a math-friendly language, Julia has nice integrated support for Unicode-8. This means that not only you can use greek letters with sub/super-script for variable names, but also frequently you can see more than one syntax of expressing the same result, such as
```julia
(∈, in)
((f ∘ g)(args...), f(g(args...)))
```
and many others.

## Dot operators

`.` in Julia has two usages:
1. access fields or properties of objects and access variables defined inside modules.
2. Perform broadcasted operations.

Let us focus on the broadcast feature, or vectorization, as many people call it. Julia defines corresponding dot operations for every binary operator. These are designed to work element-wise with collections of values. That is, the operator that is dotted is applied for each element of the collection.
At first this may be uncomfortable for MATLAB programmers, because in MATLAB often you don't need to use dot as it is implicitly inferred. However from a language perspective, it is more strict and general to define a broadcast operation, or for short notation, `.`. Given that applying dot operator to all the places may be hard to read, Julia provides a macro `@.` that can be used at the beginning of an expression to indicate that each variable that is not protected by a preceding `$` sign is treated as broadcasted collection.

Vectorized code is an important part of the language due to its readability and conciseness, but also because it provides important performance optimizations. In general, Julia community recommend de-vectorized codes to speed up the code, as in C and Fortran. The vectorized codes are not as fast as their de-vectorized version. Obviously the developer are trying to catch up. See [More Dots: Syntactic Loop Fusion in Julia](https://julialang.org/blog/2017/01/moredots). What I notice in practice is that the broadcast version usually allocates more memory, but the performance is only slightly behind.

## Splat operator

Sometime you will see this `...` operator: it is called splat. It is often handy to "splat" the values contained in an iterable collection into a function call as individual arguments.

A range can be expanded into its corresponding values by using the splat operator `...`. For example, we can splat it into a tuple:

```julia:./splat_tuple.jl
@show (20:-5:-20...,)
```

\output{./splat_tuple.jl}

We can also splat it into a list:

```julia:./splat_list.jl
@show [1:10...]
```

\output{./splat_list.jl}

## Functions

Note the ending exclamation mark ! for some functions. These are perfectly legal function name in Julia. It is a **convention** to warn that the function is mutating---that is, it will modify the data passed as argument to it, instead of returning a new value.

## Scopes

It's very important to keep in mind that `if` blocks do not introduce local scope. That is, variables defined within them will be accessible after the block is exited (of course, provided that the respective branch has been evaluated):

```julia
status = if x < 0 
            "x is a negative number" 
         elseif x > 0 
            y = 20 
            "x is a positive number greater than 0" 
         else  
            "x is 0" 
         end 
y 
```

We can see here that the `y` variable, initialized within the `elseif` block, is still accessible outside the conditional expression.

This can be avoided if we declare the variable to be local:

```julia
status = if x < 0 
            "x is a negative number" 
         elseif x > 0 
            local z = 20 
            "x is a positive number greater than 0" 
         else  
            "x is 0" 
         end 
z # UndefVarError: z not defined
```

## Control Flow

### Ternary operator

Similar to C, an `if,then and else` type of condition can be expressed using the ternary operator `? :`.

For instance, 

```julia
x = 10
x < 0 ? "negative" : "positive"
```

### Short-circuit evaluation

Julia provides an even more concise type of evaluation --- short-circuit evaluation (exactly the same thing as in MATLAB). In a series of Boolean expressions connected by `&&` and `||` operators, only the minimum number of expressions are evaluated—as many as are necessary in order to determine the final Boolean value of the entire chain. We can exploit this to return certain values, depending on what gets to be evaluated. For instance:

```julia
x = 10
x > 5 && "bigger than 5" # "bigger than 5"
```

In an expression `A && B`, the second expression B is only evaluated if and only if A evaluates to true. In this case, the whole expression has the return value of the sub-expression B, which in the previous example is bigger than 5.

If, on the contrary, A evaluates to false, B does not get evaluated at all. Thus, beware --- the whole expression will return a false Boolean (not a string!):

```julia
x > 15 && "bigger than 15"
```

The same logic applies to the logical or operator, `||`:

```julia
x < 5 || "greater than 5"
```

In an expression `A || B`, the second expression B is only evaluated if A evaluates to false. The same logic applies when the first sub-expression is evaluated to true; true will be the return value of the whole expression:

```julia
x > 5 || "less than 5"
```

### Beware of operator precedence

Sometimes short-circuit expressions can confuse the compiler, resulting in errors or unexpected results. For example, short-circuit expressions are often used with assignment operations, as follows:

```julia
x > 15 || message = "That's a lot" 
```

This will fail with the syntax: `invalid assignment location "(x > 15) || message` error because the `=` assignment operator has higher precedence than logical `or` and `||`. It can easily be fixed by using brackets to explicitly control the evaluation order:

```julia
x > 15 || (message = "That's a lot") 
```

It's something to keep in mind as it's a common source of errors for beginners.

## GPU

The capability of generating assembly code from Julia makes it possible to take advantage of the CUDA C API and pass instructions to the backend GPU compiler. Writing CUDA code in Julia is by far the easiest way to do it besides C/C++ and Fortran: I have created a [repository](https://github.com/henry2004y/GPU-Collection/tree/master/julia) for the small examples.

Check out this [interview of Time Besard](https://notamonadtutorial.com/julia-gpu-98a461d33e21) for the logics and progress of GPU programming in Julia.

## Live evaluation of code blocks

If you would like to show code as well as what the code outputs, you only need to specify where the script corresponding to the code block will be saved.

Indeed, what happens is that the code block gets saved as a script which then gets executed.
This also allows for that block to not be re-executed every time you change something _else_ on the page.

Here's a simple example (change values in `a` to see the results being live updated):

```julia:./exdot.jl
using LinearAlgebra
a = [1, 2, 3, 3, 4, 5, 2, 2]
@show dot(a, a)
println(dot(a, a))
```

You can now show what this would look like:

\output{./exdot.jl}
