/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// alchemy.sol - alchemy api testing

pragma solidity ^0.8.0;

contract Alchemy {
  string ownerDictator;

  struct Potion {
    string name;
    string effectDescription;
    uint256 quatity;
  }

  Potion[] public potions;

  constructor(string memory _dictatorName) {
    ownerDictator = _dictatorName;
  }

  function createPotion(
    string memory name,
    string memory description,
    uint256 quatity
  ) public {
    potions.push(Potion(name, description, quatity));
  }
}