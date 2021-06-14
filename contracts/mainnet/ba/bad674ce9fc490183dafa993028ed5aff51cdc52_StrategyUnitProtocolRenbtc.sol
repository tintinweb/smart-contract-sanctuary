/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// Sources flattened with hardhat v2.0.5 https://hardhat.org

// File deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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


// File deps/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


// File deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol



pragma solidity ^0.6.0;

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


// File deps/@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol



pragma solidity ^0.6.0;



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


// File interfaces/curve/ICurveGauge.sol


pragma solidity >=0.5.0 <0.8.0;

interface ICurveGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function balanceOf(address arg0) external view returns (uint256);

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool claim_rewards) external;

    function claim_rewards() external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external view returns (uint256);

    function claimable_reward(address addr) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);
}


// File interfaces/curve/ICurveMintr.sol


pragma solidity >=0.5.0 <0.8.0;

interface ICurveMintr {
    function mint(address) external;

    function minted(address arg0, address arg1) external view returns (uint256);
}


// File interfaces/curve/ICurveFi.sol


pragma solidity >=0.5.0 <0.8.0;

interface ICurveFi {
    function get_virtual_price() external view returns (uint256 out);

    function add_liquidity(
        // renbtc/tbtc pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256 out);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256 out);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256 deadline,
        uint256[2] calldata min_amounts
    ) external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 deadline) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;

    function commit_new_parameters(
        int128 amplification,
        int128 new_fee,
        int128 new_admin_fee
    ) external;

    function apply_new_parameters() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function coins(int128 arg0) external returns (address out);

    function underlying_coins(int128 arg0) external returns (address out);

    function balances(int128 arg0) external returns (uint256 out);

    function A() external returns (int128 out);

    function fee() external returns (int128 out);

    function admin_fee() external returns (int128 out);

    function owner() external returns (address out);

    function admin_actions_deadline() external returns (uint256 out);

    function transfer_ownership_deadline() external returns (uint256 out);

    function future_A() external returns (int128 out);

    function future_fee() external returns (int128 out);

    function future_admin_fee() external returns (int128 out);

    function future_owner() external returns (address out);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 _i) external view returns (uint256 out);
}


// File interfaces/curve/ICurveExchange.sol

pragma solidity >=0.6.0;

interface ICurveExchange {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256 amount);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts) external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amounts,
        int128 i,
        uint256 min_amount
    ) external;
}

interface ICurveRegistryAddressProvider {
    function get_address(uint256 id) external returns (address);
}

interface ICurveRegistryExchange {
    function get_best_rate(
        address from,
        address to,
        uint256 amount
    ) external view returns (address, uint256);

    function exchange(
        address pool,
        address from,
        address to,
        uint256 amount,
        uint256 expected,
        address receiver
    ) external payable returns (uint256);
}


// File deps/@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol



pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol



pragma solidity >=0.4.24 <0.7.0;


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


// File deps/@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol



pragma solidity ^0.6.0;

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


// File deps/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol



pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}


// File interfaces/uniswap/IUniswapRouterV2.sol


pragma solidity >=0.5.0 <0.8.0;

interface IUniswapRouterV2 {
    function factory() external view returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}


// File interfaces/badger/IController.sol


pragma solidity >=0.5.0 <0.8.0;

interface IController {
    function withdraw(address, uint256) external;

    function strategies(address) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);
}


// File interfaces/badger/IStrategy.sol




pragma solidity >=0.5.0 <0.8.0;

interface IStrategy {
    function want() external view returns (address);

    function deposit() external;

    // NOTE: must exclude any tokens used in the yield
    // Controller role - withdraw should return to Controller
    function withdrawOther(address) external returns (uint256 balance);

    // Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function getName() external pure returns (string memory);

    function setStrategist(address _strategist) external;

    function setWithdrawalFee(uint256 _withdrawalFee) external;

    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external;

    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external;

    function setGovernance(address _governance) external;

    function setController(address _controller) external;

    function tend() external;

    function harvest() external;
}


// File contracts/badger-sett/SettAccessControl.sol


pragma solidity ^0.6.11;

/*
    Common base for permissioned roles throughout Sett ecosystem
*/
contract SettAccessControl is Initializable {
    address public governance;
    address public strategist;
    address public keeper;

    // ===== MODIFIERS =====
    function _onlyGovernance() internal view {
        require(msg.sender == governance, "onlyGovernance");
    }

    function _onlyGovernanceOrStrategist() internal view {
        require(msg.sender == strategist || msg.sender == governance, "onlyGovernanceOrStrategist");
    }

    function _onlyAuthorizedActors() internal view {
        require(msg.sender == keeper || msg.sender == governance, "onlyAuthorizedActors");
    }

    // ===== PERMISSIONED ACTIONS =====

    /// @notice Change strategist address
    /// @notice Can only be changed by governance itself
    function setStrategist(address _strategist) external {
        _onlyGovernance();
        strategist = _strategist;
    }

    /// @notice Change keeper address
    /// @notice Can only be changed by governance itself
    function setKeeper(address _keeper) external {
        _onlyGovernance();
        keeper = _keeper;
    }

    /// @notice Change governance address
    /// @notice Can only be changed by governance itself
    function setGovernance(address _governance) public {
        _onlyGovernance();
        governance = _governance;
    }

    uint256[50] private __gap;
}


