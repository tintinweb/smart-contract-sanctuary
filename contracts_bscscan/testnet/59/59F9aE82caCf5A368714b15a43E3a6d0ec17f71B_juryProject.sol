/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

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

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
}

contract tokenMigration is AccessControl, Pausable{
    
    address GiftingAddress;
    
    constructor() {
     GiftingAddress = msg.sender;
     _setupRole(DEFAULT_ADMIN_ROLE, GiftingAddress);
    }
    
    // this contract is to swap the old Spon tokens with the new Spon tokens 
    // if the user doesnt have any old spon tokens the swap function will not continue and will drop an error
    // after the swap complets an event will take a place and his old spon tokens will be swapped
    
    // this is the real contract address of the old token
    //0xD1992F0BAcfdb7D195a819306c30eA65F73080af
      // ERC20 oldSponToken = ERC20(0x25A038EeE581d2a45F6a5c1fa3f355e08D20D4CD);
      ERC20 oldSponToken = ERC20(0x25A038EeE581d2a45F6a5c1fa3f355e08D20D4CD);
    // this is the real contract address of the new token
    //0xE41d9E1311209F2e05850F9de6201Ab4B930Bfc2
     // ERC20 newSponToken = ERC20(0x1415D17851EA092D6121b6A4de6bF8E0210A81F2);
     ERC20 newSponToken = ERC20(0x1415D17851EA092D6121b6A4de6bF8E0210A81F2);


    // this mapp to save the commit balance of the users
    mapping(address=>uint256) public committedBalance;
    
    event SwapToken(uint256 oldSponToken, uint256 newSponToken, uint256 committedBalance);

    // the amount will be directly user old spon balance in line 61 
    // zaid has 1000 OLD spon 
    // take the 1000 OLD SPON from me 
    // and i will recive 1000 new spon

    // is it good to make the user do 2 approves and we do 1 approve to implement a function ?
    // 1 approve from the old spon user to the migration contract so that it can take the old spon from him
    // 1 approve to the jury contract to take the 500 new spon tokens from him
    // 1 approve from Sponsee team to give him the 1000 new spon tokens  
    
    function swapToken(uint256 userCommittedBalance) public whenNotPaused(){

        address ownerOfOldSpon = msg.sender;
        uint256 userOldSponBalance = oldSponToken.balanceOf(ownerOfOldSpon);
        uint256 userNewSponBalance = userOldSponBalance - userCommittedBalance;
        
        require(ownerOfOldSpon != address(0), "Sponsee: Invalid address");
        require(userOldSponBalance > 0, "Sponsee: your balance is zero");
        require(userOldSponBalance >= userCommittedBalance, "Sponsee: invalid amount");
        require(newSponToken.balanceOf(GiftingAddress)>= userNewSponBalance, "Sponsee: invalid amount");
        
        committedBalance[ownerOfOldSpon] = userCommittedBalance;
        
        // approve needed from the suer
        oldSponToken.transferFrom(ownerOfOldSpon, GiftingAddress, userOldSponBalance);
        // approve needeed from Sponsee owners
        newSponToken.transferFrom(GiftingAddress, ownerOfOldSpon, userNewSponBalance);

        emit SwapToken(userOldSponBalance, userNewSponBalance, userCommittedBalance);
    }

    
    // Query functions

    // this function might be usefull to query for the user old Spon tokens to display in frontend when the user connects his wallet
    function oldSponBalance(address _user) public view returns (uint256){
       uint256 QueryBalance =  oldSponToken.balanceOf(_user);
       return QueryBalance;
    }
    
    // this function might be usefull to query for the user new Spon tokens to display in frontend when the user connects his wallet
    function newSponBalance(address _user) public view returns (uint256){
       uint256 QueryBalance2 =  newSponToken.balanceOf(_user);
       return QueryBalance2;
    }
    
    function getOwnerGiftAddress() public view returns(address){
        return GiftingAddress;
    }

    function getuserAddress() public view returns(address){
        address userAddress = msg.sender;
        return userAddress;
    }

    function getUserCommittedBalance(address _user) public view returns (uint256){
        uint256 queryCommittedBalance = committedBalance[_user];
        return queryCommittedBalance;
    }

    function startPasue() public whenNotPaused(){
    require(
      hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "Caller is not an admin"
    );

    // we pasue the contract for ever and we end sign it from our side to close it
    super._pause();
  }


  function startUnpasue() external {

      require(
      hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "Caller is not an admin"
    );
    
    // Active the Unpause function
    super._unpause();

    // Notify...
    emit Unpaused(_msgSender());
  }
}

