/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * Elijah Jasso, 2021
 */
 
 contract TestValues {
     address private owner;
     uint32 private a;
     uint32 private b;
     uint32 private c;
     
     constructor() {
         owner = msg.sender;
         
        a = 123;
        b = 423;
        c = 4294967295;
     }
     
     function getA() public view returns (uint32) {
         return a;
     }
     
     function getB() public view returns (uint32) {
         return b;
     }
     
     function getC() public view returns (uint32) {
         return c;
     }
 }