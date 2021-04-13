// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

/// @title PoolTogether Generic Minimal ProxyFactory
/// @notice EIP-1167 Minimal proxy factory pattern for creating proxy contracts
contract GenericProxyFactory{
  
  ///@notice Event fired when minimal proxy has been created
  event ProxyCreated(address indexed created, address indexed implementation);

  /// @notice Create a proxy contract for given instance
  /// @param _instance Contract implementation which the created contract will point at
  /// @param _data Data which is to be called after the proxy contract is created
  function create(address _instance, bytes calldata _data) public returns (address instanceCreated, bytes memory result) {
    
    instanceCreated = ClonesUpgradeable.clone(_instance);
    emit ProxyCreated(instanceCreated, _instance);

    if(_data.length > 0) {
      return callContract(instanceCreated, _data);
    }

    return (instanceCreated, "");  
  }

  /// @notice Create a proxy contract with a deterministic address using create2
  /// @param _instance Contract implementation which the created contract will point at
  /// @param _salt Salt which is used as the create2 salt
  /// @param _data Data which is to be called after the proxy contract is created
  function create2(address _instance, bytes32 _salt, bytes calldata _data) public returns (address instanceCreated, bytes memory result) {

    instanceCreated = ClonesUpgradeable.cloneDeterministic(_instance, _salt);
    emit ProxyCreated(instanceCreated, _instance);

    if(_data.length > 0) {
      return callContract(instanceCreated, _data);
    }

    return (instanceCreated, "");
  }

  /// @notice Calculates what the proxy address would be when deterministically created
  /// @param _master Contract implementation which the created contract will point at
  /// @param _salt Salt which would be used as the create2 salt
  /// @return Deterministic address for given master code and salt using create2
  function predictDeterministicAddress(address _master, bytes32 _salt) public view returns (address) {
    return ClonesUpgradeable.predictDeterministicAddress(_master, _salt, address(this));
  }

  /// @notice Calls the instance contract with the specified data
  /// @dev Will revert if call unsuccessful 
  /// @param target Call target contract
  /// @param _data Data for contract call
  /// @return Tuple of the address called contract and the return data from the call
  function callContract(address target, bytes memory _data) internal returns (address, bytes memory) {
    (bool success, bytes memory returnData) = target.call(_data);
    require(success, string(returnData));
    return (target, returnData);
  }

}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
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