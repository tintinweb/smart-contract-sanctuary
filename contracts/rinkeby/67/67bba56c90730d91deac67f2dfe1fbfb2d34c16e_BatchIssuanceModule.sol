/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/GSN/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/math/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/math/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/interfaces/IController.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IController {
    function addCK(address _ckToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isCK(address _ckToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}


// File contracts/interfaces/ICKToken.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

/**
 * @title ICKToken
 * @author Cook Finance
 *
 * Interface for operating with CKTokens.
 */
interface ICKToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a CKToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a CKToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}


// File contracts/interfaces/IBasicIssuanceModule.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface IBasicIssuanceModule {
    function getRequiredComponentUnitsForIssue(
        ICKToken _ckToken,
        uint256 _quantity
    ) external returns(address[] memory, uint256[] memory);

    function issue(ICKToken _ckToken, uint256 _quantity, address _to) external;
}


// File contracts/interfaces/IIndexExchangeAdapter.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface IIndexExchangeAdapter {
    function getSpender() external view returns(address);

    /**
     * Returns calldata for executing trade on given adapter's exchange when using the GeneralIndexModule.
     *
     * @param  _sourceToken              Address of source token to be sold
     * @param  _destinationToken         Address of destination token to buy
     * @param  _destinationAddress       Address that assets should be transferred to
     * @param  _isSendTokenFixed         Boolean indicating if the send quantity is fixed, used to determine correct trade interface
     * @param  _sourceQuantity           Fixed/Max amount of source token to sell
     * @param  _destinationQuantity      Min/Fixed amount of destination tokens to receive
     * @param  _data                     Arbitrary bytes that can be used to store exchange specific parameters or logic
     *
     * @return address                   Target contract address
     * @return uint256                   Call value
     * @return bytes                     Trade calldata
     */
    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        bool _isSendTokenFixed,
        uint256 _sourceQuantity,
        uint256 _destinationQuantity,
        bytes memory _data
    )
        external
        view
        returns (address, uint256, bytes memory);
}


// File contracts/interfaces/IPriceOracle.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

/**
 * @title IPriceOracle
 * @author Cook Finance
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}


// File contracts/interfaces/external/IWETH.sol

/*
    Copyright 2018 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

/**
 * @title IWETH
 * @author Cook Finance
 *
 * Interface for Wrapped Ether. This interface allows for interaction for wrapped ether's deposit and withdrawal
 * functionality.
 */
interface IWETH is IERC20{
    function deposit()
        external
        payable;

    function withdraw(
        uint256 wad
    )
        external;
}


// File contracts/lib/AddressArrayUtils.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Cook Finance
 *
 * Utility functions to handle Address Arrays
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove     
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}


// File contracts/lib/ExplicitERC20.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;



/**
 * @title ExplicitERC20
 * @author Cook Finance
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
    using SafeMath for uint256;

    /**
     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     *
     * @param _token           ERC20 token to approve
     * @param _from            The account to transfer tokens from
     * @param _to              The account to transfer tokens to
     * @param _quantity        The quantity to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        internal
    {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
        }
    }
}


// File contracts/interfaces/IModule.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;


/**
 * @title IModule
 * @author Cook Finance
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a CKToken to notify that this module was removed from the CK token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}


// File contracts/protocol/lib/Invoke.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;


/**
 * @title Invoke
 * @author Cook Finance
 *
 * A collection of common utility functions for interacting with the CKToken's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the CKToken to set approvals of the ERC20 token to a spender.
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the CKToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        ICKToken _ckToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _ckToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the CKToken to transfer the ERC20 token to a recipient.
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        ICKToken _ckToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _ckToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the CKToken to transfer the ERC20 token to a recipient.
     * The new CKToken balance must equal the existing balance less the quantity transferred
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        ICKToken _ckToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the CKToken
            uint256 existingBalance = IERC20(_token).balanceOf(address(_ckToken));

            Invoke.invokeTransfer(_ckToken, _token, _to, _quantity);

            // Get new balance of transferred token for CKToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_ckToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the CKToken to unwrap the passed quantity of WETH
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(ICKToken _ckToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _ckToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the CKToken to wrap the passed quantity of ETH
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(ICKToken _ckToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _ckToken.invoke(_weth, _quantity, callData);
    }
}


// File @openzeppelin/contracts/math/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}


// File contracts/lib/PreciseUnitMath.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;


/**
 * @title PreciseUnitMath
 * @author Cook Finance
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
    }
}


// File contracts/protocol/lib/Position.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;





/**
 * @title Position
 * @author Cook Finance
 *
 * Collection of helper functions for handling and updating CKToken Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the CKToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(ICKToken _ckToken, address _component) internal view returns(bool) {
        return _ckToken.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the CKToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(ICKToken _ckToken, address _component) internal view returns(bool) {
        return _ckToken.getExternalPositionModules(_component).length > 0;
    }
    
    /**
     * Returns whether the CKToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(ICKToken _ckToken, address _component, uint256 _unit) internal view returns(bool) {
        return _ckToken.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
    }

    /**
     * Returns whether the CKToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        ICKToken _ckToken,
        address _component,
        address _positionModule,
        uint256 _unit
    )
        internal
        view
        returns(bool)
    {
       return _ckToken.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();    
    }

    /**
     * If the position does not exist, create a new Position and add to the CKToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of 
     * components where needed (in light of potential external positions).
     *
     * @param _ckToken           Address of CKToken being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(ICKToken _ckToken, address _component, uint256 _newUnit) internal {
        bool isPositionFound = hasDefaultPosition(_ckToken, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_ckToken, _component)) {
                _ckToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_ckToken, _component)) {
                _ckToken.removeComponent(_component);
            }
        }

        _ckToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position. 
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _ckToken         CKToken being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        ICKToken _ckToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        if (_newUnit != 0) {
            if (!_ckToken.isComponent(_component)) {
                _ckToken.addComponent(_component);
                _ckToken.addExternalPositionModule(_component, _module);
            } else if (!_ckToken.isExternalPositionModule(_component, _module)) {
                _ckToken.addExternalPositionModule(_component, _module);
            }
            _ckToken.editExternalPositionUnit(_component, _module, _newUnit);
            _ckToken.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (_ckToken.getExternalPositionRealUnit(_component, _module) != 0) {
                address[] memory positionModules = _ckToken.getExternalPositionModules(_component);
                if (_ckToken.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == _module, "External positions must be 0 to remove component");
                    _ckToken.removeComponent(_component);
                }
                _ckToken.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _ckTokenSupply     Supply of CKToken in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 _ckTokenSupply, uint256 _positionUnit) internal pure returns (uint256) {
        return _ckTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _ckTokenSupply     Supply of CKToken in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(uint256 _ckTokenSupply, uint256 _totalNotional) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_ckTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _ckToken           Address of the CKToken
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(ICKToken _ckToken, address _component) internal view returns(uint256) {
        int256 positionUnit = _ckToken.getDefaultPositionRealUnit(_component); 
        return _ckToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _ckToken                 Address of the CKToken
     * @param _component                Address of the component
     * @param _ckTotalSupply           Current CKToken supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        ICKToken _ckToken,
        address _component,
        uint256 _ckTotalSupply,
        uint256 _componentPreviousBalance
    )
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 currentBalance = IERC20(_component).balanceOf(address(_ckToken));
        uint256 positionUnit = _ckToken.getDefaultPositionRealUnit(_component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _ckTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(_ckToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes CKToken state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _ckTokenSupply     Supply of CKToken in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of CKToken prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _ckTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    )
        internal
        pure
        returns (uint256)
    {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional.sub(_prePositionUnit.preciseMul(_ckTokenSupply));
        return _postTotalNotional.sub(airdroppedAmount).preciseDiv(_ckTokenSupply);
    }
}


// File contracts/interfaces/IIntegrationRegistry.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
}


// File contracts/interfaces/ICKValuer.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface ICKValuer {
    function calculateCKTokenValuation(ICKToken _ckToken, address _quoteAsset) external view returns (uint256);
}


// File contracts/protocol/lib/ResourceIdentifier.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;




/**
 * @title ResourceIdentifier
 * @author Cook Finance
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // CKValuer resource will always be resource ID 2 in the system
    uint256 constant internal CK_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of CK valuer on Controller. Note: CKValuer is stored as index 2 on the Controller
     */
    function getCKValuer(IController _controller) internal view returns (ICKValuer) {
        return ICKValuer(_controller.resourceId(CK_VALUER_RESOURCE_ID));
    }
}


