/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract sendbackhalf
{
       fallback() external payable {}
       address payable owner;
       constructor()
       {
           owner=payable(msg.sender);
       }
       function withdraw () public
       {
           owner.send(address(this).balance);
       }
}