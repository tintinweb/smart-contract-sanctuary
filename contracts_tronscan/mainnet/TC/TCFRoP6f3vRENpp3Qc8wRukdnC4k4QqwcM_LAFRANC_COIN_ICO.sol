//SourceUnit: lafranccoin_ico.sol

// LAFRANC-COIN ICO 

pragma solidity ^0.4.11; 


contract LAFRANC_COIN_ICO{
    
    
    //INTRODUCING TOTAL LAFRANC COINS FOR SALE 
    uint public max_lafranccoins = 19700905;
    
    // INTRODUCING USD TO LAFRANC CONVERSION RATE 
    uint public usd_to_lafranccoins = 1970; 
    
    //INTRODUCING TOTAL NUMBER OF LAFRANC COINS BOUGHT BY INVESTORS
    uint public total_lafranccoins_bought = 0; 
    
    //MAPPING IS STORED IN AN ARRAY 
    mapping(address => uint) equity_lafranccoins; 
    mapping(address => uint) equity_usd; 
    
    //CHECK IF INVESTORS CAN BUY LAFRANCCOINS 
    modifier can_buy_lafranccoins(uint usd_invested){
        require (usd_invested * usd_to_lafranccoins + total_lafranccoins_bought<=max_lafranccoins);
        _;
    }
    //GETTING EQUITY IN LAFRANCCOINS AS INVESTOR 
    function equity_in_lafranccoins(address investor) external constant returns(uint){
        return equity_lafranccoins[investor];
    }
    
    //GETTING EQUITY IN USD AS INVESTOR 
    function equity_in_USD(address investor) external constant returns(uint){
        return equity_usd[investor];
    }
    
    //buying LAFRANCCOINS 
    function buy_lafranccoins(address investor, uint usd_invested) external 
    can_buy_lafranccoins(usd_invested){
        uint lafranccoins_bought= usd_invested * usd_to_lafranccoins;
        equity_lafranccoins[investor] += lafranccoins_bought; 
        equity_usd[investor] = equity_lafranccoins[investor]/ 1099; 
        total_lafranccoins_bought += lafranccoins_bought;
    }
    //SELLING LAFRANCCOINS
    function sell_lafranccoins(address investor, uint lafranccoins_sold) external{
        equity_lafranccoins[investor] -= lafranccoins_sold; 
        equity_usd[investor] = equity_lafranccoins[investor]/ 1099; 
        total_lafranccoins_bought -= lafranccoins_sold;
    }
}