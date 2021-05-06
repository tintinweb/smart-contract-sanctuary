/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-18
 */

// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol

// pragma solidity ^0.6.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

// pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
        assembly {
            size := extcodesize(account)
        }
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
     * // importANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol

// pragma solidity ^0.6.0;

// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Dependency file: /Users/present/code/super-sett/interfaces/badger/IController.sol

// pragma solidity >=0.5.0 <0.8.0;

interface IController {
    function withdraw(address, uint256) external;

    function strategies(address) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);
}

// Dependency file: /Users/present/code/super-sett/interfaces/badger/IStrategy.sol

// pragma solidity >=0.5.0 <0.8.0;

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
}

// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol

// pragma solidity ^0.6.0;

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
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol

// pragma solidity >=0.4.24 <0.7.0;

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
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol

// pragma solidity ^0.6.0;
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

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

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol

// pragma solidity ^0.6.0;

// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

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

// Dependency file: contracts/badger-sett/SettAccessControl.sol

// pragma solidity ^0.6.11;

// import "deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

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

// Dependency file: contracts/badger-sett/strategies/BaseStrategy.sol

// pragma solidity ^0.6.11;

// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
// import "/Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
// import "/Users/present/code/super-sett/interfaces/uniswap/IUniswapRouterV2.sol";
// import "/Users/present/code/super-sett/interfaces/badger/IController.sol";
// import "/Users/present/code/super-sett/interfaces/badger/IStrategy.sol";

// import "contracts/badger-sett/SettAccessControl.sol";

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
    function baseStrategyVersion() public pure returns (string memory) {
        return "1.2";
    }

    /// @notice Get the balance of want held idle in the Strategy
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Get the total balance of want realized in the strategy, whether idle or active in Strategy positions.
    function balanceOf() public view virtual returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function isTendable() public pure virtual returns (bool) {
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
    function withdrawAll() external virtual whenNotPaused returns (uint256) {
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

    function getProtectedTokens() external view virtual returns (address[] memory);

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
    function getName() external pure virtual returns (string memory);

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public view virtual returns (uint256);

    uint256[49] private __gap;
}

// Root file: contracts/StabilizeStrategyDiggV1.sol

pragma solidity =0.6.11;

/*
    This is a strategy to stabilize Digg with wBTC. It takes advantage of market momentum and accumulated collateral to
    track Digg price with BTC price after rebase events. Users exposed in this strategy are somewhat protected from
    a loss of value due to a negative rebase
    
    Authorized parties include many different parties that can modify trade parameters and fees
*/

interface AggregatorV3Interface {
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
}

interface TradeRouter {
    function swapExactETHForTokens(
        uint256,
        address[] calldata,
        address,
        uint256
    ) external payable returns (uint256[] memory);

    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory);

    function getAmountsOut(uint256, address[] calldata) external view returns (uint256[] memory); // For a value in, it calculates value out
}

interface UniswapLikeLPToken {
    function sync() external; // We need to call sync before Trading on Uniswap/Sushiswap due to rebase potential of Digg
}

interface DiggTreasury {
    function exchangeWBTCForDigg(
        uint256, // wBTC that we are sending to the treasury exchange
        uint256, // digg that we are requesting from the treasury exchange
        address // address to send the digg to, which is this address
    ) external;
}

