/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.4.25;

contract Child {

   string public a;

   event LogCreatedBy(address creator, string arg);

   constructor (string arg) public payable { 
       a = arg;
       emit LogCreatedBy(msg.sender, a);
   }
}

contract Factory {

    event LogCreatedChild(address sender, string arg, address created);

    function createChild(string arg) public payable {
        address issueContract = (new Child).value(msg.value)(arg);
        emit LogCreatedChild(msg.sender, arg, issueContract);
    }
}