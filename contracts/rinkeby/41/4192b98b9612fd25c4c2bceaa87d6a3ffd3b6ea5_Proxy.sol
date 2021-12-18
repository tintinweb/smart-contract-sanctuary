/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
 

contract Proxy {    
    address payable implementation = payable(0x7deB3583Dc0F61C17FB0d306073e60A1Dd7839A0);
    uint256 version = 1; //slot 2
    
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
         }
    
    function changeImplementation(address payable _newImplementation, uint256 _newVersion) public  {
        require(_newVersion > version, "New version must be greater then previous");
        implementation = _newImplementation;
    }
    

}