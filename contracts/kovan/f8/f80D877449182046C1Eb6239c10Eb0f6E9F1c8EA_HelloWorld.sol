/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.8.0;

contract HelloWorld {
    string public hello;
    
    function setHello(string memory _hello) external {
        hello = _hello;
    }
    
    // function getHello() external view returns (string memory){
    //     return hello;
    // }
    
    
}