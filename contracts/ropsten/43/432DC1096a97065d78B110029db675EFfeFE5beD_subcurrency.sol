/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract subcurrency{
address owner;
mapping (address=>uint) public balances;
event sent(address from ,address to, uint amount);
constructor() {
    owner=msg.sender;
}
function mint(address receiver, uint amount)public{
    require(owner==msg.sender);
    balances[receiver]+=amount;
}
function send(address receiver, uint amount)public{
require(amount<balances[msg.sender]);
balances[msg.sender]-=amount;
balances[receiver]+=amount;
emit sent(msg.sender,receiver,amount);
}


}