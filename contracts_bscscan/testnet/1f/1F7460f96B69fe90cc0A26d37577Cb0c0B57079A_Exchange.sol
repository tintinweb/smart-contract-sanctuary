// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DFY is 
    Initializable, 
    ERC20Upgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable 
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("DeFi For You", "DFY");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
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

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
library StorageSlotUpgradeable {
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
pragma solidity ^0.8.4;

// Will be replaced by DFY-AccessControl when it's merged or later phases.
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IReputation.sol";


contract Reputation is 
    IReputation, 
    UUPSUpgradeable, 
    PausableUpgradeable, 
    AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;
    using AddressUpgradeable for address;

    /**
    * @dev PAUSER_ROLE: those who can pause the contract
    * by default this role is assigned _to the contract creator.
    */ 
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // mapping of user address's reputation score
    mapping (address => uint32) private _reputationScore;

    mapping(ReasonType => int8) _rewardByReason;

    mapping(address => bool) whitelistedContractCaller;

    event ReputationPointRewarded(address _user, uint256 _points, ReasonType _reasonType);
    event ReputationPointReduced(address _user, uint256 _points, ReasonType _reasonType);
    
    function initialize() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);

        //initialize Reward by Reason mapping values.
        _initializeRewardByReason();
    }

    // Reason for Reputation point adjustment
    /**
    * @dev Reputation points in correspondence with ReasonType 
    * LD_CREATE_PACKAGE         : +3    (0)
    * LD_CANCEL_PACKAGE         : -3    (1)
    * LD_REOPEN_PACKAGE         : +3    (2)
    * LD_GENERATE_CONTRACT      : +1    (3)
    * LD_CREATE_OFFER           : +2    (4)
    * LD_CANCEL_OFFER           : -2    (5)
    * LD_ACCEPT_OFFER           : +1    (6)
    * BR_CREATE_COLLATERAL      : +3    (7)
    * BR_CANCEL_COLLATERAL      : -3    (8)
    * BR_ONTIME_PAYMENT         : +1    (9)
    * BR_LATE_PAYMENT           : -1    (10)
    * BR_ACCEPT_OFFER           : +1    (11)
    * BR_CONTRACT_COMPLETE      : +5    (12)
    * BR_CONTRACT_DEFAULTED     : -5    (13)
    * LD_REVIEWED_BY_BORROWER_1 : +1    (14)
    * LD_REVIEWED_BY_BORROWER_2 : +2    (15)
    * LD_REVIEWED_BY_BORROWER_3 : +3    (16)
    * LD_REVIEWED_BY_BORROWER_4 : +4    (17)
    * LD_REVIEWED_BY_BORROWER_5 : +5    (18)
    * LD_KYC                    : +5    (19)
    * BR_REVIEWED_BY_LENDER_1   : +1    (20)
    * BR_REVIEWED_BY_LENDER_2   : +2    (21)
    * BR_REVIEWED_BY_LENDER_3   : +3    (22)
    * BR_REVIEWED_BY_LENDER_4   : +4    (23)
    * BR_REVIEWED_BY_LENDER_5   : +5    (24)
    * BR_KYC                    : +5    (25)
    */
    function _initializeRewardByReason() internal virtual {
        _rewardByReason[ReasonType.LD_CREATE_PACKAGE]    =  3;  // index: 0
        _rewardByReason[ReasonType.LD_CANCEL_PACKAGE]    = -3;  // index: 1
        _rewardByReason[ReasonType.LD_REOPEN_PACKAGE]    =  3;  // index: 2
        _rewardByReason[ReasonType.LD_GENERATE_CONTRACT] =  1;  // index: 3
        _rewardByReason[ReasonType.LD_CREATE_OFFER]      =  2;  // index: 4
        _rewardByReason[ReasonType.LD_CANCEL_OFFER]      = -2;  // index: 5
        _rewardByReason[ReasonType.LD_ACCEPT_OFFER]      =  1;  // index: 6
        _rewardByReason[ReasonType.BR_CREATE_COLLATERAL] =  3;  // index: 7
        _rewardByReason[ReasonType.BR_CANCEL_COLLATERAL] = -3;  // index: 8
        _rewardByReason[ReasonType.BR_ONTIME_PAYMENT]    =  1;  // index: 9
        _rewardByReason[ReasonType.BR_LATE_PAYMENT]      = -1;  // index: 10
        _rewardByReason[ReasonType.BR_ACCEPT_OFFER]      =  1;  // index: 11
        _rewardByReason[ReasonType.BR_CONTRACT_COMPLETE] =  5;  // index: 12
        _rewardByReason[ReasonType.BR_CONTRACT_DEFAULTED]= -5;  // index: 13
    }

    function initializeRewardByReason() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _initializeRewardByReason();
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function version() public virtual pure returns (string memory) {
        return "1.0.2";
    }

    modifier isNotZeroAddress(address _to) {
        require(_to != address(0), "DFY: Reward pawn reputation to the zero address");
        _;
    }

    modifier onlyEOA(address _to) {
        require(!_to.isContract(), "DFY: Reward pawn reputation to a contract address");
        _;
    }

    modifier onlyWhitelistedContractCaller(address _from) {
        // Caller must be a contract
        require(_from.isContract(), "DFY: Calling Reputation adjustment from a non-contract address");

        // Caller must be whitelisted
        require(whitelistedContractCaller[_from] == true, "DFY: Caller is not allowed");
        _;
    }

    /** 
    * @dev Add a contract address that use Reputation to whitelist
    * @param _caller is the contract address being whitelisted=
    */
    function addWhitelistedContractCaller(address _caller) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_caller.isContract(), "DFY: Setting reputation contract caller to a non-contract address");
        whitelistedContractCaller[_caller] = true;
    }

    /** 
    * @dev remove a contract address from whitelist
    * @param _caller is the contract address being removed
    */
    function removeWhitelistedContractCaller(address _caller) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete whitelistedContractCaller[_caller];
    }

    /** 
    * @dev check if an address is whitelisted
    * @param _contract is the address being verified
    */
    function isWhitelistedContractCaller(address _contract) external view returns (bool) {
        return whitelistedContractCaller[_contract];
    }

    /**
    * @dev Get the reputation score of an account
    */
    function getReputationScore(address _address) external virtual override view returns(uint32) {
        return _reputationScore[_address];
    }

    /**
    * @dev Return the absolute value of a signed integer
    * @param _input is any signed integer
    * @return an unsigned integer that is the absolute value of _input
    */
    function abs(int256 _input) internal pure returns (uint256) {
        return _input >= 0 ? uint256(_input) : uint256(_input * -1);
    }

    /**
    * @dev Adjust reputation score base on the input reason
    * @param _user is the address of the user whose reputation score is being adjusted.
    * @param _reasonType is the reason of the adjustment.
    */
    function adjustReputationScore(
        address _user, 
        ReasonType _reasonType) 
        external override
        whenNotPaused isNotZeroAddress(_user) onlyEOA(_user) onlyWhitelistedContractCaller(_msgSender())
    {
        int8 pointsByReason     = _rewardByReason[_reasonType];
        uint256 points          = abs(pointsByReason);

        // Check if the points mapped by _reasonType is greater than 0 or not
        if(pointsByReason >= 0) {
            // If pointsByReason is greater than 0, reward points to the user.
            _rewardReputationScore(_user, points, _reasonType);
        }
        else {
            // If pointByReason is lesser than 0, substract the points from user's current score.
            _reduceReputationScore(_user, points, _reasonType);
        }
    }
    
    /** 
    * @dev Reward Reputation score to a user
    * @param _to is the address whose reputation score is going to be adjusted
    * @param _points is the points will be added to _to's reputation score (unsigned integer)
    * @param _reasonType is the reason of score adjustment
    */    
    function _rewardReputationScore(
        address _to, 
        uint256 _points, 
        ReasonType _reasonType) 
        internal
    {
        uint256 currentScore = uint256(_reputationScore[_to]);
        _reputationScore[_to] = currentScore.add(_points).toUint32();

        emit ReputationPointRewarded(_to, _points, _reasonType);
    }

    /** 
    * @dev Reduce Reputation score of a user.
    * @param _from is the address whose reputation score is going to be adjusted
    * @param _points is the points will be subtracted from _from's reputation score (unsigned integer)
    * @param _reasonType is the reason of score adjustment
    */  
    function _reduceReputationScore(
        address _from, 
        uint256 _points, 
        ReasonType _reasonType) 
        internal 
    {
        uint256 currentScore = uint256(_reputationScore[_from]);
        
        (bool success, uint result) = currentScore.trySub(_points);
        
        // if the current reputation score is lesser than the reducing points, 
        // set reputation score to 0
        _reputationScore[_from] = success == true ? result.toUint32() : 0;

        emit ReputationPointReduced(_from, _points, _reasonType);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

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
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
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
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IReputation {
    
    // Reason for Reputation point adjustment
    /**
    * @dev Reputation points in correspondence with ReasonType 
    * LD_CREATE_PACKAGE         : +3    (0)
    * LD_CANCEL_PACKAGE         : -3    (1)
    * LD_REOPEN_PACKAGE         : +3    (2)
    * LD_GENERATE_CONTRACT      : +1    (3)
    * LD_CREATE_OFFER           : +2    (4)
    * LD_CANCEL_OFFER           : -2    (5)
    * LD_ACCEPT_OFFER           : +1    (6)
    * BR_CREATE_COLLATERAL      : +3    (7)
    * BR_CANCEL_COLLATERAL      : -3    (8)
    * BR_ONTIME_PAYMENT         : +1    (9)
    * BR_LATE_PAYMENT           : -1    (10)
    * BR_ACCEPT_OFFER           : +1    (11)
    * BR_CONTRACT_COMPLETE      : +5    (12)
    * BR_CONTRACT_DEFAULTED     : -5    (13)
    * LD_REVIEWED_BY_BORROWER_1 : +1    (14)
    * LD_REVIEWED_BY_BORROWER_2 : +2    (15)
    * LD_REVIEWED_BY_BORROWER_3 : +3    (16)
    * LD_REVIEWED_BY_BORROWER_4 : +4    (17)
    * LD_REVIEWED_BY_BORROWER_5 : +5    (18)
    * LD_KYC                    : +5    (19)
    * BR_REVIEWED_BY_LENDER_1   : +1    (20)
    * BR_REVIEWED_BY_LENDER_2   : +2    (21)
    * BR_REVIEWED_BY_LENDER_3   : +3    (22)
    * BR_REVIEWED_BY_LENDER_4   : +4    (23)
    * BR_REVIEWED_BY_LENDER_5   : +5    (24)
    * BR_KYC                    : +5    (25)
    */
    
    enum ReasonType {
        LD_CREATE_PACKAGE, 
        LD_CANCEL_PACKAGE,
        LD_REOPEN_PACKAGE,
        LD_GENERATE_CONTRACT,
        LD_CREATE_OFFER,
        LD_CANCEL_OFFER,
        LD_ACCEPT_OFFER,
        BR_CREATE_COLLATERAL,
        BR_CANCEL_COLLATERAL,
        BR_ONTIME_PAYMENT,
        BR_LATE_PAYMENT,
        BR_ACCEPT_OFFER,
        BR_CONTRACT_COMPLETE,
        BR_CONTRACT_DEFAULTED,
        
        LD_REVIEWED_BY_BORROWER_1,
        LD_REVIEWED_BY_BORROWER_2,
        LD_REVIEWED_BY_BORROWER_3,
        LD_REVIEWED_BY_BORROWER_4,
        LD_REVIEWED_BY_BORROWER_5,
        LD_KYC,

        BR_REVIEWED_BY_LENDER_1,
        BR_REVIEWED_BY_LENDER_2,
        BR_REVIEWED_BY_LENDER_3,
        BR_REVIEWED_BY_LENDER_4,
        BR_REVIEWED_BY_LENDER_5,
        BR_KYC
    }
    
    /**
    * @dev Get the reputation score of an account
    */
    function getReputationScore(address _address) external view returns(uint32);

    function adjustReputationScore(address _user, ReasonType _reasonType) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./IPawn.sol";
import "../reputation/IReputation.sol";
import "../exchange/Exchange.sol";
import "../pawn-p2p-v2/PawnP2PLoanContract.sol";

contract PawnContract is IPawn, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CollateralLib for Collateral;
    using OfferLib for Offer;
    using PawnPackageLib for PawnShopPackage;

    mapping(address => uint256) public whitelistCollateral;
    address public operator;
    address public feeWallet = address(this);
    uint256 public penaltyRate;
    uint256 public systemFeeRate;
    uint256 public lateThreshold;
    uint256 public prepaidFeeRate;
    uint256 public ZOOM;
    bool public initialized = false;
    address public admin;

    /**
     * @dev initialize function
     * @param _zoom is coefficient used to represent risk params
     */

    function initialize(uint256 _zoom) external notInitialized {
        ZOOM = _zoom;
        initialized = true;
        admin = address(msg.sender);
    }

    function setOperator(address _newOperator) external onlyAdmin {
        operator = _newOperator;
    }

    function setFeeWallet(address _newFeeWallet) external onlyAdmin {
        feeWallet = _newFeeWallet;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unPause() external onlyAdmin {
        _unpause();
    }

    /**
     * @dev set fee for each token
     * @param _feeRate is percentage of tokens to pay for the transaction
     */

    function setSystemFeeRate(uint256 _feeRate) external onlyAdmin {
        systemFeeRate = _feeRate;
    }

    /**
     * @dev set fee for each token
     * @param _feeRate is percentage of tokens to pay for the penalty
     */
    function setPenaltyRate(uint256 _feeRate) external onlyAdmin {
        penaltyRate = _feeRate;
    }

    /**
     * @dev set fee for each token
     * @param _threshold is number of time allowed for late repayment
     */
    function setLateThreshold(uint256 _threshold) external onlyAdmin {
        lateThreshold = _threshold;
    }

    function setPrepaidFeeRate(uint256 _feeRate) external onlyAdmin {
        prepaidFeeRate = _feeRate;
    }

    function setWhitelistCollateral(address _token, uint256 _status)
        external
        onlyAdmin
    {
        whitelistCollateral[_token] = _status;
    }

    modifier notInitialized() {
        require(!initialized, "-2"); //initialized
        _;
    }

    modifier isInitialized() {
        require(initialized, "-3"); //not-initialized
        _;
    }

    function _onlyOperator() private view {
        require(operator == msg.sender, "-0"); //operator
    }

    modifier onlyOperator() {
        // require(operator == msg.sender, "operator");
        _onlyOperator();
        _;
    }

    function _onlyAdmin() private view {
        require(admin == msg.sender, "-1"); //admin
    }

    modifier onlyAdmin() {
        // require(admin == msg.sender, "admin");
        _onlyAdmin();
        _;
    }

    function _whenNotPaused() private view {
        require(!paused(), "-4"); //Pausable: paused
    }

    modifier whenContractNotPaused() {
        // require(!paused(), "Pausable: paused");
        _whenNotPaused();
        _;
    }

    function emergencyWithdraw(address _token)
        external
        override
        onlyAdmin
        whenPaused
    {
        PawnLib.safeTransfer(
            _token,
            address(this),
            admin,
            PawnLib.calculateAmount(_token, address(this))
        );
    }

    /** ========================= COLLATERAL FUNCTIONS & STATES ============================= */
    uint256 public numberCollaterals;
    mapping(uint256 => Collateral) public collaterals;

    event CreateCollateralEvent(uint256 collateralId, Collateral data);

    event WithdrawCollateralEvent(
        uint256 collateralId,
        address collateralOwner
    );

    /**
     * @dev create Collateral function, collateral will be stored in this contract
     * @param _collateralAddress is address of collateral
     * @param _packageId is id of pawn shop package
     * @param _amount is amount of token
     * @param _loanAsset is address of loan token
     * @param _expectedDurationQty is expected duration
     * @param _expectedDurationType is expected duration type
     */
    function createCollateral(
        address _collateralAddress,
        int256 _packageId,
        uint256 _amount,
        address _loanAsset,
        uint256 _expectedDurationQty,
        LoanDurationType _expectedDurationType
    ) external payable whenContractNotPaused returns (uint256 _idx) {
        //check whitelist collateral token
        require(whitelistCollateral[_collateralAddress] == 1, "0"); //n-sup-col
        //validate: cannot use BNB as loanAsset
        require(_loanAsset != address(0), "1"); //bnb

        //id of collateral
        _idx = numberCollaterals;

        //create new collateral
        Collateral storage newCollateral = collaterals[_idx];

        newCollateral.create(
            _collateralAddress,
            _amount,
            _loanAsset,
            _expectedDurationQty,
            _expectedDurationType
        );

        ++numberCollaterals;

        emit CreateCollateralEvent(_idx, newCollateral);

        if (_packageId >= 0) {
            //Package must active
            PawnShopPackage storage pawnShopPackage = pawnShopPackages[
                uint256(_packageId)
            ];
            require(
                pawnShopPackage.status == PawnShopPackageStatus.ACTIVE,
                "2"
            ); //pack

            // Submit collateral to package
            CollateralAsLoanRequestListStruct
                storage loanRequestListStruct = collateralAsLoanRequestMapping[
                    _idx
                ];

            newCollateral.submitToLoanPackage(
                uint256(_packageId),
                loanRequestListStruct
            );

            emit SubmitPawnShopPackage(
                uint256(_packageId),
                _idx,
                LoanRequestStatus.PENDING
            );
        }

        // transfer to this contract
        PawnLib.safeTransfer(
            _collateralAddress,
            msg.sender,
            address(this),
            _amount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_CREATE_COLLATERAL
        );
    }

    /**
     * @dev cancel collateral function and return back collateral
     * @param  _collateralId is id of collateral
     */
    function withdrawCollateral(uint256 _collateralId)
        external
        whenContractNotPaused
    {
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.owner == msg.sender, "0"); //owner
        require(collateral.status == CollateralStatus.OPEN, "1"); //col

        PawnLib.safeTransfer(
            collateral.collateralAddress,
            address(this),
            collateral.owner,
            collateral.amount
        );

        // Remove relation of collateral and offers
        CollateralOfferList
            storage collateralOfferList = collateralOffersMapping[
                _collateralId
            ];
        if (collateralOfferList.isInit == true) {
            for (
                uint256 i = 0;
                i < collateralOfferList.offerIdList.length;
                i++
            ) {
                uint256 offerId = collateralOfferList.offerIdList[i];
                Offer storage offer = collateralOfferList.offerMapping[offerId];
                emit CancelOfferEvent(offerId, _collateralId, offer.owner);
            }
            delete collateralOffersMapping[_collateralId];
        }

        delete collaterals[_collateralId];
        emit WithdrawCollateralEvent(_collateralId, msg.sender);

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_CANCEL_COLLATERAL
        );
    }

    function updateCollateralStatus(
        uint256 _collateralId,
        CollateralStatus _status
    ) external override whenContractNotPaused {
        require(
            _msgSender() == address(pawnLoanContract) ||
                _msgSender() == operator ||
                _msgSender() == admin,
            "not-allow"
        );

        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.DOING, "invalid-col");

        collateral.status = _status;
    }

    /** ========================= OFFER FUNCTIONS & STATES ============================= */
    uint256 public numberOffers;

    mapping(uint256 => CollateralOfferList) public collateralOffersMapping;

    event CreateOfferEvent(uint256 offerId, uint256 collateralId, Offer data);

    event CancelOfferEvent(
        uint256 offerId,
        uint256 collateralId,
        address offerOwner
    );

    /**
     * @dev create Collateral function, collateral will be stored in this contract
     * @param _collateralId is id of collateral
     * @param _repaymentAsset is address of repayment token
     * @param _duration is duration of this offer
     * @param _loanDurationType is type for calculating loan duration
     * @param _repaymentCycleType is type for calculating repayment cycle
     * @param _liquidityThreshold is ratio of assets to be liquidated
     */
    function createOffer(
        uint256 _collateralId,
        address _repaymentAsset,
        uint256 _loanAmount,
        uint256 _duration,
        uint256 _interest,
        uint8 _loanDurationType,
        uint8 _repaymentCycleType,
        uint256 _liquidityThreshold
    ) external whenContractNotPaused returns (uint256 _idx) {
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.OPEN, "0"); // col
        // validate not allow for collateral owner to create offer
        require(collateral.owner != msg.sender, "1"); // owner
        // Validate ower already approve for this contract to withdraw
        require(
            IERC20Upgradeable(collateral.loanAsset).allowance(
                msg.sender,
                address(this)
            ) >= _loanAmount,
            "2"
        ); // not-apr

        // Get offers of collateral
        CollateralOfferList
            storage collateralOfferList = collateralOffersMapping[
                _collateralId
            ];
        if (!collateralOfferList.isInit) {
            collateralOfferList.isInit = true;
        }
        // Create offer id
        _idx = numberOffers;

        // Create offer data
        Offer storage _offer = collateralOfferList.offerMapping[_idx];

        _offer.create(
            _repaymentAsset,
            _loanAmount,
            _duration,
            _interest,
            _loanDurationType,
            _repaymentCycleType,
            _liquidityThreshold
        );

        collateralOfferList.offerIdList.push(_idx);

        ++numberOffers;

        emit CreateOfferEvent(_idx, _collateralId, _offer);

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CREATE_OFFER
        );
    }

    /**
     * @dev cancel offer function, used for cancel offer
     * @param  _offerId is id of offer
     * @param _collateralId is id of collateral associated with offer
     */
    function cancelOffer(uint256 _offerId, uint256 _collateralId)
        external
        whenContractNotPaused
    {
        CollateralOfferList
            storage collateralOfferList = collateralOffersMapping[
                _collateralId
            ];
        require(collateralOfferList.isInit == true, "0"); // col

        Offer storage offer = collateralOfferList.offerMapping[_offerId];

        offer.cancel(_offerId, collateralOfferList);

        delete collateralOfferList.offerIdList[
            collateralOfferList.offerIdList.length - 1
        ];
        emit CancelOfferEvent(_offerId, _collateralId, msg.sender);

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CANCEL_OFFER
        );
    }

    /** ========================= PAWNSHOP PACKAGE FUNCTIONS & STATES ============================= */
    uint256 public numberPawnShopPackages;
    mapping(uint256 => PawnShopPackage) public pawnShopPackages;

    event CreatePawnShopPackage(uint256 packageId, PawnShopPackage data);

    event ChangeStatusPawnShopPackage(
        uint256 packageId,
        PawnShopPackageStatus status
    );

    function createPawnShopPackage(
        PawnShopPackageType _packageType,
        address _loanToken,
        Range calldata _loanAmountRange,
        address[] calldata _collateralAcceptance,
        uint256 _interest,
        uint256 _durationType,
        Range calldata _durationRange,
        address _repaymentAsset,
        LoanDurationType _repaymentCycleType,
        uint256 _loanToValue,
        uint256 _loanToValueLiquidationThreshold
    ) external whenContractNotPaused returns (uint256 _idx) {
        _idx = numberPawnShopPackages;

        // Validataion logic: whitelist collateral, ranges must have upper greater than lower, duration type
        for (uint256 i = 0; i < _collateralAcceptance.length; i++) {
            require(whitelistCollateral[_collateralAcceptance[i]] == 1, "0"); // col
        }

        require(_loanAmountRange.lowerBound < _loanAmountRange.upperBound, "1"); // loan-rge
        require(_durationRange.lowerBound < _durationRange.upperBound, "2"); // dur-rge
        require(_durationType < 2, "3"); // dur-type

        require(_loanToken != address(0), "4"); // bnb

        //create new collateral
        PawnShopPackage storage newPackage = pawnShopPackages[_idx];

        newPackage.create(
            _packageType,
            _loanToken,
            _loanAmountRange,
            _collateralAcceptance,
            _interest,
            _durationType,
            _durationRange,
            _repaymentAsset,
            _repaymentCycleType,
            _loanToValue,
            _loanToValueLiquidationThreshold
        );

        ++numberPawnShopPackages;
        emit CreatePawnShopPackage(_idx, newPackage);

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CREATE_PACKAGE
        );
    }

    function activePawnShopPackage(uint256 _packageId)
        external
        whenContractNotPaused
    {
        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];
        require(pawnShopPackage.owner == msg.sender, "0"); // owner
        require(pawnShopPackage.status == PawnShopPackageStatus.INACTIVE, "1"); // pack

        pawnShopPackage.status = PawnShopPackageStatus.ACTIVE;
        emit ChangeStatusPawnShopPackage(
            _packageId,
            PawnShopPackageStatus.ACTIVE
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_REOPEN_PACKAGE
        );
    }

    function deactivePawnShopPackage(uint256 _packageId)
        external
        whenContractNotPaused
    {
        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];

        // Deactivate package
        require(pawnShopPackage.owner == msg.sender, "0"); // owner
        require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, "1"); // pack

        pawnShopPackage.status = PawnShopPackageStatus.INACTIVE;
        emit ChangeStatusPawnShopPackage(
            _packageId,
            PawnShopPackageStatus.INACTIVE
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CANCEL_PACKAGE
        );
    }

    /** ========================= SUBMIT & ACCEPT WORKFLOW OF PAWNSHOP PACKAGE FUNCTIONS & STATES ============================= */

    mapping(uint256 => CollateralAsLoanRequestListStruct)
        public collateralAsLoanRequestMapping; // Map from collateral to loan request
    event SubmitPawnShopPackage(
        uint256 packageId,
        uint256 collateralId,
        LoanRequestStatus status
    );

    /**
     * @dev Submit Collateral to Package function, collateral will be submit to pawnshop package
     * @param _collateralId is id of collateral
     * @param _packageId is id of pawn shop package
     */
    function submitCollateralToPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) external whenContractNotPaused {
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.owner == msg.sender, "0"); // owner
        require(collateral.status == CollateralStatus.OPEN, "1"); // col

        PawnShopPackage storage pawnShopPackage = pawnShopPackages[_packageId];
        require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, "2"); // pack

        // VALIDATE HAVEN'T SUBMIT TO PACKAGE YET
        CollateralAsLoanRequestListStruct
            storage loanRequestListStruct = collateralAsLoanRequestMapping[
                _collateralId
            ];

        if (loanRequestListStruct.isInit == true) {
            LoanRequestStatusStruct storage statusStruct = loanRequestListStruct
                .loanRequestToPawnShopPackageMapping[_packageId];

            require(statusStruct.isInit == false, "3"); // subed
        }

        // Save
        collateral.submitToLoanPackage(_packageId, loanRequestListStruct);
        emit SubmitPawnShopPackage(
            _packageId,
            _collateralId,
            LoanRequestStatus.PENDING
        );
    }

    function withdrawCollateralFromPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) external whenContractNotPaused {
        // Collateral must OPEN
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.OPEN, "0"); // col
        // Sender is collateral owner
        require(collateral.owner == msg.sender, "1"); // owner
        // collateral-package status must pending
        CollateralAsLoanRequestListStruct
            storage loanRequestListStruct = collateralAsLoanRequestMapping[
                _collateralId
            ];
        LoanRequestStatusStruct
            storage loanRequestStatus = loanRequestListStruct
                .loanRequestToPawnShopPackageMapping[_packageId];
        require(loanRequestStatus.status == LoanRequestStatus.PENDING, "2"); // col-pack

        // _removeCollateralFromPackage(_collateralId, _packageId);

        collateral.removeFromLoanPackage(_packageId, loanRequestListStruct);
        emit SubmitPawnShopPackage(
            _packageId,
            _collateralId,
            LoanRequestStatus.CANCEL
        );
    }

    function acceptCollateralOfPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) external whenContractNotPaused {
        (
            Collateral storage collateral,
            PawnShopPackage storage pawnShopPackage,
            CollateralAsLoanRequestListStruct storage loanRequestListStruct,
            LoanRequestStatusStruct storage statusStruct
        ) = verifyCollateralPackageData(
                _collateralId,
                _packageId,
                CollateralStatus.OPEN,
                LoanRequestStatus.PENDING
            );

        // Check for owner of packageId
        require(
            pawnShopPackage.owner == msg.sender || msg.sender == operator,
            "0"
        ); // owner-or-oper

        // Execute accept => change status of loan request to ACCEPTED, wait for system to generate contract
        // Update status of loan request between _collateralId and _packageId to Accepted
        statusStruct.status = LoanRequestStatus.ACCEPTED;
        collateral.status = CollateralStatus.DOING;

        // Remove status of loan request between _collateralId and other packageId then emit event Cancel
        for (
            uint256 i = 0;
            i < loanRequestListStruct.pawnShopPackageIdList.length;
            i++
        ) {
            uint256 packageId = loanRequestListStruct.pawnShopPackageIdList[i];
            if (packageId != _packageId) {
                // Remove status
                delete loanRequestListStruct
                    .loanRequestToPawnShopPackageMapping[packageId];
                emit SubmitPawnShopPackage(
                    packageId,
                    _collateralId,
                    LoanRequestStatus.CANCEL
                );
            }
        }
        delete loanRequestListStruct.pawnShopPackageIdList;
        loanRequestListStruct.pawnShopPackageIdList.push(_packageId);

        // Remove relation of collateral and offers
        CollateralOfferList
            storage collateralOfferList = collateralOffersMapping[
                _collateralId
            ];
        if (collateralOfferList.isInit == true) {
            for (
                uint256 i = 0;
                i < collateralOfferList.offerIdList.length;
                i++
            ) {
                uint256 offerId = collateralOfferList.offerIdList[i];
                Offer storage offer = collateralOfferList.offerMapping[offerId];
                emit CancelOfferEvent(offerId, _collateralId, offer.owner);
            }
            delete collateralOffersMapping[_collateralId];
        }

        generateContractForCollateralAndPackage(_collateralId, _packageId);
    }

    function rejectCollateralOfPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) external whenContractNotPaused {
        (
            Collateral storage collateral,
            PawnShopPackage storage pawnShopPackage,
            CollateralAsLoanRequestListStruct storage loanRequestListStruct,

        ) = verifyCollateralPackageData(
                _collateralId,
                _packageId,
                CollateralStatus.OPEN,
                LoanRequestStatus.PENDING
            );
        require(pawnShopPackage.owner == msg.sender);

        // _removeCollateralFromPackage(_collateralId, _packageId);
        collateral.removeFromLoanPackage(_packageId, loanRequestListStruct);
        emit SubmitPawnShopPackage(
            _packageId,
            _collateralId,
            LoanRequestStatus.REJECTED
        );
    }

    function verifyCollateralPackageData(
        uint256 _collateralId,
        uint256 _packageId,
        CollateralStatus _requiredCollateralStatus,
        LoanRequestStatus _requiredLoanRequestStatus
    )
        internal
        view
        returns (
            Collateral storage collateral,
            PawnShopPackage storage pawnShopPackage,
            CollateralAsLoanRequestListStruct storage loanRequestListStruct,
            LoanRequestStatusStruct storage statusStruct
        )
    {
        collateral = collaterals[_collateralId];
        pawnShopPackage = pawnShopPackages[_packageId];
        loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];

        statusStruct = collateral.checkCondition(
            _packageId,
            pawnShopPackage,
            loanRequestListStruct,
            _requiredCollateralStatus,
            _requiredLoanRequestStatus
        );
    }

    /** ========================= CONTRACT RELATED FUNCTIONS & STATES ============================= */
    uint256 public numberContracts;
    mapping(uint256 => Contract) public contracts;

    /** ================================ 1. ACCEPT OFFER (FOR P2P WORKFLOWS) ============================= */
    // Old LoanContractCreatedEvent

    event LoanContractCreatedEvent(
        address fromAddress,
        uint256 contractId,
        Contract data
    );

    /**
     * @dev accept offer and create contract between collateral and offer
     * @param  _collateralId is id of collateral
     * @param  _offerId is id of offer
     */
    function acceptOffer(uint256 _collateralId, uint256 _offerId)
        external
        whenContractNotPaused
    {
        Collateral storage collateral = collaterals[_collateralId];
        require(msg.sender == collateral.owner, "0"); // owner
        require(collateral.status == CollateralStatus.OPEN, "1"); // col

        CollateralOfferList
            storage collateralOfferList = collateralOffersMapping[
                _collateralId
            ];
        require(collateralOfferList.isInit == true, "2"); // col-off
        Offer storage offer = collateralOfferList.offerMapping[_offerId];
        require(offer.isInit == true, "3"); // not-sent
        require(offer.status == OfferStatus.PENDING, "4"); // unavail

        // Prepare contract raw data
        uint256 exchangeRate = exchange.exchangeRateofOffer(
            collateral.loanAsset,
            offer.repaymentAsset
        );
        ContractRawData memory contractData = ContractRawData(
            _collateralId,
            collateral.owner,
            collateral.loanAsset,
            collateral.collateralAddress,
            collateral.amount,
            -1,
            int256(_offerId),
            exchangeRate, /* Exchange rate */
            offer.loanAmount,
            offer.owner,
            offer.repaymentAsset,
            offer.interest,
            offer.loanDurationType,
            offer.liquidityThreshold,
            offer.duration
        );

        // Create Contract
        uint256 contractId = pawnLoanContract.createContract(contractData);

        // change status of offer and collateral
        offer.status = OfferStatus.ACCEPTED;
        collateral.status = CollateralStatus.DOING;

        // Cancel other offer sent to this collateral
        for (uint256 i = 0; i < collateralOfferList.offerIdList.length; i++) {
            uint256 thisOfferId = collateralOfferList.offerIdList[i];
            if (thisOfferId != _offerId) {
                Offer storage thisOffer = collateralOfferList.offerMapping[
                    thisOfferId
                ];
                emit CancelOfferEvent(i, _collateralId, thisOffer.owner);

                delete collateralOfferList.offerMapping[thisOfferId];
            }
        }
        delete collateralOfferList.offerIdList;
        collateralOfferList.offerIdList.push(_offerId);

        // transfer loan asset to collateral owner
        PawnLib.safeTransfer(
            collateral.loanAsset,
            offer.owner,
            collateral.owner,
            offer.loanAmount
        );

        // transfer collateral to LoanContract
        PawnLib.safeTransfer(
            collateral.collateralAddress,
            address(this),
            address(pawnLoanContract),
            collateral.amount
        );

        // PawnLib.safeTransfer(
        //     newContract.terms.loanAsset,
        //     newContract.terms.lender,
        //     newContract.terms.borrower,
        //     newContract.terms.loanAmount
        // );

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_ACCEPT_OFFER
        );
        reputation.adjustReputationScore(
            offer.owner,
            IReputation.ReasonType.LD_ACCEPT_OFFER
        );

        // Generate first payment period
        pawnLoanContract.closePaymentRequestAndStartNew(
            0,
            contractId,
            PaymentRequestTypeEnum.INTEREST
        );
    }

    /** ================================ 2. ACCEPT COLLATERAL (FOR PAWNSHOP PACKAGE WORKFLOWS) ============================= */

    /**
     * @dev create contract between package and collateral
     * @param  _collateralId is id of collateral
     * @param  _packageId is id of package
     */
    function generateContractForCollateralAndPackage(
        uint256 _collateralId,
        uint256 _packageId
    ) internal whenContractNotPaused {
        (
            Collateral storage collateral,
            PawnShopPackage storage pawnShopPackage,
            ,
            LoanRequestStatusStruct storage statusStruct
        ) = verifyCollateralPackageData(
                _collateralId,
                _packageId,
                CollateralStatus.DOING,
                LoanRequestStatus.ACCEPTED
            );

        // function tinh loanAmount va Exchange Rate trong contract Exchange.
        (uint256 loanAmount, uint256 exchangeRate) = exchange
            .calculateLoanAmountAndExchangeRate(
                collaterals[_collateralId],
                pawnShopPackages[_packageId]
            );

        // uint loanAmount = 1000 * 10 ** 18;
        // uint exchangeRate = 1 * 10 ** 18;

        // Prepare contract raw data
        ContractRawData memory contractData = ContractRawData(
            _collateralId,
            collateral.owner,
            collateral.loanAsset,
            collateral.collateralAddress,
            collateral.amount,
            int256(_packageId),
            -1,
            exchangeRate,
            loanAmount,
            pawnShopPackage.owner,
            pawnShopPackage.repaymentAsset,
            pawnShopPackage.interest,
            pawnShopPackage.repaymentCycleType,
            pawnShopPackage.loanToValueLiquidationThreshold,
            collateral.expectedDurationQty
        );
        // Create Contract
        uint256 contractId = pawnLoanContract.createContract(contractData);

        // Change status of collateral loan request to package to CONTRACTED
        statusStruct.status == LoanRequestStatus.CONTRACTED;
        emit SubmitPawnShopPackage(
            _packageId,
            _collateralId,
            LoanRequestStatus.CONTRACTED
        );

        // Transfer loan token from lender to borrower
        PawnLib.safeTransfer(
            collateral.loanAsset,
            pawnShopPackage.owner,
            collateral.owner,
            loanAmount
        );

        // transfer collateral to LoanContract
        PawnLib.safeTransfer(
            collateral.collateralAddress,
            address(this),
            address(pawnLoanContract),
            collateral.amount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            pawnShopPackage.owner,
            IReputation.ReasonType.LD_GENERATE_CONTRACT
        );

        //ki dau tien BEId = 0
        pawnLoanContract.closePaymentRequestAndStartNew(
            0,
            contractId,
            PaymentRequestTypeEnum.INTEREST
        );
    }

    /** ================================ 3. PAYMENT REQUEST & REPAYMENT WORKLOWS ============================= */
    /** ===================================== 3.1. PAYMENT REQUEST ============================= */
    mapping(uint256 => PaymentRequest[]) public contractPaymentRequestMapping;

    // Old PaymentRequestEvent
    event PaymentRequestEvent(uint256 contractId, PaymentRequest data);

    function closePaymentRequestAndStartNew(
        uint256 _contractId,
        uint256 _remainingLoan,
        uint256 _nextPhrasePenalty,
        uint256 _nextPhraseInterest,
        uint256 _dueDateTimestamp,
        PaymentRequestTypeEnum _paymentRequestType,
        bool _chargePrepaidFee
    ) external whenNotPaused onlyOperator {
        Contract storage currentContract = contractMustActive(_contractId);

        // Check if number of requests is 0 => create new requests, if not then update current request as LATE or COMPLETE and create new requests
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        if (requests.length > 0) {
            // not first phrase, get previous request
            PaymentRequest storage previousRequest = requests[
                requests.length - 1
            ];

            // Validate: time must over due date of current payment
            require(block.timestamp >= previousRequest.dueDateTimestamp, "0"); // time-not-due

            // Validate: remaining loan must valid
            require(previousRequest.remainingLoan == _remainingLoan, "1"); // remain

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(
                _dueDateTimestamp <= currentContract.terms.contractEndDate,
                "2"
            ); // contr-end
            require(
                _dueDateTimestamp > previousRequest.dueDateTimestamp ||
                    _dueDateTimestamp == 0,
                "3"
            ); // less-th-prev

            // update previous
            // check for remaining penalty and interest, if greater than zero then is Lated, otherwise is completed
            if (
                previousRequest.remainingInterest > 0 ||
                previousRequest.remainingPenalty > 0
            ) {
                previousRequest.status = PaymentRequestStatusEnum.LATE;

                // Adjust reputation score
                reputation.adjustReputationScore(
                    currentContract.terms.borrower,
                    IReputation.ReasonType.BR_LATE_PAYMENT
                );

                // Update late counter of contract
                currentContract.lateCount += 1;

                // Check for late threshold reach
                if (
                    currentContract.terms.lateThreshold <=
                    currentContract.lateCount
                ) {
                    // Execute liquid
                    _liquidationExecution(
                        _contractId,
                        ContractLiquidedReasonType.LATE
                    );
                    return;
                }
            } else {
                previousRequest.status = PaymentRequestStatusEnum.COMPLETE;

                // Adjust reputation score
                reputation.adjustReputationScore(
                    currentContract.terms.borrower,
                    IReputation.ReasonType.BR_ONTIME_PAYMENT
                );
            }

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                if (
                    previousRequest.remainingInterest +
                        previousRequest.remainingPenalty +
                        previousRequest.remainingLoan >
                    0
                ) {
                    // unpaid => liquid
                    _liquidationExecution(
                        _contractId,
                        ContractLiquidedReasonType.UNPAID
                    );
                    return;
                } else {
                    // paid full => release collateral
                    _returnCollateralToBorrowerAndCloseContract(_contractId);
                    return;
                }
            }

            emit PaymentRequestEvent(_contractId, previousRequest);
        } else {
            // Validate: remaining loan must valid
            require(currentContract.terms.loanAmount == _remainingLoan, "4"); // remain

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(
                _dueDateTimestamp <= currentContract.terms.contractEndDate,
                "5"
            ); // contr-end
            require(
                _dueDateTimestamp > currentContract.terms.contractStartDate ||
                    _dueDateTimestamp == 0,
                "6"
            ); // less-th-prev
            require(
                block.timestamp < _dueDateTimestamp || _dueDateTimestamp == 0,
                "7"
            ); // over

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                // paid full => release collateral
                _returnCollateralToBorrowerAndCloseContract(_contractId);
                return;
            }
        }

        // Create new payment request and store to contract
        PaymentRequest memory newRequest = PaymentRequest({
            requestId: requests.length,
            paymentRequestType: _paymentRequestType,
            remainingLoan: _remainingLoan,
            penalty: _nextPhrasePenalty,
            interest: _nextPhraseInterest,
            remainingPenalty: _nextPhrasePenalty,
            remainingInterest: _nextPhraseInterest,
            dueDateTimestamp: _dueDateTimestamp,
            status: PaymentRequestStatusEnum.ACTIVE,
            chargePrepaidFee: _chargePrepaidFee
        });
        requests.push(newRequest);
        emit PaymentRequestEvent(_contractId, newRequest);
    }

    /** ===================================== 3.2. REPAYMENT ============================= */

    event RepaymentEvent(
        uint256 contractId,
        uint256 paidPenaltyAmount,
        uint256 paidInterestAmount,
        uint256 paidLoanAmount,
        uint256 paidPenaltyFeeAmount,
        uint256 paidInterestFeeAmount,
        uint256 prepaidAmount,
        uint256 paymentRequestId,
        uint256 UID
    );

    /**
        End lend period settlement and generate invoice for next period
     */
    function repayment(
        uint256 _contractId,
        uint256 _paidPenaltyAmount,
        uint256 _paidInterestAmount,
        uint256 _paidLoanAmount,
        uint256 _UID
    ) external whenNotPaused {
        // Get contract & payment request
        Contract storage _contract = contractMustActive(_contractId);
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        require(requests.length > 0, "0");
        PaymentRequest storage _paymentRequest = requests[requests.length - 1];

        // Validation: Contract must not overdue
        require(block.timestamp <= _contract.terms.contractEndDate, "1"); // contr-over

        // Validation: current payment request must active and not over due
        require(_paymentRequest.status == PaymentRequestStatusEnum.ACTIVE, "2"); // not-act
        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            require(block.timestamp <= _paymentRequest.dueDateTimestamp, "3"); // over-due
        }

        // Calculate paid amount / remaining amount, if greater => get paid amount
        if (_paidPenaltyAmount > _paymentRequest.remainingPenalty) {
            _paidPenaltyAmount = _paymentRequest.remainingPenalty;
        }

        if (_paidInterestAmount > _paymentRequest.remainingInterest) {
            _paidInterestAmount = _paymentRequest.remainingInterest;
        }

        if (_paidLoanAmount > _paymentRequest.remainingLoan) {
            _paidLoanAmount = _paymentRequest.remainingLoan;
        }

        // Calculate fee amount based on paid amount
        uint256 _feePenalty = PawnLib.calculateSystemFee(
            _paidPenaltyAmount,
            _contract.terms.systemFeeRate,
            ZOOM
        );
        uint256 _feeInterest = PawnLib.calculateSystemFee(
            _paidInterestAmount,
            _contract.terms.systemFeeRate,
            ZOOM
        );

        uint256 _prepaidFee = 0;
        if (_paymentRequest.chargePrepaidFee) {
            _prepaidFee = PawnLib.calculateSystemFee(
                _paidLoanAmount,
                _contract.terms.prepaidFeeRate,
                ZOOM
            );
        }

        // Update paid amount on payment request
        _paymentRequest.remainingPenalty -= _paidPenaltyAmount;
        _paymentRequest.remainingInterest -= _paidInterestAmount;
        _paymentRequest.remainingLoan -= _paidLoanAmount;

        // emit event repayment
        emit RepaymentEvent(
            _contractId,
            _paidPenaltyAmount,
            _paidInterestAmount,
            _paidLoanAmount,
            _feePenalty,
            _feeInterest,
            _prepaidFee,
            _paymentRequest.requestId,
            _UID
        );

        // If remaining loan = 0 => paidoff => execute release collateral
        if (
            _paymentRequest.remainingLoan == 0 &&
            _paymentRequest.remainingPenalty == 0 &&
            _paymentRequest.remainingInterest == 0
        ) {
            _returnCollateralToBorrowerAndCloseContract(_contractId);
        }

        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            // Transfer fee to fee wallet
            PawnLib.safeTransfer(
                _contract.terms.repaymentAsset,
                msg.sender,
                feeWallet,
                _feePenalty + _feeInterest
            );

            // Transfer penalty and interest to lender except fee amount
            uint256 transferAmount = _paidPenaltyAmount +
                _paidInterestAmount -
                _feePenalty -
                _feeInterest;
            PawnLib.safeTransfer(
                _contract.terms.repaymentAsset,
                msg.sender,
                _contract.terms.lender,
                transferAmount
            );
        }

        if (_paidLoanAmount > 0) {
            // Transfer loan amount and prepaid fee to lender
            PawnLib.safeTransfer(
                _contract.terms.loanAsset,
                msg.sender,
                _contract.terms.lender,
                _paidLoanAmount + _prepaidFee
            );
        }
    }

    /** ===================================== 3.3. LIQUIDITY & DEFAULT ============================= */
    // enum ContractLiquidedReasonType { LATE, RISK, UNPAID }
    event ContractLiquidedEvent(
        uint256 contractId,
        uint256 liquidedAmount,
        uint256 feeAmount,
        ContractLiquidedReasonType reasonType
    );
    event LoanContractCompletedEvent(uint256 contractId);

    function collateralRiskLiquidationExecution(
        uint256 _contractId,
        uint256 _collateralPerRepaymentTokenExchangeRate,
        uint256 _collateralPerLoanAssetExchangeRate
    ) external whenNotPaused onlyOperator {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);

        (
            uint256 remainingRepayment,
            uint256 remainingLoan
        ) = calculateRemainingLoanAndRepaymentFromContract(
                _contractId,
                _contract
            );
        uint256 valueOfRemainingRepayment = (_collateralPerRepaymentTokenExchangeRate *
                remainingRepayment) / ZOOM;
        uint256 valueOfRemainingLoan = (_collateralPerLoanAssetExchangeRate *
            remainingLoan) / ZOOM;
        uint256 valueOfCollateralLiquidationThreshold = (_contract
            .terms
            .collateralAmount * _contract.terms.liquidityThreshold) /
            (100 * ZOOM);

        require(
            valueOfRemainingLoan + valueOfRemainingRepayment >=
                valueOfCollateralLiquidationThreshold,
            "0"
        ); // under-thres

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.RISK);
    }

    function calculateRemainingLoanAndRepaymentFromContract(
        uint256 _contractId,
        Contract storage _contract
    )
        internal
        view
        returns (uint256 remainingRepayment, uint256 remainingLoan)
    {
        // Validate: sum of unpaid interest, penalty and remaining loan in value must reach liquidation threshold of collateral value
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        if (requests.length > 0) {
            // Have payment request
            PaymentRequest storage _paymentRequest = requests[
                requests.length - 1
            ];
            remainingRepayment =
                _paymentRequest.remainingInterest +
                _paymentRequest.remainingPenalty;
            remainingLoan = _paymentRequest.remainingLoan;
        } else {
            // Haven't had payment request
            remainingRepayment = 0;
            remainingLoan = _contract.terms.loanAmount;
        }
    }

    function lateLiquidationExecution(uint256 _contractId)
        external
        whenNotPaused
    {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);

        // validate: contract have lateCount == lateThreshold
        require(_contract.lateCount >= _contract.terms.lateThreshold, "0"); // not-reach

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
    }

    function contractMustActive(uint256 _contractId)
        internal
        view
        returns (Contract storage _contract)
    {
        // Validate: Contract must active
        _contract = contracts[_contractId];
        require(_contract.status == ContractStatus.ACTIVE, "0"); // contr-act
    }

    function notPaidFullAtEndContractLiquidation(uint256 _contractId)
        external
        whenNotPaused
    {
        Contract storage _contract = contractMustActive(_contractId);
        // validate: current is over contract end date
        require(block.timestamp >= _contract.terms.contractEndDate, "0"); // due

        // validate: remaining loan, interest, penalty haven't paid in full
        (
            uint256 remainingRepayment,
            uint256 remainingLoan
        ) = calculateRemainingLoanAndRepaymentFromContract(
                _contractId,
                _contract
            );
        require(remainingRepayment + remainingLoan > 0, "1"); // paid

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.UNPAID);
    }

    function _liquidationExecution(
        uint256 _contractId,
        ContractLiquidedReasonType _reasonType
    ) internal {
        Contract storage _contract = contracts[_contractId];

        // Execute: calculate system fee of collateral and transfer collateral except system fee amount to lender
        uint256 _systemFeeAmount = PawnLib.calculateSystemFee(
            _contract.terms.collateralAmount,
            _contract.terms.systemFeeRate,
            ZOOM
        );
        uint256 _liquidAmount = _contract.terms.collateralAmount -
            _systemFeeAmount;

        // Execute: update status of contract to DEFAULT, collateral to COMPLETE
        _contract.status = ContractStatus.DEFAULT;
        PaymentRequest[]
            storage _paymentRequests = contractPaymentRequestMapping[
                _contractId
            ];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[
            _paymentRequests.length - 1
        ];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.DEFAULT;
        Collateral storage _collateral = collaterals[_contract.collateralId];
        _collateral.status = CollateralStatus.COMPLETED;

        // Emit Event ContractLiquidedEvent & PaymentRequest event
        emit ContractLiquidedEvent(
            _contractId,
            _liquidAmount,
            _systemFeeAmount,
            _reasonType
        );

        emit PaymentRequestEvent(_contractId, _lastPaymentRequest);

        // Transfer to lender liquid amount
        PawnLib.safeTransfer(
            _contract.terms.collateralAsset,
            address(this),
            _contract.terms.lender,
            _liquidAmount
        );

        // Transfer to system fee wallet fee amount
        PawnLib.safeTransfer(
            _contract.terms.collateralAsset,
            address(this),
            feeWallet,
            _systemFeeAmount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_LATE_PAYMENT
        );
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_CONTRACT_DEFAULTED
        );
    }

    function _returnCollateralToBorrowerAndCloseContract(uint256 _contractId)
        internal
    {
        Contract storage _contract = contracts[_contractId];

        // Execute: Update status of contract to COMPLETE, collateral to COMPLETE
        _contract.status = ContractStatus.COMPLETED;
        PaymentRequest[]
            storage _paymentRequests = contractPaymentRequestMapping[
                _contractId
            ];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[
            _paymentRequests.length - 1
        ];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.COMPLETE;
        Collateral storage _collateral = collaterals[_contract.collateralId];
        _collateral.status = CollateralStatus.COMPLETED;

        // Emit event ContractCompleted
        emit LoanContractCompletedEvent(_contractId);
        emit PaymentRequestEvent(_contractId, _lastPaymentRequest);

        // Execute: Transfer collateral to borrower
        PawnLib.safeTransfer(
            _contract.terms.collateralAsset,
            address(this),
            _contract.terms.borrower,
            _contract.terms.collateralAmount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_ONTIME_PAYMENT
        );
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_CONTRACT_COMPLETE
        );
    }

    function releaseTrappedCollateralLockedWithoutContract(
        uint256 _collateralId,
        uint256 _packageId
    ) external onlyAdmin {
        // Validate: Collateral must Doing
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.DOING, "0"); // col

        // Check for collateral not being in any contract
        for (uint256 i = 0; i < numberContracts - 1; i++) {
            Contract storage mContract = contracts[i];
            require(mContract.collateralId != _collateralId, "1"); // col-in-cont
        }

        // Check for collateral-package status is ACCEPTED
        CollateralAsLoanRequestListStruct
            storage loanRequestListStruct = collateralAsLoanRequestMapping[
                _collateralId
            ];
        require(loanRequestListStruct.isInit == true, "2"); // col-loan-req
        LoanRequestStatusStruct storage statusStruct = loanRequestListStruct
            .loanRequestToPawnShopPackageMapping[_packageId];
        require(statusStruct.isInit == true, "3"); // col-loan-req-pack
        require(statusStruct.status == LoanRequestStatus.ACCEPTED, "4"); // not-acpt

        // Update status of loan request
        statusStruct.status = LoanRequestStatus.PENDING;
        collateral.status = CollateralStatus.OPEN;
    }

    /** ===================================== CONTRACT ADMIN ============================= */

    event AdminChanged(address _from, address _to);

    function changeAdmin(address newAddress) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAddress;

        emit AdminChanged(oldAdmin, newAddress);
    }

    /** ===================================== REPUTATION FUNCTIONS & STATES ===================================== */

    IReputation public reputation;

    function setReputationContract(address _reputationAddress)
        external
        onlyAdmin
    {
        reputation = IReputation(_reputationAddress);
    }

    /** ==================== Exchange functions & states ==================== */
    Exchange public exchange;

    function setExchangeContract(address _exchangeAddress) external onlyAdmin {
        exchange = Exchange(_exchangeAddress);
    }

    /** ==================== Loan Contract functions & states ==================== */
    PawnP2PLoanContract public pawnLoanContract;

    function setPawnLoanContract(address _pawnLoanAddress) external onlyAdmin {
        pawnLoanContract = PawnP2PLoanContract(_pawnLoanAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../pawn-p2p-v2/PawnLib.sol";

interface IPawn {
    /** General functions */

    function emergencyWithdraw(address _token) external;

    function updateCollateralStatus(
        uint256 _collateralId,
        CollateralStatus _status
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../pawn-p2p-v2/PawnLib.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../pawn-nft/IPawnNFT.sol";

contract Exchange is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    
    mapping(address => address) public ListCryptoExchange;

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // set dia chi cac token ( crypto) tuong ung voi dia chi chuyen doi ra USD tren chain link
    function setCryptoExchange(
        address _cryptoAddress,
        address _latestPriceAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ListCryptoExchange[_cryptoAddress] = _latestPriceAddress;
    }

    // lay gia cua dong BNB
    function RateBNBwithUSD() internal view returns (int256 price) {
        AggregatorV3Interface getPriceToUSD = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        (, price, , , ) = getPriceToUSD.latestRoundData();
    }

    // lay ti gia dong BNB + timestamp
    function RateBNBwithUSDAttimestamp()
        internal
        view
        returns (int256 price, uint256 timeStamp)
    {
        AggregatorV3Interface getPriceToUSD = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        (, price, , timeStamp, ) = getPriceToUSD.latestRoundData();
    }

    // lay gia cua cac crypto va token khac da duoc them vao ListcryptoExchange
    function getLatesPriceToUSD(address _adcrypto)
        internal
        view
        returns (int256 price)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ListCryptoExchange[_adcrypto]
        );
        (, price, , , ) = priceFeed.latestRoundData();
    }

    // lay ti gia va timestamp cua cac crypto va token da duoc them vao ListcryptoExchange
    function getRateAndTimestamp(address _adcrypto)
        internal
        view
        returns (int256 price, uint256 timeStamp)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ListCryptoExchange[_adcrypto]
        );
        (, price, , timeStamp, ) = priceFeed.latestRoundData();
    }

    // loanAmount= (CollateralAsset * amount * loanToValue) / RateLoanAsset
    // exchangeRate = RateLoanAsset / RateRepaymentAsset
    function calculateLoanAmountAndExchangeRate(
        Collateral memory _col,
        PawnShopPackage memory _pkg
    ) external view returns (uint256 loanAmount, uint256 exchangeRate) {
        uint256 collateralToUSD;
        uint256 rateLoanAsset;
        uint256 rateRepaymentAsset;

        if (_col.collateralAddress == address(0)) {
            // If collateral address is address(0), check BNB exchange rate with USD
            // collateralToUSD = (uint256(RateBNBwithUSD()) * 10**10 * _pkg.loanToValue * _col.amount) / 100;
            (, uint256 _ltvAmount)  = SafeMathUpgradeable.tryMul(_pkg.loanToValue, _col.amount);
            (, uint256 _collRate)   = SafeMathUpgradeable.tryMul(_ltvAmount, uint256(RateBNBwithUSD()));
            (, uint256 _collToUSD)  = SafeMathUpgradeable.tryDiv(_collRate, (100 * 10**5));

            collateralToUSD = _collToUSD;
        } else {
            // If collateral address is not BNB, get latest price in USD of collateral crypto
            // collateralToUSD = (uint256(getLatesPriceToUSD(_col.collateralAddress)) * 10**10 * _pkg.loanToValue * _col.amount) / 100;
            (, uint256 _ltvAmount)  = SafeMathUpgradeable.tryMul(_pkg.loanToValue, _col.amount);
            (, uint256 _collRate)   = SafeMathUpgradeable.tryMul(_ltvAmount, uint256(getLatesPriceToUSD(_col.collateralAddress)));
            (, uint256 _collToUSD)  = SafeMathUpgradeable.tryDiv(_collRate, (100 * 10**5));

            collateralToUSD = _collToUSD;
        }
        
        if (_col.loanAsset == address(0)) {
            // get price of BNB in USD
            rateLoanAsset = uint256(RateBNBwithUSD());
        } else {
            // get price in USD of crypto as loan asset
            rateLoanAsset = uint256(getLatesPriceToUSD(_col.loanAsset));
        }

        // Calculate Loan amount
        (, uint256 _loanAmount) = SafeMathUpgradeable.tryDiv(collateralToUSD, rateLoanAsset); 
        loanAmount = _loanAmount;

        if (_pkg.repaymentAsset == address(0)) {
            // get price in USD of BNB as repayment asset 
            rateRepaymentAsset = uint256(RateBNBwithUSD());
        } else {
            // get latest price in USD of crypto as repayment asset
            rateRepaymentAsset = uint256(getLatesPriceToUSD(_pkg.repaymentAsset));
        }

        // calculate exchange rate
        (, uint256 _exchange) = SafeMathUpgradeable.tryDiv(rateLoanAsset, rateRepaymentAsset);
        exchangeRate = _exchange;
    }

    function calcLoanAmountAndExchangeRate(
        address collateralAddress,
        uint256 amount,
        address loanAsset,
        uint256 loanToValue,
        address repaymentAsset
    ) external view returns (
        uint256 loanAmount, 
        uint256 exchangeRate, 
        uint256 collateralToUSD, 
        uint256 rateLoanAsset,
        uint256 rateRepaymentAsset) {

        if (collateralAddress == address(0)) {
            // If collateral address is address(0), check BNB exchange rate with USD
            // collateralToUSD = (uint256(RateBNBwithUSD()) * loanToValue * amount) / (100 * 10**5);
            (, uint256 ltvAmount)  = SafeMathUpgradeable.tryMul(loanToValue, amount);
            (, uint256 collRate)   = SafeMathUpgradeable.tryMul(ltvAmount, uint256(RateBNBwithUSD()));
            (, uint256 collToUSD)  = SafeMathUpgradeable.tryDiv(collRate, (100 * 10**5));

            collateralToUSD = collToUSD;
        } else {
            // If collateral address is not BNB, get latest price in USD of collateral crypto
            // collateralToUSD = (uint256(getLatesPriceToUSD(collateralAddress))  * loanToValue * amount) / (100 * 10**5);
            (, uint256 ltvAmount)  = SafeMathUpgradeable.tryMul(loanToValue, amount);
            (, uint256 collRate)   = SafeMathUpgradeable.tryMul(ltvAmount, uint256(getLatesPriceToUSD(collateralAddress)));
            (, uint256 collToUSD)  = SafeMathUpgradeable.tryDiv(collRate, (100 * 10**5));

            collateralToUSD = collToUSD;
        }

        if (loanAsset == address(0)) {
            // get price of BNB in USD
            rateLoanAsset = uint256(RateBNBwithUSD());
        } else {
            // get price in USD of crypto as loan asset
            rateLoanAsset = uint256(getLatesPriceToUSD(loanAsset));
        }

        (, uint256 lAmount) = SafeMathUpgradeable.tryDiv(collateralToUSD, rateLoanAsset); 
        // loanAmount = collateralToUSD / rateLoanAsset;
        loanAmount = lAmount;

        if (repaymentAsset == address(0)) {
            // get price in USD of BNB as repayment asset 
            rateRepaymentAsset = uint256(RateBNBwithUSD());
        } else {
            // get latest price in USD of crypto as repayment asset
            rateRepaymentAsset = uint256(getLatesPriceToUSD(repaymentAsset));
        }

        // calculate exchange rate
        (, uint256 xchange) = SafeMathUpgradeable.tryDiv(rateLoanAsset, rateRepaymentAsset);
        exchangeRate = xchange;
    }

    function exchangeRateofOffer(address _adLoanAsset, address _adRepayment)
        external
        view
        returns (uint256 exchangeRateOfOffer)
    {
        if (_adLoanAsset == address(0)) {
            exchangeRateOfOffer =
                (uint256(RateBNBwithUSD()) * 10**10) /
                (uint256(getLatesPriceToUSD(_adRepayment)) * 10**10);
        } else if (_adRepayment == address(0)) {
            exchangeRateOfOffer =
                (uint256(getLatesPriceToUSD(_adLoanAsset)) * 10**10) /
                (uint256(RateBNBwithUSD()) * 10**10);
        } else {
            exchangeRateOfOffer =
                (uint256(getLatesPriceToUSD(_adLoanAsset)) * 10**10) /
                (uint256(getLatesPriceToUSD(_adRepayment)) * 10**10);
        }
    }

    // tinh tien lai: interest = loanAmount * interestByLoanDurationType (interestByLoanDurationType = % lãi * số kì * loại kì / (365*100))
    function calculateInterest(Contract memory _contract)
        external
        view
        returns (uint256 interest)
    {
        uint256 interestToUSD;
        uint256 repaymentAssetToUSD;
        uint256 _interestByLoanDurationType;

        if (_contract.terms.repaymentCycleType == LoanDurationType.WEEK) {
            _interestByLoanDurationType =
                (_contract.terms.interest * 7 * 10**5) /
                (100 * 365);
        } else {
            _interestByLoanDurationType =
                (_contract.terms.interest * 30 * 10**5) /
                (100 * 365);
        }

        if (_contract.terms.loanAsset == address(0)) {
            interestToUSD = (uint256(RateBNBwithUSD()) *
                10**10 *
                _contract.terms.loanAmount);
        } else {
            interestToUSD = (uint256(
                getLatesPriceToUSD(_contract.terms.loanAsset)
            ) *
                10**10 *
                _contract.terms.loanAmount);
        }

        if (_contract.terms.repaymentAsset == address(0)) {
            repaymentAssetToUSD = uint256(RateBNBwithUSD()) * 10**10;
        } else {
            repaymentAssetToUSD =
                uint256(getLatesPriceToUSD(_contract.terms.loanAsset)) *
                10**10;
        }

        interest =
            (interestToUSD * _interestByLoanDurationType) /
            (repaymentAssetToUSD * 10**10);
    }

    // tinh penalty
    function calculatePenalty(
        PaymentRequest memory _paymentrequest,
        Contract memory _contract,
        uint256 _penaltyRate
    ) external pure returns (uint256 valuePenalty) {
        uint256 _interestByLoanDurationType;
        if (_contract.terms.repaymentCycleType == LoanDurationType.WEEK) {
            _interestByLoanDurationType =
                (_contract.terms.interest * 7 * 10**5) /
                (100 * 365);
        } else {
            _interestByLoanDurationType =
                (_contract.terms.interest * 30 * 10**5) /
                (100 * 365);
        }

        valuePenalty =
            (_paymentrequest.remainingPenalty *
                10**5 +
                _paymentrequest.remainingPenalty *
                _interestByLoanDurationType +
                _paymentrequest.remainingInterest *
                _penaltyRate) /
            10**10;
    }

    // lay Rate va thoi gian cap nhat ti gia do
    function RateAndTimestamp(Contract memory _contract)
        external
        view
        returns (
            uint256 _collateralExchangeRate,
            uint256 _loanExchangeRate,
            uint256 _repaymemtExchangeRate,
            uint256 _rateUpdateTime
        )
    {
        int256 priceCollateral;
        int256 priceLoan;
        int256 priceRepayment;

        if (_contract.terms.collateralAsset == address(0)) {
            (priceCollateral, _rateUpdateTime) = RateBNBwithUSDAttimestamp();
        } else {
            (priceCollateral, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.collateralAsset
            );
        }
        _collateralExchangeRate = uint256(priceCollateral) * 10**10;

        if (_contract.terms.loanAsset == address(0)) {
            (priceLoan, _rateUpdateTime) = RateBNBwithUSDAttimestamp();
        } else {
            (priceLoan, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.loanAsset
            );
        }
        _loanExchangeRate = uint256(priceLoan) * 10**10;

        if (_contract.terms.repaymentAsset == address(0)) {
            (priceRepayment, _rateUpdateTime) = RateBNBwithUSDAttimestamp();
        } else {
            (priceRepayment, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.repaymentAsset
            );
        }
        _repaymemtExchangeRate = uint256(priceRepayment) * 10**10;
    }

    // ======================================= NFT==========================

    // tinh tien lai: interest = loanAmount * interestByLoanDurationType (interestByLoanDurationType = % lãi * số kì * loại kì / (365*100))
    function calculateInterestNFT(IPawnNFT.Contract memory _contract)
        external
        view
        returns (uint256 interest)
    {
        uint256 interestToUSD;
        uint256 repaymentAssetToUSD;
        uint256 _interestByLoanDurationType;

        if (
            _contract.terms.repaymentCycleType == IPawnNFT.LoanDurationType.WEEK
        ) {
            _interestByLoanDurationType =
                (_contract.terms.interest * 7 * 10**5) /
                (100 * 365);
        } else {
            _interestByLoanDurationType =
                (_contract.terms.interest * 30 * 10**5) /
                (100 * 365);
        }

        if (_contract.terms.loanAsset == address(0)) {
            interestToUSD =
                (uint256(Exchange.RateBNBwithUSD())) *
                10**10 *
                _contract.terms.loanAmount;
        } else {
            interestToUSD =
                (
                    uint256(
                        Exchange.getLatesPriceToUSD(_contract.terms.loanAsset)
                    )
                ) *
                10**10 *
                _contract.terms.loanAmount;
        }

        if (_contract.terms.repaymentAsset == address(0)) {
            repaymentAssetToUSD = (uint256(Exchange.RateBNBwithUSD())) * 10**10;
        } else {
            repaymentAssetToUSD =
                (
                    uint256(
                        Exchange.getLatesPriceToUSD(
                            _contract.terms.repaymentAsset
                        )
                    )
                ) *
                10**10;
        }

        interest =
            (interestToUSD * _interestByLoanDurationType) /
            (repaymentAssetToUSD * 10**5);
    }

    function calculatePenaltyNFT(
        IPawnNFT.PaymentRequest memory _paymentrequest,
        IPawnNFT.Contract memory _contract,
        uint256 _penaltyRate
    ) external pure returns (uint256 valuePenalty) {
        uint256 _interestByLoanDurationType;
        if (
            _contract.terms.repaymentCycleType == IPawnNFT.LoanDurationType.WEEK
        ) {
            _interestByLoanDurationType =
                (_contract.terms.interest * 7 * 10**5) /
                (100 * 365);
        } else {
            _interestByLoanDurationType =
                (_contract.terms.interest * 30 * 10**5) /
                (100 * 365);
        }

        valuePenalty =
            (_paymentrequest.remainingPenalty *
                10**5 +
                _paymentrequest.remainingPenalty *
                _interestByLoanDurationType +
                _paymentrequest.remainingInterest *
                _penaltyRate) /
            10**5;
    }

    function RateAndTimestampNFT(
        IPawnNFT.Contract memory _contract,
        address _token
    )
        external
        view
        returns (
            uint256 _collateralExchangeRate,
            uint256 _loanExchangeRate,
            uint256 _repaymemtExchangeRate,
            uint256 _rateUpdateTime
        )
    {
        int256 priceCollateral;
        int256 priceLoan;
        int256 priceRepayment;

        if (_token == address(0)) {
            (priceCollateral, _rateUpdateTime) = RateBNBwithUSDAttimestamp();
        } else {
            (priceCollateral, _rateUpdateTime) = getRateAndTimestamp(_token);
        }
        _collateralExchangeRate = uint256(priceCollateral) * 10**10;

        if (_contract.terms.loanAsset == address(0)) {
            (priceLoan, _rateUpdateTime) = RateBNBwithUSDAttimestamp();
        } else {
            (priceLoan, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.loanAsset
            );
        }
        _loanExchangeRate = uint256(priceLoan) * 10**10;

        if (_contract.terms.repaymentAsset == address(0)) {
            (priceRepayment, _rateUpdateTime) = RateBNBwithUSDAttimestamp();
        } else {
            (priceRepayment, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.repaymentAsset
            );
        }
        _repaymemtExchangeRate = uint256(priceRepayment) * 10**10;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./PawnModel.sol";
import "../pawn-p2p/IPawn.sol";
import "../access/DFY-AccessControl.sol";
import "../reputation/IReputation.sol";

contract PawnP2PLoanContract is PawnModel {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    IPawn public pawnContract;

    /** ==================== Loan contract & Payment related state variables ==================== */
    uint256 public numberContracts;
    mapping(uint256 => Contract) public contracts;

    mapping(uint256 => PaymentRequest[]) public contractPaymentRequestMapping;

    mapping(uint256 => CollateralAsLoanRequestListStruct)
        public collateralAsLoanRequestMapping; // Map from collateral to loan request

    /** ==================== Loan contract related events ==================== */
    event LoanContractCreatedEvent(
        uint256 exchangeRate,
        address fromAddress,
        uint256 contractId,
        Contract data
    );

    event PaymentRequestEvent(
        int256 paymentRequestId,
        uint256 contractId,
        PaymentRequest data
    );

    event RepaymentEvent(
        uint256 contractId,
        uint256 paidPenaltyAmount,
        uint256 paidInterestAmount,
        uint256 paidLoanAmount,
        uint256 paidPenaltyFeeAmount,
        uint256 paidInterestFeeAmount,
        uint256 prepaidAmount,
        uint256 paymentRequestId,
        uint256 UID
    );

    /** ==================== Liquidate & Default related events ==================== */
    event ContractLiquidedEvent(ContractLiquidationData liquidationData);

    event LoanContractCompletedEvent(uint256 contractId);

    /** ==================== Initialization ==================== */

    /**
     * @dev initialize function
     * @param _zoom is coefficient used to represent risk params
     */
    function initialize(uint32 _zoom) public initializer {
        __PawnModel_init(_zoom);
    }

    function setPawnContract(address _pawnAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pawnContract = IPawn(_pawnAddress);
        grantRole(OPERATOR_ROLE, _pawnAddress);
    }

    /** ================================ CREATE LOAN CONTRACT ============================= */

    function createContract(ContractRawData memory contractData)
        external
        onlyRole(OPERATOR_ROLE)
        returns (uint256 _idx)
    {
        _idx = numberContracts;
        Contract storage newContract = contracts[_idx];

        newContract.collateralId = contractData.collateralId;
        newContract.offerId = contractData.offerId;
        newContract.pawnShopPackageId = contractData.packageId;
        newContract.status = ContractStatus.ACTIVE;
        newContract.lateCount = 0;
        newContract.terms.borrower = contractData.borrower;
        newContract.terms.lender = contractData.lender;
        newContract.terms.collateralAsset = contractData.collateralAsset;
        newContract.terms.collateralAmount = contractData.collateralAmount;
        newContract.terms.loanAsset = contractData.loanAsset;
        newContract.terms.loanAmount = contractData.loanAmount;
        newContract.terms.repaymentCycleType = contractData.repaymentCycleType;
        newContract.terms.repaymentAsset = contractData.repaymentAsset;
        newContract.terms.interest = contractData.interest;
        newContract.terms.liquidityThreshold = contractData.liquidityThreshold;
        newContract.terms.contractStartDate = block.timestamp;
        newContract.terms.contractEndDate =
            block.timestamp +
            PawnLib.calculateContractDuration(
                contractData.repaymentCycleType,
                contractData.loanDurationQty
            );
        newContract.terms.lateThreshold = lateThreshold;
        newContract.terms.systemFeeRate = systemFeeRate;
        newContract.terms.penaltyRate = penaltyRate;
        newContract.terms.prepaidFeeRate = prepaidFeeRate;
        ++numberContracts;

        emit LoanContractCreatedEvent(
            contractData.exchangeRate,
            _msgSender(),
            _idx,
            newContract
        );
    }

    function contractMustActive(uint256 _contractId)
        internal
        view
        returns (Contract storage _contract)
    {
        // Validate: Contract must active
        _contract = contracts[_contractId];
        require(_contract.status == ContractStatus.ACTIVE, "0"); // contr-act
    }

    /** ================================ 3. PAYMENT REQUEST & REPAYMENT WORKLOWS ============================= */

    function closePaymentRequestAndStartNew(
        int256 _paymentRequestId,
        uint256 _contractId,
        PaymentRequestTypeEnum _paymentRequestType
    ) public whenContractNotPaused onlyRole(OPERATOR_ROLE) {
        Contract storage currentContract = contractMustActive(_contractId);
        bool _chargePrepaidFee;
        uint256 _remainingLoan;
        uint256 _nextPhrasePenalty;
        uint256 _nextPhraseInterest;
        uint256 _dueDateTimestamp;

        // Check if number of requests is 0 => create new requests, if not then update current request as LATE or COMPLETE and create new requests
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        if (requests.length > 0) {
            // not first phrase, get previous request
            PaymentRequest storage previousRequest = requests[
                requests.length - 1
            ];

            // Validate: time must over due date of current payment
            require(block.timestamp >= previousRequest.dueDateTimestamp, "0"); // time-not-due

            // Validate: remaining loan must valid
            // require(previousRequest.remainingLoan == _remainingLoan, '1'); // remain
            _remainingLoan = previousRequest.remainingLoan;
            _nextPhrasePenalty = exchange.calculatePenalty(
                previousRequest,
                currentContract,
                penaltyRate
            );

            if (_paymentRequestType == PaymentRequestTypeEnum.INTEREST) {
                _dueDateTimestamp = PawnLib.add(
                    previousRequest.dueDateTimestamp,
                    PawnLib.calculatedueDateTimestampInterest(
                        currentContract.terms.repaymentCycleType
                    )
                );
                _nextPhraseInterest = exchange.calculateInterest(
                    currentContract
                );
            }
            if (_paymentRequestType == PaymentRequestTypeEnum.OVERDUE) {
                _dueDateTimestamp = PawnLib.add(
                    previousRequest.dueDateTimestamp,
                    PawnLib.calculatedueDateTimestampPenalty(
                        currentContract.terms.repaymentCycleType
                    )
                );
                _nextPhraseInterest = 0;
            }

            if (_dueDateTimestamp >= currentContract.terms.contractEndDate) {
                _chargePrepaidFee = true;
            } else {
                _chargePrepaidFee = false;
            }

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(
                _dueDateTimestamp <= currentContract.terms.contractEndDate,
                "2"
            ); // contr-end
            // require(_dueDateTimestamp > previousRequest.dueDateTimestamp || _dueDateTimestamp == 0, '3'); // less-th-prev

            // update previous
            // check for remaining penalty and interest, if greater than zero then is Lated, otherwise is completed
            if (
                previousRequest.remainingInterest > 0 ||
                previousRequest.remainingPenalty > 0
            ) {
                previousRequest.status = PaymentRequestStatusEnum.LATE;

                // Adjust reputation score
                reputation.adjustReputationScore(
                    currentContract.terms.borrower,
                    IReputation.ReasonType.BR_LATE_PAYMENT
                );

                // Update late counter of contract
                currentContract.lateCount += 1;

                // Check for late threshold reach
                if (
                    currentContract.terms.lateThreshold <=
                    currentContract.lateCount
                ) {
                    // Execute liquid
                    _liquidationExecution(
                        _contractId,
                        ContractLiquidedReasonType.LATE
                    );
                    return;
                }
            } else {
                previousRequest.status = PaymentRequestStatusEnum.COMPLETE;

                // Adjust reputation score
                reputation.adjustReputationScore(
                    currentContract.terms.borrower,
                    IReputation.ReasonType.BR_ONTIME_PAYMENT
                );
            }

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                uint256 remainingAmount = previousRequest.remainingInterest + previousRequest.remainingPenalty + previousRequest.remainingLoan;
                if (remainingAmount > 0) {
                    // unpaid => liquid
                    _liquidationExecution(
                        _contractId,
                        ContractLiquidedReasonType.UNPAID
                    );
                    return;
                } else {
                    // paid full => release collateral
                    _returnCollateralToBorrowerAndCloseContract(_contractId);
                    return;
                }
            }

            emit PaymentRequestEvent(-1, _contractId, previousRequest);
        } else {
            // Validate: remaining loan must valid
            // require(currentContract.terms.loanAmount == _remainingLoan, '4'); // remain
            _remainingLoan = currentContract.terms.loanAmount;
            _nextPhraseInterest = exchange.calculateInterest(currentContract);
            _nextPhrasePenalty = 0;
            _dueDateTimestamp = PawnLib.add(
                block.timestamp,
                PawnLib.calculatedueDateTimestampInterest(
                    currentContract.terms.repaymentCycleType
                )
            );

            if (
                currentContract.terms.repaymentCycleType ==
                LoanDurationType.WEEK
            ) {
                if (
                    currentContract.terms.contractEndDate -
                        currentContract.terms.contractStartDate ==
                    600
                ) {
                    _chargePrepaidFee = true;
                } else {
                    _chargePrepaidFee = false;
                }
            } else {
                if (
                    currentContract.terms.contractEndDate -
                        currentContract.terms.contractStartDate ==
                    900
                ) {
                    _chargePrepaidFee = true;
                } else {
                    _chargePrepaidFee = false;
                }
            }

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(
                _dueDateTimestamp <= currentContract.terms.contractEndDate,
                "5"
            ); // contr-end
            require(
                _dueDateTimestamp > currentContract.terms.contractStartDate ||
                    _dueDateTimestamp == 0,
                "6"
            ); // less-th-prev
            require(
                block.timestamp < _dueDateTimestamp || _dueDateTimestamp == 0,
                "7"
            ); // over

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                // paid full => release collateral
                _returnCollateralToBorrowerAndCloseContract(_contractId);
                return;
            }
        }

        // Create new payment request and store to contract
        PaymentRequest memory newRequest = PaymentRequest({
            requestId: requests.length,
            paymentRequestType: _paymentRequestType,
            remainingLoan: _remainingLoan,
            penalty: _nextPhrasePenalty,
            interest: _nextPhraseInterest,
            remainingPenalty: _nextPhrasePenalty,
            remainingInterest: _nextPhraseInterest,
            dueDateTimestamp: _dueDateTimestamp,
            status: PaymentRequestStatusEnum.ACTIVE,
            chargePrepaidFee: _chargePrepaidFee
        });
        requests.push(newRequest);
        emit PaymentRequestEvent(_paymentRequestId, _contractId, newRequest);
    }

    /** ===================================== 3.2. REPAYMENT ============================= */

    /**
        End lend period settlement and generate invoice for next period
     */
    function repayment(
        uint256 _contractId,
        uint256 _paidPenaltyAmount,
        uint256 _paidInterestAmount,
        uint256 _paidLoanAmount,
        uint256 _UID
    ) external whenContractNotPaused {
        // Get contract & payment request
        Contract storage _contract = contractMustActive(_contractId);
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        require(requests.length > 0, "0");
        PaymentRequest storage _paymentRequest = requests[requests.length - 1];

        // Validation: Contract must not overdue
        require(block.timestamp <= _contract.terms.contractEndDate, "1"); // contr-over

        // Validation: current payment request must active and not over due
        require(_paymentRequest.status == PaymentRequestStatusEnum.ACTIVE, "2"); // not-act
        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            require(block.timestamp <= _paymentRequest.dueDateTimestamp, "3"); // over-due
        }

        // Calculate paid amount / remaining amount, if greater => get paid amount
        if (_paidPenaltyAmount > _paymentRequest.remainingPenalty) {
            _paidPenaltyAmount = _paymentRequest.remainingPenalty;
        }

        if (_paidInterestAmount > _paymentRequest.remainingInterest) {
            _paidInterestAmount = _paymentRequest.remainingInterest;
        }

        if (_paidLoanAmount > _paymentRequest.remainingLoan) {
            _paidLoanAmount = _paymentRequest.remainingLoan;
        }

        // Calculate fee amount based on paid amount
        uint256 _feePenalty = PawnLib.calculateSystemFee(
            _paidPenaltyAmount,
            _contract.terms.systemFeeRate,
            ZOOM
        );
        uint256 _feeInterest = PawnLib.calculateSystemFee(
            _paidInterestAmount,
            _contract.terms.systemFeeRate,
            ZOOM
        );

        uint256 _prepaidFee = 0;
        if (_paymentRequest.chargePrepaidFee) {
            _prepaidFee = PawnLib.calculateSystemFee(
                _paidLoanAmount,
                _contract.terms.prepaidFeeRate,
                ZOOM
            );
        }

        // Update paid amount on payment request
        _paymentRequest.remainingPenalty -= _paidPenaltyAmount;
        _paymentRequest.remainingInterest -= _paidInterestAmount;
        _paymentRequest.remainingLoan -= _paidLoanAmount;

        // emit event repayment
        emit RepaymentEvent(
            _contractId,
            _paidPenaltyAmount,
            _paidInterestAmount,
            _paidLoanAmount,
            _feePenalty,
            _feeInterest,
            _prepaidFee,
            _paymentRequest.requestId,
            _UID
        );

        // If remaining loan = 0 => paidoff => execute release collateral
        if (
            _paymentRequest.remainingLoan == 0 &&
            _paymentRequest.remainingPenalty == 0 &&
            _paymentRequest.remainingInterest == 0
        ) {
            _returnCollateralToBorrowerAndCloseContract(_contractId);
        }

        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            // Transfer fee to fee wallet
            PawnLib.safeTransfer(
                _contract.terms.repaymentAsset,
                msg.sender,
                feeWallet,
                _feePenalty + _feeInterest
            );

            // Transfer penalty and interest to lender except fee amount
            uint256 transferAmount = _paidPenaltyAmount +
                _paidInterestAmount -
                _feePenalty -
                _feeInterest;
            PawnLib.safeTransfer(
                _contract.terms.repaymentAsset,
                msg.sender,
                _contract.terms.lender,
                transferAmount
            );
        }

        if (_paidLoanAmount > 0) {
            // Transfer loan amount and prepaid fee to lender
            PawnLib.safeTransfer(
                _contract.terms.loanAsset,
                msg.sender,
                _contract.terms.lender,
                _paidLoanAmount + _prepaidFee
            );
        }
    }

    /** ===================================== 3.3. LIQUIDITY & DEFAULT ============================= */

    function collateralRiskLiquidationExecution(uint256 _contractId)
        external
        whenContractNotPaused
        onlyRole(OPERATOR_ROLE)
    {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);

        (
            uint256 collateralExchangeRate,
            uint256 loanExchangeRate,
            uint256 repaymentExchangeRate,

        ) = exchange.RateAndTimestamp(_contract);

        (
            uint256 remainingRepayment,
            uint256 remainingLoan
        ) = calculateRemainingLoanAndRepaymentFromContract(
                _contractId,
                _contract
            );

        uint256 valueOfRemainingRepayment = (repaymentExchangeRate *
            remainingRepayment) / ZOOM;
        uint256 valueOfRemainingLoan = (loanExchangeRate * remainingLoan) /
            ZOOM;
        uint256 valueOfCollateralLiquidationThreshold = (collateralExchangeRate *
                _contract.terms.collateralAmount *
                _contract.terms.liquidityThreshold) / (100 * ZOOM);

        require(
            valueOfRemainingLoan + valueOfRemainingRepayment >=
                valueOfCollateralLiquidationThreshold,
            "0"
        ); // under-thres

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.RISK);
    }

    function calculateRemainingLoanAndRepaymentFromContract(
        uint256 _contractId,
        Contract storage _contract
    )
        internal
        view
        returns (uint256 remainingRepayment, uint256 remainingLoan)
    {
        // Validate: sum of unpaid interest, penalty and remaining loan in value must reach liquidation threshold of collateral value
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        if (requests.length > 0) {
            // Have payment request
            PaymentRequest storage _paymentRequest = requests[
                requests.length - 1
            ];
            remainingRepayment =
                _paymentRequest.remainingInterest +
                _paymentRequest.remainingPenalty;
            remainingLoan = _paymentRequest.remainingLoan;
        } else {
            // Haven't had payment request
            remainingRepayment = 0;
            remainingLoan = _contract.terms.loanAmount;
        }
    }

    function lateLiquidationExecution(uint256 _contractId)
        external
        whenContractNotPaused
    {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);

        // validate: contract have lateCount == lateThreshold
        require(_contract.lateCount >= _contract.terms.lateThreshold, "0"); // not-reach

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
    }

    function notPaidFullAtEndContractLiquidation(uint256 _contractId)
        external
        whenContractNotPaused
    {
        Contract storage _contract = contractMustActive(_contractId);
        // validate: current is over contract end date
        require(block.timestamp >= _contract.terms.contractEndDate, "0"); // due

        // validate: remaining loan, interest, penalty haven't paid in full
        (
            uint256 remainingRepayment,
            uint256 remainingLoan
        ) = calculateRemainingLoanAndRepaymentFromContract(
                _contractId,
                _contract
            );
        require(remainingRepayment + remainingLoan > 0, "1"); // paid

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.UNPAID);
    }

    function _liquidationExecution(
        uint256 _contractId,
        ContractLiquidedReasonType _reasonType
    ) internal {
        Contract storage _contract = contracts[_contractId];

        // Execute: calculate system fee of collateral and transfer collateral except system fee amount to lender
        uint256 _systemFeeAmount = PawnLib.calculateSystemFee(
            _contract.terms.collateralAmount,
            _contract.terms.systemFeeRate,
            ZOOM
        );
        uint256 _liquidAmount = _contract.terms.collateralAmount -
            _systemFeeAmount;

        // Execute: update status of contract to DEFAULT, collateral to COMPLETE
        _contract.status = ContractStatus.DEFAULT;
        PaymentRequest[]
            storage _paymentRequests = contractPaymentRequestMapping[
                _contractId
            ];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[
            _paymentRequests.length - 1
        ];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.DEFAULT;

        // Update collateral status in Pawn contract
        // Collateral storage _collateral = collaterals[_contract.collateralId];
        // _collateral.status = CollateralStatus.COMPLETED;
        pawnContract.updateCollateralStatus(
            _contract.collateralId,
            CollateralStatus.COMPLETED
        );

        (
            uint256 _collateralExchangeRate,
            uint256 _loanExchangeRate,
            uint256 _repaymentExchangeRate,
            uint256 _rateUpdatedTime
        ) = exchange.RateAndTimestamp(_contract);

        // Emit Event ContractLiquidedEvent & PaymentRequest event
        ContractLiquidationData
            memory liquidationData = ContractLiquidationData(
                _contractId,
                _liquidAmount,
                _systemFeeAmount,
                _collateralExchangeRate,
                _loanExchangeRate,
                _repaymentExchangeRate,
                _rateUpdatedTime,
                _reasonType
            );

        emit ContractLiquidedEvent(liquidationData);

        emit PaymentRequestEvent(-1, _contractId, _lastPaymentRequest);

        // Transfer to lender liquid amount
        PawnLib.safeTransfer(
            _contract.terms.collateralAsset,
            address(this),
            _contract.terms.lender,
            _liquidAmount
        );

        // Transfer to system fee wallet fee amount
        PawnLib.safeTransfer(
            _contract.terms.collateralAsset,
            address(this),
            feeWallet,
            _systemFeeAmount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_LATE_PAYMENT
        );
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_CONTRACT_DEFAULTED
        );
    }

    function _returnCollateralToBorrowerAndCloseContract(uint256 _contractId)
        internal
    {
        Contract storage _contract = contracts[_contractId];

        // Execute: Update status of contract to COMPLETE, collateral to COMPLETE
        _contract.status = ContractStatus.COMPLETED;
        PaymentRequest[]
            storage _paymentRequests = contractPaymentRequestMapping[
                _contractId
            ];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[
            _paymentRequests.length - 1
        ];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.COMPLETE;

        // Update Pawn contract's collateral status
        // Collateral storage _collateral = collaterals[_contract.collateralId];
        // _collateral.status = CollateralStatus.COMPLETED;
        pawnContract.updateCollateralStatus(
            _contract.collateralId,
            CollateralStatus.COMPLETED
        );

        // Emit event ContractCompleted
        emit LoanContractCompletedEvent(_contractId);
        emit PaymentRequestEvent(-1, _contractId, _lastPaymentRequest);

        // Execute: Transfer collateral to borrower
        PawnLib.safeTransfer(
            _contract.terms.collateralAsset,
            address(this),
            _contract.terms.borrower,
            _contract.terms.collateralAmount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_ONTIME_PAYMENT
        );
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_CONTRACT_COMPLETE
        );
    }

    function findContractOfCollateral(
        uint256 _collateralId,
        uint256 _contractStart,
        uint256 _contractEnd
    ) external view returns (int256 _idx) {
        _idx = -1;
        uint256 endIdx = _contractEnd;
        if (_contractEnd >= numberContracts - 1) {
            endIdx = numberContracts - 1;
        }
        for (uint256 i = _contractStart; i < endIdx; i++) {
            Contract storage mContract = contracts[i];
            if (mContract.collateralId == _collateralId) {
                _idx = int256(i);
                break;
            }
        }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
// import "./IPawn.sol";

enum LoanDurationType {WEEK, MONTH}
enum CollateralStatus {OPEN, DOING, COMPLETED, CANCEL}
struct Collateral {
    address owner;
    uint256 amount;
    address collateralAddress;
    address loanAsset;
    uint256 expectedDurationQty;
    LoanDurationType expectedDurationType;
    CollateralStatus status;
}

enum OfferStatus {PENDING, ACCEPTED, COMPLETED, CANCEL}
struct CollateralOfferList {
    mapping (uint256 => Offer) offerMapping;
    uint256[] offerIdList;
    bool isInit;
}

struct Offer {
    address owner;
    address repaymentAsset;
    uint256 loanAmount;
    uint256 interest;
    uint256 duration;
    OfferStatus status;
    LoanDurationType loanDurationType;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    bool isInit;
}

enum PawnShopPackageStatus {ACTIVE, INACTIVE}
enum PawnShopPackageType {AUTO, SEMI_AUTO}
struct Range {
    uint256 lowerBound;
    uint256 upperBound;
}

struct PawnShopPackage {
    address owner;
    PawnShopPackageStatus status;
    PawnShopPackageType packageType;
    address loanToken;
    Range loanAmountRange;
    address[] collateralAcceptance;
    uint256 interest;
    uint256 durationType;
    Range durationRange;
    address repaymentAsset;
    LoanDurationType repaymentCycleType;
    uint256 loanToValue;
    uint256 loanToValueLiquidationThreshold;
}

enum LoanRequestStatus {PENDING, ACCEPTED, REJECTED, CONTRACTED, CANCEL}
struct LoanRequestStatusStruct {
    bool isInit;
    LoanRequestStatus status;
}
struct CollateralAsLoanRequestListStruct {
    mapping (uint256 => LoanRequestStatusStruct) loanRequestToPawnShopPackageMapping; // Mapping from package to status
    uint256[] pawnShopPackageIdList;
    bool isInit;
}

enum ContractStatus {ACTIVE, COMPLETED, DEFAULT}
struct ContractTerms {
    address borrower;
    address lender;
    address collateralAsset;
    uint256 collateralAmount;
    address loanAsset;
    uint256 loanAmount;
    address repaymentAsset;
    uint256 interest;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    uint256 contractStartDate;
    uint256 contractEndDate;
    uint256 lateThreshold;
    uint256 systemFeeRate;
    uint256 penaltyRate;
    uint256 prepaidFeeRate;
}
struct Contract {
    uint256 collateralId;
    int256 offerId;
    int256 pawnShopPackageId;
    ContractTerms terms;
    ContractStatus status;
    uint8 lateCount;
}

enum PaymentRequestStatusEnum {ACTIVE, LATE, COMPLETE, DEFAULT}
enum PaymentRequestTypeEnum {INTEREST, OVERDUE, LOAN}
struct PaymentRequest {
    uint256 requestId;
    PaymentRequestTypeEnum paymentRequestType;
    uint256 remainingLoan;
    uint256 penalty;
    uint256 interest;
    uint256 remainingPenalty;
    uint256 remainingInterest;
    uint256 dueDateTimestamp;
    bool chargePrepaidFee;
    PaymentRequestStatusEnum status;
}

enum ContractLiquidedReasonType {LATE, RISK, UNPAID}

struct ContractRawData {
    uint256 collateralId;
    address borrower;
    address loanAsset;
    address collateralAsset;
    uint256 collateralAmount;
    int256 packageId;
    int256 offerId;
    uint256 exchangeRate;
    uint256 loanAmount;
    address lender;
    address repaymentAsset;
    uint256 interest;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    uint256 loanDurationQty;    
}

struct ContractLiquidationData {
    uint256 contractId;
    uint256 liquidAmount;
    uint256 systemFeeAmount;
    uint256 collateralExchangeRate;
    uint256 loanExchangeRate;
    uint256 repaymentExchangeRate;
    uint256 rateUpdateTime;
    ContractLiquidedReasonType reasonType;
}

library PawnLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function safeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (asset == address(0)) {
            require(from.balance >= amount, "balance");
            // Handle BNB
            if (to == address(this)) {
                // Send to this contract
            } else if (from == address(this)) {
                // Send from this contract
                (bool success, ) = to.call{value: amount}("");
                require(success, "fail-trans-bnb");
            } else {
                // Send from other address to another address
                require(false, "not-allow-transfer");
            }
        } else {
            // Handle ERC20
            uint256 prebalance = IERC20Upgradeable(asset).balanceOf(to);
            require(IERC20Upgradeable(asset).balanceOf(from) >= amount, "not-enough-balance");
            if (from == address(this)) {
                // transfer direct to to
                IERC20Upgradeable(asset).safeTransfer(to, amount);
            } else {
                require(IERC20Upgradeable(asset).allowance(from, address(this)) >= amount, "not-allowance");
                IERC20Upgradeable(asset).safeTransferFrom(from, to, amount);
            }
            require(IERC20Upgradeable(asset).balanceOf(to) - amount == prebalance, "not-trans-enough");
        }
    }

    function calculateAmount(address _token, address from)
        internal
        view
        returns (uint256 _amount)
    {
        if (_token == address(0)) {
            // BNB
            _amount = from.balance;
        } else {
            // ERC20
            _amount = IERC20Upgradeable(_token).balanceOf(from);
        }
    }

    function calculateSystemFee(
        uint256 amount,
        uint256 feeRate,
        uint256 zoom
    ) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (zoom * 100);
    }

    function calculateContractDuration(
        LoanDurationType durationType,
        uint256 duration
    ) internal pure returns (uint256 inSeconds) {
        if (durationType == LoanDurationType.WEEK) {
            // inSeconds = 7 * 24 * 3600 * duration;
            inSeconds = 600 * duration; // test
        } else {
            // inSeconds = 30 * 24 * 3600 * duration;
            inSeconds = 900 * duration; // test
        }
    }

    function calculatedueDateTimestampInterest(LoanDurationType durationType)
        internal
        pure
        returns (uint256 duedateTimestampInterest)
    {
        if (durationType == LoanDurationType.WEEK) {
            // duedateTimestampInterest = 3*24*3600;
            duedateTimestampInterest = 180; // test
        } else {
            // duedateTimestampInterest = 7 * 24 * 3600;
            duedateTimestampInterest = 300; // test
        }
    }

    function calculatedueDateTimestampPenalty(LoanDurationType durationType)
        internal
        pure
        returns (uint256 duedateTimestampInterest)
    {
        if (durationType == LoanDurationType.WEEK) {
            // duedateTimestampInterest = 7 * 24 *3600 - 3 * 24 * 3600;
            duedateTimestampInterest = 600 - 180; // test
        } else {
            //  duedateTimestampInterest = 30 * 24 *3600 - 7 * 24 * 3600;
            duedateTimestampInterest = 900 - 300; // test
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "0");//SafeMath: addition overflow

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "1"); //SafeMath: subtraction overflow
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "2"); //SafeMath: multiplication overflow

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "3");  //SafeMath: division by zero
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}

