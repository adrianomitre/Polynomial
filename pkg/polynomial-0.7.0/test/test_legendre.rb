require File.dirname(__FILE__) + '/test_helper.rb'

require 'polynomial/legendre'

class TestLegendre < Test::Unit::TestCase

  @@epsilon = 1e-12

  @@in_out = {
    0=>[1],
    1=>[0, 1],
    2=>[Rational(-1, 2), Rational(0, 1), Rational(3, 2)],
    3=>[Rational(0, 1), Rational(-3, 2), Rational(0, 1), Rational(5, 2)],
    4=>[Rational(3, 8), Rational(0, 1), Rational(-15, 4), Rational(0, 1), Rational(35, 8)],
    5=>[Rational(0, 1), Rational(15, 8), Rational(0, 1), Rational(-35, 4), Rational(0, 1), Rational(63, 8)],
    6=>[Rational(-5, 16), Rational(0, 1), Rational(105, 16), Rational(0, 1), Rational(-315, 16), Rational(0, 1), Rational(231, 16)],
    7=>[Rational(0, 1), Rational(-35, 16), Rational(0, 1), Rational(315, 16), Rational(0, 1), Rational(-693, 16), Rational(0, 1), Rational(429, 16)],
    8=>[Rational(35, 128), Rational(0, 1), Rational(-315, 32), Rational(0, 1), Rational(3465, 64), Rational(0, 1), Rational(-3003, 32), Rational(0, 1), Rational(6435, 128)],
    9=>[Rational(0, 1), Rational(315, 128), Rational(0, 1), Rational(-1155, 32), Rational(0, 1), Rational(9009, 64), Rational(0, 1), Rational(-6435, 32), Rational(0, 1), Rational(12155, 128)],
    10=>[Rational(-63, 256), Rational(0, 1), Rational(3465, 256), Rational(0, 1), Rational(-15015, 128), Rational(0, 1), Rational(45045, 128), Rational(0, 1), Rational(-109395, 256), Rational(0, 1), Rational(46189, 256)]
  }

  def test_invalid_degree
    assert_raise(RangeError) { Polynomial::Legendre.uncached_legendre(-1) }
    assert_raise(RangeError) { Polynomial::Legendre.cached_legendre(-1) }
  end

  def my_test_in_out_rand(in_out_hash, method_name)
    keys, size = in_out_hash.keys, in_out_hash.size
    100.times do
      degree = keys[rand(size)]
      coefs = in_out_hash[degree]
      assert_equal Polynomial[*coefs], Polynomial::Legendre.send(method_name, degree)
    end
  end
  
  def my_test_in_out_seq(in_out_hash, method_name)
    in_out_hash.each_pair do |degree, coefs|
      assert_equal Polynomial[*coefs], Polynomial::Legendre.send(method_name, degree)
    end
  end
  
  def test_cached
    my_test_in_out_rand(@@in_out, :cached_legendre)
    my_test_in_out_seq(@@in_out, :cached_legendre)
  end
  
  def test_uncached
    my_test_in_out_rand(@@in_out, :uncached_legendre)
    my_test_in_out_seq(@@in_out, :uncached_legendre)
  end
    
end
