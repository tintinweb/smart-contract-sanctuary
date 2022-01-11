/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract uSC{
    bytes32 public ValidationHash ;
    bytes32 public NewAddr;

    function _SetHASH() public {
        ValidationHash = bytes32(bytes20(msg.sender));
    }   
       
    function _GetHASH() public view returns(bytes32){
        return ValidationHash;
    }
  function _NewAddr(address newaddr) public {
        NewAddr = bytes32(bytes20(newaddr));
    }   

    function _Validate() public view returns(bool){
        return ValidationHash == NewAddr;
    }
}