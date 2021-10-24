/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

///SPDX-License-Identifier: SPDX-License

pragma solidity 0.7.4;



contract CurrencyExchange{
    
    uint256 public virtualCoins = 100;  // balance for coins
    uint256 public valueUSD = 20; // how mutch is a USD
    address owner; // creat owner
    
    constructor(){
        owner = msg.sender; // set owner
    }
    
    
    modifier onlyOwner(){
        require(msg.sender == owner,"ERROR: You no owner."); // only "owner" can set "new value" for "valueUSD"
        _;
    }
    
    
    modifier ifZero(){
        require(valueUSD != 0, "ERROR: Balance of USD |0|."); // when "valueUSD" <= 0;
        require(virtualCoins != 0, "ERROR: Balance of coins |0|."); // when "virtualCoins" <= 0;
        _;  
    }
    
    
    
    function setValueUSD(uint256 _valueUSD) public onlyOwner{
        valueUSD = _valueUSD; // new value
    }
    
    
    function setVirtualCoins(uint256 _virtualCoins) public {
        virtualCoins = _virtualCoins;  // new value
    }
    
    
}


contract ExchangeOnUSD is CurrencyExchange{
    
    
    function getDollars() public view ifZero returns(uint256){
        return virtualCoins / valueUSD; // the formula for USD and shows coins  in " Dollars "
    }
    
}