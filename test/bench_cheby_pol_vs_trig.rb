require 'benchmark'

$:.unshift File.join(File.dirname(__FILE__),'..','lib', 'saturator')

require 'chebyshev'
require 'bigmath_ext'
include BigMath

if $0 == __FILE__

  m = 200
  n = 2**7
  x = BigDecimal(rand.to_s)
  prec = 20
  a = Chebyshev.first_kind(m)
  
  Benchmark.bmbm(7) do |foo|
    foo.report("trig:")  { n.times { cos(m*acos(x,prec), prec) } }
    foo.report("trig(tmp):")  do
      tmp = acos(x,prec)
      n.times { cos(m*tmp, prec) }
    end
    foo.report("poly:" )  { n.times { a.substitute(x) } }
  end
  
end