// File contracts/protocol/lib/ModuleBase.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;












/**
 * @title ModuleBase
 * @author Cook Finance
 *
 * Abstract class that houses common Module-related state and functions.
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for ICKToken;
    using Position for ICKToken;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidCK(ICKToken _ckToken) { 
        _validateOnlyManagerAndValidCK(_ckToken);
        _;
    }

    modifier onlyCKManager(ICKToken _ckToken, address _caller) {
        _validateOnlyCKManager(_ckToken, _caller);
        _;
    }

    modifier onlyValidAndInitializedCK(ICKToken _ckToken) {
        _validateOnlyValidAndInitializedCK(_ckToken);
        _;
    }

    /**
     * Throws if the sender is not a CKToken's module or module not enabled
     */
    modifier onlyModule(ICKToken _ckToken) {
        _validateOnlyModule(_ckToken);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the CKToken is valid
     */
    modifier onlyValidAndPendingCK(ICKToken _ckToken) {
        _validateOnlyValidAndPendingCK(_ckToken);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) { 
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) { 
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter"); 
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _ckToken denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromCKToken(ICKToken _ckToken, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _ckToken.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity); 
        }
    }

    /**
     * Returns true if the module is in process of initialization on the CKToken
     */
    function isCKPendingInitialization(ICKToken _ckToken) internal view returns(bool) {
        return _ckToken.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the CKToken's manager
     */
    function isCKManager(ICKToken _ckToken, address _toCheck) internal view returns(bool) {
        return _ckToken.manager() == _toCheck;
    }

    /**
     * Returns true if CKToken must be enabled on the controller 
     * and module is registered on the CKToken
     */
    function isCKValidAndInitialized(ICKToken _ckToken) internal view returns(bool) {
        return controller.isCK(address(_ckToken)) &&
            _ckToken.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must CKToken manager and CKToken must be valid and initialized
     */
    function _validateOnlyManagerAndValidCK(ICKToken _ckToken) internal view {
       require(isCKManager(_ckToken, msg.sender), "Must be the CKToken manager");
       require(isCKValidAndInitialized(_ckToken), "Must be a valid and initialized CKToken");
    }

    /**
     * Caller must CKToken manager
     */
    function _validateOnlyCKManager(ICKToken _ckToken, address _caller) internal view {
        require(isCKManager(_ckToken, _caller), "Must be the CKToken manager");
    }

    /**
     * CKToken must be valid and initialized
     */
    function _validateOnlyValidAndInitializedCK(ICKToken _ckToken) internal view {
        require(isCKValidAndInitialized(_ckToken), "Must be a valid and initialized CKToken");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(ICKToken _ckToken) internal view {
        require(
            _ckToken.moduleStates(msg.sender) == ICKToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * CKToken must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingCK(ICKToken _ckToken) internal view {
        require(controller.isCK(address(_ckToken)), "Must be controller-enabled CKToken");
        require(isCKPendingInitialization(_ckToken), "Must be pending initialization");
    }
}


// File contracts/protocol/modules/BatchIssuanceModule.sol

/*
    Copyright 2021 Cook Finance.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;















/**
 * @title BatchIssuanceModule
 * @author Cook Finance
 *
 * Module that enables batch issuance and redemption functionality on a CKToken, for the purpose of gas saving.
 * This is a module that is required to bring the totalSupply of a CK above 0.
 */
contract BatchIssuanceModule is ModuleBase, ReentrancyGuard {
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;
    using Math for uint256;
    using SafeCast for int256;
    using SafeERC20 for IWETH;
    using SafeERC20 for IERC20;
    using Address for address;

    /* ============ Events ============ */

    event CKTokenBatchIssued(
        ICKToken indexed _ckToken,
        uint256 _inputUsed,
        uint256 _outputCK,
        uint256 _numberOfRounds
    );
    event ManagerFeeEdited(ICKToken indexed _ckToken, uint256 _newManagerFee, uint256 _index);
    event FeeRecipientEdited(ICKToken indexed _ckToken, address _feeRecipient);
    event AssetExchangeUpdated(ICKToken indexed _ckToken, address _component, string _newExchangeName);
    event DepositAllowanceUpdated(ICKToken indexed _ckToken, bool _allowDeposit);
    event RoundInputCapsUpdated(ICKToken indexed _ckToken, uint256 roundInputCap);
    event Deposit(address indexed _to, uint256 _amount);
    event WithdrawCKToken(
        ICKToken indexed _ckToken,
        address indexed _from,
        address indexed _to,
        uint256 _inputAmount,
        uint256 _outputAmount
    );

    /* ============ Structs ============ */

    struct BatchIssuanceSetting {
        address feeRecipient;                       // Manager fee recipient
        uint256[2] managerFees;                     // Manager fees. 0 index is issue and 1 index is redeem fee (0.01% = 1e14, 1% = 1e16)
        uint256 maxManagerFee;                      // Maximum fee manager is allowed to set for issue and redeem
        uint256 minCKTokenSupply;                   // Minimum CKToken supply required for issuance and redemption 
                                                    // to prevent dramatic inflationary changes to the CKToken's position multiplier
        bool allowDeposit;                          // to pause users from depositting into batchIssuance module
    }

    struct ActionInfo {
        uint256 preFeeReserveQuantity;              // Reserve value before fees; During issuance, represents raw quantity
        uint256 totalFeePercentage;                 // Total protocol fees (direct + manager revenue share)
        uint256 protocolFees;                       // Total protocol fees (direct + manager revenue share)
        uint256 managerFee;                         // Total manager fee paid in reserve asset
        uint256 netFlowQuantity;                    // When issuing, quantity of reserve asset sent to CKToken
        uint256 ckTokenQuantity;                    // When issuing, quantity of CKTokens minted to mintee
        uint256 previousCKTokenSupply;              // CKToken supply prior to issue/redeem action
        uint256 newCKTokenSupply;                   // CKToken supply after issue/redeem action
    }

    struct TradeExecutionParams {
        string exchangeName;                        // Exchange adapter name
        bytes exchangeData;                         // Arbitrary data that can be used to encode exchange specific 
                                                    // settings (fee tier) or features (multi-hop)
    }

    struct TradeInfo {
        IIndexExchangeAdapter exchangeAdapter;      // Instance of Exchange Adapter
        address receiveToken;                       // Address of token being bought
        uint256 sendQuantityMax;                    // Max amount of tokens to sent to the exchange
        uint256 receiveQuantity;                    // Amount of tokens receiving
        bytes exchangeData;                         // Arbitrary data for executing trade on given exchange
    }

    struct Round {
        uint256 totalDeposited;                     // Total WETH deposited in a round
        mapping(address => uint256) deposits;       // Mapping address to uint256, shows which address deposited how much WETH
        uint256 totalBakedInput;                    // Total WETH used for issuance in a round
        uint256 totalOutput;                        // Total CK amount issued in a round
    }

    /* ============ Constants ============ */

    // 0 index stores the manager fee in managerFees array, percentage charged on issue (denominated in reserve asset)
    uint256 constant internal MANAGER_ISSUE_FEE_INDEX = 0;
    // 0 index stores the manager revenue share protocol fee % on the controller, charged in the issuance function
    uint256 constant internal PROTOCOL_ISSUE_MANAGER_REVENUE_SHARE_FEE_INDEX = 0;
    // 2 index stores the direct protocol fee % on the controller, charged in the issuance function
    uint256 constant internal PROTOCOL_ISSUE_DIRECT_FEE_INDEX = 2;

    /* ============ State Variables ============ */

    IWETH public immutable weth;                        // Wrapped ETH address
    IBasicIssuanceModule public basicIssuanceModule;    // Basic Issuance Module
    // Mapping of CKToken to Batch issuance setting
    mapping(ICKToken => BatchIssuanceSetting) private batchIssuanceSettings;
    // Mapping of CKToken to (component to execution params)
    mapping(ICKToken => mapping(IERC20 => TradeExecutionParams)) private tradeExecutionInfo;
    // Mapping of CKToken to Input amount size per round
    mapping(ICKToken => uint256) private roundInputCaps;
    // Mapping of CKToken to Array of rounds
    mapping(ICKToken => Round[]) private rounds;
    // Mapping of CKToken to User round, a user can have multiple rounds
    mapping(ICKToken => mapping(address => uint256[])) private userRounds;

    /* ============ Constructor ============ */

    /**
     * Set state controller state variable
     *
     * @param _controller           Address of controller contract
     * @param _weth                 Address of WETH
     * @param _basicIssuanceModule  Instance of the basic issuance module
     */
    constructor(
        IController _controller,
        IWETH _weth,
        IBasicIssuanceModule _basicIssuanceModule
    ) public ModuleBase(_controller) {
        weth = _weth;
        // set basic issuance module
        basicIssuanceModule = _basicIssuanceModule;
    }

    /* ============ External Functions ============ */

    /**
     * Initializes this module to the CKToken with issuance settings and round input cap(limit)
     *
     * @param _ckToken              Instance of the CKToken to issue
     * @param _batchIssuanceSetting BatchIssuanceSetting struct define parameters
     * @param _roundInputCap        Maximum input amount per round
     */
    function initialize(
        ICKToken _ckToken,
        BatchIssuanceSetting memory _batchIssuanceSetting,
        uint256 _roundInputCap
    )
        external
        onlyCKManager(_ckToken, msg.sender)
        onlyValidAndPendingCK(_ckToken)
    {
        require(_ckToken.isInitializedModule(address(basicIssuanceModule)), "BasicIssuanceModule must be initialized");
        require(_batchIssuanceSetting.maxManagerFee < PreciseUnitMath.preciseUnit(), "Max manager fee must be less than 100%");
        require(_batchIssuanceSetting.managerFees[0] <= _batchIssuanceSetting.maxManagerFee, "Manager issue fee must be less than max");
        require(_batchIssuanceSetting.managerFees[1] <= _batchIssuanceSetting.maxManagerFee, "Manager redeem fee must be less than max");
        require(_batchIssuanceSetting.feeRecipient != address(0), "Fee Recipient must be non-zero address.");
        require(_batchIssuanceSetting.minCKTokenSupply > 0, "Min CKToken supply must be greater than 0");

        // create first empty round
        rounds[_ckToken].push();
        // set round input limit
        roundInputCaps[_ckToken] = _roundInputCap;

        // set batch issuance setting
        batchIssuanceSettings[_ckToken] = _batchIssuanceSetting;

        // initialize module for the CKToken
        _ckToken.initializeModule();
    }

    /**
     * CK MANAGER ONLY. Edit manager fee
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _managerFeePercentage         Manager fee percentage in 10e16 (e.g. 10e16 = 1%)
     * @param _managerFeeIndex              Manager fee index. 0 index is issue fee, 1 index is redeem fee
     */
    function editManagerFee(
        ICKToken _ckToken,
        uint256 _managerFeePercentage,
        uint256 _managerFeeIndex
    )
        external
        onlyManagerAndValidCK(_ckToken)
    {
        require(_managerFeePercentage <= batchIssuanceSettings[_ckToken].maxManagerFee, "Manager fee must be less than maximum allowed");
        
        batchIssuanceSettings[_ckToken].managerFees[_managerFeeIndex] = _managerFeePercentage;

        emit ManagerFeeEdited(_ckToken, _managerFeePercentage, _managerFeeIndex);
    }

    /**
     * CK MANAGER ONLY. Edit the manager fee recipient
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _managerFeeRecipient          Manager fee recipient
     */
    function editFeeRecipient(
        ICKToken _ckToken,
        address _managerFeeRecipient
    ) external onlyManagerAndValidCK(_ckToken) {
        require(_managerFeeRecipient != address(0), "Fee recipient must not be 0 address");
        
        batchIssuanceSettings[_ckToken].feeRecipient = _managerFeeRecipient;

        emit FeeRecipientEdited(_ckToken, _managerFeeRecipient);
    }

    function setDepositAllowance(ICKToken _ckToken, bool _allowDeposit) external onlyManagerAndValidCK(_ckToken) {
        batchIssuanceSettings[_ckToken].allowDeposit = _allowDeposit;
        emit DepositAllowanceUpdated(_ckToken, _allowDeposit);
    }

    function editRoundInputCaps(ICKToken _ckToken, uint256 _roundInputCap) external onlyManagerAndValidCK(_ckToken) {
        roundInputCaps[_ckToken] = _roundInputCap;
        emit RoundInputCapsUpdated(_ckToken, _roundInputCap);
    }

    /**
     * CK MANAGER ONLY: Set exchanges for underlying components of the CKToken. Can be called at anytime.
     *
     * @param _ckToken              Instance of the CKToken
     * @param _components           Array of components
     * @param _exchangeNames        Array of exchange names mapping to correct component
     */
    function setExchanges(
        ICKToken _ckToken,
        address[] memory _components,
        string[] memory _exchangeNames
    )
        external
        onlyManagerAndValidCK(_ckToken)
    {
        _components.validatePairsWithArray(_exchangeNames);

        for (uint256 i = 0; i < _components.length; i++) {
            if (_components[i] != address(weth)) {

                require(
                    controller.getIntegrationRegistry().isValidIntegration(address(this), _exchangeNames[i]),
                    "Unrecognized exchange name"
                );

                tradeExecutionInfo[_ckToken][IERC20(_components[i])].exchangeName = _exchangeNames[i];
                emit AssetExchangeUpdated(_ckToken, _components[i], _exchangeNames[i]);
            }
        }
    }

    /**
     * Mints the appropriate % of Net Asset Value of the CKToken from the deposited WETH in the rounds.
     * Fee(protocol fee + manager shared fee + manager fee in the module) will be used as slipage to trade on DEXs.
     * The exact amount protocol fee will be deliver to the protocol. Only remaining WETH will be paid to the manager as a fee.
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _rounds                       Array of round indexes
     */
    function batchIssue(
        ICKToken _ckToken, uint256[] memory _rounds
    ) 
        external
        nonReentrant
        onlyValidAndInitializedCK(_ckToken)
    {
        uint256 maxInputAmount;
        Round[] storage roundsPerCK = rounds[_ckToken];
        // Get max input amount
        for(uint256 i = 0; i < _rounds.length; i ++) {
        
            // Prevent round from being baked twice
            if(i != 0) {
                require(_rounds[i] > _rounds[i - 1], "Rounds out of order");
            }

            Round storage round = roundsPerCK[_rounds[i]];
            maxInputAmount = maxInputAmount.add(round.totalDeposited.sub(round.totalBakedInput));
        }

        require(maxInputAmount > 0, "Quantity must be > 0");

        ActionInfo memory issueInfo = _createIssuanceInfo(_ckToken, address(weth), maxInputAmount);
        _validateIssuanceInfo(_ckToken, issueInfo);

        uint256 inputUsed = 0;
        uint256 outputAmount = issueInfo.ckTokenQuantity;

        // To issue ckTokenQuantity amount of CKs, swap the required underlying components amount
        (
            address[] memory components,
            uint256[] memory componentQuantities
        ) = basicIssuanceModule.getRequiredComponentUnitsForIssue(_ckToken, outputAmount);
        for (uint256 i = 0; i < components.length; i++) {
            IERC20 component_ = IERC20(components[i]);
            uint256 quantity_ = componentQuantities[i];
            if (address(component_) != address(weth)) {
                TradeInfo memory tradeInfo = _createTradeInfo(
                    _ckToken,
                    IERC20(component_),
                    quantity_,
                    issueInfo.totalFeePercentage
                );
                uint256 usedAmountForTrade = _executeTrade(tradeInfo);
                inputUsed = inputUsed.add(usedAmountForTrade);
            } else {
                inputUsed = inputUsed.add(quantity_);
            }

            // approve every component for basic issuance module
            if (component_.allowance(address(this), address(basicIssuanceModule)) < quantity_) {
                component_.safeIncreaseAllowance(address(basicIssuanceModule), quantity_);
            }
        }

        // Mint the CKToken
        basicIssuanceModule.issue(_ckToken, outputAmount, address(this));

        uint256 inputUsedRemaining = maxInputAmount;

        for(uint256 i = 0; i < _rounds.length; i ++) {
            Round storage round = roundsPerCK[_rounds[i]];

            uint256 roundTotalBaked = round.totalBakedInput;
            uint256 roundTotalDeposited = round.totalDeposited;
            uint256 roundInputBaked = (roundTotalDeposited.sub(roundTotalBaked)).min(inputUsedRemaining);

            // Skip round if it is already baked
            if(roundInputBaked == 0) {
                continue;
            }

            uint256 roundOutputBaked = outputAmount.mul(roundInputBaked).div(maxInputAmount);

            round.totalBakedInput = roundTotalBaked.add(roundInputBaked);
            inputUsedRemaining = inputUsedRemaining.sub(roundInputBaked);
            round.totalOutput = round.totalOutput.add(roundOutputBaked);

            // Sanity check for round
            require(round.totalBakedInput <= round.totalDeposited, "Round input sanity check failed");
        }

        // Sanity check
        uint256 inputUsedWithProtocolFee = inputUsed.add(issueInfo.protocolFees);
        require(inputUsedWithProtocolFee <= maxInputAmount, "Max input sanity check failed");

        // turn remaining amount into manager fee
        issueInfo.managerFee = maxInputAmount.sub(inputUsedWithProtocolFee);
        _transferFees(_ckToken, issueInfo);

        emit CKTokenBatchIssued(_ckToken, maxInputAmount, outputAmount, _rounds.length);
    }

    /**
     * Wrap ETH and then deposit
     *
     * @param _ckToken                      Instance of the CKToken
     */
    function depositEth(ICKToken _ckToken) external payable {
        weth.deposit{ value: msg.value }();
        _depositTo(_ckToken, msg.value, msg.sender);
    }

    /**
     * Deposit WETH
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _amount                       Amount of WETH
     */
    function deposit(ICKToken _ckToken, uint256 _amount) external {
        weth.safeTransferFrom(msg.sender, address(this), _amount);
        _depositTo(_ckToken, _amount, msg.sender);
    }

    /**
     * Withdraw CKToken within the number of rounds limit
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _roundsLimit                  Number of rounds limit
     */
    function withdrawCKToken(ICKToken _ckToken, uint256 _roundsLimit) external onlyValidAndInitializedCK(_ckToken) {
        withdrawCKTokenTo(_ckToken, msg.sender, _roundsLimit);
    }

    /**
     * Withdraw CKToken within the number of rounds limit, to a specific address
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _to                           Address to withdraw to
     * @param _roundsLimit                  Number of rounds limit
     */
    function withdrawCKTokenTo(
        ICKToken _ckToken,
        address _to,
        uint256 _roundsLimit
    ) public nonReentrant onlyValidAndInitializedCK(_ckToken) {
        uint256 inputAmount;
        uint256 outputAmount;

        mapping(address => uint256[]) storage userRoundsPerCK = userRounds[_ckToken];
        Round[] storage roundsPerCK = rounds[_ckToken];
        uint256 userRoundsLength = userRoundsPerCK[msg.sender].length;
        uint256 numRounds = userRoundsLength.min(_roundsLimit);

        for(uint256 i = 0; i < numRounds; i ++) {
            // start at end of array for efficient popping of elements
            uint256 userRoundIndex = userRoundsLength.sub(i).sub(1);
            uint256 roundIndex = userRoundsPerCK[msg.sender][userRoundIndex];
            Round storage round = roundsPerCK[roundIndex];

            // amount of input of user baked
            uint256 bakedInput = round.deposits[msg.sender].mul(round.totalBakedInput).div(round.totalDeposited);

            // amount of output the user is entitled to
            uint256 userRoundOutput;
            if(bakedInput == 0) {
                userRoundOutput = 0;
            } else {
                userRoundOutput = round.totalOutput.mul(bakedInput).div(round.totalBakedInput);
            }
            // unbaked input
            uint256 unspentInput = round.deposits[msg.sender].sub(bakedInput);
            inputAmount = inputAmount.add(unspentInput);
            //amount of output the user is entitled to
            outputAmount = outputAmount.add(userRoundOutput);

            round.totalDeposited = round.totalDeposited.sub(round.deposits[msg.sender]);
            round.deposits[msg.sender] = 0;
            round.totalBakedInput = round.totalBakedInput.sub(bakedInput);

            round.totalOutput = round.totalOutput.sub(userRoundOutput);

            // pop of user round
            userRoundsPerCK[msg.sender].pop();
        }

        if(inputAmount != 0) {
            // handle rounding issues due to integer division inaccuracies
            inputAmount = inputAmount.min(weth.balanceOf(address(this)));
            weth.safeTransfer(_to, inputAmount);
        }
        
        if(outputAmount != 0) {
            // handle rounding issues due to integer division inaccuracies
            outputAmount = outputAmount.min(_ckToken.balanceOf(address(this)));
            _ckToken.transfer(_to, outputAmount);
        }

        emit WithdrawCKToken(_ckToken, msg.sender, _to, inputAmount, outputAmount);
    }

    /**
     * Removes this module from the CKToken, via call by the CKToken.
     */
    function removeModule() external override {
        ICKToken ckToken_ = ICKToken(msg.sender);

        // delete tradeExecutionInfo
        address[] memory components = ckToken_.getComponents();
        for (uint256 i = 0; i < components.length; i++) {
            delete tradeExecutionInfo[ckToken_][IERC20(components[i])];
        }

        delete batchIssuanceSettings[ckToken_];
        delete roundInputCaps[ckToken_];
        delete rounds[ckToken_];
        // delete userRounds[ckToken_];
    }

    /* ============ External Getter Functions ============ */

    /**
     * Get current round index
     *
     * @param _ckToken                      Instance of the CKToken
     */
    function getRoundInputCap(ICKToken _ckToken) public view returns(uint256) {
        return roundInputCaps[_ckToken];
    }

    /**
     * Get current round index
     *
     * @param _ckToken                      Instance of the CKToken
     */
    function getCurrentRound(ICKToken _ckToken) public view returns(uint256) {
        return rounds[_ckToken].length.sub(1);
    }

    /**
     * Get ETH amount deposited in current round
     *
     * @param _ckToken                      Instance of the CKToken
     */
    function getCurrentRoundDeposited(ICKToken _ckToken) public view returns(uint256) {
        uint256 currentRound = rounds[_ckToken].length.sub(1);
        return rounds[_ckToken][currentRound].totalDeposited;
    }

    /**
     * Get un-baked round indexes
     *
     * @param _ckToken                      Instance of the CKToken
     */
    function getRoundsToBake(ICKToken _ckToken, uint256 _start) external view returns(uint256[] memory) {
        uint256 count = 0;
        Round[] storage roundsPerCK = rounds[_ckToken];
        for(uint256 i = _start; i < roundsPerCK.length; i ++) {
            Round storage round = roundsPerCK[i];
            if (round.totalDeposited.sub(round.totalBakedInput) > 0) {
                count ++;
            }
        }
        uint256[] memory roundsToBake = new uint256[](count);
        uint256 focus = 0;
        for(uint256 i = _start; i < roundsPerCK.length; i ++) {
            Round storage round = roundsPerCK[i];
            if (round.totalDeposited.sub(round.totalBakedInput) > 0) {
                roundsToBake[focus] = i;
                focus ++;
            }
        }
        return roundsToBake;
    }

    /**
     * Get round input of an address(user)
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _round                        index of the round
     * @param _of                           address of the user
     */
    function roundInputBalanceOf(ICKToken _ckToken, uint256 _round, address _of) public view returns(uint256) {
        Round storage round = rounds[_ckToken][_round];
        // if there are zero deposits the input balance of `_of` would be zero too
        if(round.totalDeposited == 0) {
            return 0;
        }
        uint256 bakedInput = round.deposits[_of].mul(round.totalBakedInput).div(round.totalDeposited);
        return round.deposits[_of].sub(bakedInput);
    }

    /**
     * Get total input of an address(user)
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _of                           address of the user
     */
    function inputBalanceOf(ICKToken _ckToken, address _of) public view returns(uint256) {
        mapping(address => uint256[]) storage userRoundsPerCK = userRounds[_ckToken];
        uint256 roundsCount = userRoundsPerCK[_of].length;

        uint256 balance;

        for(uint256 i = 0; i < roundsCount; i ++) {
            balance = balance.add(roundInputBalanceOf(_ckToken, userRoundsPerCK[_of][i], _of));
        }

        return balance;
    }

    /**
     * Get round output of an address(user)
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _round                        index of the round
     * @param _of                           address of the user
     */
    function roundOutputBalanceOf(ICKToken _ckToken, uint256 _round, address _of) public view returns(uint256) {
        Round storage round = rounds[_ckToken][_round];

        if(round.totalBakedInput == 0) {
            return 0;
        }

        // amount of input of user baked
        uint256 bakedInput = round.deposits[_of].mul(round.totalBakedInput).div(round.totalDeposited);
        // amount of output the user is entitled to
        uint256 userRoundOutput = round.totalOutput.mul(bakedInput).div(round.totalBakedInput);

        return userRoundOutput;
    }

    /**
     * Get total output of an address(user)
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _of                           address of the user
     */
    function outputBalanceOf(ICKToken _ckToken, address _of) external view returns(uint256) {
        mapping(address => uint256[]) storage userRoundsPerCK = userRounds[_ckToken];
        uint256 roundsCount = userRoundsPerCK[_of].length;

        uint256 balance;

        for(uint256 i = 0; i < roundsCount; i ++) {
            balance = balance.add(roundOutputBalanceOf(_ckToken, userRoundsPerCK[_of][i], _of));
        }

        return balance;
    }

    /**
     * Get user's round count
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _user                         address of the user
     */
    function getUserRoundsCount(ICKToken _ckToken, address _user) external view returns(uint256) {
        return userRounds[_ckToken][_user].length;
    }

    /**
     * Get user round number
     * 
     * @param _ckToken                      Instance of the CKToken
     * @param _user                         address of the user
     * @param _index                        index in the round array
     */
    function getUserRound(ICKToken _ckToken, address _user, uint256 _index) external view returns(uint256) {
        return userRounds[_ckToken][_user][_index];
    }

    /**
     * Get total round count
     *
     * @param _ckToken                      Instance of the CKToken
     */
    function getRoundsCount(ICKToken _ckToken) external view returns(uint256) {
        return rounds[_ckToken].length;
    }

    /**
     * Get manager fee by index
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _managerFeeIndex              Manager fee index
     */
    function getManagerFee(ICKToken _ckToken, uint256 _managerFeeIndex) external view returns (uint256) {
        return batchIssuanceSettings[_ckToken].managerFees[_managerFeeIndex];
    }

    /**
     * Get batch issuance setting for a CK
     *
     * @param _ckToken                      Instance of the CKToken
     */
    function getBatchIssuanceSetting(ICKToken _ckToken) external view returns (BatchIssuanceSetting memory) {
        return batchIssuanceSettings[_ckToken];
    }

    /**
     * Get tradeExecutionParam for a component of a CK
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _component                    ERC20 instance of the component
     */
    function getTradeExecutionParam(
        ICKToken _ckToken,
        IERC20 _component
    ) external view returns (TradeExecutionParams memory) {
        return tradeExecutionInfo[_ckToken][_component];
    }

    /**
     * Get bake round for a CK
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _index                        index number of a round
     */
    function getRound(ICKToken _ckToken, uint256 _index) external view returns (uint256, uint256, uint256) {
        Round[] storage roundsPerCK = rounds[_ckToken];
        Round memory round = roundsPerCK[_index];
        return (round.totalDeposited, round.totalBakedInput, round.totalOutput);
    }

    /* ============ Internal Functions ============ */

    /**
     * Deposit by user by round
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _amount                       Amount of WETH
     * @param _to                           Address of depositor
     */
    function _depositTo(ICKToken _ckToken, uint256 _amount, address _to) internal {
        // if amount is zero return early
        if(_amount == 0) {
            return;
        }

        require(batchIssuanceSettings[_ckToken].allowDeposit, "not allowed to deposit");

        Round[] storage roundsPerCK = rounds[_ckToken];
        uint256 currentRound = getCurrentRound(_ckToken);
        uint256 deposited = 0;

        while(deposited < _amount) {
            //if the current round does not exist create it
            if(currentRound >= roundsPerCK.length) {
                roundsPerCK.push();
            }

            //if the round is already partially baked create a new round
            if(roundsPerCK[currentRound].totalBakedInput != 0) {
                currentRound = currentRound.add(1);
                roundsPerCK.push();
            }

            Round storage round = roundsPerCK[currentRound];

            uint256 roundDeposit = (_amount.sub(deposited)).min(roundInputCaps[_ckToken].sub(round.totalDeposited));

            round.totalDeposited = round.totalDeposited.add(roundDeposit);
            round.deposits[_to] = round.deposits[_to].add(roundDeposit);

            deposited = deposited.add(roundDeposit);

            // only push roundsPerCK we are actually in
            if(roundDeposit != 0) {
                _pushUserRound(_ckToken, _to, currentRound);
            }

            // if full amount assigned to roundsPerCK break the loop
            if(deposited == _amount) {
                break;
            }

            currentRound = currentRound.add(1);
        }

        emit Deposit(_to, _amount);
    }

    /**
     * Create and return TradeInfo struct. Send Token is WETH
     *
     * @param _ckToken              Instance of the CKToken
     * @param _component            IERC20 component to trade
     * @param _receiveQuantity      Amount of the component asset 
     * @param _slippage             Limitation percentage 
     *
     * @return tradeInfo            Struct containing data for trade
     */
    function _createTradeInfo(
        ICKToken _ckToken,
        IERC20 _component,
        uint256 _receiveQuantity,
        uint256 _slippage
    )
        internal
        view
        virtual
        returns (TradeInfo memory tradeInfo)
    {
        // set the exchange info
        tradeInfo.exchangeAdapter = IIndexExchangeAdapter(
            getAndValidateAdapter(tradeExecutionInfo[_ckToken][_component].exchangeName)
        );
        tradeInfo.exchangeData = tradeExecutionInfo[_ckToken][_component].exchangeData;

        // set receive token info
        tradeInfo.receiveToken = address(_component);
        tradeInfo.receiveQuantity = _receiveQuantity;

        // exactSendQuantity is calculated based on the price from the oracle, not the price from the proper exchange
        uint256 receiveTokenPrice = _calculateComponentPrice(address(_component), address(weth));
        uint256 wethDecimals = ERC20(address(weth)).decimals();
        uint256 componentDecimals = ERC20(address(_component)).decimals();
        uint256 exactSendQuantity = tradeInfo.receiveQuantity
                                        .preciseMul(receiveTokenPrice)
                                        .mul(10**wethDecimals)
                                        .div(10**componentDecimals);
        // set max send limit
        uint256 unit_ = 1e18;
        tradeInfo.sendQuantityMax = exactSendQuantity.mul(unit_).div(unit_.sub(_slippage));
    }

    /**
     * Function handles all interactions with exchange.
     *
     * @param _tradeInfo            Struct containing trade information used in internal functions
     */
    function _executeTrade(TradeInfo memory _tradeInfo) internal returns (uint256) {
        ERC20(address(weth)).approve(_tradeInfo.exchangeAdapter.getSpender(), _tradeInfo.sendQuantityMax);

        (
            address targetExchange,
            uint256 callValue,
            bytes memory methodData
        ) = _tradeInfo.exchangeAdapter.getTradeCalldata(
            address(weth),
            _tradeInfo.receiveToken,
            address(this),
            false,
            _tradeInfo.sendQuantityMax,
            _tradeInfo.receiveQuantity,
            _tradeInfo.exchangeData
        );

        uint256 preTradeReserveAmount = weth.balanceOf(address(this));
        targetExchange.functionCallWithValue(methodData, callValue);
        uint256 postTradeReserveAmount = weth.balanceOf(address(this));

        uint256 usedAmount = preTradeReserveAmount.sub(postTradeReserveAmount);
        return usedAmount;
    }

    /**
     * Validate issuance info used internally.
     *
     * @param _ckToken              Instance of the CKToken
     * @param _issueInfo            Struct containing inssuance information used in internal functions
     */
    function _validateIssuanceInfo(ICKToken _ckToken, ActionInfo memory _issueInfo) internal view {
        // Check that total supply is greater than min supply needed for issuance
        // Note: A min supply amount is needed to avoid division by 0 when CKToken supply is 0
        require(
            _issueInfo.previousCKTokenSupply >= batchIssuanceSettings[_ckToken].minCKTokenSupply,
            "Supply must be greater than minimum issuance"
        );
    }

    /**
     * Create and return ActionInfo struct.
     *
     * @param _ckToken                  Instance of the CKToken
     * @param _reserveAsset             Address of reserve asset
     * @param _reserveAssetQuantity     Amount of the reserve asset 
     *
     * @return issueInfo                Struct containing data for issuance
     */
    function _createIssuanceInfo(
        ICKToken _ckToken,
        address _reserveAsset,
        uint256 _reserveAssetQuantity
    )
        internal
        view
        returns (ActionInfo memory)
    {
        ActionInfo memory issueInfo;

        issueInfo.previousCKTokenSupply = _ckToken.totalSupply();

        issueInfo.preFeeReserveQuantity = _reserveAssetQuantity;

        (issueInfo.totalFeePercentage, issueInfo.protocolFees, issueInfo.managerFee) = _getFees(
            _ckToken,
            issueInfo.preFeeReserveQuantity,
            PROTOCOL_ISSUE_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_ISSUE_DIRECT_FEE_INDEX,
            MANAGER_ISSUE_FEE_INDEX
        );

        issueInfo.netFlowQuantity = issueInfo.preFeeReserveQuantity
                                        .sub(issueInfo.protocolFees)
                                        .sub(issueInfo.managerFee);

        issueInfo.ckTokenQuantity = _getCKTokenMintQuantity(
            _ckToken,
            _reserveAsset,
            issueInfo.netFlowQuantity
        );

        issueInfo.newCKTokenSupply = issueInfo.ckTokenQuantity.add(issueInfo.previousCKTokenSupply);

        return issueInfo;
    }

    /**
     * Calculate CKToken mint amount.
     *
     * @param _ckToken                  Instance of the CKToken
     * @param _reserveAsset             Address of reserve asset
     * @param _netReserveFlows          Value of reserve asset net of fees 
     *
     * @return uint256                  Amount of CKToken to mint
     */
    function _getCKTokenMintQuantity(
        ICKToken _ckToken,
        address _reserveAsset,
        uint256 _netReserveFlows
    )
        internal
        view
        returns (uint256)
    {

        // Get valuation of the CKToken with the quote asset as the reserve asset. Returns value in precise units (1e18)
        // Reverts if price is not found
        uint256 ckTokenValuation = controller.getCKValuer().calculateCKTokenValuation(_ckToken, _reserveAsset);

        // Get reserve asset decimals
        uint256 reserveAssetDecimals = ERC20(_reserveAsset).decimals();
        uint256 normalizedTotalReserveQuantityNetFees = _netReserveFlows.preciseDiv(10 ** reserveAssetDecimals);

        // Calculate CKTokens to mint to issuer
        return normalizedTotalReserveQuantityNetFees.preciseDiv(ckTokenValuation);
    }

    /**
     * Add new roundId to user's rounds array
     *
     * @param _ckToken                  Instance of the CKToken
     * @param _to                       Address of depositor
     * @param _roundId                  Round id to add in userRounds
     */
    function _pushUserRound(ICKToken _ckToken, address _to, uint256 _roundId) internal {
        // only push when its not already added
        mapping(address => uint256[]) storage userRoundsPerCK = userRounds[_ckToken];
        if(userRoundsPerCK[_to].length == 0 || userRoundsPerCK[_to][userRoundsPerCK[_to].length - 1] != _roundId) {
            userRoundsPerCK[_to].push(_roundId);
        }
    }

    /**
     * Returns the fees attributed to the manager and the protocol. The fees are calculated as follows:
     *
     * ManagerFee = (manager fee % - % to protocol) * reserveAssetQuantity, will be recalculated after trades
     * Protocol Fee = (% manager fee share + direct fee %) * reserveAssetQuantity
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _reserveAssetQuantity         Quantity of reserve asset to calculate fees from
     * @param _protocolManagerFeeIndex      Index to pull rev share batch Issuance fee from the Controller
     * @param _protocolDirectFeeIndex       Index to pull direct batch issuance fee from the Controller
     * @param _managerFeeIndex              Index from BatchIssuanceSettings (0 = issue fee, 1 = redeem fee)
     *
     * @return  uint256                     Total fee percentage
     * @return  uint256                     Fees paid to the protocol in reserve asset
     * @return  uint256                     Fees paid to the manager in reserve asset
     */
    function _getFees(
        ICKToken _ckToken,
        uint256 _reserveAssetQuantity,
        uint256 _protocolManagerFeeIndex,
        uint256 _protocolDirectFeeIndex,
        uint256 _managerFeeIndex
    )
        internal
        view
        returns (uint256, uint256, uint256)
    {
        (uint256 protocolFeePercentage, uint256 managerFeePercentage) = _getProtocolAndManagerFeePercentages(
            _ckToken,
            _protocolManagerFeeIndex,
            _protocolDirectFeeIndex,
            _managerFeeIndex
        );

        // total fee percentage
        uint256 totalFeePercentage = protocolFeePercentage.add(managerFeePercentage);

        // Calculate total notional fees
        uint256 protocolFees = protocolFeePercentage.preciseMul(_reserveAssetQuantity);
        uint256 managerFee = managerFeePercentage.preciseMul(_reserveAssetQuantity);

        return (totalFeePercentage, protocolFees, managerFee);
    }

    /**
     * Returns the fee percentages of the manager and the protocol.
     *
     * @param _ckToken                      Instance of the CKToken
     * @param _protocolManagerFeeIndex      Index to pull rev share Batch Issuance fee from the Controller
     * @param _protocolDirectFeeIndex       Index to pull direct Batc issuance fee from the Controller
     * @param _managerFeeIndex              Index from BatchIssuanceSettings (0 = issue fee, 1 = redeem fee)
     *
     * @return  uint256                     Fee percentage to the protocol in reserve asset
     * @return  uint256                     Fee percentage to the manager in reserve asset
     */
    function _getProtocolAndManagerFeePercentages(
        ICKToken _ckToken,
        uint256 _protocolManagerFeeIndex,
        uint256 _protocolDirectFeeIndex,
        uint256 _managerFeeIndex
    )
        internal
        view
        returns(uint256, uint256)
    {
        // Get protocol fee percentages
        uint256 protocolDirectFeePercent = controller.getModuleFee(address(this), _protocolDirectFeeIndex);
        uint256 protocolManagerShareFeePercent = controller.getModuleFee(address(this), _protocolManagerFeeIndex);
        uint256 managerFeePercent = batchIssuanceSettings[_ckToken].managerFees[_managerFeeIndex];
        
        // Calculate revenue share split percentage
        uint256 protocolRevenueSharePercentage = protocolManagerShareFeePercent.preciseMul(managerFeePercent);
        uint256 managerRevenueSharePercentage = managerFeePercent.sub(protocolRevenueSharePercentage);
        uint256 totalProtocolFeePercentage = protocolRevenueSharePercentage.add(protocolDirectFeePercent);

        return (totalProtocolFeePercentage, managerRevenueSharePercentage);
    }

    /**
     * Get the price of the component
     *
     * @param _component       Component to get the price for
     * @param _quoteAsset      Address of token to quote valuation in
     *
     * @return uint256         Component's price
     */
    function _calculateComponentPrice(address _component, address _quoteAsset) internal view returns (uint256) {
        IPriceOracle priceOracle = controller.getPriceOracle();
        address masterQuoteAsset = priceOracle.masterQuoteAsset();
        
        // Get component price from price oracle. If price does not exist, revert.
        uint256 componentPrice = priceOracle.getPrice(_component, masterQuoteAsset);
        if (masterQuoteAsset != _quoteAsset) {
            uint256 quoteToMaster = priceOracle.getPrice(_quoteAsset, masterQuoteAsset);
            componentPrice = componentPrice.preciseDiv(quoteToMaster);
        }

        return componentPrice;
    }

    /**
     * Transfer fees(WETH) from module to appropriate fee recipients
     *
     * @param _ckToken         Instance of the CKToken
     * @param _issueInfo       Issuance information, contains fee recipient address and fee amounts
     */
    function _transferFees(ICKToken _ckToken, ActionInfo memory _issueInfo) internal {
        if (_issueInfo.protocolFees > 0) {
            weth.safeTransfer(controller.feeRecipient(), _issueInfo.protocolFees);
        }

        if (_issueInfo.managerFee > 0) {
            weth.safeTransfer(batchIssuanceSettings[_ckToken].feeRecipient, _issueInfo.managerFee);
        }
    }
}