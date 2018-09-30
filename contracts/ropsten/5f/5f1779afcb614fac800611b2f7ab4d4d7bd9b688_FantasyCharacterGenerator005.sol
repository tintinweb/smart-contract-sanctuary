/*
/// @title Fantasy Character Generator - version 005
/// @author MarkCTest
/// @notice I&#39;m not sure how to test Event-Emit in Remix
/// @notice Deploy to Ropsten cost $0.14 / 0.000629 gas
*/

pragma solidity ^0.4.18;

contract FantasyCharacterGenerator005 {

// @dev     
event NewCharacter(string firstName, string secondName);

// @param Set stats to have only 2 digits (e.g. 10 to 99)
uint statDigitSize = 2;
// @param From Crypto Zombies zombiefactory.sol, not 100% clear how it works
uint statModulus = 10 ** statDigitSize;

// @dev Create a Struct that has each of the character attributes we want
  struct CharacterDetails {
      string firstName;
      string secondName;
      uint32 level;
      uint32 strength;
      uint32 health;
  }
  
// @dev Array to store each of the characters we generate
  CharacterDetails[] public characters;
  
// @dev Use keccak256 to generate a random number for the stats using names provided by the contract user / player
  function generateRandomStats(string _randString) private view returns (uint) {
      uint32 randStat = uint32(keccak256(_randString));
      return randStat % statModulus;
  }
  
// @dev 
// @notice Would be nice to concat name but seems stricky AND I think this is a cosmetic/front-end job anyway
  function _generateName(string _firstName, string _secondName) public {
    uint randStrength = generateRandomStats(_firstName);
    uint randHealth = generateRandomStats(_secondName);
    
    // @dev Testing the following two lines from kaijchang2 to see if we can show multiple characters onto the array and see them in Remix
    CharacterDetails memory character = CharacterDetails(_firstName, _secondName, 1, uint32(randStrength), uint32(randHealth));
    characters.push(character);
    
    // @notice Not sure how we &#39;see&#39; the emission of the event in Remix...
    emit NewCharacter(_firstName, _secondName);
  }
  
}