module InControl

export @control, Predicate

using MacroTools

shortcircuit{T}(::Type{T}) = method_exists(convert, (Type{Predicate}, T))

handle_if(pred, cons) = handle_if(pred, cons, nothing)

function handle_while end

abstract Predicate

Base.convert(::Type{Predicate}, x::Bool) = x

function custom_if(pred, cons, alt=:nothing)
  quote
    val = $pred
    if shortcircuit(typeof(val))
      if convert(Predicate, val)
        $cons
      else
        $alt
      end
    else
      handle_if($pred, $cons, $alt)
    end
  end
end

function custom_while(pred, body)
  quote
    val = $pred
    if shortcircuit(typeof(val))
      if convert(Predicate, val)
        $body  # TODO: scoping is wrong
        while convert(Predicate, $pred)
          $body
        end
      end
    else
      handle_while($pred, $body)
    end
  end
end

trans(x) = x

function trans(expr::Expr)
  if @capture expr if a_; b_; else c_ end
    custom_if(trans(a), trans(b), trans(c))
  elseif @capture expr if a_; b_ end
    custom_if(trans(a), trans(b))
  elseif @capture expr a_ && b_
    custom_if(trans(a), trans(b), false)
  elseif @capture expr a_ || b_
    custom_if(:(!$(trans(a))), trans(b), true)
  elseif @capture expr a_ ? b_ : c_
    custom_if(trans(a), trans(b), trans(c))
  elseif @capture expr while a_; b_; end
    custom_while(trans(a), trans(b))
  else
    Expr(expr.head, [trans(arg) for arg in expr.args]...)
  end
end

function _control(expr)
  is_func = @capture expr begin
    function f_(args__)
      body_
    end
  end
  if !is_func
    is_func = @capture expr begin
      f_(args__) = body_
    end
    is_func || error("Expected function")
  end
  quote
    function $(esc(f))($(args...))
      $(trans(body))
    end
  end
end

macro control(f)
  _control(f)
end

end # module
