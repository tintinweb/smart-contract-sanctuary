/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Proxy {

    address public owner;
    address payable public implementation;
    uint256 public version;
    
    uint256 public test1;
    uint256 public test2;
    uint256 public result;
    
    constructor(address payable _implementation) {
        owner = msg.sender;
        implementation = _implementation;
        version = 1;
    }

    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
    }
    
    function changeImplementation(address payable _newImplementation, uint256 _newVersion) public {
        require(_newVersion > version, "New version must be greater then previous");
        implementation = _newImplementation;
    }    
}