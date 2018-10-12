// @title  HeroWasCreated.sol
// @author MarkCTest

pragma solidity ^0.4.21;

contract genCharacter {
  
  event HeroWasCreated(string name, uint16 health, uint16 stamina, uint16 luck);
  
  uint16 private luck = 10;

  struct theHero {
      string name;
      uint16 health;
      uint16 stamina;
      uint16 luck;
  }
  
  mapping(address => theHero) heroDetails;
  
  function createHero (string _name, uint16 _health, uint16 _stamina) public {
      theHero memory playerCharacter = theHero ({
        name    : _name,
        health  : _health,
        stamina : _stamina,
        luck    : luck
      });
      
      heroDetails[msg.sender] = playerCharacter;
      
      // emit came in at 0.4.21
      emit HeroWasCreated(_name, _health, _stamina, luck);
      
  }
  
}