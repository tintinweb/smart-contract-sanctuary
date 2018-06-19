pragma solidity ^0.4.6;

contract MoonBook { 
  function MoonBook() {}

  bytes[] terms;

  function put(bytes term) {
    terms.push(term);
  }

  function get(uint256 index) constant returns (bytes) {
    return terms[index];
  }
}