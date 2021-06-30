// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import './MetaProxyFactory.sol';
import './IBridge.sol';

/// @notice This contract verifies execution permits and is meant to be used for L1 governance.
/// A new proxy can be created with `createProxy`, to be used for governance.
// Audit-1: ok
contract ExecutionProxy is MetaProxyFactory {
  /// @notice keeps track of already executed permits
  mapping (bytes32 => bool) public executed;

  event ProxyCreated(address indexed bridge, address indexed vault, address proxy);

  /// @notice Returns the metadata of this (MetaProxy) contract.
  /// Only relevant with contracts created via the MetaProxy.
  /// @dev This function is aimed to be invoked with- & without a call.
  function getMetadata () public pure returns (
    address bridge,
    address vault
  ) {
    assembly {
      // calldata layout:
      // [ arbitrary data... ] [ metadata... ] [ size of metadata 32 bytes ]
      bridge := calldataload(sub(calldatasize(), 96))
      vault := calldataload(sub(calldatasize(), 64))
    }
  }

  /// @notice MetaProxy construction via calldata.
  /// @param bridge is the address of the habitat rollup
  /// @param vault is the L2 vault used for governance.
  function createProxy (address bridge, address vault) external returns (address addr) {
    addr = MetaProxyFactory._metaProxyFromCalldata();
    emit ProxyCreated(bridge, vault, addr);
  }

  /// @notice Executes a set of contract calls `actions` if there is a valid
  /// permit on the rollup bridge for `proposalId` and `actions`.
  function execute (bytes32 proposalId, bytes memory actions) external {
    (address bridge, address vault) = getMetadata();

    require(executed[proposalId] == false, 'already executed');
    require(
      IBridge(bridge).executionPermit(vault, proposalId) == keccak256(actions),
      'wrong permit'
    );

    // mark it as executed
    executed[proposalId] = true;
    // execute
    assembly {
      // Note: we use `callvalue()` instead of `0`
      let ptr := add(actions, 32)
      let max := add(ptr, mload(actions))

      for { } lt(ptr, max) { } {
        let addr := mload(ptr)
        ptr := add(ptr, 32)
        let size := mload(ptr)
        ptr := add(ptr, 32)

        let success := call(gas(), addr, callvalue(), ptr, size, callvalue(), callvalue())
        if iszero(success) {
          // failed, copy the error
          returndatacopy(callvalue(), callvalue(), returndatasize())
          revert(callvalue(), returndatasize())
        }
        ptr := add(ptr, size)
      }
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

interface IBridge {
  function executionPermit (address vault, bytes32 proposalId) external view returns (bytes32);
  function deposit (address token, uint256 amountOrId, address receiver) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

/// @notice Based on EIP-3448
// Audit-1: ok
contract MetaProxyFactory {
  /// @dev Creates a child with metadata from calldata.
  /// Copies everything from calldata except the first 4 bytes.
  function _metaProxyFromCalldata () internal returns (address addr) {
    // the following assembly code (init code + contract code) constructs a metaproxy.
    assembly {
      // load free memory pointer as per solidity convention
      let start := mload(64)
      // copy
      let ptr := start
      // deploy code (11 bytes) + first part of the proxy (21 bytes)
      mstore(ptr, 0x600b380380600b3d393df3363d3d373d3d3d3d60368038038091363936013d73)
      ptr := add(ptr, 32)

      // store the address of the contract to be called
      mstore(ptr, shl(96, address()))
      // 20 bytes
      ptr := add(ptr, 20)

      // the remaining proxy code...
      mstore(ptr, 0x5af43d3d93803e603457fd5bf300000000000000000000000000000000000000)
      // ...13 bytes
      ptr := add(ptr, 13)

      // now calculdate the size and copy the metadata
      // - 4 bytes function signature
      let size := sub(calldatasize(), 4)
      // copy
      calldatacopy(ptr, 4, size)
      ptr := add(ptr, size)
      // store the size of the metadata at the end of the bytecode
      mstore(ptr, size)
      ptr := add(ptr, 32)

      // The size is deploy code + contract code + calldatasize - 4 + 32.
      addr := create(0, start, sub(ptr, start))
    }
  }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": false,
      "peephole": true,
      "yul": false
    },
    "runs": 256
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