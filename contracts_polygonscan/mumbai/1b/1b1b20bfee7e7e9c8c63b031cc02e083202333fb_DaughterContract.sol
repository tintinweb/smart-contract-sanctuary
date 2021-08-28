/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

pragma solidity ^0.6.0;
contract DaughterContract {
 string public name;
 uint public age;
 constructor(
  string memory _daughtersName,
  uint _daughtersAge
 )
  public
 {
  name = _daughtersName;
  age = _daughtersAge;
 }
}