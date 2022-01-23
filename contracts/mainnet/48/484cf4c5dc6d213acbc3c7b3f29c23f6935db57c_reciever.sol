/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
contract reciever{
address immutable owner;
address payable recieverAccount;

constructor(address  _reciever){
    owner=msg.sender;
    recieverAccount=payable(_reciever);
}
 receive() external payable {
     recieverAccount.transfer(address(this).balance);
 }

 function updateReciever(address _reciever) public {
     require(msg.sender==owner);
     recieverAccount=payable(_reciever);
 }
 
}