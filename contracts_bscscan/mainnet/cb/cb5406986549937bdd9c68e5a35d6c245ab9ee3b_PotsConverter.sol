/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

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
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


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


// File @openzeppelin/contracts-upgradeable/math/[email protected]


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
library SafeMathUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File contracts/infra/IGateManagerMultiRewards.sol

pragma solidity ^0.6.12;

interface IGateManagerMultiRewards {
    function notifyRewardAmount(uint256 rid, uint256 reward) external;
    function userTotalBalance(address user) external view returns (uint256);
    function earned(address account, uint256 id) external view returns (uint256);
    function depositMoonPot(address user, uint256 amount, address referrer) external;
    function getReward(address user, uint256 id) external;
    function getReward(address user) external;
    function compound(address user) external;
}


// File contracts/infra/IUniswapRouterETH.sol


pragma solidity ^0.6.0;

interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}


// File contracts/infra/PotsConverter.sol


pragma solidity ^0.6.12;
interface ReserveInterface {
    function withdrawReserve(address prizePool, address to) external;
    function transferOwnership(address owner) external;
    function setRateMantissa(uint256 rate) external;
}

interface IBeltLP {
    function underlying_coins(int128 i) external view returns (address);
    function add_liquidity(uint256[4] memory uamounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _amount, uint256[4] memory min_amounts) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount) external;
}

