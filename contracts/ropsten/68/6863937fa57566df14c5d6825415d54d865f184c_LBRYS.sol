/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// lbrys-COIN ICO 

pragma solidity ^0.4.11; 


contract LBRYS{
    
    
    //INTRODUCING TOTAL lbrys COINS FOR SALE 
    uint public max_lbrys = 7110;
    
    // INTRODUCING USD TO lbrys CONVERSION RATE 
    uint public usd_to_lbrys = 1970; 
    
    //INTRODUCING TOTAL NUMBER OF lbrys COINS BOUGHT BY INVESTORS
    uint public total_lbrys_bought = 0; 
    
    //MAPPING IS STORED IN AN ARRAY 
    mapping(address => uint) equity_lbrys; 
    mapping(address => uint) equity_usd; 
    
    //CHECK IF INVESTORS CAN BUY lbrys
    modifier can_buy_lbrys(uint usd_invested){
        require (usd_invested * usd_to_lbrys + total_lbrys_bought<=max_lbrys);
        _;
    }
    //GETTING EQUITY IN lbrys AS INVESTOR 
    function equity_in_lbrys(address investor) external constant returns(uint){
        return equity_lbrys[investor];
    }
    
    //GETTING EQUITY IN USD AS INVESTOR 
    function equity_in_USD(address investor) external constant returns(uint){
        return equity_usd[investor];
    }
    
    //buying LAFRANCCOINS 
    function buy_lbrys(address investor, uint usd_invested) external 
    can_buy_lbrys(usd_invested){
        uint lbrys_bought= usd_invested * usd_to_lbrys;
        equity_lbrys[investor] += lbrys_bought; 
        equity_usd[investor] = equity_lbrys[investor]/ 1099; 
        total_lbrys_bought += lbrys_bought;
    }
    //SELLING lbrys
    function sell_lbrys(address investor, uint lbrys_sold) external{
        equity_lbrys[investor] -= lbrys_sold; 
        equity_usd[investor] = equity_lbrys[investor]/ 1099; 
        total_lbrys_bought -= lbrys_sold;
    }
}