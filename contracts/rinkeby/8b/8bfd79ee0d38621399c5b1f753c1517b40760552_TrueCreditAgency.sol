/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

/*
    .'''''''''''..     ..''''''''''''''''..       ..'''''''''''''''..
    .;;;;;;;;;;;'.   .';;;;;;;;;;;;;;;;;;,.     .,;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;,.    .,;;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.   .;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;;;;'.  .';;;;;;;;;;;;;;;;;;;;;;,. .';;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;,..   .';;;;;;;;;;;;;;;;;;;;;;;,..';;;;;;;;;;;;;;;;;;;;;;,.
    ......     .';;;;;;;;;;;;;,'''''''''''.,;;;;;;;;;;;;;,'''''''''..
              .,;;;;;;;;;;;;;.           .,;;;;;;;;;;;;;.
             .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
            .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
           .,;;;;;;;;;;;;,.           .;;;;;;;;;;;;;,.     .....
          .;;;;;;;;;;;;;'.         ..';;;;;;;;;;;;;'.    .',;;;;,'.
        .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.   .';;;;;;;;;;.
       .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.    .;;;;;;;;;;;,.
      .,;;;;;;;;;;;;;'...........,;;;;;;;;;;;;;;.      .;;;;;;;;;;;,.
     .,;;;;;;;;;;;;,..,;;;;;;;;;;;;;;;;;;;;;;;,.       ..;;;;;;;;;,.
    .,;;;;;;;;;;;;,. .,;;;;;;;;;;;;;;;;;;;;;;,.          .',;;;,,..
   .,;;;;;;;;;;;;,.  .,;;;;;;;;;;;;;;;;;;;;;,.              ....
    ..',;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.
       ..',;;;;'.    .,;;;;;;;;;;;;;;;;;;;'.
          ...'..     .';;;;;;;;;;;;;;,,,'.
                       ...............
*/

// https://github.com/trusttoken/smart-contracts
// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * // importANT: because control is transferred to `recipient`, care must be
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


// Dependency file: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity ^0.6.0;

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


// Dependency file: contracts/common/Initializable.sol

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/v3.0.0/contracts/Initializable.sol
// Added public isInitialized() view of private initialized bool.

// pragma solidity 0.6.10;

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


// Dependency file: contracts/common/UpgradeableERC20.sol

// pragma solidity 0.6.10;

// import {Address} from "@openzeppelin/contracts/utils/Address.sol";
// import {Context} from "@openzeppelin/contracts/GSN/Context.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

// import {Initializable} from "contracts/common/Initializable.sol";

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


// Dependency file: contracts/common/UpgradeableClaimable.sol

// pragma solidity 0.6.10;

// import {Context} from "@openzeppelin/contracts/GSN/Context.sol";

// import {Initializable} from "contracts/common/Initializable.sol";

/**
 * @title UpgradeableClaimable
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. Since
 * this contract combines Claimable and UpgradableOwnable contracts, ownership
 * can be later change via 2 step method {transferOwnership} and {claimOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract UpgradeableClaimable is Initializable, Context {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting a custom initial owner of choice.
     * @param __owner Initial owner of contract to be set.
     */
    function initialize(address __owner) internal initializer {
        _owner = __owner;
        emit OwnershipTransferred(address(0), __owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pending owner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}


// Dependency file: contracts/truefi2/interface/ILoanToken2.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ERC20} from "contracts/common/UpgradeableERC20.sol";
// import {ITrueFiPool2} from "contracts/truefi2/interface/ITrueFiPool2.sol";

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


// Dependency file: contracts/truefi2/interface/ITrueLender2.sol

// pragma solidity 0.6.10;

// import {ITrueFiPool2} from "contracts/truefi2/interface/ITrueFiPool2.sol";
// import {ILoanToken2} from "contracts/truefi2/interface/ILoanToken2.sol";

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


// Dependency file: contracts/truefi2/interface/IERC20WithDecimals.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint256);
}


// Dependency file: contracts/truefi2/interface/ITrueFiPoolOracle.sol

// pragma solidity 0.6.10;

// import {IERC20WithDecimals} from "contracts/truefi2/interface/IERC20WithDecimals.sol";

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


// Dependency file: contracts/truefi2/interface/I1Inch3.sol

// pragma solidity 0.6.10;
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


// Dependency file: contracts/truefi2/interface/IDeficiencyToken.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ILoanToken2} from "contracts/truefi2/interface/ILoanToken2.sol";

