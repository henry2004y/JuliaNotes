@def title = "Coding in Julia"
@def tags = ["syntax", "code"]

# Overview

\tableofcontents <!-- you can use \toc as well -->

## How Julia works

The Julia compiler workflow is presented in [Jameson Nash's talk](https://www.youtube.com/watch?v=7KGZ_9D_DbI&list=WL&index=6). The key essense is shown in the structure below:
* method definition
  * macros, metaprogramming
* code_lowered
  * generated functions
  * simplified code structure
* code_typed
  * precompiled modules (.ji)
  * global inference
  * local optimization
  * code_warntype: dynamic behavior annotations
* code_llvm
  * external codegen
  * llvm-2.0 Julep Intermediate Representation (IR) for low-level optimization
* code_native
  * static system image (.so/.dll/.dylib)
  * machine code representation

If one dive deeper into the processor, he/she will find that it handles the machine code in a way similar to Julia's workflow, with multiple levels of caching and optimization.

So what's unique about Julia in the sense of a new programming language? It all lies in the **code_typed** process which is closely related to **Interprocedural Optimization (IPO)**. Julia has implemented a dataflow inference algorithm that runs Ahead of Time (AOT), which is different from the common Just-In-Time (JIT) compilation that people talk about. This is also the reason why Julia takes a significant amount of time the first time it executes the code: for later runs, the compiler caches previous machine codes and will only rerun the compilation process for the modified codes.

## Big pictures to keep in mind

In a compiled language like Julia, loops are most-of-the-time better than vectorization, even though vectorized version may be shorter and cleaner. This is mainly because a vectorized version creates many temporary variables behind the scene, and memory allocation is slow compared to operations. So when writing Julia code, it is like a combination of interpreting language like MATLAB and compiled language like Fortran: you need to think both ways to get the most out of Julia.

When people like me jumps into the Julia world, we would often love to convert our existing codes from other languages into Julia and check if it shows the promised performance. This is the time we truly learn Julia the Julian way.

What I really love about Julia is its desire to point out the deficiencies of other languages' implementations and improve from them. Being a new language in the competitive world, Julia grows in the open source community with support from enthusiasts, and is now gaining attention from the mainstream science and business fields.

Learning new things is fun. Starting to code in Julia, there are several things you should keep in mind:

1. Julia is not an OOP language, but everything in Julia is an object. In Julia, we use what is being called **multiple dispatch** to do things like _overloading_. To write good Julia code, you need to adopt the method-focused workflow and rethink about the knowledge you have about OOP and functional programming.

2. My first implementation of KEMPO1, a 1D PIC code originally writeen in MATLAB, ran 50% slower than the MATLAB version even without graphics! This was really surprising to me, but it also showed that I was not familiar with Julia at all. The lesson is that type stability is extremely important in Julia. Just by making the code type-stable results in a 50x speedup! For sure more tricks can be applied: for instance, somebody who came from the Haskel world posted a case on Discourse with a program of simple geometry accelerated by 1000x.

3. The conversion from C/Fortran/Python into Julia is easy. However, Julia has 1-based indexing, the same as MATLAB/Fortran as opposed to the 0-based indexing in C/C++/Python. This is the error-prone part during the conversion. If you consider it really necessary, Julia has support for arrays with arbitrary indices, allowing, for example, to start numbering at 0. This is widely used in the image processing packages. If you are curious, check the [official documentation](https://docs.julialang.org/en/v1/devdocs/offset-arrays/).

4. At the current stage, a realistic expectation for Julia program compared with C/C++/Fortran is that the timings should be within a factor of 3. In certain cases, Julia can even outperform them (e.g. 1D Vlasov demo).

## Why Julia

Fast implementation, easy maintenance and decent performance.

As quoted from Christopher Rackauckas, all the micro-examples performed as benchmarks for Julia, Numba, Cython and others will show only tiny differences. Actually nowadays with the advance of LLVM backend any any sufficient competent IR generating mechanism will hit the performance limit on small examples (as shown with the compilation stages above).

What really matters is whether it can scale into large projects. Chris showed an example of 10x faster performance achieve by the _Julia called from Python_ solution than the SciPy+Numba code, which is essentially just a full Julia vs Fortran+Numba solution.
The main issue is that Fortran+Numba still has Python context switches in there because the two pieces were independently compiled and it's this which becomes the remaining bottleneck that cannot be erased.

On the other hand, the Cython approach, where you can design the entire package yourself as one monolithic code base, will become maintenance nightmares which decrease programming productivity since you'll have to reinvent the wheel.
And the even larger issue in scientific computing is that it is the intersection of high performance computational utilities with complex mathematical algorithms that gives you strong performance.
Rewriting every single difficult algorithm from scratch in order to utilize the most modern methods with the most efficient structures is not a style of programming that scales well.
If there's one thing that Python really does well, I would say it's the package ecosystem.
Julia learns from Python and now has a really good package system, and we have the ability to have separate packages work fully together.

The key difference between Cython and Julia:
* In Cython you have separately compiled functions and packages, much like static compilation to shared libraries in C++, and then you put function calls between them. In a few cases where you compile parts together it can inline, but generally you have separate packages/modules/etc. compile separately. This cuts down on compile time and makes it easier to generate a static binary but adds runtime costs.
* In Julia you have fully dependent compilation. Packages which call other packages can take control of the full code before compilation and then choices have to be made at how to separate it in a meaningful way.

This will lead to the next part: once you have the entire code of a function, you can use the dependent compilation to build alternative output functions at compile time. These are language level compilation control features, which can really help to interact with the efficient data structures and difficult algorithms.
A good example is the combination usage of dual numbers in _automatic differentiation_ and _ODE solvers_.
Another example is the _porting to GPU_ process, which basically requires nothing if you are using broadcast.

Dependent compilation fully eliminates the overhead that exists when different libraries are separately compiled. Broadcast overrides allow you to dictate how internal structures of scientific computing codes should be implemented and optimized on your specific model.

There is a tradeoff for all these amazing things to happen: compile-time. For this system to be used interactively, you have to take a step back and find out where you want to stop specializing and where to put up artificial walls. A combination of statically compiled and dynamically compiled code is also an engineering challenge.

## Getting help

If you know the names of unsure functions and operators, type `?` in the Julia REPL followed by the function/operator name. It will show the comments from the source code.

In many circumstances you can find the solutions to your question online.
In case you fail, people in the community are generally helpful. Most of them work across multiple languages and are very knowledgeable about programming techniques. Either ask questions on the [main Discourse](https://discourse.julialang.org/) or the [Chinese Discourse](https://discourse.juliacn.com/). For specific question about packages, go to their GitHub repositories and submit an issue.

The language itself gets more stable after 1.0 release, but it's still changing relatively rapidly. Take a look at [What has changed since 1.0](https://www.oxinabox.net/2021/02/13/Julia-1.6-what-has-changed-since-1.0.html) for the gradually evolving new features.

### References

[Julia Programming Projects, Adrian Salceanu](https://github.com/PacktPublishing/Julia-Programming-Projects)

[New Trends in Programming Languages](https://www.juliabloggers.com/new-trends-in-programming-languages/)

[Think Julia](https://benlauwens.github.io/ThinkJulia.jl/latest/book.html#_copyright)
