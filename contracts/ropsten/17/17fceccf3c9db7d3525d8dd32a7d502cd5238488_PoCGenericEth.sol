/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract PoCGenericEth {
    
    address singleAddr;
    address[] multipleAddr;
    
    uint singleUint;
    uint[] primaryArray;
    uint16[] secondaryArray;
    

    function setSingle(uint value) public {
      singleUint = value;
    }
    
    function getSingle() public view returns (uint) {
      return singleUint;
    }
    
    function setAddress(address addrSingle) public {
       singleAddr = addrSingle;
    }
    
    
    function setAddressArray(address[] memory addressesArray) public {
       multipleAddr = addressesArray;
    }
    
    function getAddressArray() public view returns (address[] memory) {
        return multipleAddr;
    }
    
    function setArrayAndSingle(uint[] memory valuesToBeStored, uint value) public {
      primaryArray = valuesToBeStored;
      singleUint = value;
    }
    
    function setSingleAndArray(uint value, uint[] calldata valuesToBeStored) public {
      primaryArray = valuesToBeStored;
      singleUint = value;
    }
    
    function getArrayPrimary() public view returns (uint[] memory) {
      return primaryArray;
    }
    
    function getArraySecondary() public view returns (uint16[] memory) {
      return secondaryArray;
    }

}