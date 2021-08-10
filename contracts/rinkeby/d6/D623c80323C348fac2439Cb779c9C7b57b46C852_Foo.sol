contract Foo {
  uint nonce = 1353211;
}

{
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "libraries": {}
}