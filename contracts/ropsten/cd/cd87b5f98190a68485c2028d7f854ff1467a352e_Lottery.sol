pragma solidity ^0.4.0;
contract Lottery {

  struct Entrant {
      address user;
      uint stake;
  }
  
  Entrant[] entrants;
  uint currentEntrantCount;
  
  constructor() public {
      entrants.length = 5;
      currentEntrantCount = 0;
  }

  function enter() public payable {
      require(msg.value > 0, "msg.value required");
      
      entrants[currentEntrantCount].user = msg.sender;
      entrants[currentEntrantCount].stake = msg.value;
      
      ++currentEntrantCount;
      if (currentEntrantCount == entrants.length) {
          uint winnerIndex = random() % entrants.length;
          
          uint totalStake = 0;
          for (uint i = 0; i < entrants.length; ++i) {
              totalStake += entrants[i].stake;
          }
          
          entrants[winnerIndex].user.transfer(totalStake);
          currentEntrantCount = 0;
      }
  }
  
  function () public payable {
  }
  
  function random() private view returns(uint) {
      return uint(keccak256(abi.encodePacked(block.difficulty, now)));
  }
}