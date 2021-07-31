/**
 *Submitted for verification at polygonscan.com on 2021-07-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
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
     * - `account` cannot be the zero address.
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}



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
    constructor() {
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

    constructor() {
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
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IMintable is IERC20 {
    function mint(address _to, uint256 _amount) external;
}


interface IPolyMasterCorn {
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _maxDepositAmount,
        bool _canDeposit,
        address _strat,
        bool _stratDepositFee,
        bool _isLocked,
        bool _hasLockedReward,
        uint256 _toLockedPid,
        bool _withUpdate
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _maxDepositAmount,
        bool _canDeposit,
        address _strat,
        bool _stratDepositFee,
        bool _withUpdate
    ) external;

    function setCanDeposit(
        uint256 _pid,
        bool _canDeposit,
        bool _withUpdate
    ) external;

    function setLock(
        uint256 _pid,
        bool _isLocked,
        bool _hasFixedLockBaseFee,
        uint256 _lockBaseFee,
        uint256 _lockBaseTime,
        bool _withUpdate
    ) external;

    function setLockableReward(
        uint256 _pid,
        bool _hasLockedReward,
        uint256 _toLockedPid,
        uint256 _lockedRewardPercent,
        bool _withUpdate
    ) external;

    function massUpdatePools() external;

    function setLotteryAddress(address _lotteryAddress) external;
}


// For interacting with our own strategy
interface IStrategy {
    // Total want tokens managed by stratfegy
    function wantLockedTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens yetiFarm -> strategy
    function deposit(uint256 _wantAmt)
        external
        returns (uint256);

    // Transfer want tokens strategy -> yetiFarm
    function withdraw(uint256 _wantAmt)
        external
        returns (uint256);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function fetchDepositFee() external view returns (uint256);
}


contract PolyMasterCorn is Ownable, ReentrancyGuard, IPolyMasterCorn  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 lastDepositTime;
        uint256 startLockTime;
        uint256 endLockTime;
        //
        // We do some fancy math here. Basically, any point in time, the amount of YCorns
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSinkPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSinkPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;                        // Address of LP token contract.
        uint256 allocPoint;                    // How many allocation points assigned to this pool. YCorns to distribute per block.
        uint256 lastRewardBlock;               // Last block number that YCorns distribution occurs.
        uint256 accSinkPerShare;               // Accumulated YCorns per share, times 1e6. See below.
        uint256 maxDepositAmount;              // Maximum deposit quota (0 means no limit)
        bool canDeposit;                       // Can deposit in this pool
        uint256 currentDepositAmount;          // Current total deposit amount in this pool
        address strat;                                      
        bool stratDepositFee;
        // lockable reward
        bool hasLockedReward; 
        uint256 lockedRewardPercent;
        uint256 toLockedPid; 
    }

    // Lock info of each pool.
    struct PoolLockInfo {
        bool isLocked; 
        bool hasFixedLockBaseFee; 
        uint256 lockBaseFee;
        uint256 lockBaseTime;
    }

    // The reward token
    IMintable public yCorn;
    // Dev address
    address public devAddress;
    address public govAddress;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    // Lottery address
    address public lotteryAddress;
    // YCorn tokens created per block.
    uint256 public yCornPerBlock;
    // Lottery reward ratio
    uint256 public lotteryPercent = 0;
    // Bonus multiplier for early yCorn makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    uint256 public constant REWARD_MULTIPLIER = 1e12;

    // Info of each pool.
    PoolInfo[] public poolInfo;    
    // Lock info of each pool.
    PoolLockInfo[] public poolLockInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when YCorn mining starts.
    uint256 public startBlock;
    // Du to the unstable block duration on Polygon we put a setter to initialize the deposit
    bool public initStacking = false;

    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetLotteryAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 yCornPerBlock);
    event UpdateLotteryRewardRate(address indexed user, uint256 lotteryPercent);
    event LockedReward(address indexed user, uint256 indexed pidPoolLocked, uint256 amountLocked);
    modifier onlyOwnerOrGov()
    {
        require(msg.sender == owner() || msg.sender == govAddress ,"onlyOwnerOrGov");
        _;
    }
    constructor(
        IMintable _yCorn,
        address _devAddress,
        address _govAddress,
        uint256 _yCornPerBlock,
        uint256 _startBlock
    ) public {
        yCorn = _yCorn;
        devAddress = _devAddress;
        govAddress = _govAddress;
        yCornPerBlock = _yCornPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _maxDepositAmount,
        bool _canDeposit,
        address _strat,
        bool _stratDepositFee,
        bool _isLocked,
        bool _hasLockedReward,
        uint256 _toLockedPid,
        bool _withUpdate
    ) override external onlyOwner {
        if (_withUpdate) {
            _massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSinkPerShare: 0,
            maxDepositAmount: _maxDepositAmount,
            currentDepositAmount: 0,
            canDeposit: _canDeposit,
            strat: _strat,
            stratDepositFee: _stratDepositFee,
            hasLockedReward: _hasLockedReward,
            lockedRewardPercent: 5000,
            toLockedPid: _toLockedPid
        }));

        poolLockInfo.push(PoolLockInfo({
            isLocked: _isLocked,
            hasFixedLockBaseFee: false,
            lockBaseFee: 7500,
            lockBaseTime: 30 days
        }));
    }

    // Update the given pool's YCorn allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _maxDepositAmount,
        bool _canDeposit,
        address _strat,
        bool _stratDepositFee,
        bool _withUpdate
    ) override external onlyOwner {
        if (_withUpdate) {
            _massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].lpToken = _lpToken;
        poolInfo[_pid].maxDepositAmount = _maxDepositAmount;
        poolInfo[_pid].canDeposit = _canDeposit;
        poolInfo[_pid].strat = poolInfo[_pid].currentDepositAmount > 0 ? poolInfo[_pid].strat : _strat;
        poolInfo[_pid].stratDepositFee = _stratDepositFee;   
    }

    function setCanDeposit(
        uint256 _pid,
        bool _canDeposit,
        bool _withUpdate
    ) override external onlyOwner {
        if (_withUpdate) {
            _massUpdatePools();
        }
        poolInfo[_pid].canDeposit = _canDeposit;
    }

    function setLock(
        uint256 _pid,
        bool _isLocked,
        bool _hasFixedLockBaseFee,
        uint256 _lockBaseFee,
        uint256 _lockBaseTime,
        bool _withUpdate
    ) override external onlyOwner {
        require(_lockBaseFee <= 10000, "Max lockBaseFee is 100%");

        if (_withUpdate) {
            _massUpdatePools();
        }
        poolLockInfo[_pid].isLocked = _isLocked;
        poolLockInfo[_pid].hasFixedLockBaseFee = _hasFixedLockBaseFee;
        poolLockInfo[_pid].lockBaseFee = _lockBaseFee;
        poolLockInfo[_pid].lockBaseTime = _lockBaseTime;
    }

    function setLockableReward(
        uint256 _pid,
        bool _hasLockedReward,
        uint256 _toLockedPid,
        uint256 _lockedRewardPercent,
        bool _withUpdate
    ) override external onlyOwner {
        require(_lockedRewardPercent <= 10000, "Max lockedRewardPercent is 100%");

        if (_withUpdate) {
            _massUpdatePools();
        }
        
        poolInfo[_pid].hasLockedReward = _hasLockedReward;
        poolInfo[_pid].toLockedPid = _toLockedPid;        
        poolInfo[_pid].lockedRewardPercent = _lockedRewardPercent;        
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending YCorns on frontend.
    function pendingYCorn(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSinkPerShare = pool.accSinkPerShare;
        uint256 lpSupply = 0;
        if(pool.strat != address(0)) {
            lpSupply = IStrategy(pool.strat).wantLockedTotal();
        } else {
            lpSupply = pool.currentDepositAmount;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 yCornReward = multiplier.mul(yCornPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSinkPerShare = accSinkPerShare.add(yCornReward.mul(REWARD_MULTIPLIER).div(lpSupply));
        }
        return user.amount.mul(accSinkPerShare).div(REWARD_MULTIPLIER).sub(user.rewardDebt);
    }

    function massUpdatePools() override external {
        _massUpdatePools();
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function _massUpdatePools() private {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = 0;
        if(pool.strat != address(0)) {
            lpSupply = IStrategy(pool.strat).wantLockedTotal();
        } else {
            lpSupply = pool.currentDepositAmount;
        }
        if (lpSupply == 0 || pool.allocPoint == 0 || yCornPerBlock == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (multiplier <= 0) {
            return;
        }
        uint256 yCornReward = multiplier.mul(yCornPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 devReward = yCornReward.div(10);
        uint256 lotteryReward = yCornReward.mul(lotteryPercent).div(10000);
        yCorn.mint(address(this), yCornReward);
        yCorn.mint(devAddress, devReward);
        if(lotteryReward > 0) {
            yCorn.mint(lotteryAddress, lotteryReward);
        }
        
        pool.accSinkPerShare = pool.accSinkPerShare.add(yCornReward.mul(REWARD_MULTIPLIER).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit tokens to chef for YCorn allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        require(initStacking, "NOT INITIALISED");
        require(block.number >= startBlock, "NOT STARTED");

        PoolInfo storage pool = poolInfo[_pid];
        PoolLockInfo storage poolLock = poolLockInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.canDeposit, "deposit: can't deposit in this pool");

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER).sub(user.rewardDebt);
            if (pending > 0) {
                if(pool.hasLockedReward) { 
                    _lockReward(pool, msg.sender, pending);
                } else {
                    safeYCornTransfer(msg.sender, pending);
                }
            }
        }
        if (_amount > 0) {
            
            uint256 depositFee = 0;
            if(pool.strat != address(0)) {
                if(pool.stratDepositFee) {
                    uint256 stratDepositFee = IStrategy(pool.strat).fetchDepositFee();
                    depositFee = _amount.mul(stratDepositFee).div(10000);
                }
            }   
            uint256 depositAmount = _amount.sub(depositFee);

            //Ensure adequate deposit quota if there is a max cap
            if(pool.maxDepositAmount > 0){
                uint256 remainingQuota = pool.maxDepositAmount.sub(pool.currentDepositAmount);
                require(remainingQuota >= depositAmount, "deposit: reached maximum limit");
            }

            if (user.amount == 0 && poolLock.isLocked) {
                user.startLockTime = block.timestamp;
                user.endLockTime = block.timestamp + poolLock.lockBaseTime;
            }

            uint256 balanceBefore =  pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 tokenBalance =  pool.lpToken.balanceOf(address(this)).sub(balanceBefore);
            
            uint256 rAmount = tokenBalance.sub(depositFee);
            pool.currentDepositAmount = pool.currentDepositAmount.add(rAmount);

            if(pool.strat != address(0)) {
                require(_amount == tokenBalance, 'Taxed tokens not ALLOWED');
                pool.lpToken.safeIncreaseAllowance(pool.strat, tokenBalance);
                uint256 amountDeposit = IStrategy(pool.strat).deposit(tokenBalance);
                user.amount = user.amount.add(amountDeposit);
            } else {
                user.amount = user.amount.add(rAmount);
            }
            user.lastDepositTime = block.timestamp;
        }
        user.rewardDebt = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        PoolLockInfo storage poolLock = poolLockInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.currentDepositAmount > 0, "pool.currentDepositAmount is 0");
        
        if(pool.strat != address(0)) {
            uint256 total = IStrategy(pool.strat).wantLockedTotal();
            require(total > 0, "Total is 0");
        }

        require(user.amount >= _amount, "withdraw: not good");

        uint256 pending = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER).sub(user.rewardDebt);
        if (pending > 0) {
            if(pool.hasLockedReward) { 
                _lockReward(pool, msg.sender, pending);
            } else {
                safeYCornTransfer(msg.sender, pending);
            }
        }
        // Withdraw want tokens
        uint256 userAmount = user.amount;
        if (_amount > userAmount) {
            _amount = userAmount;
        }
        if (_amount > 0) {
            uint256 amountRemove = _amount;

            if(pool.strat != address(0)) {
               amountRemove = IStrategy(pool.strat).withdraw(_amount);
            }

            if (amountRemove > user.amount) {
                user.amount = 0;
            } else {
                user.amount = user.amount.sub(amountRemove);
            }

            pool.currentDepositAmount = pool.currentDepositAmount.sub(amountRemove);

            if (pool.lpToken == IERC20(yCorn) && poolLock.isLocked && poolLock.lockBaseFee > 0) {
                user.endLockTime = user.startLockTime + poolLock.lockBaseTime;
                if (block.timestamp < user.endLockTime) {
                    uint256 lockedAmount = 0;
                    if(poolLock.hasFixedLockBaseFee) {
                        lockedAmount = amountRemove.mul(poolLock.lockBaseFee).div(10000);
                    } else {
                        uint256 PRECISION = 1e3;
                        uint256 lockTotalTime = user.endLockTime.sub(user.startLockTime);
                        uint256 lockCurrentTime = block.timestamp.sub(user.startLockTime);

                        uint256 lockProgress = lockCurrentTime.mul(PRECISION).div(lockTotalTime);
                        uint256 lockRate = PRECISION.sub(lockProgress);

                        uint256 lockFee = poolLock.lockBaseFee.mul(lockRate).div(PRECISION);

                        lockedAmount = amountRemove.mul(lockFee).div(10000);
                    }

                    amountRemove = amountRemove.sub(lockedAmount);
                    
                    if(lockedAmount > 0) {    
                        safeYCornTransfer(burnAddress, lockedAmount);
                    }
                    
                    user.startLockTime = block.timestamp;
                    user.endLockTime = block.timestamp + poolLock.lockBaseTime;
                }
            }

            uint256 wantBal = IERC20(pool.lpToken).balanceOf(address(this));
            if (wantBal < amountRemove) {
                amountRemove = wantBal;
            }
            pool.lpToken.safeTransfer(address(msg.sender), amountRemove);
        }
        if(user.amount == 0) {
            user.startLockTime = 0;
            user.endLockTime = 0;
        }
        user.rewardDebt = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function _lockReward(PoolInfo storage pool, address user, uint256 pending) private {
        PoolInfo storage targetPool = poolInfo[pool.toLockedPid];
        PoolLockInfo storage targetLockPool = poolLockInfo[pool.toLockedPid];
        UserInfo storage userPoolLocked = userInfo[pool.toLockedPid][user];

        if(targetLockPool.isLocked) {
            uint256 lockedAmount = pending.mul(pool.lockedRewardPercent).div(10000); // 50% (default) pending rewards to locked pool
            uint256 unlockedAmount = pending.sub(lockedAmount); // 50% pending rewards left to user
            if(unlockedAmount > 0) {    
                safeYCornTransfer(user, unlockedAmount);
            }

            updatePool(pool.toLockedPid);

            targetPool.currentDepositAmount = targetPool.currentDepositAmount.add(lockedAmount);
            if (userPoolLocked.amount == 0) {
                userPoolLocked.startLockTime = block.timestamp;
                userPoolLocked.endLockTime = block.timestamp + targetLockPool.lockBaseTime;
            } else {
                uint256 pendingOfLockedPool = userPoolLocked.amount.mul(targetPool.accSinkPerShare).div(REWARD_MULTIPLIER).sub(userPoolLocked.rewardDebt);
                if (pendingOfLockedPool > 0) {
                    safeYCornTransfer(user, pendingOfLockedPool);
                }
            }
            userPoolLocked.amount = userPoolLocked.amount.add(lockedAmount);
            userPoolLocked.lastDepositTime = block.timestamp;
            userPoolLocked.rewardDebt = userPoolLocked.amount.mul(targetPool.accSinkPerShare).div(REWARD_MULTIPLIER);
            emit LockedReward(user, pool.toLockedPid, lockedAmount);
        } else {
            safeYCornTransfer(user, pending);
        }
    } 

    function _burnReward(PoolInfo storage pool, address user, uint256 pending) private {
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        PoolLockInfo storage poolLock = poolLockInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amountRemove = user.amount;

        if(pool.strat != address(0)) {
           amountRemove = IStrategy(pool.strat).withdraw(amountRemove);
        }

        if(poolLock.isLocked) { 
           amountRemove = 0;
        } else {
           user.amount = 0;
           user.rewardDebt = 0;
        }

        pool.currentDepositAmount = pool.currentDepositAmount.sub(amountRemove);
        pool.lpToken.safeTransfer(address(msg.sender), amountRemove);
        emit EmergencyWithdraw(msg.sender, _pid, amountRemove);
    }
    
    receive() external payable {}

    function safeTransferMATIC(address to, uint value) external  {
        require(msg.sender == govAddress, "safeTransferMATIC : FORBIDDEN");
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: MATIC_TRANSFER_FAILED');
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) external
    {
        require(msg.sender == govAddress, "inCaseTokensGetStuck : FORBIDDEN");
        require(_token != address(yCorn), "!safe");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    
    // Safe yCorn transfer function, just in case if rounding error causes pool to not have enough YCorns.
    function safeYCornTransfer(address _to, uint256 _amount) internal {
        uint256 yCornBal = yCorn.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > yCornBal) {
            transferSuccess = yCorn.transfer(_to, yCornBal);
        } else {
            transferSuccess = yCorn.transfer(_to, _amount);
        }
        require(transferSuccess, "safeYCornTransfer: transfer failed");
    }

    function setDevAddress(address _devAddress) external {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    function setLotteryAddress(address _lotteryAddress) override external onlyOwner {
        lotteryAddress = _lotteryAddress;
        emit SetLotteryAddress(msg.sender, _lotteryAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _yCornPerBlock) external onlyOwner {
        _massUpdatePools();
        yCornPerBlock = _yCornPerBlock;
        emit UpdateEmissionRate(msg.sender, _yCornPerBlock);
    }

    function updateLotteryRewardRate(uint256 _lotteryPercent) external onlyOwner {
        require(_lotteryPercent <= 500, "Max lottery percent is 50%");
        lotteryPercent = _lotteryPercent;
        emit UpdateLotteryRewardRate(msg.sender, _lotteryPercent);
    }

    //New function to trigger harvest for a specific user and pool
    //A specific user address is provided to facilitate aggregating harvests on multiple chefs
    //Also, it is harmless monetary-wise to help someone else harvests
    function harvestFor(uint256 _pid, address _user) public nonReentrant {
        //Limit to self or delegated harvest to avoid unnecessary confusion
        require(msg.sender == _user || tx.origin == _user, "harvestFor: FORBIDDEN");

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        require(pool.currentDepositAmount > 0, "pool.currentDepositAmount is 0");
        
        if(pool.strat != address(0)) {
            uint256 total = IStrategy(pool.strat).wantLockedTotal();
            require(total > 0, "Total is 0");
        }

        require(user.amount > 0, "user.amount is 0");
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER).sub(user.rewardDebt);
            if (pending > 0) {
                if(pool.hasLockedReward) { 
                    _lockReward(pool, _user, pending);
                } else {
                    safeYCornTransfer(_user, pending);
                }
                user.rewardDebt = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER);
                emit Harvest(_user, _pid, pending);
            }
        }
    }
    
    function setInitStackingTrue() external onlyOwnerOrGov {
        require(!initStacking, "ALREADY INITIALIZED");
        initStacking = true;
    }

    function bulkHarvestFor(uint256[] calldata pidArray, address _user) external {
        uint256 length = pidArray.length;
        for (uint256 index = 0; index < length; ++index) {
            uint256 _pid = pidArray[index];
            harvestFor(_pid, _user);
        }
    }
}


contract WrapperPolyMasterCorn is Ownable  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    PolyMasterCorn public polyMasterCorn;

    constructor(
      PolyMasterCorn _polyMasterCorn
    ) public {
        polyMasterCorn = _polyMasterCorn;
    }

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _maxDepositAmount,
        bool _canDeposit,
        address _strat,
        bool _stratDepositFee,
        bool _isLocked,
        bool _hasLockedReward,
        uint256 _toLockedPid,
        bool _withUpdate
    ) external onlyOwner {
        polyMasterCorn.add(_allocPoint, _lpToken, _maxDepositAmount, _canDeposit, _strat, _stratDepositFee, _isLocked, _hasLockedReward, _toLockedPid, _withUpdate);
    }

    // Update the given pool's YCorn allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _maxDepositAmount,
        bool _canDeposit,
        bool _stratDepositFee,
        bool _withUpdate
    ) external onlyOwner {
        (IERC20 lpToken,,,,,,,address strat,,,,) = polyMasterCorn.poolInfo(_pid);
        polyMasterCorn.set(_pid, _allocPoint, lpToken, _maxDepositAmount, _canDeposit, strat, _stratDepositFee, _withUpdate);
    }

    function setCanDeposit(
        uint256 _pid,
        bool _canDeposit,
        bool _withUpdate
    ) external onlyOwner {
        polyMasterCorn.setCanDeposit(_pid, _canDeposit, _withUpdate);
    }

    function setLock(
        uint256 _pid,
        bool _isLocked,
        bool _hasFixedLockBaseFee,
        uint256 _lockBaseFee,
        uint256 _lockBaseTime,
        bool _withUpdate
    ) external onlyOwner {
        polyMasterCorn.setLock(_pid, _isLocked, _hasFixedLockBaseFee, _lockBaseFee, _lockBaseTime, _withUpdate);
    }

    function setLockableReward(
        uint256 _pid,
        bool _hasLockedReward,
        uint256 _toLockedPid,
        uint256 _lockedRewardPercent,
        bool _withUpdate
    )  external onlyOwner {
        polyMasterCorn.setLockableReward(_pid, _hasLockedReward, _toLockedPid, _lockedRewardPercent, _withUpdate);
    }

    function setLotteryAddress(address _lotteryAddress) external onlyOwner {
        polyMasterCorn.setLotteryAddress(_lotteryAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _yCornPerBlock) external onlyOwner {
        require(_yCornPerBlock <= 2e18, "Emission can't go higher than 2 tokens per block");
        polyMasterCorn.updateEmissionRate(_yCornPerBlock);
    }

    function updateLotteryRewardRate(uint256 _lotteryPercent) external onlyOwner {
        polyMasterCorn.updateLotteryRewardRate(_lotteryPercent);
    }
}