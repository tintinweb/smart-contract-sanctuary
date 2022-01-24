/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

pragma solidity 0.7.5;

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view override returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

pragma solidity 0.7.5;

interface IBondCalculator {

    function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
    
    function markdown( address pair_ ) external view returns ( uint );
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity 0.7.5;

// ICOWERC20
interface ICOW20 {
    
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);
    
    function burnFrom(address account_, uint256 amount_) external;
}

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.7.5;

interface IsCOW {
    function rebase( uint256 COWProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function gonsForBalance( uint amount ,address who) external view returns ( uint );

    function balanceForGons( uint gons ,address who) external view returns ( uint );
}

pragma solidity 0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

pragma solidity 0.7.5;

library FixedPoint {
   

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}

pragma solidity ^0.7.0;

library ABDKMath64x64 {
  
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
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
    }
}

pragma solidity 0.7.5;

library SafeMathForOneDecimals {
    
    uint private constant BASE = 10 ** 27;

    function rpow(uint x, uint n) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := BASE} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := BASE } default { z := x }
                let half := div(BASE, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, BASE)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, BASE)
                }
            }
            }
        }
    }
}

pragma solidity 0.7.5;

interface IStaking {
    function epoch() external view returns (uint length, uint number, uint endBlock,uint distribute);
    function totalStaked() external view returns ( uint );
}

interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}

interface ICirculatingCOW {
    function COWCirculatingSupply() external view returns ( uint );
}

interface IBond {
    function currentDebt() external view returns ( uint );
    function totlPayout() external view returns ( uint );
}

