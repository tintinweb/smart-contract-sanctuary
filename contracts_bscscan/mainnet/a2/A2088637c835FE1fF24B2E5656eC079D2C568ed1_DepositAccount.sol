/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity >=0.4.22 <0.6.0;
contract DepositAccount {
address payable owner;

constructor() public {
        owner = msg.sender;
}
    
function withdraw() payable public {
    require(owner == msg.sender);
    owner.transfer(address(this).balance);
}
    
function withdraw(uint256 amount) payable public {
    require(owner == msg.sender);
    require(address(this).balance >= amount);
    
    owner.transfer(amount);
}
    
function() payable external {}
}