/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

pragma solidity ^0.7.4;

contract Fabrication{
    
    // Storage
    uint256 public units;
    address public owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    // Functions
    function setUnits(uint256 newUnits) public {
        require(msg.sender == owner); // in msg.sender we have address of the accunt sending the transaction
        units = newUnits;
    }
    
}