contract PotsConverter is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // All single asset Pots
    struct SinglePrizes {
        address prizePool;
        address superManager;
        address prizeToken;
        address router;
        address[] route;
        uint128 ziggyAlloc;
        uint128 superAlloc;
        uint128 prizeAlloc;
        uint128 treasuryAlloc;
        uint256 superPotsBal;
    }

    SinglePrizes[] public singlePrize;

    // All LP Pots
    struct LpPrizes {
        address prizePool;
        address prizeToken;
        address router;
        address[] token0Route;
        address[] token1Route;
        uint128 ziggyAlloc;
        uint128 prizeAlloc;
        uint128 treasuryAlloc;
    }

    LpPrizes[] public lpPrize;

    // Belt Pot
    struct BeltPrizes {
        address prizePool;
        address prizeToken;
        address router;
        address[] route;
        uint128 ziggyAlloc;
        uint128 prizeAlloc;
        uint128 treasuryAlloc;
    }

    BeltPrizes[] public beltPrize;

    // Reserves 
    mapping(uint256 => address) public reserveIndex;

    // addresses needed for harvesting
    address public pots;
    address public ziggyManager;
    address public ziggyPrizePool;
    address public harvester;
    address public treasury;
    address public busd;

    // Pots buy back stats weekly
    uint256 public potsBuyBack;
    uint256 public extraPots;

    // Total alloc of reserve distribution
    uint128 public totalAlloc;

    function initialize(
        address _pots, 
        address _ziggyManager, 
        address _ziggyPrizePool,
        address _harvester, 
        address _treasury, 
        address _busd,
        uint128 _totalAlloc
    ) public  initializer {
        pots = _pots;
        ziggyManager = _ziggyManager;
        ziggyPrizePool = _ziggyPrizePool;
        harvester = _harvester;
        treasury = _treasury;
        busd = _busd;
        totalAlloc = _totalAlloc;

        __Ownable_init();
    }

    event NewZiggyPrizePool(address oldPrizePool, address newPrizePool);
    event NewZiggyManager(address oldZiggyManager, address newZiggyManager);
    event NewUnirouter(uint256 prize, address oldUnirouter, address newUnirouter);
    event NewRoute(uint256 prize, address[] oldRoute, address[] newRoute);
    event NewHarvester(address newHarvester, address oldHarvester);
    event NewTreasury(address newTreasury, address oldTreasury);
    event ZiggyNotified(uint256 potsAmt);
    event SuperNotified(address gateManager, uint256 potsAmt);
    event ReserveAdded(uint256 index, address reserve);
    event Harvest(uint256 amount);
    event PotsAdded(uint256 prizeId, uint256 amount);

     modifier onlyHarvester() {
        require(msg.sender == owner() || msg.sender == address(harvester), "!Harvester");
        _;
    }

    // Harvests single pots reserve and splits funds proportionately.
    function singleHarvest(uint256 pid, uint256 index) public onlyHarvester {
            SinglePrizes storage convert = singlePrize[pid];
            ReserveInterface(reserveIndex[index]).withdrawReserve(convert.prizePool, address(this));
            uint256 bal = IERC20Upgradeable(convert.prizeToken).balanceOf(address(this));
            uint256 prizeBal = bal.mul(convert.prizeAlloc).div(totalAlloc);
            IERC20Upgradeable(convert.prizeToken).safeTransfer(ziggyPrizePool, prizeBal);

            uint256 potsIn;
            if (convert.ziggyAlloc > 0) {
                uint256 ziggyBal = bal.mul(convert.ziggyAlloc).div(totalAlloc);
                uint256[] memory amounts = IUniswapRouterETH(convert.router).swapExactTokensForTokens(ziggyBal, 0, convert.route, address(this), now);
                potsIn = amounts[amounts.length - 1];
            } else {
                uint256 superBal = bal.mul(convert.superAlloc).div(totalAlloc);
                uint256[] memory amounts = IUniswapRouterETH(convert.router).swapExactTokensForTokens(superBal, 0, convert.route, address(this), now);
                potsIn = amounts[amounts.length - 1];
                convert.superPotsBal = convert.superPotsBal.add(potsIn);
                extraPots = extraPots.add(potsIn);
            }
            
            potsBuyBack = potsBuyBack.add(potsIn);
            if (convert.treasuryAlloc > 0) {
                uint256 treasuryAlloc = bal.mul(convert.treasuryAlloc).div(totalAlloc);
                IERC20Upgradeable(convert.prizeToken).safeTransfer(treasury, treasuryAlloc);
            }

            emit Harvest(bal);
    }

    // Harvests belt pots reserve and splits funds proportionately.
    function beltHarvest(uint256 pid, uint256 index) public onlyHarvester {
            BeltPrizes storage convert = beltPrize[pid];
            ReserveInterface(reserveIndex[index]).withdrawReserve(convert.prizePool, address(this));
            uint256 lpBal = IERC20Upgradeable(convert.prizeToken).balanceOf(address(this));
            IBeltLP(convert.prizeToken).remove_liquidity_one_coin(lpBal, 3, 0);
            uint256 bal = IERC20Upgradeable(busd).balanceOf(address(this));
            uint256 prizeBal = bal.mul(convert.prizeAlloc).div(totalAlloc);
            IERC20Upgradeable(convert.prizeToken).safeTransfer(ziggyPrizePool, prizeBal);
            uint256 ziggyBal = bal.mul(convert.ziggyAlloc).div(totalAlloc);
            uint256[] memory amounts = IUniswapRouterETH(convert.router).swapExactTokensForTokens(ziggyBal, 0, convert.route, address(this), now);
            uint256 potsIn = amounts[amounts.length - 1];
            potsBuyBack = potsBuyBack.add(potsIn);
            if (convert.treasuryAlloc > 0) {
                uint256 treasuryAlloc = bal.mul(convert.treasuryAlloc).div(totalAlloc);
                IERC20Upgradeable(convert.prizeToken).safeTransfer(treasury, treasuryAlloc);
            }

            emit Harvest(lpBal);
    }

    // Harvests LP pots reserve and splits funds proportionately.
    function lpHarvest(uint256 pid, uint256 index) public onlyHarvester {
            LpPrizes storage convert = lpPrize[pid];
            address token0 = IUniswapV2Pair(convert.prizeToken).token0();
            address token1 = IUniswapV2Pair(convert.prizeToken).token1();
            ReserveInterface(reserveIndex[index]).withdrawReserve(convert.prizePool, address(this));
            uint256 lpBal = IERC20Upgradeable(convert.prizeToken).balanceOf(address(this));
            IUniswapRouterETH(convert.router).removeLiquidity(token0, token1, lpBal, 0, 0, address(this), now);
            uint256 token0Bal = IERC20Upgradeable(token0).balanceOf(address(this));
            uint256 token1Bal = IERC20Upgradeable(token1).balanceOf(address(this));

            uint256 token0PrizeBal = token0Bal.mul(convert.prizeAlloc).div(totalAlloc);
            IERC20Upgradeable(token0).safeTransfer(ziggyPrizePool, token0PrizeBal);
            if (convert.treasuryAlloc > 0) {
                uint256 token0Treasury = token0Bal.mul(convert.treasuryAlloc).div(totalAlloc);
                IERC20Upgradeable(token0).safeTransfer(treasury, token0Treasury);
            }

            uint256 token1PrizeBal = token1Bal.mul(convert.prizeAlloc).div(totalAlloc);
            IERC20Upgradeable(token1).safeTransfer(ziggyPrizePool, token1PrizeBal);
            if (convert.treasuryAlloc > 0) {
                uint256 token1Treasury = token1Bal.mul(convert.treasuryAlloc).div(totalAlloc);
                IERC20Upgradeable(token1).safeTransfer(treasury, token1Treasury);
            }

            uint256 token0Ziggy = token0Bal.mul(convert.ziggyAlloc).div(totalAlloc);
            uint256[] memory amounts1 = IUniswapRouterETH(convert.router).swapExactTokensForTokens(token0Ziggy, 0, convert.token0Route, address(this), now);
            uint256 token1Ziggy = token1Bal.mul(convert.ziggyAlloc).div(totalAlloc);
            uint256[] memory amounts2 = IUniswapRouterETH(convert.router).swapExactTokensForTokens(token1Ziggy, 0, convert.token1Route, address(this), now);
            uint256 potsIn = amounts1[amounts1.length - 1 ] + amounts2[amounts2.length - 1];
            potsBuyBack = potsBuyBack.add(potsIn);

            emit Harvest(lpBal);
    }

    function notifyPots() external onlyOwner {
        uint256 potsBal = IERC20Upgradeable(pots).balanceOf(address(this));
        uint256 rewardablePots = potsBal.sub(extraPots);
        IERC20Upgradeable(pots).safeTransfer(ziggyManager, rewardablePots);
        IGateManagerMultiRewards(ziggyManager).notifyRewardAmount(0, rewardablePots);
        potsBuyBack = 0;
        emit ZiggyNotified(rewardablePots);
    }

    function notifySuperGM(uint256 superPool, uint256 potsRewardId) external onlyOwner {
        IERC20Upgradeable(pots).safeTransfer(singlePrize[superPool].superManager, singlePrize[superPool].superPotsBal);
        IGateManagerMultiRewards(singlePrize[superPool].superManager).notifyRewardAmount(potsRewardId, singlePrize[superPool].superPotsBal);
        emit SuperNotified(singlePrize[superPool].superManager, singlePrize[superPool].superPotsBal);
        extraPots = extraPots.sub(singlePrize[superPool].superPotsBal);
        singlePrize[superPool].superPotsBal = 0;
    }

    // Adds new reward token to the gate manager
    function addLpPrizeToken(
        address _prizePool,
        address _prizeToken,
        address _router,
        address[] memory _token0Route,
        address[] memory _token1Route,
        uint128 _ziggyAlloc,
        uint128 _prizeAlloc, 
        uint128 _treasuryAlloc
    ) external onlyOwner {
        uint256 allocInput = _ziggyAlloc + _prizeAlloc + _treasuryAlloc;
        require(allocInput == totalAlloc, "!Alloc won't work");
        address token0 = IUniswapV2Pair(_prizeToken).token0();
        address token1 = IUniswapV2Pair(_prizeToken).token1();
        IERC20Upgradeable(_prizeToken).safeApprove(_router, uint256(-1));
        IERC20Upgradeable(token0).safeApprove(_router, 0);
        IERC20Upgradeable(token0).safeApprove(_router, uint256(-1));
        IERC20Upgradeable(token1).safeApprove(_router, 0);
        IERC20Upgradeable(token1).safeApprove(_router, uint256(-1));
        lpPrize.push(
            LpPrizes({
                prizePool: _prizePool,
                prizeToken: _prizeToken,
                router: _router,
                token0Route: _token0Route,
                token1Route: _token1Route,
                ziggyAlloc: _ziggyAlloc,
                prizeAlloc: _prizeAlloc,
                treasuryAlloc: _treasuryAlloc
            })
        );
    }

    // Adds new reward token to the gate manager
    function addSinglePrizeToken(
        address _prizePool,
        address _superManager,
        address _prizeToken,
        address _router,
        address[] memory _route,
        uint128 _ziggyAlloc,
        uint128 _superAlloc,
        uint128 _prizeAlloc, 
        uint128 _treasuryAlloc
    ) external onlyOwner {
        uint256 allocInput = _ziggyAlloc + _prizeAlloc + _treasuryAlloc + _superAlloc;
        require(allocInput == totalAlloc, "!Alloc won't work");
        IERC20Upgradeable(_prizeToken).safeApprove(_router, 0);
        IERC20Upgradeable(_prizeToken).safeApprove(_router, uint256(-1));
        singlePrize.push(
            SinglePrizes({
                prizePool: _prizePool,
                superManager: _superManager,
                prizeToken: _prizeToken,
                router: _router,
                route: _route,
                ziggyAlloc: _ziggyAlloc,
                superAlloc: _superAlloc,
                prizeAlloc: _prizeAlloc,
                treasuryAlloc: _treasuryAlloc,
                superPotsBal: 0

            })
        );
    }

    // Adds new reward token to the gate manager
    function addBeltPrizeToken(
        address _prizePool,
        address _prizeToken,
        address _router,
        address[] memory _route,
        uint128 _ziggyAlloc,
        uint128 _prizeAlloc, 
        uint128 _treasuryAlloc
    ) external onlyOwner {
        uint256 allocInput = _ziggyAlloc + _prizeAlloc + _treasuryAlloc;
        require(allocInput == totalAlloc, "!Alloc won't work");
        IERC20Upgradeable(_prizeToken).safeApprove(_prizeToken, uint(-1));
        IERC20Upgradeable(busd).safeApprove(_router, 0);
        IERC20Upgradeable(busd).safeApprove(_router, uint256(-1));
        beltPrize.push(
            BeltPrizes({
                prizePool: _prizePool,
                prizeToken: _prizeToken,
                router: _router,
                route: _route,
                ziggyAlloc: _ziggyAlloc,
                prizeAlloc: _prizeAlloc,
                treasuryAlloc: _treasuryAlloc
            })
        );
    }

    function depositPotsForRewards(uint256 _singlePrizeId, uint256 _amount) external {
        IERC20Upgradeable(pots).safeTransferFrom(msg.sender, address(this), _amount);
        singlePrize[_singlePrizeId].superPotsBal = singlePrize[_singlePrizeId].superPotsBal.add(_amount);
        extraPots = extraPots.add(_amount);
        emit PotsAdded(_singlePrizeId, _amount);
    }

    function addReserve(uint256 index, address reserve) external onlyOwner {
            emit ReserveAdded(index, reserve);
            reserveIndex[index] = reserve;
    }

    function singleRoute(uint256 prizeId) external view returns (address[] memory route ) {
            route = singlePrize[prizeId].route;
    }

    function lpRoute(uint256 prizeId) external view returns (address[] memory token0Route, address[] memory token1Route ) {
            token0Route = lpPrize[prizeId].token0Route;
            token1Route = lpPrize[prizeId].token1Route;
    }

    function beltRoute(uint256 prizeId) external view returns (address[] memory route ) {
            route = beltPrize[prizeId].route;
    }

    // Manage the contract
    function setPrizePool(address _prizePool) external onlyOwner {
        emit NewZiggyPrizePool(ziggyPrizePool, _prizePool);
        ziggyPrizePool = _prizePool;
    }

    function setTreasury(address _treasury) external onlyOwner {
        emit NewTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    function setZiggyManager(address _ziggyManager) external onlyOwner {
        emit NewZiggyManager(ziggyManager, _ziggyManager);
        ziggyManager = _ziggyManager;
    }

    function setHarvester(address _harvester) external onlyOwner {
        emit NewHarvester(harvester, _harvester);
        harvester = _harvester;
    }

    function setSingleUnirouter(uint256 prizeId, address _router) external onlyOwner {
        emit NewUnirouter(prizeId, singlePrize[prizeId].router, _router);

        IERC20Upgradeable(singlePrize[prizeId].prizeToken).safeApprove(_router, uint256(-1));
        IERC20Upgradeable(singlePrize[prizeId].prizeToken).safeApprove(singlePrize[prizeId].router, 0);

        singlePrize[prizeId].router = _router;
    }

    function setLpUnirouter(uint256 prizeId, address _router) external onlyOwner {
        emit NewUnirouter(prizeId, lpPrize[prizeId].router, _router);

        address token0 = IUniswapV2Pair(lpPrize[prizeId].prizeToken).token0();
        address token1 = IUniswapV2Pair(lpPrize[prizeId].prizeToken).token1();

        uint256 token0Allowance = IERC20Upgradeable(token0).allowance(address(this), _router);
        if (token0Allowance == 0) {
            IERC20Upgradeable(token0).safeApprove(_router, uint256(-1));
            }
               
        uint256 token1Allowance = IERC20Upgradeable(token1).allowance(address(this), _router);
        if (token1Allowance == 0) {
            IERC20Upgradeable(token1).safeApprove(_router, uint256(-1));
            }          

        uint256 prizeTokenAllowance = IERC20Upgradeable(lpPrize[prizeId].prizeToken).allowance(address(this), _router);
        IERC20Upgradeable(lpPrize[prizeId].prizeToken).safeApprove(_router, uint256(-1));
        IERC20Upgradeable(lpPrize[prizeId].prizeToken).safeApprove(lpPrize[prizeId].router, 0);

        lpPrize[prizeId].router = _router;
    }

    function setSingleRoute(uint256 prizeId, address[] memory _route) external onlyOwner {
        require(_route[0] == singlePrize[prizeId].prizeToken);
        require(_route[_route.length - 1] == pots);

        singlePrize[prizeId].route = _route;
    }

    function setLpRoutes(uint256 prizeId, address[] memory _token0Route, address[] memory _token1Route) external onlyOwner {
        address token0 = IUniswapV2Pair(lpPrize[prizeId].prizeToken).token0();
        address token1 = IUniswapV2Pair(lpPrize[prizeId].prizeToken).token1();
        require(_token0Route[0] == token0, "first token needs to be token0");
        require(_token1Route[0] == token1, "first token needs to be token1");
        require(_token0Route[_token0Route.length - 1] == pots, "Token 0 route needs to end in POTS");
        require(_token1Route[_token1Route.length - 1] == pots, "Token 1 route needs to end in POTS");

        lpPrize[prizeId].token0Route = _token0Route;
        lpPrize[prizeId].token1Route = _token1Route;
    }

    function transferReserveOwner(uint256 index, address owner) external onlyOwner {
        ReserveInterface(reserveIndex[index]).transferOwnership(owner);
    }

    function setReserveRateMantissa(uint256 index, uint256 _rate) external onlyOwner {
        ReserveInterface(reserveIndex[index]).setRateMantissa(_rate);
    }
    
    // Rescue locked funds sent by mistake
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(msg.sender, amount);
    }
}