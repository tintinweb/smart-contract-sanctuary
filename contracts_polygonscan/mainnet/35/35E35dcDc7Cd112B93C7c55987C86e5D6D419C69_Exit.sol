/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

pragma solidity ^0.8.6;

contract Enum {
    enum Operation {Call, DelegateCall}
}

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
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

contract Guardable is OwnableUpgradeable {
    event ChangedGuard(address guard);

    address public guard;

    /// @dev Set a guard that checks transactions before execution
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            require(
                BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId),
                "Guard does not implement IERC165"
            );
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        /// check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                address(0)
            );
        }
        success = IAvatar(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        /// check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                address(0)
            );
        }
        (success, returnData) = IAvatar(target)
            .execTransactionFromModuleReturnData(to, value, data, operation);
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return (success, returnData);
    }
}

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

interface IAvatar {
    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract CirculatingSupply is OwnableUpgradeable {
    event ExclusionAdded(address indexed excludedAddress);
    event ExclusionRemoved(address indexed RemovedAddress);
    event TokenSet(address indexed newToken);

    address public token;
    address internal constant SENTINEL_EXCLUSIONS = address(0x1);

    // Mapping of excluded addresses
    mapping(address => address) internal exclusions;

    constructor(
        address _owner,
        address _token,
        address[] memory _exclusions
    ) {
        bytes memory initParams = abi.encode(_owner, _token, _exclusions);
        setUp(initParams);
    }

    function setUp(bytes memory initializeParams) public {
        (address _owner, address _token, address[] memory _exclusions) = abi
            .decode(initializeParams, (address, address, address[]));
        __Ownable_init();
        transferOwnership(_owner);
        setupExclusions();
        token = _token;
        for (uint256 i = 0; i < _exclusions.length; i++) {
            excludeAddress(_exclusions[i]);
        }
    }

    function get() public view returns (uint256 circulatingSupply) {
        circulatingSupply = ERC20(token).totalSupply();
        if (exclusions[SENTINEL_EXCLUSIONS] != SENTINEL_EXCLUSIONS) {
            address exclusion = exclusions[SENTINEL_EXCLUSIONS];
            while (exclusion != SENTINEL_EXCLUSIONS) {
                circulatingSupply -= ERC20(token).balanceOf(exclusion);
                exclusion = exclusions[exclusion];
            }
        }
        return circulatingSupply;
    }

    /// @dev Sets the token to calculate circulating supply of
    /// @param _token token to calculate circulating supply of
    /// @notice This can only be called by the owner
    function setToken(address _token) public onlyOwner {
        token = _token;
        emit TokenSet(_token);
    }

    function setupExclusions() internal {
        require(
            exclusions[SENTINEL_EXCLUSIONS] == address(0),
            "setUpModules has already been called"
        );
        exclusions[SENTINEL_EXCLUSIONS] = SENTINEL_EXCLUSIONS;
    }

    /// @dev Removes an excluded address
    /// @param prevExclusion Exclusion that pointed to the exclusion to be removed in the linked list
    /// @param exclusion Exclusion to be removed
    /// @notice This can only be called by the owner
    function removeExclusion(address prevExclusion, address exclusion)
        public
        onlyOwner
    {
        require(
            exclusion != address(0) && exclusion != SENTINEL_EXCLUSIONS,
            "Invalid exclusion"
        );
        require(
            exclusions[prevExclusion] == exclusion,
            "Exclusion already disabled"
        );
        exclusions[prevExclusion] = exclusions[exclusion];
        exclusions[exclusion] = address(0);
        emit ExclusionRemoved(exclusion);
    }

    /// @dev Enables the balance of an address from the circulatingSupply calculation
    /// @param exclusion Address to be excluded
    /// @notice This can only be called by the owner
    function exclude(address exclusion) public onlyOwner {
        excludeAddress(exclusion);
    }

    function excludeAddress(address exclusion) private {
        require(
            exclusion != address(0) && exclusion != SENTINEL_EXCLUSIONS,
            "Invalid exclusion"
        );
        require(
            exclusions[exclusion] == address(0),
            "Exclusion already enabled"
        );
        exclusions[exclusion] = exclusions[SENTINEL_EXCLUSIONS];
        exclusions[SENTINEL_EXCLUSIONS] = exclusion;
        emit ExclusionAdded(exclusion);
    }

    /// @dev Returns if an exclusion is enabled
    /// @return True if the exclusion is enabled
    function isExcluded(address _exclusion) public view returns (bool) {
        return
            SENTINEL_EXCLUSIONS != _exclusion &&
            exclusions[_exclusion] != address(0);
    }

    /// @dev Returns array of exclusions.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of exclusions that should be returned.
    /// @return array Array of exclusions.
    /// @return next Start of the next page.
    function getExclusionsPaginated(address start, uint256 pageSize)
        public
        view
        returns (address[] memory array, address next)
    {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 exclusionCount = 0;
        address currentExclusion = exclusions[start];
        while (
            currentExclusion != address(0x0) &&
            currentExclusion != SENTINEL_EXCLUSIONS &&
            exclusionCount < pageSize
        ) {
            array[exclusionCount] = currentExclusion;
            currentExclusion = exclusions[currentExclusion];
            exclusionCount++;
        }
        next = currentExclusion;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, exclusionCount)
        }
    }
}

