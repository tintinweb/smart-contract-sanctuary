pragma solidity 0.5.17;

/**
 *Submitted for verification at Etherscan.io on 2020-05-04
*/

// File: contracts/interfaces/IWhitelist.sol

pragma solidity 0.5.17;


/**
 * Source: https://raw.githubusercontent.com/simple-restricted-token/reference-implementation/master/contracts/token/ERC1404/ERC1404.sol
 * With ERC-20 APIs removed (will be implemented as a separate contract).
 * And adding authorizeTransfer.
 */
interface IWhitelist
{
  /**
   * @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
   * @param from Sending address
   * @param to Receiving address
   * @param value Amount of tokens being transferred
   * @return Code by which to reference message for rejection reasoning
   * @dev Overwrite with your custom transfer restriction logic
   */
  function detectTransferRestriction(
    address from,
    address to,
    uint value
  ) external view
    returns (uint8);

  /**
   * @notice Returns a human-readable message for a given restriction code
   * @param restrictionCode Identifier for looking up a message
   * @return Text showing the restriction's reasoning
   * @dev Overwrite with your custom message and restrictionCode handling
   */
  function messageForTransferRestriction(
    uint8 restrictionCode
  ) external pure
    returns (string memory);

  /**
   * @notice Called by the DAT contract before a transfer occurs.
   * @dev This call will revert when the transfer is not authorized.
   * This is a mutable call to allow additional data to be recorded,
   * such as when the user aquired their tokens.
   */
  function authorizeTransfer(
    address _from,
    address _to,
    uint _value,
    bool _isSell
  ) external;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/math/BigDiv.sol

pragma solidity ^0.5.0;


/**
 * @title Reduces the size of terms before multiplication, to avoid an overflow, and then
 * restores the proper size after division.
 * @notice This effectively allows us to overflow values in the numerator and/or denominator
 * of a fraction, so long as the end result does not overflow as well.
 * @dev Results may be off by 1 + 0.000001% for 2x1 calls and 2 + 0.00001% for 2x2 calls.
 * Do not use if your contract expects very small result values to be accurate.
 */
library BigDiv
{
  using SafeMath for uint256;

  /// @notice The max possible value
  uint256 private constant MAX_UINT = 2**256 - 1;

  /// @notice When multiplying 2 terms <= this value the result won't overflow
  uint256 private constant MAX_BEFORE_SQUARE = 2**128 - 1;

  /// @notice The max error target is off by 1 plus up to 0.000001% error
  /// for bigDiv2x1 and that `* 2` for bigDiv2x2
  uint256 private constant MAX_ERROR = 100000000;

  /// @notice A larger error threshold to use when multiple rounding errors may apply
  uint256 private constant MAX_ERROR_BEFORE_DIV = MAX_ERROR * 2;

  /**
   * @notice Returns the approx result of `a * b / d` so long as the result is <= MAX_UINT
   * @param _numA the first numerator term
   * @param _numB the second numerator term
   * @param _den the denominator
   * @return the approx result with up to off by 1 + MAX_ERROR, rounding down if needed
   */
  function bigDiv2x1(
    uint256 _numA,
    uint256 _numB,
    uint256 _den
  ) internal pure
    returns(uint256)
  {
    if(_numA == 0 || _numB == 0)
    {
      // would div by 0 or underflow if we don't special case 0
      return 0;
    }

    uint256 value;

    if(MAX_UINT / _numA >= _numB)
    {
      // a*b does not overflow, return exact math
      value = _numA * _numB;
      value /= _den;
      return value;
    }

    // Sort numerators
    uint256 numMax = _numB;
    uint256 numMin = _numA;
    if(_numA > _numB)
    {
      numMax = _numA;
      numMin = _numB;
    }

    value = numMax / _den;
    if(value > MAX_ERROR)
    {
      // _den is small enough to be MAX_ERROR or better w/o a factor
      value = value.mul(numMin);
      return value;
    }

    // formula = ((a / f) * b) / (d / f)
    // factor >= a / sqrt(MAX) * (b / sqrt(MAX))
    uint256 factor = numMin - 1;
    factor /= MAX_BEFORE_SQUARE;
    factor += 1;
    uint256 temp = numMax - 1;
    temp /= MAX_BEFORE_SQUARE;
    temp += 1;
    if(MAX_UINT / factor >= temp)
    {
      factor *= temp;
      value = numMax / factor;
      if(value > MAX_ERROR_BEFORE_DIV)
      {
        value = value.mul(numMin);
        temp = _den - 1;
        temp /= factor;
        temp = temp.add(1);
        value /= temp;
        return value;
      }
    }

    // formula: (a / (d / f)) * (b / f)
    // factor: b / sqrt(MAX)
    factor = numMin - 1;
    factor /= MAX_BEFORE_SQUARE;
    factor += 1;
    value = numMin / factor;
    temp = _den - 1;
    temp /= factor;
    temp += 1;
    temp = numMax / temp;
    value = value.mul(temp);
    return value;
  }

  /**
   * @notice Returns the approx result of `a * b / d` so long as the result is <= MAX_UINT
   * @param _numA the first numerator term
   * @param _numB the second numerator term
   * @param _den the denominator
   * @return the approx result with up to off by 1 + MAX_ERROR, rounding down if needed
   * @dev roundUp is implemented by first rounding down and then adding the max error to the result
   */
  function bigDiv2x1RoundUp(
    uint256 _numA,
    uint256 _numB,
    uint256 _den
  ) internal pure
    returns(uint256)
  {
    // first get the rounded down result
    uint256 value = bigDiv2x1(_numA, _numB, _den);

    if(value == 0)
    {
      // when the value rounds down to 0, assume up to an off by 1 error
      return 1;
    }

    // round down has a max error of MAX_ERROR, add that to the result
    // for a round up error of <= MAX_ERROR
    uint256 temp = value - 1;
    temp /= MAX_ERROR;
    temp += 1;
    if(MAX_UINT - value < temp)
    {
      // value + error would overflow, return MAX
      return MAX_UINT;
    }

    value += temp;

    return value;
  }

  /**
   * @notice Returns the approx result of `a * b / (c * d)` so long as the result is <= MAX_UINT
   * @param _numA the first numerator term
   * @param _numB the second numerator term
   * @param _denA the first denominator term
   * @param _denB the second denominator term
   * @return the approx result with up to off by 2 + MAX_ERROR*10 error, rounding down if needed
   * @dev this uses bigDiv2x1 and adds additional rounding error so the max error of this
   * formula is larger
   */
  function bigDiv2x2(
    uint256 _numA,
    uint256 _numB,
    uint256 _denA,
    uint256 _denB
  ) internal pure
    returns (uint256)
  {
    if(MAX_UINT / _denA >= _denB)
    {
      // denA*denB does not overflow, use bigDiv2x1 instead
      return bigDiv2x1(_numA, _numB, _denA * _denB);
    }

    if(_numA == 0 || _numB == 0)
    {
      // would div by 0 or underflow if we don't special case 0
      return 0;
    }

    // Sort denominators
    uint256 denMax = _denB;
    uint256 denMin = _denA;
    if(_denA > _denB)
    {
      denMax = _denA;
      denMin = _denB;
    }

    uint256 value;

    if(MAX_UINT / _numA >= _numB)
    {
      // a*b does not overflow, use `a / d / c`
      value = _numA * _numB;
      value /= denMin;
      value /= denMax;
      return value;
    }

    // `ab / cd` where both `ab` and `cd` would overflow

    // Sort numerators
    uint256 numMax = _numB;
    uint256 numMin = _numA;
    if(_numA > _numB)
    {
      numMax = _numA;
      numMin = _numB;
    }

    // formula = (a/d) * b / c
    uint256 temp = numMax / denMin;
    if(temp > MAX_ERROR_BEFORE_DIV)
    {
      return bigDiv2x1(temp, numMin, denMax);
    }

    // formula: ((a/f) * b) / d then either * f / c or / c * f
    // factor >= a / sqrt(MAX) * (b / sqrt(MAX))
    uint256 factor = numMin - 1;
    factor /= MAX_BEFORE_SQUARE;
    factor += 1;
    temp = numMax - 1;
    temp /= MAX_BEFORE_SQUARE;
    temp += 1;
    if(MAX_UINT / factor >= temp)
    {
      factor *= temp;

      value = numMax / factor;
      if(value > MAX_ERROR_BEFORE_DIV)
      {
        value = value.mul(numMin);
        value /= denMin;
        if(value > 0 && MAX_UINT / value >= factor)
        {
          value *= factor;
          value /= denMax;
          return value;
        }
      }
    }

    // formula: (a/f) * b / ((c*d)/f)
    // factor >= c / sqrt(MAX) * (d / sqrt(MAX))
    factor = denMin;
    factor /= MAX_BEFORE_SQUARE;
    temp = denMax;
    // + 1 here prevents overflow of factor*temp
    temp /= MAX_BEFORE_SQUARE + 1;
    factor *= temp;
    return bigDiv2x1(numMax / factor, numMin, MAX_UINT);
  }
}

// File: contracts/math/Sqrt.sol

pragma solidity ^0.5.0;


/**
 * @title Calculates the square root of a given value.
 * @dev Results may be off by 1.
 */
library Sqrt
{
  /// @notice The max possible value
  uint256 private constant MAX_UINT = 2**256 - 1;

  // Source: https://github.com/ethereum/dapp-bin/pull/50
  function sqrt(
    uint x
  ) internal pure
    returns (uint y)
  {
    if (x == 0)
    {
      return 0;
    }
    else if (x <= 3)
    {
      return 1;
    }
    else if (x == MAX_UINT)
    {
      // Without this we fail on x + 1 below
      return 2**128 - 1;
    }

    uint z = (x + 1) / 2;
    y = x;
    while (z < y)
    {
      y = z;
      z = (x / z + z) / 2;
    }
  }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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

pragma solidity ^0.5.0;


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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;



/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

// File: contracts/DecentralizedAutonomousTrust.sol

pragma solidity 0.5.17;











/**
 * @title Decentralized Autonomous Trust
 * This contract is a modified version of the implementation provided by Fairmint for a
 * Decentralized Autonomous Trust as described in the continuous
 * organization whitepaper (https://github.com/c-org/whitepaper) and
 * specified here: https://github.com/fairmint/c-org/wiki.
 * Code from : https://github.com/Fairmint/c-org/blob/dfd3129f9bce8717406aba54d1f1888d8e253dbb/contracts/DecentralizedAutonomousTrust.sol
 * Changes Added: https://github.com/Fairmint/c-org/commit/60bb63b9112a82996f275a75a87c28b1d73e3f11
 *
 * Use at your own risk. 
 */
contract DecentralizedAutonomousTrust
  is ERC20, ERC20Detailed
{
  using SafeMath for uint;
  using Sqrt for uint;
  using SafeERC20 for IERC20;

  /**
   * Events
   */

  event Buy(
    address indexed _from,
    address indexed _to,
    uint _currencyValue,
    uint _fairValue
  );
  event Sell(
    address indexed _from,
    address indexed _to,
    uint _currencyValue,
    uint _fairValue
  );
  event Burn(
    address indexed _from,
    uint _fairValue
  );
  event Pay(
    address indexed _from,
    address indexed _to,
    uint _currencyValue,
    uint _fairValue
  );
  event Close(
    uint _exitFee
  );
  event StateChange(
    uint _previousState,
    uint _newState
  );
  event UpdateConfig(
    address _whitelistAddress,
    address indexed _beneficiary,
    address indexed _control,
    address indexed _feeCollector,
    bool _autoBurn,
    uint _revenueCommitmentBasisPoints,
    uint _feeBasisPoints,
    uint _minInvestment,
    uint _openUntilAtLeast
  );

  /**
   * Constants
   */

  /// @notice The default state
  uint private constant STATE_INIT = 0;

  /// @notice The state after initGoal has been reached
  uint private constant STATE_RUN = 1;

  /// @notice The state after closed by the `beneficiary` account from STATE_RUN
  uint private constant STATE_CLOSE = 2;

  /// @notice The state after closed by the `beneficiary` account from STATE_INIT
  uint private constant STATE_CANCEL = 3;

  /// @notice When multiplying 2 terms, the max value is 2^128-1
  uint private constant MAX_BEFORE_SQUARE = 2**128 - 1;

  /// @notice The denominator component for values specified in basis points.
  uint private constant BASIS_POINTS_DEN = 10000;

  /// @notice The max `totalSupply() + burnedSupply`
  /// @dev This limit ensures that the DAT's formulas do not overflow (<MAX_BEFORE_SQUARE/2)
  uint private constant MAX_SUPPLY = 10 ** 38;

  /**
   * Data specific to our token business logic
   */

  /// @notice The contract for transfer authorizations, if any.
  IWhitelist public whitelist;

  /// @notice The total number of burned COT tokens, excluding tokens burned from a `Sell` action in the DAT.
  uint public burnedSupply;

  /**
   * Data for DAT business logic
   */

  /// @notice Set if the COTs minted by the organization when it commits its revenues are
  /// automatically burnt (`true`) or not (`false`). Defaults to `false` meaning that there
  /// is no automatic burn.
  bool public autoBurn;

  /// @notice The address of the beneficiary organization which receives the investments.
  /// Points to the wallet of the organization.
  address payable public beneficiary;

  /// @notice The buy slope of the bonding curve.
  /// Does not affect the financial model, only the granularity of COT.
  /// @dev This is the numerator component of the fractional value.
  uint public buySlopeNum;

  /// @notice The buy slope of the bonding curve.
  /// Does not affect the financial model, only the granularity of COT.
  /// @dev This is the denominator component of the fractional value.
  uint public buySlopeDen;

  /// @notice The address from which the updatable variables can be updated
  address public control;

  /// @notice The address of the token used as reserve in the bonding curve
  /// (e.g. the DAI contract). Use ETH if 0.
  IERC20 public currency;

  /// @notice The address where fees are sent.
  address payable public feeCollector;

  /// @notice The percent fee collected each time new COT are issued expressed in basis points.
  uint public feeBasisPoints;

  /// @notice The initial fundraising goal (expressed in COT) to start the c-org.
  /// `0` means that there is no initial fundraising and the c-org immediately moves to run state.
  uint public initGoal;

  /// @notice A map with all investors in init state using address as a key and amount as value.
  /// @dev This structure's purpose is to make sure that only investors can withdraw their money if init_goal is not reached.
  mapping(address => uint) public initInvestors;

  /// @notice The initial number of COT created at initialization for the beneficiary.
  /// Technically however, this variable is not a constant as we must always have
  ///`init_reserve>=total_supply+burnt_supply` which means that `init_reserve` will be automatically
  /// decreased to equal `total_supply+burnt_supply` in case `init_reserve>total_supply+burnt_supply`
  /// after an investor sells his COTs.
  /// @dev Organizations may move these tokens into vesting contract(s)
  uint public initReserve;

  /// @notice The investment reserve of the c-org. Defines the percentage of the value invested that is
  /// automatically funneled and held into the buyback_reserve expressed in basis points.
  uint public investmentReserveBasisPoints;

  /// @notice The earliest date/time (in seconds) that the DAT may enter the `CLOSE` state, ensuring
  /// that if the DAT reaches the `RUN` state it will remain running for at least this period of time.
  /// @dev This value may be increased anytime by the control account
  uint public openUntilAtLeast;

  /// @notice The minimum amount of `currency` investment accepted.
  uint public minInvestment;

  /// @notice The revenue commitment of the organization. Defines the percentage of the value paid through the contract
  /// that is automatically funneled and held into the buyback_reserve expressed in basis points.
  uint public revenueCommitmentBasisPoints;

  /// @notice The current state of the contract.
  /// @dev See the constants above for possible state values.
  uint public state;

  string public constant version = "2";
  // --- EIP712 niceties ---
  // Original source: https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f#code
  mapping (address => uint) public nonces;
  bytes32 public DOMAIN_SEPARATOR;
  // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
  bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

  modifier authorizeTransfer(
    address _from,
    address _to,
    uint _value,
    bool _isSell
  )
  {
    if(address(whitelist) != address(0))
    {
      // This is not set for the minting of initialReserve
      whitelist.authorizeTransfer(_from, _to, _value, _isSell);
    }
    _;
  }

  /**
   * Buyback reserve
   */

  /// @notice The total amount of currency value currently locked in the contract and available to sellers.
  function buybackReserve() public view returns (uint)
  {
    uint reserve = address(this).balance;
    if(address(currency) != address(0))
    {
      reserve = currency.balanceOf(address(this));
    }

    if(reserve > MAX_BEFORE_SQUARE)
    {
      /// Math: If the reserve becomes excessive, cap the value to prevent overflowing in other formulas
      return MAX_BEFORE_SQUARE;
    }

    return reserve;
  }

  /**
   * Functions required for the whitelist
   */

  function _detectTransferRestriction(
    address _from,
    address _to,
    uint _value
  ) private view
    returns (uint)
  {
    if(address(whitelist) != address(0))
    {
      // This is not set for the minting of initialReserve
      return whitelist.detectTransferRestriction(_from, _to, _value);
    }

    return 0;
  }

  /**
   * Functions required by the ERC-20 token standard
   */

  /// @dev Moves tokens from one account to another if authorized.
  function _transfer(
    address _from,
    address _to,
    uint _amount
  ) internal
    authorizeTransfer(_from, _to, _amount, false)
  {
    require(state != STATE_INIT || _from == beneficiary, "ONLY_BENEFICIARY_DURING_INIT");
    super._transfer(_from, _to, _amount);
  }

  /// @dev Removes tokens from the circulating supply.
  function _burn(
    address _from,
    uint _amount,
    bool _isSell
  ) internal
    authorizeTransfer(_from, address(0), _amount, _isSell)
  {
    super._burn(_from, _amount);

    if(!_isSell)
    {
      // This is a burn
      require(state == STATE_RUN, "ONLY_DURING_RUN");
      // SafeMath not required as we cap how high this value may get during mint
      burnedSupply += _amount;
      emit Burn(_from, _amount);
    }
  }

  /// @notice Called to mint tokens on `buy`.
  function _mint(
    address _to,
    uint _quantity
  ) internal
    authorizeTransfer(address(0), _to, _quantity, false)
  {
    super._mint(_to, _quantity);

    // Math: If this value got too large, the DAT may overflow on sell
    require(totalSupply().add(burnedSupply) <= MAX_SUPPLY, "EXCESSIVE_SUPPLY");
  }

  /**
   * Transaction Helpers
   */

  /// @notice Confirms the transfer of `_quantityToInvest` currency to the contract.
  function _collectInvestment(
    uint _quantityToInvest,
    uint _msgValue,
    bool _refundRemainder
  ) private
  {
    if(address(currency) == address(0))
    {
      // currency is ETH
      if(_refundRemainder)
      {
        // Math: if _msgValue was not sufficient then revert
        uint refund = _msgValue.sub(_quantityToInvest);
        if(refund > 0)
        {
          Address.sendValue(msg.sender, refund);
        }
      }
      else
      {
        require(_quantityToInvest == _msgValue, "INCORRECT_MSG_VALUE");
      }
    }
    else
    {
      // currency is ERC20
      require(_msgValue == 0, "DO_NOT_SEND_ETH");

      currency.safeTransferFrom(msg.sender, address(this), _quantityToInvest);
    }
  }

  /// @dev Send `_amount` currency from the contract to the `_to` account.
  function _transferCurrency(
    address payable _to,
    uint _amount
  ) private
  {
    if(_amount > 0)
    {
      if(address(currency) == address(0))
      {
        Address.sendValue(_to, _amount);
      }
      else
      {
        currency.safeTransfer(_to, _amount);
      }
    }
  }

  /**
   * Config / Control
   */

  /// @notice Called once after deploy to set the initial configuration.
  /// None of the values provided here may change once initially set.
  /// @dev using the init pattern in order to support zos upgrades
  function initialize(
    uint _initReserve,
    address _currencyAddress,
    uint _initGoal,
    uint _buySlopeNum,
    uint _buySlopeDen,
    uint _investmentReserveBasisPoints,
    string memory _name,
    string memory _symbol
  ) public
  {
    require(control == address(0), "ALREADY_INITIALIZED");

    ERC20Detailed.initialize(_name, _symbol, 18);

    // Set initGoal, which in turn defines the initial state
    if(_initGoal == 0)
    {
      emit StateChange(state, STATE_RUN);
      state = STATE_RUN;
    }
    else
    {
      // Math: If this value got too large, the DAT would overflow on sell
      require(_initGoal < MAX_SUPPLY, "EXCESSIVE_GOAL");
      initGoal = _initGoal;
    }

    require(_buySlopeNum > 0, "INVALID_SLOPE_NUM");
    require(_buySlopeDen > 0, "INVALID_SLOPE_DEN");
    require(_buySlopeNum < MAX_BEFORE_SQUARE, "EXCESSIVE_SLOPE_NUM");
    require(_buySlopeDen < MAX_BEFORE_SQUARE, "EXCESSIVE_SLOPE_DEN");
    buySlopeNum = _buySlopeNum;
    buySlopeDen = _buySlopeDen;
    // 100% or less
    require(_investmentReserveBasisPoints <= BASIS_POINTS_DEN, "INVALID_RESERVE");
    investmentReserveBasisPoints = _investmentReserveBasisPoints;

    // Set default values (which may be updated using `updateConfig`)
    minInvestment = 100 ether;
    beneficiary = msg.sender;
    control = msg.sender;
    feeCollector = msg.sender;

    // Save currency
    currency = IERC20(_currencyAddress);

    // Mint the initial reserve
    if(_initReserve > 0)
    {
      initReserve = _initReserve;
      _mint(beneficiary, initReserve);
    }

    // Initialize permit
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name())),
        keccak256(bytes(version)),
        getChainId(),
        address(this)
      )
    );
  }
  function getChainId(
  ) private pure
    returns (uint id)
  {
    // solium-disable-next-line
    assembly
    {
      id := chainid()
    }
  }

  function updateConfig(
    address _whitelistAddress,
    address payable _beneficiary,
    address _control,
    address payable _feeCollector,
    uint _feeBasisPoints,
    bool _autoBurn,
    uint _revenueCommitmentBasisPoints,
    uint _minInvestment,
    uint _openUntilAtLeast
  ) public
  {
    // This require(also confirms that initialize has been called.
    require(msg.sender == control, "CONTROL_ONLY");

    // address(0) is okay
    whitelist = IWhitelist(_whitelistAddress);

    require(_control != address(0), "INVALID_ADDRESS");
    control = _control;

    require(_feeCollector != address(0), "INVALID_ADDRESS");
    feeCollector = _feeCollector;

    autoBurn = _autoBurn;

    require(_revenueCommitmentBasisPoints <= BASIS_POINTS_DEN, "INVALID_COMMITMENT");
    require(_revenueCommitmentBasisPoints >= revenueCommitmentBasisPoints, "COMMITMENT_MAY_NOT_BE_REDUCED");
    revenueCommitmentBasisPoints = _revenueCommitmentBasisPoints;

    require(_feeBasisPoints <= BASIS_POINTS_DEN, "INVALID_FEE");
    feeBasisPoints = _feeBasisPoints;

    require(_minInvestment > 0, "INVALID_MIN_INVESTMENT");
    minInvestment = _minInvestment;

    require(_openUntilAtLeast >= openUntilAtLeast, "OPEN_UNTIL_MAY_NOT_BE_REDUCED");
    openUntilAtLeast = _openUntilAtLeast;

    if(beneficiary != _beneficiary)
    {
      require(_beneficiary != address(0), "INVALID_ADDRESS");
      uint tokens = balanceOf(beneficiary);
      initInvestors[_beneficiary] = initInvestors[_beneficiary].add(initInvestors[beneficiary]);
      initInvestors[beneficiary] = 0;
      if(tokens > 0)
      {
        _transfer(beneficiary, _beneficiary, tokens);
      }
      beneficiary = _beneficiary;
    }

    emit UpdateConfig(
      _whitelistAddress,
      _beneficiary,
      _control,
      _feeCollector,
      _autoBurn,
      _revenueCommitmentBasisPoints,
      _feeBasisPoints,
      _minInvestment,
      _openUntilAtLeast
    );
  }

  /**
   * Functions for our business logic
   */

  /// @notice Burn the amount of tokens from the address msg.sender if authorized.
  /// @dev Note that this is not the same as a `sell` via the DAT.
  function burn(
    uint _amount
  ) public
  {
    _burn(msg.sender, _amount, false);
  }

  // Buy

  /// @dev Distributes _value currency between the buybackReserve, beneficiary, and feeCollector.
  function _distributeInvestment(
    uint _value
  ) private
  {
    // Rounding favors buybackReserve, then beneficiary, and feeCollector is last priority.

    // Math: if investment value is < (2^256 - 1) / 10000 this will never overflow.
    // Except maybe with a huge single investment, but they can try again with multiple smaller investments.
    uint reserve = investmentReserveBasisPoints.mul(_value);
    reserve /= BASIS_POINTS_DEN;
    reserve = _value.sub(reserve);
    uint fee = reserve.mul(feeBasisPoints);
    fee /= BASIS_POINTS_DEN;

    // Math: since feeBasisPoints is <= BASIS_POINTS_DEN, this will never underflow.
    _transferCurrency(beneficiary, reserve - fee);
    _transferCurrency(feeCollector, fee);
  }

  /// @notice Calculate how many COT tokens you would buy with the given amount of currency if `buy` was called now.
  /// @param _currencyValue How much currency to spend in order to buy COT.
  function estimateBuyValue(
    uint _currencyValue
  ) public view
    returns (uint)
  {
    if(_currencyValue < minInvestment)
    {
      return 0;
    }

    /// Calculate the tokenValue for this investment
    uint tokenValue;
    if(state == STATE_INIT)
    {
      uint currencyValue = _currencyValue;
      uint _totalSupply = totalSupply();
      // (buy_slope*init_goal)*(init_goal+init_reserve-total_supply)/2
      // n/d: buy_slope (MAX_BEFORE_SQUARE / MAX_BEFORE_SQUARE)
      // g: init_goal (MAX_BEFORE_SQUARE/2)
      // t: total_supply (MAX_BEFORE_SQUARE/2)
      // r: init_reserve (MAX_BEFORE_SQUARE/2)
      // source: ((n/d)*g)*(g+r-t)/2
      // impl: (g n (g + r - t))/(2 d)
      uint max = BigDiv.bigDiv2x1(
        initGoal * buySlopeNum,
        initGoal + initReserve - _totalSupply,
        2 * buySlopeDen
      );
      if(currencyValue > max)
      {
        currencyValue = max;
      }
      // Math: worst case
      // MAX * 2 * MAX_BEFORE_SQUARE
      // / MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE
      tokenValue = BigDiv.bigDiv2x1(
        currencyValue,
        2 * buySlopeDen,
        initGoal * buySlopeNum
      );

      if(currencyValue != _currencyValue)
      {
        currencyValue = _currencyValue - max;
        // ((2*next_amount/buy_slope)+init_goal^2)^(1/2)-init_goal
        // a: next_amount | currencyValue
        // n/d: buy_slope (MAX_BEFORE_SQUARE / MAX_BEFORE_SQUARE)
        // g: init_goal (MAX_BEFORE_SQUARE/2)
        // r: init_reserve (MAX_BEFORE_SQUARE/2)
        // sqrt(((2*a/(n/d))+g^2)-g
        // sqrt((2 d a + n g^2)/n) - g

        // currencyValue == 2 d a
        uint temp = 2 * buySlopeDen;
        currencyValue = temp.mul(currencyValue);

        // temp == g^2
        temp = initGoal;
        temp *= temp;

        // temp == n g^2
        temp = temp.mul(buySlopeNum);

        // temp == (2 d a) + n g^2
        temp = currencyValue.add(temp);

        // temp == (2 d a + n g^2)/n
        temp /= buySlopeNum;

        // temp == sqrt((2 d a + n g^2)/n)
        temp = temp.sqrt();

        // temp == sqrt((2 d a + n g^2)/n) - g
        temp -= initGoal;

        tokenValue = tokenValue.add(temp);
      }
    }
    else if(state == STATE_RUN)
    {
      // initReserve is reduced on sell as necessary to ensure that this line will not overflow
      uint supply = totalSupply() + burnedSupply - initReserve;
      // Math: worst case
      // MAX * 2 * MAX_BEFORE_SQUARE
      // / MAX_BEFORE_SQUARE
      tokenValue = BigDiv.bigDiv2x1(
        _currencyValue,
        2 * buySlopeDen,
        buySlopeNum
      );

      // Math: worst case MAX + (MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE)
      tokenValue = tokenValue.add(supply * supply);
      tokenValue = tokenValue.sqrt();

      // Math: small chance of underflow due to possible rounding in sqrt
      tokenValue = tokenValue.sub(supply);
    }
    else
    {
      // invalid state
      return 0;
    }

    return tokenValue;
  }

  /// @notice Purchase COT tokens with the given amount of currency.
  /// @param _to The account to receive the COT tokens from this purchase.
  /// @param _currencyValue How much currency to spend in order to buy COT.
  /// @param _minTokensBought Buy at least this many COT tokens or the transaction reverts.
  /// @dev _minTokensBought is necessary as the price will change if some elses transaction mines after
  /// yours was submitted.
  function buy(
    address _to,
    uint _currencyValue,
    uint _minTokensBought
  ) public payable
  {
    require(_to != address(0), "INVALID_ADDRESS");
    require(_minTokensBought > 0, "MUST_BUY_AT_LEAST_1");

    // Calculate the tokenValue for this investment
    uint tokenValue = estimateBuyValue(_currencyValue);
    require(tokenValue >= _minTokensBought, "PRICE_SLIPPAGE");

    emit Buy(msg.sender, _to, _currencyValue, tokenValue);

    _collectInvestment(_currencyValue, msg.value, false);

    // Update state, initInvestors, and distribute the investment when appropriate
    if(state == STATE_INIT)
    {
      // Math worst case: MAX_BEFORE_SQUARE
      initInvestors[_to] += tokenValue;
      // Math worst case:
      // MAX_BEFORE_SQUARE + MAX_BEFORE_SQUARE
      if(totalSupply() + tokenValue - initReserve >= initGoal)
      {
        emit StateChange(state, STATE_RUN);
        state = STATE_RUN;
        // Math worst case:
        // MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE/2
        // / MAX_BEFORE_SQUARE * 2
        uint beneficiaryContribution = BigDiv.bigDiv2x1(
          initInvestors[beneficiary],
          buySlopeNum * initGoal,
          buySlopeDen * 2
        );
        _distributeInvestment(buybackReserve().sub(beneficiaryContribution));
      }
    }
    else // implied: if(state == STATE_RUN)
    {
      if(_to != beneficiary)
      {
        _distributeInvestment(_currencyValue);
      }
    }

    _mint(_to, tokenValue);

    if(state == STATE_RUN && msg.sender == beneficiary && _to == beneficiary && autoBurn)
    {
      // must mint before this call
      _burn(beneficiary, tokenValue, false);
    }
  }

  /// Sell

  function estimateSellValue(
    uint _quantityToSell
  ) public view
    returns(uint)
  {
    uint reserve = buybackReserve();

    // Calculate currencyValue for this sale
    uint currencyValue;
    if(state == STATE_RUN)
    {
      uint supply = totalSupply() + burnedSupply;

      // buyback_reserve = r
      // total_supply = t
      // burnt_supply = b
      // amount = a
      // source: (t+b)*a*(2*r)/((t+b)^2)-(((2*r)/((t+b)^2)*a^2)/2)+((2*r)/((t+b)^2)*a*b^2)/(2*(t))
      // imp: (a b^2 r)/(t (b + t)^2) + (2 a r)/(b + t) - (a^2 r)/(b + t)^2

      // Math: burnedSupply is capped in COT such that the square will never overflow
      // Math worst case:
      // MAX * MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE/2 * MAX_BEFORE_SQUARE/2
      // / MAX_BEFORE_SQUARE/2 * MAX_BEFORE_SQUARE/2 * MAX_BEFORE_SQUARE/2
      currencyValue = BigDiv.bigDiv2x2(
        _quantityToSell.mul(reserve),
        burnedSupply * burnedSupply,
        totalSupply(), supply * supply
      );
      // Math: worst case currencyValue is MAX_BEFORE_SQUARE (max reserve, 1 supply)

      // Math worst case:
      // MAX * 2 * MAX_BEFORE_SQUARE
      uint temp = _quantityToSell.mul(2 * reserve);
      temp /= supply;
      // Math: worst-case temp is MAX_BEFORE_SQUARE (max reserve, 1 supply)

      // Math: considering the worst-case for currencyValue and temp, this can never overflow
      currencyValue += temp;

      // Math: worst case
      // MAX * MAX * MAX_BEFORE_SQUARE
      // / MAX_BEFORE_SQUARE/2 * MAX_BEFORE_SQUARE/2
      currencyValue -= BigDiv.bigDiv2x1RoundUp(
        _quantityToSell.mul(_quantityToSell),
        reserve,
        supply * supply
      );
    }
    else if(state == STATE_CLOSE)
    {
      // Math worst case
      // MAX * MAX_BEFORE_SQUARE
      currencyValue = _quantityToSell.mul(reserve);
      currencyValue /= totalSupply();
    }
    else
    {
      // STATE_INIT or STATE_CANCEL
      // Math worst case:
      // MAX * MAX_BEFORE_SQUARE
      currencyValue = _quantityToSell.mul(reserve);
      // Math: COT blocks initReserve from being burned unless we reach the RUN state which prevents an underflow
      currencyValue /= totalSupply() - initReserve;
    }

    return currencyValue;
  }

  /// @notice Sell COT tokens for at least the given amount of currency.
  /// @param _to The account to receive the currency from this sale.
  /// @param _quantityToSell How many COT tokens to sell for currency value.
  /// @param _minCurrencyReturned Get at least this many currency tokens or the transaction reverts.
  /// @dev _minCurrencyReturned is necessary as the price will change if some elses transaction mines after
  /// yours was submitted.
  function sell(
    address payable _to,
    uint _quantityToSell,
    uint _minCurrencyReturned
  ) public
  {
    require(msg.sender != beneficiary || state >= STATE_CLOSE, "BENEFICIARY_ONLY_SELL_IN_CLOSE_OR_CANCEL");
    require(_minCurrencyReturned > 0, "MUST_SELL_AT_LEAST_1");

    uint currencyValue = estimateSellValue(_quantityToSell);
    require(currencyValue >= _minCurrencyReturned, "PRICE_SLIPPAGE");

    if(state == STATE_INIT || state == STATE_CANCEL)
    {
      initInvestors[msg.sender] = initInvestors[msg.sender].sub(_quantityToSell);
    }

    _burn(msg.sender, _quantityToSell, true);
    uint supply = totalSupply() + burnedSupply;
    if(supply < initReserve)
    {
      initReserve = supply;
    }

    _transferCurrency(_to, currencyValue);
    emit Sell(msg.sender, _to, currencyValue, _quantityToSell);
  }

  /// Pay

  function estimatePayValue(
    uint _currencyValue
  ) public view
    returns (uint)
  {
    // buy_slope = n/d
    // revenue_commitment = c/g
    // sqrt(
    //  (2 a c d)
    //  /
    //  (g n)
    //  + s^2
    // ) - s

    uint supply = totalSupply() + burnedSupply;

    // Math: worst case
    // MAX * 2 * 10000 * MAX_BEFORE_SQUARE
    // / 10000 * MAX_BEFORE_SQUARE
    uint tokenValue = BigDiv.bigDiv2x1(
      _currencyValue.mul(2 * revenueCommitmentBasisPoints),
      buySlopeDen,
      BASIS_POINTS_DEN * buySlopeNum
    );

    tokenValue = tokenValue.add(supply * supply);
    tokenValue = tokenValue.sqrt();

    if(tokenValue > supply)
    {
      tokenValue -= supply;
    }
    else
    {
      tokenValue = 0;
    }

    return tokenValue;
  }

  /// @dev Pay the organization on-chain.
  /// @param _to The account which receives tokens for the contribution.
  /// @param _currencyValue How much currency which was paid.
  function _pay(
    address _to,
    uint _currencyValue
  ) private
  {
    require(_currencyValue > 0, "MISSING_CURRENCY");
    require(state == STATE_RUN, "INVALID_STATE");

    // Send a portion of the funds to the beneficiary, the rest is added to the buybackReserve
    // Math: if _currencyValue is < (2^256 - 1) / 10000 this will not overflow
    uint reserve = _currencyValue.mul(investmentReserveBasisPoints);
    reserve /= BASIS_POINTS_DEN;

    uint tokenValue = estimatePayValue(_currencyValue);

    // Update the to address to the beneficiary if the currency value would fail
    address to = _to;
    if(to == address(0))
    {
      to = beneficiary;
    }
    else if(_detectTransferRestriction(address(0), _to, tokenValue) != 0)
    {
      to = beneficiary;
    }

    // Math: this will never underflow since investmentReserveBasisPoints is capped to BASIS_POINTS_DEN
    _transferCurrency(beneficiary, _currencyValue - reserve);

    // Distribute tokens
    if(tokenValue > 0)
    {
      _mint(to, tokenValue);
      if(to == beneficiary && autoBurn)
      {
        // must mint before this call
        _burn(beneficiary, tokenValue, false);
      }
    }

    emit Pay(msg.sender, _to, _currencyValue, tokenValue);
  }

  /// @dev Pay the organization on-chain.
  /// @param _to The account which receives tokens for the contribution. If this address
  /// is not authorized to receive tokens then they will be sent to the beneficiary account instead.
  /// @param _currencyValue How much currency which was paid.
  function pay(
    address _to,
    uint _currencyValue
  ) public payable
  {
    _collectInvestment(_currencyValue, msg.value, false);
    _pay(_to, _currencyValue);
  }

  /// @notice Pay the organization on-chain without minting any tokens.
  /// @dev This allows you to add funds directly to the buybackReserve.
  function () external payable
  {
    require(address(currency) == address(0), "ONLY_FOR_CURRENCY_ETH");
  }
  
  /// Close

  function estimateExitFee(
    uint _msgValue
  ) public view
    returns(uint)
  {
    uint exitFee;

    if(state == STATE_RUN)
    {
      uint reserve = buybackReserve();
      reserve = reserve.sub(_msgValue);

      // Source: t*(t+b)*(n/d)-r
      // Implementation: (b n t)/d + (n t^2)/d - r

      uint _totalSupply = totalSupply();

      // Math worst case:
      // MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE/2 * MAX_BEFORE_SQUARE
      exitFee = BigDiv.bigDiv2x1(
        _totalSupply,
        burnedSupply * buySlopeNum,
        buySlopeDen
      );
      // Math worst case:
      // MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE
      exitFee += BigDiv.bigDiv2x1(
        _totalSupply,
        buySlopeNum * _totalSupply,
        buySlopeDen
      );
      // Math: this if condition avoids a potential overflow
      if(exitFee <= reserve)
      {
        exitFee = 0;
      }
      else
      {
        exitFee -= reserve;
      }
    }

    return exitFee;
  }

  /// @notice Called by the beneficiary account to STATE_CLOSE or STATE_CANCEL the c-org,
  /// preventing any more tokens from being minted.
  /// @dev Requires an `exitFee` to be paid.  If the currency is ETH, include a little more than
  /// what appears to be required and any remainder will be returned to your account.  This is
  /// because another user may have a transaction mined which changes the exitFee required.
  /// For other `currency` types, the beneficiary account will be billed the exact amount required.
  function close() public payable
  {
    require(msg.sender == beneficiary, "BENEFICIARY_ONLY");

    uint exitFee = 0;

    if(state == STATE_INIT)
    {
      // Allow the org to cancel anytime if the initGoal was not reached.
      emit StateChange(state, STATE_CANCEL);
      state = STATE_CANCEL;
    }
    else if(state == STATE_RUN)
    {
      // Collect the exitFee and close the c-org.
      require(openUntilAtLeast <= block.timestamp, "TOO_EARLY");

      exitFee = estimateExitFee(msg.value);

      emit StateChange(state, STATE_CLOSE);
      state = STATE_CLOSE;

      _collectInvestment(exitFee, msg.value, true);
    }
    else
    {
      revert("INVALID_STATE");
    }

    emit Close(exitFee);
  }

  // --- Approve by signature ---
  // Original source: https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f#code
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external
  {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(PERMIT_TYPEHASH,
                    holder,
                    spender,
                    nonce,
                    expiry,
                    allowed
          )
        )
      )
    );

    require(holder != address(0), "DAT/invalid-address-0");
    require(holder == ecrecover(digest, v, r, s), "DAT/invalid-permit");
    require(expiry == 0 || now <= expiry, "DAT/permit-expired");
    require(nonce == nonces[holder]++, "DAT/invalid-nonce");
    uint wad = allowed ? uint(-1) : 0;
    _approve(holder, spender, wad);
  }
}

/// @title DXDBurnRelayer
/// @author github:AugustoL
/// @notice This smart contract has not be audited.
/// @dev Only burns DXD received
contract DXDBurnRelayer {

  DecentralizedAutonomousTrust public DXD;
  
  constructor(address payable _DXD) public {
    DXD = DecentralizedAutonomousTrust(_DXD);
  }

  function executeBurn() public {
     DXD.burn(DXD.balanceOf(address(this)));
  }
  
}