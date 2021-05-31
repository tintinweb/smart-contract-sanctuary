/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity =0.6.7 >=0.4.0 >=0.5.0 >=0.6.0;

////// src/erc20/IERC20.sol

/* pragma solidity 0.6.7; */

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

////// src/erc20/SafeMath.sol

/* pragma solidity 0.6.7; */

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
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint128 a, uint128 b) internal pure returns (uint128) {
    uint128 c = a + b;
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
  function sub(uint128 a, uint128 b) internal pure returns (uint128) {
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
  function mul(uint128 a, uint128 b) internal pure returns (uint128) {
    if (a == 0) return 0;
    uint128 c = a * b;
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
  function div(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

////// src/erc20/SafeMath128.sol

/* pragma solidity 0.6.7; */

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
library SafeMath128 {


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
  function add(uint128 a, uint128 b) internal pure returns (uint128) {
    uint128 c = a + b;
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
  function sub(uint128 a, uint128 b) internal pure returns (uint128) {
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
  function mul(uint128 a, uint128 b) internal pure returns (uint128) {
    if (a == 0) return 0;
    uint128 c = a * b;
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
  function div(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }
}

////// src/erc20/ERC20.sol

/* pragma solidity 0.6.7; */

/* import "./IERC20.sol"; */
/* import "./SafeMath.sol"; */
/* import "./SafeMath128.sol"; */

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
contract ERC20 is IERC20 {
  using SafeMath for uint256;
  using SafeMath128 for uint128;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 _totalSupply;

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
  constructor(string memory name_, string memory symbol_) public {
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
    _transfer(msg.sender, recipient, amount);
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
    _approve(msg.sender, spender, amount);
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

////// src/uni/interfaces/IERC20Minimal.sol
/* pragma solidity >=0.5.0; */

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

////// src/uni/libraries/TransferHelper.sol
/* pragma solidity >=0.6.0; */

/* import "../interfaces/IERC20Minimal.sol"; */

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
  /// @notice Transfers tokens from msg.sender to a recipient
  /// @dev Calls transfer on token contract, errors with TF if transfer fails
  /// @param token The contract address of the token which will be transferred
  /// @param to The recipient of the transfer
  /// @param value The value of the transfer
  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
  }

  /// @notice Transfers tokens from msg.sender to a recipient
  /// @dev Calls transfer on token contract, errors with TF if transfer fails
  /// @param token The contract address of the token which will be transferred
  /// @param to The recipient of the transfer
  /// @param value The value of the transfer
  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
  }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

////// src/PeripheryPayments.sol
/*
MIT License

Copyright (c) 2021 Reflexer Labs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/* pragma solidity 0.6.7; */

/* import { ERC20 } from "./erc20/ERC20.sol"; */
/* import { TransferHelper } from "./uni/libraries/TransferHelper.sol"; */

/// @title Interface for WETH9
abstract contract IWETH9 is ERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external virtual payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) virtual external;
}

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable WETH9;

    constructor(address _WETH9) public {
        WETH9 = _WETH9;
    }
}


/**
 * @notice This contract is based on https://github.com/dmihal/uniswap-liquidity-dao/blob/master/contracts/MetaPool.sol
 */
abstract contract PherypheryPayments is PeripheryImmutableState {

    constructor(address _WETH9) public PeripheryImmutableState(_WETH9) {}

    receive() external payable {
        require(msg.sender == WETH9, 'Not WETH9');
    }

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, 'Insufficient WETH9');

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
            TransferHelper.safeTransferETH(recipient, balanceWETH9);
        }
    }


     /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() internal {
        if (address(this).balance > 0) TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH9 && address(this).balance >= value) {
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}

////// src/PoolViewer.sol
/* pragma solidity 0.6.7; */

contract PoolViewer {
    // --- Mint  ---
    /**
     * @notice Helper function to simulate a mint action on a Uniswap v3 pool
     * @param pool The address of the target pool
     * @param recipient The address that will receive and pay for tokens
     * @param tickLower The lower bound of the range to deposit the liquidity to
     * @param tickUpper The upper bound of the range to deposit the liquidity to
     * @param amount The amount of liquidity to mint
     * @param data The data for the callback function
     */
    function mintViewer(
        address pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external {
        (bool success, bytes memory ret) =
            pool.call(abi.encodeWithSignature("mint(address,int24,int24,uint128,bytes)", recipient, tickLower, tickUpper, amount, data));
        (uint256 amount0, uint256 amount1) = (0, 0);
        if (success) (amount0, amount1) = abi.decode(ret, (uint256, uint256));

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amount0)
            mstore(add(ptr, 32), amount1)
            revert(ptr, 64)
        }
    }

    // --- Collect  ---
    /**
     * @notice Helper function to simulate an action on a Uniswap v3 pool
     * @param pool The address of the target pool
     * @param recipient The address that will receive and pay for tokens
     * @param tickLower The lower bound of the range to deposit the liquidity to
     * @param tickUpper The upper bound of the range to deposit the liquidity to
     * @param amount0Requested The amount of token0 requested
     * @param amount1Requested The amount of token1 requested
     */
    function collectViewer(
        address pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external {
        (bool success, bytes memory ret) =
            pool.call(
                abi.encodeWithSignature("collect(address,int24,int24,uint128,uint128)", recipient, tickLower, tickUpper, amount0Requested, amount1Requested)
            );
        (uint128 amount0, uint128 amount1) = (0, 0);
        if (success) (amount0, amount1) = abi.decode(ret, (uint128, uint128));
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amount0)
            mstore(add(ptr, 32), amount1)
            revert(ptr, 64)
        }
    }

    // --- Burn ---
    /**
     * @notice Helper function to simulate (non state-mutating) an action on a Uniswap v3 pool
     * @param pool The address of the target pool
     * @param tickLower The lower bound of the Uni v3 position
     * @param tickUpper The lower bound of the Uni v3 position
     * @param amount The amount of liquidity to burn
     */
    function burnViewer(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external {
        (bool success, bytes memory ret) = pool.call(abi.encodeWithSignature("burn(int24,int24,uint128)", tickLower, tickUpper, amount));
        (uint256 amount0, uint256 amount1) = (0, 0);
        if (success) (amount0, amount1) = abi.decode(ret, (uint256, uint256));
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amount0)
            mstore(add(ptr, 32), amount1)
            revert(ptr, 64)
        }
    }
}

