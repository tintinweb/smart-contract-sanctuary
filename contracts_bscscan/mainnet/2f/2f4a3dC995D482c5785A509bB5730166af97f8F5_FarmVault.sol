/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

/*



    https://icecreamswap.finance

    https://t.me/IceCreamSwap







*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
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

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol



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

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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

// File: @openzeppelin\contracts\token\ERC20\ERC20Burnable.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// File: node_modules\@openzeppelin\contracts\math\Math.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

// File: @openzeppelin\contracts\utils\Arrays.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// File: @openzeppelin\contracts\utils\Counters.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



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
abstract contract Ownable is Context {
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

// File: contracts\farming\Token.sol

/*

https://icecreamswap.finance/

Telegram: https://t.me/IceCreamSwap

Twitter: https://twitter.com/SwapIceCream

*/

pragma solidity 0.6.12;






contract Token is ERC20('VaniSwap', 'Vani'), Ownable {
    using SafeMath for uint256;
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);
    event MinterStatus(address minter, bool status);
    mapping(address => bool) private minters;
    constructor() public {
        // for presale/ido/airdrop/market
        _mint(msg.sender, 10_000 ether);
    }
    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }
    function setMinter(address _minter, bool _status) external onlyOwner {
        minters[_minter] = _status;
    }
    modifier onlyMinter() {
        require(_msgSender() == owner() || minters[_msgSender()], "err");
        _;
    }
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) external {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
    private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// File: @openzeppelin\contracts\GSN\Context.sol



pragma solidity >=0.6.0 <0.8.0;

// File: node_modules\@openzeppelin\contracts\utils\Address.sol



pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol



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

// File: contracts\farming\libs\ReentrancyGuard.sol


pragma solidity 0.6.12;


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
abstract contract ReentrancyGuard {
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

// File: contracts\farming\libs\AddrArrayLib.sol

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity 0.6.12;

library AddrArrayLib {
    using AddrArrayLib for Addresses;

    struct Addresses {
        address[]  _items;
    }

    /**
     * @notice push an address to the array
     * @dev if the address already exists, it will not be added again
     * @param self Storage array containing address type variables
     * @param element the element to add in the array
     */
    function pushAddress(Addresses storage self, address element) internal {
        if (!exists(self, element)) {
            self._items.push(element);
        }
    }

    /**
     * @notice remove an address from the array
     * @dev finds the element, swaps it with the last element, and then deletes it;
     *      returns a boolean whether the element was found and deleted
     * @param self Storage array containing address type variables
     * @param element the element to remove from the array
     */
    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the address at a specific index from array
     * @dev revert if the index is out of bounds
     * @param self Storage array containing address type variables
     * @param index the index in the array
     */
    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }

    /**
     * @notice get the size of the array
     * @param self Storage array containing address type variables
     */
    function size(Addresses storage self) internal view returns (uint256) {
        return self._items.length;
    }

    /**
     * @notice check if an element exist in the array
     * @param self Storage array containing address type variables
     * @param element the element to check if it exists in the array
     */
    function exists(Addresses storage self, address element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the array
     * @param self Storage array containing address type variables
     */
    function getAllAddresses(Addresses storage self) internal view returns(address[] memory) {
        return self._items;
    }

}

// File: contracts\farming\libs\IFarm.sol



pragma solidity 0.6.12;

interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accEggPerShare);
    function emergencyWithdraw(uint256 _pid) external;
    function poolLength()external view returns (uint256);
}

// File: contracts\farming\interfaces.sol


pragma solidity 0.6.12;


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


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


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts\farming\masterchef.sol

/*

https://icecreamswap.finance/

Telegram: https://t.me/IceCreamSwap

Twitter: https://twitter.com/SwapIceCream

*/

pragma solidity 0.6.12;












