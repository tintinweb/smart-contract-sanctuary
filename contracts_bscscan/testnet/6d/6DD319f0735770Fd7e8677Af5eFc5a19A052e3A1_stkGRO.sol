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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
}

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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { Math } from "./modules/Math.sol";
import { Wrapping } from "./modules/Wrapping.sol";
import { Transfers } from "./modules/Transfers.sol";
import { Conversions } from "./modules/Conversions.sol";
import { FlashLoans } from "./modules/FlashLoans.sol";
import { Multisig } from "./modules/Multisig.sol";
import { BalancerLiquidityPoolAbstraction } from "./modules/BalancerLiquidityPoolAbstraction.sol";

/**
 * @dev This public library provides a single entrypoint to most of the relevant
 *      internal libraries available in the modules folder. It exists to
 *      circunvent the contract size limitation imposed by the EVM. All function
 *      calls are directly delegated to the target library function preserving
 *      argument and return values exactly as they are. This library is shared
 *      by many contracts and even other public libraries from this repository,
 *      therefore it needs to be published alongside them.
 */
library G
{
	function min(uint256 _amount1, uint256 _amount2) public pure returns (uint256 _minAmount) { return Math._min(_amount1, _amount2); }
//	function max(uint256 _amount1, uint256 _amount2) public pure returns (uint256 _maxAmount) { return Math._max(_amount1, _amount2); }

//	function wrap(uint256 _amount) public returns (bool _success) { return Wrapping._wrap(_amount); }
//	function unwrap(uint256 _amount) public returns (bool _success) { return Wrapping._unwrap(_amount); }
	function safeWrap(uint256 _amount) public { Wrapping._safeWrap(_amount); }
	function safeUnwrap(uint256 _amount) public { Wrapping._safeUnwrap(_amount); }

	function getBalance(address _token) public view returns (uint256 _balance) { return Transfers._getBalance(_token); }
	function pullFunds(address _token, address _from, uint256 _amount) public { Transfers._pullFunds(_token, _from, _amount); }
	function pushFunds(address _token, address _to, uint256 _amount) public { Transfers._pushFunds(_token, _to, _amount); }
	function approveFunds(address _token, address _to, uint256 _amount) public { Transfers._approveFunds(_token, _to, _amount); }

//	function calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) public view returns (uint256 _outputAmount) { return Conversions._calcConversionOutputFromInput(_from, _to, _inputAmount); }
//	function calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) public view returns (uint256 _inputAmount) { return Conversions._calcConversionInputFromOutput(_from, _to, _outputAmount); }
//	function convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) public returns (uint256 _outputAmount) { return Conversions._convertFunds(_from, _to, _inputAmount, _minOutputAmount); }
	function dynamicConvertFunds(address _exchange, address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) public returns (uint256 _outputAmount) { return Conversions._dynamicConvertFunds(_exchange, _from, _to, _inputAmount, _minOutputAmount); }

//	function estimateFlashLoanFee(FlashLoans.Provider _provider, address _token, uint256 _netAmount) public pure returns (uint256 _feeAmount) { return FlashLoans._estimateFlashLoanFee(_provider, _token, _netAmount); }
	function getFlashLoanLiquidity(address _token) public view returns (uint256 _liquidityAmount) { return FlashLoans._getFlashLoanLiquidity(_token); }
	function requestFlashLoan(address _token, uint256 _amount, bytes memory _context) public returns (bool _success) { return FlashLoans._requestFlashLoan(_token, _amount, _context); }
	function paybackFlashLoan(FlashLoans.Provider _provider, address _token, uint256 _grossAmount) public { FlashLoans._paybackFlashLoan(_provider, _token, _grossAmount); }

	function getOwners(address _safe) public view returns (address[] memory _owners) { return Multisig._getOwners(_safe); }
	function isOwner(address _safe, address _owner) public view returns (bool _isOwner) { return Multisig._isOwner(_safe, _owner); }
	function addOwnerWithThreshold(address _safe, address _owner, uint256 _threshold) public returns (bool _success) { return Multisig._addOwnerWithThreshold(_safe, _owner, _threshold); }
	function removeOwner(address _safe, address _prevOwner, address _owner, uint256 _threshold) public returns (bool _success) { return Multisig._removeOwner(_safe, _prevOwner, _owner, _threshold); }
	function changeThreshold(address _safe, uint256 _threshold) public returns (bool _success) { return Multisig._changeThreshold(_safe, _threshold); }

	function createPool(address _token0, uint256 _amount0, address _token1, uint256 _amount1) public returns (address _pool) { return BalancerLiquidityPoolAbstraction._createPool(_token0, _amount0, _token1, _amount1); }
	function joinPool(address _pool, address _token, uint256 _maxAmount) public returns (uint256 _amount) { return BalancerLiquidityPoolAbstraction._joinPool(_pool, _token, _maxAmount); }
	function exitPool(address _pool, uint256 _percent) public returns (uint256 _amount0, uint256 _amount1) { return BalancerLiquidityPoolAbstraction._exitPool(_pool, _percent); }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { CompoundLendingMarketAbstraction } from "./modules/CompoundLendingMarketAbstraction.sol";

/**
 * @dev This public library provides a single entrypoint to the Compound lending
 *      market internal library available in the modules folder. It is a
 *      complement to the G.sol library. Both libraries exists to circunvent the
 *      contract size limitation imposed by the EVM. See G.sol for further
 *      documentation.
 */
library GC
{
	function getUnderlyingToken(address _ctoken) public view returns (address _token) { return CompoundLendingMarketAbstraction._getUnderlyingToken(_ctoken); }
	function getCollateralRatio(address _ctoken) public view returns (uint256 _collateralFactor) { return CompoundLendingMarketAbstraction._getCollateralRatio(_ctoken); }
	function getMarketAmount(address _ctoken) public view returns (uint256 _marketAmount) { return CompoundLendingMarketAbstraction._getMarketAmount(_ctoken); }
	function getLiquidityAmount(address _ctoken) public view returns (uint256 _liquidityAmount) { return CompoundLendingMarketAbstraction._getLiquidityAmount(_ctoken); }
//	function getAvailableAmount(address _ctoken, uint256 _marginAmount) public view returns (uint256 _availableAmount) { return CompoundLendingMarketAbstraction._getAvailableAmount(_ctoken, _marginAmount); }
	function getExchangeRate(address _ctoken) public view returns (uint256 _exchangeRate) { return CompoundLendingMarketAbstraction._getExchangeRate(_ctoken); }
	function fetchExchangeRate(address _ctoken) public returns (uint256 _exchangeRate) { return CompoundLendingMarketAbstraction._fetchExchangeRate(_ctoken); }
	function getLendAmount(address _ctoken) public view returns (uint256 _amount) { return CompoundLendingMarketAbstraction._getLendAmount(_ctoken); }
	function fetchLendAmount(address _ctoken) public returns (uint256 _amount) { return CompoundLendingMarketAbstraction._fetchLendAmount(_ctoken); }
	function getBorrowAmount(address _ctoken) public view returns (uint256 _amount) { return CompoundLendingMarketAbstraction._getBorrowAmount(_ctoken); }
	function fetchBorrowAmount(address _ctoken) public returns (uint256 _amount) { return CompoundLendingMarketAbstraction._fetchBorrowAmount(_ctoken); }
//	function enter(address _ctoken) public returns (bool _success) { return CompoundLendingMarketAbstraction._enter(_ctoken); }
	function lend(address _ctoken, uint256 _amount) public returns (bool _success) { return CompoundLendingMarketAbstraction._lend(_ctoken, _amount); }
	function redeem(address _ctoken, uint256 _amount) public returns (bool _success) { return CompoundLendingMarketAbstraction._redeem(_ctoken, _amount); }
	function borrow(address _ctoken, uint256 _amount) public returns (bool _success) { return CompoundLendingMarketAbstraction._borrow(_ctoken, _amount); }
	function repay(address _ctoken, uint256 _amount) public returns (bool _success) { return CompoundLendingMarketAbstraction._repay(_ctoken, _amount); }
	function safeEnter(address _ctoken) public { CompoundLendingMarketAbstraction._safeEnter(_ctoken); }
	function safeLend(address _ctoken, uint256 _amount) public { CompoundLendingMarketAbstraction._safeLend(_ctoken, _amount); }
	function safeRedeem(address _ctoken, uint256 _amount) public { CompoundLendingMarketAbstraction._safeRedeem(_ctoken, _amount); }
//	function safeBorrow(address _ctoken, uint256 _amount) public { CompoundLendingMarketAbstraction._safeBorrow(_ctoken, _amount); }
//	function safeRepay(address _ctoken, uint256 _amount) public { CompoundLendingMarketAbstraction._safeRepay(_ctoken, _amount); }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { GToken } from "./GToken.sol";
import { G } from "./G.sol";
import { GC } from "./GC.sol";

/**
 * @dev This library implements data structure abstraction for the delegated
 *      reserve management code in order to circuvent the EVM contract size limit.
 *      It is therefore a public library shared by all gcToken Type 2 contracts and
 *      needs to be published alongside them. See GCTokenType2.sol for further
 *      documentation.
 */
library GCDelegatedReserveManager
{
	using SafeMath for uint256;
	using GCDelegatedReserveManager for GCDelegatedReserveManager.Self;

	uint256 constant MAXIMUM_COLLATERALIZATION_RATIO = 96e16; // 96% of 50% = 48%
	uint256 constant DEFAULT_COLLATERALIZATION_RATIO = 66e16; // 66% of 50% = 33%
	uint256 constant DEFAULT_COLLATERALIZATION_MARGIN = 15e16; // 15% of 50% = 7.5%

	struct Self {
		address reserveToken;
		address underlyingToken;

		address exchange;

		address miningToken;
		uint256 miningMinGulpAmount;
		uint256 miningMaxGulpAmount;

		address borrowToken;

		address growthToken;
		address growthReserveToken;
		uint256 growthMinGulpAmount;
		uint256 growthMaxGulpAmount;

		uint256 collateralizationRatio;
		uint256 collateralizationMargin;
	}

	/**
	 * @dev Initializes the data structure. This method is exposed publicly.
	 *      Note that the underlying borrowing token must match the growth
	 *      reserve token given that funds borrowed will be reinvested in
	 *      the provided growth token (gToken).
	 * @param _reserveToken The ERC-20 token address of the reserve token (cToken).
	 * @param _miningToken The ERC-20 token address to be collected from
	 *                     liquidity mining (COMP).
	 * @param _borrowToken The ERC-20 token address of the borrow token (cToken).
	 * @param _growthToken The ERC-20 token address of the growth token (gToken).
	 */
	function init(Self storage _self, address _reserveToken, address _miningToken, address _borrowToken, address _growthToken) public
	{
		address _underlyingToken = GC.getUnderlyingToken(_reserveToken);
		address _borrowUnderlyingToken = GC.getUnderlyingToken(_borrowToken);
		address _growthReserveToken = GToken(_growthToken).reserveToken();
		assert(_borrowUnderlyingToken == _growthReserveToken);

		_self.reserveToken = _reserveToken;
		_self.underlyingToken = _underlyingToken;

		_self.exchange = address(0);

		_self.miningToken = _miningToken;
		_self.miningMinGulpAmount = 0;
		_self.miningMaxGulpAmount = 0;

		_self.borrowToken = _borrowToken;

		_self.growthToken = _growthToken;
		_self.growthReserveToken = _growthReserveToken;
		_self.growthMinGulpAmount = 0;
		_self.growthMaxGulpAmount = 0;

		_self.collateralizationRatio = DEFAULT_COLLATERALIZATION_RATIO;
		_self.collateralizationMargin = DEFAULT_COLLATERALIZATION_MARGIN;

		GC.safeEnter(_reserveToken);
	}

	/**
	 * @dev Sets the contract address for asset conversion delegation.
	 *      This library converts the miningToken into the underlyingToken
	 *      and use the assets to back the reserveToken. See GExchange.sol
	 *      for further documentation. This method is exposed publicly.
	 * @param _exchange The address of the contract that implements the
	 *                  GExchange interface.
	 */
	function setExchange(Self storage _self, address _exchange) public
	{
		_self.exchange = _exchange;
	}

	/**
	 * @dev Sets the range for converting liquidity mining assets. This
	 *      method is exposed publicly.
	 * @param _miningMinGulpAmount The minimum amount, funds will only be
	 *                             converted once the minimum is accumulated.
	 * @param _miningMaxGulpAmount The maximum amount, funds beyond this
	 *                             limit will not be converted and are left
	 *                             for future rounds of conversion.
	 */
	function setMiningGulpRange(Self storage _self, uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public
	{
		require(_miningMinGulpAmount <= _miningMaxGulpAmount, "invalid range");
		_self.miningMinGulpAmount = _miningMinGulpAmount;
		_self.miningMaxGulpAmount = _miningMaxGulpAmount;
	}

	/**
	 * @dev Sets the range for converting growth profits. This
	 *      method is exposed publicly.
	 * @param _growthMinGulpAmount The minimum amount, funds will only be
	 *                             converted once the minimum is accumulated.
	 * @param _growthMaxGulpAmount The maximum amount, funds beyond this
	 *                             limit will not be converted and are left
	 *                             for future rounds of conversion.
	 */
	function setGrowthGulpRange(Self storage _self, uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount) public
	{
		require(_growthMinGulpAmount <= _growthMaxGulpAmount, "invalid range");
		_self.growthMinGulpAmount = _growthMinGulpAmount;
		_self.growthMaxGulpAmount = _growthMaxGulpAmount;
	}

	/**
	 * @dev Sets the collateralization ratio and margin. These values are
	 *      percentual and relative to the maximum collateralization ratio
	 *      provided by the underlying asset. This method is exposed publicly.
	 * @param _collateralizationRatio The target collateralization ratio,
	 *                                between lend and borrow, that the
	 *                                reserve will try to maintain.
	 * @param _collateralizationMargin The deviation from the target ratio
	 *                                 that should be accepted.
	 */
	function setCollateralizationRatio(Self storage _self, uint256 _collateralizationRatio, uint256 _collateralizationMargin) public
	{
		require(_collateralizationMargin <= _collateralizationRatio && _collateralizationRatio.add(_collateralizationMargin) <= MAXIMUM_COLLATERALIZATION_RATIO, "invalid ratio");
		_self.collateralizationRatio = _collateralizationRatio;
		_self.collateralizationMargin = _collateralizationMargin;
	}

	/**
	 * @dev Performs the reserve adjustment actions leaving a liquidity room,
	 *      if necessary. It will attempt to incorporate the liquidity mining
	 *      assets into the reserve, the profits from the underlying growth
	 *      investment and adjust the collateralization targeting the
	 *      configured ratio. This method is exposed publicly.
	 * @param _roomAmount The underlying token amount to be available after the
	 *                    operation. This is revelant for withdrawals, once the
	 *                    room amount is withdrawn the reserve should reflect
	 *                    the configured collateralization ratio.
	 * @return _success A boolean indicating whether or not both actions suceeded.
	 */
	function adjustReserve(Self storage _self, uint256 _roomAmount) public returns (bool _success)
	{
		bool _success1 = _self._gulpMiningAssets();
		bool _success2 = _self._gulpGrowthAssets();
		bool _success3 = _self._adjustReserve(_roomAmount);
		return _success1 && _success2 && _success3;
	}

	/**
	 * @dev Calculates the collateralization ratio relative to the maximum
	 *      collateralization ratio provided by the underlying asset.
	 * @return _collateralizationRatio The target absolute collateralization ratio.
	 */
	function _calcCollateralizationRatio(Self storage _self) internal view returns (uint256 _collateralizationRatio)
	{
		return GC.getCollateralRatio(_self.reserveToken).mul(_self.collateralizationRatio).div(1e18);
	}

	/**
	 * @dev Incorporates the liquidity mining assets into the reserve. Assets
	 *      are converted to the underlying asset and then added to the reserve.
	 *      If the amount available is below the minimum, or if the exchange
	 *      contract is not set, nothing is done. Otherwise the operation is
	 *      performed, limited to the maximum amount. Note that this operation
	 *      will incorporate to the reserve all the underlying token balance
	 *      including funds sent to it or left over somehow.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _gulpMiningAssets(Self storage _self) internal returns (bool _success)
	{
		if (_self.exchange == address(0)) return true;
		if (_self.miningMaxGulpAmount == 0) return true;
		uint256 _miningAmount = G.getBalance(_self.miningToken);
		if (_miningAmount == 0) return true;
		if (_miningAmount < _self.miningMinGulpAmount) return true;
		_self._convertMiningToUnderlying(G.min(_miningAmount, _self.miningMaxGulpAmount));
		return GC.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	/**
	 * @dev Incorporates the profits from growth into the reserve. Assets
	 *      are converted to the underlying asset and then added to the reserve.
	 *      If the amount available is below the minimum, or if the exchange
	 *      contract is not set, nothing is done. Otherwise the operation is
	 *      performed, limited to the maximum amount. Note that this operation
	 *      will incorporate to the reserve all the growth reserve token balance
	 *      including funds sent to it or left over somehow.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _gulpGrowthAssets(Self storage _self) internal returns (bool _success)
	{
		if (_self.exchange == address(0)) return true;
		if (_self.growthMaxGulpAmount == 0) return true;
		// calculates how much was borrowed
		uint256 _borrowAmount = GC.fetchBorrowAmount(_self.borrowToken);
		// calculates how much can be redeemed from the growth token
		uint256 _totalShares = G.getBalance(_self.growthToken);
		uint256 _redeemableAmount = _self._calcWithdrawalCostFromShares(_totalShares);
		// if there is a profit and that amount is within range
		// it gets converted to the underlying reserve token and
		// incorporated to the reserve
		if (_redeemableAmount <= _borrowAmount) return true;
		uint256 _growthAmount = _redeemableAmount.sub(_borrowAmount);
		if (_growthAmount < _self.growthMinGulpAmount) return true;
		uint256 _grossShares = _self._calcWithdrawalSharesFromCost(G.min(_growthAmount, _self.growthMaxGulpAmount));
		_grossShares = G.min(_grossShares, _totalShares);
		if (_grossShares == 0) return true;
		_success = _self._withdraw(_grossShares);
		if (!_success) return false;
		_self._convertGrowthReserveToUnderlying(G.getBalance(_self.growthReserveToken));
		return GC.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	/**
	 * @dev Adjusts the reserve to match the configured collateralization
	 *      ratio. It uses the reserve collateral to borrow a proper amount
	 *      of the growth token reserve asset and deposit it. Or it
	 *      redeems from the growth token and repays the loan.
	 * @param _roomAmount The amount of underlying token to be liquid after
	 *                    the operation.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _adjustReserve(Self storage _self, uint256 _roomAmount) internal returns (bool _success)
	{
		// calculates the percental change from the current reserve
		// and the reserve deducting the room amount
		uint256 _scalingRatio;
		{
			uint256 _reserveAmount = GC.fetchLendAmount(_self.reserveToken);
			_roomAmount = G.min(_roomAmount, _reserveAmount);
			uint256 _newReserveAmount = _reserveAmount.sub(_roomAmount);
			_scalingRatio = _reserveAmount > 0 ? uint256(1e18).mul(_newReserveAmount).div(_reserveAmount) : 0;
		}
		// calculates the borrowed amount and range in terms of the reserve token
		uint256 _borrowAmount = GC.fetchBorrowAmount(_self.borrowToken);
		uint256 _newBorrowAmount;
		uint256 _minBorrowAmount;
		uint256 _maxBorrowAmount;
		{
			uint256 _freeAmount = GC.getLiquidityAmount(_self.borrowToken);
			uint256 _totalAmount = _borrowAmount.add(_freeAmount);
			// applies the scaling ratio to account for the required room
			uint256 _newTotalAmount = _totalAmount.mul(_scalingRatio).div(1e18);
			_newBorrowAmount = _newTotalAmount.mul(_self.collateralizationRatio).div(1e18);
			uint256 _newMarginAmount = _newTotalAmount.mul(_self.collateralizationMargin).div(1e18);
			_minBorrowAmount = _newBorrowAmount.sub(G.min(_newMarginAmount, _newBorrowAmount));
			_maxBorrowAmount = G.min(_newBorrowAmount.add(_newMarginAmount), _newTotalAmount);
		}
		// if the borrow amount is below the lower bound,
		// borrows the diference and deposits in the growth token contract
		if (_borrowAmount < _minBorrowAmount) {
			uint256 _amount = _newBorrowAmount.sub(_borrowAmount);
			_amount = G.min(_amount, GC.getMarketAmount(_self.borrowToken));
			_success = GC.borrow(_self.borrowToken, _amount);
			if (!_success) return false;
			_success = _self._deposit(_amount);
			if (_success) return true;
			GC.repay(_self.borrowToken, _amount);
			return false;
		}
		// if the borrow amount is above the upper bound,
		// redeems the diference from the growth token contract and
		// repays the loan
		if (_borrowAmount > _maxBorrowAmount) {
			uint256 _amount = _borrowAmount.sub(_newBorrowAmount);
			uint256 _grossShares = _self._calcWithdrawalSharesFromCost(_amount);
			_grossShares = G.min(_grossShares, G.getBalance(_self.growthToken));
			if (_grossShares == 0) return true;
			_success = _self._withdraw(_grossShares);
			if (!_success) return false;
			uint256 _repayAmount = G.min(_borrowAmount, G.getBalance(_self.growthReserveToken));
			return GC.repay(_self.borrowToken, _repayAmount);
		}
		return true;
	}

	/**
	 * @dev Calculates how much of the growth reserve token can be redeemed
	 *      from a given amount of shares.
	 * @param _grossShares The number of shares to redeem.
	 * @return _cost The reserve token amount to be withdraw.
	 */
	function _calcWithdrawalCostFromShares(Self storage _self, uint256 _grossShares) internal view returns (uint256 _cost) {
		uint256 _totalReserve = GToken(_self.growthToken).totalReserve();
		uint256 _totalSupply = GToken(_self.growthToken).totalSupply();
		uint256 _withdrawalFee = GToken(_self.growthToken).withdrawalFee();
		(_cost,) = GToken(_self.growthToken).calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
		return _cost;
	}

	/**
	 * @dev Calculates how many shares must be redeemed in order to withdraw
	 *      so much of the growth reserve token.
	 * @param _cost The amount of the reserve token to be received on
	 *               withdrawal.
	 * @return _grossShares The number of shares one must redeem.
	 */
	function _calcWithdrawalSharesFromCost(Self storage _self, uint256 _cost) internal view returns (uint256 _grossShares) {
		uint256 _totalReserve = GToken(_self.growthToken).totalReserve();
		uint256 _totalSupply = GToken(_self.growthToken).totalSupply();
		uint256 _withdrawalFee = GToken(_self.growthToken).withdrawalFee();
		(_grossShares,) = GToken(_self.growthToken).calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
		return _grossShares;
	}

	/**
	 * @dev Deposits into the growth token contract.
	 * @param _cost The amount of thr growth reserve token to be deposited.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _deposit(Self storage _self, uint256 _cost) internal returns (bool _success)
	{
		G.approveFunds(_self.growthReserveToken, _self.growthToken, _cost);
		try GToken(_self.growthToken).deposit(_cost) {
			return true;
		} catch (bytes memory /* _data */) {
			G.approveFunds(_self.growthReserveToken, _self.growthToken, 0);
			return false;
		}
	}

	/**
	 * @dev Withdraws from the growth token contract.
	 * @param _grossShares The number of shares to be redeemed.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _withdraw(Self storage _self, uint256 _grossShares) internal returns (bool _success)
	{
		try GToken(_self.growthToken).withdraw(_grossShares) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	/**
	 * @dev Converts a given amount of the mining token to the underlying
	 *      token using the external exchange contract. Both amounts are
	 *      deducted and credited, respectively, from the current contract.
	 * @param _inputAmount The amount to be converted.
	 */
	function _convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		G.dynamicConvertFunds(_self.exchange, _self.miningToken, _self.underlyingToken, _inputAmount, 0);
	}

	/**
	 * @dev Converts a given amount of the growth reserve token to the
	 *      underlying token using the external exchange contract. Both
	 *      amounts are deducted and credited, respectively, from the
	 *      current contract.
	 * @param _inputAmount The amount to be converted.
	 */
	function _convertGrowthReserveToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		G.dynamicConvertFunds(_self.exchange, _self.growthReserveToken, _self.underlyingToken, _inputAmount, 0);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { GFormulae } from "./GFormulae.sol";

/**
 * @dev Pure implementation of deposit/minting and withdrawal/burning formulas
 *      for gTokens calculated based on the cToken underlying asset
 *      (e.g. DAI for cDAI). See GFormulae.sol and GCTokenBase.sol for further
 *      documentation.
 */
library GCFormulae
{
	using SafeMath for uint256;

	/**
	 * @dev Simple token to cToken formula from Compound
	 */
	function _calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) internal pure returns (uint256 _cost)
	{
		return _underlyingCost.mul(1e18).div(_exchangeRate);
	}

	/**
	 * @dev Simple cToken to token formula from Compound
	 */
	function _calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost)
	{
		return _cost.mul(_exchangeRate).div(1e18);
	}

	/**
	 * @dev Composition of the gToken deposit formula with the Compound
	 *      conversion formula to obtain the gcToken deposit formula in
	 *      terms of the cToken underlying asset.
	 */
	function _calcDepositSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) internal pure returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
		return GFormulae._calcDepositSharesFromCost(_cost, _totalReserve, _totalSupply, _depositFee);
	}

	/**
	 * @dev Composition of the gToken reserve deposit formula with the
	 *      Compound conversion formula to obtain the gcToken reverse
	 *      deposit formula in terms of the cToken underlying asset.
	 */
	function _calcDepositUnderlyingCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		uint256 _cost;
		(_cost, _feeShares) = GFormulae._calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
		return (_calcUnderlyingCostFromCost(_cost, _exchangeRate), _feeShares);
	}

	/**
	 * @dev Composition of the gToken reserve withdrawal formula with the
	 *      Compound conversion formula to obtain the gcToken reverse
	 *      withdrawal formula in terms of the cToken underlying asset.
	 */
	function _calcWithdrawalSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) internal pure returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
		return GFormulae._calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
	}

	/**
	 * @dev Composition of the gToken withdrawal formula with the Compound
	 *      conversion formula to obtain the gcToken withdrawal formula in
	 *      terms of the cToken underlying asset.
	 */
	function _calcWithdrawalUnderlyingCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		uint256 _cost;
		(_cost, _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
		return (_calcUnderlyingCostFromCost(_cost, _exchangeRate), _feeShares);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { G } from "./G.sol";
import { GC } from "./GC.sol";

/**
 * @dev This library implements data structure abstraction for the leveraged
 *      reserve management code in order to circuvent the EVM contract size limit.
 *      It is therefore a public library shared by all gcToken Type 1 contracts and
 *      needs to be published alongside them. See GCTokenType1.sol for further
 *      documentation.
 */
library GCLeveragedReserveManager
{
	using SafeMath for uint256;
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	uint256 constant MAXIMUM_COLLATERALIZATION_RATIO = 98e16; // 98% of 75% = 73.5%
	uint256 constant DEFAULT_COLLATERALIZATION_RATIO = 94e16; // 94% of 75% = 70.5%
	uint256 constant DEFAULT_COLLATERALIZATION_MARGIN = 2e16; // 2% of 75% = 1.5%

	struct Self {
		address reserveToken;
		address underlyingToken;

		address exchange;

		address miningToken;
		uint256 miningMinGulpAmount;
		uint256 miningMaxGulpAmount;

		uint256 collateralizationRatio;
		uint256 collateralizationMargin;
	}

	/**
	 * @dev Initializes the data structure. This method is exposed publicly.
	 * @param _reserveToken The ERC-20 token address of the reserve token (cToken).
	 * @param _miningToken The ERC-20 token address to be collected from
	 *                     liquidity mining (COMP).
	 */
	function init(Self storage _self, address _reserveToken, address _miningToken) public
	{
		address _underlyingToken = GC.getUnderlyingToken(_reserveToken);

		_self.reserveToken = _reserveToken;
		_self.underlyingToken = _underlyingToken;

		_self.exchange = address(0);

		_self.miningToken = _miningToken;
		_self.miningMinGulpAmount = 0;
		_self.miningMaxGulpAmount = 0;

		_self.collateralizationRatio = DEFAULT_COLLATERALIZATION_RATIO;
		_self.collateralizationMargin = DEFAULT_COLLATERALIZATION_MARGIN;

		GC.safeEnter(_reserveToken);
	}

	/**
	 * @dev Sets the contract address for asset conversion delegation.
	 *      This library converts the miningToken into the underlyingToken
	 *      and use the assets to back the reserveToken. See GExchange.sol
	 *      for further documentation. This method is exposed publicly.
	 * @param _exchange The address of the contract that implements the
	 *                  GExchange interface.
	 */
	function setExchange(Self storage _self, address _exchange) public
	{
		_self.exchange = _exchange;
	}

	/**
	 * @dev Sets the range for converting liquidity mining assets. This
	 *      method is exposed publicly.
	 * @param _miningMinGulpAmount The minimum amount, funds will only be
	 *                             converted once the minimum is accumulated.
	 * @param _miningMaxGulpAmount The maximum amount, funds beyond this
	 *                             limit will not be converted and are left
	 *                             for future rounds of conversion.
	 */
	function setMiningGulpRange(Self storage _self, uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public
	{
		require(_miningMinGulpAmount <= _miningMaxGulpAmount, "invalid range");
		_self.miningMinGulpAmount = _miningMinGulpAmount;
		_self.miningMaxGulpAmount = _miningMaxGulpAmount;
	}

	/**
	 * @dev Sets the collateralization ratio and margin. These values are
	 *      percentual and relative to the maximum collateralization ratio
	 *      provided by the underlying asset. This method is exposed publicly.
	 * @param _collateralizationRatio The target collateralization ratio,
	 *                                between lend and borrow, that the
	 *                                reserve will try to maintain.
	 * @param _collateralizationMargin The deviation from the target ratio
	 *                                 that should be accepted.
	 */
	function setCollateralizationRatio(Self storage _self, uint256 _collateralizationRatio, uint256 _collateralizationMargin) public
	{
		require(_collateralizationMargin <= _collateralizationRatio && _collateralizationRatio.add(_collateralizationMargin) <= MAXIMUM_COLLATERALIZATION_RATIO, "invalid ratio");
		_self.collateralizationRatio = _collateralizationRatio;
		_self.collateralizationMargin = _collateralizationMargin;
	}

	/**
	 * @dev Performs the reserve adjustment actions leaving a liquidity room,
	 *      if necessary. It will attempt to incorporate the liquidity mining
	 *      assets into the reserve and adjust the collateralization
	 *      targeting the configured ratio. This method is exposed publicly.
	 * @param _roomAmount The underlying token amount to be available after the
	 *                    operation. This is revelant for withdrawals, once the
	 *                    room amount is withdrawn the reserve should reflect
	 *                    the configured collateralization ratio.
	 * @return _success A boolean indicating whether or not both actions suceeded.
	 */
	function adjustReserve(Self storage _self, uint256 _roomAmount) public returns (bool _success)
	{
		bool success1 = _self._gulpMiningAssets();
		bool success2 = _self._adjustLeverage(_roomAmount);
		return success1 && success2;
	}

	/**
	 * @dev Calculates the collateralization ratio and range relative to the
	 *      maximum collateralization ratio provided by the underlying asset.
	 * @return _collateralizationRatio The target absolute collateralization ratio.
	 * @return _minCollateralizationRatio The minimum absolute collateralization ratio.
	 * @return _maxCollateralizationRatio The maximum absolute collateralization ratio.
	 */
	function _calcCollateralizationRatio(Self storage _self) internal view returns (uint256 _collateralizationRatio, uint256 _minCollateralizationRatio, uint256 _maxCollateralizationRatio)
	{
		uint256 _collateralRatio = GC.getCollateralRatio(_self.reserveToken);
		_collateralizationRatio = _collateralRatio.mul(_self.collateralizationRatio).div(1e18);
		_minCollateralizationRatio = _collateralRatio.mul(_self.collateralizationRatio.sub(_self.collateralizationMargin)).div(1e18);
		_maxCollateralizationRatio = _collateralRatio.mul(_self.collateralizationRatio.add(_self.collateralizationMargin)).div(1e18);
		return (_collateralizationRatio, _minCollateralizationRatio, _maxCollateralizationRatio);
	}

	/**
	 * @dev Incorporates the liquidity mining assets into the reserve. Assets
	 *      are converted to the underlying asset and then added to the reserve.
	 *      If the amount available is below the minimum, or if the exchange
	 *      contract is not set, nothing is done. Otherwise the operation is
	 *      performed, limited to the maximum amount. Note that this operation
	 *      will incorporate to the reserve all the underlying token balance
	 *      including funds sent to it or left over somehow.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _gulpMiningAssets(Self storage _self) internal returns (bool _success)
	{
		if (_self.exchange == address(0)) return true;
		if (_self.miningMaxGulpAmount == 0) return true;
		uint256 _miningAmount = G.getBalance(_self.miningToken);
		if (_miningAmount == 0) return true;
		if (_miningAmount < _self.miningMinGulpAmount) return true;
		_self._convertMiningToUnderlying(G.min(_miningAmount, _self.miningMaxGulpAmount));
		return GC.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	/**
	 * @dev Adjusts the reserve to match the configured collateralization
	 *      ratio. It calculates how much the collateralization must be
	 *      increased or decreased and either: 1) lend/borrow, or
	 *      2) repay/redeem, respectivelly. The funds required to perform
	 *      the operation are obtained via FlashLoan to avoid having to
	 *      maneuver around margin when moving in/out of leverage.
	 * @param _roomAmount The amount of underlying token to be liquid after
	 *                    the operation.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _adjustLeverage(Self storage _self, uint256 _roomAmount) internal returns (bool _success)
	{
		// the reserve is the diference between lend and borrow
		uint256 _lendAmount = GC.fetchLendAmount(_self.reserveToken);
		uint256 _borrowAmount = GC.fetchBorrowAmount(_self.reserveToken);
		uint256 _reserveAmount = _lendAmount.sub(_borrowAmount);
		// caps the room in case it is larger than the reserve
		_roomAmount = G.min(_roomAmount, _reserveAmount);
		// The new reserve must deduct the room requested
		uint256 _newReserveAmount = _reserveAmount.sub(_roomAmount);
		// caculates the assumed lend amount deducting the requested room
		uint256 _oldLendAmount = _lendAmount.sub(_roomAmount);
		// the new lend amount is the new reserve with leverage applied
		uint256 _newLendAmount;
		uint256 _minNewLendAmount;
		uint256 _maxNewLendAmount;
		{
			(uint256 _collateralizationRatio, uint256 _minCollateralizationRatio, uint256 _maxCollateralizationRatio) = _self._calcCollateralizationRatio();
			_newLendAmount = _newReserveAmount.mul(1e18).div(uint256(1e18).sub(_collateralizationRatio));
			_minNewLendAmount = _newReserveAmount.mul(1e18).div(uint256(1e18).sub(_minCollateralizationRatio));
			_maxNewLendAmount = _newReserveAmount.mul(1e18).div(uint256(1e18).sub(_maxCollateralizationRatio));
		}
		// adjust the reserve by:
		// 1- increasing collateralization by the difference
		// 2- decreasing collateralization by the difference
		// the adjustment is capped by the liquidity available on the market
		uint256 _liquidityAmount = G.getFlashLoanLiquidity(_self.underlyingToken);
		if (_minNewLendAmount > _oldLendAmount) {
			{
				uint256 _minAmount = _minNewLendAmount.sub(_oldLendAmount);
				require(_liquidityAmount >= _minAmount, "cannot maintain collateralization ratio");
			}
			uint256 _amount = _newLendAmount.sub(_oldLendAmount);
			return _self._dispatchFlashLoan(G.min(_amount, _liquidityAmount), 1);
		}
		if (_maxNewLendAmount < _oldLendAmount) {
			{
				uint256 _minAmount = _oldLendAmount.sub(_maxNewLendAmount);
				require(_liquidityAmount >= _minAmount, "cannot maintain collateralization ratio");
			}
			uint256 _amount = _oldLendAmount.sub(_newLendAmount);
			return _self._dispatchFlashLoan(G.min(_amount, _liquidityAmount), 2);
		}
		return true;
	}

	/**
	 * @dev This is the continuation of _adjustLeverage once funds are
	 *      borrowed via the FlashLoan callback.
	 * @param _amount The borrowed amount as requested.
	 * @param _fee The additional fee that needs to be paid for the FlashLoan.
	 * @param _which A flag indicating whether the funds were borrowed to
	 *               1) increase or 2) decrease the collateralization ratio.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _continueAdjustLeverage(Self storage _self, uint256 _amount, uint256 _fee, uint256 _which) internal returns (bool _success)
	{
		// note that the reserve adjustment is not 100% accurate as we
		// did not account for FlashLoan fees in the initial calculation
		if (_which == 1) {
			bool _success1 = GC.lend(_self.reserveToken, _amount.sub(_fee));
			bool _success2 = GC.borrow(_self.reserveToken, _amount);
			return _success1 && _success2;
		}
		if (_which == 2) {
			bool _success1 = GC.repay(_self.reserveToken, _amount);
			bool _success2 = GC.redeem(_self.reserveToken, _amount.add(_fee));
			return _success1 && _success2;
		}
		assert(false);
	}

	/**
	 * @dev Abstracts the details of dispatching the FlashLoan by encoding
	 *      the extra parameters.
	 * @param _amount The amount to be borrowed.
	 * @param _which A flag indicating whether the funds are borrowed to
	 *               1) increase or 2) decrease the collateralization ratio.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _dispatchFlashLoan(Self storage _self, uint256 _amount, uint256 _which) internal returns (bool _success)
	{
		return G.requestFlashLoan(_self.underlyingToken, _amount, abi.encode(_which));
	}

	/**
	 * @dev Abstracts the details of receiving a FlashLoan by decoding
	 *      the extra parameters.
	 * @param _token The asset being borrowed.
	 * @param _amount The borrowed amount.
	 * @param _fee The fees to be paid along with the borrowed amount.
	 * @param _params Additional encoded parameters to be decoded.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _receiveFlashLoan(Self storage _self, address _token, uint256 _amount, uint256 _fee, bytes memory _params) external returns (bool _success)
	{
		assert(_token == _self.underlyingToken);
		uint256 _which = abi.decode(_params, (uint256));
		return _self._continueAdjustLeverage(_amount, _fee, _which);
	}

	/**
	 * @dev Converts a given amount of the mining token to the underlying
	 *      token using the external exchange contract. Both amounts are
	 *      deducted and credited, respectively, from the current contract.
	 * @param _inputAmount The amount to be converted.
	 */
	function _convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		G.dynamicConvertFunds(_self.exchange, _self.miningToken, _self.underlyingToken, _inputAmount, 0);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GToken } from "./GToken.sol";

/**
 * @dev Minimal interface for gcTokens, implemented by the GCTokenBase contract.
 *      See GCTokenBase.sol for further documentation.
 */
interface GCToken is GToken
{
	// pure functions
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) external pure returns (uint256 _cost);
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost);
	function calcDepositSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) external pure returns (uint256 _netShares, uint256 _feeShares);
	function calcDepositUnderlyingCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost, uint256 _feeShares);
	function calcWithdrawalSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) external pure returns (uint256 _grossShares, uint256 _feeShares);
	function calcWithdrawalUnderlyingCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost, uint256 _feeShares);

	// view functions
	function underlyingToken() external view returns (address _underlyingToken);
	function exchangeRate() external view returns (uint256 _exchangeRate);
	function totalReserveUnderlying() external view returns (uint256 _totalReserveUnderlying);
	function lendingReserveUnderlying() external view returns (uint256 _lendingReserveUnderlying);
	function borrowingReserveUnderlying() external view returns (uint256 _borrowingReserveUnderlying);
	function collateralizationRatio() external view returns (uint256 _collateralizationRatio, uint256 _collateralizationMargin);

	// open functions
	function depositUnderlying(uint256 _underlyingCost) external;
	function withdrawUnderlying(uint256 _grossShares) external;

	// priviledged functions
	function setCollateralizationRatio(uint256 _collateralizationRatio, uint256 _collateralizationMargin) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GFormulae } from "./GFormulae.sol";
