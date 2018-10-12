pragma solidity ^0.4.23;

contract lockCardHash {
  address public owner;
  uint public myHash;
  mapping(uint => string[]) public cards;
  constructor() public {
    owner = msg.sender;
  }
  modifier restricted() {
    if (msg.sender == owner) _;
  }
  function addCardsHash(uint key, string card) public restricted {
      cards[key].push(card);
  }
}