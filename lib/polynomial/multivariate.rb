begin
  require 'handy_hash'
rescue LoadError
  $stderr.puts 'HandyHash not be loaded, abbreviations not enabled'
  HandyHash ||= Hash
  Hash.class_eval { alias merge_abbrv merge }
end

$:.unshift File.join(File.dirname(__FILE__), '..')
require 'polynomial'

# TODO: consider building an writer for @terms which sorts the value
#       prior to actually setting it.

class Multivariate < Polynomial

  attr_reader :vars, :terms

  class <<self
    alias [] new
  end

  # Creates a new multivariate polynomial from supplied string representation,
  # basically delegating to Multivariate.from_string.
  #
  # Examples:
  #   Polynomial::Multivariate[[1,1,0],[2,0,1]].to_s #=> "x + 2*y"
  #--
  #   Polynomial::Multivariate['x+y'].to_s #=> "x + y"
  #   Polynomial::Multivariate['xy+y^3', :power_symbol=>'^'].to_s #=> "x*y + y**3"
  #++
  #
  def initialize(*terms)
    !terms.empty? or raise ArgumentError, 'at least one coefficient should be supplied'
    arg = terms[0]
    case arg
    when Array
      terms.flatten.all? {|a| a.is_a? Numeric } or raise TypeError, 'coefficient-power should be Numeric'
      sz = arg.size
      sz > 2 or raise ArgumentError, 'coefficient-power tuplets should have length > 2'
      terms.all? {|ary| ary.size == sz } or raise ArgumentError, 'inconsistent data'
    when String
      raise NotImplementedError
#      coefs = self.class.coefs_from_string(coefs[0], coefs[1] || {})
    else
      raise TypeError, 'coefficient-power should be Numeric'
    end
    @vars = sz - 1
    @terms = self.class.reduce_terms(terms).sort
  end

  # Evaluates Multivariate polynomial
  #--
  # FIXME: replace current straightforward but slow implementation
  #        by some efficient Horner's rule inspired algorithm.
  #++
  def substitute(*xs)
    xs.size == @vars or raise ArgumentError, "wrong number of arguments (#{xs.size} for #{@vars})"
    total = 0
    @terms.each do |coef, *powers|
      result = coef
      for i in 0 ... @vars
        result *= xs[i] ** powers[i]
      end
      total += result
    end
    total
  end

  def *(other)
    @vars == other.vars or raise ArgumentError, "number of variables must be the same for both multiplicands"
    new_terms = []
    @terms.each do |my_term|
      other.terms.each do |other_term|
        new_coef = my_term[0] * other_term[0]
        new_powers = my_term[1..-1].zip(other_term[1..-1]).map {|a,b| a + b }
        new_term = [new_coef] + new_powers
        new_terms << new_term
      end
    end
    self.class.new(*new_terms.sort)
  end

  # FIXME: implement efficiently, i.e., O(m) where m is the number of terms
  def **(n)
    n >= 0 or raise RangeError, "negative argument"
    n.is_a?(Integer) or raise TypeError, "non-integer argument"
    ([self]*n).inject(Unity) {|s,k| s*k }
  end

  def ==(other)
    self.instance_variables.all? do |var_name|
      self.instance_variable_get(var_name) == other.instance_variable_get(var_name)
    end
  end

  def degree(index)
    if index == 0
      0
    elsif index > 0 && index <= @vars
      @terms.map {|cp| cp[index] }.max
    else
      raise RangeError, 'invalid variable index'
    end
  end

  def coerce(other)
    case other
    when Numeric
      [self.class.new([other]), self]
    when Polynomial
      [other, self]
    else
      raise TypeError, "#{other.class} can't be coerced into Polynomial"
    end
  end

#  private
=begin
  def self.remove_trailing_zeroes(ary)
    m = 0
    ary.reverse.each.with_index do |a,n|
      unless a.all? {|z| z.zero? }
        m = n+1
        break
      end
    end
    ary[0..-m]
  end
=end

  # Group same powered terms.
  #
  # The result is always non-empty, the base case being [[0,..,0]]
  #
  def self.reduce_terms(terms)
    new_terms = []
    terms.group_by {|a,*powers| powers }.each_pair do |powers, terms|
      new_coef = 0
      terms.each {|coef, *rest| new_coef += coef }
      new_terms << [new_coef, *powers] unless new_coef.zero?
    end
    new_terms.empty? ? [terms[0].map { 0 }] : new_terms
  end

  public

  Unity = new([1,0,0])
  Zero = new([0,0,0])
  
end
