pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract Lottery{
    using SafeMath for uint256;

    address public lastWinner;
    address public owner;
    uint256 public jackpot;
    uint256 public MaxPlayers;
    uint256 public completedGames;
    address[] public players;
    
    constructor() public {
         owner = msg.sender;
         MaxPlayers = 10;
    }

    function UpdateNumPlayers (uint256 num) public {
        if (owner != msg.sender || num < 3 || num >= 1000) revert();
        MaxPlayers = num;
    }
    
     function () payable public  {
        if(msg.value < .01 ether) revert();
        players.push(msg.sender);
        jackpot += msg.value;
        if (players.length >= MaxPlayers) RandomWinner();
    }

    function getPlayers() public view returns(address[]) {
        return players;
    }
    
    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, now, msg.sender, players)));
    }

    function RandomWinner()  private {
        if (players.length < MaxPlayers) revert();
        uint256 fee = SafeMath.div(address(this).balance, 100);
        lastWinner = players[random() % players.length];
        
        lastWinner.transfer(address(this).balance - fee);
        owner.transfer(fee);
        delete players;
        jackpot = 0;
        
        completedGames++;
    }

}