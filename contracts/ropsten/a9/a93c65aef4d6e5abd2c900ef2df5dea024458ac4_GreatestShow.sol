pragma solidity ^0.4.23;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/GreatestShow.sol

contract GreatestShow {
  
  address public owner;
  string public ringMaster;

  constructor(string _ringMaster) public {
    owner = msg.sender;
    ringMaster = _ringMaster;
  }

  uint availableSeats;

  function setAvailableSeats( uint _availableSeats ) public {
      availableSeats = _availableSeats;
  }
  
  function getAvailableSeats() view public returns(uint) {
      return availableSeats;
  }

  struct Performance {
    string name;

    uint32 actors;

    uint8 tigers;
    uint8 bears;
    uint8 elephants;

    uint16 timeInSeconds;

    bool clearTheStageFirst;
  }

  Performance[] performances;
    
  function addPerformance( 
              string _name,
              uint32 _actors,                              
              uint8 _tigers, 
              uint8 _bears,
              uint8 _elephants, 
              uint16 _timeInSeconds,
              bool _clearTheStageFirst ) public returns(uint) {

      performances.push( 
          Performance( { name: _name, actors: _actors, 
              tigers: _tigers, bears: _bears, 
              elephants: _elephants,
              timeInSeconds: _timeInSeconds,
              clearTheStageFirst: _clearTheStageFirst } 
          ) 
      );

      return performances.length;
  }
 
  function getPerformance( uint _index ) view public 
      returns (string, uint32, uint8, uint8, uint8, uint16, bool) {

      Performance storage perf = performances[_index];
      return (perf.name, perf.actors, perf.tigers, perf.bears, 
              perf.elephants, perf.timeInSeconds, perf.clearTheStageFirst); 
  }

  mapping(address => uint256) internal tickets;

  uint256 internal ethusd = 700; // peg to 700 dollars
  uint256 internal rateInCents = 2000; // 2000 cents = $20.00

  using SafeMath for uint256;

  function () payable public {     
     uint256 _wei = msg.value; // 1 Ether = 1000000000000000000
     uint256 tickets4ETH = _wei.mul(ethusd).mul(100).div(rateInCents);
     tickets[msg.sender] = tickets[msg.sender].add( tickets4ETH );     
  }
      
}