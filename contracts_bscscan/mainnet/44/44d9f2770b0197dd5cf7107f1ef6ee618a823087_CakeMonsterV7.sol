/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]





/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]





/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]







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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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


// File @openzeppelin/contracts/utils/math/[email protected]





// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]



// solhint-disable-next-line compiler-version


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]





/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]






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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]





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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]





/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
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
            uint256 mid = MathUpgradeable.average(low, high);

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]





/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]





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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]





/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/ERC20UpgradeableCustom.sol








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
contract ERC20UpgradeableCustom is
  Initializable,
  ContextUpgradeable,
  IERC20Upgradeable,
  IERC20MetadataUpgradeable
{
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The defaut value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
    __Context_init_unchained();
    __ERC20_init_unchained(name_, symbol_);
  }

  function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
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
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
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

  function approveTransferFrom(address sender, uint256 amount) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');

    _approve(sender, _msgSender(), amount);
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

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
    _approve(sender, _msgSender(), currentAllowance - amount);

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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

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
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
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
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
    _balances[account] = accountBalance - amount;
    _totalSupply -= amount;

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
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
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

  uint256[45] private __gap;
}


// File contracts/ERC20SnapshotUpgradeableCustom.sol







/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20SnapshotUpgradeableCustom is Initializable, ERC20UpgradeableCustom {
  function __ERC20Snapshot_init() internal initializer {
    __Context_init_unchained();
    __ERC20Snapshot_init_unchained();
  }

  function __ERC20Snapshot_init_unchained() internal initializer {}

  // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
  // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

  using ArraysUpgradeable for uint256[];
  using CountersUpgradeable for CountersUpgradeable.Counter;

  // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
  // Snapshot struct, but that would impede usage of functions that work on an array.
  struct Snapshots {
    uint256[] ids;
    uint256[] values;
  }

  mapping(address => Snapshots) private _accountBalanceSnapshots;
  Snapshots private _totalSupplySnapshots;

  // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
  CountersUpgradeable.Counter private _currentSnapshotId;

  /**
   * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
   */
  event Snapshot(uint256 id);

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
  function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
    (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

    return snapshotted ? value : totalSupply();
  }

  // Update balance and/or total supply snapshots before the values are modified. This is implemented
  // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
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
    private
    view
    returns (bool, uint256)
  {
    require(snapshotId > 0, 'ERC20Snapshot: id is 0');
    // solhint-disable-next-line max-line-length
    require(snapshotId <= _currentSnapshotId.current(), 'ERC20Snapshot: nonexistent id');

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

  uint256[46] private __gap;
}


// File contracts/CakeMonsterV7.sol



// import 'hardhat/console.sol';




interface ISwapRouter {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function WETH() external pure returns (address);

  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
}

interface ISwapFactory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ISwapPair {
  function sync() external;
}

interface ICakeMonsterReserve {
  function buyReserveAsset(uint256 amount) external returns (bool);

  function buyReserveAsset2(uint256 amount, bool collectStakingRewards) external returns (bool);

  function unstakeReserveAsset(uint256 amount) external;

  function unstakeAllReserveAsset() external;

  function addLiquidity(uint256 amount) external returns (bool);

  function resetLiquidity() external returns (bool);

  function removeLiquidity() external returns (bool);

  function transferAsset(uint256 amount, address to) external returns (bool);

  function reserveAssetBalance() external returns (uint256);
}

interface CakeMonster_DC_NFT {
  function hasLevelQualified(address account, uint256 level) external view returns (bool);

  function canDoCashout(address account) external view returns (bool allow, string memory reason);

  function registerCashout(address account) external;
}

contract CakeMonsterV7 is ERC20SnapshotUpgradeableCustom, OwnableUpgradeable {
  address public RESERVE;
  address public ASSET;
  address public SWAP_ROUTER;
  address public SWAP_FACTORY;

  bool public enabled;
  bool public finished;

  uint256 public startTime;
  uint256 public finishTime;
  uint256 public lastActivityTime;
  uint256 public initialSupply;
  uint256 public minSupply;
  uint256 public baseSupplySnapshot;
  uint256 public assetSupplySnapshot;
  uint256 public reserveManagersIndex;
  uint256 public nextInterimClaimThreshold;
  uint256 public interimSnapshotId;
  uint256 public endSnapshotId;
  uint256 public interimAssetSupplySnapshot;
  uint256 public interimAssetAmountSnapshot;
  uint256 public nTrades;

  mapping(address => uint256) public last5pctMove;
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public interimClaims;
  mapping(address => uint256) public endClaims;

  address[10] public reserveManagers;

  uint256 public constant burnRate = 250; // 2.5%
  uint256 public constant reserveRate = 250; // 2.5%
  uint256 public constant reserveThreshold = 1; // 0.01%
  uint256 public constant forcedSellIncentive = 500; // 5%
  uint256 public constant manageReserveIncentive = 100; // 1%
  uint256 public constant interimClaimPct = 100; // 1%

  event ManageReserve(address indexed sender);
  event ClaimInterim(address indexed sender);
  event ForceSell(address indexed sender, address indexed target);
  event Finish(address indexed sender);
  event Claim(address indexed sender);
  event BigReset(address indexed sender);

  // V4
  uint256 public canManageTime;
  address public DC_NFT;

  // V6
  uint256 public cashoutRewardPct;
  uint256 public cashoutAmountPct;
  uint256 public cashoutVaultPct;
  uint256 public kitchenRewardPct;

  function initialize(
    address _RESERVE,
    address _ASSET,
    address _SWAP_ROUTER,
    address _SWAP_FACTORY
  ) external initializer {
    __ERC20_init('Cake Monster', 'MONSTA');
    __Ownable_init();
    __ERC20Snapshot_init();

    ASSET = _ASSET;
    RESERVE = _RESERVE;
    SWAP_ROUTER = _SWAP_ROUTER;
    SWAP_FACTORY = _SWAP_FACTORY;

    startTime = block.timestamp;
    lastActivityTime = block.timestamp;
    finishTime = 0;

    initialSupply = 10000000000 * 10**decimals();
    minSupply = 1000000 * 10**decimals();

    enabled = false;
    finished = false;

    baseSupplySnapshot = 0;
    assetSupplySnapshot = 0;
    reserveManagersIndex = 0;

    interimSnapshotId = 0;
    endSnapshotId = 0;
    interimAssetSupplySnapshot = 0;
    interimAssetAmountSnapshot = 0;
    nTrades = 0;

    // V4
    canManageTime = 0;

    // V6
    cashoutRewardPct = 250; // 2.5%
    cashoutAmountPct = 7000; // 70.0%
    cashoutVaultPct = 2000; // 20.0%
    kitchenRewardPct = 200; // 2%

    nextInterimClaimThreshold = _pct(10000 - interimClaimPct, initialSupply);

    setWhitelist(owner(), true);
    setWhitelist(_RESERVE, true);
    setWhitelist(_SWAP_ROUTER, true);

    _mint(owner(), initialSupply);
  }

  /** PUBLIC FUNCTIONS **/

  function monsterStart() public onlyOwner {
    enabled = true;
  }

  function updatePct() public onlyOwner {
    cashoutRewardPct = 250; // 2.5%
    cashoutAmountPct = 7000; // 70.0%
    cashoutVaultPct = 2000; // 20.0%
    kitchenRewardPct = 200; // 2%
  }

  function setWhitelist(address addy, bool add) public onlyOwner {
    whitelist[addy] = add;
  }

  function setMoveTime(address[] memory addys, uint256[] memory times) public onlyOwner {
    for (uint256 i = 0; i < addys.length; i++) {
      last5pctMove[addys[i]] = times[i];
    }
  }

  function setDcNft(address addy) public onlyOwner {
    DC_NFT = addy;
  }

  function createSnapshot() external onlyOwner returns (uint256) {
    return _snapshot();
  }

  function burn(uint256 amount) external {
    _burn(_msgSender(), amount);
  }

  function resetLastActivity() external {
    require(!finished, 'FINISHED');

    uint256 balance = balanceOf(_msgSender());

    _transferHelper(_msgSender(), _msgSender(), _pct(501, balance));
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transferHelper(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transferHelper(sender, recipient, amount);
    approveTransferFrom(sender, amount);
    return true;
  }

  function forcedSell(address target) external {
    require(!finished, 'FINISHED');
    require(!_isWhitelisted(target), 'TARGET_WHITELISTED');
    require(block.timestamp - last5pctMove[target] > 4320000, '5PCT_MOVE_MADE');

    uint256 balance = balanceOf(target);

    require(balance > 0, 'WALLET_EMPTY');

    (bool allow, string memory reason) = CakeMonster_DC_NFT(DC_NFT).canDoCashout(_msgSender());

    require(allow, reason);

    // incentive executioner
    uint256 incentive = _pct(cashoutRewardPct, balance);
    _mint(_msgSender(), incentive);
    _check5pctMove(_msgSender(), incentive);

    // burn all target holdings
    _burn(target, balance);

    // If amount is too small then just burn, because a swap is not possible
    if (_getEthOutputAmount(address(this), balance) == 0) {
      return;
    }

    // Calc amounts for swaps
    uint256 sellAmountCashout = _pct(cashoutAmountPct, balance);
    uint256 sellAmountVault = _pct(cashoutVaultPct, balance);

    _mint(address(this), sellAmountCashout);

    uint256 lpBalanceBefore = balanceOf(_getLP());

    // Sell to target
    _swapToEth(address(this), sellAmountCashout, target);

    // Buy $CAKE for vault
    _mint(RESERVE, sellAmountVault);

    ICakeMonsterReserve(RESERVE).buyReserveAsset2(sellAmountVault, false);

    uint256 lpBalanceAfter = balanceOf(_getLP());

    _burn(_getLP(), SafeMath.sub(lpBalanceAfter, lpBalanceBefore));

    _sync();

    last5pctMove[target] = block.timestamp;

    CakeMonster_DC_NFT(DC_NFT).registerCashout(_msgSender());

    emit ForceSell(_msgSender(), target);
  }

  function manageReserve() external {
    require(!finished, 'FINISHED');

    checkCanManage();

    require(canManageTime > 0, 'TEMP_RESERVE_LOW');

    uint256 reserveBalance = balanceOf(RESERVE);

    require(!_isInReserveManagersList(_msgSender()), 'IN_MANAGE_RES_LIST');

    uint256 timeDiff = block.timestamp - canManageTime;

    if (timeDiff < 600) {
      uint256 minLevel = 0;
      uint256 minBalancePct = 0;
      if (timeDiff < 120) {
        minLevel = 5;
        minBalancePct = 1000;
      } else if (timeDiff < 240) {
        minLevel = 4;
        minBalancePct = 750;
      } else if (timeDiff < 360) {
        minLevel = 3;
        minBalancePct = 500;
      } else if (timeDiff < 480) {
        minLevel = 2;
        minBalancePct = 250;
      } else {
        minLevel = 1;
        minBalancePct = 125;
      }

      require(
        CakeMonster_DC_NFT(DC_NFT).hasLevelQualified(_msgSender(), minLevel),
        'NFT_LEVEL_TOO_LOW'
      );

      require(
        balanceOf(_msgSender()) >= SafeMath.div(_pct(minBalancePct, totalSupply()), 1000),
        'NFT_INSUFFICIENT_BALANCE'
      );
    }

    _addReserveManager(_msgSender());

    lastActivityTime = block.timestamp;

    // give caller an incentive
    uint256 incentive = _pct(kitchenRewardPct, reserveBalance);

    _transferHelper(RESERVE, _msgSender(), incentive);

    // Add 10% of temp reserve to liquidity (locked in contract)
    ICakeMonsterReserve(RESERVE).addLiquidity(_pct(1000, reserveBalance));

    reserveBalance = balanceOf(RESERVE);

    // Convert remaining 90% of temp reserve to the reserve asset
    ICakeMonsterReserve(RESERVE).buyReserveAsset2(reserveBalance, true);

    // If totalsupply < interim claim threshold
    if (totalSupply() < nextInterimClaimThreshold) {
      nextInterimClaimThreshold = _pct(10000 - interimClaimPct, totalSupply());

      uint256 currentAssetSupply = ICakeMonsterReserve(RESERVE).reserveAssetBalance();

      // Skip crumbs if amount is too low
      if (currentAssetSupply > SafeMath.add(interimAssetSupplySnapshot, 100000)) {
        interimAssetAmountSnapshot = _pct(
          2500,
          SafeMath.sub(currentAssetSupply, interimAssetSupplySnapshot)
        );
        interimAssetSupplySnapshot = currentAssetSupply;

        interimSnapshotId = _snapshot();
      }
    }

    canManageTime = 0;

    emit ManageReserve(_msgSender());
  }

  function finish() external {
    require(!finished, 'ALREADY_FINISHED');

    bool maxLifetimePassed = block.timestamp - startTime > 63072000;
    bool inactiveReserveManaging = block.timestamp - lastActivityTime > 10713600;

    if (!maxLifetimePassed && !inactiveReserveManaging) {
      require(totalSupply() <= minSupply, 'SUPPLY_HIGH');
    }

    finished = true;
    finishTime = block.timestamp;

    // Remove liquidity
    ICakeMonsterReserve(RESERVE).removeLiquidity();

    // Burn any left-over tokens
    _burn(RESERVE, balanceOf(RESERVE));

    // Unstake any CAKE
    ICakeMonsterReserve(RESERVE).unstakeAllReserveAsset();

    baseSupplySnapshot = totalSupply();
    assetSupplySnapshot = IERC20(ASSET).balanceOf(RESERVE);

    endSnapshotId = _snapshot();

    emit Finish(_msgSender());
  }

  function claim() external {
    require(finished, 'NOT_FINISHED');
    require(endSnapshotId > 0, 'NO_CLAIM');
    require(endClaims[_msgSender()] < endSnapshotId, 'ALREADY_CLAIMED');

    uint256 callerBalance = balanceOfAt(_msgSender(), endSnapshotId);

    require(callerBalance > 0, 'NO_CLAIM_WALLET_EMPTY');

    uint256 baseSharePct = SafeMath.div(callerBalance * 10**decimals(), baseSupplySnapshot);
    uint256 assetShareAmount = SafeMath.div(
      SafeMath.mul(assetSupplySnapshot, baseSharePct),
      10**decimals()
    );

    endClaims[_msgSender()] = endSnapshotId;

    // First burn current holdings to zero
    _burn(_msgSender(), balanceOf(_msgSender()));

    // Mint based on new supply
    _mint(_msgSender(), SafeMath.div(SafeMath.mul(initialSupply, baseSharePct), 10**decimals()));

    // Reset last 5pct move time
    last5pctMove[_msgSender()] = finishTime + 3024000;

    ICakeMonsterReserve(RESERVE).transferAsset(assetShareAmount, _msgSender());

    emit Claim(_msgSender());
  }

  function claimInterim() external {
    require(!finished, 'FINISHED');
    require(!_isWhitelisted(_msgSender()), 'WHITELISTED');
    require(interimSnapshotId > 0, 'NO_CLAIM');
    require(interimClaims[_msgSender()] < interimSnapshotId, 'ALREADY_CLAIMED');

    uint256 callerBalance = balanceOfAt(_msgSender(), interimSnapshotId);

    require(callerBalance > 0, 'EMPTY_WALLET_SNAPSHOT');

    uint256 baseSharePct = SafeMath.div(
      callerBalance * 10**decimals(),
      totalSupplyAt(interimSnapshotId) - balanceOfAt(owner(), interimSnapshotId)
    );
    uint256 assetShareAmount = SafeMath.div(
      SafeMath.mul(interimAssetAmountSnapshot, baseSharePct),
      10**decimals()
    );

    interimClaims[_msgSender()] = interimSnapshotId;

    ICakeMonsterReserve(RESERVE).unstakeReserveAsset(assetShareAmount);
    ICakeMonsterReserve(RESERVE).transferAsset(assetShareAmount, _msgSender());

    emit ClaimInterim(_msgSender());
  }

  function bigReset() external {
    require(finished, 'NOT_FINISHED');
    require(block.timestamp - finishTime > 3024000, 'CLAIM_NOT_FINISHED');

    startTime = block.timestamp;
    finishTime = 0;
    finished = false;
    baseSupplySnapshot = 0;
    assetSupplySnapshot = 0;
    interimAssetAmountSnapshot = 0;
    interimAssetSupplySnapshot = 0;
    interimSnapshotId = 0;

    // Make sure resere has enough tokens for adding liquidity
    _mint(RESERVE, SafeMath.sub(initialSupply, totalSupply()));

    // Add liquidity with all bnb + tokens in reserve
    ICakeMonsterReserve(RESERVE).resetLiquidity();

    // Burn all remaining tokens in reserve (because adding liquidity uses not all)
    _burn(RESERVE, balanceOf(RESERVE));

    // Mint tokens in LP so total supply equals initial supply
    _mint(_getLP(), SafeMath.sub(initialSupply, totalSupply()));

    // Sync to adjust LP reserves to minted tokens
    _sync();

    interimSnapshotId = _snapshot();

    emit BigReset(_msgSender());
  }

  /** PRIVATE FUNCTIONS **/

  function _transferHelper(
    address sender,
    address recipient,
    uint256 amount
  ) private returns (bool) {
    require(amount <= balanceOf(sender), 'EXCEED_BALANCE');

    // Allow tokens burns while finished
    if (
      !((_isLP(sender) && recipient == SWAP_ROUTER) ||
        (_isLP(recipient) && sender == SWAP_ROUTER) ||
        recipient == RESERVE)
    ) {
      require(!finished, 'FINISHED_NO_TRADES');
    }

    uint256 burnAmount = _pct(burnRate, amount);
    uint256 reserveAmount = _pct(reserveRate, amount);

    _check5pctMove(sender, amount);
    _check5pctMove(recipient, amount);

    if (_isWhitelisted(sender) && !_isLP(sender)) {
      _transfer(sender, recipient, amount);

      checkCanManage();

      return true;
    }

    require(enabled, 'NOT_ENABLED');

    if (nTrades <= 200) {
      require(amount <= 10000000 * 10**decimals(), 'BUY_LIMIT');
    }

    // burn 2.5%
    _burn(sender, burnAmount);

    // transfer to temp reserve
    _transfer(sender, RESERVE, reserveAmount);

    // transfer excluding burn amount and reserve
    _transfer(sender, recipient, SafeMath.sub(amount, SafeMath.add(burnAmount, reserveAmount)));

    checkCanManage();

    nTrades += 1;

    return true;
  }

  function checkCanManage() private {
    if (canManageTime > 0) {
      return;
    }

    if (balanceOf(RESERVE) > _pct(reserveThreshold, totalSupply())) {
      canManageTime = block.timestamp;
    }
  }

  function _check5pctMove(address addy, uint256 amount) private {
    uint256 amount5pct = _pct(500, balanceOf(addy));

    if (last5pctMove[addy] == 0) {
      last5pctMove[addy] = block.timestamp;
    }

    if (amount >= amount5pct) {
      last5pctMove[addy] = block.timestamp;
    }
  }

  function _isWhitelisted(address addy) private view returns (bool) {
    if (whitelist[addy]) {
      return true;
    }

    if (_isLP(addy)) {
      return true;
    }

    return false;
  }

  function _isLP(address addy) private view returns (bool) {
    if (_getLP() == addy) {
      return true;
    }

    return false;
  }

  function _getLP() private view returns (address) {
    return ISwapFactory(SWAP_FACTORY).getPair(address(this), ISwapRouter(SWAP_ROUTER).WETH());
  }

  function _isInReserveManagersList(address addy) private view returns (bool) {
    if (addy == owner()) {
      return false;
    }

    for (uint256 i = 0; i < reserveManagers.length; i++) {
      if (reserveManagers[i] == addy) {
        return true;
      }
    }

    return false;
  }

  function _addReserveManager(address addy) private {
    reserveManagers[reserveManagersIndex] = addy;
    reserveManagersIndex++;

    if (reserveManagersIndex >= reserveManagers.length) {
      reserveManagersIndex = 0;
    }
  }

  function _pct(uint256 pct100, uint256 amount) private pure returns (uint256) {
    return SafeMath.div(SafeMath.mul(pct100, amount), 10000);
  }

  function _swapToEth(
    address _tokenIn,
    uint256 _amountIn,
    address _to
  ) private {
    IERC20(_tokenIn).approve(SWAP_ROUTER, _amountIn);

    address[] memory path = new address[](2);
    path[0] = _tokenIn;
    path[1] = ISwapRouter(SWAP_ROUTER).WETH();

    ISwapRouter(SWAP_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
      _amountIn,
      0,
      path,
      _to,
      block.timestamp
    );
  }

  function _getEthOutputAmount(address _tokenIn, uint256 _amountIn) private view returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = _tokenIn;
    path[1] = ISwapRouter(SWAP_ROUTER).WETH();

    uint256[] memory result = ISwapRouter(SWAP_ROUTER).getAmountsOut(_amountIn, path);

    return result[1];
  }

  function _sync() private {
    address pairAddress = ISwapFactory(SWAP_FACTORY).getPair(
      address(this),
      ISwapRouter(SWAP_ROUTER).WETH()
    );

    ISwapPair(pairAddress).sync();
  }
}