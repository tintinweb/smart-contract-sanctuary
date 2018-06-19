pragma solidity ^0.4.11;

contract PonziScheme {
  uint public round;
  address public lastDepositor;
  uint public lastDepositorAmount;
  uint public startingAmount;
  uint public nextAmount;

  function PonziScheme(uint _startingAmount) {
    round = 1;
    startingAmount = _startingAmount;
    nextAmount = _startingAmount;
  }

  function() payable {
    if(round == 1) {
      if(msg.value != startingAmount) {
        throw;
      }
    } else {
      checkAmount(msg.value);

      lastDepositor.send(msg.value);
    }

    lastDepositorAmount = msg.value;
    lastDepositor = msg.sender;
    nextAmount = msg.value * 2;

    increaseRound();
  }

  function checkAmount(uint amount) private {
    if(amount != lastDepositorAmount * 2) {
      throw;
    }
  }

  function increaseRound() private {
    round = round + 1;
  }
}