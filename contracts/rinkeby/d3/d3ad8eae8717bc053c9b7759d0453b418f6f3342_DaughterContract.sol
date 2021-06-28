/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity ^0.5.0;

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

 function getFlavor()
    public
    view
    returns (string memory flavor)
  {
    return name;
  } 


}