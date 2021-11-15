// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
library SafeMath {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "IERC20.sol";
import "SafeMath.sol";
import "Address.sol";

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

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/v3.0.0/contracts/Initializable.sol
// Added public isInitialized() view of private initialized bool.

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

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
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    /**
     * @dev Return true if and only if the contract has been initialized
     * @return whether the contract has been initialized
     */
    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {Address} from "Address.sol";
import {Context} from "Context.sol";
import {IERC20} from "IERC20.sol";
import {SafeMath} from "SafeMath.sol";

import {Initializable} from "Initializable.sol";

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
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    function __ERC20_initialize(string memory name, string memory symbol) internal initializer {
        _name = name;
        _symbol = symbol;
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
    function decimals() public virtual view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
    function allowance(address owner, address spender) public virtual override view returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
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
     * Requirements
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
     * Requirements
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function updateNameAndSymbol(string memory __name, string memory __symbol) internal {
        _name = __name;
        _symbol = __symbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {Context} from "Context.sol";

import {Initializable} from "Initializable.sol";

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
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() internal initializer {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";

interface IYToken is IERC20 {
    function getPricePerFullShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";

import {IYToken} from "IYToken.sol";

interface ICurve {
    function calc_token_amount(uint256[4] memory amounts, bool deposit) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

interface ICurveGauge {
    function balanceOf(address depositor) external view returns (uint256);

    function minter() external returns (ICurveMinter);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

interface ICurveMinter {
    function mint(address gauge) external;

    function token() external view returns (IERC20);
}

interface ICurvePool {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool donate_dust
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function token() external view returns (IERC20);

    function curve() external view returns (ICurve);

    function coins(int128 id) external view returns (IYToken);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";

/**
 * TruePool is an ERC20 which represents a share of a pool
 *
 * This contract can be used to wrap opportunities to be compatible
 * with TrueFi and allow users to directly opt-in through the TUSD contract
 *
 * Each TruePool is also a staking opportunity for TRU
 */
interface ITrueFiPool is IERC20 {
    /// @dev pool token (TUSD)
    function currencyToken() external view returns (IERC20);

    /**
     * @dev join pool
     * 1. Transfer TUSD from sender
     * 2. Mint pool tokens based on value to sender
     */
    function join(uint256 amount) external;

    /**
     * @dev borrow from pool
     * 1. Transfer TUSD to sender
     * 2. Only lending pool should be allowed to call this
     */
    function borrow(uint256 amount, uint256 fee) external;

    /**
     * @dev join pool
     * 1. Transfer TUSD from sender
     * 2. Only lending pool should be allowed to call this
     */
    function repay(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface ITrueLender {
    function value() external view returns (uint256);

    function distribute(
        address recipient,
        uint256 numerator,
        uint256 denominator
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.6.10;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(x <= 0x7FFFFFFFFFFFFFFF);
        return int128(x << 64);
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(x) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        require(x > 0);

        return int128((uint256(log_2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface ICrvPriceOracle {
    function usdToCrv(uint256 amount) external view returns (uint256);

    function crvToUsd(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

/**
 * @dev interface to allow standard pause function
 */
interface IPauseableContract {
    function setPauseStatus(bool pauseStatus) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";
import {ERC20} from "UpgradeableERC20.sol";
import {ITrueFiPool2} from "ITrueFiPool2.sol";

interface ILoanToken2 is IERC20 {
    enum Status {Awaiting, Funded, Withdrawn, Settled, Defaulted, Liquidated}

    function borrower() external view returns (address);

    function amount() external view returns (uint256);

    function term() external view returns (uint256);

    function apy() external view returns (uint256);

    function start() external view returns (uint256);

    function lender() external view returns (address);

    function debt() external view returns (uint256);

    function pool() external view returns (ITrueFiPool2);

    function profit() external view returns (uint256);

    function status() external view returns (Status);

    function getParameters()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function fund() external;

    function withdraw(address _beneficiary) external;

    function settle() external;

    function enterDefault() external;

    function liquidate() external;

    function redeem(uint256 _amount) external;

    function repay(address _sender, uint256 _amount) external;

    function repayInFull(address _sender) external;

    function reclaim() external;

    function allowTransfer(address account, bool _status) external;

    function repaid() external view returns (uint256);

    function isRepaid() external view returns (bool);

    function balance() external view returns (uint256);

    function value(uint256 _balance) external view returns (uint256);

    function token() external view returns (ERC20);

    function version() external pure returns (uint8);
}

//interface IContractWithPool {
//    function pool() external view returns (ITrueFiPool2);
//}
//
//// Had to be split because of multiple inheritance problem
//interface ILoanToken2 is ILoanToken, IContractWithPool {
//
//}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {ITrueFiPool2} from "ITrueFiPool2.sol";
import {ILoanToken2} from "ILoanToken2.sol";

interface ITrueLender2 {
    // @dev calculate overall value of the pools
    function value(ITrueFiPool2 pool) external view returns (uint256);

    // @dev distribute a basket of tokens for exiting user
    function distribute(
        address recipient,
        uint256 numerator,
        uint256 denominator
    ) external;

    function transferAllLoanTokens(ILoanToken2 loan, address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";

interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20WithDecimals} from "IERC20WithDecimals.sol";

/**
 * @dev Oracle that converts any token to and from TRU
 * Used for liquidations and valuing of liquidated TRU in the pool
 */
interface ITrueFiPoolOracle {
    // token address
    function token() external view returns (IERC20WithDecimals);

    // amount of tokens 1 TRU is worth
    function truToToken(uint256 truAmount) external view returns (uint256);

    // amount of TRU 1 token is worth
    function tokenToTru(uint256 tokenAmount) external view returns (uint256);

    // USD price of token with 18 decimals
    function tokenToUsd(uint256 tokenAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

interface I1Inch3 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(
        address caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        returns (
            uint256 returnAmount,
            uint256 gasLeft,
            uint256 chiSpent
        );

    function unoswap(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata /* pools */
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";
import {ILoanToken2} from "ILoanToken2.sol";

interface IDeficiencyToken is IERC20 {
    function loan() external view returns (ILoanToken2);

    function burnFrom(address account, uint256 amount) external;

    function version() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IDeficiencyToken} from "IDeficiencyToken.sol";
import {ILoanToken2} from "ILoanToken2.sol";

interface ISAFU {
    function poolDeficit(address pool) external view returns (uint256);

    function deficiencyToken(ILoanToken2 loan) external view returns (IDeficiencyToken);

    function reclaim(ILoanToken2 loan, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {ERC20, IERC20} from "UpgradeableERC20.sol";
import {ITrueLender2, ILoanToken2} from "ITrueLender2.sol";
import {ITrueFiPoolOracle} from "ITrueFiPoolOracle.sol";
import {I1Inch3} from "I1Inch3.sol";
import {ISAFU} from "ISAFU.sol";

interface ITrueFiPool2 is IERC20 {
    function initialize(
        ERC20 _token,
        ITrueLender2 _lender,
        ISAFU safu,
        address __owner
    ) external;

    function singleBorrowerInitialize(
        ERC20 _token,
        ITrueLender2 _lender,
        ISAFU safu,
        address __owner,
        string memory borrowerName,
        string memory borrowerSymbol
    ) external;

    function token() external view returns (ERC20);

    function oracle() external view returns (ITrueFiPoolOracle);

    function poolValue() external view returns (uint256);

    /**
     * @dev Ratio of liquid assets in the pool to the pool value
     */
    function liquidRatio() external view returns (uint256);

    /**
     * @dev Ratio of liquid assets in the pool after lending
     * @param amount Amount of asset being lent
     */
    function proFormaLiquidRatio(uint256 amount) external view returns (uint256);

    /**
     * @dev Join the pool by depositing tokens
     * @param amount amount of tokens to deposit
     */
    function join(uint256 amount) external;

    /**
     * @dev borrow from pool
     * 1. Transfer TUSD to sender
     * 2. Only lending pool should be allowed to call this
     */
    function borrow(uint256 amount) external;

    /**
     * @dev pay borrowed money back to pool
     * 1. Transfer TUSD from sender
     * 2. Only lending pool should be allowed to call this
     */
    function repay(uint256 currencyAmount) external;

    /**
     * @dev SAFU buys LoanTokens from the pool
     */
    function liquidate(ILoanToken2 loan) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {ILoanToken2} from "ILoanToken2.sol";
import {ITrueLender2} from "ITrueLender2.sol";
import {ISAFU} from "ISAFU.sol";

/**
 * @dev Library that has shared functions between legacy TrueFi Pool and Pool2
 */
library PoolExtensions {
    function _liquidate(
        ISAFU safu,
        ILoanToken2 loan,
        ITrueLender2 lender
    ) internal {
        require(msg.sender == address(safu), "TrueFiPool: Should be called by SAFU");
        lender.transferAllLoanTokens(loan, address(safu));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {SafeMath} from "SafeMath.sol";
import {SafeERC20} from "SafeERC20.sol";

import {ERC20} from "UpgradeableERC20.sol";
import {Ownable} from "UpgradeableOwnable.sol";
import {ICurveGauge, ICurveMinter, ICurvePool} from "ICurve.sol";
import {ITrueFiPool} from "ITrueFiPool.sol";
import {ITrueLender} from "ITrueLender.sol";
import {IUniswapRouter} from "IUniswapRouter.sol";
import {ABDKMath64x64} from "Log.sol";
import {ICrvPriceOracle} from "ICrvPriceOracle.sol";
import {IPauseableContract} from "IPauseableContract.sol";
import {ITrueFiPool2, ITrueFiPoolOracle, ITrueLender2, ILoanToken2, ISAFU} from "ITrueFiPool2.sol";
import {PoolExtensions} from "PoolExtensions.sol";

/**
 * @title TrueFi Pool
 * @dev Lending pool which uses curve.fi to store idle funds
 * Earn high interest rates on currency deposits through uncollateralized loans
 *
 * Funds deposited in this pool are not fully liquid. Liquidity
 * Exiting incurs an exit penalty depending on pool liquidity
 * After exiting, an account will need to wait for LoanTokens to expire and burn them
 * It is recommended to perform a zap or swap tokens on Uniswap for increased liquidity
 *
 * Funds are managed through an external function to save gas on deposits
 */
contract TrueFiPool is ITrueFiPool, IPauseableContract, ERC20, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    ICurvePool public _curvePool;
    ICurveGauge public _curveGauge;
    IERC20 public token;
    ITrueLender public _lender;
    ICurveMinter public _minter;
    IUniswapRouter public _uniRouter;

    // fee for deposits
    uint256 public joiningFee;
    // track claimable fees
    uint256 public claimableFees;

    mapping(address => uint256) latestJoinBlock;

    address private DEPRECATED__stakeToken;

    // cache values during sync for gas optimization
    bool private inSync;
    uint256 private yTokenValueCache;
    uint256 private loansValueCache;

    // TRU price oracle
    ITrueFiPoolOracle public oracle;

    // fund manager can call functions to help manage pool funds
    // fund manager can be set to 0 or governance
    address public fundsManager;

    // allow pausing of deposits
    bool public pauseStatus;

    // CRV price oracle
    ICrvPriceOracle public _crvOracle;

    ITrueLender2 public _lender2;

    ISAFU public safu;

    // ======= STORAGE DECLARATION END ============

    // curve.fi data
    uint8 constant N_TOKENS = 4;
    uint8 constant TUSD_INDEX = 3;

    uint256 constant MAX_PRICE_SLIPPAGE = 10; // 0.1%

    /**
     * @dev Emitted when TrueFi oracle was changed
     * @param newOracle New oracle address
     */
    event TruOracleChanged(ITrueFiPoolOracle newOracle);

    /**
     * @dev Emitted when CRV oracle was changed
     * @param newOracle New oracle address
     */
    event CrvOracleChanged(ICrvPriceOracle newOracle);

    /**
     * @dev Emitted when funds manager is changed
     * @param newManager New manager address
     */
    event FundsManagerChanged(address newManager);

    /**
     * @dev Emitted when fee is changed
     * @param newFee New fee
     */
    event JoiningFeeChanged(uint256 newFee);

    /**
     * @dev Emitted when someone joins the pool
     * @param staker Account staking
     * @param deposited Amount deposited
     * @param minted Amount of pool tokens minted
     */
    event Joined(address indexed staker, uint256 deposited, uint256 minted);

    /**
     * @dev Emitted when someone exits the pool
     * @param staker Account exiting
     * @param amount Amount unstaking
     */
    event Exited(address indexed staker, uint256 amount);

    /**
     * @dev Emitted when funds are flushed into curve.fi
     * @param currencyAmount Amount of tokens deposited
     */
    event Flushed(uint256 currencyAmount);

    /**
     * @dev Emitted when funds are pulled from curve.fi
     * @param yAmount Amount of pool tokens
     */
    event Pulled(uint256 yAmount);

    /**
     * @dev Emitted when funds are borrowed from pool
     * @param borrower Borrower address
     * @param amount Amount of funds borrowed from pool
     * @param fee Fees collected from this transaction
     */
    event Borrow(address borrower, uint256 amount, uint256 fee);

    /**
     * @dev Emitted when borrower repays the pool
     * @param payer Address of borrower
     * @param amount Amount repaid
     */
    event Repaid(address indexed payer, uint256 amount);

    /**
     * @dev Emitted when fees are collected
     * @param beneficiary Account to receive fees
     * @param amount Amount of fees collected
     */
    event Collected(address indexed beneficiary, uint256 amount);

    /**
     * @dev Emitted when joining is paused or unpaused
     * @param pauseStatus New pausing status
     */
    event PauseStatusChanged(bool pauseStatus);

    /**
     * @dev Emitted when SAFU address is changed
     * @param newSafu New SAFU address
     */
    event SafuChanged(ISAFU newSafu);

    /**
     * @dev only lender can perform borrowing or repaying
     */
    modifier onlyLender() {
        require(msg.sender == address(_lender) || msg.sender == address(_lender2), "TrueFiPool: Caller is not the lender");
        _;
    }

    /**
     * @dev pool can only be joined when it's unpaused
     */
    modifier joiningNotPaused() {
        require(!pauseStatus, "TrueFiPool: Joining the pool is paused");
        _;
    }

    /**
     * @dev only lender can perform borrowing or repaying
     */
    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || msg.sender == fundsManager, "TrueFiPool: Caller is neither owner nor funds manager");
        _;
    }

    /**
     * @dev ensure than as a result of running a function,
     * balance of `token` increases by at least `expectedGain`
     */
    modifier exchangeProtector(uint256 expectedGain, IERC20 _token) {
        uint256 balanceBefore = _token.balanceOf(address(this));
        _;
        uint256 balanceDiff = _token.balanceOf(address(this)).sub(balanceBefore);
        require(balanceDiff >= conservativePriceEstimation(expectedGain), "TrueFiPool: Not optimal exchange");
    }

    /**
     * Sync values to avoid making expensive calls multiple times
     * Will set inSync to true, allowing getter functions to return cached values
     * Wipes cached values to save gas
     */
    modifier sync() {
        // sync
        yTokenValueCache = yTokenValue();
        loansValueCache = loansValue();
        inSync = true;
        _;
        // wipe
        inSync = false;
        yTokenValueCache = 0;
        loansValueCache = 0;
    }

    function updateNameAndSymbolToLegacy() public {
        updateNameAndSymbol("Legacy TrueFi TrueUSD", "Legacy tfTUSD");
    }

    /// @dev support borrow function from pool V2
    function borrow(uint256 amount) external {
        borrow(amount, 0);
    }

    /**
     * @dev get currency token address
     * @return currency token address
     */
    function currencyToken() public override view returns (IERC20) {
        return token;
    }

    /**
     * @dev set TrueLenderV2
     */
    function setLender2(ITrueLender2 lender2) public onlyOwner {
        require(address(_lender2) == address(0), "TrueFiPool: Lender 2 is already set");
        _lender2 = lender2;
    }

    /**
     * @dev set funds manager address
     */
    function setFundsManager(address newFundsManager) public onlyOwner {
        fundsManager = newFundsManager;
        emit FundsManagerChanged(newFundsManager);
    }

    /**
     * @dev set TrueFi price oracle token address
     * @param newOracle new oracle address
     */
    function setTruOracle(ITrueFiPoolOracle newOracle) public onlyOwner {
        oracle = newOracle;
        emit TruOracleChanged(newOracle);
    }

    /**
     * @dev set CRV price oracle token address
     * @param newOracle new oracle address
     */
    function setCrvOracle(ICrvPriceOracle newOracle) public onlyOwner {
        _crvOracle = newOracle;
        emit CrvOracleChanged(newOracle);
    }

    /**
     * @dev Allow pausing of deposits in case of emergency
     * @param status New deposit status
     */
    function setPauseStatus(bool status) external override onlyOwnerOrManager {
        pauseStatus = status;
        emit PauseStatusChanged(status);
    }

    /**
     * @dev Change SAFU address
     */
    function setSafuAddress(ISAFU _safu) external onlyOwner {
        safu = _safu;
        emit SafuChanged(_safu);
    }

    /**
     * @dev Get total balance of CRV tokens
     * @return Balance of stake tokens in this contract
     */
    function crvBalance() public view returns (uint256) {
        if (address(_minter) == address(0)) {
            return 0;
        }
        return _minter.token().balanceOf(address(this));
    }

    /**
     * @dev Get total balance of curve.fi pool tokens
     * @return Balance of y pool tokens in this contract
     */
    function yTokenBalance() public view returns (uint256) {
        return _curvePool.token().balanceOf(address(this)).add(_curveGauge.balanceOf(address(this)));
    }

    /**
     * @dev Virtual value of yCRV tokens in the pool
     * Will return sync value if inSync
     * @return yTokenValue in USD.
     */
    function yTokenValue() public view returns (uint256) {
        if (inSync) {
            return yTokenValueCache;
        }
        return yTokenBalance().mul(_curvePool.curve().get_virtual_price()).div(1 ether);
    }

    /**
     * @dev Price of CRV in USD
     * @return Oracle price of TRU in USD
     */
    function crvValue() public view returns (uint256) {
        uint256 balance = crvBalance();
        if (balance == 0 || address(_crvOracle) == address(0)) {
            return 0;
        }
        return conservativePriceEstimation(_crvOracle.crvToUsd(balance));
    }

    /**
     * @dev Virtual value of liquid assets in the pool
     * @return Virtual liquid value of pool assets
     */
    function liquidValue() public view returns (uint256) {
        return currencyBalance().add(yTokenValue());
    }

    /**
     * @dev Return pool deficiency value, to be returned by safu
     * @return pool deficiency value
     */
    function deficitValue() public view returns (uint256) {
        if (address(safu) == address(0)) {
            return 0;
        }
        return safu.poolDeficit(address(this));
    }

    /**
     * @dev Calculate pool value in TUSD
     * "virtual price" of entire pool - LoanTokens, TUSD, curve y pool tokens
     * @return pool value in USD
     */
    function poolValue() public view returns (uint256) {
        // this assumes defaulted loans are worth their full value
        return liquidValue().add(loansValue()).add(crvValue()).add(deficitValue());
    }

    /**
     * @dev Virtual value of loan assets in the pool
     * Will return cached value if inSync
     * @return Value of loans in pool
     */
    function loansValue() public view returns (uint256) {
        if (inSync) {
            return loansValueCache;
        }
        if (address(_lender2) != address(0)) {
            return _lender.value().add(_lender2.value(ITrueFiPool2(address(this))));
        }
        return _lender.value();
    }

    /**
     * @dev ensure enough curve.fi pool tokens are available
     * Check if current available amount of TUSD is enough and
     * withdraw remainder from gauge
     * @param neededAmount amount required
     */
    function ensureEnoughTokensAreAvailable(uint256 neededAmount) internal {
        uint256 currentlyAvailableAmount = _curvePool.token().balanceOf(address(this));
        if (currentlyAvailableAmount < neededAmount) {
            _curveGauge.withdraw(neededAmount.sub(currentlyAvailableAmount));
        }
    }

    /**
     * @dev set pool join fee
     * @param fee new fee
     */
    function setJoiningFee(uint256 fee) external onlyOwner {
        require(fee <= 10000, "TrueFiPool: Fee cannot exceed transaction value");
        joiningFee = fee;
        emit JoiningFeeChanged(fee);
    }

    /**
     * @dev Join the pool by depositing currency tokens
     * @param amount amount of currency token to deposit
     */
    function join(uint256 amount) external override joiningNotPaused {
        uint256 fee = amount.mul(joiningFee).div(10000);
        uint256 mintedAmount = mint(amount.sub(fee));
        claimableFees = claimableFees.add(fee);

        latestJoinBlock[tx.origin] = block.number;
        require(token.transferFrom(msg.sender, address(this), amount));

        emit Joined(msg.sender, amount, mintedAmount);
    }

    /**
     * @dev Exit pool only with liquid tokens
     * This function will withdraw TUSD but with a small penalty
     * Uses the sync() modifier to reduce gas costs of using curve
     * @param amount amount of pool tokens to redeem for underlying tokens
     */
    function liquidExit(uint256 amount) external nonReentrant sync {
        require(block.number != latestJoinBlock[tx.origin], "TrueFiPool: Cannot join and exit in same block");
        require(amount <= balanceOf(msg.sender), "TrueFiPool: Insufficient funds");

        uint256 amountToWithdraw = poolValue().mul(amount).div(totalSupply());
        require(amountToWithdraw <= liquidValue(), "TrueFiPool: Not enough liquidity in pool");

        // burn tokens sent
        _burn(msg.sender, amount);

        if (amountToWithdraw > currencyBalance()) {
            removeLiquidityFromCurve(amountToWithdraw.sub(currencyBalance()));
            require(amountToWithdraw <= currencyBalance(), "TrueFiPool: Not enough funds were withdrawn from Curve");
        }

        require(token.transfer(msg.sender, amountToWithdraw));

        emit Exited(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Deposit idle funds into curve.fi pool and stake in gauge
     * Called by owner to help manage funds in pool and save on gas for deposits
     * @param currencyAmount Amount of funds to deposit into curve
     */
    function flush(uint256 currencyAmount) external {
        require(currencyAmount <= currencyBalance(), "TrueFiPool: Insufficient currency balance");

        uint256 expectedMinYTokenValue = yTokenValue().add(conservativePriceEstimation(currencyAmount));
        _curvePoolDeposit(currencyAmount);
        require(yTokenValue() >= expectedMinYTokenValue, "TrueFiPool: yToken value expected to be higher");
        emit Flushed(currencyAmount);
    }

    function _curvePoolDeposit(uint256 currencyAmount) private {
        uint256[N_TOKENS] memory amounts = [0, 0, 0, currencyAmount];

        token.safeApprove(address(_curvePool), currencyAmount);
        uint256 conservativeMinAmount = calcTokenAmount(currencyAmount).mul(999).div(1000);
        _curvePool.add_liquidity(amounts, conservativeMinAmount);

        // stake yCurve tokens in gauge
        uint256 yBalance = _curvePool.token().balanceOf(address(this));
        _curvePool.token().safeApprove(address(_curveGauge), yBalance);
        _curveGauge.deposit(yBalance);
    }

    /**
     * @dev Remove liquidity from curve
     * @param yAmount amount of curve pool tokens
     * @param minCurrencyAmount minimum amount of tokens to withdraw
     */
    function pull(uint256 yAmount, uint256 minCurrencyAmount) external onlyOwnerOrManager {
        require(yAmount <= yTokenBalance(), "TrueFiPool: Insufficient Curve liquidity balance");

        // unstake in gauge
        ensureEnoughTokensAreAvailable(yAmount);

        // remove TUSD from curve
        _curvePool.token().safeApprove(address(_curvePool), yAmount);
        _curvePool.remove_liquidity_one_coin(yAmount, TUSD_INDEX, minCurrencyAmount, false);

        emit Pulled(yAmount);
    }

    // prettier-ignore
    /**
     * @dev Remove liquidity from curve if necessary and transfer to lender
     * @param amount amount for lender to withdraw
     */
    function borrow(uint256 amount, uint256 fee) public override nonReentrant onlyLender {
        // if there is not enough TUSD, withdraw from curve
        if (amount > currencyBalance()) {
            removeLiquidityFromCurve(amount.sub(currencyBalance()));
            require(amount <= currencyBalance(), "TrueFiPool: Not enough funds in pool to cover borrow");
        }

        mint(fee);
        require(token.transfer(msg.sender, amount.sub(fee)));

        emit Borrow(msg.sender, amount, fee);
    }

    function removeLiquidityFromCurve(uint256 amountToWithdraw) internal {
        // get rough estimate of how much yCRV we should sell
        uint256 roughCurveTokenAmount = calcTokenAmount(amountToWithdraw).mul(1005).div(1000);
        require(roughCurveTokenAmount <= yTokenBalance(), "TrueFiPool: Not enough Curve liquidity tokens in pool to cover borrow");
        // pull tokens from gauge
        ensureEnoughTokensAreAvailable(roughCurveTokenAmount);
        // remove TUSD from curve
        _curvePool.token().safeApprove(address(_curvePool), roughCurveTokenAmount);
        uint256 minAmount = roughCurveTokenAmount.mul(_curvePool.curve().get_virtual_price()).mul(999).div(1000).div(1 ether);
        _curvePool.remove_liquidity_one_coin(roughCurveTokenAmount, TUSD_INDEX, minAmount, false);
    }

    /**
     * @dev repay debt by transferring tokens to the contract
     * @param currencyAmount amount to repay
     */
    function repay(uint256 currencyAmount) external override onlyLender {
        require(token.transferFrom(msg.sender, address(this), currencyAmount));
        emit Repaid(msg.sender, currencyAmount);
    }

    /**
     * @dev Collect CRV tokens minted by staking at gauge
     */
    function collectCrv() external onlyOwnerOrManager {
        _minter.mint(address(_curveGauge));
    }

    /**
     * @dev Sell collected CRV on Uniswap
     * - Selling CRV is managed by the contract owner
     * - Calculations can be made off-chain and called based on market conditions
     * - Need to pass path of exact pairs to go through while executing exchange
     * For example, CRV -> WETH -> TUSD
     *
     * @param amountIn see https://uniswap.org/docs/v2/smart-contracts/router02/#swapexacttokensfortokens
     * @param amountOutMin see https://uniswap.org/docs/v2/smart-contracts/router02/#swapexacttokensfortokens
     * @param path see https://uniswap.org/docs/v2/smart-contracts/router02/#swapexacttokensfortokens
     */
    function sellCrv(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) public exchangeProtector(_crvOracle.crvToUsd(amountIn), token) {
        _minter.token().safeApprove(address(_uniRouter), amountIn);
        _uniRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 1 hours);
    }

    /**
     * @dev Claim fees from the pool
     * @param beneficiary account to send funds to
     */
    function collectFees(address beneficiary) external onlyOwnerOrManager {
        uint256 amount = claimableFees;
        claimableFees = 0;

        if (amount > 0) {
            require(token.transfer(beneficiary, amount));
        }

        emit Collected(beneficiary, amount);
    }

    /**
     * @dev Function called by SAFU when liquidation happens. It will transfer all tokens of this loan the SAFU
     */
    function liquidate(ILoanToken2 loan) external {
        PoolExtensions._liquidate(safu, loan, _lender2);
    }

    /**
     * @notice Expected amount of minted Curve.fi yDAI/yUSDC/yUSDT/yTUSD tokens.
     * Can be used to control slippage
     * Called in flush() function
     * @param currencyAmount amount to calculate for
     * @return expected amount minted given currency amount
     */
    function calcTokenAmount(uint256 currencyAmount) public view returns (uint256) {
        // prettier-ignore
        uint256 yTokenAmount = currencyAmount.mul(1e18).div(
            _curvePool.coins(TUSD_INDEX).getPricePerFullShare());
        uint256[N_TOKENS] memory yAmounts = [0, 0, 0, yTokenAmount];
        return _curvePool.curve().calc_token_amount(yAmounts, true);
    }

    /**
     * @dev Currency token balance
     * @return Currency token balance
     */
    function currencyBalance() public view returns (uint256) {
        return token.balanceOf(address(this)).sub(claimableFees);
    }

    /**
     * @param depositedAmount Amount of currency deposited
     * @return amount minted from this transaction
     */
    function mint(uint256 depositedAmount) internal returns (uint256) {
        uint256 mintedAmount = depositedAmount;
        if (mintedAmount == 0) {
            return mintedAmount;
        }

        // first staker mints same amount deposited
        if (totalSupply() > 0) {
            mintedAmount = totalSupply().mul(depositedAmount).div(poolValue());
        }
        // mint pool tokens
        _mint(msg.sender, mintedAmount);

        return mintedAmount;
    }

    /**
     * @dev Calculate price minus max percentage of slippage during exchange
     * This will lead to the pool value become a bit undervalued
     * compared to the oracle price but will ensure that the value doesn't drop
     * when token exchanges are performed.
     */
    function conservativePriceEstimation(uint256 price) internal pure returns (uint256) {
        return price.mul(uint256(10000).sub(MAX_PRICE_SLIPPAGE)).div(10000);
    }
}

