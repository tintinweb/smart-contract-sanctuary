/**
 *Submitted for verification at polygonscan.com on 2021-07-03
*/

pragma solidity ^0.5.7;

contract Alexa4Musicians {

  // Musician to be created on Alexa4Musicians
  struct Musician {
    string stageName;
    address owner; // Owner of the property
  }

  uint256 public musicianId;

  // mapping of propertyId to Property object
  mapping(uint256 => Musician) public musicians;

  // This event is emitted when a new property is put up for sale
  event NewMusician (
    uint256 indexed musicianId
  );

  /**
   * @dev Create new Musician in the system
   * @param name Name of the musician
   */
  function createNewMusician(string memory name) public {
    Musician memory musician = Musician(name, msg.sender /* owner */);

    // Persist `musician` object to the "permanent" storage
    musicians[musicianId] = musician;

    // emit an event to notify the clients
    emit NewMusician(musicianId++);
  }
}