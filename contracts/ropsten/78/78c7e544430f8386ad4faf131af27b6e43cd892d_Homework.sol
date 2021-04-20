/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity >=0.7.0 <0.8.0;contract Homework {
    
    mapping(address => string) public submitters;
    
    function store(string memory BSON340116) public {
        submitters[msg.sender] = BSON340116;
    }
    
}