/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]



pragma solidity ^0.8.0;

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



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]



pragma solidity ^0.8.0;




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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/access/[email protected]



pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts-upgradeable/security/[email protected]



pragma solidity ^0.8.0;


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


// File contracts/child/MelalieDistributionPool.sol


pragma solidity ^0.8.0;

contract MelalieDistributionPool  {

    receive() payable external {}
    

}


// File contracts/child/MelalieStakingTokenUpgradableV2.sol

pragma solidity ^0.8.0;






contract MelalieStakingTokenUpgradableV2 is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    address public childChainManagerProxy;
    address public distributionPoolContract;
    uint256 public minimumStake;
    uint256 public totalDistributions;
    address deployer;

    //staking
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;

    //events
    event StakeCreated(address indexed _from, uint256 _stake);
    event StakeRemoved(address indexed _from, uint256 _stake);
    event RewardsDistributed(uint256 _distributionAmount);
    event RewardWithdrawn(address indexed _from, uint256 _stake);

    //new variable v2
    bool private _upgradedV2;
    address rewardDistributor;
    bool public autostake;

    /**
     * @notice initialize function of the upgradable contract 
     */
    function initialize(string memory name,string memory symbol, address _childChainManagerProxy) initializer public {
       __ERC20_init(name, symbol);
       __Ownable_init();
       __Pausable_init();
        childChainManagerProxy = _childChainManagerProxy;
        deployer = msg.sender;
        minimumStake = 1000000000000000000000;
        distributionPoolContract = address(0);
    }

    function upgrade() public {
        require(!_upgradedV2, "MelalieStakingTokenUpgradableV2: already upgraded");
        _upgradedV2 = true;
        rewardDistributor = msg.sender;

        /*
        1. distributionPoolContract should contain following amounts: 
                - total stakes (old contract was: 1086026210091837526600000 / new contract is: 1065797210091837526600000)
                - total rewards (old contract was     794063807637144565908)
                - total balances (old contract was at block 17386211: 1815457759082812094567 MEL <-- without 0x6e and other exiters!
                - sum of old distribution pool 2998342.392799415984103501 should be 3.000.000 = totalDistributions+balanceOf(0x1F70A6Ebe74f202d1eC02124A7179fa7CE0D122f) )

        2. Upgrade the contract 
                -  initialize stakes, rewards of all accounts without exits (all except: 
                            0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E, 
                            0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c, 
                            0x1F70A6Ebe74f202d1eC02124A7179fa7CE0D122f,
                            0xB94a1473F2C418AAa06bf664C76D13685c559362 - has still registered rewards 
                -  transfer stake amount of all acounts to staking contract (where it gets locked)
                -  transfer all account balances back from distributionPool (which holds those funds too)

        3. initialize totalDistributions
                - either get all distribut events or 
                - red this variable from smart contract

        totalDistributions = 
        4. transfer stakes from distributionContract to Melalieaddress(this)
        5. transfer account balances from distributionContract bac to the acccounts 
        6. execute missing (19) distributions since #RewardDistribution 4 / 2021-07-23 
                   /* Distributed MEL: 534 
                    REST POOL: 2.998.342  MEL 
                    TOTAL STAKES: 1.924.368 MEL
                    https://polygonscan.com/tx/0x8c1110f697d01cccaaad01d2fd799b609494ba58e0b3a5b3c489421434913684 */
    
        ///7. implement the autotask with defender */
        sendMelFromDistributionPool(distributionPoolContract,2998342392799415984103501); //2.998 Million MEL to distribution contract

        // addStakeholder(0xB94a1473F2C418AAa06bf664C76D13685c559362);
        rewards[address(0xB94a1473F2C418AAa06bf664C76D13685c559362)] =  2108333333333333333; //stake and belance withdrawn - only rewards
        
        addStakeholder(0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c);   
        stakes[address(0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c)] =   1290284042557023600000; //token owner account which discovered and handeld the recovery of v1 
        rewards[address(0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c)] =     1433760047285581776;
        sendMelFromDistributionPool(address(this),1290284042557023600000);

    //0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC  12639.0
    addStakeholder(0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC);
    stakes[address(0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC)] = 12639000000000000000000;
    sendMelFromDistributionPool(address(this),12639000000000000000000);
    //0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC  14.043333333333333332
    rewards[address(0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC)] = 14043333333333333332;
    //0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC  0.091456440198947603
    sendMelFromDistributionPool(0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC,91456440198947603);

    //0xB8b58B248e975A76d147404454F6aA07d2A4E3e2  89928.9792489785
    addStakeholder(0xB8b58B248e975A76d147404454F6aA07d2A4E3e2);
    stakes[address(0xB8b58B248e975A76d147404454F6aA07d2A4E3e2)] = 89928979248978500000000;
    sendMelFromDistributionPool(address(this),89928979248978500000000);
    //0xB8b58B248e975A76d147404454F6aA07d2A4E3e2  99.921088054420555552
    rewards[address(0xB8b58B248e975A76d147404454F6aA07d2A4E3e2)] = 99921088054420555552;
    //0xB8b58B248e975A76d147404454F6aA07d2A4E3e2  0.000000000002449489
    sendMelFromDistributionPool(0xB8b58B248e975A76d147404454F6aA07d2A4E3e2,2449489);

    //0xA27B52456fb9CE5d3f2608CebDE10599A97961D5  1000.0
    addStakeholder(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5);
    stakes[address(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5)] = 1000000000000000000000;
    sendMelFromDistributionPool(address(this),1000000000000000000000);
    //0xA27B52456fb9CE5d3f2608CebDE10599A97961D5  1.111111111111111108
    rewards[address(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5)] = 1111111111111111108;
    //0xA27B52456fb9CE5d3f2608CebDE10599A97961D5  1000.0
    sendMelFromDistributionPool(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5,1000000000000000000000);

    //0xF95720db004d94922Abb904222f02bc0793b589d  4000.0
    addStakeholder(0xF95720db004d94922Abb904222f02bc0793b589d);
    stakes[address(0xF95720db004d94922Abb904222f02bc0793b589d)] = 4000000000000000000000;
    sendMelFromDistributionPool(address(this),4000000000000000000000);
    //0xF95720db004d94922Abb904222f02bc0793b589d  4.444444444444444444
    rewards[address(0xF95720db004d94922Abb904222f02bc0793b589d)] = 4444444444444444444;

    //0x3d2596AEDCfef405F04eb78C38426113d19AADda  300000.0
    addStakeholder(0x3d2596AEDCfef405F04eb78C38426113d19AADda);
    stakes[address(0x3d2596AEDCfef405F04eb78C38426113d19AADda)] = 300000000000000000000000;
    sendMelFromDistributionPool(address(this),300000000000000000000000);
    //0x3d2596AEDCfef405F04eb78C38426113d19AADda  249.999999999999999999
    rewards[address(0x3d2596AEDCfef405F04eb78C38426113d19AADda)] = 249999999999999999999;
    //0x90e0C41B5B4B769e78c740b5f0F11E61cfbDD5F9  7056.0
    sendMelFromDistributionPool(0x90e0C41B5B4B769e78c740b5f0F11E61cfbDD5F9,7056000000000000000000);
    //0xF32719Bd3683Ba776fE060B0a216B6f95Acd2805  102290.796548951105460435
    sendMelFromDistributionPool(0xF32719Bd3683Ba776fE060B0a216B6f95Acd2805,102290796548951105460435);

    //0xde9a65d3F549EDD70163795479a7c88d13DbB15C  7589.0
    addStakeholder(0xde9a65d3F549EDD70163795479a7c88d13DbB15C);
    stakes[address(0xde9a65d3F549EDD70163795479a7c88d13DbB15C)] = 7589000000000000000000;
    sendMelFromDistributionPool(address(this),7589000000000000000000);
    //0xde9a65d3F549EDD70163795479a7c88d13DbB15C  8.43222222222222222
    rewards[address(0xde9a65d3F549EDD70163795479a7c88d13DbB15C)] = 8432222222222222220;

    //0xEE02C646939F0d518a6C1DF19DCec96145347Af4  5295.0
    addStakeholder(0xEE02C646939F0d518a6C1DF19DCec96145347Af4);
    stakes[address(0xEE02C646939F0d518a6C1DF19DCec96145347Af4)] = 5295000000000000000000;
    sendMelFromDistributionPool(address(this),5295000000000000000000);
    //0xEE02C646939F0d518a6C1DF19DCec96145347Af4  1.470833333333333333
    rewards[address(0xEE02C646939F0d518a6C1DF19DCec96145347Af4)] = 1470833333333333333;

    //0x2C2ADD1C863551A0644876be227604C8E458dD7e  22000.0
    addStakeholder(0x2C2ADD1C863551A0644876be227604C8E458dD7e);
    stakes[address(0x2C2ADD1C863551A0644876be227604C8E458dD7e)] = 22000000000000000000000;
    sendMelFromDistributionPool(address(this),22000000000000000000000);
    //0x2C2ADD1C863551A0644876be227604C8E458dD7e  24.444444444444444444
    rewards[address(0x2C2ADD1C863551A0644876be227604C8E458dD7e)] = 24444444444444444444;
    //0x2C2ADD1C863551A0644876be227604C8E458dD7e  500.0
    sendMelFromDistributionPool(0x2C2ADD1C863551A0644876be227604C8E458dD7e,500000000000000000000);

    //0xa92A96fe994f7F0E73593f4d88877636aA7790Ba  7590.0
    addStakeholder(0xa92A96fe994f7F0E73593f4d88877636aA7790Ba);
    stakes[address(0xa92A96fe994f7F0E73593f4d88877636aA7790Ba)] = 7590000000000000000000;
    sendMelFromDistributionPool(address(this),7590000000000000000000);
    //0xa92A96fe994f7F0E73593f4d88877636aA7790Ba  8.433333333333333332
    rewards[address(0xa92A96fe994f7F0E73593f4d88877636aA7790Ba)] = 8433333333333333332;

    //0xA1a506bB6442d763362291076911EDBaE1222CF1  7590.0
    addStakeholder(0xA1a506bB6442d763362291076911EDBaE1222CF1);
    stakes[address(0xA1a506bB6442d763362291076911EDBaE1222CF1)] = 7590000000000000000000;
    sendMelFromDistributionPool(address(this),7590000000000000000000);
    //0xA1a506bB6442d763362291076911EDBaE1222CF1  8.433333333333333332
    rewards[address(0xA1a506bB6442d763362291076911EDBaE1222CF1)] = 8433333333333333332;

    //0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064  7590.0
    addStakeholder(0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064);
    stakes[address(0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064)] = 7590000000000000000000;
    sendMelFromDistributionPool(address(this),7590000000000000000000);
    //0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064  8.433333333333333332
    rewards[address(0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064)] = 8433333333333333332;

    //0x65d55B28264131473Fa09BA9e0403350952aC1ce  40083.0
    addStakeholder(0x65d55B28264131473Fa09BA9e0403350952aC1ce);
    stakes[address(0x65d55B28264131473Fa09BA9e0403350952aC1ce)] = 40083000000000000000000;
    sendMelFromDistributionPool(address(this),40083000000000000000000);
    //0x65d55B28264131473Fa09BA9e0403350952aC1ce  11.134166666666666666
    rewards[address(0x65d55B28264131473Fa09BA9e0403350952aC1ce)] = 11134166666666666666;
    //0x65d55B28264131473Fa09BA9e0403350952aC1ce  22.268333333333333332
    sendMelFromDistributionPool(0x65d55B28264131473Fa09BA9e0403350952aC1ce,22268333333333333332);
    //0x2a61D756637e7cEB89076947800EB5CC52624c9b  7590.0
    sendMelFromDistributionPool(0x2a61D756637e7cEB89076947800EB5CC52624c9b,7590000000000000000000);

    //0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35  11010.0
    addStakeholder(0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35);
    stakes[address(0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35)] = 11010000000000000000000;
    sendMelFromDistributionPool(address(this),11010000000000000000000);
    //0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35  3.058333333333333333
    rewards[address(0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35)] = 3058333333333333333;

    //0x012601876006aFa5EDaED3C75275689Aa71D8cD2  42461.0
    addStakeholder(0x012601876006aFa5EDaED3C75275689Aa71D8cD2);
    stakes[address(0x012601876006aFa5EDaED3C75275689Aa71D8cD2)] = 42461000000000000000000;
    sendMelFromDistributionPool(address(this),42461000000000000000000);
    //0x012601876006aFa5EDaED3C75275689Aa71D8cD2  47.178888888888888888
    rewards[address(0x012601876006aFa5EDaED3C75275689Aa71D8cD2)] = 47178888888888888888;

    //0x09A84adF034E5901B80e68508E4FDc7931D9a7C9  4000.0
    addStakeholder(0x09A84adF034E5901B80e68508E4FDc7931D9a7C9);
    stakes[address(0x09A84adF034E5901B80e68508E4FDc7931D9a7C9)] = 4000000000000000000000;
    sendMelFromDistributionPool(address(this),4000000000000000000000);
    //0x09A84adF034E5901B80e68508E4FDc7931D9a7C9  1.111111111111111111
    rewards[address(0x09A84adF034E5901B80e68508E4FDc7931D9a7C9)] = 1111111111111111111;
    //0x6ec04CBe2f8e192d8df0BCf94aFb58A4094F7C91  3201.0
    sendMelFromDistributionPool(0x6ec04CBe2f8e192d8df0BCf94aFb58A4094F7C91,3201000000000000000000);

    //0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA  6208.16772
    addStakeholder(0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA);
    stakes[address(0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA)] = 6208167720000000000000;
    sendMelFromDistributionPool(address(this),6208167720000000000000);
    //0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA  3.448982066666666666
    rewards[address(0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA)] = 3448982066666666666;

    //0x7d7D8baee84bCA250fa1A61813EC2322f9f88751  2000.0
    addStakeholder(0x7d7D8baee84bCA250fa1A61813EC2322f9f88751);
    stakes[address(0x7d7D8baee84bCA250fa1A61813EC2322f9f88751)] = 2000000000000000000000;
    sendMelFromDistributionPool(address(this),2000000000000000000000);
    //0x7d7D8baee84bCA250fa1A61813EC2322f9f88751  2.22222222222222222
    rewards[address(0x7d7D8baee84bCA250fa1A61813EC2322f9f88751)] = 2222222222222222220;

    //0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C  88755.0
    addStakeholder(0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C);
    stakes[address(0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C)] = 88755000000000000000000;
    sendMelFromDistributionPool(address(this),88755000000000000000000);
    //0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C  65.419444444444444443
    rewards[address(0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C)] = 65419444444444444443;
    //0x189Bf18FD03edfE7046D03eA2f3A563366A3f48E  51000.0
    sendMelFromDistributionPool(0x189Bf18FD03edfE7046D03eA2f3A563366A3f48E,51000000000000000000000);

    //0x34062Df52BA70F88868377159c849A43ba89e21F  6072.0
    addStakeholder(0x34062Df52BA70F88868377159c849A43ba89e21F);
    stakes[address(0x34062Df52BA70F88868377159c849A43ba89e21F)] = 6072000000000000000000;
    sendMelFromDistributionPool(address(this),6072000000000000000000);
    //0x34062Df52BA70F88868377159c849A43ba89e21F  5.059999999999999998
    rewards[address(0x34062Df52BA70F88868377159c849A43ba89e21F)] = 5059999999999999998;

    //0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414  5335.0
    addStakeholder(0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414);
    stakes[address(0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414)] = 5335000000000000000000;
    sendMelFromDistributionPool(address(this),5335000000000000000000);
    //0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414  4.445833333333333332
    rewards[address(0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414)] = 4445833333333333332;
    //0x4A52b132a00330fa03c87a563D7909A38d8afee8  272202.637672010812245853
    sendMelFromDistributionPool(0x4A52b132a00330fa03c87a563D7909A38d8afee8,272202637672010812245853);

    //0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6  93000.0
    addStakeholder(0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6);
    stakes[address(0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6)] = 93000000000000000000000;
    sendMelFromDistributionPool(address(this),93000000000000000000000);
    //0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6  77.499999999999999999
    rewards[address(0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6)] = 77499999999999999999;
    //0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6  119.425447074028542367
    sendMelFromDistributionPool(0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6,119425447074028542367);

    //0x35969973D0C9015183B4591692866319b0227c63  2000.0
    addStakeholder(0x35969973D0C9015183B4591692866319b0227c63);
    stakes[address(0x35969973D0C9015183B4591692866319b0227c63)] = 2000000000000000000000;
    sendMelFromDistributionPool(address(this),2000000000000000000000);
    //0x35969973D0C9015183B4591692866319b0227c63  1.666666666666666665
    rewards[address(0x35969973D0C9015183B4591692866319b0227c63)] = 1666666666666666665;

    //0xa4804e097552867c442Bc42B5Ac17810dB8518b6  5335.0
    addStakeholder(0xa4804e097552867c442Bc42B5Ac17810dB8518b6);
    stakes[address(0xa4804e097552867c442Bc42B5Ac17810dB8518b6)] = 5335000000000000000000;
    sendMelFromDistributionPool(address(this),5335000000000000000000);
    //0xa4804e097552867c442Bc42B5Ac17810dB8518b6  4.445833333333333332
    rewards[address(0xa4804e097552867c442Bc42B5Ac17810dB8518b6)] = 4445833333333333332;

    //0x533a04903DADe8B86cC01FCb29204d273fc9f9B9  77262.06990363817
    addStakeholder(0x533a04903DADe8B86cC01FCb29204d273fc9f9B9);
    stakes[address(0x533a04903DADe8B86cC01FCb29204d273fc9f9B9)] = 77262069903638170000000;
    sendMelFromDistributionPool(address(this),77262069903638170000000);
    //0x533a04903DADe8B86cC01FCb29204d273fc9f9B9  64.385058253031808333
    rewards[address(0x533a04903DADe8B86cC01FCb29204d273fc9f9B9)] = 64385058253031808333;
    //0x533a04903DADe8B86cC01FCb29204d273fc9f9B9  0.000000000002252811
    sendMelFromDistributionPool(0x533a04903DADe8B86cC01FCb29204d273fc9f9B9,2252811);
    
    
    //0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D  51411.877275152098120059
    addStakeholder(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D);
    stakes[address(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D)] = 51411877275152098120059;
    sendMelFromDistributionPool(address(this),51411877275152098120059);
    // sendMelFromDistributionPool(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D,51411877275152098120059); //he didn't stake but was waiting for it the whole time

    //0x8Bb9ac4086df14f7977DA0537367E312618A1480  102218.65
    addStakeholder(0x8Bb9ac4086df14f7977DA0537367E312618A1480);
    stakes[address(0x8Bb9ac4086df14f7977DA0537367E312618A1480)] = 102218650000000000000000;
    sendMelFromDistributionPool(address(this),102218650000000000000000);
    //0x8Bb9ac4086df14f7977DA0537367E312618A1480  28.394069444444444444
    rewards[address(0x8Bb9ac4086df14f7977DA0537367E312618A1480)] = 28394069444444444444;
    //0x8Bb9ac4086df14f7977DA0537367E312618A1480  0.000723809394329539
    sendMelFromDistributionPool(0x8Bb9ac4086df14f7977DA0537367E312618A1480,723809394329539);
    //0xe85Ee15145bF0c8155A7Dfa0f200e8f497104aFD  6262.020240979984765333
    sendMelFromDistributionPool(0xe85Ee15145bF0c8155A7Dfa0f200e8f497104aFD,6262020240979984765333);

    //0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1  5335.0
    addStakeholder(0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1);
    stakes[address(0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1)] = 5335000000000000000000;
    sendMelFromDistributionPool(address(this),5335000000000000000000);
    //0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1  2.963888888888888888
    rewards[address(0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1)] = 2963888888888888888;

    //0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab  58762.0
    addStakeholder(0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab);
    stakes[address(0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab)] = 58762000000000000000000;
    sendMelFromDistributionPool(address(this),58762000000000000000000);
    //0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab  32.645555555555555554
    rewards[address(0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab)] = 32645555555555555554;

    //0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718  14039.215674629722
    addStakeholder(0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718);
    stakes[address(0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718)] = 14039215674629722000000;
    sendMelFromDistributionPool(address(this),14039215674629722000000);
    //0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718  3.899782131841589444
    rewards[address(0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718)] = 3899782131841589444;
    //0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718  0.000000000001007319
    sendMelFromDistributionPool(0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718,1007319);

    //0xba20aD613983407ad50557c60773494A438f7A8a  8547.843502034111
    addStakeholder(0xba20aD613983407ad50557c60773494A438f7A8a);
    stakes[address(0xba20aD613983407ad50557c60773494A438f7A8a)] = 8547843502034111000000;
    sendMelFromDistributionPool(address(this),8547843502034111000000);
    //0xba20aD613983407ad50557c60773494A438f7A8a  2.374400972787253055
    rewards[address(0xba20aD613983407ad50557c60773494A438f7A8a)] = 2374400972787253055;
    //0xba20aD613983407ad50557c60773494A438f7A8a  0.000000000001115894
    sendMelFromDistributionPool(0xba20aD613983407ad50557c60773494A438f7A8a,1115894);
    //0x20D525051A2017CB043a351621cbb9B6b61f98B9  3301.812402020496251436
    sendMelFromDistributionPool(0x20D525051A2017CB043a351621cbb9B6b61f98B9,3301812402020496251436);

    //0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B  39500.0
    addStakeholder(0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B);
    stakes[address(0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B)] = 39500000000000000000000;
    sendMelFromDistributionPool(address(this),39500000000000000000000);
    //0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B  173.763254866049063816
    sendMelFromDistributionPool(0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B,173763254866049063816);
    
    totalDistributions = 1657607200584015896499;
    autostake=true;
    }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner{
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    function updateDistributionPool(address _distributionPoolContract) external onlyOwner {
        require(_distributionPoolContract != address(0), "Bad distributionPoolContract address");
        distributionPoolContract = _distributionPoolContract;
    }

    /**
     * @notice Owner should but able to change the address which is allowed to distribute rewards
     * function: distributeRewardsPercentageFromPool (uint256 _percentagePerYear)
     */
    function updateRewardDistributor(address _rewardDistributor) external onlyOwner {
        rewardDistributor = _rewardDistributor;
    }

    /**
     * @notice setAutoStake true/false
     */
    function updateAutoStake(bool _autostake) external onlyOwner {
        autostake = _autostake;
    }


   /**
    * @notice as the token bridge calls this function, 
    * we mint the amount to the users balance and 
    * immediately creating a stake with this amount.
    * 
    * The latter function is getting removed as we get more functionality onto this contract
    */
    function deposit(address user, bytes calldata depositData) external whenNotPaused {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
        
        if(autostake)
            createStake(user,amount);
    }

   /**
    * @notice Withdraw just burns the amount which triggers the POS-bridge.
    * After the next checkpoint the amount can be withrawn on Ethereum
    */
    function withdraw(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    // ---------- STAKES ----------
    /**
     * Updates minimum Stake - only owner can do
    */
    function updateMinimumStake(uint256 newMinimumStake) public onlyOwner {
        minimumStake = newMinimumStake;
    }

    /**
     * @notice A method to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public whenNotPaused
    {
        createStake(msg.sender, _stake);
    }

    /**
    * @notice A method to create a stake from anybody for anybody. 
    * The transfered amount gets locked at this contract.

    * @param _stakeHolder The address of the beneficiary stake holder 
    * @param _stake The size of the stake to be created.
    */
    function createStake(address _stakeHolder, uint256 _stake)
        private whenNotPaused
    {
        require((_stakeHolder == msg.sender || msg.sender == childChainManagerProxy), "stakeholder must be msg.sender");
        require(_stake >= minimumStake, "Minimum Stake not reached");
        
        if(stakes[_stakeHolder] == 0) addStakeholder(_stakeHolder);
        stakes[_stakeHolder] = stakes[_stakeHolder].add(_stake);

        //we lock the stake amount in this contract 
        _transfer(_stakeHolder,address(this), _stake);
        emit StakeCreated(_stakeHolder, _stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake. Amount gets unlocked from this contract
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake)
        public whenNotPaused
    { 
        require(_stake >= minimumStake, "Minimum Stake not reached");
        stakes[msg.sender] = stakes[msg.sender].sub(_stake); //if unstake amount is negative an error is thrown
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        //when removing a stake we unlock the stake from this contract and give it back to the owner 
        _transfer(address(this), msg.sender, _stake);
        emit StakeRemoved(msg.sender, _stake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     * @param _amount The amount to be distributed
     */
    function calculateReward(address _stakeholder,uint256 _amount)
        public
        view
        returns(uint256)
    {
        return (stakes[_stakeholder] * _amount).div(totalStakes());
    }

    /**
     * @notice The method to distribute rewards based on a percentage per year to all stakeholders from 
     * the distribution contract account funds in MEL (the distribution pool)
     * We distribute it daily. 10% - is divided by 360. 
     * 
     * We distribute (register a reward) then from the current total stakes the daily percentage.
     * Only rewardDistributor account is allowed to execute
     * 
     */
    function distributeRewardsPercentageFromPool(uint256 _percentagePerYear) public whenNotPaused
    {   
        require((rewardDistributor == msg.sender), "only reward distributor is allowed");
        
        uint256 _distributionAmount = (totalStakes() * _percentagePerYear).div(360*100);
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder,_distributionAmount);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
        totalDistributions+=_distributionAmount;
        emit RewardsDistributed(_distributionAmount);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public whenNotPaused
    {
        uint256 reward = rewards[msg.sender];
        _transfer(distributionPoolContract, msg.sender, reward);

        rewards[msg.sender] = 0;
        emit RewardWithdrawn(msg.sender,reward);
    }
        
    /**
     *  @notice 
     * - the owner of this smart contract should be able to transfer MelalieToken from this contract
     * - doing so he could use the staked tokens for important goals 
     */
    function sendMel(address recipient,uint256 amount) public onlyOwner {
        _transfer(address(this), recipient, amount);
    }

    /**
     * @notice 
     * the owner of this smart contract should be able to transfer MelalieToken 
     * from the distribution pool contract
     */
    function sendMelFromDistributionPool(address recipient, uint256 amount) public onlyOwner {
        _transfer(address(distributionPoolContract), recipient, amount);
    }

    /**
     * @notice The owner of this smart contract should be able to transfer ETH 
     * to any other address from this contract address
     */
    function sendEther(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
       _unpause();
    }

    /**
    *  @notice This smart contract should be able to receive ETH and other tokens.
    */
    receive() payable external {}
}


// File contracts/child/MelalieStakingTokenUpgradableV2_1.sol

pragma solidity ^0.8.0;



contract MelalieStakingTokenUpgradableV2_1 is MelalieStakingTokenUpgradableV2
{

bool private _upgradedV2_1;
using SafeMathUpgradeable for uint256;

 function upgradeV2_1() public {
    require(!_upgradedV2_1, "MelalieStakingTokenUpgradableV2_1: already upgraded");

    uint256 rewardManual01 = 1290284042557023600000;
    rewards[0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c] = rewards[0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c] + rewardManual01*10/100/360*32;

    uint256 rewardManual02 = 51411877275152098120059;
    rewards[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D] = rewards[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D] + rewardManual02*10/100/360*32;
    
    rewards[0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC] = rewards[0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC] + 112346666666666666656;
    rewards[0xB8b58B248e975A76d147404454F6aA07d2A4E3e2] = rewards[0xB8b58B248e975A76d147404454F6aA07d2A4E3e2] + 799368704435364444416;
    rewards[0xA27B52456fb9CE5d3f2608CebDE10599A97961D5] = rewards[0xA27B52456fb9CE5d3f2608CebDE10599A97961D5] + 8888888888888888864;
    rewards[0xF95720db004d94922Abb904222f02bc0793b589d] = rewards[0xF95720db004d94922Abb904222f02bc0793b589d] + 35555555555555555552;
    rewards[0x3d2596AEDCfef405F04eb78C38426113d19AADda] = rewards[0x3d2596AEDCfef405F04eb78C38426113d19AADda] + 2666666666666666666656;
    rewards[0xde9a65d3F549EDD70163795479a7c88d13DbB15C] = rewards[0xde9a65d3F549EDD70163795479a7c88d13DbB15C] + 67457777777777777760;
    rewards[0xEE02C646939F0d518a6C1DF19DCec96145347Af4] = rewards[0xEE02C646939F0d518a6C1DF19DCec96145347Af4] + 47066666666666666656;
    rewards[0x2C2ADD1C863551A0644876be227604C8E458dD7e] = rewards[0x2C2ADD1C863551A0644876be227604C8E458dD7e] + 195555555555555555552;
    rewards[0xa92A96fe994f7F0E73593f4d88877636aA7790Ba] = rewards[0xa92A96fe994f7F0E73593f4d88877636aA7790Ba] + 67466666666666666656;
    rewards[0xA1a506bB6442d763362291076911EDBaE1222CF1] = rewards[0xA1a506bB6442d763362291076911EDBaE1222CF1] + 67466666666666666656;
    rewards[0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064] = rewards[0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064] + 67466666666666666656;
    rewards[0x65d55B28264131473Fa09BA9e0403350952aC1ce] = rewards[0x65d55B28264131473Fa09BA9e0403350952aC1ce] + 356293333333333333312;
    rewards[0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35] = rewards[0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35] + 97866666666666666656;
    rewards[0x012601876006aFa5EDaED3C75275689Aa71D8cD2] = rewards[0x012601876006aFa5EDaED3C75275689Aa71D8cD2] + 377431111111111111104;
    rewards[0x09A84adF034E5901B80e68508E4FDc7931D9a7C9] = rewards[0x09A84adF034E5901B80e68508E4FDc7931D9a7C9] + 35555555555555555552;
    rewards[0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA] = rewards[0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA] + 55183713066666666656;
    rewards[0x7d7D8baee84bCA250fa1A61813EC2322f9f88751] = rewards[0x7d7D8baee84bCA250fa1A61813EC2322f9f88751] + 17777777777777777760;
    rewards[0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C] = rewards[0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C] + 788933333333333333312;
    rewards[0x34062Df52BA70F88868377159c849A43ba89e21F] = rewards[0x34062Df52BA70F88868377159c849A43ba89e21F] + 53973333333333333312;
    rewards[0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414] = rewards[0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414] + 47422222222222222208;
    rewards[0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6] = rewards[0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6] + 826666666666666666656;
    rewards[0x35969973D0C9015183B4591692866319b0227c63] = rewards[0x35969973D0C9015183B4591692866319b0227c63] + 17777777777777777760;
    rewards[0xa4804e097552867c442Bc42B5Ac17810dB8518b6] = rewards[0xa4804e097552867c442Bc42B5Ac17810dB8518b6] + 47422222222222222208;
    rewards[0x533a04903DADe8B86cC01FCb29204d273fc9f9B9] = rewards[0x533a04903DADe8B86cC01FCb29204d273fc9f9B9] + 686773954699005955552;
    rewards[0x8Bb9ac4086df14f7977DA0537367E312618A1480] = rewards[0x8Bb9ac4086df14f7977DA0537367E312618A1480] + 908610222222222222208;
    rewards[0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1] = rewards[0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1] + 47422222222222222208;
    rewards[0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab] = rewards[0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab] + 522328888888888888864;
    rewards[0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718] = rewards[0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718] + 124793028218930862208;
    rewards[0xba20aD613983407ad50557c60773494A438f7A8a] = rewards[0xba20aD613983407ad50557c60773494A438f7A8a] + 75980831129192097760;
    
    autostake = true;
    _upgradedV2_1 = true;
 }

 function version() public virtual pure returns (string memory){ //override
     return "2.1.0";
 }
}