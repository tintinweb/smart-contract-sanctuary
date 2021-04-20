// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

/// @title UsdOracle is a constant price oracle feed that always returns 1 USD in USDC precision.
contract UsdOracle {

    int256 constant USD_PRICE = 1 * 10 ** 8;

    /**
        @dev Returns the constant USD price.
     */
    function getLatestPrice() public pure returns (int256) {
        return USD_PRICE;
    }
}

{
  "optimizer": {
    "enabled": true,
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