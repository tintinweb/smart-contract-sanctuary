/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File contracts/Interfaces/IPriceFeed.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function setAddresses(address _firstPriceAggregatorAddress, address _secondPriceAggregatorAddress) external;
    function fetchPrice() external returns (uint);
}


// File contracts/TestContracts/PriceFeedTestnet.sol

pragma solidity 0.6.11;

/*
* PriceFeed placeholder for testnet and develofment. The price is simply set manually and saved in a state 
* variable. The contract does not connect to a live Chainlink price feed. 
*/
contract PriceFeedTestnet is IPriceFeed {
    
    uint256 private _price = 200 * 1e18;

    // --- Functions ---
    function setAddresses(address _firstPriceAggregatorAddress, address _secondPriceAggregatorAddress) external override {
        //do nothing
    }

    // View price getter for simplicity in tests
    function getPrice() external view returns (uint256) {
        return _price;
    }

    function fetchPrice() external override returns (uint256) {
        // Fire an event just like the mainnet version would.
        // This lets the subgraph rely on events to get the latest price even when developing locally.
        emit LastGoodPriceUpdated(_price);
        return _price;
    }

    // Manual external price setter.
    function setPrice(uint256 price) external returns (bool) {
        _price = price;
        return true;
    }
}