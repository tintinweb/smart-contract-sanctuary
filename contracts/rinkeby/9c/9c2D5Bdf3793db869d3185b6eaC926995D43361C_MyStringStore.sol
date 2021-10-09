/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

pragma solidity ^0.5.0;
contract MyStringStore {

   string public myString = "Hola UTNFRBA";

   function set(string memory x) public {
      myString = x;
   }
}