pragma solidity ^0.8.7;

import "./RisingToken.sol";

/**
    HypeRiser! Unique tokenomics that keep the hype building and the chart rising!   
   
    An extremely rare opportunity has landed on the BSC. Imagine you were actually 
    
    protected from large scale dumps and chart crushing sells, well, that's what we're offering! 
 
    We're also burning 4% of every transaction to keep the supply deflationary and make sure your token value is always RISING! 
 
    TG HypeRiser
    
 */
 // SPDX-License-Identifier: MIT
contract HypeRiser is RisingToken {

    string private name_ = "HypeRiser";
    string private symbol_ = "HR";
    uint8 private decimals_ = 9;
    uint256 private supply_ = 500000000 * 10**6 * 10**decimals_;

    constructor() RisingToken(name_, symbol_, decimals_, supply_) {}

}