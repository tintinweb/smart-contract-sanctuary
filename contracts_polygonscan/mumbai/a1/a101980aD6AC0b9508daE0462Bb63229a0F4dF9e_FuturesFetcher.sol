// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
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

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface BColor {
    function getColor() external view returns (bytes32);
}

contract BBronze is BColor {
    function getColor() external pure override returns (bytes32) {
        return bytes32("BRONZE");
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BColor.sol";

contract BConst is BBronze {
    uint256 public constant BONE = 10**18;

    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 8;

    uint256 public constant MIN_FEE = BONE / 10**6;
    uint256 public constant MAX_FEE = BONE / 10;
    uint256 public constant EXIT_FEE = 0;

    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint256 public constant MIN_BALANCE = BONE / 10**12;

    uint256 public constant INIT_POOL_SUPPLY = BONE * 100;

    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 10**10;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

import "./BPool.sol";

contract BFactory is BBronze {
    event LOG_NEW_POOL(address indexed caller, address indexed pool);

    event LOG_BLABS(address indexed caller, address indexed blabs);

    mapping(address => bool) private _isBPool;

    function isBPool(address b) external view returns (bool) {
        return _isBPool[b];
    }

    function newBPool() external returns (BPool) {
        BPool bpool = new BPool();
        _isBPool[address(bpool)] = true;
        emit LOG_NEW_POOL(msg.sender, address(bpool));
        bpool.setController(msg.sender);
        return bpool;
    }

    address private _blabs;

    constructor() {
        _blabs = msg.sender;
    }

    function getBLabs() external view returns (address) {
        return _blabs;
    }

    function setBLabs(address b) external {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        emit LOG_BLABS(msg.sender, b);
        _blabs = b;
    }

    function collect(BPool pool) external {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        uint256 collected = IERC20Balancer(pool).balanceOf(address(this));
        bool xfer = pool.transfer(_blabs, collected);
        require(xfer, "ERR_ERC20_FAILED");
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BNum.sol";

contract BMath is BBronze, BConst, BNum {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint256 ratio = bdiv(numer, denom);
        uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
        return (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint256 adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint256 foo = bpow(y, weightRatio);
        uint256 bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint256 y = bdiv(tokenBalanceOut, diff);
        uint256 foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        tokenAmountIn = bsub(BONE, swapFee);
        tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/

    // Charge the trading fee for the proportion of tokenAi
    ///  which is implicitly traded to the other pool tokens.
    // That proportion is (1- weightTokenIn)
    // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountOut) {
        uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

        uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint256 newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
        uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint256 boo = bdiv(BONE, normalizedWeight);
        uint256 tokenInRatio = bpow(poolRatio, boo);
        uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
        uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint256 tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountIn) {
        // charge swap fee on the output token side
        uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint256 zoo = bsub(BONE, normalizedWeight);
        uint256 zar = bmul(zoo, swapFee);
        uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

        uint256 newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint256 newPoolSupply = bmul(poolRatio, poolSupply);
        uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
        return poolAmountIn;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BConst.sol";

contract BNum is BConst {
    function btoi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function bfloor(uint256 a) internal pure returns (uint256) {
        return btoi(a) * BONE;
    }

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = bsubSign(base, BONE);
        uint256 term = BONE;
        uint256 sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BToken.sol";
import "./BMath.sol";

contract BPool is BBronze, BToken, BMath {
    struct Record {
        bool bound; // is token bound to pool
        uint256 index; // private
        uint256 denorm; // denormalized weight
        uint256 balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);

    event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);

    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    bool private _mutex;

    address private _factory; // BFactory address to push token exitFee to
    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint256 private _swapFee;
    bool private _finalized;

    address[] private _tokens;
    mapping(address => Record) private _records;
    uint256 private _totalWeight;

    constructor() {
        _controller = msg.sender;
        _factory = msg.sender;
        _swapFee = MIN_FEE;
        _publicSwap = false;
        _finalized = false;
    }

    function isPublicSwap() external view returns (bool) {
        return _publicSwap;
    }

    function isFinalized() external view returns (bool) {
        return _finalized;
    }

    function isBound(address t) external view returns (bool) {
        return _records[t].bound;
    }

    function getNumTokens() external view returns (uint256) {
        return _tokens.length;
    }

    function getCurrentTokens() external view _viewlock_ returns (address[] memory tokens) {
        return _tokens;
    }

    function getFinalTokens() external view _viewlock_ returns (address[] memory tokens) {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token) external view _viewlock_ returns (uint256) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight() external view _viewlock_ returns (uint256) {
        return _totalWeight;
    }

    function getNormalizedWeight(address token) external view _viewlock_ returns (uint256) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        uint256 denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }

    function getBalance(address token) external view _viewlock_ returns (uint256) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee() external view _viewlock_ returns (uint256) {
        return _swapFee;
    }

    function getController() external view _viewlock_ returns (address) {
        return _controller;
    }

    function setSwapFee(uint256 swapFee) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
    }

    function setController(address manager) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _controller = manager;
    }

    function setPublicSwap(bool public_) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _publicSwap = public_;
    }

    function finalize() external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    )
        external
        _logs_ // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0, // balance and denorm will be validated
            balance: 0 // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) public _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint256 oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        } else if (denorm < oldWeight) {
            _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint256 oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, so charge EXIT_FEE
            uint256 tokenBalanceWithdrawn = bsub(oldBalance, balance);
            uint256 tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
            _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
            _pushUnderlying(token, _factory, tokenExitFee);
        }
    }

    function unbind(address token) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        uint256 tokenBalance = _records[token].balance;
        uint256 tokenExitFee = bmul(tokenBalance, EXIT_FEE);

        _totalWeight = bsub(_totalWeight, _records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint256 index = _records[token].index;
        uint256 last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({bound: false, index: 0, denorm: 0, balance: 0});

        _pushUnderlying(token, msg.sender, bsub(tokenBalance, tokenExitFee));
        _pushUnderlying(token, _factory, tokenExitFee);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token) external _logs_ _lock_ {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20Balancer(token).balanceOf(address(this));
    }

    function getSpotPrice(address tokenIn, address tokenOut) external view _viewlock_ returns (uint256 spotPrice) {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external
        view
        _viewlock_
        returns (uint256 spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
    }

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external _logs_ _lock_ {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint256 poolTotal = totalSupply();
        uint256 ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external _logs_ _lock_ {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint256 poolTotal = totalSupply();
        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_factory, exitFee);
        _burnPoolShare(pAiAfterExitFee);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    function calcExitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external
        view
        returns (uint256[] memory)
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint256 poolTotal = totalSupply();
        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);

        uint256[] memory _amounts = new uint256[](_tokens.length * 2);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;

            _amounts[i] = bmul(ratio, bal);
            _amounts[_tokens.length + i] = minAmountsOut[i];
            require(_amounts[i] >= minAmountsOut[i], "ERR_LIMIT_OUT");
        }

        return _amounts;
    }

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external _logs_ _lock_ returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint256 spotPriceBefore =
            calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = calcOutGivenIn(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountIn,
            _swapFee
        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external _logs_ _lock_ returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        uint256 spotPriceBefore =
            calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = calcInGivenOut(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountOut,
            _swapFee
        );
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return (tokenAmountIn, spotPriceAfter);
    }

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external _logs_ _lock_ returns (uint256 poolAmountOut) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        Record storage inRecord = _records[tokenIn];

        poolAmountOut = calcPoolOutGivenSingleIn(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountIn,
            _swapFee
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return poolAmountOut;
    }

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external _logs_ _lock_ returns (uint256 tokenAmountIn) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");

        Record storage inRecord = _records[tokenIn];

        tokenAmountIn = calcSingleInGivenPoolOut(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountOut,
            _swapFee
        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return tokenAmountIn;
    }

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external _logs_ _lock_ returns (uint256 tokenAmountOut) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountIn,
            _swapFee
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external _logs_ _lock_ returns (uint256 poolAmountIn) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        Record storage outRecord = _records[tokenOut];

        poolAmountIn = calcPoolInGivenSingleOut(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountOut,
            _swapFee
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return poolAmountIn;
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal {
        bool xfer = IERC20Balancer(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        bool xfer = IERC20Balancer(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pullPoolShare(address from, uint256 amount) internal {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint256 amount) internal {
        _push(to, amount);
    }

    function _mintPoolShare(uint256 amount) internal {
        _mint(amount);
    }

    function _burnPoolShare(uint256 amount) internal {
        _burn(amount);
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BNum.sol";

interface IERC20Balancer {
    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);
}

contract BTokenBase is BNum {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function _mint(uint256 amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        _totalSupply = badd(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint256 amt) internal {
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(
        address src,
        address dst,
        uint256 amt
    ) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }
}

contract BToken is BTokenBase, IERC20Balancer {
    string private _name = "Balancer Pool Token";
    string private _symbol = "BPT";
    uint8 private _decimals = 18;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view override returns (uint256) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt) external override returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint256 amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint256 amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external override returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "ERR_BTOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMathUint256.sol";
import "./SafeMathInt256.sol";

abstract contract CalculateLinesToBPoolOdds {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 constant MAX_BPOOL_WEIGHT = 50e18;

    function ratioOdds(uint256[] memory _proportions) internal pure returns (uint256[] memory _odds) {
        uint256 _total = sum(_proportions);

        _odds = new uint256[](_proportions.length);
        for (uint256 i = 0; i < _proportions.length; i++) {
            _odds[i] = (MAX_BPOOL_WEIGHT).mul(_proportions[i]).div(_total);
            require(_odds[i] >= 1e18, "min outcome weight is 2%");
        }
    }

    function sum(uint256[] memory _numbers) private pure returns (uint256 _sum) {
        for (uint256 i = 0; i < _numbers.length; i++) {
            _sum += _numbers[i];
        }
    }

    function evenOdds(bool _invalid, uint256 _outcomes) internal pure returns (uint256[] memory _odds) {
        uint256 _size = _outcomes + (_invalid ? 1 : 0);
        _odds = new uint256[](_size);

        if (_invalid) _odds[0] = 1e18; // 2%

        uint256 _each = (_invalid ? 49e18 : 50e18) / _outcomes;
        for (uint256 i = _invalid ? 1 : 0; i < _size; i++) {
            _odds[i] = _each;
        }
    }

    function oddsFromLines(int256 _moneyline1, int256 _moneyline2) internal pure returns (uint256[] memory _odds) {
        uint256 _odds1 = __calcLineToOdds(_moneyline1);
        uint256 _odds2 = __calcLineToOdds(_moneyline2);

        uint256 _total = _odds1 + _odds2;

        _odds1 = uint256(49e18).mul(_odds1).div(_total);
        _odds2 = uint256(49e18).mul(_odds2).div(_total);

        // Moneyline odds are too skewed: would have under 2% odds.
        require(_odds1 >= 1e18);
        require(_odds2 >= 1e18);

        _odds = new uint256[](3);
        _odds[0] = 1e18; // Invalid, 2%
        _odds[1] = _odds1;
        _odds[2] = _odds2;
    }

    function __calcLineToOdds(int256 _line) internal pure returns (uint256) {
        if (_line < 0) {
            // favored
            uint256 _posLine = uint256(-_line);
            return _posLine.mul(49e18).div(_posLine.add(100)); // 49e18 * _line / (_line + 100)
        } else {
            // underdog
            return uint256(4900e18).div(uint256(_line).add(100)); // 49e18 * 100 / (_line + 100)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../turbo/AbstractMarketFactoryV3.sol";
import "./Sport.sol";
import "./CalculateLinesToBPoolOdds.sol";
import "./TokenNamesFromTeams.sol";

abstract contract HasHeadToHeadMarket is
    AbstractMarketFactoryV3,
    Sport,
    CalculateLinesToBPoolOdds,
    TokenNamesFromTeams
{
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 private headToHeadMarketType;
    string private noContestName;

    uint256 constant HeadToHeadAway = 1;
    uint256 constant HeadToHeadHome = 2;

    constructor(uint256 _marketType, string memory _noContestName) {
        headToHeadMarketType = _marketType;
        noContestName = _noContestName;
    }

    function makeHeadToHeadMarket(
        int256[2] memory _moneylines,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) internal returns (uint256) {
        // moneylines is [home,away] but the outcomes are listed [NC,away,home] so they must be reversed
        return
            makeSportsMarket(
                noContestName,
                _homeTeamName,
                _awayTeamName,
                oddsFromLines(_moneylines[1], _moneylines[0])
            );
    }

    function resolveHeadToHeadMarket(
        uint256 _marketId,
        uint256 _homeScore,
        uint256 _awayScore
    ) internal {
        uint256 _shareTokenIndex = calcHeadToHeadWinner(_homeScore, _awayScore);
        endMarket(_marketId, _shareTokenIndex);
    }

    function calcHeadToHeadWinner(uint256 _homeScore, uint256 _awayScore) private pure returns (uint256) {
        if (_homeScore > _awayScore) {
            return HeadToHeadHome;
        } else if (_homeScore < _awayScore) {
            return HeadToHeadAway;
        } else {
            return NoContest;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../turbo/AbstractMarketFactoryV3.sol";
import "./Sport.sol";
import "./CalculateLinesToBPoolOdds.sol";

abstract contract HasOverUnderMarket is AbstractMarketFactoryV3, Sport, CalculateLinesToBPoolOdds {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 private overUnderMarketType;
    string private noContestName;

    uint256 constant Over = 1;
    uint256 constant Under = 2;

    constructor(uint256 _marketType, string memory _noContestName) {
        overUnderMarketType = _marketType;
        noContestName = _noContestName;
    }

    function makeOverUnderMarket() internal returns (uint256) {
        string[] memory _outcomeNames = makeOutcomeNames(noContestName);
        return startMarket(msg.sender, _outcomeNames, evenOdds(true, 2), true);
    }

    function resolveOverUnderMarket(
        uint256 _marketId,
        int256 _line,
        uint256 _homeScore,
        uint256 _awayScore
    ) internal {
        uint256 _shareTokenIndex = calcOverUnderWinner(_homeScore, _awayScore, _line);
        endMarket(_marketId, _shareTokenIndex);
    }

    function calcOverUnderWinner(
        uint256 _homeScore,
        uint256 _awayScore,
        int256 _targetTotal
    ) internal pure returns (uint256) {
        int256 _actualTotal = int256(_homeScore).add(int256(_awayScore));

        if (_actualTotal > _targetTotal) {
            return Over; // total score above than line
        } else if (_actualTotal < _targetTotal) {
            return Under; // total score below line
        } else {
            return NoContest; // draw / tie; some sports eliminate this with half-points
        }
    }

    function makeOutcomeNames(string memory _noContestName) private pure returns (string[] memory _names) {
        _names = new string[](3);
        _names[NoContest] = _noContestName;
        _names[Over] = "Over";
        _names[Under] = "Under";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../turbo/AbstractMarketFactoryV3.sol";
import "./Sport.sol";
import "./CalculateLinesToBPoolOdds.sol";
import "./TokenNamesFromTeams.sol";

abstract contract HasSpreadMarket is AbstractMarketFactoryV3, Sport, CalculateLinesToBPoolOdds, TokenNamesFromTeams {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 private spreadMarketType;
    string private noContestName;

    uint256 constant SpreadAway = 1;
    uint256 constant SpreadHome = 2;

    constructor(uint256 _marketType, string memory _noContestName) {
        spreadMarketType = _marketType;
        noContestName = _noContestName;
    }

    function makeSpreadMarket(string memory _homeTeamName, string memory _awayTeamName) internal returns (uint256) {
        return makeSportsMarket(noContestName, _homeTeamName, _awayTeamName, evenOdds(true, 2));
    }

    function resolveSpreadMarket(
        uint256 _marketId,
        int256 _line,
        uint256 _homeScore,
        uint256 _awayScore
    ) internal {
        uint256 _shareTokenIndex = calcSpreadWinner(_homeScore, _awayScore, _line);
        endMarket(_marketId, _shareTokenIndex);
    }

    function calcSpreadWinner(
        uint256 _homeScore,
        uint256 _awayScore,
        int256 _targetSpread
    ) internal pure returns (uint256) {
        int256 _adjustedHomeScore = int256(_homeScore) + int256(_targetSpread);

        if (_adjustedHomeScore > int256(_awayScore)) {
            return SpreadHome; // home spread greater
        } else if (_adjustedHomeScore < int256(_awayScore)) {
            return SpreadAway; // away spread lesser
        } else {
            // draw / tie; some sports eliminate this with half-points
            return NoContest;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Full is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IOwnable {
    function getOwner() external view returns (address);

    function transferOwnership(address _newOwner) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract LineHelper {
    function build1Line() internal pure returns (int256[] memory _lines) {
        _lines = new int256[](1);
    }

    function build3Lines(int256 _homeSpread, int256 _totalScore) internal pure returns (int256[] memory _lines) {
        _lines = new int256[](3);
        // 0 is the Head-to-Head market, which has no lines
        _lines[1] = addHalfPoint(_homeSpread);
        _lines[2] = addHalfPoint(_totalScore);
    }

    function addHalfPoint(int256 _line) private pure returns (int256) {
        // The line is a quantity of tenths. So 55 is 5.5 and -6 is -60.
        // If the line is a whole number then make it a half point more extreme, to eliminate ties.
        // So 50 becomes 55, -60 becomes -65, and 0 becomes 5.
        if (_line >= 0 && _line % 10 == 0) {
            return _line + 5;
        } else if (_line < 0 && (-_line) % 10 == 0) {
            return _line - 5;
        } else {
            return _line;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Ownable.sol";

abstract contract ManagedByLink is Ownable {
    event LinkNodeChanged(address newLinkNode);

    address public linkNode;

    constructor(address _linkNode) {
        linkNode = _linkNode;
    }

    function setLinkNode(address _newLinkNode) external onlyOwner {
        linkNode = _newLinkNode;
        emit LinkNodeChanged(_newLinkNode);
    }

    modifier onlyLinkNode() {
        require(msg.sender == linkNode);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IOwnable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable is IOwnable {
    address internal owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public override onlyOwner returns (bool) {
        require(_newOwner != address(0));
        onTransferOwnership(owner, _newOwner);
        owner = _newOwner;
        return true;
    }

    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract
    function onTransferOwnership(address, address) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Sport.sol";
import "./ManagedByLink.sol";

abstract contract ResolvesByFiat is Sport, ManagedByLink {
    function resolveEvent(
        uint256 _eventId,
        SportsEventStatus _eventStatus,
        uint256 _homeTeamId, // for verifying team stability
        uint256 _awayTeamId, // for verifying team stability
        uint256 _whoWon
    ) public onlyLinkNode {
        SportsEvent storage _event = sportsEvents[_eventId];

        require(_event.status == SportsEventStatus.Scheduled);
        require(SportsEventStatus(_eventStatus) != SportsEventStatus.Scheduled);

        if (eventIsNoContest(_event, _eventStatus, _homeTeamId, _awayTeamId, _whoWon)) {
            resolveInvalidEvent(_eventId);
        } else {
            resolveValidEvent(_event, _whoWon);
        }

        sportsEvents[_eventId].status = _eventStatus;
    }

    function resolveValidEvent(SportsEvent memory _event, uint256 _whoWon) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Sport.sol";
import "./ManagedByLink.sol";

abstract contract ResolvesByScore is Sport, ManagedByLink {
    function resolveEvent(
        uint256 _eventId,
        SportsEventStatus _eventStatus,
        uint256 _homeTeamId, // for verifying team stability
        uint256 _awayTeamId, // for verifying team stability
        uint256 _homeScore,
        uint256 _awayScore
    ) public onlyLinkNode {
        SportsEvent storage _event = sportsEvents[_eventId];

        require(_event.status == SportsEventStatus.Scheduled);
        require(SportsEventStatus(_eventStatus) != SportsEventStatus.Scheduled);

        if (eventIsNoContest(_event, _eventStatus, _homeTeamId, _awayTeamId, WhoWonUnknown)) {
            resolveInvalidEvent(_eventId);
        } else {
            resolveValidEvent(_event, _homeScore, _awayScore);
        }

        sportsEvents[_eventId].status = _eventStatus;
    }

    function resolveValidEvent(
        SportsEvent memory _event,
        uint256 _homeScore,
        uint256 _awayScore
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract Rewardable {
    // Rewards will be paid out over the lifetime of an event.
    // An value of zero will start rewards immediately and proceed based on the values set in master chef.

    // _Id here is the market id passed to the amm factory when creating a pool.
    function getRewardEndTime(uint256 _Id) public virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @title SafeMathInt256
 * @dev Int256 math operations with safety checks that throw on error
 */
library SafeMathInt256 {
    // Signed ints with n bits can range from -2**(n-1) to (2**(n-1) - 1)
    int256 private constant INT256_MIN = -2**(255);
    int256 private constant INT256_MAX = (2**(255) - 1);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // No need to check for dividing by 0 -- Solidity automatically throws on division by 0
        int256 c = a / b;
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require(((a >= 0) && (b >= a - INT256_MAX)) || ((a < 0) && (b <= a - INT256_MIN)));
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        require(((a >= 0) && (b <= INT256_MAX - a)) || ((a < 0) && (b >= INT256_MIN - a)));
        return a + b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function abs(int256 a) internal pure returns (int256) {
        if (a < 0) {
            return -a;
        }
        return a;
    }

    function getInt256Min() internal pure returns (int256) {
        return INT256_MIN;
    }

    function getInt256Max() internal pure returns (int256) {
        return INT256_MAX;
    }

    // Float [fixed point] Operations
    function fxpMul(
        int256 a,
        int256 b,
        int256 base
    ) internal pure returns (int256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(
        int256 a,
        int256 b,
        int256 base
    ) internal pure returns (int256) {
        return div(mul(a, base), b);
    }

    function sqrt(int256 y) internal pure returns (int256 z) {
        if (y > 3) {
            int256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @title SafeMathUint256
 * @dev Uint256 math operations with safety checks that throw on error
 */
library SafeMathUint256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function subS(
        uint256 a,
        uint256 b,
        string memory message
    ) internal pure returns (uint256) {
        require(b <= a, message);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            uint256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        // 2 ** 256 - 1
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

    // Float [fixed point] Operations
    function fxpMul(
        uint256 a,
        uint256 b,
        uint256 base
    ) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(
        uint256 a,
        uint256 b,
        uint256 base
    ) internal pure returns (uint256) {
        return div(mul(a, base), b);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../turbo/AbstractMarketFactoryV3.sol";
import "./LineHelper.sol";

abstract contract Sport is AbstractMarketFactoryV3, LineHelper {
    event SportsEventCreated(
        uint256 id,
        uint256[] markets,
        int256[] lines,
        uint256 homeTeamId,
        uint256 awayTeamId,
        string homeTeamName,
        string awayTeamName,
        uint256 estimatedStartTime
    );

    enum SportsEventStatus {Unknown, Scheduled, Final, Postponed, Canceled}
    struct SportsEvent {
        SportsEventStatus status;
        uint256[] markets;
        int256[] lines;
        uint256 estimatedStartTime;
        uint256 homeTeamId;
        uint256 awayTeamId;
        string homeTeamName;
        string awayTeamName;
        uint256 homeScore;
        uint256 awayScore;
    }
    // EventId => EventDetails
    mapping(uint256 => SportsEvent) public sportsEvents;
    uint256[] public listOfSportsEvents;

    uint256 constant NoContest = 0;

    function eventCount() public view returns (uint256) {
        return listOfSportsEvents.length;
    }

    function getSportsEvent(uint256 _eventId) public view returns (SportsEvent memory) {
        return sportsEvents[_eventId];
    }

    function getSportsEventByIndex(uint256 _index) public view returns (SportsEvent memory _event, uint256 _eventId) {
        _eventId = listOfSportsEvents[_index];
        _event = getSportsEvent(_eventId);
    }

    function makeSportsEvent(
        uint256 _eventId,
        uint256[] memory _markets,
        int256[] memory _lines,
        uint256 _estimatedStartTime,
        uint256 _homeTeamId,
        uint256 _awayTeamId,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) internal {
        // Cannot create markets for an event twice.
        require(sportsEvents[_eventId].status == SportsEventStatus.Unknown, "event exists");

        listOfSportsEvents.push(_eventId);
        sportsEvents[_eventId].status = SportsEventStatus.Scheduled; // new events must be Scheduled
        sportsEvents[_eventId].markets = _markets;
        sportsEvents[_eventId].lines = _lines;
        sportsEvents[_eventId].estimatedStartTime = _estimatedStartTime;
        sportsEvents[_eventId].homeTeamId = _homeTeamId;
        sportsEvents[_eventId].awayTeamId = _awayTeamId;
        sportsEvents[_eventId].homeTeamName = _homeTeamName;
        sportsEvents[_eventId].awayTeamName = _awayTeamName;
        // homeScore and awayScore default to zero, which is correct for new events

        emit SportsEventCreated(
            _eventId,
            _markets,
            _lines,
            _homeTeamId,
            _awayTeamId,
            _homeTeamName,
            _awayTeamName,
            _estimatedStartTime
        );
    }

    uint256 constant WhoWonUnknown = 0;
    uint256 constant WhoWonHome = 1;
    uint256 constant WhoWonAway = 2;
    uint256 constant WhoWonDraw = 3;

    function eventIsNoContest(
        SportsEvent memory _event,
        SportsEventStatus _eventStatus,
        uint256 _homeTeamId,
        uint256 _awayTeamId,
        uint256 _whoWon // pass in WhoWonUnknown if using a scoring sport
    ) internal pure returns (bool) {
        bool _draw = _whoWon == WhoWonDraw;
        bool _notFinal = _eventStatus != SportsEventStatus.Final;
        bool _unstableHomeTeamId = _event.homeTeamId != _homeTeamId;
        bool _unstableAwayTeamId = _event.awayTeamId != _awayTeamId;
        return _draw || _notFinal || _unstableHomeTeamId || _unstableAwayTeamId;
    }

    function resolveInvalidEvent(uint256 _eventId) internal {
        uint256[] memory _marketIds = sportsEvents[_eventId].markets;
        for (uint256 i = 0; i < _marketIds.length; i++) {
            uint256 _marketId = _marketIds[i];
            if (_marketId == 0) continue; // skip non-created markets
            endMarket(_marketId, NoContest);
        }
    }

    // TODO is this needed? getSportsEvent should do the same
    function getEventMarkets(uint256 _eventId) public view returns (uint256[] memory _markets) {
        uint256[] storage _original = sportsEvents[_eventId].markets;
        uint256 _len = _original.length;
        _markets = new uint256[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _markets[i] = _original[i];
        }
    }

    function getRewardEndTime(uint256 _eventId) public override returns (uint256) {
        return getSportsEvent(_eventId).estimatedStartTime;
    }
}

// TODO change this to work with the Fetcher contracts and use it there, since it's offchain-read-only.
abstract contract SportView is Sport {
    // Only usable off-chain. Gas cost can easily eclipse block limit.
    // Lists all events that could be resolved with a call to resolveEvent.
    // Not all will be resolvable because this does not ensure the game ended.
    function listResolvableEvents() external view returns (uint256[] memory) {
        uint256 _totalResolvable = countResolvableEvents();
        uint256[] memory _resolvableEvents = new uint256[](_totalResolvable);

        uint256 n = 0;
        for (uint256 i = 0; i < listOfSportsEvents.length; i++) {
            if (n > _totalResolvable) break;
            uint256 _eventId = listOfSportsEvents[i];
            if (isEventResolvable(_eventId)) {
                _resolvableEvents[n] = _eventId;
                n++;
            }
        }

        return _resolvableEvents;
    }

    function countResolvableEvents() internal view returns (uint256) {
        uint256 _totalResolvable = 0;
        for (uint256 i = 0; i < listOfSportsEvents.length; i++) {
            uint256 _eventId = listOfSportsEvents[i];
            if (isEventResolvable(_eventId)) {
                _totalResolvable++;
            }
        }
        return _totalResolvable;
    }

    // Returns true if a call to resolveEvent is potentially useful.
    function isEventResolvable(uint256 _eventId) internal view returns (bool) {
        uint256[] memory _markets = getEventMarkets(_eventId);

        bool _unresolved = false; // default because non-existing markets aren't resolvable
        for (uint256 i = 0; i < _markets.length; i++) {
            uint256 _marketId = _markets[i];
            if (_marketId != 0 && !isMarketResolved(_marketId)) {
                _unresolved = true;
                break;
            }
        }

        return _unresolved;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Sport.sol";

abstract contract TokenNamesFromTeams is Sport {
    uint256 constant Away = 1;
    uint256 constant Home = 2;

    function makeSportsMarket(
        string memory _noContestName,
        string memory _homeTeamName,
        string memory _awayTeamName,
        uint256[] memory _odds
    ) internal returns (uint256) {
        string[] memory _outcomeNames = makeOutcomeNames(_noContestName, _homeTeamName, _awayTeamName);
        return startMarket(msg.sender, _outcomeNames, _odds, true);
    }

    function makeOutcomeNames(
        string memory _noContestName,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) private pure returns (string[] memory _names) {
        _names = new string[](3);
        _names[NoContest] = _noContestName;
        _names[Away] = _awayTeamName;
        _names[Home] = _homeTeamName;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract Versioned {
    string internal version;

    constructor(string memory _version) {
        version = _version;
    }

    function getVersion() public view returns (string memory) {
        return version;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol" as OpenZeppelinOwnable;
import "../turbo/AbstractMarketFactoryV3.sol";
import "../turbo/AMMFactory.sol";

// MasterChef is the master of Reward. He can make Reward and he is a fair guy.
contract MasterChef is OpenZeppelinOwnable.Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BONE = 10**18;

    // The percentage of the rewards period that early deposit bonus will payout.
    // e.g. Early deposit bonus hits if LP is done in the first x percent of the period.
    uint256 public constant EARLY_DEPOSIT_BONUS_REWARDS_PERCENTAGE = BONE / 10; // 10% of reward period.

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastActionTimestamp; // Timestamp of the withdrawal or deposit from this user.
        //
        // We do some fancy math here. Basically, any point in time, the amount of REWARDs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each user that deposits LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 accRewardsPerShare; // Accumulated REWARDs per share, times BONE. See below.
        uint256 totalEarlyDepositBonusRewardShares; // The total number of share currently qualifying bonus REWARDs.
        uint256 beginTimestamp; // The timestamp to begin calculating rewards at.
        uint256 endTimestamp; // Timestamp of the end of the rewards period.
        uint256 earlyDepositBonusRewards; // Amount of REWARDs to distribute to early depositors.
        uint256 lastRewardTimestamp; // Last timestamp REWARDs distribution occurred.
        uint256 rewardsPerSecond; // Number of rewards paid out per second.
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // This is a snapshot of the current state of a market.
    struct PoolStatusInfo {
        uint256 beginTimestamp;
        uint256 endTimestamp;
        uint256 earlyDepositEndTimestamp;
        uint256 totalRewardsAccrued;
        bool created;
    }

    struct PendingRewardInfo {
        uint256 beginTimestamp;
        uint256 endTimestamp;
        uint256 earlyDepositEndTimestamp;
        uint256 accruedStandardRewards;
        uint256 accruedEarlyDepositBonusRewards;
        uint256 pendingEarlyDepositBonusRewards;
    }

    struct MarketFactoryInfo {
        uint256 earlyDepositBonusRewards; // Amount of REWARDs to distribute to early depositors.
        uint256 rewardsPeriods; // Number of days the rewards for this pool will payout.
        uint256 rewardsPerPeriod; // Amount of rewards to be given out for a given period.
    }
    mapping(address => MarketFactoryInfo) marketFactoryRewardInfo;

    struct RewardPoolLookupInfo {
        uint256 pid;
        bool created;
    }

    // AMMFactory => MarketFactory => MarketId
    mapping(address => mapping(address => mapping(uint256 => RewardPoolLookupInfo))) public rewardPoolLookup;

    // The REWARD TOKEN!
    IERC20 private rewardsToken;

    mapping(address => bool) private approvedAMMFactories;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address recipient);
    event TrustMarketFactory(
        address indexed MarketFactory,
        uint256 OriginEarlyDepositBonusRewards,
        uint256 OriginrewardsPeriods,
        uint256 OriginRewardsPerPeriod,
        uint256 EarlyDepositBonusRewards,
        uint256 rewardsPeriods,
        uint256 RewardsPerPeriod
    );

    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IERC20 _rewardsToken) {
        rewardsToken = _rewardsToken;
    }

    function trustAMMFactory(address _ammFactory) public onlyOwner {
        approvedAMMFactories[_ammFactory] = true;
    }

    function untrustAMMFactory(address _ammFactory) public onlyOwner {
        delete approvedAMMFactories[_ammFactory];
    }

    // This method can also be used to update rewards
    function addRewards(
        address _marketFactory,
        uint256 _rewardsPerMarket,
        uint256 _rewardDaysPerMarket,
        uint256 _earlyDepositBonusRewards
    ) public onlyOwner {
        MarketFactoryInfo memory _oldMarketFactoryInfo = marketFactoryRewardInfo[_marketFactory];

        marketFactoryRewardInfo[_marketFactory] = MarketFactoryInfo({
            rewardsPeriods: _rewardDaysPerMarket,
            rewardsPerPeriod: _rewardsPerMarket,
            earlyDepositBonusRewards: _earlyDepositBonusRewards
        });

        emit TrustMarketFactory(
            _marketFactory,
            _oldMarketFactoryInfo.earlyDepositBonusRewards,
            _oldMarketFactoryInfo.rewardsPeriods,
            _oldMarketFactoryInfo.rewardsPerPeriod,
            _earlyDepositBonusRewards,
            _rewardDaysPerMarket,
            _rewardsPerMarket
        );
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // An _endTimestamp of zero means the rewards start immediately.
    function add(
        address _ammFactory,
        address _marketFactory,
        uint256 _marketId,
        IERC20 _lpToken,
        uint256 _endTimestamp
    ) public onlyOwner returns (uint256 _nextPID) {
        return addInternal(_ammFactory, _marketFactory, _marketId, _lpToken, _endTimestamp);
    }

    function addInternal(
        address _ammFactory,
        address _marketFactory,
        uint256 _marketId,
        IERC20 _lpToken,
        uint256 _endTimestamp
    ) internal returns (uint256 _nextPID) {
        _nextPID = poolInfo.length;

        require(
            !rewardPoolLookup[_ammFactory][_marketFactory][_marketId].created,
            "Reward pool has already been created."
        );

        rewardPoolLookup[_ammFactory][_marketFactory][_marketId] = RewardPoolLookupInfo({pid: _nextPID, created: true});

        MarketFactoryInfo memory _marketFactoryInfo = marketFactoryRewardInfo[_marketFactory];

        // Need to figure out the beginning/end of the reward period.
        uint256 _rewardsPeriodsInSeconds = _marketFactoryInfo.rewardsPeriods * 1 days;
        uint256 _beginTimestamp = block.timestamp;

        if (_endTimestamp == 0) {
            _endTimestamp = _beginTimestamp + _rewardsPeriodsInSeconds;
        } else if ((_endTimestamp - _rewardsPeriodsInSeconds) > block.timestamp) {
            _beginTimestamp = _endTimestamp - _rewardsPeriodsInSeconds;
        }

        poolInfo.push(
            PoolInfo({
                accRewardsPerShare: 0,
                beginTimestamp: _beginTimestamp,
                endTimestamp: _endTimestamp,
                totalEarlyDepositBonusRewardShares: 0,
                earlyDepositBonusRewards: _marketFactoryInfo.earlyDepositBonusRewards,
                lpToken: _lpToken,
                rewardsPerSecond: (_marketFactoryInfo.rewardsPerPeriod / 1 days),
                lastRewardTimestamp: _beginTimestamp
            })
        );
    }

    // Return number of seconds elapsed in terms of BONEs.
    function getTimeElapsed(uint256 _pid) public view returns (uint256) {
        PoolInfo storage _pool = poolInfo[_pid];
        uint256 _fromTimestamp = block.timestamp;

        if (
            // Rewards have not started yet.
            _pool.beginTimestamp > _fromTimestamp ||
            // Not sure how this happens but it is accounted for in the original master chef contract.
            _pool.lastRewardTimestamp > _fromTimestamp ||
            // No rewards to be distributed
            _pool.rewardsPerSecond == 0
        ) {
            return 0;
        }

        // Rewards are over for this pool. No more rewards have accrued.
        if (_pool.lastRewardTimestamp >= _pool.endTimestamp) {
            return 0;
        }

        return min(_fromTimestamp, _pool.endTimestamp).sub(_pool.lastRewardTimestamp).add(1).mul(BONE);
    }

    function getPoolTokenBalance(
        AMMFactory _ammFactory,
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        address _user
    ) external view returns (uint256) {
        RewardPoolLookupInfo memory _rewardPoolLookupInfo =
            rewardPoolLookup[address(_ammFactory)][address(_marketFactory)][_marketId];

        return userInfo[_rewardPoolLookupInfo.pid][_user].amount;
    }

    function getUserAmount(uint256 _pid, address _user) external view returns (uint256) {
        return userInfo[_pid][_user].amount;
    }

    function getPoolRewardEndTimestamp(uint256 _pid) public view returns (uint256) {
        PoolInfo storage _pool = poolInfo[_pid];
        return _pool.endTimestamp;
    }

    function getPoolInfo(
        AMMFactory _ammFactory,
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId
    ) public view returns (PoolStatusInfo memory _poolStatusInfo) {
        RewardPoolLookupInfo memory _rewardPoolLookupInfo =
            rewardPoolLookup[address(_ammFactory)][address(_marketFactory)][_marketId];
        PoolInfo storage _pool = poolInfo[_rewardPoolLookupInfo.pid];

        // This cannot revert as it will be used in a multicall.
        if (_rewardPoolLookupInfo.created) {
            _poolStatusInfo.beginTimestamp = _pool.beginTimestamp;
            _poolStatusInfo.endTimestamp = _pool.endTimestamp;
            _poolStatusInfo.earlyDepositEndTimestamp =
                ((_poolStatusInfo.endTimestamp * EARLY_DEPOSIT_BONUS_REWARDS_PERCENTAGE) / BONE) +
                _pool.beginTimestamp +
                1;

            _poolStatusInfo.totalRewardsAccrued =
                (min(block.timestamp, _pool.endTimestamp) - _pool.beginTimestamp) *
                _pool.rewardsPerSecond;
            _poolStatusInfo.created = true;
        }
    }

    // View function to see pending REWARDs on frontend.
    function getUserPendingRewardInfo(uint256 _pid, address _userAddress)
        external
        view
        returns (PendingRewardInfo memory _pendingRewardInfo)
    {
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _user = userInfo[_pid][_userAddress];
        uint256 accRewardsPerShare = _pool.accRewardsPerShare;
        uint256 lpSupply = _pool.lpToken.balanceOf(address(this));

        _pendingRewardInfo.beginTimestamp = _pool.beginTimestamp;
        _pendingRewardInfo.endTimestamp = _pool.endTimestamp;
        _pendingRewardInfo.earlyDepositEndTimestamp =
            ((_pendingRewardInfo.endTimestamp * EARLY_DEPOSIT_BONUS_REWARDS_PERCENTAGE) / BONE) +
            _pool.beginTimestamp +
            1;

        if (_pool.totalEarlyDepositBonusRewardShares > 0 && block.timestamp > _pendingRewardInfo.endTimestamp) {
            _pendingRewardInfo.accruedEarlyDepositBonusRewards = _pool.earlyDepositBonusRewards.mul(_user.amount).div(
                _pool.totalEarlyDepositBonusRewardShares
            );
        } else if (_pool.totalEarlyDepositBonusRewardShares > 0) {
            _pendingRewardInfo.pendingEarlyDepositBonusRewards = _pool.earlyDepositBonusRewards.mul(_user.amount).div(
                _pool.totalEarlyDepositBonusRewardShares
            );
        }

        if (block.timestamp > _pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = getTimeElapsed(_pid);
            accRewardsPerShare = multiplier.mul(_pool.rewardsPerSecond).div(lpSupply);
        }

        _pendingRewardInfo.accruedStandardRewards = _user.amount.mul(accRewardsPerShare).div(BONE).sub(
            _user.rewardDebt
        );
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getTimeElapsed(_pid);
        pool.accRewardsPerShare = pool.accRewardsPerShare.add(multiplier.mul(pool.rewardsPerSecond).div(lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for REWARD allocation.
    // Assumes the staked tokens are already on contract.
    function depositInternal(
        address _userAddress,
        uint256 _pid,
        uint256 _amount
    ) internal {
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _user = userInfo[_pid][_userAddress];

        updatePool(_pid);

        if (_user.amount > 0) {
            uint256 pending = _user.amount.mul(_pool.accRewardsPerShare).div(BONE).sub(_user.rewardDebt);
            safeRewardsTransfer(_userAddress, pending);
        }

        uint256 _rewardsPeriodsInSeconds = _pool.endTimestamp - _pool.beginTimestamp;
        uint256 _bonusrewardsPeriodsEndTimestamp =
            ((_rewardsPeriodsInSeconds * EARLY_DEPOSIT_BONUS_REWARDS_PERCENTAGE) / BONE) + _pool.beginTimestamp + 1;

        // If the user was an early deposit, remove user amount from the pool.
        // Even if the pools reward period has elapsed. They must withdraw first.
        if (
            block.timestamp > _bonusrewardsPeriodsEndTimestamp &&
            _user.lastActionTimestamp <= _bonusrewardsPeriodsEndTimestamp
        ) {
            _pool.totalEarlyDepositBonusRewardShares = _pool.totalEarlyDepositBonusRewardShares.sub(_user.amount);
        }

        // Still in the early deposit bonus period.
        if (_bonusrewardsPeriodsEndTimestamp > block.timestamp) {
            _pool.totalEarlyDepositBonusRewardShares = _pool.totalEarlyDepositBonusRewardShares.add(_amount);
        }

        _user.amount = _user.amount.add(_amount);

        _user.rewardDebt = _user.amount.mul(_pool.accRewardsPerShare).div(BONE);
        _user.lastActionTimestamp = block.timestamp;
        emit Deposit(_userAddress, _pid, _amount);
    }

    function depositByMarket(
        AMMFactory _ammFactory,
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _amount
    ) public {
        RewardPoolLookupInfo memory _rewardPoolLookupInfo =
            rewardPoolLookup[address(_ammFactory)][address(_marketFactory)][_marketId];

        require(_rewardPoolLookupInfo.created, "Reward pool has not been created.");

        deposit(_rewardPoolLookupInfo.pid, _amount);
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        poolInfo[_pid].lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        depositInternal(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    // Assumes caller is handling distribution of LP tokens.
    function withdrawInternal(
        address _userAddress,
        uint256 _pid,
        uint256 _amount,
        address _tokenRecipientAddress
    ) internal {
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _user = userInfo[_pid][_userAddress];
        require(_user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint256 _rewardsPeriodsInSeconds = _pool.endTimestamp - _pool.beginTimestamp;
        uint256 _bonusrewardsPeriodsEndTimestamp =
            ((_rewardsPeriodsInSeconds * EARLY_DEPOSIT_BONUS_REWARDS_PERCENTAGE) / BONE) + _pool.beginTimestamp + 1;
        uint256 _rewardPeriodEndTimestamp = _rewardsPeriodsInSeconds + _pool.beginTimestamp + 1;

        if (_rewardPeriodEndTimestamp <= block.timestamp) {
            if (
                _pool.totalEarlyDepositBonusRewardShares > 0 &&
                _user.lastActionTimestamp <= _bonusrewardsPeriodsEndTimestamp
            ) {
                uint256 _rewardsToUser =
                    _pool.earlyDepositBonusRewards.mul(_user.amount).div(_pool.totalEarlyDepositBonusRewardShares);
                safeRewardsTransfer(_userAddress, _rewardsToUser);
            }
        } else if (_bonusrewardsPeriodsEndTimestamp >= block.timestamp) {
            // Still in the early deposit bonus period.
            _pool.totalEarlyDepositBonusRewardShares = _pool.totalEarlyDepositBonusRewardShares.sub(_amount);
        } else if (
            // If the user was an early deposit, remove user amount from the pool.
            _bonusrewardsPeriodsEndTimestamp >= _user.lastActionTimestamp
        ) {
            _pool.totalEarlyDepositBonusRewardShares = _pool.totalEarlyDepositBonusRewardShares.sub(_user.amount);
        }

        uint256 pending = _user.amount.mul(_pool.accRewardsPerShare).div(BONE).sub(_user.rewardDebt);

        safeRewardsTransfer(_tokenRecipientAddress, pending);
        _user.amount = _user.amount.sub(_amount);
        _user.rewardDebt = _user.amount.mul(_pool.accRewardsPerShare).div(BONE);
        _user.lastActionTimestamp = block.timestamp;

        emit Withdraw(msg.sender, _pid, _amount, _tokenRecipientAddress);
    }

    function withdrawByMarket(
        AMMFactory _ammFactory,
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _amount
    ) public {
        RewardPoolLookupInfo memory _rewardPoolLookupInfo =
            rewardPoolLookup[address(_ammFactory)][address(_marketFactory)][_marketId];

        require(_rewardPoolLookupInfo.created, "Reward pool has not been created.");

        withdraw(_rewardPoolLookupInfo.pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        withdrawInternal(msg.sender, _pid, _amount, msg.sender);
        poolInfo[_pid].lpToken.safeTransfer(msg.sender, _amount);
    }

    function createPool(
        AMMFactory _ammFactory,
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _initialLiquidity,
        address _lpTokenRecipient
    ) public returns (uint256) {
        require(approvedAMMFactories[address(_ammFactory)], "AMMFactory must be approved to create pool");
        _marketFactory.collateral().transferFrom(msg.sender, address(this), _initialLiquidity);
        _marketFactory.collateral().approve(address(_ammFactory), _initialLiquidity);

        uint256 _lpTokensIn = _ammFactory.createPool(_marketFactory, _marketId, _initialLiquidity, address(this));
        IERC20 _lpToken = IERC20(address(_ammFactory.getPool(_marketFactory, _marketId)));

        uint256 _nextPID =
            addInternal(
                address(_ammFactory),
                address(_marketFactory),
                _marketId,
                _lpToken,
                _marketFactory.getRewardEndTime(_marketId)
            );

        depositInternal(_lpTokenRecipient, _nextPID, _lpTokensIn);

        return _lpTokensIn;
    }

    function addLiquidity(
        AMMFactory _ammFactory,
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _collateralIn,
        uint256 _minLPTokensOut,
        address _lpTokenRecipient
    ) public returns (uint256 _poolAmountOut, uint256[] memory _balances) {
        RewardPoolLookupInfo memory _rewardPoolLookupInfo =
            rewardPoolLookup[address(_ammFactory)][address(_marketFactory)][_marketId];

        require(_rewardPoolLookupInfo.created, "Reward pool has not been created.");

        _marketFactory.collateral().transferFrom(msg.sender, address(this), _collateralIn);
        _marketFactory.collateral().approve(address(_ammFactory), _collateralIn);

        (_poolAmountOut, _balances) = _ammFactory.addLiquidity(
            _marketFactory,
            _marketId,
            _collateralIn,
            _minLPTokensOut,
            _lpTokenRecipient
        );

        depositInternal(_lpTokenRecipient, _rewardPoolLookupInfo.pid, _poolAmountOut);
    }

    function removeLiquidity(
        AMMFactory _ammFactory,
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _lpTokensIn,
        uint256 _minCollateralOut,
        address _collateralRecipient
    ) public returns (uint256, uint256[] memory) {
        RewardPoolLookupInfo memory _rewardPoolLookupInfo =
            rewardPoolLookup[address(_ammFactory)][address(_marketFactory)][_marketId];

        require(_rewardPoolLookupInfo.created, "Reward pool has not been created.");

        withdrawInternal(msg.sender, _rewardPoolLookupInfo.pid, _lpTokensIn, _collateralRecipient);

        PoolInfo storage _pool = poolInfo[_rewardPoolLookupInfo.pid];

        _pool.lpToken.approve(address(_ammFactory), _lpTokensIn);
        return
            _ammFactory.removeLiquidity(
                _marketFactory,
                _marketId,
                _lpTokensIn,
                _minCollateralOut,
                _collateralRecipient
            );
    }

    function withdrawRewards(uint256 _amount) external onlyOwner {
        rewardsToken.transfer(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.lastActionTimestamp = 0;
    }

    function safeRewardsTransfer(address _to, uint256 _amount) internal {
        uint256 _rewardsBal = rewardsToken.balanceOf(address(this));
        if (_amount > _rewardsBal) {
            rewardsToken.transfer(_to, _rewardsBal);
        } else {
            rewardsToken.transfer(_to, _amount);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../balancer/BFactory.sol";
import "../libraries/SafeMathUint256.sol";
import "./AbstractMarketFactoryV3.sol";
import "../balancer/BNum.sol";

import "hardhat/console.sol";

contract AMMFactory is BNum {
    using SafeMathUint256 for uint256;

    uint256 private constant MAX_UINT = 2**256 - 1;
    uint256 private constant MIN_INITIAL_LIQUIDITY = BONE * 100;

    BFactory public bFactory;
    // MarketFactory => Market => BPool
    mapping(address => mapping(uint256 => BPool)) public pools;
    uint256 fee;

    event PoolCreated(
        address pool,
        address indexed marketFactory,
        uint256 indexed marketId,
        address indexed creator,
        address lpTokenRecipient
    );
    event LiquidityChanged(
        address indexed marketFactory,
        uint256 indexed marketId,
        address indexed user,
        address recipient,
        // from the perspective of the user. e.g. collateral is negative when adding liquidity
        int256 collateral,
        int256 lpTokens,
        uint256[] sharesReturned
    );
    event SharesSwapped(
        address indexed marketFactory,
        uint256 indexed marketId,
        address indexed user,
        uint256 outcome,
        // from the perspective of the user. e.g. collateral is negative when buying
        int256 collateral,
        int256 shares,
        uint256 price
    );

    constructor(BFactory _bFactory, uint256 _fee) {
        bFactory = _bFactory;
        fee = _fee;
    }

    function createPool(
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _initialLiquidity,
        address _lpTokenRecipient
    ) public returns (uint256) {
        require(pools[address(_marketFactory)][_marketId] == BPool(0), "Pool already created");

        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);

        uint256 _sets = _marketFactory.calcShares(_initialLiquidity);

        // Comparing to sets because sets are normalized to 10e18.
        require(_sets >= MIN_INITIAL_LIQUIDITY, "Initial liquidity must be at least 100 collateral.");

        //  Turn collateral into shares
        IERC20Full _collateral = _marketFactory.collateral();
        require(
            _collateral.allowance(msg.sender, address(this)) >= _initialLiquidity,
            "insufficient collateral allowance for initial liquidity"
        );

        _collateral.transferFrom(msg.sender, address(this), _initialLiquidity);
        _collateral.approve(address(_marketFactory), MAX_UINT);

        _marketFactory.mintShares(_marketId, _sets, address(this));

        // Create pool
        BPool _pool = bFactory.newBPool();

        // Add each outcome to the pool. Collateral is NOT added.
        for (uint256 i = 0; i < _market.shareTokens.length; i++) {
            OwnedERC20 _token = _market.shareTokens[i];
            _token.approve(address(_pool), MAX_UINT);
            _pool.bind(address(_token), _sets, _market.initialOdds[i]);
        }

        // Set the swap fee.
        _pool.setSwapFee(fee);

        // Finalize pool setup
        _pool.finalize();

        pools[address(_marketFactory)][_marketId] = _pool;

        // Pass along LP tokens for initial liquidity
        uint256 _lpTokenBalance = _pool.balanceOf(address(this)) - (BONE / 1000);

        // Burn (BONE / 1000) lp tokens to prevent the bpool from locking up. When all liquidity is removed.
        _pool.transfer(address(0x0), (BONE / 1000));
        _pool.transfer(_lpTokenRecipient, _lpTokenBalance);

        uint256[] memory _balances = new uint256[](_market.shareTokens.length);
        for (uint256 i = 0; i < _market.shareTokens.length; i++) {
            _balances[i] = 0;
        }

        emit PoolCreated(address(_pool), address(_marketFactory), _marketId, msg.sender, _lpTokenRecipient);
        emit LiquidityChanged(
            address(_marketFactory),
            _marketId,
            msg.sender,
            _lpTokenRecipient,
            -int256(_initialLiquidity),
            int256(_lpTokenBalance),
            _balances
        );

        return _lpTokenBalance;
    }

    function addLiquidity(
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _collateralIn,
        uint256 _minLPTokensOut,
        address _lpTokenRecipient
    ) public returns (uint256 _poolAmountOut, uint256[] memory _balances) {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        require(_pool != BPool(0), "Pool needs to be created");

        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);

        //  Turn collateral into shares
        IERC20Full _collateral = _marketFactory.collateral();
        _collateral.transferFrom(msg.sender, address(this), _collateralIn);
        _collateral.approve(address(_marketFactory), MAX_UINT);
        uint256 _sets = _marketFactory.calcShares(_collateralIn);
        _marketFactory.mintShares(_marketId, _sets, address(this));

        // Find poolAmountOut
        _poolAmountOut = MAX_UINT;

        {
            uint256 _totalSupply = _pool.totalSupply();
            uint256[] memory _maxAmountsIn = new uint256[](_market.shareTokens.length);
            for (uint256 i = 0; i < _market.shareTokens.length; i++) {
                _maxAmountsIn[i] = _sets;

                OwnedERC20 _token = _market.shareTokens[i];
                uint256 _bPoolTokenBalance = _pool.getBalance(address(_token));

                // This is the result the following when solving for poolAmountOut:
                // uint256 ratio = bdiv(poolAmountOut, poolTotal);
                // uint256 tokenAmountIn = bmul(ratio, bal);
                uint256 _tokenPoolAmountOut =
                    (((((_sets * BONE) - (BONE / 2)) * _totalSupply) / _bPoolTokenBalance) - (_totalSupply / 2)) / BONE;

                if (_tokenPoolAmountOut < _poolAmountOut) {
                    _poolAmountOut = _tokenPoolAmountOut;
                }
            }
            _pool.joinPool(_poolAmountOut, _maxAmountsIn);
        }

        require(_poolAmountOut >= _minLPTokensOut, "Would not have received enough LP tokens");

        _pool.transfer(_lpTokenRecipient, _poolAmountOut);

        // Transfer the remaining shares back to _lpTokenRecipient.
        _balances = new uint256[](_market.shareTokens.length);
        for (uint256 i = 0; i < _market.shareTokens.length; i++) {
            OwnedERC20 _token = _market.shareTokens[i];
            _balances[i] = _token.balanceOf(address(this));
            if (_balances[i] > 0) {
                _token.transfer(_lpTokenRecipient, _balances[i]);
            }
        }

        emit LiquidityChanged(
            address(_marketFactory),
            _marketId,
            msg.sender,
            _lpTokenRecipient,
            -int256(_collateralIn),
            int256(_poolAmountOut),
            _balances
        );
    }

    function removeLiquidity(
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _lpTokensIn,
        uint256 _minCollateralOut,
        address _collateralRecipient
    ) public returns (uint256 _collateralOut, uint256[] memory _balances) {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        require(_pool != BPool(0), "Pool needs to be created");

        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);

        _pool.transferFrom(msg.sender, address(this), _lpTokensIn);

        uint256[] memory exitPoolEstimate;
        {
            uint256[] memory minAmountsOut = new uint256[](_market.shareTokens.length);
            exitPoolEstimate = _pool.calcExitPool(_lpTokensIn, minAmountsOut);
            _pool.exitPool(_lpTokensIn, minAmountsOut);
        }

        // Find the number of sets to sell.
        uint256 _setsToSell = MAX_UINT;
        for (uint256 i = 0; i < _market.shareTokens.length; i++) {
            uint256 _acquiredTokenBalance = exitPoolEstimate[i];
            if (_acquiredTokenBalance < _setsToSell) _setsToSell = _acquiredTokenBalance;
        }

        // Must be a multiple of share factor.
        _setsToSell = (_setsToSell / _marketFactory.shareFactor()) * _marketFactory.shareFactor();

        bool _resolved = _marketFactory.isMarketResolved(_marketId);
        if (_resolved) {
            _collateralOut = _marketFactory.claimWinnings(_marketId, _collateralRecipient);
        } else {
            _collateralOut = _marketFactory.burnShares(_marketId, _setsToSell, _collateralRecipient);
        }
        require(_collateralOut > _minCollateralOut, "Amount of collateral returned too low.");

        // Transfer the remaining shares back to _collateralRecipient.
        _balances = new uint256[](_market.shareTokens.length);
        for (uint256 i = 0; i < _market.shareTokens.length; i++) {
            OwnedERC20 _token = _market.shareTokens[i];
            if (_resolved && _token == _market.winner) continue; // all winning shares claimed when market is resolved
            _balances[i] = exitPoolEstimate[i] - _setsToSell;
            if (_balances[i] > 0) {
                _token.transfer(_collateralRecipient, _balances[i]);
            }
        }

        emit LiquidityChanged(
            address(_marketFactory),
            _marketId,
            msg.sender,
            _collateralRecipient,
            int256(_collateralOut),
            -int256(_lpTokensIn),
            _balances
        );
    }

    function buy(
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _outcome,
        uint256 _collateralIn,
        uint256 _minTokensOut
    ) external returns (uint256) {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        require(_pool != BPool(0), "Pool needs to be created");

        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);

        IERC20Full _collateral = _marketFactory.collateral();
        _collateral.transferFrom(msg.sender, address(this), _collateralIn);
        uint256 _sets = _marketFactory.calcShares(_collateralIn);
        _marketFactory.mintShares(_marketId, _sets, address(this));

        uint256 _totalDesiredOutcome = _sets;
        {
            OwnedERC20 _desiredToken = _market.shareTokens[_outcome];

            for (uint256 i = 0; i < _market.shareTokens.length; i++) {
                if (i == _outcome) continue;
                OwnedERC20 _token = _market.shareTokens[i];
                (uint256 _acquiredToken, ) =
                    _pool.swapExactAmountIn(address(_token), _sets, address(_desiredToken), 0, MAX_UINT);
                _totalDesiredOutcome += _acquiredToken;
            }
            require(_totalDesiredOutcome >= _minTokensOut, "Slippage exceeded");

            _desiredToken.transfer(msg.sender, _totalDesiredOutcome);
        }

        emit SharesSwapped(
            address(_marketFactory),
            _marketId,
            msg.sender,
            _outcome,
            -int256(_collateralIn),
            int256(_totalDesiredOutcome),
            bdiv(_sets, _totalDesiredOutcome)
        );

        return _totalDesiredOutcome;
    }

    function sellForCollateral(
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        uint256 _outcome,
        uint256[] memory _shareTokensIn,
        uint256 _minSetsOut
    ) external returns (uint256) {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        require(_pool != BPool(0), "Pool needs to be created");
        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);

        uint256 _setsOut = MAX_UINT;
        uint256 _totalUndesiredTokensIn = 0;
        for (uint256 i = 0; i < _market.shareTokens.length; i++) {
            _totalUndesiredTokensIn += _shareTokensIn[i];
        }

        {
            _market.shareTokens[_outcome].transferFrom(msg.sender, address(this), _totalUndesiredTokensIn);
            _market.shareTokens[_outcome].approve(address(_pool), MAX_UINT);

            for (uint256 i = 0; i < _market.shareTokens.length; i++) {
                if (i == _outcome) continue;
                OwnedERC20 _token = _market.shareTokens[i];
                (uint256 tokenAmountOut, ) =
                    _pool.swapExactAmountIn(
                        address(_market.shareTokens[_outcome]),
                        _shareTokensIn[i],
                        address(_token),
                        0,
                        MAX_UINT
                    );

                //Ensure tokenAmountOut is a multiple of shareFactor.
                tokenAmountOut = (tokenAmountOut / _marketFactory.shareFactor()) * _marketFactory.shareFactor();
                if (tokenAmountOut < _setsOut) _setsOut = tokenAmountOut;
            }

            require(_setsOut >= _minSetsOut, "Minimum sets not available.");
            _marketFactory.burnShares(_marketId, _setsOut, msg.sender);
        }

        // Transfer undesired token balance back.
        for (uint256 i = 0; i < _market.shareTokens.length; i++) {
            OwnedERC20 _token = _market.shareTokens[i];
            uint256 _balance = _token.balanceOf(address(this));
            if (_balance > 0) {
                _token.transfer(msg.sender, _balance);
            }
        }

        uint256 _collateralOut = _marketFactory.calcCost(_setsOut);
        emit SharesSwapped(
            address(_marketFactory),
            _marketId,
            msg.sender,
            _outcome,
            int256(_collateralOut),
            -int256(_totalUndesiredTokensIn),
            bdiv(_setsOut, _totalUndesiredTokensIn)
        );

        return _collateralOut;
    }

    // Returns an array of token values for the outcomes of the market, relative to the first outcome.
    // So the first outcome is 10**18 and all others are higher or lower.
    // Prices can be derived due to the fact that the total of all outcome shares equals one collateral, possibly with a scaling factor,
    function tokenRatios(AbstractMarketFactoryV3 _marketFactory, uint256 _marketId)
        external
        view
        returns (uint256[] memory)
    {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        // Pool does not exist. Do not want to revert because multicall.
        if (_pool == BPool(0)) {
            return new uint256[](0);
        }

        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);
        address _basisToken = address(_market.shareTokens[0]);
        uint256[] memory _ratios = new uint256[](_market.shareTokens.length);
        _ratios[0] = 10**18;
        for (uint256 i = 1; i < _market.shareTokens.length; i++) {
            uint256 _price = _pool.getSpotPrice(_basisToken, address(_market.shareTokens[i]));
            _ratios[i] = _price;
        }
        return _ratios;
    }

    function getPoolBalances(AbstractMarketFactoryV3 _marketFactory, uint256 _marketId)
        external
        view
        returns (uint256[] memory)
    {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        // Pool does not exist. Do not want to revert because multicall.
        if (_pool == BPool(0)) {
            return new uint256[](0);
        }

        address[] memory _tokens = _pool.getCurrentTokens();
        uint256[] memory _balances = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _balances[i] = _pool.getBalance(_tokens[i]);
        }
        return _balances;
    }

    function getPoolWeights(AbstractMarketFactoryV3 _marketFactory, uint256 _marketId)
        external
        view
        returns (uint256[] memory)
    {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        // Pool does not exist. Do not want to revert because multicall.
        if (_pool == BPool(0)) {
            return new uint256[](0);
        }

        address[] memory _tokens = _pool.getCurrentTokens();
        uint256[] memory _weights = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _weights[i] = _pool.getDenormalizedWeight(_tokens[i]);
        }
        return _weights;
    }

    function getSwapFee(AbstractMarketFactoryV3 _marketFactory, uint256 _marketId) external view returns (uint256) {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        return _pool.getSwapFee();
    }

    function getPoolTokenBalance(
        AbstractMarketFactoryV3 _marketFactory,
        uint256 _marketId,
        address _user
    ) external view returns (uint256) {
        BPool _pool = pools[address(_marketFactory)][_marketId];
        return _pool.balanceOf(_user);
    }

    function getPool(AbstractMarketFactoryV3 _marketFactory, uint256 _marketId) external view returns (BPool) {
        return pools[address(_marketFactory)][_marketId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/IERC20Full.sol";
import "../balancer/BPool.sol";
import "./TurboShareTokenFactory.sol";
import "./FeePot.sol";
import "../libraries/Rewardable.sol";

abstract contract AbstractMarketFactoryV3 is TurboShareTokenFactory, Ownable, Rewardable {
    using SafeMathUint256 for uint256;

    event MarketCreated(uint256 id, string[] names, uint256[] initialOdds);
    event MarketResolved(uint256 id, address winner, uint256 winnerIndex, string winnerName);
    event MarketActivated(uint256 id);

    event SharesMinted(uint256 id, uint256 amount, address receiver);
    event SharesBurned(uint256 id, uint256 amount, address receiver);
    event WinningsClaimed(
        uint256 id,
        address winningOutcome,
        uint256 winningIndex,
        string winningName,
        uint256 amount,
        uint256 settlementFee,
        uint256 payout,
        address indexed receiver
    );

    IERC20Full public collateral;
    FeePot public feePot;

    // fees are out of 1e18 and only apply to new markets
    uint256 public stakerFee;
    uint256 public settlementFee;
    uint256 public protocolFee;

    address public protocol; // collects protocol fees

    uint256 public accumulatedProtocolFee = 0;
    // settlement address => amount of collateral
    mapping(address => uint256) public accumulatedSettlementFees;

    // How many shares equals one collateral.
    // Necessary to account for math errors from small numbers in balancer.
    // shares = collateral / shareFactor
    // collateral = shares * shareFactor
    uint256 public shareFactor;

    struct Market {
        address settlementAddress;
        OwnedERC20[] shareTokens;
        OwnedERC20 winner;
        uint256 winnerIndex;
        uint256 settlementFee;
        uint256 protocolFee;
        uint256 stakerFee;
        uint256 creationTimestamp;
        uint256 resolutionTimestamp; // when winner is declared
        uint256[] initialOdds;
        bool active; // false if not ready to use or if resolved
    }
    Market[] internal markets;

    uint256 private constant MAX_UINT = 2**256 - 1;

    constructor(
        address _owner,
        IERC20Full _collateral,
        uint256 _shareFactor,
        FeePot _feePot,
        uint256[3] memory _fees, // staker, settlement, protocol
        address _protocol
    ) {
        owner = _owner; // controls fees for new markets
        collateral = _collateral;
        shareFactor = _shareFactor;
        feePot = _feePot;
        stakerFee = _fees[0];
        settlementFee = _fees[1];
        protocolFee = _fees[2];
        protocol = _protocol;

        _collateral.approve(address(_feePot), MAX_UINT);

        // First market is always empty so that marketid zero means "no market"
        markets.push(makeEmptyMarket());
    }

    // Returns an empty struct if the market doesn't exist.
    // Can check market existence before calling this by comparing _id against markets.length.
    // Can check market existence of the return struct by checking that shareTokens[0] isn't the null address
    function getMarket(uint256 _id) public view returns (Market memory) {
        if (_id >= markets.length) {
            return makeEmptyMarket();
        } else {
            return markets[_id];
        }
    }

    function marketCount() public view returns (uint256) {
        return markets.length;
    }

    // Returns factory-specific details about a market.
    // function getMarketDetails(uint256 _id) public view returns (MarketDetails memory);

    function mintShares(
        uint256 _id,
        uint256 _shareToMint,
        address _receiver
    ) public {
        require(markets.length > _id);
        require(markets[_id].active);

        uint256 _cost = calcCost(_shareToMint);
        collateral.transferFrom(msg.sender, address(this), _cost);

        Market memory _market = markets[_id];
        for (uint256 _i = 0; _i < _market.shareTokens.length; _i++) {
            _market.shareTokens[_i].trustedMint(_receiver, _shareToMint);
        }

        emit SharesMinted(_id, _shareToMint, _receiver);
    }

    function burnShares(
        uint256 _id,
        uint256 _sharesToBurn,
        address _receiver
    ) public returns (uint256) {
        require(markets.length > _id);
        require(markets[_id].active);

        Market memory _market = markets[_id];
        for (uint256 _i = 0; _i < _market.shareTokens.length; _i++) {
            // errors if sender doesn't have enough shares
            _market.shareTokens[_i].trustedBurn(msg.sender, _sharesToBurn);
        }

        uint256 _payout = calcCost(_sharesToBurn);
        uint256 _protocolFee = _payout.mul(_market.protocolFee).div(10**18);
        uint256 _stakerFee = _payout.mul(_market.stakerFee).div(10**18);
        _payout = _payout.sub(_protocolFee).sub(_stakerFee);

        accumulatedProtocolFee += _protocolFee;
        collateral.transfer(_receiver, _payout);
        feePot.depositFees(_stakerFee);

        emit SharesBurned(_id, _sharesToBurn, msg.sender);
        return _payout;
    }

    function claimWinnings(uint256 _id, address _receiver) public returns (uint256) {
        require(isMarketResolved(_id), "market unresolved");

        Market memory _market = markets[_id];
        uint256 _winningShares = _market.winner.trustedBurnAll(msg.sender);
        _winningShares = (_winningShares / shareFactor) * shareFactor; // remove unusable dust

        uint256 _payout = calcCost(_winningShares); // will fail if there are no winnings to claim
        uint256 _settlementFee = _payout.mul(_market.settlementFee).div(10**18);
        _payout = _payout.sub(_settlementFee);

        accumulatedSettlementFees[_market.settlementAddress] += _settlementFee;
        collateral.transfer(_receiver, _payout);

        uint256 _winningIndex = _market.winnerIndex;
        string memory _winningName = _market.winner.name();

        emit WinningsClaimed(
            _id,
            address(_market.winner),
            _winningIndex,
            _winningName,
            _winningShares,
            _settlementFee,
            _payout,
            _receiver
        );
        return _payout;
    }

    function claimManyWinnings(uint256[] memory _ids, address _receiver) public returns (uint256) {
        uint256 _totalWinnings = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            _totalWinnings = _totalWinnings.add(claimWinnings(_ids[i], _receiver));
        }
        return _totalWinnings;
    }

    function claimSettlementFees(address _receiver) public returns (uint256) {
        uint256 _fees = accumulatedSettlementFees[msg.sender];
        if (_fees > 0) {
            accumulatedSettlementFees[msg.sender] = 0;
            collateral.transfer(_receiver, _fees);
        }
        return _fees;
    }

    function claimProtocolFees() public returns (uint256) {
        require(msg.sender == protocol || msg.sender == address(this));
        uint256 _fees = accumulatedProtocolFee;
        if (_fees > 0) {
            accumulatedProtocolFee = 0;
            collateral.transfer(protocol, _fees);
        }
        return _fees;
    }

    function setSettlementFee(uint256 _newFee) external onlyOwner {
        settlementFee = _newFee;
    }

    function setStakerFee(uint256 _newFee) external onlyOwner {
        stakerFee = _newFee;
    }

    function setProtocolFee(uint256 _newFee) external onlyOwner {
        protocolFee = _newFee;
    }

    function setProtocol(address _newProtocol, bool _claimFirst) external onlyOwner {
        if (_claimFirst) {
            claimProtocolFees();
        }
        protocol = _newProtocol;
    }

    function startMarket(
        address _settlementAddress,
        string[] memory _names,
        uint256[] memory _initialOdds,
        bool _active
    ) internal returns (uint256 _marketId) {
        _marketId = markets.length;
        markets.push(
            Market(
                _settlementAddress,
                createShareTokens(_names, address(this)),
                OwnedERC20(0),
                0,
                settlementFee,
                protocolFee,
                stakerFee,
                block.timestamp,
                0,
                _initialOdds,
                _active
            )
        );
        emit MarketCreated(_marketId, _names, _initialOdds);
        if (_active) {
            emit MarketActivated(_marketId);
        }
    }

    function activateMarket(uint256 _marketId) internal {
        markets[_marketId].active = true;
        emit MarketActivated(_marketId);
    }

    function makeEmptyMarket() private pure returns (Market memory) {
        OwnedERC20[] memory _tokens = new OwnedERC20[](0);
        uint256[] memory _initialOdds = new uint256[](0);
        return Market(address(0), _tokens, OwnedERC20(0), 0, 0, 0, 0, 0, 0, _initialOdds, false);
    }

    function endMarket(uint256 _marketId, uint256 _winningOutcome) internal {
        Market storage _market = markets[_marketId];
        OwnedERC20 _winner = _market.shareTokens[_winningOutcome];

        _market.winner = _winner;
        _market.active = false;
        _market.winnerIndex = _winningOutcome;
        _market.resolutionTimestamp = block.timestamp;
        string memory _outcomeName = _winner.name();
        emit MarketResolved(_marketId, address(_winner), _winningOutcome, _outcomeName);
    }

    function isMarketResolved(uint256 _id) public view returns (bool) {
        Market memory _market = markets[_id];
        return _market.winner != OwnedERC20(0);
    }

    // shares => collateral
    // Shares must be both greater than (or equal to) and divisible by shareFactor.
    function calcCost(uint256 _shares) public view returns (uint256) {
        require(_shares >= shareFactor && _shares % shareFactor == 0);
        return _shares / shareFactor;
    }

    // collateral => shares
    function calcShares(uint256 _collateralIn) public view returns (uint256) {
        return _collateralIn * shareFactor;
    }

    function onTransferOwnership(address, address) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/IERC20Full.sol";
import "../balancer/BPool.sol";
import "./AbstractMarketFactoryV3.sol";
import "./FeePot.sol";
import "../libraries/SafeMathInt256.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "../libraries/CalculateLinesToBPoolOdds.sol";
import "../libraries/Versioned.sol";
import "../libraries/ManagedByLink.sol";
import "../libraries/Rewardable.sol";

contract CryptoMarketFactoryV3 is AbstractMarketFactoryV3, CalculateLinesToBPoolOdds, Versioned, ManagedByLink {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    event CoinAdded(uint256 indexed id, string name);

    event NewPrices(uint256 indexed nextResolutionTime, uint256[] markets, uint256[] prices);

    struct Coin {
        string name;
        AggregatorV3Interface priceFeed;
        uint256 price;
        uint8 imprecision; // how many decimals to truncate
        uint256[1] currentMarkets;
    }
    Coin[] public coins;

    enum MarketType {
        PriceUpDown // 0
    }
    enum PriceUpDownOutcome {
        Above, // 0
        NotAbove // 1
    }
    struct MarketDetails {
        MarketType marketType;
        uint256 coinIndex;
        uint256 creationPrice;
        uint256 resolutionPrice;
        uint256 resolutionTime; // price at given time; this is that time
    }
    // MarketId => MarketDetails
    mapping(uint256 => MarketDetails) internal marketDetails;

    uint256 public nextResolutionTime;

    constructor(
        address _owner,
        IERC20Full _collateral,
        uint256 _shareFactor,
        FeePot _feePot,
        uint256[3] memory _fees,
        address _protocol,
        address _linkNode
    )
        AbstractMarketFactoryV3(_owner, _collateral, _shareFactor, _feePot, _fees, _protocol)
        Versioned("v1.2.0")
        ManagedByLink(_linkNode)
    {
        string memory _name = "";
        coins.push(makeCoin(_name, AggregatorV3Interface(0), 0));
    }

    function getMarketDetails(uint256 _marketId) public view returns (MarketDetails memory) {
        return marketDetails[_marketId];
    }

    // NOTE: Trusts the owner not to add a coin twice.
    // Returns the coin index.
    function addCoin(
        string calldata _name,
        AggregatorV3Interface _priceFeed,
        uint8 _imprecision
    ) external onlyOwner returns (uint256 _coinIndex) {
        Coin memory _coin = makeCoin(_name, _priceFeed, _imprecision);
        _coinIndex = coins.length;
        coins.push(_coin);
        emit CoinAdded(_coinIndex, _name);
    }

    function getCoin(uint256 _coinIndex) public view returns (Coin memory _coin) {
        _coin = coins[_coinIndex];
    }

    function getCoins() public view returns (Coin[] memory _coins) {
        _coins = new Coin[](coins.length);
        // Skip first coin because it's always the zeroed-out fake coin.
        for (uint256 i = 1; i < coins.length; i++) {
            _coins[i] = coins[i];
        }
    }

    // Iterates over all coins.
    // If markets do not exist for coin, create them.
    // Unless _nextResolutionTime is zero; then do not create new markets.
    // If markets for coin exist and are ready to resolve, resolve them and create new markets.
    // Else, error.
    //
    // Assume that _roundIds has a dummy value at index 0, and is 1 indexed like the
    // coins array.
    function createAndResolveMarkets(uint80[] calldata _roundIds, uint256 _nextResolutionTime) public onlyLinkNode {
        // If market creation was stopped then it can be started again.
        // If market creation wasn't stopped then you must wait for market end time to resolve.
        require(block.timestamp >= nextResolutionTime, "Must wait for market resolution");
        require(_roundIds.length == coins.length, "Must specify one roundId for each coin");

        uint256 _resolutionTime = nextResolutionTime;
        nextResolutionTime = _nextResolutionTime;

        uint256[] memory _prices = new uint256[](coins.length - 1);
        uint256[] memory _newMarketIds = new uint256[](coins.length - 1);
        // Start at 1 to skip the fake Coin in the 0 index
        for (uint256 i = 1; i < coins.length; i++) {
            (_prices[i - 1], _newMarketIds[i - 1]) = createAndResolveMarketsForCoin(i, _resolutionTime, _roundIds[i]);
        }

        emit NewPrices(nextResolutionTime, _newMarketIds, _prices);
    }

    function createAndResolveMarketsForCoin(
        uint256 _coinIndex,
        uint256 _resolutionTime,
        uint80 _roundId
    ) internal returns (uint256 _price, uint256 _newMarketId) {
        Coin memory _coin = coins[_coinIndex];
        (uint256 _fullPrice, uint256 _newPrice) = getPrice(_coin, _roundId, _resolutionTime);

        // resolve markets
        if (_coin.currentMarkets[uint256(MarketType.PriceUpDown)] != 0) {
            resolvePriceUpDownMarket(_coin, _newPrice, _fullPrice);
        }

        // update price only AFTER resolution
        coins[_coinIndex].price = _newPrice;

        // link node sets nextResolutionTime to zero to signify "do not create markets after resolution"
        if (nextResolutionTime == 0) {
            return (0, 0);
        }

        // create markets
        _newMarketId = createPriceUpDownMarket(_coinIndex, linkNode, _newPrice);
        coins[_coinIndex].currentMarkets[uint256(MarketType.PriceUpDown)] = _newMarketId;

        return (_newPrice, _newMarketId);
    }

    function resolvePriceUpDownMarket(
        Coin memory _coin,
        uint256 _newPrice,
        uint256 _fullPrice
    ) internal {
        uint256 _marketId = _coin.currentMarkets[uint256(MarketType.PriceUpDown)];

        uint256 _winningOutcome;
        if (_newPrice > _coin.price) {
            _winningOutcome = uint256(PriceUpDownOutcome.Above);
        } else {
            _winningOutcome = uint256(PriceUpDownOutcome.NotAbove);
        }

        endMarket(_marketId, _winningOutcome);
        marketDetails[_marketId].resolutionPrice = _fullPrice;
    }

    function createPriceUpDownMarket(
        uint256 _coinIndex,
        address _creator,
        uint256 _newPrice
    ) internal returns (uint256 _id) {
        string[] memory _outcomes = new string[](2);
        _outcomes[uint256(PriceUpDownOutcome.Above)] = "Above";
        _outcomes[uint256(PriceUpDownOutcome.NotAbove)] = "Not Above";

        _id = startMarket(_creator, _outcomes, evenOdds(false, 2), true);
        marketDetails[_id] = MarketDetails(MarketType.PriceUpDown, _coinIndex, _newPrice, 0, nextResolutionTime);
    }

    // Returns the price based on a few factors.
    // If _roundId is zero then it returns the latest price.
    // Else, it returns the price for that round,
    //       but errors if that isn't the first round after the resolution time.
    // The price is then altered to match the desired precision.
    function getPrice(
        Coin memory _coin,
        uint80 _roundId,
        uint256 _resolutionTime
    ) internal view returns (uint256 _fullPrice, uint256 _truncatedPrice) {
        if (_roundId == 0) {
            (, int256 _rawPrice, , , ) = _coin.priceFeed.latestRoundData();
            require(_rawPrice >= 0, "Price from feed is negative");
            _fullPrice = uint256(_rawPrice);
        } else {
            (, int256 _rawPrice, , uint256 updatedAt, ) = _coin.priceFeed.getRoundData(_roundId);
            require(_rawPrice >= 0, "Price from feed is negative");
            require(updatedAt >= _resolutionTime, "Price hasn't been updated yet");

            // if resolution time is zero then market creation was stopped, so the previous round doesn't matter
            if (_resolutionTime != 0) {
                (, , , uint256 _previousRoundTime, ) = _coin.priceFeed.getRoundData(previousRound(_roundId));
                require(_previousRoundTime < _resolutionTime, "Must use first round after resolution time");
            }

            _fullPrice = uint256(_rawPrice);
        }

        // The precision is how many decimals the price has. Zero is dollars, 2 includes cents, 3 is tenths of a cent, etc.
        // Our resolution rules want a certain precision. Like BTC is to the dollar and MATIC is to the cent.
        // If somehow the decimals are larger than the desired precision then add zeroes to the end to meet the precision.
        // This does not change the resolution outcome but does guard against decimals() changing and therefore altering the basis.

        uint8 _precision = _coin.priceFeed.decimals(); // probably constant but that isn't guaranteed, so query each time
        if (_precision > _coin.imprecision) {
            uint8 _truncate = _precision - _coin.imprecision;
            _truncatedPrice = _fullPrice / (10**_truncate);
        } else if (_precision < _coin.imprecision) {
            uint8 _greaten = _coin.imprecision - _precision;
            _truncatedPrice = _fullPrice * (10**_greaten);
        } else {
            _truncatedPrice = _fullPrice;
        }

        // Round up because that cleanly fits Above/Not-Above.
        if (_truncatedPrice != _fullPrice) {
            _truncatedPrice += 1;
        }
    }

    function makeCoin(
        string memory _name,
        AggregatorV3Interface _priceFeed,
        uint8 _imprecision
    ) internal pure returns (Coin memory _coin) {
        uint256[1] memory _currentMarkets = [uint256(0)];
        _coin = Coin(_name, _priceFeed, 0, _imprecision, _currentMarkets);
    }

    // The roundId is the encoding of two parts: the phase and the phase-specific round id.
    // To find the previous roundId:
    // 1. extract the phase and phase-specific round (I call these _phaseId and _roundId)
    // 2. decrement the phase-specific round
    // 3. re-encode the phase and phase-specific round.
    uint256 private constant PHASE_OFFSET = 64;

    function previousRound(uint80 _fullRoundId) internal pure returns (uint80) {
        uint256 _phaseId = uint256(uint16(_fullRoundId >> PHASE_OFFSET));
        uint64 _roundId = uint64(_fullRoundId) - 1;
        return uint80((_phaseId << PHASE_OFFSET) | _roundId);
    }

    function getRewardEndTime(uint256 _eventId) public override returns (uint256) {
        return getMarketDetails(_eventId).resolutionTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/SafeMathUint256.sol";
import "../libraries/IERC20Full.sol";

contract FeePot is ERC20 {
    using SafeMathUint256 for uint256;

    uint256 internal constant magnitude = 2**128;

    IERC20Full public collateral;
    IERC20Full public reputationToken;

    uint256 public magnifiedFeesPerShare;

    mapping(address => uint256) public magnifiedFeesCorrections;
    mapping(address => uint256) public storedFees;

    uint256 public feeReserve;

    constructor(IERC20Full _collateral, IERC20Full _reputationToken)
        ERC20(
            string(abi.encodePacked("S_", _reputationToken.symbol())),
            string(abi.encodePacked("S_", _reputationToken.symbol()))
        )
    {
        collateral = _collateral;
        reputationToken = _reputationToken;

        require(_collateral != IERC20Full(0));
    }

    function depositFees(uint256 _amount) public returns (bool) {
        collateral.transferFrom(msg.sender, address(this), _amount);
        uint256 _totalSupply = totalSupply(); // after collateral.transferFrom to prevent reentrancy causing stale totalSupply
        if (_totalSupply == 0) {
            feeReserve = feeReserve.add(_amount);
            return true;
        }
        if (feeReserve > 0) {
            _amount = _amount.add(feeReserve);
            feeReserve = 0;
        }
        magnifiedFeesPerShare = magnifiedFeesPerShare.add((_amount).mul(magnitude) / _totalSupply);
        return true;
    }

    function withdrawableFeesOf(address _owner) public view returns (uint256) {
        return earnedFeesOf(_owner).add(storedFees[_owner]);
    }

    function earnedFeesOf(address _owner) public view returns (uint256) {
        uint256 _ownerBalance = balanceOf(_owner);
        uint256 _magnifiedFees = magnifiedFeesPerShare.mul(_ownerBalance);
        return _magnifiedFees.sub(magnifiedFeesCorrections[_owner]) / magnitude;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        storedFees[_from] = storedFees[_from].add(earnedFeesOf(_from));
        super._transfer(_from, _to, _amount);

        magnifiedFeesCorrections[_from] = magnifiedFeesPerShare.mul(balanceOf(_from));
        magnifiedFeesCorrections[_to] = magnifiedFeesCorrections[_to].add(magnifiedFeesPerShare.mul(_amount));
    }

    function stake(uint256 _amount) external returns (bool) {
        reputationToken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesCorrections[msg.sender].add(
            magnifiedFeesPerShare.mul(_amount)
        );
        return true;
    }

    function exit(uint256 _amount) external returns (bool) {
        redeemInternal(msg.sender);
        _burn(msg.sender, _amount);
        reputationToken.transfer(msg.sender, _amount);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesPerShare.mul(balanceOf(msg.sender));
        return true;
    }

    function redeem() public returns (bool) {
        redeemInternal(msg.sender);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesPerShare.mul(balanceOf(msg.sender));
        return true;
    }

    function redeemInternal(address _account) internal {
        uint256 _withdrawableFees = withdrawableFeesOf(_account);
        if (_withdrawableFees > 0) {
            storedFees[_account] = 0;
            collateral.transfer(_account, _withdrawableFees);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/IERC20Full.sol";
import "../balancer/BPool.sol";
import "./AbstractMarketFactoryV3.sol";
import "./FeePot.sol";
import "../libraries/SafeMathInt256.sol";
import "./MMAMarketFactoryV3.sol";
import "./AMMFactory.sol";
import "./CryptoMarketFactoryV3.sol";
import "./NBAMarketFactoryV3.sol";
import "../rewards/MasterChef.sol";

// Helper contract for grabbing huge amounts of data without overloading multicall.
abstract contract Fetcher {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    struct CollateralBundle {
        address addr;
        string symbol;
        uint256 decimals;
    }

    struct MarketFactoryBundle {
        uint256 shareFactor;
        uint256 stakerFee;
        uint256 settlementFee;
        uint256 protocolFee;
        FeePot feePot;
        CollateralBundle collateral;
        uint256 marketCount;
    }

    struct PoolBundle {
        address addr;
        uint256[] tokenRatios;
        uint256[] balances;
        uint256[] weights;
        uint256 swapFee;
        uint256 totalSupply;
    }

    struct StaticMarketBundle {
        AbstractMarketFactoryV3 factory;
        uint256 marketId;
        PoolBundle pool;
        MasterChef.PoolStatusInfo rewards;
        OwnedERC20[] shareTokens;
        uint256 creationTimestamp;
        OwnedERC20 winner;
        uint256[] initialOdds;
    }

    struct DynamicMarketBundle {
        AbstractMarketFactoryV3 factory;
        uint256 marketId;
        PoolBundle pool;
        OwnedERC20 winner;
    }

    string public marketType;
    string public version;

    constructor(string memory _type, string memory _version) {
        marketType = _type;
        version = _version;
    }

    function buildCollateralBundle(IERC20Full _collateral) internal view returns (CollateralBundle memory _bundle) {
        _bundle.addr = address(_collateral);
        _bundle.symbol = _collateral.symbol();
        _bundle.decimals = _collateral.decimals();
    }

    function buildMarketFactoryBundle(AbstractMarketFactoryV3 _marketFactory)
        internal
        view
        returns (MarketFactoryBundle memory _bundle)
    {
        _bundle.shareFactor = _marketFactory.shareFactor();
        _bundle.stakerFee = _marketFactory.stakerFee();
        _bundle.settlementFee = _marketFactory.settlementFee();
        _bundle.protocolFee = _marketFactory.protocolFee();
        _bundle.feePot = _marketFactory.feePot();
        _bundle.collateral = buildCollateralBundle(_marketFactory.collateral());
        _bundle.marketCount = _marketFactory.marketCount();
    }

    function buildStaticMarketBundle(
        AbstractMarketFactoryV3 _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _marketId
    ) internal view returns (StaticMarketBundle memory _bundle) {
        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);
        _bundle.factory = _marketFactory;
        _bundle.marketId = _marketId;
        _bundle.shareTokens = _market.shareTokens;
        _bundle.creationTimestamp = _market.creationTimestamp;
        _bundle.winner = _market.winner;
        _bundle.pool = buildPoolBundle(_marketFactory, _ammFactory, _marketId);
        _bundle.initialOdds = _market.initialOdds;
    }

    function buildDynamicMarketBundle(
        AbstractMarketFactoryV3 _marketFactory,
        AMMFactory _ammFactory,
        uint256 _marketId
    ) internal view returns (DynamicMarketBundle memory _bundle) {
        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);

        _bundle.factory = _marketFactory;
        _bundle.marketId = _marketId;
        _bundle.winner = _market.winner;
        _bundle.pool = buildPoolBundle(_marketFactory, _ammFactory, _marketId);
    }

    function buildPoolBundle(
        AbstractMarketFactoryV3 _marketFactory,
        AMMFactory _ammFactory,
        uint256 _marketId
    ) internal view returns (PoolBundle memory _bundle) {
        BPool _pool = _ammFactory.getPool(_marketFactory, _marketId);
        if (_pool == BPool(address(0))) return _bundle;

        _bundle.addr = address(_pool);
        _bundle.totalSupply = _pool.totalSupply();
        _bundle.swapFee = _ammFactory.getSwapFee(_marketFactory, _marketId);
        _bundle.balances = _ammFactory.getPoolBalances(_marketFactory, _marketId);
        _bundle.tokenRatios = _ammFactory.tokenRatios(_marketFactory, _marketId);
        _bundle.weights = _ammFactory.getPoolWeights(_marketFactory, _marketId);
    }

    function openOrHasWinningShares(AbstractMarketFactoryV3 _marketFactory, uint256 _marketId)
        internal
        view
        returns (bool)
    {
        AbstractMarketFactoryV3.Market memory _market = _marketFactory.getMarket(_marketId);
        if (_market.winner == OwnedERC20(address(0))) return true; // open
        return _market.winner.totalSupply() > 0; // has winning shares
    }
}

abstract contract SportsFetcher is Fetcher {
    struct SpecificMarketFactoryBundle {
        MarketFactoryBundle super;
    }

    struct StaticEventBundle {
        uint256 id;
        StaticMarketBundle[] markets;
        int256[] lines;
        uint256 estimatedStartTime;
        uint256 homeTeamId;
        uint256 awayTeamId;
        string homeTeamName;
        string awayTeamName;
        // Dynamics
        Sport.SportsEventStatus status;
        uint256 homeScore;
        uint256 awayScore;
    }

    struct DynamicEventBundle {
        uint256 id;
        Sport.SportsEventStatus status;
        DynamicMarketBundle[] markets;
        uint256 homeScore;
        uint256 awayScore;
    }

    function buildSpecificMarketFactoryBundle(address _marketFactory)
        internal
        view
        returns (SpecificMarketFactoryBundle memory _bundle)
    {
        _bundle.super = buildMarketFactoryBundle(AbstractMarketFactoryV3(_marketFactory));
    }

    function fetchInitial(
        address _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _offset,
        uint256 _total
    )
        public
        view
        returns (
            SpecificMarketFactoryBundle memory _marketFactoryBundle,
            StaticEventBundle[] memory _eventBundles,
            uint256 _lowestEventIndex
        )
    {
        _marketFactoryBundle = buildSpecificMarketFactoryBundle(_marketFactory);
        (_eventBundles, _lowestEventIndex) = buildStaticEventBundles(
            _marketFactory,
            _ammFactory,
            _masterChef,
            _offset,
            _total
        );
    }

    function fetchDynamic(
        address _marketFactory,
        AMMFactory _ammFactory,
        uint256 _offset,
        uint256 _total
    ) public view returns (DynamicEventBundle[] memory _bundles, uint256 _lowestEventIndex) {
        (_bundles, _lowestEventIndex) = buildDynamicEventBundles(_marketFactory, _ammFactory, _offset, _total);
    }

    function buildStaticEventBundles(
        address _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _offset,
        uint256 _total
    ) internal view returns (StaticEventBundle[] memory _bundles, uint256 _lowestEventIndex) {
        uint256[] memory _eventIds;
        (_eventIds, _lowestEventIndex) = listOfInterestingEvents(_marketFactory, _offset, _total);

        _total = _eventIds.length;
        _bundles = new StaticEventBundle[](_total);
        for (uint256 i; i < _total; i++) {
            _bundles[i] = buildStaticEventBundle(_marketFactory, _ammFactory, _masterChef, _eventIds[i]);
        }
    }

    function buildDynamicEventBundles(
        address _marketFactory,
        AMMFactory _ammFactory,
        uint256 _offset,
        uint256 _total
    ) internal view returns (DynamicEventBundle[] memory _bundles, uint256 _lowestEventIndex) {
        uint256[] memory _eventIds;
        (_eventIds, _lowestEventIndex) = listOfInterestingEvents(_marketFactory, _offset, _total);

        _total = _eventIds.length;
        _bundles = new DynamicEventBundle[](_total);
        for (uint256 i; i < _total; i++) {
            _bundles[i] = buildDynamicEventBundle(_marketFactory, _ammFactory, _eventIds[i]);
        }
    }

    function buildStaticEventBundle(
        address _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _eventId
    ) public view returns (StaticEventBundle memory _bundle) {
        Sport.SportsEvent memory _event = Sport(_marketFactory).getSportsEvent(_eventId);

        StaticMarketBundle[] memory _markets = new StaticMarketBundle[](_event.markets.length);
        for (uint256 i = 0; i < _markets.length; i++) {
            _markets[i] = buildStaticMarketBundle(
                AbstractMarketFactoryV3(_marketFactory),
                _ammFactory,
                _masterChef,
                _event.markets[i]
            );
        }

        _bundle.id = _eventId;
        _bundle.status = _event.status;
        _bundle.markets = _markets;
        _bundle.lines = _event.lines;
        _bundle.estimatedStartTime = _event.estimatedStartTime;
        _bundle.homeTeamId = _event.homeTeamId;
        _bundle.awayTeamId = _event.awayTeamId;
        _bundle.homeTeamName = _event.homeTeamName;
        _bundle.awayTeamName = _event.awayTeamName;
        _bundle.homeScore = _event.homeScore;
        _bundle.awayScore = _event.awayScore;
    }

    function buildDynamicEventBundle(
        address _marketFactory,
        AMMFactory _ammFactory,
        uint256 _eventId
    ) public view returns (DynamicEventBundle memory _bundle) {
        Sport.SportsEvent memory _event = Sport(_marketFactory).getSportsEvent(_eventId);

        DynamicMarketBundle[] memory _markets = new DynamicMarketBundle[](_event.markets.length);
        for (uint256 i = 0; i < _markets.length; i++) {
            _markets[i] = buildDynamicMarketBundle(
                AbstractMarketFactoryV3(_marketFactory),
                _ammFactory,
                _event.markets[i]
            );
        }

        _bundle.id = _eventId;
        _bundle.markets = _markets;
        _bundle.status = _event.status;
        _bundle.homeScore = _event.homeScore;
        _bundle.awayScore = _event.awayScore;
    }

    // Starts from the end of the events list because newer events are more interesting.
    // _offset is skipping all events, not just interesting events
    function listOfInterestingEvents(
        address _marketFactory,
        uint256 _offset,
        uint256 _total
    ) internal view returns (uint256[] memory _interestingEventIds, uint256 _eventIndex) {
        _interestingEventIds = new uint256[](_total);

        uint256 _eventCount = Sport(_marketFactory).eventCount();

        // No events so return nothing. (needed to avoid integer underflow below)
        if (_eventCount == 0) {
            return (new uint256[](0), 0);
        }

        uint256 _max = _eventCount;

        // No remaining events so return nothing. (needed to avoid integer underflow below)
        if (_offset > _max) {
            return (new uint256[](0), 0);
        }

        uint256 _collectedEvents = 0;
        _eventIndex = _max - _offset;
        while (true) {
            if (_collectedEvents >= _total) break;
            if (_eventIndex == 0) break;

            _eventIndex--; // starts out one too high, so this works

            (Sport.SportsEvent memory _event, uint256 _eventId) =
                Sport(_marketFactory).getSportsEventByIndex(_eventIndex);

            if (isEventInteresting(_event, AbstractMarketFactoryV3(_marketFactory))) {
                _interestingEventIds[_collectedEvents] = _eventId;
                _collectedEvents++;
            }
        }

        if (_total > _collectedEvents) {
            assembly {
                // shortens array
                mstore(_interestingEventIds, _collectedEvents)
            }
        }
    }

    function isEventInteresting(Sport.SportsEvent memory _event, AbstractMarketFactoryV3 _marketFactory)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _event.markets.length; i++) {
            uint256 _marketId = _event.markets[i];
            if (openOrHasWinningShares(_marketFactory, _marketId)) {
                return true;
            }
        }
        return false;
    }
}

contract NBAFetcher is SportsFetcher {
    constructor() Fetcher("NBA", "TBD") {}
}

contract MLBFetcher is SportsFetcher {
    constructor() Fetcher("MLB", "TBD") {}
}

contract MMAFetcher is SportsFetcher {
    constructor() Fetcher("MMA", "TBD") {}
}

contract NFLFetcher is SportsFetcher {
    constructor() Fetcher("NFL", "TBD") {}
}

contract CryptoFetcher is Fetcher {
    constructor() Fetcher("Crypto", "TBD") {}

    struct SpecificMarketFactoryBundle {
        MarketFactoryBundle super;
    }

    struct SpecificStaticMarketBundle {
        StaticMarketBundle super;
        uint8 marketType;
        uint256 coinIndex;
        uint256 creationPrice;
        uint256 resolutionTime;
        // Dynamics
        uint256 resolutionPrice;
    }

    struct SpecificDynamicMarketBundle {
        DynamicMarketBundle super;
        uint256 resolutionPrice;
    }

    function buildSpecificMarketFactoryBundle(address _marketFactory)
        internal
        view
        returns (SpecificMarketFactoryBundle memory _bundle)
    {
        _bundle.super = buildMarketFactoryBundle(CryptoMarketFactoryV3(_marketFactory));
    }

    function buildSpecificStaticMarketBundle(
        address _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _marketId
    ) internal view returns (SpecificStaticMarketBundle memory _bundle) {
        CryptoMarketFactoryV3.MarketDetails memory _details =
            CryptoMarketFactoryV3(_marketFactory).getMarketDetails(_marketId);
        _bundle.super = buildStaticMarketBundle(
            CryptoMarketFactoryV3(_marketFactory),
            _ammFactory,
            _masterChef,
            _marketId
        );
        _bundle.marketType = uint8(_details.marketType);
        _bundle.creationPrice = _details.creationPrice;
        _bundle.coinIndex = _details.coinIndex;
        _bundle.resolutionPrice = _details.resolutionPrice;
        _bundle.resolutionTime = _details.resolutionTime;
    }

    function buildSpecificDynamicMarketBundle(
        address _marketFactory,
        AMMFactory _ammFactory,
        uint256 _marketId
    ) internal view returns (SpecificDynamicMarketBundle memory _bundle) {
        CryptoMarketFactoryV3.MarketDetails memory _details =
            CryptoMarketFactoryV3(_marketFactory).getMarketDetails(_marketId);
        _bundle.super = buildDynamicMarketBundle(CryptoMarketFactoryV3(_marketFactory), _ammFactory, _marketId);
        _bundle.resolutionPrice = _details.resolutionPrice;
    }

    function fetchInitial(
        address _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _offset,
        uint256 _total
    )
        public
        view
        returns (
            SpecificMarketFactoryBundle memory _marketFactoryBundle,
            SpecificStaticMarketBundle[] memory _marketBundles,
            uint256 _lowestMarketIndex
        )
    {
        _marketFactoryBundle = buildSpecificMarketFactoryBundle(_marketFactory);

        uint256[] memory _marketIds;
        (_marketIds, _lowestMarketIndex) = listOfInterestingMarkets(_marketFactory, _offset, _total);

        _total = _marketIds.length;
        _marketBundles = new SpecificStaticMarketBundle[](_total);
        for (uint256 i; i < _total; i++) {
            _marketBundles[i] = buildSpecificStaticMarketBundle(
                _marketFactory,
                _ammFactory,
                _masterChef,
                _marketIds[i]
            );
        }
    }

    function fetchDynamic(
        address _marketFactory,
        AMMFactory _ammFactory,
        uint256 _offset,
        uint256 _total
    ) public view returns (SpecificDynamicMarketBundle[] memory _bundles, uint256 _lowestMarketIndex) {
        uint256[] memory _marketIds;
        (_marketIds, _lowestMarketIndex) = listOfInterestingMarkets(_marketFactory, _offset, _total);

        _total = _marketIds.length;
        _bundles = new SpecificDynamicMarketBundle[](_total);
        for (uint256 i; i < _total; i++) {
            _bundles[i] = buildSpecificDynamicMarketBundle(_marketFactory, _ammFactory, _marketIds[i]);
        }
    }

    // Starts from the end of the markets list because newer markets are more interesting.
    // _offset is skipping all markets, not just interesting markets
    function listOfInterestingMarkets(
        address _marketFactory,
        uint256 _offset,
        uint256 _total
    ) internal view returns (uint256[] memory _interestingMarketIds, uint256 _marketId) {
        _interestingMarketIds = new uint256[](_total);
        uint256 _max = AbstractMarketFactoryV3(_marketFactory).marketCount() - 1;

        // No markets so return nothing. (needed to prevent integer underflow below)
        if (_max == 0 || _offset >= _max) {
            return (new uint256[](0), 0);
        }

        // Starts at the end, less offset.
        // Stops before the 0th market since that market is always fake.
        uint256 _collectedMarkets = 0;
        _marketId = _max - _offset;

        while (true) {
            if (openOrHasWinningShares(AbstractMarketFactoryV3(_marketFactory), _marketId)) {
                _interestingMarketIds[_collectedMarkets] = _marketId;
                _collectedMarkets++;
            }

            if (_collectedMarkets >= _total) break;
            if (_marketId == 1) break; // skipping 0th market, which is fake
            _marketId--; // starts out oone too high, so this works
        }

        if (_total > _collectedMarkets) {
            assembly {
                // shortens array
                mstore(_interestingMarketIds, _collectedMarkets)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Fetcher.sol";
import "./Grouped.sol";

abstract contract GroupFetcher is Fetcher {
    struct SpecificMarketFactoryBundle {
        MarketFactoryBundle super;
    }

    struct StaticGroupBundle {
        uint256 id;
        string name;
        StaticMarketBundle[] markets;
        string[] marketNames;
        StaticMarketBundle invalidMarket;
        string invalidMarketName;
        uint256 endTime;
        string category;
        // Dynamics
        Grouped.GroupStatus status;
    }

    struct DynamicGroupBundle {
        uint256 id;
        Grouped.GroupStatus status;
        DynamicMarketBundle[] markets;
        DynamicMarketBundle invalidMarket;
    }

    function buildSpecificMarketFactoryBundle(address _marketFactory)
        internal
        view
        returns (SpecificMarketFactoryBundle memory _bundle)
    {
        _bundle.super = buildMarketFactoryBundle(AbstractMarketFactoryV3(_marketFactory));
    }

    function fetchInitial(
        address _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _offset,
        uint256 _total
    )
        public
        view
        returns (
            SpecificMarketFactoryBundle memory _marketFactoryBundle,
            StaticGroupBundle[] memory _groupBundles,
            uint256 _lowestGroupIndex
        )
    {
        _marketFactoryBundle = buildSpecificMarketFactoryBundle(_marketFactory);
        (_groupBundles, _lowestGroupIndex) = buildStaticGroupBundles(
            _marketFactory,
            _ammFactory,
            _masterChef,
            _offset,
            _total
        );
    }

    function fetchDynamic(
        address _marketFactory,
        AMMFactory _ammFactory,
        uint256 _offset,
        uint256 _total
    ) public view returns (DynamicGroupBundle[] memory _bundles, uint256 _lowestGroupIndex) {
        (_bundles, _lowestGroupIndex) = buildDynamicGroupBundles(_marketFactory, _ammFactory, _offset, _total);
    }

    function buildStaticGroupBundles(
        address _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _offset,
        uint256 _total
    ) internal view returns (StaticGroupBundle[] memory _bundles, uint256 _lowestGroupIndex) {
        uint256[] memory _groupIds;
        (_groupIds, _lowestGroupIndex) = listOfInterestingGroups(_marketFactory, _offset, _total);

        _total = _groupIds.length;
        _bundles = new StaticGroupBundle[](_total);
        for (uint256 i; i < _total; i++) {
            _bundles[i] = buildStaticGroupBundle(_marketFactory, _ammFactory, _masterChef, _groupIds[i]);
        }
    }

    function buildDynamicGroupBundles(
        address _marketFactory,
        AMMFactory _ammFactory,
        uint256 _offset,
        uint256 _total
    ) internal view returns (DynamicGroupBundle[] memory _bundles, uint256 _lowestGroupIndex) {
        uint256[] memory _groupIds;
        (_groupIds, _lowestGroupIndex) = listOfInterestingGroups(_marketFactory, _offset, _total);

        _total = _groupIds.length;
        _bundles = new DynamicGroupBundle[](_total);
        for (uint256 i; i < _total; i++) {
            _bundles[i] = buildDynamicGroupBundle(_marketFactory, _ammFactory, _groupIds[i]);
        }
    }

    function buildStaticGroupBundle(
        address _marketFactory,
        AMMFactory _ammFactory,
        MasterChef _masterChef,
        uint256 _groupId
    ) public view returns (StaticGroupBundle memory _bundle) {
        Grouped.MarketGroup memory _group = Grouped(_marketFactory).getGroup(_groupId);

        StaticMarketBundle[] memory _markets = new StaticMarketBundle[](_group.markets.length);
        for (uint256 i = 0; i < _markets.length; i++) {
            _markets[i] = buildStaticMarketBundle(
                AbstractMarketFactoryV3(_marketFactory),
                _ammFactory,
                _masterChef,
                _group.markets[i]
            );
        }

        _bundle.id = _groupId;
        _bundle.name = _group.name;
        _bundle.status = _group.status;
        _bundle.markets = _markets;
        _bundle.endTime = _group.endTime;
        _bundle.invalidMarket = buildStaticMarketBundle(
            AbstractMarketFactoryV3(_marketFactory),
            _ammFactory,
            _masterChef,
            _group.invalidMarket
        );
        _bundle.invalidMarketName = _group.invalidMarketName;
        _bundle.marketNames = _group.marketNames;
        _bundle.category = _group.category;
    }

    function buildDynamicGroupBundle(
        address _marketFactory,
        AMMFactory _ammFactory,
        uint256 _groupId
    ) public view returns (DynamicGroupBundle memory _bundle) {
        Grouped.MarketGroup memory _group = Grouped(_marketFactory).getGroup(_groupId);

        DynamicMarketBundle[] memory _markets = new DynamicMarketBundle[](_group.markets.length);
        for (uint256 i = 0; i < _markets.length; i++) {
            _markets[i] = buildDynamicMarketBundle(
                AbstractMarketFactoryV3(_marketFactory),
                _ammFactory,
                _group.markets[i]
            );
        }

        _bundle.id = _groupId;
        _bundle.markets = _markets;
        _bundle.invalidMarket = buildDynamicMarketBundle(
            AbstractMarketFactoryV3(_marketFactory),
            _ammFactory,
            _group.invalidMarket
        );
        _bundle.status = _group.status;
    }

    // Starts from the end of the groups list because newer groups are more interesting.
    // _offset is skipping all groups, not just interesting groups
    function listOfInterestingGroups(
        address _marketFactory,
        uint256 _offset,
        uint256 _total
    ) internal view returns (uint256[] memory _interestingGroupIds, uint256 _groupIndex) {
        _interestingGroupIds = new uint256[](_total);

        uint256 _groupCount = Grouped(_marketFactory).groupCount();

        // No groups so return nothing. (needed to avoid integer underflow below)
        if (_groupCount == 0) {
            return (new uint256[](0), 0);
        }

        uint256 _max = _groupCount;

        // No remaining groups so return nothing. (needed to avoid integer underflow below)
        if (_offset > _max) {
            return (new uint256[](0), 0);
        }

        uint256 _collectedGroups = 0;
        _groupIndex = _max - _offset;
        while (true) {
            if (_collectedGroups >= _total) break;
            if (_groupIndex == 0) break;

            _groupIndex--; // starts out one too high, so this works

            (Grouped.MarketGroup memory _group, uint256 _groupId) =
                Grouped(_marketFactory).getGroupByIndex(_groupIndex);

            if (isGroupInteresting(_group, AbstractMarketFactoryV3(_marketFactory))) {
                _interestingGroupIds[_collectedGroups] = _groupId;
                _collectedGroups++;
            }
        }

        if (_total > _collectedGroups) {
            assembly {
                // shortens array
                mstore(_interestingGroupIds, _collectedGroups)
            }
        }
    }

    function isGroupInteresting(Grouped.MarketGroup memory _group, AbstractMarketFactoryV3 _marketFactory)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _group.markets.length; i++) {
            uint256 _marketId = _group.markets[i];
            if (openOrHasWinningShares(_marketFactory, _marketId)) {
                return true;
            }
        }
        if (openOrHasWinningShares(_marketFactory, _group.invalidMarket)) {
            return true;
        }

        return false;
    }
}

contract FuturesFetcher is GroupFetcher {
    constructor() Fetcher("Futures", "TBD") {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./AbstractMarketFactoryV3.sol";
import "../libraries/CalculateLinesToBPoolOdds.sol";
import "./GroupFetcher.sol";

abstract contract Grouped is AbstractMarketFactoryV3, CalculateLinesToBPoolOdds {
    event GroupCreated(uint256 indexed id, uint256 endTime, uint256 invalidMarketId, string invalidMarketName);
    event GroupMarketAdded(uint256 indexed groupId, uint256 marketId, string marketName);
    event GroupFinalizing(uint256 indexed groupId, uint256 winningMarketIndex);
    event GroupResolved(uint256 indexed id, bool valid);

    enum GroupStatus {Unknown, Scheduled, Finalizing, Final, Invalid}

    struct MarketGroup {
        GroupStatus status;
        string name;
        uint256[] markets;
        string[] marketNames;
        uint256 invalidMarket;
        string invalidMarketName;
        uint256 endTime;
        string category;
        uint256 winningMarketIndex; // ignore when status is Scheduled. MAX_UINT is invalid
    }
    // GroupId => MarketGroup
    mapping(uint256 => MarketGroup) public marketGroups;
    uint256[] public listOfMarketGroups;

    // For regular markets, YES means the team won and NO means the team did not win.
    // For the invalid market, YES means none of the teams won and NO means a team won.
    uint256 constant OUTCOME_NO = 0;
    uint256 constant OUTCOME_YES = 1;

    uint256 constant MAX_UINT = 2**256 - 1;

    function groupCount() public view returns (uint256) {
        return listOfMarketGroups.length;
    }

    function getGroup(uint256 _groupId) public view returns (MarketGroup memory) {
        return marketGroups[_groupId];
    }

    function getGroupByIndex(uint256 _index) public view returns (MarketGroup memory _group, uint256 _groupId) {
        _groupId = listOfMarketGroups[_index];
        _group = getGroup(_groupId);
    }

    function startCreatingMarketGroup(
        uint256 _groupId,
        string memory _groupName,
        uint256 _endTime,
        string memory _invalidMarketName,
        string memory _category
    ) internal {
        require(marketGroups[_groupId].status == GroupStatus.Unknown, "group exists");

        listOfMarketGroups.push(_groupId);
        marketGroups[_groupId].status = GroupStatus.Scheduled;
        marketGroups[_groupId].name = _groupName;
        marketGroups[_groupId].endTime = _endTime;
        marketGroups[_groupId].category = _category;

        uint256 _invalidMarket = startMarket(msg.sender, buildOutcomesNames(_invalidMarketName), invalidOdds(), true);
        marketGroups[_groupId].invalidMarket = _invalidMarket;
        marketGroups[_groupId].invalidMarketName = _invalidMarketName;

        emit GroupCreated(_groupId, _endTime, _invalidMarket, _invalidMarketName);
        emit GroupMarketAdded(_groupId, _invalidMarket, _invalidMarketName);
    }

    function addMarketToMarketGroup(
        uint256 _groupId,
        string memory _marketName,
        uint256[] memory _odds
    ) internal {
        require(marketGroups[_groupId].status == GroupStatus.Scheduled, "group must be Scheduled");

        uint256 _marketId = startMarket(msg.sender, buildOutcomesNames(_marketName), _odds, true);
        marketGroups[_groupId].markets.push(_marketId);
        marketGroups[_groupId].marketNames.push(_marketName);
        emit GroupMarketAdded(_groupId, _marketId, _marketName);
    }

    // Use MAX_UINT for _winningMarketIndex to indicate INVALID
    function startResolvingMarketGroup(uint256 _groupId, uint256 _winningMarketIndex) internal {
        bool _isInvalid = _winningMarketIndex == MAX_UINT;
        MarketGroup memory _group = marketGroups[_groupId];

        require(_group.status == GroupStatus.Scheduled, "group not Scheduled");

        resolveInvalidMarket(_group, _isInvalid);
        marketGroups[_groupId].status = GroupStatus.Finalizing;
        marketGroups[_groupId].winningMarketIndex = _winningMarketIndex;
        emit GroupFinalizing(_groupId, _winningMarketIndex);
    }

    function resolveFinalizingGroupMarket(uint256 _groupId, uint256 _marketIndex) internal {
        MarketGroup memory _group = marketGroups[_groupId];
        require(_group.status == GroupStatus.Finalizing, "must be finalizing");

        uint256 _marketId = _group.markets[_marketIndex];
        bool _wins = _marketIndex == _group.winningMarketIndex;
        resolveGroupMarket(_marketId, _wins);
    }

    function finalizeMarketGroup(uint256 _groupId) internal {
        MarketGroup storage _group = marketGroups[_groupId];
        require(_group.status == GroupStatus.Finalizing);

        bool _valid = _group.winningMarketIndex != MAX_UINT;

        _group.status = _valid ? GroupStatus.Final : GroupStatus.Invalid;

        emit GroupResolved(_groupId, _valid);
    }

    function resolveGroupMarket(uint256 _marketId, bool _wins) internal {
        uint256 _winningOutcome = _wins ? OUTCOME_YES : OUTCOME_NO;
        endMarket(_marketId, _winningOutcome);
    }

    function resolveInvalidMarket(MarketGroup memory _group, bool _invalid) private {
        uint256 _outcomeIndex = _invalid ? OUTCOME_YES : OUTCOME_NO;
        endMarket(_group.invalidMarket, _outcomeIndex);
    }

    function buildOutcomesNames(string memory _marketName) internal pure returns (string[] memory _names) {
        _names = new string[](2);
        _names[OUTCOME_NO] = string(abi.encodePacked("NO - ", _marketName));
        _names[OUTCOME_YES] = string(abi.encodePacked("YES - ", _marketName));
    }

    function invalidOdds() private pure returns (uint256[] memory _odds) {
        _odds = new uint256[](2);
        _odds[OUTCOME_YES] = 1e18;
        _odds[OUTCOME_NO] = 49e18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./AbstractMarketFactoryV3.sol";
import "./FeePot.sol";
import "../libraries/SafeMathInt256.sol";
import "../libraries/Sport.sol";
import "../libraries/ResolveByFiat.sol";
import "../libraries/HasHeadToHeadMarket.sol";
import "../libraries/Versioned.sol";

contract MMAMarketFactoryV3 is AbstractMarketFactoryV3, SportView, ResolvesByFiat, HasHeadToHeadMarket, Versioned {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 constant HeadToHead = 0;
    string constant InvalidName = "No Contest / Draw";

    constructor(
        address _owner,
        IERC20Full _collateral,
        uint256 _shareFactor,
        FeePot _feePot,
        uint256[3] memory _fees,
        address _protocol,
        address _linkNode
    )
        AbstractMarketFactoryV3(_owner, _collateral, _shareFactor, _feePot, _fees, _protocol)
        Versioned("v1.2.0")
        ManagedByLink(_linkNode)
        HasHeadToHeadMarket(HeadToHead, InvalidName)
    {}

    function createEvent(
        uint256 _eventId,
        string memory _homeTeamName,
        uint256 _homeTeamId,
        string memory _awayTeamName,
        uint256 _awayTeamId,
        uint256 _startTimestamp,
        int256[2] memory _moneylines // [home,away]
    ) public onlyLinkNode returns (uint256[] memory _marketIds) {
        _marketIds = makeMarkets(_moneylines, _homeTeamName, _awayTeamName);
        makeSportsEvent(
            _eventId,
            _marketIds,
            build1Line(),
            _startTimestamp,
            _homeTeamId,
            _awayTeamId,
            _homeTeamName,
            _awayTeamName
        );
    }

    function makeMarkets(
        int256[2] memory _moneylines,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) internal returns (uint256[] memory _marketIds) {
        _marketIds = new uint256[](1);
        _marketIds[HeadToHead] = makeHeadToHeadMarket(_moneylines, _homeTeamName, _awayTeamName);
    }

    function resolveValidEvent(SportsEvent memory _event, uint256 _whoWon) internal override {
        resolveHeadToHeadMarket(_event.markets[HeadToHead], _whoWon);
    }

    function resolveHeadToHeadMarket(uint256 _marketId, uint256 _whoWon) internal {
        uint256 _shareTokenIndex = calcHeadToHeadWinner(_whoWon);
        endMarket(_marketId, _shareTokenIndex);
    }

    function calcHeadToHeadWinner(uint256 _whoWon) internal pure returns (uint256) {
        if (WhoWonHome == _whoWon) {
            return HeadToHeadHome;
        } else if (WhoWonAway == _whoWon) {
            return HeadToHeadAway;
        } else {
            return NoContest; // shouldn't happen here
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/IERC20Full.sol";
import "../balancer/BPool.sol";
import "./AbstractMarketFactoryV3.sol";
import "./FeePot.sol";
import "../libraries/SafeMathInt256.sol";
import "../libraries/Sport.sol";
import "../libraries/HasHeadToHeadMarket.sol";
import "../libraries/HasSpreadMarket.sol";
import "../libraries/HasOverUnderMarket.sol";
import "../libraries/ResolveByScore.sol";
import "../libraries/Versioned.sol";

contract NBAMarketFactoryV3 is
    AbstractMarketFactoryV3,
    SportView,
    HasHeadToHeadMarket,
    HasSpreadMarket,
    HasOverUnderMarket,
    ResolvesByScore,
    Versioned
{
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 constant HeadToHead = 0;
    uint256 constant Spread = 1;
    uint256 constant OverUnder = 2;
    string constant InvalidName = "No Contest";

    constructor(
        address _owner,
        IERC20Full _collateral,
        uint256 _shareFactor,
        FeePot _feePot,
        uint256[3] memory _fees,
        address _protocol,
        address _linkNode
    )
        AbstractMarketFactoryV3(_owner, _collateral, _shareFactor, _feePot, _fees, _protocol)
        Versioned("1.2.0")
        ManagedByLink(_linkNode)
        HasHeadToHeadMarket(HeadToHead, InvalidName)
        HasSpreadMarket(Spread, InvalidName)
        HasOverUnderMarket(OverUnder, InvalidName)
    {}

    function createEvent(
        uint256 _eventId,
        string memory _homeTeamName,
        uint256 _homeTeamId,
        string memory _awayTeamName,
        uint256 _awayTeamId,
        uint256 _startTimestamp,
        int256 _homeSpread,
        int256 _totalScore,
        int256[2] memory _moneylines // [home,away]
    ) public onlyLinkNode returns (uint256[] memory _marketIds) {
        _marketIds = makeMarkets(_moneylines, _homeTeamName, _awayTeamName);
        makeSportsEvent(
            _eventId,
            _marketIds,
            build3Lines(_homeSpread, _totalScore),
            _startTimestamp,
            _homeTeamId,
            _awayTeamId,
            _homeTeamName,
            _awayTeamName
        );
    }

    function makeMarkets(
        int256[2] memory _moneylines,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) internal returns (uint256[] memory _marketIds) {
        _marketIds = new uint256[](3);

        _marketIds[HeadToHead] = makeHeadToHeadMarket(_moneylines, _homeTeamName, _awayTeamName);
        _marketIds[Spread] = makeSpreadMarket(_homeTeamName, _awayTeamName);
        _marketIds[OverUnder] = makeOverUnderMarket();
    }

    function resolveValidEvent(
        SportsEvent memory _event,
        uint256 _homeScore,
        uint256 _awayScore
    ) internal override {
        resolveHeadToHeadMarket(_event.markets[HeadToHead], _homeScore, _awayScore);
        resolveSpreadMarket(_event.markets[Spread], _event.lines[Spread], _homeScore, _awayScore);
        resolveOverUnderMarket(_event.markets[OverUnder], _event.lines[Spread], _homeScore, _awayScore);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/Ownable.sol";

contract OwnedERC20 is ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        address _owner
    ) ERC20(name_, symbol_) {
        owner = _owner;
    }

    function trustedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _transfer(_from, _to, _amount);
    }

    function trustedMint(address _target, uint256 _amount) external onlyOwner {
        _mint(_target, _amount);
    }

    function trustedBurn(address _target, uint256 _amount) external onlyOwner {
        _burn(_target, _amount);
    }

    function trustedBurnAll(address _target) external onlyOwner returns (uint256) {
        uint256 _balance = balanceOf(_target);
        _burn(_target, _balance);
        return _balance;
    }

    function onTransferOwnership(address, address) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./OwnedShareToken.sol";

abstract contract TurboShareTokenFactory {
    function createShareTokens(string[] memory _names, address _owner) internal returns (OwnedERC20[] memory) {
        uint256 _numOutcomes = _names.length;
        OwnedERC20[] memory _tokens = new OwnedERC20[](_numOutcomes);

        for (uint256 _i = 0; _i < _numOutcomes; _i++) {
            _tokens[_i] = new OwnedERC20(_names[_i], _names[_i], _owner);
        }
        return _tokens;
    }
}

abstract contract TurboShareTokenFactoryV1 {
    function createShareTokens(
        string[] memory _names,
        string[] memory _symbols,
        address _owner
    ) internal returns (OwnedERC20[] memory) {
        uint256 _numOutcomes = _names.length;
        OwnedERC20[] memory _tokens = new OwnedERC20[](_numOutcomes);

        for (uint256 _i = 0; _i < _numOutcomes; _i++) {
            _tokens[_i] = new OwnedERC20(_names[_i], _symbols[_i], _owner);
        }
        return _tokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}