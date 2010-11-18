require File.dirname(__FILE__) + '/test_helper.rb'

require 'benchmark'
require 'polynomial/chebyshev'
require 'saturator/bigmath_ext' # Saturator gem is required
include BigMath

if $0 == __FILE__

  m = 200
  n = 2**7
  x = BigDecimal(rand.to_s)
  prec = 20
  a = Polynomial::Chebyshev.first_kind(m)
  
  Benchmark.bmbm(7) do |foo|
    foo.report("trig:")  { n.times { cos(m*acos(x,prec), prec) } }
    foo.report("trig(tmp):")  do
      tmp = acos(x,prec)
      n.times { cos(m*tmp, prec) }
    end
    foo.report("poly:" )  { n.times { a.substitute(x) } }
  end
  
end
