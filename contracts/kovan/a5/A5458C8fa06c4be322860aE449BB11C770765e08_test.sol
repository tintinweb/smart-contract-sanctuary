/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.7.0;

contract test {
    
    address owner;
    
    function own() public{
        owner = msg.sender;
    }
    
}