pragma solidity ^0.8.6;


contract TestRouter {
    address public immutable WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    constructor(){}

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts){
        amounts = new uint[](path.length);

        amounts[path.length-1] = amountIn;
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