contract StabilizeStrategyDiggV1 is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    // Variables
    uint256 public stabilizeFee; // 1000 = 1%, this fee goes to Stabilize Treasury
    address public diggExchangeTreasury;
    address public stabilizeVault; // Address to the Stabilize treasury

    uint256 public strategyLockedUntil; // The blocknumber that the strategy will prevent withdrawals until
    bool public diggInExpansion;
    uint256 public lastDiggTotalSupply; // The last recorded total supply of the digg token
    uint256 public lastDiggPrice; // The price of Digg at last trade in BTC units
    uint256 public diggSupplyChangeFactor = 50000; // This is a factor used by the strategy to determine how much digg to sell in expansion
    uint256 public wbtcSupplyChangeFactor = 20000; // This is a factor used by the strategy to determine how much wbtc to sell in contraction
    uint256 public wbtcSellAmplificationFactor = 2; // The higher this number the more aggressive the buyback in contraction
    uint256 public maxGainedDiggSellPercent = 100000; // The maximum percent of sellable Digg gains through rebase
    uint256 public maxWBTCSellPercent = 50000; // The maximum percent of sellable wBTC;
    uint256 public tradeBatchSize = 10e18; // The normalized size of the trade batches, can be adjusted
    uint256 public tradeAmountLeft = 0; // The amount left to trade
    uint256 private _maxOracleLag = 12 hours; // Maximum amount of lag the oracle can have before reverting the price

    // Constants
    uint256 constant DIVISION_FACTOR = 100000;
    address constant SUSHISWAP_ROUTER_ADDRESS = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // Sushi swap router
    address constant UNISWAP_ROUTER_ADDRESS = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant SUSHISWAP_DIGG_LP = address(0x9a13867048e01c663ce8Ce2fE0cDAE69Ff9F35E3); // Will need to sync before trading
    address constant UNISWAP_DIGG_LP = address(0xE86204c4eDDd2f70eE00EAd6805f917671F56c52);
    address constant BTC_ORACLE_ADDRESS = address(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c); // Chainlink BTC Oracle
    address constant DIGG_ORACLE_ADDRESS = address(0x418a6C98CD5B8275955f08F0b8C1c6838c8b1685); // Chainlink DIGG Oracle

    struct TokenInfo {
        IERC20Upgradeable token; // Reference of token
        uint256 decimals; // Decimals of token
    }

    TokenInfo[] private tokenList; // An array of tokens accepted as deposits

    event TradeState(
        uint256 soldAmountNormalized,
        int256 percentPriceChange,
        uint256 soldPercent,
        uint256 oldSupply,
        uint256 newSupply,
        uint256 blocknumber
    );

    event NoTrade(uint256 blocknumber);

    function initialize(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian,
        uint256 _lockedUntil,
        address[2] memory _vaultConfig,
        uint256[4] memory _feeConfig
    ) public initializer {
        __BaseStrategy_init(_governance, _strategist, _controller, _keeper, _guardian);

        stabilizeVault = _vaultConfig[0];
        diggExchangeTreasury = _vaultConfig[1];

        performanceFeeGovernance = _feeConfig[0];
        performanceFeeStrategist = _feeConfig[1];
        withdrawalFee = _feeConfig[2];
        stabilizeFee = _feeConfig[3];
        strategyLockedUntil = _lockedUntil; // Deployer can optionally lock strategy from withdrawing until a certain blocknumber

        setupTradeTokens();
        lastDiggPrice = getDiggPrice();
        lastDiggTotalSupply = tokenList[0].token.totalSupply(); // The supply only changes at rebase
        want = address(tokenList[0].token);
    }

    function setupTradeTokens() internal {
        // Start with DIGG
        IERC20Upgradeable _token = IERC20Upgradeable(address(0x798D1bE841a82a273720CE31c822C61a67a601C3));
        tokenList.push(TokenInfo({token: _token, decimals: _token.decimals()}));

        // WBTC
        _token = IERC20Upgradeable(address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599));
        tokenList.push(TokenInfo({token: _token, decimals: _token.decimals()}));
    }

    function _onlyAnyAuthorizedParties() internal view {
        require(
            msg.sender == strategist || msg.sender == governance || msg.sender == controller || msg.sender == keeper || msg.sender == guardian,
            "Not an authorized party"
        );
    }

    /// ===== View Functions =====

    // Chainlink price grabbers
    function getDiggUSDPrice() public view returns (uint256) {
        AggregatorV3Interface priceOracle = AggregatorV3Interface(DIGG_ORACLE_ADDRESS);
        (, int256 intPrice, , uint256 lastUpdateTime, ) = priceOracle.latestRoundData(); // We only want the answer
        require(block.timestamp.sub(lastUpdateTime) < _maxOracleLag, "Price data is too old to use");
        uint256 usdPrice = uint256(intPrice);
        priceOracle = AggregatorV3Interface(BTC_ORACLE_ADDRESS);
        (, intPrice, , lastUpdateTime, ) = priceOracle.latestRoundData(); // We only want the answer
        require(block.timestamp.sub(lastUpdateTime) < _maxOracleLag, "Price data is too old to use");
        usdPrice = usdPrice.mul(uint256(intPrice)).mul(10**2);
        return usdPrice; // Digg Price in USD
    }

    function getDiggPrice() public view returns (uint256) {
        AggregatorV3Interface priceOracle = AggregatorV3Interface(DIGG_ORACLE_ADDRESS);
        (, int256 intPrice, , uint256 lastUpdateTime, ) = priceOracle.latestRoundData(); // We only want the answer
        require(block.timestamp.sub(lastUpdateTime) < _maxOracleLag, "Price data is too old to use");
        return uint256(intPrice).mul(10**10);
    }

    function getWBTCUSDPrice() public view returns (uint256) {
        AggregatorV3Interface priceOracle = AggregatorV3Interface(BTC_ORACLE_ADDRESS);
        (, int256 intPrice, , uint256 lastUpdateTime, ) = priceOracle.latestRoundData(); // We only want the answer
        require(block.timestamp.sub(lastUpdateTime) < _maxOracleLag, "Price data is too old to use");
        return uint256(intPrice).mul(10**10);
    }

    function getTokenAddress(uint256 _id) external view returns (address) {
        require(_id < tokenList.length, "ID is too high");
        return address(tokenList[_id].token);
    }

    function getName() external pure override returns (string memory) {
        return "StabilizeStrategyDiggV1";
    }

    function version() external pure returns (string memory) {
        return "1.0";
    }

    function balanceOf() public view override returns (uint256) {
        // This will return the DIGG and DIGG equivalent of WBTC in Digg decimals
        uint256 _diggAmount = tokenList[0].token.balanceOf(address(this));
        uint256 _wBTCAmount = tokenList[1].token.balanceOf(address(this));
        return _diggAmount.add(wbtcInDiggUnits(_wBTCAmount));
    }

    function wbtcInDiggUnits(uint256 amount) internal view returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        amount = amount.mul(1e18).div(10**tokenList[1].decimals); // Normalize the wBTC amount
        uint256 _digg = amount.mul(getWBTCUSDPrice()).div(1e18); // Get the USD value of wBtC
        _digg = _digg.mul(1e18).div(getDiggUSDPrice());
        _digg = _digg.mul(10**tokenList[0].decimals).div(1e18); // Convert to Digg units
        return _digg;
    }

    function diggInWBTCUnits(uint256 amount) internal view returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        // Converts digg into wbtc equivalent
        amount = amount.mul(1e18).div(10**tokenList[0].decimals); // Normalize the digg amount
        uint256 _wbtc = amount.mul(getDiggUSDPrice()).div(1e18); // Get the USD value of digg
        _wbtc = _wbtc.mul(1e18).div(getWBTCUSDPrice());
        _wbtc = _wbtc.mul(10**tokenList[1].decimals).div(1e18); // Convert to wbtc units
        return _wbtc;
    }

    /// @dev Not used
    function balanceOfPool() public view override returns (uint256) {
        return 0;
    }

    function getProtectedTokens() external view override returns (address[] memory) {
        address[] memory protectedTokens = new address[](2);
        protectedTokens[0] = address(tokenList[0].token);
        protectedTokens[1] = address(tokenList[1].token);
        return protectedTokens;
    }

    // Customer active Strategy functions

    // This function will sell one token for another on Sushiswap and Uniswap
    function exchange(
        uint256 _inID,
        uint256 _outID,
        uint256 _amount
    ) internal {
        address _inputToken = address(tokenList[_inID].token);
        address _outputToken = address(tokenList[_outID].token);
        // One route, between DIGG and WBTC on Sushiswap and Uniswap, split based on liquidity of LPs
        address[] memory path = new address[](2);
        path[0] = _inputToken;
        path[1] = _outputToken;

        // Sync Sushiswap pool
        UniswapLikeLPToken lpPool = UniswapLikeLPToken(SUSHISWAP_DIGG_LP);
        lpPool.sync(); // Sync the pool amounts
        // Sync Uniswap pool
        lpPool = UniswapLikeLPToken(UNISWAP_DIGG_LP);
        lpPool.sync(); // Sync the pool amounts

        // Now determine the split between Uni and Sushi
        // Amount sold is split between these two biggest liquidity providers to decrease the chance of price inequities between the exchanges
        // This also helps reduce slippage and creates a higher return than using one exchange
        // Look at the total balance of the pooled tokens in Uniswap compared to the total for both exchanges
        uint256 uniPercent =
            tokenList[0]
                .token
                .balanceOf(address(UNISWAP_DIGG_LP))
                .add(tokenList[1].token.balanceOf(address(UNISWAP_DIGG_LP)))
                .mul(DIVISION_FACTOR)
                .div(
                tokenList[0]
                    .token
                    .balanceOf(address(UNISWAP_DIGG_LP))
                    .add(tokenList[0].token.balanceOf(address(SUSHISWAP_DIGG_LP)))
                    .add(tokenList[1].token.balanceOf(address(UNISWAP_DIGG_LP)))
                    .add(tokenList[1].token.balanceOf(address(SUSHISWAP_DIGG_LP)))
            );
        uint256 uniAmount = _amount.mul(uniPercent).div(DIVISION_FACTOR);
        _amount = _amount.sub(uniAmount);

        // Make sure selling produces a growth in pooled tokens
        TradeRouter router = TradeRouter(SUSHISWAP_ROUTER_ADDRESS);
        uint256 minAmount = _amount.mul(10**tokenList[_outID].decimals).div(10**tokenList[_inID].decimals); // Trades should always increase balance
        uint256[] memory estimates = router.getAmountsOut(_amount, path);
        uint256 estimate = estimates[estimates.length - 1]; // This is the amount of expected output token
        if (estimate > minAmount) {
            _safeApproveHelper(_inputToken, SUSHISWAP_ROUTER_ADDRESS, _amount);
            router.swapExactTokensForTokens(_amount, minAmount, path, address(this), now.add(60)); // Get output token
        }

        if (uniAmount > 0) {
            // Now try the same on Uniswap
            router = TradeRouter(UNISWAP_ROUTER_ADDRESS);
            minAmount = uniAmount.mul(10**tokenList[_outID].decimals).div(10**tokenList[_inID].decimals); // Trades should always increase balance
            estimates = router.getAmountsOut(uniAmount, path);
            estimate = estimates[estimates.length - 1]; // This is the amount of expected output token
            if (estimate > minAmount) {
                _safeApproveHelper(_inputToken, UNISWAP_ROUTER_ADDRESS, uniAmount);
                router.swapExactTokensForTokens(uniAmount, minAmount, path, address(this), now.add(60)); // Get output token
            }
        }
        return;
    }

    function governancePullSomeCollateral(uint256 _amount) external {
        // This will pull wBTC from the contract by governance
        _onlyGovernance();
        IERC20Upgradeable wbtc = tokenList[1].token;
        uint256 _balance = wbtc.balanceOf(address(this));
        if (_amount <= _balance) {
            wbtc.safeTransfer(governance, _amount);
        }
    }

    // Changeable variables by governance
    function setTradingBatchSize(uint256 _size) external {
        _onlyGovernance();
        tradeBatchSize = _size;
    }

    function setOracleLagTime(uint256 _time) external {
        _onlyAnyAuthorizedParties();
        _maxOracleLag = _time;
    }

    function setStabilizeFee(uint256 _fee) external {
        _onlyGovernance();
        require(_fee <= MAX_FEE, "base-strategy/excessive-stabilize-fee");
        stabilizeFee = _fee;
    }

    function setStabilizeVault(address _vault) external {
        _onlyGovernance();
        require(_vault != address(0), "No vault");
        stabilizeVault = _vault;
    }

    function setDiggExchangeTreasury(address _treasury) external {
        _onlyGovernance();
        require(_treasury != address(0), "No vault");
        diggExchangeTreasury = _treasury;
    }

    function setSellFactorsAndPercents(
        uint256 _dFactor, // This will influence how much digg is sold when the token is in expansion
        uint256 _wFactor, // This will influence how much wbtc is sold when the token is in contraction
        uint256 _wAmplifier, // This will amply the amount of wbtc sold based on the change in the price
        uint256 _mPDigg, // Governance can cap maximum amount of gained digg sold during rebase. 0-100% accepted (0-100000)
        uint256 _mPWBTC // Governance can cap the maximum amount of wbtc sold during rebase. 0-100% accepted (0-100000)
    ) external {
        _onlyGovernanceOrStrategist();
        require(_mPDigg <= 100000 && _mPWBTC <= 100000, "Percents outside range");
        diggSupplyChangeFactor = _dFactor;
        wbtcSupplyChangeFactor = _wFactor;
        wbtcSellAmplificationFactor = _wAmplifier;
        maxGainedDiggSellPercent = _mPDigg;
        maxWBTCSellPercent = _mPWBTC;
    }

    /// ===== Internal Core Implementations =====

    function _onlyNotProtectedTokens(address _asset) internal override {
        require(address(tokenList[0].token) != _asset, "DIGG");
        require(address(tokenList[1].token) != _asset, "WBTC");
    }

    /// @notice No active position
    function _deposit(uint256 _want) internal override {
        // This strategy doesn't do anything when tokens are deposited
    }

    /// @dev No active position to exit, just send all want to controller as per wrapper withdrawAll() function
    function _withdrawAll() internal override {
        // This strategy doesn't do anything when tokens are withdrawn, wBTC stays in strategy until governance decides
        // what to do with it
        // When a user withdraws, it is performed via _withdrawSome
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        require(block.number >= strategyLockedUntil, "Unable to withdraw from strategy until certain block");
        // We only have idle DIGG, withdraw from the strategy directly
        // Note: This value is in DIGG fragments

        // Make sure that when the user withdraws, the vaults try to maintain a 1:1 ratio in value
        uint256 _diggEquivalent = wbtcInDiggUnits(tokenList[1].token.balanceOf(address(this)));
        uint256 _diggBalance = tokenList[0].token.balanceOf(address(this));
        uint256 _extraDiggNeeded = 0;
        if (_amount > _diggBalance) {
            _extraDiggNeeded = _amount.sub(_diggBalance);
            _diggBalance = 0;
        } else {
            _diggBalance = _diggBalance.sub(_amount);
        }

        if (_extraDiggNeeded > 0) {
            // Calculate how much digg we need from digg vault
            _diggEquivalent = _diggEquivalent.sub(_extraDiggNeeded);
        }

        if (_diggBalance < _diggEquivalent || _diggEquivalent == 0) {
            // Now balance the vaults
            _extraDiggNeeded = _extraDiggNeeded.add(_diggEquivalent.sub(_diggBalance).div(2));
            // Exchange with the digg treasury to keep this balanced
            uint256 wbtcAmount = diggInWBTCUnits(_extraDiggNeeded);
            if (wbtcAmount > tokenList[1].token.balanceOf(address(this))) {
                wbtcAmount = tokenList[1].token.balanceOf(address(this)); // Make sure we can actual spend it
                _extraDiggNeeded = wbtcInDiggUnits(wbtcAmount);
            }
            _safeApproveHelper(address(tokenList[1].token), diggExchangeTreasury, wbtcAmount);
            // TODO: Badger team needs to develop a contract that holds Digg, can pull wbtc from this contract and return the requested amount of Digg to this address
            DiggTreasury(diggExchangeTreasury).exchangeWBTCForDigg(wbtcAmount, _extraDiggNeeded, address(this)); // Internal no slip treasury exchange
        }

        return _amount;
    }

    // We will separate trades into batches to reduce market slippage
    // Keepers can call this function after rebalancing to sell/buy slowly
    function executeTradeBatch() public whenNotPaused {
        _onlyAuthorizedActors();
        if (tradeAmountLeft == 0) {
            return;
        }

        // Reduce the trade amount left
        uint256 batchSize = tradeBatchSize;
        if (tradeAmountLeft < batchSize) {
            batchSize = tradeAmountLeft;
        }
        tradeAmountLeft = tradeAmountLeft.sub(batchSize);

        if (diggInExpansion == true) {
            // We will be selling digg for wbtc, convert to digg units from normalized
            batchSize = batchSize.mul(10**tokenList[0].decimals).div(1e18);
            uint256 _earned = tokenList[1].token.balanceOf(address(this)); // Get the pre-exchange WBTC balance
            if (batchSize > 0) {
                exchange(0, 1, batchSize); // Sell Digg for wBTC
            }
            _earned = tokenList[1].token.balanceOf(address(this)).sub(_earned);

            if (_earned > 0) {
                // We will distribute some of this wBTC to different parties
                _processFee(address(tokenList[1].token), _earned, performanceFeeGovernance, IController(controller).rewards());
                _processFee(address(tokenList[1].token), _earned, stabilizeFee, stabilizeVault);
            }
        } else {
            // We will be selling wbtc for digg, convert to wbtc units from normalized
            batchSize = batchSize.mul(10**tokenList[1].decimals).div(1e18);
            uint256 _earned = tokenList[0].token.balanceOf(address(this)); // Get the pre-exchange Digg balance
            if (batchSize > 0) {
                exchange(1, 0, batchSize); // Sell WBTC for digg
            }
            _earned = tokenList[0].token.balanceOf(address(this)).sub(_earned);
        }
    }

    function rebalance() external whenNotPaused {
        // Modified the harvest function and called it rebalance
        // This function is called by Keepers post rebase to evaluate what to do with the trade
        // A percent of wbtc earned during expansion goes to rewards pool and stabilize vault
        _onlyAuthorizedActors();
        uint256 currentTotalSupply = tokenList[0].token.totalSupply();
        if (currentTotalSupply != lastDiggTotalSupply) {
            // Rebase has taken place, act on it
            int256 currentPrice = int256(getDiggPrice());
            int256 percentChange = ((currentPrice - int256(lastDiggPrice)) * int256(DIVISION_FACTOR)) / int256(lastDiggPrice);
            if (percentChange > 100000) {
                percentChange = 100000;
            } // We only act on at most 100% change
            if (percentChange < -100000) {
                percentChange = -100000;
            }
            if (currentTotalSupply > lastDiggTotalSupply) {
                diggInExpansion = true;
                // Price is still positive
                // We will sell digg for wbtc

                // Our formula to calculate the amount of digg sold is below
                // digg_supply_change_amount * (digg_supply_change_factor - price_change_percent)
                // If amount is < 0, nothing is sold. The higher the price change, the less is sold
                uint256 sellPercent;
                if (int256(diggSupplyChangeFactor) <= percentChange) {
                    sellPercent = 0;
                } else if (percentChange > 0) {
                    sellPercent = diggSupplyChangeFactor.sub(uint256(percentChange));
                } else {
                    sellPercent = diggSupplyChangeFactor.add(uint256(-percentChange));
                }
                if (sellPercent > maxGainedDiggSellPercent) {
                    sellPercent = maxGainedDiggSellPercent;
                }

                // Get the percentage amount the supply increased by
                uint256 changedDigg = currentTotalSupply.sub(lastDiggTotalSupply).mul(DIVISION_FACTOR).div(lastDiggTotalSupply);
                changedDigg = tokenList[0].token.balanceOf(address(this)).mul(changedDigg).div(DIVISION_FACTOR);
                // This is the amount of Digg gain from the rebase returned

                uint256 _amount = changedDigg.mul(sellPercent).div(DIVISION_FACTOR); // This the amount to sell

                // Normalize sell amount
                _amount = _amount.mul(1e18).div(10**tokenList[0].decimals);
                tradeAmountLeft = _amount;
                executeTradeBatch(); // This will start to trade in batches

                emit TradeState(_amount, percentChange, sellPercent, lastDiggTotalSupply, currentTotalSupply, block.number);
            } else {
                diggInExpansion = false;
                // Price is now negative
                // We will sell wbtc for digg only if price begins to rise again
                if (percentChange > 0) {
                    // Our formula to calculate the percentage of wbtc sold is below
                    // -digg_supply_change_percent * (wbtc_supply_change_factor + price_change_percent * amplication_factor)

                    // First get the digg supply change in positive units
                    uint256 changedDiggPercent = lastDiggTotalSupply.sub(currentTotalSupply).mul(DIVISION_FACTOR).div(lastDiggTotalSupply);

                    // The faster the rise and the larger the negative rebase, the more that is bought
                    uint256 sellPercent =
                        changedDiggPercent.mul(wbtcSupplyChangeFactor.add(uint256(percentChange).mul(wbtcSellAmplificationFactor))).div(
                            DIVISION_FACTOR
                        );
                    if (sellPercent > maxWBTCSellPercent) {
                        sellPercent = maxWBTCSellPercent;
                    }

                    // We just sell this percentage of wbtc for digg gains
                    uint256 _amount = tokenList[1].token.balanceOf(address(this)).mul(sellPercent).div(DIVISION_FACTOR);

                    //Normalize the amount
                    _amount = _amount.mul(1e18).div(10**tokenList[1].decimals);
                    tradeAmountLeft = _amount;
                    executeTradeBatch();

                    emit TradeState(_amount, percentChange, sellPercent, lastDiggTotalSupply, currentTotalSupply, block.number);
                } else {
                    tradeAmountLeft = 0; // Do not trade
                    emit NoTrade(block.number);
                }
            }
            lastDiggPrice = uint256(currentPrice);
            lastDiggTotalSupply = currentTotalSupply;
        } else {
            emit NoTrade(block.number);
        }
    }
}