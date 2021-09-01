pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


contract Oracle {
  //using sushiv2
    UniswapRouter UR = UniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    uint[] price;
    function getUniPrice(uint _eth_amount) public view returns(uint[] memory amount) {
        address[] memory path = new address[](2);
        path[0] = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        path[1] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

        uint256[] memory result = UR.getAmountsOut(_eth_amount, path);
        return result;
    }
    function showUniPrice() public view returns(uint[] memory amount) {
      return price;
    }

    function setPrice() public {
      price = getUniPrice(25000000000000000);
    }
}

interface UniswapRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
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