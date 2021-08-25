// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./lib/Governable.sol";

contract VaultRegistry is Governable {

    /// @notice List of protocol vaults. 
    address[] public vaults;

    /// @notice Names for each vault.
    mapping(address => string) public vaultName;

    /// @notice If a vault has been registered or not.
    mapping(address => bool) public isVaultRegistered;

    /// @notice Addresses allowed to update the registry.
    mapping(address => bool) public keepers;

    /// @notice Emitted on update to the registry.
    event RegistryUpdated(address indexed vault, string name);

    modifier onlyGovernanceOrKeeper {
        require(msg.sender == governance() || keepers[msg.sender], "VaultRegistry: Caller not governance or keeper");
        _;
    }

    constructor(address _store) Governable(_store) {} 

    /// @notice Adds a new vault to the registry
    /// @param _vault Vault to add.
    /// @param _name Name of the added vault.
    function addVault(
        address _vault,
        string memory _name
    ) public onlyGovernance {
        require(!isVaultRegistered[_vault], "VaultRegistry: Vault already registered");
        vaults.push(_vault);
        vaultName[_vault] = _name;
        isVaultRegistered[_vault] = true;
        emit RegistryUpdated(_vault, _name);
    }

    /// @notice Updates the name of a vault in the registry.
    /// @param _vault Vault to update the name of.
    /// @param _newName New name to give to the vault.
    function updateVaultName(
        address _vault,
        string memory _newName
    ) public onlyGovernanceOrKeeper {
        require(isVaultRegistered[_vault], "VaultRegistry: Vault is not registered");
        vaultName[_vault] = _newName;
        emit RegistryUpdated(_vault, _newName);
    }

    /// @notice Adds vaults to the registry in batches.
    /// @param _vaults Vaults to add to the registry.
    /// @param _names Names of the added vaults.
    function batchAddVaults(
        address[] memory _vaults,
        string[] memory _names
    ) public onlyGovernanceOrKeeper {
        require(_names.length == _vaults.length, "VaultRegistry: Name length does not match with vaults length");
        for(uint256 i = 0; i < _vaults.length; i++) {
            require(!isVaultRegistered[_vaults[i]], "VaultRegistry: Vault already registered");
            vaults.push(_vaults[i]);
            vaultName[_vaults[i]] = _names[i];
            emit RegistryUpdated(_vaults[i], _names[i]);
        }
    }

    /// @notice Adds a keeper to the registry.
    /// @param _keeper Address of the keeper to add.
    function addKeeper(address _keeper) public onlyGovernance {
        keepers[_keeper] = true;
    }

    /// @notice Removes a keeper from the registry.
    /// @param _keeper Address of the keeper to remove from the registry,
    function removeKeeper( address _keeper) public onlyGovernance {
        keepers[_keeper] = false;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 */

contract Governable {

  Storage public store;

  constructor(address _store) {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

{
  "optimizer": {
    "enabled": false,
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