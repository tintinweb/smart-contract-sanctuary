/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

/*
* The Comfy Place Lottery
* Telegram: https://t.me/thecomfyplace
*
* 0.003 BNB per entry
*   * You may enter as many times as you like, more tickets = more chances to win.
*   * To enter, send your entry fee to the contract address.
*
* Main Pot Winner receives 51% of the pot
* Second Place receives 21% of the pot
* Third Place receives 11% of the pot
* Fourth Place recieves 8% of the pot
* Fifth Place recieves 6% of the pot
* Manager recevices 0.8% of the pot
* 2.2% of the pot remains to seed the next drawing
*
* Min. pot size for a drawing is 0.05 BNB
*
* Deposits can not be refunded. The only way to remove the BNB in the contract is with a drawing.
*
* Yes, it is possible (however unlikely) for one address to win it all.
*
*/
pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
contract Comfy_Lottery {
  address public manager;
  address[] private players;
  uint8 constant _decimals = 18;
  uint256 private _conversion = 1 * 1**18 * (10 ** _decimals);
  uint256 public lotteryTicketThreshold = (_conversion * 3) / 1000;
  uint256 public lotteryDrawingThreshold = (_conversion * 1) / 20;

constructor() {
    manager = msg.sender;
    }
receive() external payable {
    address sender = msg.sender;
    uint amount = msg.value;
    enterLottery(sender, amount);
    }

function enterLottery(address sender, uint256 amount) private {
    require(amount == lotteryTicketThreshold, "Tickets cost 0.003 BNB");
    players.push(sender);
    }

function uRandom(uint r1, uint r2, uint r3, uint r4, uint r5, uint r6) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(r1, (block.difficulty + r5), r2, (block.timestamp + r6), r3, players, r4)));
    }
function pickWinner(uint int1, uint int2, uint int3, uint int4, uint int5) external restricted {
    //Random numbers generated @ https://www.random.org/integers/?num=100&min=1&max=1000000000&col=5&base=10&format=html&rnd=new before drawing
    require(address(this).balance >= lotteryDrawingThreshold);
    uint c1 = 9635359276758564373636277628658048485560646880578514462425440239;
    uint c2 = 7661469080169249235643996203715535746686914566153027535078650456;
    uint c3 = 5326250783062808799855841211854322535141653540993328141807918378;
    uint c4 = 3971065551983868307494490791389887576409020460731844360611034950;
    uint c5 = 6925254825160690701711414165062447840829032091557454881415593950;
    uint a = int1;
    uint b = int2;
    uint c = int3;
    uint d = int4;
    uint e = int5;
    uint firstPlace = uRandom(c, a, c1, b, d, e) % players.length;
    uint secondPlace = uRandom(a, e, b, c2, d, c) % players.length;
    uint thirdPlace = uRandom(d, c3, c, a, b, e) % players.length;
    uint fourthPlace = uRandom(b, d, c4, c, e, a) % players.length;
    uint fifthPlace = uRandom(c5, a, c, e, b, d) % players.length;
    uint256 primary = (address(this).balance * 51) / 100; // 51%
    uint256 secondary = (address(this).balance * 21) / 100; // 21%
    uint256 tertiary = (address(this).balance * 11) / 100; // 11%
    uint256 quaternary = (address(this).balance * 8) / 100; // 8%
    uint256 quinary = (address(this).balance * 6) / 100; // 6%
    uint256 management = (address(this).balance * 1) / 125; // 0.8%
    // 2.2% of the pot remains to seed the next drawing
    payable(players[firstPlace]).transfer(primary);
    payable(players[secondPlace]).transfer(secondary);
    payable(players[thirdPlace]).transfer(tertiary);
    payable(players[fourthPlace]).transfer(quaternary);
    payable(players[fifthPlace]).transfer(quinary);
    payable(manager).transfer(management);
    players = new address[](0);
    }

modifier restricted() {
    require(msg.sender == manager);
    _;
    }
}