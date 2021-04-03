/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract SmartContract {
    uint256 count ;
    address owner;
    constructor(uint256 init) public{
        count = init;
        owner = msg.sender;
    }
    
    function add(uint256 val) public{
        require(msg.sender == owner);
        count += val;
    }
    
    function getValue() public view returns(uint256){
        return count;
    }
}