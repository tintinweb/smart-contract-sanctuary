pragma solidity ^0.8.0;

contract UniswapOracleManipulator {

  uint256 public price = 105 * 10**16;  // $1.05

  constructor() public {}

  function update() external pure returns (bool success) {
    return true;
  }

  function consult(address token, uint256 amountIn)
    external
    view
    returns (uint256 amountOut)
  {
    amountOut = price;
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