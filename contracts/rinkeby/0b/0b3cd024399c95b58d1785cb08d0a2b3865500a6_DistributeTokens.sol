/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity ^0.4.24;

contract DistributeTokens {
    address public owner; 
    address[] public investors; 
    uint[] public investorTokens; 

    constructor() public {
        owner = msg.sender;
    }

    function invest() public payable {
        investors.push(msg.sender);  
        investorTokens.push(msg.value / 10); 
    }

    function distribute() public {
        require(msg.sender == owner); 
        
        
        for(uint i = 0; i < investors.length; i++) { 
            investors[i].transfer(investorTokens[i]);
        }
    }
}