// File contracts/badger-sett/strategies/BaseStrategy.sol



pragma solidity ^0.6.11;










/*
    ===== Badger Base Strategy =====
    Common base class for all Sett strategies

    Changelog
    V1.1
    - Verify amount unrolled from strategy positions on withdraw() is within a threshold relative to the requested amount as a sanity check
    - Add version number which is displayed with baseStrategyVersion(). If a strategy does not implement this function, it can be assumed to be 1.0

    V1.2
    - Remove idle want handling from base withdraw() function. This should be handled as the strategy sees fit in _withdrawSome()
*/
abstract contract BaseStrategy is PausableUpgradeable, SettAccessControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    event Withdraw(uint256 amount);
    event WithdrawAll(uint256 balance);
    event WithdrawOther(address token, uint256 amount);
    event SetStrategist(address strategist);
    event SetGovernance(address governance);
    event SetController(address controller);
    event SetWithdrawalFee(uint256 withdrawalFee);
    event SetPerformanceFeeStrategist(uint256 performanceFeeStrategist);
    event SetPerformanceFeeGovernance(uint256 performanceFeeGovernance);
    event Harvest(uint256 harvested, uint256 indexed blockNumber);
    event Tend(uint256 tended);

    address public want; // Want: Curve.fi renBTC/wBTC (crvRenWBTC) LP token

    uint256 public performanceFeeGovernance;
    uint256 public performanceFeeStrategist;
    uint256 public withdrawalFee;

    uint256 public constant MAX_FEE = 10000;
    address public constant uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Dex

    address public controller;
    address public guardian;

    uint256 public withdrawalMaxDeviationThreshold;

    function __BaseStrategy_init(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian
    ) public initializer whenNotPaused {
        __Pausable_init();
        governance = _governance;
        strategist = _strategist;
        keeper = _keeper;
        controller = _controller;
        guardian = _guardian;
        withdrawalMaxDeviationThreshold = 50;
    }

    // ===== Modifiers =====

    function _onlyController() internal view {
        require(msg.sender == controller, "onlyController");
    }

    function _onlyAuthorizedActorsOrController() internal view {
        require(msg.sender == keeper || msg.sender == governance || msg.sender == controller, "onlyAuthorizedActorsOrController");
    }

    function _onlyAuthorizedPausers() internal view {
        require(msg.sender == guardian || msg.sender == governance, "onlyPausers");
    }

    /// ===== View Functions =====
    function baseStrategyVersion() public view returns (string memory) {
        return "1.2";
    }

    /// @notice Get the balance of want held idle in the Strategy
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Get the total balance of want realized in the strategy, whether idle or active in Strategy positions.
    function balanceOf() public virtual view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function isTendable() public virtual view returns (bool) {
        return false;
    }

    /// ===== Permissioned Actions: Governance =====

    function setGuardian(address _guardian) external {
        _onlyGovernance();
        guardian = _guardian;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        _onlyGovernance();
        require(_withdrawalFee <= MAX_FEE, "base-strategy/excessive-withdrawal-fee");
        withdrawalFee = _withdrawalFee;
    }

    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external {
        _onlyGovernance();
        require(_performanceFeeStrategist <= MAX_FEE, "base-strategy/excessive-strategist-performance-fee");
        performanceFeeStrategist = _performanceFeeStrategist;
    }

    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external {
        _onlyGovernance();
        require(_performanceFeeGovernance <= MAX_FEE, "base-strategy/excessive-governance-performance-fee");
        performanceFeeGovernance = _performanceFeeGovernance;
    }

    function setController(address _controller) external {
        _onlyGovernance();
        controller = _controller;
    }

    function setWithdrawalMaxDeviationThreshold(uint256 _threshold) external {
        _onlyGovernance();
        require(_threshold <= MAX_FEE, "base-strategy/excessive-max-deviation-threshold");
        withdrawalMaxDeviationThreshold = _threshold;
    }

    function deposit() public virtual whenNotPaused {
        _onlyAuthorizedActorsOrController();
        uint256 _want = IERC20Upgradeable(want).balanceOf(address(this));
        if (_want > 0) {
            _deposit(_want);
        }
        _postDeposit();
    }

    // ===== Permissioned Actions: Controller =====

    /// @notice Controller-only function to Withdraw partial funds, normally used with a vault withdrawal
    function withdrawAll() external virtual whenNotPaused returns (uint256 balance) {
        _onlyController();

        _withdrawAll();

        _transferToVault(IERC20Upgradeable(want).balanceOf(address(this)));
    }

    /// @notice Withdraw partial funds from the strategy, unrolling from strategy positions as necessary
    /// @notice Processes withdrawal fee if present
    /// @dev If it fails to recover sufficient funds (defined by withdrawalMaxDeviationThreshold), the withdrawal should fail so that this unexpected behavior can be investigated
    function withdraw(uint256 _amount) external virtual whenNotPaused {
        _onlyController();

        // Withdraw from strategy positions, typically taking from any idle want first.
        _withdrawSome(_amount);
        uint256 _postWithdraw = IERC20Upgradeable(want).balanceOf(address(this));

        // Sanity check: Ensure we were able to retrieve sufficent want from strategy positions
        // If we end up with less than the amount requested, make sure it does not deviate beyond a maximum threshold
        if (_postWithdraw < _amount) {
            uint256 diff = _diff(_amount, _postWithdraw);

            // Require that difference between expected and actual values is less than the deviation threshold percentage
            require(diff <= _amount.mul(withdrawalMaxDeviationThreshold).div(MAX_FEE), "base-strategy/withdraw-exceed-max-deviation-threshold");
        }

        // Return the amount actually withdrawn if less than amount requested
        uint256 _toWithdraw = MathUpgradeable.min(_postWithdraw, _amount);

        // Process withdrawal fee
        uint256 _fee = _processWithdrawalFee(_toWithdraw);

        // Transfer remaining to Vault to handle withdrawal
        _transferToVault(_toWithdraw.sub(_fee));
    }

    // NOTE: must exclude any tokens used in the yield
    // Controller role - withdraw should return to Controller
    function withdrawOther(address _asset) external virtual whenNotPaused returns (uint256 balance) {
        _onlyController();
        _onlyNotProtectedTokens(_asset);

        balance = IERC20Upgradeable(_asset).balanceOf(address(this));
        IERC20Upgradeable(_asset).safeTransfer(controller, balance);
    }

    /// ===== Permissioned Actions: Authoized Contract Pausers =====

    function pause() external {
        _onlyAuthorizedPausers();
        _pause();
    }

    function unpause() external {
        _onlyGovernance();
        _unpause();
    }

    /// ===== Internal Helper Functions =====

    /// @notice If withdrawal fee is active, take the appropriate amount from the given value and transfer to rewards recipient
    /// @return The withdrawal fee that was taken
    function _processWithdrawalFee(uint256 _amount) internal returns (uint256) {
        if (withdrawalFee == 0) {
            return 0;
        }

        uint256 fee = _amount.mul(withdrawalFee).div(MAX_FEE);
        IERC20Upgradeable(want).safeTransfer(IController(controller).rewards(), fee);
        return fee;
    }

    /// @dev Helper function to process an arbitrary fee
    /// @dev If the fee is active, transfers a given portion in basis points of the specified value to the recipient
    /// @return The fee that was taken
    function _processFee(
        address token,
        uint256 amount,
        uint256 feeBps,
        address recipient
    ) internal returns (uint256) {
        if (feeBps == 0) {
            return 0;
        }
        uint256 fee = amount.mul(feeBps).div(MAX_FEE);
        IERC20Upgradeable(token).safeTransfer(recipient, fee);
        return fee;
    }

    /// @dev Reset approval and approve exact amount
    function _safeApproveHelper(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        IERC20Upgradeable(token).safeApprove(recipient, 0);
        IERC20Upgradeable(token).safeApprove(recipient, amount);
    }

    function _transferToVault(uint256 _amount) internal {
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20Upgradeable(want).safeTransfer(_vault, _amount);
    }

    /// @notice Swap specified balance of given token on Uniswap with given path
    function _swap(
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, uniswap, balance);
        IUniswapRouterV2(uniswap).swapExactTokensForTokens(balance, 0, path, address(this), now);
    }

    function _swapEthIn(uint256 balance, address[] memory path) internal {
        IUniswapRouterV2(uniswap).swapExactETHForTokens{value: balance}(0, path, address(this), now);
    }

    function _swapEthOut(
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, uniswap, balance);
        IUniswapRouterV2(uniswap).swapExactTokensForETH(balance, 0, path, address(this), now);
    }

    /// @notice Add liquidity to uniswap for specified token pair, utilizing the maximum balance possible
    function _add_max_liquidity_uniswap(address token0, address token1) internal virtual {
        uint256 _token0Balance = IERC20Upgradeable(token0).balanceOf(address(this));
        uint256 _token1Balance = IERC20Upgradeable(token1).balanceOf(address(this));

        _safeApproveHelper(token0, uniswap, _token0Balance);
        _safeApproveHelper(token1, uniswap, _token1Balance);

        IUniswapRouterV2(uniswap).addLiquidity(token0, token1, _token0Balance, _token1Balance, 0, 0, address(this), block.timestamp);
    }

    /// @notice Utility function to diff two numbers, expects higher value in first position
    function _diff(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "diff/expected-higher-number-in-first-position");
        return a.sub(b);
    }

    // ===== Abstract Functions: To be implemented by specific Strategies =====

    /// @dev Internal deposit logic to be implemented by Stratgies
    function _deposit(uint256 _want) internal virtual;

    function _postDeposit() internal virtual {
        //no-op by default
    }

    /// @notice Specify tokens used in yield process, should not be available to withdraw via withdrawOther()
    function _onlyNotProtectedTokens(address _asset) internal virtual;

    function getProtectedTokens() external virtual view returns (address[] memory);

    /// @dev Internal logic for strategy migration. Should exit positions as efficiently as possible
    function _withdrawAll() internal virtual;

    /// @dev Internal logic for partial withdrawals. Should exit positions as efficiently as possible.
    /// @dev The withdraw() function shell automatically uses idle want in the strategy before attempting to withdraw more using this
    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    /// @dev Realize returns from positions
    /// @dev Returns can be reinvested into positions, or distributed in another fashion
    /// @dev Performance fees should also be implemented in this function
    /// @dev Override function stub is removed as each strategy can have it's own return signature for STATICCALL
    // function harvest() external virtual;

    /// @dev User-friendly name for this strategy for purposes of convenient reading
    function getName() external virtual pure returns (string memory);

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public virtual view returns (uint256);

    uint256[49] private __gap;
}


