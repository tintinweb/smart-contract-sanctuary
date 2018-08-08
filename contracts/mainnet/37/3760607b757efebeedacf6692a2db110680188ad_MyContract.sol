pragma solidity ^0.4.11;

contract MyContract {
  string word = "All men are created equal!";

  function getWord() returns (string){
    return word;
  }

}