contract Exit is Module {
    ERC20 public designatedToken;
    CirculatingSupply public circulatingSupply;

    event ExitModuleSetup(address indexed initiator, address indexed avatar);
    event ExitSuccessful(address indexed leaver);

    /// @notice Mapping of denied tokens defined by the avatar
    mapping(address => bool) public deniedTokens;

    /// @dev Initialize function, will be triggered when a new proxy is deployed
    /// @param _owner Address of the owner
    /// @param _avatar Address of the avatar (e.g. a Safe or Delay Module)
    /// param _target Address that this module will pass transactions to
    /// @param _designatedToken Address of the ERC20 token that will define the share of users
    /// @param _circulatingSupply Circulating Supply of designated token
    /// @notice Designated token address can not be zero
    constructor(
        address _owner,
        address _avatar,
        address _target,
        address _designatedToken,
        address _circulatingSupply
    ) {
        bytes memory initParams = abi.encode(
            _owner,
            _avatar,
            _target,
            _designatedToken,
            _circulatingSupply
        );
        setUp(initParams);
    }

    function setUp(bytes memory initParams) public override {
        (
            address _owner,
            address _avatar,
            address _target,
            address _designatedToken,
            address _circulatingSupply
        ) = abi.decode(
            initParams,
            (address, address, address, address, address)
        );
        __Ownable_init();
        require(_avatar != address(0), "Avatar can not be zero address");
        avatar = _avatar;
        require(_target != address(0), "Target can not be zero address");
        target = _target;
        designatedToken = ERC20(_designatedToken);
        circulatingSupply = CirculatingSupply(_circulatingSupply);

        transferOwnership(_owner);

        emit ExitModuleSetup(msg.sender, _avatar);
    }

    /// @dev Execute the share of assets and the transfer of designated tokens
    /// @param amountToRedeem Amount to be sent to the avatar
    /// @param tokens Array of tokens to claim, orderred lowest to highest
    /// @notice Will revert if tokens[] is not orderred highest to lowest, contains duplicates, or includes denied tokens
    function exit(uint256 amountToRedeem, address[] calldata tokens) public {
        require(
            designatedToken.balanceOf(msg.sender) >= amountToRedeem,
            "Amount to redeem is greater than balance"
        );

        uint256 supply = getCirculatingSupply();

        designatedToken.transferFrom(msg.sender, avatar, amountToRedeem);

        if (avatar.balance > 0) {
            transferNativeAsset(msg.sender, amountToRedeem, supply);
        }

        address previousToken;
        for (uint8 i = 0; i < tokens.length; i++) {
            require(
                !deniedTokens[tokens[i]] &&
                    tokens[i] != address(designatedToken),
                "Denied token"
            );
            require(
                tokens[i] > previousToken,
                "tokens[] is out of order or contains a duplicate"
            );
            transferToken(tokens[i], msg.sender, amountToRedeem, supply);
            previousToken = tokens[i];
        }

        emit ExitSuccessful(msg.sender);
    }

    /// @dev Execute a token transfer through the avatar
    /// @param token address of token to transfer
    /// @param leaver address that will receive the transfer
    function transferToken(
        address token,
        address leaver,
        uint256 amountToRedeem,
        uint256 supply
    ) private {
        uint256 avatarBalance = ERC20(token).balanceOf(avatar);
        uint256 amount = (amountToRedeem * avatarBalance) / supply;
        // 0xa9059cbb - bytes4(keccak256("transfer(address,uint256)"))
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, leaver, amount);
        require(
            exec(token, 0, data, Enum.Operation.Call),
            "Error on token transfer"
        );
    }

    /// @dev Execute a token transfer through the avatar
    /// @param leaver address that will receive the transfer
    function transferNativeAsset(
        address leaver,
        uint256 amountToRedeem,
        uint256 supply
    ) private {
        uint256 amount = (amountToRedeem * avatar.balance) / supply;
        require(
            exec(leaver, amount, bytes("0x"), Enum.Operation.Call),
            "Error on native asset transfer"
        );
    }

    /// @dev Add a batch of token addresses to denied tokens list
    /// @param tokens Batch of addresses to add into the denied token list
    /// @notice Can not add duplicate token address or it will throw
    /// @notice Can only be modified by owner
    function addToDenylist(address[] calldata tokens) external onlyOwner {
        for (uint8 i; i < tokens.length; i++) {
            require(!deniedTokens[tokens[i]], "Token already denied");
            deniedTokens[tokens[i]] = true;
        }
    }

    /// @dev Remove a batch of token addresses from denied tokens list
    /// @param tokens Batch of addresses to be removed from the denied token list
    /// @notice If a non-denied token address is passed, the function will throw
    /// @notice Can only be modified by owner
    function removeFromDenylist(address[] calldata tokens) external onlyOwner {
        for (uint8 i; i < tokens.length; i++) {
            require(deniedTokens[tokens[i]], "Token not denied");
            deniedTokens[tokens[i]] = false;
        }
    }

    /// @dev Change the designated token address variable
    /// @param _token Address of new designated token
    /// @notice Can only be modified by owner
    function setDesignatedToken(address _token) public onlyOwner {
        designatedToken = ERC20(_token);
    }

    /// @dev Change the circulating supply vairable
    /// @param _circulatingSupply Address of new circulating supply contract
    /// @notice Can only be modified by owner
    function setCirculatingSupply(address _circulatingSupply) public onlyOwner {
        circulatingSupply = CirculatingSupply(_circulatingSupply);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return circulatingSupply.get();
    }
}