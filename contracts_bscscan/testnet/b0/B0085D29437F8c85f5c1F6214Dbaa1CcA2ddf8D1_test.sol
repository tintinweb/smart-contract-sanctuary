/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed


 
 contract test{


    function createcontract(address account) public view returns(bytes32)
    
    {
        bytes32 codehash;
      assembly { codehash := extcodehash(account) }
      return codehash;
    }


}