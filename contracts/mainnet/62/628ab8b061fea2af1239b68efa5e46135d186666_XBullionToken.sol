/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-30
*/

pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;





contract ERC20Interface {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _amount) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

    function decimals() public view returns (uint8);
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function totalSupply() public view returns (uint256);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract ERC20 is ERC20Interface {
    using SafeMath for uint256;

    string  internal tokenName;
    string  internal tokenSymbol;
    uint8   internal tokenDecimals;
    uint256 internal tokenTotalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply)
        internal
    {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        _mint(msg.sender, _totalSupply);
    }

    function approve(address _spender, uint256 _amount)
        public
        returns (bool success)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _delta)
        public
        returns (bool success)
    {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender].sub(_delta));
        return true;
    }

    function increaseAllowance(address _spender, uint256 _delta)
        public
        returns (bool success)
    {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender].add(_delta));
        return true;
    }

    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        public
        returns (bool success)
    {
        _transfer(_from, _to, _amount);
        _approve(_from, msg.sender, allowed[_from][msg.sender].sub(_amount));
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner)
        public
        view
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function decimals()
        public
        view
        returns (uint8)
    {
        return tokenDecimals;
    }

    function name()
        public
        view
        returns (string memory)
    {
        return tokenName;
    }

    function symbol()
        public
        view
        returns (string memory)
    {
        return tokenSymbol;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return tokenTotalSupply;
    }

    function _approve(address _owner, address _spender, uint256 _amount)
        internal
    {
        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _burn(address _from, uint256 _amount)
        internal
    {
        balances[_from] = balances[_from].sub(_amount);
        tokenTotalSupply = tokenTotalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
        emit Burn(_from, _amount);
    }

    function _mint(address _to, uint256 _amount)
        internal
    {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(_to != address(this), "ERC20: mint to token contract");

        tokenTotalSupply = tokenTotalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(address(0), _to, _amount);
        emit Mint(_to, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount)
        internal
    {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_to != address(this), "ERC20: transfer to token contract");

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
}

library AddressSet
{
    struct addrset
    {
        mapping(address => uint) index;
        address[] elements;
    }

    function insert(addrset storage self, address e)
        internal
        returns (bool success)
    {
        if (self.index[e] > 0) {
            return false;
        } else {
            self.index[e] = self.elements.push(e);
            return true;
        }
    }

    function remove(addrset storage self, address e)
        internal
        returns (bool success)
    {
        uint index = self.index[e];
        if (index == 0) {
            return false;
        } else {
            address e0 = self.elements[self.elements.length - 1];
            self.elements[index - 1] = e0;
            self.elements.pop();
            self.index[e0] = index;
            delete self.index[e];
            return true;
        }
    }

    function has(addrset storage self, address e)
        internal
        view
        returns (bool)
    {
        return self.index[e] > 0;
    }
}

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.
 */
library Math64x64 {
  /**
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /**
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m), uint256 (x) + uint256 (y) >> 1));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64, 0x10000000000000000));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << 127 - msb;
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= 63 - (x >> 64);
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 a = 192;
      uint256 b = 255;
      while (a < b) {
        uint256 m = a + b >> 1;
        uint256 t = x >> m;
        if (t == 0) b = m - 1;
        else if (t > 1) a = m + 1;
        else {
          a = m;
          break;
        }
      }

      result = (x << 255 - a) / ((y - 1 >> a - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      uint256 a = 0;
      uint256 b = 255;
      while (a < b) {
        uint256 m = a + b >> 1;
        uint256 t = x >> m;
        if (t == 0) b = m - 1;
        else if (t > 1) a = m + 1;
        else {
          a = m;
          break;
        }
      }

      int256 xe = int256 (a) - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
  }
}



contract OwnerRole {
    using AddressSet for AddressSet.addrset;

    AddressSet.addrset private owners;

    event OwnerAddition(address indexed addr);
    event OwnerRemoval(address indexed addr);

    modifier ifOwner(address _addr) {
        require(isOwner(_addr),
            "OwnerRole: specified account does not have the Owner role");
        _;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender),
            "OwnerRole: caller does not have the Owner role");
        _;
    }

    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners.elements;
    }

    function isOwner(address _addr)
        public
        view
        returns (bool)
    {
        return owners.has(_addr);
    }

    function numOwners()
        public
        view
        returns (uint)
    {
        return owners.elements.length;
    }

    function _addOwner(address _addr)
        internal
    {
        require(owners.insert(_addr),
            "OwnerRole: duplicate bearer");
        emit OwnerAddition(_addr);
    }

    function _removeOwner(address _addr)
        internal
    {
        require(owners.remove(_addr),
            "OwnerRole: not a bearer");
        emit OwnerRemoval(_addr);
    }
}

contract MultiOwned is OwnerRole {
    uint constant public MAX_OWNER_COUNT = 50;

    struct Transaction {
        bytes data;
        bool executed;
    }

    mapping(bytes32 => Transaction) public transactions;
    mapping(bytes32 => mapping(address => bool)) internal confirmations;
    uint public required;

    event Confirmation(address indexed sender, bytes32 indexed transactionId);
    event Revocation(address indexed sender, bytes32 indexed transactionId);
    event Submission(bytes32 indexed transactionId);
    event Execution(bytes32 indexed transactionId);
    event ExecutionFailure(bytes32 indexed transactionId);
    event Requirement(uint required);

    modifier confirmed(bytes32 _transactionId, address _owner) {
        require(confirmations[_transactionId][_owner]);
        _;
    }

    modifier notConfirmed(bytes32 _transactionId, address _owner) {
        require(!confirmations[_transactionId][_owner]);
        _;
    }

    modifier notExecuted(bytes32 _transactionId) {
        require(!transactions[_transactionId].executed);
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    modifier transactionExists(bytes32 _transactionId) {
        require(transactions[_transactionId].data.length != 0);
        _;
    }

    modifier validRequirement(uint _ownerCount, uint _required) {
        require(0 < _ownerCount
            && 0 < _required
            && _required <= _ownerCount
            && _ownerCount <= MAX_OWNER_COUNT);
        _;
    }

    constructor(address[] memory _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; ++i) {
            _addOwner(_owners[i]);
        }
        required = _required;
    }

    function addOwner(address _owner)
        public
        onlySelf
        validRequirement(numOwners() + 1, required)
    {
        _addOwner(_owner);
    }

    function addTransaction(bytes memory _data, uint _nonce)
        internal
        returns (bytes32 transactionId)
    {
        if (_nonce == 0) _nonce = block.number;
        transactionId = makeTransactionId(_data, _nonce);
        if (transactions[transactionId].data.length == 0) {
            transactions[transactionId] = Transaction({
                data: _data,
                executed: false
            });
            emit Submission(transactionId);
        }
    }

    function confirmTransaction(bytes32 _transactionId)
        public
        onlyOwner
        transactionExists(_transactionId)
        notConfirmed(_transactionId, msg.sender)
    {
        confirmations[_transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, _transactionId);
        executeTransaction(_transactionId);
    }

    function executeTransaction(bytes32 _transactionId)
        public
        onlyOwner
        confirmed(_transactionId, msg.sender)
        notExecuted(_transactionId)
    {
        if (isConfirmed(_transactionId)) {
            Transaction storage txn = transactions[_transactionId];
            txn.executed = true;
            (bool success,) = address(this).call(txn.data);
            if (success) {
                emit Execution(_transactionId);
            } else {
                emit ExecutionFailure(_transactionId);
                txn.executed = false;
            }
        }
    }

    function removeOwner(address _owner)
        public
        onlySelf
    {
        _removeOwner(_owner);
        if (required > numOwners()) {
            setRequirement(numOwners());
        }
    }

    function renounceOwner()
        public
        validRequirement(numOwners() - 1, required)
    {
        _removeOwner(msg.sender);
    }

    function replaceOwner(address _owner, address _newOwner)
        public
        onlySelf
    {
        _removeOwner(_owner);
        _addOwner(_newOwner);
    }

    function revokeConfirmation(bytes32 _transactionId)
        public
        onlyOwner
        confirmed(_transactionId, msg.sender)
        notExecuted(_transactionId)
    {
        confirmations[_transactionId][msg.sender] = false;
        emit Revocation(msg.sender, _transactionId);
    }

    function setRequirement(uint _required)
        public
        onlySelf
        validRequirement(numOwners(), _required)
    {
        required = _required;
        emit Requirement(_required);
    }

    function submitTransaction(bytes memory _data, uint _nonce)
        public
        returns (bytes32 transactionId)
    {
        transactionId = addTransaction(_data, _nonce);
        confirmTransaction(transactionId);
    }

    function getConfirmationCount(bytes32 _transactionId)
        public
        view
        returns (uint count)
    {
        address[] memory owners = getOwners();
        for (uint i = 0; i < numOwners(); ++i) {
            if (confirmations[_transactionId][owners[i]]) ++count;
        }
    }

    function getConfirmations(bytes32 _transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTmp = new address[](numOwners());
        uint count = 0;
        uint i;
        address[] memory owners = getOwners();
        for (i = 0; i < numOwners(); ++i) {
            if (confirmations[_transactionId][owners[i]]) {
                confirmationsTmp[count] = owners[i];
                ++count;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; ++i) {
            _confirmations[i] = confirmationsTmp[i];
        }
    }

    function isConfirmed(bytes32 _transactionId)
        public
        view
        returns (bool)
    {
        address[] memory owners = getOwners();
        uint count = 0;
        for (uint i = 0; i < numOwners(); ++i) {
            if (confirmations[_transactionId][owners[i]]) ++count;
            if (count == required) return true;
        }
    }

    function makeTransactionId(bytes memory _data, uint _nonce)
        public
        pure
        returns (bytes32 transactionId)
    {
        transactionId = keccak256(abi.encode(_data, _nonce));
    }
}


contract TrusteeRole {
    using AddressSet for AddressSet.addrset;

    AddressSet.addrset private trustees;

    event TrusteeAddition(address indexed addr);
    event TrusteeRemoval(address indexed addr);

    modifier ifTrustee(address _addr) {
        require(isTrustee(_addr),
            "TrusteeRole: specified account does not have the Trustee role");
        _;
    }

    modifier onlyTrustee() {
        require(isTrustee(msg.sender),
            "TrusteeRole: caller does not have the Trustee role");
        _;
    }

    function getTrustees()
        public
        view
        returns (address[] memory)
    {
        return trustees.elements;
    }

    function isTrustee(address _addr)
        public
        view
        returns (bool)
    {
        return trustees.has(_addr);
    }

    function numTrustees()
        public
        view
        returns (uint)
    {
        return trustees.elements.length;
    }

    function _addTrustee(address _addr)
        internal
    {
        require(trustees.insert(_addr),
            "TrusteeRole: duplicate bearer");
        emit TrusteeAddition(_addr);
    }

    function _removeTrustee(address _addr)
        internal
    {
        require(trustees.remove(_addr),
            "TrusteeRole: not a bearer");
        emit TrusteeRemoval(_addr);
    }
}

contract ERC20WithFees is MultiOwned, ERC20, TrusteeRole {
    using Math64x64 for int128;
    using SafeMath for uint256;
    using AddressSet for AddressSet.addrset;

    AddressSet.addrset internal holders;
    int128 txFee; // Transfer fee ratio; positive 64.64 fixed point number

    event TransferFeeChanged(int128 txFee);
    event TransferFeeCollected(address indexed addr, uint256 amount);

    constructor(int128 _txFee)
        public
    {
        _setTxFee(_txFee);
    }

    function addTrustee(address _addr)
        public
        onlySelf
    {
        _addTrustee(_addr);
    }

    function removeTrustee(address _addr)
        public
        onlySelf
    {
        _removeTrustee(_addr);
    }

    function setTxFee(int128 _txFee)
        public
        onlySelf
    {
        _setTxFee(_txFee);
    }

    function holderCount()
        public
        view
        returns (uint)
    {
        return holders.elements.length;
    }

    function _collectTxFee(address _from, uint256 _amount)
        internal
        returns (uint256 txFeeAmount)
    {
        if (isTrustee(_from)) {
            txFeeAmount = 0;
        } else {
            txFeeAmount = _computeTxFee(_amount);
        }
        if (txFeeAmount != 0) {
            balances[_from] = balances[_from].sub(txFeeAmount);
            tokenTotalSupply = tokenTotalSupply.sub(txFeeAmount);
            emit Transfer(_from, address(0), txFeeAmount);
            emit TransferFeeCollected(_from, txFeeAmount);
        }
    }

    function _setTxFee(int128 _txFee)
        internal
    {
        require(Math64x64.fromUInt(0) <= _txFee
            && _txFee <= Math64x64.fromUInt(1),
            "ERC20WithFees: invalid transfer fee value");
        txFee = _txFee;
        emit TransferFeeChanged(_txFee);
    }

    function _transfer(address _from, address _to, uint256 _amount)
        internal
    {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_to != address(this), "ERC20: transfer to token contract");

        // Execute transfer
        super._transfer(_from, _to, _amount);

        // Collect transfer fee
        _collectTxFee(_to, _amount);

        // Update set of holders
        if (balances[_from] == 0) holders.remove(_from);
        if (balances[_to] > 0) holders.insert(_to);
    }

    function _computeTxFee(uint256 _amount)
        internal
        view
        returns (uint)
    {
        return txFee.mulu(_amount);
    }
}


contract BurnerRole {
    using AddressSet for AddressSet.addrset;

    AddressSet.addrset private burners;

    event BurnerAddition(address indexed addr);
    event BurnerRemoval(address indexed addr);

    modifier ifBurner(address _addr) {
        require(isBurner(_addr),
            "BurnerRole: specified account does not have the Burner role");
        _;
    }

    modifier onlyBurner() {
        require(isBurner(msg.sender),
            "BurnerRole: caller does not have the Burner role");
        _;
    }

    function getBurners()
        public
        view
        returns (address[] memory)
    {
        return burners.elements;
    }

    function isBurner(address _addr)
        public
        view
        returns (bool)
    {
        return burners.has(_addr);
    }

    function numBurners()
        public
        view
        returns (uint)
    {
        return burners.elements.length;
    }

    function _addBurner(address _addr)
        internal
    {
        require(burners.insert(_addr),
            "BurnerRole: duplicate bearer");
        emit BurnerAddition(_addr);
    }

    function _removeBurner(address _addr)
        internal
    {
        require(burners.remove(_addr),
            "BurnerRole: not a bearer");
        emit BurnerRemoval(_addr);
    }
}

contract ERC20Burnable is ERC20WithFees, BurnerRole {
    function addBurner(address _addr)
        public
        onlySelf
    {
        _addBurner(_addr);
    }

    function burn(uint256 _amount)
        public
        onlyBurner
        returns (bool success)
    {
        _burn(msg.sender, _amount);
        return true;
    }

    function burnFrom(address _from, uint256 _amount)
        public
        ifBurner(_from)
        returns (bool success)
    {
        _burn(_from, _amount);
        _approve(_from, msg.sender, allowed[_from][msg.sender].sub(_amount));
        return true;
    }

    function removeBurner(address _addr)
        public
        onlySelf
    {
        _removeBurner(_addr);
    }

    function _burn(address _from, uint256 _amount)
        internal
    {
        balances[_from] = balances[_from].sub(_amount);
        if (balances[_from] == 0) holders.remove(_from);
        tokenTotalSupply = tokenTotalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
        emit Burn(_from, _amount);
    }
}



contract XBullionTokenConfig {
    using Math64x64 for int128;

    string internal constant TOKEN_SYMBOL = "SILV";
    string internal constant TOKEN_NAME = "XBullion Silver";
    uint8 internal constant TOKEN_DECIMALS = 8;

    uint256 private constant DECIMALS_FACTOR = 10**uint256(TOKEN_DECIMALS);
    uint256 internal constant TOKEN_INITIALSUPPLY = 0;

    uint256 internal constant TOKEN_MINTCAPACITY = 100 * DECIMALS_FACTOR;
    uint internal constant TOKEN_MINTPERIOD = 24 hours;

    function initialTxFee()
        internal
        pure
        returns (int128)
    {
        return txFeeFromBPs(19);
    }

    function makeAddressSingleton(address _addr)
        internal
        pure
        returns (address[] memory addrs)
    {
        addrs = new address[](1);
        addrs[0] = _addr;
    }

    function txFeeFromBPs(uint _bps)
        internal
        pure
        returns (int128)
    {
        return Math64x64.fromUInt(_bps)
            .div(Math64x64.fromUInt(10000));
    }
}


contract MinterRole {
    using AddressSet for AddressSet.addrset;

    AddressSet.addrset private minters;

    event MinterAddition(address indexed addr);
    event MinterRemoval(address indexed addr);

    modifier ifMinter(address _addr) {
        require(isMinter(_addr),
            "MinterRole: specified account does not have the Minter role");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender),
            "MinterRole: caller does not have the Minter role");
        _;
    }

    function getMinters()
        public
        view
        returns (address[] memory)
    {
        return minters.elements;
    }

    function isMinter(address _addr)
        public
        view
        returns (bool)
    {
        return minters.has(_addr);
    }

    function numMinters()
        public
        view
        returns (uint)
    {
        return minters.elements.length;
    }

    function _addMinter(address _addr)
        internal
    {
        require(minters.insert(_addr),
            "MinterRole: duplicate bearer");
        emit MinterAddition(_addr);
    }

    function _removeMinter(address _addr)
        internal
    {
        require(minters.remove(_addr),
            "MinterRole: not a bearer");
        emit MinterRemoval(_addr);
    }
}

contract ERC20Mintable is XBullionTokenConfig, ERC20WithFees, MinterRole {
    uint256 public mintCapacity;
    uint256 public amountMinted;
    uint public mintPeriod;
    uint public mintPeriodStart;

    event MintCapacity(uint256 amount);
    event MintPeriod(uint duration);

    constructor(uint256 _mintCapacity, uint _mintPeriod)
        public
    {
        _setMintCapacity(_mintCapacity);
        _setMintPeriod(_mintPeriod);
    }

    function addMinter(address _addr)
        public
        onlySelf
    {
        _addMinter(_addr);
    }

    function mint(address _to, uint256 _amount)
        public
    {
        if (msg.sender != address(this)) {
            require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
            require(isUnderMintLimit(_amount), "ERC20: exceeds minting capacity");
        }
        _mint(_to, _amount);
    }

    function removeMinter(address _addr)
        public
        onlySelf
    {
        _removeMinter(_addr);
    }

    function renounceMinter()
        public
        returns (bool)
    {
        _removeMinter(msg.sender);
        return true;
    }

    function setMintCapacity(uint256 _amount)
        public
        onlySelf
    {
        _setMintCapacity(_amount);
    }

    function setMintPeriod(uint _duration)
        public
        onlySelf
    {
        _setMintPeriod(_duration);
    }

    function _mint(address _to, uint256 _amount)
        internal
    {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(_to != address(this), "ERC20: mint to token contract");

        if (now > mintPeriodStart + mintPeriod) {
            amountMinted = 0;
            mintPeriodStart = now;
        }
        amountMinted = amountMinted.add(_amount);
        tokenTotalSupply = tokenTotalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        if (balances[_to] > 0) holders.insert(_to);

        emit Transfer(address(0), _to, _amount);
        emit Mint(_to, _amount);
    }

    function _setMintCapacity(uint256 _amount)
        internal
    {
        mintCapacity = _amount;
        emit MintCapacity(_amount);
    }

    function _setMintPeriod(uint _duration)
        internal
    {
        require(_duration < (1 << 64),
                "ERC20: mint period must be less than 2^64 seconds");
        mintPeriod = _duration;
        emit MintPeriod(_duration);
    }

    function isUnderMintLimit(uint256 _amount)
        internal
        view
        returns (bool)
    {
        uint256 effAmountMinted = (now > mintPeriodStart + mintPeriod) ? 0 : amountMinted;
        if (effAmountMinted + _amount > mintCapacity
            || effAmountMinted + _amount < effAmountMinted) {
            return false;
        }
        return true;
    }

    function remainingMintCapacity()
        public
        view
        returns (uint256)
    {
        if (now > mintPeriodStart + mintPeriod)
            return mintCapacity;
        if (mintCapacity < amountMinted)
            return 0;
        return mintCapacity - amountMinted;
    }
}

contract XBullionToken is XBullionTokenConfig, ERC20Burnable, ERC20Mintable {
    constructor()
        MultiOwned(
            makeAddressSingleton(msg.sender),
            1)
        ERC20(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOKEN_DECIMALS,
            TOKEN_INITIALSUPPLY)
        ERC20WithFees(
            initialTxFee())
        ERC20Mintable(
            TOKEN_MINTCAPACITY,
            TOKEN_MINTPERIOD)
        public
    {}
}