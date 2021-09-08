/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract PricePredictor{
    
    string dogecoinPrice = "in 72 hours, this smart contract predicts 1 dogecoin to be the price of 1 dogecoin";
    
    
    function PredictPrice() public view returns (string memory){
        
        return dogecoinPrice;
    }
}