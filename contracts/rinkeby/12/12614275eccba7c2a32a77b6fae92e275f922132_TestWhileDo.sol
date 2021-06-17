/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract TestWhileDo {
  
  uint public blockNumber;
    bytes32 public blockHashNow;
    bytes32 public blockHashPrevious;
    uint[] public numbers;

constructor(){
    blockNumber = block.number;
    //calBlock();
}
    function setValues() public {
        blockNumber = block.number;
        blockHashNow = blockhash(blockNumber);
        blockHashPrevious = blockhash(blockNumber - 1);
    }    
  function getBlockNumber() public view returns(uint) {
      //blockNumber = block.number;
      return block.number;
  }
  
  function kiemtrasonguyento(uint number) internal pure returns(bool){
      if(number < 2) return false;
      else{
          uint i = 2;
          while(i < number - 1){
              if(number % i == 0) return false;
              i++;
          }
      }
      return true;
  }
  function calBlock() public {
      delete numbers;
      uint num = 2;
      while(num < 100000000000000000000000000000000000000){
          if(kiemtrasonguyento(num)){
              numbers.push(num);
          }
          num++;
      }
      
  }
  
  function getNumbersLength() public view returns(uint){
      return numbers.length;
  }
  
}