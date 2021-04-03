/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Smartcon{
    uint s;
    address owner;
    constructor(uint a) public{
        s = a;
        owner = msg.sender; 
    }
    function brabara(uint c) public {
        require(msg.sender == owner);
        s += c;
    }
    function getValue() public view returns (uint){
        return s;
    }
}