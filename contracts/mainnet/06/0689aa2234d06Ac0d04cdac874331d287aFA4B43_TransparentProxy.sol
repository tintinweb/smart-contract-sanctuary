{{
  "language": "Solidity",
  "settings": {
    "evmVersion": "istanbul",
    "libraries": {},
    "metadata": {
      "bytecodeHash": "ipfs",
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 2000
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
  },
  "sources": {
    "solc_0.6/proxy/Proxy.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.6.0;\n\n// EIP-1967\nabstract contract Proxy {\n    // /////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////////\n\n    event ProxyImplementationUpdated(\n        address indexed previousImplementation,\n        address indexed newImplementation\n    );\n\n    // /////////////////////// CONSTRUCTOR //////////////////////////////////////////////////////////////////////\n\n    function _setImplementation(address newImplementation, bytes memory data)\n        internal\n    {\n        address previousImplementation;\n        // solhint-disable-next-line security/no-inline-assembly\n        assembly {\n            previousImplementation := sload(\n                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc\n            )\n        }\n\n        // solhint-disable-next-line security/no-inline-assembly\n        assembly {\n            sstore(\n                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,\n                newImplementation\n            )\n        }\n\n        emit ProxyImplementationUpdated(\n            previousImplementation,\n            newImplementation\n        );\n\n        if (data.length > 0) {\n            (bool success, ) = newImplementation.delegatecall(data);\n            if (!success) {\n                assembly {\n                    // This assembly ensure the revert contains the exact string data\n                    let returnDataSize := returndatasize()\n                    returndatacopy(0, 0, returnDataSize)\n                    revert(0, returnDataSize)\n                }\n            }\n        }\n    }\n\n    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////\n\n    receive() external payable {\n        _fallback();\n    }\n\n    fallback() external payable {\n        _fallback();\n    }\n\n    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////\n\n    function _fallback() internal {\n        // solhint-disable-next-line security/no-inline-assembly\n        assembly {\n            let implementationAddress := sload(\n                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc\n            )\n            calldatacopy(0x0, 0x0, calldatasize())\n            let success := delegatecall(\n                gas(),\n                implementationAddress,\n                0x0,\n                calldatasize(),\n                0,\n                0\n            )\n            let retSz := returndatasize()\n            returndatacopy(0, 0, retSz)\n            switch success\n                case 0 {\n                    revert(0, retSz)\n                }\n                default {\n                    return(0, retSz)\n                }\n        }\n    }\n}\n",
      "keccak256": "0x51edce92812a1b92067c4c640e4236ca8af0fd6df5ebf7e826905d2ef803a8b4"
    },
    "solc_0.6/proxy/TransparentProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.6.0;\n\nimport \"./Proxy.sol\";\n\ncontract TransparentProxy is Proxy {\n    // /////////////////////// CONSTRUCTOR //////////////////////////////////////////////////////////////////////\n\n    constructor(\n        address implementationAddress,\n        bytes memory data,\n        address adminAddress\n    ) public {\n        _setImplementation(implementationAddress, data);\n        _setAdmin(adminAddress);\n    }\n\n    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////\n\n    function changeImplementation(\n        address newImplementation,\n        bytes calldata data\n    ) external ifAdmin {\n        _setImplementation(newImplementation, data);\n    }\n\n    function proxyAdmin() external ifAdmin returns (address) {\n        return _admin();\n    }\n\n    // Transfer of adminship on the other hand is only visible to the admin of the Proxy\n    function changeProxyAdmin(address newAdmin) external ifAdmin {\n        uint256 disabled;\n        // solhint-disable-next-line security/no-inline-assembly\n        assembly {\n            disabled := sload(\n                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6102\n            )\n        }\n        require(disabled == 0, \"changeAdmin has been disabled\");\n\n        _setAdmin(newAdmin);\n    }\n\n    // to be used if EIP-173 needs to be implemented in the implementation contract so that change of admin can be constrained\n    // in a way that OwnershipTransfered is trigger all the time\n    function disableChangeProxyAdmin() external ifAdmin {\n        // solhint-disable-next-line security/no-inline-assembly\n        assembly {\n            sstore(\n                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6102,\n                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n            )\n        }\n    }\n\n    // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////\n\n    modifier ifAdmin() {\n        if (msg.sender == _admin()) {\n            _;\n        } else {\n            _fallback();\n        }\n    }\n\n    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////\n\n    function _admin() internal view returns (address adminAddress) {\n        // solhint-disable-next-line security/no-inline-assembly\n        assembly {\n            adminAddress := sload(\n                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103\n            )\n        }\n    }\n\n    function _setAdmin(address newAdmin) internal {\n        // solhint-disable-next-line security/no-inline-assembly\n        assembly {\n            sstore(\n                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,\n                newAdmin\n            )\n        }\n    }\n}\n",
      "keccak256": "0x013a1d0c6462957ca6cdd39835b98a83c25b39eaa16a172ad03b836fc26d825a"
    }
  }
}}