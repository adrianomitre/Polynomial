my_path = File.dirname(File.expand_path(__FILE__))
require File.join(my_path, '../polynomial')

class Polynomial

  # Generate Legendre polynomials.
  # For the mathematics, see {Wikipedia entry}[http://en.wikipedia.org/wiki/Legendre_polynomials].
  #
  module Legendre

    @cache = [Polynomial.new(1), Polynomial.new(0,1)]

    # Generate the n-th Legendre polynomial using a cached interactive
    # implementation of the recurrence relation.
    # Caching reduces amortized (average after many calls) time consumption
    # to O(1) in the hypothetical case of infinite calls with uniform
    # distribution in a bounded range.
    #
    # Warning: due to caching, memory usage is proportional to the square of
    # the greatest degree computed. Use the uncached_first_kind method
    # if no caching is wanted.
    #
    def self.cached_legendre(n)
      n >= 0 or raise RangeError, 'degree should be non-negative'

      for m in @cache.size-1 ... n
        @cache[m+1] = (Polynomial.new(0,2*m+1)*@cache[m] - m*@cache[m-1]).quo(m+1)
      end
      @cache[n]
    end
    class <<self; alias legendre cached_legendre; end

    # Generate the n-th Legendre polynomial, but uncached.
    # It saves memory but the amortized time consumption is higher,
    # namely O(n^2).
    #
    def self.uncached_legendre(n)
      n >= 0 or raise RangeError, 'degree should be non-negative'

      case n
      when 0 then @cache[0]
      when 1 then @cache[1]
      else
        prev2 = @cache[0]
        prev1 = @cache[1]
        curr = nil # scope
        for m in 1 ... n
          curr = (Polynomial.new(0,2*m+1)*prev1 - m*prev2).quo(m+1)
          prev1, prev2 = curr, prev1
        end
        curr
      end
    end

  end

end