////// src/uni/interfaces/pool/IUniswapV3PoolActions.sol
/* pragma solidity >=0.5.0; */

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
  /// @notice Sets the initial price for the pool
  /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
  /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
  function initialize(uint160 sqrtPriceX96) external;

  /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
  /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
  /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
  /// on tickLower, tickUpper, the amount of liquidity, and the current price.
  /// @param recipient The address for which the liquidity will be created
  /// @param tickLower The lower tick of the position in which to add liquidity
  /// @param tickUpper The upper tick of the position in which to add liquidity
  /// @param amount The amount of liquidity to mint
  /// @param data Any data that should be passed through to the callback
  /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes calldata data
  ) external returns (uint256 amount0, uint256 amount1);

  /// @notice Collects tokens owed to a position
  /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
  /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
  /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
  /// actual tokens owed, e.g. (0 - uint128(1)). Tokens owed may be from accumulated swap fees or burned liquidity.
  /// @param recipient The address which should receive the fees collected
  /// @param tickLower The lower tick of the position for which to collect fees
  /// @param tickUpper The upper tick of the position for which to collect fees
  /// @param amount0Requested How much token0 should be withdrawn from the fees owed
  /// @param amount1Requested How much token1 should be withdrawn from the fees owed
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
  /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
  /// @dev Fees must be collected separately via a call to #collect
  /// @param tickLower The lower tick of the position for which to burn liquidity
  /// @param tickUpper The upper tick of the position for which to burn liquidity
  /// @param amount How much liquidity to burn
  /// @return amount0 The amount of token0 sent to the recipient
  /// @return amount1 The amount of token1 sent to the recipient
  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
  /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
  /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
  /// with 0 amount{0,1} and sending the donation amount(s) from the callback
  /// @param recipient The address which will receive the token0 and token1 amounts
  /// @param amount0 The amount of token0 to send
  /// @param amount1 The amount of token1 to send
  /// @param data Any data to be passed through to the callback
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;

  /// @notice Increase the maximum number of price and liquidity observations that this pool will store
  /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
  /// the input observationCardinalityNext.
  /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
  function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

////// src/uni/interfaces/pool/IUniswapV3PoolDerivedState.sol
/* pragma solidity >=0.5.0; */

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns a relative timestamp value representing how long, in seconds, the pool has spent between
    /// tickLower and tickUpper
    /// @dev This timestamp is strictly relative. To get a useful elapsed time (i.e., duration) value, the value returned
    /// by this method should be checkpointed externally after a position is minted, and again before a position is
    /// burned. Thus the external contract must control the lifecycle of the position.
    /// @param tickLower The lower tick of the range for which to get the seconds inside
    /// @param tickUpper The upper tick of the range for which to get the seconds inside
    /// @return A relative timestamp for how long the pool spent in the tick range
    function secondsInside(int24 tickLower, int24 tickUpper) external view returns (uint32);

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return liquidityCumulatives Cumulative liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory liquidityCumulatives);
}

////// src/uni/interfaces/pool/IUniswapV3PoolEvents.sol
/* pragma solidity >=0.5.0; */

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

////// src/uni/interfaces/pool/IUniswapV3PoolImmutables.sol
/* pragma solidity >=0.5.0; */

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

////// src/uni/interfaces/pool/IUniswapV3PoolOwnerActions.sol
/* pragma solidity >=0.5.0; */

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

////// src/uni/interfaces/pool/IUniswapV3PoolState.sol
/* pragma solidity >=0.5.0; */

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// feeGrowthOutsideX128 values can only be used if the tick is initialized,
    /// i.e. if liquidityGross is greater than 0. In addition, these values are only relative and are used to
    /// compute snapshots.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns 8 packed tick seconds outside values. See SecondsOutside for more information
    function secondsOutside(int24 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the current tick multiplied by seconds elapsed for the life of the pool as of the
    /// observation,
    /// Returns liquidityCumulative the current liquidity multiplied by seconds elapsed for the life of the pool as of
    /// the observation,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 liquidityCumulative,
            bool initialized
        );
}

////// src/uni/interfaces/IUniswapV3Pool.sol
/* pragma solidity >=0.5.0; */

/* import './pool/IUniswapV3PoolImmutables.sol'; */
/* import './pool/IUniswapV3PoolState.sol'; */
/* import './pool/IUniswapV3PoolDerivedState.sol'; */
/* import './pool/IUniswapV3PoolActions.sol'; */
/* import './pool/IUniswapV3PoolOwnerActions.sol'; */
/* import './pool/IUniswapV3PoolEvents.sol'; */

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

////// src/uni/interfaces/callback/IUniswapV3MintCallback.sol
/* pragma solidity >=0.5.0; */

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

////// src/uni/libraries/FixedPoint96.sol
/* pragma solidity >=0.4.0; */

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

