/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract NewContract2{
    uint256 obj;
    address owner;
    constructor(uint256 init) public {
       obj = init;
       owner = msg.sender;
    }
    
    function add(uint256 vol) public {
       require(msg.sender == owner);
       obj += vol;
    }
    
    function getValue() public view returns (uint256){
        return obj;
    }
    
}