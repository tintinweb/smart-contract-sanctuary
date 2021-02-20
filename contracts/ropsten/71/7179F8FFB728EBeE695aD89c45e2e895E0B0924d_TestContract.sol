/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

contract TestContract {
  uint256 public num;

  function setNum(uint256 _n) external{
  	num = _n;  	
  }
  
  function getNun() external view returns(uint256){
  	return num;
  }
  
}