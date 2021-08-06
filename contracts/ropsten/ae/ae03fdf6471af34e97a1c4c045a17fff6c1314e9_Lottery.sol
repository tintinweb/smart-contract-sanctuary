/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

pragma solidity ^0.4.21;

contract Lottery {
  address public manager;
  address[] public players;

  constructor() public {
    manager = msg.sender;
  }

  function enter() public payable {
    require(msg.value > .00001 ether);

    players.push(msg.sender);
  }
  
  function addplayer(address pl) public restricted {
      players.push(pl);
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
  }

  function pickWinner() public restricted {
    uint index = random() % players.length;

    players[index].transfer(address(this).balance);

    players = new address[](0);
  }

  function getPlayers() public view returns (address[]) {
    return players;
  }

  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}