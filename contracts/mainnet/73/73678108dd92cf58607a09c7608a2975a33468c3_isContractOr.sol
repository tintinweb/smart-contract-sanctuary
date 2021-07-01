/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity ^0.5.16;

contract isContractOr {

function isContract(address _addr) public view returns (bool){
  uint32 size;
  assembly {
    size := extcodesize(_addr)
  }
  return (size > 0);
}
    
}