library PawnEventLib {
    event SubmitPawnShopPackage(
        uint256 packageId,
        uint256 collateralId,
        LoanRequestStatus status
    );

    event ChangeStatusPawnShopPackage(
        uint256 packageId,
        PawnShopPackageStatus status
    );

    event CreateCollateralEvent(uint256 collateralId, Collateral data);

    event WithdrawCollateralEvent(
        uint256 collateralId,
        address collateralOwner
    );

    event CreateOfferEvent(uint256 offerId, uint256 collateralId, Offer data);

    event CancelOfferEvent(
        uint256 offerId,
        uint256 collateralId,
        address offerOwner
    );
}

library CollateralLib {
    
    function create(
        Collateral storage self,
        address _collateralAddress,
        uint256 _amount,
        address _loanAsset,
        uint256 _expectedDurationQty,
        LoanDurationType _expectedDurationType
    ) internal {
        self.owner = msg.sender;
        self.amount = _amount;
        self.collateralAddress = _collateralAddress;
        self.loanAsset = _loanAsset;
        self.status = CollateralStatus.OPEN;
        self.expectedDurationQty = _expectedDurationQty;
        self.expectedDurationType = _expectedDurationType;
    }

    function withdraw(
        Collateral storage self,
        uint256 _collateralId,
        CollateralOfferList storage _collateralOfferList
    ) internal {
        for (uint256 i = 0; i < _collateralOfferList.offerIdList.length; i++) {
            uint256 offerId = _collateralOfferList.offerIdList[i];
            Offer storage offer = _collateralOfferList.offerMapping[offerId];
            emit PawnEventLib.CancelOfferEvent(
                offerId,
                _collateralId,
                offer.owner
            );
        }
    }

    function submitToLoanPackage(
        Collateral storage self,
        uint256 _packageId,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct
    ) internal {
        if (!_loanRequestListStruct.isInit) {
            _loanRequestListStruct.isInit = true;
        }

        LoanRequestStatusStruct storage statusStruct = _loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];
        require(statusStruct.isInit == false);
        statusStruct.isInit = true;
        statusStruct.status = LoanRequestStatus.PENDING;

        _loanRequestListStruct.pawnShopPackageIdList.push(_packageId);
    }

    function removeFromLoanPackage(
        Collateral storage self,
        uint256 _packageId,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct
    ) internal {
        delete _loanRequestListStruct.loanRequestToPawnShopPackageMapping[_packageId];

        uint256 lastIndex = _loanRequestListStruct.pawnShopPackageIdList.length - 1;

        for (uint256 i = 0; i <= lastIndex; i++) {
            if (_loanRequestListStruct.pawnShopPackageIdList[i] == _packageId) {
                _loanRequestListStruct.pawnShopPackageIdList[i] = _loanRequestListStruct.pawnShopPackageIdList[lastIndex];
                break;
            }
        }
    }

    function checkCondition(
        Collateral storage self,
        uint256 _packageId,
        PawnShopPackage storage _pawnShopPackage,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct,
        CollateralStatus _requiredCollateralStatus,
        LoanRequestStatus _requiredLoanRequestStatus
    ) 
        internal 
        view 
        returns (LoanRequestStatusStruct storage _statusStruct) 
    {
        // Check for owner of packageId
        // _pawnShopPackage = pawnShopPackages[_packageId];
        require(_pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, "0"); // pack

        // Check for collateral status is open
        // _collateral = collaterals[_collateralId];
        require(self.status == _requiredCollateralStatus, "1"); // col

        // Check for collateral-package status is PENDING (waiting for accept)
        // _loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        require(_loanRequestListStruct.isInit == true, "2"); // col-loan-req
        _statusStruct = _loanRequestListStruct
            .loanRequestToPawnShopPackageMapping[_packageId];
        require(_statusStruct.isInit == true, "3"); // col-loan-req-pack
        require(_statusStruct.status == _requiredLoanRequestStatus, "4"); // stt
    }
}

