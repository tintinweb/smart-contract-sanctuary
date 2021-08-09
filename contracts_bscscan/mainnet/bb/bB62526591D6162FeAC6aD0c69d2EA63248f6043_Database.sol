/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
* initialize significant data, and update for future use
*/
contract Database{
    // addresse state variables
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
 
    address public bcl_addr = 0x12f46F0E5040a21e9ce022Ae0E6201F0A4cb017d;
    address public base = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  //  wBNB, decimals = 18 , BNB decimal = 8
    address public USDT = 0x55d398326f99059fF775485246999027B3197955;   // USDT token
    address public SYNC = 0x0E8BEC319761DA84A95E3BECf6518c7e48bdac0e;
    
    address public platform = 0xa7ab1687BF7A6eF2E8D489948D6e0ae8CE50a77e;
    address public taibao = 0xB5C7C2a37C3f301247F29e0047ea1341D5eF6dD5;
    address public node = 0x5A4d28C7736892fDC4C79a3f6f971Ea1867601E6;
    address public sub_node =0x0df8fF0CB58FAd477E2ffe98E51E5d4fA7a9eDbe;

    address public owner;
    address public newOwner;
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner");
        _;
    }
    
    function transferOwnership(address newOwner_) public onlyOwner{
        newOwner = newOwner_;
    }
    
    function claimOwnership() public {
        require(msg.sender == newOwner,"new owner only");
        owner = newOwner;
        newOwner = address(0);
    }
    
    
    function setSwapAddr(address router_, 
                         address factory_) public onlyOwner{
        router = router_;
        factory = factory_;
        
    }
    
    function setTokens(address bcl_addr_, 
                       address sync_, 
                       address base_, 
                       address USDT_) public onlyOwner{
        bcl_addr = bcl_addr_;
        SYNC = sync_;
        base = base_;
        USDT = USDT_;
                           
    }
                       
    function setFundAddr(address platform_,
                         address taibao_,
                         address node_,
                         address sub_node_) public onlyOwner{
        platform = platform_;
        taibao = taibao_;
        node = node_;
        sub_node = sub_node_;
        
    }
    
    
}