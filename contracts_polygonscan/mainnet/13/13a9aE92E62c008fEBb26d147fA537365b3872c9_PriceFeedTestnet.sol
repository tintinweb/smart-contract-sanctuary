/**
 *Submitted for verification at polygonscan.com on 2021-09-22
*/

// File: contracts/Interfaces/IPriceFeed.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice() external returns (uint);

    function lastGoodPrice() external view returns (uint);
}

// File: contracts/mock/PriceFeedTestnet.sol



/*
* PriceFeed placeholder for testnet and development. The price is simply set manually and saved in a state 
* variable. The contract does not connect to a live Chainlink price feed. 
*/
contract PriceFeedTestnet is IPriceFeed {
    
    uint256 private _price = 2000 * 1e18;

    uint public override lastGoodPrice;
    address public owner;
    string public collTokenName;
    address public priceAggregatorAddress;
    address public bandCallerAddress;


    // --- Functions ---

    constructor (string memory _collTokenName) public {
        collTokenName = _collTokenName;
        owner = msg.sender;
    }

    function setAddresses(
        address _priceAggregatorAddress,
        address _bandCallerAddress
    ) external {
        priceAggregatorAddress = _priceAggregatorAddress;
        bandCallerAddress = _bandCallerAddress;
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