library OfferLib {
    function create(
        Offer storage self,
        address _repaymentAsset,
        uint256 _loanAmount,
        uint256 _duration,
        uint256 _interest,
        uint8 _loanDurationType,
        uint8 _repaymentCycleType,
        uint256 _liquidityThreshold
    ) internal {
        self.isInit = true;
        self.owner = msg.sender;
        self.loanAmount = _loanAmount;
        self.interest = _interest;
        self.duration = _duration;
        self.loanDurationType = LoanDurationType(_loanDurationType);
        self.repaymentAsset = _repaymentAsset;
        self.repaymentCycleType = LoanDurationType(_repaymentCycleType);
        self.liquidityThreshold = _liquidityThreshold;
        self.status = OfferStatus.PENDING;
    }

    function cancel(
        Offer storage self,
        uint256 _id,
        CollateralOfferList storage _collateralOfferList
    ) internal {
        require(self.isInit == true, "1"); // offer-col
        require(self.owner == msg.sender, "2"); // owner
        require(self.status == OfferStatus.PENDING, "3"); // offer

        delete _collateralOfferList.offerMapping[_id];
        uint256 lastIndex = _collateralOfferList.offerIdList.length - 1;
        for (uint256 i = 0; i <= lastIndex; i++) {
            if (_collateralOfferList.offerIdList[i] == _id) {
                _collateralOfferList.offerIdList[i] = _collateralOfferList.offerIdList[lastIndex];
                break;
            }
        }

        delete _collateralOfferList.offerIdList[lastIndex];
    }
}

