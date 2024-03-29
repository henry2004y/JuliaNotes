@def title = "Parallel"
@def hascode = true
@def rss = "Introduction to parallel programming in Julia"
@def rss_title = "Julia parallel computing"
@def rss_pubdate = Date(2020, 11, 8)

# Parallel Computing

Julia introduced to me several different patterns of parallel execution. I learned from failures and unexpected performance.
For example, the built-in one-sided parallel communication is very confusing and hard to use for me. I need more time and exprience.

Mechanisms for distributed computing are built into the Julia language. But to fully take advantage of it, we need much more than the built-in support, and often we need extra packages from the community.

## SIMD

In Julia now we have several options of utilizing the SIMD instructions in LLVM:
* [LoopVectorization.jl](https://github.com/JuliaSIMD/LoopVectorization.jl): focus on kernel loops, one macro for all;
* [SIMD.jl](https://github.com/eschnett/SIMD.jl): explicit vectorization calls. Everything at programmers' hand, but may not be optimal. The concept is similar to, e.g., Agner's vectorization library in C++.

## Multi-processing

Julia provides built-in language functionality to run a program across many processes that can run locally, across a distributed network, or in a computational cluster.

* Specify the number of required worker processes using the `-p {N|auto}` option on Julia startup.
  * It is important to understand that when you start N workers, then Julia will spin up N+1 processes. If I understand it correctly, the master process is independent from the work processes, but it does not need to map to an additional physical core: this is a software level isolation.
* Check the number of workers in Julia by using the `nworkers()` function from the Distributed package.
* If you want to execute some script on every worker on startup, you can do it using the `-L` option. When the `-L` option is passed, then Julia stays in command line after executing the script (as opposed to running a script normally, where we have to pass the `-i` option to remain in REPL).
* You can also add processes after Julia has started using the `addprocs` function. `addprocs` does not execute the script that was specified by the `-L` switch on Julia startup. Typically this is used for experimenting interactively.

Check the ID numbers of the master and worker processes:

```julia-repl
julia> using Distributed
julia> addprocs(1)
julia> Distributed.myid()
1

julia> workers()
1-element Array{Int64,1}:
 2
julia> res = @spawnat 2 myid()
julia> fetch(res)
```

Simple function:

```julia
remote_f = function(s::Int=3)
    println("Worker $(myid()) will sleep for $s seconds")
    sleep(s)
    val=rand(1:1000)
    println("Completed worker $(myid()) - return $val")
    return val
end
```

Now, let's test the function:

```julia-repl
julia> @fetchfrom 2 remote_f(4)
      From worker 2:    Worker 2 will sleep for 4 seconds
      From worker 2:    Completed worker 2 - return 466
466
```

Now, let's define a function that runs a remote process, waits a given time, and collects the results:

```julia
function run_timeout(timeout::Int, f::Function, params...)    
    wid = addprocs(1)[1]
    result = RemoteChannel(()->Channel{Tuple}(1));
    @spawnat wid put!(result, (f(params...), myid()))
    res = nothing    
    time_elapsed = 0.0
    while time_elapsed < timeout && !isready(result)
        sleep(0.25)
        time_elapsed += 0.25
    end
    if !isready(result)
        println("Not completed! Computation at $wid will be 
        terminated!")        
    else
        res = take!(result)
    end
    rmprocs(wid);
    return res
end
```

Now, let's use the `run_timeout` function to run the `remote_f` function remotely; we start by assigning an amount of time that a job can complete:

```julia-repl
julia> run_timeout(3, remote_f, 2)
      From worker 3:    Worker 3 will sleep for 2 seconds
      From worker 3:    Completed worker 3 - return 335
(335, 3)
```

Then, run a job that lasts longer than an actual computation:

```julia-repl
julia> run_timeout(3, remote_f, 10)
      From worker 4:    Worker 4 will sleep for 10 seconds
Not completed! Computation at 4 will be terminated!
```

We can see that this job has spawned a new process with an ID equal to 4, and this process terminated after three seconds (when the timeout was reached). 

Functions must be defined on every processor that is being called:

```julia-repl
julia> using Distributed

julia> @everywhere function myF2(); println("myF2 ", myid()); end;
​
julia> @spawnat workers()[end] myF2();
​
       From worker 3:    myF2 3
```

However, in the case of anonymous functions, they can be passed as parameters to the preceding macros. Still, if a function uses a method not defined on a remote process then it will fail:

```julia-repl
julia> hello() = println("hello");
​
julia> @fetchfrom 2 hello()
ERROR: On worker 2:
UndefVarError: #hello not defined
​
julia> f_lambda = () -> hello();
​
julia> f_lambda()
hello
​
julia> @fetchfrom 2 f_lambda()
ERROR: On worker 2:
UndefVarError: #hello not defined
```

The solution is, again, `@everywhere`.

Typically we want the number of workers to match the number of physical cores (`nproc` in Bash). The master process should not participate in computing.

There is a macro named `@distributed` which is very tempting to use for loop reductions, but use it with care. Nothing is shared from one iteration to another, and currently there is no way to control this behavior.

For more in-depth usage, checkout e.g. `pmap` which applys a function to each element of a collection using available workers.

### Machine File On a Cluster

A typical scenario for distributed computing is running a parameter sweep over a significantly large set of computations.

We explain how to use the `--machine-file` Julia options to run Julia workers across many nodes. However, the computational example can also be run on a single machine using the multiprocessing mode (for example, in Julia launched with the julia `-p 4` command).

In order to build a distributed cluster, we need to configure passwordless SSH. Julia uses SSH connections to spawn workers on remote nodes. For passwordless SSH, we will configure key-based authentication. In order for passwordless SSH to work, the master node needs to have the private key, while each slave node needs to have the public key in the `~/.ssh/authorized_users` file.

We assume that Linux Ubuntu 18.04.1 LTS is used and the username for the computations is ubuntu. We start by creating the key. You will find the command and a sample output, as follows:

```sh
ssh-keygen -P "" -t rsa -f ~/.ssh/cluster
```

The next step is to edit the `~/.ssh/config` file. Ensure that the following lines are present:

```plaintext
User ubuntu
PubKeyAuthentication yes
StrictHostKeyChecking no
IdentityFile ~/.ssh/cluster
```

Now, we need to add the contents of the public key to the `~/.ssh/authorized_keys` file. Please note that the contents of `~/.ssh/cluster.pub` should be copied to `~/.ssh/authorized_keys` on every node in the cluster:

Now, we can test our configuration on a local machine:

```sh
ssh ubuntu@localhost
```

Distributed multiprocessing in Julia is achieved using the `--machine-file` launch option of the julia command. The functionality is similar to the `-p` option but much more powerful since you can distribute Julia over any cluster size. Sample `machinefile.txt` content is presented in the following code snippet. The first number in each line provides the number of worker processes that should be started on the remote host. It is followed by an asterisk `*` character and the username on the remote host. In a production environment, you would provide IP addresses of the remote host rather than 127.0.0.1:

```plaintext
2*ubuntu@127.0.0.1
1*ubuntu@127.0.0.1
1*ubuntu@127.0.0.1
```

The preceding options will allow you to use Julia's distributed cluster mechanism on just a single local machine. We recommend that you also try adding the IP addresses of the remote machines to the preceding file.

Once you have the `machinefile.txt` file ready, you can tell Julia to load it by running the following command:
```sh
julia --machine-file machinefile.txt
```

This will launch the Julia master process and a number of Julia slave processes, according to the definitions given in the `machinefile.txt` file.

If you use a _High Performance Computing (HPC)_ system such as Cray, the passwordless SSH mechanism might not be available. However, such systems usually contain some form of cluster job management software, such as `SLURM`, `SGE`, or `PBS`. These job managers can be used from within Julia via the [ClusterManagers.jl](https://github.com/JuliaParallel/ClusterManagers.jl) package.

### DistributedArray

There are supports to the SPMD through the package DistributedArray. However, currently it is not so easy to learn, and the performance is bad.

1. To set the values of DArray, you need to first make them local. A typical way of doing this is by saying `mylp = d_in[:L]`, and them work on the local reference `mylp`.
2. The initialization of DArray requires special attention to the format. I opt for the do-block syntax, but the syntax itself needs some time to understand.

### MPI

This is probably the way to go for large-scale HPC across hundreds of nodes, because it utilizes infiniband.

1. I am still not sure about using MPI in Julia: since I can only do this in command line, does it mean that every time the code needs to be recompiled?

The answer is yes. This question reflects my misunderstanding of the underlying workflow: every Julia function and type is compiled the first time it is executed. This has nothing to do with MPI, which is a standard for inter-process communication. MPI is implemented in C, so the MPI.jl package is basically calling the C library for sending/receiving data from other processors.

## Multi-threading

Julia can be run in a multithreaded mode. This has gone through many improvements in recent versions, and may be subject to change in the future. This mode is achieved via the `JULIA_NUM_THREADS` system environment variable, or the `-t` option when opening Julia. One should perform the following steps:

* To start Julia with the number of threads equal to the number of cores in your machine, you have to set the environment variable `JULIA_NUM_THREADS` first; otherwise start Julia with `-p=N` where N is the number of threads.
* Check how many threads Julia is using with the `Threads.nthreads()` function.

As you have seen, in order to start Julia with multiple threads, you have to set the environment variable `JULIA_NUM_THREADS`. It is used by Julia to determine how many threads it should use. This value --- in order to have any effect --- must be set before Julia is started. This means that you can access it via the `ENV["JULIA_NUM_THREADS"]` option but changing it when Julia is running will not add or remove threads.

Many packages provides native threading support under the hood, for example, [Tullio.jl](https://github.com/mcabbott/Tullio.jl). However, the built-in threading control is currently limited, especially for nested loops. I wish the native Julia threading can be as good as OpenMP one day.

There is also a new threading library [Polyester.jl](https://github.com/JuliaSIMD/Polyester.jl) which is more restrictive but offers less overhead.

As of Julia 1.7,
* the garbage collector is still single-threaded, which indicates that it would be better to create as few garbages as possible (i.e. as few allocations as possible);
* there is no task migration: whichever thread creates the task is in charge of executing it. This is one of the reasons currently Julia won't benefit from hyperthreading.

## Hybrid Parallelism

Based on my experiments, it is possible to combine multi-processing and multi-threading togther. Here is a simple example which can be run with `julia -p 2 -t 2`:
```julia
@everywhere function foo(n)
   a = zeros(10)
   Threads.@threads for i = 1:10
      a[i] = Threads.threadid()
   end
   a
end

out = pmap(foo, 1:10)
```

---

Checkout more about CPU parallel computing in Julia in [ParallelJulia](https://github.com/henry2004y/ParallelJulia). 