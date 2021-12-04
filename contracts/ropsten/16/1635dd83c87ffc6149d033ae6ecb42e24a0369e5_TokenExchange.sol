/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract TokenExchange {
    // Hashmap of all tokens to their prices
    mapping(address => uint256) public tokenPrices;

    // Retrieves the current price of the baseToken
    function getBaseTokenPrice(address baseTokenAddress) public view returns (uint256)
    {
        return tokenPrices[baseTokenAddress];
    }
    
    //This is a helper function to help the user see what the cost to exercise an option is currently before they do so
    //Updates lastestCost member of option which is publicly viewable
    function setBaseTokenPrice(address baseTokenAddress, uint256 baseTokenPrice) public {
        tokenPrices[baseTokenAddress] = baseTokenPrice;
    }
}