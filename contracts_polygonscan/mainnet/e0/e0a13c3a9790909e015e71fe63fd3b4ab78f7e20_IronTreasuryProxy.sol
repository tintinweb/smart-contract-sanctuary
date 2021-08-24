pragma solidity 0.8.4;

contract IronTreasuryProxy {
    function hasPool(address _pool) external pure returns (bool) {
        return _pool == 0x09cA5d827712dD7b2570FD534305B663Ae788C17;
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