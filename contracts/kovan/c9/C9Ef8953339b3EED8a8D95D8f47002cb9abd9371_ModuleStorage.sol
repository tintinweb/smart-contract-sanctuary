// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

/**
 * @title ModuleStorage
 * @author Pods Finance
 * @notice Stores addresses from configuration modules
 */
contract ModuleStorage {
    mapping(bytes32 => address) private _addresses;

    event ModuleSet(bytes32 indexed name, address indexed newAddress);

    /**
     * @dev Get a configuration module address
     * @param name The name of a module
     */
    function getModule(bytes32 name) public view returns (address) {
        return _addresses[name];
    }

    /**
     * @dev Set a configuration module address
     * @param name The name of a module
     * @param module The module address
     */
    function _setModule(bytes32 name, address module) internal {
        require(module != address(0), "ModuleStorage: Invalid module");
        _addresses[name] = module;
        emit ModuleSet(name, module);
    }
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