////// src/uni/libraries/FullMath.sol
/* pragma solidity >=0.4.0; */

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    uint256 twos = -denominator & denominator;
    // Divide denominator by power of two
    assembly {
      denominator := div(denominator, twos)
    }

    // Divide [prod1 prod0] by the factors of two
    assembly {
      prod0 := div(prod0, twos)
    }
    // Shift in bits from prod1 into prod0. For this we need
    // to flip `twos` such that it is 2**256 / twos.
    // If twos is zero, then it becomes one
    assembly {
      twos := add(div(sub(0, twos), twos), 1)
    }
    prod0 |= prod1 * twos;

    // Invert denominator mod 2**256
    // Now that denominator is an odd number, it has an inverse
    // modulo 2**256 such that denominator * inv = 1 mod 2**256.
    // Compute the inverse by starting with a seed that is correct
    // correct for four bits. That is, denominator * inv = 1 mod 2**4
    uint256 inv = (3 * denominator) ^ 2;
    // Now use Newton-Raphson iteration to improve the precision.
    // Thanks to Hensel's lifting lemma, this also works in modular
    // arithmetic, doubling the correct bits in each step.
    inv *= 2 - denominator * inv; // inverse mod 2**8
    inv *= 2 - denominator * inv; // inverse mod 2**16
    inv *= 2 - denominator * inv; // inverse mod 2**32
    inv *= 2 - denominator * inv; // inverse mod 2**64
    inv *= 2 - denominator * inv; // inverse mod 2**128
    inv *= 2 - denominator * inv; // inverse mod 2**256

    // Because the division is now exact we can divide by multiplying
    // with the modular inverse of denominator. This will give us the
    // correct result modulo 2**256. Since the precoditions guarantee
    // that the outcome is less than 2**256, this is the final result.
    // We don't need to compute the high bits of the result and prod1
    // is no longer required.
    result = prod0 * inv;
    return result;
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      require(result < (0 - uint256(1)));
      result++;
    }
  }
}

////// src/uni/libraries/LiquidityAmounts.sol
/* pragma solidity >=0.5.0; */

/* import "./FullMath.sol"; */
/* import "./FixedPoint96.sol"; */

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
  /// @notice Downcasts uint256 to uint128
  /// @param x The uint258 to be downcasted
  /// @return y The passed value, downcasted to uint128
  function toUint128(uint256 x) private pure returns (uint128 y) {
    require((y = uint128(x)) == x);
  }

  /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
  /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param amount0 The amount0 being sent in
  /// @return liquidity The amount of returned liquidity
  function getLiquidityForAmount0(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount0
  ) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
    return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
  }

  /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
  /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param amount1 The amount1 being sent in
  /// @return liquidity The amount of returned liquidity
  function getLiquidityForAmount1(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount1
  ) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
  }

  /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
  /// pool prices and the prices at the tick boundaries
  /// @param sqrtRatioX96 A sqrt price representing the current pool prices
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param amount0 The amount of token0 being sent in
  /// @param amount1 The amount of token1 being sent in
  /// @return liquidity The maximum amount of liquidity received
  function getLiquidityForAmounts(
    uint160 sqrtRatioX96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount0,
    uint256 amount1
  ) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    if (sqrtRatioX96 <= sqrtRatioAX96) {
      liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
    } else if (sqrtRatioX96 < sqrtRatioBX96) {
      uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
      uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

      liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    } else {
      liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
    }
  }

  /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param liquidity The liquidity being valued
  /// @return amount0 The amount of token0
  function getAmount0ForLiquidity(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity
  ) internal pure returns (uint256 amount0) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    return FullMath.mulDiv(uint256(liquidity) << FixedPoint96.RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96) / sqrtRatioAX96;
  }

  /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param liquidity The liquidity being valued
  /// @return amount1 The amount of token1
  function getAmount1ForLiquidity(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity
  ) internal pure returns (uint256 amount1) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
  }

  /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
  /// pool prices and the prices at the tick boundaries
  /// @param sqrtRatioX96 A sqrt price representing the current pool prices
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param liquidity The liquidity being valued
  /// @return amount0 The amount of token0
  /// @return amount1 The amount of token1
  function getAmountsForLiquidity(
    uint160 sqrtRatioX96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity
  ) internal pure returns (uint256 amount0, uint256 amount1) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    if (sqrtRatioX96 <= sqrtRatioAX96) {
      amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
    } else if (sqrtRatioX96 < sqrtRatioBX96) {
      amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
      amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
    } else {
      amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
    }
  }
}

