/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

///SPDX-License-Identifier: SPDX-License

pragma solidity 0.7.4;



contract CurrencyExchange{
    
    uint256 virtualCoins = 100;  // creat a account of coins
    uint256 valueUSD = 20; // How mutch is a USD
    address owner = msg.sender; // set owner
    
    modifier onlyOwner(){
        require(msg.sender == owner,"At you not rights do this "); // only "owner" can set "new value" for one "dollar"
        _;
    }
    
    
    function setValueUSD(uint256 _valueUSD) public onlyOwner{
        valueUSD = _valueUSD; // set user value
    }
    
    
    function setVirtualCoins(uint256 _virtualCoins) public {
        virtualCoins = _virtualCoins;  // set user value
    }
    
    
    function getValueUSD() public view returns(uint256){
        return valueUSD; // returns coins for one USD
    }
    
    
    function getBalance() public view returns(uint256){
        return virtualCoins; // returns coins 
    }
}



contract ExchangeOnUSD is CurrencyExchange{
    
    
    function getDollars() public view returns(uint256){
        return virtualCoins / valueUSD; // formula for USD and is show  coins  in " Dollars "
    }
    
}