contract CowBondPrice is Ownable {
    using FixedPoint for *;
    using SafeMath for uint;
    // bonds
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private bondDepoitories;

     // tokens
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private tokens;
    // getCaculator With TokenAddress
    mapping( address => address ) private tokenCalculator; // stores calculator address for pair

    // default for 1
    uint256 private constant DEFAULT_1 = 1000000000;

    address public immutable COW; // calculate balacnOf token in treasury
    address public immutable sCOW; // calculate balacnOf token in treasury
    address public immutable cowPair; // for calculate bondPrice
    address public immutable treasury; // calculate balacnOf token in treasury
    address public immutable staking; // staking for rewards
    uint public validBlock;                  //  Block 
    uint public calLength;
    uint public lastStaked;
    uint public lastBondPayout;
    uint public lastNStaked;
    uint public lastNPayout;
    uint256 public currentBondPrice;

    constructor (address _cow,address _sCOW, address _staking, address _cowPair, address _treasury, uint _calLength) {
        require( _cow != address(0) );
        COW = _cow;
        require( _sCOW != address(0) );
        sCOW = _sCOW;
        require( _staking != address(0) );
        staking = _staking;
        require( _cowPair != address(0) );
        cowPair = _cowPair;
        require( _treasury != address(0) );
        treasury = _treasury;
        require(_calLength > 20);               // longer than one minutes
        calLength = _calLength;
        lastNStaked = 0;
        lastNPayout = 0;
    }
    //
    function calculateBondPrice() external {
        uint circlatingValue = IsCOW(sCOW).circulatingSupply();
        uint cowPrice = this.getCowPrice();
        uint minBondPirce = cowPrice.mul(750000000).div(1e9);           //

        if(EnumerableSet.length(bondDepoitories) == 0){
            currentBondPrice = minBondPirce;
            return;
        }
        // step1
        uint fiveDaysRebase = getFiveDaysRebase(circlatingValue);
        // step2
        uint takeRatio = getStakeRatio();
        // step3 
        uint256 pirce = _calculateBondPrice(fiveDaysRebase,takeRatio,cowPrice);
        currentBondPrice = pirce;
    }
    // 
    function _calculateBondPrice(uint _fiveDaysRebase,uint _stakeRatio,uint _cowPrice) internal view returns(uint256){
        uint minBondPirce = _cowPrice.mul(750000000).div(1e9);           //0.75 
        //step4
        uint rebase = DEFAULT_1+_fiveDaysRebase;
        rebase = rebase.mul(225).div(100);

        uint debtValue = _stakeRatio.add(2000000000);           // +2
        uint value = FixedPoint.fraction(debtValue,rebase).decode112with18().div(1e9);
        uint bondPrice = _cowPrice.mul(value).div(1e9);
        if(bondPrice<minBondPirce){
            bondPrice = minBondPirce;
        }else if(bondPrice >= _cowPrice){
            bondPrice = _cowPrice;
        }

        if(bondPrice < DEFAULT_1){
            bondPrice = DEFAULT_1;
        }

        return bondPrice;
    }

    function getFiveDaysRebase(uint _scowCirclatingValue) internal view returns (uint){
        uint256 epochRebase = getEpochRebase(_scowCirclatingValue);
        uint256 rebase_ = SafeMathForOneDecimals.rpow(epochRebase.mul(1e18),15);
        rebase_ = rebase_.div(1e18)-DEFAULT_1;                                    
        return rebase_;
    }

    function getEpochRebase(uint _scowCirclatingValue) internal view returns(uint rebase_){
        uint256 nextReward = getNextReward();
        uint256 nextEpochRebase;
        if(_scowCirclatingValue != 0){
            nextEpochRebase = FixedPoint.fraction(
                nextReward,
                _scowCirclatingValue
            ).decode112with18().div(1e9);
        }
        if(nextEpochRebase >= 12696833){
            nextEpochRebase = 12696833;            // 1000k
        }else if(nextEpochRebase == 0){
            nextEpochRebase = 2943800;              // 2.5k
        }
        uint256 epochRebase = DEFAULT_1+nextEpochRebase;
        return epochRebase;
    }

    function getNextReward() internal view returns(uint rewards_){
        (,,,uint distribute) = IStaking(staking).epoch();
        uint singleRewards = distribute;
        rewards_ = rewards_.add(singleRewards);
    }

    function getCowPrice() public view returns(uint price_){
        address token0 = IUniswapV2Pair( cowPair ).token0();
        address token1 = IUniswapV2Pair( cowPair ).token1();
        uint256 token0Balance = ICOW20(token0).balanceOf(cowPair);
        uint256 token1Balance = ICOW20(token1).balanceOf(cowPair);
        if(token0 == COW){
            token0Balance = token0Balance.mul(1e9);
            price_ = FixedPoint.fraction(      
                            token1Balance,
                            token0Balance
                        ).decode112with18().div(1e9);
        }else{
            token1Balance = token1Balance.mul(1e9);
            price_ = FixedPoint.fraction(      
                            token0Balance,
                            token1Balance
                        ).decode112with18().div(1e9);
        }
    }
    
    function getStakeRatio() internal returns(uint) {
        uint allStaked = 0;
        uint allPayout = 0;
        if(block.number >= validBlock){
            require(validBlock > 0,"invalid value for validBlock");
            validBlock = block.number.add(calLength);
            //getTotalState
            allStaked = IStaking(staking).totalStaked();
            // calculated ALL Bond Payout
            uint length = EnumerableSet.length(bondDepoitories);
            for( uint index = 0; index < length; index++ ) {
                
                address bond = EnumerableSet.at(bondDepoitories, index);
                uint payout = IBond(bond).totlPayout();
                allPayout = allPayout.add(payout);
            }

            lastNStaked = allStaked>=lastStaked?allStaked.sub(lastStaked):lastNStaked;
            lastNPayout = allPayout>=lastBondPayout?allPayout.sub(lastBondPayout):lastNPayout;

            lastStaked = allStaked;
            lastBondPayout = allPayout;
            
        }
       
        
        uint ratio = 350000000;
        if(lastNStaked > 0){
            ratio = FixedPoint.fraction(      
                            lastNPayout,
                            lastNStaked
                        ).decode112with18().div(1e9);

            
        }
        
        return ratio;
    }

    function cacluateRunTime() public view returns(uint256){
        uint _scowCirclatingValue = IsCOW(sCOW).circulatingSupply();
        uint freeRiskValue = calculateFreeRiskValue();
        uint256 treasury_runway = 200000000000;     // defalut 200days
        if(_scowCirclatingValue > 0){
            treasury_runway = FixedPoint.fraction(
                                freeRiskValue,
                                _scowCirclatingValue
                            ).decode112with18().div(1e9);
                            
        }else{
            return treasury_runway;
        }
        // 
        uint256 epochRebase = getEpochRebase(_scowCirclatingValue);
        int128 defalutLog = ABDKMath64x64.log_2(ABDKMath64x64.fromUInt(DEFAULT_1));
        int128 logTreasury = ABDKMath64x64.log_2(ABDKMath64x64.fromUInt(treasury_runway));
        int128 logRewardRebase = ABDKMath64x64.log_2(ABDKMath64x64.fromUInt(epochRebase));   // 
        // step1 for div
        uint256 runwayCurrent_num = FixedPoint.fraction(
            uint256(logTreasury-defalutLog),
            uint256(logRewardRebase-defalutLog)
        ).decode112with18().div(1e9);
        // step2 for div
        runwayCurrent_num = FixedPoint.fraction(      // 
            runwayCurrent_num,
            3000000000
        ).decode112with18().div(1e9);
        return runwayCurrent_num;
    }

    function calculateFreeRiskValue() public view returns(uint){
        uint length = EnumerableSet.length(tokens);
        uint frv_ = 0;
        for( uint index = 0; index < length; index++ ) {
            address token = EnumerableSet.at(tokens, index);
            if (token != address(0) ) {
                uint freeRiskValue = 0;
                uint tokenBalace = ICOW20(token).balanceOf(treasury);
                if(tokenCalculator[token] != address(0)){
                    address calculator = tokenCalculator[token];
                    freeRiskValue = IBondCalculator(calculator).valuation(token,tokenBalace);
                }else {
                    freeRiskValue = tokenBalace.mul(10 ** ICOW20(sCOW ).decimals() ).div(10 ** ICOW20(token).decimals());
                }
                //                //
                frv_ = frv_.add(freeRiskValue);
            }
        }
        return frv_;
    }

    function addBondDepo(address _addBond) public onlyOwner returns (bool) {
        require(_addBond != address(0), "Bond: _addBond is the zero address");
        EnumerableSet.add(bondDepoitories, _addBond);
        return true;
    }

    function delBondDepo(address _delBond) public onlyOwner returns (bool) {
        require(_delBond != address(0), "Bond: _delBond is the zero address");
        return EnumerableSet.remove(bondDepoitories, _delBond);
    }

    function resetStakeLpBasicData() public onlyOwner {
        validBlock = block.number.add(calLength);
        uint allPayout = 0;
        //getTotalState
        lastStaked = IStaking(staking).totalStaked();
        // calculated ALL Bond Payout
        uint length = EnumerableSet.length(bondDepoitories);
        for( uint index = 0; index < length; index++ ) {
            address bond = EnumerableSet.at(bondDepoitories, index);
            uint payout = IBond(bond).totlPayout();
            allPayout = allPayout.add(payout);
        }
        lastNPayout = allPayout;
    }

    function addToken(address _addToken,address _cal,bool _isPair) public onlyOwner returns (bool) {
        require(_addToken != address(0), "Token: _addToken is the zero address");
        if(_isPair){
            require(_cal != address(0), "Recipient: _cal is the zero address");
            tokenCalculator[_addToken] = _cal;
        }
        return EnumerableSet.add(tokens, _addToken);
    }

    function delToken(address _delToken,bool _isPair) public onlyOwner returns (bool) {
        require(_delToken != address(0), "Token: _delToken is the zero address");
         if(_isPair){
            tokenCalculator[_delToken] = address(0);
        }
        return EnumerableSet.remove(tokens, _delToken);
    }
}