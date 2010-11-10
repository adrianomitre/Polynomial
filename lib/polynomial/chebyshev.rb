$:.unshift File.join(File.dirname(__FILE__), '..')

require 'polynomial'

class Polynomial

  # Generate Chebyshev polynomials of first and second kinds.
  # For the mathematics, see {Wikipedia entry}[http://en.wikipedia.org/wiki/Chebyshev_polynomials].
  #
  module Chebyshev

    @fk = [Polynomial.new(1), Polynomial.new(0,1)]
    @sk = [Polynomial.new(1), Polynomial.new(0,2)]
    @fact = Polynomial.new(0,2)

    # Generate the n-th Chebyshev polynomial of the first kind using
    # a cached interactive implementation of the recurrence relation.
    # Caching reduces amortized (average after many calls) time consumption
    # to O(1) in the hypothetical case of infinite calls with uniform
    # distribution in a bounded range.
    #
    # Warning: due to caching, memory usage is proportional to the square of
    # the greatest degree computed. Use the uncached_first_kind method
    # if no caching is wanted.
    #
    def self.first_kind(n)
      n >= 0 or raise RangeError, 'degree should be non-negative'

      (@fk.size).upto(n) do |m|
        @fk[m] = (@fact * @fk[m-1] - @fk[m-2])
      end
      @fk[n]
    end

    # Same as second_kind, but uncached. It saves memory but the amortized time
    # consumption is higher, namely O(n^2).
    #
    def self.uncached_first_kind(n)
      n >= 0 or raise RangeError, 'degree should be non-negative'

      case n
      when 0 then Polynomial.new(1)
      when 1 then Polynomial.new(0,1)
      else
        prev2 = self.first_kind(0)
        prev1 = self.first_kind(1)
        curr = nil # scope
        (n-1).times do
          curr = (@fact * prev1 - prev2)
          prev1, prev2 = curr, prev1
        end
        curr
      end
    end

    # Generate the n-th Chebyshev polynomial of the second kind using
    # an cached-interactive implementation of the recurrence relation.
    # Caching reduces amortized (average after many calls) time consumption.
    #
    # Warning: due to caching, memory usage is proportional to the square of
    # the greatest degree computed. Use the uncached_second_kind method
    # if no caching is wanted.
    #
    def self.second_kind(n)
      n >= 0 or raise RangeError, 'degree should be non-negative'

      (@sk.size).upto(n) do |m|
        @sk[m] = (@fact * @sk[m-1] - @sk[m-2])
      end
      @sk[n]
    end

    # Same as second_kind, but uncached (saves memory but the amortized time
    # consumption is higher).
    #
    def self.uncached_second_kind(n)
      n >= 0 or raise RangeError, 'degree should be non-negative'

      case n
      when 0 then Polynomial.new(1)
      when 1 then Polynomial.new(0,2)
      else
        prev2 = self.second_kind(0)
        prev1 = self.second_kind(1)
        curr = nil # scope
        (n-1).times do
          curr = (@fact * prev1 - prev2)
          prev1, prev2 = curr, prev1
        end
        curr
      end
    end

  end

end
