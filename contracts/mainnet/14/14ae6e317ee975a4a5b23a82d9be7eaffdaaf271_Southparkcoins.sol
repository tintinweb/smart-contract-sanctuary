/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// Southparkcoins ICO

// Version of compiler
pragma solidity ^0.4.11;

// SPDX-License-Identifier: unlicensed

contract Southparkcoins {
    
    // Introducing the maximum number of Southparkcoins available for sale 
    uint public max_southparkcoins = 9000000000000;
    
    // Introducing the USD to Southparkcoins conversion rate 
    uint public usd_to_southparkcoins = 1;
    
    // Introducing the total number of Southparkcoins that have been bought by the investors
    uint public total_southparkcoins_bought = 0;
    
    //Mapping from the investor address to its equity in Southparkcoins and usd_to_southparkcoins
    mapping(address => uint) equity_southparkcoins;
    mapping(address => uint) equity_usd;
    
    // Checking if an investor can buy Southparkcoins
    modifier can_buy_southparkcoins(uint usd_invested) {
        require (usd_invested * usd_to_southparkcoins + total_southparkcoins_bought <= max_southparkcoins);
        _;
    }
    
    // Getting the equity in southparkcoins of an investor
    function equity_in_southparkcoins(address investor) external constant returns (uint) {
            return equity_southparkcoins[investor];
    }
    
    // Getting the equity_in_southparkcoins in USD of an investor
    function equity_in_usd(address investor) external constant returns (uint) {
            return equity_usd[investor];
    }
    
    // Buying southparkcoins
    function buy_southparkcoins(address investor, uint usd_invested) external
    can_buy_southparkcoins(usd_invested) {
        uint southparkcoins_bought = usd_invested * usd_to_southparkcoins;
        equity_southparkcoins[investor] += southparkcoins_bought;
        equity_usd[investor] = equity_southparkcoins[investor] / 1 ;
        total_southparkcoins_bought += southparkcoins_bought;
    }
    
    // Selling Southparkcoins
    function sell_southparkcoins(address investor, uint southparkcoins_sold) external {
        equity_southparkcoins[investor] -= southparkcoins_sold;
        equity_usd[investor] = equity_southparkcoins[investor] / 1;
        total_southparkcoins_bought -= southparkcoins_sold;
    }
}