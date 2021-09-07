/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

pragma solidity ^0.4.19;

library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract PlayerFactory{
    
    event NewPlayerBuyed(uint playerId, string name, uint adn);
     
    uint adnDigits = 16; 
    uint adnModulus = 10 ** adnDigits;
    
    struct Player{
        string name;
        uint adn; 
        uint energy;
    }
    
    Player[] public players;
    
    mapping (uint => address) public playerToOwner; 
    mapping (address => uint) ownerPlayerCount; 
    
    function _createPlayer(string _name, uint _adn) private {
        uint id = players.push(Player(_name, _adn, 1)); 
        playerToOwner[id] = msg.sender; 
        ownerPlayerCount[msg.sender]++; 
        NewPlayerBuyed(id, _name, _adn); 
    }
    
    function _generateRandomAdn(string _str) private view returns(uint){
        uint rand = uint(keccak256(_str)); 
        return rand % adnModulus;
    }
    
    function _buyPlayer(string _name) public{
        uint randAdn = _generateRandomAdn(_name);
        _createPlayer(_name, randAdn);
    }
    
    function getPlayersByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerPlayerCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < players.length; i++) {
      if (playerToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
    
}

contract EnergyControl is PlayerFactory{
    
    using SafeMath for uint256;
    uint levelUpFee = 1 ether;
    
    uint8 energy;
    
    function _addEnergy(uint _playerId, uint _energy) external payable{
        require(msg.value == levelUpFee);
        players[_playerId].energy = players[_playerId].energy.add(_energy);
    }
    
    function _removeEnergy(uint _playerId, uint _energy) external {
        players[_playerId].energy = players[_playerId].energy.sub(_energy);
    }
}