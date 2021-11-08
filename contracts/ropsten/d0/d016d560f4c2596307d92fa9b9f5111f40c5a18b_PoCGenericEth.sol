/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


contract PoCGenericEth {
    
    uint storedData;

    function setValSD(uint x) public {
        storedData = x;
    }

    function getValSD() public view returns (uint) {
        return storedData;
    }

    function testSingleValue(uint value) public pure returns (uint) {
      return value;
    }

    function testSingleAddress(address  addrSingle) public pure returns (address) {
       return addrSingle;
    }
    
    function testAddressArray(address[] memory addressesArray) public pure returns (address[] memory) {
       return addressesArray;
    }

    function testSingleAndArray(uint value, uint[] memory valuesToBeStored) public pure returns (uint) {
        return valuesToBeStored[0] - value;
    }
    
}