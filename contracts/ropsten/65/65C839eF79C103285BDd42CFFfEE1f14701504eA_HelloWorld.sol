/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity >=0.4.25 <0.6.0;
 
contract HelloWorld {
  string word;
 
  constructor(string memory _word) public {
      word = _word;
  }
 
  function getWord() public view returns(string memory) {
      return word;
  }
  
  function changeWord(string memory _word) public {
      word = _word;
  }
 
}