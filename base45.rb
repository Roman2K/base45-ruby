module Base45
  CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
  private_constant :CHARSET

  def self.encode(s)
    s.each_byte.each_slice(2).flat_map { |a,b|
      if b
        x = (a << 8) + b
        e, x = x.divmod(CHARSET.size ** 2)
        d, c = x.divmod CHARSET.size
        [c, d, e]
      else
        d, c = a.divmod CHARSET.size
        [c, d]
      end
    }.map { CHARSET.getbyte _1 or raise }.pack("C*")
  end

  class Error < StandardError; end
  class InvalidLengthError < Error; end
  class IllegalCharError < Error; end
  class OverflowError < Error; end

  def self.decode(s)
    s.upcase.each_char.map { |c|
      CHARSET.index c or raise IllegalCharError, c.inspect
    }.each_slice(3).flat_map { |c,d,e|
      c && d or raise InvalidLengthError
      v = c + d * CHARSET.size
      if e
        v += e * (CHARSET.size ** 2)
        x, y = v.divmod 256
        x < 256 or raise OverflowError
        [x, y]
      else
        [v]
      end
    }.pack("C*")
  end
end

if $0 == __FILE__

require 'minitest/autorun'
require 'base64'

class Base45Test < Minitest::Test
  TESTS = [
    ["AB", "BB8"],
    ["", ""],
    ["Hello!!", "%69 VD92EX0"],
    ["base-45", "UJCLQE7W581"],
    ["The quick brown fox jumps over the lazy dog",
     "8UADZCKFEOEDJOD2KC54EM-DX.CH8FSKDQ$D.OE44E5$CS44+8DK44OEC3EFGVCD2"],
    [Base64.decode64("Zm9vIMKpIGJhciDwnYyGIGJheg=="), # "foo (c) bar [] baz"
     "X.C82EIROA44GECH74C-J1/GUJCW2"],
    [Base64.decode64("SSDinaTvuI8gIFJ1c3Q="), # "I <3 Rust"
     "0B98TSD%K.ENY244JA QE"],
    ["ietf!", "QED8WEX0"],
    [[72, 101, 108, 108, 111, 33, 33].pack("C*"),
     "%69 VD92EX0"],
  ]

  def test_encode
    TESTS.each do |clear, enc|
      assert_equal norm(enc), norm(Base45.encode(clear)),
        "#{clear.inspect} expected to be encoded as #{enc.inspect}"
    end
  end

  private def norm(s) = s.dup.force_encoding(Encoding::UTF_8)

  def test_decode
    TESTS.each do |clear, enc|
      assert_equal norm(clear), norm(Base45.decode(enc)),
        "#{enc.inspect} expected to be decoded as #{clear.inspect}"
    end

    assert_equal "base-45", Base45.decode("UjClqe7w581")
    assert_raises Base45::OverflowError do
      Base45.decode ":::"
    end
    assert_raises Base45::IllegalCharError do
      Base45.decode "!^&"
    end
    assert_raises Base45::InvalidLengthError do
      Base45.decode "AAAA"
    end
    assert_raises Base45::OverflowError do
      Base45.decode "ZZZZ"
    end
  end
end

end
