/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/*
* Archer's Degen Lottery
* Telegram: https://t.me/archersdegenlounge
*
* Tickets cost 0.01 BNB per entry
*   * You may enter as many times as you like, more tickets = more chances to win
*   * To enter, send your entry fee to the contract address
*
* Main Pot Winner receives 75% of the pot
* Second place receives 15% of the pot
* Third place receives 5% of the pot
* Manager recevices 1% of the pot
* 4% of the pot remains to seed the next drawing
*
* Min. pot size for a drawing is 0.50 BNB
*
*/
pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
contract Archers_Degen_Lottery {
  address public manager;
  address[] private players;
  uint8 constant _decimals = 18;
  uint256 private _conversion = 1 * 1**18 * (10 ** _decimals);
  uint256 public lotteryTicketThreshold = (_conversion * 10) / 1000;
  uint256 public lotteryDrawingThreshold = (_conversion * 2) / 4;

constructor() {
    manager = msg.sender;
    }
receive() external payable {
    address sender = msg.sender;
    uint amount = msg.value;
    enterLottery(sender, amount);
    }

function enterLottery(address sender, uint256 amount) private {
    require(amount == lotteryTicketThreshold, "Tickets cost 0.01 BNB");
    players.push(sender);
    }

function wRandom(uint c1, uint s, uint t, uint x, uint y, uint z) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(c1, t, block.difficulty, x, block.timestamp, y, players, z, s)));
    }
function rRandom(uint c2, uint s, uint t, uint x, uint y, uint z) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(c2, y, block.difficulty, s, block.timestamp, z, players, x, t)));
    }
function tRandom(uint c3, uint s, uint t, uint x, uint y, uint z) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(c3, s, block.difficulty, z, block.timestamp, x, players, t, y)));
    }
function pickWinner(uint chaos, uint flux, uint entropy, uint disorder, uint randomness) external restricted {
    //Random numbers generated @ https://www.random.org/integers/?num=100&min=1&max=1000000000&col=5&base=10&format=html&rnd=new before drawing
    require(address(this).balance >= lotteryDrawingThreshold);
    uint c1 = 9417516486109280390003496426289039311882436518904988223867279986;
    uint c2 = 1035215303509616133014819108821498707079547386856642619764042470;
    uint c3 = 6507915208907040637114068953100943927226694919545005588978607592;
    uint s = chaos;
    uint t = flux;
    uint x = entropy;
    uint y = disorder;
    uint z = randomness;
    uint winner = wRandom(c1, s, t, x, y, z) % players.length;
    uint secondPlace = rRandom(c2, s, t, x, y, z) % players.length;
    uint thirdPlace = tRandom(c3, s, t, x, y, z) % players.length;
    uint256 mainpot = (address(this).balance * 75) / 100;
    uint256 secondary = (address(this).balance * 15) / 100;
    uint256 tertiary = (address(this).balance * 5) / 100;
    uint256 management = (address(this).balance * 1) / 100;
    //4% of the pot remains to seed the next drawing
    payable(players[winner]).transfer(mainpot);
    payable(players[secondPlace]).transfer(secondary);
    payable(players[thirdPlace]).transfer(tertiary);
    payable(manager).transfer(management);
    players = new address[](0);
    }

modifier restricted() {
    require(msg.sender == manager);
    _;
    }
}