// File interfaces/unitprotocol/IUnitProtocol.sol

pragma solidity 0.6.12;

interface IUnitVaultParameters {
    function tokenDebtLimit(address asset) external view returns (uint256);
}

interface IUnitVault {
    function calculateFee(
        address asset,
        address user,
        uint256 amount
    ) external view returns (uint256);

    function getTotalDebt(address asset, address user) external view returns (uint256);

    function debts(address asset, address user) external view returns (uint256);

    function collaterals(address asset, address user) external view returns (uint256);

    function tokenDebts(address asset) external view returns (uint256);
}

interface IUnitCDPManager {
    function exit(
        address asset,
        uint256 assetAmount,
        uint256 usdpAmount
    ) external returns (uint256);

    function join(
        address asset,
        uint256 assetAmount,
        uint256 usdpAmount
    ) external;
	
    function oracleRegistry() external view returns (address);
}

interface IUnitUsdOracle {
    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is $1
    function assetToUsd(address asset, uint amount) external view returns (uint);
}

interface IUnitOracleRegistry {
    function oracleByAsset(address asset) external view returns (address);
}


// File interfaces/chainlink/IChainlink.sol

pragma solidity 0.6.12;

interface IChainlinkAggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}


// File contracts/badger-sett/strategies/unitprotocol/StrategyUnitProtocolMeta.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;




