/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.6.0;

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenApproval {
  function approveSushiswap() external {
    address sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    IERC20(sushi).approve(sushiRouter, uint(-1));
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}