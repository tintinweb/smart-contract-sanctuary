/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

///SPDX-License-Identifier: SPDX-License

pragma solidity 0.7.4;



contract CurrencyExchange{
    
    uint virtualCoins = 20000;  // creat a account of coins
    
    uint valueUSD = 20; // How mutch is a USD
    uint valueUER = 25; // How mutch is a EUR
    uint valueUAN = 30; // How mutch is a UAN
    
    function VirtualCoinsSet(uint _virtualCoins) public {
        virtualCoins = _virtualCoins;  // set user value
    }
    
    
    function Balance() public view returns(uint){
        return virtualCoins;
    }
}




contract ExchangeOnUAN is CurrencyExchange{
    
    uint scoreUAN = virtualCoins / valueUAN; // formula for UAN
    
    
    function Hryvnia() public view returns(uint){
        return scoreUAN; // is show coins  in " Hryvnia "
    }
    
}