abstract contract StrategyUnitProtocolMeta is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    // Unit Protocol module: https://github.com/unitprotocol/core/blob/master/CONTRACTS.md
    address public constant cdpMgr01 = 0x0e13ab042eC5AB9Fc6F43979406088B9028F66fA;
    address public constant unitVault = 0xb1cFF81b9305166ff1EFc49A129ad2AfCd7BCf19;
    address public constant unitVaultParameters = 0xB46F8CF42e504Efe8BEf895f848741daA55e9f1D;
    address public constant debtToken = 0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address public constant eth_usd = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    bool public useUnitUsdOracle = true;

    // sub-strategy related constants
    address public collateral;
    uint256 public collateralDecimal = 1e18;
    address public unitOracle;
    uint256 public collateralPriceDecimal = 1;
    bool public collateralPriceEth = false;

    // configurable minimum collateralization percent this strategy would hold for CDP
    uint256 public minRatio = 200;
    // collateralization percent buffer in CDP debt actions
    uint256 public ratioBuff = 200;
    uint256 public constant ratioBuffMax = 10000;
    uint public constant Q112 = 2 ** 112;

    // **** Modifiers **** //

    function _onlyCDPInUse() internal view {
        uint256 collateralAmt = getCollateralBalance();
        require(collateralAmt > 0, "!zeroCollateral");

        uint256 debtAmt = getDebtBalance();
        require(debtAmt > 0, "!zeroDebt");
    }

    // **** Getters ****

    function getCollateralBalance() public view returns (uint256) {
        return IUnitVault(unitVault).collaterals(collateral, address(this));
    }

    function getDebtBalance() public view returns (uint256) {
        return IUnitVault(unitVault).getTotalDebt(collateral, address(this));
    }

    function getDebtWithoutFee() public view returns (uint256) {
        return IUnitVault(unitVault).debts(collateral, address(this));
    }

    function debtLimit() public view returns (uint256) {
        return IUnitVaultParameters(unitVaultParameters).tokenDebtLimit(collateral);
    }

    function debtUsed() public view returns (uint256) {
        return IUnitVault(unitVault).tokenDebts(collateral);
    }

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public override view returns (uint256) {
        return getCollateralBalance();
    }

    function collateralValue(uint256 collateralAmt) public view returns (uint256) {
        uint256 collateralPrice = getLatestCollateralPrice();
        return collateralAmt.mul(collateralPrice).mul(1e18).div(collateralDecimal).div(collateralPriceDecimal); // debtToken in 1e18 decimal
    }

    function currentRatio() public view returns (uint256) {
        _onlyCDPInUse();
        uint256 collateralAmt = collateralValue(getCollateralBalance()).mul(100);
        uint256 debtAmt = getDebtBalance();
        return collateralAmt.div(debtAmt);
    }

    // if borrow is true (for addCollateralAndBorrow): return (maxDebt - currentDebt) if positive value, otherwise return 0
    // if borrow is false (for repayAndRedeemCollateral): return (currentDebt - maxDebt) if positive value, otherwise return 0
    function calculateDebtFor(uint256 collateralAmt, bool borrow) public view returns (uint256) {
        uint256 maxDebt = collateralAmt > 0? collateralValue(collateralAmt).mul(ratioBuffMax).div(_getBufferedMinRatio(ratioBuffMax)) : 0;

        uint256 debtAmt = getDebtBalance();

        uint256 debt = 0;

        if (borrow && maxDebt >= debtAmt) {
            debt = maxDebt.sub(debtAmt);
        } else if (!borrow && debtAmt >= maxDebt) {
            debt = debtAmt.sub(maxDebt);
        }

        return (debt > 0) ? debt : 0;
    }

    function _getBufferedMinRatio(uint256 _multiplier) internal view returns (uint256) {
        require(ratioBuffMax > 0, "!ratioBufferMax");
        require(minRatio > 0, "!minRatio");
        return minRatio.mul(_multiplier).mul(ratioBuffMax.add(ratioBuff)).div(ratioBuffMax).div(100);
    }

    function borrowableDebt() public view returns (uint256) {
        uint256 collateralAmt = getCollateralBalance();
        return calculateDebtFor(collateralAmt, true);
    }

    function requiredPaidDebt(uint256 _redeemCollateralAmt) public view returns (uint256) {
        uint256 totalCollateral = getCollateralBalance();
        uint256 collateralAmt = _redeemCollateralAmt >= totalCollateral? 0 : totalCollateral.sub(_redeemCollateralAmt);
        return calculateDebtFor(collateralAmt, false);
    }

    // **** sub-strategy implementation ****
    function _depositUSDP(uint256 _usdpAmt) internal virtual;

    function _withdrawUSDP(uint256 _usdpAmt) internal virtual;

    // **** Oracle (using chainlink) ****

    function getLatestCollateralPrice() public view returns (uint256) {
        if (useUnitUsdOracle){
            address unitOracleRegistry = IUnitCDPManager(cdpMgr01).oracleRegistry();
            address unitUsdOracle = IUnitOracleRegistry(unitOracleRegistry).oracleByAsset(collateral);
            uint usdPriceInQ122 = IUnitUsdOracle(unitUsdOracle).assetToUsd(collateral, collateralDecimal);
            return uint256(usdPriceInQ122 / Q112).mul(collateralPriceDecimal).div(1e18);// usd price from unit protocol oracle in 1e18 decimal		
        }
	
        require(unitOracle != address(0), "!_collateralOracle");

        (, int256 price, , , ) = IChainlinkAggregator(unitOracle).latestRoundData();

        if (price > 0) {
            if (collateralPriceEth) {
                (, int256 ethPrice, , , ) = IChainlinkAggregator(eth_usd).latestRoundData(); // eth price from chainlink in 1e8 decimal
                return uint256(price).mul(collateralPriceDecimal).mul(uint256(ethPrice)).div(1e8).div(collateralPriceEth ? 1e18 : 1);
            } else{
                return uint256(price).mul(collateralPriceDecimal).div(1e8);
            }
        } else {
            return 0;
        }
    }

    // **** Setters ****

    function setMinRatio(uint256 _minRatio) external {
        _onlyGovernance();
        minRatio = _minRatio;
    }

    function setRatioBuff(uint256 _ratioBuff) external {
        _onlyGovernance();
        ratioBuff = _ratioBuff;
    }

    function setUseUnitUsdOracle(bool _useUnitUsdOracle) external {
        _onlyGovernance();
        useUnitUsdOracle = _useUnitUsdOracle;
    }

    // **** Unit Protocol CDP actions ****

    function addCollateralAndBorrow(uint256 _collateralAmt, uint256 _usdpAmt) internal {
        require(_usdpAmt.add(debtUsed()) < debtLimit(), "!exceedLimit");
        _safeApproveHelper(collateral, unitVault, _collateralAmt);
        IUnitCDPManager(cdpMgr01).join(collateral, _collateralAmt, _usdpAmt);
    }

    function repayAndRedeemCollateral(uint256 _collateralAmt, uint256 _usdpAmt) internal {
        _safeApproveHelper(debtToken, unitVault, _usdpAmt);
        IUnitCDPManager(cdpMgr01).exit(collateral, _collateralAmt, _usdpAmt);
    }

    // **** State Mutation functions ****

    function keepMinRatio() external {
        _onlyCDPInUse();
        _onlyAuthorizedActorsOrController();

        uint256 requiredPaidback = requiredPaidDebt(0);
        if (requiredPaidback > 0) {
            _withdrawUSDP(requiredPaidback);

            uint256 _currentDebtVal = IERC20Upgradeable(debtToken).balanceOf(address(this));
            uint256 _actualPaidDebt = _currentDebtVal;
            uint256 _totalDebtWithoutFee = getDebtWithoutFee();
            uint256 _fee = getDebtBalance().sub(_totalDebtWithoutFee);

            require(_actualPaidDebt > _fee, "!notEnoughForFee");
            _actualPaidDebt = _actualPaidDebt.sub(_fee); // unit protocol will charge fee first
            _actualPaidDebt = _capMaxDebtPaid(_actualPaidDebt, _totalDebtWithoutFee);

            require(_currentDebtVal >= _actualPaidDebt.add(_fee), "!notEnoughRepayment");
            repayAndRedeemCollateral(0, _actualPaidDebt);
        }
    }

    /// @dev Internal deposit logic to be implemented by Strategies
    function _deposit(uint256 _want) internal override {
        if (_want > 0) {
            uint256 _newDebt = calculateDebtFor(_want.add(getCollateralBalance()), true);
            if (_newDebt > 0) {
                addCollateralAndBorrow(_want, _newDebt);
                uint256 wad = IERC20Upgradeable(debtToken).balanceOf(address(this));
                _depositUSDP(_newDebt > wad ? wad : _newDebt);
            }
        }
    }

    // to avoid repay all debt resulting to close the CDP unexpectedly
    function _capMaxDebtPaid(uint256 _actualPaidDebt, uint256 _totalDebtWithoutFee) internal view returns (uint256) {
        uint256 _maxDebtToRepay = _totalDebtWithoutFee.sub(ratioBuffMax);
        return _actualPaidDebt >= _maxDebtToRepay ? _maxDebtToRepay : _actualPaidDebt;
    }

    /// @dev Internal logic for partial withdrawals. Should exit positions as efficiently as possible.
    /// @dev The withdraw() function shell automatically uses idle want in the strategy before attempting to withdraw more using this
    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        if (_amount == 0) {
            return _amount;
        }

        uint256 requiredPaidback = requiredPaidDebt(_amount);
        if (requiredPaidback > 0) {
            _withdrawUSDP(requiredPaidback);
        }

        bool _fullWithdraw = _amount >= balanceOfPool();
        uint256 _wantBefore = IERC20Upgradeable(want).balanceOf(address(this));
        if (!_fullWithdraw) {
            uint256 _currentDebtVal = IERC20Upgradeable(debtToken).balanceOf(address(this));
            uint256 _actualPaidDebt = _currentDebtVal;
            uint256 _totalDebtWithoutFee = getDebtWithoutFee();
            uint256 _fee = getDebtBalance().sub(_totalDebtWithoutFee);

            require(_actualPaidDebt > _fee, "!notEnoughForFee");
            _actualPaidDebt = _actualPaidDebt.sub(_fee); // unit protocol will charge fee first
            _actualPaidDebt = _capMaxDebtPaid(_actualPaidDebt, _totalDebtWithoutFee);

            require(_currentDebtVal >= _actualPaidDebt.add(_fee), "!notEnoughRepayment");
            repayAndRedeemCollateral(_amount, _actualPaidDebt);
        } else {
            require(IERC20Upgradeable(debtToken).balanceOf(address(this)) >= getDebtBalance(), "!notEnoughFullRepayment");
            repayAndRedeemCollateral(_amount, getDebtBalance());
            require(getDebtBalance() == 0, "!leftDebt");
            require(getCollateralBalance() == 0, "!leftCollateral");
        }

        uint256 _wantAfter = IERC20Upgradeable(want).balanceOf(address(this));
        return _wantAfter.sub(_wantBefore);
    }

    /// @dev Internal logic for strategy migration. Should exit positions as efficiently as possible
    function _withdrawAll() internal override {
        _withdrawSome(balanceOfPool());
    }
}


