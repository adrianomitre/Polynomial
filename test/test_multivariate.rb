require File.dirname(__FILE__) + '/test_helper.rb'
require 'complex'
require 'bigdecimal'
require 'polynomial/multivariate'

MVP = Multivariate

class TestPoly < Test::Unit::TestCase

  @@epsilon = 1e-7

  def setup
    @one = MVP::Unity
    @zero = MVP::Zero
  end
  
  def test_incorrect_initialization
    assert_raise(ArgumentError) { MVP.new }
    assert_raise(ArgumentError) { MVP.new [] }
    assert_raise(ArgumentError) { MVP.new [1], [2] }
    assert_raise(ArgumentError) { MVP.new [1,2], [3,4] }
    assert_raise(ArgumentError) { MVP.new [1,2,3], [4,5] }
    assert_raise(TypeError) { MVP.new :oops }
    assert_raise(TypeError) { MVP.new ['foo'] }
  end

  def test_initialization
    assert_equal(MVP.new([1,0,0]), MVP.new([1,0,0],[0,0,3]))
  end

  def test_equal
    assert_equal(MVP.new([1,0,0]), MVP.new([1,0,0]))
    assert_not_equal(MVP.new([1,0,0]), MVP.new([1,1,0]))
    assert_not_equal(MVP.new([1,0,0]), MVP.new([1,0,1]))
  end

  def test_degree
    q = MVP.new([1,0,0],[1,0,3])
    assert_equal(0, q.degree(0))
    assert_equal(0, q.degree(1))
    assert_equal(3, q.degree(2))
  end

  CoefficientsVariablesValues = {
    [[1,0,0]] => {
      [0,0] => 1, [0,1] => 1, [1,0] => 1, [1,1] => 1, [1,-1] => 1, [-1,-1] => 1,
    },
    [[1,0,0],[1,1,0],[1,0,1]] => {
      [0,0] => 1, [0,1] => 2, [1,0] => 2, [1,1] => 3, [1,-1] => 1,
      [-1,-1] => -1, [0,-1] => 0,
    },
    [[2,2,0],[3,0,3]] => {
      [0,0] => 0, [0,1] => 3, [1,0] => 2, [1,1] => 5, [1,-1] => -1,
      [-1,-1] => -1, [0,-1] => -3, [-1,0] => 2, [2,0] => 8, [0,2] => 24,
      [3,0] => 18, [0,3] => 81,
    },
  }
  def test_substitute
    CoefficientsVariablesValues.each_pair do |coefs_ary, var_val|
      q = MVP.new(*coefs_ary)
      var_val.each_pair do |var, val|
        error_msg = "coefs_ary=#{coefs_ary.inspect}\nvar=#{var.inspect}\nval=#{val}"
        assert_equal val, q.substitute(*var), error_msg
      end
    end
  end

  def test_multiplication
    a = MVP.new([2,0,0])
    b = MVP.new([1,1,0])
    c = MVP.new([2,1,0])
    assert_equal c, a*b
    d = MVP.new([2,2,0])
    assert_equal d, b*c
    e = MVP.new([3,0,3])
    f = MVP.new([6,2,3])
    assert_equal f, d*e
    a = MVP.new([2,0,0], [3,5,0], [7,0,11])
    aa = MVP.new([4, 0, 0], [9, 10, 0], [49, 0, 22], [28, 0, 11], [42, 5, 11], [12, 5, 0])
    assert_equal aa, a*a
  end

  def test_unity_and_zero
    assert_equal @one, @one*@one
    assert_not_equal @zero, @one
    assert_equal @zero, @one*@zero
    q = MVP.new([2,0,0], [3,5,0], [7,0,11])
    assert_equal q, @one*q
    assert_equal @zero, q*@zero
  end

  def test_power
    assert_equal @one, @zero**0
    assert_equal @zero, @zero**1
    assert_equal @zero, @zero**2
    q = MVP.new([2,0,0], [3,5,0], [7,0,11])
    assert_equal @one, q**0
    assert_equal q*q, q**2
    assert_equal q*q*q, q**3
    assert_raise(RangeError) { q**(-1) }
    assert_raise(TypeError) { q**(2.3) }
  end

