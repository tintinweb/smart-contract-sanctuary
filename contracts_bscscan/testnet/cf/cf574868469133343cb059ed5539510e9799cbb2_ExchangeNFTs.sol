/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
        return msg.data;
    }
    uint256[50] private __gap;
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        _afterTokenTransfer(sender, recipient, amount);
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

        _afterTokenTransfer(address(0), account, amount);
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

        _afterTokenTransfer(account, address(0), amount);
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
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * plain `call` is an unsafe replacement for a function call: use this
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
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
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
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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
library EnumerableSetUpgradeable {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSetUpgradeable.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableMap.sol
 */
library EnumerableMap {
    struct MapEntry {
        uint256 _key;
        uint256 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(uint256 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        uint256 key,
        uint256 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, uint256 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, uint256 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (uint256, uint256) {
        require(map._entries.length > index, 'EnumerableMap: index out of bounds');

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, uint256 key) private view returns (uint256) {
        return _get(map, key, 'EnumerableMap: nonexistent key');
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        uint256 key,
        string memory errorMessage
    ) private view returns (uint256) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToUintMap

    struct UintToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return _get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return _get(map._inner, key, errorMessage);
    }
}

interface IExchangeNFTs {
    event Ask(
        address indexed nftToken,
        address seller,
        uint256 indexed tokenId,
        address indexed quoteToken,
        uint256 price
    );
    event Trade(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        address buyer,
        uint256 indexed tokenId,
        uint256 price,
        uint256 fee
    );
    event CancelSellToken(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        uint256 indexed tokenId,
        uint256 price
    );
    event FeeAddressTransferred(address indexed nftToken, address indexed previousOwner, address indexed newOwner);
    event SetFee(address indexed nftToken, address seller, uint256 oldFee, uint256 newFee);
    event Bid(
        address indexed nftToken,
        address bidder,
        uint256 indexed tokenId,
        address indexed quoteToken,
        uint256 price
    );
    event CancelBidToken(
        address indexed nftToken,
        address indexed quoteToken,
        address bidder,
        uint256 indexed tokenId,
        uint256 price
    );

    function batchReadyToSellToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function batchReadyToSellTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) external;

    function readyToSellToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external;

    function readyToSellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external;

    function batchSetCurrentPrice(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function setCurrentPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external;

    function batchBuyToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function batchBuyTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) external;

    function buyToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external;

    function buyTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external;

    function batchCancelSellToken(address[] memory _nftTokens, uint256[] memory _tokenIds) external;

    function cancelSellToken(address _nftToken, uint256 _tokenId) external;

    function batchBidToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function batchBidTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) external;

    function bidToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external;

    function bidTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external;

    function batchUpdateBidPrice(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function updateBidPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external;

    function sellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external;

    function batchCancelBidToken(
        address[] memory _nftTokens,
        address[] memory _quoteTokens,
        uint256[] memory _tokenIds
    ) external;

    function cancelBidToken(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId
    ) external;
}

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256('Part(address account,uint96 value)');

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

interface Royalties {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRoyalties(uint256 id) external view returns (LibPart.Part[] memory);
}

contract ExchangeNFTs is IExchangeNFTs, ERC721HolderUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct NftSettings {
        bool enable;
        bool feeBurnAble;
        bool royaltiesAble;
        bool royaltiesBurnAble;
    }

    struct AskEntry {
        uint256 tokenId;
        uint256 price;
    }

    struct BidEntry {
        address bidder;
        uint256 price;
    }

    struct UserBidEntry {
        uint256 tokenId;
        uint256 price;
    }

    // nft => settings
    mapping(address => NftSettings) public nftSettingsMap;
    // nft => quote => isEnable
    mapping(address => mapping(address => bool)) public nftQuoteEnables;
    // nft => quotes
    mapping(address => EnumerableSetUpgradeable.AddressSet) private nftQuotes;
    // nft => fee address
    mapping(address => address) public feeAddresses;
    // nft => fee
    mapping(address => uint256) public feeValues;
    // nft => tokenId => seller
    mapping(address => mapping(uint256 => address)) public tokenSellers;
    // nft => tokenId => quote
    mapping(address => mapping(uint256 => address)) public tokenSelleOn;
    // nft => quote => tokenId,price
    mapping(address => mapping(address => EnumerableMap.UintToUintMap)) private _asksMaps;
    // nft => quote => seller => tokenIds
    mapping(address => mapping(address => mapping(address => EnumerableSetUpgradeable.UintSet)))
        private _userSellingTokens;
    // nft => quote => tokenId => bid
    mapping(address => mapping(address => mapping(uint256 => BidEntry[]))) public tokenBids;
    // nft => quote => buyer => tokenId,bid
    mapping(address => mapping(address => mapping(address => EnumerableMap.UintToUintMap))) private _userBids;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Holder_init();
    }

    modifier enableTrade(address _nftToken, address _quoteToken) {
        // nft disable
        require(nftSettingsMap[_nftToken].enable, 'n');
        // quote disable
        require(nftQuoteEnables[_nftToken][_quoteToken], 'q');
        _;
    }

    function setNftSettings(
        address _nftToken,
        bool _enable,
        bool _feeBurnAble,
        bool _royaltiesAble,
        bool _royaltiesBurnAble
    ) public onlyOwner {
        nftSettingsMap[_nftToken] = NftSettings({
            enable: _enable,
            feeBurnAble: _feeBurnAble,
            royaltiesAble: _royaltiesAble,
            royaltiesBurnAble: _royaltiesBurnAble
        });
    }

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) public onlyOwner {
        EnumerableSetUpgradeable.AddressSet storage quotes = nftQuotes[_nftToken];
        for (uint256 i = 0; i < _quotes.length; i++) {
            nftQuoteEnables[_nftToken][_quotes[i]] = _enable;
            if (!quotes.contains(_quotes[i])) {
                quotes.add(_quotes[i]);
            }
        }
    }

    function getNftQuotes(address _nftToken) public view returns (address[] memory quotes) {
        quotes = new address[](nftQuotes[_nftToken].length());
        for (uint256 i = 0; i < nftQuotes[_nftToken].length(); ++i) {
            quotes[i] = nftQuotes[_nftToken].at(i);
        }
    }

    function transferFeeAddress(address _nftToken, address _feeAddress) public {
        // FORBIDDEN
        require(_msgSender() == feeAddresses[_nftToken] || owner() == _msgSender(), 'f');
        emit FeeAddressTransferred(_nftToken, feeAddresses[_nftToken], _feeAddress);
        feeAddresses[_nftToken] = _feeAddress;
    }

    function setFee(address _nftToken, uint256 _feeValue) public onlyOwner {
        // Not need update
        require(feeValues[_nftToken] != _feeValue, 'n');
        emit SetFee(_nftToken, _msgSender(), feeValues[_nftToken], _feeValue);
        feeValues[_nftToken] = _feeValue;
    }

    function addNft(
        address _nftToken,
        address[] memory _quotes,
        address _feeAddress,
        uint256 _feeValue,
        bool _enable,
        bool _feeBurnAble,
        bool _royaltiesAble,
        bool _royaltiesBurnAble
    ) public onlyOwner {
        setNftSettings(_nftToken, _enable, _feeBurnAble, _royaltiesAble, _royaltiesBurnAble);
        setNftQuoteEnables(_nftToken, _quotes, true);
        transferFeeAddress(_nftToken, _feeAddress);
        setFee(_nftToken, _feeValue);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function batchReadyToSellToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override whenNotPaused {
        batchReadyToSellTokenTo(_nftTokens, _tokenIds, _quoteTokens, _prices, _msgSender());
    }

    function batchReadyToSellTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) public override whenNotPaused {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            'l'
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            buyTokenTo(_nftTokens[i], _tokenIds[i], _quoteTokens[i], _prices[i], _to);
        }
    }

    function readyToSellToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external override whenNotPaused {
        readyToSellTokenTo(_nftToken, _tokenId, _quoteToken, _price, _msgSender());
    }

    function readyToSellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) public override enableTrade(_nftToken, _quoteToken) whenNotPaused {
        // Only Token Owner can sell token
        require(_msgSender() == IERC721Upgradeable(_nftToken).ownerOf(_tokenId), 'o');
        // Price must be granter than zero
        require(_price != 0, 'p');
        IERC721Upgradeable(_nftToken).safeTransferFrom(_msgSender(), address(this), _tokenId);
        _asksMaps[_nftToken][_quoteToken].set(_tokenId, _price);
        tokenSellers[_nftToken][_tokenId] = _to;
        tokenSelleOn[_nftToken][_tokenId] = _quoteToken;
        _userSellingTokens[_nftToken][_quoteToken][_to].add(_tokenId);
        emit Ask(_nftToken, _msgSender(), _tokenId, _quoteToken, _price);
    }

    function batchSetCurrentPrice(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override whenNotPaused {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            'l'
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            setCurrentPrice(_nftTokens[i], _tokenIds[i], _quoteTokens[i], _prices[i]);
        }
    }

    function setCurrentPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) public override enableTrade(_nftToken, _quoteToken) whenNotPaused {
        // Only Seller can update price
        require(_userSellingTokens[_nftToken][_quoteToken][_msgSender()].contains(_tokenId), 'o');
        // Price must be granter than zero
        require(_price != 0, 'p0');
        _asksMaps[_nftToken][_quoteToken].set(_tokenId, _price);
        emit Ask(_nftToken, _msgSender(), _tokenId, _quoteToken, _price);
    }

    function batchBuyToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override whenNotPaused {
        batchBuyTokenTo(_nftTokens, _tokenIds, _quoteTokens, _prices, _msgSender());
    }

    function batchBuyTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) public override whenNotPaused {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            'l'
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            buyTokenTo(_nftTokens[i], _tokenIds[i], _quoteTokens[i], _prices[i], _to);
        }
    }

    function buyToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external override whenNotPaused {
        buyTokenTo(_nftToken, _tokenId, _quoteToken, _price, _msgSender());
    }

    function _settleTrade(
        address _nftToken,
        address _quoteToken,
        address _buyer,
        address _seller,
        uint256 _tokenId,
        uint256 _price,
        bool _isMaker
    ) internal virtual {
        NftSettings memory nftSettings = nftSettingsMap[_nftToken];
        IERC721Upgradeable(_nftToken).safeTransferFrom(address(this), _buyer, _tokenId);

        uint256 feeAmount = _price.mul(feeValues[_nftToken]).div(10000);

        if (feeAmount != 0) {
            if (nftSettings.feeBurnAble) {
                if (_isMaker) {
                    ERC20BurnableUpgradeable(_quoteToken).burn(feeAmount);
                } else {
                    ERC20BurnableUpgradeable(_quoteToken).burnFrom(_msgSender(), feeAmount);
                }
            } else {
                if (_isMaker) {
                    IERC20Upgradeable(_quoteToken).transfer(feeAddresses[_nftToken], feeAmount);
                } else {
                    IERC20Upgradeable(_quoteToken).safeTransferFrom(_msgSender(), feeAddresses[_nftToken], feeAmount);
                }
            }
        }
        uint256 restValue = _price.sub(feeAmount);
        if (nftSettings.royaltiesAble) {
            LibPart.Part[] memory fees = Royalties(_nftToken).getRoyalties(_tokenId);
            for (uint256 i = 0; i < fees.length; i++) {
                uint256 feeValue = _price.mul(fees[i].value).div(10000);
                if (restValue > feeValue) {
                    restValue = restValue.sub(feeValue);
                } else {
                    feeValue = restValue;
                    restValue = 0;
                }
                if (feeValue != 0) {
                    feeAmount = feeAmount.add(feeValue);
                    if (nftSettings.royaltiesBurnAble) {
                        if (_isMaker) {
                            ERC20BurnableUpgradeable(_quoteToken).burn(feeValue);
                        } else {
                            ERC20BurnableUpgradeable(_quoteToken).burnFrom(_msgSender(), feeValue);
                        }
                    } else {
                        if (_isMaker) {
                            IERC20Upgradeable(_quoteToken).transfer(fees[i].account, feeValue);
                        } else {
                            IERC20Upgradeable(_quoteToken).safeTransferFrom(_msgSender(), fees[i].account, feeValue);
                        }
                    }
                }
            }
        }

        if (restValue != 0) {
            if (_isMaker) {
                IERC20Upgradeable(_quoteToken).transfer(_seller, restValue);
            } else {
                IERC20Upgradeable(_quoteToken).safeTransferFrom(_msgSender(), _seller, restValue);
            }
        }

        _asksMaps[_nftToken][_quoteToken].remove(_tokenId);
        _userSellingTokens[_nftToken][_quoteToken][_seller].remove(_tokenId);
        emit Trade(_nftToken, _quoteToken, _seller, _buyer, _tokenId, _price, feeAmount);
        delete tokenSellers[_nftToken][_tokenId];
        delete tokenSelleOn[_nftToken][_tokenId];
    }

    function buyTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) public override enableTrade(_nftToken, _quoteToken) whenNotPaused {
        // quote token error
        require(tokenSelleOn[_nftToken][_tokenId] == _quoteToken, 'qt');
        // Token not in sell book
        require(_asksMaps[_nftToken][_quoteToken].contains(_tokenId), 'b');
        // You must cancel your bid first
        require(!_userBids[_nftToken][_quoteToken][_msgSender()].contains(_tokenId), 'f');
        uint256 price = _asksMaps[_nftToken][_quoteToken].get(_tokenId);
        // Wrong price
        require(_price == price, 'p');
        _settleTrade(_nftToken, _quoteToken, _to, tokenSellers[_nftToken][_tokenId], _tokenId, _price, false);
    }

    function batchCancelSellToken(address[] memory _nftTokens, uint256[] memory _tokenIds)
        external
        override
        whenNotPaused
    {
        require(_nftTokens.length == _tokenIds.length);
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            cancelSellToken(_nftTokens[i], _tokenIds[i]);
        }
    }

    function cancelSellToken(address _nftToken, uint256 _tokenId) public override whenNotPaused {
        // Only Seller can cancel sell token
        require(tokenSellers[_nftToken][_tokenId] == _msgSender(), 's');
        IERC721Upgradeable(_nftToken).safeTransferFrom(address(this), _msgSender(), _tokenId);
        _userSellingTokens[_nftToken][tokenSelleOn[_nftToken][_tokenId]][_msgSender()].remove(_tokenId);
        emit CancelSellToken(
            _nftToken,
            tokenSelleOn[_nftToken][_tokenId],
            _msgSender(),
            _tokenId,
            _asksMaps[_nftToken][tokenSelleOn[_nftToken][_tokenId]].get(_tokenId)
        );
        _asksMaps[_nftToken][tokenSelleOn[_nftToken][_tokenId]].remove(_tokenId);
        delete tokenSellers[_nftToken][_tokenId];
        delete tokenSelleOn[_nftToken][_tokenId];
    }

    function getAskLength(address _nftToken, address _quoteToken) public view returns (uint256) {
        return _asksMaps[_nftToken][_quoteToken].length();
    }

    function getAsks(address _nftToken, address _quoteToken) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_asksMaps[_nftToken][_quoteToken].length());
        for (uint256 i = 0; i < _asksMaps[_nftToken][_quoteToken].length(); ++i) {
            (uint256 tokenId, uint256 price) = _asksMaps[_nftToken][_quoteToken].at(i);
            asks[i] = AskEntry({tokenId: tokenId, price: price});
        }
        return asks;
    }

    function getAsksByNFT(address _nftToken)
        public
        view
        returns (
            address[] memory quotes,
            uint256[] memory lengths,
            AskEntry[] memory asks
        )
    {
        quotes = getNftQuotes(_nftToken);
        lengths = new uint256[](quotes.length);
        uint256 total = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            lengths[i] = getAskLength(_nftToken, quotes[i]);
            total = total + lengths[i];
        }
        asks = new AskEntry[](total);
        uint256 index = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            AskEntry[] memory tempAsks = getAsks(_nftToken, quotes[i]);
            for (uint256 j = 0; j < tempAsks.length; ++j) {
                asks[index] = tempAsks[j];
                ++index;
            }
        }
    }

    function getAsksByPage(
        address _nftToken,
        address _quoteToken,
        uint256 _page,
        uint256 _size
    ) public view returns (AskEntry[] memory) {
        if (_asksMaps[_nftToken][_quoteToken].length() > 0) {
            uint256 from = _page == 0 ? 0 : (_page - 1) * _size;
            uint256 to =
                MathUpgradeable.min((_page == 0 ? 1 : _page) * _size, _asksMaps[_nftToken][_quoteToken].length());
            AskEntry[] memory asks = new AskEntry[]((to - from));
            for (uint256 i = 0; from < to; ++i) {
                (uint256 tokenId, uint256 price) = _asksMaps[_nftToken][_quoteToken].at(from);
                asks[i] = AskEntry({tokenId: tokenId, price: price});
                ++from;
            }
            return asks;
        } else {
            return new AskEntry[](0);
        }
    }

    function getUserAsks(
        address _nftToken,
        address _quoteToken,
        address _user
    ) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_userSellingTokens[_nftToken][_quoteToken][_user].length());
        for (uint256 i = 0; i < _userSellingTokens[_nftToken][_quoteToken][_user].length(); ++i) {
            uint256 tokenId = _userSellingTokens[_nftToken][_quoteToken][_user].at(i);
            uint256 price = _asksMaps[_nftToken][_quoteToken].get(tokenId);
            asks[i] = AskEntry({tokenId: tokenId, price: price});
        }
        return asks;
    }

    function getUserAsksByNFT(address _nftToken, address _user)
        public
        view
        returns (
            address[] memory quotes,
            uint256[] memory lengths,
            AskEntry[] memory asks
        )
    {
        quotes = getNftQuotes(_nftToken);
        lengths = new uint256[](quotes.length);
        uint256 total = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            lengths[i] = _userSellingTokens[_nftToken][quotes[i]][_user].length();
            total = total + lengths[i];
        }
        asks = new AskEntry[](total);
        uint256 index = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            AskEntry[] memory tempAsks = getUserAsks(_nftToken, quotes[i], _user);
            for (uint256 j = 0; j < tempAsks.length; ++j) {
                asks[index] = tempAsks[j];
                ++index;
            }
        }
    }

    // bid
    function batchBidToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override whenNotPaused {
        batchBidTokenTo(_nftTokens, _tokenIds, _quoteTokens, _prices, _msgSender());
    }

    function batchBidTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) public override whenNotPaused {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            'l'
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            bidTokenTo(_nftTokens[i], _tokenIds[i], _quoteTokens[i], _prices[i], _to);
        }
    }

    function bidToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external override whenNotPaused {
        bidTokenTo(_nftToken, _tokenId, _quoteToken, _price, _msgSender());
    }

    function bidTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) public override enableTrade(_nftToken, _quoteToken) whenNotPaused {
        // Price must be granter than zero
        require(_price != 0, 'p0');
        // Token not in sell book
        require(_asksMaps[_nftToken][_quoteToken].contains(_tokenId), 'b');
        // Owner cannot bid
        require(tokenSellers[_nftToken][_tokenId] != _to, 'o');
        // Bidder already exists
        require(!_userBids[_nftToken][_quoteToken][_to].contains(_tokenId), 'e');
        IERC20Upgradeable(_quoteToken).safeTransferFrom(_msgSender(), address(this), _price);
        _userBids[_nftToken][_quoteToken][_to].set(_tokenId, _price);
        tokenBids[_nftToken][_quoteToken][_tokenId].push(BidEntry({bidder: _to, price: _price}));
        emit Bid(_nftToken, _to, _tokenId, _quoteToken, _price);
    }

    function batchUpdateBidPrice(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override whenNotPaused {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            'l'
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            updateBidPrice(_nftTokens[i], _tokenIds[i], _quoteTokens[i], _prices[i]);
        }
    }

    function updateBidPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) public override enableTrade(_nftToken, _quoteToken) whenNotPaused {
        // Only Bidder can update the bid price
        require(_userBids[_nftToken][_quoteToken][_msgSender()].contains(_tokenId), 'o');
        // Price must be granter than zero
        require(_price != 0, 'p0');
        address _to = _msgSender(); // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenIdAndAddress(_nftToken, _quoteToken, _tokenId, _to);
        // Bidder does not exist
        require(bidEntry.price != 0, 'e');
        // The bid price cannot be the same
        require(bidEntry.price != _price, 'p1');
        if (_price > bidEntry.price) {
            IERC20Upgradeable(_quoteToken).safeTransferFrom(_msgSender(), address(this), _price.sub(bidEntry.price));
        } else {
            IERC20Upgradeable(_quoteToken).transfer(_to, bidEntry.price.sub(_price));
        }
        _userBids[_nftToken][_quoteToken][_to].set(_tokenId, _price);
        tokenBids[_nftToken][_quoteToken][_tokenId][_index] = BidEntry({bidder: _to, price: _price});
        emit Bid(_nftToken, _to, _tokenId, _quoteToken, _price);
    }

    function getBidByTokenIdAndAddress(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId,
        address _address
    ) internal view virtual returns (BidEntry memory, uint256) {
        // find the index of the bid
        BidEntry[] memory bidEntries = tokenBids[_nftToken][_quoteToken][_tokenId];
        uint256 len = bidEntries.length;
        uint256 _index;
        BidEntry memory bidEntry;
        for (uint256 i = 0; i < len; i++) {
            if (_address == bidEntries[i].bidder) {
                _index = i;
                bidEntry = BidEntry({bidder: bidEntries[i].bidder, price: bidEntries[i].price});
                break;
            }
        }
        return (bidEntry, _index);
    }

    function delBidByTokenIdAndIndex(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId,
        uint256 _index
    ) internal virtual {
        _userBids[_nftToken][_quoteToken][tokenBids[_nftToken][_quoteToken][_tokenId][_index].bidder].remove(_tokenId);
        // delete the bid
        uint256 len = tokenBids[_nftToken][_quoteToken][_tokenId].length;
        for (uint256 i = _index; i < len - 1; i++) {
            tokenBids[_nftToken][_quoteToken][_tokenId][i] = tokenBids[_nftToken][_quoteToken][_tokenId][i + 1];
        }
        tokenBids[_nftToken][_quoteToken][_tokenId].pop();
    }

    function sellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) public override enableTrade(_nftToken, _quoteToken) whenNotPaused {
        // Token not in sell book
        require(_asksMaps[_nftToken][_quoteToken].contains(_tokenId), 'b');
        // Only owner can sell token
        require(tokenSellers[_nftToken][_tokenId] == _msgSender(), 'o');
        // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenIdAndAddress(_nftToken, _quoteToken, _tokenId, _to);
        // Bidder does not exist
        require(bidEntry.price != 0, 'e');
        // Wrong price
        require(_price == bidEntry.price, 'p');
        _settleTrade(_nftToken, _quoteToken, _to, tokenSellers[_nftToken][_tokenId], _tokenId, bidEntry.price, true);
        delBidByTokenIdAndIndex(_nftToken, _quoteToken, _tokenId, _index);
    }

    function batchCancelBidToken(
        address[] memory _nftTokens,
        address[] memory _quoteTokens,
        uint256[] memory _tokenIds
    ) external override whenNotPaused {
        require(_nftTokens.length == _quoteTokens.length && _quoteTokens.length == _tokenIds.length, 'l');
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            cancelBidToken(_nftTokens[i], _quoteTokens[i], _tokenIds[i]);
        }
    }

    function cancelBidToken(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId
    ) public override whenNotPaused {
        // Only Bidder can cancel the bid
        require(_userBids[_nftToken][_quoteToken][_msgSender()].contains(_tokenId), 'b');
        // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) =
            getBidByTokenIdAndAddress(_nftToken, _quoteToken, _tokenId, _msgSender());
        // Bidder does not exist
        require(bidEntry.price != 0, 'e');
        IERC20Upgradeable(_quoteToken).transfer(_msgSender(), bidEntry.price);
        emit CancelBidToken(_nftToken, _quoteToken, _msgSender(), _tokenId, bidEntry.price);
        delBidByTokenIdAndIndex(_nftToken, _quoteToken, _tokenId, _index);
    }

    function getBidsLength(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId
    ) public view returns (uint256) {
        return tokenBids[_nftToken][_quoteToken][_tokenId].length;
    }

    function getBids(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId
    ) public view returns (BidEntry[] memory) {
        return tokenBids[_nftToken][_quoteToken][_tokenId];
    }

    function getUserBids(
        address _nftToken,
        address _quoteToken,
        address _user
    ) public view returns (UserBidEntry[] memory) {
        uint256 length = _userBids[_nftToken][_quoteToken][_user].length();
        UserBidEntry[] memory bids = new UserBidEntry[](length);
        for (uint256 i = 0; i < length; i++) {
            (uint256 tokenId, uint256 price) = _userBids[_nftToken][_quoteToken][_user].at(i);
            bids[i] = UserBidEntry({tokenId: tokenId, price: price});
        }
        return bids;
    }

    function getUserBidsByNFT(address _nftToken, address _user)
        public
        view
        returns (
            address[] memory quotes,
            uint256[] memory lengths,
            UserBidEntry[] memory bids
        )
    {
        quotes = getNftQuotes(_nftToken);
        lengths = new uint256[](quotes.length);
        uint256 total = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            lengths[i] = _userBids[_nftToken][quotes[i]][_user].length();
            total = total + lengths[i];
        }
        bids = new UserBidEntry[](total);
        uint256 index = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            UserBidEntry[] memory tempBids = getUserBids(_nftToken, quotes[i], _user);
            for (uint256 j = 0; j < tempBids.length; ++j) {
                bids[index] = tempBids[j];
                ++index;
            }
        }
    }
}