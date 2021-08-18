/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.5.0;

contract Ownable {
  address payable owner;
  // set the state variable ‘owner’ to the address of the creator.
  constructor() public {
    owner = msg.sender;
  }

  modifier Owned {
    require(msg.sender == owner);
    _;
  }
}

contract Mortal is Ownable {
  // allows the contract owner (access modifier) to destroy the contract and send the remaining funds back to him.
  function kill() public Owned {
    selfdestruct(owner);
  }
}

contract Casino is Mortal{
  uint minBet;
  uint houseEdge; //in %

  event Won(bool _status, uint _amount);

  // make our constructor payable so we can preload our contract with some Ether on deployment. 
  constructor(uint _minBet, uint _houseEdge) payable public {
    require(_minBet > 0);
    require(_houseEdge <= 100);
    minBet = _minBet;
    houseEdge = _houseEdge;
  }
  
  function() external { //fallback
    revert();
  }

  function bet(uint _number) payable public {
    require(_number > 0 && _number <= 10);
    require(msg.value >= minBet);
    uint winningNumber = block.number % 10 + 1;
    if (_number == winningNumber) {
      uint amountWon = msg.value * (100 - houseEdge)/10;
      if(!msg.sender.send(amountWon)) revert();
      emit Won(true, amountWon);
    } else {
      emit Won(false, 0);
    }
  }
  
  function checkContractBalance() Owned public view returns(uint) {
      return address(this).balance;
  }
}