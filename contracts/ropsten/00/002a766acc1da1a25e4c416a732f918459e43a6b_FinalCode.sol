/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
contract FinalCode{
  bool public isCompleted;
  uint public floor = 1;
  uint public ceil = 100;
  uint randNonce = 10;
  uint secretNum;

  constructor(){
    isCompleted = false;
    secretNum = randMod(ceil);
  }
  function randMod(uint _modulus) internal returns(uint){
    randNonce++;
    return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus + 1;
  }
  function guessNum(uint num) public payable{
    require(msg.value == 1 gwei);
    if(num == secretNum){
      floor = num;
      ceil = num;
      isCompleted = true;
    }
    else{
      if(num < secretNum){
        floor = num;
      }
      else{
        ceil = num;
      }
    }
  }
}