// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INHERITANCE IMPORTS */

import "./IXenoERC20.sol";
import "./proxy/Initializable.sol";
import "./proxy/UUPSUpgradeable.sol";
import "./access/manager/ManagerRole.sol";
import "./extensions/freezable/Freezable.sol";
import "./extensions/pausable/Pausable.sol";
import "./extensions/recoverable/Recoverable.sol";
import "./ERC20/ERC20.sol";

contract XenoERC20 is IXenoERC20, Initializable, UUPSUpgradeable, ManagerRole, Freezable, Pausable, Recoverable, ERC20 {

    /* INITIALIZE METHOD */

    /**
     * @dev initalize() replaces the contract constructor in the UUPS proxy upgrade pattern.
     * It is gated by the initializer modifier to ensure that it can only be run once.
     * All inherited contracts must also replace constructors with initialize methods to be called here.
     */
    function initialize(string calldata setName, string calldata setSymbol, uint256 initialSupply ) external initializer {
        // set initializer as manager
        _initializeManagerRole(msg.sender);
        
        // set ERC20 name, symbol, decimals, and initial supply
        _initalizeERC20(setName, setSymbol, 18, initialSupply);

        // set pause state to false by default
        _initializePausable();
    }

    /* ManagerRoleInterface METHODS */

    /**
     * @dev Returns true if `account` holds a manager role, returns false otherwise.
     */
    function isManager(address account) external view override returns (bool) {
        return _isManager(account);
    }

    /**
     * @dev Give the manager role to `account`.
     *
     * Requirements;
     *
     * - caller must be a manager
     * - `account` is not already a manager
     *
     * Emits an {ManagerAdded} event.
     */
    function addManager(address account) external override {
       _addManager(account);
    }

    /**
     * @dev Renounce the manager role for the caller.
     *
     * Requirements;
     *
     * - caller must be a manager
     * - caller must NOT be the ONLY manager
     *
     * Emits an {ManagerRemoved} event.
     */
    function renounceManager() external override {
        _renounceManager();
    }

    /* IERC20Metadata METHODS */

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override returns (string memory) {
        return _name();
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view override returns (string memory) {
        return _symbol();
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view override returns (uint8) {
        return _decimals();
    }

    /* IERC20 METHODS */

   /**
     * @dev Returns the the total amount of tokens that exist.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply();
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowance(owner, spender);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - `recipient` is not frozen
     * - transfer rules apply (i.e. adequate balance, non-zero addresses)
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.transfer: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.transfer: CALLER_FROZEN"
        );
        /* check if recipient frozen */
        require(
            !_frozen(recipient),
            "XenoERC20.transfer: RECIPIENT_FROZEN"
        );
        return _transfer(_msgSender(), recipient, amount);
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - `sender` is not forzen
     * - `recipient` is not frozen
     * - transferFrom rules apply (i.e. adequate allowance and balance, non-zero addresses)
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.transferFrom: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.transferFrom: CALLER_FROZEN"
        );
        /* check if sender frozen */
        require(
            !_frozen(sender),
            "XenoERC20.transferFrom: SENDER_FROZEN"
        );
        /* check if recipient frozen */
        require(
            !_frozen(recipient),
            "XenoERC20.transferFrom: RECIPIENT_FROZEN"
        );
        return _transferFrom(sender, recipient, amount);
    }

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
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - `spender` is not frozen
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.approve: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.approve: CALLER_FROZEN"
        );
        /* check if spender frozen */
        require(
            !_frozen(spender),
            "XenoERC20.approve: SPENDER_FROZEN"
        );
        return _approve(spender, amount);
    }

    /* ERC20AllowanceInterface METHODS */

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
     * - contract is upaused
     * - caller is not frozen
     * - `spender` is not frozen
     *
     * Emits an {Approval} event
     */
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.increaseAllowance: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.increaseAllowance: CALLER_FROZEN"
        );
        /* check if spender frozen */
        require(
            !_frozen(spender),
            "XenoERC20.increaseAllowance: SPENDER_FROZEN"
        );
        return _increaseAllowance(spender, addedValue);
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
     * - contract is upaused
     * - caller is not frozen
     * - `spender` is not frozen
     *
     * Emits an {Approval} event
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.decreaseAllowance: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.decreaseAllowance: CALLER_FROZEN"
        );
        /* check if spender frozen */
        require(
            !_frozen(spender),
            "XenoERC20.decreaseAllowance: SPENDER_FROZEN"
        );
        return _decreaseAllowance(spender, subtractedValue);
    }

    /* IERC20Burnable METHODS */

    /**
     * @dev Burns `amount` tokens from the caller account
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - transfer rules apply (i.e. adequate balance, non-zero addresses)
     *
     * Emits a {Transfer} event with the ZERO address as recipient
     */
    function burn(uint256 amount) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.burn: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.burn: CALLER_FROZEN"
        );
        return _burn(amount);
    }

    /**
     * @dev Burns `amount` tokens from caller using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     * - contract is upaused
     * - caller is not frozen
     * - `account` is not frozen
     * - transfer rules apply (i.e. adequate balance)
     *
     * Emits a {Transfer} event with the ZERO address as recipient
     */
    function burnFrom(address account, uint256 amount) external override returns (bool) {
        /* check if paused */
        require(
            !_paused(),
            "XenoERC20.burnFrom: PAUSED"
        );
        /* check if caller frozen */
        require(
            !_frozen(_msgSender()),
            "XenoERC20.burnFrom: CALLER_FROZEN"
        );
        /* check if account frozen */
        require(
            !_frozen(account),
            "XenoERC20.burnFrom: ACCOUNT_FROZEN"
        );
        return _burnFrom(account, amount);
    }

    /* FreezableInterface METHODS */

    /**
     * @dev Returns the frozen state of `account`.
     */
    function frozen(address account) external view override returns (bool) {
        return _frozen(account);
    }

    /**
     * @dev Freezes activity of `account` until unfrozen
     *
     * Frozen activities include: 
     * - transfer (as sender and recipient)
     * - transferFrom (as caller, owner and recipient)
     * - approve (as caller and spender)
     * - increaseAllowance (as caller and spender)
     * - decreaseAllowance (as caller and spender)
     * - burn (as caller)
     * - burnFrom (as caller and spender)
     *
     * Requirements:
     * - caller must hold the ManagerRole
     * - `account` is unfrozen
     *
     * * Emits a {Frozen} event
     */
    function freeze(address account) external override {
        require(
            _isManager(_msgSender()),
            "XenoERC20.freeze: INVALID_CALLER"
        );
        _freeze(account);
    }

    /**
     * @dev Restores `account` activity
     *
     * Requirements:
     * - caller must hold the ManagerRole
     * - `account` is frozen
     *
     * * Emits an {Unfrozen} event
     *
     */
    function unfreeze(address account) external override {
        require(
            _isManager(_msgSender()),
            "XenoERC20.unfreeze: INVALID_CALLER"
        );
        _unfreeze(account);
    }

    /* PausableInterface  METHODS */

    /**
     * @dev Returns the paused state of the contract.
     */
    function paused() external view override returns (bool) {
        return _paused();
    }

    /**
     * @dev Pauses state changing activity of the entire contract
     *
     * Paused activities include: 
     * - transfer
     * - transferFrom
     * - approve
     * - increaseAllowance
     * - decreaseAllowance
     * - burn
     * - burnFrom
     *
     * Requirements:
     * - caller must hold the ManagerRole
     * - contract is unpaused
     *
     * * Emits a {Paused} event
     */
    function pause() external override {
        require(
            _isManager(_msgSender()),
            "XenoERC20.pause: INVALID_CALLER"
        );
        _pause();
    }

    /**
     * @dev Restores state changing activity to the entire contract
     *
     * Requirements:
     * - caller must hold the MangaerRole
     * - contract is paused
     *
     * * Emits a {Unpaused} event
     */
    function unpause() external override {
        require(
            _isManager(_msgSender()),
            "XenoERC20.unpause: INVALID_CALLER"
        );
        _unpause();
    }

    /* RecoverableInterface METHODS */

    /**
     * @dev Recovers `amount` of ERC20 `token` sent to the contract.
     *
     * Requirements:
     * - caller must hold the ManagerRole
     * - `token`.balanceOf(contract) must be greater than or equal to `amount`
     *
     * * Emits a {Recovered} event
     */
    function recover(IERC20 token, uint256 amount) override external {
        require(
            _isManager(_msgSender()),
            "XenoERC20.recover: INVALID_CALLER"
        );
        _recover(token, amount);
    }

    /* UUPSUpgradable METHODS */

    /**
     * @dev Returns the contract address of the currently deployed logic.
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }


    /**
     * @dev Ensures only manager role accounts can upgrade contract logic.
     */
    function _authorizeUpgrade(address) internal view override {
        require(
            _isManager(_msgSender()),
            "XenoERC20._authorizeUpgrade: INVALID_CALLER"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INTERFACE INHERITANCE IMPORTS */

import "./access/manager/interfaces/ManagerRoleInterface.sol";

import "./ERC20/interfaces/IERC20.sol";
import "./ERC20/interfaces/IERC20Metadata.sol";
import "./ERC20/interfaces/ERC20AllowanceInterface.sol";
import "./ERC20/interfaces/IERC20Burnable.sol";

import "./extensions/freezable/interfaces/FreezableInterface.sol";
import "./extensions/pausable/interfaces/PausableInterface.sol";
import "./extensions/recoverable/interfaces/RecoverableInterface.sol";

/**
 * @dev Interface for XenoERC20
 */
interface IXenoERC20 is
    ManagerRoleInterface,
    IERC20,
    IERC20Metadata,
    ERC20AllowanceInterface,
    IERC20Burnable,
    FreezableInterface,
    PausableInterface,
    RecoverableInterface
{ }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE */

import "../ERC20/ERC20Storage.sol";

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
abstract contract Initializable is ERC20Storage {

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(x.initializable.initializing || !x.initializable.initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !x.initializable.initializing;
        if (isTopLevelCall) {
            x.initializable.initializing = true;
            x.initializable.initialized = true;
        }

        _;

        if (isTopLevelCall) {
            x.initializable.initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INHERITANCE IMPORTS */

import "./ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./ManagerRoleStore.sol";

/* LIBRARY IMPORTS */

import "../base/Roles.sol";

/* INHERITANCE IMPORTS */

import "../../utils/Context.sol";
import "./interfaces/ManagerRoleEvents.sol";

/* STORAGE */

import "../../ERC20/ERC20Storage.sol"; 

contract ManagerRole is Context, ManagerRoleEvents, ERC20Storage {
    /* LIBRARY USAGE */
    
    using Roles for Role;

    /* MODIFIERS */

    modifier onlyUninitialized() {
        require(!x.managerRole.initialized, "ManagerRole.onlyUninitialized: ALREADY_INITIALIZED");
        _;
    }

    modifier onlyInitialized() {
        require(x.managerRole.initialized, "ManagerRole.onlyInitialized: NOT_INITIALIZED");
        _;
    }

    modifier onlyManager() {
        require(_isManager(_msgSender()), "ManagerRole.onlyManager: NOT_MANAGER");
        _;
    }

    /* INITIALIZE METHOD */
    
    /**
     * @dev Gives the intialize() caller the manager role during initialization. 
     * It is the developer's responsibility to only call this 
     * function in initialize() of the base contract context.
     */
    function _initializeManagerRole(
        address account
    )
        internal
        onlyUninitialized
     {
        _addManager_(account);
        x.managerRole.initialized = true;
    }

    /* GETTER METHODS */

    /**
     * @dev Returns true if `account` has the manager role, and false otherwise.
     */
    function _isManager(
        address account
    )
        internal
        view
        returns (bool)
    {
        return _isManager_(account);
    }


    /* STATE CHANGE METHODS */
    
    /**
     * @dev Give the manager role to `account`.
     */
    function _addManager(
        address account
    )
        internal
        onlyManager
        onlyInitialized
    {
        _addManager_(account);
    }

    /**
     * @dev Renounce the manager role for the caller.
     */
    function _renounceManager()
        internal
        onlyInitialized
    {
        _removeManager_(_msgSender());
    }

    /* PRIVATE LOGIC METHODS */

    function _isManager_(
        address account
    )
        private
        view
        returns (bool)
    {
        return x.managerRole.managers._has(account);
    }

    function _addManager_(
        address account
    )
        private
    {
        x.managerRole.managers._add(account);
        emit ManagerAdded(account);
    }

    function _removeManager_(
        address account
    )
        private
    {
        x.managerRole.managers._safeRemove(account);
        emit ManagerRemoved(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./FreezableStore.sol";

/* INHERITANCE IMPORTS */

import "../../utils/Context.sol";
import "./interfaces/FreezableEvents.sol";

/* STORAGE */

import "../../ERC20/ERC20Storage.sol";

contract Freezable is Context, FreezableEvents, ERC20Storage {

    /* MODIFIERS */

    /**
     * @dev Modifier to make a function callable only when an account is not frozen.
     *
     * Requirements:
     *
     * - `account` must not be frozen.
     */
    modifier whenNotFrozen(address account) {
        require(
            !_frozen_(account),
            "Freezable.whenNotFrozen: FROZEN"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the `account` is frozen.
     *
     * Requirements:
     *
     * - `account` must be frozen.
     */
    modifier whenFrozen(address account) {
        require(
            _frozen_(account),
            "Freezable.whenFrozen: NOT_FROZEN"
        );
        _;
    }

    /* GETTER METHODS */

    /**
     * @dev Returns true if `account` is frozen, and false otherwise.
     */
    function _frozen(address account) internal view returns (bool) {
        return _frozen_(account);
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Triggers stopped `account` state.
     *
     * Requirements:
     *
     * - `account` must not be frozen.
     */
    function _freeze(address account) internal whenNotFrozen(account) {
        require(account != address(0), "Freezable._freeze: ACCOUNT_ZERO_ADDRESS");
        x.freezable.isFrozen[account] = true;
        emit Frozen(_msgSender(), account);
    }

    /**
     * @dev Returns `account` to normal state.
     *
     * Requirements:
     *
     * - `account` must be frozen.
     */
    function _unfreeze(address account) internal whenFrozen(account) {
        x.freezable.isFrozen[account] = false;
        emit Unfrozen(_msgSender(), account);
    }

    /* PRIVATE LOGIC METHODS */

    function _frozen_(address account) private view returns (bool) {
        return x.freezable.isFrozen[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./PausableStore.sol";

/* INHERITANCE IMPORTS */

import "../../utils/Context.sol";
import "./interfaces/PausableEvents.sol";

/* STORAGE */

import "../../ERC20/ERC20Storage.sol";

contract Pausable is Context, PausableEvents, ERC20Storage {

    /* MODIFIERS */

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused_(), "Pausable.whenNotPaused: PAUSED");
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
        require(_paused_(), "Pausable.whenPaused: NOT_PAUSED");
        _;
    }
    
    /* INITIALIZE METHOD */

    /**
     * @dev Sets the value for {isPaused} to false once during initialization. 
     * It is the developer's responsibility to only call this 
     * function in initialize() of the base contract context.
     */
    function _initializePausable() internal {
        x.pausable.isPaused = false;
    }

    /* GETTER METHODS */

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function _paused() internal view returns (bool) {
        return _paused_();
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
        x.pausable.isPaused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal whenPaused {
        x.pausable.isPaused = false;
        emit Unpaused(_msgSender());
    }

    /* PRIVATE LOGIC METHODS */ 

    function _paused_() private view returns (bool) {
        return x.pausable.isPaused;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INTERFACE IMPORTS */

import "../../ERC20/interfaces/IERC20.sol";

/* INHERITANCE IMPORTS */

import "../../utils/Context.sol";
import "./interfaces/RecoverableEvents.sol";


contract Recoverable is Context, RecoverableEvents {
    /**
     * @param token - the token contract address to recover
     * @param amount - number of tokens to be recovered
     */
    function _recover(IERC20 token, uint256 amount) internal virtual {
        require(token.balanceOf(address(this)) >= amount, "Recoverable.recover: INVALID_AMOUNT");
        token.transfer(_msgSender(), amount);
        emit Recovered(_msgSender(), token, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INHERITANCE IMPORTS */

import "../utils/Context.sol";
import "./interfaces/IERC20Events.sol";

/* STORAGE */

import "./ERC20Storage.sol";

/**
 * @dev Implementation of the {IERC20} interface.
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
contract ERC20 is Context, IERC20Events, ERC20Storage {
    
    /* INITIALIZE METHOD */

    /**
     * @dev Sets the values for {name}, {symbol}, {decimals}, and {inital minted supply}.
     * All of these values are immutable: they can only be set once during
     * initialization. This means it is the developer's responsibility to
     * only call this function in the initialize function of the base contract context.
     */
    function _initalizeERC20(string calldata setName, string calldata setSymbol, uint8 setDecimals, uint256 initialSupply) internal {
        x.erc20.named = setName;
        x.erc20.symboled = setSymbol;
        x.erc20.decimaled = setDecimals;
        _mint_(_msgSender(), initialSupply);
    }

    /* GETTER METHODS */

    /**
     * @dev Returns the name of the token.
     */
    function _name() internal view returns (string memory) {
        return x.erc20.named;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function _symbol() internal view returns (string memory) {
        return x.erc20.symboled;
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
    function _decimals() internal view returns (uint8) {
        return x.erc20.decimaled;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function _totalSupply() internal view returns (uint256) {
        return x.erc20.total;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function _balanceOf(address account) internal view returns (uint256) {
        return x.erc20.balances[account];
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _transfer_(sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function _allowance(address owner, address spender) internal view returns (uint256) {
        return _allowance_(owner, spender);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function _approve(address spender, uint256 amount) internal returns (bool) {
        _approve_(_msgSender(), spender, amount);
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
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _transfer_(sender, recipient, amount);

        uint256 currentAllowance = x.erc20.allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20._transferFrom: AMOUNT_EXCEEDS_ALLOWANCE");
        unchecked {
            _approve_(sender, _msgSender(), currentAllowance - amount);
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
    function _increaseAllowance(address spender, uint256 addedValue) internal returns (bool) {
        _approve_(_msgSender(), spender, x.erc20.allowances[_msgSender()][spender] + addedValue);
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
    function _decreaseAllowance(address spender, uint256 subtractedValue) internal returns (bool) {
        uint256 currentAllowance = x.erc20.allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20._decreaseAllowance: DECREASE_BELOW_ZERO");
        unchecked {
            _approve_(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function _burn(uint256 amount) internal returns (bool) {
        _burn_(_msgSender(), amount);
        return true;
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
    function _burnFrom(address account, uint256 amount) internal returns (bool) {
        uint256 currentAllowance = _allowance_(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20._burnFrom: AMOUNT_EXCEEDS_ALLOWANCE"
        );
        unchecked {
            _approve_(account, _msgSender(), currentAllowance - amount);
        }
        _burn_(account, amount);
        return true;
    }

    /* PRIVATE LOGIC METHODS */

    function _allowance_(address owner, address spender) private view returns (uint256) {
        return x.erc20.allowances[owner][spender];
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
    function _transfer_(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20._transfer_: SENDER_ZERO_ADDRESS");
        require(recipient != address(0), "ERC20._transfer_: RECIPIENT_ZERO_ADDRESS");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = x.erc20.balances[sender];
        require(senderBalance >= amount, "ERC20._transfer_: AMOUNT_EXCEEDS_BALANCE");
        unchecked {
            x.erc20.balances[sender] = senderBalance - amount;
        }
        x.erc20.balances[recipient] += amount;

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
    function _mint_(address account, uint256 amount) private {
        require(account != address(0), "ERC20._mint_: ACCOUNT_ZERO_ADDRESS");

        _beforeTokenTransfer(address(0), account, amount);

        x.erc20.total += amount;
        x.erc20.balances[account] += amount;
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
    function _burn_(address account, uint256 amount) private {
        require(account != address(0), "ERC20._burn_: ACCOUNT_ZERO_ADDRESS");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = x.erc20.balances[account];
        require(accountBalance >= amount, "ERC20._burn_: AMOUNT_EXCEEDS_BALANCE");
        unchecked {
            x.erc20.balances[account] = accountBalance - amount;
        }
        x.erc20.total -= amount;

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
    function _approve_(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20._approve_: OWNER_ZERO_ADDRESS");
        require(spender != address(0), "ERC20._approve_: SPENDER_ZERO_ADDRESS");

        x.erc20.allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /* INTERNAL HOOKS */

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
    ) internal {}

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
    ) internal {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ManagerRoleInterface {    

    /**
     * @dev Returns true if `account` has the manager role, and false otherwise.
     */
    function isManager(address account) external view returns (bool);

    /**
     * @dev Give the manager role to `account`.
     */
    function addManager(address account) external;

    /**
     * @dev Renounce the manager role for the caller.
     */
    function renounceManager() external;

}

// SPDX-License-Identifier: MIT

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

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20AllowanceInterface {

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Burnable {
    
    /**
     * @dev Burns `amount` tokens from the caller account
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @dev Burns `amount` tokens from caller using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     */
    function burnFrom(address account, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface FreezableInterface {

    /**
     * @dev Returns the frozen state of `account`.
     */
    function frozen(address account) external view returns (bool);

    /**
     * @dev Freezes activity of `account` until unfrozen
     */
    function freeze(address account)  external;

    /**
     * @dev Restores `account` activity
     */
    function unfreeze(address account) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface PausableInterface {

    /**
     * @dev Returns the paused state of the contract.
     */
    function paused() external view returns (bool);

    /**
     * @dev Pauses state changing activity of the entire contract
     */
    function pause() external;

    /**
     * @dev Restores state changing activity to the entire contract
     */
    function unpause() external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../ERC20/interfaces/IERC20.sol";
interface RecoverableInterface {

    /**
     * @dev Recovers `amount` of ERC20 `token` sent to the contract.
     */
    function recover(IERC20 token, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "../XenoERC20Store.sol";

/* STORAGE */

contract ERC20Storage {
    XenoERC20Store internal x;
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./proxy/InitializableStore.sol";
import "./access/manager/ManagerRoleStore.sol";
import "./ERC20/ERC20Store.sol";
import "./extensions/pausable/PausableStore.sol";
import "./extensions/freezable/FreezableStore.sol";

struct XenoERC20Store {
    InitializableStore initializable;
    ManagerRoleStore managerRole;
    ERC20Store erc20;
    PausableStore pausable;
    FreezableStore freezable; // the slot taken by the struct of this is the last slotted item
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE LAYOUT */

struct InitializableStore {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool initializing;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "../base/RolesStore.sol";

/* STORAGE LAYOUT */

struct ManagerRoleStore {
    bool initialized;
    Role managers;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE LAYOUT */

struct ERC20Store {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    uint256 total;
    string named;
    string symboled;
    uint8 decimaled;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE LAYOUT */

struct PausableStore {
    bool isPaused;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE LAYOUT */

struct FreezableStore {
    mapping(address => bool) isFrozen;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE */

struct Role {
    mapping (address => bool) bearer;
    uint256 numberOfBearers;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/* LIBRARY IMPORTS */

import "./lib/Address.sol";
import "./lib/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./RolesStore.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    
    /* GETTER METHODS */

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function _has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles._has: ZERO_ADDRESS");
        return role.bearer[account];
    }

    /**
     * @dev Check if this role has at least one account assigned to it.
     * @return bool
     */
    function _atLeastOneBearer(uint256 numberOfBearers) internal pure returns (bool) {
        if (numberOfBearers > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Give an account access to this role.
     */
    function _add(
        Role storage role,
        address account
    )
        internal
    {
        require(
            !_has(role, account),
            "Roles._add: ALREADY_ASSIGNED"
        );

        role.bearer[account] = true;
        role.numberOfBearers += 1;
    }

    /**
     * @dev Remove an account's access to this role. (1 account minimum enforced for safeRemove)
     */
    function _safeRemove(
        Role storage role,
        address account
    )
        internal
    {
        require(
            _has(role, account),
            "Roles._safeRemove: INVALID_ACCOUNT"
        );
        uint256 numberOfBearers = role.numberOfBearers -= 1; // roles that use safeRemove must implement initializeRole() and onlyIntialized() and must set the contract deployer as the first account, otherwise this can underflow below zero
        require(
            _atLeastOneBearer(numberOfBearers),
            "Roles._safeRemove: MINIMUM_ACCOUNTS"
        );
        
        role.bearer[account] = false;
    }

    /**
     * @dev Remove an account's access to this role. (no minimum enforced)
     */
    function _remove(Role storage role, address account) internal {
        require(_has(role, account), "Roles.remove: INVALID_ACCOUNT");
        role.numberOfBearers -= 1;
        
        role.bearer[account] = false;
    }
}

// SPDX-License-Identifier: MIT

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
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ManagerRoleEvents {

    /**
     * @dev Emitted when `account` is assigned the manager Role.
     */
    event ManagerAdded(address indexed account);
    
    /**
     * @dev Emitted when `account` has renounced its manager Role.
     */
    event ManagerRemoved(address indexed account);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface FreezableEvents {
    
    /**
     * @dev Emitted when `account` is frozen by `manager`.
     */
    event Frozen(address manager, address account);

    /**
     * @dev Emitted when `account` is unfrozen by `manager`.
     */
    event Unfrozen(address manager, address account);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface PausableEvents {

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INTERFACE IMPORTS */

import "../../../ERC20/interfaces/IERC20.sol";

interface RecoverableEvents {
    
    /**
     * @dev Emitted when `account` recovers an `amount` ot `token`.
     */
    event Recovered(address account, IERC20 token, uint256 amount);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Events {

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}