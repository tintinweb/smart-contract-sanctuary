/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
 

contract Proxy {    
    address payable implementation = payable(0x7b1aC1f2D144cEf572cD95D51789a209E83C0a3A);
    uint256 version = 1; //slot 0
    string wellcomeString; // slot 1
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
         }
    
    function changeImplementation(address payable _newImplementation, uint256 _newVersion) public  {
        require(_newVersion > version, "New version must be greater then previous");
        implementation = _newImplementation;
    }
    

}