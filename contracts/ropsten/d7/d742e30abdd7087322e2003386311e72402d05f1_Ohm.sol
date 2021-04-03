/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Ohm{

    uint256 number;
    address owner;
    
    constructor(uint256 init)public{
        number = init;
        owner = msg.sender;
    }
    
    function add(uint256 num) public{
        number += num;
    }
    
    function getValue() public view returns(uint256){
        require(msg.sender == owner);
        return number;
    }
}