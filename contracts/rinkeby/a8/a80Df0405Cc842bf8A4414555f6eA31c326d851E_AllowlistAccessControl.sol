// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAccessControl.sol";
import "../vaults/roles/Governable.sol";
import "./PerVaultGatekeeper.sol";

contract AllowlistAccessControl is IAccessControl, PerVaultGatekeeper {
  mapping(address => bool) public globalAccessMap;
  mapping(address => mapping(address => bool)) public vaultAccessMap;

  event GlobalAccessGranted(address indexed _user);
  event GlobalAccessRemoved(address indexed _user);
  event VaultAccessGranted(address indexed _user, address indexed _vault);
  event VaultAccessRemoved(address indexed _user, address indexed _vault);

  // solhint-disable-next-line no-empty-blocks
  constructor(address _governance) PerVaultGatekeeper(_governance) {}

  function allowGlobalAccess(address[] calldata _users) external onlyGovernance {
    _updateGlobalAccess(_users, true);
  }

  function removeGlobalAccess(address[] calldata _users) external onlyGovernance {
    _updateGlobalAccess(_users, false);
  }

  function allowVaultAccess(address[] calldata _users, address _vault) external {
    _onlyGovernanceOrGatekeeper(_vault);
    _updateAllowVaultAccess(_users, _vault, true);
  }

  function removeVaultAccess(address[] calldata _users, address _vault) external {
    _onlyGovernanceOrGatekeeper(_vault);
    _updateAllowVaultAccess(_users, _vault, false);
  }

  function _hasAccess(address _user, address _vault) internal view returns (bool) {
    require(_user != address(0), "invalid user address");
    require(_vault != address(0), "invalid vault address");
    return globalAccessMap[_user] || vaultAccessMap[_user][_vault];
  }

  function hasAccess(address _user, address _vault) external view returns (bool) {
    return _hasAccess(_user, _vault);
  }

  /// @dev updates the users global access
  function _updateGlobalAccess(address[] calldata _users, bool _permission) internal {
    for (uint256 i = 0; i < _users.length; i++) {
      require(_users[i] != address(0), "invalid address");
      /// @dev only update mappign if permissions are changed
      if (globalAccessMap[_users[i]] != _permission) {
        globalAccessMap[_users[i]] = _permission;
        if (_permission) {
          emit GlobalAccessGranted(_users[i]);
        } else {
          emit GlobalAccessRemoved(_users[i]);
        }
      }
    }
  }

  function _updateAllowVaultAccess(
    address[] calldata _users,
    address _vault,
    bool _permission
  ) internal {
    require(_vault != address(0), "invalid vault address");
    for (uint256 i = 0; i < _users.length; i++) {
      require(_users[i] != address(0), "invalid user address");
      if (vaultAccessMap[_users[i]][_vault] != _permission) {
        vaultAccessMap[_users[i]][_vault] = _permission;
        if (_permission) {
          emit VaultAccessGranted(_users[i], _vault);
        } else {
          emit VaultAccessRemoved(_users[i], _vault);
        }
      }
    }
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
pragma solidity =0.8.9;

interface IAccessControl {
  function hasAccess(address _user, address _vault) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

interface IGovernable {
  function proposeGovernance(address _pendingGovernance) external;

  function acceptGovernance() external;
}

abstract contract GovernableInternal {
  event GovenanceUpdated(address _govenance);
  event GovenanceProposed(address _pendingGovenance);

  /// @dev This contract is used as part of the Vault contract and it is upgradeable.
  ///  which means any changes to the state variables could corrupt the data. Do not modify these at all.
  /// @notice the address of the current governance
  address public governance;
  /// @notice the address of the pending governance
  address public pendingGovernance;

  /// @dev ensure msg.send is the governanace
  modifier onlyGovernance() {
    require(_getMsgSender() == governance, "governance only");
    _;
  }

  /// @dev ensure msg.send is the pendingGovernance
  modifier onlyPendingGovernance() {
    require(_getMsgSender() == pendingGovernance, "pending governance only");
    _;
  }

  /// @dev the deployer of the contract will be set as the initial governance
  // solhint-disable-next-line func-name-mixedcase
  function __Governable_init_unchained(address _governance) internal {
    require(_getMsgSender() != _governance, "invalid address");
    _updateGovernance(_governance);
  }

  ///@notice propose a new governance of the vault. Only can be called by the existing governance.
  ///@param _pendingGovernance the address of the pending governance
  function proposeGovernance(address _pendingGovernance) external onlyGovernance {
    require(_pendingGovernance != address(0), "invalid address");
    require(_pendingGovernance != governance, "already the governance");
    pendingGovernance = _pendingGovernance;
    emit GovenanceProposed(_pendingGovernance);
  }

  ///@notice accept the proposal to be the governance of the vault. Only can be called by the pending governance.
  function acceptGovernance() external onlyPendingGovernance {
    _updateGovernance(pendingGovernance);
  }

  function _updateGovernance(address _pendingGovernance) internal {
    governance = _pendingGovernance;
    emit GovenanceUpdated(governance);
  }

  /// @dev provides an internal function to allow reduce the contract size
  function _onlyGovernance() internal view {
    require(_getMsgSender() == governance, "governance only");
  }

  function _getMsgSender() internal view virtual returns (address);
}

/// @dev Add a `governance` and a `pendingGovernance` role to the contract, and implements a 2-phased nominatiom process to change the governance.
///   Also provides a modifier to allow controlling access to functions of the contract.
contract Governable is Context, GovernableInternal {
  constructor(address _governance) GovernableInternal() {
    __Governable_init_unchained(_governance);
  }

  function _getMsgSender() internal view override returns (address) {
    return _msgSender();
  }
}

/// @dev ungradeable version of the {Governable} contract. Can be used as part of an upgradeable contract.
abstract contract GovernableUpgradeable is ContextUpgradeable, GovernableInternal {
  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  // solhint-disable-next-line func-name-mixedcase
  function __Governable_init(address _governance) internal {
    __Context_init();
    __Governable_init_unchained(_governance);
  }

  // solhint-disable-next-line func-name-mixedcase
  function _getMsgSender() internal view override returns (address) {
    return _msgSender();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "../vaults/roles/Governable.sol";

contract PerVaultGatekeeper is Governable {
  event GatekeeperUpdated(address indexed _gatekeeper, address indexed _vault);

  mapping(address => address) public vaultGatekeepers;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _governance) Governable(_governance) {}

  function setVaultGatekeeper(address _vault, address _gatekeeper) external onlyGovernance {
    require(_vault != address(0) && _gatekeeper != address(0), "invalid address");
    vaultGatekeepers[_vault] = _gatekeeper;
    emit GatekeeperUpdated(_gatekeeper, _vault);
  }

  function _onlyGovernanceOrGatekeeper(address _vault) internal view {
    require(_msgSender() == governance || _msgSender() == vaultGatekeepers[_vault], "not authorised");
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