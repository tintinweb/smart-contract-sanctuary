/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

//SPDX-License-Identifier: Unlicense

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;


/**
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

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
}

// File: @openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: contracts/LaunchVerse.sol

pragma solidity ^0.8.5;







contract LaunchVerse is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct Order {
        uint256 amountRIR;
        uint256 amountBUSD;
        address referer;
        uint256 approvedBUSD;
        uint256 refundedBUSD;
        uint256 claimedToken;
    }


    // List of subscriber who prefund to Pool
    mapping(address => Order) public subscription; 
    address[] public subscribers;
    uint256 public totalSubBUSD;
    uint256 public totalSubRIR;
    function subscriptionCount() public view returns (uint) {
        return subscribers.length;
    }

    // List of winner address and count
    address[] public winners;
    function winCount() public view returns (uint) {
        return winners.length;
    }

    // deposited token
    uint256 public totalTokenDeposited;

    event DepositEvent(
        uint256 amount,
        uint256 timestamp
    );

    event SubscriptionEvent(
        uint256 amountRIR,
        uint256 amountBUSD,
        address indexed referer,
        address indexed buyer,
        uint256 timestamp
    );

    uint256 public startDate; /* Start Date  - https://www.epochconverter.com/ */
    uint256 public endDate; /* End Date - https://www.epochconverter.com/ */
    uint256 public individualMinimumAmountBusd; /* Minimum Amount Per Address */
    uint256 public individualMaximumAmountBusd; /* Minimum Amount Per Address */
    uint256 public tokenPrice; /* Token price */
    uint256 public bUSDForSale; /* Total Raising fund */
    uint256 public rate; /* 1 RIR = 100 BUSD */
    uint256 public tokenFee; /* Platform fee, token keep to platform. Should be zero */

    uint256 public totalRIRAllocation; /* Maximum RIR can be used for all, by default is 80% of sale allocation */

    address public WITHDRAW_ADDRESS; /* Address to cashout */

    uint256 public bUSDAllocated; /* Total Tokens Approved */

    ERC20 public tokenAddress; /* Address of token to be sold */
    ERC20 public bUSDAddress; /* Address of bUSD */
    ERC20 public rirAddress; /* Address of RIR */

    
    /* Admins List */
    mapping(address => bool) public admins;

    /* State variables */
    bool private isTokenAddressSet;
    bool public isCommit;
    bool public isWithdrawBusd;
    bool public isWithdrawAddressSet;



    function initialize(
        /* address _tokenAddress, */ // Will setup later, not available at the Pool start
        address _bUSDAddress,
        address _rirAddress,
        uint256 _tokenPrice, // Price Token (Ex: 1 TOKEN = 0.01 BUSD)
        uint256 _bUSDForSale,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _individualMinimumAmountBusd,
        uint256 _individualMaximumAmountBusd,
        uint256 _tokenFee
    ) public initializer {
        __Ownable_init();
        __Pausable_init();

        require(_startDate < _endDate, "End Date higher than Start Date");

        require(_tokenPrice > 0, "Price token of project should be > 0");

        require(_bUSDForSale > 0, "BUSD for Sale should be > 0");

        require(
            _individualMinimumAmountBusd > 0,
            "Individual Minimum Amount Busd should be > 0"
        );

        require(
            _individualMaximumAmountBusd > 0,
            "Individual Maximim Amount Busd should be > 0"
        );

        require(
            _individualMaximumAmountBusd >= _individualMinimumAmountBusd,
            "Individual Maximim Amount should be > Individual Minimum Amount"
        );

        require(_bUSDForSale >= _individualMinimumAmountBusd);

        startDate = _startDate;
        endDate = _endDate;
        bUSDForSale = _bUSDForSale;
        tokenPrice = _tokenPrice;
        bUSDAllocated = 0;
        rate = 100;
        tokenFee = _tokenFee;
        isCommit = false;
        
        // for widthdraw BUSD
        isWithdrawBusd = false;
        // WITHDRAW_ADDRESS = 0xdDDDbebEAD284030Ba1A59cCD99cE34e6d5f4C96; // should not change

        individualMinimumAmountBusd = _individualMinimumAmountBusd;
        individualMaximumAmountBusd = _individualMaximumAmountBusd;

        // tokenAddress = ERC20(_tokenAddress); // 
        bUSDAddress = ERC20(_bUSDAddress);
        rirAddress = ERC20(_rirAddress);

        // Default total RIR allocation: 80% of sale allocation
        totalRIRAllocation = bUSDForSale.div(rate).mul(80).div(100);

        // Grant admin role to a owner
        admins[owner()] = true;
    }


    /**
     * MODIFIERS
     */
    modifier winEmpty() {
        require(winners.length == 0, "Wins need empty");
        require(winCount() == 0, "Wins need empty");
        _;
    }

    modifier onlyUncommit() {
        require(!isCommit, "Wins is verifyed");
        _;
    }

    modifier onlyCommit() {
        require(isCommit, "Wins not verifyed");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Caller is not an approved user");
        _;
    }

    modifier onlyUnwithdrawBusd() {
        require(!isWithdrawBusd, "You have withdrawn Busd");
        _;
    }

    /* State for setup Token Address */
    modifier onlyTokenNotSet() {
        require(!isTokenAddressSet, "Token Address has set already");
        _;
    }
    modifier onlyTokenSet() {
        require(isTokenAddressSet, "Token Address has not set");
        _;
    }
    
    /* State for setup WITHDRAW Address */
    modifier onlyWithdrawAddressNotSet() {
        require(!isWithdrawAddressSet, "Token Address has set already");
        _;
    }
    modifier onlyWithdrawAddressSet() {
        require(isWithdrawAddressSet, "Token Address has not set");
        _;
    }
    


    /*
     * INTERNAL Funtions
    */
    function _tokenDeduceFee(uint256 numOfToken) internal view returns (uint256) {
        if (tokenFee <= 0) return numOfToken;
        uint256 cent = 100;
        return numOfToken.mul(cent.mul(1e18) - tokenFee).div(cent.mul(1e18));
    }

    /* Check if all RIR prefunders in Winner List */
    function verifySubWinnerHasRIR() internal view returns (bool) {
        bool _isVerify = true;
        for (uint256 i = 0; i < subscribers.length; i++) {
            address _subscriber = subscribers[i];
            Order memory _order = subscription[_subscriber];
            if (_order.amountRIR > 0) {
                if (!this.isWinner(_subscriber)) {
                    _isVerify = false;
                }
            }
        }
        return _isVerify;
    }

    /**
     *   GETTER Functions
     */
    
    /* not win fund, then need refund to subscribers */
    function bUSDLeft() external view returns (uint256) {
        return bUSDForSale - bUSDAllocated;
    }

    /* Get List Subscribers address */
    function getSubscribers() external view returns (address[] memory) {
        return subscribers;
    }

    /* Get List Winners address */
    function getWinners() external view returns (address[] memory) {
        return winners;
    }

    /* Get Order Of Subscriber */
    function getOrderSubscriber(address _address)
        external
        view
        returns (Order memory)
    {
        return subscription[_address];
    }

    function minimumAmountBusd() public view returns (uint256) {
        return individualMinimumAmountBusd;
    }
    function maximumAmountBusd() public view returns (uint256) {
        return individualMaximumAmountBusd;
    }
    function getTotalTokenForSale() public view returns (uint256) {
        return _tokenDeduceFee(bUSDForSale.div(tokenPrice).mul(1e18));
    }
    function getTotalTokenSold() public view returns (uint256) {
        return _tokenDeduceFee(bUSDAllocated.div(tokenPrice).mul(1e18));
    }

    /**
     * Check Buyer is Subscriber - just check in the subscription list
     **/
    function isSubscriber(address _address) external view returns (bool) {
        return subscription[_address].amountBUSD != 0;
    }

    /**
     * Check Buyer is Winner - just check in the winners list
     **/
    function isWinner(address _address) external view returns (bool) {
        return subscription[_address].approvedBUSD > 0;
    }

    function isBuyerHasRIR(address buyer) external view returns (bool) {
        return rirAddress.balanceOf(buyer) > 0;
    }

    function getTotalBusdWinners() internal view returns (uint256) {
        return bUSDAllocated;
    }

    function balanceTokens() public view returns (uint256) {
        return tokenAddress.balanceOf(address(this));
    }

    function balanceBusd() external view returns (uint256) {
        return bUSDAddress.balanceOf(address(this));
    }

    function balanceRIR() external view returns (uint256) {
        return rirAddress.balanceOf(address(this));
    }


    /**
     * MAIN Functions
     */
    
    /* Create Subscription */
    function createSubscription(
        uint256 _amountBusd,
        uint256 _amountRIR,
        address _referer
    ) public payable virtual {

        // require project is open and not expire
        require(block.timestamp <= endDate, "The Pool has been expired");
        require(block.timestamp >= startDate, "The Pool have not started");

        // amount cannot be negative
        require(_amountBusd >= 0, "Amount BUSD is not valid");
        require(_amountRIR >= 0, "Amount RIR is not valid");
        // and at least one is positive
        require(_amountBusd > 0 || _amountRIR > 0, "Amount is not valid");

        // cannot out of bound 
        require(
            maximumAmountBusd() >=
                subscription[msg.sender].amountBUSD + _amountBusd,
            "Amount is overcome maximum"
        );
        require(
            minimumAmountBusd() <=
                subscription[msg.sender].amountBUSD + _amountBusd,
            "Amount is overcome minimum"
        );

        if (!this.isSubscriber(msg.sender)) {
            // first time, need add to subscribers address list and count
            // do we need check and init subscription[msg.sender] = Order ?
            subscribers.push(msg.sender);
        }

        if (_amountRIR > 0) {
            require(
                rirAddress.balanceOf(msg.sender) >= _amountRIR,
                "You dont have enough RIR Token"
            );

            // check if over RIR allocation fill
            require(
                totalSubRIR + _amountRIR <= totalRIRAllocation,
                "Eceeds Total RIR Allocation"
            );

            // Prevent misunderstanding: only RIR is enough
            // (_amountRIR + subscription[msg.sender].amountRIR).mul(rate) <= need include prefunded RIR
            require(
                subscription[msg.sender].amountRIR.add(_amountRIR).mul(rate) <=
                    subscription[msg.sender].amountBUSD + _amountBusd,
                "Amount is not valid"
            );

            require(
                rirAddress.transferFrom(msg.sender, address(this), _amountRIR),
                "RIR transfer failed"
            );

            subscription[msg.sender].amountRIR += _amountRIR;
            // update total RIR
            totalSubRIR += _amountRIR;
        }

        if (_amountBusd > 0) {
            require(
                bUSDAddress.transferFrom(
                    msg.sender,
                    address(this),
                    _amountBusd
                ),
                "Transfer BUSD fail"
            );

            subscription[msg.sender].amountBUSD += _amountBusd;
            // update total
            totalSubBUSD += _amountBusd;
        }

        // check referer if not set
        if (_referer != address(0) && subscription[msg.sender].referer == address(0)) {
            subscription[msg.sender].referer = _referer;
        }

        emit SubscriptionEvent(
            _amountRIR,
            _amountBusd,
            _referer,
            msg.sender,
            block.timestamp
        );
    }


    /**
        Claim totken
     */
    function getTotalTokenForWinner(address _winner) public view returns (uint256)  {
        Order memory _winnerOrder = subscription[_winner];
        return _winnerOrder.approvedBUSD.mul(getTotalTokenForSale()).div(bUSDForSale);
    }
    
    function getClaimable(address _address) public view returns (uint256[2] memory) {
        uint256[2] memory claimable;
        Order memory _order = subscription[_address];
        // check if available busd to refund
        claimable[0] = _order.amountBUSD - _order.approvedBUSD - _order.refundedBUSD;

        // check if available token to claim
        if (isTokenAddressSet) {
            uint256 _deposited =  totalTokenDeposited;
            uint256 _maxDeposited = getTotalTokenForSale();
            if (_deposited > _maxDeposited) _deposited = _maxDeposited; // cannot eceeds total sale token

            uint256 _tokenClaimable = _order.approvedBUSD.mul(_deposited).div(bUSDForSale);
            claimable[1] = _tokenClaimable.sub(_order.claimedToken);
        }
        return claimable;
    }

    function claim() external payable onlyCommit {
        uint256[2] memory claimable = getClaimable(msg.sender);
        if (claimable[0] > 0) {
            require(bUSDAddress.balanceOf(address(this)) >= claimable[0], "BUSD Not enough");
            // available claim busd
            require(
                bUSDAddress.transfer(msg.sender, claimable[0]),
                "ERC20 transfer failed - claim refund"
            );

            // update refunded
            subscription[msg.sender].refundedBUSD = claimable[0];
        }
        if (isTokenAddressSet && claimable[1] > 0) {
            // make sure not out of max
            require(getTotalTokenForWinner(msg.sender) >= subscription[msg.sender].claimedToken + claimable[1], "Cannot claim more token than approved");
            // available claim busd
            require(tokenAddress.balanceOf(address(this)) >= claimable[1], "Not enough token");
            require(
                tokenAddress.transfer(msg.sender, claimable[1]),
                "ERC20 transfer failed - claim token"
            );
            // update claimed token
            subscription[msg.sender].claimedToken += claimable[1];
        }
    }


    /**
     * ADMIN FUNCTIONS
     */
    /*
    /* Deposit Token by admin
    */
    function deposit(uint256 _amount) external payable onlyTokenSet onlyAdmin {
        require(_amount > 0, "Amount has to be positive");
        require(
            tokenAddress.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        // update total deposited token
        totalTokenDeposited += _amount;

        emit DepositEvent(_amount, block.timestamp);
    }

    /**
     * Import Winners by Admin
     **/
    function importWinners(
        address[] calldata _address,
        uint256[] calldata _approvedBusd
    ) external virtual onlyAdmin winEmpty {
        uint256 _bUSDAllocated = 0;

        for (uint256 i = 0; i < _address.length; i++) {
            _bUSDAllocated += _approvedBusd[i];

            // should put buyer address into error message
            require(this.isSubscriber(_address[i]), "Buyer is not subscriber");

            require(
                !this.isWinner(_address[i]),
                "Buyer already exists in the list"
            );

            require(_approvedBusd[i] > 0, "Amount has to be positive");

            // need require less than his prefund amount
            require(
                _approvedBusd[i] <= subscription[_address[i]].amountBUSD,
                "Approved BUSD exceed the amount for a buyer"
            );

            // update approveBUSD
            subscription[_address[i]].approvedBUSD = _approvedBusd[i];

            // push into winners list address and increase count
            winners.push(_address[i]);
        }

        require(
            bUSDForSale >= _bUSDAllocated,
            "Approved BUSD exceed the amount for sale"
        );

        // check if all RIR holder are in winners list
        require(verifySubWinnerHasRIR(), "Some RIR investers are not in winners list");

        // make sure maximize total approved
        if (totalSubBUSD >= bUSDForSale) {
            // oversub, then the approved amount need full
            require(_bUSDAllocated == bUSDForSale, "Sale is not fullfill");
        } else {
            // sub less than tota raising, fullfill all sub
            require(_bUSDAllocated == totalSubBUSD, "Sub is not fullfill");
        }

        // update bUSDAllocated
        bUSDAllocated = _bUSDAllocated;
    }

    /**
     * Reset Winner List to make new Import
     **/
    function setEmptyWins() external onlyAdmin onlyUncommit {
        require(winCount() > 0);
        require(winners.length > 0);
        for (uint256 i = 0; i < subscribers.length; i++) {
            address _address = subscribers[i];
            // just reset approvedBUSD
            if (subscription[_address].approvedBUSD != 0) {
                subscription[_address].approvedBUSD = 0;
            }
        }

        // reset winners and allocated
        delete winners;
        delete bUSDAllocated;
    }

    /* Setup Token Address */
    function setTokenAddress(address _tokenAddress) external onlyTokenNotSet onlyAdmin {
        tokenAddress = ERC20(_tokenAddress); 
    }
    /* Setup Token Address */
    function setWithdrawAddress(address _withdrawAddress) external onlyWithdrawAddressNotSet onlyAdmin {
        WITHDRAW_ADDRESS = _withdrawAddress;
    }


    /**
     * OWNER FUNCTIONS
     */

    /* Admin role who can handle winner list, deposit token */
    function setAdmin(address _adminAddress, bool _allow) public onlyOwner {
        admins[_adminAddress] = _allow;
    }    

    /* 
    /* Admin withdraw token remain
    /* require total token deposit > total token of winners
    */
    function getUnsoldTokens() public view onlyOwner onlyCommit returns (uint256) {
        // get total claimed token
        uint256 _totalClaimedToken;
        for (uint256 i = 0; i < subscribers.length; i++) {
            _totalClaimedToken += subscription[subscribers[i]].claimedToken;
        }
        uint256 _tokenBalance = balanceTokens();
        uint256 _remain = _tokenBalance.add(_totalClaimedToken).sub(getTotalTokenSold());
        return _remain > 0 ? _remain : 0;
    }

    function withdrawUnsoldTokens() external payable onlyOwner onlyCommit onlyTokenSet onlyWithdrawAddressSet {
        uint256 _remain = getUnsoldTokens();
        require(_remain > 0, "No remain token");
        require(tokenAddress.transfer(WITHDRAW_ADDRESS, _remain), "ERC20 Cannot widthraw remaining token");
    }

    /* Admin Withdraw BUSD */
    function withdrawBusdFunds() external virtual onlyOwner onlyCommit onlyUnwithdrawBusd onlyWithdrawAddressSet {
        uint256 _balanceBusd = getTotalBusdWinners();
        require(
            bUSDAddress.transfer(WITHDRAW_ADDRESS, _balanceBusd),
            "ERC20 Cannot withdraw fund"
        );
        isWithdrawBusd = true;
    }

    /* Get Back unused token to Owner */
    function removeOtherERC20Tokens(address _tokenAddress) external onlyOwner
    {
        require(
            _tokenAddress != address(bUSDAddress),
            "Cannot remove BUSD"
        );

        require(
            _tokenAddress != address(tokenAddress),
            "Token Address has to be diff than the erc20 subject to sale"
        );

        require(
            _tokenAddress != address(rirAddress),
            "Token Address has to be diff than the erc20 subject to sale"
        );
        // Confirm tokens addresses are different from main sale one
        ERC20 erc20Token = ERC20(_tokenAddress);
        require(
            erc20Token.transfer(WITHDRAW_ADDRESS, erc20Token.balanceOf(address(this))),
            "ERC20 Token transfer failed"
        );
    }


    /* After Admin import WinnerList, make a verification and Owner will commit the WinnerList */
    /* After WinnerList is committed, the List cannot be changed */
    function commitWinners() external payable virtual onlyOwner onlyUncommit {
        // make sure winners list available
        require(winners.length > 0 && winCount() > 0, "No winner");

        // every thing need to be check are checked when import
        require(isCommit = true);
    }

    /* Not allow change Pool Token Address later */
    function commitTokenAddress() external onlyTokenNotSet onlyOwner {
        isTokenAddressSet = true; 
    }

    /* Not allow change Pool Token Address later */
    function commitWithdrawAddress() external onlyWithdrawAddressNotSet onlyOwner {
        isWithdrawAddressSet = true; 
    }

    /**
     * UPDATE Total RIR Allocation - by default is 80% of all allocation
     */
    function updateRIRAllocation(uint percentage) external onlyOwner {
        totalRIRAllocation = bUSDForSale.div(rate).mul(percentage).div(100);
    }

}

