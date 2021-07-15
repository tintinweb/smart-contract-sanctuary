/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol



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
library SafeMathUpgradeable {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol






/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol


// solhint-disable-next-line compiler-version


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: @openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol




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
abstract contract ContextUpgradeable is Initializable {
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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol




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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

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

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
}

// File: contracts/interface/IPriceFeed.sol


interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);
}

// File: contracts/utils/DecimalMath.sol



/// @dev Implements simple fixed point math add, sub, mul and div operations.
/// @author Alberto Cuesta Cañada
library DecimalMath {
    using SafeMathUpgradeable for uint256;

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

// File: contracts/utils/Decimal.sol




library Decimal {
    using DecimalMath for uint256;
    using SafeMathUpgradeable for uint256;

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

// File: @openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol



/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
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
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: contracts/utils/SignedDecimalMath.sol



/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    using SignedSafeMathUpgradeable for int256;

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

// File: contracts/utils/SignedDecimal.sol





library SignedDecimal {
    using SignedDecimalMath for int256;
    using SignedSafeMathUpgradeable for int256;

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

// File: contracts/types/ISakePerpVaultTypes.sol

pragma experimental ABIEncoderV2;

interface ISakePerpVaultTypes {
    /**
     * @notice pool types
     * @param HIGH high risk pool
     * @param LOW low risk pool
     */
    enum Risk {HIGH, LOW}
}

// File: contracts/types/IExchangeTypes.sol




interface IExchangeTypes {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {ADD_TO_AMM, REMOVE_FROM_AMM}

    struct LiquidityChangedSnapshot {
        SignedDecimal.signedDecimal cumulativeNotional;
        // the base/quote reserve of amm right before liquidity changed
        Decimal.decimal quoteAssetReserve;
        Decimal.decimal baseAssetReserve;
        // total position size owned by amm after last snapshot taken
        // `totalPositionSize` = currentBaseAssetReserve - lastLiquidityChangedHistoryItem.baseAssetReserve + prevTotalPositionSize
        SignedDecimal.signedDecimal totalPositionSize;
    }
}

// File: contracts/interface/IExchange.sol







interface IExchange is IExchangeTypes {
    function swapInput(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit,
        bool _reverse
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

    function settleFunding(bool movingAmm)
        external
        returns (
            SignedDecimal.signedDecimal memory,
            SignedDecimal.signedDecimal memory,
            SignedDecimal.signedDecimal memory
        );

    function calcFee(Decimal.decimal calldata _quoteAssetAmount) external view returns (Decimal.decimal memory);

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
    ) external view returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);

    function getSpotPrice() external view returns (Decimal.decimal memory);

    function getLiquidityHistoryLength() external view returns (uint256);

    // overridden by state variable
    function quoteAsset() external view returns (IERC20Upgradeable);

    function open() external view returns (bool);

    // can not be overridden by state variable due to type `Deciaml.decimal`
    function getSettlementPrice() external view returns (Decimal.decimal memory);

    function getCumulativeNotional() external view returns (SignedDecimal.signedDecimal memory);

    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function getLiquidityChangedSnapshots(uint256 i) external view returns (LiquidityChangedSnapshot memory);

    function mint(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function burn(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function getMMUnrealizedPNL(Decimal.decimal memory _baseAssetReserve, Decimal.decimal memory _quoteAssetReserve)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function moveAMMPriceToOracle(uint256 _oraclePrice, bytes32 _priceFeedKey) external;

    function setPriceFeed(address _priceFeed) external;

    function getReserve() external view returns (Decimal.decimal memory, Decimal.decimal memory);

    function initMarginRatio() external view returns (Decimal.decimal memory);

    function maintenanceMarginRatio() external view returns (Decimal.decimal memory);

    function liquidationFeeRatio() external view returns (Decimal.decimal memory);

    function maxLiquidationFee() external view returns (Decimal.decimal memory);

    function spreadRatio() external view returns (Decimal.decimal memory);

    function priceFeedKey() external view returns (bytes32);

    function tradeLimitRatio() external view returns (uint256);

    function priceAdjustRatio() external view returns (uint256);

    function fluctuationLimitRatio() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function adjustTotalPosition(
        SignedDecimal.signedDecimal memory adjustedPosition,
        SignedDecimal.signedDecimal memory oldAdjustedPosition
    ) external;

    function getTotalPositionSize() external view returns (SignedDecimal.signedDecimal memory);

    function getExchangeState() external view returns (address);

    function getUnderlyingPrice() external view returns (Decimal.decimal memory);

    function isOverSpreadLimit() external view returns (bool);

    function getPositionSize()
        external
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory);
}

// File: contracts/types/ISakePerpTypes.sol




interface ISakePerpTypes {
    //
    // Struct and Enum
    //
    enum Side {BUY, SELL}
    enum PnlCalcOption { SPOT_PRICE, TWAP, ORACLE }

    /// @notice This struct records personal position information
    /// @param size denominated in amm.baseAsset
    /// @param margin isolated margin
    /// @param openNotional the quoteAsset value of position when opening position. the cost of the position
    /// @param lastUpdatedCumulativePremiumFraction for calculating funding payment, record at the moment every time when trader open/reduce/close position
    /// @param lastUpdatedCumulativeOvernightFeeRate for calculating holding fee, record at the moment every time when trader open/reduce/close position
    /// @param liquidityHistoryIndex
    /// @param blockNumber the block number of the last position
    struct Position {
        SignedDecimal.signedDecimal size;
        Decimal.decimal margin;
        Decimal.decimal openNotional;
        SignedDecimal.signedDecimal lastUpdatedCumulativePremiumFraction;
        Decimal.decimal lastUpdatedCumulativeOvernightFeeRate;
        uint256 liquidityHistoryIndex;
        uint256 blockNumber;
    }
}

// File: contracts/interface/ISakePerp.sol






interface ISakePerp is ISakePerpTypes {
    function getMMLiquidity(address _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function getLatestCumulativePremiumFraction(IExchange _exchange)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function getLatestCumulativePremiumFractionWithPosition(
        IExchange _exchange,
        SignedDecimal.signedDecimal memory _position
    ) external view returns (SignedDecimal.signedDecimal memory);

    function getLatestCumulativeOvernightFeeRate(IExchange _exchange) external view returns (Decimal.decimal memory);

    function getPositionNotionalAndUnrealizedPnl(
        IExchange _exchange,
        address _trader,
        PnlCalcOption _pnlCalcOption
    ) external view returns (Decimal.decimal memory positionNotional, SignedDecimal.signedDecimal memory unrealizedPnl);

    function getPosition(IExchange _exchange, address _trader) external view returns (Position memory);

    function getUnadjustedPosition(IExchange _exchange, address _trader)
        external
        view
        returns (Position memory position);

    function getMarginRatio(IExchange _exchange, address _trader)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function payFunding(IExchange _exchange) external;
}

// File: contracts/interface/ISakePerpVault.sol






interface ISakePerpVault is ISakePerpVaultTypes {
    function withdraw(
        IExchange _exchange,
        address _receiver,
        Decimal.decimal memory _amount
    ) external;

    function realizeBadDebt(IExchange _exchange, Decimal.decimal memory _badDebt) external;

    function modifyLiquidity() external;

    function getMMLiquidity(address _exchange, Risk _risk) external view returns (SignedDecimal.signedDecimal memory);

    function getAllMMLiquidity(address _exchange)
        external
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory);

    function getTotalMMLiquidity(address _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function getTotalMMAvailableLiquidity(address _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function getTotalLpUnrealizedPNL(IExchange _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function addCachedLiquidity(address _exchange, Decimal.decimal memory _DeltalpLiquidity) external;

    function requireMMNotBankrupt(address _exchange) external;

    function getMMCachedLiquidity(address _exchange, Risk _risk) external view returns (Decimal.decimal memory);

    function getTotalMMCachedLiquidity(address _exchange) external view returns (Decimal.decimal memory);

    function setRiskLiquidityWeight(address _exchange, uint256 _highWeight, uint256 _lowWeight) external;

    function setMaxLoss(
        address _exchange,
        Risk _risk,
        uint256 _max
    ) external;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol







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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal {
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
    uint256[44] private __gap;
}

// File: contracts/interface/IInsuranceFund.sol




interface IInsuranceFund {
    function withdraw(Decimal.decimal calldata _amount) external returns (Decimal.decimal memory badDebt);

    function setExchange(IExchange _exchange) external;

    function setBeneficiary(address _beneficiary) external;
}

// File: contracts/interface/ISystemSettings.sol





interface ISystemSettings {
    function insuranceFundFeeRatio() external view returns (Decimal.decimal memory);

    function lpWithdrawFeeRatio() external view returns (Decimal.decimal memory);

    function overnightFeeRatio() external view returns (Decimal.decimal memory);

    function overnightFeeLpShareRatio() external view returns (Decimal.decimal memory);

    function fundingFeeLpShareRatio() external view returns (Decimal.decimal memory);

    function overnightFeePeriod() external view returns (uint256);

    function isExistedExchange(IExchange _exchange) external view returns (bool);

    function getAllExchanges() external view returns (IExchange[] memory);

    function getInsuranceFund(IExchange _exchange) external view returns (IInsuranceFund);

    function setNextOvernightFeeTime(IExchange _exchange) external;

    function nextOvernightFeeTime(address _exchange) external view returns (uint256);

    function checkTransfer(address _from, address _to) external view returns (bool);
}

// File: contracts/MMLPToken.sol





contract MMLPToken is ERC20Upgradeable, OwnableUpgradeable {
    ISystemSettings public systemSettings;

    constructor(
        string memory _name,
        string memory _symbol,
        address _systemSettings
    ) public {
        systemSettings = ISystemSettings(_systemSettings);
        __ERC20_init(_name, _symbol);
        __Ownable_init();
    }

    function mint(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyOwner {
        _burn(_account, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        amount;
        require(systemSettings.checkTransfer(from, to), "illegal transfer");
    }
}

// File: contracts/interface/IExchangeState.sol







interface IExchangeState {
    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function initMarginRatio() external view returns (Decimal.decimal memory);

    function maintenanceMarginRatio() external view returns (Decimal.decimal memory);

    function liquidationFeeRatio() external view returns (Decimal.decimal memory);

    function maxLiquidationFee() external view returns (Decimal.decimal memory);

    function spreadRatio() external view returns (Decimal.decimal memory);

    function maxOracleSpreadRatio() external view returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        IExchangeTypes.Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external pure returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        IExchangeTypes.Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external pure returns (Decimal.decimal memory);

    function calcFee(Decimal.decimal calldata _quoteAssetAmount) external view returns (Decimal.decimal memory);

    function mint(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function burn(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function getLPToken(ISakePerpVaultTypes.Risk _level) external view returns (MMLPToken);
}

// File: contracts/utils/MixedDecimal.sol





/// @dev To handle a signedDecimal add/sub/mul/div a decimal and provide convert decimal to signedDecimal helper
library MixedDecimal {
    using SignedDecimal for SignedDecimal.signedDecimal;
    using SignedSafeMathUpgradeable for int256;

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

// File: contracts/utils/BlockContext.sol


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

// File: contracts/utils/Sqrt.sol


library Sqrt {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256) {
        if (y > 3) {
            uint256 z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
            return z;
        } else if (y != 0) {
            return 1;
        } else {
            return 0;
        }
    }
}

// File: contracts/Exchange.sol

















contract Exchange is IExchange, OwnableUpgradeable, BlockContext {
    using SafeMathUpgradeable for uint256;
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;
    using Sqrt for uint256;

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
    event SeparateFundingRateUpdated(int256 longRate, int256 shortRate, uint256 underlyingPrice);
    event ReserveSnapshotted(uint256 quoteAssetReserve, uint256 baseAssetReserve, uint256 timestamp);
    event LiquidityChanged(uint256 quoteReserve, uint256 baseReserve, int256 cumulativeNotional);
    event CapChanged(uint256 maxHoldingBaseAsset, uint256 openInterestNotionalCap);
    event Shutdown(uint256 settlementPrice);
    event MoveAMMPrice(
        uint256 ammPrice,
        uint256 oraclePrice,
        uint256 adjustPrice,
        int256 MMLiquidity,
        int256 MMPNL,
        bool moved
    );

    //
    // MODIFIERS
    //
    modifier onlyOpen() {
        require(open, "exchange was closed");
        _;
    }

    modifier onlyClose() {
        require(open == false, "exchange was open");
        _;
    }

    modifier onlyCounterParty() {
        require(address(sakePerp) == _msgSender(), "caller is not counterParty");
        _;
    }

    modifier onlyMinter() {
        require(address(sakePerpVault) == _msgSender(), "caller is not minter");
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
    enum QuoteAssetDir {
        QUOTE_IN,
        QUOTE_OUT
    }
    // internal usage
    enum TwapCalcOption {
        RESERVE_ASSET,
        INPUT_ASSET
    }

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

    // update during every swap and used when shutting exchange down
    SignedDecimal.signedDecimal public totalPositionSize;

    // latest funding rate = ((twap market price - twap oracle price) / twap oracle price) / 24
    SignedDecimal.signedDecimal public fundingRate;
    SignedDecimal.signedDecimal private cumulativeNotional;
    SignedDecimal.signedDecimal private mmCumulativeNotional;

    Decimal.decimal private settlementPrice;
    Decimal.decimal public override tradeLimitRatio;
    Decimal.decimal public quoteAssetReserve;
    Decimal.decimal public baseAssetReserve;
    Decimal.decimal public override fluctuationLimitRatio;

    // owner can update
    Decimal.decimal public override priceAdjustRatio;

    // snapshot of amm reserve when change liquidity's invariant
    LiquidityChangedSnapshot[] private liquidityChangedSnapshots;

    uint256 public spotPriceTwapInterval;
    uint256 public override fundingPeriod;
    uint256 public fundingBufferPeriod;
    uint256 public nextFundingTime;
    bytes32 public override priceFeedKey;
    ReserveSnapshot[] public reserveSnapshots;

    ISakePerpVault public sakePerpVault;
    IERC20Upgradeable public override quoteAsset;
    IPriceFeed public priceFeed;
    ISakePerp public sakePerp;
    bool public override open;
    uint256 public lastMoveAmmPriceTime;
    Decimal.decimal public oraclePriceSpreadLimit;
    address public mover;
    IExchangeState private exchangeState;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    SignedDecimal.signedDecimal public longPositionSize;
    SignedDecimal.signedDecimal public shortPositionSize;
    SignedDecimal.signedDecimal public longFundingRate;
    SignedDecimal.signedDecimal public shortFundingRate;

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
        ISakePerp _sakePerp,
        ISakePerpVault _sakePerpVault,
        bytes32 _priceFeedKey,
        address _quoteAsset,
        uint256 _fluctuationLimitRatio,
        uint256 _priceAdjustRatio,
        IExchangeState _exchangeState
    ) public initializer {
        require(
            _quoteAssetReserve != 0 &&
                _tradeLimitRatio != 0 &&
                _baseAssetReserve != 0 &&
                _fundingPeriod != 0 &&
                address(_priceFeed) != address(0) &&
                address(_sakePerp) != address(0) &&
                address(_sakePerpVault) != address(0) &&
                address(_exchangeState) != address(0) &&
                _quoteAsset != address(0),
            "invalid input"
        );
        __Ownable_init();

        quoteAssetReserve = Decimal.decimal(_quoteAssetReserve);
        baseAssetReserve = Decimal.decimal(_baseAssetReserve);
        tradeLimitRatio = Decimal.decimal(_tradeLimitRatio);
        priceAdjustRatio = Decimal.decimal(_priceAdjustRatio);
        fluctuationLimitRatio = Decimal.decimal(_fluctuationLimitRatio);
        fundingPeriod = _fundingPeriod;
        fundingBufferPeriod = _fundingPeriod.div(2);
        spotPriceTwapInterval = 1 hours;
        priceFeedKey = _priceFeedKey;
        quoteAsset = IERC20Upgradeable(_quoteAsset);
        priceFeed = _priceFeed;
        sakePerp = _sakePerp;
        sakePerpVault = _sakePerpVault;
        exchangeState = _exchangeState;
        oraclePriceSpreadLimit = Decimal.decimal(3 * 10**17);
        mover = _msgSender();

        sakePerpVault.setRiskLiquidityWeight(address(this), 800, 0);
        sakePerpVault.setMaxLoss(address(this), ISakePerpVaultTypes.Risk.HIGH, 50);
        sakePerpVault.setMaxLoss(address(this), ISakePerpVaultTypes.Risk.LOW, 25);

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
     * @notice mint MLP for MM
     * @dev only sakePerpVault can call this function
     */
    function mint(
        ISakePerpVaultTypes.Risk _risk,
        address account,
        uint256 amount
    ) external override onlyOpen onlyMinter {
        exchangeState.mint(_risk, account, amount);
    }

    /**
     * @notice burn MLP
     * @dev only sakePerpVault can call this function
     */
    function burn(
        ISakePerpVaultTypes.Risk _risk,
        address account,
        uint256 amount
    ) external override onlyMinter {
        exchangeState.burn(_risk, account, amount);
    }

    /**
     * @notice Swap your quote asset to base asset, the impact of the price MUST be less than `fluctuationLimitRatio`
     * @dev Only clearingHouse can call this function
     * @param _dir ADD_TO_AMM for long, REMOVE_FROM_AMM for short
     * @param _quoteAssetAmount quote asset amount
     * @param _baseAssetAmountLimit minimum base asset amount expected to get to prevent front running
     * @param _reverse true: increase position  false: decrease position
     * @return base asset amount
     */
    function swapInput(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit,
        bool _reverse
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

        if (_dir == Dir.ADD_TO_AMM) {
            if (_reverse == false) {
                longPositionSize = longPositionSize.addD(baseAssetAmount);
            } else {
                shortPositionSize = shortPositionSize.subD(baseAssetAmount);
            }
        } else {
            if (_reverse == false) {
                shortPositionSize = shortPositionSize.addD(baseAssetAmount);
            } else {
                longPositionSize = longPositionSize.subD(baseAssetAmount);
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
     * @param movingAmm if called when movingAmmPrice
     * @return premium fraction of this period in 18 digits
     */
    function settleFunding(bool movingAmm)
        external
        override
        onlyOpen
        onlyCounterParty
        returns (
            SignedDecimal.signedDecimal memory,
            SignedDecimal.signedDecimal memory,
            SignedDecimal.signedDecimal memory
        )
    {
        uint256 twapInterval = spotPriceTwapInterval;
        uint256 nextFundingTimeEst = nextFundingTime.add(fundingPeriod);

        if (movingAmm) {
            // lastFundingTime = nextFundingTime - fundingPeriod
            // twapInterval = _blockTimestamp() - lastFundingTime = _blockTimestamp() + fundingPeriod - nextFundingTime
            if (_blockTimestamp() < nextFundingTime && _blockTimestamp().add(fundingPeriod) > nextFundingTime) {
                twapInterval = _blockTimestamp().add(fundingPeriod).sub(nextFundingTime);
                nextFundingTimeEst = _blockTimestamp().add(fundingPeriod);
            }
        } else {
            require(_blockTimestamp() >= nextFundingTime, "settle funding too early");
        }
        
        SignedDecimal.signedDecimal memory premiumFraction = SignedDecimal.zero();
        Decimal.decimal memory underlyingPrice = getUnderlyingTwapPrice(twapInterval);

        // premium = twapMarketPrice - twapIndexPrice
        // timeFraction = fundingPeriod(1 hour) / 1 day
        // premiumFraction = premium * timeFraction
        SignedDecimal.signedDecimal memory premium = MixedDecimal.fromDecimal(getTwapPrice(twapInterval)).subD(
            underlyingPrice
        );
        premiumFraction = premium.mulScalar(twapInterval).divScalar(int256(1 days));

        SignedDecimal.signedDecimal memory longPremiumFraction = premiumFraction;
        SignedDecimal.signedDecimal memory shortPremiumFraction = premiumFraction;

        // premiumFraction > 0 long pay short
        // totalPositionSize > 0 longPositionSize is bigger than shortPositionSize
        // premiumFraction > 0 && totalPositionSize > 0 amm will receive fundingFee
        // premiumFraction > 0 && totalPositionSize < 0 amm need to pay fundingFee
        // premiumFraction < 0 && totalPositionSize > 0 amm need to pay fundingFee
        // premiumFraction < 0 && totalPositionSize < 0 amm will receive fundingFee
        // when amm need to pay fundingFee, to avoid this we recalculated the premiumFraction
        // so the receiver will get less fundingFee and payer will pay the same as before
        SignedDecimal.signedDecimal memory ammFundingPaymentLoss = premiumFraction.mulD(totalPositionSize);
        if (ammFundingPaymentLoss.isNegative()) {
            if (premiumFraction.isNegative()) {
                longPremiumFraction = shortPositionSize.mulD(premiumFraction).divD(longPositionSize);
            } else {
                shortPremiumFraction = longPositionSize.mulD(premiumFraction).divD(shortPositionSize);
            }
        }

        // update funding rate = premiumFraction / twapIndexPrice
        updateFundingRate(longPremiumFraction, shortPremiumFraction, underlyingPrice);

        // in order to prevent multiple funding settlement during very short time after network congestion
        uint256 minNextValidFundingTime = _blockTimestamp().add(fundingBufferPeriod);

        // max(nextFundingTimeEst, minNextValidFundingTime)
        nextFundingTime = nextFundingTimeEst > minNextValidFundingTime
            ? nextFundingTimeEst
            : minNextValidFundingTime;

        return (longPremiumFraction, shortPremiumFraction, ammFundingPaymentLoss);
    }

    function migrateLiquidity(
        Decimal.decimal calldata _liquidityMultiplier,
        Decimal.decimal calldata _fluctuationLimitRatio
    ) external override onlyOwner {
        require(_liquidityMultiplier.toUint() != Decimal.one().toUint(), "multiplier can't be 1");

        // check liquidity multiplier limit, have lower bound if position size is positive for now.
        checkLiquidityMultiplierLimit(totalPositionSize, _liquidityMultiplier);

        // #53 fix sandwich attack during liquidity migration
        checkFluctuationLimit(_fluctuationLimitRatio);

        // get current reserve values
        Decimal.decimal memory quoteAssetBeforeAddingLiquidity = quoteAssetReserve;
        Decimal.decimal memory baseAssetBeforeAddingLiquidity = baseAssetReserve;
        SignedDecimal.signedDecimal memory totalPositionSizeBefore = totalPositionSize;

        // migrate liquidity
        quoteAssetReserve = quoteAssetBeforeAddingLiquidity.mulD(_liquidityMultiplier);
        baseAssetReserve = baseAssetBeforeAddingLiquidity.mulD(_liquidityMultiplier);

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
     * @notice shutdown exchange
     * @dev only owner can call this function
     */
    function shutdown() external override onlyOwner {
        sakePerpVault.modifyLiquidity();
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

    /**
     * @notice set counter party
     * @dev only owner can call this function
     * @param _counterParty address of counter party
     */
    function setCounterParty(address _counterParty) external onlyOwner {
        sakePerp = ISakePerp(_counterParty);
    }

    /**
     * @notice set minter
     * @dev only owner can call this function
     * @param _minter address of minter
     */
    function setMinter(address _minter) external onlyOwner {
        sakePerpVault = ISakePerpVault(_minter);
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
     * @notice set new price adjust ratio
     * @dev only owner can call
     * @param _priceAdjustRatio new price adjust spread in 18 digits
     */
    function setPriceAdjustRatio(Decimal.decimal memory _priceAdjustRatio) public onlyOwner {
        require(_priceAdjustRatio.cmp(Decimal.one()) <= 0, "invalid ratio");
        priceAdjustRatio = _priceAdjustRatio;
    }

    /**
     * @notice set price feed address
     * @param _priceFeed new price feed address
     */
    function setPriceFeed(address _priceFeed) public override onlyOwner {
        require(_priceFeed != address(0), "invalid address");
        priceFeed = IPriceFeed(_priceFeed);
    }

    /**
     * @notice set oracle price spread limitation
     * @param _limit new limitation
     */
    function setOraclePriceSpreadLimit(Decimal.decimal memory _limit) public onlyOwner {
        oraclePriceSpreadLimit = _limit;
    }

    /**
     * @notice set oracle price mover
     * @param _newMover new mover
     */
    function setMover(address _newMover) public onlyOwner {
        require(_newMover != address(0), "invalid address");
        mover = _newMover;
    }

    /**
     * @notice set exchange state address
     * @param _exchangeState new exchange state address
     */
    function setExchangeState(address _exchangeState) public onlyOwner {
        require(_exchangeState != address(0), "invalid address");
        exchangeState = IExchangeState(_exchangeState);
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
    function getUnderlyingPrice() public view override returns (Decimal.decimal memory) {
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
    function getReserve() external view override returns (Decimal.decimal memory, Decimal.decimal memory) {
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

    function getMaxHoldingBaseAsset() external view override returns (Decimal.decimal memory) {
        return exchangeState.getMaxHoldingBaseAsset();
    }

    function getOpenInterestNotionalCap() external view override returns (Decimal.decimal memory) {
        return exchangeState.getOpenInterestNotionalCap();
    }

    function initMarginRatio() external view override returns (Decimal.decimal memory) {
        return exchangeState.initMarginRatio();
    }

    function maintenanceMarginRatio() external view override returns (Decimal.decimal memory) {
        return exchangeState.maintenanceMarginRatio();
    }

    function liquidationFeeRatio() external view override returns (Decimal.decimal memory) {
        return exchangeState.liquidationFeeRatio();
    }

    function maxLiquidationFee() external view override returns (Decimal.decimal memory) {
        return exchangeState.maxLiquidationFee();
    }

    function spreadRatio() external view override returns (Decimal.decimal memory) {
        return exchangeState.spreadRatio();
    }

    function getTotalPositionSize() external view override returns (SignedDecimal.signedDecimal memory) {
        return totalPositionSize;
    }

    function getPositionSize()
        external
        view
        override
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory)
    {
        return (longPositionSize, shortPositionSize);
    }

    function getExchangeState() external view override returns (address) {
        return address(exchangeState);
    }

    function isOverSpreadLimit() external view override returns (bool) {
        Decimal.decimal memory oraclePrice = getUnderlyingPrice();
        require(oraclePrice.toUint() > 0, "underlying price is 0");
        Decimal.decimal memory marketPrice = getSpotPrice();
        Decimal.decimal memory oracleSpreadRatioAbs = MixedDecimal
        .fromDecimal(marketPrice)
        .subD(oraclePrice)
        .divD(oraclePrice)
        .abs();

        return oracleSpreadRatioAbs.toUint() >= exchangeState.maxOracleSpreadRatio().toUint() ? true : false;
    }

    /**
     * @notice calculate spread fee by input quoteAssetAmount
     * @param _quoteAssetAmount quoteAssetAmount
     * @return total tx fee
     */
    function calcFee(Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return exchangeState.calcFee(_quoteAssetAmount);
    }

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) public view override returns (Decimal.decimal memory) {
        return
            exchangeState.getInputPriceWithReserves(
                _dir,
                _quoteAssetAmount,
                _quoteAssetPoolAmount,
                _baseAssetPoolAmount
            );
    }

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) public view override returns (Decimal.decimal memory) {
        return
            exchangeState.getOutputPriceWithReserves(
                _dir,
                _baseAssetAmount,
                _quoteAssetPoolAmount,
                _baseAssetPoolAmount
            );
    }

    //
    // INTERNAL FUNCTIONS
    //
    // update funding rate = premiumFraction / twapIndexPrice
    function updateFundingRate(
        SignedDecimal.signedDecimal memory _longPremiumFraction,
        SignedDecimal.signedDecimal memory _shortPremiumFraction,
        Decimal.decimal memory _underlyingPrice
    ) private {
        longFundingRate = _longPremiumFraction.divD(_underlyingPrice);
        shortFundingRate = _shortPremiumFraction.divD(_underlyingPrice);
        emit SeparateFundingRateUpdated(longFundingRate.toInt(), shortFundingRate.toInt(), _underlyingPrice.toUint());
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

        // positionSize may little than real position size because of migtrate liquidity
        if (_dir == Dir.REMOVE_FROM_AMM) {
            require(baseAssetReserve.mulD(tradeLimitRatio).toUint() >= _baseAssetAmount.toUint(), "over trading limit");
            shortPositionSize = shortPositionSize.subD(_baseAssetAmount);
        } else {
            longPositionSize = longPositionSize.subD(_baseAssetAmount);
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
            totalPositionSize = totalPositionSize.addD(_baseAssetAmount);
            cumulativeNotional = cumulativeNotional.addD(_quoteAssetAmount);
        } else {
            quoteAssetReserve = quoteAssetReserve.subD(_quoteAssetAmount);
            baseAssetReserve = baseAssetReserve.addD(_baseAssetAmount);
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

    function moveAMMPriceToOracle(uint256 _oraclePrice, bytes32 _priceFeedKey) public override {
        require(mover == _msgSender() || address(priceFeed) == _msgSender(), "illegal operator");
        require(_oraclePrice > 0, "oracle price can't be zero");
        require(priceFeedKey == _priceFeedKey, "illegal price feed key");
        if (!open || priceAdjustRatio.toUint() == 0) return;

        Decimal.decimal memory oraclePrice = Decimal.decimal(_oraclePrice);
        Decimal.decimal memory AMMPrice = quoteAssetReserve.divD(baseAssetReserve);
        require(
            MixedDecimal.fromDecimal(oraclePrice).subD(AMMPrice).abs().cmp(oraclePriceSpreadLimit.mulD(AMMPrice)) <= 0,
            "invalid oracle price"
        );

        Decimal.decimal memory adjustPrice = MixedDecimal
        .fromDecimal(AMMPrice)
        .addD(MixedDecimal.fromDecimal(oraclePrice).subD(AMMPrice).mulD(priceAdjustRatio))
        .abs();

        // baseAssetReserve * oraclePrice * baseAssetReserve = invariant
        Decimal.decimal memory invariant = quoteAssetReserve.mulD(baseAssetReserve);
        uint256 basePow = invariant.divD(adjustPrice).toUint().mul(Decimal.one().toUint());
        Decimal.decimal memory _baseAssetReserve = Decimal.decimal(basePow.sqrt());
        Decimal.decimal memory _quoteAssetReserve = invariant.divD(_baseAssetReserve);

        SignedDecimal.signedDecimal memory MMPNL = getMMUnrealizedPNL(_baseAssetReserve, _quoteAssetReserve);
        SignedDecimal.signedDecimal memory MMLiquidity = sakePerpVault.getTotalMMAvailableLiquidity(address(this));
        Decimal.decimal memory MMCachedLiquidity = sakePerpVault.getTotalMMCachedLiquidity(address(this));

        // negative means MM can't pay for this price movement
        if (MMPNL.addD(MMLiquidity).addD(MMCachedLiquidity).isNegative()) {
            emit MoveAMMPrice(
                AMMPrice.toUint(),
                _oraclePrice,
                adjustPrice.toUint(),
                MMLiquidity.toInt(),
                MMPNL.toInt(),
                false
            );
        } else {
            sakePerp.payFunding(IExchange(address(this)));

            SignedDecimal.signedDecimal memory mmNotional = MixedDecimal.fromDecimal(_quoteAssetReserve).subD(
                quoteAssetReserve
            );
            mmCumulativeNotional = mmCumulativeNotional.addD(mmNotional);
            cumulativeNotional = cumulativeNotional.addD(mmNotional);
            baseAssetReserve = _baseAssetReserve;
            quoteAssetReserve = _quoteAssetReserve;
            lastMoveAmmPriceTime = _blockTimestamp();

            addReserveSnapshot();
            sakePerpVault.modifyLiquidity();

            emit MoveAMMPrice(
                AMMPrice.toUint(),
                _oraclePrice,
                adjustPrice.toUint(),
                MMLiquidity.addD(MMCachedLiquidity).toInt(),
                MMPNL.toInt(),
                true
            );
        }
    }

    /**
     * @notice get MM unrealized PNL
     */
    function getMMUnrealizedPNL(Decimal.decimal memory _baseAssetReserve, Decimal.decimal memory _quoteAssetReserve)
        public
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        // MMUnrealizedPNL = - (closeLongQuoteAssetAmout - openLongQuoteAssetAmout + openShortQuoteAssetAmout - closeShortQuoteAssetAmout)
        // MMUnrealizedPNL = openLongQuoteAssetAmout - openShortQuoteAssetAmout + closeShortQuoteAssetAmout - closeLongQuoteAssetAmout
        // cumulativeNotional = openLongQuoteAssetAmout - openShortQuoteAssetAmout
        // MMUnrealizedPNL = cumulativeNotional + closeShortQuoteAssetAmout - closeLongQuoteAssetAmout
        SignedDecimal.signedDecimal memory detalCloseAmount;
        if (totalPositionSize.isNegative()) {
            detalCloseAmount = MixedDecimal.fromDecimal(
                getOutputPriceWithReserves(
                    Dir.REMOVE_FROM_AMM,
                    totalPositionSize.abs(),
                    _quoteAssetReserve,
                    _baseAssetReserve
                )
            );
        } else {
            detalCloseAmount = MixedDecimal
            .fromDecimal(
                getOutputPriceWithReserves(
                    Dir.ADD_TO_AMM,
                    totalPositionSize.abs(),
                    _quoteAssetReserve,
                    _baseAssetReserve
                )
            ).mulScalar(-1);
        }

        return cumulativeNotional.subD(mmCumulativeNotional).addD(detalCloseAmount);
    }

    function adjustTotalPosition(
        SignedDecimal.signedDecimal memory adjustedPosition,
        SignedDecimal.signedDecimal memory oldAdjustedPosition
    ) public override onlyCounterParty {
        totalPositionSize = totalPositionSize.addD(adjustedPosition).subD(oldAdjustedPosition);
    }

    function checkMovingAmmPrice(uint256 _oraclePrice) public view returns (bool) {
        if (!open || priceAdjustRatio.toUint() == 0) return false;

        Decimal.decimal memory oraclePrice = Decimal.decimal(_oraclePrice);
        Decimal.decimal memory AMMPrice = quoteAssetReserve.divD(baseAssetReserve);
        if (MixedDecimal.fromDecimal(oraclePrice).subD(AMMPrice).abs().cmp(oraclePriceSpreadLimit.mulD(AMMPrice)) > 0) {
            return false;
        }

        Decimal.decimal memory adjustPrice = MixedDecimal
        .fromDecimal(AMMPrice)
        .addD(MixedDecimal.fromDecimal(oraclePrice).subD(AMMPrice).mulD(priceAdjustRatio))
        .abs();

        // baseAssetReserve * oraclePrice * baseAssetReserve = invariant
        Decimal.decimal memory invariant = quoteAssetReserve.mulD(baseAssetReserve);
        uint256 basePow = invariant.divD(adjustPrice).toUint().mul(Decimal.one().toUint());
        Decimal.decimal memory _baseAssetReserve = Decimal.decimal(basePow.sqrt());
        Decimal.decimal memory _quoteAssetReserve = invariant.divD(_baseAssetReserve);

        SignedDecimal.signedDecimal memory MMPNL = getMMUnrealizedPNL(_baseAssetReserve, _quoteAssetReserve);
        SignedDecimal.signedDecimal memory MMLiquidity = sakePerpVault.getTotalMMAvailableLiquidity(address(this));
        Decimal.decimal memory MMCachedLiquidity = sakePerpVault.getTotalMMCachedLiquidity(address(this));

        // negative means MM can't pay for this price movement
        if (MMPNL.addD(MMLiquidity).addD(MMCachedLiquidity).isNegative()) {
            return false;
        }

        return true;
    }

    function getCurrentFundingRate() public view returns (int256, int256) {
        uint256 twapInterval = spotPriceTwapInterval;

        // lastFundingTime = nextFundingTime - fundingPeriod
        // twapInterval = _blockTimestamp() - lastFundingTime = _blockTimestamp() + fundingPeriod - nextFundingTime
        if (_blockTimestamp() < nextFundingTime && _blockTimestamp().add(fundingPeriod) > nextFundingTime) {
            twapInterval = _blockTimestamp().add(fundingPeriod).sub(nextFundingTime);
        }
        SignedDecimal.signedDecimal memory premiumFraction = SignedDecimal.zero();
        Decimal.decimal memory underlyingPrice = getUnderlyingTwapPrice(twapInterval);

        // premium = twapMarketPrice - twapIndexPrice
        // timeFraction = fundingPeriod(1 hour) / 1 day
        // premiumFraction = premium * timeFraction
        SignedDecimal.signedDecimal memory premium = MixedDecimal.fromDecimal(getTwapPrice(twapInterval)).subD(
            underlyingPrice
        );
        premiumFraction = premium.mulScalar(twapInterval).divScalar(int256(1 days));

        SignedDecimal.signedDecimal memory longPremiumFraction = premiumFraction;
        SignedDecimal.signedDecimal memory shortPremiumFraction = premiumFraction;
        if (premiumFraction.mulD(totalPositionSize).isNegative()) {
            if (premiumFraction.isNegative()) {
                longPremiumFraction = shortPositionSize.mulD(premiumFraction).divD(longPositionSize);
            } else {
                shortPremiumFraction = longPositionSize.mulD(premiumFraction).divD(shortPositionSize);
            }
        }

        SignedDecimal.signedDecimal memory longFundingRateNow = longPremiumFraction.divD(underlyingPrice);
        SignedDecimal.signedDecimal memory shortFundingRateNow = shortPremiumFraction.divD(underlyingPrice);
        return (longFundingRateNow.toInt(), shortFundingRateNow.toInt());
    }

    function setInitialPosition(int256 long, int256 short) external onlyOwner {
        longPositionSize = SignedDecimal.signedDecimal(long);
        shortPositionSize = SignedDecimal.signedDecimal(short);
    }
}