my_path = File.dirname(File.expand_path(__FILE__))
require File.join(my_path, 'chebyshev')
require File.join(my_path, 'legendre')

class Polynomial

  # Generate ultraspherical (or Gegenbauer) polynomials.
  # For the mathematics, see {Wikipedia}[http://en.wikipedia.org/wiki/Gegenbauer_polynomials]
  # or {Mathworld entry}[http://mathworld.wolfram.com/GegenbauerPolynomial.html].
  #
  module Ultraspherical

    # Generates the ultraspherical (or Gegenbauer) polynomial of given degree
    # and parameter using an interactive implementation of the recurrence
    # relation which takes O(r^2) time.
    #
    def self.ultraspherical(degree, alpha)
      degree >= 0 or raise RangeError, 'degree should be non-negative'
      case alpha
      when 0   then Polynomial::Chebyshev.first_kind(degree)
      when 0.5 then Polynomial::Legendre.legendre(degree)
      when 1   then Polynomial::Chebyshev.second_kind(degree)
      else
        case degree
        when 0
          Polynomial.new(1)
        when 1
          Polynomial.new(0, 2*alpha)
        else
          prev2, prev1 = self.ultraspherical(0, alpha), self.ultraspherical(1, alpha)
          curr = nil # scope reasons
          2.upto(degree) do |m|
            a = Polynomial.new(0, 2*(m+alpha-1)) * prev1
            b = Polynomial.new(m+2*alpha-2) * prev2
            curr = (a - b).quo(m)
            raise RangeError, "alpha #{alpha} is degenerate for specified degree #{degree}" if curr.degree < m
            prev1, prev2 = curr, prev1
          end
          curr
        end
      end
    end
    class <<self; alias us ultraspherical; end

  end

end
