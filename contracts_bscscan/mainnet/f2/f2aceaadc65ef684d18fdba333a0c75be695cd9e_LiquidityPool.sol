/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

contract LiquidityPool{
    address public  manager;
    constructor() public {
        manager = msg.sender;   
   }
   function AddLiquidity() public payable{
       
   }
   function Withdraw() public payable{
       require(msg.sender==manager);
       msg.sender.transfer(address(this).balance);
   }
}