=begin
  def test_new_from_coefficients
    assert_nothing_raised { Poly.new 0 }
    assert_nothing_raised { Poly.new [0] }
    assert_nothing_raised { Poly.new [1,2] }
    assert_nothing_raised { Poly.new [1, 2.2] }
    assert_nothing_raised { Poly.new [1, Complex(0,1)] }
    assert_nothing_raised { Poly.new [1, BigDecimal('1e-2')] }
    assert_nothing_raised { Poly.new 1,2 }
    assert_equal Poly.new(1,2), Poly.new([1,2])
    assert_equal Poly.new(1), Poly.new(1,0)
    assert_equal Poly.new(1), Poly.new([1,0,0])
    assert_equal Poly.new(1,2,3), Poly[1,2,3]
  end

  def test_new_from_block
    assert_equal Poly.new(0,1,2), Poly.new(2) {|n| n }
    assert_equal Poly.new(1,2,3), Poly.new(2) {|n| n+1 }
    assert_equal Poly.new(0,1,4,9), Poly.new(3) {|n| n**2 }
    assert_equal Poly.new(3.2), Poly.new(3.2) {|n| n**2 }
  end
  
  def test_new_from_power_coefficients_hash
    assert_equal Poly[0,2], Poly.new({1=>2})
    assert_equal Poly[0,0,3], Poly.new({2=>3})
    assert_equal Poly[0,2,3], Poly[1=>2, 2=>3]
  end
  
  def test_new_from_valid_strings
    assert_equal Poly[0], Poly['0']
    assert_equal Poly[1], Poly['  1  ']
    assert_equal Poly[-1], Poly['-1']
    assert_equal Poly[-1.3], Poly['-1.3']
    assert_equal Poly[0,1], Poly['x']
    assert_equal Poly[0,1], Poly['+x']
    assert_equal Poly[0,1], Poly['+1x', {:multiplication_symbol=>''}]
    assert_equal Poly[1,1], Poly['1+x']
    assert_equal Poly[1,1], Poly['1+1x', {:multiplication_symbol=>''}]
    assert_equal Poly[0,0,3], Poly['3*x**2']
    assert_equal Poly[0,0,1], Poly['x**2']
    assert_equal Poly[3,0,1], Poly['3+x**2']
    assert_equal Poly[3,0,1], Poly['3+x^2', {:power_symbol=>'^'}]
    assert_equal Poly[3,2], Poly['3+2*x']
    assert_equal Poly[2,1], Poly['2+y', {:variable_name=>'y'}]
    assert_equal Poly['4*x**2+2'], Poly[2,0,4]
    assert_equal Poly['  4*x**2  +  2  '], Poly[2,0,4]
    assert_equal Poly[1,0,-7], Poly.from_string("1 - 7*x**2")
    assert_equal Poly[3,4.1,5], Poly.from_string("3 + 4.1x + 5x^2", :multiplication_symbol=>'', :power_symbol=>'^')
    assert_equal Poly[0,-3], Poly.from_string("-3*y", :variable_name=>'y')
    assert_equal Poly[1e-2], Poly.from_string('1e-2')
    assert_equal Poly[0,1e-2], Poly.from_string('1e-2*x')
    assert_equal Poly[BigDecimal('1.1')], Poly.from_string(BigDecimal('1.1').to_s)
  end
  
  def test_from_invalid_strings_misc
    assert_raise(ArgumentError) { Poly[''] }
    assert_raise(ArgumentError) { Poly['1..'] }
    assert_raise(ArgumentError) { Poly['1..1'] }
    assert_raise(ArgumentError) { Poly['+'] }
    assert_raise(ArgumentError) { Poly['++1'] }
    assert_raise(ArgumentError) { Poly['-+1'] }
    assert_raise(ArgumentError) { Poly['--1'] }
    assert_raise(ArgumentError) { Poly['1-'] }
    assert_raise(ArgumentError) { Poly['1.2-'] }
    assert_raise(ArgumentError) { Poly['xx'] }
    assert_raise(ArgumentError) { Poly['xx**2'] }
    assert_raise(ArgumentError) { Poly['x*x'] }
    assert_raise(ArgumentError) { Poly['x**x'] }
    assert_raise(ArgumentError) { Poly['2**3'] }
    assert_raise(ArgumentError) { Poly['x**3*4'] }
    assert_raise(ArgumentError) { Poly['e2'] }
    assert_raise(ArgumentError) { Poly['1e--2'] }
    assert_raise(ArgumentError) { Poly['1ee2'] }
  end
  
  def test_from_invalid_strings_incomplete
    assert_raise(ArgumentError) { Poly['1+'] }
    assert_raise(ArgumentError) { Poly['1.2+'] }
    assert_raise(ArgumentError) { Poly['1*'] }
    assert_raise(ArgumentError) { Poly['1.2*'] }
    assert_raise(ArgumentError) { Poly['2*x**'] }
  end

  def test_from_invalid_strings_symbol_omission
    assert_raise(ArgumentError) { Poly['1x'] }
    assert_raise(ArgumentError) { Poly['1.2x'] }
    assert_raise(ArgumentError) { Poly['2*x3'] }
  end

  def test_from_invalid_strings_spaces
    assert_raise(ArgumentError) { Poly['1 * x'] }
    assert_raise(ArgumentError) { Poly['1 *x'] }
    assert_raise(ArgumentError) { Poly['1* x'] }
    assert_raise(ArgumentError) { Poly['1*x ** 2'] }
    assert_raise(ArgumentError) { Poly['1*x **2'] }
    assert_raise(ArgumentError) { Poly['1*x** 2'] }
  end
  
  def test_from_string_repeated
    assert_equal Poly['1+2'], Poly[3]
    assert_equal Poly['x+3*x'], Poly[0,4]
    assert_equal Poly['1+x+x**2+2*x**2'], Poly[1,1,3]
  end
  
  def test_substitute
    poly = Poly[0]
    pairs = [[0,0], [1,0], [-1,0], [2,0], [0.33, 0]]
    assert_in_out_pairs(poly, pairs)

    poly = Poly[0, 1]
    pairs = [[0,0], [1,1], [-1,-1], [2,2], [0.33, 0.33]]
    assert_in_out_pairs(poly, pairs)

    poly = Poly[0, 0, 1]
    pairs = [[0,0], [1,1], [-1,1], [2,4], [0.33, 0.33**2]]
    assert_in_out_pairs(poly, pairs)

    poly = Poly[1, 1]
    pairs = [[0,1], [1,2], [-1,0], [2,3], [0.33, 1.33]]
    assert_in_out_pairs(poly, pairs)

    poly = Poly[1, -1]
    pairs = [[0,1], [1,0], [-1,2], [2,-1], [0.33, 1-0.33]]
    assert_in_out_pairs(poly, pairs)
    
    poly = Poly[Complex(0,1), 1]
    pairs = [[0,Complex(0,1)], [1,Complex(1,1)], [-1,Complex(-1,1)], [2,Complex(2,1)], [0.33, Complex(0.33,1)]]
    assert_in_out_pairs(poly, pairs)

    poly = Poly[BigDecimal('0'), BigDecimal('1.11')]
    pairs = [[0,BigDecimal('0')], [1,BigDecimal('1.11')], [-1,BigDecimal('-1.11')], [2,BigDecimal('2.22')], [BigDecimal('0.33'), BigDecimal('0.3663')]]
    assert_in_out_pairs(poly, pairs)