library PawnPackageLib {
    function create(
        PawnShopPackage storage self,
        PawnShopPackageType _packageType,
        address _loanToken,
        Range calldata _loanAmountRange,
        address[] calldata _collateralAcceptance,
        uint256 _interest,
        uint256 _durationType,
        Range calldata _durationRange,
        address _repaymentAsset,
        LoanDurationType _repaymentCycleType,
        uint256 _loanToValue,
        uint256 _loanToValueLiquidationThreshold
    ) internal {
        self.owner = msg.sender;
        self.status = PawnShopPackageStatus.ACTIVE;
        self.packageType = _packageType;
        self.loanToken = _loanToken;
        self.loanAmountRange = _loanAmountRange;
        self.collateralAcceptance = _collateralAcceptance;
        self.interest = _interest;
        self.durationType = _durationType;
        self.durationRange = _durationRange;
        self.repaymentAsset = _repaymentAsset;
        self.repaymentCycleType = _repaymentCycleType;
        self.loanToValue = _loanToValue;
        self.loanToValueLiquidationThreshold = _loanToValueLiquidationThreshold;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPawnNFT {
    /** ========================= Collateral ============================= */

    // Enum
    enum LoanDurationType {
        WEEK,
        MONTH
    }
    enum CollateralStatus {
        OPEN,
        DOING,
        COMPLETED,
        CANCEL
    }
    enum OfferStatus {
        PENDING,
        ACCEPTED,
        COMPLETED,
        CANCEL
    }
    enum ContractStatus {
        ACTIVE,
        COMPLETED,
        DEFAULT
    }
    enum PaymentRequestStatusEnum {
        ACTIVE,
        LATE,
        COMPLETE,
        DEFAULT
    }
    enum PaymentRequestTypeEnum {
        INTEREST,
        OVERDUE,
        LOAN
    }
    enum ContractLiquidedReasonType {
        LATE,
        RISK,
        UNPAID
    }

    struct Collateral {
        address owner;
        address nftContract;
        uint256 nftTokenId;
        uint256 loanAmount;
        address loanAsset;
        uint256 nftTokenQuantity;
        uint256 expectedDurationQty;
        LoanDurationType durationType;
        CollateralStatus status;
    }

    /**
     * @dev create collateral function, collateral will be stored in this contract
     * @param _nftContract is address NFT token collection
     * @param _nftTokenId is token id of NFT
     * @param _loanAmount is amount collateral
     * @param _loanAsset is address of loan token
     * @param _nftTokenQuantity is quantity NFT token
     * @param _expectedDurationQty is expected duration
     * @param _durationType is expected duration type
     * @param _UID is UID pass create collateral to event collateral
     */
    function createCollateral(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _loanAmount,
        address _loanAsset,
        uint256 _nftTokenQuantity,
        uint256 _expectedDurationQty,
        LoanDurationType _durationType,
        uint256 _UID
    ) external;

    /**
     * @dev withdrawCollateral function, collateral will be delete stored in contract
     * @param _nftCollateralId is id of collateral
     */
    function withdrawCollateral(uint256 _nftCollateralId, uint256 _UID)
        external;

    /** ========================= OFFER ============================= */

    struct CollateralOfferList {
        //offerId => Offer
        mapping(uint256 => Offer) offerMapping;
        uint256[] offerIdList;
        bool isInit;
    }

    struct Offer {
        address owner;
        address repaymentAsset;
        uint256 loanToValue;
        uint256 loanAmount;
        uint256 interest;
        uint256 duration;
        OfferStatus status;
        LoanDurationType loanDurationType;
        LoanDurationType repaymentCycleType;
        uint256 liquidityThreshold;
    }

    /**
     * @dev create offer to collateral
     * @param _nftCollateralId is id collateral
     * @param _repaymentAsset is address token repayment
     * @param _loanToValue is LTV token of loan
     * @param _loanAmount is amount token of loan
     * @param _interest is interest of loan
     * @param _duration is duration of loan
     * @param _liquidityThreshold is liquidity threshold of loan
     * @param _loanDurationType is duration type of loan
     * @param _repaymentCycleType is repayment type of loan
     */
    function createOffer(
        uint256 _nftCollateralId,
        address _repaymentAsset,
        uint256 _loanToValue,
        uint256 _loanAmount,
        uint256 _interest,
        uint256 _duration,
        uint256 _liquidityThreshold,
        LoanDurationType _loanDurationType,
        LoanDurationType _repaymentCycleType,
        uint256 _UID
    ) external;

    /**
     * @dev cancel offer
     * @param _offerId is id offer
     * @param _nftCollateralId is id NFT collateral
     */
    function cancelOffer(
        uint256 _offerId,
        uint256 _nftCollateralId,
        uint256 _UID
    ) external;

    /** ========================= ACCEPT OFFER ============================= */

    struct ContractTerms {
        address borrower;
        address lender;
        uint256 nftTokenId;
        address nftCollateralAsset;
        uint256 nftCollateralAmount;
        address loanAsset;
        uint256 loanAmount;
        address repaymentAsset;
        uint256 interest;
        LoanDurationType repaymentCycleType;
        uint256 liquidityThreshold;
        uint256 contractStartDate;
        uint256 contractEndDate;
        uint256 lateThreshold;
        uint256 systemFeeRate;
        uint256 penaltyRate;
        uint256 prepaidFeeRate;
    }

    struct Contract {
        uint256 nftCollateralId;
        uint256 offerId;
        ContractTerms terms;
        ContractStatus status;
        uint8 lateCount;
    }

    function acceptOffer(
        uint256 _nftCollateralId,
        uint256 _offerId,
        uint256 _UID
    ) external;

    /** ========================= REPAYMENT ============================= */

    struct PaymentRequest {
        uint256 requestId;
        PaymentRequestTypeEnum paymentRequestType;
        uint256 remainingLoan;
        uint256 penalty;
        uint256 interest;
        uint256 remainingPenalty;
        uint256 remainingInterest;
        uint256 dueDateTimestamp;
        bool chargePrepaidFee;
        PaymentRequestStatusEnum status;
    }

    struct ContractLiquidationData {
        uint256 contractId;
        uint256 liquidAmount;
        uint256 systemFeeAmount;
        uint256 collateralExchangeRate;
        uint256 loanExchangeRate;
        uint256 repaymentExchangeRate;
        uint256 rateUpdateTime;
        ContractLiquidedReasonType reasonType;
    }

    function closePaymentRequestAndStartNew(
        int256 _paymentRequestId,
        uint256 _contractId,
        PaymentRequestTypeEnum _paymentRequestType
    ) external;

    /**
     * @dev Borrowers make repayments
     * @param _contractId is id contract
     * @param _paidPenaltyAmount is paid Penalty Amount
     * @param _paidInterestAmount is paid Interest Amount
     * @param _paidLoanAmount is paidLoanAmount
     */
    function repayment(
        uint256 _contractId,
        uint256 _paidPenaltyAmount,
        uint256 _paidInterestAmount,
        uint256 _paidLoanAmount,
        uint256 _UID
    ) external;

    function collateralRiskLiquidationExecution(
        uint256 _contractId
        //        uint256 _collateralPerRepaymentTokenExchangeRate,
        //        uint256 _collateralPerLoanAssetExchangeRate
    ) external;

    function lateLiquidationExecution(uint256 _contractId) external;

    function notPaidFullAtEndContractLiquidation(uint256 _contractId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./IPawn.sol";
import "./PawnLib.sol";
import "../exchange/Exchange.sol";
import "../access/DFY-AccessControl.sol";
import "../reputation/IReputation.sol";

abstract contract PawnModel is
    IPawnV2,
    Initializable,
    UUPSUpgradeable,
    DFYAccessControl,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable 
{
    
    /** ==================== Common state variables ==================== */
    
    mapping(address => uint256) public whitelistCollateral;
    address public feeWallet;
    uint32 public lateThreshold;
    uint32 public penaltyRate;
    uint32 public systemFeeRate; 
    uint32 public prepaidFeeRate;
    uint32 public ZOOM;

    IReputation public reputation;

    /** ==================== Collateral related state variables ==================== */
    // uint256 public numberCollaterals;
    // mapping(uint256 => Collateral) public collaterals;

    /** ==================== Common events ==================== */

    event SubmitPawnShopPackage(
        uint256 packageId,
        uint256 collateralId,
        LoanRequestStatus status
    );

    /** ==================== Initialization ==================== */

    /**
    * @dev initialize function
    * @param _zoom is coefficient used to represent risk params
    */
    function __PawnModel_init(uint32 _zoom) internal initializer {
        __PawnModel_init_unchained();

        ZOOM = _zoom;
    }

    function __PawnModel_init_unchained() internal initializer {
        __DFYAccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    /** ==================== Common functions ==================== */

    // modifier onlyOperator() {
    //     // require(operator == msg.sender, "operator");
    //     _onlyOperator();
    //     _;
    // }
    
    modifier whenContractNotPaused() {
        // require(!paused(), "Pausable: paused");
        _whenNotPaused();
        _;
    }

    // function _onlyOperator() private view {
    //     require(operator == msg.sender, "-0"); //operator
    // }

    function _whenNotPaused() private view {
        require(!paused(), "Pausable: paused");
    }
    
    function pause() onlyRole(DEFAULT_ADMIN_ROLE) external {
        _pause();
    }

    function unPause() onlyRole(DEFAULT_ADMIN_ROLE) external {
        _unpause();
    }

    function setOperator(address _newOperator) onlyRole(DEFAULT_ADMIN_ROLE) external {
        // operator = _newOperator;
        grantRole(OPERATOR_ROLE, _newOperator);
    }

    function setFeeWallet(address _newFeeWallet) onlyRole(DEFAULT_ADMIN_ROLE) external {
        feeWallet = _newFeeWallet;
    }

    /**
    * @dev set fee for each token
    * @param _feeRate is percentage of tokens to pay for the transaction
    */
    function setSystemFeeRate(uint32 _feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        systemFeeRate = _feeRate;
    }

    /**
    * @dev set fee for each token
    * @param _feeRate is percentage of tokens to pay for the penalty
    */
    function setPenaltyRate(uint32 _feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        penaltyRate = _feeRate;
    }

    /**
    * @dev set fee for each token
    * @param _threshold is number of time allowed for late repayment
    */
    function setLateThreshold(uint32 _threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lateThreshold = _threshold;
    }

    function setPrepaidFeeRate(uint32 _feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        prepaidFeeRate = _feeRate;
    }

    function setWhitelistCollateral(address _token, uint256 _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistCollateral[_token] = _status;
    }

    function emergencyWithdraw(address _token)
        external
        override
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PawnLib.safeTransfer(
            _token,
            address(this),
            _msgSender(),
            PawnLib.calculateAmount(_token, address(this))
        );
    }

    /** ==================== Reputation ==================== */
    
    function setReputationContract(address _reputationAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        reputation = IReputation(_reputationAddress);
    }

    /** ==================== Exchange functions & states ==================== */
    Exchange public exchange;

    function setExchangeContract(address _exchangeAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        exchange = Exchange(_exchangeAddress);
    }

    /** ==================== Standard interface function implementations ==================== */

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function supportsInterface(bytes4 interfaceId) 
        public view 
        override(AccessControlUpgradeable) 
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract DFYAccessControl is AccessControlUpgradeable {
    using AddressUpgradeable for address;
    
    /**
    * @dev OPERATOR_ROLE: those who have this role can assigne EVALUATOR_ROLE to others
    */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
    * @dev PAUSER_ROLE: those who can pause the contract
    * by default this role is assigned to the contract creator
    *
    * NOTE: The main contract must inherit `Pausable` or this ROLE doesn't make sense
    */ 
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
    * @dev EVALUATOR_ROLE: Whitelisted Evaluators who can mint NFT token after evaluation has been accepted.
    */
    bytes32 public constant EVALUATOR_ROLE = keccak256("EVALUATOR_ROLE");

    function __DFYAccessControl_init() internal initializer {
        __AccessControl_init();

        __DFYAccessControl_init_unchained();
    }

    function __DFYAccessControl_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        
        // Set OPERATOR_ROLE as EVALUATOR_ROLE's Admin Role 
        _setRoleAdmin(EVALUATOR_ROLE, OPERATOR_ROLE);
    }

    event ContractAdminChanged(address from, address to);

    /**
    * @dev change contract's admin to a new address
    */
    function changeContractAdmin(address newAdmin) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        // Check if the new Admin address is a contract address
        require(!newAdmin.isContract(), "New admin must not be a contract");
        
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());

        emit ContractAdminChanged(_msgSender(), newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPawnV2 {

    /** General functions */

    function emergencyWithdraw(address _token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IPawnNFT.sol";
import "./PawnNFTLib.sol";
import "../access/DFY-AccessControl.sol";
import "../nft/IDFY_Physical_NFTs.sol";
import "../evaluation/EvaluationContract.sol";
import "../evaluation/IBEP20.sol";
import "../reputation/IReputation.sol";
import "../exchange/Exchange.sol";

contract PawnNFTContract is
    IPawnNFT,
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155HolderUpgradeable,
    DFYAccessControl
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    AssetEvaluation assetEvaluation;

    mapping(address => uint256) public whitelistCollateral;
    address public feeWallet;
    uint256 public penaltyRate;
    uint256 public systemFeeRate;
    uint256 public lateThreshold;
    uint256 public prepaidFeeRate;
    uint256 public ZOOM;

    // DFY_Physical_NFTs dfy_physical_nfts;
    // AssetEvaluation assetEvaluation;

    function initialize(uint256 _zoom) public initializer {
        __ERC1155Holder_init();
        __DFYAccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        ZOOM = _zoom;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setOperator(address _newOperator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // operator = _newOperator;
        grantRole(OPERATOR_ROLE, _newOperator);
    }

    function setFeeWallet(address _newFeeWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feeWallet = _newFeeWallet;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev set fee for each token
     * @param _feeRate is percentage of tokens to pay for the transaction
     */
    function setSystemFeeRate(uint256 _feeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        systemFeeRate = _feeRate;
    }

    /**
     * @dev set fee for each token
     * @param _feeRate is percentage of tokens to pay for the penalty
     */
    function setPenaltyRate(uint256 _feeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        penaltyRate = _feeRate;
    }

    /**
     * @dev set fee for each token
     * @param _threshold is number of time allowed for late repayment
     */
    function setLateThreshold(uint256 _threshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lateThreshold = _threshold;
    }

    function setPrepaidFeeRate(uint256 _feeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        prepaidFeeRate = _feeRate;
    }

    function setWhitelistCollateral(address _token, uint256 _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistCollateral[_token] = _status;
    }

    function emergencyWithdraw(address _token)
        external
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PawnNFTLib.safeTransfer(
            _token,
            address(this),
            msg.sender,
            PawnNFTLib.calculateAmount(_token, address(this))
        );
    }

    /** ========================= EVENT ============================= */
    //create collateral & withdraw
    event CollateralEvent(
        uint256 nftCollateralId,
        Collateral data,
        uint256 UID
    );

    //create offer & cancel
    event OfferEvent(
        uint256 offerId,
        uint256 nftCollateralId,
        Offer data,
        uint256 UID
    );

    //accept offer
    event LoanContractCreatedEvent(
        address fromAddress,
        uint256 contractId,
        Contract data,
        uint256 UID
    );

    //repayment
    event PaymentRequestEvent(
        int256 PaymentRequestId,
        uint256 contractId,
        PaymentRequest data
    );

    event RepaymentEvent(
        uint256 contractId,
        uint256 paidPenaltyAmount,
        uint256 paidInterestAmount,
        uint256 paidLoanAmount,
        uint256 paidPenaltyFeeAmount,
        uint256 paidInterestFeeAmount,
        uint256 prepaidAmount,
        uint256 UID
    );

    event ContractLiquidedEvent(ContractLiquidationData liquidationData);

    event LoanContractCompletedEvent(uint256 contractId);

    event CancelOfferEvent(
        uint256 offerId,
        uint256 nftCollateralId,
        address offerOwner,
        uint256 UID
    );

    // Total collateral
    CountersUpgradeable.Counter public numberCollaterals;

    // Mapping collateralId => Collateral
    mapping(uint256 => Collateral) public collaterals;

    // Total offer
    CountersUpgradeable.Counter public numberOffers;

    // Mapping collateralId => list offer of collateral
    mapping(uint256 => CollateralOfferList) public collateralOffersMapping;

    // Total contract
    uint256 public numberContracts;

    // Mapping contractId => Contract
    mapping(uint256 => Contract) public contracts;

    // Mapping contract Id => array payment request
    mapping(uint256 => PaymentRequest[]) public contractPaymentRequestMapping;

    /**
     * @dev create collateral function, collateral will be stored in this contract
     * @param _nftContract is address NFT token collection
     * @param _nftTokenId is token id of NFT
     * @param _loanAmount is amount collateral
     * @param _loanAsset is address of loan token
     * @param _nftTokenQuantity is quantity NFT token
     * @param _expectedDurationQty is expected duration
     * @param _durationType is expected duration type
     * @param _UID is UID pass create collateral to event collateral
     */
    function createCollateral(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _loanAmount,
        address _loanAsset,
        uint256 _nftTokenQuantity,
        uint256 _expectedDurationQty,
        LoanDurationType _durationType,
        uint256 _UID
    ) external override whenNotPaused nonReentrant {
        /**
        TODO: Implementation

        Chú ý: Kiểm tra bên Physical NFT, so khớp số NFT quantity với _nftTokenQuantity
        Chỉ cho phép input <= amount của NFT
        */

        // Check white list nft contract
        require(whitelistCollateral[_nftContract] == 1, "0");

        // Check loan amount
        require(_loanAmount > 0 && _expectedDurationQty > 0, "1");

        // Check loan asset
        require(_loanAsset != address(0), "2");

        // Create Collateral Id
        uint256 collateralId = numberCollaterals.current();

        // Transfer token
        PawnNFTLib.safeTranferNFTToken(
            _nftContract,
            msg.sender,
            address(this),
            _nftTokenId,
            _nftTokenQuantity
        );

        // Create collateral
        collaterals[collateralId] = Collateral({
            owner: msg.sender,
            nftContract: _nftContract,
            nftTokenId: _nftTokenId,
            loanAmount: _loanAmount,
            loanAsset: _loanAsset,
            nftTokenQuantity: _nftTokenQuantity,
            expectedDurationQty: _expectedDurationQty,
            durationType: _durationType,
            status: CollateralStatus.OPEN
        });

        // Update number colaterals
        numberCollaterals.increment();

        emit CollateralEvent(collateralId, collaterals[collateralId], _UID);

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_CREATE_COLLATERAL
        );
    }

    function withdrawCollateral(uint256 _nftCollateralId, uint256 _UID)
        external
        override
        whenNotPaused
    {
        Collateral storage _collateral = collaterals[_nftCollateralId];

        // Check owner collateral
        require(
            _collateral.owner == msg.sender &&
                _collateral.status == CollateralStatus.OPEN,
            "0"
        );

        // Return NFT token to owner
        PawnNFTLib.safeTranferNFTToken(
            _collateral.nftContract,
            address(this),
            _collateral.owner,
            _collateral.nftTokenId,
            _collateral.nftTokenQuantity
        );

        // Remove relation of collateral and offers
        CollateralOfferList
            storage collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];
        if (collateralOfferList.isInit == true) {
            for (
                uint256 i = 0;
                i < collateralOfferList.offerIdList.length;
                i++
            ) {
                uint256 offerId = collateralOfferList.offerIdList[i];
                Offer storage offer = collateralOfferList.offerMapping[offerId];
                emit CancelOfferEvent(
                    offerId,
                    _nftCollateralId,
                    offer.owner,
                    _UID
                );
            }
            delete collateralOffersMapping[_nftCollateralId];
        }

        // Update collateral status
        _collateral.status = CollateralStatus.CANCEL;

        emit CollateralEvent(_nftCollateralId, _collateral, _UID);

        delete collaterals[_nftCollateralId];

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_CANCEL_COLLATERAL
        );
    }

    /**
     * @dev create offer to collateral
     * @param _nftCollateralId is id collateral
     * @param _repaymentAsset is address token repayment
     * @param _loanToValue is LTV token of loan
     * @param _loanAmount is amount token of loan
     * @param _interest is interest of loan
     * @param _duration is duration of loan
     * @param _liquidityThreshold is liquidity threshold of loan
     * @param _loanDurationType is duration type of loan
     * @param _repaymentCycleType is repayment type of loan
     */
    function createOffer(
        uint256 _nftCollateralId,
        address _repaymentAsset,
        uint256 _loanToValue,
        uint256 _loanAmount,
        uint256 _interest,
        uint256 _duration,
        uint256 _liquidityThreshold,
        LoanDurationType _loanDurationType,
        LoanDurationType _repaymentCycleType,
        uint256 _UID
    ) external override whenNotPaused {
        // Get collateral
        Collateral storage _collateral = collaterals[_nftCollateralId];

        // Check owner collateral
        require(
            _collateral.owner != msg.sender &&
                _collateral.status == CollateralStatus.OPEN,
            "0"
        ); // You can not offer.

        // Check approve
        require(
            IERC20Upgradeable(_collateral.loanAsset).allowance(
                msg.sender,
                address(this)
            ) >= _loanAmount,
            "1"
        ); // You not approve.

        // Check repayment asset
        require(_repaymentAsset != address(0), "2"); // Address repayment asset must be different address(0).

        // Check loan amount
        require(
            _loanToValue > 0 &&
                _loanAmount > 0 &&
                _interest > 0 &&
                _liquidityThreshold > _loanToValue,
            "3"
        ); // Loan to value must be grean that 0.

        // Gennerate Offer Id
        uint256 offerId = numberOffers.current();

        // Get offers of collateral
        CollateralOfferList
            storage _collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];

        if (!_collateralOfferList.isInit) {
            _collateralOfferList.isInit = true;
        }

        _collateralOfferList.offerMapping[offerId] = Offer({
            owner: msg.sender,
            repaymentAsset: _repaymentAsset,
            loanToValue: _loanToValue,
            loanAmount: _loanAmount,
            interest: _interest,
            duration: _duration,
            status: OfferStatus.PENDING,
            loanDurationType: _loanDurationType,
            repaymentCycleType: _repaymentCycleType,
            liquidityThreshold: _liquidityThreshold
        });
        _collateralOfferList.offerIdList.push(offerId);

        _collateralOfferList.isInit = true;

        // Update number offer
        numberOffers.increment();

        emit OfferEvent(
            offerId,
            _nftCollateralId,
            _collateralOfferList.offerMapping[offerId],
            _UID
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CREATE_OFFER
        );
    }

    function cancelOffer(
        uint256 _offerId,
        uint256 _nftCollateralId,
        uint256 _UID
    ) external override whenNotPaused {
        // Get offer
        CollateralOfferList
            storage _collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];

        // Check Offer Collater isnit
        require(_collateralOfferList.isInit == true, "0");

        // Get offer
        Offer storage _offer = _collateralOfferList.offerMapping[_offerId];

        // Check owner offer
        require(
            _offer.owner == msg.sender && _offer.status == OfferStatus.PENDING,
            "1"
        );

        delete _collateralOfferList.offerMapping[_offerId];
        for (uint256 i = 0; i < _collateralOfferList.offerIdList.length; i++) {
            if (_collateralOfferList.offerIdList[i] == _offerId) {
                _collateralOfferList.offerIdList[i] = _collateralOfferList
                    .offerIdList[_collateralOfferList.offerIdList.length - 1];
                break;
            }
        }

        delete _collateralOfferList.offerIdList[
            _collateralOfferList.offerIdList.length - 1
        ];
        emit CancelOfferEvent(_offerId, _nftCollateralId, msg.sender, _UID);

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CANCEL_OFFER
        );
    }

    /** ================================ ACCEPT OFFER ============================= */
    /**
     * @dev accept offer and create contract between collateral and offer
     * @param  _nftCollateralId is id of collateral NFT
     * @param  _offerId is id of offer
     */
    function acceptOffer(
        uint256 _nftCollateralId,
        uint256 _offerId,
        uint256 _UID
    ) external override whenNotPaused {
        Collateral storage collateral = collaterals[_nftCollateralId];
        // Check owner of collateral
        require(msg.sender == collateral.owner, "0");
        // Check for collateralNFT status is OPEN
        require(collateral.status == CollateralStatus.OPEN, "1");

        CollateralOfferList
            storage collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];
        require(collateralOfferList.isInit == true, "2");
        // Check for offer status is PENDING
        Offer storage offer = collateralOfferList.offerMapping[_offerId];

        require(offer.status == OfferStatus.PENDING, "3");

        uint256 contractId = createContract(
            _nftCollateralId,
            collateral,
            _offerId,
            offer.loanAmount,
            offer.owner,
            offer.repaymentAsset,
            offer.interest,
            offer.loanDurationType,
            offer.liquidityThreshold
        );
        Contract storage newContract = contracts[contractId];
        // Change status of offer and collateral
        offer.status = OfferStatus.ACCEPTED;
        collateral.status = CollateralStatus.DOING;

        // Cancel other offer sent to this collateral
        for (uint256 i = 0; i < collateralOfferList.offerIdList.length; i++) {
            uint256 thisOfferId = collateralOfferList.offerIdList[i];
            if (thisOfferId != _offerId) {
                //Offer storage thisOffer = collateralOfferList.offerMapping[thisOfferId];
                emit CancelOfferEvent(
                    thisOfferId,
                    _nftCollateralId,
                    offer.owner,
                    _UID
                );
                delete collateralOfferList.offerMapping[thisOfferId];
            }
        }
        delete collateralOfferList.offerIdList;
        collateralOfferList.offerIdList.push(_offerId);

        emit LoanContractCreatedEvent(
            msg.sender,
            contractId,
            newContract,
            _UID
        );

        // Transfer loan asset to collateral owner
        PawnNFTLib.safeTransfer(
            newContract.terms.loanAsset,
            newContract.terms.lender,
            newContract.terms.borrower,
            newContract.terms.loanAmount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_ACCEPT_OFFER
        );
        reputation.adjustReputationScore(
            offer.owner,
            IReputation.ReasonType.LD_ACCEPT_OFFER
        );

        closePaymentRequestAndStartNew(
            0,
            contractId,
            PaymentRequestTypeEnum.INTEREST
        );
    }

    /**
     * @dev create contract between offer and collateral
     * @param  _nftCollateralId is id of Collateral
     * @param  _collateral is Collateral
     * @param  _offerId is id of offer
     * @param  _loanAmount is loan amount
     * @param  _lender is address of lender
     * @param  _repaymentAsset is address of pay token
     * @param  _interest is interest rate payable
     * @param  _repaymentCycleType is repayment cycle type (WEEK/MONTH)
     * @param  _liquidityThreshold is rate will liquidate the contract
     */
    function createContract(
        uint256 _nftCollateralId,
        Collateral storage _collateral,
        uint256 _offerId,
        uint256 _loanAmount,
        address _lender,
        address _repaymentAsset,
        uint256 _interest,
        LoanDurationType _repaymentCycleType,
        uint256 _liquidityThreshold
    ) internal returns (uint256 _idx) {
        // Get Offer
        CollateralOfferList
            storage collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];
        Offer storage _offer = collateralOfferList.offerMapping[_offerId];

        _idx = numberContracts;
        Contract storage newContract = contracts[_idx];
        newContract.nftCollateralId = _nftCollateralId;
        newContract.offerId = _offerId;
        newContract.status = ContractStatus.ACTIVE;
        newContract.lateCount = 0;
        newContract.terms.borrower = _collateral.owner;
        newContract.terms.lender = _lender;
        newContract.terms.nftTokenId = _collateral.nftTokenId;
        newContract.terms.nftCollateralAsset = _collateral.nftContract;
        newContract.terms.nftCollateralAmount = _collateral.nftTokenQuantity;
        newContract.terms.loanAsset = _collateral.loanAsset;
        newContract.terms.loanAmount = _loanAmount;
        newContract.terms.repaymentCycleType = _repaymentCycleType;
        newContract.terms.repaymentAsset = _repaymentAsset;
        newContract.terms.interest = _interest;
        newContract.terms.liquidityThreshold = _liquidityThreshold;
        newContract.terms.contractStartDate = block.timestamp;
        newContract.terms.contractEndDate =
            block.timestamp +
            PawnNFTLib.calculateContractDuration(
                _offer.loanDurationType,
                _offer.duration
            );
        newContract.terms.lateThreshold = lateThreshold;
        newContract.terms.systemFeeRate = systemFeeRate;
        newContract.terms.penaltyRate = penaltyRate;
        newContract.terms.prepaidFeeRate = prepaidFeeRate;
        ++numberContracts;
    }

    function closePaymentRequestAndStartNew(
        int256 _paymentRequestId,
        uint256 _contractId,
        //        uint256 _remainingLoan,
        //        uint256 _nextPhrasePenalty,
        //        uint256 _nextPhraseInterest,
        //        uint256 _dueDateTimestamp,
        PaymentRequestTypeEnum _paymentRequestType
    )
        public
        override
        //        bool _chargePrepaidFee
        whenNotPaused
        onlyRole(OPERATOR_ROLE)
    {
        //Get contract
        Contract storage currentContract = contractMustActive(_contractId);
        bool _chargePrepaidFee;
        uint256 _remainingLoan;
        uint256 _nextPhrasePenalty;
        uint256 _nextPhraseInterest;
        uint256 _dueDateTimestamp;

        // Check if number of requests is 0 => create new requests, if not then update current request as LATE or COMPLETE and create new requests
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        if (requests.length > 0) {
            // not first phrase, get previous request
            PaymentRequest storage previousRequest = requests[
                requests.length - 1
            ];

            // Validate: time must over due date of current payment
            require(block.timestamp >= previousRequest.dueDateTimestamp, "0");

            // Validate: remaining loan must valid
            //            require(previousRequest.remainingLoan == _remainingLoan, '1');
            _remainingLoan = previousRequest.remainingLoan;
            _nextPhrasePenalty = exchange.calculatePenaltyNFT(
                previousRequest,
                currentContract,
                penaltyRate
            );

            if (_paymentRequestType == PaymentRequestTypeEnum.INTEREST) {
                _dueDateTimestamp = PawnNFTLib.add(
                    previousRequest.dueDateTimestamp,
                    PawnNFTLib.calculatedueDateTimestampInterest(
                        currentContract.terms.repaymentCycleType
                    )
                );
                _nextPhraseInterest = exchange.calculateInterestNFT(
                    currentContract
                );
            }
            if (_paymentRequestType == PaymentRequestTypeEnum.OVERDUE) {
                _dueDateTimestamp = PawnNFTLib.add(
                    previousRequest.dueDateTimestamp,
                    PawnNFTLib.calculatedueDateTimestampPenalty(
                        currentContract.terms.repaymentCycleType
                    )
                );
                _nextPhraseInterest = 0;
            }

            if (_dueDateTimestamp >= currentContract.terms.contractEndDate) {
                _chargePrepaidFee = true;
            } else {
                _chargePrepaidFee = false;
            }

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(
                _dueDateTimestamp <= currentContract.terms.contractEndDate,
                "2"
            );
            //            require(_dueDateTimestamp > previousRequest.dueDateTimestamp || _dueDateTimestamp == 0, '3');

            // update previous
            // check for remaining penalty and interest, if greater than zero then is Lated, otherwise is completed
            if (
                previousRequest.remainingInterest > 0 ||
                previousRequest.remainingPenalty > 0
            ) {
                previousRequest.status = PaymentRequestStatusEnum.LATE;
                // Update late counter of contract
                currentContract.lateCount += 1;

                // Adjust reputation score
                reputation.adjustReputationScore(
                    currentContract.terms.borrower,
                    IReputation.ReasonType.BR_LATE_PAYMENT
                );

                // Check for late threshold reach
                if (
                    currentContract.terms.lateThreshold <=
                    currentContract.lateCount
                ) {
                    // Execute liquid
                    _liquidationExecution(
                        _contractId,
                        ContractLiquidedReasonType.LATE
                    );
                    return;
                }
            } else {
                previousRequest.status = PaymentRequestStatusEnum.COMPLETE;

                // Adjust reputation score
                reputation.adjustReputationScore(
                    currentContract.terms.borrower,
                    IReputation.ReasonType.BR_ONTIME_PAYMENT
                );
            }

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                if (
                    previousRequest.remainingInterest +
                        previousRequest.remainingPenalty +
                        previousRequest.remainingLoan >
                    0
                ) {
                    // unpaid => liquid
                    _liquidationExecution(
                        _contractId,
                        ContractLiquidedReasonType.UNPAID
                    );
                    return;
                } else {
                    // paid full => release collateral
                    _returnCollateralToBorrowerAndCloseContract(_contractId);
                    return;
                }
            }

            emit PaymentRequestEvent(-1, _contractId, previousRequest);
        } else {
            // Validate: remaining loan must valid
            //            require(currentContract.terms.loanAmount == _remainingLoan, '4');
            _remainingLoan = currentContract.terms.loanAmount;
            _nextPhraseInterest = exchange.calculateInterestNFT(
                currentContract
            );
            _nextPhrasePenalty = 0;
            _dueDateTimestamp = PawnNFTLib.add(
                block.timestamp,
                PawnNFTLib.calculatedueDateTimestampInterest(
                    currentContract.terms.repaymentCycleType
                )
            );

            if (
                currentContract.terms.repaymentCycleType ==
                LoanDurationType.WEEK
            ) {
                if (
                    currentContract.terms.contractEndDate -
                        currentContract.terms.contractStartDate ==
                    600
                ) {
                    _chargePrepaidFee = true;
                } else {
                    _chargePrepaidFee = false;
                }
            } else {
                if (
                    currentContract.terms.contractEndDate -
                        currentContract.terms.contractStartDate ==
                    900
                ) {
                    _chargePrepaidFee = true;
                } else {
                    _chargePrepaidFee = false;
                }
            }
            // Validate: Due date timestamp of next payment request must not over contract due date
            require(
                _dueDateTimestamp <= currentContract.terms.contractEndDate,
                "5"
            );
            require(
                _dueDateTimestamp > currentContract.terms.contractStartDate ||
                    _dueDateTimestamp == 0,
                "6"
            );
            require(
                block.timestamp < _dueDateTimestamp || _dueDateTimestamp == 0,
                "7"
            );

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                // paid full => release collateral
                _returnCollateralToBorrowerAndCloseContract(_contractId);
                return;
            }
        }

        // Create new payment request and store to contract
        PaymentRequest memory newRequest = PaymentRequest({
            requestId: requests.length,
            paymentRequestType: _paymentRequestType,
            remainingLoan: _remainingLoan,
            penalty: _nextPhrasePenalty,
            interest: _nextPhraseInterest,
            remainingPenalty: _nextPhrasePenalty,
            remainingInterest: _nextPhraseInterest,
            dueDateTimestamp: _dueDateTimestamp,
            status: PaymentRequestStatusEnum.ACTIVE,
            chargePrepaidFee: _chargePrepaidFee
        });
        requests.push(newRequest);
        emit PaymentRequestEvent(_paymentRequestId, _contractId, newRequest);
    }

    /**
     * @dev get Contract must active
     * @param  _contractId is id of contract
     */
    function contractMustActive(uint256 _contractId)
        internal
        view
        returns (Contract storage _contract)
    {
        // Validate: Contract must active
        _contract = contracts[_contractId];
        require(_contract.status == ContractStatus.ACTIVE, "0");
    }

    /**
     * @dev Perform contract liquidation
     * @param  _contractId is id of contract
     * @param  _reasonType is type of reason for liquidation of the contract
     */
    function _liquidationExecution(
        uint256 _contractId,
        ContractLiquidedReasonType _reasonType
    ) internal {
        Contract storage _contract = contracts[_contractId];

        // Execute: update status of contract to DEFAULT, collateral to COMPLETE
        _contract.status = ContractStatus.DEFAULT;
        PaymentRequest[]
            storage _paymentRequests = contractPaymentRequestMapping[
                _contractId
            ];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[
            _paymentRequests.length - 1
        ];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.DEFAULT;
        Collateral storage _collateral = collaterals[_contract.nftCollateralId];
        _collateral.status = CollateralStatus.COMPLETED;

        //get Address of EvaluationContract
        (address _evaluationContract, ) = IDFY_Physical_NFTs(
            _collateral.nftContract
        ).getEvaluationOfToken(_collateral.nftTokenId);

        // get Evaluation from address of EvaluationContract
        (, , , , address token, , ) = AssetEvaluation(_evaluationContract)
            .tokenIdByEvaluation(_collateral.nftTokenId);

        (
            uint256 _collateralExchangeRate,
            uint256 _loanExchangeRate,
            uint256 _repaymentExchangeRate,
            uint256 _rateUpdatedTime
        ) = exchange.RateAndTimestampNFT(_contract, token);

        // Emit Event ContractLiquidedEvent
        ContractLiquidationData
            memory liquidationData = ContractLiquidationData(
                _contractId,
                0,
                0,
                _collateralExchangeRate,
                _loanExchangeRate,
                _repaymentExchangeRate,
                _rateUpdatedTime,
                _reasonType
            );

        emit ContractLiquidedEvent(liquidationData);
        // Transfer to lender collateral
        PawnNFTLib.safeTranferNFTToken(
            _contract.terms.nftCollateralAsset,
            address(this),
            _contract.terms.lender,
            _contract.terms.nftTokenId,
            _contract.terms.nftCollateralAmount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_LATE_PAYMENT
        );
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_CONTRACT_DEFAULTED
        );
    }

    /**
     * @dev return collateral to borrower and close contract
     * @param  _contractId is id of contract
     */
    function _returnCollateralToBorrowerAndCloseContract(uint256 _contractId)
        internal
    {
        Contract storage _contract = contracts[_contractId];
        Collateral storage _collateral = collaterals[_contract.nftCollateralId];

        // Execute: Update status of contract to COMPLETE, collateral to COMPLETE
        _contract.status = ContractStatus.COMPLETED;
        PaymentRequest[]
            storage _paymentRequests = contractPaymentRequestMapping[
                _contractId
            ];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[
            _paymentRequests.length - 1
        ];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.COMPLETE;
        _collateral.status = CollateralStatus.COMPLETED;

        // Emit Event ContractLiquidedEvent
        emit LoanContractCompletedEvent(_contractId);

        // Execute: Transfer collateral to borrower
        PawnNFTLib.safeTranferNFTToken(
            _contract.terms.nftCollateralAsset,
            address(this),
            _contract.terms.borrower,
            _contract.terms.nftTokenId,
            _contract.terms.nftCollateralAmount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_ONTIME_PAYMENT
        );
        reputation.adjustReputationScore(
            _contract.terms.borrower,
            IReputation.ReasonType.BR_CONTRACT_COMPLETE
        );
    }

    /**
     * @dev the borrower repays the debt
     * @param  _contractId is id of contract
     * @param  _paidPenaltyAmount is paid penalty amount
     * @param  _paidInterestAmount is paid interest amount
     * @param  _paidLoanAmount is paid loan amount
     */
    function repayment(
        uint256 _contractId,
        uint256 _paidPenaltyAmount,
        uint256 _paidInterestAmount,
        uint256 _paidLoanAmount,
        uint256 _UID
    ) external override whenNotPaused {
        // Get contract & payment request
        Contract storage _contract = contractMustActive(_contractId);
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        require(requests.length > 0, "0");
        PaymentRequest storage _paymentRequest = requests[requests.length - 1];

        // Validation: Contract must not overdue
        require(block.timestamp <= _contract.terms.contractEndDate, "1");

        // Validation: current payment request must active and not over due
        require(_paymentRequest.status == PaymentRequestStatusEnum.ACTIVE, "2");
        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            require(block.timestamp <= _paymentRequest.dueDateTimestamp, "3");
        }

        // Calculate paid amount / remaining amount, if greater => get paid amount
        if (_paidPenaltyAmount > _paymentRequest.remainingPenalty) {
            _paidPenaltyAmount = _paymentRequest.remainingPenalty;
        }

        if (_paidInterestAmount > _paymentRequest.remainingInterest) {
            _paidInterestAmount = _paymentRequest.remainingInterest;
        }

        if (_paidLoanAmount > _paymentRequest.remainingLoan) {
            _paidLoanAmount = _paymentRequest.remainingLoan;
        }

        // Calculate fee amount based on paid amount
        uint256 _feePenalty = PawnNFTLib.calculateSystemFee(
            _paidPenaltyAmount,
            _contract.terms.systemFeeRate,
            ZOOM
        );
        uint256 _feeInterest = PawnNFTLib.calculateSystemFee(
            _paidInterestAmount,
            _contract.terms.systemFeeRate,
            ZOOM
        );

        uint256 _prepaidFee = 0;
        if (_paymentRequest.chargePrepaidFee) {
            _prepaidFee = PawnNFTLib.calculateSystemFee(
                _paidLoanAmount,
                _contract.terms.prepaidFeeRate,
                ZOOM
            );
        }

        // Update paid amount on payment request
        _paymentRequest.remainingPenalty -= _paidPenaltyAmount;
        _paymentRequest.remainingInterest -= _paidInterestAmount;
        _paymentRequest.remainingLoan -= _paidLoanAmount;

        // emit event repayment
        emit RepaymentEvent(
            _contractId,
            _paidPenaltyAmount,
            _paidInterestAmount,
            _paidLoanAmount,
            _feePenalty,
            _feeInterest,
            _prepaidFee,
            _UID
        );

        // If remaining loan = 0 => paidoff => execute release collateral
        if (
            _paymentRequest.remainingLoan == 0 &&
            _paymentRequest.remainingPenalty == 0 &&
            _paymentRequest.remainingInterest == 0
        ) _returnCollateralToBorrowerAndCloseContract(_contractId);

        uint256 _totalFee;
        uint256 _totalTransferAmount;

        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            // Transfer fee to fee wallet
            _totalFee = _feePenalty + _feeInterest;
            PawnNFTLib.safeTransfer(
                _contract.terms.repaymentAsset,
                msg.sender,
                feeWallet,
                _totalFee
            );

            // Transfer penalty and interest to lender except fee amount
            _totalTransferAmount =
                _paidPenaltyAmount +
                _paidInterestAmount -
                _feePenalty -
                _feeInterest;
            PawnNFTLib.safeTransfer(
                _contract.terms.repaymentAsset,
                msg.sender,
                _contract.terms.lender,
                _totalTransferAmount
            );
        }

        if (_paidLoanAmount > 0) {
            // Transfer loan amount and prepaid fee to lender
            _totalTransferAmount = _paidLoanAmount + _prepaidFee;
            PawnNFTLib.safeTransfer(
                _contract.terms.loanAsset,
                msg.sender,
                _contract.terms.lender,
                _totalTransferAmount
            );
        }
    }

    function collateralRiskLiquidationExecution(uint256 _contractId)
        external
        override
        //        uint256 _collateralPerRepaymentTokenExchangeRate,
        //        uint256 _collateralPerLoanAssetExchangeRate
        whenNotPaused
        onlyRole(OPERATOR_ROLE)
    {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);
        Collateral storage _collateral = collaterals[_contract.nftCollateralId];

        //get Address of EvaluationContract
        (address _evaluationContract, ) = IDFY_Physical_NFTs(
            _collateral.nftContract
        ).getEvaluationOfToken(_collateral.nftTokenId);

        // get Evaluation from address of EvaluationContract
        (, , , , address token, uint256 price, ) = AssetEvaluation(
            _evaluationContract
        ).tokenIdByEvaluation(_collateral.nftTokenId);

        (
            uint256 collateralExchangeRate,
            uint256 loanExchangeRate,
            uint256 repaymentExchangeRate,

        ) = exchange.RateAndTimestampNFT(_contract, token);

        (
            uint256 remainingRepayment,
            uint256 remainingLoan
        ) = calculateRemainingLoanAndRepaymentFromContract(
                _contractId,
                _contract
            );
        uint256 valueOfRemainingRepayment = (repaymentExchangeRate *
            remainingRepayment) / ZOOM;
        uint256 valueOfRemainingLoan = (loanExchangeRate * remainingLoan) /
            ZOOM;
        uint256 valueOfCollateralLiquidationThreshold = (collateralExchangeRate *
                price *
                _contract.terms.liquidityThreshold) / (100 * ZOOM);

        require(
            valueOfRemainingLoan + valueOfRemainingRepayment >=
                valueOfCollateralLiquidationThreshold,
            "0"
        );

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.RISK);
    }

    /**
     * @dev liquidate the contract if the borrower has not paid in full at the end of the contract
     * @param _contractId is id of contract
     */
    function lateLiquidationExecution(uint256 _contractId)
        external
        override
        whenNotPaused
    {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);

        // validate: contract have lateCount == lateThreshold
        require(_contract.lateCount >= _contract.terms.lateThreshold, "0");

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
    }

    /**
     * @dev liquidate the contract if the borrower has not paid in full at the end of the contract
     * @param _contractId is id of contract
     */
    function notPaidFullAtEndContractLiquidation(uint256 _contractId)
        external
        override
        whenNotPaused
    {
        Contract storage _contract = contractMustActive(_contractId);
        // validate: current is over contract end date
        require(block.timestamp >= _contract.terms.contractEndDate, "0");

        // validate: remaining loan, interest, penalty haven't paid in full
        (
            uint256 remainingRepayment,
            uint256 remainingLoan
        ) = calculateRemainingLoanAndRepaymentFromContract(
                _contractId,
                _contract
            );

        require(remainingRepayment + remainingLoan > 0, "1");

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.UNPAID);
    }

    function calculateRemainingLoanAndRepaymentFromContract(
        uint256 _contractId,
        Contract storage _contract
    )
        internal
        view
        returns (uint256 remainingRepayment, uint256 remainingLoan)
    {
        // Validate: sum of unpaid interest, penalty and remaining loan in value must reach liquidation threshold of collateral value
        PaymentRequest[] storage requests = contractPaymentRequestMapping[
            _contractId
        ];
        if (requests.length > 0) {
            // Have payment request
            PaymentRequest storage _paymentRequest = requests[
                requests.length - 1
            ];
            remainingRepayment =
                _paymentRequest.remainingInterest +
                _paymentRequest.remainingPenalty;
            remainingLoan = _paymentRequest.remainingLoan;
        } else {
            // Haven't had payment request
            remainingRepayment = 0;
            remainingLoan = _contract.terms.loanAmount;
        }
    }

    /** ===================================== REPUTATION FUNCTIONS & STATES ===================================== */

    IReputation public reputation;

    function setReputationContract(address _reputationAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        reputation = IReputation(_reputationAddress);
    }

    Exchange public exchange;

    function setExchangeContract(address _exchangeAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        exchange = Exchange(_exchangeAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./IPawnNFT.sol";

library PawnNFTLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev safe transfer BNB or ERC20
     * @param  asset is address of the cryptocurrency to be transferred
     * @param  from is the address of the transferor
     * @param  to is the address of the receiver
     * @param  amount is transfer amount
     */
    function safeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (asset == address(0)) {
            require(from.balance >= amount, "not-enough-balance");
            // Handle BNB
            if (to == address(this)) {
                // Send to this contract
            } else if (from == address(this)) {
                // Send from this contract
                (bool success, ) = to.call{value: amount}("");
                require(success, "fail-transfer-bnb");
            } else {
                // Send from other address to another address
                require(false, "not-allow-transfer");
            }
        } else {
            // Handle ERC20
            uint256 prebalance = IERC20Upgradeable(asset).balanceOf(to);
            require(
                IERC20Upgradeable(asset).balanceOf(from) >= amount,
                "not-enough-balance"
            );
            if (from == address(this)) {
                // transfer direct to to
                IERC20Upgradeable(asset).safeTransfer(to, amount);
            } else {
                require(
                    IERC20Upgradeable(asset).allowance(from, address(this)) >=
                        amount,
                    "not-enough-allowance"
                );
                IERC20Upgradeable(asset).safeTransferFrom(from, to, amount);
            }
            require(
                IERC20Upgradeable(asset).balanceOf(to) - amount == prebalance,
                "not-transfer-enough"
            );
        }
    }

    function safeTranferNFTToken(
        address _nftToken,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal {
        // check address token
        require(
            _nftToken != address(0),
            "Address token must be different address(0)."
        );

        // check address from
        require(
            _from != address(0),
            "Address from must be different address(0)."
        );

        // check address from
        require(_to != address(0), "Address to must be different address(0).");

        // Check amount token
        require(_amount > 0, "Amount must be grean than 0.");

        // Check balance of from,
        require(
            IERC1155Upgradeable(_nftToken).balanceOf(_from, _id) >= _amount,
            "Your balance not enough."
        );

        // Transfer token
        IERC1155Upgradeable(_nftToken).safeTransferFrom(
            _from,
            _to,
            _id,
            _amount,
            ""
        );
    }

    /**
     * @dev Calculate the duration of the contract
     * @param  durationType is loan duration type of contract (WEEK/MONTH)
     * @param  duration is duration of contract
     */
    function calculateContractDuration(
        IPawnNFT.LoanDurationType durationType,
        uint256 duration
    ) internal pure returns (uint256 inSeconds) {
        if (durationType == IPawnNFT.LoanDurationType.WEEK) {
            // inSeconds = 7 * 24 * 3600 * duration;
            inSeconds = 600 * duration; //test
        } else {
            // inSeconds = 30 * 24 * 3600 * duration;
            inSeconds = 900 * duration; // test
        }
    }

    function calculatedueDateTimestampInterest(
        IPawnNFT.LoanDurationType durationType
    ) internal pure returns (uint256 duedateTimestampInterest) {
        if (durationType == IPawnNFT.LoanDurationType.WEEK) {
            // duedateTimestampInterest = 3*24*3600;
            duedateTimestampInterest = 300; // test
        } else {
            // duedateTimestampInterest = 7 * 24 * 3600;
            duedateTimestampInterest = 500; // test
        }
    }

    function calculatedueDateTimestampPenalty(
        IPawnNFT.LoanDurationType durationType
    ) internal pure returns (uint256 duedateTimestampInterest) {
        if (durationType == IPawnNFT.LoanDurationType.WEEK) {
            // duedateTimestampInterest = 7 * 24 *3600 - 3 * 24 * 3600;
            duedateTimestampInterest = 600 - 300; // test
        } else {
            //  duedateTimestampInterest = 30 * 24 *3600 - 7 * 24 * 3600;
            duedateTimestampInterest = 900 - 500; // test
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "0"); //SafeMath: addition overflow

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "1"); //SafeMath: subtraction overflow
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "2"); //SafeMath: multiplication overflow

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "3"); //SafeMath: division by zero
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Calculate balance of wallet address
     * @param  _token is address of token
     * @param  from is address wallet
     */
    function calculateAmount(address _token, address from)
        internal
        view
        returns (uint256 _amount)
    {
        if (_token == address(0)) {
            // BNB
            _amount = from.balance;
        } else {
            // ERC20
            _amount = IERC20Upgradeable(_token).balanceOf(from);
        }
    }

    /**
     * @dev Calculate fee of system
     * @param  amount amount charged to the system
     * @param  feeRate is system fee rate
     */
    function calculateSystemFee(
        uint256 amount,
        uint256 feeRate,
        uint256 zoom
    ) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (zoom * 100);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDFY_Physical_NFTs {
    
    struct NFTEvaluation{
        address evaluationContract;
        uint256 evaluationId;
    }

    function mint(
        address _assetOwner, 
        address _evaluator, 
        uint256 _evaluatontId, 
        uint256 _amount, 
        string memory _cid, 
        bytes memory _data
    ) 
        external
        returns (uint256 tokenId);

    function getEvaluationOfToken(uint256 _tokenId) 
        external 
        returns (address evaluationAddress, uint256 evaluationId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../access/DFY-AccessControl.sol";
import "../nft/IDFY_Physical_NFTs.sol";
import "./IBEP20.sol";



contract AssetEvaluation is 
    Initializable,
    UUPSUpgradeable, 
    ReentrancyGuardUpgradeable,
    ERC1155HolderUpgradeable, 
    PausableUpgradeable, 
    DFYAccessControl
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint;

    // Total asset
    CountersUpgradeable.Counter public totalAssets;

    // DFY Token;
    IBEP20 public ibepDFY;

    // NFT Token;
    IDFY_Physical_NFTs public dfy_physical_nfts;

    // Address admin
    address private addressAdmin;

    // Assuming _assetBaseUri = "https://ipfs.io/ipfs"
    string private _assetBaseUri;

    // Mapping list asset
    // AssetId => Asset
    mapping (uint256 => Asset) public assetList;

    // Mapping from creator to asset
    // Creator => listAssetId
    mapping (address => uint256[]) public assetListByCreator; 

    // Mapping from creator address to assetId in his/her possession
    // Creator => (assetId => bool)
    mapping (address => mapping (uint256 => bool)) private _assetsOfCreator;

    // Total evaluation
    CountersUpgradeable.Counter public totalEvaluation;

    // Mapping list evaluation
    // EvaluationId => evaluation
    mapping (uint256 => Evaluation) public evaluationList;

    // Mapping from asset to list evaluation
    // AssetId => listEvaluationId
    mapping (uint256 => uint256[]) public evaluationByAsset;

    // Mapping from evaluator to evaluation
    // Evaluator => listEvaluation
    mapping (address => uint256[]) public evaluationListByEvaluator;

    // Mapping tokenId to asset
    // TokenId => asset
    mapping (uint256 => Asset) public tokenIdByAsset;

    // Mapping tokenId to evaluation
    // TokenId => evaluation
    mapping (uint256 => Evaluation) public tokenIdByEvaluation; // Should be changed to Evaluation by tokenId

    // Mintting NFT fee
    uint256 public _mintingNFTFee;

    function initialize(
        string memory _uri,
        address _dfy1155_physical_nft_address,
        address _ibep20_DFY_address
    ) public initializer {
        __ERC1155Holder_init();
        __DFYAccessControl_init();
        __Pausable_init();

        _setAssetBaseURI(_uri);

        _setNFTAddress(_dfy1155_physical_nft_address);

        _setTokenIBEP20Address(_ibep20_DFY_address);

        _setAddressAdmin(msg.sender);

        _setMintingNFTFee(50 * 10 ** 18);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // Enum status asset
    enum AssetStatus {OPEN, EVALUATED, NFT_CREATED}

    // Asset
    struct Asset {
        string assetDataCID;
        address creator;
        AssetStatus status;
    }

    // Enum status evaluation
    enum EvaluationStatus {EVALUATED, EVALUATION_ACCEPTED, EVALUATION_REJECTED, NFT_CREATED}

    // Evaluation
    struct Evaluation {
        uint256 assetId;
        string  evaluationCID;
        uint256 depreciationRate;
        address evaluator;
        address token;
        uint256 price;
        EvaluationStatus status;
    }

    event AssetCreated (
        uint256 assetId,
        Asset asset
    );

    event AssetEvaluated(
        uint256 evaluationId,
        uint256 assetId,
        Asset asset,
        Evaluation evaluation
    );

    event ApproveEvaluator(
        address evaluator
    );

    // Modifier check address call function
    modifier OnlyEOA() {
        require(!msg.sender.isContract(), "Calling from a contract");
        _;
    }

    // Function set base uri
    function setBaseURI(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setAssetBaseURI(_uri);
    }

    // Function set asset base uri
    function _setAssetBaseURI(string memory _uri) internal {
        require(bytes(_uri).length > 0, "Empty asset URI");
        _assetBaseUri = _uri;
    }

    // Function  
    function assetURI(uint256 _assetId) external view returns (string memory){
        return bytes(_assetBaseUri).length > 0 ? string(abi.encodePacked(_assetBaseUri, assetList[_assetId].assetDataCID)) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable) returns (bool){
        return super.supportsInterface(interfaceId);
    }


    /**
    * @dev Set the current NFT contract address to a new address
    * @param _newAddress is the address of the new NFT contract
    */
    function setNftContractAddress(address _newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Verify if the new address is a contract or not
        require(_newAddress.isContract(), "Not a contract");
        
        _setNFTAddress(_newAddress);
    }

    function _setNFTAddress(address _newAddress) internal {
        dfy_physical_nfts = IDFY_Physical_NFTs(_newAddress);
    }

    /**
    * @dev Set the current NFT contract address to a new address
    * @param _newAddress is the address of the new NFT contract
    */
    function setTokenIBEP20Address(address _newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Verify if the new address is a contract or not
        require(_newAddress.isContract(), "Not a contract");
        
        _setTokenIBEP20Address(_newAddress);
    }

    function _setTokenIBEP20Address(address _newAddress) internal {
        ibepDFY = IBEP20(_newAddress);
    }

    function setFeeWallet(address _feeWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setAddressAdmin(_feeWallet);
    }

    function feeWallet() external view returns (address) {
        return addressAdmin;
    }
    
    function _setAddressAdmin(address _newAddress) internal {
        addressAdmin = _newAddress;
    }

    function setMintingNFTFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Verify if the new address is a contract or not
        require(_fee > 0, "Not_Enough");
        
        _setMintingNFTFee(_fee);
    }

    function _setMintingNFTFee(uint256 _fee) internal {
        _mintingNFTFee = _fee;
    }

    /**
    * @dev Asset creation request by customer
    * @dev msg.sender is the asset creator's address
    * @param _cid is the CID string of the asset's JSON file stored on IFPS
    */
    function createAssetRequest(string memory _cid) external OnlyEOA {
        // msg.sender must not be a contract address

        // Require length _cid >0
        require(bytes(_cid).length > 0, "Asset CID must not be empty.");

        // Create asset id
        uint256 _assetId = totalAssets.current();

        // Add asset from asset list
        assetList[_assetId] =  Asset({
                                assetDataCID: _cid,
                                creator: msg.sender,
                                status: AssetStatus.OPEN
                            });
        
        // Add asset id from list asset id of owner
        assetListByCreator[msg.sender].push(_assetId);

        // Update status from asset id of owner 
        _assetsOfCreator[msg.sender][_assetId] = true;

        // Update total asset
        totalAssets.increment();

        emit AssetCreated(_assetId, assetList[_assetId]);
    }

    /**
    * @dev Return a list of asset created by _creator 
    * @param _creator address representing the creator / owner of the assets.
    */
    function getAssetsByCreator(address _creator) external view returns (uint256[] memory) {
        require(_creator != address(0), "There is no asset associated with the zero address");

        return assetListByCreator[_creator];
    }

    // Function check asset of creator
    function _isAssetOfCreator(address _creator, uint256 _assetId) internal view returns (bool) {
        return _assetsOfCreator[_creator][_assetId];
    }

    /**
    * @dev Asset evaluation by evaluator
    * @dev msg.sender is evaluator address
    * @param _assetId is the ID of the asset in AssetList
    * @param _currency is address of the token who create the asset
    * @param _price value of the asset, given by the Evaluator
    * @param _evaluationCID is Evaluation CID
    * @param _depreciationRate is depreciation rate of asset
    */
    function evaluateAsset(uint256 _assetId, address _currency, uint256 _price, string memory _evaluationCID, uint256 _depreciationRate) external OnlyEOA onlyRole(EVALUATOR_ROLE) {
        // TODO
        // Require validation of msg.sender
        require(msg.sender != address(0),"Caller address different address(0).");

        // Check evaluation CID
        require(bytes(_evaluationCID).length >0, "Evaluation CID not be empty.");

        // Require address currency is contract except BNB - 0x0000000000000000000000000000000000000000
        if(_currency != address(0)) {
            require(_currency.isContract(), "Address token is not defined.");
        }

        // Require validation is creator asset
        require(!_isAssetOfCreator(msg.sender, _assetId), "You cant evaluted your asset.");

        // Require validation of asset via _assetId
        require(_assetId >=0 ,"Asset does not exist.");

        // Get asset to asset id;
        Asset memory _asset = assetList[_assetId];

        // Check asset is exists
        require(bytes(_asset.assetDataCID).length >0, "Asset does not exists.");

        // check status asset
        require(_asset.status == AssetStatus.OPEN, "This asset evaluated.");

        // Create evaluation id
        uint256 _evaluationId = totalEvaluation.current();
        
        // Add evaluation to evaluationList 
        evaluationList[_evaluationId] = Evaluation({
                                                assetId: _assetId,
                                                evaluationCID: _evaluationCID,
                                                depreciationRate: _depreciationRate,
                                                evaluator: msg.sender,
                                                token: _currency,
                                                price: _price,
                                                status: EvaluationStatus.EVALUATED
                                            });
        
        
        // Add evaluation id to list evaluation of asset
        evaluationByAsset[_assetId].push(_evaluationId);

        // Add evaluation id to list evaluation of evaluator 
        evaluationListByEvaluator[msg.sender].push(_evaluationId);

        // Update total evaluation
        totalEvaluation.increment();

        emit AssetEvaluated(_evaluationId,_assetId,_asset,evaluationList[_evaluationId]);
    }

    /** 
    * @dev this function is check data when customer accept or reject evaluation
    * @param _assetId is the ID of the asset in AssetList
    * @param _evaluationId is the look up index of the Evaluation data in EvaluationsByAsset list
    */
    function _checkDataAcceptOrReject(uint256 _assetId, uint256 _evaluationId) internal view returns (bool) {
        
        // Check creator is address 0
        require(msg.sender != address(0), "ZERO_ADDRESS"); // msg.sender must not be the zero address

        // Check asset id
        require(_assetId >= 0, "INVALID_ASSET"); // assetId must not be zero

        // Check evaluation index
        require(_evaluationId >= 0, "INVALID_EVA"); // evaluationID must not be zero

        // Get asset to asset id;
        Asset memory _asset = assetList[_assetId];

        // Check asset to creator
        require(_asset.creator == msg.sender, "NOT_THE_OWNER"); // msg.sender must be the creator of the asset

        // Check asset is exists
        require(_asset.status == AssetStatus.OPEN, "EVA_NOT_ALLOWED"); // asset status must be Open

        // approve an evaluation by looking for its index in the array.
        Evaluation memory _evaluation = evaluationList[_evaluationId];

        // Check status evaluation
        require(_evaluation.status == EvaluationStatus.EVALUATED, "ASSET_NOT_EVALUATED"); // evaluation status must be Evaluated
        
        return true;
    }

    /**
    * @dev This function is customer accept an evaluation
    * @param _assetId is id of asset
    * @param _evaluationId is id evaluation of asset
    */    
    function acceptEvaluation(uint256 _assetId, uint256 _evaluationId) external OnlyEOA {

        // Check data
        require(_checkDataAcceptOrReject(_assetId, _evaluationId));

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];
        
        // Update status evaluation
        _evaluation.status = EvaluationStatus.EVALUATION_ACCEPTED;
        
        // Reject all other evaluation of asset
        for(uint i = 0; i < evaluationByAsset[_assetId].length; i++) {
            if(evaluationByAsset[_assetId][i] != _evaluationId) {
                uint256  _evaluationIdReject = evaluationByAsset[_assetId][i];
                
                // Get evaluation
                Evaluation storage _otherEvaluation = evaluationList[_evaluationIdReject];
        
                // Update status evaluation
                _otherEvaluation.status = EvaluationStatus.EVALUATION_REJECTED;

                emit AssetEvaluated(_evaluationId,_assetId, _asset, _otherEvaluation);
            }
        }

        // Update status asset
        _asset.status = AssetStatus.EVALUATED;

        emit AssetEvaluated(_evaluationId, _assetId, _asset , _evaluation);
    }

    /**
    * @dev This function is customer reject an evaluation
    * @param _assetId is id of asset
    * @param _evaluationId is id evaluation of asset
    */ 
    function rejectEvaluation(uint256 _assetId, uint256 _evaluationId) external OnlyEOA {

        // Check data
        require(_checkDataAcceptOrReject(_assetId, _evaluationId));

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];
        
        // Update status evaluation
        _evaluation.status = EvaluationStatus.EVALUATION_REJECTED;

        emit AssetEvaluated(_evaluationId,_assetId, _asset, _evaluation);
    }

    
    /**
    * @dev After an evaluation is approved, the Evaluator who submit
    * @dev evaluation data will call this function to generate an NFT token
    * @dev and transfer its ownership to Asset Creator's address.
    *
    * @param _assetId is the ID of the asset being converted to NFT token
    * @param _evaluationId is the look up index of the Evaluation data in the EvaluationsByAsset list
    * @param _nftCID is the NFT CID when mint token
    */

    function createNftToken(
        uint256 _assetId, 
        uint256 _evaluationId,  
        string memory _nftCID
    )
        external 
        OnlyEOA 
        onlyRole(EVALUATOR_ROLE) 
        nonReentrant {

        // Check nft CID
        require(bytes(_nftCID).length > 0, "NFT CID not be empty.");

        // Check asset id
        require(_assetId >=0 , "Asset does not exists.");

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Check asset CID
        require(bytes(_asset.assetDataCID).length > 0, "Asset does not exists");
        
        // Check status asset
        require(_asset.status == AssetStatus.EVALUATED, "Asset have not evaluation.");

        // Check evaluationId
        require(_evaluationId >=0 , "Evaluation does not exists.");

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];

        // Check evaluation CID
        require(bytes(_evaluation.evaluationCID).length > 0, "Evaluation does not exists");

        // Check status evaluation
        require(_evaluation.status == EvaluationStatus.EVALUATION_ACCEPTED, "Evaluation is not acceptable.");

        // Check evaluator
        require(msg.sender == _evaluation.evaluator, "Evaluator address does not match.");

        // Check balance
        require(ibepDFY.balanceOf(msg.sender) >= (_mintingNFTFee), "Your balance is not enough.");
        

        require(ibepDFY.allowance(msg.sender, address(this)) >= (_mintingNFTFee), "You have not approve DFY.");

        // Create NFT
        uint256 mintedTokenId = dfy_physical_nfts.mint(_asset.creator, msg.sender, _evaluationId, 1, _nftCID , "");

        // Tranfer minting fee to admin
        ibepDFY.transferFrom(msg.sender,addressAdmin , _mintingNFTFee);

        // Update status asset
        _asset.status = AssetStatus.NFT_CREATED;

        // Update status evaluation
        _evaluation.status = EvaluationStatus.NFT_CREATED;

        // Add token id to list asset of owner
        tokenIdByAsset[mintedTokenId] = _asset;

        // Add token id to list nft of evaluator
        tokenIdByEvaluation[mintedTokenId] = _evaluation;

    }

    /**
    * @dev Add an Evaluator to Whitelist and grant him Minter role.
    * @param _account is the address of an Evaluator
    */ 
    function addEvaluator(address _account) external onlyRole(OPERATOR_ROLE) {
        // Grant Evaluator role
        grantRole(EVALUATOR_ROLE, _account);

        // Approve
        emit ApproveEvaluator(_account);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../access/DFY-AccessControl.sol";
import "./IDFY_Physical_NFTs.sol";

contract DFY_Physical_NFTs is 
    IDFY_Physical_NFTs,
    Initializable,
    UUPSUpgradeable, 
    ERC1155Upgradeable, 
    DFYAccessControl, 
    PausableUpgradeable, 
    ERC1155BurnableUpgradeable 
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;

    // Total NFT token
    CountersUpgradeable.Counter public totalToken;
    
    // Address evaluation
    address public evaluationContract;

    // Mapping list tokenId to CID
    // TokenId => CID
    mapping(uint256 => string) public tokenIdListToCID;

    // Mapping token id to information evaluation of NFT token 
    // TokenId => NFTEvaluation
    mapping (uint256 => NFTEvaluation) public tokenIdOfEvaluation; //evaluation Of Token

    // Mapping evaluator to NFT 
    // Address evaluator => listTokenId
    mapping (address => uint256[] ) public tokenIdListByEvaluator;

    // Struct NFT Evaluation
    // struct NFTEvaluation{
    //     address evaluationContract;
    //     uint256 evaluationId;
    // }

    // Name NFT token
    string public name;

    // Symbol NFT token
    string public symbol;

    // Base URI NFT Token
    string private _tokenBaseUri;

    // Event NFT create success
    event NFTCreated(
        address assetOwner,
        uint256 tokenID,
        string cid
    );

    // Modifier check contract valuation call mint NFT token
    modifier onlyEvaluation {
        require(msg.sender == evaluationContract, 'Cant mint.');
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public initializer {
        __ERC1155_init("");
        __DFYAccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __UUPSUpgradeable_init();

        name = _name;
        symbol = _symbol;
        
        _setBaseURI(_uri);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}


    function _setBaseURI(string memory _uri) internal {
        require(bytes(_uri).length > 0, "Blank baseURI");
        _tokenBaseUri = _uri;
    }

    function _baseURI() internal view returns (string memory) {
        return _tokenBaseUri;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return bytes(tokenIdListToCID[tokenId]).length > 0;
    }

    function setBaseURI(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_uri);
    }

    function uri(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid token");

        string memory baseUri = _baseURI();
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenIdListToCID[tokenId])) : "";
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
    * @dev set address evaluation contract
    * @param _evaluationContract is address evaluation contract
    */
    function setEvaluationContract(address _evaluationContract) external onlyRole(DEFAULT_ADMIN_ROLE){
        // Check address different address(0)
        require(_evaluationContract != address(0), "Zero address.");

        // Check address is contract
        require(_evaluationContract.isContract(), "Not a contract.");

        // Set address evaluation
        evaluationContract = _evaluationContract;
    }

    /**
    * @dev evaluation contract call this function mint NFT token
    * @param _assetOwner is owner of asset mint NFT token
    * @param _evaluator is evaluator mint NFT
    * @param _evaluatontId is id evaluation NFT token
    * @param _amount is amount NFT token
    * @param _cid is cid of NFT token
    * @param _data is data of NFT token
    */
    function mint(
        address _assetOwner, 
        address _evaluator, 
        uint256 _evaluatontId, 
        uint256 _amount, 
        string memory _cid, 
        bytes memory _data
    ) 
        external
        override 
        onlyEvaluation 
        returns (uint256 tokenId)
    {
        // Gennerate tokenId
        tokenId = totalToken.current();

        // Add mapping tokenId to CID
        tokenIdListToCID[tokenId] = _cid;

        // Create NFT Evaluation and add to list
        tokenIdOfEvaluation[tokenId] = NFTEvaluation({
            evaluationContract: msg.sender,
            evaluationId: _evaluatontId
        });

        // Add tokenId to list tokenId by evaluator
        tokenIdListByEvaluator[_evaluator].push(tokenId);

        // Mint nft
        _mint(_assetOwner, tokenId, _amount, _data);

        // Update tokenId count
        totalToken.increment();

        emit NFTCreated(_assetOwner, tokenId, _cid);

        return tokenId;
    }

    /**
    * @dev get evaluation id and address of given token Id
    * @param _tokenId is the token whose evaluation data is being queried
    */
    function getEvaluationOfToken(uint256 _tokenId) 
        external 
        view
        override
        returns (address evaluationAddress, uint256 evaluationId) 
    {
        evaluationAddress   = tokenIdOfEvaluation[_tokenId].evaluationContract;
        evaluationId        = tokenIdOfEvaluation[_tokenId].evaluationId;
    }

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) 
        internal 
        override whenNotPaused 
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function updateCID (uint256 _tokenId, string memory _newCID) external onlyRole(DEFAULT_ADMIN_ROLE){
        // Check for empty CID string input
        require(bytes(_newCID).length > 0, "Empty CID");

        // Check if token exists
        require(bytes(tokenIdListToCID[_tokenId]).length > 0, "Token doesn't exist");

        // Update CID
        tokenIdListToCID[_tokenId] = _newCID;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155Burnable_init_unchained();
    }

    function __ERC1155Burnable_init_unchained() internal initializer {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./PawnModel.sol";
import "../access/DFY-AccessControl.sol";
import "../reputation/IReputation.sol";

contract PawnContractV2 is PawnModel
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint;
    using CollateralLib for Collateral;
    using OfferLib for Offer;

    mapping(address => bool) whitelistedPawnContract;

    /** ==================== Collateral related state variables ==================== */
    uint256 public numberCollaterals;
    mapping(uint256 => Collateral) public collaterals;

    /** ==================== Offer related state variables ==================== */
    uint256 public numberOffers;
    mapping(uint256 => CollateralOfferList) public collateralOffersMapping;

    /** ==================== Pawshop package related state variables ==================== */
    uint256 public numberPawnShopPackages;
    mapping(uint256 => PawnShopPackage) public pawnShopPackages;
    mapping(uint256 => CollateralAsLoanRequestListStruct) public collateralAsLoanRequestMapping; // Map from collateral to loan request
    
    /** ==================== Collateral related events ==================== */
    event CreateCollateralEvent(
        uint256 collateralId,
        Collateral data
    );

    event WithdrawCollateralEvent(
        uint256 collateralId,
        address collateralOwner
    );

    /** ==================== Offer related events ==================== */
    event CreateOfferEvent(
        uint256 offerId,
        uint256 collateralId,
        Offer data
    );

    event CancelOfferEvent(
        uint256 offerId,
        uint256 collateralId,
        address offerOwner
    );

    /** ==================== Pawshop package related events ==================== */
    event CreatePawnShopPackage(
        uint256 packageId,
        PawnShopPackage data
    );

    event ChangeStatusPawnShopPackage(
        uint256 packageId,
        PawnShopPackageStatus status         
    );


    /** ==================== Initialization ==================== */

    /**
    * @dev initialize function
    * @param _zoom is coefficient used to represent risk params
    */
    function initialize(uint32 _zoom) public initializer {
        __PawnModel_init(_zoom);
    }

    /** ==================== Collateral functions ==================== */
    
    /**
    * @dev create Collateral function, collateral will be stored in this contract
    * @param _collateralAddress is address of collateral
    * @param _packageId is id of pawn shop package
    * @param _amount is amount of token
    * @param _loanAsset is address of loan token
    * @param _expectedDurationQty is expected duration
    * @param _expectedDurationType is expected duration type
    */
    function createCollateral(
        address _collateralAddress,
        int256 _packageId,
        uint256 _amount,
        address _loanAsset,
        uint256 _expectedDurationQty,
        LoanDurationType _expectedDurationType
    ) 
        external 
        payable 
        whenNotPaused 
        returns (uint256 _idx) 
    {
        //check whitelist collateral token
        require(whitelistCollateral[_collateralAddress] == 1, '0'); //n-sup-col
        //validate: cannot use BNB as loanAsset
        require(_loanAsset != address(0), '1'); //bnb

        //id of collateral
        _idx = numberCollaterals;

        //create new collateral
        Collateral storage newCollateral = collaterals[_idx];
        
        newCollateral.create(
            _collateralAddress,
            _amount,
            _loanAsset,
            _expectedDurationQty,
            _expectedDurationType
        );

        ++numberCollaterals;

        emit CreateCollateralEvent(_idx, newCollateral);

        if (_packageId >= 0) {
            //Package must active
            PawnShopPackage storage pawnShopPackage = pawnShopPackages[uint256(_packageId)];
            require(pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, '2'); //pack

            // Submit collateral to package
            CollateralAsLoanRequestListStruct storage loanRequestListStruct = collateralAsLoanRequestMapping[_idx];

            newCollateral.submitToLoanPackage(
                uint256(_packageId),
                loanRequestListStruct
            );

            emit SubmitPawnShopPackage(
                uint256(_packageId),
                _idx,
                LoanRequestStatus.PENDING
            );
        }

        // transfer to this contract
        PawnLib.safeTransfer(
            _collateralAddress,
            msg.sender,
            address(this),
            _amount
        );

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_CREATE_COLLATERAL
        );
    }

    /**
    * @dev cancel collateral function and return back collateral
    * @param  _collateralId is id of collateral
    */
    function withdrawCollateral(uint256 _collateralId) external whenNotPaused {
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.owner == msg.sender, '0'); //owner
        require(collateral.status == CollateralStatus.OPEN, '1'); //col

        PawnLib.safeTransfer(
            collateral.collateralAddress,
            address(this),
            collateral.owner,
            collateral.amount
        );

        // Remove relation of collateral and offers
        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_collateralId];
        if (collateralOfferList.isInit == true) {
            for (uint256 i = 0; i < collateralOfferList.offerIdList.length; i++) {
                uint256 offerId = collateralOfferList.offerIdList[i];
                Offer storage offer = collateralOfferList.offerMapping[offerId];
                emit CancelOfferEvent(
                    offerId,
                    _collateralId,
                    offer.owner
                );
            }
            delete collateralOffersMapping[_collateralId];
        }

        delete collaterals[_collateralId];
        emit WithdrawCollateralEvent(_collateralId, msg.sender);

        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_CANCEL_COLLATERAL
        );
    }

    /** ==================== Offer functions ==================== */

    /**
    * @dev create Collateral function, collateral will be stored in this contract
    * @param _collateralId is id of collateral
    * @param _repaymentAsset is address of repayment token
    * @param _duration is duration of this offer
    * @param _loanDurationType is type for calculating loan duration
    * @param _repaymentCycleType is type for calculating repayment cycle
    * @param _liquidityThreshold is ratio of assets to be liquidated
    */
    function createOffer(
        uint256 _collateralId,
        address _repaymentAsset,
        uint256 _loanAmount,
        uint256 _duration,
        uint256 _interest,
        uint8 _loanDurationType,
        uint8 _repaymentCycleType,
        uint256 _liquidityThreshold
    )
        external 
        whenNotPaused 
        returns (uint256 _idx)
    {
        Collateral storage collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus.OPEN, '0'); // col
        // validate not allow for collateral owner to create offer
        require(collateral.owner != msg.sender, '1'); // owner
        // Validate ower already approve for this contract to withdraw
        require(IERC20Upgradeable(collateral.loanAsset).allowance(msg.sender, address(this)) >= _loanAmount, '2'); // not-apr

        // Get offers of collateral
        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_collateralId];
        if (!collateralOfferList.isInit) {
            collateralOfferList.isInit = true;
        }
        // Create offer id       
        _idx = numberOffers;

        // Create offer data
        Offer storage _offer = collateralOfferList.offerMapping[_idx];

        _offer.create(
            _repaymentAsset,
            _loanAmount,
            _duration,
            _interest,
            _loanDurationType,
            _repaymentCycleType,
            _liquidityThreshold
        );

        collateralOfferList.offerIdList.push(_idx);

        ++numberOffers;

        emit CreateOfferEvent(_idx, _collateralId, _offer);
        
        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CREATE_OFFER
        );
    }

    /**
    * @dev cancel offer function, used for cancel offer
    * @param  _offerId is id of offer
    * @param _collateralId is id of collateral associated with offer
    */
    function cancelOffer(uint256 _offerId, uint256 _collateralId)
        external
        whenNotPaused
    {
        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_collateralId];
        require(collateralOfferList.isInit == true, '0'); // col
        
        Offer storage offer = collateralOfferList.offerMapping[_offerId];

        offer.cancel(_offerId, collateralOfferList);

        delete collateralOfferList.offerIdList[collateralOfferList.offerIdList.length - 1];
        emit CancelOfferEvent(_offerId, _collateralId, msg.sender);
        
        // Adjust reputation score
        reputation.adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CANCEL_OFFER
        );
    }
}