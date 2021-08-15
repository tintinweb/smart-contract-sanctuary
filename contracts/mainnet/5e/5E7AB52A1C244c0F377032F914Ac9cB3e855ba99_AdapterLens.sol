// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./interfaces/IProtocolAdapter.sol";
import "./interfaces/IAdapterRegistry.sol";



contract AdapterLens {
  IAdapterRegistry internal registry = IAdapterRegistry(0x5F2945604013Ee9f80aE2eDDb384462B681859C4);

  function getSupportedProtocols(address token) external view returns (string[] memory protocolNames) {
    address[] memory adapters = registry.getAdaptersList(token);
    protocolNames = new string[](adapters.length);
    for (uint256 i; i < adapters.length; i++) {
      protocolNames[i] = IProtocolAdapter(registry.getProtocolForTokenAdapter(adapters[i])).protocol();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IAdapterRegistry {
/* ========== Events ========== */

  event ProtocolAdapterAdded(uint256 protocolId, address protocolAdapter);

  event ProtocolAdapterRemoved(uint256 protocolId);

  event TokenAdapterAdded(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenAdapterRemoved(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenSupportAdded(address underlying);

  event TokenSupportRemoved(address underlying);

  event VaultFactoryAdded(address factory);

  event VaultFactoryRemoved(address factory);

  event VaultAdded(address underlying, address vault);

  event VaultRemoved(address underlying, address vault);

/* ========== Structs ========== */

  struct TokenAdapter {
    address adapter;
    uint96 protocolId;
  }

/* ========== Storage ========== */

  function protocolsCount() external view returns (uint256);

  function protocolAdapters(uint256 id) external view returns (address protocolAdapter);

  function protocolAdapterIds(address protocolAdapter) external view returns (uint256 id);

  function vaultsByUnderlying(address underlying) external view returns (address vault);

  function approvedVaultFactories(address factory) external view returns (bool approved);

/* ========== Vault Factory Management ========== */

  function addVaultFactory(address _factory) external;

  function removeVaultFactory(address _factory) external;

/* ========== Vault Management ========== */

  function addVault(address vault) external;

  function removeVault(address vault) external;

/* ========== Protocol Adapter Management ========== */

  function addProtocolAdapter(address protocolAdapter) external returns (uint256 id);

  function removeProtocolAdapter(address protocolAdapter) external;

/* ========== Token Adapter Management ========== */

  function addTokenAdapter(address adapter) external;

  function addTokenAdapters(address[] calldata adapters) external;

  function removeTokenAdapter(address adapter) external;

/* ========== Vault Queries ========== */

  function getVaultsList() external view returns (address[] memory);

  function haveVaultFor(address underlying) external view returns (bool);

/* ========== Protocol Queries ========== */

  function getProtocolAdaptersAndIds() external view returns (address[] memory adapters, uint256[] memory ids);

  function getProtocolMetadata(uint256 id) external view returns (address protocolAdapter, string memory name);

  function getProtocolForTokenAdapter(address adapter) external view returns (address protocolAdapter);

/* ========== Supported Token Queries ========== */

  function isSupported(address underlying) external view returns (bool);

  function getSupportedTokens() external view returns (address[] memory list);

/* ========== Token Adapter Queries ========== */

  function isApprovedAdapter(address adapter) external view returns (bool);

  function getAdaptersList(address underlying) external view returns (address[] memory list);

  function getAdapterForWrapperToken(address wrapperToken) external view returns (address);

  function getAdaptersCount(address underlying) external view returns (uint256);

  function getAdaptersSortedByAPR(address underlying)
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdaptersSortedByAPRWithDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  )
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdapterWithHighestAPR(address underlying) external view returns (address adapter, uint256 apr);

  function getAdapterWithHighestAPRForDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  ) external view returns (address adapter, uint256 apr);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10;
import "./IAdapterRegistry.sol";


interface IProtocolAdapter {
  event MarketFrozen(address token);

  event MarketUnfrozen(address token);

  event AdapterFrozen(address adapter);

  event AdapterUnfrozen(address adapter);

  function registry() external view returns (IAdapterRegistry);

  function frozenAdapters(uint256 index) external view returns (address);

  function frozenTokens(uint256 index) external view returns (address);

  function totalMapped() external view returns (uint256);

  function protocol() external view returns (string memory);

  function getUnmapped() external view returns (address[] memory tokens);

  function getUnmappedUpTo(uint256 max) external view returns (address[] memory tokens);

  function map(uint256 max) external;

  function unfreezeAdapter(uint256 index) external;

  function unfreezeToken(uint256 index) external;

  function freezeAdapter(address adapter) external;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}