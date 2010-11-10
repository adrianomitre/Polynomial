begin
  require 'handy_hash'
rescue LoadError
  $stderr.puts 'HandyHash not be loaded, abbreviations not enabled'
  HandyHash ||= Hash
  Hash.class_eval { alias merge_abbrv merge }
end

# Polynomials on a single variable.
#
class Polynomial

  class <<self
    alias [] new
  end

  # Creates a new polynomial with provided coefficients, which are interpreted
  # as corresponding to increasing powers of _x_. Alternatively, a hash
  # of power=>coefficients may be supplied, as well as the polynomial
  # degree plus a block to compute each coefficient from correspoding degree.
  # If a string, optionally followed by a arguments hash, is supplied,
  # from_string is called.
  #
  # Examples:
  #   Polynomial.new(1, 2).to_s #=> 1 + 2*x
  #   Polynomial.new(1, Complex(2,3)).to_s #=> 1 + (2+3i)*x
  #   Polynomial.new(1) {|n| n+1 }.to_s #=> 1 + 2*x
  #   Polynomial[3, 4, 5].to_s #=> 3 + 4*x + 5x**2
  #   Polynomial[1 => 2, 3 => 4].to_s #=> 2*x + 4x**3
  #   Polynomial['x^2-1', :power_symbol=>'^'].to_s #=> -1 + x**2
  #
  def initialize(*coefs)
    case coefs[0]
    when Integer
      if block_given?
        coefs = 0.upto(coefs[0]).map {|degree| yield(degree) }
      end
    when Hash
      coefs = self.class.coefs_from_pow_coefs(coefs[0])
    when String
      coefs = self.class.coefs_from_string(coefs[0], coefs[1] || {})
    else
      coefs.flatten!
      if coefs.empty?
        raise ArgumentError, 'at least one coefficient should be supplied'
      elsif !coefs.all? {|c| c.is_a? Numeric }
        raise TypeError, 'non-Numeric coefficient supplied'
      end
    end
    @coefs = Polynomial.remove_trailing_zeroes(coefs)
  end
  
  FromStringDefaults = HandyHash[
    :power_symbol => '**',
    :multiplication_symbol => '*',
    :variable_name => 'x',
  ]
  # Creates Polynomial from a String in appropriate format.
  # Coefficients must be integers or decimals (interpreted as floats).
  #
  # Warning: complex coefficients are not currently accepted.
  #
  # Examples:
  #   Polynomial.from_string("1 - 7*x**2") == Polynomial.new(1,0,-7) #=> true
  #   Polynomial.from_string("3 + 4.1x + 5x^2", :multiplication_symbol=>'', :power_symbol=>'^') == Polynomial.new(3,4.1,5) #=> true
  #   Polynomial.from_string("-3*y", :variable_name=>'y') == Polynomial.new(0,-3) #=> true
  #   Polynomial.from_string('x^2-1', :power_symbol=>'^').to_s #=> -1 + x**2
  #
  def self.from_string(s, params={})
    Polynomial.new(self.coefs_from_string(s, FromStringDefaults.merge_abbrv(params)))
  end
  
  # Degree of the polynomial (i.e., highest not null power of the variable).
  #
  def degree
    @coefs.size-1
  end
  
  # Evaluates Polynomial of degree _n_ at point _x_ in O(_n_) time using Horner's rule.
  #
  def substitute(x)
    total = @coefs.last
    @coefs[0..-2].reverse.each do |a|
      total = total * x + a
    end
    total
  end

  # Returns true if (and only if) the polynomial is null.
  #
  def zero?
    @coefs == [0]
  end

  # Returns an array with the 1st, 2nd, ..., +degree+ derivatives.
  # These are the only possibly non null derivatives, subsequent ones would
  # necesseraly be zero.
  #
  def derivatives
    ds = []
    d = self
    begin
      d = d.derivative
      ds << d
    end until d.zero?
    ds
  end

  def coerce(other)
    case other
    when Numeric
      [Polynomial.new(other), self]
    when Polynomial
      [other, self]
    else
      raise TypeError, "#{other.class} can't be coerced into Polynomial"
    end
  end
  
  # Add another Polynomial or Numeric object.
  #
  def +(other)
    case other
      when Numeric
        self + Polynomial.new(other)
      else
        small, big = [self, other].sort
        a = big.coefs
        for n in 0 .. small.degree
          a[n] += small.coefs[n]
        end
        Polynomial.new(a)
    end
  end
  
  # Generates a Polynomial object with negated coefficients.
  #
  def -@
    Polynomial.new(coefs.map {|x| -x})
  end
  
  # Subtract another Polynomial or Numeric object.
  #
  def -(other)
    self + (-other)
  end
  
  # Multiply by another Polynomial or Numeric object.
  # As the straightforward algorithm is used, multipling two polynomials of
  # degree _m_ and _n_ takes O(_m_ _n_) operations. It is well-known, though,
  # that the Fast Fourier Transform may be employed to reduce the time
  # complexity to O(_K_ log _K_), where _K_ = max{_m_, _n_}.
  #
  def *(other)
    case other
    when Numeric
      result_coefs = @coefs.map {|a| a * other}
    else
      result_coefs = [0] * (self.degree + other.degree + 2)
      for m in 0 .. self.degree
        for n in 0 .. other.degree
          result_coefs[m+n] += @coefs[m] * other.coefs[n]
        end
      end
    end
    Polynomial.new(result_coefs)
  end

  # Divides by +divisor+ (using coefficients' #quo), returning quotient and rest.
  # If dividend and divisor have Intenger or Rational coefficients,
  # then both quotient and rest will have Rational coefficients.
  # If +divisor+ is a polynomial, uses polynomial long division.
  # Otherwise, performs the division direclty on the coefficients.
  #
  def quomod(divisor)
    case divisor
    when Numeric
      new_coefs = @coefs.map {|a| a.quo(divisor) }
      q, r = Polynomial.new(new_coefs), 0
    when Polynomial
      a = self; b = divisor; q = 0; r = self
      (a.degree - b.degree + 1).times do
        dd = r.degree - b.degree
        qqa = r.coefs[-1].quo(b.coefs[-1])
        qq = Polynomial[dd => qqa]
        q += qq
        r -= qq * divisor
        break if r.zero?
      end
    else
      raise ArgumentError, 'divisor should be Numeric or Polynomial'
    end
    [q, r]
  end

  # Divides by +divisor+ (using coefficients' #quo), which may be a number
  # or another polynomial, which need not be divisible by the former.
  # If dividend and divisor have Intenger or Rational coefficients,
  # then the quotient will have Rational coefficients.
  #
  #
  def quo(divisor)
    quomod(divisor).first
  end

  # Divides by +divisor+, returing quotient and rest.
  # If +divisor+ is a polynomial, uses polynomial long division.
  # Otherwise, performs the division direclty on the coefficients.
  #
  def divmod(divisor)
    case divisor
    when Numeric
      new_coefs = @coefs.map do |a|
        if divisor.is_a?(Integer)
          qq, rr = a.divmod(divisor)
          if rr.zero? then qq else a / divisor.to_f end
        else
          a / divisor
        end
      end
      q, r = Polynomial.new(new_coefs), 0
    when Polynomial
      a = self; b = divisor; q = 0; r = self
      (a.degree - b.degree + 1).times do
        dd = r.degree - b.degree
        qqa = r.coefs[-1] / (b.coefs[-1].to_f rescue b.coefs[-1]) # rescue for complex numbers
        qq = Polynomial[dd => qqa]
        q += qq
        r -= qq * divisor
        break if r.zero?
      end
    else
      raise ArgumentError, 'divisor should be Numeric or Polynomial'
    end
    [q, r]
  end

  # Divides polynomial by a number or another polynomial,
  # which need not be divisible by the former.
  #
  def div(other)
    divmod(other).first
  end
  alias / div

  # Remainder of division by supplied divisor, which may be another polynomial
  # or a number.
  #
  def %(other)
    divmod(other).last
  end

  # Raises to non-negative integer power.
  #
  def **(n)
    raise ArgumentError, "negative argument" if n < 0
    result = Polynomial[1]
    n.times do
      result *= self
    end
    result
  end

  # Computes polynomial's indefinite integral (which is itself a polynomial).
  #
  def integral
    a = Array.new(@coefs.size+1)
    a[0] = 0
    @coefs.each.with_index do |coef, n|
      if coef.is_a?(Integer) && coef.modulo(n+1).zero?
        a[n+1] = coef / (n + 1)
      else
        a[n+1] = coef / (n + 1.0)
      end
    end
    Polynomial.new(a)
  end
  
  # Computes polynomial's derivative (which is itself a polynomial).
  #
  def derivative
    if degree > 0
      a = Array.new(@coefs.size-1)
      a.each_index { |n| a[n] = (n+1) * @coefs[n+1] }
    else
      a = [0]
    end
    Polynomial.new(a)
  end
  
  ToSDefaults = HandyHash[
    :verbose => false,
    :spaced => true,
    :power_symbol => '**',
    :multiplication_symbol => '*',
    :variable_name => 'x',
    :decreasing => false
  ]
  # Generate the string corresponding to the polynomial.
  # If :verbose is false (default), omits zero-coefficiented monomials.
  # If :spaced is true (default), monomials are spaced.
  # If :decreasing is false (default), monomials are present from
  # lowest to greatest degree.
  #
  # Examples:
  #   Polynomial[1,-2,3].to_s #=> "1 - 2*x + 3*x**2"
  #   Polynomial[1,-2,3].to_s(:spaced=>false) #=> "1-2*x+3*x**2"
  #   Polynomial[1,-2,3].to_s(:decreasing=>true) #=> "3*x**2 - 2*x + 1"
  #   Polynomial[1,0,3].to_s(:verbose=>true) #=> "1 + 0*x + 3*x**2"
  #
  def to_s(params={})
    params = ToSDefaults.merge_abbrv(params)
    mult = params[:multiplication_symbol]
    pow = params[:power_symbol]
    var = params[:variable_name]
    coefs_index_enumerator = if params[:decreasing]
                               @coefs.each.with_index.reverse_each
                             else
                               @coefs.each.with_index
                             end
    result = ''
    coefs_index_enumerator.each do |a,n|
      next if a.zero? && degree > 0 && !params[:verbose]
      result += '+' unless result.empty?
      coef_str = a.to_s
      coef_str = '(' + coef_str + ')' if coef_str[/[+\/]/]
      result += coef_str unless a == 1 && n > 0
      result += "#{mult}" if a != 1 && n > 0
      result += "#{var}" if n >= 1
      result += "#{pow}#{n}" if n >= 2
    end
    result.gsub!(/\+-/,'-')
    result.gsub!(/([^e\(])(\+|-)(.)/,'\1 \2 \3') if params[:spaced]
    result
  end

  # Converts a zero-degree polynomial to a number, i.e., returns its only
  # coefficient. If degree is positive, an exception is raised.
  #
  def to_num
    if self.degree == 0
      @coefs[0]
    else
      raise ArgumentError, "can't convert Polynomial of positive degree to Numeric"
    end
  end

  # Returns the only coefficient of a zero-degree polynomial converted to a
  # Float. If degree is positive, an exception is raised.
  #
  def to_f; to_num.to_f; end
  
  # Returns the only coefficient of a zero-degree polynomial converted to an
  # Integer. If degree is positive, an exception is raised.
  #
  def to_i; to_num.to_i; end
  
  # If EasyPlot can be loaded, plot method is defined.
  begin
    require 'easy_plot'

    # Plots polynomial using EasyPlot.
    #
    def plot(params={})
      EasyPlot.plot(self.to_s, params)
    end
  rescue LoadError
    $stderr.puts 'EasyPlot could not be loaded, thus plotting convenience methods were not defined.'
  end

  attr_reader :coefs
  
  # Compares with another Polynomial by degrees then coefficients.
  #
  def <=>(other)
    case other
    when Numeric
      [self.degree, @coefs[0]] <=> [0, other]
    when Polynomial
      [self.degree, @coefs] <=> [other.degree, other.coefs]
    else
      raise TypeError, "can't compare #{other.class} to Polynomial"
    end
  end
  include Comparable
  
  # Returns true if the other Polynomial has same degree and close-enough
  # (up to delta absolute difference) coefficients. Returns false otherwise.
  #
  def equal_in_delta(other, delta)
    return false unless self.degree == other.degree
    for n in 0 .. degree
      return false unless (@coefs[n] - other.coefs[n]).abs <= delta
    end  
    true
  end
  
  private

  def self.remove_trailing_zeroes(ary)
    m = 0
    ary.reverse.each.with_index do |a,n|
      unless a.zero?
        m = n+1
        break
      end
    end
    ary[0..-m]
  end

  # Converts a power-to-coefficient Hash into the Array of coefficients.
  #
  def self.coefs_from_pow_coefs(hash, params={})
    power_coefs = Hash.new(0).merge(hash)
    (0..power_coefs.keys.max).map {|p| power_coefs[p] }
  end
  
  # Extracts the Array of coefficients from a String.
  #
  def self.coefs_from_string(s, params={})
    h = pow_coefs_from_string(s, params)
    coefs_from_pow_coefs(h, params)
  end
  
  # Extracts a power-to-coefficient Hash from a String.
  #
  def self.pow_coefs_from_string(s, params={})
    h = Hash.new(0)
    begin
      power, coef, s = parse_term(s, params)
      h[power] += coef
    end until s.strip.empty?
    h
  end

  # Parses a single polynomial term (i.e., a monomial). Returns an array with
  # degree (power), coeficient and the remainder of the string, which may
  # contains other terms.
  #
  # Example:
  #   Polynomial.parse_term('x**2-3') #=> [2, 1, '-3']
  #   Polynomial.parse_term('4') #=> [0, 4, '']
  #
  def self.parse_term(string, params={})
    params = FromStringDefaults.merge(params)
    mult = Regexp.escape(params[:multiplication_symbol])
    pow_sym = Regexp.escape(params[:power_symbol])
    var = Regexp.escape(params[:variable_name])
    opt_sign = '(\+|-)?'
    int = '(\d+)'
    decimal = '(\d+(?:\.\d+)?(?:[eE]\-?\d+)?)'
    opt_space = '\s*'
    anything = '(.*)'
    tbp = string.strip # tbp stands for 'to be parsed'
    power, coef = nil, nil # scope reasons
    make_regex = lambda {|core| Regexp.new('^' + core + '$') }

    # matches terms starting with numbers, possibly signed, such as '1', '2.5', '- 3.3', '3*x', '4*x**2'
    if md = make_regex[opt_sign + opt_space + decimal + anything].match(tbp)
      sn = md[1] ? md[1]+md[2] : md[2]
      coef = Integer(sn) rescue Float(sn)
      tbp = md[-1]
      if md = make_regex[mult + var + anything].match(tbp)
        tbp = md[-1]
        if md = make_regex[pow_sym + int + anything].match(tbp)
          power = Integer(md[1])
          tbp = md[-1]
        else
          power = 1
        end
      else
        power = 0
      end
    # matches terms starting with variable, such as 'x', 'x**2'
    elsif md = make_regex.call(opt_sign + opt_space + var + anything).match(tbp)
      power, coef, tbp = 1, 1, md[-1].strip
      if md = make_regex[pow_sym + int + anything].match(tbp)
        power = Integer(md[1])
        tbp = md[-1]
      end
    end
    unless [power, coef].none? {|val| val.nil? } && (tbp[/^\s*\+|-/] || tbp.empty?)
      raise ArgumentError, "invalid value for Polynomial: \"#{string}\""
    end
    [power, coef, tbp]
  end

  public

  Zero = new([0])
  Unity = new([1])

  def zero?
    self == Zero
  end

  def unity?
    self == Unity
  end
  
end
