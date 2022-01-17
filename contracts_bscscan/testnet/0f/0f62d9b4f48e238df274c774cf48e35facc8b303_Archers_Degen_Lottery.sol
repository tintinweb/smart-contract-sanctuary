/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/*
* Archer's Degen Lottery
* Ticket cost 0.025 BNB per entry
*   * You may enter as many times as you like, more tickets = more chances to win
*   * To enter, send your entry fee to the contract address
*
* Telegram: https://t.me/archersdegenlounge
*
* Winner receives 95% of the pot
* Manager recevices 1% of the pot
* 4% of the pot remains to seed the next drawing
*
* Min. pot size to do a drawing is 0.50 BNB
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
  uint256 public lotteryDrawingThreshold = (_conversion * 2) / 4;

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

function random(uint t, uint x, uint y, uint z) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(t, block.difficulty, x, block.timestamp, y, players, z)));
    }

function pickWinner(uint chaos, uint entropy, uint disorder, uint randomness) external restricted {
    require(address(this).balance >= lotteryDrawingThreshold);
    //Random numbers generated @ https://www.random.org/integers/?num=100&min=1&max=1000000000&col=5&base=10&format=html&rnd=new before drawing
    uint t = chaos;
    uint x = entropy;
    uint y = disorder;
    uint z = randomness;
    uint index = random(t, x, y, z) % players.length;
    uint256 winnings = (address(this).balance * 95) / 100;
    uint256 management = (address(this).balance * 1) / 100;
    //4% of the pot remains to seed the next drawing
    payable(players[index]).transfer(winnings);
    payable(manager).transfer(management);
    players = new address[](0);
    }

modifier restricted() {
    require(msg.sender == manager);
    _;
    }
}