/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract B {
    address public contratoNuevo;
    address public contractB ;
    
    constructor(){
        contractB = address(this);
    }
    
    function setContract() public {
        contratoNuevo = msg.sender;
    }
}

contract A {
    
    address public contractA ;
    
    constructor(){
        contractA = address(this);
    }

    function setContract(address b) public returns (bool, bytes memory) {        
          (bool success, bytes memory data) = b.delegatecall(
            abi.encodeWithSignature("setContract()"));
        return (success, data);
    }
    
    
    function setSender(address a) public returns(bool, bytes memory) {
        (bool success, bytes memory data) = a.delegatecall(
            abi.encodeWithSignature("setSender()")
        );
        return (success, data);
    }
    

}