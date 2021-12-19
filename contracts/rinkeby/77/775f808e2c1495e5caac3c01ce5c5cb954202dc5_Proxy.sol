/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
 contract Proxy {    
     address  payable implementation = payable(0x6E93aD6E5C0a28c053e5322aBDc860071F60347c);
    uint256 version = 1;  
    string wellcomeString;  
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
         }
    
    function changeImplementation(address payable _newImplementation, uint256 _newVersion) public  {
        require(_newVersion > version, "New version must be greater then previous");
        implementation = _newImplementation;
    }
    

}