interface IDeficiencyToken is IERC20 {
    function loan() external view returns (ILoanToken2);

    function burnFrom(address account, uint256 amount) external;

    function version() external pure returns (uint8);
}


// Dependency file: contracts/truefi2/interface/ISAFU.sol

// pragma solidity 0.6.10;

// import {IDeficiencyToken} from "contracts/truefi2/interface/IDeficiencyToken.sol";
// import {ILoanToken2} from "contracts/truefi2/interface/ILoanToken2.sol";

interface ISAFU {
    function poolDeficit(address pool) external view returns (uint256);

    function deficiencyToken(ILoanToken2 loan) external view returns (IDeficiencyToken);

    function reclaim(ILoanToken2 loan, uint256 amount) external;
}


// Dependency file: contracts/truefi2/interface/ITrueFiPool2.sol

// pragma solidity 0.6.10;

// import {ERC20, IERC20} from "contracts/common/UpgradeableERC20.sol";
// import {ITrueLender2, ILoanToken2} from "contracts/truefi2/interface/ITrueLender2.sol";
// import {ITrueFiPoolOracle} from "contracts/truefi2/interface/ITrueFiPoolOracle.sol";
// import {I1Inch3} from "contracts/truefi2/interface/I1Inch3.sol";
// import {ISAFU} from "contracts/truefi2/interface/ISAFU.sol";

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


// Dependency file: contracts/truefi2/interface/ITrueRateAdjuster.sol

// pragma solidity 0.6.10;

// import {ITrueFiPool2} from "contracts/truefi2/interface/ITrueFiPool2.sol";

interface ITrueRateAdjuster {
    function rate(ITrueFiPool2 pool, uint8 score) external view returns (uint256);

    function proFormaRate(
        ITrueFiPool2 pool,
        uint8 score,
        uint256 amount
    ) external view returns (uint256);

    function securedRate(ITrueFiPool2 pool) external view returns (uint256);

    function poolBasicRate(ITrueFiPool2 pool) external view returns (uint256);

    function combinedRate(uint256 partialRate, uint256 __creditScoreAdjustmentRate) external pure returns (uint256);

    function creditScoreAdjustmentRate(uint8 score) external view returns (uint256);

    function utilizationAdjustmentRate(ITrueFiPool2 pool) external view returns (uint256);

    function fixedTermLoanAdjustment(uint256 term) external view returns (uint256);

    function borrowLimitAdjustment(uint8 score) external view returns (uint256);

    function borrowLimit(
        ITrueFiPool2 pool,
        uint8 score,
        uint256 maxBorrowerLimit,
        uint256 totalTVL,
        uint256 totalBorrowed
    ) external view returns (uint256);
}


// Dependency file: contracts/truefi2/interface/ITrueCreditAgency.sol

// pragma solidity 0.6.10;

// import {ITrueFiPool2} from "contracts/truefi2/interface/ITrueFiPool2.sol";

interface ITrueCreditAgency {
    function poolCreditValue(ITrueFiPool2 pool) external view returns (uint256);
}


// Dependency file: contracts/truefi2/interface/ITrueFiCreditOracle.sol

// pragma solidity 0.6.10;

interface ITrueFiCreditOracle {
    enum Status {Eligible, OnHold, Ineligible}

    function status(address account) external view returns (Status);

    function score(address account) external view returns (uint8);

    function maxBorrowerLimit(address account) external view returns (uint256);
}


// Dependency file: contracts/truefi2/interface/ITimeAveragedBaseRateOracle.sol

// pragma solidity 0.6.10;

interface ITimeAveragedBaseRateOracle {
    function calculateAverageAPY(uint16 numberOfValues) external view returns (uint256);

    function getWeeklyAPY() external view returns (uint256);

    function getMonthlyAPY() external view returns (uint256);

    function getYearlyAPY() external view returns (uint256);
}


// Root file: contracts/truefi2/TrueCreditAgency.sol

pragma solidity 0.6.10;

// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import {ERC20, IERC20, SafeMath} from "contracts/common/UpgradeableERC20.sol";
// import {UpgradeableClaimable} from "contracts/common/UpgradeableClaimable.sol";