////// src/uni/libraries/TickMath.sol
/* pragma solidity >=0.5.0; */

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = -887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = -MIN_TICK;

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
    uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
    require(absTick <= uint256(MAX_TICK), "T");

    uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
    if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
    if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
    if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
    if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
    if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
    if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
    if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
    if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
    if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
    if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
    if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
    if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
    if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
    if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
    if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
    if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
    if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
    if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
    if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

    if (tick > 0) ratio = (0 - uint256(1)) / ratio;

    // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
    // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
    // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
    sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
    uint256 ratio = uint256(sqrtPriceX96) << 32;

    uint256 r = ratio;
    uint256 msb = 0;

    assembly {
      let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(5, gt(r, 0xFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(4, gt(r, 0xFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(3, gt(r, 0xFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(2, gt(r, 0xF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(1, gt(r, 0x3))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := gt(r, 0x1)
      msb := or(msb, f)
    }

    if (msb >= 128) r = ratio >> (msb - 127);
    else r = ratio << (127 - msb);

    int256 log_2 = (int256(msb) - 128) << 64;

    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(63, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(62, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(61, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(60, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(59, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(58, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(57, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(56, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(55, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(54, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(53, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(52, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(51, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(50, f))
    }

    int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

    int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
    int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

    tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
  }
}

////// src/GebUniswapV3ManagerBase.sol
/*
MIT License

Copyright (c) 2021 Reflexer Labs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/* pragma solidity 0.6.7; */

// import { ERC20 } from "./erc20/ERC20.sol";
/* import "./PoolViewer.sol"; */
/* import "./PeripheryPayments.sol"; */
/* import { IUniswapV3Pool } from "./uni/interfaces/IUniswapV3Pool.sol"; */
/* import { IUniswapV3MintCallback } from "./uni/interfaces/callback/IUniswapV3MintCallback.sol"; */
// import { TransferHelper } from "./uni/libraries/TransferHelper.sol";
/* import { LiquidityAmounts } from "./uni/libraries/LiquidityAmounts.sol"; */
/* import { TickMath } from "./uni/libraries/TickMath.sol"; */

abstract contract OracleForUniswapLike {
    function getResultsWithValidity() public virtual returns (uint256, uint256, bool);
}

/**
 * @notice This contract is based on https://github.com/dmihal/uniswap-liquidity-dao/blob/master/contracts/MetaPool.sol
 */
abstract contract GebUniswapV3ManagerBase is ERC20, PherypheryPayments {
    // --- Pool Variables ---
    // The address of pool's token0
    address public token0;
    // The address of pool's token1
    address public token1;
    // The pool's fee
    uint24 public fee;
    // The pool's tickSpacing
    int24 public tickSpacing;
    // The pool's maximum liquidity per tick
    uint128 public maxLiquidityPerTick;
    // Flag to identify whether the system coin is token0 or token1. Needed for correct tick calculation
    bool systemCoinIsT0;

    // --- General Variables ---
    // The minimum delay required to perform a rebalance. Bounded to be between MINIMUM_DELAY and MAXIMUM_DELAY
    uint256 public delay;
    // The timestamp of the last rebalance
    uint256 public lastRebalance;

    // --- External Contracts ---
    // Address of the Uniswap v3 pool
    IUniswapV3Pool public pool;
    // Address of oracle relayer to get prices from
    OracleForUniswapLike public oracle;
    // Address of contract that allows simulating pool fuctions
    PoolViewer public poolViewer;

    // --- Constants ---
    // Used to get the max amount of tokens per liquidity burned
    uint128 constant MAX_UINT128 = uint128(0 - 1);
    // 100% - Not really achievable, because it'll reach max and min ticks
    uint256 constant MAX_THRESHOLD = 10000000;
    // 1% - Quite dangerous because the market price can easily move beyond the threshold
    uint256 constant MIN_THRESHOLD = 10000; // 1%
    // A week is the maximum time allowed without a rebalance
    uint256 constant MAX_DELAY = 7 days;
    // 1 hour is the absolute minimum delay for a rebalance. Could be less through deposits
    uint256 constant MIN_DELAY = 60 minutes;
    // Absolutes ticks, (MAX_TICK % tickSpacing == 0) and (MIN_TICK % tickSpacing == 0)
    int24 public constant MAX_TICK = 887220;
    int24 public constant MIN_TICK = -887220;

    // --- Struct ---
    struct Position {
      bytes32 id;
      int24 lowerTick;
      int24 upperTick;
      uint128 uniLiquidity;
      uint256 threshold;
    }

    // --- Events ---
    event ModifyParameters(bytes32 parameter, uint256 val);
    event ModifyParameters(bytes32 parameter, address val);
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Deposit(address sender, address recipient, uint256 liquidityAdded);
    event Withdraw(address sender, address recipient, uint256 liquidityAdded);
    event Rebalance(address sender, uint256 timestamp);

    // --- Auth ---
    mapping(address => uint256) public authorizedAccounts;

    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }

    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }

    /**
     * @notice Checks whether msg.sender can call an authed function
     **/
    modifier isAuthorized() {
        require(authorizedAccounts[msg.sender] == 1, "GebUniswapV3LiquidityManager/account-not-authorized");
        _;
    }

    /**
     * @notice Constructor that sets initial parameters for this contract
     * @param name_ The name of the ERC20 this contract will distribute
     * @param symbol_ The symbol of the ERC20 this contract will distribute
     * @param systemCoinAddress_ The address of the system coin
     * @param delay_ The minimum required time before rebalance() can be called
     * @param pool_ Address of the already deployed Uniswap v3 pool that this contract will manage
     * @param oracle_ Address of the already deployed oracle that provides both prices
     */
    constructor(
      string memory name_,
      string memory symbol_,
      address systemCoinAddress_,
      uint256 delay_,
      address pool_,
      OracleForUniswapLike oracle_,
      PoolViewer poolViewer_,
      address weth9Address
    ) public ERC20(name_, symbol_) PherypheryPayments(weth9Address) {
        require(delay_ >= MIN_DELAY && delay_ <= MAX_DELAY, "GebUniswapv3LiquidityManager/invalid-delay");

        authorizedAccounts[msg.sender] = 1;

        // Getting pool information
        pool = IUniswapV3Pool(pool_);

        token0 = pool.token0();
        token1 = pool.token1();
        fee = pool.fee();
        tickSpacing = pool.tickSpacing();
        maxLiquidityPerTick = pool.maxLiquidityPerTick();

        require(MIN_TICK % tickSpacing == 0, "GebUniswapv3LiquidityManager/invalid-max-tick-for-spacing");
        require(MAX_TICK % tickSpacing == 0, "GebUniswapv3LiquidityManager/invalid-min-tick-for-spacing");

        delay = delay_;
        systemCoinIsT0 = token0 == systemCoinAddress_ ? true : false;
        oracle = oracle_;
        poolViewer = poolViewer_;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    /**
     * @notice Calculates the sqrt of a number
     * @param y The number to calculate the square root of
     * @return z The result of the calculation
     */
    function sqrt(uint256 y) public pure returns (uint256 z) {
        if (y > 3) {
          z = y;
          uint256 x = y / 2 + 1;
          while (x < z) {
            z = x;
            x = (y / x + x) / 2;
          }
        } else if (y != 0) {
          z = 1;
        }
    }

    // --- Administration ---
    /**
     * @notice Modify the adjustable parameters
     * @param parameter The variable to change
     * @param data The value to set for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "delay") {
          require(data >= MIN_DELAY && data <= MAX_DELAY, "GebUniswapv3LiquidityManager/invalid-delay");
          delay = data;
        } else revert("GebUniswapv3LiquidityManager/modify-unrecognized-param");

        emit ModifyParameters(parameter, data);
    }

    /**
     * @notice Modify adjustable parameters
     * @param parameter The variable to change
     * @param data The value to set for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "GebUniswapv3LiquidityManager/null-data");

        if (parameter == "oracle") {
          // If it's an invalid address, this tx will revert
          OracleForUniswapLike(data).getResultsWithValidity();
          oracle = OracleForUniswapLike(data);
        }

        emit ModifyParameters(parameter, data);
    }

    // --- Virtual functions  ---
    function deposit(uint256 newLiquidity, address recipient, uint256 minAm0, uint256 minAm1) external payable virtual returns (uint256 mintAmount);
    function withdraw(uint256 liquidityAmount, address recipient) external virtual returns (uint256 amount0, uint256 amount1);
    function rebalance() external virtual;

    // --- Getters ---
    /**
     * @notice Public function to get both the redemption price for the system coin and the other token's price
     * @return redemptionPrice The redemption price
     * @return tokenPrice The other token's price
     */
    function getPrices() public returns (uint256 redemptionPrice, uint256 tokenPrice) {
        bool valid;
        (redemptionPrice, tokenPrice, valid) = oracle.getResultsWithValidity();
        require(valid, "GebUniswapv3LiquidityManager/invalid-price");
    }

    /**
     * @notice Function that returns the next target ticks based on the redemption price
     * @return _nextLower The lower bound of the range
     * @return _nextUpper The upper bound of the range
     */
    function getNextTicks(uint256 _threshold) public returns (int24 _nextLower, int24 _nextUpper, int24 targetTick) {
       targetTick  = getTargetTick();
       (_nextLower,  _nextUpper) = getTicksWithThreshold(targetTick, _threshold);
    }

    function getTargetTick() public returns(int24 targetTick){
         // 1. Get prices from the oracle relayer
        (uint256 redemptionPrice, uint256 ethUsdPrice) = getPrices();

        // 2. Calculate the price ratio
        uint160 sqrtPriceX96;
        uint256 scale = 1000000000;
        if (systemCoinIsT0) {
          sqrtPriceX96 = uint160(sqrt((redemptionPrice.mul(scale).div(ethUsdPrice) << 192) / scale));
        } else {
          sqrtPriceX96 = uint160(sqrt((ethUsdPrice.mul(scale).div(redemptionPrice) << 192) / scale));
        }

        // 3. Calculate the tick that the ratio is at
        int24 approximatedTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        // 4. Adjust to comply to tickSpacing
        targetTick = approximatedTick - (approximatedTick % tickSpacing);
    }

    function getTicksWithThreshold(int24 targetTick, uint256 _threshold) public pure returns(int24 lowerTick, int24 upperTick){
        // 5. Find lower and upper bounds for the next position
        lowerTick = targetTick - int24(_threshold) < MIN_TICK ? MIN_TICK : targetTick - int24(_threshold);
        upperTick = targetTick + int24(_threshold) > MAX_TICK ? MAX_TICK : targetTick + int24(_threshold);
    }

    function _getTokenAmountsFromLiquidity(Position storage _position, uint128 _liquidity) internal returns (uint256 amount0, uint256 amount1) {
        uint256 __supply = _totalSupply;
        uint128 _liquidityBurned = uint128(uint256(_liquidity).mul(_position.uniLiquidity).div(__supply));

        (, bytes memory ret) =
          address(poolViewer).delegatecall(
            abi.encodeWithSignature("burnViewer(address,int24,int24,uint128)", address(pool), _position.lowerTick, _position.upperTick, _liquidityBurned)
          );
        (amount0, amount1) = abi.decode(ret, (uint256, uint256));
    }

    /**
     * @notice Add liquidity to this pool manager
     * @param _position The position to perform the operation
     * @param _newLiquidity The amount of liquidity to add
     * @param _targetTick The price to center the position around
     */
    function _deposit(Position storage _position, uint128 _newLiquidity, int24 _targetTick ) internal returns(uint256 amount0,uint256 amount1){
        (int24 _nextLowerTick,int24 _nextUpperTick) = getTicksWithThreshold(_targetTick,_position.threshold);

        { // Scope to avoid stack too deep
          uint128 compoundLiquidity = 0;
          uint256 collected0 = 0;
          uint256 collected1 = 0;

          if (_position.uniLiquidity > 0 && (_position.lowerTick != _nextLowerTick || _position.upperTick != _nextUpperTick)) {
            // 1. Burn and collect all liquidity
            (collected0, collected1) = _burnOnUniswap(_position, _position.lowerTick, _position.upperTick, _position.uniLiquidity, address(this));

            // 2. Figure how much liquidity we can get from our current balances
            compoundLiquidity = _getCompoundLiquidity(_nextLowerTick,_nextUpperTick,collected0,collected1);
            require(_newLiquidity + compoundLiquidity >= _newLiquidity, "GebUniswapv3LiquidityManager/liquidity-overflow");

            emit Rebalance(msg.sender, block.timestamp);
          }
          // 3. Mint our new position on Uniswap
          lastRebalance = block.timestamp;
          (uint256 amount0Minted, uint256 amount1Minted) = _mintOnUniswap(_position, _nextLowerTick, _nextUpperTick, _newLiquidity+compoundLiquidity, abi.encode(msg.sender, collected0, collected1));
          (amount0, amount1) = (amount0Minted - collected0, amount1Minted - collected1);
        }
    }

    /**
     * @notice Remove liquidity and withdraw the underlying assets
     * @param _position The position to perform the operation
     * @param _liquidityBurned The amount of liquidity to withdraw
     * @param _recipient The address that will receive token0 and token1 tokens
     * @return amount0 The amount of token0 requested from the pool
     * @return amount1 The amount of token1 requested from the pool
     */
    function _withdraw(
        Position storage _position,
        uint128 _liquidityBurned,
        address _recipient
    ) internal returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _burnOnUniswap(_position, _position.lowerTick, _position.upperTick, uint128(_liquidityBurned), _recipient);
        emit Withdraw(msg.sender, _recipient, _liquidityBurned);
    }

    /**
     * @notice Rebalance by burning and then minting the position
     * @param _position The position to perform the operation
     * @param _targetTick The desired price to center the liquidity around
     */
    function _rebalance(Position storage _position, int24 _targetTick) internal {
        (int24 _nextLowerTick, int24 _nextUpperTick) = getTicksWithThreshold(_targetTick,_position.threshold);
        (int24 _currentLowerTick, int24 _currentUpperTick) = (_position.lowerTick, _position.upperTick);

        if (_currentLowerTick != _nextLowerTick || _currentUpperTick != _nextUpperTick) {
          // Get the fees
          (uint256 collected0, uint256 collected1) = _burnOnUniswap(
            _position, _currentLowerTick, _currentUpperTick, _position.uniLiquidity, address(this)
          );

          // Figure how much liquidity we can get from our current balances
          (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

          uint128 compoundLiquidity =
            LiquidityAmounts.getLiquidityForAmounts(
              sqrtRatioX96,
              TickMath.getSqrtRatioAtTick(_nextLowerTick),
              TickMath.getSqrtRatioAtTick(_nextUpperTick),
              collected0.add(1),
              collected1.add(1)
            );

          _mintOnUniswap(_position, _nextLowerTick, _nextUpperTick, compoundLiquidity, abi.encode(msg.sender, collected0, collected1));
        }
    }

    // --- Uniswap Related Functions ---
    /**
     * @notice Helper function to mint a position
     * @param _lowerTick The lower bound of the range to deposit the liquidity to
     * @param _upperTick The upper bound of the range to deposit the liquidity to
     * @param _totalLiquidity The total amount of liquidity to mint
     * @param _callbackData The data to pass on to the callback function
     */
    function _mintOnUniswap(
        Position storage _position,
        int24 _lowerTick,
        int24 _upperTick,
        uint128 _totalLiquidity,
        bytes memory _callbackData
    ) internal returns(uint256 amount0, uint256 amount1) {
        (amount0, amount1) = pool.mint(address(this), _lowerTick, _upperTick, _totalLiquidity, _callbackData);
        _position.lowerTick = _lowerTick;
        _position.upperTick = _upperTick;

        bytes32 id = keccak256(abi.encodePacked(address(this), _lowerTick, _upperTick));
        (uint128 _liquidity, , , , ) = pool.positions(id);
        _position.id = id;
        _position.uniLiquidity = _liquidity;
    }

    /**
     * @notice Helper function to burn a position
     * @param _lowerTick The lower bound of the range to deposit the liquidity to
     * @param _upperTick The upper bound of the range to deposit the liquidity to
     * @param _burnedLiquidity The amount of liquidity to burn
     * @param _recipient The address to send the tokens to
     * @return collected0 The amount of token0 requested from the pool
     * @return collected1 The amount of token1 requested from the pool
     */
    function _burnOnUniswap(
        Position storage _position,
        int24 _lowerTick,
        int24 _upperTick,
        uint128 _burnedLiquidity,
        address _recipient
    ) internal returns (uint256 collected0, uint256 collected1) {
        (uint128 _liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(_position.id);

        pool.burn(_lowerTick, _upperTick, _burnedLiquidity);

        ( _liquidity,  feeGrowthInside0LastX128,  feeGrowthInside1LastX128,  tokensOwed0,  tokensOwed1) = pool.positions(_position.id);

        // Collect all owed
        (collected0, collected1) = pool.collect(_recipient, _lowerTick, _upperTick, MAX_UINT128, MAX_UINT128);
         ( _liquidity,  feeGrowthInside0LastX128,  feeGrowthInside1LastX128,  tokensOwed0,  tokensOwed1) = pool.positions(_position.id);

        // Update position. All other factors are still the same
        ( _liquidity, , , , ) = pool.positions(_position.id);
        _position.uniLiquidity = _liquidity;
    }

    function _getCompoundLiquidity(int24 _nextLowerTick, int24 _nextUpperTick, uint256 _collected0, uint256 _collected1) internal view returns(uint128 compoundLiquidity){
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

        compoundLiquidity = LiquidityAmounts.getLiquidityForAmounts(
          sqrtRatioX96,
          TickMath.getSqrtRatioAtTick(_nextLowerTick),
          TickMath.getSqrtRatioAtTick(_nextUpperTick),
          _collected0.add(1),
          _collected1.add(1)
        );
    }

    /**
     * @notice Callback used to transfer tokens to the pool. Tokens need to be aproved before calling mint or deposit.
     * @param amount0Owed The amount of token0 necessary to send to pool
     * @param amount1Owed The amount of token1 necessary to send to pool
     * @param data Arbitrary data to use in the function
     */
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {
        require(msg.sender == address(pool));

        (address sender, uint256 amt0FromThis, uint256 amt1FromThis) = abi.decode(data, (address, uint256, uint256));

        // Pay what this contract owes
        if (amt0FromThis > 0) {
          TransferHelper.safeTransfer(token0, msg.sender, amt0FromThis);
        }
        if (amt1FromThis > 0) {
          TransferHelper.safeTransfer(token1, msg.sender, amt1FromThis);
        }

        // Pay what the sender owes
        if (amount0Owed > amt0FromThis) {
          pay(token0, sender, msg.sender, amount0Owed - amt0FromThis);
        }
        if (amount1Owed > amt1FromThis) {
          pay(token1, sender, msg.sender, amount1Owed - amt1FromThis);
        }
    }
}

////// src/GebUniswapV3TwoTrancheManager.sol
/*
MIT License

Copyright (c) 2021 Reflexer Labs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/* pragma solidity 0.6.7; */

/* import "./GebUniswapV3ManagerBase.sol"; */

/**
 * @notice This contract is based on https://github.com/dmihal/uniswap-liquidity-dao/blob/master/contracts/MetaPool.sol
 */
contract GebUniswapV3TwoTrancheManager is GebUniswapV3ManagerBase {
    // --- Variables ---
    // Manager's positions in the Uniswap pool
    Position[2] public positions;
    // Ratio for each tranche allocation in relation to the total capital allocated, in percentages (1 == 1%)
    uint128     public ratio1;
    uint128     public ratio2;

    /**
     * @notice Constructor that sets initial parameters for this contract
     * @param name_ The name of the ERC20 this contract will distribute
     * @param symbol_ The symbol of the ERC20 this contract will distribute
     * @param systemCoinAddress_ The address of the system coin
     * @param threshold_1 The liquidity threshold around the redemption price
     * @param threshold_2 The liquidity threshold around the redemption price
     * @param ratio_1 The ratio around that the first position invest with
     * @param ratio_2 The ratio around that the second position invest with
     * @param delay_ The minimum required time before rebalance() can be called
     * @param pool_ Address of the already deployed Uniswap v3 pool that this contract will manage
     * @param oracle_ Address of the already deployed oracle that provides both prices
     * @param wethAddress_ Address of the WETH9 contract
     */
    constructor(
      string memory name_,
      string memory symbol_,
      address systemCoinAddress_,
      uint256 delay_,
      uint256 threshold_1,
      uint256 threshold_2,
      uint128 ratio_1,
      uint128 ratio_2,
      address pool_,
      OracleForUniswapLike oracle_,
      PoolViewer poolViewer_,
      address wethAddress_
    ) public GebUniswapV3ManagerBase(name_, symbol_,systemCoinAddress_,delay_,pool_,oracle_,poolViewer_,wethAddress_) {
        require(threshold_1 >= MIN_THRESHOLD && threshold_1 <= MAX_THRESHOLD, "GebUniswapV3TwoTrancheManager/invalid-thresold");
        require(threshold_1 % uint256(tickSpacing) == 0, "GebUniswapV3TwoTrancheManager/threshold-incompatible-w/-tickSpacing");

        require(threshold_2 >= MIN_THRESHOLD && threshold_2 <= MAX_THRESHOLD, "GebUniswapV3TwoTrancheManager/invalid-thresold2");
        require(threshold_2 % uint256(tickSpacing) == 0, "GebUniswapV3TwoTrancheManager/threshold-incompatible-w/-tickSpacing");

        require(ratio_1.add(ratio_2) == 100,"GebUniswapV3TwoTrancheManager/invalid-ratios");

        ratio1 = ratio_1;
        ratio2 = ratio_2;

        // Initialize starting positions
        int24 target = getTargetTick();
        (int24 lower_1, int24 upper_1) = getTicksWithThreshold(target, threshold_1);
        positions[0] = Position({
          id: keccak256(abi.encodePacked(address(this), lower_1, upper_1)),
          lowerTick: lower_1,
          upperTick: upper_1,
          uniLiquidity: 0,
          threshold: threshold_1
        });

        (int24 lower_2, int24 upper_2) = getTicksWithThreshold(target, threshold_2);
        positions[1] = Position({
          id: keccak256(abi.encodePacked(address(this), lower_2, upper_2)),
          lowerTick: lower_2,
          upperTick: upper_2,
          uniLiquidity: 0,
          threshold: threshold_2
        });
    }

    // --- Helper ---
    function getAmountFromRatio(uint128 _amount, uint128 _ratio) internal pure returns (uint128){
      return _amount.mul(_ratio).div(100);
    }

    // --- Getters ---
    /**
     * @notice Returns the current amount of token0 for a given liquidity amount
     * @param _liquidity The amount of liquidity to withdraw
     * @return amount0 The amount of token0 received for the liquidity
     * @return amount1 The amount of token0 received for the liquidity
     */
    function getTokenAmountsFromLiquidity(uint128 _liquidity) public returns (uint256 amount0, uint256 amount1) {
        uint256 __supply = _totalSupply;
        uint128 _liquidityBurned = uint128(uint256(_liquidity).mul(positions[0].uniLiquidity + positions[1].uniLiquidity).div(__supply));
        (uint256 am0_pos0, uint256 am1_pos0) = _getTokenAmountsFromLiquidity(positions[0], _liquidityBurned);
        (uint256 am0_pos1, uint256 am1_pos1) = _getTokenAmountsFromLiquidity(positions[1], _liquidityBurned);
        (amount0, amount1) = (am0_pos0.add(am0_pos1), am1_pos0.add(am1_pos1));
    }

    /**
     * @notice Returns the current amount of token0 for a given liquidity amount
     * @param _liquidity The amount of liquidity to withdraw
     * @return amount0 The amount of token0 received for the liquidity
     */
    function getToken0FromLiquidity(uint128 _liquidity) public returns (uint256 amount0) {
        if (_liquidity == 0) return 0;
        (uint256 am0_pos0, ) = _getTokenAmountsFromLiquidity(positions[0], _liquidity);
        (uint256 am0_pos1, ) = _getTokenAmountsFromLiquidity(positions[1], _liquidity);
        amount0 = am0_pos0.add(am0_pos1);
    }

    /**
     * @notice Returns the current amount of token1 for a given liquidity amount
     * @param _liquidity The amount of liquidity to withdraw
     * @return amount1 The amount of token1 received for the liquidity
     */
    function getToken1FromLiquidity(uint128 _liquidity) public returns (uint256 amount1) {
        (,uint256 am1_pos0) = _getTokenAmountsFromLiquidity(positions[0], _liquidity);
        (,uint256 am1_pos1 ) = _getTokenAmountsFromLiquidity(positions[1], _liquidity);
        amount1 = am1_pos0.add(am1_pos1);
    }

    /**
     * @notice Add liquidity to this Uniswap pool manager
     * @param newLiquidity The amount of liquidty that the user wishes to add
     * @param recipient The address that will receive ERC20 wrapper tokens for the provided liquidity
     * @param minAm0 The minimum amount of token 0 for the tx to be considered valid. Preventing sandwich attacks
     * @param minAm1 The minimum amount of token 1 for the tx to be considered valid. Preventing sandwich attacks
     */
    function deposit(uint256 newLiquidity, address recipient, uint256 minAm0, uint256 minAm1) external payable override returns (uint256 mintAmount) {
        require(recipient != address(0), "GebUniswapV3TwoTrancheManager/invalid-recipient");
        require(newLiquidity < MAX_UINT128, "GebUniswapV3TwoTrancheManager/too-much-to-mint-at-once");

        uint128 totalLiquidity = positions[0].uniLiquidity.add(positions[1].uniLiquidity);
        { //Avoid stack too deep
          int24 target= getTargetTick();

          uint128 liq1 = getAmountFromRatio(uint128(newLiquidity), ratio1);
          uint128 liq2 = getAmountFromRatio(uint128(newLiquidity), ratio2);

          require(liq1 > 0 && liq2 > 0, "GebUniswapV3TwoTrancheManager/minting-zero-liquidity");

          (uint256 pos0Am0, uint256 pos0Am1) = _deposit(positions[0], liq1, target);
          (uint256 pos1Am0, uint256 pos1Am1) = _deposit(positions[1], liq2, target);
          require(pos0Am0.add(pos1Am0) >= minAm0 && pos0Am1.add(pos1Am1) >= minAm1,"GebUniswapV3TwoTrancheManager/slippage-check");
        }
        uint256 __supply = _totalSupply;
        if (__supply == 0) {
          mintAmount = newLiquidity;
        } else {
          mintAmount = newLiquidity.mul(_totalSupply).div(totalLiquidity);
        }

        _mint(recipient, mintAmount);

        refundETH();
        emit Deposit(msg.sender, recipient, newLiquidity);
    }

    /**
     * @notice Remove liquidity and withdraw the underlying assets
     * @param liquidityAmount The amount of liquidity to withdraw
     * @param recipient The address that will receive token0 and token1 tokens
     * @return amount0 The amount of token0 requested from the pool
     * @return amount1 The amount of token1 requested from the pool
     */
    function withdraw(uint256 liquidityAmount, address recipient) external override returns (uint256 amount0, uint256 amount1) {
        require(recipient != address(0), "GebUniswapV3TwoTrancheManager/invalid-recipient");
        require(liquidityAmount != 0, "GebUniswapV3TwoTrancheManager/burning-zero-amount");

        uint256 __supply = _totalSupply;
        _burn(msg.sender, liquidityAmount);

        uint256 _liquidityBurned0 = liquidityAmount.mul(positions[0].uniLiquidity).div(__supply);
        require(_liquidityBurned0 < MAX_UINT128, "GebUniswapV3TwoTrancheManager/too-much-to-burn-at-once");

        uint256 _liquidityBurned1 = liquidityAmount.mul(positions[1].uniLiquidity).div(__supply);
        require(_liquidityBurned0 < MAX_UINT128, "GebUniswapV3TwoTrancheManager/too-much-to-burn-at-once");

        (uint256 am0_pos0, uint256 am1_pos0 ) = _withdraw(positions[0], uint128(_liquidityBurned0), recipient);
        (uint256 am0_pos1, uint256 am1_pos1 ) = _withdraw(positions[1], uint128(_liquidityBurned1), recipient);

        (amount0, amount1) = (am0_pos0.add(am0_pos1), am1_pos0.add(am1_pos1));
        emit Withdraw(msg.sender, recipient, liquidityAmount);
    }

    /**
     * @notice Public function to move liquidity to the correct threshold from the redemption price
     */
    function rebalance() external override {
        require(block.timestamp.sub(lastRebalance) >= delay, "GebUniswapV3TwoTrancheManager/too-soon");

        int24 target= getTargetTick();

        // Cheaper calling twice than adding a for loop
        _rebalance(positions[0], target);
        _rebalance(positions[1], target);

        // Even if there's no change, we still update the time
        lastRebalance = block.timestamp;
        emit Rebalance(msg.sender, block.timestamp);
    }
}