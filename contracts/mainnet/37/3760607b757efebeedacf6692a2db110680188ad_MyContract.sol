pragma solidity ^0.4.11;

contract MyContract {
  string word = &quot;All men are created equal!&quot;;

  function getWord() returns (string){
    return word;
  }

}