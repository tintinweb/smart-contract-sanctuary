// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

contract ProxyConstructorArg {
    function getEncodedArg(address _proxyAdmin)
        public
        pure
        returns (bytes memory)
    {
        bytes memory payload = abi.encodeWithSignature(
            "initialize(address)",
            _proxyAdmin
        );
        return payload;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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