// File: contracts/LaunchVerseWhitelist.sol

pragma solidity ^0.8.5;



contract LaunchVerseWhitelist is LaunchVerse {
    using SafeMathUpgradeable for uint256;

    // store list to accept to join Pool
    mapping (address => bool) public whitelist;
    address[] whitelistAddresses;

    mapping (address => uint256) public allocations;


    // Getter
    function inWhitelist(address _address) public view returns (bool) {
        return whitelist[_address];
    }
    function countWhitelist() public view returns (uint) {
        return whitelistAddresses.length;
    }
    /** 
        Add or update to whitelist
     */
    function addToWhitelist(address _address) public virtual onlyUncommit onlyAdmin {
        if (!inWhitelist(_address)) {
            whitelistAddresses.push(_address);
        }
        whitelist[_address] = true;
    }
    function removeFromWhitelist(address _address) external virtual onlyUncommit onlyAdmin {
        require(inWhitelist(_address), "Not in whitelist");
        delete whitelist[_address];
        // takeout from array of address
        bool found;
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            if (!found && whitelistAddresses[i] == _address) {
                found = true;                
            }

            // shift up when found
            if (found && i<whitelistAddresses.length-1) {
                whitelistAddresses[i] = whitelistAddresses[i+1];
            }
        }
        // takeout last one if found
        if (found) {
            delete whitelistAddresses[whitelistAddresses.length-1];
            // whitelistAddresses.length--;
        }
    }
    function importWhitelist(address[] memory _addresses) external virtual onlyUncommit onlyAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addToWhitelist(_addresses[i]);
        }
    }


    function importAllocations(address[] memory _addresses, uint256[] memory _allocations) external virtual onlyAdmin {
        require(_addresses.length == _allocations.length, "length not match");
        for (uint256 i = 0; i < _addresses.length; i++) {
            allocations[_addresses[i]] = _allocations[i];
        }
    }


    function createSubscription(
        uint256 _amountBusd,
        uint256 _amountRIR,
        address _referer
    ) public payable override {
        // make sure the caller inside whitelist
        require(inWhitelist(msg.sender), "Not allow");

        // call parent
        super.createSubscription(_amountBusd, _amountRIR, _referer);
    }


    /**
     Pick Winner List base on the allocations and subscriptions
     */
    function pickWinners() external virtual onlyAdmin winEmpty {
        uint256 _bUSDLeft = bUSDForSale;
        uint256 _bUSDAllocated = 0;
        for (uint256 i=0; i< subscribers.length && _bUSDLeft > 0; i++) {
            address _address = subscribers[i];
            Order memory _order = subscription[_address];
            // max approved allocation
            uint256 _allocation = allocations[_address];
            // check with input
            if (_allocation > _order.amountBUSD) _allocation = _order.amountBUSD;
            // check if over total
            if (_allocation > _bUSDLeft) _allocation = _bUSDLeft;
            if (_allocation > 0) {
                // approve this allocation for this address
                subscription[_address].approvedBUSD = _allocation;
                winners.push(_address);
                // 
                _bUSDAllocated += _allocation;
                _bUSDLeft -= _allocation;
            }
        }

        bUSDAllocated = _bUSDAllocated;
    }

    function importSubscriptionForTesting ( address[] memory _addresses, uint256[] memory _amountBusds ) external virtual onlyAdmin {
        require(_addresses.length == _amountBusds.length, "length not match");
        for (uint256 i = 0; i < _addresses.length; i++) {
            //if (subscription[_addresses[i]].amountBUSD == 0) 
            subscribers.push(_addresses[i]);
            subscription[_addresses[i]].amountBUSD = _amountBusds[i];
        }
    }

}