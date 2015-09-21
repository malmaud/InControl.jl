using InControl
using Base.Test

@control function f(x)
  if x
    1
  else
    -1
  end
end

# Short-circuiting example
Base.convert(::Type{Predicate}, x::Nullable{Bool}) = get(x)
@test f(Nullable(false)) == -1


# Non-short-circuiting
immutable IfTrace
  predicate
  consequent
  alternative
end

type Trace{T}
  value::T
end

function InControl.handle_if(predicate::Trace, consequent, alternative)
  IfTrace(predicate.value, consequent, alternative)
end

@test f(Trace(:test)) == IfTrace(:test, 1, -1)

# Other control operators
@control g1(x) = if x; 1; end
@control g2(x) = x && 1
@control g3(x) = x || 1
@control function g4(x)
  s=0
  while x>0
    s+=1
    x-=1
  end
  s
end

import Base: !, -, >
for op in [:!, :-, :>]
  @eval $op(x::Nullable, args...) = Nullable($op(get(x), args...))
end

let ntrue=Nullable(true), nfalse=Nullable(false)
  @test g1(ntrue) == 1
  @test g1(nfalse) == nothing
  @test g2(ntrue) == 1
  @test g2(nfalse) == false
  @test g3(ntrue) == true
  @test g3(nfalse) == 1
end

@test g4(Nullable(5)) == 5
