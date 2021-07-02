// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "../interfaces/IPriceProvider.sol";

contract SimplePriceProvider is IPriceProvider {
    mapping(address => uint256) public pairPrice;

    // pair - uniswap address
    // base - erc20 contract as base currency
    // return price with 18 decimals precision
    function getPairPrice(address pair, address base)
        external
        view
        override
        returns (uint256)
    {
        require(pair != base);
        return pairPrice[pair]; //price
    }

    function setPrice(address pair, uint256 _price) external {
        pairPrice[pair] = _price;
    }
}

// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPriceProvider {
    // pair - uniswap address
    // base - erc20 contract as base currency
    // return price with 18 decimals precision
    function getPairPrice(address pair, address base)
        external
        view
        returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 5000
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