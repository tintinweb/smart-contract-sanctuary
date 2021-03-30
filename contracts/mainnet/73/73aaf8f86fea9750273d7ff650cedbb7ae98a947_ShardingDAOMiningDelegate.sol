/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// File: interfaces/DelegatorInterface.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract DelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract DelegatorInterface is DelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public virtual;
}

abstract contract DelegateInterface is DelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public virtual;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public virtual;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @uniswap/lib/contracts/libraries/FullMath.sol

pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
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

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// File: @uniswap/lib/contracts/libraries/Babylonian.sol


pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// File: @uniswap/lib/contracts/libraries/BitMath.sol

pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// File: @uniswap/lib/contracts/libraries/FixedPoint.sol

pragma solidity >=0.4.0;




// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
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

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol

pragma solidity >=0.5.0;



// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// File: interfaces/IInvitation.sol

pragma solidity 0.6.12;

interface IInvitation{

    function acceptInvitation(address _invitor) external;

    function getInvitation(address _sender) external view returns(address _invitor, address[] memory _invitees, bool _isWithdrawn);
    
}

// File: contracts/ActivityBase.sol


pragma solidity 0.6.12;



contract ActivityBase is Ownable{
    using SafeMath for uint256;

    address public admin;
    
    address public marketingFund;
    // token as the unit of measurement
    address public WETHToken;
    // invitee's supply 5% deposit weight to its invitor
    uint256 public constant INVITEE_WEIGHT = 20; 
    // invitee's supply 10% deposit weight to its invitor
    uint256 public constant INVITOR_WEIGHT = 10;

    // The block number when SHARD mining starts.
    uint256 public startBlock;

    // dev fund
    uint256 public userDividendWeight;
    uint256 public devDividendWeight;
    address public developerDAOFund;

    // deposit limit
    uint256 public amountFeeRateNumerator;
    uint256 public amountfeeRateDenominator;

    // contract sender fee rate
    uint256 public contractFeeRateNumerator;
    uint256 public contractFeeRateDenominator;

    // Info of each user is Contract sender
    mapping (uint256 => mapping (address => bool)) public isUserContractSender;
    mapping (uint256 => uint256) public poolTokenAmountLimit;

    function setDividendWeight(uint256 _userDividendWeight, uint256 _devDividendWeight) external virtual{
        checkAdmin();
        require(
            _userDividendWeight != 0 && _devDividendWeight != 0,
            "invalid input"
        );
        userDividendWeight = _userDividendWeight;
        devDividendWeight = _devDividendWeight;
    }

    function setDeveloperDAOFund(address _developerDAOFund) external virtual onlyOwner {
        developerDAOFund = _developerDAOFund;
    }

    function setTokenAmountLimit(uint256 _pid, uint256 _tokenAmountLimit) external virtual {
        checkAdmin();
        poolTokenAmountLimit[_pid] = _tokenAmountLimit;
    }

    function setTokenAmountLimitFeeRate(uint256 _feeRateNumerator, uint256 _feeRateDenominator) external virtual {
        checkAdmin();
        require(
            _feeRateDenominator >= _feeRateNumerator, "invalid input"
        );
        amountFeeRateNumerator = _feeRateNumerator;
        amountfeeRateDenominator = _feeRateDenominator;
    }

    function setContracSenderFeeRate(uint256 _feeRateNumerator, uint256 _feeRateDenominator) external virtual {
        checkAdmin();
        require(
            _feeRateDenominator >= _feeRateNumerator, "invalid input"
        );
        contractFeeRateNumerator = _feeRateNumerator;
        contractFeeRateDenominator = _feeRateDenominator;
    }

    function setStartBlock(uint256 _startBlock) external virtual onlyOwner { 
        require(startBlock > block.number, "invalid start block");
        startBlock = _startBlock;
        updateAfterModifyStartBlock(_startBlock);
    }

    function transferAdmin(address _admin) external virtual {
        checkAdmin();
        admin = _admin;
    }

    function setMarketingFund(address _marketingFund) external virtual onlyOwner {
        marketingFund = _marketingFund;
    }

    function updateAfterModifyStartBlock(uint256 _newStartBlock) internal virtual{
    }

    function calculateDividend(uint256 _pending, uint256 _pid, uint256 _userAmount, bool _isContractSender) internal view returns (uint256 _marketingFundDividend, uint256 _devDividend, uint256 _userDividend){
        uint256 fee = 0;
        if(_isContractSender && contractFeeRateDenominator > 0){
            fee = _pending.mul(contractFeeRateNumerator).div(contractFeeRateDenominator);
            _marketingFundDividend = _marketingFundDividend.add(fee);
            _pending = _pending.sub(fee);
        }
        if(poolTokenAmountLimit[_pid] > 0 && amountfeeRateDenominator > 0 && _userAmount >= poolTokenAmountLimit[_pid]){
            fee = _pending.mul(amountFeeRateNumerator).div(amountfeeRateDenominator);
            _marketingFundDividend =_marketingFundDividend.add(fee);
            _pending = _pending.sub(fee);
        }
        if(devDividendWeight > 0){
            fee = _pending.mul(devDividendWeight).div(devDividendWeight.add(userDividendWeight));
            _devDividend = _devDividend.add(fee);
            _pending = _pending.sub(fee);
        }
        _userDividend = _pending;
    }

    function judgeContractSender(uint256 _pid) internal {
        if(msg.sender != tx.origin){
            isUserContractSender[_pid][msg.sender] = true;
        }
    }

    function checkAdmin() internal view {
        require(admin == msg.sender, "invalid authorized");
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/SHDToken.sol


pragma solidity 0.6.12;






// SHDToken with Governance.
contract SHDToken is ERC20("ShardingDAO", "SHD"), Ownable {
    // cross chain
    mapping(address => bool) public minters;

    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }
    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint256) public numCheckpoints;
    event VotesBalanceChanged(
        address indexed user,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public {
        require(minters[msg.sender] == true, "SHD : You are not the miner");
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function addMiner(address _miner) external onlyOwner {
        minters[_miner] = true;
    }

    function removeMiner(address _miner) external onlyOwner {
        minters[_miner] = false;
    }

    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "getPriorVotes: not yet determined"
        );

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _voteTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint256 fromNum = numCheckpoints[from];
                uint256 fromOld =
                    fromNum > 0 ? checkpoints[from][fromNum - 1].votes : 0;
                uint256 fromNew = fromOld.sub(amount);
                _writeCheckpoint(from, fromNum, fromOld, fromNew);
            }

            if (to != address(0)) {
                uint256 toNum = numCheckpoints[to];
                uint256 toOld =
                    toNum > 0 ? checkpoints[to][toNum - 1].votes : 0;
                uint256 toNew = toOld.add(amount);
                _writeCheckpoint(to, toNum, toOld, toNew);
            }
        }
    }

    function _writeCheckpoint(
        address user,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint256 blockNumber = block.number;
        if (
            nCheckpoints > 0 &&
            checkpoints[user][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[user][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[user][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[user] = nCheckpoints + 1;
        }

        emit VotesBalanceChanged(user, oldVotes, newVotes);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _voteTransfer(from, to, amount);
    }
}

// File: contracts/ShardingDAOMining.sol


pragma solidity 0.6.12;











contract ShardingDAOMining is IInvitation, ActivityBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20; 
    using FixedPoint for *;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How much LP token the user has provided.
        uint256 originWeight; //initial weight
        uint256 inviteeWeight; // invitees' weight
        uint256 endBlock;
        bool isCalculateInvitation;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 nftPoolId;
        address lpTokenSwap; // uniswapPair contract address
        uint256 accumulativeDividend;
        uint256 usersTotalWeight; // user's sum weight
        uint256 lpTokenAmount; // lock amount
        uint256 oracleWeight; // eth value
        uint256 lastDividendHeight; // last dividend block height
        TokenPairInfo tokenToEthPairInfo;
        bool isFirstTokenShard;
    }

    struct TokenPairInfo{
        IUniswapV2Pair tokenToEthSwap; 
        FixedPoint.uq112x112 price; 
        bool isFirstTokenEth;
        uint256 priceCumulativeLast;
        uint32  blockTimestampLast;
        uint256 lastPriceUpdateHeight;
    }

    struct InvitationInfo {
        address invitor;
        address[] invitees;
        bool isUsed;
        bool isWithdrawn;
        mapping(address => uint256) inviteeIndexMap;
    }

    // black list
    struct EvilPoolInfo {
        uint256 pid;
        string description;
    }

    // The SHD TOKEN!
    SHDToken public SHD;
    // Info of each pool.
    uint256[] public rankPoolIndex;
    // indicates whether the pool is in the rank
    mapping(uint256 => uint256) public rankPoolIndexMap;
    // relationship info about invitation
    mapping(address => InvitationInfo) public usersRelationshipInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Info of each pool.
    PoolInfo[] private poolInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public maxRankNumber = 10;
    // Last block number that SHARDs distribution occurs.
    uint256 public lastRewardBlock;
    // produced blocks per day
    uint256 public constant produceBlocksPerDay = 6496;
    // produced blocks per month
    uint256 public constant produceBlocksPerMonth = produceBlocksPerDay * 30;
    // SHD tokens created per block.
    uint256 public SHDPerBlock = 104994 * (1e13);
    // after each term, mine half SHD token
    uint256 public constant MINT_DECREASE_TERM = 9500000;
    // used to caculate user deposit weight
    uint256[] private depositTimeWeight;
    // max lock time in stage two
    uint256 private constant MAX_MONTH = 36;
    // add pool automatically in nft shard
    address public nftShard;
    // oracle token price update term
    uint256 public updateTokenPriceTerm = 120;
    // to mint token cross chain
    uint256 public shardMintWeight = 1;
    uint256 public reserveMintWeight = 0;
    uint256 public reserveToMint;
    // black list
    EvilPoolInfo[] public blackList;
    mapping(uint256 => uint256) public blackListMap;
    // undividend shard
    uint256 public unDividendShard;
    // 20% shard => SHD - ETH pool
    uint256 public shardPoolDividendWeight = 2;
    // 80% shard => SHD - ETH pool
    uint256 public otherPoolDividendWeight = 8;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 weight
    );
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Replace(
        address indexed user,
        uint256 indexed rankIndex,
        uint256 newPid
    );

    event AddToBlacklist(
        uint256 indexed pid
    );

    event RemoveFromBlacklist(
        uint256 indexed pid
    );
    event AddPool(uint256 indexed pid, uint256 nftId, address tokenAddress);

    function initialize(
        SHDToken _SHD,
        address _wethToken,
        address _developerDAOFund,
        address _marketingFund,
        uint256 _maxRankNumber,
        uint256 _startBlock
    ) public virtual onlyOwner{
        require(WETHToken == address(0), "already initialized");
        SHD = _SHD;
        maxRankNumber = _maxRankNumber;
        if (_startBlock < block.number) {
            startBlock = block.number;
        } else {
            startBlock = _startBlock;
        }
        lastRewardBlock = startBlock.sub(1);
        WETHToken = _wethToken;
        initializeTimeWeight();
        developerDAOFund = _developerDAOFund;
        marketingFund = _marketingFund;
        InvitationInfo storage initialInvitor =
            usersRelationshipInfo[address(this)];

        userDividendWeight = 8;
        devDividendWeight = 2;

        amountFeeRateNumerator = 0;
        amountfeeRateDenominator = 0;

        contractFeeRateNumerator = 1;
        contractFeeRateDenominator = 5;
        initialInvitor.isUsed = true;
    }

    function initializeTimeWeight() private {
        depositTimeWeight = [
            1238,
            1383,
            1495,
            1587,
            1665,
            1732,
            1790,
            1842,
            1888,
            1929,
            1966,
            2000,
            2031,
            2059,
            2085,
            2108,
            2131,
            2152,
            2171,
            2189,
            2206,
            2221,
            2236,
            2250,
            2263,
            2276,
            2287,
            2298,
            2309,
            2319,
            2328,
            2337,
            2346,
            2355,
            2363,
            2370
        ];
    }

    function setNftShard(address _nftShard) external virtual {
        checkAdmin();
        nftShard = _nftShard;
    }

    // Add a new lp to the pool. Can only be called by the nft shard contract.
    // if _lpTokenSwap contains tokenA instead of eth, then _tokenToEthSwap should consist of token A and eth
    function add(
        uint256 _nftPoolId,
        IUniswapV2Pair _lpTokenSwap,
        IUniswapV2Pair _tokenToEthSwap
    ) external virtual {
        require(msg.sender == nftShard || msg.sender == admin, "invalid sender");
        TokenPairInfo memory tokenToEthInfo;
        uint256 lastDividendHeight = 0;
        if(poolInfo.length == 0){
            _nftPoolId = 0;
            lastDividendHeight = lastRewardBlock;
        }
        bool isFirstTokenShard;
        if (address(_tokenToEthSwap) != address(0)) {
            (address token0, address token1, uint256 targetTokenPosition) =
                getTargetTokenInSwap(_tokenToEthSwap, WETHToken);
            address wantToken;
            bool isFirstTokenEthToken;
            if (targetTokenPosition == 0) {
                isFirstTokenEthToken = true;
                wantToken = token1;
            } else {
                isFirstTokenEthToken = false;
                wantToken = token0;
            }
            (, , targetTokenPosition) = getTargetTokenInSwap(
                _lpTokenSwap,
                wantToken
            );
            if (targetTokenPosition == 0) {
                isFirstTokenShard = false;
            } else {
                isFirstTokenShard = true;
            }
            tokenToEthInfo = generateOrcaleInfo(
                _tokenToEthSwap,
                isFirstTokenEthToken
            );
        } else {
            (, , uint256 targetTokenPosition) =
                getTargetTokenInSwap(_lpTokenSwap, WETHToken);
            if (targetTokenPosition == 0) {
                isFirstTokenShard = false;
            } else {
                isFirstTokenShard = true;
            }
            tokenToEthInfo = generateOrcaleInfo(
                _lpTokenSwap,
                !isFirstTokenShard
            );
        }
        poolInfo.push(
            PoolInfo({
                nftPoolId: _nftPoolId,
                lpTokenSwap: address(_lpTokenSwap),
                lpTokenAmount: 0,
                usersTotalWeight: 0,
                accumulativeDividend: 0,
                oracleWeight: 0,
                lastDividendHeight: lastDividendHeight,
                tokenToEthPairInfo: tokenToEthInfo,
                isFirstTokenShard: isFirstTokenShard
            })
        );
        emit AddPool(poolInfo.length.sub(1), _nftPoolId, address(_lpTokenSwap));
    }

    function setPriceUpdateTerm(uint256 _term) external virtual onlyOwner{
        updateTokenPriceTerm = _term;
    }

    function kickEvilPoolByPid(uint256 _pid, string calldata description)
        external
        virtual
        onlyOwner
    {
        bool isDescriptionLeagal = verifyDescription(description);
        require(isDescriptionLeagal, "invalid description, just ASCII code is allowed");
        require(_pid > 0, "invalid pid");
        uint256 poolRankIndex = rankPoolIndexMap[_pid];
        if (poolRankIndex > 0) {
            massUpdatePools();
            uint256 _rankIndex = poolRankIndex.sub(1);
            uint256 currentRankLastIndex = rankPoolIndex.length.sub(1);
            uint256 lastPidInRank = rankPoolIndex[currentRankLastIndex];
            rankPoolIndex[_rankIndex] = lastPidInRank;
            rankPoolIndexMap[lastPidInRank] = poolRankIndex;
            delete rankPoolIndexMap[_pid];
            rankPoolIndex.pop();
        }
        addInBlackList(_pid, description);
        dealEvilPoolDiviend(_pid);
        emit AddToBlacklist(_pid);
    }

    function addInBlackList(uint256 _pid, string calldata description) private {
        if (blackListMap[_pid] > 0) {
            return;
        }
        blackList.push(EvilPoolInfo({pid: _pid, description: description}));
        blackListMap[_pid] = blackList.length;
    }

    function resetEvilPool(uint256 _pid) external virtual onlyOwner {
        uint256 poolPosition = blackListMap[_pid];
        if (poolPosition == 0) {
            return;
        }
        uint256 poolIndex = poolPosition.sub(1);
        uint256 lastIndex = blackList.length.sub(1);
        EvilPoolInfo storage lastEvilInBlackList = blackList[lastIndex];
        uint256 lastPidInBlackList = lastEvilInBlackList.pid;
        blackListMap[lastPidInBlackList] = poolPosition;
        blackList[poolIndex] = blackList[lastIndex];
        delete blackListMap[_pid];
        blackList.pop();
        emit RemoveFromBlacklist(_pid);
    }

    function dealEvilPoolDiviend(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 undistributeDividend = pool.accumulativeDividend;
        if (undistributeDividend == 0) {
            return;
        }
        uint256 currentRankCount = rankPoolIndex.length;
        if (currentRankCount > 0) {
            uint256 averageDividend =
                undistributeDividend.div(currentRankCount);
            for (uint256 i = 0; i < currentRankCount; i++) {
                PoolInfo storage poolInRank = poolInfo[rankPoolIndex[i]];
                if (i < currentRankCount - 1) {
                    poolInRank.accumulativeDividend = poolInRank
                        .accumulativeDividend
                        .add(averageDividend);
                    undistributeDividend = undistributeDividend.sub(
                        averageDividend
                    );
                } else {
                    poolInRank.accumulativeDividend = poolInRank
                        .accumulativeDividend
                        .add(undistributeDividend);
                }
            }
        } else {
            unDividendShard = unDividendShard.add(undistributeDividend);
        }
        pool.accumulativeDividend = 0;
    }

    function setMintCoefficient(
        uint256 _shardMintWeight,
        uint256 _reserveMintWeight
    ) external virtual {
        checkAdmin();
        require(
            _shardMintWeight != 0 && _reserveMintWeight != 0,
            "invalid input"
        );
        massUpdatePools();
        shardMintWeight = _shardMintWeight;
        reserveMintWeight = _reserveMintWeight;
    }

    function setShardPoolDividendWeight(
        uint256 _shardPoolWeight,
        uint256 _otherPoolWeight
    ) external virtual {
        checkAdmin();
        require(
            _shardPoolWeight != 0 && _otherPoolWeight != 0,
            "invalid input"
        );
        massUpdatePools();
        shardPoolDividendWeight = _shardPoolWeight;
        otherPoolDividendWeight = _otherPoolWeight;
    }

    function setSHDPerBlock(uint256 _SHDPerBlock, bool _withUpdate) external virtual {
        checkAdmin();
        if (_withUpdate) {
            massUpdatePools();
        }
        SHDPerBlock = _SHDPerBlock;
    }

    function massUpdatePools() public virtual {
        uint256 poolCountInRank = rankPoolIndex.length;
        uint256 farmMintShard = mintSHARD(address(this), block.number);
        updateSHARDPoolAccumulativeDividend(block.number);
        if(poolCountInRank == 0){
            farmMintShard = farmMintShard.mul(otherPoolDividendWeight)
                                     .div(shardPoolDividendWeight.add(otherPoolDividendWeight));
            if(farmMintShard > 0){
                unDividendShard = unDividendShard.add(farmMintShard);
            }
        }
        for (uint256 i = 0; i < poolCountInRank; i++) {
            updatePoolAccumulativeDividend(
                rankPoolIndex[i],
                poolCountInRank,
                block.number
            );
        }
    }

    // update reward vairables for a pool
    function updatePoolDividend(uint256 _pid) public virtual {
        if(_pid == 0){
            updateSHARDPoolAccumulativeDividend(block.number);
            return;
        }
        if (rankPoolIndexMap[_pid] == 0) {
            return;
        }
        updatePoolAccumulativeDividend(
            _pid,
            rankPoolIndex.length,
            block.number
        );
    }

    function mintSHARD(address _address, uint256 _toBlock) private returns (uint256){
        uint256 recentlyRewardBlock = lastRewardBlock;
        if (recentlyRewardBlock >= _toBlock) {
            return 0;
        }
        uint256 totalReward =
            getRewardToken(recentlyRewardBlock.add(1), _toBlock);
        uint256 farmMint =
            totalReward.mul(shardMintWeight).div(
                reserveMintWeight.add(shardMintWeight)
            );
        uint256 reserve = totalReward.sub(farmMint);
        if (totalReward > 0) {
            SHD.mint(_address, farmMint);
            if (reserve > 0) {
                reserveToMint = reserveToMint.add(reserve);
            }
            lastRewardBlock = _toBlock;
        }
        return farmMint;
    }

    function updatePoolAccumulativeDividend(
        uint256 _pid,
        uint256 _validRankPoolCount,
        uint256 _toBlock
    ) private {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.lastDividendHeight >= _toBlock) return;
        uint256 poolReward =
            getModifiedRewardToken(pool.lastDividendHeight.add(1), _toBlock)
                                    .mul(otherPoolDividendWeight)
                                    .div(shardPoolDividendWeight.add(otherPoolDividendWeight));

        uint256 otherPoolReward = poolReward.div(_validRankPoolCount);                            
        pool.lastDividendHeight = _toBlock;
        uint256 existedDividend = pool.accumulativeDividend;
        pool.accumulativeDividend = existedDividend.add(otherPoolReward);
    }

    function updateSHARDPoolAccumulativeDividend (uint256 _toBlock) private{
        PoolInfo storage pool = poolInfo[0];
        if (pool.lastDividendHeight >= _toBlock) return;
        uint256 poolReward =
            getModifiedRewardToken(pool.lastDividendHeight.add(1), _toBlock);

        uint256 shardPoolDividend = poolReward.mul(shardPoolDividendWeight)
                                               .div(shardPoolDividendWeight.add(otherPoolDividendWeight));                              
        pool.lastDividendHeight = _toBlock;
        uint256 existedDividend = pool.accumulativeDividend;
        pool.accumulativeDividend = existedDividend.add(shardPoolDividend);
    }

    // deposit LP tokens to MasterChef for SHD allocation.
    // ignore lockTime in stage one
    function deposit(
        uint256 _pid,
        uint256 _amount,
        uint256 _lockTime
    ) external virtual {
        require(_amount > 0, "invalid deposit amount");
        InvitationInfo storage senderInfo = usersRelationshipInfo[msg.sender];
        require(senderInfo.isUsed, "must accept an invitation firstly");
        require(_lockTime > 0 && _lockTime <= 36, "invalid lock time"); // less than 36 months
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpTokenAmount = pool.lpTokenAmount.add(_amount);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 newOriginWeight = user.originWeight;
        uint256 existedAmount = user.amount;
        uint256 endBlock = user.endBlock;
        uint256 newEndBlock =
            block.number.add(produceBlocksPerMonth.mul(_lockTime));
        if (existedAmount > 0) {
            if (block.number >= endBlock) {
                newOriginWeight = getDepositWeight(
                    _amount.add(existedAmount),
                    _lockTime
                );
            } else {
                newOriginWeight = newOriginWeight.add(getDepositWeight(_amount, _lockTime));
                newOriginWeight = newOriginWeight.add(
                    getDepositWeight(
                        existedAmount,
                        newEndBlock.sub(endBlock).div(produceBlocksPerMonth)
                    )
                );
            }
        } else {
            judgeContractSender(_pid);
            newOriginWeight = getDepositWeight(_amount, _lockTime);
        }
        modifyWeightByInvitation(
            _pid,
            msg.sender,
            user.originWeight,
            newOriginWeight,
            user.inviteeWeight,
            existedAmount
        );   
        updateUserInfo(
            user,
            existedAmount.add(_amount),
            newOriginWeight,
            newEndBlock
        );
        IERC20(pool.lpTokenSwap).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        pool.oracleWeight =  getOracleWeight(pool, lpTokenAmount);
        pool.lpTokenAmount = lpTokenAmount;
        if (
            rankPoolIndexMap[_pid] == 0 &&
            rankPoolIndex.length < maxRankNumber &&
            blackListMap[_pid] == 0
        ) {
            addToRank(pool, _pid);
        }
        emit Deposit(msg.sender, _pid, _amount, newOriginWeight);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid) external virtual {
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        require(amount > 0, "user is not existed");
        require(user.endBlock < block.number, "token is still locked");
        mintSHARD(address(this), block.number);
        updatePoolDividend(_pid);
        uint256 originWeight = user.originWeight;
        PoolInfo storage pool = poolInfo[_pid];
        uint256 usersTotalWeight = pool.usersTotalWeight;
        uint256 userWeight = user.inviteeWeight.add(originWeight);
        if(user.isCalculateInvitation){
            userWeight = userWeight.add(originWeight.div(INVITOR_WEIGHT));
        }
        if (pool.accumulativeDividend > 0) {
            uint256 pending = pool.accumulativeDividend.mul(userWeight).div(usersTotalWeight);
            pool.accumulativeDividend = pool.accumulativeDividend.sub(pending);
            uint256 treasruyDividend;
            uint256 devDividend;
            (treasruyDividend, devDividend, pending) = calculateDividend(pending, _pid, amount, isUserContractSender[_pid][msg.sender]);
            if(treasruyDividend > 0){
                safeSHARDTransfer(marketingFund, treasruyDividend);
            }
            if(devDividend > 0){
                safeSHARDTransfer(developerDAOFund, devDividend);
            }
            if(pending > 0){
                safeSHARDTransfer(msg.sender, pending);
            }
        }
        pool.usersTotalWeight = usersTotalWeight.sub(userWeight);
        user.amount = 0;
        user.originWeight = 0;
        user.endBlock = 0;
        IERC20(pool.lpTokenSwap).safeTransfer(address(msg.sender), amount);
        pool.lpTokenAmount = pool.lpTokenAmount.sub(amount);
        if (pool.lpTokenAmount == 0) pool.oracleWeight = 0;
        else {
            pool.oracleWeight = getOracleWeight(pool, pool.lpTokenAmount);
        }
        resetInvitationRelationship(_pid, msg.sender, originWeight);
        emit Withdraw(msg.sender, _pid, amount);
    }

    function addToRank(
        PoolInfo storage _pool,
        uint256 _pid
    ) private {
        if(_pid == 0){
            return;
        }
        massUpdatePools();
        _pool.lastDividendHeight = block.number;
        rankPoolIndex.push(_pid);
        rankPoolIndexMap[_pid] = rankPoolIndex.length;
        if(unDividendShard > 0){
            _pool.accumulativeDividend = _pool.accumulativeDividend.add(unDividendShard);
            unDividendShard = 0;
        }
        emit Replace(msg.sender, rankPoolIndex.length.sub(1), _pid);
        return;
    }

    //_poolIndexInRank is the index in rank
    //_pid is the index in poolInfo
    function tryToReplacePoolInRank(uint256 _poolIndexInRank, uint256 _pid)
        external
        virtual
    {
        if(_pid == 0){
            return;
        }
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.lpTokenAmount > 0, "there is not any lp token depsoited");
        require(blackListMap[_pid] == 0, "pool is in the black list");
        if (rankPoolIndexMap[_pid] > 0) {
            return;
        }
        uint256 currentPoolCountInRank = rankPoolIndex.length;
        require(currentPoolCountInRank == maxRankNumber, "invalid operation");
        uint256 targetPid = rankPoolIndex[_poolIndexInRank];
        PoolInfo storage targetPool = poolInfo[targetPid];
        uint256 targetPoolOracleWeight = getOracleWeight(targetPool, targetPool.lpTokenAmount);
        uint256 challengerOracleWeight = getOracleWeight(pool, pool.lpTokenAmount);
        if (challengerOracleWeight <= targetPoolOracleWeight) {
            return;
        }
        updatePoolDividend(targetPid);
        rankPoolIndex[_poolIndexInRank] = _pid;
        delete rankPoolIndexMap[targetPid];
        rankPoolIndexMap[_pid] = _poolIndexInRank.add(1);
        pool.lastDividendHeight = block.number;
        emit Replace(msg.sender, _poolIndexInRank, _pid);
    }

    function acceptInvitation(address _invitor) external virtual override {
        require(_invitor != msg.sender, "invitee should not be invitor");
        buildInvitation(_invitor, msg.sender);
    }

    function buildInvitation(address _invitor, address _invitee) private {
        InvitationInfo storage invitee = usersRelationshipInfo[_invitee];
        require(!invitee.isUsed, "has accepted invitation");
        invitee.isUsed = true;
        InvitationInfo storage invitor = usersRelationshipInfo[_invitor];
        require(invitor.isUsed, "invitor has not acceptted invitation");
        invitee.invitor = _invitor;
        invitor.invitees.push(_invitee);
        invitor.inviteeIndexMap[_invitee] = invitor.invitees.length.sub(1);
    }

    function setMaxRankNumber(uint256 _count) external virtual {
        checkAdmin();
        require(_count > 0, "invalid count");
        if (maxRankNumber == _count) return;
        massUpdatePools();
        maxRankNumber = _count;
        uint256 currentPoolCountInRank = rankPoolIndex.length;
        if (_count >= currentPoolCountInRank) {
            return;
        }
        uint256 sparePoolCount = currentPoolCountInRank.sub(_count);
        uint256 lastPoolIndex = currentPoolCountInRank.sub(1);
        while (sparePoolCount > 0) {
            delete rankPoolIndexMap[rankPoolIndex[lastPoolIndex]];
            rankPoolIndex.pop();
            lastPoolIndex--;
            sparePoolCount--;
        }
    }

    function getModifiedRewardToken(uint256 _fromBlock, uint256 _toBlock)
        private
        view
        returns (uint256)
    {
        return
            getRewardToken(_fromBlock, _toBlock).mul(shardMintWeight).div(
                reserveMintWeight.add(shardMintWeight)
            );
    }

    // View function to see pending SHARDs on frontend.
    function pendingSHARDByPids(uint256[] memory _pids, address _user)
        external
        view
        virtual
        returns (uint256[] memory _pending, uint256[] memory _potential, uint256 _blockNumber)
    {
         uint256 poolCount = _pids.length;
        _pending = new uint256[](poolCount);
        _potential = new uint256[](poolCount);
        _blockNumber = block.number;
        for(uint i = 0; i < poolCount; i ++){
            (_pending[i], _potential[i]) = calculatePendingSHARD(_pids[i], _user);
        }
    }

    function calculatePendingSHARD(uint256 _pid, address _user) private view returns (uint256 _pending, uint256 _potential){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        if (user.amount == 0) {
            return (0, 0);
        }
        uint256 userModifiedWeight = getUserModifiedWeight(_pid, _user);
        _pending = pool.accumulativeDividend.mul(userModifiedWeight);
        _pending = _pending.div(pool.usersTotalWeight);
        bool isContractSender = isUserContractSender[_pid][_user];
        (,,_pending) = calculateDividend(_pending, _pid, user.amount, isContractSender);
        if (pool.lastDividendHeight >= block.number) {
            return (_pending, 0);
        }
        if (_pid != 0 && (rankPoolIndex.length == 0 || rankPoolIndexMap[_pid] == 0)) {
            return (_pending, 0);
        }
        uint256 poolReward = getModifiedRewardToken(pool.lastDividendHeight.add(1), block.number);
        uint256 numerator;
        uint256 denominator = otherPoolDividendWeight.add(shardPoolDividendWeight);
        if(_pid == 0){
            numerator = shardPoolDividendWeight;
        }
        else{
            numerator = otherPoolDividendWeight;
        }
        poolReward = poolReward       
            .mul(numerator)
            .div(denominator);
        if(_pid != 0){
            poolReward = poolReward.div(rankPoolIndex.length);
        }                          
        _potential = poolReward
            .mul(userModifiedWeight)
            .div(pool.usersTotalWeight);
        (,,_potential) = calculateDividend(_potential, _pid, user.amount, isContractSender);
    }

    //calculate the weight and end block when users deposit
    function getDepositWeight(uint256 _lockAmount, uint256 _lockTime)
        private
        view
        returns (uint256)
    {
        if (_lockTime == 0) return 0;
        if (_lockTime.div(MAX_MONTH) > 1) _lockTime = MAX_MONTH;
        return depositTimeWeight[_lockTime.sub(1)].sub(500).mul(_lockAmount);
    }

    function getPoolLength() external view virtual returns (uint256) {
        return poolInfo.length;
    }

    function getPagePoolInfo(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        virtual
        returns (
            uint256[] memory _nftPoolId,
            uint256[] memory _accumulativeDividend,
            uint256[] memory _usersTotalWeight,
            uint256[] memory _lpTokenAmount,
            uint256[] memory _oracleWeight,
            address[] memory _swapAddress
        )
    {
        uint256 poolCount = _toIndex.sub(_fromIndex).add(1);
        _nftPoolId = new uint256[](poolCount);
        _accumulativeDividend = new uint256[](poolCount);
        _usersTotalWeight = new uint256[](poolCount);
        _lpTokenAmount = new uint256[](poolCount);
        _oracleWeight = new uint256[](poolCount);
        _swapAddress = new address[](poolCount);
        uint256 startIndex = 0;
        for (uint256 i = _fromIndex; i <= _toIndex; i++) {
            PoolInfo storage pool = poolInfo[i];
            _nftPoolId[startIndex] = pool.nftPoolId;
            _accumulativeDividend[startIndex] = pool.accumulativeDividend;
            _usersTotalWeight[startIndex] = pool.usersTotalWeight;
            _lpTokenAmount[startIndex] = pool.lpTokenAmount;
            _oracleWeight[startIndex] = pool.oracleWeight;
            _swapAddress[startIndex] = pool.lpTokenSwap;
            startIndex++;
        }
    }

    function getInstantPagePoolInfo(uint256 _fromIndex, uint256 _toIndex)
    external
    virtual
    returns (
        uint256[] memory _nftPoolId,
        uint256[] memory _accumulativeDividend,
        uint256[] memory _usersTotalWeight,
        uint256[] memory _lpTokenAmount,
        uint256[] memory _oracleWeight,
        address[] memory _swapAddress
    )
    {
        uint256 poolCount = _toIndex.sub(_fromIndex).add(1);
        _nftPoolId = new uint256[](poolCount);
        _accumulativeDividend = new uint256[](poolCount);
        _usersTotalWeight = new uint256[](poolCount);
        _lpTokenAmount = new uint256[](poolCount);
        _oracleWeight = new uint256[](poolCount);
        _swapAddress = new address[](poolCount);
        uint256 startIndex = 0;
        for (uint256 i = _fromIndex; i <= _toIndex; i++) {
            PoolInfo storage pool = poolInfo[i];
            _nftPoolId[startIndex] = pool.nftPoolId;
            _accumulativeDividend[startIndex] = pool.accumulativeDividend;
            _usersTotalWeight[startIndex] = pool.usersTotalWeight;
            _lpTokenAmount[startIndex] = pool.lpTokenAmount;
            _oracleWeight[startIndex] = getOracleWeight(pool, _lpTokenAmount[startIndex]);
            _swapAddress[startIndex] = pool.lpTokenSwap;
            startIndex++;
        }
    }

    function getRankList() external view virtual returns (uint256[] memory) {
        uint256[] memory rankIdList = rankPoolIndex;
        return rankIdList;
    }

    function getBlackList()
        external
        view
        virtual
        returns (EvilPoolInfo[] memory _blackList)
    {
        _blackList = blackList;
    }

    function getInvitation(address _sender)
        external
        view
        virtual
        override
        returns (
            address _invitor,
            address[] memory _invitees,
            bool _isWithdrawn
        )
    {
        InvitationInfo storage invitation = usersRelationshipInfo[_sender];
        _invitees = invitation.invitees;
        _invitor = invitation.invitor;
        _isWithdrawn = invitation.isWithdrawn;
    }

    function getUserInfo(uint256 _pid, address _user)
        private
        view
        returns (
            uint256 _amount,
            uint256 _originWeight,
            uint256 _modifiedWeight,
            uint256 _endBlock
        )
    {
        UserInfo storage user = userInfo[_pid][_user];
        _amount = user.amount;
        _originWeight = user.originWeight;
        _modifiedWeight = getUserModifiedWeight(_pid, _user);
        _endBlock = user.endBlock;
    }

    function getUserInfoByPids(uint256[] memory _pids, address _user)
        external
        view
        virtual
        returns (
            uint256[] memory _amount,
            uint256[] memory _originWeight,
            uint256[] memory _modifiedWeight,
            uint256[] memory _endBlock
        )
    {
        uint256 poolCount = _pids.length;
        _amount = new uint256[](poolCount);
        _originWeight = new uint256[](poolCount);
        _modifiedWeight = new uint256[](poolCount);
        _endBlock = new uint256[](poolCount);
        for(uint i = 0; i < poolCount; i ++){
            (_amount[i], _originWeight[i], _modifiedWeight[i], _endBlock[i]) = getUserInfo(_pids[i], _user);
        }
    }

    // Safe SHD transfer function, just in case if rounding error causes pool to not have enough SHARDs.
    function safeSHARDTransfer(address _to, uint256 _amount) internal {
        uint256 SHARDBal = SHD.balanceOf(address(this));
        if (_amount > SHARDBal) {
            SHD.transfer(_to, SHARDBal);
        } else {
            SHD.transfer(_to, _amount);
        }
    }

    function updateUserInfo(
        UserInfo storage _user,
        uint256 _amount,
        uint256 _originWeight,
        uint256 _endBlock
    ) private {
        _user.amount = _amount;
        _user.originWeight = _originWeight;
        _user.endBlock = _endBlock;
    }

    function getOracleWeight(
        PoolInfo storage _pool,
        uint256 _amount
    ) private returns (uint256 _oracleWeight) {
        _oracleWeight = calculateOracleWeight(_pool, _amount);
        _pool.oracleWeight = _oracleWeight;
    }

    function calculateOracleWeight(PoolInfo storage _pool, uint256 _amount)
        private
        returns (uint256 _oracleWeight)
    {
        uint256 lpTokenTotalSupply =
            IUniswapV2Pair(_pool.lpTokenSwap).totalSupply();
        (uint112 shardReserve, uint112 wantTokenReserve, ) =
            IUniswapV2Pair(_pool.lpTokenSwap).getReserves();
        if (_amount == 0) {
            _amount = _pool.lpTokenAmount;
            if (_amount == 0) {
                return 0;
            }
        }
        if (!_pool.isFirstTokenShard) {
            uint112 wantToken = wantTokenReserve;
            wantTokenReserve = shardReserve;
            shardReserve = wantToken;
        }
        FixedPoint.uq112x112 memory price;
        if(_pool.tokenToEthPairInfo.blockTimestampLast == 0){
            price = initializeTokenOracle(_pool.tokenToEthPairInfo);
        }
        else{
            price = updateTokenOracle(_pool.tokenToEthPairInfo);
        }
        if (
            address(_pool.tokenToEthPairInfo.tokenToEthSwap) ==
            _pool.lpTokenSwap
        ) {
            _oracleWeight = uint256(price.mul(shardReserve).decode144())
                .mul(2)
                .mul(_amount)
                .div(lpTokenTotalSupply);
        } else {
            _oracleWeight = uint256(price.mul(wantTokenReserve).decode144())
                .mul(2)
                .mul(_amount)
                .div(lpTokenTotalSupply);
        }
    }

    function resetInvitationRelationship(
        uint256 _pid,
        address _user,
        uint256 _originWeight
    ) private {
        InvitationInfo storage senderRelationshipInfo =
            usersRelationshipInfo[_user];
        if (!senderRelationshipInfo.isWithdrawn){
            senderRelationshipInfo.isWithdrawn = true;
            InvitationInfo storage invitorRelationshipInfo =
            usersRelationshipInfo[senderRelationshipInfo.invitor];
            uint256 targetIndex = invitorRelationshipInfo.inviteeIndexMap[_user];
            uint256 inviteesCount = invitorRelationshipInfo.invitees.length;
            address lastInvitee =
            invitorRelationshipInfo.invitees[inviteesCount.sub(1)];
            invitorRelationshipInfo.inviteeIndexMap[lastInvitee] = targetIndex;
            invitorRelationshipInfo.invitees[targetIndex] = lastInvitee;
            delete invitorRelationshipInfo.inviteeIndexMap[_user];
            invitorRelationshipInfo.invitees.pop();
        }
        
        UserInfo storage invitorInfo =
            userInfo[_pid][senderRelationshipInfo.invitor];
        UserInfo storage user =
            userInfo[_pid][_user];
        if(!user.isCalculateInvitation){
            return;
        }
        user.isCalculateInvitation = false;
        uint256 inviteeToSubWeight = _originWeight.div(INVITEE_WEIGHT);
        invitorInfo.inviteeWeight = invitorInfo.inviteeWeight.sub(inviteeToSubWeight);
        if (invitorInfo.amount == 0){
            return;
        }
        PoolInfo storage pool = poolInfo[_pid];
        pool.usersTotalWeight = pool.usersTotalWeight.sub(inviteeToSubWeight);
    }

    function modifyWeightByInvitation(
        uint256 _pid,
        address _user,
        uint256 _oldOriginWeight,
        uint256 _newOriginWeight,
        uint256 _inviteeWeight,
        uint256 _existedAmount
    ) private{
        PoolInfo storage pool = poolInfo[_pid];
        InvitationInfo storage senderInfo = usersRelationshipInfo[_user];
        uint256 poolTotalWeight = pool.usersTotalWeight;
        poolTotalWeight = poolTotalWeight.sub(_oldOriginWeight).add(_newOriginWeight);
        if(_existedAmount == 0){
            poolTotalWeight = poolTotalWeight.add(_inviteeWeight);
        }     
        UserInfo storage user = userInfo[_pid][_user];
        if (!senderInfo.isWithdrawn || (_existedAmount > 0 && user.isCalculateInvitation)) {
            UserInfo storage invitorInfo = userInfo[_pid][senderInfo.invitor];
            user.isCalculateInvitation = true;
            uint256 addInviteeWeight =
                    _newOriginWeight.div(INVITEE_WEIGHT).sub(
                        _oldOriginWeight.div(INVITEE_WEIGHT)
                    );
            invitorInfo.inviteeWeight = invitorInfo.inviteeWeight.add(
                addInviteeWeight
            );
            uint256 addInvitorWeight = 
                    _newOriginWeight.div(INVITOR_WEIGHT).sub(
                        _oldOriginWeight.div(INVITOR_WEIGHT)
                    );
            
            poolTotalWeight = poolTotalWeight.add(addInvitorWeight);
            if (invitorInfo.amount > 0) {
                poolTotalWeight = poolTotalWeight.add(addInviteeWeight);
            } 
        }
        pool.usersTotalWeight = poolTotalWeight;
    }

    function verifyDescription(string memory description)
        internal
        pure
        returns (bool success)
    {
        bytes memory nameBytes = bytes(description);
        uint256 nameLength = nameBytes.length;
        require(nameLength > 0, "INVALID INPUT");
        success = true;
        bool n7;
        for (uint256 i = 0; i <= nameLength - 1; i++) {
            n7 = (nameBytes[i] & 0x80) == 0x80 ? true : false;
            if (n7) {
                success = false;
                break;
            }
        }
    }

    function getUserModifiedWeight(uint256 _pid, address _user) private view returns (uint256){
        UserInfo storage user =  userInfo[_pid][_user];
        uint256 originWeight = user.originWeight;
        uint256 modifiedWeight = originWeight.add(user.inviteeWeight);
        if(user.isCalculateInvitation){
            modifiedWeight = modifiedWeight.add(originWeight.div(INVITOR_WEIGHT));
        }
        return modifiedWeight;
    }

        // get how much token will be mined from _toBlock to _toBlock.
    function getRewardToken(uint256 _fromBlock, uint256 _toBlock) public view virtual returns (uint256){
        return calculateRewardToken(MINT_DECREASE_TERM, SHDPerBlock, startBlock, _fromBlock, _toBlock);
    }

    function calculateRewardToken(uint _term, uint256 _initialBlock, uint256 _startBlock, uint256 _fromBlock, uint256 _toBlock) private pure returns (uint256){
        if(_fromBlock > _toBlock || _startBlock > _toBlock)
            return 0;
        if(_startBlock > _fromBlock)
            _fromBlock = _startBlock;
        uint256 totalReward = 0;
        uint256 blockPeriod = _fromBlock.sub(_startBlock).add(1);
        uint256 yearPeriod = blockPeriod.div(_term);  // produce 5760 blocks per day, 2102400 blocks per year.
        for (uint256 i = 0; i < yearPeriod; i++){
            _initialBlock = _initialBlock.div(2);
        }
        uint256 termStartIndex = yearPeriod.add(1).mul(_term).add(_startBlock);
        uint256 beforeCalculateIndex = _fromBlock.sub(1);
        while(_toBlock >= termStartIndex && _initialBlock > 0){
            totalReward = totalReward.add(termStartIndex.sub(beforeCalculateIndex).mul(_initialBlock));
            beforeCalculateIndex = termStartIndex.add(1);
            _initialBlock = _initialBlock.div(2);
            termStartIndex = termStartIndex.add(_term);
        }
        if(_toBlock > beforeCalculateIndex){
            totalReward = totalReward.add(_toBlock.sub(beforeCalculateIndex).mul(_initialBlock));
        }
        return totalReward;
    }

    function getTargetTokenInSwap(IUniswapV2Pair _lpTokenSwap, address _targetToken) internal view returns (address, address, uint256){
        address token0 = _lpTokenSwap.token0();
        address token1 = _lpTokenSwap.token1();
        if(token0 == _targetToken){
            return(token0, token1, 0);
        }
        if(token1 == _targetToken){
            return(token0, token1, 1);
        }
        require(false, "invalid uniswap");
    }

    function generateOrcaleInfo(IUniswapV2Pair _pairSwap, bool _isFirstTokenEth) internal view returns(TokenPairInfo memory){
        uint256 priceTokenCumulativeLast = _isFirstTokenEth? _pairSwap.price1CumulativeLast(): _pairSwap.price0CumulativeLast();
        uint32 tokenBlockTimestampLast = 0;
        if(priceTokenCumulativeLast != 0){
            (, , tokenBlockTimestampLast) = _pairSwap.getReserves();
        }
        TokenPairInfo memory tokenBInfo = TokenPairInfo({
            tokenToEthSwap: _pairSwap,
            isFirstTokenEth: _isFirstTokenEth,
            priceCumulativeLast: priceTokenCumulativeLast,
            blockTimestampLast: tokenBlockTimestampLast,
            price: FixedPoint.uq112x112(0),
            lastPriceUpdateHeight: block.number
        });
        return tokenBInfo;
    }

    function initializeTokenOracle(TokenPairInfo storage _pairInfo) internal returns (FixedPoint.uq112x112 memory _price){
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed;
        uint256 initialPriceCumulative;
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(_pairInfo.tokenToEthSwap).getReserves();
        if(_pairInfo.isFirstTokenEth){
            _price = FixedPoint.fraction(reserve0, reserve1);
            initialPriceCumulative = IUniswapV2Pair(_pairInfo.tokenToEthSwap).price1CumulativeLast();
        }
        else{
            _price = FixedPoint.fraction(reserve1, reserve0);
            initialPriceCumulative = IUniswapV2Pair(_pairInfo.tokenToEthSwap).price0CumulativeLast();
        }
        _pairInfo.price = _price;
        timeElapsed = blockTimestamp - blockTimestampLast;
        initialPriceCumulative = initialPriceCumulative.add(uint(_price._x).mul(timeElapsed));
        _pairInfo.priceCumulativeLast = initialPriceCumulative;
        _pairInfo.lastPriceUpdateHeight = block.number;
        _pairInfo.blockTimestampLast = blockTimestamp;
        return _price;
    }

    function updateTokenOracle(TokenPairInfo storage _pairInfo) internal returns (FixedPoint.uq112x112 memory _price) {
        FixedPoint.uq112x112 memory cachedPrice = _pairInfo.price;
        if(cachedPrice._x > 0 && block.number.sub(_pairInfo.lastPriceUpdateHeight) <= updateTokenPriceTerm){
            return cachedPrice;
        }
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_pairInfo.tokenToEthSwap));
        uint32 timeElapsed = blockTimestamp - _pairInfo.blockTimestampLast; // overflow is desired
        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        if(_pairInfo.isFirstTokenEth){
            _price = FixedPoint.uq112x112(uint224(price1Cumulative.sub(_pairInfo.priceCumulativeLast).div(timeElapsed)));
            _pairInfo.priceCumulativeLast = price1Cumulative;
        }     
        else{
            _price = FixedPoint.uq112x112(uint224(price0Cumulative.sub(_pairInfo.priceCumulativeLast).div(timeElapsed)));
            _pairInfo.priceCumulativeLast = price0Cumulative;
        }
        _pairInfo.price = _price;
        _pairInfo.lastPriceUpdateHeight = block.number;
        _pairInfo.blockTimestampLast = blockTimestamp;
    }

    function updateAfterModifyStartBlock(uint256 _newStartBlock) internal override{
        lastRewardBlock = _newStartBlock.sub(1);
        if(poolInfo.length > 0){
            PoolInfo storage shdPool = poolInfo[0];
            shdPool.lastDividendHeight = lastRewardBlock;
        }
    }
}

// File: contracts/ShardingDAOMiningDelegate.sol


pragma solidity 0.6.12;



contract ShardingDAOMiningDelegate is DelegateInterface, ShardingDAOMining {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data)
        public
        override
    {
        checkAdmin();
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public override {
        checkAdmin();
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }
    }
}