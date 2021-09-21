/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

pragma solidity ^0.5.5;

contract MyEvetTest {

   event MyEvent(uint256 timestamp);

   function myFunction() public {
       emit MyEvent(block.timestamp);
   }
}