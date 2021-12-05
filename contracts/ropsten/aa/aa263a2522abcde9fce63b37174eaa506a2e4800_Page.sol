/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.10;

contract Page {
    
    string message = "a";

    function name() public view returns(string memory){
      return message;
    }

}