contract FarmVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for Token;
    using AddrArrayLib for AddrArrayLib.Addresses;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastDepositTime;
        uint256 rewardLockedUp;
        uint256 nextHarvestUntil;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint16 taxWithdraw;
        uint16 taxWithdrawBeforeLock;
        uint256 withdrawLockPeriod;
        uint256 lock;
        uint16 depositFee;
        uint256 cake_pid;
        uint16 harvestFee;
        uint16 unlocked;
    }

    struct PoolInfoMigration {
        uint256 startBlock;
        uint256 endBlock;
        uint256 ratio;
        bool enabled;
        address reserve;
        uint256 max;
    }

    Token public token;
    IUniswapV2Factory public factory;// = IUniswapV2Factory(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapV2Router02 public router;// = IUniswapV2Router02(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IFarm public mc;
    IERC20 public cake;

    address payable public devaddr;
    address payable public taxLpAddress;
    uint16 public reserveFee = 500;
    uint256 totalLockedUpRewards;

    uint256 public constant MAX_PERFORMANCE_FEE = 5000; // 50%
    uint256 public constant MAX_CALL_FEE = 100; // 1%
    uint256 public performanceFee = 3000; // 30%
    uint256 public callFee = 1; // 0.01%
    // 0: stake it, 1: send to reserve address
    uint256 public harvestProcessProfitMode = 2;

    event Earned(address indexed sender, uint256 pid, uint256 balance, uint256 performanceFee, uint256 callFee);

    uint256 public tokenPerBlock;
    uint256 public bonusMultiplier = 1;

    PoolInfo[] public poolInfo;

    PoolInfoMigration[] public poolInfoMigration;


    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => AddrArrayLib.Addresses) private addressByPid;
    mapping(uint256 => uint[]) public userPoolByPid;

    mapping(address => bool) public poolExists;
    mapping(address => bool) public _authorizedCaller;
    mapping(uint256 => uint256) public deposits;
    uint256 public totalAllocPoint = 0;
    uint256 public immutable startBlock;
    address payable public treasureAddress; // receive swaped asset
    address payable public reserveAddress; // receive farmed asset
    address payable public taxAddress; // receive fees

    // global vault stats
    uint256 public statsCakeCollected;
    uint256 public statsBnbCollected;
    uint256 public statsTokenBurned;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 received);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawWithTax(address indexed user, uint256 indexed pid, uint256 sent, uint256 burned);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Transfer(address indexed to, uint256 requsted, uint256 unlocked);
    event TokenPerBlockUpdated(uint256 tokenPerBlock);
    event UpdateEmissionSettings(address indexed from, uint256 depositAmount, uint256 endBlock);
    event UpdateMultiplier(uint256 multiplierNumber);
    event SetDev(address indexed prevDev, address indexed newDev);
    event SetTaxAddr(address indexed prevAddr, address indexed newAddr);
    event SetReserveAddr(address indexed prevAddr, address indexed newAddr);
    event SetAuthorizedCaller(address indexed caller, bool _status);
    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "pool id not exisit");
        _;
    }

    uint256 totalProfit; // hold total asset generated by this vault

    constructor(
        Token _token,
        uint256 _startBlock,
        address _mc, address _cake,
        address _router, address _factory
    ) public {
        token = _token;
        devaddr = msg.sender;
        taxLpAddress = msg.sender;
        reserveAddress = msg.sender;
        treasureAddress = msg.sender;
        taxAddress = msg.sender;
        tokenPerBlock = 0.1 ether;
        startBlock = _startBlock;


        factory = IUniswapV2Factory(_factory);
        router = IUniswapV2Router02(_router);

        mc = IFarm(_mc);
        cake = IERC20(_cake);
        cake.safeApprove(_mc, 0);
        cake.safeApprove(address(router), uint256(- 1));
        IERC20(router.WETH()).safeApprove(address(router), uint256(- 1));
        cake.safeApprove(_mc, uint256(- 1));

    }
    function updateTokenPerBlock(uint256 _tokenPerBlock) external onlyOwner {
        require(_tokenPerBlock <= 1 ether, "too high.");
        tokenPerBlock = _tokenPerBlock;
        emit TokenPerBlockUpdated(_tokenPerBlock);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function adminAddPool(
        uint256 _allocPoint,
        address _lpToken,
        uint16 _taxWithdraw,
        uint16 _taxWithdrawBeforeLock,
        uint256 _withdrawLockPeriod,
        uint256 _lock,
        uint16 _depositFee,
        bool _withUpdate,
        uint256 _cake_pid,
        uint16 _harvestFee
    ) external onlyOwner
    {
        _add(_allocPoint, _lpToken, _taxWithdraw, _taxWithdrawBeforeLock, _withdrawLockPeriod, _lock, _depositFee, _withUpdate, _cake_pid, _harvestFee);
    }


    function _add(
        uint256 _allocPoint,
        address _lpToken,
        uint16 _taxWithdraw,
        uint16 _taxWithdrawBeforeLock,
        uint256 _withdrawLockPeriod,
        uint256 _lock,
        uint16 _depositFee,
        bool _withUpdate,
        uint256 _cake_pid,
        uint16 _harvestFee
    ) internal
    {
        require(_depositFee <= 1000, "err1");
        require(_taxWithdraw <= 1000, "err2");
        require(_taxWithdrawBeforeLock <= 2500, "err3");
        require(_withdrawLockPeriod <= 30 days, "err4");
        require(poolExists[_lpToken] == false, "err5");

        IERC20(_lpToken).balanceOf(address(this));

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;

        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo(
            {
            lpToken : IERC20(_lpToken),
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accTokenPerShare : 0,
            taxWithdraw : _taxWithdraw,
            taxWithdrawBeforeLock : _taxWithdrawBeforeLock,
            withdrawLockPeriod : _withdrawLockPeriod,
            lock : _lock,
            depositFee : _depositFee,
            cake_pid : _cake_pid,
            harvestFee : _harvestFee,
            unlocked : 1000 // 10% of reward generated is unlocked.
            })
        );
        poolInfoMigration.push(
            PoolInfoMigration({
        startBlock : 0,
        endBlock : 0,
        ratio : 0,
        enabled : false,
        reserve : msg.sender,
        max : 0
        })
        );

        if (_cake_pid > 0) {
            require(_lpToken == getLpOf(_cake_pid), "src/lp!=dst/lp");
            IERC20(_lpToken).safeApprove(address(mc), 0);
            IERC20(_lpToken).safeApprove(address(mc), uint256(- 1));
        }

    }

    function adminSetPoolLocks(uint256 _pid,
        uint16 _taxWithdraw,
        uint16 _taxWithdrawBeforeLock,
        uint256 _withdrawLockPeriod,
        uint256 _lock,
        uint16 _depositFee,
        uint16 _harvestFee,
        uint16 _unlocked
    )
    external onlyOwner validatePoolByPid(_pid)
    {
        require(_unlocked <= 10000, "err1");
        require(_depositFee <= 1000, "err2");
        require(_taxWithdraw <= 1000, "err3");
        require(_taxWithdrawBeforeLock <= 2500, "err4");
        require(_withdrawLockPeriod <= 30 days, "err5");

        poolInfo[_pid].taxWithdraw = _taxWithdraw;
        poolInfo[_pid].taxWithdrawBeforeLock = _taxWithdrawBeforeLock;
        poolInfo[_pid].withdrawLockPeriod = _withdrawLockPeriod;
        poolInfo[_pid].lock = _lock;
        poolInfo[_pid].depositFee = _depositFee;
        poolInfo[_pid].harvestFee = _harvestFee;
        poolInfo[_pid].unlocked = _unlocked;

    }

    /*
    Allow admin to setup migration.
    - Migration allow conversion from any token to our token.
    - Every migration will stake migrated tokens to token pool.
    */
    function adminSetMigration(uint256 _pid,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _ratio,
        bool _enabled,
        address _reserve,
        uint256 _max)
    external onlyOwner validatePoolByPid(_pid) {
        poolInfoMigration[_pid].startBlock = _startBlock;
        poolInfoMigration[_pid].endBlock = _endBlock;
        poolInfoMigration[_pid].ratio = _ratio;
        poolInfoMigration[_pid].enabled = _enabled;
        poolInfoMigration[_pid].reserve = _reserve;
        poolInfoMigration[_pid].max = _max;
    }

    function adminConfigurePool(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate,
        uint256 _cake_pid
    ) external onlyOwner validatePoolByPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(
                _allocPoint
            );
        }
        IERC20 lp = poolInfo[_pid].lpToken;
        if (_cake_pid > 0 && poolInfo[_pid].cake_pid == 0) {
            require(address(lp) == getLpOf(_cake_pid), "src/lp!=dst/lp");
            lp.safeApprove(address(mc), 0);
            lp.safeApprove(address(mc), uint256(- 1));
            mc.deposit(_cake_pid, lp.balanceOf(address(this)));
        } else if (_cake_pid == 0 && poolInfo[_pid].cake_pid > 0) {
            uint256 amount = balanceOf(_pid);
            if (amount > 0)
                mc.withdraw(poolInfo[_pid].cake_pid, amount);
            lp.safeApprove(address(mc), 0);
        }
        poolInfo[_pid].cake_pid = _cake_pid;
    }

    function getMultiplier(uint256 _from, uint256 _to)
    public
    view
    returns (uint256)
    {
        return _to.sub(_from).mul(bonusMultiplier);
    }

    function pendingReward(uint256 _pid, address _user)
    public
    view
    validatePoolByPid(_pid)
    returns (uint256)
    {
        // this is a migration pool, get pending from pool token.
        if (poolInfoMigration[_pid].enabled)
            _pid = 0;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = deposits[_pid];
        uint256 tokenPendingReward;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        tokenPendingReward = user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
        return tokenPendingReward.add(user.rewardLockedUp);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
        harvestAll();
    }

    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = deposits[_pid];
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 fee = tokenReward.mul(reserveFee).div(10000); // 5%
        token.mint(devaddr, fee);
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function payRewardByPid(uint256 pid) nonReentrant public {
        _payRewardByPid(pid, msg.sender);
        _harvestAll();
    }

    function compoundAll() nonReentrant public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            compound(pid);
        }
        _harvestAll();
    }
    // Stake Token tokens to MasterChef
    function compound(uint256 _pid) public nonReentrant {
        if (pendingReward(_pid, msg.sender) > 0) {
            PoolInfo storage pool = poolInfo[_pid];
            updatePool(_pid);
            _payRewardByPid(_pid, msg.sender);
            uint256 _amount = pool.lpToken.balanceOf(msg.sender);
            deposit_internal(0, _amount);
        }
    }


    //
    function deposit(uint256 _pid, uint256 _amount)
    validatePoolByPid(_pid) nonReentrant notContract notBlacklisted
    public {
        deposit_internal(_pid, _amount);
    }

    function deposit_internal(uint256 _pid, uint256 _amount) internal

    {

        // migration support
        if (poolInfoMigration[_pid].enabled) {
            // if farm token has tax on transfer or migrated token.
            _amount = migrateToken(_pid, _amount);
            // we are migrating, so we operate on pid=0 (farm token)
            _pid = 0;
        }

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        _payRewardByPid(_pid, msg.sender);

        if (_amount > 0) {
            if (pool.depositFee > 0) {
                // this pool has deposit fee, compute it here
                uint256 tax = _amount.mul(pool.depositFee).div(10000);
                pool.lpToken.safeTransferFrom(address(msg.sender), taxAddress, tax);

                // will store value - fee to save correct deposited amount to user balance
                uint256 received;

                if (poolInfoMigration[_pid].enabled)
                // are we doing a migration? if so, amount is same
                    received = _amount.sub(tax);
                else

                // no migration, transfer token and caputure new amount in received
                    received = transferToContract(pool.lpToken, _amount.sub(tax));

                // contract balance for this pid/lp
                deposits[_pid] = deposits[_pid].add(received);
                user.amount = user.amount.add(received);
                userPool(_pid, msg.sender);
                emit Deposit(msg.sender, _pid, _amount, received);
                if (pool.cake_pid > 0) {
                    mc.deposit(pool.cake_pid, received);
                }
            } else {
                _amount = transferToContract(pool.lpToken, _amount);
                deposits[_pid] = deposits[_pid].add(_amount);
                user.amount = user.amount.add(_amount);
                userPool(_pid, msg.sender);
                emit Deposit(msg.sender, _pid, _amount);
                if (pool.cake_pid > 0) {
                    mc.deposit(pool.cake_pid, _amount);
                }
            }
            user.lastDepositTime = block.timestamp;
            if (user.nextHarvestUntil == 0 && pool.lock > 0) {
                user.nextHarvestUntil = block.timestamp.add(pool.lock);
            }

        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        _harvestAll();

    }


    event withdrawTax(uint256 tax);

    function withdraw(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid)
    nonReentrant notContract {

        // migration pool, reward from token pool
        if (poolInfoMigration[_pid].enabled)
            _pid = 0;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount >= _amount && pool.cake_pid > 0) {
            mc.withdraw(pool.cake_pid, _amount);
        }
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        _payRewardByPid(_pid, msg.sender);
        if (_amount > 0) {
            if (pool.withdrawLockPeriod > 0) {
                uint256 tax = 0;
                if (block.timestamp < user.lastDepositTime + pool.withdrawLockPeriod) {
                    if (pool.taxWithdrawBeforeLock > 0) {
                        tax = _amount.mul(pool.taxWithdrawBeforeLock).div(10000);
                    }
                } else {
                    if (pool.taxWithdraw > 0) {
                        tax = _amount.mul(pool.taxWithdraw).div(10000);
                    }
                }
                if (tax > 0) {
                    deposits[_pid] = deposits[_pid].sub(tax);
                    user.amount = user.amount.sub(tax);
                    _amount = _amount.sub(tax);
                    pool.lpToken.safeTransfer(taxLpAddress, tax);
                    emit withdrawTax(tax);
                }
            }
            _withdraw(_pid, _amount);
        }
        _harvestAll();
    }

    function _withdraw(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        deposits[_pid] = deposits[_pid].sub(_amount);
        user.amount = user.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    }

    function emergencyWithdraw(uint256 _pid) external validatePoolByPid(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        reflectEmergencyWithdraw(_pid, user.amount);
        deposits[_pid] = deposits[_pid].sub(user.amount);
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        deposits[_pid] = deposits[_pid].sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        userPool(_pid, msg.sender);
    }

    function dev(address payable _devaddr, address payable _reserve, address payable _taxLpAddress,
        address payable _taxAddress, address payable _treasureAddress) external onlyAdmin {
        devaddr = _devaddr;
        reserveAddress = _reserve;
        taxLpAddress = _taxLpAddress;
        taxAddress = _taxAddress;
        treasureAddress = _treasureAddress;
    }

    function setReserveFee(uint16 _reserveFee) external onlyAdmin {
        reserveFee = _reserveFee;
    }

    function getTotalPoolUsers(uint256 _pid) external virtual view returns (uint256) {
        return addressByPid[_pid].getAllAddresses().length;
    }

    function getAllPoolUsers(uint256 _pid) public virtual view returns (address[] memory) {
        return addressByPid[_pid].getAllAddresses();
    }

    function userPoolBalances(uint256 _pid) external virtual view returns (UserInfo[] memory) {
        address[] memory list = getAllPoolUsers(_pid);
        UserInfo[] memory balances = new UserInfo[](list.length);
        for (uint i = 0; i < list.length; i++) {
            address addr = list[i];
            balances[i] = userInfo[_pid][addr];
        }
        return balances;
    }

    function userPool(uint256 _pid, address _user) internal {
        AddrArrayLib.Addresses storage addresses = addressByPid[_pid];
        uint256 amount = userInfo[_pid][_user].amount;
        if (amount > 0) {
            addresses.pushAddress(_user);
        } else if (amount == 0) {
            addresses.removeAddress(_user);
        }
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyAdmin {
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "performanceFee cannot be more than MAX_PERFORMANCE_FEE");
        performanceFee = _performanceFee;
    }

    function setCallFee(uint256 _callFee) external onlyAdmin {
        require(_callFee <= MAX_CALL_FEE, "callFee cannot be more than MAX_CALL_FEE");
        callFee = _callFee;
    }

    function setHarvestProcessProfitMode(uint16 mode) external onlyAdmin {
        harvestProcessProfitMode = mode;
    }

    function getLpOf(uint256 pid) public view returns (address) {
        (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCakePerShare) = mc.poolInfo(pid);
        return lpToken;
    }

    function balanceOf(uint256 pid) public view returns (uint256) {
        (uint256 amount,) = mc.userInfo(pid, address(this));
        return amount;
    }

    function pendingCake(uint256 pid) public view returns (uint256) {
        return mc.pendingCake(pid, address(this));

    }

    function calculateHarvestRewards(uint256 pid) external view returns (uint256) {
        return pendingCake(pid).mul(callFee).div(10000);
    }

    mapping(address => bool) public contractAllowed;
    mapping(address => bool) public blacklist;
    modifier notContract() {
        if (contractAllowed[msg.sender] == false) {
            require(!_isContract(msg.sender), "CnA");
            require(msg.sender == tx.origin, "PCnA");
        }
        _;
    }
    modifier notBlacklisted() {
        require(blacklist[msg.sender] == false, "BLK");
        _;
    }
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setContractAllowed(bool status) external onlyAdmin {
        contractAllowed[msg.sender] = status;
    }

    function setBlaclisted(address addr, bool status) external onlyAdmin {
        blacklist[addr] = status;
    }

    event EnterStaking(uint256 amount);
    event TransferToReserve(address to, uint256 amount);
    function adminProcessReserve() external onlyAdmin {
        uint256 reserveAmount = balanceOf(0);
        if (reserveAmount > 0) {
            mc.leaveStaking(reserveAmount);
            cake.safeTransfer(reserveAddress, reserveAmount);
        }
    }

    function harvestAll() public nonReentrant {
        _harvestAll();
    }

    function _harvestAll() internal {
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            uint256 pid = poolInfo[i].cake_pid;
            if (pid == 0 || balanceOf(pid) == 0 ) {
                continue;
            }
            mc.deposit(pid, 0);
            uint256 balance = cake.balanceOf(address(this));
            if (balance > 0) {
                statsCakeCollected = statsCakeCollected.add(balance);
                uint256 currentPerformanceFee = balance.mul(performanceFee).div(10000);
                uint256 currentCallFee = balance.mul(callFee).div(10000);
                cake.safeTransfer(devaddr, currentPerformanceFee);
                cake.safeTransfer(msg.sender, currentCallFee);
                uint256 reserveAmount = cake.balanceOf(address(this));
                emit Earned(msg.sender, pid, balance, currentPerformanceFee, currentCallFee);
                if (reserveAmount > 0) {
                    swapAll( reserveAmount );
                }
            }
        }
    }

    function inCaseTokensGetStuck(address _token, address to) external onlyAdmin {
        require(_token != address(token), "!token");
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            require(address(poolInfo[pid].lpToken) != _token, "!pool asset");
        }
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, amount);
    }

    function reflectEmergencyWithdraw(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.cake_pid == 0) return;
        mc.withdraw(pool.cake_pid, _amount);
    }

    function adminEmergencyWithdraw(uint256 _pid) external onlyAdmin {
        mc.emergencyWithdraw(poolInfo[_pid].cake_pid);
    }

    function panicAll() external onlyAdmin {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            if (pool.cake_pid != 0) {
                mc.emergencyWithdraw(pool.cake_pid);
                pool.lpToken.safeApprove(address(mc), 0);
                pool.cake_pid = 0;
            }
        }
    }

    function panic(uint256 pid) public onlyAdmin {
        PoolInfo storage pool = poolInfo[pid];
        if (pool.cake_pid != 0) {
            mc.emergencyWithdraw(pool.cake_pid);
            pool.lpToken.safeApprove(address(mc), 0);
            pool.cake_pid = 0;
        }
    }
    modifier onlyAdmin() {
        // does not manipulate user funds and allow fast actions to stop/panic withdraw
        require(msg.sender == owner() || msg.sender == devaddr, "access denied");
        _;
    }

    function canHarvest(uint256 pid, address recipient) public view returns (bool){
        // PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][recipient];
        // return pool.lock == 0 || block.timestamp >= user.lastDepositTime + pool.lock;
        return block.timestamp >= user.nextHarvestUntil;
    }

    function _payRewardByPid(uint256 pid, address recipient) internal {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][recipient];
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(pid, recipient)) {
            uint256 totalRewards = pending.add(user.rewardLockedUp);
            if (totalRewards > 0) {
                uint256 fee = 0;
                if (pool.harvestFee > 0) {
                    fee = totalRewards.mul(pool.harvestFee).div(10000);
                    token.mint(taxAddress, fee);
                }

                totalRewards = totalRewards.sub(fee);
                uint256 unlocked = totalRewards.mul(pool.unlocked).div(10000);
                token.mint(recipient, unlocked);
                emit Transfer(recipient, totalRewards, unlocked);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.lock);
            }
        } else {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
        }
        // emit PayReward(recipient, pid, status, user.amount, pending, user.rewardDebt);
    }

    function transferToContract(IERC20 lp, uint256 amount) internal returns (uint256){
        require(amount > 0, "amount=0");
        uint256 oldBalance = lp.balanceOf(address(this));
        lp.safeTransferFrom(address(msg.sender), address(this), amount);
        uint256 newBalance = lp.balanceOf(address(this));
        return newBalance.sub(oldBalance);
    }

    event Migration(address indexed user, uint256 indexed pid, uint256 amount);
    // control the max amount user can migrate
    mapping(address => mapping(uint256 => uint256)) private _migrationPool;

    // migration routine
    function migrateToken(uint256 _pid, uint256 amount) internal returns (uint256){
        require(poolInfoMigration[_pid].enabled, "invalid migration");
        PoolInfo storage pool = poolInfo[_pid];
        PoolInfoMigration storage mig = poolInfoMigration[_pid];
        require(mig.startBlock == 0 || mig.startBlock >= block.number, "invalid start");
        require(mig.endBlock == 0 || mig.endBlock < block.number, "already finished");
        require(mig.max == 0 || amount <= mig.max && _migrationPool[msg.sender][_pid] <= mig.max, "too much token to migrate");
        uint256 oldBalance = pool.lpToken.balanceOf(address(this));
        pool.lpToken.safeTransferFrom(address(msg.sender), mig.reserve, amount);
        uint256 newBalance = pool.lpToken.balanceOf(address(this));
        amount = newBalance.sub(oldBalance);
        require(amount > 0, "amount=0");

        // stake minted amount in the native pool
        emit Migration(msg.sender, _pid, amount);
        _migrationPool[msg.sender][_pid] = _migrationPool[msg.sender][_pid].add(amount);

        if (mig.ratio > 1) amount = amount.div(mig.ratio);
        token.mint(msg.sender, amount);
        return amount;
    }

    function _createPair(IERC20 _a, IERC20 _b) internal returns (address){
        address a = address(_a);
        address b = address(_b);
        address addr = factory.getPair(a, b);
        if (addr == 0x0000000000000000000000000000000000000000) {
            addr = factory.createPair(a, b);
        }
        require(addr != 0x0000000000000000000000000000000000000000, "invalid pair");
        return addr;
    }

    event SwapNoBalance(uint8 id);
    event SwapAndBurn(uint256 cake, uint256 wbnb, uint256 token);
    event SwapAllNoBalances(uint256 cakeBalance, uint256 wbnb);

    function swapAll( uint256 cakeBalance ) internal {
        uint256 bnbCollected = _safeSwap(1, cakeBalance, address(cake), router.WETH());
        if (bnbCollected > 0) {
            statsBnbCollected = statsBnbCollected.add(bnbCollected);
            uint256 toBurn = _safeSwap(2, bnbCollected, router.WETH(), address(token));
            if (toBurn > 0) {
                statsTokenBurned = statsTokenBurned.add(toBurn);
                token.safeTransfer(treasureAddress, toBurn);
            }
            emit SwapAndBurn(cakeBalance, bnbCollected, toBurn);
        } else {
            lastId = 3;
            emit SwapAllNoBalances(cakeBalance, bnbCollected);
        }
    }

    event Swapped(uint8 id, uint256 tokenBalance, uint256 bnbAmount, address token);
    uint8 public lastId;
    function _safeSwap(uint8 id, uint256 tokenBalance, address token0, address token1) internal returns (uint256) {
        if (tokenBalance > 0) {
            address[] memory _path = new address[](2);
            _path[0] = token0;
            _path[1] = token1;
            uint256 bnbBefore = IERC20(token1).balanceOf(address(this));
            router.swapExactTokensForTokens(tokenBalance, 0, _path, address(this), now.add(600));
            uint256 bnbAfter = IERC20(token1).balanceOf(address(this));
            uint256 bnbAmount = bnbAfter.sub(bnbBefore);
            emit Swapped(1, tokenBalance, bnbAmount, token0);
            return bnbAmount;
        } else {
            lastId = id;
            emit SwapNoBalance(id);
        }
        return 0;
    }


}