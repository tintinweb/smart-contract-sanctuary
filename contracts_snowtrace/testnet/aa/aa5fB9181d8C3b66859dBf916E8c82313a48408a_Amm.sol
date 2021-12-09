/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-07
*/

// File: src/utils/BlockContext.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// File: src/interface/IPriceFeed.sol


interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(bytes32 _priceFeedKey) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);

    function setLatestData(
        bytes32 _priceFeedKey,
        uint256 _price,
        uint256 _timestamp,
        uint256 _roundId
    ) external;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: src/utils/DecimalMath.sol



/// @dev Implements simple fixed point math add, sub, mul and div operations.
/// @author Alberto Cuesta Cañada
library DecimalMath {
    using SafeMath for uint256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(unit(decimals)).div(y);
    }
}

// File: src/utils/Decimal.sol




library Decimal {
    using DecimalMath for uint256;
    using SafeMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal(x.d.mul(DecimalMath.unit(18)) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SignedSafeMath.sol


/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: src/utils/SignedDecimalMath.sol



/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    using SignedSafeMath for int256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(int256 x, int256 y) internal pure returns (int256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(int256 x, int256 y) internal pure returns (int256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(int256 x, int256 y) internal pure returns (int256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(int256 x, int256 y) internal pure returns (int256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return x.mul(unit(decimals)).div(y);
    }
}

// File: src/utils/SignedDecimal.sol





library SignedDecimal {
    using SignedDecimalMath for int256;
    using SignedSafeMath for int256;

    struct signedDecimal {
        int256 d;
    }

    function zero() internal pure returns (signedDecimal memory) {
        return signedDecimal(0);
    }

    function toInt(signedDecimal memory x) internal pure returns (int256) {
        return x.d;
    }

    function isNegative(signedDecimal memory x) internal pure returns (bool) {
        if (x.d < 0) {
            return true;
        }
        return false;
    }

    function abs(signedDecimal memory x) internal pure returns (Decimal.decimal memory) {
        Decimal.decimal memory t;
        if (x.d < 0) {
            t.d = uint256(0 - x.d);
        } else {
            t.d = uint256(x.d);
        }
        return t;
    }

    /// @dev add two decimals
    function addD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a signedDecimal by a int256
    function mulScalar(signedDecimal memory x, int256 y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a signedDecimal by a int256
    function divScalar(signedDecimal memory x, int256 y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// File: src/utils/MixedDecimal.sol





/// @dev To handle a signedDecimal add/sub/mul/div a decimal and provide convert decimal to signedDecimal helper
library MixedDecimal {
    using SignedDecimal for SignedDecimal.signedDecimal;
    using SignedSafeMath for int256;

    uint256 private constant _INT256_MAX = 2**255 - 1;
    string private constant ERROR_NON_CONVERTIBLE = "MixedDecimal: uint value is bigger than _INT256_MAX";

    modifier convertible(Decimal.decimal memory x) {
        require(_INT256_MAX >= x.d, ERROR_NON_CONVERTIBLE);
        _;
    }

    function fromDecimal(Decimal.decimal memory x)
        internal
        pure
        convertible(x)
        returns (SignedDecimal.signedDecimal memory)
    {
        return SignedDecimal.signedDecimal(int256(x.d));
    }

    function toUint(SignedDecimal.signedDecimal memory x) internal pure returns (uint256) {
        return x.abs().d;
    }

    /// @dev add SignedDecimal.signedDecimal and Decimal.decimal, using SignedSafeMath directly
    function addD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d.add(int256(y.d));
        return t;
    }

    /// @dev subtract SignedDecimal.signedDecimal by Decimal.decimal, using SignedSafeMath directly
    function subD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d.sub(int256(y.d));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by Decimal.decimal
    function mulD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.mulD(fromDecimal(y));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by a uint256
    function mulScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.mulScalar(int256(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a Decimal.decimal
    function divD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.divD(fromDecimal(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a uint256
    function divScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.divScalar(int256(y));
        return t;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol



/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: src/utils/PerpFiOwnableUpgrade.sol



// copy from openzeppelin Ownable, only modify how the owner transfer
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract PerpFiOwnableUpgrade is ContextUpgradeSafe {
    address private _owner;
    address private _candidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function candidate() public view returns (address) {
        return _candidate;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "PerpFiOwnableUpgrade: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "PerpFiOwnableUpgrade: zero address");
        require(newOwner != _owner, "PerpFiOwnableUpgrade: same as original");
        require(newOwner != _candidate, "PerpFiOwnableUpgrade: same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "PerpFiOwnableUpgrade: candidate is zero address");
        require(_candidate == _msgSender(), "PerpFiOwnableUpgrade: not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

    uint256[50] private __gap;
}

// File: src/interface/IAmm.sol

pragma experimental ABIEncoderV2;




interface IAmm {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir { ADD_TO_AMM, REMOVE_FROM_AMM }

    struct LiquidityChangedSnapshot {
        SignedDecimal.signedDecimal cumulativeNotional;
        // the base/quote reserve of amm right before liquidity changed
        Decimal.decimal quoteAssetReserve;
        Decimal.decimal baseAssetReserve;
        // total position size owned by amm after last snapshot taken
        // `totalPositionSize` = currentBaseAssetReserve - lastLiquidityChangedHistoryItem.baseAssetReserve + prevTotalPositionSize
        SignedDecimal.signedDecimal totalPositionSize;
    }

    function swapInput(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        Dir _dir,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit,
        bool _skipFluctuationCheck
    ) external returns (Decimal.decimal memory);

    function migrateLiquidity(Decimal.decimal calldata _liquidityMultiplier, Decimal.decimal calldata _priceLimitRatio)
        external;

    function shutdown() external;

    function settleFunding() external returns (SignedDecimal.signedDecimal memory);

    function calcFee(Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory, Decimal.decimal memory);

    //
    // VIEW
    //

    function calcBaseAssetAfterLiquidityMigration(
        SignedDecimal.signedDecimal memory _baseAssetAmount,
        Decimal.decimal memory _fromQuoteReserve,
        Decimal.decimal memory _fromBaseReserve
    ) external view returns (SignedDecimal.signedDecimal memory);

    function getInputTwap(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputTwap(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPrice(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputPrice(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external pure returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external pure returns (Decimal.decimal memory);

    function getSpotPrice() external view returns (Decimal.decimal memory);

    function getLiquidityHistoryLength() external view returns (uint256);

    // overridden by state variable
    function quoteAsset() external view returns (IERC20);

    function open() external view returns (bool);

    // can not be overridden by state variable due to type `Deciaml.decimal`
    function getSettlementPrice() external view returns (Decimal.decimal memory);

    function getBaseAssetDeltaThisFundingPeriod() external view returns (SignedDecimal.signedDecimal memory);

    function getCumulativeNotional() external view returns (SignedDecimal.signedDecimal memory);

    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function getLiquidityChangedSnapshots(uint256 i) external view returns (LiquidityChangedSnapshot memory);
}

// File: src/Amm.sol











contract Amm is IAmm, PerpFiOwnableUpgrade, BlockContext {
    using SafeMath for uint256;
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;

    //
    // CONSTANT
    //
    // because position decimal rounding error,
    // if the position size is less than IGNORABLE_DIGIT_FOR_SHUTDOWN, it's equal size is 0
    uint256 private constant IGNORABLE_DIGIT_FOR_SHUTDOWN = 100;

    // a margin to prevent from rounding when calc liquidity multiplier limit
    uint256 private constant MARGIN_FOR_LIQUIDITY_MIGRATION_ROUNDING = 1e9;

    //
    // EVENTS
    //
    event SwapInput(Dir dir, uint256 quoteAssetAmount, uint256 baseAssetAmount);
    event SwapOutput(Dir dir, uint256 quoteAssetAmount, uint256 baseAssetAmount);
    event FundingRateUpdated(int256 rate, uint256 underlyingPrice);
    event ReserveSnapshotted(uint256 quoteAssetReserve, uint256 baseAssetReserve, uint256 timestamp);
    event LiquidityChanged(uint256 quoteReserve, uint256 baseReserve, int256 cumulativeNotional);
    event CapChanged(uint256 maxHoldingBaseAsset, uint256 openInterestNotionalCap);
    event Shutdown(uint256 settlementPrice);

    //
    // MODIFIERS
    //
    modifier onlyOpen() {
        require(open, "amm was closed");
        _;
    }

    modifier onlyCounterParty() {
        require(counterParty == _msgSender(), "caller is not counterParty");
        _;
    }

    //
    // enum and struct
    //
    struct ReserveSnapshot {
        Decimal.decimal quoteAssetReserve;
        Decimal.decimal baseAssetReserve;
        uint256 timestamp;
        uint256 blockNumber;
    }

    // internal usage
    enum QuoteAssetDir { QUOTE_IN, QUOTE_OUT }
    // internal usage
    enum TwapCalcOption { RESERVE_ASSET, INPUT_ASSET }

    // To record current base/quote asset to calculate TWAP

    struct TwapInputAsset {
        Dir dir;
        Decimal.decimal assetAmount;
        QuoteAssetDir inOrOut;
    }

    struct TwapPriceCalcParams {
        TwapCalcOption opt;
        uint256 snapshotIndex;
        TwapInputAsset asset;
    }

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//

    // update during every swap and calculate total amm pnl per funding period
    SignedDecimal.signedDecimal private baseAssetDeltaThisFundingPeriod;

    // update during every swap and used when shutting amm down
    SignedDecimal.signedDecimal public totalPositionSize;

    // latest funding rate = ((twap market price - twap oracle price) / twap oracle price) / 24
    SignedDecimal.signedDecimal public fundingRate;

    SignedDecimal.signedDecimal private cumulativeNotional;

    Decimal.decimal private settlementPrice;
    Decimal.decimal public tradeLimitRatio;
    Decimal.decimal public quoteAssetReserve;
    Decimal.decimal public baseAssetReserve;
    Decimal.decimal public fluctuationLimitRatio;

    // owner can update
    Decimal.decimal public tollRatio;
    Decimal.decimal public spreadRatio;
    Decimal.decimal public tollAmount;
    Decimal.decimal private maxHoldingBaseAsset;
    Decimal.decimal private openInterestNotionalCap;

    // init cumulativePositionMultiplier is 1, will be updated every time when amm reserve increase/decrease
    Decimal.decimal private cumulativePositionMultiplier;

    // snapshot of amm reserve when change liquidity's invariant
    LiquidityChangedSnapshot[] private liquidityChangedSnapshots;

    uint256 public spotPriceTwapInterval;
    uint256 public fundingPeriod;
    uint256 public fundingBufferPeriod;
    uint256 public nextFundingTime;
    bytes32 public priceFeedKey;
    ReserveSnapshot[] public reserveSnapshots;

    address private counterParty;
    address public globalShutdown;
    IERC20 public override quoteAsset;
    IPriceFeed public priceFeed;
    bool public override open;
    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //
    function initialize(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        uint256 _tradeLimitRatio,
        uint256 _fundingPeriod,
        IPriceFeed _priceFeed,
        bytes32 _priceFeedKey,
        address _quoteAsset,
        uint256 _fluctuationLimitRatio,
        uint256 _tollRatio,
        uint256 _spreadRatio
    ) public initializer {
        require(
            _quoteAssetReserve != 0 &&
                _tradeLimitRatio != 0 &&
                _baseAssetReserve != 0 &&
                _fundingPeriod != 0 &&
                address(_priceFeed) != address(0) &&
                _quoteAsset != address(0),
            "invalid input"
        );
        __Ownable_init();

        quoteAssetReserve = Decimal.decimal(_quoteAssetReserve);
        baseAssetReserve = Decimal.decimal(_baseAssetReserve);
        tradeLimitRatio = Decimal.decimal(_tradeLimitRatio);
        tollRatio = Decimal.decimal(_tollRatio);
        spreadRatio = Decimal.decimal(_spreadRatio);
        fluctuationLimitRatio = Decimal.decimal(_fluctuationLimitRatio);
        fundingPeriod = _fundingPeriod;
        fundingBufferPeriod = _fundingPeriod.div(2);
        spotPriceTwapInterval = 1 hours;
        priceFeedKey = _priceFeedKey;
        quoteAsset = IERC20(_quoteAsset);
        priceFeed = _priceFeed;
        cumulativePositionMultiplier = Decimal.one();
        liquidityChangedSnapshots.push(
            LiquidityChangedSnapshot({
                cumulativeNotional: SignedDecimal.zero(),
                baseAssetReserve: baseAssetReserve,
                quoteAssetReserve: quoteAssetReserve,
                totalPositionSize: SignedDecimal.zero()
            })
        );
        reserveSnapshots.push(ReserveSnapshot(quoteAssetReserve, baseAssetReserve, _blockTimestamp(), _blockNumber()));
        emit ReserveSnapshotted(quoteAssetReserve.toUint(), baseAssetReserve.toUint(), _blockTimestamp());
    }

    /**
     * @notice Swap your quote asset to base asset, the impact of the price MUST be less than `fluctuationLimitRatio`
     * @dev Only clearingHouse can call this function
     * @param _dir ADD_TO_AMM for long, REMOVE_FROM_AMM for short
     * @param _quoteAssetAmount quote asset amount
     * @param _baseAssetAmountLimit minimum base asset amount expected to get to prevent front running
     * @return base asset amount
     */
    function swapInput(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit
    ) external override onlyOpen onlyCounterParty returns (Decimal.decimal memory) {
        if (_quoteAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }
        if (_dir == Dir.REMOVE_FROM_AMM) {
            require(
                quoteAssetReserve.mulD(tradeLimitRatio).toUint() >= _quoteAssetAmount.toUint(),
                "over trading limit"
            );
        }

        Decimal.decimal memory baseAssetAmount = getInputPrice(_dir, _quoteAssetAmount);
        // If LONG, exchanged base amount should be more than _baseAssetAmountLimit,
        // otherwise(SHORT), exchanged base amount should be less than _baseAssetAmountLimit.
        // In SHORT case, more position means more debt so should not be larger than _baseAssetAmountLimit
        if (_baseAssetAmountLimit.toUint() != 0) {
            if (_dir == Dir.ADD_TO_AMM) {
                require(baseAssetAmount.toUint() >= _baseAssetAmountLimit.toUint(), "Less than minimal base token");
            } else {
                require(baseAssetAmount.toUint() <= _baseAssetAmountLimit.toUint(), "More than maximal base token");
            }
        }

        updateReserve(_dir, _quoteAssetAmount, baseAssetAmount, false);
        emit SwapInput(_dir, _quoteAssetAmount.toUint(), baseAssetAmount.toUint());
        return baseAssetAmount;
    }

    /**
     * @notice swap your base asset to quote asset; the impact of the price can be restricted with fluctuationLimitRatio
     * @dev only clearingHouse can call this function
     * @param _dir ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from swapInput
     * @param _baseAssetAmount base asset amount
     * @param _quoteAssetAmountLimit limit of quote asset amount; for slippage protection
     * @param _skipFluctuationCheck false for checking fluctuationLimitRatio; true for no limit, only when closePosition()
     * @return quote asset amount
     */
    function swapOutput(
        Dir _dir,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit,
        bool _skipFluctuationCheck
    ) external override onlyOpen onlyCounterParty returns (Decimal.decimal memory) {
        return implSwapOutput(_dir, _baseAssetAmount, _quoteAssetAmountLimit, _skipFluctuationCheck);
    }

    /**
     * @notice update funding rate
     * @dev only allow to update while reaching `nextFundingTime`
     * @return premium fraction of this period in 18 digits
     */
    function settleFunding() external override onlyOpen onlyCounterParty returns (SignedDecimal.signedDecimal memory) {
        require(_blockTimestamp() >= nextFundingTime, "settle funding too early");

        // premium = twapMarketPrice - twapIndexPrice
        // timeFraction = fundingPeriod(1 hour) / 1 day
        // premiumFraction = premium * timeFraction
        Decimal.decimal memory underlyingPrice = getUnderlyingTwapPrice(spotPriceTwapInterval);
        SignedDecimal.signedDecimal memory premium = MixedDecimal.fromDecimal(getTwapPrice(spotPriceTwapInterval)).subD(
            underlyingPrice
        );
        SignedDecimal.signedDecimal memory premiumFraction = premium.mulScalar(fundingPeriod).divScalar(int256(1 days));

        // update funding rate = premiumFraction / twapIndexPrice
        updateFundingRate(premiumFraction, underlyingPrice);

        // in order to prevent multiple funding settlement during very short time after network congestion
        uint256 minNextValidFundingTime = _blockTimestamp().add(fundingBufferPeriod);

        // floor((nextFundingTime + fundingPeriod) / 3600) * 3600
        uint256 nextFundingTimeOnHourStart = nextFundingTime.add(fundingPeriod).div(1 hours).mul(1 hours);

        // max(nextFundingTimeOnHourStart, minNextValidFundingTime)
        nextFundingTime = nextFundingTimeOnHourStart > minNextValidFundingTime
            ? nextFundingTimeOnHourStart
            : minNextValidFundingTime;

        // reset funding related states
        baseAssetDeltaThisFundingPeriod = SignedDecimal.zero();

        return premiumFraction;
    }

    function migrateLiquidity(
        Decimal.decimal calldata _liquidityMultiplier,
        Decimal.decimal calldata _fluctuationLimitRatio
    ) external override onlyOwner {
        require(_liquidityMultiplier.toUint() != Decimal.one().toUint(), "multiplier can't be 1");

        // check liquidity multiplier limit, have lower bound if position size is positive for now.
        checkLiquidityMultiplierLimit(totalPositionSize, _liquidityMultiplier);
        checkLiquidityMultiplierLimit(baseAssetDeltaThisFundingPeriod, _liquidityMultiplier);

        // #53 fix sandwich attack during liquidity migration
        checkFluctuationLimit(_fluctuationLimitRatio);

        // get current reserve values
        Decimal.decimal memory quoteAssetBeforeAddingLiquidity = quoteAssetReserve;
        Decimal.decimal memory baseAssetBeforeAddingLiquidity = baseAssetReserve;
        SignedDecimal.signedDecimal memory totalPositionSizeBefore = totalPositionSize;

        // migrate liquidity
        quoteAssetReserve = quoteAssetBeforeAddingLiquidity.mulD(_liquidityMultiplier);
        baseAssetReserve = baseAssetBeforeAddingLiquidity.mulD(_liquidityMultiplier);

        // MUST be called after liquidity migrated
        // baseAssetDeltaThisFundingPeriod is total position size(of a funding period) owned by Amm
        // That's why need to mulScalar(-1) when calculating the migrated size.
        baseAssetDeltaThisFundingPeriod = calcBaseAssetAfterLiquidityMigration(
            baseAssetDeltaThisFundingPeriod.mulScalar(-1),
            quoteAssetBeforeAddingLiquidity,
            baseAssetBeforeAddingLiquidity
        )
            .mulScalar(-1);

        totalPositionSize = calcBaseAssetAfterLiquidityMigration(
            totalPositionSizeBefore,
            quoteAssetBeforeAddingLiquidity,
            baseAssetBeforeAddingLiquidity
        );

        // update snapshot
        liquidityChangedSnapshots.push(
            LiquidityChangedSnapshot({
                cumulativeNotional: cumulativeNotional,
                quoteAssetReserve: quoteAssetReserve,
                baseAssetReserve: baseAssetReserve,
                totalPositionSize: totalPositionSize
            })
        );

        emit LiquidityChanged(quoteAssetReserve.toUint(), baseAssetReserve.toUint(), cumulativeNotional.toInt());
    }

    function calcBaseAssetAfterLiquidityMigration(
        SignedDecimal.signedDecimal memory _baseAssetAmount,
        Decimal.decimal memory _fromQuoteReserve,
        Decimal.decimal memory _fromBaseReserve
    ) public view override returns (SignedDecimal.signedDecimal memory) {
        if (_baseAssetAmount.toUint() == 0) {
            return _baseAssetAmount;
        }

        bool isPositiveValue = _baseAssetAmount.toInt() > 0 ? true : false;

        // measure the trader position's notional value on the old curve
        // (by simulating closing the position)
        Decimal.decimal memory posNotional = getOutputPriceWithReserves(
            isPositiveValue ? Dir.ADD_TO_AMM : Dir.REMOVE_FROM_AMM,
            _baseAssetAmount.abs(),
            _fromQuoteReserve,
            _fromBaseReserve
        );

        // calculate and apply the required size on the new curve
        SignedDecimal.signedDecimal memory newBaseAsset = MixedDecimal.fromDecimal(
            getInputPrice(isPositiveValue ? Dir.REMOVE_FROM_AMM : Dir.ADD_TO_AMM, posNotional)
        );
        return newBaseAsset.mulScalar(isPositiveValue ? 1 : int256(-1));
    }

    /**
     * @notice shutdown amm,
     * @dev only `globalShutdown` or owner can call this function
     * The price calculation is in `globalShutdown`.
     */
    function shutdown() external override {
        require(_msgSender() == owner() || _msgSender() == globalShutdown, "not owner nor globalShutdown");
        implShutdown();
    }

    /**
     * @notice set counter party
     * @dev only owner can call this function
     * @param _counterParty address of counter party
     */
    function setCounterParty(address _counterParty) external onlyOwner {
        counterParty = _counterParty;
    }

    /**
     * @notice set `globalShutdown`
     * @dev only owner can call this function
     * @param _globalShutdown address of `globalShutdown`
     */
    function setGlobalShutdown(address _globalShutdown) external onlyOwner {
        globalShutdown = _globalShutdown;
    }

    /**
     * @notice set fluctuation limit rate. Default value is `1 / max leverage`
     * @dev only owner can call this function
     * @param _fluctuationLimitRatio fluctuation limit rate in 18 digits, 0 means skip the checking
     */
    function setFluctuationLimitRatio(Decimal.decimal memory _fluctuationLimitRatio) public onlyOwner {
        fluctuationLimitRatio = _fluctuationLimitRatio;
    }

    /**
     * @notice set time interval for twap calculation, default is 1 hour
     * @dev only owner can call this function
     * @param _interval time interval in seconds
     */
    function setSpotPriceTwapInterval(uint256 _interval) external onlyOwner {
        require(_interval != 0, "can not set interval to 0");
        spotPriceTwapInterval = _interval;
    }

    /**
     * @notice set `open` flag. Amm is open to trade if `open` is true. Default is false.
     * @dev only owner can call this function
     * @param _open open to trade is true, otherwise is false.
     */
    function setOpen(bool _open) external onlyOwner {
        if (open == _open) return;

        open = _open;
        if (_open) {
            nextFundingTime = _blockTimestamp().add(fundingPeriod).div(1 hours).mul(1 hours);
        }
    }

    /**
     * @notice set new toll ratio
     * @dev only owner can call
     * @param _tollRatio new toll ratio in 18 digits
     */
    function setTollRatio(Decimal.decimal memory _tollRatio) public onlyOwner {
        tollRatio = _tollRatio;
    }

    /**
     * @notice set new spread ratio
     * @dev only owner can call
     * @param _spreadRatio new toll spread in 18 digits
     */
    function setSpreadRatio(Decimal.decimal memory _spreadRatio) public onlyOwner {
        spreadRatio = _spreadRatio;
    }

    /**
     * @notice set new cap during guarded period, which is max position size that traders can hold
     * @dev only owner can call. assume this will be removes soon once the guarded period has ended. must be set before opening amm
     * @param _maxHoldingBaseAsset max position size that traders can hold in 18 digits
     * @param _openInterestNotionalCap open interest cap, denominated in quoteToken
     */
    function setCap(Decimal.decimal memory _maxHoldingBaseAsset, Decimal.decimal memory _openInterestNotionalCap)
        public
        onlyOwner
    {
        maxHoldingBaseAsset = _maxHoldingBaseAsset;
        openInterestNotionalCap = _openInterestNotionalCap;
        emit CapChanged(maxHoldingBaseAsset.toUint(), openInterestNotionalCap.toUint());
    }

    //
    // VIEW FUNCTIONS
    //

    /**
     * @notice get input twap amount.
     * returns how many base asset you will get with the input quote amount based on twap price.
     * @param _dir ADD_TO_AMM for long, REMOVE_FROM_AMM for short.
     * @param _quoteAssetAmount quote asset amount
     * @return base asset amount
     */
    function getInputTwap(Dir _dir, Decimal.decimal memory _quoteAssetAmount)
        public
        view
        override
        returns (Decimal.decimal memory)
    {
        return implGetInputAssetTwapPrice(_dir, _quoteAssetAmount, QuoteAssetDir.QUOTE_IN, 15 minutes);
    }

    /**
     * @notice get output twap amount.
     * return how many quote asset you will get with the input base amount on twap price.
     * @param _dir ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from `getInputTwap`.
     * @param _baseAssetAmount base asset amount
     * @return quote asset amount
     */
    function getOutputTwap(Dir _dir, Decimal.decimal memory _baseAssetAmount)
        public
        view
        override
        returns (Decimal.decimal memory)
    {
        return implGetInputAssetTwapPrice(_dir, _baseAssetAmount, QuoteAssetDir.QUOTE_OUT, 15 minutes);
    }

    /**
     * @notice get input amount. returns how many base asset you will get with the input quote amount.
     * @param _dir ADD_TO_AMM for long, REMOVE_FROM_AMM for short.
     * @param _quoteAssetAmount quote asset amount
     * @return base asset amount
     */
    function getInputPrice(Dir _dir, Decimal.decimal memory _quoteAssetAmount)
        public
        view
        override
        returns (Decimal.decimal memory)
    {
        return getInputPriceWithReserves(_dir, _quoteAssetAmount, quoteAssetReserve, baseAssetReserve);
    }

    /**
     * @notice get output price. return how many quote asset you will get with the input base amount
     * @param _dir ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from `getInput`.
     * @param _baseAssetAmount base asset amount
     * @return quote asset amount
     */
    function getOutputPrice(Dir _dir, Decimal.decimal memory _baseAssetAmount)
        public
        view
        override
        returns (Decimal.decimal memory)
    {
        return getOutputPriceWithReserves(_dir, _baseAssetAmount, quoteAssetReserve, baseAssetReserve);
    }

    /**
     * @notice get underlying price provided by oracle
     * @return underlying price
     */
    function getUnderlyingPrice() public view returns (Decimal.decimal memory) {
        return Decimal.decimal(priceFeed.getPrice(priceFeedKey));
    }

    /**
     * @notice get underlying twap price provided by oracle
     * @return underlying price
     */
    function getUnderlyingTwapPrice(uint256 _intervalInSeconds) public view returns (Decimal.decimal memory) {
        return Decimal.decimal(priceFeed.getTwapPrice(priceFeedKey, _intervalInSeconds));
    }

    /**
     * @notice get spot price based on current quote/base asset reserve.
     * @return spot price
     */
    function getSpotPrice() public view override returns (Decimal.decimal memory) {
        return quoteAssetReserve.divD(baseAssetReserve);
    }

    /**
     * @notice get twap price
     */
    function getTwapPrice(uint256 _intervalInSeconds) public view returns (Decimal.decimal memory) {
        return implGetReserveTwapPrice(_intervalInSeconds);
    }

    /**
     * @notice get current quote/base asset reserve.
     * @return (quote asset reserve, base asset reserve)
     */
    function getReserve() external view returns (Decimal.decimal memory, Decimal.decimal memory) {
        return (quoteAssetReserve, baseAssetReserve);
    }

    //@audit - no one use this anymore, can be remove (@wraecca).
    // If we remove this, we should make reserveSnapshots private.
    // If we need reserveSnapshots, should keep this. (@Kimi)
    function getSnapshotLen() external view returns (uint256) {
        return reserveSnapshots.length;
    }

    function getLiquidityHistoryLength() external view override returns (uint256) {
        return liquidityChangedSnapshots.length;
    }

    function getCumulativeNotional() external view override returns (SignedDecimal.signedDecimal memory) {
        return cumulativeNotional;
    }

    function getLatestLiquidityChangedSnapshots() public view returns (LiquidityChangedSnapshot memory) {
        return liquidityChangedSnapshots[liquidityChangedSnapshots.length.sub(1)];
    }

    function getLiquidityChangedSnapshots(uint256 i) external view override returns (LiquidityChangedSnapshot memory) {
        require(i < liquidityChangedSnapshots.length, "incorrect index");
        return liquidityChangedSnapshots[i];
    }

    function getSettlementPrice() external view override returns (Decimal.decimal memory) {
        return settlementPrice;
    }

    function getBaseAssetDeltaThisFundingPeriod() external view override returns (SignedDecimal.signedDecimal memory) {
        return baseAssetDeltaThisFundingPeriod;
    }

    function getMaxHoldingBaseAsset() external view override returns (Decimal.decimal memory) {
        return maxHoldingBaseAsset;
    }

    function getOpenInterestNotionalCap() external view override returns (Decimal.decimal memory) {
        return openInterestNotionalCap;
    }

    /**
     * @notice calculate total fee (including toll and spread) by input quoteAssetAmount
     * @param _quoteAssetAmount quoteAssetAmount
     * @return total tx fee
     */
    function calcFee(Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        override
        returns (Decimal.decimal memory, Decimal.decimal memory)
    {
        if (_quoteAssetAmount.toUint() == 0) {
            return (Decimal.zero(), Decimal.zero());
        }
        return (_quoteAssetAmount.mulD(tollRatio), _quoteAssetAmount.mulD(spreadRatio));
    }

    /*       plus/minus 1 while the amount is not dividable
     *
     *        getInputPrice                         getOutputPrice
     *
     *     ＡＤＤ      (amount - 1)              (amount + 1)   ＲＥＭＯＶＥ
     *      ◥◤            ▲                         |             ◢◣
     *      ◥◤  ------->  |                         ▼  <--------  ◢◣
     *    -------      -------                   -------        -------
     *    |  Q  |      |  B  |                   |  Q  |        |  B  |
     *    -------      -------                   -------        -------
     *      ◥◤  ------->  ▲                         |  <--------  ◢◣
     *      ◥◤            |                         ▼             ◢◣
     *   ＲＥＭＯＶＥ  (amount + 1)              (amount + 1)      ＡＤＤ
     **/

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) public pure override returns (Decimal.decimal memory) {
        if (_quoteAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }

        bool isAddToAmm = _dir == Dir.ADD_TO_AMM;
        SignedDecimal.signedDecimal memory invariant = MixedDecimal.fromDecimal(
            _quoteAssetPoolAmount.mulD(_baseAssetPoolAmount)
        );
        SignedDecimal.signedDecimal memory baseAssetAfter;
        Decimal.decimal memory quoteAssetAfter;
        Decimal.decimal memory baseAssetBought;
        if (isAddToAmm) {
            quoteAssetAfter = _quoteAssetPoolAmount.addD(_quoteAssetAmount);
        } else {
            quoteAssetAfter = _quoteAssetPoolAmount.subD(_quoteAssetAmount);
        }
        require(quoteAssetAfter.toUint() != 0, "quote asset after is 0");

        baseAssetAfter = invariant.divD(quoteAssetAfter);
        baseAssetBought = baseAssetAfter.subD(_baseAssetPoolAmount).abs();

        // if the amount is not dividable, return 1 wei less for trader
        if (invariant.abs().modD(quoteAssetAfter).toUint() != 0) {
            if (isAddToAmm) {
                baseAssetBought = baseAssetBought.subD(Decimal.decimal(1));
            } else {
                baseAssetBought = baseAssetBought.addD(Decimal.decimal(1));
            }
        }

        return baseAssetBought;
    }

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) public pure override returns (Decimal.decimal memory) {
        if (_baseAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }

        bool isAddToAmm = _dir == Dir.ADD_TO_AMM;
        SignedDecimal.signedDecimal memory invariant = MixedDecimal.fromDecimal(
            _quoteAssetPoolAmount.mulD(_baseAssetPoolAmount)
        );
        SignedDecimal.signedDecimal memory quoteAssetAfter;
        Decimal.decimal memory baseAssetAfter;
        Decimal.decimal memory quoteAssetSold;

        if (isAddToAmm) {
            baseAssetAfter = _baseAssetPoolAmount.addD(_baseAssetAmount);
        } else {
            baseAssetAfter = _baseAssetPoolAmount.subD(_baseAssetAmount);
        }
        require(baseAssetAfter.toUint() != 0, "base asset after is 0");

        quoteAssetAfter = invariant.divD(baseAssetAfter);
        quoteAssetSold = quoteAssetAfter.subD(_quoteAssetPoolAmount).abs();

        // if the amount is not dividable, return 1 wei less for trader
        if (invariant.abs().modD(baseAssetAfter).toUint() != 0) {
            if (isAddToAmm) {
                quoteAssetSold = quoteAssetSold.subD(Decimal.decimal(1));
            } else {
                quoteAssetSold = quoteAssetSold.addD(Decimal.decimal(1));
            }
        }

        return quoteAssetSold;
    }

    //
    // INTERNAL FUNCTIONS
    //
    // update funding rate = premiumFraction / twapIndexPrice
    function updateFundingRate(
        SignedDecimal.signedDecimal memory _premiumFraction,
        Decimal.decimal memory _underlyingPrice
    ) private {
        fundingRate = _premiumFraction.divD(_underlyingPrice);
        emit FundingRateUpdated(fundingRate.toInt(), _underlyingPrice.toUint());
    }

    function addReserveSnapshot() internal {
        uint256 currentBlock = _blockNumber();
        ReserveSnapshot storage latestSnapshot = reserveSnapshots[reserveSnapshots.length - 1];
        // update values in snapshot if in the same block
        if (currentBlock == latestSnapshot.blockNumber) {
            latestSnapshot.quoteAssetReserve = quoteAssetReserve;
            latestSnapshot.baseAssetReserve = baseAssetReserve;
        } else {
            reserveSnapshots.push(
                ReserveSnapshot(quoteAssetReserve, baseAssetReserve, _blockTimestamp(), currentBlock)
            );
        }
        emit ReserveSnapshotted(quoteAssetReserve.toUint(), baseAssetReserve.toUint(), _blockTimestamp());
    }

    function implSwapOutput(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetAmountLimit,
        bool _skipFluctuationCheck
    ) internal returns (Decimal.decimal memory) {
        if (_baseAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }
        if (_dir == Dir.REMOVE_FROM_AMM) {
            require(baseAssetReserve.mulD(tradeLimitRatio).toUint() >= _baseAssetAmount.toUint(), "over trading limit");
        }

        Decimal.decimal memory quoteAssetAmount = getOutputPrice(_dir, _baseAssetAmount);
        // If SHORT, exchanged quote amount should be less than _quoteAssetAmountLimit,
        // otherwise(LONG), exchanged base amount should be more than _quoteAssetAmountLimit.
        // In the SHORT case, more quote assets means more payment so should not be more than _quoteAssetAmountLimit
        if (_quoteAssetAmountLimit.toUint() != 0) {
            if (_dir == Dir.ADD_TO_AMM) {
                // SHORT
                require(quoteAssetAmount.toUint() >= _quoteAssetAmountLimit.toUint(), "Less than minimal quote token");
            } else {
                // LONG
                require(quoteAssetAmount.toUint() <= _quoteAssetAmountLimit.toUint(), "More than maximal quote token");
            }
        }

        // If the price impact of one single tx is larger than priceFluctuation, skip the check
        // only for liquidate()
        if (!_skipFluctuationCheck) {
            _skipFluctuationCheck = isSingleTxOverFluctuation(_dir, quoteAssetAmount, _baseAssetAmount);
        }

        updateReserve(
            _dir == Dir.ADD_TO_AMM ? Dir.REMOVE_FROM_AMM : Dir.ADD_TO_AMM,
            quoteAssetAmount,
            _baseAssetAmount,
            _skipFluctuationCheck
        );

        emit SwapOutput(_dir, quoteAssetAmount.toUint(), _baseAssetAmount.toUint());
        return quoteAssetAmount;
    }

    function updateReserve(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _baseAssetAmount,
        bool _skipFluctuationCheck
    ) internal {
        if (_dir == Dir.ADD_TO_AMM) {
            quoteAssetReserve = quoteAssetReserve.addD(_quoteAssetAmount);
            baseAssetReserve = baseAssetReserve.subD(_baseAssetAmount);
            baseAssetDeltaThisFundingPeriod = baseAssetDeltaThisFundingPeriod.subD(_baseAssetAmount);
            totalPositionSize = totalPositionSize.addD(_baseAssetAmount);
            cumulativeNotional = cumulativeNotional.addD(_quoteAssetAmount);
        } else {
            quoteAssetReserve = quoteAssetReserve.subD(_quoteAssetAmount);
            baseAssetReserve = baseAssetReserve.addD(_baseAssetAmount);
            baseAssetDeltaThisFundingPeriod = baseAssetDeltaThisFundingPeriod.addD(_baseAssetAmount);
            totalPositionSize = totalPositionSize.subD(_baseAssetAmount);
            cumulativeNotional = cumulativeNotional.subD(_quoteAssetAmount);
        }

        // check if it's over fluctuationLimitRatio
        if (!_skipFluctuationCheck) {
            checkFluctuationLimit(fluctuationLimitRatio);
        }

        // addReserveSnapshot must be after checking price fluctuation
        addReserveSnapshot();
    }

    function implGetInputAssetTwapPrice(
        Dir _dir,
        Decimal.decimal memory _assetAmount,
        QuoteAssetDir _inOut,
        uint256 _interval
    ) internal view returns (Decimal.decimal memory) {
        TwapPriceCalcParams memory params;
        params.opt = TwapCalcOption.INPUT_ASSET;
        params.snapshotIndex = reserveSnapshots.length.sub(1);
        params.asset.dir = _dir;
        params.asset.assetAmount = _assetAmount;
        params.asset.inOrOut = _inOut;
        return calcTwap(params, _interval);
    }

    function implGetReserveTwapPrice(uint256 _interval) internal view returns (Decimal.decimal memory) {
        TwapPriceCalcParams memory params;
        params.opt = TwapCalcOption.RESERVE_ASSET;
        params.snapshotIndex = reserveSnapshots.length.sub(1);
        return calcTwap(params, _interval);
    }

    function calcTwap(TwapPriceCalcParams memory _params, uint256 _interval)
        internal
        view
        returns (Decimal.decimal memory)
    {
        Decimal.decimal memory currentPrice = getPriceWithSpecificSnapshot(_params);
        if (_interval == 0) {
            return currentPrice;
        }

        uint256 baseTimestamp = _blockTimestamp().sub(_interval);
        ReserveSnapshot memory currentSnapshot = reserveSnapshots[_params.snapshotIndex];
        // return the latest snapshot price directly
        // if only one snapshot or the timestamp of latest snapshot is earlier than asking for
        if (reserveSnapshots.length == 1 || currentSnapshot.timestamp <= baseTimestamp) {
            return currentPrice;
        }

        uint256 previousTimestamp = currentSnapshot.timestamp;
        uint256 period = _blockTimestamp().sub(previousTimestamp);
        Decimal.decimal memory weightedPrice = currentPrice.mulScalar(period);
        while (true) {
            // if snapshot history is too short
            if (_params.snapshotIndex == 0) {
                return weightedPrice.divScalar(period);
            }

            _params.snapshotIndex = _params.snapshotIndex.sub(1);
            currentSnapshot = reserveSnapshots[_params.snapshotIndex];
            currentPrice = getPriceWithSpecificSnapshot(_params);

            // check if current round timestamp is earlier than target timestamp
            if (currentSnapshot.timestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, _interval is 100, then target timestamp is 900. If timestamp of current round is 970,
                // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice = weightedPrice.addD(currentPrice.mulScalar(previousTimestamp.sub(baseTimestamp)));
                break;
            }

            uint256 timeFraction = previousTimestamp.sub(currentSnapshot.timestamp);
            weightedPrice = weightedPrice.addD(currentPrice.mulScalar(timeFraction));
            period = period.add(timeFraction);
            previousTimestamp = currentSnapshot.timestamp;
        }
        return weightedPrice.divScalar(_interval);
    }

    function getPriceWithSpecificSnapshot(TwapPriceCalcParams memory params)
        internal
        view
        virtual
        returns (Decimal.decimal memory)
    {
        ReserveSnapshot memory snapshot = reserveSnapshots[params.snapshotIndex];

        // RESERVE_ASSET means price comes from quoteAssetReserve/baseAssetReserve
        // INPUT_ASSET means getInput/Output price with snapshot's reserve
        if (params.opt == TwapCalcOption.RESERVE_ASSET) {
            return snapshot.quoteAssetReserve.divD(snapshot.baseAssetReserve);
        } else if (params.opt == TwapCalcOption.INPUT_ASSET) {
            if (params.asset.assetAmount.toUint() == 0) {
                return Decimal.zero();
            }
            if (params.asset.inOrOut == QuoteAssetDir.QUOTE_IN) {
                return
                    getInputPriceWithReserves(
                        params.asset.dir,
                        params.asset.assetAmount,
                        snapshot.quoteAssetReserve,
                        snapshot.baseAssetReserve
                    );
            } else if (params.asset.inOrOut == QuoteAssetDir.QUOTE_OUT) {
                return
                    getOutputPriceWithReserves(
                        params.asset.dir,
                        params.asset.assetAmount,
                        snapshot.quoteAssetReserve,
                        snapshot.baseAssetReserve
                    );
            }
        }
        revert("not supported option");
    }

    function isSingleTxOverFluctuation(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _baseAssetAmount
    ) internal view returns (bool) {
        Decimal.decimal memory priceAfterReserveUpdated = (_dir == Dir.ADD_TO_AMM)
            ? quoteAssetReserve.subD(_quoteAssetAmount).divD(baseAssetReserve.addD(_baseAssetAmount))
            : quoteAssetReserve.addD(_quoteAssetAmount).divD(baseAssetReserve.subD(_baseAssetAmount));
        return
            isOverFluctuationLimit(
                priceAfterReserveUpdated,
                fluctuationLimitRatio,
                reserveSnapshots[reserveSnapshots.length.sub(1)]
            );
    }

    function checkFluctuationLimit(Decimal.decimal memory _fluctuationLimitRatio) internal view {
        // Skip the check if the limit is 0
        if (_fluctuationLimitRatio.toUint() > 0) {
            uint256 len = reserveSnapshots.length;
            ReserveSnapshot memory latestSnapshot = reserveSnapshots[len - 1];

            // if the latest snapshot is the same as current block, get the previous one
            if (latestSnapshot.blockNumber == _blockNumber() && len > 1) {
                latestSnapshot = reserveSnapshots[len - 2];
            }

            require(
                !isOverFluctuationLimit(
                    quoteAssetReserve.divD(baseAssetReserve),
                    _fluctuationLimitRatio,
                    latestSnapshot
                ),
                "price is over fluctuation limit"
            );
        }
    }

    function checkLiquidityMultiplierLimit(
        SignedDecimal.signedDecimal memory _positionSize,
        Decimal.decimal memory _liquidityMultiplier
    ) internal view {
        // have lower bound when position size is long
        if (_positionSize.toInt() > 0) {
            Decimal.decimal memory liquidityMultiplierLowerBound = _positionSize
                .addD(Decimal.decimal(MARGIN_FOR_LIQUIDITY_MIGRATION_ROUNDING))
                .divD(baseAssetReserve)
                .abs();
            require(_liquidityMultiplier.cmp(liquidityMultiplierLowerBound) >= 0, "illegal liquidity multiplier");
        }
    }

    function isOverFluctuationLimit(
        Decimal.decimal memory _price,
        Decimal.decimal memory _fluctuationLimitRatio,
        ReserveSnapshot memory _snapshot
    ) internal pure returns (bool) {
        Decimal.decimal memory lastPrice = _snapshot.quoteAssetReserve.divD(_snapshot.baseAssetReserve);
        Decimal.decimal memory upperLimit = lastPrice.mulD(Decimal.one().addD(_fluctuationLimitRatio));
        Decimal.decimal memory lowerLimit = lastPrice.mulD(Decimal.one().subD(_fluctuationLimitRatio));

        if (_price.cmp(upperLimit) <= 0 && _price.cmp(lowerLimit) >= 0) {
            return false;
        }
        return true;
    }

    function implShutdown() internal {
        LiquidityChangedSnapshot memory latestLiquiditySnapshot = getLatestLiquidityChangedSnapshots();

        // get last liquidity changed history to calc new quote/base reserve
        Decimal.decimal memory previousK = latestLiquiditySnapshot.baseAssetReserve.mulD(
            latestLiquiditySnapshot.quoteAssetReserve
        );
        SignedDecimal.signedDecimal memory lastInitBaseReserveInNewCurve = latestLiquiditySnapshot
            .totalPositionSize
            .addD(latestLiquiditySnapshot.baseAssetReserve);
        SignedDecimal.signedDecimal memory lastInitQuoteReserveInNewCurve = MixedDecimal.fromDecimal(previousK).divD(
            lastInitBaseReserveInNewCurve
        );

        // settlementPrice = SUM(Open Position Notional Value) / SUM(Position Size)
        // `Open Position Notional Value` = init quote reserve - current quote reserve
        // `Position Size` = init base reserve - current base reserve
        SignedDecimal.signedDecimal memory positionNotionalValue = lastInitQuoteReserveInNewCurve.subD(
            quoteAssetReserve
        );

        // if total position size less than IGNORABLE_DIGIT_FOR_SHUTDOWN, treat it as 0 positions due to rounding error
        if (totalPositionSize.toUint() > IGNORABLE_DIGIT_FOR_SHUTDOWN) {
            settlementPrice = positionNotionalValue.abs().divD(totalPositionSize.abs());
        }

        open = false;
        emit Shutdown(settlementPrice.toUint());
    }
}