// import {ITrueRateAdjuster} from "contracts/truefi2/interface/ITrueRateAdjuster.sol";
// import {ITrueFiPool2} from "contracts/truefi2/interface/ITrueFiPool2.sol";
// import {ITrueCreditAgency} from "contracts/truefi2/interface/ITrueCreditAgency.sol";
// import {ITrueFiCreditOracle} from "contracts/truefi2/interface/ITrueFiCreditOracle.sol";
// import {ITimeAveragedBaseRateOracle} from "contracts/truefi2/interface/ITimeAveragedBaseRateOracle.sol";

interface ITrueFiPool2WithDecimals is ITrueFiPool2 {
    function decimals() external view returns (uint8);
}

// prettier-ignore
/**
 * @title TrueCreditAgency
 * @dev Manager for Lines of Credit in the TrueFi Protocol
 * https://github.com/trusttoken/truefi-spec/blob/master/TrueFi2.0.md#lines-of-credit
 *
 * - Tracks interest rates and cumulative interest owed
 * - Data is grouped by score in "buckets" for scalability
 * - poke() functions used to update state for buckets
 * - Uses TrueRateAdjuster to calculate rates & limits
 * - Responsible for approving borrowing from TrueFi pools using Lines of Credit
 */
contract TrueCreditAgency is UpgradeableClaimable, ITrueCreditAgency {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    /// @dev credit scores are uint8
    uint8 constant MAX_CREDIT_SCORE = 255;

    /// @dev precision used for cumulative interest per share
    uint256 constant ADDITIONAL_PRECISION = 1e27;

    /// @dev total & cumulative interest for borrowers in a bucket
    struct SavedInterest {
        uint256 total;
        uint256 perShare;
    }

    /// @dev borrowers are grouped by score in order to scale more efficiently
    struct CreditScoreBucket {
        // number of borrowers in this bucket
        uint16 borrowersCount;
        // last updated timestamp
        uint128 timestamp;
        // current bucket rate
        uint256 rate;
        // how much interest was gathered by 1 wei times 10^27
        uint256 cumulativeInterestPerShare;
        // total borrowed in this bucket
        uint256 totalBorrowed;
        // save total & cumulative interest per borrower
        mapping(address => SavedInterest) savedInterest;
    }

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    /// @dev credit score buckets for each pool
    mapping(ITrueFiPool2 => CreditScoreBucket[256]) public buckets;

    /// @dev score per borrower for each pool
    mapping(ITrueFiPool2 => mapping(address => uint8)) public creditScore;

    /// @dev amount borrowed per borrower for each pool
    mapping(ITrueFiPool2 => mapping(address => uint256)) public borrowed;

    /// @dev total interest paid by borrower for each pool
    mapping(ITrueFiPool2 => mapping(address => uint256)) public borrowerTotalPaidInterest;

    /// @dev total interest paid for each pool
    mapping(ITrueFiPool2 => uint256) public poolTotalPaidInterest;

    /// @dev total interest for each pool
    mapping(ITrueFiPool2 => uint256) public poolTotalInterest;

    /// @dev next payment due time per borrower for each pool
    mapping(ITrueFiPool2 => mapping(address => uint256)) public nextInterestRepayTime;

    /// @dev whitelist for allowing pools to have lines of credit
    mapping(ITrueFiPool2 => bool) public isPoolAllowed;

    /// @dev array of pools with lines of credit
    ITrueFiPool2[] public pools;

    /// @dev whitelist for allowing borrowers to take lines of credit
    mapping(address => bool) public isBorrowerAllowed;

    /// @dev period over which regular interest payments must be made
    uint256 public interestRepaymentPeriod;

    /// @dev rate adjuster
    ITrueRateAdjuster public rateAdjuster;

    /// @dev credit oracle
    ITrueFiCreditOracle public creditOracle;

    /**
     * @dev Buckets Bitmap
     * This bitmap is used to non-empty buckets.
     * If at least one borrower with a score n has an opened credit line, the n-th bit of the bitmap is set
     * Profiling result of calling poke() with one borrower:
     * - 650k gas used without using bitmap
     * - 120k gas used using bitmap
     */
    uint256 public usedBucketsBitmap;

    /// @dev minimum credit score required to use lines of credit
    uint256 public minCreditScore;

    // ======= STORAGE DECLARATION END ============

    /// @dev emit `pool` and `oracle` when base rate oracle changed
    event BaseRateOracleChanged(ITrueFiPool2 pool, ITimeAveragedBaseRateOracle oracle);

    /// @dev emit `newRateAdjuster` when rate adjuster changed
    event TrueRateAdjusterChanged(ITrueRateAdjuster newRateAdjuster);

    /// @dev emit `who` and `isAllowed` when borrower allowance changes
    event BorrowerAllowed(address indexed who, bool isAllowed);

    /// @dev emit `pool` and `isAllowed` when pool allowance changes
    event PoolAllowed(ITrueFiPool2 pool, bool isAllowed);

    /// @dev emit `newPeriod` when interest repayment period changes
    event InterestRepaymentPeriodChanged(uint256 newPeriod);

    /// @dev emit `pool`, `amount` when `borrower` makes an interest payment
    event InterestPaid(ITrueFiPool2 pool, address borrower, uint256 amount);

    /// @dev emit `pool`, `amount` when `borrower` repays principal balance
    event PrincipalRepaid(ITrueFiPool2 pool, address borrower, uint256 amount);

    /// @dev emit `newValue` when minimum credit score is changed
    event MinCreditScoreChanged(uint256 newValue);

    /// @dev initialize
    function initialize(ITrueFiCreditOracle _creditOracle, ITrueRateAdjuster _rateAdjuster) public initializer {
        UpgradeableClaimable.initialize(msg.sender);
        creditOracle = _creditOracle;
        rateAdjuster = _rateAdjuster;
        interestRepaymentPeriod = 31 days;
    }

    /// @dev modifier for only whitelisted borrowers
    modifier onlyAllowedBorrowers() {
        require(isBorrowerAllowed[msg.sender], "TrueCreditAgency: Sender is not allowed to borrow");
        _;
    }

    /// @dev Set rateAdjuster to `newRateAdjuster` and update state
    function setRateAdjuster(ITrueRateAdjuster newRateAdjuster) external onlyOwner {
        rateAdjuster = newRateAdjuster;
        pokeAll();
        emit TrueRateAdjusterChanged(newRateAdjuster);
    }

    /// @dev set interestRepaymentPeriod to `newPeriod`
    function setInterestRepaymentPeriod(uint256 newPeriod) external onlyOwner {
        interestRepaymentPeriod = newPeriod;
        emit InterestRepaymentPeriodChanged(newPeriod);
    }

    /// @dev set minCreditScore to `newValue`
    function setMinCreditScore(uint256 newValue) external onlyOwner {
        minCreditScore = newValue;
        emit MinCreditScoreChanged(newValue);
    }

    /// @dev set borrower `who` to whitelist status `isAllowed`
    function allowBorrower(address who, bool isAllowed) external onlyOwner {
        isBorrowerAllowed[who] = isAllowed;
        emit BorrowerAllowed(who, isAllowed);
    }

    /**
     * @dev Allow `pool` to be used with lines of credit
     * Loop through
     */
    function allowPool(ITrueFiPool2 pool, bool isAllowed) external onlyOwner {
        // if allowing new pool, push to pools array
        if (!isPoolAllowed[pool] && isAllowed) {
            pools.push(pool);
        }
        // if disallowing pool, search for pool and remove from pools array
        if (isPoolAllowed[pool] && !isAllowed) {
            for (uint256 i = 0; i < pools.length; i++) {
                if (pools[i] == pool) {
                    pools[i] = pools[pools.length - 1];
                    pools.pop();
                    break;
                }
            }
        }
        // set new allowance
        isPoolAllowed[pool] = isAllowed;
        emit PoolAllowed(pool, isAllowed);
    }

    /**
     * @dev Update credit score for `borrower` in `pool` and refresh state
     * Can be called by anyone
     * @param pool Pool to update credit score for
     * @param borrower Borrower to update credit score for
     */
    function updateCreditScore(ITrueFiPool2 pool, address borrower) external {
        (uint8 oldScore, uint8 newScore) = _updateCreditScore(pool, borrower);
        if (oldScore == newScore) {
            return;
        }

        _rebucket(pool, borrower, oldScore, newScore, borrowed[pool][borrower]);
    }

    /**
     * @dev Internal function to update `borrower` credit score for `pool` using credit oracle
     * @return Tuple containing (oldScore, newScore)
     */
    function _updateCreditScore(ITrueFiPool2 pool, address borrower) internal returns (uint8, uint8) {
        uint8 oldScore = creditScore[pool][borrower];
        uint8 newScore = creditOracle.score(borrower);
        creditScore[pool][borrower] = newScore;
        return (oldScore, newScore);
    }

    /// @dev Get credit score adjustment from rate adjuster
    function creditScoreAdjustmentRate(ITrueFiPool2 pool, address borrower) public view returns (uint256) {
        return rateAdjuster.creditScoreAdjustmentRate(creditScore[pool][borrower]);
    }

    /// @dev Get utilization adjustment from rate adjuster
    function utilizationAdjustmentRate(ITrueFiPool2 pool) public view returns (uint256) {
        return rateAdjuster.utilizationAdjustmentRate(pool);
    }

    /// @dev Get borrow limit adjustment from rate adjuster
    function borrowLimitAdjustment(uint8 score) public view returns (uint256) {
        return rateAdjuster.borrowLimitAdjustment(score);
    }

    /**
     * @dev Calculate total TVL in USD
     * @param decimals Precision to return
     * @return TVL for all pools with lines of credit
     */
    function totalTVL(uint8 decimals) public view returns (uint256) {
        uint256 tvl = 0;
        uint256 resultPrecision = uint256(10)**decimals;

        // loop through pools and sum tvl accounting for precision
        for (uint8 i = 0; i < pools.length; i++) {
            tvl = tvl.add(
                pools[i].poolValue().mul(resultPrecision).div(uint256(10)**(ITrueFiPool2WithDecimals(address(pools[i])).decimals()))
            );
        }
        return tvl;
    }

    /**
     * @dev Get total amount borrowed for `borrower` from lines of credit in USD
     * @param borrower Borrower to get amount borrowed for
     * @param decimals Precision to use when calculating total borrowed
     * @return Total amount borrowed for `borrower` in USD
     */
    function totalBorrowed(address borrower, uint8 decimals) public view returns (uint256) {
        uint256 borrowSum = 0;
        uint256 resultPrecision = uint256(10)**decimals;

        // loop through pools and sum amount borrowed accounting for precision
        for (uint8 i = 0; i < pools.length; i++) {
            borrowSum = borrowSum.add(
                borrowed[pools[i]][borrower].mul(resultPrecision).div(
                    uint256(10)**(ITrueFiPool2WithDecimals(address(pools[i])).decimals())
                )
            );
        }
        return borrowSum;
    }

    /**
     * @dev Get borrow limit for `borrower` in `pool` using rate adjuster
     * @param pool Pool to get borrow limit for
     * @param borrower Borrower to get borrow limit for
     * @return borrow limit for `borrower` in `pool`
     */
    function borrowLimit(ITrueFiPool2 pool, address borrower) public view returns (uint256) {
        uint8 poolDecimals = ITrueFiPool2WithDecimals(address(pool)).decimals();
        return
            rateAdjuster.borrowLimit(
                pool,
                creditOracle.score(borrower),
                creditOracle.maxBorrowerLimit(borrower),
                totalTVL(poolDecimals),
                totalBorrowed(borrower, poolDecimals)
            );
    }

    /**
     * @dev Get current rate for `borrower` in `pool` from rate adjuster
     * @return current rate for `borrower` in `pool`
     */
    function currentRate(ITrueFiPool2 pool, address borrower) external view returns (uint256) {
        return rateAdjuster.rate(pool, creditScore[pool][borrower]);
    }

    /**
     * @dev Get interest rate for `borrower` in `pool` from storage
     * @return Interest owed for `borrower` in `pool`
     */
    function interest(ITrueFiPool2 pool, address borrower) public view returns (uint256) {
        CreditScoreBucket storage bucket = buckets[pool][creditScore[pool][borrower]];
        return _interest(pool, bucket, borrower);
    }

    /**
     * @dev Borrow from `pool` for `amount` using lines of credit
     * Only whitelisted borrowers that meet all requirements can borrow
     * @param pool Pool to borrow from
     * @param amount Amount of tokens to borrow
     */
    function borrow(ITrueFiPool2 pool, uint256 amount) external onlyAllowedBorrowers {
        require(isPoolAllowed[pool], "TrueCreditAgency: The pool is not whitelisted for borrowing");
        require(
            creditOracle.status(msg.sender) == ITrueFiCreditOracle.Status.Eligible,
            "TrueCreditAgency: Sender not eligible to borrow"
        );
        require(!_hasOverdueInterest(pool, msg.sender), "TrueCreditAgency: Sender has overdue interest in this pool");
        (uint8 oldScore, uint8 newScore) = _updateCreditScore(pool, msg.sender);
        require(newScore >= minCreditScore, "TrueCreditAgency: Borrower has credit score below minimum");
        require(amount <= borrowLimit(pool, msg.sender), "TrueCreditAgency: Borrow amount cannot exceed borrow limit");
        uint256 currentDebt = borrowed[pool][msg.sender];

        if (currentDebt == 0) {
            nextInterestRepayTime[pool][msg.sender] = block.timestamp.add(interestRepaymentPeriod);
        }

        _rebucket(pool, msg.sender, oldScore, newScore, currentDebt.add(amount));

        pool.borrow(amount);
        pool.token().safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Pay full balance of interest to `pool`
     * Calling this function resets a timer for when interest payments are due
     * Borrowers should call this function at least once per payment period
     * @param pool Pool to pay full balacne of interest for
     */
    function payInterest(ITrueFiPool2 pool) external {
        repay(pool, interest(pool, msg.sender));
    }

    /**
     * @dev Function to repay debt in `pool` for `amount`
     * Accrued interest is always repaid first before principal
     * Paying equal to or greater than accrued interest resets next repayment time
     * @param pool Pool to repay principal for
     * @param amount Amount of tokens to repay
     */
    function repay(ITrueFiPool2 pool, uint256 amount) public {
        uint256 currentDebt = borrowed[pool][msg.sender];
        uint256 accruedInterest = interest(pool, msg.sender);
        require(currentDebt.add(accruedInterest) >= amount, "TrueCreditAgency: Cannot repay over the debt");

        // update state before making token transfer
        if (amount < accruedInterest) {
            _payInterestWithoutTransfer(pool, amount);
        } else {
            nextInterestRepayTime[pool][msg.sender] = block.timestamp.add(interestRepaymentPeriod);
            _payInterestWithoutTransfer(pool, accruedInterest);
            _payPrincipalWithoutTransfer(pool, amount.sub(accruedInterest));
        }
        if (borrowed[pool][msg.sender] == 0) {
            nextInterestRepayTime[pool][msg.sender] = 0;
        }
        // transfer token from sender wallets
        _repay(pool, amount);
    }

    /**
     * @dev Repay principal and interest for `pool` in a single transaction
     * @param pool Pool to repay full debt in
     */
    function repayInFull(ITrueFiPool2 pool) external {
        repay(pool, interest(pool, msg.sender).add(borrowed[pool][msg.sender]));
    }

    /**
     * @dev Update state for a pool
     * @param pool Pool to update state for
     */
    function poke(ITrueFiPool2 pool) public {
        uint256 bitMap = usedBucketsBitmap;
        uint256 timeNow = block.timestamp;
        // get basic pool rate
        uint256 poolRate = rateAdjuster.poolBasicRate(pool);

        // loop through scores and poke buckets, ignoring empty buckets
        for (uint16 i = 0; i <= MAX_CREDIT_SCORE; (i++, bitMap >>= 1)) {
            if (bitMap & 1 == 0) {
                continue;
            }

            _pokeSingleBucket(pool, uint8(i), timeNow, poolRate);
        }
    }

    /**
     * @dev Update state for all pools
     */
    function pokeAll() public {
        // loop through pools array and poke
        for (uint256 i = 0; i < pools.length; i++) {
            poke(pools[i]);
        }
    }

    /// @dev Internal function to update state for `bucketNumber` in `pool`
    function pokeSingleBucket(ITrueFiPool2 pool, uint8 bucketNumber) internal {
        uint256 timeNow = block.timestamp;
        uint256 poolRate = rateAdjuster.poolBasicRate(pool);

        _pokeSingleBucket(pool, bucketNumber, timeNow, poolRate);
    }

    /**
     * @dev Internal function to update state for a single bucket
     * @param pool Pool to update bucket for
     * @param bucketNumber Bucket to update
     * @param timeNow Current time
     * @param poolRate Pool base rate
     */
    function _pokeSingleBucket(
        ITrueFiPool2 pool,
        uint8 bucketNumber,
        uint256 timeNow,
        uint256 poolRate
    ) internal {
        CreditScoreBucket storage bucket = buckets[pool][bucketNumber];

        uint256 newInterestPerShare = _newInterestPerShare(bucket, timeNow);
        poolTotalInterest[pool] = poolTotalInterest[pool].add(bucket.totalBorrowed.mul(newInterestPerShare));
        bucket.cumulativeInterestPerShare = bucket.cumulativeInterestPerShare.add(newInterestPerShare);

        bucket.rate = rateAdjuster.combinedRate(poolRate, rateAdjuster.creditScoreAdjustmentRate(bucketNumber));
        bucket.timestamp = uint128(timeNow);
    }

    /// @dev Calculate new interest per share for `bucket` at `timeNow`
    function _newInterestPerShare(CreditScoreBucket storage bucket, uint256 timeNow) private view returns (uint256) {
        return bucket.rate.mul(timeNow.sub(bucket.timestamp)).mul(ADDITIONAL_PRECISION / 10_000).div(365 days);
    }

    /**
     * @dev Calculate USD value for credit lines in pool
     * @param pool Pool to get USD value for
     * @return USD value of credit lines for pool
     */
    function poolCreditValue(ITrueFiPool2 pool) external override view returns (uint256) {
        uint256 bitMap = usedBucketsBitmap;
        CreditScoreBucket[256] storage creditScoreBuckets = buckets[pool];
        uint256 timeNow = block.timestamp;
        uint256 bucketSum = 0;

        // loop through buckets and sum total borrowed ignoring empty buckets
        for (uint16 i = 0; i <= MAX_CREDIT_SCORE; (i++, bitMap >>= 1)) {
            if (bitMap & 1 == 0) {
                continue;
            }

            CreditScoreBucket storage bucket = creditScoreBuckets[i];

            bucketSum = bucketSum.add(bucket.totalBorrowed.mul(ADDITIONAL_PRECISION));
            bucketSum = bucketSum.add(bucket.totalBorrowed.mul(_newInterestPerShare(bucket, timeNow)));
        }
        return (poolTotalInterest[pool].add(bucketSum).div(ADDITIONAL_PRECISION)).sub(poolTotalPaidInterest[pool]);
    }

    /**
     * @dev Get value of a single line of credit for `borrower` in `pool`
     * @return Value of a borrower's line of credit in a pool
     */
    function singleCreditValue(ITrueFiPool2 pool, address borrower) external view returns (uint256) {
        return borrowed[pool][borrower].add(interest(pool, borrower));
    }

    /**
     * @dev Internal function to check if a borrower has overdue interest
     * @return Returns true if a borrower is overdue
     */
    function _hasOverdueInterest(ITrueFiPool2 pool, address borrower) private view returns (bool) {
        return borrowed[pool][borrower] > 0 && block.timestamp >= nextInterestRepayTime[pool][borrower];
    }

    /**
     * @dev Move borrower from one bucket to another when borrower score changes
     * @param pool Pool to rebucket in
     * @param borrower Borrower to move to a new bucket
     * @param oldScore Old credit score
     * @param newScore New credit score
     * @param updatedBorrowAmount New borrower amount
     */
    function _rebucket(
        ITrueFiPool2 pool,
        address borrower,
        uint8 oldScore,
        uint8 newScore,
        uint256 updatedBorrowAmount
    ) internal {
        // take out of old bucket
        uint256 totalBorrowerInterest = oldScore > 0 ? _takeOutOfBucket(pool, buckets[pool][oldScore], oldScore, borrower) : 0;
        // update borrow amount
        borrowed[pool][borrower] = updatedBorrowAmount;
        CreditScoreBucket storage bucket = buckets[pool][newScore];
        // put into new bucket
        _putIntoBucket(pool, bucket, newScore, borrower);
        // save interest
        bucket.savedInterest[borrower] = SavedInterest(totalBorrowerInterest, bucket.cumulativeInterestPerShare);
    }

    /**
     * @dev Internal function to take `borrower` out of a bucket
     * @param pool Pool to remove borrower from
     * @param bucket Bucket data
     * @param bucketNumber Bucket number based on credit score
     * @param borrower Borrower to take out of bucket
     * @return totalBorrowerInterest Total borrower interest for this pool
     */
    function _takeOutOfBucket(
        ITrueFiPool2 pool,
        CreditScoreBucket storage bucket,
        uint8 bucketNumber,
        address borrower
    ) internal returns (uint256 totalBorrowerInterest) {
        require(bucket.borrowersCount > 0, "TrueCreditAgency: bucket is empty");
        // update bucket state
        pokeSingleBucket(pool, bucketNumber);
        // decrement count for this bucket
        bucket.borrowersCount -= 1;
        // clear bucket bitmap if bucket is empty
        if (bucket.borrowersCount == 0) {
            usedBucketsBitmap &= ~(uint256(1) << bucketNumber);
        }
        // adjust total borrow & interest for bucket and delete in storage
        bucket.totalBorrowed = bucket.totalBorrowed.sub(borrowed[pool][borrower]);
        totalBorrowerInterest = _totalBorrowerInterest(pool, bucket, borrower);
        delete bucket.savedInterest[borrower];
    }

    /**
     * @dev Internal function to put borrower into a bucket
     * @param pool Pool to add borrower to
     * @param bucket Bucket data
     * @param bucketNumber Bucket number based on credit score
     * @param borrower Borrower to put into bucket
     */
    function _putIntoBucket(
        ITrueFiPool2 pool,
        CreditScoreBucket storage bucket,
        uint8 bucketNumber,
        address borrower
    ) internal {
        // update  bucket state
        pokeSingleBucket(pool, bucketNumber);
        // increment count for this bucket
        bucket.borrowersCount = bucket.borrowersCount + 1;
        // add to bitmap if first time in this bucket
        if (bucket.borrowersCount == 1) {
            usedBucketsBitmap |= uint256(1) << bucketNumber;
        }
        // adjust total borrow in bucket
        bucket.totalBorrowed = bucket.totalBorrowed.add(borrowed[pool][borrower]);
    }

    /**
     * @dev Internal helper to calculate total borrower interest in a pool based on bucket share
     * @param pool Pool to calculate interest for
     * @param bucket Bucket data
     * @param borrower Borrower to get total interest for
     * @return Borrower total interest for a pool
     */
    function _totalBorrowerInterest(
        ITrueFiPool2 pool,
        CreditScoreBucket storage bucket,
        address borrower
    ) internal view returns (uint256) {
        uint256 interestPerShare = bucket.cumulativeInterestPerShare.sub(bucket.savedInterest[borrower].perShare).add(
            _newInterestPerShare(bucket, block.timestamp)
        );
        return bucket.savedInterest[borrower].total.add(borrowed[pool][borrower].mul(interestPerShare).div(ADDITIONAL_PRECISION));
    }

    /**
     * @dev Internal function to calculate interest for a single pool 
     * @param pool Pool to calculate interest for
     * @param bucket Bucket data
     * @param borrower Borrower to get total interest for
     * @return `borrower` interest in `pool`
     */
    function _interest(
        ITrueFiPool2 pool,
        CreditScoreBucket storage bucket,
        address borrower
    ) internal view returns (uint256) {
        return _totalBorrowerInterest(pool, bucket, borrower).sub(borrowerTotalPaidInterest[pool][borrower]);
    }

    /**
     * @dev Internal function to change state when msg.sender pays interest
     * Used before transfer to satisfy check-effects interactions
     * @param pool Pool to pay interest in for msg.sender
     * @param amount Amount of interest to pay for msg.sender
     */
    function _payInterestWithoutTransfer(ITrueFiPool2 pool, uint256 amount) internal {
        borrowerTotalPaidInterest[pool][msg.sender] = borrowerTotalPaidInterest[pool][msg.sender].add(amount);
        poolTotalPaidInterest[pool] = poolTotalPaidInterest[pool].add(amount);
        emit InterestPaid(pool, msg.sender, amount);
    }

    /**
     * @dev Internal function to change state when msg.sender pays principal
     * Used before transfer to satisfy check-effects interactions
     * @param pool Pool to pay principal in for msg.sender
     * @param amount Amount of principal to pay for msg.sender
     */
    function _payPrincipalWithoutTransfer(ITrueFiPool2 pool, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        (uint8 oldScore, uint8 newScore) = _updateCreditScore(pool, msg.sender);
        _rebucket(pool, msg.sender, oldScore, newScore, borrowed[pool][msg.sender].sub(amount));

        emit PrincipalRepaid(pool, msg.sender, amount);
    }

    /**
     * @dev Internal function used to approve and transfer tokens from agency to pool
     * Called after "payWithoutTransfer" functions to satisfy check-effects interactions
     * @param pool Pool to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function _repay(ITrueFiPool2 pool, uint256 amount) internal {
        pool.token().safeTransferFrom(msg.sender, address(this), amount);
        pool.token().safeApprove(address(pool), amount);
        pool.repay(amount);
    }
}