// File contracts/badger-sett/strategies/unitprotocol/StrategyUnitProtocolRenbtc.sol

pragma solidity 0.6.12;

contract StrategyUnitProtocolRenbtc is StrategyUnitProtocolMeta {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    // strategy specific
    address public constant renbtc_collateral = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    uint256 public constant renbtc_collateral_decimal = 1e8;
    address public constant renbtc_oracle = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    uint256 public constant renbtc_price_decimal = 1;
    bool public constant renbtc_price_eth = false;

    // yield-farming in usdp-3crv pool
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant usdp3crv = 0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6;
    address public constant usdp = 0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address public constant usdp_gauge = 0x055be5DDB7A925BfEF3417FC157f53CA77cA7222;
    address public constant curvePool = 0x42d7025938bEc20B69cBae5A77421082407f053A;
    address public constant mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // slippage protection for one-sided ape in/out
    uint256 public slippageProtectionIn = 50; // max 0.5%
    uint256 public slippageProtectionOut = 50; // max 0.5%
    uint256 public keepCRV;

    event RenBTCStratHarvest(
        uint256 crvHarvested,
        uint256 keepCrv,
        uint256 crvRecycled,
        uint256 wantProcessed,
        uint256 wantDeposited,
        uint256 governancePerformanceFee,
        uint256 strategistPerformanceFee
    );

    struct HarvestData {
        uint256 crvHarvested;
        uint256 keepCrv;
        uint256 crvRecycled;
        uint256 wantProcessed;
        uint256 wantDeposited;
        uint256 governancePerformanceFee;
        uint256 strategistPerformanceFee;
    }

    function initialize(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian,
        address[1] memory _wantConfig,
        uint256[4] memory _feeConfig
    ) public initializer {
        __BaseStrategy_init(_governance, _strategist, _controller, _keeper, _guardian);

        require(_wantConfig[0] == renbtc_collateral, "!want");
        want = _wantConfig[0];
        collateral = renbtc_collateral;
        collateralDecimal = renbtc_collateral_decimal;
        unitOracle = renbtc_oracle;
        collateralPriceDecimal = renbtc_price_decimal;
        collateralPriceEth = renbtc_price_eth;

        performanceFeeGovernance = _feeConfig[0];
        performanceFeeStrategist = _feeConfig[1];
        withdrawalFee = _feeConfig[2];
        keepCRV = _feeConfig[3];

        minRatio = 200;
        ratioBuff = 200;
    }

    // **** Setters ****

    function setSlippageProtectionIn(uint256 _slippage) external {
        _onlyGovernance();
        slippageProtectionIn = _slippage;
    }

    function setSlippageProtectionOut(uint256 _slippage) external {
        _onlyGovernance();
        slippageProtectionOut = _slippage;
    }

    function setKeepCRV(uint256 _keepCRV) external {
        _onlyGovernance();
        keepCRV = _keepCRV;
    }

    // **** State Mutation functions ****

    function getHarvestable() external view returns (uint256) {
        return ICurveGauge(usdp_gauge).claimable_tokens(address(this));
    }

    function harvest() external whenNotPaused returns (HarvestData memory) {
        _onlyAuthorizedActors();

        HarvestData memory harvestData;

        uint256 _before = IERC20Upgradeable(want).balanceOf(address(this));
        uint256 _beforeCrv = IERC20Upgradeable(crv).balanceOf(address(this));

        // Harvest from Gauge
        ICurveMintr(mintr).mint(usdp_gauge);
        uint256 _afterCrv = IERC20Upgradeable(crv).balanceOf(address(this));

        harvestData.crvHarvested = _afterCrv.sub(_beforeCrv);
        uint256 _crv = _afterCrv;

        // Transfer CRV to keep to Rewards
        harvestData.keepCrv = _crv.mul(keepCRV).div(MAX_FEE);
        IERC20Upgradeable(crv).safeTransfer(IController(controller).rewards(), harvestData.keepCrv);

        harvestData.crvRecycled = _crv.sub(harvestData.keepCrv);

        if (harvestData.crvRecycled > 0) {
            address[] memory path = new address[](3);
            path[0] = crv;
            path[1] = weth;
            path[2] = want;
            _swap(crv, harvestData.crvRecycled, path);
        }

        // Take fees from want increase, and deposit remaining into Gauge
        harvestData.wantProcessed = IERC20Upgradeable(want).balanceOf(address(this));
        if (harvestData.wantProcessed > 0) {
            (harvestData.governancePerformanceFee, harvestData.strategistPerformanceFee) = _processPerformanceFees(harvestData.wantProcessed);

            // Reinvest remaining want
            harvestData.wantDeposited = IERC20Upgradeable(want).balanceOf(address(this));

            if (harvestData.wantDeposited > 0) {
                _deposit(harvestData.wantDeposited);
            }
        }

        emit RenBTCStratHarvest(
            harvestData.crvHarvested,
            harvestData.keepCrv,
            harvestData.crvRecycled,
            harvestData.wantProcessed,
            harvestData.wantDeposited,
            harvestData.governancePerformanceFee,
            harvestData.strategistPerformanceFee
        );

        emit Harvest(harvestData.wantProcessed.sub(_before), block.number);

        return harvestData;
    }

    function _processPerformanceFees(uint256 _amount) internal returns (uint256 governancePerformanceFee, uint256 strategistPerformanceFee) {
        governancePerformanceFee = _processFee(want, _amount, performanceFeeGovernance, IController(controller).rewards());
        strategistPerformanceFee = _processFee(want, _amount, performanceFeeStrategist, strategist);
    }

    function _depositUSDP(uint256 _usdpAmt) internal override {
        if (_usdpAmt > 0 && checkSlip(_usdpAmt)) {
            _safeApproveHelper(usdp, curvePool, _usdpAmt);
            uint256[2] memory amounts = [_usdpAmt, 0];
            ICurveFi(curvePool).add_liquidity(amounts, 0);
        }

        uint256 _usdp3crv = IERC20Upgradeable(usdp3crv).balanceOf(address(this));
        if (_usdp3crv > 0) {
            _safeApproveHelper(usdp3crv, usdp_gauge, _usdp3crv);
            ICurveGauge(usdp_gauge).deposit(_usdp3crv);
        }
    }

    function _withdrawUSDP(uint256 _usdpAmt) internal override {
        uint256 _requiredUsdp3crv = estimateRequiredUsdp3crv(_usdpAmt);
        _requiredUsdp3crv = _requiredUsdp3crv.mul(MAX_FEE.add(slippageProtectionOut)).div(MAX_FEE); // try to remove bit more

        uint256 _usdp3crv = IERC20Upgradeable(usdp3crv).balanceOf(address(this));
        uint256 _withdrawFromGauge = _usdp3crv < _requiredUsdp3crv ? _requiredUsdp3crv.sub(_usdp3crv) : 0;

        if (_withdrawFromGauge > 0) {
            uint256 maxInGauge = ICurveGauge(usdp_gauge).balanceOf(address(this));
            ICurveGauge(usdp_gauge).withdraw(maxInGauge < _withdrawFromGauge ? maxInGauge : _withdrawFromGauge);
        }

        _usdp3crv = IERC20Upgradeable(usdp3crv).balanceOf(address(this));
        if (_usdp3crv > 0) {
            _requiredUsdp3crv = _requiredUsdp3crv > _usdp3crv ? _usdp3crv : _requiredUsdp3crv;
            uint256 maxSlippage = _requiredUsdp3crv.mul(MAX_FEE.sub(slippageProtectionOut)).div(MAX_FEE);
            _safeApproveHelper(usdp3crv, curvePool, _requiredUsdp3crv);
            ICurveFi(curvePool).remove_liquidity_one_coin(_requiredUsdp3crv, 0, maxSlippage);
        }
    }

    // **** Views ****

    function virtualPriceToWant() public view returns (uint256) {
        uint256 p = ICurveFi(curvePool).get_virtual_price();
        require(p > 0, "!p");
        return p;
    }

    function estimateRequiredUsdp3crv(uint256 _usdpAmt) public view returns (uint256) {
        return _usdpAmt.mul(1e18).div(virtualPriceToWant());
    }

    function checkSlip(uint256 _usdpAmt) public view returns (bool) {
        uint256 expectedOut = _usdpAmt.mul(1e18).div(virtualPriceToWant());
        uint256 maxSlip = expectedOut.mul(MAX_FEE.sub(slippageProtectionIn)).div(MAX_FEE);

        uint256[2] memory amounts = [_usdpAmt, 0];
        return ICurveExchange(curvePool).calc_token_amount(amounts, true) >= maxSlip;
    }

    function usdpOfPool() public view returns (uint256) {
        uint256 _usdp3crv = IERC20Upgradeable(usdp3crv).balanceOf(address(this));
        _usdp3crv = _usdp3crv.add(ICurveGauge(usdp_gauge).balanceOf(address(this)));
        return usdp3crvToUsdp(_usdp3crv);
    }

    function usdp3crvToUsdp(uint256 _usdp3crv) public view returns (uint256) {
        if (_usdp3crv == 0) {
            return 0;
        }
        // use underestimate of current assets.
        uint256 virtualOut = virtualPriceToWant().mul(_usdp3crv).div(1e18);
        // uint256 realOut = ICurveFi(curvePool).calc_withdraw_one_coin(_usdp3crv, 0);
        return virtualOut; // virtualOut > realOut? realOut : virtualOut;
    }

    /// @notice Specify tokens used in yield process, should not be available to withdraw via withdrawOther()
    function _onlyNotProtectedTokens(address _asset) internal override {
        require(usdp3crv != _asset, "!usdp3crv");
        require(usdp != _asset, "!usdp");
        require(renbtc_collateral != _asset, "!usdp");
    }

    function getProtectedTokens() external override view returns (address[] memory) {
        address[] memory protectedTokens = new address[](3);
        protectedTokens[0] = renbtc_collateral;
        protectedTokens[1] = usdp;
        protectedTokens[2] = usdp3crv;
        return protectedTokens;
    }

    /// @dev User-friendly name for this strategy for purposes of convenient reading
    function getName() external override pure returns (string memory) {
        return "StrategyUnitProtocolRenbtc";
    }
}