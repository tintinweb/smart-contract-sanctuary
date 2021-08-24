/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity ^0.8.0;

//"SPDX-License-Identifier: UNLICENSED"

//PIAIC PIAIC79180 Name Abdul Basit Abbasi

//Assignment 3B

contract assignment3B {
    
    mapping(address => uint) balances;
    
    string public Name;
    string public Symbol;
    uint public initialSuppply;
    uint public totalSuppply;
    address owner;
    uint decimal = 2;
    uint price = 1*10**16;
    uint cap;
    uint time = 5 minutes;
    uint releaseTime = block.timestamp * time;
    
    
    constructor() {
        
        Name = "My First Token";
        Symbol = "MFT";
        owner = msg.sender;
        cap = 2000000*10**decimal;
        
        initialSuppply = 1000000 * 10**decimal;
        totalSuppply = initialSuppply;
        
        balances[owner] = totalSuppply;

    }

    
    function buyToken() public payable {
        
        uint amount = msg.value;
        uint tokenQty = amount/price;
        address buyer = msg.sender;
        
        require(owner != buyer,"Owner can not be buyer");
        require(msg.value >= 1, "Value should be more than 1");
        require(block.timestamp > releaseTime, "please wait until time to transfer starts");
        
        balances[buyer] = balances[buyer] + tokenQty *1e2 ;
        balances[owner] = balances[owner] - tokenQty *1e2 ;
        
    }
    
    //price will be adjusted at the moment price is 100 tokens per ether so price = 1/100 then (result*1e18 to convert in wei)
    function setPrice(uint newPrice) external {
        
        require(msg.sender == owner, "only owner can set price");
        price = newPrice;
    }
    
    function mintToken(uint _NoOfToken) external {
        
        uint NoOfToken = _NoOfToken*1e2; //there are two decimals in tokken so multiplying it with 1e2
        require(totalSuppply + NoOfToken <= cap, "Token Quantity can not be more than Capped amount");
        require(msg.sender == owner, "Only owner can mint tokken");// tokken will be released after 5 minutes of block creation
        
        totalSuppply += NoOfToken;
        balances[owner] = totalSuppply;
        
    }
    
    function tokenBalance(address a) public view returns(uint) {
        return balances[a];
    }
    
    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }
}