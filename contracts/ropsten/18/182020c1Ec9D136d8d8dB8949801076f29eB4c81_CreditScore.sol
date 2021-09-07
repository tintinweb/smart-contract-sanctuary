/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract CreditScore {
     uint public currtime;
     uint public newScore;
      uint B0=2;
     uint B1=3;
      uint B2=1;
      uint B3=4;
      uint u=2;
      uint l=23;
      uint c= 4;
     uint w=1;

    mapping (address => uint) public scores;
    mapping (address => bool) public banks;
    address owner;
    event CreditScoreUpdated(address userId, uint newScore);
    event calculateScore(address personAddress, uint newScore);


    constructor() public {
        owner = msg.sender;
        banks[msg.sender] = true;
    }

//Yi=β0+ β1c,i  + β2l,i + β3wi + ui
function calScore(address personAddress) public returns(uint)
{
    
  newScore = B0 + (B1*c) + (B2*l) + (B3*w) + u;
      return(newScore);
      
}
    function updateScore(address personAddress) public {
        if (banks[msg.sender] == true) {
            scores[personAddress] = newScore;
            emit CreditScoreUpdated(personAddress, newScore);   
        }
    }

    function getScore(address personAddress) public view returns (uint) {
        return scores[personAddress];
    }
    
        function addBank(address bankAddress) public {
        if (msg.sender == owner) {
            banks[bankAddress] = true;
        }
    }

    
    function getcurrtime() public returns(uint)
  {

      currtime=block.timestamp;
      return currtime;
  }

}