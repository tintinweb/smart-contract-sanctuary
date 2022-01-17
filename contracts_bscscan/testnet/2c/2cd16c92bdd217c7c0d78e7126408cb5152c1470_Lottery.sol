/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/*
*/
pragma solidity ^0.8.11;
// SPDX-License-Identifier: MIT
contract Lottery {
  address public manager;
  address[] public players;
  uint8 constant _decimals = 18;
  uint256 private _conversion = 1 * 1**18 * (10 ** _decimals);
  uint256 public lotteryTicketThreshold = (_conversion * 25) / 1000;

  constructor() {
    manager = msg.sender;
  }
receive() external payable {}

function enterLotteryTicket(uint256 amount) public {
    if (amount >= lotteryTicketThreshold) {
            players.push(msg.sender);
        }
    }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  }

  function pickWinner() public restricted {
    uint index = random() % players.length;
    uint256 winnings = (address(this).balance * 95) / 100;
    uint256 management = address(this).balance - winnings;
    payable(players[index]).transfer(winnings);
    payable(manager).transfer(management);
    players = new address[](0);
  }

  function getPlayers() public view returns (address[] memory) {
    return players;
  }

  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}