import { GTokenBase } from "./GTokenBase.sol";
import { GCToken } from "./GCToken.sol";
import { GCFormulae } from "./GCFormulae.sol";
import { GMining } from "./GMining.sol";
import { G } from "./G.sol";
import { GC } from "./GC.sol";

import { $ } from "./network/$.sol";

/**
 * @notice This abstract contract provides the basis implementation for all
 *         gcTokens, i.e. gTokens that use Compound cTokens as reserve, and
 *         implements the common functionality shared amongst them.
 *         In a nutshell, it extends the functinality of the GTokenBase contract
 *         to support operating directly using the cToken underlying asset.
 *         Therefore this contract provides functions that encapsulate minting
 *         and redeeming of cTokens internally, allowing users to interact with
 *         the contract providing funds directly in their underlying asset.
 */
abstract contract GCTokenBase is GTokenBase, GCToken, GMining
{
	address public immutable override miningToken;
	address public immutable override growthToken;
	address public immutable override underlyingToken;

	/**
	 * @dev Constructor for the gcToken contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. cDAI for gcDAI).
	 * @param _miningToken The ERC-20 token used for liquidity mining on
	 *                     compound (COMP).
	 * @param _growthToken The ERC-20 token address of the associated
	 *                     gToken, for gcTokens Type 2, or address(0),
	 *                     if this contract is a gcToken Type 1.
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken, address _miningToken, address _growthToken)
		GTokenBase(_name, _symbol, _decimals, _stakesToken, _reserveToken) public
	{
		miningToken = _miningToken;
		growthToken = _growthToken;
		address _underlyingToken = GC.getUnderlyingToken(_reserveToken);
		underlyingToken = _underlyingToken;
	}

	/**
	 * @notice Allows for the beforehand calculation of the cToken amount
	 *         given the amount of the underlying token and an exchange rate.
	 * @param _underlyingCost The cost in terms of the cToken underlying asset.
	 * @param _exchangeRate The given exchange rate as provided by exchangeRate().
	 * @return _cost The equivalent cost in terms of cToken
	 */
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) public pure override returns (uint256 _cost)
	{
		return GCFormulae._calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of the underlying token
	 *         amount given the cToken amount and an exchange rate.
	 * @param _cost The cost in terms of the cToken.
	 * @param _exchangeRate The given exchange rate as provided by exchangeRate().
	 * @return _underlyingCost The equivalent cost in terms of the cToken underlying asset.
	 */
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost)
	{
		return GCFormulae._calcUnderlyingCostFromCost(_cost, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         received/minted upon depositing the underlying asset to the
	 *         contract.
	 * @param _underlyingCost The amount of the underlying asset being deposited.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @param _exchangeRate The exchange rate as obtained by exchangeRate().
	 * @return _netShares The net amount of shares being received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		return GCFormulae._calcDepositSharesFromUnderlyingCost(_underlyingCost, _totalReserve, _totalSupply, _depositFee, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of the
	 *         underlying asset to be deposited in order to receive the desired
	 *         amount of shares.
	 * @param _netShares The amount of this gcToken shares to receive.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @param _exchangeRate The exchange rate as obtained by exchangeRate().
	 * @return _underlyingCost The cost, in the underlying asset, to be paid.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositUnderlyingCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		return GCFormulae._calcDepositUnderlyingCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         given/burned upon withdrawing the underlying asset from the
	 *         contract.
	 * @param _underlyingCost The amount of the underlying asset being withdrawn.
	 * @param _totalReserve The reserve balance as obtained by totalReserve()
	 * @param _totalSupply The shares supply as obtained by totalSupply()
	 * @param _withdrawalFee The current withdrawl fee as obtained by withdrawalFee()
	 * @param _exchangeRate The exchange rate as obtained by exchangeRate().
	 * @return _grossShares The total amount of shares being deducted,
	 *                      including fees.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		return GCFormulae._calcWithdrawalSharesFromUnderlyingCost(_underlyingCost, _totalReserve, _totalSupply, _withdrawalFee, _exchangeRate);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of the
	 *         underlying asset to be withdrawn given the desired amount of
	 *         shares.
	 * @param _grossShares The amount of this gcToken shares to provide.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _withdrawalFee The current withdrawal fee as obtained by withdrawalFee().
	 * @param _exchangeRate The exchange rate as obtained by exchangeRate().
	 * @return _underlyingCost The cost, in the underlying asset, to be received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalUnderlyingCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		return GCFormulae._calcWithdrawalUnderlyingCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee, _exchangeRate);
	}

	/**
	 * @notice Provides the Compound exchange rate since their last update.
	 * @return _exchangeRate The exchange rate between cToken and its
	 *                       underlying asset
	 */
	function exchangeRate() public view override returns (uint256 _exchangeRate)
	{
		return GC.getExchangeRate(reserveToken);
	}

	/**
	 * @notice Provides the total amount kept in the reserve in terms of the
	 *         underlying asset.
	 * @return _totalReserveUnderlying The underlying asset balance on reserve.
	 */
	function totalReserveUnderlying() public view virtual override returns (uint256 _totalReserveUnderlying)
	{
		return GCFormulae._calcUnderlyingCostFromCost(totalReserve(), exchangeRate());
	}

	/**
	 * @notice Provides the total amount of the underlying asset (or equivalent)
	 *         this contract is currently lending on Compound.
	 * @return _lendingReserveUnderlying The underlying asset lending
	 *                                   balance on Compound.
	 */
	function lendingReserveUnderlying() public view virtual override returns (uint256 _lendingReserveUnderlying)
	{
		return GC.getLendAmount(reserveToken);
	}

	/**
	 * @notice Provides the total amount of the underlying asset (or equivalent)
	 *         this contract is currently borrowing on Compound.
	 * @return _borrowingReserveUnderlying The underlying asset borrowing
	 *                                     balance on Compound.
	 */
	function borrowingReserveUnderlying() public view virtual override returns (uint256 _borrowingReserveUnderlying)
	{
		return GC.getBorrowAmount(reserveToken);
	}

	/**
	 * @notice Performs the minting of gcToken shares upon the deposit of the
	 *         cToken underlying asset. The funds will be pulled in by this
	 *         contract, therefore they must be previously approved. This
	 *         function builds upon the GTokenBase deposit function. See
	 *         GTokenBase.sol for further documentation.
	 * @param _underlyingCost The amount of the underlying asset being
	 *                        deposited in the operation.
	 */
	function depositUnderlying(uint256 _underlyingCost) public override nonReentrant
	{
		address _from = msg.sender;
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		uint256 _cost = GCFormulae._calcCostFromUnderlyingCost(_underlyingCost, exchangeRate());
		(uint256 _netShares, uint256 _feeShares) = GFormulae._calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "shares must be greater than 0");
		G.pullFunds(underlyingToken, _from, _underlyingCost);
		GC.safeLend(reserveToken, _underlyingCost);
		require(_prepareDeposit(_cost), "not available at the moment");
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
	}

	/**
	 * @notice Performs the burning of gcToken shares upon the withdrawal of
	 *         the underlying asset. This function builds upon the
	 *         GTokenBase withdrawal function. See GTokenBase.sol for
	 *         further documentation.
	 * @param _grossShares The gross amount of this gcToken shares being
	 *                     redeemed in the operation.
	 */
	function withdrawUnderlying(uint256 _grossShares) public override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = GCFormulae._calcUnderlyingCostFromCost(_cost, exchangeRate());
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		require(_prepareWithdrawal(_cost), "not available at the moment");
		_underlyingCost = G.min(_underlyingCost, GC.getLendAmount(reserveToken));
		GC.safeRedeem(reserveToken, _underlyingCost);
		G.pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
	}

	/**
	 * @dev The default behavior of this function is to send the funds to
	 *      address(0), but we override it and send the funds to the stkGRO
	 *      contract instead.
	 * @param _stakesAmount The amount of the stakes token being burned.
	 */
	function _burnStakes(uint256 _stakesAmount) internal override
	{
		G.pushFunds(stakesToken, $.stkGRO, _stakesAmount);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { GCFormulae } from "./GCFormulae.sol";
import { GCTokenBase } from "./GCTokenBase.sol";
import { GCLeveragedReserveManager } from "./GCLeveragedReserveManager.sol";
import { GFlashBorrower } from "./GFlashBorrower.sol";
import { G } from "./G.sol";
import { GC } from "./GC.sol";

/**
 * @notice This contract implements the functionality for the gcToken Type 1.
 *         As with all gcTokens, gcTokens Type 1 use a Compound cToken as
 *         reserve token. Furthermore, Type 1 tokens may apply leverage to the
 *         reserve by using the cToken balance to borrow its associated
 *         underlying asset which in turn is used to mint more cToken. This
 *         process is performed to the limit where the actual reserve balance
 *         ends up accounting for the difference between the total amount lent
 *         and the total amount borrowed. One may observe that there is
 *         always a net loss when considering just the yield accrued for
 *         lending minus the yield accrued for borrowing on Compound. However,
 *         if we consider COMP being credited for liquidity mining the net
 *         balance may become positive and that is when the leverage mechanism
 *         should be applied. The COMP is periodically converted to the
 *         underlying asset and naturally becomes part of the reserve.
 *         In order to easily and efficiently adjust the leverage, this contract
 *         performs flash loans. See GCTokenBase, GFlashBorrower and
 *         GCLeveragedReserveManager for further documentation.
 */
contract GCTokenType1 is GCTokenBase, GFlashBorrower
{
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	GCLeveragedReserveManager.Self lrm;

	/**
	 * @dev Constructor for the gcToken Type 1 contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. cDAI for gcDAI).
	 * @param _miningToken The ERC-20 token used for liquidity mining on
	 *                     compound (COMP).
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken, address _miningToken)
		GCTokenBase(_name, _symbol, _decimals, _stakesToken, _reserveToken, _miningToken, address(0)) public
	{
		lrm.init(_reserveToken, _miningToken);
	}

	/**
	 * @notice Overrides the default total reserve definition in order to
	 *         account only for the diference between assets being lent
	 *         and assets being borrowed.
	 * @return _totalReserve The amount of the reserve token corresponding
	 *                       to this contract's worth.
	 */
	function totalReserve() public view override returns (uint256 _totalReserve)
	{
		return GCFormulae._calcCostFromUnderlyingCost(totalReserveUnderlying(), exchangeRate());
	}

	/**
	 * @notice Overrides the default total underlying reserve definition in
	 *         order to account only for the diference between assets being
	 *         lent and assets being borrowed.
	 * @return _totalReserveUnderlying The amount of the underlying asset
	 *                                 corresponding to this contract's worth.
	 */
	function totalReserveUnderlying() public view override returns (uint256 _totalReserveUnderlying)
	{
		return lendingReserveUnderlying().sub(borrowingReserveUnderlying());
	}

	/**
	 * @notice Provides the contract address for the GExchange implementation
	 *         currently being used to convert the mining token (COMP) into
	 *         the underlying asset.
	 * @return _exchange A GExchange compatible contract address, or address(0)
	 *                   if it has not been set.
	 */
	function exchange() public view override returns (address _exchange)
	{
		return lrm.exchange;
	}

	/**
	 * @notice Provides the minimum and maximum amount of the mining token to
	 *         be processed on every operation. If the contract balance
	 *         is below the minimum it waits until more accumulates.
	 *         If the total amount is beyond the maximum it processes the
	 *         maximum and leaves the rest for future operations. The mining
	 *         token accumulated via liquidity mining is converted to the
	 *         underlying asset and used to mint the associated cToken.
	 *         This range is used to avoid wasting gas converting small
	 *         amounts as well as mitigating slipage converting large amounts.
	 * @return _miningMinGulpAmount The minimum amount of the mining token
	 *                              to be processed per deposit/withdrawal.
	 * @return _miningMaxGulpAmount The maximum amount of the mining token
	 *                              to be processed per deposit/withdrawal.
	 */
	function miningGulpRange() public view override returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount)
	{
		return (lrm.miningMinGulpAmount, lrm.miningMaxGulpAmount);
	}

	/**
	 * @notice Provides the minimum and maximum amount of the gcToken Type 1 to
	 *         be processed on every operation. This method applies only to
	 *         gcTokens Type 2 and is not relevant for gcTokens Type 1.
	 * @return _growthMinGulpAmount The minimum amount of the gcToken Type 1
	 *                              to be processed per deposit/withdrawal
	 *                              (always 0).
	 * @return _growthMaxGulpAmount The maximum amount of the gcToken Type 1
	 *                              to be processed per deposit/withdrawal
	 *                              (always 0).
	 */
	function growthGulpRange() public view override returns (uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount)
	{
		return (0, 0);
	}

	/**
	 * @notice Provides the target collateralization ratio and margin to be
	 *         maintained by this contract. The amount is relative to the
	 *         maximum collateralization available for the associated cToken
	 *         on Compound. gcToken Type 1 uses leveraged collateralization
	 *         where the cToken is used to borrow its underlying token which
	 *         in turn is used to mint new cToken and repeat. This is
	 *         performed to the maximal level where the actual reserve
	 *         ends up corresponding to the difference between the amount
	 *         lent and the amount borrowed.
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                (defaults to 94%)
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                margin (defaults to 2%)
	 */
	function collateralizationRatio() public view override returns (uint256 _collateralizationRatio, uint256 _collateralizationMargin)
	{
		return (lrm.collateralizationRatio, lrm.collateralizationMargin);
	}

	/**
	 * @notice Sets the contract address for the GExchange implementation
	 *         to be used in converting the mining token (COMP) into
	 *         the underlying asset. This is a priviledged function
	 *         restricted to the contract owner.
	 * @param _exchange A GExchange compatible contract address.
	 */
	function setExchange(address _exchange) public override onlyOwner nonReentrant
	{
		lrm.setExchange(_exchange);
	}

	/**
	 * @notice Sets the minimum and maximum amount of the mining token to
	 *         be processed on every operation. See miningGulpRange().
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _miningMinGulpAmount The minimum amount of the mining token
	 *                             to be processed per deposit/withdrawal.
	 * @param _miningMaxGulpAmount The maximum amount of the mining token
	 *                             to be processed per deposit/withdrawal.
	 */
	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public override onlyOwner nonReentrant
	{
		lrm.setMiningGulpRange(_miningMinGulpAmount, _miningMaxGulpAmount);
	}

	/**
	 * @notice Sets the minimum and maximum amount of the gcToken Type 1 to
	 *         be processed on every operation. This method applies only to
	 *         gcTokens Type 2 and is not relevant for gcTokens Type 1.
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _growthMinGulpAmount The minimum amount of the gcToken Type 1
	 *                             to be processed per deposit/withdrawal
	 *                             (ignored).
	 * @param _growthMaxGulpAmount The maximum amount of the gcToken Type 1
	 *                             to be processed per deposit/withdrawal
	 *                             (ignored).
	 */
	function setGrowthGulpRange(uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount) public override /*onlyOwner nonReentrant*/
	{
		_growthMinGulpAmount; _growthMaxGulpAmount; // silences warnings
	}

	/**
	 * @notice Sets the target collateralization ratio and margin to be
	 *         maintained by this contract. See collateralizationRatio().
	 *         Setting both parameters to 0 turns off collateralization and
	 *         leveraging. This is a priviledged function restricted to the
	 *         contract owner.
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                (defaults to 94%)
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                margin (defaults to 2%)
	 */
	function setCollateralizationRatio(uint256 _collateralizationRatio, uint256 _collateralizationMargin) public override onlyOwner nonReentrant
	{
		lrm.setCollateralizationRatio(_collateralizationRatio, _collateralizationMargin);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      after a deposit comes along. It basically adjusts the
	 *      collateralization/leverage to reflect the new increased reserve
	 *      balance. This method uses the GCLeveragedReserveManager to
	 *      adjust the reserve and this is done via flash loans.
	 *      See GCLeveragedReserveManager.sol.
	 * @param _cost The amount of reserve being deposited (ignored).
	 * @return _success A boolean indicating whether or not the operation
	 *                  succeeded. This operation should not fail unless
	 *                  any of the underlying components (Compound, Aave,
	 *                  Dydx) also fails.
	 */
	function _prepareDeposit(uint256 _cost) internal override mayFlashBorrow returns (bool _success)
	{
		_cost; // silences warnings
		return lrm.adjustReserve(0);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      before a withdrawal comes along. It basically calculates the
	 *      the amount that will be left in the reserve, in terms of cToken
	 *      cost, and adjusts the collateralization/leverage accordingly. This
	 *      method uses the GCLeveragedReserveManager to adjust the reserve
	 *      and this is done via flash loans. See GCLeveragedReserveManager.sol.
	 * @param _cost The amount of reserve being withdrawn and that needs to
	 *              be immediately liquid.
	 * @return _success A boolean indicating whether or not the operation succeeded.
	 *                  The operation may fail if it is not possible to recover
	 *                  the required liquidity (e.g. low liquidity in the markets).
	 */
	function _prepareWithdrawal(uint256 _cost) internal override mayFlashBorrow returns (bool _success)
	{
		return lrm.adjustReserve(GCFormulae._calcUnderlyingCostFromCost(_cost, GC.fetchExchangeRate(reserveToken)));
	}

	/**
	 * @dev This method dispatches the flash loan callback back to the
	 *      GCLeveragedReserveManager library. See GCLeveragedReserveManager.sol
	 *      and GFlashBorrower.sol.
	 */
	function _processFlashLoan(address _token, uint256 _amount, uint256 _fee, bytes memory _params) internal override returns (bool _success)
	{
		return lrm._receiveFlashLoan(_token, _amount, _fee, _params);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GCFormulae } from "./GCFormulae.sol";
import { GCTokenBase } from "./GCTokenBase.sol";
import { GCDelegatedReserveManager } from "./GCDelegatedReserveManager.sol";
import { G } from "./G.sol";
import { GC } from "./GC.sol";

/**
 * @notice This contract implements the functionality for the gcToken Type 2.
 *         As with all gcTokens, gcTokens Type 2 use a Compound cToken as
 *         reserve token. Furthermore, Type 2 tokens will use that cToken
 *         balance to borrow funds that are then deposited into another gToken.
 *         Periodically the gcToken Type 2 will collect profits from liquidity
 *         mining COMP, as well as profits from investing borrowed assets in
 *         the gToken. These profits are converted into the cToken underlying 
 *         asset and incorporated to the reserve. See GCTokenBase and
 *         GCDelegatedReserveManager for further documentation.
 */
contract GCTokenType2 is GCTokenBase
{
	using GCDelegatedReserveManager for GCDelegatedReserveManager.Self;

	GCDelegatedReserveManager.Self drm;

	/**
	 * @dev Constructor for the gcToken Type 2 contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. cDAI for gcDAI).
	 * @param _miningToken The ERC-20 token used for liquidity mining on
	 *                     compound (COMP).
	 * @param _borrowToken The cToken used for borrowing funds on compound (cDAI).
	 * @param _growthToken The gToken used for reinvesting borrowed funds (gDAI).
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken, address _miningToken, address _borrowToken, address _growthToken)
		GCTokenBase(_name, _symbol, _decimals, _stakesToken, _reserveToken, _miningToken, _growthToken) public
	{
		drm.init(_reserveToken, _miningToken, _borrowToken, _growthToken);
	}

	/**
	 * @notice Provides the total amount of the underlying asset (or equivalent)
	 *         this contract is currently borrowing on Compound.
	 * @return _borrowingReserveUnderlying The underlying asset borrowing
	 *                                     balance on Compound.
	 */
	function borrowingReserveUnderlying() public view override returns (uint256 _borrowingReserveUnderlying)
	{
		uint256 _lendAmount = GC.getLendAmount(reserveToken);
		uint256 _availableAmount = _lendAmount.mul(GC.getCollateralRatio(reserveToken)).div(1e18);
		uint256 _borrowAmount = GC.getBorrowAmount(drm.borrowToken);
		uint256 _freeAmount = GC.getLiquidityAmount(drm.borrowToken);
		uint256 _totalAmount = _borrowAmount.add(_freeAmount);
		return _totalAmount > 0 ? _availableAmount.mul(_borrowAmount).div(_totalAmount) : 0;
	}

	/**
	 * @notice Provides the contract address for the GExchange implementation
	 *         currently being used to convert the mining token (COMP), and
	 *         the gToken reserve token (DAI), into the underlying asset.
	 * @return _exchange A GExchange compatible contract address, or address(0)
	 *                   if it has not been set.
	 */
	function exchange() public view override returns (address _exchange)
	{
		return drm.exchange;
	}

	/**
	 * @notice Provides the minimum and maximum amount of the mining token to
	 *         be processed on every operation. If the contract balance
	 *         is below the minimum it waits until more accumulates.
	 *         If the total amount is beyond the maximum it processes the
	 *         maximum and leaves the rest for future operations. The mining
	 *         token accumulated via liquidity mining is converted to the
	 *         underlying asset and used to mint the associated cToken.
	 *         This range is used to avoid wasting gas converting small
	 *         amounts as well as mitigating slipage converting large amounts.
	 * @return _miningMinGulpAmount The minimum amount of the mining token
	 *                              to be processed per deposit/withdrawal.
	 * @return _miningMaxGulpAmount The maximum amount of the mining token
	 *                              to be processed per deposit/withdrawal.
	 */
	function miningGulpRange() public view override returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount)
	{
		return (drm.miningMinGulpAmount, drm.miningMaxGulpAmount);
	}

	/**
	 * @notice Provides the minimum and maximum amount of the gToken reserve
	 *         profit to be processed on every operation. If the profit balance
	 *         is below the minimum it waits until more accumulates.
	 *         If the total profit is beyond the maximum it processes the
	 *         maximum and leaves the rest for future operations. The profit
	 *         accumulated via gToken reinvestment is converted to the
	 *         underlying asset and used to mint the associated cToken.
	 *         This range is used to avoid wasting gas converting small
	 *         amounts as well as mitigating slipage converting large amounts.
	 * @return _growthMinGulpAmount The minimum profit of the gToken reserve
	 *                              to be processed per deposit/withdrawal.
	 * @return _growthMaxGulpAmount The maximum profit of the gToken reserve
	 *                              to be processed per deposit/withdrawal.
	 */
	function growthGulpRange() public view override returns (uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount)
	{
		return (drm.growthMinGulpAmount, drm.growthMaxGulpAmount);
	}

	/**
	 * @notice Provides the target collateralization ratio and margin to be
	 *         maintained by this contract. The amount is relative to the
	 *         maximum collateralization available for the associated cToken
	 *         on Compound. gcToken Type 2 uses the reserve token as collateral
	 *         to borrow funds and revinvest into the gToken.
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                (defaults to 66%)
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                margin (defaults to 8%)
	 */
	function collateralizationRatio() public view override returns (uint256 _collateralizationRatio, uint256 _collateralizationMargin)
	{
		return (drm.collateralizationRatio, drm.collateralizationMargin);
	}

	/**
	 * @notice Sets the contract address for the GExchange implementation
	 *         to be used in converting the mining token (COMP), and
	 *         the gToken reserve token (DAI), into the underlying asset.
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _exchange A GExchange compatible contract address.
	 */
	function setExchange(address _exchange) public override onlyOwner nonReentrant
	{
		drm.setExchange(_exchange);
	}

	/**
	 * @notice Sets the minimum and maximum amount of the mining token to
	 *         be processed on every operation. See miningGulpRange().
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _miningMinGulpAmount The minimum amount of the mining token
	 *                             to be processed per deposit/withdrawal.
	 * @param _miningMaxGulpAmount The maximum amount of the mining token
	 *                             to be processed per deposit/withdrawal.
	 */
	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public override onlyOwner nonReentrant
	{
		drm.setMiningGulpRange(_miningMinGulpAmount, _miningMaxGulpAmount);
	}

	/**
	 * @notice Sets the minimum and maximum amount of the gToken reserve profit
	 *         to be processed on every operation. See growthGulpRange().
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _growthMinGulpAmount The minimum profit of the gToken reserve
	 *                             to be processed per deposit/withdrawal.
	 * @param _growthMaxGulpAmount The maximum profit of the gToken reserve
	 *                             to be processed per deposit/withdrawal.
	 */
	function setGrowthGulpRange(uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount) public override onlyOwner nonReentrant
	{
		drm.setGrowthGulpRange(_growthMinGulpAmount, _growthMaxGulpAmount);
	}

	/**
	 * @notice Sets the target collateralization ratio and margin to be
	 *         maintained by this contract. See collateralizationRatio().
	 *         Setting both parameters to 0 turns off collateralization.
	 *         This is a priviledged function restricted to the contract owner.
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                (defaults to 66%)
	 * @param _collateralizationRatio The percent value relative to the
	 *                                maximum allowed that this contract
	 *                                will target for collateralization
	 *                                margin (defaults to 8%)
	 */
	function setCollateralizationRatio(uint256 _collateralizationRatio, uint256 _collateralizationMargin) public override onlyOwner nonReentrant
	{
		drm.setCollateralizationRatio(_collateralizationRatio, _collateralizationMargin);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      after a deposit comes along. It basically adjusts the
	 *      collateralization to reflect the new increased reserve
	 *      balance. This method uses the GCDelegatedReserveManager to
	 *      adjust the reserve. See GCDelegatedReserveManager.sol.
	 * @param _cost The amount of reserve being deposited (ignored).
	 * @return _success A boolean indicating whether or not the operation
	 *                  succeeded.
	 */
	function _prepareDeposit(uint256 _cost) internal override returns (bool _success)
	{
		_cost; // silences warnings
		return drm.adjustReserve(0);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      before a withdrawal comes along. It basically calculates the
	 *      the amount that will be left in the reserve, in terms of cToken
	 *      cost, and adjusts the collateralization accordingly. This
	 *      method uses the GCDelegatedReserveManager to adjust the reserve.
	 *      See GCDelegatedReserveManager.sol.
	 * @param _cost The amount of reserve being withdrawn and that needs to
	 *              be immediately liquid.
	 * @return _success A boolean indicating whether or not the operation succeeded.
	 *                  The operation may fail if it is not possible to recover
	 *                  the required liquidity (e.g. low liquidity in the markets).
	 */
	function _prepareWithdrawal(uint256 _cost) internal override returns (bool _success)
	{
		return drm.adjustReserve(GCFormulae._calcUnderlyingCostFromCost(_cost, GC.fetchExchangeRate(reserveToken)));
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @dev Custom and uniform interface to a decentralized exchange. It is used
 *      to estimate and convert funds whenever necessary. This furnishes
 *      client contracts with the flexibility to replace conversion strategy
 *      and routing, dynamically, by delegating these operations to different
 *      external contracts that share this common interface. See
 *      GUniswapV2Exchange.sol for further documentation.
 */
interface GExchange
{
	// view functions
	function calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) external view returns (uint256 _outputAmount);
	function calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) external view returns (uint256 _inputAmount);

	// open functions
	function convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) external returns (uint256 _outputAmount);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { G } from "./G.sol";

import { FlashLoanReceiver } from "./interop/Aave.sol";
import { ICallee, Account } from "./interop/Dydx.sol";

import { FlashLoans } from "./modules/FlashLoans.sol";

import { $ } from "./network/$.sol";

/**
 * @dev This abstract contract provides an uniform interface for receiving
 *      flash loans. It encapsulates the required functionality provided by
 *      both Aave and Dydx. It performs the basic validation to ensure that
 *      only Aave/Dydx contracts can dispatch the operation and only the
 *      current contract (that inherits from it) can initiate it.
 */
abstract contract GFlashBorrower is FlashLoanReceiver, ICallee
{
	using SafeMath for uint256;

	uint256 private allowOperationLevel = 0;

	/**
	 * @dev Handy definition to ensure that flash loans are only initiated
	 *      from within the current contract.
	 */
	modifier mayFlashBorrow()
	{
		allowOperationLevel++;
		_;
		allowOperationLevel--;
	}

	/**
	 * @dev Handles Aave callback. Delegates the processing of the funds
	 *      to the virtual function _processFlashLoan and later takes care
	 *      of paying it back.
	 * @param _token The ERC-20 contract address.
	 * @param _amount The amount being borrowed.
	 * @param _fee The fee, in addition to the amount borrowed, to be repaid.
	 * @param _params Additional user parameters provided when the flash
	 *                loan was requested.
	 */
	function executeOperation(address _token, uint256 _amount, uint256 _fee, bytes calldata _params) external override
	{
		assert(allowOperationLevel > 0);
		address _from = msg.sender;
		address _pool = $.Aave_AAVE_LENDING_POOL;
		assert(_from == _pool);
		require(_processFlashLoan(_token, _amount, _fee, _params)/*, "failure processing flash loan"*/);
		G.paybackFlashLoan(FlashLoans.Provider.Aave, _token, _amount.add(_fee));
	}

	/**
	 * @dev Handles Dydx callback. Delegates the processing of the funds
	 *      to the virtual function _processFlashLoan and later takes care
	 *      of paying it back.
	 * @param _sender The contract address of the initiator of the flash
	 *                loan, expected to be the current contract.
	 * @param _account Dydx account info provided in the callback.
	 * @param _data Aditional external data provided to the Dydx callback,
	 *              this is used by the Dydx module to pass the ERC-20 token
	 *              address, the amount and fee, as well as user parameters.
	 */
	function callFunction(address _sender, Account.Info memory _account, bytes memory _data) external override
	{
		assert(allowOperationLevel > 0);
		address _from = msg.sender;
		address _solo = $.Dydx_SOLO_MARGIN;
		assert(_from == _solo);
		assert(_sender == address(this));
		assert(_account.owner == address(this));
		(address _token, uint256 _amount, uint256 _fee, bytes memory _params) = abi.decode(_data, (address,uint256,uint256,bytes));
		require(_processFlashLoan(_token, _amount, _fee, _params)/*, "failure processing flash loan"*/);
		G.paybackFlashLoan(FlashLoans.Provider.Dydx, _token, _amount.add(_fee));
	}

	/**
	 * @dev Internal function that abstracts the algorithm to be performed
	 *      with borrowed funds. It receives the funds, deposited in the
	 *      current contract, and must ensure they are available as balance
	 *      of the current contract, including fees, before it returns.
	 * @param _token The ERC-20 contract address.
	 * @param _amount The amount being borrowed.
	 * @param _fee The fee, in addition to the amount borrowed, to be repaid.
	 * @param _params Additional user parameters provided when the flash
	 *                loan was requested.
	 * @return _success A boolean indicating success.
	 */
	function _processFlashLoan(address _token, uint256 _amount, uint256 _fee, bytes memory _params) internal virtual returns (bool _success);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Pure implementation of deposit/minting and withdrawal/burning formulas
 *      for gTokens.
 *      All operations assume that, if total supply is 0, then the total
 *      reserve is also 0, and vice-versa.
 *      Fees are calculated percentually based on the gross amount.
 *      See GTokenBase.sol for further documentation.
 */
library GFormulae
{
	using SafeMath for uint256;

	/* deposit(cost):
	 *   price = reserve / supply
	 *   gross = cost / price
	 *   net = gross * 0.99	# fee is assumed to be 1% for simplicity
	 *   fee = gross - net
	 *   return net, fee
	 */
	function _calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) internal pure returns (uint256 _netShares, uint256 _feeShares)
	{
		require(_totalReserve > 0,"totalReserve must be upper to 0");
		uint256 _grossShares = _totalSupply == _totalReserve ? _cost : _cost.mul(_totalSupply).div(_totalReserve);
		_netShares = _grossShares.mul(uint256(1e18).sub(_depositFee)).div(1e18);
		_feeShares = _grossShares.sub(_netShares);
		return (_netShares, _feeShares);
	}

	/* deposit_reverse(net):
	 *   price = reserve / supply
	 *   gross = net / 0.99	# fee is assumed to be 1% for simplicity
	 *   cost = gross * price
	 *   fee = gross - net
	 *   return cost, fee
	 */
	function _calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) internal pure returns (uint256 _cost, uint256 _feeShares)
	{
		require(_totalReserve > 0,"totalReserve must be upper to 0");
		uint256 _grossShares = _netShares.mul(1e18).div(uint256(1e18).sub(_depositFee));
		_cost = _totalReserve == _totalSupply ? _grossShares : _grossShares.mul(_totalReserve).div(_totalSupply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	/* withdrawal_reverse(cost):
	 *   price = reserve / supply
	 *   net = cost / price
	 *   gross = net / 0.99	# fee is assumed to be 1% for simplicity
	 *   fee = gross - net
	 *   return gross, fee
	 */
	function _calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) internal pure returns (uint256 _grossShares, uint256 _feeShares)
	{
		require(_totalReserve > 0,"totalReserve must be upper to 0");
		uint256 _netShares = _cost == _totalReserve ? _totalSupply : _cost.mul(_totalSupply).div(_totalReserve);
		_grossShares = _netShares.mul(1e18).div(uint256(1e18).sub(_withdrawalFee));
		_feeShares = _grossShares.sub(_netShares);
		return (_grossShares, _feeShares);
	}

	/* withdrawal(gross):
	 *   price = reserve / supply
	 *   net = gross * 0.99	# fee is assumed to be 1% for simplicity
	 *   cost = net * price
	 *   fee = gross - net
	 *   return cost, fee
	 */
	function _calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) internal pure returns (uint256 _cost, uint256 _feeShares)
	{
		require(_totalReserve > 0,"totalReserve must be upper to 0");
		uint256 _netShares = _grossShares.mul(uint256(1e18).sub(_withdrawalFee)).div(1e18);
		_cost = _netShares == _totalSupply ? _totalReserve : _netShares.mul(_totalReserve).div(_totalSupply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { G } from "./G.sol";

/**
 * @dev This library implements data structure abstraction for the liquidity
 *      pool management code in order to circuvent the EVM contract size limit.
 *      It is therefore a public library shared by all gToken contracts and
 *      needs to be published alongside them. See GTokenBase.sol for further
 *      documentation.
 */
library GLiquidityPoolManager
{
	using GLiquidityPoolManager for GLiquidityPoolManager.Self;

	uint256 constant MAXIMUM_BURNING_RATE = 2e16; // 2%
	uint256 constant DEFAULT_BURNING_RATE = 5e15; // 0.5%
	uint256 constant BURNING_INTERVAL = 7 days;
	uint256 constant MIGRATION_INTERVAL = 7 days;

	enum State { Created, Allocated, Migrating, Migrated }

	struct Self {
		address stakesToken;
		address sharesToken;

		State state;
		address liquidityPool;

		uint256 burningRate;
		uint256 lastBurningTime;

		address migrationRecipient;
		uint256 migrationUnlockTime;
	}

	/**
	 * @dev Initializes the data structure. This method is exposed publicly.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _sharesToken The ERC-20 token address to be used as shares
	 *                     token (gToken).
	 */
	function init(Self storage _self, address _stakesToken, address _sharesToken) public
	{
		_self.stakesToken = _stakesToken;
		_self.sharesToken = _sharesToken;

		_self.state = State.Created;
		_self.liquidityPool = address(0);

		_self.burningRate = DEFAULT_BURNING_RATE;
		_self.lastBurningTime = 0;

		_self.migrationRecipient = address(0);
		_self.migrationUnlockTime = uint256(-1);
	}

	/**
	 * @dev Verifies whether or not a liquidity pool is migrating or
	 *      has migrated. This method is exposed publicly.
	 * @return _hasMigrated A boolean indicating whether or not the pool
	 *                      migration has started.
	 */
	function hasMigrated(Self storage _self) public view returns (bool _hasMigrated)
	{
		return _self.state == State.Migrating || _self.state == State.Migrated;
	}

	/**
	 * @dev Moves the current balances (if any) of stakes and shares tokens
	 *      to the liquidity pool. This method is exposed publicly.
	 */
	function gulpPoolAssets(Self storage _self) public
	{
		if (!_self._hasPool()) return;
		G.joinPool(_self.liquidityPool, _self.stakesToken, G.getBalance(_self.stakesToken));
		G.joinPool(_self.liquidityPool, _self.sharesToken, G.getBalance(_self.sharesToken));
	}

	/**
	 * @dev Sets the liquidity pool burning rate. This method is exposed
	 *      publicly.
	 * @param _burningRate The percent value of the liquidity pool to be
	 *                     burned at each 7-day period.
	 */
	function setBurningRate(Self storage _self, uint256 _burningRate) public
	{
		require(_burningRate <= MAXIMUM_BURNING_RATE, "invalid rate");
		_self.burningRate = _burningRate;
	}

	/**
	 * @dev Burns a portion of the liquidity pool according to the defined
	 *      burning rate. It must happen at most once every 7-days. This
	 *      method does not actually burn the funds, but it will redeem
	 *      the amounts from the pool to the caller contract, which is then
	 *      assumed to perform the burn. This method is exposed publicly.
	 * @return _stakesAmount The amount of stakes (GRO) redeemed from the pool.
	 * @return _sharesAmount The amount of shares (gToken) redeemed from the pool.
	 */
	function burnPoolPortion(Self storage _self) public returns (uint256 _stakesAmount, uint256 _sharesAmount)
	{
		require(_self._hasPool(), "pool not available");
		require(now >= _self.lastBurningTime + BURNING_INTERVAL, "must wait lock interval");
		_self.lastBurningTime = now;
		return G.exitPool(_self.liquidityPool, _self.burningRate);
	}

	/**
	 * @dev Creates a fresh new liquidity pool and deposits the initial
	 *      amounts of the stakes token and the shares token. The pool
	 *      if configure 50%/50% with a 10% swap fee. This method is exposed
	 *      publicly.
	 * @param _stakesAmount The amount of stakes token initially deposited
	 *                      into the pool.
	 * @param _sharesAmount The amount of shares token initially deposited
	 *                      into the pool.
	 */
	function allocatePool(Self storage _self, uint256 _stakesAmount, uint256 _sharesAmount) public
	{
		require(_self.state == State.Created, "pool cannot be allocated");
		_self.state = State.Allocated;
		_self.liquidityPool = G.createPool(_self.stakesToken, _stakesAmount, _self.sharesToken, _sharesAmount);
	}

	/**
	 * @dev Initiates the liquidity pool migration by setting a funds
	 *      recipent and starting the clock towards the 7-day grace period.
	 *      This method is exposed publicly.
	 * @param _migrationRecipient The recipient address to where funds will
	 *                            be transfered.
	 */
	function initiatePoolMigration(Self storage _self, address _migrationRecipient) public
	{
		require(_self.state == State.Allocated || _self.state == State.Migrated, "migration unavailable");
		_self.state = State.Migrating;
		_self.migrationRecipient = _migrationRecipient;
		_self.migrationUnlockTime = now + MIGRATION_INTERVAL;
	}

	/**
	 * @dev Cancels the liquidity pool migration by reseting the procedure
	 *      to its original state. This method is exposed publicly.
	 * @return _migrationRecipient The address of the former recipient.
	 */
	function cancelPoolMigration(Self storage _self) public returns (address _migrationRecipient)
	{
		require(_self.state == State.Migrating, "migration not initiated");
		_migrationRecipient = _self.migrationRecipient;
		_self.state = State.Allocated;
		_self.migrationRecipient = address(0);
		_self.migrationUnlockTime = uint256(-1);
		return _migrationRecipient;
	}

	/**
	 * @dev Completes the liquidity pool migration by redeeming all funds
	 *      from the pool. This method does not actually transfer the
	 *      redemeed funds to the recipient, it assumes the caller contract
	 *      will perform that. This method is exposed publicly.
	 * @return _migrationRecipient The address of the recipient.
	 * @return _stakesAmount The amount of stakes (GRO) redeemed from the pool.
	 * @return _sharesAmount The amount of shares (gToken) redeemed from the pool.
	 */
	function completePoolMigration(Self storage _self) public returns (address _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount)
	{
		require(_self.state == State.Migrating, "migration not initiated");
		require(now >= _self.migrationUnlockTime, "must wait lock interval");
		_migrationRecipient = _self.migrationRecipient;
		_self.state = State.Migrated;
		_self.migrationRecipient = address(0);
		_self.migrationUnlockTime = uint256(-1);
		(_stakesAmount, _sharesAmount) = G.exitPool(_self.liquidityPool, 1e18);
		return (_migrationRecipient, _stakesAmount, _sharesAmount);
	}

	/**
	 * @dev Verifies whether or not a liquidity pool has been allocated.
	 * @return _poolAvailable A boolean indicating whether or not the pool
	 *                        is available.
	 */
	function _hasPool(Self storage _self) internal view returns (bool _poolAvailable)
	{
		return _self.state != State.Created;
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @dev An interface to extend gTokens with liquidity mining capabilities.
 *      See GCTokenBase.sol and GATokenBase.sol for further documentation.
 */
interface GMining
{
	// view functions
	function miningToken() external view returns (address _miningToken);
	function growthToken() external view returns (address _growthToken);
	function exchange() external view returns (address _exchange);
	function miningGulpRange() external view returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount);
	function growthGulpRange() external view returns (uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount);

	// priviledged functions
	function setExchange(address _exchange) external;
	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) external;
	function setGrowthGulpRange(uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev An interface to extend gTokens with locked liquidity pools.
 *      See GTokenBase.sol for further documentation.
 */
interface GPooler
{
	// view functions
	function stakesToken() external view returns (address _stakesToken);
	function liquidityPool() external view returns (address _liquidityPool);
	function liquidityPoolBurningRate() external view returns (uint256 _burningRate);
	function liquidityPoolLastBurningTime() external view returns (uint256 _lastBurningTime);
	function liquidityPoolMigrationRecipient() external view returns (address _migrationRecipient);
	function liquidityPoolMigrationUnlockTime() external view returns (uint256 _migrationUnlockTime);

	// priviledged functions
	function allocateLiquidityPool(uint256 _stakesAmount, uint256 _sharesAmount) external;
	function setLiquidityPoolBurningRate(uint256 _burningRate) external;
	function burnLiquidityPoolPortion() external;
	function initiateLiquidityPoolMigration(address _migrationRecipient) external;
	function cancelLiquidityPoolMigration() external;
	function completeLiquidityPoolMigration() external;

	// emitted events
	event BurnLiquidityPoolPortion(uint256 _stakesAmount, uint256 _sharesAmount);
	event InitiateLiquidityPoolMigration(address indexed _migrationRecipient);
	event CancelLiquidityPoolMigration(address indexed _migrationRecipient);
	event CompleteLiquidityPoolMigration(address indexed _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @dev An interface with the extended functionality of portfolio management
 *      gTokens. See GTokenType0.sol for further documentation.
 */
interface GPortfolio
{
	// view functions
	function tokenCount() external view returns (uint256 _count);
	function tokenAt(uint256 _index) external view returns (address _token);
	function tokenPercent(address _token) external view returns (uint256 _percent);
	function getRebalanceMargins() external view returns (uint256 _liquidRebalanceMargin, uint256 _portfolioRebalanceMargin);

	// priviledged functions
	function insertToken(address _token) external;
	function removeToken(address _token) external;
	function anounceTokenPercentTransfer(address _sourceToken, address _targetToken, uint256 _percent) external;
	function transferTokenPercent(address _sourceToken, address _targetToken, uint256 _percent) external;
	function setRebalanceMargins(uint256 _liquidRebalanceMargin, uint256 _portfolioRebalanceMargin) external;

	// emitted events
	event InsertToken(address indexed _token);
	event RemoveToken(address indexed _token);
	event AnnounceTokenPercentTransfer(address indexed _sourceToken, address indexed _targetToken, uint256 _percent);
	event TransferTokenPercent(address indexed _sourceToken, address indexed _targetToken, uint256 _percent);
	event ChangeTokenPercent(address indexed _token, uint256 _oldPercent, uint256 _newPercent);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import { GCToken } from "./GCToken.sol";
import { G } from "./G.sol";

/**
 * @dev This library implements data structure abstraction for the portfolio
 *      reserve management code in order to circuvent the EVM contract size limit.
 *      It is therefore a public library shared by all gToken Type 0 contracts and
 *      needs to be published alongside them. See GTokenType0.sol for further
 *      documentation.
 */
library GPortfolioReserveManager
{
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;
	using GPortfolioReserveManager for GPortfolioReserveManager.Self;

	uint256 constant DEFAULT_LIQUID_REBALANCE_MARGIN = 95e15; // 9.5%
	uint256 constant DEFAULT_PORTFOLIO_REBALANCE_MARGIN = 1e16; // 1%
	uint256 constant MAXIMUM_TOKEN_COUNT = 5;
	uint256 constant PORTFOLIO_CHANGE_WAIT_INTERVAL = 1 days;
	uint256 constant PORTFOLIO_CHANGE_OPEN_INTERVAL = 1 days;

	struct Self {
		address reserveToken;
		EnumerableSet.AddressSet tokens;
		mapping (address => uint256) percents;
		mapping (uint256 => uint256) announcements;
		uint256 liquidRebalanceMargin;
		uint256 portfolioRebalanceMargin;
	}

	/**
	 * @dev Initializes the data structure. This method is exposed publicly.
	 * @param _reserveToken The ERC-20 token address of the reserve token.
	 */
	function init(Self storage _self, address _reserveToken) public
	{
		_self.reserveToken = _reserveToken;
		_self.percents[_reserveToken] = 1e18;
		_self.liquidRebalanceMargin = DEFAULT_LIQUID_REBALANCE_MARGIN;
		_self.portfolioRebalanceMargin = DEFAULT_PORTFOLIO_REBALANCE_MARGIN;
	}

	/**
	 * @dev The total number of gTokens added to the portfolio. This method
	 *      is exposed publicly.
	 * @return _count The number of gTokens that make up the portfolio.
	 */
	function tokenCount(Self storage _self) public view returns (uint256 _count)
	{
		return _self.tokens.length();
	}

	/**
	 * @dev Returns one of the gTokens that makes up the portfolio. This
	 *      method is exposed publicly.
	 * @param _index The desired index, must be less than the token count.
	 * @return _token The gToken currently present at the given index.
	 */
	function tokenAt(Self storage _self, uint256 _index) public view returns (address _token)
	{
		require(_index < _self.tokens.length(), "invalid index");
		return _self.tokens.at(_index);
	}

	/**
	 * @dev Returns the percentual participation of a token (including
	 *      the reserve token) in the portfolio composition. This method is
	 *      exposed publicly.
	 * @param _token The given token address.
	 * @return _percent The token percentual share of the portfolio.
	 */
	function tokenPercent(Self storage _self, address _token) public view returns (uint256 _percent)
	{
		return _self.percents[_token];
	}

	/**
	 * @dev Inserts a new gToken into the portfolio. The new gToken must
	 *      have the reserve token as its underlying token. The initial
	 *      portfolio share of the new token will be 0%. This method is
	 *      exposed publicly.
	 * @param _token The contract address of the new gToken to be incorporated
	 *               into the portfolio.
	 */
	function insertToken(Self storage _self, address _token) public
	{
		require(_self.tokens.length() < MAXIMUM_TOKEN_COUNT, "limit reached");
		address _underlyingToken = GCToken(_token).underlyingToken();
		require(_underlyingToken == _self.reserveToken, "mismatched token");
		require(_self.tokens.add(_token), "duplicate token");
		assert(_self.percents[_token] == 0);
	}

	/**
	 * @dev Removes a gToken from the portfolio. The portfolio share of the
	 *      token must be 0% before it can be removed. The underlying reserve
	 *      is redeemed upon removal. This method is exposed publicly.
	 * @param _token The contract address of the gToken to be removed from
	 *               the portfolio.
	 */
	function removeToken(Self storage _self, address _token) public
	{
		require(_self.percents[_token] == 0, "positive percent");
		require(_self.tokens.remove(_token), "unknown token");
		_self._withdrawUnderlying(_token, _self._getUnderlyingReserve(_token));
	}

	/**
	 * @dev Announces a token percent transfer before it can happen.
	 * @param _sourceToken The token address to provide the share.
	 * @param _targetToken The token address to receive the share.
	 * @param _percent The percentual share to shift.
	 */
	function announceTokenPercentTransfer(Self storage _self, address _sourceToken, address _targetToken, uint256 _percent) public
	{
		uint256 _hash = uint256(keccak256(abi.encode(uint256(_sourceToken), uint256(_targetToken), _percent)));
		uint256 _announcementTime = now;
		_self.announcements[_hash] = _announcementTime;
	}

	/**
	 * @dev Shifts a percentual share of the portfolio allocation from
	 *      one gToken to another gToken. The reserve token can also be
	 *      used as source or target of the operation. This does not
	 *      actually shifts funds, only reconfigures the allocation.
	 *      This method is exposed publicly. Note that in order to perform
	 *      a token transfer where the target token is not the reserve token
	 *      one must account the transfer ahead of time.
	 *      See anounceTokenPercentTransfer().
	 * @param _sourceToken The token address to provide the share.
	 * @param _targetToken The token address to receive the share.
	 * @param _percent The percentual share to shift.
	 */
	function transferTokenPercent(Self storage _self, address _sourceToken, address _targetToken, uint256 _percent) public
	{
		require(_percent <= _self.percents[_sourceToken], "invalid percent");
		require(_sourceToken != _targetToken, "invalid transfer");
		require(_targetToken == _self.reserveToken || _self.tokens.contains(_targetToken), "unknown token");
		uint256 _hash = uint256(keccak256(abi.encode(uint256(_sourceToken), uint256(_targetToken), _percent)));
		uint256 _announcementTime = _self.announcements[_hash];
		uint256 _effectiveTime = _announcementTime + PORTFOLIO_CHANGE_WAIT_INTERVAL;
		uint256 _cutoffTime = _effectiveTime + PORTFOLIO_CHANGE_OPEN_INTERVAL;
		require(_targetToken == _self.reserveToken || _effectiveTime <= now && now < _cutoffTime, "unannounced transfer");
		_self.announcements[_hash] = 0;
		_self.percents[_sourceToken] -= _percent;
		_self.percents[_targetToken] += _percent;
	}

	/**
	 * @dev Sets the percentual margins tolerable before triggering a
	 *      rebalance action (i.e. an underlying deposit or withdrawal).
	 *      This method is exposed publicly.
	 * @param _liquidRebalanceMargin The liquid percentual rebalance margin,
	 *                               to be configured by the owner.
	 * @param _portfolioRebalanceMargin The portfolio percentual rebalance
	 *                                  margin, to be configured by the owner.
	 */
	function setRebalanceMargins(Self storage _self, uint256 _liquidRebalanceMargin, uint256 _portfolioRebalanceMargin) public
	{
		require(0 <= _liquidRebalanceMargin && _liquidRebalanceMargin <= 1e18, "invalid margin");
		require(0 <= _portfolioRebalanceMargin && _portfolioRebalanceMargin <= 1e18, "invalid margin");
		_self.liquidRebalanceMargin = _liquidRebalanceMargin;
		_self.portfolioRebalanceMargin = _portfolioRebalanceMargin;
	}

	/**
	 * @dev Returns the total reserve amount held liquid by the contract
	 *      summed up with the underlying reserve of all gTokens that make up
	 *      the portfolio. This method is exposed publicly.
	 * @return _totalReserve The computed total reserve amount.
	 */
	function totalReserve(Self storage _self) public view returns (uint256 _totalReserve)
	{
		return _self._calcTotalReserve();
	}

	/**
	 * @dev Performs the reserve adjustment actions leaving a liquidity room,
	 *      if necessary. It will attempt to perform the operation using the
	 *      liquid pool and, if necessary, either withdrawal from an underlying
	 *      gToken to get more liquidity, or deposit/withdrawal from an
	 *      underlying gToken to move towards the desired reserve allocation
	 *      if any of them falls beyond the rebalance margin thresholds.
	 *      To save on gas costs the reserve adjusment will request at most
	 *      one operation from any of the underlying gTokens. This method is
	 *      exposed publicly.
	 * @param _roomAmount The underlying token amount to be available after the
	 *                    operation. This is revelant for withdrawals, once the
	 *                    room amount is withdrawn the reserve should reflect
	 *                    the configured collateralization ratio.
	 * @return _success A boolean indicating whether or not both actions suceeded.
	 */
	function adjustReserve(Self storage _self, uint256 _roomAmount) public returns (bool _success)
	{
		// the reserve amount must deduct the room requested
		uint256 _reserveAmount = _self._calcTotalReserve();
		_roomAmount = G.min(_roomAmount, _reserveAmount);
		_reserveAmount = _reserveAmount.sub(_roomAmount);

		// the liquid amount must deduct the room requested
		uint256 _liquidAmount = G.getBalance(_self.reserveToken);
		uint256 _blockedAmount = G.min(_roomAmount, _liquidAmount);
		_liquidAmount = _liquidAmount.sub(_blockedAmount);

		// calculates whether or not the liquid amount exceeds the
		// configured range and requires either a deposit or a withdrawal
		// to be performed
		(uint256 _depositAmount, uint256 _withdrawalAmount) = _self._calcLiquidAdjustment(_reserveAmount, _liquidAmount);

		// if the liquid amount is not enough to process a withdrawal
		// we will need to withdraw the missing amount from one of the
		// underlying gTokens (actually we will choose the one for which
		// the withdrawal will produce the least impact in terms of
		// percentual share deviation from its configured target)
		uint256 _requiredAmount = _roomAmount.sub(_blockedAmount);
		if (_requiredAmount > 0) {
			_withdrawalAmount = _withdrawalAmount.add(_requiredAmount);
			(address _adjustToken, uint256 _adjustAmount) = _self._findRequiredWithdrawal(_reserveAmount, _requiredAmount, _withdrawalAmount);
			if (_adjustToken == address(0)) return false;
			return _self._withdrawUnderlying(_adjustToken, _adjustAmount);
		}

		// finds the gToken that will have benefited more of this deposit
		// in terms of its target percentual share deviation and performs
		// the deposit on it
		if (_depositAmount > 0) {
			(address _adjustToken, uint256 _adjustAmount) = _self._findDeposit(_reserveAmount);
			if (_adjustToken == address(0)) return true;
			return _self._depositUnderlying(_adjustToken, G.min(_adjustAmount, _depositAmount));
		}

		// finds the gToken that will have benefited more of this withdrawal
		// in terms of its target percentual share deviation and performs
		// the withdrawal on it
		if (_withdrawalAmount > 0) {
			(address _adjustToken, uint256 _adjustAmount) = _self._findWithdrawal(_reserveAmount);
			if (_adjustToken == address(0)) return true;
			return _self._withdrawUnderlying(_adjustToken, G.min(_adjustAmount, _withdrawalAmount));
		}

		return true;
	}

	/**
	 * @dev Calculates the total reserve amount. It sums up the reserve held
	 *      by the contract with the underlying reserve held by the gTokens
	 *      that make up the portfolio.
	 * @return _totalReserve The computed total reserve amount.
	 */
	function _calcTotalReserve(Self storage _self) internal view returns (uint256 _totalReserve)
	{
		_totalReserve = G.getBalance(_self.reserveToken);
		uint256 _tokenCount = _self.tokens.length();
		for (uint256 _index = 0; _index < _tokenCount; _index++) {
			address _token = _self.tokens.at(_index);
			uint256 _tokenReserve = _self._getUnderlyingReserve(_token);
			_totalReserve = _totalReserve.add(_tokenReserve);
		}
		return _totalReserve;
	}

	/**
	 * @dev Calculates the amount that falls either above or below
	 *      the rebalance margin for the liquid pool. If we have more
	 *      liquid amount than its configured share plus the rebalance
	 *      margin it returns that amount paired with zero. If we have less
	 *      liquid amount than its configured share minus the rebalance
	 *      margin it returns zero paired with that amount. If none of these
	 *      two situations happen, then the liquid amount falls within the
	 *      acceptable parameters, and it returns a pair of zeros.
	 * @param _reserveAmount The total reserve amount used for calculation.
	 * @param _liquidAmount The liquid amount available used for calculation.
	 * @return _depositAmount The amount to be deposited or zero.
	 * @return _withdrawalAmount The amount to be withdrawn or zero.
	 */
	function _calcLiquidAdjustment(Self storage _self, uint256 _reserveAmount, uint256 _liquidAmount) internal view returns (uint256 _depositAmount, uint256 _withdrawalAmount)
	{
		uint256 _tokenPercent = _self.percents[_self.reserveToken];
		uint256 _tokenReserve = _reserveAmount.mul(_tokenPercent).div(1e18);
		if (_liquidAmount > _tokenReserve) {
			uint256 _upperPercent = G.min(1e18, _tokenPercent.add(_self.liquidRebalanceMargin));
			uint256 _upperReserve = _reserveAmount.mul(_upperPercent).div(1e18);
			if (_liquidAmount > _upperReserve) return (_liquidAmount.sub(_tokenReserve), 0);
		}
		else
		if (_liquidAmount < _tokenReserve) {
			uint256 _lowerPercent = _tokenPercent.sub(G.min(_tokenPercent, _self.liquidRebalanceMargin));
			uint256 _lowerReserve = _reserveAmount.mul(_lowerPercent).div(1e18);
			if (_liquidAmount < _lowerReserve) return (0, _tokenReserve.sub(_liquidAmount));
		}
		return (0, 0);
	}

	/**
	 * @dev Search the list of gTokens and selects the one that has enough
	 *      liquidity and for which the withdrawal of the required amount
	 *      will yield the least deviation from its target share.
	 * @param _reserveAmount The total reserve amount used for calculation.
	 * @param _minimumAmount The minimum liquidity amount used for calculation.
	 * @param _targetAmount The target liquidity amount used for calculation.
	 * @return _adjustToken The gToken to withdraw from.
	 * @return _adjustAmount The amount to be withdrawn.
	 */
	function _findRequiredWithdrawal(Self storage _self, uint256 _reserveAmount, uint256 _minimumAmount, uint256 _targetAmount) internal view returns (address _adjustToken, uint256 _adjustAmount)
	{
		uint256 _minPercent = 1e18;
		_adjustToken = address(0);
		_adjustAmount = 0;

		uint256 _tokenCount = _self.tokens.length();
		for (uint256 _index = 0; _index < _tokenCount; _index++) {
			address _token = _self.tokens.at(_index);
			uint256 _tokenReserve = _self._getUnderlyingReserve(_token);
			if (_tokenReserve < _minimumAmount) continue;
			uint256 _maximumAmount = G.min(_tokenReserve, _targetAmount);

			uint256 _oldTokenReserve = _tokenReserve.sub(_maximumAmount);
			uint256 _oldTokenPercent = _oldTokenReserve.mul(1e18).div(_reserveAmount);
			uint256 _newTokenPercent = _self.percents[_token];

			uint256 _percent = 0;
			if (_newTokenPercent > _oldTokenPercent) _percent = _newTokenPercent.sub(_oldTokenPercent);
			else
			if (_newTokenPercent < _oldTokenPercent) _percent = _oldTokenPercent.sub(_newTokenPercent);

			if (_maximumAmount > _adjustAmount || _maximumAmount == _adjustAmount && _percent < _minPercent) {
				_minPercent = _percent;
				_adjustToken = _token;
				_adjustAmount = _maximumAmount;
			}
		}

		return (_adjustToken, _adjustAmount);
	}

	/**
	 * @dev Search the list of gTokens and selects the one for which the
	 *      deposit will provide the best correction of deviation from
	 *      its target share.
	 * @param _reserveAmount The total reserve amount used for calculation.
	 * @return _adjustToken The gToken to deposit to.
	 * @return _adjustAmount The amount to be deposited.
	 */
	function _findDeposit(Self storage _self, uint256 _reserveAmount) internal view returns (address _adjustToken, uint256 _adjustAmount)
	{
		uint256 _maxPercent = _self.portfolioRebalanceMargin;
		_adjustToken = address(0);
		_adjustAmount = 0;

		uint256 _tokenCount = _self.tokens.length();
		for (uint256 _index = 0; _index < _tokenCount; _index++) {
			address _token = _self.tokens.at(_index);

			uint256 _oldTokenReserve = _self._getUnderlyingReserve(_token);
			uint256 _oldTokenPercent = _oldTokenReserve.mul(1e18).div(_reserveAmount);
			uint256 _newTokenPercent = _self.percents[_token];

			if (_newTokenPercent > _oldTokenPercent) {
				uint256 _percent = _newTokenPercent.sub(_oldTokenPercent);
				if (_percent > _maxPercent) {
					uint256 _newTokenReserve = _reserveAmount.mul(_newTokenPercent).div(1e18);
					uint256 _amount = _newTokenReserve.sub(_oldTokenReserve);

					_maxPercent = _percent;
					_adjustToken = _token;
					_adjustAmount = _amount;
				}
			}
		}

		return (_adjustToken, _adjustAmount);
	}

	/**
	 * @dev Search the list of gTokens and selects the one for which the
	 *      withdrawal will provide the best correction of deviation from
	 *      its target share.
	 * @param _reserveAmount The total reserve amount used for calculation.
	 * @return _adjustToken The gToken to withdraw from.
	 * @return _adjustAmount The amount to be withdrawn.
	 */
	function _findWithdrawal(Self storage _self, uint256 _reserveAmount) internal view returns (address _adjustToken, uint256 _adjustAmount)
	{
		uint256 _maxPercent = _self.portfolioRebalanceMargin;
		_adjustToken = address(0);
		_adjustAmount = 0;

		uint256 _tokenCount = _self.tokens.length();
		for (uint256 _index = 0; _index < _tokenCount; _index++) {
			address _token = _self.tokens.at(_index);

			uint256 _oldTokenReserve = _self._getUnderlyingReserve(_token);
			uint256 _oldTokenPercent = _oldTokenReserve.mul(1e18).div(_reserveAmount);
			uint256 _newTokenPercent = _self.percents[_token];

			if (_newTokenPercent < _oldTokenPercent) {
				uint256 _percent = _oldTokenPercent.sub(_newTokenPercent);
				if (_percent > _maxPercent) {
					uint256 _newTokenReserve = _reserveAmount.mul(_newTokenPercent).div(1e18);
					uint256 _amount = _oldTokenReserve.sub(_newTokenReserve);

					_maxPercent = _percent;
					_adjustToken = _token;
					_adjustAmount = _amount;
				}
			}
		}

		return (_adjustToken, _adjustAmount);
	}

	/**
	 * @dev Performs a deposit of the reserve asset to the given gToken.
	 * @param _token The gToken to deposit to.
	 * @param _amount The amount to be deposited.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _depositUnderlying(Self storage _self, address _token, uint256 _amount) internal returns (bool _success)
	{
		_amount = G.min(_amount, G.getBalance(_self.reserveToken));
		if (_amount == 0) return true;
		G.approveFunds(_self.reserveToken, _token, _amount);
		try GCToken(_token).depositUnderlying(_amount) {
			return true;
		} catch (bytes memory /* _data */) {
			G.approveFunds(_self.reserveToken, _token, 0);
			return false;
		}
	}

	/**
	 * @dev Performs a withdrawal of the reserve asset from the given gToken.
	 * @param _token The gToken to withdraw from.
	 * @param _amount The amount to be withdrawn.
	 * @return _success A boolean indicating whether or not the action succeeded.
	 */
	function _withdrawUnderlying(Self storage _self, address _token, uint256 _amount) internal returns (bool _success)
	{
		uint256 _grossShares = _self._calcWithdrawalSharesFromUnderlyingCost(_token, _amount);
		_grossShares = G.min(_grossShares, G.getBalance(_token));
		if (_grossShares == 0) return true;
		try GCToken(_token).withdrawUnderlying(_grossShares) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	/**
	 * @dev Calculates how much of the reserve token is available for
	 *      withdrawal by the current contract for the given gToken.
	 * @param _token The gToken to withdraw from.
	 * @return _underlyingCost The total amount redeemable by the current
	 *                         contract from the given gToken.
	 */
	function _getUnderlyingReserve(Self storage _self, address _token) internal view returns (uint256 _underlyingCost)
	{
		uint256 _grossShares = G.getBalance(_token);
		return _self._calcWithdrawalUnderlyingCostFromShares(_token, _grossShares);
	}

	/**
	 * @dev Calculates how much will be received for withdrawing the provided
	 *      number of shares from a given gToken.
	 * @param _token The gToken to withdraw from.
	 * @param _grossShares The number of shares to be provided.
	 * @return _underlyingCost The amount to be received.
	 */
	function _calcWithdrawalUnderlyingCostFromShares(Self storage /* _self */, address _token, uint256 _grossShares) internal view returns (uint256 _underlyingCost)
	{
		uint256 _totalReserve = GCToken(_token).totalReserve();
		uint256 _totalSupply = GCToken(_token).totalSupply();
		uint256 _withdrawalFee = GCToken(_token).withdrawalFee();
		uint256 _exchangeRate = GCToken(_token).exchangeRate();
		(_underlyingCost,) = GCToken(_token).calcWithdrawalUnderlyingCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee, _exchangeRate);
		return _underlyingCost;
	}

	/**
	 * @dev Calculates how many shares are required to withdraw so much from
	 *      a given gToken.
	 * @param _token The gToken to withdraw from.
	 * @param _underlyingCost The desired amount to be withdrawn.
	 * @return _grossShares The number of shares required to withdraw the desired amount.
	 */
	function _calcWithdrawalSharesFromUnderlyingCost(Self storage /* _self */, address _token, uint256 _underlyingCost) internal view returns (uint256 _grossShares)
	{
		uint256 _totalReserve = GCToken(_token).totalReserve();
		uint256 _totalSupply = GCToken(_token).totalSupply();
		uint256 _withdrawalFee = GCToken(_token).withdrawalFee();
		uint256 _exchangeRate = GCToken(_token).exchangeRate();
		(_grossShares,) = GCToken(_token).calcWithdrawalSharesFromUnderlyingCost(_underlyingCost, _totalReserve, _totalSupply, _withdrawalFee, _exchangeRate);
		return _grossShares;
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Minimal interface for gTokens, implemented by the GTokenBase contract.
 *      See GTokenBase.sol for further documentation.
 */
interface GToken is IERC20
{
	// pure functions
	function calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) external pure returns (uint256 _netShares, uint256 _feeShares);
	function calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) external pure returns (uint256 _cost, uint256 _feeShares);
	function calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) external pure returns (uint256 _grossShares, uint256 _feeShares);
	function calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) external pure returns (uint256 _cost, uint256 _feeShares);

	// view functions
	function reserveToken() external view returns (address _reserveToken);
	function totalReserve() external view returns (uint256 _totalReserve);
	function depositFee() external view returns (uint256 _depositFee);
	function withdrawalFee() external view returns (uint256 _withdrawalFee);

	// open functions
	function deposit(uint256 _cost) external;
	function withdraw(uint256 _grossShares) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { GToken } from "./GToken.sol";
import { GPooler } from "./GPooler.sol";
import { GFormulae } from "./GFormulae.sol";
import { GLiquidityPoolManager } from "./GLiquidityPoolManager.sol";
import { G } from "./G.sol";

/**
 * @notice This abstract contract provides the basis implementation for all
 *         gTokens. It extends the ERC20 functionality by implementing all
 *         the methods of the GToken interface. The gToken basic functionality
 *         comprises of a reserve, provided in the reserve token, and a supply
 *         of shares. Every time someone deposits into the contract some amount
 *         of reserve tokens it will receive a given amount of this gToken
 *         shares. Conversely, upon withdrawal, someone redeems their previously
 *         deposited assets by providing the associated amount of gToken shares.
 *         The nominal price of a gToken is given by the ratio between the
 *         reserve balance and the total supply of shares. Upon deposit and
 *         withdrawal of funds a 1% fee is applied and collected from shares.
 *         Half of it is immediately burned, which is equivalent to
 *         redistributing it to all gToken holders, and the other half is
 *         provided to a liquidity pool configured as a 50% GRO/50% gToken with
 *         a 10% swap fee. Every week a percentage of the liquidity pool is
 *         burned to account for the accumulated swap fees for that period.
 *         Finally, the gToken contract provides functionality to migrate the
 *         total amount of funds locked in the liquidity pool to an external
 *         address, this mechanism is provided to facilitate the upgrade of
 *         this gToken contract by future implementations. After migration has
 *         started the fee for deposits becomes 2% and the fee for withdrawals
 *         becomes 0%, in order to incentivise others to follow the migration.
 */
abstract contract GTokenBase is ERC20, Ownable, ReentrancyGuard, GToken, GPooler
{
	using GLiquidityPoolManager for GLiquidityPoolManager.Self;

	uint256 constant DEPOSIT_FEE = 1e16; // 1%
	uint256 constant WITHDRAWAL_FEE = 1e16; // 1%
	uint256 constant DEPOSIT_FEE_AFTER_MIGRATION = 2e16; // 2%
	uint256 constant WITHDRAWAL_FEE_AFTER_MIGRATION = 0e16; // 0%

	address public immutable override stakesToken;
	address public immutable override reserveToken;

	GLiquidityPoolManager.Self lpm;

	/**
	 * @dev Constructor for the gToken contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. cDAI for gcDAI).
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken)
		ERC20(_name, _symbol) public
	{
		_setupDecimals(_decimals);
		stakesToken = _stakesToken;
		reserveToken = _reserveToken;
		lpm.init(_stakesToken, address(this));
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         received/minted upon depositing to the contract.
	 * @param _cost The amount of reserve token being deposited.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @return _netShares The net amount of shares being received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		return GFormulae._calcDepositSharesFromCost(_cost, _totalReserve, _totalSupply, _depositFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of
	 *         reserve token to be deposited in order to receive the desired
	 *         amount of shares.
	 * @param _netShares The amount of this gToken shares to receive.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @return _cost The cost, in the reserve token, to be paid.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return GFormulae._calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         given/burned upon withdrawing from the contract.
	 * @param _cost The amount of reserve token being withdrawn.
	 * @param _totalReserve The reserve balance as obtained by totalReserve()
	 * @param _totalSupply The shares supply as obtained by totalSupply()
	 * @param _withdrawalFee The current withdrawal fee as obtained by withdrawalFee()
	 * @return _grossShares The total amount of shares being deducted,
	 *                      including fees.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		return GFormulae._calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of
	 *         reserve token to be withdrawn given the desired amount of
	 *         shares.
	 * @param _grossShares The amount of this gToken shares to provide.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _withdrawalFee The current withdrawal fee as obtained by withdrawalFee().
	 * @return _cost The cost, in the reserve token, to be received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return GFormulae._calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
	}

	/**
	 * @notice Provides the amount of reserve tokens currently being help by
	 *         this contract.
	 * @return _totalReserve The amount of the reserve token corresponding
	 *                       to this contract's balance.
	 */
	function totalReserve() public view virtual override returns (uint256 _totalReserve)
	{
		return G.getBalance(reserveToken);
	}

	/**
	 * @notice Provides the current minting/deposit fee. This fee is
	 *         applied to the amount of this gToken shares being created
	 *         upon deposit. The fee defaults to 1% and is set to 2%
	 *         after the liquidity pool has been migrated.
	 * @return _depositFee A percent value that accounts for the percentage
	 *                     of shares being minted at each deposit that be
	 *                     collected as fee.
	 */
	function depositFee() public view override returns (uint256 _depositFee) {
		return lpm.hasMigrated() ? DEPOSIT_FEE_AFTER_MIGRATION : DEPOSIT_FEE;
	}

	/**
	 * @notice Provides the current burning/withdrawal fee. This fee is
	 *         applied to the amount of this gToken shares being redeemed
	 *         upon withdrawal. The fee defaults to 1% and is set to 0%
	 *         after the liquidity pool is migrated.
	 * @return _withdrawalFee A percent value that accounts for the
	 *                        percentage of shares being burned at each
	 *                        withdrawal that be collected as fee.
	 */
	function withdrawalFee() public view override returns (uint256 _withdrawalFee) {
		return lpm.hasMigrated() ? WITHDRAWAL_FEE_AFTER_MIGRATION : WITHDRAWAL_FEE;
	}

	/**
	 * @notice Provides the address of the liquidity pool contract.
	 * @return _liquidityPool An address identifying the liquidity pool.
	 */
	function liquidityPool() public view override returns (address _liquidityPool)
	{
		return lpm.liquidityPool;
	}

	/**
	 * @notice Provides the percentage of the liquidity pool to be burned.
	 *         This amount should account approximately for the swap fees
	 *         collected by the liquidity pool during a 7-day period.
	 * @return _burningRate A percent value that corresponds to the current
	 *                      amount of the liquidity pool to be burned at
	 *                      each 7-day cycle.
	 */
	function liquidityPoolBurningRate() public view override returns (uint256 _burningRate)
	{
		return lpm.burningRate;
	}

	/**
	 * @notice Marks when the last liquidity pool burn took place. There is
	 *         a minimum 7-day grace period between consecutive burnings of
	 *         the liquidity pool.
	 * @return _lastBurningTime A timestamp for when the liquidity pool
	 *                          burning took place for the last time.
	 */
	function liquidityPoolLastBurningTime() public view override returns (uint256 _lastBurningTime)
	{
		return lpm.lastBurningTime;
	}

	/**
	 * @notice Provides the address receiving the liquidity pool migration.
	 * @return _migrationRecipient An address to which funds will be sent
	 *                             upon liquidity pool migration completion.
	 */
	function liquidityPoolMigrationRecipient() public view override returns (address _migrationRecipient)
	{
		return lpm.migrationRecipient;
	}

	/**
	 * @notice Provides the timestamp for when the liquidity pool migration
	 *         can be completed.
	 * @return _migrationUnlockTime A timestamp that defines the end of the
	 *                              7-day grace period for liquidity pool
	 *                              migration.
	 */
	function liquidityPoolMigrationUnlockTime() public view override returns (uint256 _migrationUnlockTime)
	{
		return lpm.migrationUnlockTime;
	}

	/**
	 * @notice Performs the minting of gToken shares upon the deposit of the
	 *         reserve token. The actual number of shares being minted can
	 *         be calculated using the calcDepositSharesFromCost function.
	 *         In every deposit, 1% of the shares is retained in terms of
	 *         deposit fee. Half of it is immediately burned and the other
	 *         half is provided to the locked liquidity pool. The funds
	 *         will be pulled in by this contract, therefore they must be
	 *         previously approved.
	 * @param _cost The amount of reserve token being deposited in the
	 *              operation.
	 */
	function deposit(uint256 _cost) public override nonReentrant
	{
		address _from = msg.sender;
		require(_cost > 0, "cost must be greater than 0");
		(uint256 _netShares, uint256 _feeShares) = GFormulae._calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "shares must be greater than 0");
		G.pullFunds(reserveToken, _from, _cost);
		require(_prepareDeposit(_cost), "not available at the moment");
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
	}

	/**
	 * @notice Performs the burning of gToken shares upon the withdrawal of
	 *         the reserve token. The actual amount of the reserve token to
	 *         be received can be calculated using the
	 *         calcWithdrawalCostFromShares function. In every withdrawal,
	 *         1% of the shares is retained in terms of withdrawal fee.
	 *         Half of it is immediately burned and the other half is
	 *         provided to the locked liquidity pool.
	 * @param _grossShares The gross amount of this gToken shares being
	 *                     redeemed in the operation.
	 */
	function withdraw(uint256 _grossShares) public override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		require(_cost > 0, "cost must be greater than 0");
		require(_prepareWithdrawal(_cost), "not available at the moment");
		_cost = G.min(_cost, G.getBalance(reserveToken));
		G.pushFunds(reserveToken, _from, _cost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
	}

	/**
	 * @notice Allocates a liquidity pool with the given amount of funds and
	 *         locks it to this contract. This function should be called
	 *         shortly after the contract is created to associated a newly
	 *         created liquidity pool to it, which will collect fees
	 *         associated with the minting and burning of this gToken shares.
	 *         The liquidity pool will consist of a 50%/50% balance of the
	 *         stakes token (GRO) and this gToken shares with a swap fee of
	 *         10%. The rate between the amount of the two assets deposited
	 *         via this function defines the initial price. The minimum
	 *         amount to be provided for each is 1,000,000 wei. The funds
	 *         will be pulled in by this contract, therefore they must be
	 *         previously approved. This is a priviledged function
	 *         restricted to the contract owner.
	 * @param _stakesAmount The initial amount of stakes token.
	 * @param _sharesAmount The initial amount of this gToken shares.
	 */
	function allocateLiquidityPool(uint256 _stakesAmount, uint256 _sharesAmount) public override onlyOwner nonReentrant
	{
		address _from = msg.sender;
		G.pullFunds(stakesToken, _from, _stakesAmount);
		_transfer(_from, address(this), _sharesAmount);
		lpm.allocatePool(_stakesAmount, _sharesAmount);
	}

	/**
	 * @notice Changes the percentual amount of the funds to be burned from
	 *         the liquidity pool at each 7-day period. This is a
	 *         priviledged function restricted to the contract owner.
	 * @param _burningRate The percentage of the liquidity pool to be burned.
	 */
	function setLiquidityPoolBurningRate(uint256 _burningRate) public override onlyOwner nonReentrant
	{
		lpm.setBurningRate(_burningRate);
	}

	/**
	 * @notice Burns part of the liquidity pool funds decreasing the supply
	 *         of both the stakes token and this gToken shares.
	 *         The amount to be burned is set via the function
	 *         setLiquidityPoolBurningRate and defaults to 0.5%.
	 *         After this function is called there must be a 7-day wait
	 *         period before it can be called again.
	 *         The purpose of this function is to burn the aproximate amount
	 *         of fees collected from swaps that take place in the liquidity
	 *         pool during the previous 7-day period. This function will
	 *         emit a BurnLiquidityPoolPortion event upon success. This is
	 *         a priviledged function restricted to the contract owner.
	 */
	function burnLiquidityPoolPortion() public override onlyOwner nonReentrant
	{
		lpm.gulpPoolAssets();
		(uint256 _stakesAmount, uint256 _sharesAmount) = lpm.burnPoolPortion();
		_burnStakes(_stakesAmount);
		_burn(address(this), _sharesAmount);
		emit BurnLiquidityPoolPortion(_stakesAmount, _sharesAmount);
	}

	/**
	 * @notice Initiates the liquidity pool migration. It consists of
	 *         setting the migration recipient address and starting a
	 *         7-day grace period. After the 7-day grace period the
	 *         migration can be completed via the
	 *         completeLiquidityPoolMigration fuction. Anytime before
	 *         the migration is completed is can be cancelled via
	 *         cancelLiquidityPoolMigration. This function will emit a
	 *         InitiateLiquidityPoolMigration event upon success. This is
	 *         a priviledged function restricted to the contract owner.
	 * @param _migrationRecipient The receiver of the liquidity pool funds.
	 */
	function initiateLiquidityPoolMigration(address _migrationRecipient) public override onlyOwner nonReentrant
	{
		lpm.initiatePoolMigration(_migrationRecipient);
		emit InitiateLiquidityPoolMigration(_migrationRecipient);
	}

	/**
	 * @notice Cancels the liquidity pool migration if it has been already
	 *         initiated. This will reset the state of the liquidity pool
	 *         migration. This function will emit a
	 *         CancelLiquidityPoolMigration event upon success. This is
	 *         a priviledged function restricted to the contract owner.
	 */
	function cancelLiquidityPoolMigration() public override onlyOwner nonReentrant
	{
		address _migrationRecipient = lpm.cancelPoolMigration();
		emit CancelLiquidityPoolMigration(_migrationRecipient);
	}

	/**
	 * @notice Completes the liquidity pool migration at least 7-days after
	 *         it has been started. The migration consists of sendind the
	 *         the full balance held in the liquidity pool, both in the
	 *         stakes token and gToken shares, to the address set when
	 *         the migration was initiated. This function will emit a
	 *         CompleteLiquidityPoolMigration event upon success. This is
	 *         a priviledged function restricted to the contract owner.
	 */
	function completeLiquidityPoolMigration() public override onlyOwner nonReentrant
	{
		lpm.gulpPoolAssets();
		(address _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount) = lpm.completePoolMigration();
		G.pushFunds(stakesToken, _migrationRecipient, _stakesAmount);
		_transfer(address(this), _migrationRecipient, _sharesAmount);
		emit CompleteLiquidityPoolMigration(_migrationRecipient, _stakesAmount, _sharesAmount);
	}

	/**
	 * @dev This abstract method must be implemented by subcontracts in
	 *      order to adjust the underlying reserve after a deposit takes
	 *      place. The actual implementation depends on the strategy and
	 *      algorithm used to handle the reserve.
	 * @param _cost The amount of the reserve token being deposited.
	 */
	function _prepareDeposit(uint256 _cost) internal virtual returns (bool _success);

	/**
	 * @dev This abstract method must be implemented by subcontracts in
	 *      order to adjust the underlying reserve before a withdrawal takes
	 *      place. The actual implementation depends on the strategy and
	 *      algorithm used to handle the reserve.
	 * @param _cost The amount of the reserve token being withdrawn.
	 */
	function _prepareWithdrawal(uint256 _cost) internal virtual returns (bool _success);

	/**
	 * @dev Burns the given amount of the stakes token. The default behavior
	 *      of the function for general ERC-20 is to send the funds to
	 *      address(0), but that can be overriden by a subcontract.
	 * @param _stakesAmount The amount of the stakes token being burned.
	 */
	function _burnStakes(uint256 _stakesAmount) internal virtual
	{
		G.pushFunds(stakesToken, address(0), _stakesAmount);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GTokenBase } from "./GTokenBase.sol";
import { GPortfolio } from "./GPortfolio.sol";
import { GPortfolioReserveManager } from "./GPortfolioReserveManager.sol";

/**
 * @notice This contract implements the functionality for the gToken Type 0.
 *         The gToken Type 0 provides a simple portfolio management strategy
 *         that splits the reserve asset percentually among multiple other
 *         gTokens. Also, it allows for part of the reserve to be kept liquid,
 *         in the reserve token itself, to save on gas fees. The contract owner
 *         can add and remove gTokens that compose the portfolio, as much as
 *         reconfigure their percentual shares. There is also a configurable
 *         rebalance margins that serves as threshold for when the contract will
 *         or not attempt to rebalance the reserve according to the set
 *         percentual ratios. The algorithm that maintains the proper
 *         distribution of the reserve token does so incrementally based on the
 *         following principles: 1) At each deposit/withdrawal, at most one
 *         underlying deposit/withdrawal is performed; 2) When the
 *         deposit/withdrawal can be served from the liquid pool, and within the
 *         bounds of the rebalance margin, no underlying deposit/withdrawal is
 *         performed; 3) When performing a rebalance the gToken with the
 *         most discrepant reserve share is chosen for rebalancing; 4) When
 *         performing an withdrawal, if it cannot be served entirely from
 *         the liquid pool, the we choose the gToken that can provide the
 *         required additional liquidity with the least percentual impact to
 *         its reserve share. As with all gTokens, gTokens Type 0 have an
 *         associated locked liquidity pool and follow the same fee structure.
 *         See GTokenBase and GPortfolioReserveManager for further documentation.
 */
contract GTokenType0 is GTokenBase, GPortfolio
{
	using GPortfolioReserveManager for GPortfolioReserveManager.Self;

	GPortfolioReserveManager.Self prm;

	/**
	 * @dev Constructor for the gToken Type 0 contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _stakesToken The ERC-20 token address to be used as stakes
	 *                     token (GRO).
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. DAI for gDAI).
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken)
		GTokenBase(_name, _symbol, _decimals, _stakesToken, _reserveToken) public
	{
		prm.init(_reserveToken);
	}

	/**
	 * @notice Overrides the default total reserve definition in order to
	 *         account, not only for the reserve asset being kept liquid by
	 *         this contract, but also sum up the reserve portions delegated
	 *         to all gTokens that make up the portfolio.
	 * @return _totalReserve The amount of the reserve token corresponding
	 *                       to this contract's worth.
	 */
	function totalReserve() public view override returns (uint256 _totalReserve)
	{
		return prm.totalReserve();
	}

	/**
	 * @notice Provides the number of gTokens that were added to this
	 *         contract by the owner.
	 * @return _count The number of gTokens that make up the portfolio.
	 */
	function tokenCount() public view override returns (uint256 _count)
	{
		return prm.tokenCount();
	}

	/**
	 * @notice Provides a gToken that was added to this contract by the owner
	 *         at a given index. Note that the index to token association
	 *         is preserved in between token removals, however removals may
	 *         may shuffle it around.
	 * @param _index The desired index, must be less than the token count.
	 * @return _token The gToken currently present at the given index.
	 */
	function tokenAt(uint256 _index) public view override returns (address _token)
	{
		return prm.tokenAt(_index);
	}

	/**
	 * @notice Provides the percentual share of a gToken in the composition
	 *         of the portfolio. Note that the value returned is the desired
	 *         percentual share and not the actual reserve share.
	 * @param _token The given token address.
	 * @return _percent The token percentual share of the portfolio, as
	 *                  configured by the owner.
	 */
	function tokenPercent(address _token) public view override returns (uint256 _percent)
	{
		return prm.tokenPercent(_token);
	}

	/**
	 * @notice Provides the percentual margins tolerable before triggering a
	 *         rebalance action (i.e. an underlying deposit or withdrawal).
	 * @return _liquidRebalanceMargin The liquid percentual rebalance margin,
	 *                                as configured by the owner.
	 * @return _portfolioRebalanceMargin The portfolio percentual rebalance
	 *                                   margin, as configured by the owner.
	 */
	function getRebalanceMargins() public view override returns (uint256 _liquidRebalanceMargin, uint256 _portfolioRebalanceMargin)
	{
		return (prm.liquidRebalanceMargin, prm.portfolioRebalanceMargin);
	}

	/**
	 * @notice Inserts a new gToken into the portfolio. The new gToken must
	 *         have the reserve token as its underlying token. The initial
	 *         portfolio share of the new token will be 0%.
	 * @param _token The contract address of the new gToken to be incorporated
	 *               into the portfolio.
	 */
	function insertToken(address _token) public override onlyOwner nonReentrant
	{
		prm.insertToken(_token);
		emit InsertToken(_token);
	}

	/**
	 * @notice Removes a gToken from the portfolio. The portfolio share of
	 *         the token must be 0% before it can be removed. The underlying
	 *         reserve is redeemed upon removal.
	 * @param _token The contract address of the gToken to be removed from
	 *               the portfolio.
	 */
	function removeToken(address _token) public override onlyOwner nonReentrant
	{
		prm.removeToken(_token);
		emit RemoveToken(_token);
	}

	/**
	 * @notice Announces a token percent transfer before it can happen,
	 *         signaling the intention to modify the porfolio distribution.
	 * @param _sourceToken The token address to provide the share.
	 * @param _targetToken The token address to receive the share.
	 * @param _percent The percentual share to shift.
	 */
	function anounceTokenPercentTransfer(address _sourceToken, address _targetToken, uint256 _percent) public override onlyOwner nonReentrant
	{
		prm.announceTokenPercentTransfer(_sourceToken, _targetToken, _percent);
		emit AnnounceTokenPercentTransfer(_sourceToken, _targetToken, _percent);
	}

	/**
	 * @notice Shifts a percentual share of the portfolio allocation from
	 *         one gToken to another gToken. The reserve token can also be
	 *         used as source or target of the operation. This does not
	 *         actually shifts funds, only reconfigures the allocation.
	 * @param _sourceToken The token address to provide the share.
	 * @param _targetToken The token address to receive the share.
	 * @param _percent The percentual share to shift.
	 */
	function transferTokenPercent(address _sourceToken, address _targetToken, uint256 _percent) public override onlyOwner nonReentrant
	{
		uint256 _oldSourceTokenPercent = prm.tokenPercent(_sourceToken);
		uint256 _oldTargetTokenPercent = prm.tokenPercent(_targetToken);
		prm.transferTokenPercent(_sourceToken, _targetToken, _percent);
		uint256 _newSourceTokenPercent = prm.tokenPercent(_sourceToken);
		uint256 _newTargetTokenPercent = prm.tokenPercent(_targetToken);
		emit TransferTokenPercent(_sourceToken, _targetToken, _percent);
		emit ChangeTokenPercent(_sourceToken, _oldSourceTokenPercent, _newSourceTokenPercent);
		emit ChangeTokenPercent(_targetToken, _oldTargetTokenPercent, _newTargetTokenPercent);
	}

	/**
	 * @notice Sets the percentual margins tolerable before triggering a
	 *         rebalance action (i.e. an underlying deposit or withdrawal).
	 * @param _liquidRebalanceMargin The liquid percentual rebalance margin,
	 *                               to be configured by the owner.
	 * @param _portfolioRebalanceMargin The portfolio percentual rebalance
	 *                                  margin, to be configured by the owner.
	 */
	function setRebalanceMargins(uint256 _liquidRebalanceMargin, uint256 _portfolioRebalanceMargin) public override onlyOwner nonReentrant
	{
		prm.setRebalanceMargins(_liquidRebalanceMargin, _portfolioRebalanceMargin);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      after a deposit comes along. This method uses the GPortfolioReserveManager
	 *      to adjust the reserve implementing the rebalance policy.
	 *      See GPortfolioReserveManager.sol.
	 * @param _cost The amount of reserve being deposited (ignored).
	 * @return _success A boolean indicating whether or not the operation
	 *                  succeeded. This operation should not fail unless
	 *                  any of the underlying components (Compound, Aave,
	 *                  Dydx) also fails.
	 */
	function _prepareDeposit(uint256 _cost) internal override returns (bool _success)
	{
		_cost; // silences warnings
		return prm.adjustReserve(0);
	}

	/**
	 * @dev This method is overriden from GTokenBase and sets up the reserve
	 *      before a withdrawal comes along. This method uses the GPortfolioReserveManager
	 *      to adjust the reserve implementing the rebalance policy.
	 *      See GPortfolioReserveManager.sol.
	 * @param _cost The amount of reserve being withdrawn and that needs to
	 *              be immediately liquid.
	 * @return _success A boolean indicating whether or not the operation succeeded.
	 *                  The operation may fail if it is not possible to recover
	 *                  the required liquidity (e.g. low liquidity in the markets).
	 */
	function _prepareWithdrawal(uint256 _cost) internal override returns (bool _success)
	{
		return prm.adjustReserve(_cost);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { GToken } from "./GToken.sol";
import { GVoting } from "./GVoting.sol";
import { GFormulae } from "./GFormulae.sol";
import { G } from "./G.sol";

/**
 * @notice This contract implements the functionality for the gToken Type 3.
 *         It has a higher deposit/withdrawal fee when compared to other
 *         gTokens (10%). Half of the collected fee used to reward token
 *         holders while the other half is burned along with the same proportion
 *         of the reserve. It is used in the implementation of stkGRO.
 */
contract GTokenType3 is ERC20, ReentrancyGuard, GToken, GVoting
{
	using SafeMath for uint256;

	uint256 constant DEPOSIT_FEE = 10e16; // 10%
	uint256 constant WITHDRAWAL_FEE = 10e16; // 10%

	uint256 constant VOTING_ROUND_INTERVAL = 1 days;

	address public immutable override reserveToken;

	mapping (address => address) public override candidate;

	mapping (address => uint256) private votingRound;
	mapping (address => uint256[2]) private voting;

	/**
	 * @dev Constructor for the gToken contract.
	 * @param _name The ERC-20 token name.
	 * @param _symbol The ERC-20 token symbol.
	 * @param _decimals The ERC-20 token decimals.
	 * @param _reserveToken The ERC-20 token address to be used as reserve
	 *                      token (e.g. GRO for sktGRO).
	 */
	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _reserveToken)
		ERC20(_name, _symbol) public
	{
		_setupDecimals(_decimals);
		_mint(address(this), 10);
		reserveToken = _reserveToken;
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         received/minted upon depositing to the contract.
	 * @param _cost The amount of reserve token being deposited.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @return _netShares The net amount of shares being received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		return GFormulae._calcDepositSharesFromCost(_cost, _totalReserve, _totalSupply, _depositFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of
	 *         reserve token to be deposited in order to receive the desired
	 *         amount of shares.
	 * @param _netShares The amount of this gToken shares to receive.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _depositFee The current deposit fee as obtained by depositFee().
	 * @return _cost The cost, in the reserve token, to be paid.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return GFormulae._calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of shares to be
	 *         given/burned upon withdrawing from the contract.
	 * @param _cost The amount of reserve token being withdrawn.
	 * @param _totalReserve The reserve balance as obtained by totalReserve()
	 * @param _totalSupply The shares supply as obtained by totalSupply()
	 * @param _withdrawalFee The current withdrawal fee as obtained by withdrawalFee()
	 * @return _grossShares The total amount of shares being deducted,
	 *                      including fees.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		return GFormulae._calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
	}

	/**
	 * @notice Allows for the beforehand calculation of the amount of
	 *         reserve token to be withdrawn given the desired amount of
	 *         shares.
	 * @param _grossShares The amount of this gToken shares to provide.
	 * @param _totalReserve The reserve balance as obtained by totalReserve().
	 * @param _totalSupply The shares supply as obtained by totalSupply().
	 * @param _withdrawalFee The current withdrawal fee as obtained by withdrawalFee().
	 * @return _cost The cost, in the reserve token, to be received.
	 * @return _feeShares The fee amount of shares being deducted.
	 */
	function calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return GFormulae._calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
	}

	/**
	 * @notice Provides the amount of reserve tokens currently being help by
	 *         this contract.
	 * @return _totalReserve The amount of the reserve token corresponding
	 *                       to this contract's balance.
	 */
	function totalReserve() public view override returns (uint256 _totalReserve)
	{
		return G.getBalance(reserveToken);
	}

	/**
	 * @notice Provides the current minting/deposit fee. This fee is
	 *         applied to the amount of this gToken shares being created
	 *         upon deposit. The fee defaults to 10%.
	 * @return _depositFee A percent value that accounts for the percentage
	 *                     of shares being minted at each deposit that be
	 *                     collected as fee.
	 */
	function depositFee() public view override returns (uint256 _depositFee) {
		return DEPOSIT_FEE;
	}

	/**
	 * @notice Provides the current burning/withdrawal fee. This fee is
	 *         applied to the amount of this gToken shares being redeemed
	 *         upon withdrawal. The fee defaults to 10%.
	 * @return _withdrawalFee A percent value that accounts for the
	 *                        percentage of shares being burned at each
	 *                        withdrawal that be collected as fee.
	 */
	function withdrawalFee() public view override returns (uint256 _withdrawalFee) {
		return WITHDRAWAL_FEE;
	}

	/**
	 * @notice Provides the number of votes a given candidate has at the end
	 *         of the previous voting interval. The interval is 24 hours
	 *         and resets at 12AM UTC. See _transferVotes().
	 * @param _candidate The candidate for which we want to know the number
	 *                   of delegated votes.
	 * @return _votes The candidate number of votes. It is the sum of the
	 *                balances of the voters that have him as cadidate at
	 *                the end of the previous voting interval.
	 */
	function votes(address _candidate) public view override returns (uint256 _votes)
	{
		uint256 _votingRound = block.timestamp.div(VOTING_ROUND_INTERVAL);
		// if the candidate balance was last updated the current round
		// uses the backup instead (position 1), otherwise uses the most
		// up-to-date balance (position 0)
		return voting[_candidate][votingRound[_candidate] < _votingRound ? 0 : 1];
	}

	/**
	 * @notice Performs the minting of gToken shares upon the deposit of the
	 *         reserve token. The actual number of shares being minted can
	 *         be calculated using the calcDepositSharesFromCost function.
	 *         In every deposit, 10% of the shares is retained in terms of
	 *         deposit fee. The fee amount and half of its equivalent
	 *         reserve amount are immediately burned. The funds will be
	 *         pulled in by this contract, therefore they must be previously
	 *         approved.
	 * @param _cost The amount of reserve token being deposited in the
	 *              operation.
	 */
	function deposit(uint256 _cost) public override nonReentrant
	{
		address _from = msg.sender;
		require(_cost > 0, "cost must be greater than 0");
		(uint256 _netShares, uint256 _feeShares) = GFormulae._calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "shares must be greater than 0");
		G.pullFunds(reserveToken, _from, _cost);
		_mint(_from, _netShares);
		_burnReserveFromShares(_feeShares.div(2));
	}

	/**
	 * @notice Performs the burning of gToken shares upon the withdrawal of
	 *         the reserve token. The actual amount of the reserve token to
	 *         be received can be calculated using the
	 *         calcWithdrawalCostFromShares function. In every withdrawal,
	 *         10% of the shares is retained in terms of withdrawal fee.
	 *         The fee amount and half of its equivalent reserve amount are
	 *         immediately burned.
	 * @param _grossShares The gross amount of this gToken shares being
	 *                     redeemed in the operation.
	 */
	function withdraw(uint256 _grossShares) public override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		require(_cost > 0, "cost must be greater than 0");
		_cost = G.min(_cost, G.getBalance(reserveToken));
		G.pushFunds(reserveToken, _from, _cost);
		_burn(_from, _grossShares);
		_burnReserveFromShares(_feeShares.div(2));
	}

	/**
	 * @notice Changes the voter's choice for candidate and vote delegation.
	 *         It is only going to be reflected in the voting by the next
	 *         interval. The interval is 24 hours and resets at 12AM UTC.
	 *         This function will emit a ChangeCandidate event.
	 * @param _newCandidate The new candidate chosen.
	 */
	function setCandidate(address _newCandidate) public override nonReentrant
	{
		address _voter = msg.sender;
		uint256 _votes = balanceOf(_voter);
		address _oldCandidate = candidate[_voter];
		candidate[_voter] = _newCandidate;
		_transferVotes(_oldCandidate, _newCandidate, _votes);
		emit ChangeCandidate(_voter, _oldCandidate, _newCandidate);
	}

	/**
	 * @dev Burns a given amount of shares worth of the reserve token.
	 *      See burnReserve().
	 * @param _grossShares The amount of shares for which the equivalent,
	 *                     in the reserve token, will be burned.
	 */
	function _burnReserveFromShares(uint256 _grossShares) internal
	{
		// we use the withdrawal formula to calculated how much is burned (withdrawn) from the contract
		// since the fee is 0 using the deposit formula would yield the same amount
		(uint256 _cost,) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), 0);
		_cost = G.min(_cost, G.getBalance(reserveToken));
		_burnReserve(_cost);
	}

	/**
	 * @dev Burns the given amount of the reserve token. The default behavior
	 *      of the function for general ERC-20 is to send the funds to
	 *      address(0), but that can be overriden by a subcontract.
	 * @param _reserveAmount The amount of the reserve token being burned.
	 */
	function _burnReserve(uint256 _reserveAmount) internal virtual
	{
		G.pushFunds(reserveToken, address(0), _reserveAmount);
	}

	/**
	 * @dev This hook is called whenever tokens are minted, burned and
	 *      transferred. This contract forbids token transfers by design.
	 *      Token minting and burning will be reflected in the additional
	 *      votes being credited or debited to the chosen candidate.
	 *      See _transferVotes().
	 * @param _from The provider of funds. Address 0 for minting.
	 * @param _to The receiver of funds. Address 0 for burning.
	 * @param _amount The amount being transfered.
	 */
	function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override
	{
		require(_from == address(0) || _to == address(0), "transfer prohibited");
		address _oldCandidate = candidate[_from];
		address _newCandidate = candidate[_to];
		uint256 _votes = _amount;
		_transferVotes(_oldCandidate, _newCandidate, _votes);
	}

	/**
	 * @dev Implements the vote transfer logic. It will deduct the votes
	 *      from one candidate and credit it to another candidate. If
	 *      either of candidates is the 0 address, the the voter is either
	 *      setting its initial candidate or abstaining himself from voting.
	 *      The change is only reflected after the voting interval resets.
	 *      We use a 2 element array to keep track of votes. The amount on
	 *      position 0 is always the current vote count for the candidate.
	 *      The amount on position 1 is a backup that reflect the vote count
	 *      prior to the current round only if it has been updated for the
	 *      current round. We also record the last voting round where the
	 *      candidate balance was updated. If the last round is the current
	 *      then we use the backup value on position 1, otherwise we use
	 *      the most up to date value on position 0. This function will
	 *      emit a ChangeVotes event upon candidate vote balance change.
	 *      See _updateVotes().
	 * @param _oldCandidate The candidate to deduct votes from.
	 * @param _newCandidate The candidate to credit voter for.
	 * @param _votes the number of votes being transfered.
	 */
	function _transferVotes(address _oldCandidate, address _newCandidate, uint256 _votes) internal
	{
		if (_votes == 0) return;
		if (_oldCandidate == _newCandidate) return;
		if (_oldCandidate != address(0)) {
			// position 0 always has the most up-to-date balance
			uint256 _oldVotes = voting[_oldCandidate][0];
			uint256 _newVotes = _oldVotes.sub(_votes);
			// updates position 0 backing up the previous amount
			_updateVotes(_oldCandidate, _newVotes);
			emit ChangeVotes(_oldCandidate, _oldVotes, _newVotes);
		}
		if (_newCandidate != address(0)) {
			// position 0 always has the most up-to-date balance
			uint256 _oldVotes = voting[_newCandidate][0];
			uint256 _newVotes = _oldVotes.add(_votes);
			// updates position 0 backing up the previous amount
			_updateVotes(_newCandidate, _newVotes);
			emit ChangeVotes(_newCandidate, _oldVotes, _newVotes);
		}
	}

	/**
	 * @dev Updates the candidate's current vote balance (position 0) and
	 *      backs up the vote balance for the previous interval (position 1).
	 *      The routine makes sure we do not overwrite and corrupt the
	 *      backup if multiple vote updates happen within a single roung.
	 *      See _transferVotes().
	 * @param _candidate The candidate for which we are updating the votes.
	 * @param _votes The candidate's new vote balance.
	 */
	function _updateVotes(address _candidate, uint256 _votes) internal
	{
		uint256 _votingRound = block.timestamp.div(VOTING_ROUND_INTERVAL);
		// if the candidates voting round is not the current it means
		// we are updating the voting balance for the first time in
		// the current round, that is the only time we want to make a
		// backup of the vote balance for the previous roung
		if (votingRound[_candidate] < _votingRound) {
			votingRound[_candidate] = _votingRound;
			// position 1 is the backup if there are updates in
			// the current round
			voting[_candidate][1] = voting[_candidate][0];
		}
		// position 0 always hold the up-to-date vote balance
		voting[_candidate][0] = _votes;
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { GTokenType0 } from "./GTokenType0.sol";
import { GCTokenType1 } from "./GCTokenType1.sol";
import { GCTokenType2 } from "./GCTokenType2.sol";
import { GTokenType3 } from "./GTokenType3.sol";

import { $ } from "./network/$.sol";

/**
 * @notice Definition of gDAI. As a gToken Type 0, it uses DAI as reserve and
 * distributes to other gToken types.
 */
contract gDAI is GTokenType0
{
	constructor ()
		GTokenType0("growth DAI", "gDAI", 18, $.GRO, $.DAI) public
	{
	}
}

/**
 * @notice Definition of gUSDC. As a gToken Type 0, it uses USDC as reserve and
 * distributes to other gToken types.
 */
contract gUSDC is GTokenType0
{
	constructor ()
		GTokenType0("growth USDC", "gUSDC", 6, $.GRO, $.USDC) public
	{
	}
}

/**
 * @notice Definition of gETH. As a gToken Type 0, it uses WETH as reserve and
 * distributes to other gToken types.
 */
contract gETH is GTokenType0
{
	constructor ()
		GTokenType0("growth ETH", "gETH", 18, $.GRO, $.WETH) public
	{
	}
}

/**
 * @notice Definition of gWBTC. As a gToken Type 0, it uses WBTC as reserve and
 * distributes to other gToken types.
 */
contract gWBTC is GTokenType0
{
	constructor ()
		GTokenType0("growth WBTC", "gWBTC", 8, $.GRO, $.WBTC) public
	{
	}
}

/**
 * @notice Definition of gcDAI. As a gcToken Type 1, it uses cDAI as reserve
 * and employs leverage to maximize returns.
 */
contract gcDAI is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cDAI", "gcDAI", 8, $.GRO, $.cDAI, $.COMP) public
	{
	}
}

/**
 * @notice Definition of gcUSDC. As a gcToken Type 1, it uses cUSDC as reserve
 * and employs leverage to maximize returns.
 */
contract gcUSDC is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cUSDC", "gcUSDC", 8, $.GRO, $.cUSDC, $.COMP) public
	{
	}
}

/**
 * @notice Definition of gcETH. As a gcToken Type 2, it uses cETH as reserve
 * which serves as collateral for minting gDAI.
 */
contract gcETH is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cETH", "gcETH", 8, $.GRO, $.cETH, $.COMP, $.cDAI, _growthToken) public
	{
	}

	receive() external payable {} // not to be used directly
}

/**
 * @notice Definition of gcWBTC. As a gcToken Type 2, it uses cWBTC as reserve
 * which serves as collateral for minting gDAI.
 */
contract gcWBTC is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cWBTC", "gcWBTC", 8, $.GRO, $.cWBTC, $.COMP, $.cDAI, _growthToken) public
	{
	}
}

/**
 * @notice Definition of stkGRO. As a gToken Type 3, it uses GRO as reserve and
 * burns both reserve and supply with each operation.
 */
contract stkGRO is GTokenType3
{
	constructor ()
		GTokenType3("staked MTC", "stkMTC", 18, $.GRO) public
	{
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @dev An interface to extend gTokens with voting delegation capabilities.
 *      See GTokenType3.sol for further documentation.
 */
interface GVoting
{
	// view functions
	function votes(address _candidate) external view returns (uint256 _votes);
	function candidate(address _voter) external view returns (address _candidate);

	// open functions
	function setCandidate(address _newCandidate) external;

	// emitted events
	event ChangeCandidate(address indexed _voter, address indexed _oldCandidate, address indexed _newCandidate);
	event ChangeVotes(address indexed _candidate, uint256 _oldVotes, uint256 _newVotes);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Minimal set of declarations for Aave interoperability.
 */
interface LendingPoolAddressesProvider
{
	function getLendingPool() external view returns (address _pool);
	function getLendingPoolCore() external view returns (address payable _lendingPoolCore);
	function getPriceOracle() external view returns (address _priceOracle);
}

interface LendingPool
{
	function getReserveConfigurationData(address _reserve) external view returns (uint256 _ltv, uint256 _liquidationThreshold, uint256 _liquidationBonus, address _interestRateStrategyAddress, bool _usageAsCollateralEnabled, bool _borrowingEnabled, bool _stableBorrowRateEnabled, bool _isActive);
	function getUserAccountData(address _user) external view returns (uint256 _totalLiquidityETH, uint256 _totalCollateralETH, uint256 _totalBorrowsETH, uint256 _totalFeesETH, uint256 _availableBorrowsETH, uint256 _currentLiquidationThreshold, uint256 _ltv, uint256 _healthFactor);
	function getUserReserveData(address _reserve, address _user) external view returns (uint256 _currentATokenBalance, uint256 _currentBorrowBalance, uint256 _principalBorrowBalance, uint256 _borrowRateMode, uint256 _borrowRate, uint256 _liquidityRate, uint256 _originationFee, uint256 _variableBorrowIndex, uint256 _lastUpdateTimestamp, bool _usageAsCollateralEnabled);
	function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
	function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;
	function repay(address _reserve, uint256 _amount, address payable _onBehalfOf) external payable;
	function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes calldata _params) external;
}

interface LendingPoolCore
{
	function getReserveDecimals(address _reserve) external view returns (uint256 _decimals);
	function getReserveAvailableLiquidity(address _reserve) external view returns (uint256 _availableLiquidity);
}

interface AToken is IERC20
{
	function underlyingAssetAddress() external view returns (address _underlyingAssetAddress);
	function redeem(uint256 _amount) external;
}

interface APriceOracle
{
	function getAssetPrice(address _asset) external view returns (uint256 _assetPrice);
}

interface FlashLoanReceiver
{
	function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Minimal set of declarations for Balancer interoperability.
 */
interface BFactory
{
	function newBPool() external returns (address _pool);
}

interface BPool is IERC20
{
	function getFinalTokens() external view returns (address[] memory _tokens);
	function getBalance(address _token) external view returns (uint256 _balance);
	function setSwapFee(uint256 _swapFee) external;
	function finalize() external;
	function bind(address _token, uint256 _balance, uint256 _denorm) external;
	function exitPool(uint256 _poolAmountIn, uint256[] calldata _minAmountsOut) external;
	function joinswapExternAmountIn(address _tokenIn, uint256 _tokenAmountIn, uint256 _minPoolAmountOut) external returns (uint256 _poolAmountOut);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Minimal set of declarations for Compound interoperability.
 */
interface Comptroller
{
	function oracle() external view returns (address _oracle);
	function enterMarkets(address[] calldata _ctokens) external returns (uint256[] memory _errorCodes);
	function markets(address _ctoken) external view returns (bool _isListed, uint256 _collateralFactorMantissa);
	function getAccountLiquidity(address _account) external view returns (uint256 _error, uint256 _liquidity, uint256 _shortfall);
}

interface CPriceOracle
{
	function getUnderlyingPrice(address _ctoken) external view returns (uint256 _price);
}

interface CToken is IERC20
{
	function underlying() external view returns (address _token);
	function exchangeRateStored() external view returns (uint256 _exchangeRate);
	function borrowBalanceStored(address _account) external view returns (uint256 _borrowBalance);
	function exchangeRateCurrent() external returns (uint256 _exchangeRate);
	function getCash() external view returns (uint256 _cash);
	function borrowBalanceCurrent(address _account) external returns (uint256 _borrowBalance);
	function balanceOfUnderlying(address _owner) external returns (uint256 _underlyingBalance);
	function mint() external payable;
	function mint(uint256 _mintAmount) external returns (uint256 _errorCode);
	function repayBorrow() external payable;
	function repayBorrow(uint256 _repayAmount) external returns (uint256 _errorCode);
	function redeemUnderlying(uint256 _redeemAmount) external returns (uint256 _errorCode);
	function borrow(uint256 _borrowAmount) external returns (uint256 _errorCode);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Minimal set of declarations for Dydx interoperability.
 */
interface SoloMargin
{
	function getMarketTokenAddress(uint256 _marketId) external view returns (address _token);
	function getNumMarkets() external view returns (uint256 _numMarkets);
	function operate(Account.Info[] memory _accounts, Actions.ActionArgs[] memory _actions) external;
}

interface ICallee
{
	function callFunction(address _sender, Account.Info memory _accountInfo, bytes memory _data) external;
}

library Account
{
	struct Info {
		address owner;
		uint256 number;
	}
}

library Actions
{
	enum ActionType { Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call }

	struct ActionArgs {
		ActionType actionType;
		uint256 accountId;
		Types.AssetAmount amount;
		uint256 primaryMarketId;
		uint256 secondaryMarketId;
		address otherAddress;
		uint256 otherAccountId;
		bytes data;
	}
}

library Types
{
	enum AssetDenomination { Wei, Par }
	enum AssetReference { Delta, Target }

	struct AssetAmount {
		bool sign;
		AssetDenomination denomination;
		AssetReference ref;
		uint256 value;
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

interface Enum
{
	enum Operation { Call, DelegateCall }
}

interface OwnerManager
{
	function getOwners() external view returns (address[] memory _owners);
	function isOwner(address _owner) external view returns (bool _isOwner);
}

interface ModuleManager
{
	function execTransactionFromModule(address _to, uint256 _value, bytes calldata _data, Enum.Operation _operation) external returns (bool _success);
}

interface Safe is OwnerManager, ModuleManager
{
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @dev Minimal set of declarations for Uniswap V2 interoperability.
 */
interface Router01
{
	function WETH() external pure returns (address _token);
	function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapETHForExactTokens(uint256 _amountOut, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
	function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint[] memory _amounts);
	function getAmountsIn(uint256 _amountOut, address[] calldata _path) external view returns (uint[] memory _amounts);
}

interface Router02 is Router01
{
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Minimal set of declarations for WETH interoperability.
 */
interface WETH is IERC20
{
	function deposit() external payable;
	function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Transfers } from "./Transfers.sol";

import { LendingPool, LendingPoolCore } from "../interop/Aave.sol";

import { $ } from "../network/$.sol";

/**
 * @dev This library abstracts the Aave flash loan functionality. It has a
 *      standardized flash loan interface. See GFlashBorrower.sol,
 *      FlashLoans.sol, and DydxFlashLoanAbstraction.sol for further documentation.
 */
library AaveFlashLoanAbstraction
{
	using SafeMath for uint256;

	uint256 constant FLASH_LOAN_FEE_RATIO = 9e14; // 0.09%

	/**
	 * @dev Estimates the flash loan fee given the reserve token and required amount.
	 * @param _token The ERC-20 token to flash borrow from.
	 * @param _netAmount The amount to be borrowed without considering repay fees.
	 * @param _feeAmount the expected fee to be payed in excees of the loan amount.
	 */
	function _estimateFlashLoanFee(address _token, uint256 _netAmount) internal pure returns (uint256 _feeAmount)
	{
		_token; // silences warnings
		return _netAmount.mul(FLASH_LOAN_FEE_RATIO).div(1e18);
	}

	/**
	 * @dev Retrieves the current market liquidity for a given reserve.
	 * @param _token The reserve token to flash borrow from.
	 * @return _liquidityAmount The reserve token available market liquidity.
	 */
	function _getFlashLoanLiquidity(address _token) internal view returns (uint256 _liquidityAmount)
	{
		address _core = $.Aave_AAVE_LENDING_POOL_CORE;
		return LendingPoolCore(_core).getReserveAvailableLiquidity(_token);
	}

	/**
	 * @dev Triggers a flash loan. The current contract will receive a call
	 *      back with the loan amount and should repay it, including fees,
	 *      before returning. See GFlashBorrow.sol.
	 * @param _token The reserve token to flash borrow from.
	 * @param _netAmount The amount to be borrowed without considering repay fees.
	 * @param _context Additional data to be passed to the call back.
	 * @return _success A boolean indicating whether or not the operation suceeded.
         */
	function _requestFlashLoan(address _token, uint256 _netAmount, bytes memory _context) internal returns (bool _success)
	{
		address _pool = $.Aave_AAVE_LENDING_POOL;
		try LendingPool(_pool).flashLoan(address(this), _token, _netAmount, _context) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	/**
	 * @dev This function should be called as the final step of the flash
	 *      loan to properly implement the repay of the loan.
	 * @param _token The reserve token.
	 * @param _grossAmount The amount to be repayed including repay fees.
	 */
	function _paybackFlashLoan(address _token, uint256 _grossAmount) internal
	{
		address _poolCore = $.Aave_AAVE_LENDING_POOL_CORE;
		Transfers._pushFunds(_token, _poolCore, _grossAmount);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Math } from "./Math.sol";
import { Transfers } from "./Transfers.sol";

import { BFactory, BPool } from "../interop/Balancer.sol";

import { $ } from "../network/$.sol";

/**
 * @dev This library abstracts the Balancer liquidity pool operations.
 */
library BalancerLiquidityPoolAbstraction
{
	using SafeMath for uint256;

	uint256 constant MIN_AMOUNT = 1e6; // transported from Balancer
	uint256 constant TOKEN0_WEIGHT = 25e18; // 25/50 = 50%
	uint256 constant TOKEN1_WEIGHT = 25e18; // 25/50 = 50%
	uint256 constant SWAP_FEE = 10e16; // 10%

	/**
	 * @dev Creates a two-asset liquidity pool and funds it by depositing
	 *      both assets. The create pool is public with a 50%/50%
	 *      distribution and 10% swap fee.
	 * @param _token0 The ERC-20 token for the first asset of the pair.
	 * @param _amount0 The amount of the first asset of the pair to be deposited.
	 * @param _token1 The ERC-20 token for the second asset of the pair.
	 * @param _amount1 The amount of the second asset of the pair to be deposited.
	 * @return _pool The address of the newly created pool.
	 */
	function _createPool(address _token0, uint256 _amount0, address _token1, uint256 _amount1) internal returns (address _pool)
	{
		require(_amount0 >= MIN_AMOUNT && _amount1 >= MIN_AMOUNT, "amount below the minimum");
		_pool = BFactory($.Balancer_FACTORY).newBPool();
		Transfers._approveFunds(_token0, _pool, _amount0);
		Transfers._approveFunds(_token1, _pool, _amount1);
		BPool(_pool).bind(_token0, _amount0, TOKEN0_WEIGHT);
		BPool(_pool).bind(_token1, _amount1, TOKEN1_WEIGHT);
		BPool(_pool).setSwapFee(SWAP_FEE);
		BPool(_pool).finalize();
		return _pool;
	}

	/**
	 * @dev Deposits a single asset into the liquidity pool.
	 * @param _pool The liquidity pool address.
	 * @param _token The ERC-20 token for the asset being deposited.
	 * @param _maxAmount The maximum amount to be deposited.
	 * @return _amount The actual amount deposited.
	 */
	function _joinPool(address _pool, address _token, uint256 _maxAmount) internal returns (uint256 _amount)
	{
		if (_maxAmount == 0) return 0;
		uint256 _balanceAmount = BPool(_pool).getBalance(_token);
		if (_balanceAmount == 0) return 0;
		// caps the deposit amount to half the liquidity to mitigate error
		uint256 _limitAmount = _balanceAmount.div(2);
		_amount = Math._min(_maxAmount, _limitAmount);
		Transfers._approveFunds(_token, _pool, _amount);
		BPool(_pool).joinswapExternAmountIn(_token, _amount, 0);
		return _amount;
	}

	/**
	 * @dev Withdraws a percentage of the pool shares.
	 * @param _pool The liquidity pool address.
	 * @param _percent The percent amount normalized to 1e18 (100%).
	 * @return _amount0 The amount received of the first asset of the pair.
	 * @return _amount1 The amount received of the second asset of the pair.
	 */
	function _exitPool(address _pool, uint256 _percent) internal returns (uint256 _amount0, uint256 _amount1)
	{
		if (_percent == 0) return (0, 0);
		address[] memory _tokens = BPool(_pool).getFinalTokens();
		_amount0 = Transfers._getBalance(_tokens[0]);
		_amount1 = Transfers._getBalance(_tokens[1]);
		uint256 _poolAmount = Transfers._getBalance(_pool);
		uint256 _poolExitAmount = _poolAmount.mul(_percent).div(1e18);
		uint256[] memory _minAmountsOut = new uint256[](2);
		_minAmountsOut[0] = 0;
		_minAmountsOut[1] = 0;
		BPool(_pool).exitPool(_poolExitAmount, _minAmountsOut);
		_amount0 = Transfers._getBalance(_tokens[0]).sub(_amount0);
		_amount1 = Transfers._getBalance(_tokens[1]).sub(_amount1);
		return (_amount0, _amount1);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Math } from "./Math.sol";
import { Wrapping } from "./Wrapping.sol";
import { Transfers } from "./Transfers.sol";

import { Comptroller, CPriceOracle, CToken } from "../interop/Compound.sol";

import { $ } from "../network/$.sol";

/**
 * @dev This library abstracts the Compound lending market. It has a standardized
 *      lending market interface. See AaveLendingMarket.sol.
 */
library CompoundLendingMarketAbstraction
{
	using SafeMath for uint256;

	/**
	 * @dev Retreives an underlying token given a cToken.
	 * @param _ctoken The Compound cToken address.
	 * @return _token The underlying reserve token.
	 */
	function _getUnderlyingToken(address _ctoken) internal view returns (address _token)
	{
		if (_ctoken == $.cETH) return $.WETH;
		return CToken(_ctoken).underlying();
	}

	/**
	 * @dev Retrieves the maximum collateralization ratio for a given cToken.
	 * @param _ctoken The Compound cToken address.
	 * @return _collateralRatio The percentual ratio normalized to 1e18 (100%).
	 */
	function _getCollateralRatio(address _ctoken) internal view returns (uint256 _collateralRatio)
	{
		address _comptroller = $.Compound_COMPTROLLER;
		(, _collateralRatio) = Comptroller(_comptroller).markets(_ctoken);
		return _collateralRatio;
	}

	/**
	 * @dev Retrieves the current market liquidity for a given cToken.
	 * @param _ctoken The Compound cToken address.
	 * @return _marketAmount The underlying reserve token available
	 *                       market liquidity.
	 */
	function _getMarketAmount(address _ctoken) internal view returns (uint256 _marketAmount)
	{
		return CToken(_ctoken).getCash();
	}

	/**
	 * @dev Retrieves the current account liquidity in terms of a cToken
	 *      underlying reserve.
	 * @param _ctoken The Compound cToken address.
	 * @return _liquidityAmount The available account liquidity for the
	 *                          underlying reserve token.
	 */
	function _getLiquidityAmount(address _ctoken) internal view returns (uint256 _liquidityAmount)
	{
		address _comptroller = $.Compound_COMPTROLLER;
		(uint256 _result, uint256 _liquidity, uint256 _shortfall) = Comptroller(_comptroller).getAccountLiquidity(address(this));
		if (_result != 0) return 0;
		if (_shortfall > 0) return 0;
		address _priceOracle = Comptroller(_comptroller).oracle();
		uint256 _price = CPriceOracle(_priceOracle).getUnderlyingPrice(_ctoken);
		return _liquidity.mul(1e18).div(_price);
	}

	/**
	 * @dev Retrieves the calculated account liquidity in terms of a cToken
	 *      underlying reserve. It also considers the current market liquidity.
	 *      A safety margin can be provided to deflate the actual liquidity amount.
	 * @param _ctoken The Compound cToken address.
	 * @param _marginAmount The safety room to be left in terms of the
	 *                      underlying reserve token.
	 * @return _availableAmount The safe available liquidity in terms of the
	 *                          underlying reserve token.
	 */
	function _getAvailableAmount(address _ctoken, uint256 _marginAmount) internal view returns (uint256 _availableAmount)
	{
		uint256 _liquidityAmount = _getLiquidityAmount(_ctoken);
		if (_liquidityAmount <= _marginAmount) return 0;
		return Math._min(_liquidityAmount.sub(_marginAmount), _getMarketAmount(_ctoken));
	}

	/**
	 * @dev Retrieves the last read-only exchange rate between the cToken
	 *      and its underlying reserve token.
	 * @param _ctoken The Compound cToken address.
	 * @return _exchangeRate The exchange rate between the cToken and its
	 *                       underlying reserve token.
	 */
	function _getExchangeRate(address _ctoken) internal view returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateStored();
	}

	/**
	 * @dev Retrieves the last up-to-date exchange rate between the cToken
	 *      and its underlying reserve token.
	 * @param _ctoken The Compound cToken address.
	 * @return _exchangeRate The exchange rate between the cToken and its
	 *                       underlying reserve token.
	 */
	function _fetchExchangeRate(address _ctoken) internal returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateCurrent();
	}

	/**
	 * @dev Retrieves the last read-only value for the cToken lending
	 *      balance in terms of its underlying reserve token.
	 * @param _ctoken The Compound cToken address.
	 * @return _amount The lending balance in terms of the underlying
	 *                 reserve token.
	 */
	function _getLendAmount(address _ctoken) internal view returns (uint256 _amount)
	{
		return CToken(_ctoken).balanceOf(address(this)).mul(_getExchangeRate(_ctoken)).div(1e18);
	}

	/**
	 * @dev Retrieves the last up-to-date value for the cToken lending
	 *      balance in terms of its underlying reserve token.
	 * @param _ctoken The Compound cToken address.
	 * @return _amount The lending balance in terms of the underlying
	 *                 reserve token.
	 */
	function _fetchLendAmount(address _ctoken) internal returns (uint256 _amount)
	{
		return CToken(_ctoken).balanceOfUnderlying(address(this));
	}

	/**
	 * @dev Retrieves the last read-only value for the cToken borrowing
	 *      balance in terms of its underlying reserve token.
	 * @param _ctoken The Compound cToken address.
	 * @return _amount The borrowing balance in terms of the underlying
	 *                 reserve token.
	 */
	function _getBorrowAmount(address _ctoken) internal view returns (uint256 _amount)
	{
		return CToken(_ctoken).borrowBalanceStored(address(this));
	}

	/**
	 * @dev Retrieves the last up-to-date value for the cToken borrowing
	 *      balance in terms of its underlying reserve token.
	 * @param _ctoken The Compound cToken address.
	 * @return _amount The borrowing balance in terms of the underlying
	 *                 reserve token.
	 */
	function _fetchBorrowAmount(address _ctoken) internal returns (uint256 _amount)
	{
		return CToken(_ctoken).borrowBalanceCurrent(address(this));
	}

	/**
	 * @dev Signals the usage of a given cToken underlying reserve as
	 *      collateral for borrowing funds in the lending market.
	 * @param _ctoken The Compound cToken address.
	 * @return _success A boolean indicating whether or not the operation suceeded.
	 */
	function _enter(address _ctoken) internal returns (bool _success)
	{
		address _comptroller = $.Compound_COMPTROLLER;
		address[] memory _ctokens = new address[](1);
		_ctokens[0] = _ctoken;
		try Comptroller(_comptroller).enterMarkets(_ctokens) returns (uint256[] memory _errorCodes) {
			return _errorCodes[0] == 0;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	/**
	 * @dev Lend funds to a given cToken's market.
	 * @param _ctoken The Compound cToken address.
	 * @param _amount The amount of the underlying token to lend.
	 * @return _success A boolean indicating whether or not the operation suceeded.
	 */
	function _lend(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		if (_ctoken == $.cETH) {
			if (!Wrapping._unwrap(_amount)) return false;
			try CToken(_ctoken).mint{value: _amount}() {
				return true;
			} catch (bytes memory /* _data */) {
				assert(Wrapping._wrap(_amount));
				return false;
			}
		} else {
			address _token = _getUnderlyingToken(_ctoken);
			Transfers._approveFunds(_token, _ctoken, _amount);
			try CToken(_ctoken).mint(_amount) returns (uint256 _errorCode) {
				return _errorCode == 0;
			} catch (bytes memory /* _data */) {
				Transfers._approveFunds(_token, _ctoken, 0);
				return false;
			}
		}
	}

	/**
	 * @dev Redeem funds lent to a given cToken's market.
	 * @param _ctoken The Compound cToken address.
	 * @param _amount The amount of the underlying token to redeem.
	 * @return _success A boolean indicating whether or not the operation suceeded.
	 */
	function _redeem(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		if (_ctoken == $.cETH) {
			try CToken(_ctoken).redeemUnderlying(_amount) returns (uint256 _errorCode) {
				if (_errorCode == 0) {
					assert(Wrapping._wrap(_amount));
					return true;
				} else {
					return false;
				}
			} catch (bytes memory /* _data */) {
				return false;
			}
		} else {
			try CToken(_ctoken).redeemUnderlying(_amount) returns (uint256 _errorCode) {
				return _errorCode == 0;
			} catch (bytes memory /* _data */) {
				return false;
			}
		}
	}

	/**
	 * @dev Borrow funds from a given cToken's market.
	 * @param _ctoken The Compound cToken address.
	 * @param _amount The amount of the underlying token to borrow.
	 * @return _success A boolean indicating whether or not the operation suceeded.
	 */
	function _borrow(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		if (_ctoken == $.cETH) {
			try CToken(_ctoken).borrow(_amount) returns (uint256 _errorCode) {
				if (_errorCode == 0) {
					assert(Wrapping._wrap(_amount));
					return true;
				} else {
					return false;
				}
			} catch (bytes memory /* _data */) {
				return false;
			}
		} else {
			try CToken(_ctoken).borrow(_amount) returns (uint256 _errorCode) {
				return _errorCode == 0;
			} catch (bytes memory /* _data */) {
				return false;
			}
		}
	}

	/**
	 * @dev Repays a loan taken from a given cToken's market.
	 * @param _ctoken The Compound cToken address.
	 * @param _amount The amount of the underlying token to repay.
	 * @return _success A boolean indicating whether or not the operation suceeded.
	 */
	function _repay(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		if (_ctoken == $.cETH) {
			if (!Wrapping._unwrap(_amount)) return false;
			try CToken(_ctoken).repayBorrow{value: _amount}() {
				return true;
			} catch (bytes memory /* _data */) {
				assert(Wrapping._wrap(_amount));
				return false;
			}
		} else {
			address _token = _getUnderlyingToken(_ctoken);
			Transfers._approveFunds(_token, _ctoken, _amount);
			try CToken(_ctoken).repayBorrow(_amount) returns (uint256 _errorCode) {
				return _errorCode == 0;
			} catch (bytes memory /* _data */) {
				Transfers._approveFunds(_token, _ctoken, 0);
				return false;
			}
		}
	}

	/**
	 * @dev Signals the usage of a given cToken underlying reserve as
	 *      collateral for borrowing funds in the lending market. This
	 *      operation will revert if it does not succeed.
	 * @param _ctoken The Compound cToken address.
	 */
	function _safeEnter(address _ctoken) internal
	{
		require(_enter(_ctoken), "enter failed");
	}

	/**
	 * @dev Lend funds to a given cToken's market. This
	 *      operation will revert if it does not succeed.
	 * @param _ctoken The Compound cToken address.
	 * @param _amount The amount of the underlying token to lend.
	 */
	function _safeLend(address _ctoken, uint256 _amount) internal
	{
		require(_lend(_ctoken, _amount), "lend failure");
	}

	/**
	 * @dev Redeem funds lent to a given cToken's market. This
	 *      operation will revert if it does not succeed.
	 * @param _ctoken The Compound cToken address.
	 * @param _amount The amount of the underlying token to redeem.
	 */
	function _safeRedeem(address _ctoken, uint256 _amount) internal
	{
		require(_redeem(_ctoken, _amount), "redeem failure");
	}

	/**
	 * @dev Borrow funds from a given cToken's market. This
	 *      operation will revert if it does not succeed.
	 * @param _ctoken The Compound cToken address.
	 * @param _amount The amount of the underlying token to borrow.
	 */
	function _safeBorrow(address _ctoken, uint256 _amount) internal
	{
		require(_borrow(_ctoken, _amount), "borrow failure");
	}

	/**
	 * @dev Repays a loan taken from a given cToken's market. This
	 *      operation will revert if it does not succeed.
	 * @param _ctoken The Compound cToken address.
	 * @param _amount The amount of the underlying token to repay.
	 */
	function _safeRepay(address _ctoken, uint256 _amount) internal
	{
		require(_repay(_ctoken, _amount), "repay failure");
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Transfers } from "./Transfers.sol";
import { UniswapV2ExchangeAbstraction } from "./UniswapV2ExchangeAbstraction.sol";

import { GExchange } from "../GExchange.sol";

import { $ } from "../network/$.sol";

library Conversions
{
	function _calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		if (_inputAmount == 0) return 0;
		return UniswapV2ExchangeAbstraction._calcConversionOutputFromInput(_from, _to, _inputAmount);
	}

	function _calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		if (_outputAmount == 0) return 0;
		return UniswapV2ExchangeAbstraction._calcConversionInputFromOutput(_from, _to, _outputAmount);
	}

	function _convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		if (_inputAmount == 0) {
			require(_minOutputAmount == 0, "insufficient output amount");
			return 0;
		}
		return UniswapV2ExchangeAbstraction._convertFunds(_from, _to, _inputAmount, _minOutputAmount);
	}

	function _dynamicConvertFunds(address _exchange, address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		Transfers._approveFunds(_from, _exchange, _inputAmount);
		try GExchange(_exchange).convertFunds(_from, _to, _inputAmount, _minOutputAmount) returns (uint256 _outAmount) {
			return _outAmount;
		} catch (bytes memory /* _data */) {
			Transfers._approveFunds(_from, _exchange, 0);
			return 0;
		}
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Transfers } from "./Transfers.sol";

import { SoloMargin, Account, Actions, Types } from "../interop/Dydx.sol";

import { $ } from "../network/$.sol";

/**
 * @dev This library abstracts the Dydx flash loan functionality. It has a
 *      standardized flash loan interface. See GFlashBorrower.sol,
 *      FlashLoans.sol, and AaveFlashLoanAbstraction.sol for further documentation.
 */
library DydxFlashLoanAbstraction
{
	using SafeMath for uint256;

	/**
	 * @dev Estimates the flash loan fee given the reserve token and required amount.
	 * @param _token The ERC-20 token to flash borrow from.
	 * @param _netAmount The amount to be borrowed without considering repay fees.
	 * @param _feeAmount the expected fee to be payed in excees of the loan amount.
	 */
	function _estimateFlashLoanFee(address _token, uint256 _netAmount) internal pure returns (uint256 _feeAmount)
	{
		_token; _netAmount; // silences warnings
		return 2; // dydx has no fees, 2 wei is just a recommendation
	}

	/**
	 * @dev Retrieves the current market liquidity for a given reserve.
	 * @param _token The reserve token to flash borrow from.
	 * @return _liquidityAmount The reserve token available market liquidity.
	 */
	function _getFlashLoanLiquidity(address _token) internal view returns (uint256 _liquidityAmount)
	{
		address _solo = $.Dydx_SOLO_MARGIN;
		return IERC20(_token).balanceOf(_solo);
	}

	/**
	 * @dev Triggers a flash loan. The current contract will receive a call
	 *      back with the loan amount and should repay it, including fees,
	 *      before returning. See GFlashBorrow.sol.
	 * @param _token The reserve token to flash borrow from.
	 * @param _netAmount The amount to be borrowed without considering repay fees.
	 * @param _context Additional data to be passed to the call back.
	 * @return _success A boolean indicating whether or not the operation suceeded.
         */
	function _requestFlashLoan(address _token, uint256 _netAmount, bytes memory _context) internal returns (bool _success)
	{
		address _solo = $.Dydx_SOLO_MARGIN;
		uint256 _feeAmount = 2;
		uint256 _grossAmount = _netAmount.add(_feeAmount);
		// attempts to find the market id given a reserve token
		uint256 _marketId = uint256(-1);
		uint256 _numMarkets = SoloMargin(_solo).getNumMarkets();
		for (uint256 _i = 0; _i < _numMarkets; _i++) {
			address _address = SoloMargin(_solo).getMarketTokenAddress(_i);
			if (_address == _token) {
				_marketId = _i;
				break;
			}
		}
		if (_marketId == uint256(-1)) return false;
		// a flash loan on Dydx is achieved by the following sequence of
		// actions: withdrawal, user call back, and finally a deposit;
		// which is configured below
		Account.Info[] memory _accounts = new Account.Info[](1);
		_accounts[0] = Account.Info({ owner: address(this), number: 1 });
		Actions.ActionArgs[] memory _actions = new Actions.ActionArgs[](3);
		_actions[0] = Actions.ActionArgs({
			actionType: Actions.ActionType.Withdraw,
			accountId: 0,
			amount: Types.AssetAmount({
				sign: false,
				denomination: Types.AssetDenomination.Wei,
				ref: Types.AssetReference.Delta,
				value: _netAmount
			}),
			primaryMarketId: _marketId,
			secondaryMarketId: 0,
			otherAddress: address(this),
			otherAccountId: 0,
			data: ""
		});
		_actions[1] = Actions.ActionArgs({
			actionType: Actions.ActionType.Call,
			accountId: 0,
			amount: Types.AssetAmount({
				sign: false,
				denomination: Types.AssetDenomination.Wei,
				ref: Types.AssetReference.Delta,
				value: 0
			}),
			primaryMarketId: 0,
			secondaryMarketId: 0,
			otherAddress: address(this),
			otherAccountId: 0,
			data: abi.encode(_token, _netAmount, _feeAmount, _context)
		});
		_actions[2] = Actions.ActionArgs({
			actionType: Actions.ActionType.Deposit,
			accountId: 0,
			amount: Types.AssetAmount({
				sign: true,
				denomination: Types.AssetDenomination.Wei,
				ref: Types.AssetReference.Delta,
				value: _grossAmount
			}),
			primaryMarketId: _marketId,
			secondaryMarketId: 0,
			otherAddress: address(this),
			otherAccountId: 0,
			data: ""
		});
		try SoloMargin(_solo).operate(_accounts, _actions) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	/**
	 * @dev This function should be called as the final step of the flash
	 *      loan to properly implement the repay of the loan.
	 * @param _token The reserve token.
	 * @param _grossAmount The amount to be repayed including repay fees.
	 */
	function _paybackFlashLoan(address _token, uint256 _grossAmount) internal
	{
		address _solo = $.Dydx_SOLO_MARGIN;
		Transfers._approveFunds(_token, _solo, _grossAmount);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Math } from "./Math.sol";
import { AaveFlashLoanAbstraction } from "./AaveFlashLoanAbstraction.sol";
import { DydxFlashLoanAbstraction } from "./DydxFlashLoanAbstraction.sol";

import { $ } from "../network/$.sol";

/**
 * @dev This library abstracts the flash loan request combining both Aave/Dydx.
 *      See GFlashBorrower.sol, AaveFlashLoanAbstraction.sol, and
 *      DydxFlashLoanAbstraction.sol for further documentation.
 */
library FlashLoans
{
	enum Provider { Aave, Dydx }

	/**
	 * @dev Estimates the flash loan fee given the reserve token and required amount.
	 * @param _provider The flash loan provider, either Aave or Dydx.
	 * @param _token The ERC-20 token to flash borrow from.
	 * @param _netAmount The amount to be borrowed without considering repay fees.
	 * @param _feeAmount the expected fee to be payed in excees of the loan amount.
	 */
	function _estimateFlashLoanFee(Provider _provider, address _token, uint256 _netAmount) internal pure returns (uint256 _feeAmount)
	{
		if (_provider == Provider.Aave) return AaveFlashLoanAbstraction._estimateFlashLoanFee(_token, _netAmount);
		if (_provider == Provider.Dydx) return DydxFlashLoanAbstraction._estimateFlashLoanFee(_token, _netAmount);
	}

	/**
	 * @dev Retrieves the maximum market liquidity for a given reserve on
	 *      both Aave and Dydx.
	 * @param _token The reserve token to flash borrow from.
	 * @return _liquidityAmount The reserve token available market liquidity.
	 */
	function _getFlashLoanLiquidity(address _token) internal view returns (uint256 _liquidityAmount)
	{
		uint256 _liquidityAmountDydx = 0;
		if ($.NETWORK == $.Network.Mainnet || $.NETWORK == $.Network.Kovan) {
			_liquidityAmountDydx = DydxFlashLoanAbstraction._getFlashLoanLiquidity(_token);
		}
		uint256 _liquidityAmountAave = 0;
		if ($.NETWORK == $.Network.Mainnet || $.NETWORK == $.Network.Ropsten || $.NETWORK == $.Network.Kovan) {
			_liquidityAmountAave = AaveFlashLoanAbstraction._getFlashLoanLiquidity(_token);
		}
		return Math._max(_liquidityAmountDydx, _liquidityAmountAave);
	}

	/**
	 * @dev Triggers a flash loan on Dydx and, if unsuccessful, on Aave.
	 *      The current contract will receive a call back with the loan
	 *      amount and should repay it, including fees, before returning.
	 *      See GFlashBorrow.sol.
	 * @param _token The reserve token to flash borrow from.
	 * @param _netAmount The amount to be borrowed without considering repay fees.
	 * @param _context Additional data to be passed to the call back.
	 * @return _success A boolean indicating whether or not the operation suceeded.
         */
	function _requestFlashLoan(address _token, uint256 _netAmount, bytes memory _context) internal returns (bool _success)
	{
		if ($.NETWORK == $.Network.Mainnet || $.NETWORK == $.Network.Kovan) {
			_success = DydxFlashLoanAbstraction._requestFlashLoan(_token, _netAmount, _context);
			if (_success) return true;
		}
		if ($.NETWORK == $.Network.Mainnet || $.NETWORK == $.Network.Ropsten || $.NETWORK == $.Network.Kovan) {
			_success = AaveFlashLoanAbstraction._requestFlashLoan(_token, _netAmount, _context);
			if (_success) return true;
		}
		return false;
	}

	/**
	 * @dev This function should be called as the final step of the flash
	 *      loan to properly implement the repay of the loan.
	 * @param _provider The flash loan provider, either Aave or Dydx.
	 * @param _token The reserve token.
	 * @param _grossAmount The amount to be repayed including repay fees.
	 */
	function _paybackFlashLoan(Provider _provider, address _token, uint256 _grossAmount) internal
	{
		if (_provider == Provider.Aave) return AaveFlashLoanAbstraction._paybackFlashLoan(_token, _grossAmount);
		if (_provider == Provider.Dydx) return DydxFlashLoanAbstraction._paybackFlashLoan(_token, _grossAmount);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @dev This library implements auxiliary math definitions.
 */
library Math
{
	function _min(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _minAmount)
	{
		return _amount1 < _amount2 ? _amount1 : _amount2;
	}

	function _max(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _maxAmount)
	{
		return _amount1 > _amount2 ? _amount1 : _amount2;
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Enum, Safe } from "../interop/Gnosis.sol";

/**
 * @dev This library abstracts the Gnosis Safe multisig operations.
 */
library Multisig
{
	/**
	 * @dev Lists the current owners/signers of a Gnosis Safe multisig.
	 * @param _safe The Gnosis Safe contract address.
	 * @return _owners The list of current owners/signers of the multisig.
	 */
	function _getOwners(address _safe) internal view returns (address[] memory _owners)
	{
		return Safe(_safe).getOwners();
	}

	/**
	 * @dev Checks if an address is a signer of the Gnosis Safe multisig.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _owner The address to check if it is a owner/signer of the multisig.
	 * @return _isOnwer A boolean indicating if the provided address is
	 *                  indeed a signer.
	 */
	function _isOwner(address _safe, address _owner) internal view returns (bool _isOnwer)
	{
		return Safe(_safe).isOwner(_owner);
	}

	/**
	 * @dev Adds a signer to the multisig by calling the Gnosis Safe function
	 *      addOwnerWithThreshold() via the execTransactionFromModule()
	 *      primitive.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _owner The owner/signer to be added to the multisig.
	 * @param _threshold The new threshold (minimum number of signers) to be set.
	 * @return _success A boolean indicating if the operation succeded.
	 */
	function _addOwnerWithThreshold(address _safe, address _owner, uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", _owner, _threshold);
		return _execTransactionFromModule(_safe, _data);
	}

	/**
	 * @dev Removes a signer to the multisig by calling the Gnosis Safe function
	 *      removeOwner() via the execTransactionFromModule()
	 *      primitive.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _prevOwner The previous owner/signer in the multisig linked list.
	 * @param _owner The owner/signer to be added to the multisig.
	 * @param _threshold The new threshold (minimum number of signers) to be set.
	 * @return _success A boolean indicating if the operation succeded.
	 */
	function _removeOwner(address _safe, address _prevOwner, address _owner, uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("removeOwner(address,address,uint256)", _prevOwner, _owner, _threshold);
		return _execTransactionFromModule(_safe, _data);
	}

	/**
	 * @dev Changes minimum number of signers of the multisig by calling the
	 *      Gnosis Safe function changeThreshold() via the
	 *      execTransactionFromModule() primitive.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _threshold The new threshold (minimum number of signers) to be set.
	 * @return _success A boolean indicating if the operation succeded.
	 */
	function _changeThreshold(address _safe, uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("changeThreshold(uint256)", _threshold);
		return _execTransactionFromModule(_safe, _data);
	}

	/**
	 * @dev Calls the execTransactionFrom() module primitive handling
	 *      possible errors.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _data The encoded data describing the function signature and
	 *              argument values.
	 * @return _success A boolean indicating if the operation succeded.
	 */
	function _execTransactionFromModule(address _safe, bytes memory _data) internal returns (bool _success)
	{
		try Safe(_safe).execTransactionFromModule(_safe, 0, _data, Enum.Operation.Call) returns (bool _result) {
			return _result;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @dev This library abstracts ERC-20 operations.
 */
library Transfers
{
	using SafeERC20 for IERC20;

	/**
	 * @dev Retrieves a given ERC-20 token balance for the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @return _balance The current contract balance of the given ERC-20 token.
	 */
	function _getBalance(address _token) internal view returns (uint256 _balance)
	{
		return IERC20(_token).balanceOf(address(this));
	}

	/**
	 * @dev Allows a spender to access a given ERC-20 balance for the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _to The spender address.
	 * @param _amount The exact spending allowance amount.
	 */
	function _approveFunds(address _token, address _to, uint256 _amount) internal
	{
		uint256 _allowance = IERC20(_token).allowance(address(this), _to);
		if (_allowance > _amount) {
			IERC20(_token).safeDecreaseAllowance(_to, _allowance - _amount);
		}
		else
		if (_allowance < _amount) {
			IERC20(_token).safeIncreaseAllowance(_to, _amount - _allowance);
		}
	}

	/**
	 * @dev Transfer a given ERC-20 token amount into the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _from The source address.
	 * @param _amount The amount to be transferred.
	 */
	function _pullFunds(address _token, address _from, uint256 _amount) internal
	{
		if (_amount == 0) return;
		IERC20(_token).safeTransferFrom(_from, address(this), _amount);
	}

	/**
	 * @dev Transfer a given ERC-20 token amount from the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _to The target address.
	 * @param _amount The amount to be transferred.
	 */
	function _pushFunds(address _token, address _to, uint256 _amount) internal
	{
		if (_amount == 0) return;
		IERC20(_token).safeTransfer(_to, _amount);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Transfers } from "./Transfers.sol";

import { Router02 } from "../interop/UniswapV2.sol";

import { $ } from "../network/$.sol";

/**
 * @dev This library abstracts the Uniswap V2 token conversion functionality.
 */
library UniswapV2ExchangeAbstraction
{
	/**
	 * @dev Calculates how much output to be received from the given input
	 *      when converting between two assets.
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _inputAmount The input asset amount to be provided.
	 * @return _outputAmount The output asset amount to be received.
	 */
	function _calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		address _router = $.UniswapV2_ROUTER02;
		address _WETH = Router02(_router).WETH();
		address[] memory _path = _buildPath(_from, _WETH, _to);
		return Router02(_router).getAmountsOut(_inputAmount, _path)[_path.length - 1];
	}

	/**
	 * @dev Calculates how much input to be received the given the output
	 *      when converting between two assets.
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _outputAmount The output asset amount to be received.
	 * @return _inputAmount The input asset amount to be provided.
	 */
	function _calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		address _router = $.UniswapV2_ROUTER02;
		address _WETH = Router02(_router).WETH();
		address[] memory _path = _buildPath(_from, _WETH, _to);
		return Router02(_router).getAmountsIn(_outputAmount, _path)[0];
	}

	/**
	 * @dev Convert funds between two assets.
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _inputAmount The input asset amount to be provided.
	 * @param _minOutputAmount The output asset minimum amount to be received.
	 * @return _outputAmount The output asset amount received.
	 */
	function _convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		address _router = $.UniswapV2_ROUTER02;
		address _WETH = Router02(_router).WETH();
		address[] memory _path = _buildPath(_from, _WETH, _to);
		Transfers._approveFunds(_from, _router, _inputAmount);
		return Router02(_router).swapExactTokensForTokens(_inputAmount, _minOutputAmount, _path, address(this), uint256(-1))[_path.length - 1];
	}

	/**
	 * @dev Builds a routing path for conversion using WETH as intermediate.
	 *      Deals with the special case where WETH is also the input or the
	 *      output asset.
	 * @param _from The input asset address.
	 * @param _WETH The Wrapped Ether address.
	 * @param _to The output asset address.
	 * @return _path The route to perform conversion.
	 */
	function _buildPath(address _from, address _WETH, address _to) internal pure returns (address[] memory _path)
	{
		if (_from == _WETH || _to == _WETH) {
			_path = new address[](2);
			_path[0] = _from;
			_path[1] = _to;
			return _path;
		} else {
			_path = new address[](3);
			_path[0] = _from;
			_path[1] = _WETH;
			_path[2] = _to;
			return _path;
		}
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { WETH } from "../interop/WrappedEther.sol";

import { $ } from "../network/$.sol";

/**
 * @dev This library abstracts Wrapped Ether operations.
 */
library Wrapping
{
	/**
	 * @dev Sends some ETH to the Wrapped Ether contract in exchange for WETH.
	 * @param _amount The amount of ETH to be wrapped in WETH.
	 * @return _success A boolean indicating whether or not the operation suceeded.
	 */
	function _wrap(uint256 _amount) internal returns (bool _success)
	{
		try WETH($.WETH).deposit{value: _amount}() {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	/**
	 * @dev Receives some ETH from the Wrapped Ether contract in exchange for WETH.
	 *      Note that the contract using this library function must declare a
	 *      payable receive/fallback function.
	 * @param _amount The amount of ETH to be wrapped in WETH.
	 * @return _success A boolean indicating whether or not the operation suceeded.
	 */
	function _unwrap(uint256 _amount) internal returns (bool _success)
	{
		try WETH($.WETH).withdraw(_amount) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	/**
	 * @dev Sends some ETH to the Wrapped Ether contract in exchange for WETH.
	 *      This operation will revert if it does not succeed.
	 * @param _amount The amount of ETH to be wrapped in WETH.
	 */
	function _safeWrap(uint256 _amount) internal
	{
		require(_wrap(_amount), "wrap failed");
	}

	/**
	 * @dev Receives some ETH from the Wrapped Ether contract in exchange for WETH.
	 *      This operation will revert if it does not succeed. Note that
	 *      the contract using this library function must declare a payable
	 *      receive/fallback function.
	 * @param _amount The amount of ETH to be wrapped in WETH.
	 */
	function _safeUnwrap(uint256 _amount) internal
	{
		require(_unwrap(_amount), "unwrap failed");
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @dev This library is provided for conveniece. It is the single source for
 *      the current network and all related hardcoded contract addresses. It
 *      also provide useful definitions for debuging faultless code via events.
 */
library $
{
	enum Network { Mainnet, Ropsten, Rinkeby, Kovan, Goerli }

	Network constant NETWORK = Network.Mainnet;

	bool constant DEBUG = NETWORK != Network.Mainnet;

	function debug(string memory _message) internal
	{
		address _from = msg.sender;
		if (DEBUG) emit Debug(_from, _message);
	}

	function debug(string memory _message, uint256 _value) internal
	{
		address _from = msg.sender;
		if (DEBUG) emit Debug(_from, _message, _value);
	}

	function debug(string memory _message, address _address) internal
	{
		address _from = msg.sender;
		if (DEBUG) emit Debug(_from, _message, _address);
	}

	event Debug(address indexed _from, string _message);
	event Debug(address indexed _from, string _message, uint256 _value);
	event Debug(address indexed _from, string _message, address _address);

	address constant stkGRO =
		NETWORK == Network.Mainnet ? 0xD93f98b483CC2F9EFE512696DF8F5deCB73F9497 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		NETWORK == Network.Rinkeby ? 0x437664B64b88fDe761c54b3ab1568dA4227757fc :
		NETWORK == Network.Kovan ? 0x760FbB334dbbc15B9774e3d9fA0def86C0A6e7Af :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant GRO =
		NETWORK == Network.Mainnet ? 0x0813977D72b7a63bFa2f37A5037714B3c5CbfA0a :
		NETWORK == Network.Ropsten ? 0x5BaF82B5Eddd5d64E03509F0a7dBa4Cbf88CF455 :
		//NETWORK == Network.Rinkeby ? 0x020e317e70B406E23dF059F3656F6fc419411401 :
		NETWORK == Network.Rinkeby ? 0x0813977D72b7a63bFa2f37A5037714B3c5CbfA0a :
		NETWORK == Network.Kovan ? 0xFcB74f30d8949650AA524d8bF496218a20ce2db4 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant DAI =
		NETWORK == Network.Mainnet ? 0x6B175474E89094C44Da98b954EedeAC495271d0F :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant USDC =
		NETWORK == Network.Mainnet ? 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant USDT =
		NETWORK == Network.Mainnet ? 0xdAC17F958D2ee523a2206206994597C13D831ec7 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant SUSD =
		NETWORK == Network.Mainnet ? 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant TUSD =
		NETWORK == Network.Mainnet ? 0x0000000000085d4780B73119b644AE5ecd22b376 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant BUSD =
		NETWORK == Network.Mainnet ? 0x4Fabb145d64652a948d72533023f6E7A623C7C53 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant WBTC =
		NETWORK == Network.Mainnet ? 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant WETH =
		NETWORK == Network.Mainnet ? 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 :
		NETWORK == Network.Ropsten ? 0xc778417E063141139Fce010982780140Aa0cD5Ab :
		NETWORK == Network.Rinkeby ? 0xc778417E063141139Fce010982780140Aa0cD5Ab :
		NETWORK == Network.Kovan ? 0xd0A1E359811322d97991E03f863a0C30C2cF029C :
		NETWORK == Network.Goerli ? 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 :
		0x0000000000000000000000000000000000000000;

	address constant BAT =
		NETWORK == Network.Mainnet ? 0x0D8775F648430679A709E98d2b0Cb6250d2887EF :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant ENJ =
		NETWORK == Network.Mainnet ? 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant KNC =
		NETWORK == Network.Mainnet ? 0xdd974D5C2e2928deA5F71b9825b8b646686BD200 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant AAVE =
		NETWORK == Network.Mainnet ? 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant LEND =
		NETWORK == Network.Mainnet ? 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant LINK =
		NETWORK == Network.Mainnet ? 0x514910771AF9Ca656af840dff83E8264EcF986CA :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant MANA =
		NETWORK == Network.Mainnet ? 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant MKR =
		NETWORK == Network.Mainnet ? 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant REN =
		NETWORK == Network.Mainnet ? 0x408e41876cCCDC0F92210600ef50372656052a38 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant REP =
		NETWORK == Network.Mainnet ? 0x1985365e9f78359a9B6AD760e32412f4a445E862 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant SNX =
		NETWORK == Network.Mainnet ? 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant ZRX =
		NETWORK == Network.Mainnet ? 0xE41d2489571d322189246DaFA5ebDe1F4699F498 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant UNI =
		NETWORK == Network.Mainnet ? 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant YFI =
		NETWORK == Network.Mainnet ? 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant cDAI =
		NETWORK == Network.Mainnet ? 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643 :
		NETWORK == Network.Ropsten ? 0xdb5Ed4605C11822811a39F94314fDb8F0fb59A2C :
		NETWORK == Network.Rinkeby ? 0x6D7F0754FFeb405d23C51CE938289d4835bE3b14 :
		NETWORK == Network.Kovan ? 0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD :
		NETWORK == Network.Goerli ? 0x822397d9a55d0fefd20F5c4bCaB33C5F65bd28Eb :
		0x0000000000000000000000000000000000000000;

	address constant cUSDC =
		NETWORK == Network.Mainnet ? 0x39AA39c021dfbaE8faC545936693aC917d5E7563 :
		NETWORK == Network.Ropsten ? 0x8aF93cae804cC220D1A608d4FA54D1b6ca5EB361 :
		NETWORK == Network.Rinkeby ? 0x5B281A6DdA0B271e91ae35DE655Ad301C976edb1 :
		NETWORK == Network.Kovan ? 0x4a92E71227D294F041BD82dd8f78591B75140d63 :
		NETWORK == Network.Goerli ? 0xCEC4a43eBB02f9B80916F1c718338169d6d5C1F0 :
		0x0000000000000000000000000000000000000000;

	address constant cUSDT =
		NETWORK == Network.Mainnet ? 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9 :
		NETWORK == Network.Ropsten ? 0x135669c2dcBd63F639582b313883F101a4497F76 :
		NETWORK == Network.Rinkeby ? 0x2fB298BDbeF468638AD6653FF8376575ea41e768 :
		NETWORK == Network.Kovan ? 0x3f0A0EA2f86baE6362CF9799B523BA06647Da018 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant cETH =
		NETWORK == Network.Mainnet ? 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5 :
		NETWORK == Network.Ropsten ? 0xBe839b6D93E3eA47eFFcCA1F27841C917a8794f3 :
		NETWORK == Network.Rinkeby ? 0xd6801a1DfFCd0a410336Ef88DeF4320D6DF1883e :
		NETWORK == Network.Kovan ? 0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72 :
		NETWORK == Network.Goerli ? 0x20572e4c090f15667cF7378e16FaD2eA0e2f3EfF :
		0x0000000000000000000000000000000000000000;

	address constant cWBTC =
		NETWORK == Network.Mainnet ? 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4 :
		NETWORK == Network.Ropsten ? 0x58145Bc5407D63dAF226e4870beeb744C588f149 :
		NETWORK == Network.Rinkeby ? 0x0014F450B8Ae7708593F4A46F8fa6E5D50620F96 :
		NETWORK == Network.Kovan ? 0xa1fAA15655B0e7b6B6470ED3d096390e6aD93Abb :
		NETWORK == Network.Goerli ? 0x6CE27497A64fFFb5517AA4aeE908b1E7EB63B9fF :
		0x0000000000000000000000000000000000000000;

	address constant cBAT =
		NETWORK == Network.Mainnet ? 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E :
		NETWORK == Network.Ropsten ? 0x9E95c0b2412cE50C37a121622308e7a6177F819D :
		NETWORK == Network.Rinkeby ? 0xEBf1A11532b93a529b5bC942B4bAA98647913002 :
		NETWORK == Network.Kovan ? 0x4a77fAeE9650b09849Ff459eA1476eaB01606C7a :
		NETWORK == Network.Goerli ? 0xCCaF265E7492c0d9b7C2f0018bf6382Ba7f0148D :
		0x0000000000000000000000000000000000000000;

	address constant cZRX =
		NETWORK == Network.Mainnet ? 0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407 :
		NETWORK == Network.Ropsten ? 0x00e02a5200CE3D5b5743F5369Deb897946C88121 :
		NETWORK == Network.Rinkeby ? 0x52201ff1720134bBbBB2f6BC97Bf3715490EC19B :
		NETWORK == Network.Kovan ? 0xAf45ae737514C8427D373D50Cd979a242eC59e5a :
		NETWORK == Network.Goerli ? 0xA253295eC2157B8b69C44b2cb35360016DAa25b1 :
		0x0000000000000000000000000000000000000000;

	address constant cUNI =
		NETWORK == Network.Mainnet ? 0x35A18000230DA775CAc24873d00Ff85BccdeD550 :
		NETWORK == Network.Ropsten ? 0x22531F0f3a9c36Bfc3b04c4c60df5168A1cFCec3 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant cCOMP =
		NETWORK == Network.Mainnet ? 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4 :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant COMP =
		NETWORK == Network.Mainnet ? 0xc00e94Cb662C3520282E6f5717214004A7f26888 :
		NETWORK == Network.Ropsten ? 0x1Fe16De955718CFAb7A44605458AB023838C2793 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		NETWORK == Network.Kovan ? 0x61460874a7196d6a22D1eE4922473664b3E95270 :
		NETWORK == Network.Goerli ? 0xe16C7165C8FeA64069802aE4c4c9C320783f2b6e :
		0x0000000000000000000000000000000000000000;

	address constant Aave_AAVE_LENDING_POOL_ADDRESSES_PROVIDER =
		NETWORK == Network.Mainnet ? 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8 :
		NETWORK == Network.Ropsten ? 0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		NETWORK == Network.Kovan ? 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant Aave_AAVE_LENDING_POOL =
		NETWORK == Network.Mainnet ? 0x398eC7346DcD622eDc5ae82352F02bE94C62d119 :
		NETWORK == Network.Ropsten ? 0x9E5C7835E4b13368fd628196C4f1c6cEc89673Fa :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		NETWORK == Network.Kovan ? 0x580D4Fdc4BF8f9b5ae2fb9225D584fED4AD5375c :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant Aave_AAVE_LENDING_POOL_CORE =
		NETWORK == Network.Mainnet ? 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3 :
		NETWORK == Network.Ropsten ? 0x4295Ee704716950A4dE7438086d6f0FBC0BA9472 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		NETWORK == Network.Kovan ? 0x95D1189Ed88B380E319dF73fF00E479fcc4CFa45 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant Balancer_FACTORY =
		NETWORK == Network.Mainnet ? 0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		NETWORK == Network.Rinkeby ? 0x9C84391B443ea3a48788079a5f98e2EaD55c9309 :
		NETWORK == Network.Kovan ? 0x8f7F78080219d4066A8036ccD30D588B416a40DB :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant Compound_COMPTROLLER =
		NETWORK == Network.Mainnet ? 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B :
		NETWORK == Network.Ropsten ? 0x54188bBeDD7b68228fa89CbDDa5e3e930459C6c6 :
		NETWORK == Network.Rinkeby ? 0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb :
		NETWORK == Network.Kovan ? 0x5eAe89DC1C671724A672ff0630122ee834098657 :
		NETWORK == Network.Goerli ? 0x627EA49279FD0dE89186A58b8758aD02B6Be2867 :
		0x0000000000000000000000000000000000000000;

	address constant Dydx_SOLO_MARGIN =
		NETWORK == Network.Mainnet ? 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		NETWORK == Network.Kovan ? 0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant Sushiswap_ROUTER02 =
		NETWORK == Network.Mainnet ? 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F :
		// NETWORK == Network.Ropsten ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Rinkeby ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Kovan ? 0x0000000000000000000000000000000000000000 :
		// NETWORK == Network.Goerli ? 0x0000000000000000000000000000000000000000 :
		0x0000000000000000000000000000000000000000;

	address constant UniswapV2_ROUTER02 =
		NETWORK == Network.Mainnet ? 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D :
		NETWORK == Network.Ropsten ? 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D :
		NETWORK == Network.Rinkeby ? 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D :
		NETWORK == Network.Kovan ? 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D :
		NETWORK == Network.Goerli ? 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D :
		0x0000000000000000000000000000000000000000;
}

