/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity >=0.5.0 <0.7.0;

contract joker {
address payable owner;

constructor() payable public{
owner = msg.sender;
}
function doSend(uint value) public payable{
owner.transfer(value);
}
}