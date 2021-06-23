/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract BitBrokCoin{
    uint public max_bitbrokcoin = 1000000;
    uint public usd_to_bitbrokcoin = 1000;
    uint public total_bitbrokcoin_bought = 0;
    mapping(address=>uint)equity_bitbrokcoins;
    mapping(address=>uint)equity_usd;
    
    modifier can_buy_bitbrokcoins(uint usd_invested){
        
        require(usd_invested * usd_to_bitbrokcoin + total_bitbrokcoin_bought <= max_bitbrokcoin);
        _;
    }
    
    function equity_to_bitbrokcoin(address investor)external view returns(uint){
        
        return equity_bitbrokcoins[investor];
        
    }
    function equity_to_usd(address investor)external view returns(uint){
        
        return equity_usd[investor];
        
    }
    function buy_bitbrokcoin(address investor, uint usd_invested)external can_buy_bitbrokcoins(usd_invested){
        
        uint bitbrokcoins_bought = usd_invested * usd_to_bitbrokcoin;
        equity_bitbrokcoins[investor] += bitbrokcoins_bought;
        equity_usd[investor] = equity_bitbrokcoins[investor]/1000;
        total_bitbrokcoin_bought += bitbrokcoins_bought;
        
    }
      function sell_bitbrokcoin(address investor, uint bitbrokcoins_sold)external {
        
        equity_bitbrokcoins[investor] -= bitbrokcoins_sold;
        equity_usd[investor] = equity_bitbrokcoins[investor]/1000;
        total_bitbrokcoin_bought -= bitbrokcoins_sold;
        
    }
}