InControl
==========

[![Build Status](https://travis-ci.org/malmaud/InControl.jl.svg?branch=master)](https://travis-ci.org/malmaud/InControl.jl)

Intro
-----
This package lets you customize the behavior of control statements like `if` and `while` by dispatching to user-defined functions based on the type of the predicate.

It fixes a hole in the generic programming toolkit of Julia: while multiple-dispatch is a great tool at letting you customize how a generic function will behave when passed your custom type as an argument, it fails if the function uses the argument as the predicate in an `if` or `while` statement as those statements **require** a Bool in the predicate slot.

Usage
----
Decorate the function with control structures you want to override with `@control`. Then:

* Easy case: You want the normal behavior of control statements, except you want the predicate to be convertible to a boolean rather than literally being a boolean. In that case, define a `convert(::Type{Predicate}, x)` method:

```julia
Base.convert(::Type{Predicate}, x::Nullable{Bool}) = get(x)
@control function f(x)
  if x
    1
  else
    -1
  end
end

@assert f(Nullable(false)) == -1
```

* General case: You want to totally customize the semantics of control statements, including possibly turning off the short-circuit behavior. Define a custom method `handle_if(predicate::CustomPredicateType, consequent, alternative)`:

```julia
immutable IfTrace
  predicate
  consequent
  alternative
end

immutable TracedValue{T}
  value::T
end  

function InControl.handle_if(predicate::TracedValue, consequent, alternative)
  IfTrace(predicate.value, consequent, alternative)
end

>> f(TracedValue(:my_test))
IfTrace(:my_test, 1, -1)
```

`while` loops are also customizable via `handle_white(predicate, body)`.

Examples
-----
See `runtests.jl` for additional examples.

----
By Jon Malmaud (`@malmaud`)
