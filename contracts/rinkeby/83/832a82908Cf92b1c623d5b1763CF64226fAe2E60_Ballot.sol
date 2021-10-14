/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
   
  uint256 public num=0;
  event readNuM(string _eventName,uint256 _num);
  
  function edit(uint256 _num) public returns (uint256){
      num = _num;
      emit readNuM('readNuM',num);
      return _num;
  }
    
}