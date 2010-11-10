$:.unshift File.dirname(__FILE__)

require 'polynomial'

# Generate Chebyshev polynomials of first and second kinds.
# For the mathematics, see {Wikipedia entry}[http://en.wikipedia.org/wiki/Chebyshev_polynomials].
#
module Chebyshev

  #-- for documentation purposes, not the actual method definition
  #++
  # Generate the n-th Chebyshev polynomial of the first kind using an
  # interactive version of the recurrence relation.
  #
  def self.first_kind(n); end

  #-- for documentation purposes, not the actual method definition
  #++
  # Generate the n-th Chebyshev polynomial of the second kind using an
  # interactive version of the recurrence relation.
  #
  def self.second_kind(n); end

  class << self

    Kind = Struct.new(:name, :zeroth, :first)
    kinds = [ Kind.new('first', Polynomial.new(1), Polynomial.new(0,1)),
      Kind.new('second', Polynomial.new(1), Polynomial.new(0,2)) ]
    kinds.each do |k|
      full_name = k.name+'_kind'
      define_method(full_name) do |n|
        n >= 0 or raise RangeError, 'degree should be non-negative'
        case n
        when 0 then k.zeroth
        when 1 then k.first
        else
          prev2 = self.send(full_name, 0)
          prev1 = self.send(full_name, 1)
          fact = Polynomial.new(0,2)
          curr = nil # scope
          (n-1).times do
            curr = (fact * prev1 - prev2)
            prev1, prev2 = curr, prev1
          end
          curr
        end
      end
    end
  end

=begin
  # Generate the n-th Chebyshev polynomial of the first kind recursively,
  # but using memoization (i.e., cache results for already calculed recursion
  # branches). It is roughly twice as slow as the interactive version.
  #
  def self.first_kind_recursive(n)
    n >= 0 or raise RangeError, 'degree should be non-negative'
    
    return @@fk[n] if @@fk[n]
    
    @@fk[n] = case n
              when 0
              	Polynomial.new(1)
              when 1
              	Polynomial.new(0,1)
              else
                Polynomial.new(0,2) * self.first_kind(n-1) - self.first_kind(n-2)
              end
  end
=end
  
=begin
  @@sk = []
=end
  @@fk = [Polynomial.new(1), Polynomial.new(0,1)]


  # Generate the n-th Chebyshev polynomial of the first kind interatively.
  #
  def self.first_kind_interactive(n)
    n >= 0 or raise RangeError, 'degree should be non-negative'

    case n
    when 0 then @@fk[0]
    when 1 then @@fk[1]
    else
      prev2 = self.first_kind(0)
      prev1 = self.first_kind(1)
      fact = Polynomial.new(0,2)
      curr = nil # scope
      (@@fk.size).upto(n) do |m|
        @@fk[m] = (fact * @@fk[m-1] - @@fk[m-2])
      end
      @@fk[n-1]
    end
  end
#  class <<self; alias first_kind first_kind_interactive; end

=begin
  # Generate the n-th Chebyshev polynomial of the second kind recursively,
  # but using memoization (i.e., cache results for already calculed recursion
  # branches). It is roughly twice as slow as the interactive version.
  #
  def self.second_kind_recursive(n)
    n >= 0 or raise RangeError, 'degree should be non-negative'
    
    return @@sk[n] if n < @@sk.size
    
    @@sk[n] = case n
              when 0
              	Polynomial.new(1)
              when 1
              	Polynomial.new(0,2)
              else
              	-self.second_kind(n-2) + Polynomial.new(0,2) * self.second_kind(n-1)
              end
  end

  # Generate the n-th Chebyshev polynomial of the second kind interactively.
  #
  def self.second_kind_interactive(n)
    n >= 0 or raise RangeError, 'degree should be non-negative'

    case n
    when 0
      Polynomial.new(1)
    when 1
      Polynomial.new(0,2)
    else
      prev2 = self.second_kind(0)
      prev1 = self.second_kind(1)
      fact = Polynomial.new(0,2)
      curr = nil # scope
      (n-1).times do
        curr = (fact * prev1 - prev2)
        prev1, prev2 = curr, prev1
      end
      curr
    end
  end
  class <<self; alias second_kind second_kind_interactive; end
=end
end

