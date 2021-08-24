// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../Interfaces/IPriceFeed.sol";

/*
 * PriceFeed placeholder for testnet and development. The price is simply set manually and saved in a state
 * variable. The contract does not connect to a live Chainlink price feed.
 */
contract PriceFeedTestnet is IPriceFeed {
    uint256 private _price = 200 * 1e18;

    // --- Functions ---

    // View price getter for simplicity in tests
    function getPrice() external view returns (uint256) {
        return _price;
    }

    function fetchPrice() external override returns (uint256) {
        return _price;
    }

    // Manual external price setter.
    function setPrice(uint256 price) external returns (bool) {
        _price = price;
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    // --- Function ---
    function fetchPrice() external returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100
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