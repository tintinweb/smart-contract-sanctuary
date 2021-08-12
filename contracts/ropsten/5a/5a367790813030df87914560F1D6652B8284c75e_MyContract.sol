/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract MyContract {

   uint public myint;
   
   function setInt(uint _int) public returns(bool){
       myint = _int;
       return true;
   }
}