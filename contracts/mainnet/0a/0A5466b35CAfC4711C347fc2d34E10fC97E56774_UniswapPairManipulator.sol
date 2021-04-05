pragma solidity ^0.8.0;

contract UniswapPairManipulator {

    uint256 public dai = 10**18;
    uint256 public tree = 10**18;

    // Manipulate result
    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = dai;
        _reserve1 = tree;
        _blockTimestampLast = 100000;
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