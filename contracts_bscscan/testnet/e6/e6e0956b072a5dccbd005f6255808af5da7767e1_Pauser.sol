//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IPausableByPauser} from "../interfaces/IPausableByPauser.sol";
import {IPauser} from "../interfaces/IPauser.sol";

/**
 * @title Pauser Contract
 * @notice Pauses and unpauses all vaults, vault configs, strategies and rewards
 * in case of emergency.
 * Note: Owner is a multi-sig wallet.
 */
contract Pauser is IPauser, OwnableUpgradeable {
    mapping(address => bool) public isRegistered;

    // vaults
    address[] public vaults;
    // vault configs
    address[] public vaultConfigs;
    // strategies
    address[] public strategies;
    // rewards
    address[] public rewards;
    // deposit unwinder
    address[] public depositUnwinders;

    function initialize() external initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function pauseAll() external override onlyOwner {
        for (uint256 i; i < vaults.length; i++) {
            try IPausableByPauser(vaults[i]).pause() {} catch {
                continue;
            }
        }
        for (uint256 i; i < vaultConfigs.length; i++) {
            try IPausableByPauser(vaultConfigs[i]).pause() {} catch {
                continue;
            }
        }
        for (uint256 i; i < strategies.length; i++) {
            try IPausableByPauser(strategies[i]).pause() {} catch {
                continue;
            }
        }
        for (uint256 i; i < rewards.length; i++) {
            try IPausableByPauser(rewards[i]).pause() {} catch {
                continue;
            }
        }
        emit PausedAll(_msgSender());
    }

    function unpauseAll() external override onlyOwner {
        for (uint256 i; i < vaults.length; i++) {
            try IPausableByPauser(vaults[i]).unpause() {} catch {
                continue;
            }
        }
        for (uint256 i; i < vaultConfigs.length; i++) {
            try IPausableByPauser(vaultConfigs[i]).unpause() {} catch {
                continue;
            }
        }
        for (uint256 i; i < strategies.length; i++) {
            try IPausableByPauser(strategies[i]).unpause() {} catch {
                continue;
            }
        }
        for (uint256 i; i < rewards.length; i++) {
            try IPausableByPauser(rewards[i]).unpause() {} catch {
                continue;
            }
        }
        emit UnpausedAll(_msgSender());
    }

    function getVaults() external view override returns (address[] memory) {
        return vaults;
    }

    function getVaultConfigs() external view override returns (address[] memory) {
        return vaultConfigs;
    }

    function getStrategies() external view override returns (address[] memory) {
        return strategies;
    }

    function getRewards() external view override returns (address[] memory) {
        return rewards;
    }

    function pushVault(address addr) external override onlyOwner notZeroAddress(addr) {
        if (isRegistered[addr]) return;
        vaults.push(addr);
        isRegistered[addr] = true;
    }

    function pushVaultConfig(address addr) external override onlyOwner notZeroAddress(addr) {
        if (isRegistered[addr]) return;
        vaultConfigs.push(addr);
        isRegistered[addr] = true;
    }

    function pushStrategy(address addr) external override onlyOwner notZeroAddress(addr) {
        if (isRegistered[addr]) return;
        strategies.push(addr);
        isRegistered[addr] = true;
    }

    function pushRewards(address addr) external override onlyOwner notZeroAddress(addr) {
        if (isRegistered[addr]) return;
        rewards.push(addr);
        isRegistered[addr] = true;
    }

    function removeVault(address addr) external override onlyOwner notZeroAddress(addr) {
        if (!isRegistered[addr]) return;
        for (uint256 i; i < vaults.length; i++) {
            if (addr == vaults[i]) {
                vaults[i] = vaults[vaults.length - 1];
                vaults.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function removeVaultConfig(address addr) external override onlyOwner notZeroAddress(addr) {
        if (!isRegistered[addr]) return;
        for (uint256 i; i < vaultConfigs.length; i++) {
            if (addr == vaultConfigs[i]) {
                vaultConfigs[i] = vaultConfigs[vaultConfigs.length - 1];
                vaultConfigs.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function removeStrategy(address addr) external override onlyOwner notZeroAddress(addr) {
        if (!isRegistered[addr]) return;
        for (uint256 i; i < strategies.length; i++) {
            if (addr == strategies[i]) {
                strategies[i] = strategies[strategies.length - 1];
                strategies.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function removeReward(address addr) external override onlyOwner notZeroAddress(addr) {
        if (!isRegistered[addr]) return;
        for (uint256 i; i < rewards.length; i++) {
            if (addr == rewards[i]) {
                rewards[i] = rewards[rewards.length - 1];
                rewards.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function getDepositUnwinders() external view override returns (address[] memory) {
        return depositUnwinders;
    }

    function pushDepositUnwinder(address addr) external override onlyOwner notZeroAddress(addr) {
        if (isRegistered[addr]) return;
        depositUnwinders.push(addr);
        isRegistered[addr] = true;
    }

    function removeDepositUnwinder(address addr) external override onlyOwner notZeroAddress(addr) {
        if (!isRegistered[addr]) return;
        for (uint256 i; i < depositUnwinders.length; i++) {
            if (addr == depositUnwinders[i]) {
                depositUnwinders[i] = depositUnwinders[depositUnwinders.length - 1];
                depositUnwinders.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    modifier notZeroAddress(address addr) {
        require(addr != address(0), "contract address is 0");
        _;
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPausableByPauser {
    /**
     * @notice pause the contract
     * Note: only callable by PAUSER_ROLE
     */
    function pause() external;

    /**
     * @notice unpause the contract
     * Note: only callable by PAUSER_ROLE
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Pauser Interface
 * @notice Pauses and unpauses all vaults, vault configs, strategies and rewards
 * in case of emergency.
 * Note: Owner is a multi-sig wallet.
 */
interface IPauser {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event PausedAll(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event UnpausedAll(address account);

    function pauseAll() external;

    function unpauseAll() external;

    function getVaults() external view returns (address[] memory);

    function getVaultConfigs() external view returns (address[] memory);

    function getStrategies() external view returns (address[] memory);

    function getRewards() external view returns (address[] memory);

    function pushVault(address addr) external;

    function pushVaultConfig(address addr) external;

    function pushStrategy(address addr) external;

    function pushRewards(address addr) external;

    function removeVault(address addr) external;

    function removeVaultConfig(address addr) external;

    function removeStrategy(address addr) external;

    function removeReward(address addr) external;

    function getDepositUnwinders() external view returns (address[] memory);

    function pushDepositUnwinder(address addr) external;

    function removeDepositUnwinder(address addr) external;
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