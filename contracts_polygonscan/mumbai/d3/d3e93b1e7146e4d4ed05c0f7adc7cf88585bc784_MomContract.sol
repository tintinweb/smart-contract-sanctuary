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

pragma solidity ^0.6.0;
contract MomContract {
 string public name;
 uint public age;
 DaughterContract public daughter;
 constructor(
  string memory _momsName,
  uint _momsAge,
  string memory _daughtersName,
  uint _daughtersAge
 )
  public
 {
  daughter = new DaughterContract(_daughtersName, _daughtersAge);
  name = _momsName;
  age = _momsAge;
 }
}