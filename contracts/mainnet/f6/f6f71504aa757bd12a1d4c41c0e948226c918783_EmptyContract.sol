contract EmptyContract {
    fallback() external {
        revert();
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 99999
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