/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.8.4;

contract b {
    address public owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    event Do(address caller);
    
    function doSomething() external {
        require(msg.sender == owner, '!owner');
        
        emit Do(msg.sender);
    }
}