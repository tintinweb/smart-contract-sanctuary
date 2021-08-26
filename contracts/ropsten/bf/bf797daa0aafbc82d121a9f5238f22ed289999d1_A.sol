/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract A {  
    event test1(bool,bytes);
    address public temp1 = address (this);   
    uint256 public temp2 = 12;  
    bool public testOne = false;
    uint256 public testTwo = 1;
 
    function three_call(address addr) public {    
       (bool a, bytes memory b) = addr.delegatecall(abi.encodeWithSignature("tests()"));
       emit test1(a,b);
        }
}