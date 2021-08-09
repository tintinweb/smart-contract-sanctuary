/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract sendbackhalf
{
       fallback() external payable {}
       
       function withdraw (address payable tosent) public
       {
           tosent.send(100000);
       }
}