contract juryProject is AccessControl, Pausable {
    using SafeMath for uint256;

    address owner;
    bool proposalsActivity = false; // if its false that means no active contract (Satarday and monday)/ if its ture then the proposals are active (monday to frieday)


    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant UNSTAKED_WALLET_ROLE = keccak256("UNSTAKED_WALLET_ROLE");

    constructor() public {
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(ADMIN_ROLE, owner);
    }

    // this mapping saves the SPON tokens when the user commits his Balance
    mapping(address => uint256) committedBalance;

    // this mapping will track the users to only make them merge the committed balance once
    mapping(address => bool) mergeBalanceAddress;

    // this mapping is to save the addresses that picked option A from every proposal ID
    mapping(uint256 => address[]) optionAUsers;

    // this mapping is to save the addresses that picked option B from every proposal ID
    mapping(uint256 => address[]) optionBUsuers;

    // this mapping is just to make sure that users cannot spam vote the same proposal
    // so each user can only vote once
    mapping(uint256 => mapping(address => uint256)) voteCheck;

    // this mapping is to save the proposals
    mapping(uint256 => JuryProposals) public juryProposals;

    
    // this mapping is to save the number of votes weekly
    mapping(address => uint256)  public usersWeeklyVotesCount;

    // this mapping is to track the user addresses and their weekly votes to make sure that users addresses wont shit votes from one week to the other 
    mapping (address => uint256) public  userWeeklyVoteCounter;

    uint256 weeklyVotesLimit = 2;


    // this counter shows in numbers the total proposals
    // great for showcase in UI in general
    uint256 proposalCounter = 1;

    // this counter is to track the weeks of the jruy proposals, each time the defult admin changels the refreshWeeklyVotesStatus it will add acounter
    // to make sure people can't shit their votes to other weeks 
    uint256 public refreshVotesIndicatorCounter = 0;

    // this is the real contract address of the new token
    //ERC20 newSponToken = ERC20(0xD1992F0BAcfdb7D195a819306c30eA65F73080af);
    
    // this is the fake (for testing) contract address of the new tokenQuantity
      ERC20 newTestSponToken = ERC20(0x1415D17851EA092D6121b6A4de6bF8E0210A81F2);
        //ERC20 newTestSponToken = ERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);

    // migration contract (mainnet)
    //tokenMigration migration = tokenMigration(0xcaf6048F37888d8a617D13edd9ac797eEF0Fb51e);

    // migration contract (testnet)
    tokenMigration migration = tokenMigration(0x2dD94cBbB808d4B9639b34C15b001EE3f7E5ae02);

    event CreateNewProposal(
        uint256 proposalIdNumber,
        string proposalDescription,
        bool adminAnswer,
        uint256 rewardPercent,
        uint256 rewardPercentDecimal,
        uint256 votesLimit,
        bool proposalStatus,
        bool lockedAnswer,
        bool rewardsDistributed
    );

    event EndProposal(uint256 proposalID);

    event DistributeRewards(uint256 contractId);

    event AddCommitedBalance(uint256 amount);

    event WithdrawCommittedBalance(address indexed user, uint256 amount);

    event MergeCommittedBalance(address indexed user, uint256 amount);

    event ChoseOptionA(address indexed user);

    event ChoseOptionB(address indexed user);

    // a struct to save all the contracts created by the Shilly project
    struct JuryProposals {
        uint256 contractID; // this is the ID of the proposal, each proposal has an ID starting from 1.
        string proposalDescription; // this is the description of the whole proposal plus the options.
        uint256 optionOneCounter; // this is the counter of option B voters.
        uint256 optionTwoCounter; // this is the counter of option A voters.
        bool adminAnswer; // this is the tie breaker when the users votes endup 50% 50%.
        uint256 rewardPercent; // this is the reward percent that will be givine to user from their total commit balance, example: 2  means 2%.
        uint256 rewardPercentDecimal; // this is the decimals of the rewards percent, (for example: 2 = 0.02, 3 = 0.002) "the number of zeros".
        uint256 votesLimite; // the max number of addresses that are gonna be rewarded.
        bool proposalStatus; // if true: proposal is still active and accepts users votes, if false: proposal ended and can't accept users votes.
        bool lockedAnswer; // if true: option 1 (A) is choosen and locked, if false: option 2 (B) is choosen and locked.
        bool rewardsDistributed; // if true: rewards has been given for this proposal, if false: the proposal might be ended or still active but the rewards still not distributed
    }

    function addressRequireChecks()internal view{
        address user = _msgSender();
        require(user != address(0), "invalid address");
    }

    function checkAdminRole() internal view {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Jury Protocol: this address is not an admin."
        );
    }

    function notAdminCheck()internal view{
        address user = _msgSender();
        require(
            hasRole(ADMIN_ROLE, user) == false,
            "Jury Protocol: this address an admin."
        );
    }

    function checkForProposalIdStatus(uint256 selectedProposalId)internal view {
        require(
            juryProposals[selectedProposalId].proposalStatus == true,
            "Jury Protocol: this proposal is already ended or not active"
        );
    }

    function createNewProposal(
        string memory proposalDescription,
        bool adminAnswer,
        uint256 rewardPercent,
        uint256 rewardPercentDecimal,
        uint256 votesLimit
    ) public whenNotPaused returns(uint256) {
        addressRequireChecks();
        checkAdminRole();
        require(
            bytes(proposalDescription).length != 0,
            "Jury Protocol: proposal Description can't be empty."
        );
        require(rewardPercent > 0, "Jury Protocol: reward cannot be zero.");
        require(
            rewardPercentDecimal > 0,
            "Jury Protocol: reward Percent Decimal must be more than zero."
        );
        // might also add cant be bigger than 1,000
        require(
            votesLimit > 0,
            "Jury Protocol: vote limits must be bigger than zero"
        );

        juryProposals[proposalCounter] = JuryProposals(
            proposalCounter,
            proposalDescription,
            0,
            0,
            adminAnswer,
            rewardPercent,
            rewardPercentDecimal,
            votesLimit,
            true, // if its true then the contract is still active, if its false then the contract is ended and ready to distribute rewards
            false, // defult solidity bool value
            false // defult solidity bool value, if its false then the proposal still didint distrubute rewards even if its active or ended
        );


        uint256 currentProposalId = proposalCounter;

        proposalCounter = proposalCounter.add(1);

        emit CreateNewProposal(
            currentProposalId,
            proposalDescription,
            adminAnswer,
            rewardPercent,
            rewardPercentDecimal,
            votesLimit,
            true,
            false,
            false
        );

        return (currentProposalId);
    }

    uint256 fetched;

    function distributeRewards(uint256 selectedProposalId)
        public
        whenNotPaused
    {
        addressRequireChecks();
        checkAdminRole();

        require(
            juryProposals[selectedProposalId].proposalStatus == false,
            "Jury Protocol: this proposal is still active (struct check)"
        );

        require(
            juryProposals[selectedProposalId].rewardsDistributed == false,
            "Jury Protocol: this proposal already distributed rewards"
        );

        // here we fetch the correct answer from the selected proposal smart cotnract
        bool lockedAnswer = juryProposals[selectedProposalId].lockedAnswer;

        // fetch the correct addresses
        address[] memory correctAddresses;
        if (lockedAnswer == true) {
            correctAddresses = optionAUsers[selectedProposalId];
        } else if (lockedAnswer == false) {
            correctAddresses = optionBUsuers[selectedProposalId];
        }

        // here we get the reward percentage
        uint256 fetchedRewardPercent = juryProposals[selectedProposalId]
            .rewardPercent; // 10% in solidity we cant add float  (10)

        // here we fetch the vote limits enterd by the admin in the smart contract proposal
        uint256 fetchedVotesLimit = juryProposals[selectedProposalId]
            .votesLimite; // 1000 or what ever the admin picks

        // we need to change this when we go to main net
        uint8 sponDecimals = newTestSponToken.decimals();

        // uint256 rewardPercentInFloat = rewardPercent.div(100); DOESNT WORK
        uint256 rewardPercentInFloat = fetchedRewardPercent.mul(10**sponDecimals).div(
            100
        );

        uint256 rewardPercentInFloat2 = fetchedRewardPercent.mul(10**sponDecimals).div(
            1000
        );

        // the total reward of the fecthed  proposal id will be saved in this varialbe
        uint256 totalReward;

        uint256 proposalRewardPercentDecimals = juryProposals[
            selectedProposalId
        ].rewardPercentDecimal;

        // here we run a loop on the addresses with a correct answer and update their balance
        // and also update the totalReward variable
        if (proposalRewardPercentDecimals == 2) {
            for (uint256 i = 0; i <= correctAddresses.length - 1; i++) {
                if (i > fetchedVotesLimit - 1) {
                    break;
                }

                address selectedAddress = correctAddresses[i];

                uint256 userCommitedBalance = committedBalance[selectedAddress]
                    .div(1000000000000000000);

                uint256 rewardGranted = userCommitedBalance.mul(
                    rewardPercentInFloat
                );

                committedBalance[selectedAddress] = committedBalance[
                    selectedAddress
                ].add(rewardGranted);

                totalReward = totalReward.add(rewardGranted);
            }

            fetched = totalReward;
        } else if (proposalRewardPercentDecimals == 3) {
            for (uint256 i = 0; i <= correctAddresses.length - 1; i++) {
                if (i > fetchedVotesLimit - 1) {
                    break;
                }
                address selectedAddress = correctAddresses[i];

                uint256 userCommitedBalance = committedBalance[selectedAddress]
                    .div(1000000000000000000);

                uint256 rewardGranted = userCommitedBalance.mul(
                    rewardPercentInFloat2
                );

                committedBalance[selectedAddress] = committedBalance[
                    selectedAddress
                ].add(rewardGranted);

                totalReward = totalReward.add(rewardGranted);
            }

            fetched = totalReward;
        }

        // implement an approve from Sponsee (company) side contract to jury Registry contract from frontend ui
        // transfer the total reward from the admin (sponsee team) to the smart contract and lock it under the correct users addresses
        newTestSponToken.transferFrom(owner, address(this), totalReward.add(1));

        juryProposals[selectedProposalId].rewardsDistributed = true;

        emit DistributeRewards(selectedProposalId);
    }

    function choseOptionA(uint256 selectedProposalId) public whenNotPaused {
        address user = msg.sender;
        require(user != address(0), "invalid address");
        require(
            committedBalance[user] > 0,
            "Jury Protocol: user's committed balance is zero."
        );

        require(usersWeeklyVotesCount[user] < weeklyVotesLimit, "Jury Protocol: you used all your current votes");

        notAdminCheck();

        //here we fetch the index of the proposal smart contract address in the array
        //in order to run a require check on it if its exsists
        checkForProposalIdStatus(selectedProposalId);

        // make sure that the user cannot vote more than once
         require(voteCheck[selectedProposalId][user] != 1, "user already voted for this proposal");

        
        // check the weekly votes status
        require(userWeeklyVoteCounter[user] == refreshVotesIndicatorCounter, "Jury protocol: the current votes you own is from past weeks please refresh the votes");

        // adding 1 to the approve coutner
        juryProposals[selectedProposalId].optionOneCounter = juryProposals[
            selectedProposalId
        ].optionOneCounter.add(1);

        // adding the user address to the approved mapping
        // if you query the user address in this proposal you will see that its stated as true as the user approved the proposal
         optionAUsers[selectedProposalId].push(user);

        // add a counter to the user address in the mapping to make sure that this address cannot vote again in this proposal
         voteCheck[selectedProposalId][user] = 1;

         usersWeeklyVotesCount[user] = usersWeeklyVotesCount[user].add(1);

         // event
        emit ChoseOptionA(user);
    }

    function choseOptionB(uint256 selectedProposalId) public whenNotPaused {
        address user = _msgSender();
        require(user != address(0), "invalid address");
        require(
            committedBalance[user] > 0,
            "Jury Protocol: user's committed balance is zero."
        );

        require(usersWeeklyVotesCount[user] < weeklyVotesLimit, "Jury Protocol: you used all your current votes");
        
        notAdminCheck();

        // here we fetch the index of the proposal smart contract address in the array
        // in order to run a require check on it if its exsists
        checkForProposalIdStatus(selectedProposalId);

        // make sure that the user cannot vote more than once
        require(voteCheck[selectedProposalId][user] != 1, "user already voted for this proposal");

        // check the weekly votes status
        require(userWeeklyVoteCounter[user] == refreshVotesIndicatorCounter, "Jury protocol: the current votes you own is from past weeks please refresh the votes");


        // adding 1 to the approve coutner
        juryProposals[selectedProposalId].optionTwoCounter = juryProposals[
            selectedProposalId
        ].optionTwoCounter.add(1);

        // adding the user address to the approved mapping
        // if you query the user address in this proposal you will see that its stated as true as the user approved the proposal
        optionBUsuers[selectedProposalId].push(user);

        // add a counter to the user address in the mapping to make sure that this address cannot vote again in this proposal
        voteCheck[selectedProposalId][user] = 1;

        usersWeeklyVotesCount[user] = usersWeeklyVotesCount[user].add(1);

        // event
        emit ChoseOptionB(user);
    }

    // this function can only be used by the owner address from the Jury registry
    // this function can only be implemented by Sponsee team
    function endProposal(uint256 selectedProposalId) public whenNotPaused {
        addressRequireChecks();
        checkAdminRole();
        // here we fetch the index of the proposal smart contract address in the array
        // in order to run a require check on it if its exsists
        checkForProposalIdStatus(selectedProposalId);

        uint256 optionOneCounterFetched = juryProposals[selectedProposalId]
            .optionOneCounter;

        uint256 optionTwoCounterFetched = juryProposals[selectedProposalId]
            .optionTwoCounter;

        if (optionOneCounterFetched == optionTwoCounterFetched) {
            juryProposals[selectedProposalId].lockedAnswer = juryProposals[
                selectedProposalId
            ].adminAnswer;
        } else if (optionOneCounterFetched > optionTwoCounterFetched) {
            juryProposals[selectedProposalId].lockedAnswer = true;
        } else if (optionTwoCounterFetched > optionOneCounterFetched) {
            juryProposals[selectedProposalId].lockedAnswer = false;
        }

        juryProposals[selectedProposalId].proposalStatus = false;

        emit EndProposal(selectedProposalId);
    }

    // this function is to add commit balance from the spon token
    function addCommitedBalance(uint256 amount) public whenNotPaused {
        address user = _msgSender();
        require(user != address(0), "Jury Protocol: invalid address.");
        // we need to change this when we go to main net
        require(
            newTestSponToken.balanceOf(user) > 0,
            "Jury Protocol: user doesnt own any spon tokens."
        );

        // we need to change this when we go to main net
        newTestSponToken.transferFrom(user, address(this), amount);

        // update the user commit balance with the amount he entered
        committedBalance[user] = committedBalance[user] + amount;

        emit AddCommitedBalance(amount);
    }

    // this function is to allow the user to withdraw his spon commited balance
    function withdrawCommittedBalance() public {
        address user = msg.sender;
        require(user != address(0), "Jury Protocol: invalid address.");
        require(
            committedBalance[user] > 0,
            "Jury Protocol: user's committed balance is zero."
        );

        require(proposalsActivity == false, "Jury Protocol: proposalas are currently active, you can't withdraw at the moment.");


        uint256 SponBalance = newTestSponToken.balanceOf(address(this));

        // fetch the user commited balance
        uint256 userLockedBalance = committedBalance[user];
        require(
            userLockedBalance <= SponBalance,
            "Jury Protocol: there is no enough balance in the smart contract."
        );

        // transfer the tokens to the user
        // we need to change this when we go to main net
        newTestSponToken.transfer(user, userLockedBalance);

        // update his new commited balance to zero in jury Registry contract
        committedBalance[user] = 0;

        // notify
        emit WithdrawCommittedBalance(user, userLockedBalance);
    }

    function mergeCommittedBalance() public whenNotPaused {
        address user = msg.sender;

        require(user != address(0), "Jury Protocol: invalid address.");
        require(
            migration.getUserCommittedBalance(user) > 0,
            "Jury Protocol: user does not own any commit balance."
        );
        require(
            mergeBalanceAddress[user] == false,
            "Jury Protocol: the user already merged his balance."
        );
        require(
            hasRole(UNSTAKED_WALLET_ROLE, user) == false,
            "Jury Protocol: this address manually unstaked."
        );

        // implement an approve from the sponsee owner contract to jury project contract
        // so that we can transfer the user migration committed tokens here in this contract and lock it in here under the user address

        // Fetch the old commit amount from the migration contract
        uint256 amount = migration.getUserCommittedBalance(user);

        // this is the reward for early stakers
        uint256 rewardAmount = 2000 * 10**18; 

        uint256 finalAmount = amount.add(rewardAmount);

        // transfer the Spon tokens to the contract and lock them
        newTestSponToken.transferFrom(owner, address(this), finalAmount);

        // add the merged committed balance to his balance in the jury Registry contract
        committedBalance[user] = committedBalance[user] + finalAmount;

        // add his address as true in the tracking mapping in order to not let the user active that function again
        mergeBalanceAddress[user] = true;

        //notify...
        emit MergeCommittedBalance(user, amount);
    }

    function changeProposalsActivity () public {
        addressRequireChecks();
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Jury Protocol: Caller is not a main admin."
        );

        if(proposalsActivity == false){
            proposalsActivity = true;
        } else if (proposalsActivity == true) {
            proposalsActivity = false;
        }
    }

    function getProposalsActivity () public view returns (bool){
        return proposalsActivity;
    }


    // Query functions
    // this function might be usefull to query for the user new Spon tokens to display in frontend when the user connects his wallet
    function newSponBalance(address _user) public view returns (uint256) {
        uint256 QueryBalance2 = newTestSponToken.balanceOf(_user);
        return QueryBalance2;
    }

    // this function is to fetch the user spon commited balance locked in the contract
    function getUserCommittedBalance(address _user)
        public
        view
        returns (uint256)
    {
        uint256 queryCommittedBalance = committedBalance[_user];
        return queryCommittedBalance;
    }

    // view user address
    function getuserAddress() public view returns(address){
        address userAddress = _msgSender();
        return userAddress;
    }

    function getLatestProposalCounter() public view returns(uint256) {
        uint256 fetchedId;

        if(proposalCounter == 1) {
            fetchedId = 1;
        } else {
            fetchedId = proposalCounter -1;
        }

        return (fetchedId);
    }

    // this function is to add a new admin
    // admins are allowed to create, end and distribute rewards of smart contract proposals
    function addAdmin(address approvedAdmin) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Jury Protocol: Caller is not a main admin."
        );
        require(
            approvedAdmin != address(0),
            "Jury Protocol: invalied address."
        );

        grantRole(ADMIN_ROLE, approvedAdmin);
    }

    // this function is to remove a current admin
    // admins removed can't create,end and distribute rewards of smart contracts proposals
    function removeAdmin(address removedAdmin) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Jury Protocol: Caller is not a main admin."
        );
        require(removedAdmin != address(0), "Jury Protocol: invalied address.");

        require(removedAdmin != owner, "Jury Protocol: Defult admin cannot remove himself from being admin.");

        // remove the admin role from an address
        revokeRole(ADMIN_ROLE, removedAdmin);
    }

    // this function is a check function just to make sure that the user (addrtess) that implement the function is an admin
    function isAdminCheck(address user) public view {
        require(
            hasRole(ADMIN_ROLE, user),
            "Jury Protocol: this address is not an admin."
        );
    }

    // this function is to an address as unstaked
    // this function will assign a UNSTAKED_WALLET_ROLE (Role) to an address and that address can't use the merge function
    function addUnstakedAddress(address unstakedUser) public  {
        require(unstakedUser != address(0), "invalid address");
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Jury Protocol: Caller is not a main admin."
        );

        grantRole(UNSTAKED_WALLET_ROLE, unstakedUser);
    }


    // admin function to change the limit of weekly votes
    function setWeeklyVotesLimit(uint256 count) public whenNotPaused {
        require(_msgSender() != address(0), "invalid address");
        require(count > 0, "Jury Protocol: number of weekly votes can't be zero.");
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Jury Protocol: Caller is not a main admin."
        );

        weeklyVotesLimit = count;
    }

    function getWeeklyVotesLimit() public view returns (uint256) {
        return weeklyVotesLimit;
    }

    // view function to show how many proposals left
    function getUserWeeklyVotes(address user) public view returns (uint256){
        uint256 fetchedNumber = usersWeeklyVotesCount[user];
        uint256 printedOutNumber;

        if(weeklyVotesLimit <= fetchedNumber) {
            printedOutNumber = 0;
        } else if(fetchedNumber == 0){
            printedOutNumber = weeklyVotesLimit;
        }else if(fetchedNumber == 1){
            printedOutNumber = weeklyVotesLimit.sub(1); // 2 - 1 = 1
        } else if(fetchedNumber == 2){
            printedOutNumber = weeklyVotesLimit.sub(2); // 2 - 2 = 0 
        } else if(fetchedNumber == 3){
            printedOutNumber = weeklyVotesLimit.sub(3); // 4 - 3 = 1 
        } else if(fetchedNumber == 4) {
            printedOutNumber = weeklyVotesLimit.sub(4); // 4 - 4 = 0 
        }

        return printedOutNumber;
    }

    // user should click on this
    // create a button named refresh weekly votes under the view of remaining votes
    function refreshUserVotes(address user) public {
        require(user != address(0), "invalid address");
        require(userWeeklyVoteCounter[user]  != refreshVotesIndicatorCounter, "Jury Protocol: you already refreshed the votes this week");

        userWeeklyVoteCounter[user] = refreshVotesIndicatorCounter;

        usersWeeklyVotesCount[user] = 0;
    }

    // admin should click on this
    function changeRefreshVotesStatus() public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Jury Protocol: Caller is not a main admin."
        );
        refreshVotesIndicatorCounter = refreshVotesIndicatorCounter.add(1);
    }

    function getRefreshVotesIndicatorCounter() public view returns(uint256){
        return refreshVotesIndicatorCounter;
    }

    

    // this function will pasue the smart contract
    // in case of any unexpected thing happen
    // when the contract is pasued it can't use any function
    function startPause() public whenNotPaused {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not an admin"
        );

        // we pasue the contract for ever and we end sign it from our side to close it
        super._pause();
    }

    // this function is to unpasue the contract so that the functions can be called again
    function startUnpause() public whenPaused {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not an admin."
        );

        // Active the Unpause function
        super._unpause();

        // Notify...
        emit Unpaused(_msgSender());
    }
}