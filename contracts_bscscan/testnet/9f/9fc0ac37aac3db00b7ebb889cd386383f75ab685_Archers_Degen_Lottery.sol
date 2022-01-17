/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/*
*
* Archer's Degen Lottery
* Ticket cost 0.025 BNB per entry
*   * You main enter as many times as you like, more tickets = more chances to win
*   * To enter, send your entry fee to the contract address
*
* Telegram: https://t.me/archersdegenlottery
*
* Winner receives 95% of the pot
* Manager recevices 1% of the pot
* 4% of the pot remains to seed the next drawing
*
*/
pragma solidity ^0.8.11;
// SPDX-License-Identifier: MIT
contract Archers_Degen_Lottery {
  address public manager;
  address[] private players;
  uint8 constant _decimals = 18;
  uint256 private _conversion = 1 * 1**18 * (10 ** _decimals);
  uint256 public lotteryTicketThreshold = (_conversion * 25) / 1000;

constructor() {
    manager = msg.sender;
    }
receive() external payable {
    address sender = msg.sender;
    uint amount = msg.value;
    enterLotteryTicket(sender, amount);
    }

function enterLotteryTicket(address sender, uint256 amount) private {
    require(amount == lotteryTicketThreshold, "Tickets cost .025 BNB");
    players.push(sender);
    }

function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

function pickWinner() public restricted {
    uint index = random() % players.length;
    uint256 winnings = (address(this).balance * 95) / 100;
    uint256 management = (address(this).balance * 1) / 100;
    //4% of the pot remains to seed the next drawing
    payable(players[index]).transfer(winnings);
    payable(manager).transfer(management);
    players = new address[](0);
    }

/*function getPlayers() public view returns (address[] memory) {
    return players;
    }*/

modifier restricted() {
    require(msg.sender == manager);
    _;
    }
}