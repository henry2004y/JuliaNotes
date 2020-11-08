@def title = "Meta Programming"
@def hascode = true
@def rss = "Introduction to base Julia types"
@def rss_title = "Julia metaprogramming"
@def rss_pubdate = Date(2020, 11, 8)

# Metaprogramming

**Example**:

* page with tag [`syntax`](/tag/syntax/)
* page with tag [`image`](/tag/image/)
* page with tag [`code`](/tag/code/)

\toc

I have not used metaprogramming in any real program myself, but I would like to see its usage.

Understanding metaprogramming is not easy, so don't panic if it doesn't come naturally from the start. One of the reasons for this is that it takes place at a level of abstraction higher than what we're used to with regular programming. We will start with symbols, which makes the introduction less abstract. They look like this --- `:x` or `:scientific` or `:Celsius`. As you may have noticed, a symbol represents an identifier and we use it very much like a constant. However, it's more than that. It represents a piece of code that, instead of being evaluated as the variable, is used to refer to a variable itself.

A good analogy for understanding the relationship between a symbol and a variable has to do with the words in a phrase. Take for example the sentence: Richard is tall. Here, we understand that Richard is the name of a person, most likely a man. And Richard, the person, is tall. However, in the sentence: Richard has seven letters, it is obvious that now we aren't talking about Richard the person. It wouldn't make too much sense to assume that Richard the person has seven letters. We are talking about the word Richard itself.

The equivalent, in Julia, of the first sentence (Richard is tall) would be `julia> x`. Here, `x` is immediately evaluated in order to produce its value. If it hasn't been defined, it will result in an error, shown as follows:

```julia
x # ERROR: UndefVarError: x not defined
```

Julia's symbols mimic the second sentence, where we talk about the word itself. In English, we wrap the word in single quotes, 'Richard', to indicate that we're not referring to a person but to the word itself. In the same way, in Julia, we prefix the variable name with a column, `:x`:

```julia
:x
typeof(:x) # Symbol
```

Hence, the column `:` prefix is an operator that stops the evaluation. An unevaluated expression can be evaluated on demand by using the `eval()` function or the `@eval` macro, as follows:

```julia
eval(:x) # ERROR: UndefVarError: x not defined
```

But we can go beyond symbols. We can write more complex symbol-like statements, for example, `:(x = 2)`. This works a lot like a symbol but it is, in fact, an `Expr` type, which stands for expression. The expression, like any other type, can be referenced through variable names and, like symbols, they can be evaluated:

```julia
assign = :(x = 2)
eval(assign) 
x # 2
```

The preceding snippet demonstrates that we can reference an `Expr` type with the assign variable and then eval it. Evaluation produces side effects, the actual value of the variable `x` now being 2.

Even more powerful, since `Expr` is a type, it has properties that expose its internal structure:

```julia
fieldnames(typeof(assign)) # (:head, :args)
```

Every Expr object has two fields --- `head` representing its kind and `args` standing for the arguments. We can view the internals of `Expr` by using the `dump()` function:

```julia
dump(assign)
```

which shows
```plaintext
Expr
head: Symbol =
args: Array{Any}((2,))
1: Symbol x
2: Int64 2
```

This leads us to even more important discoveries. First, it means that we can programmatically manipulate `Expr` through its properties:

```julia
assign.args[2] = 3 
eval(assign)
x # 3
```

Our expression is no longer `:(x = 2)`; it's now `:(x = 3)`. By manipulating the `args` of the assign expression, the value of `x` is now 3.

Second, we can programmatically create new instances of `Expr` using the type's constructor:

```julia
assign4 = Expr(:(=), :x, 4)
eval(assign4)
x # 4 
```

Please notice here that we wrapped the equals sign `(=)` in parenthesis to designate an expression, as Julia gets confused otherwise, thinking we want to perform an assignment right there.

## Quoting Expressions

The previous procedure, in which we wrap an expression within `:(...)` in order to create `Expr` objects, is called **quoting**. It can also be done using quote blocks. Quote blocks make quoting easier as we can pass regular-looking code into them (as opposed to translating everything in to symbols), and supports quoting multiple lines of code in order to build randomly complex expressions:

```julia
quote 
    y = 42 
    x = 10 
end
 
eval(ans) # 10
y # 42
x # 10
```

## Interpolating strings

Just like with string interpolation, we can reference variables within the expressions:

```julia
name = "Dan"
greet = :("Hello " * $name)
eval(greet) # "Hello Dan" 
```

## Macros

Now, we finally have the knowledge to understand macros. They are language constructs, which are executed after the code is parsed, but before it is evaluated. It can optionally accept a tuple of arguments and must return an `Expr`. The resulting Expression is directly compiled, so we don't need to call `eval()` on it.

For example, we can implement a configurable version of the previous `greet` expression as a macro:

```julia
macro greet(name)
    :("Hello " * $name)
end
@greet("Adrian") # "Hello Adrian"
```

As per the snippet, macros are defined using the macro keyword and are invoked using the `@...` syntax. The brackets are optional when invoking macros, so we could also use `@greet "Adrian"`.

Macros are very powerful language constructs that allow parts of the code to be customized before the full program is run. The official Julia documentation has a great example to illustrate this behavior:

```julia
macro twostep(arg)
    println("I execute at parse time. The argument is: ", arg)
    return :(println("I execute at runtime. The argument is: ", $arg))
end
```

We define a `macro` called `twostep`, which has a body that calls the `println` function to output text to the console. It returns an expression which, when evaluated, will also output a piece of text via the same `println` function.

Now we can see it in action:

```julia
ex = macroexpand(@__MODULE__, :(@twostep :(1, 2, 3)))
# I execute at parse time. The argument is: $(Expr(:quote, :((1, 2, 3))))
```

The snippet shows a call to macroexpand, which takes as an argument the module in which to expand the expression (in our case, `@__MODULE__` stands for the current module) and an expression that represents a macro invocation. The call to `macroexpand` converts (expands) the macro into its resulting expressions. The output of the `macroexpand` call is suppressed by appending `;` at the end of the line, but the resulting expression is still safely stored in `ex`. Then, we can see that the expanding of the macro (its parsing) takes place because the "I execute at parse time" message is output. Now look what happens when we evaluate the expression, `ex`:

```julia
eval(ex) # I execute at runtime. The argument is: (1, 2, 3)
```

The "I execute at runtime" message is outputted, but not the "I execute at parse time" message. This is a very powerful thing. Imagine that output instead of a simple text output if we'd had some very computationally intensive or time-consuming operations. In a simple function, we'd have to run this code every time, but with a macro, this is done only once, at parse time.

## Closing Words about Macros

Besides they're very powerful, macros are also very convenient. They can provide a lot of functionality with minimal overhead and can simplify the invocation of functions that take expressions as arguments. For example, `@time` is a very useful macro that executes an `Expression` while measuring the execution time. And the great thing is that we can pass the argument expression as regular code, instead of building the `Expr` by hand:

```julia
@time rand(1000); # 0.000007 seconds (5 allocations: 8.094 KiB) 
```

Macros --- and metaprogramming in general --- are powerful concepts that require whole books to discuss at length. For more, going over the [official documentation](https://docs.julialang.org/en/stable/manual/metaprogramming/).
