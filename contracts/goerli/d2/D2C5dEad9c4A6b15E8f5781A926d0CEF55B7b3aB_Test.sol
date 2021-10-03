/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract Test{
    uint16 a;
    address payable owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    function setA(uint16 x) public payable{
        require(msg.value >= 1e15);
        owner.transfer(msg.value);
        a = x;
    }
    
    function getA() public view returns(uint16){
        return a;
    }
    
}