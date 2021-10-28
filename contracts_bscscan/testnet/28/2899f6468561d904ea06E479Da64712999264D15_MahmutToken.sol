/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

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
    uint256[45] private __gap;
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

pragma solidity ^0.8.4;

contract MahmutToken is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    /// @dev Holds blacklisted addresses
    mapping(address => bool) private _blacklist;

    // Minting vars start //
    /// @dev Minting vars to calculate and track minting rounds
    mapping(uint8 => uint256) private _mintingDates;
    mapping(uint8 => uint256) private _mintingAmounts;
    uint8 private _latestMintRound;
    uint256 private _remainingMintingAmount;
    // Minting vars end //

    // Locking vars start //
    /// @dev Locking vars to calculate and track locking
    address private _presaleLocked;
    uint256 private _nextUnlockAt;
    uint256 private _lastUnlockAt;
    uint8 private _latestUnlockRound;
    uint256 private _presaleLockedAmount;
    // Locking vars end //

    /// @dev Minter address
    address private _minter;
    /// @dev Address to mint tokens for
    address private _mintingAddress;

    modifier onlyMinter() {
        require(msg.sender == _minter, "Only minter is allowed to call");
        _;
    }

    /// @dev Initializes contract, set presale locked amounts, setup minting and lock logic
    /// @param name Name of the contract
    /// @param symbol Symbol of the contract
    /// @param mintingAddress Address to mint tokens
    /// @param presaleLocked Address to hold locked presale address
    /// @param minter Minter address
    /// @param publicSaleAddress Public sale address
    /// @param teamAddress Team address
    /// @param developmentAddress Development address
    /// @param marketingAddress Marketing address
    /// @param liquidityAddress Liquidity address
    /// @param alemAddress Advisors + Lp and Staking Rewards + Ecosystem Growth + Merger&Acquisition
    function initialize (
        string memory name,
        string memory symbol,
        address mintingAddress,
        address presaleLocked,
        address minter,
        address publicSaleAddress,
        address teamAddress,
        address developmentAddress,
        address marketingAddress,
        address liquidityAddress,
        address alemAddress 
    ) external initializer {
        __ERC20_init(name, symbol);
        __Ownable_init_unchained();
        __Pausable_init_unchained();
    
        statuses[presaleLocked] = AccountStatus(true, true, false);
        _presaleLockedAmount = 132468750 * 1e6;

        _mintingAddress = mintingAddress;
        _minter = minter;
        _presaleLocked = presaleLocked;

        // Exclude the owner and this contract from transfer restrictions
        statuses[msg.sender] = AccountStatus(true, true, false);
        statuses[address(this)] = AccountStatus(true, true, false);

        // Exclude other system accounts
        statuses[publicSaleAddress] = AccountStatus(true, true, false);
        statuses[teamAddress] = AccountStatus(true, true, false);
        statuses[developmentAddress] = AccountStatus(true, true, false);
        statuses[marketingAddress] = AccountStatus(true, true, false);
        statuses[liquidityAddress] = AccountStatus(true, true, false);
        statuses[alemAddress] = AccountStatus(true, true, false);

        setupLocks();
        setupMintingRounds();

        _mint(publicSaleAddress, 1125000 * 1e6);
        _mint(teamAddress, 156250 * 1e6);
        _mint(developmentAddress, 200000 * 1e6);
        _mint(marketingAddress, 250000 * 1e6);
        _mint(liquidityAddress, 15000000 * 1e6);
        //  Advisors + Lp and Staking Rewards + Ecosystem Growth + Merger&Acquisition
        _mint(alemAddress, ( 125000 + 375000 + 150000 + 150000 )* 1e6);

        // Token Limitations
        // Set initial settings
        accountLimit = 150 * 10e6 * (10**6);
        singleTransferLimit = 150 * 10e8 * (10**6);
    }

    mapping(address => AccountStatus) private statuses;

    struct AccountStatus {
        bool accountLimitExcluded;
        bool transferLimitExcluded;
        bool blacklistedBot;
    }

    uint256 public accountLimit;
    uint256 public singleTransferLimit;
    
    /// @dev Gets account status is it excluded from account limit, transfer limit or blacklisted as bot
    /// @param account address of user
    function getAccountStatus(address account)
        external
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return (
            statuses[account].accountLimitExcluded,
            statuses[account].transferLimitExcluded,
            statuses[account].blacklistedBot
        );
    }

    function setAccountLimit(uint256 amount) external onlyOwner {
        accountLimit = amount;
    }

    function setSingleTransferLimit(uint256 amount) external onlyOwner {
        singleTransferLimit = amount;
    }

    function setAccountLimitExclusion(address account, bool isExcluded) external onlyOwner {
        statuses[account].accountLimitExcluded = isExcluded;
    }

    function setTransferLimitExclusion(address account, bool isExcluded) external onlyOwner {
        statuses[account].transferLimitExcluded = isExcluded;
    }

    function setBotsBlacklisting(address[] memory bots, bool isBlacklisted) external onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            statuses[bots[i]].blacklistedBot = isBlacklisted;
        }
    }

    function _checkBotBlacklisting(address sender, address recipient) private view {
        require(!statuses[sender].blacklistedBot, "Sender is blacklisted");
        require(!statuses[recipient].blacklistedBot, "Recipient is blacklisted");
    }

    function _checkTransferLimit(
        address sender,
        address recipient,
        uint256 amount
    ) private view {
        if (!statuses[sender].transferLimitExcluded && !statuses[recipient].transferLimitExcluded) {
            require(amount <= singleTransferLimit, "Exceeds transfer limit");
        }
    }

    function _checkAccountLimit(
        address recipient,
        uint256 amount,
        uint256 recipientBalance
    ) private view {
        if (!statuses[recipient].accountLimitExcluded) {
            require(recipientBalance + amount <= accountLimit, "Account tokens limit");
        }
    }

    // Token limitation end

    /// @dev Returns token decimals
    /// @return uint8
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @dev Burns tokens, callable only by the owner
    /// @return bool
    function burn(uint256 amount) external onlyOwner returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /// @dev Adds an address to blacklist
    /// @return bool
    function blacklist(address account) external onlyOwner returns (bool) {
        _blacklist[account] = true;
        return true;
    }

    /// @dev Removes an address from blacklist
    /// @return bool
    function unblacklist(address account) external onlyOwner returns (bool) {
        delete _blacklist[account];
        return true;
    }

    /// @dev Checks if an address is blacklisted
    /// @return bool
    function blacklisted(address account) external view virtual returns (bool) {
        return _blacklist[account];
    }

    /// @dev Pauses token transfers
    /// @return bool
    function pause() external onlyOwner whenNotPaused returns (bool) {
        _pause();
        return true;
    }

    /// @dev Unpauses token transfers
    /// @return bool
    function unpause() external onlyOwner whenPaused returns (bool) {
        _unpause();
        return true;
    }

    /// @dev Returns presale locked amount
    /// @return uint256
    function presaleLockedAmount() external view returns (uint256) {
        return _presaleLockedAmount;
    }

    /// @dev Returns remaining minting amount
    /// @return uint256
    function remainingMintingAmount() external view returns (uint256) {
        return _remainingMintingAmount;
    }

    /// @dev Returns next minting round
    /// @return uint8
    function currentMintRound() internal view returns (uint8) {
        return _latestMintRound + 1;
    }

    /// @dev Mints next round tokens, callable only by the owner
    function mint() external onlyMinter {
        require(_mintingDates[currentMintRound()] < block.timestamp, "Too early to mint next round");
        require(_latestMintRound < 120, "Minting is over");
        _mint(_mintingAddress, _mintingAmounts[currentMintRound()]);
        _remainingMintingAmount -= _mintingAmounts[currentMintRound()];
        _latestMintRound++;
    }

    /// @dev Changes minting address, callable only by current minting address
    /// @param newAddress New minting address
    function changeMintingAddress(address newAddress) external {
        require(_mintingAddress == msg.sender, "Can not change address");

        _mintingAddress = newAddress;
    }

    /// @dev Changes minter, callable only by the owner
    /// @param newAddress New minter address
    function changeMinter(address newAddress) external onlyOwner {
        _minter = newAddress;
    }

    /// @dev Returns minting address
    /// @return address
    function mintingAddress() external view returns (address) {
        return _mintingAddress;
    }

    /// @dev Returns minter
    /// @return address
    function minter() external view returns (address) {
        return _minter;
    }

    /// @dev Setups minting rounds, will be called only on initialization
    function setupMintingRounds() internal {
        uint256 nextMintingAt = 1638090000; // Sun Nov 28 2021 09:00:00 GMT+0000
        for (uint8 i = 1; i <= 120; i++) {
            _mintingDates[i] = nextMintingAt;
            nextMintingAt += 30 days;
            
            // Muhittin was here
            if ( i == 1 || i == 2 || i == 3 ) {
                /*
                Public sale
                Team
                Devleopment
                Marketing
                Advisors
                LP and Staking Rewards
                Ecosystem Growth
                Merger & Acquisition
                */
                uint256 mintingAmount = 2531250 * 1e6;
                _mintingAmounts[i] = mintingAmount;
                _remainingMintingAmount += mintingAmount;
                continue;
            }

            if ( i >= 4 && i <= 6 ) {
                /*
                Early Birds
                Team
                Devleopment
                Marketing
                Advisors
                LP and Staking Rewards
                Ecosystem Growth
                Merger & Acquisition
                */
                uint256 mintingAmount = 1906250 * 1e6;
                _mintingAmounts[i] = mintingAmount;
                _remainingMintingAmount += mintingAmount;
                continue;
            }

            if ( i >= 7 && i <= 12 ) {
                /*
                Seed Round
                Early Birds
                Team
                Devleopment
                Marketing
                Advisors
                LP and Staking Rewards
                Ecosystem Growth
                Merger & Acquisition
                */
                uint256 mintingAmount = 2031250 * 1e6;
                _mintingAmounts[i] = mintingAmount;
                _remainingMintingAmount += mintingAmount;
                continue;
            }
            if ( i >= 13 && i <= 30 ) {
                /*
                Seed Round
                Team
                Devleopment
                Marketing
                Advisors
                LP and Staking Rewards
                Ecosystem Growth
                Merger & Acquisition
                */
                uint256 mintingAmount = 1531250 * 1e6;
                _mintingAmounts[i] = mintingAmount;
                _remainingMintingAmount += mintingAmount;
                continue;
            }

            if ( i >= 31 && i <= 59 ) {
                /*
                Team
                Devleopment
                Marketing
                Advisors
                LP and Staking Rewards
                Ecosystem Growth
                Merger & Acquisition
                */
                uint256 mintingAmount = 1406250 * 1e6;
                _mintingAmounts[i] = mintingAmount;
                _remainingMintingAmount += mintingAmount;
                continue;
            }

            if ( i >= 60 && i <= 95 ) {
                /*
                Team
                Marketing
                Ecosystem Growth
                Merger & Acquisition
                */
                uint256 mintingAmount = 706250 * 1e6;
                _mintingAmounts[i] = mintingAmount;
                _remainingMintingAmount += mintingAmount;
                continue;
            }

            if ( i >= 96 && i <= 119 ) {
                /*
                Marketing
                Ecosystem Growth
                Merger & Acquisition
                */
                uint256 mintingAmount = 550000 * 1e6;
                _mintingAmounts[i] = mintingAmount;
                _remainingMintingAmount += mintingAmount;
                continue;
            }
        }
    }

    /// @dev Setups next and last unlock date and mints presale locks, will be called only on initialization
    function setupLocks() internal {
        _nextUnlockAt = 1635454330; // Thu Oct 28 2021 23:52:10 GMT+0300 (GMT+03:00)
        _lastUnlockAt = _nextUnlockAt + 3652 days;
        _mint(_presaleLocked, _presaleLockedAmount);
    }

    /// @dev Setups next and last unlock date and mints presale locks, will be called only on initialization
    /// @param from Address to check locked amount
    /// @param amount To check if sent amount available for presale account
    function checkLockedAmount(address from, uint256 amount) internal {
        // checks locked account on every transfer and decrease locked amount if conditions met
        if (from == _presaleLocked && _presaleLockedAmount > 0) {
            // runs a while loop to update locked amount
            while (_nextUnlockAt <= block.timestamp && _nextUnlockAt <= _lastUnlockAt) {
                _latestUnlockRound++;
                
                uint256 unlockAmount;

                // Muhittin was here
                if ( _latestUnlockRound == 1 || _latestUnlockRound == 2 || _latestUnlockRound == 3) {
                    unlockAmount = 2531250 * 1e6;
                }  else if ( _latestUnlockRound >= 4 && _latestUnlockRound <= 6 ) {
                    unlockAmount = 1906250 * 1e6;
                } else if ( _latestUnlockRound >= 7 && _latestUnlockRound <= 12 ) {
                    unlockAmount = 2031250 * 1e6;
                } else if ( _latestUnlockRound >= 13 && _latestUnlockRound <= 30 ) {
                    unlockAmount = 1531250 * 1e6;
                } else  if ( _latestUnlockRound >= 31 && _latestUnlockRound <= 59 ) {
                    unlockAmount = 1406250 * 1e6;
                } else if ( _latestUnlockRound >= 60 && _latestUnlockRound <= 95 ) {
                    unlockAmount = 706250 * 1e6;
                } else if ( _latestUnlockRound >= 96 && _latestUnlockRound <= 119 ) {
                    unlockAmount = 550000 * 1e6;
                }

                // increases next unlock timestamp for 30 days
                _nextUnlockAt += 30 days;
                _presaleLockedAmount -= unlockAmount;
            }

            // reverts transaction if available balance is insufficient
            require(balanceOf(from) >= amount + _presaleLockedAmount, "insufficient funds");
        }
    }

    /** @dev Standard ERC20 hook,
        checks if transfer paused,
        checks from or to addresses is blacklisted
        checks available balance if from address is presaleLocked address
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!paused(), "ERC20Pausable: token transfer while paused");
        require(!_blacklist[from], "Token transfer from blacklisted address");
        require(!_blacklist[to], "Token transfer to blacklisted address");

        checkLockedAmount(from, amount);

        _checkBotBlacklisting(from, to);
        _checkTransferLimit(from, to, amount);
        _checkAccountLimit(to, amount, balanceOf(to));
    }
}