end
  
  def test_degree
    assert_equal 0, Poly[0].degree
    assert_equal 0, Poly[1].degree
    assert_equal 1, Poly[1,2].degree
    assert_equal 1, Poly[0,-1].degree
    assert_equal 2, Poly[1,0,1].degree
  end
  
  def test_multiplication
    assert_equal Poly[0], Poly[1] * 0
    assert_equal Poly[0], 0 * Poly[1]
    assert_equal Poly[1], Poly[1] * 1
    assert_equal Poly[1], 1 * Poly[1]
    assert_equal Poly[2], Poly[1] * 2
    assert_equal Poly[2], Poly[1] * Poly[2]
    assert_equal Poly[2,4,6], Poly[1,2,3] * 2
    assert_equal Poly[2,4,6], 2 * Poly[1,2,3]
    assert_equal Poly[0,0,1,2], Poly[0,1,2] * Poly[0,1]
  end
  
  def test_division_by_numeric
    assert_equal Poly[0], Poly[0] / 1
    assert_equal Poly[1], Poly[1] / 1
    assert_equal Poly[0.5], Poly[1] / 2
    assert_equal Poly[0.5], Poly[1] / 2.0
    assert_equal Poly[1,2,3], Poly[2,4,6] / 2
  end

  def test_divmod
    assert_equal [Poly[3], Poly[-8,-4]], Poly[1,2,3].divmod(Poly[3,2,1])
    assert_equal [Poly[0], Poly[1,2]], Poly[1,2].divmod(Poly[1,2,3])
    assert_equal [Poly[-27,-9,1], Poly[-123]], Poly[-42,0,-12,1].divmod(Poly[-3,1])
    assert_equal [Poly[4,6], Poly[2]], Poly[2,4,6].divmod(Poly[0,1])
    assert_equal [Poly[1,2,3], 0], Poly[2,4,6].divmod(2)
    assert_raise(ArgumentError) { Poly[1,2,3].divmod(:foo) }
    assert_raise(ArgumentError) { Poly[1,2,3].divmod(nil) }
  end

  def test_division_by_polynomial
    assert_equal Poly[2], Poly[2,4,6] / Poly[1,2,3]
    assert_equal Poly[0.5], Poly[1,2,3] / Poly[2,4,6]
    assert_equal Poly[3], Poly[1,2,3] / Poly[3,2,1]
    assert_equal Poly[1,2,3], Poly[2,4,6] / Poly[2]
  end

  @@quomod_data = [
    [Poly[1,2,3], Poly[3,2,1], Poly[3], Poly[-8,-4]],
    [Poly[1,2], Poly[1,2,3], Poly[0], Poly[1,2]],
    [Poly[-42,0,-12,1], Poly[-3,1], Poly[-27,-9,1], Poly[-123]],
    [Poly[1,3.quo(2)], 2, Poly[1.quo(2), 3.quo(4)], 0],
    [Poly[2,4,6], Poly[0,3], Poly[4.quo(3),6.quo(3)], Poly[2]],
    [Poly[1,3.quo(2)], Poly[2], Poly[1.quo(2), 3.quo(4)], 0],
    [Poly[2,4,6], 2, Poly[1,2,3], 0],
  ]
  def test_quomod
    @@quomod_data.each do |dividend, divisor, quotient, rest|
      assert_equal [quotient, rest], dividend.quomod(divisor)
    end
    assert_raise(ArgumentError) { Poly[1,2,3].quomod(:foo) }
    assert_raise(ArgumentError) { Poly[1,2,3].quomod(nil) }
  end

  def test_quo_by_numeric
    assert_equal Poly[1.quo(2), 3.quo(4)], Poly[1,3.quo(2)].quo(2)
    assert_equal Poly[1/2.0, 3.quo(2)/2.0], Poly[1,3.quo(2)].quo(2.0)
  end

  def test_quo_by_polynomial
    assert_equal Poly[4.quo(3),6.quo(3)], Poly[2,4,6].quo(Poly[0,3])
    assert_equal Poly[1.quo(2), 3.quo(4)], Poly[1,3.quo(2)].quo(2)
  end

  def test_remainder
    @@quomod_data.each do |dividend, divisor, quotient, rest|
      assert_equal rest, dividend % divisor
    end
  end

  @@power_data = [
    [Poly[1], 0, Poly[1]],
    [Poly[1], 1, Poly[1]],
    [Poly[1], 2, Poly[1]],
    [Poly[0,1], 1, Poly[0,1]],
    [Poly[0,1], 2, Poly[0,0,1]],
    [Poly[3,4], 2, Poly[9,24,16]],
  ]
  def test_power
    @@power_data.each do |polynomial, power, result|
      assert_equal result, polynomial**power
    end
    assert_raise(ArgumentError) { Poly[1,2,3]**(-1) }
    assert_raise(NoMethodError) { Poly[1,2,3]**(1.1) }
    # Exceptions raised in Ruby 1.8 and 1.9 are different for the following
    assert_raise(ArgumentError, NoMethodError) { Poly[1,2,3]**(:foo) }
  end

  def test_addition
    assert_equal Poly[1], Poly[1] + 0
    assert_equal Poly[2], Poly[1] + 1
    assert_equal Poly[1,1], Poly[1] + Poly[0,1]
    assert_equal Poly[2,3,4], Poly[2] + Poly[0,3,4]
  end
  
  def test_subtraction
    assert_equal Poly[1], Poly[1] - 0
    assert_equal Poly[0], Poly[1] - 1
    assert_equal Poly[1,-1], Poly[1] - Poly[0,1]
    assert_equal Poly[2,-3,-4], Poly[2] - Poly[0,3,4]
  end
  
  def test_to_s
    assert_equal "0", Poly[0].to_s
    assert_equal "1", Poly[1].to_s
    assert_equal "x", Poly[0,1].to_s
    assert_equal "1 + x", Poly[1,Complex(1,0)].to_s
    assert_equal "0 + x", Poly[0,1].to_s(:verbose=>true)
    assert_equal "1 - 2*x + 3*x**2", Poly[1,-2,3].to_s
    assert_equal "3*x**2 - 2*x + 1", Poly[1,-2,3].to_s(:decreasing=>true)
    assert_equal "1 + 0*x + 3*x**2", Poly[1,0,3].to_s(:verbose=>true)
    assert_equal "-1 - 3*x^2", Poly[-1,0,-3].to_s(:power_symbol=>'^')
    assert_equal "-1*y - 3*y**2", Poly[0,-1,-3].to_s(:variable_name=>'y')
    assert_equal "0+x", Poly[0,1].to_s(:verbose=>true, :spaced=>false)
    assert_equal "1-2*x+3*x**2", Poly[1,-2,3].to_s(:spaced=>false)
    assert_equal "1+0*x+3*x**2", Poly[1,0,3].to_s(:verbose=>true, :spaced=>false)
    assert_equal "-1-3*x^2", Poly[-1,0,-3].to_s(:power_symbol=>'^', :spaced=>false)

    # Complex#to_s results in Ruby 1.8 and 1.9 are different
    assert ["1 + (0 + 1i)*x", "1 + 1i*x"].include?(Poly[1,Complex(0,1)].to_s)
    
    assert_equal "1 + (1 + 1i)*x", Poly[1,Complex(1,1)].to_s
    assert_equal "1 + x", Poly[1,Complex(1,0)].to_s
    assert_equal "-3.33694235763727e-05", Poly[-3.33694235763727e-05].to_s
    assert_equal "1 + 3.33694235763727e-05*x", Poly[1,3.33694235763727e-05].to_s
    assert_equal "1 + (2/3)*x", Poly[1,2.quo(3)].to_s
    assert_equal "(-1/2) + (3/2)*x**2", Poly[-1.quo(2), 0, 3.quo(2)].to_s
  end

  def test_to_i
    assert_raise(ArgumentError) { Poly[1,2].to_i }
    assert_equal 0, Poly[0].to_i
    assert_equal 3, Poly[3].to_i
    assert_equal(-2, Poly[-2].to_i)
    assert_equal 3, Poly[3.3].to_i
  end
  
  def test_to_f
    assert_raise(ArgumentError) { Poly[1,2].to_f }
    assert_equal 0.0, Poly[0].to_f
    assert_equal 3.1, Poly[3.1].to_f
    assert_equal(-2.2, Poly[-2.2].to_f)
  end

  def test_integral
    assert_equal Poly[0], Poly[0].integral
    assert_equal Poly[0,1], Poly[1].integral
    assert_equal Poly[0,1], Poly[1].integral
    assert_equal Poly[0,1,1/2.0], Poly[1,1].integral
    assert_equal Poly[0,1,1/2.0,1/3.0], Poly[1,1,1].integral
  end

  def test_derivative
    assert_equal Poly[0], Poly[0].derivative
    assert_equal Poly[0], Poly[1].derivative
    assert_equal Poly[0], Poly[2].derivative
    assert_equal Poly[1], Poly[0,1].derivative
    assert_equal Poly[1,2], Poly[1,1,1].derivative
  end

  def test_derivatives
    z = Poly[0]
    assert_equal [z], z.derivatives
    assert_equal [Poly[1], z], Poly[0,1].derivatives
    assert_equal [Poly[2], z], Poly[1,2].derivatives
    assert_equal [Poly[4,10], Poly[10], z], Poly[3,4,5].derivatives
    assert_equal [Poly[2,6,12], Poly[6,24], Poly[24], z], Poly[1,2,3,4].derivatives
  end

  def test_integral_derivative_cascading
    coefs = Array.new(16) { rand }
    assert Poly[coefs].equal_in_delta Poly[coefs].integral.derivative, @@epsilon
    assert Poly[0, *coefs[1..-1]].equal_in_delta Poly[coefs].derivative.integral, @@epsilon
  end
  
  def test_equal_in_delta
    assert Poly[0].equal_in_delta(Poly[@@epsilon], @@epsilon)
    assert Poly[1].equal_in_delta(Poly[1-@@epsilon], @@epsilon)
    assert Poly[-@@epsilon,@@epsilon].equal_in_delta(Poly[@@epsilon, -@@epsilon], 2*@@epsilon)
  end
  
  def test_derivative_integral
    [ [0], [1], [0, 42], [1,11], [3,4,5] ].each do |coefs|
      poly = Poly.new(coefs)
      assert poly.equal_in_delta(poly.integral.derivative, @@epsilon)
    end
    1.upto(10) do |n|
      poly = Poly.new( Array.new(n) {|m| 2*m + rand } )
      assert poly.equal_in_delta(poly.integral.derivative, @@epsilon)
    end
  end

  def test_compare
    a = Poly[2]
    b = Poly[2,1]
    c = Poly[2,2]
    d = Poly[2,1,2]
    assert_equal [a,b,c,d], [d,b,c,a].sort
    assert_equal 0, Poly[0]
    assert_equal Poly[1], 1
    assert_equal Poly[0.5], 0.5
    assert_equal 0.5, Poly[0.5]
    assert_not_equal 1, Poly[1,2]
    assert_raise(TypeError) { Poly[1] <=> 'foo' }
  end

  def test_coerce
    assert_equal [Poly[2],Poly[1]], Poly[1].coerce(2)
    assert_equal [Poly[2],Poly[1]], Poly[1].coerce(Poly[2])
    assert_raise(TypeError) { Poly[1].coerce('foo') }
  end
  
  # HELPER FUNCTIONS
  
  def assert_in_out_pairs(polynomial, input_output_pairs, delta=@@epsilon)
    input_output_pairs.each do |x, y|
      assert_equal y, polynomial.substitute(x)
    end
  end
=end
  
end
