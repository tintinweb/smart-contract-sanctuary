/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

/*
................................................................................
................................................................................
................................................................................
......................................./#((((#/.................................
....................................#((((((((((((#/%((((((((....................
..................................(((((%((((((((%((((((((((((*..................
.............................../%(((((((((((((#((((#(((((((#%(..................
............................*((((((((((((#%((((((((#%#%##((((#%#(/..............
...........................#((((((((((((#,,&@@@@*.    #((#%%%##(((%.............
.........................((((((((((((((((%(#*,/.    ,# #@@@@@      /............
.......................*(((((((##(((((((((((((((((#(((((((((((((##..............
......................%((((((((((#(##(((((((((((((((((((&%%%%(..................
......................#((((((((((#((&(##(((((((((((((((((((((((.................
.....................###(((((((((((%(((%%(((((%%(((((((((((((((%................
................../##%%%%#((((((((((((#&##(((((%%#((((((((((((((................
................/##%%%%%######((((((((((((((((((#%#(((((((((((*.................
...............#((##%%%(%#######%##%##((((((((((((((((((%#,.....................
..............(((######(((((/(#%%####%%%##%#%%########%%%%%%#,..................
..............#####%#################(###%#%#########%(##%###((*................
.............##(%#%#%#/%#######################(((####%/##%#%%#(#...............
............####%%#%#(#################################(##%%##%##/..............
..........(#####%%%#(#####################################%%%#%###..............
.........####%%%%#####(################################%/##%%%%####.............
........#((#####%##(###################################%/%#%%%%%###.............
.......###%%%&%%%%(%(((####(/(##(#(##########(##(((((((#/########/##............
.......%##%%&%%%%%#%####(#####%%#######%#%%#%%%########%(%%%%%%&&##%............
....../%#%&%&%%%%/%%###########%%#%%%%%#%##%%%%#######%%#%&%&%%%%##%#...........
......*(/#%%%%###,(((#(/######/#%%%%%#%%%#((#//((###%#%#&&%&%&&&&##%%...........
......,###%%%%%%%/########((##%##((###(##############(%(##%%#%#%####%...........
.......#((###%##%/#((/((/(((##(########%######((((#(((#/%#######%((##...........
.......#((########((/(((/((/(##((#########(###(((((((#(#####%%##(((##...........
......./((#%%%####(######(####################((((((/#/#########((##............
*
* COMFY RAFFLE
* Telegram: https://t.me/comfytokenandraffle
*
* ** YOU MUST HOLD COMFY TO ENTER **
*
* ** 0.003 BNB per entry **
*   * You may enter as many times as you like, more tickets = more chances to win.
*   * To enter, send your entry fee to the contract address.
*
* Main Pot Winner receives 51% of the pot
* Second Place receives 21% of the pot
* Third Place receives 11% of the pot
* Fourth Place recieves 8% of the pot
* Fifth Place recieves 6% of the pot
* Manager recevices 1.5% of the pot
* 1.5% of the pot remains to seed the next drawing
*
* Min. pot size for a drawing is 0.05 BNB
*
* Deposits can not be refunded. Participation could result in loss of funds.
*
*/
pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
abstract contract tokenInterface {
    function balanceOf(address whom) view public virtual returns (uint);
}
contract Comfy_Lottery {
  address public manager;
  address[] private players;
  mapping(address => bool) public isExempt;
  uint8 constant _decimals = 18;
  uint256 private _conversion = 1 * 1**18 * (10 ** _decimals);
  uint256 public lotteryTicketThreshold = (_conversion * 3) / 1000;
  uint256 public lotteryDrawingThreshold = (_conversion * 1) / 20;
  address lotteryToken = 0x019F241bcDCdD09a99DA4aA1D6242D18E71042C0; // TESTNET
  // address lotteryToken = ; // MAINNET
constructor() {
    manager = msg.sender;
    isExempt[manager] = true;
    isExempt[lotteryToken] = true;
    }
receive() external payable {
    address sender = msg.sender;
    uint amount = msg.value;
    if (!isExempt[sender]) {
        enterLottery(sender, amount);
        }
    }
function tokenBalance(address _addressToQuery) view public returns (uint256) {
        return tokenInterface(lotteryToken).balanceOf(_addressToQuery);
    }
function enterLottery(address sender, uint256 amount) private {
    require(amount == lotteryTicketThreshold, "Tickets cost 0.003 BNB");
    if (tokenBalance(sender) > 0) {
        players.push(sender);
    } else
        revert("ONLY COMFY HOLDERS ARE ELIGIBLE TO PLAY.");
    }
function uRandom(uint r1, uint r2, uint r3, uint r4, uint r5, uint r6) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(r1, (block.difficulty + r5), r2, (block.timestamp + r6), r3, players, r4)));
    }
function pickWinner(uint int1, uint int2, uint int3, uint int4, uint int5) external restricted() {
    //Random numbers generated @ https://www.random.org/integers/?num=100&min=1&max=1000000000&col=5&base=10&format=html&rnd=new before drawing
    require(address(this).balance >= lotteryDrawingThreshold);
    uint c1 = 9887953625327145607355235511175255940523077791474319852305732268;
    uint c2 = 4796795198004991305702297602674264155664796105547239658631890248;
    uint c3 = 7205178815346393604423058351095747575378812563026498796843154840;
    uint c4 = 2216767398157128259763980577960183751601616428475541869138824052;
    uint c5 = 5477953747518892399774509850110979894189032143393282764841975164;
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
    uint256 management = (address(this).balance * 15) / 1000; // 1.5%
    // 1.5% of the pot remains to seed the next drawing
    payable(players[firstPlace]).transfer(primary);
    payable(players[secondPlace]).transfer(secondary);
    payable(players[thirdPlace]).transfer(tertiary);
    payable(players[fourthPlace]).transfer(quaternary);
    payable(players[fifthPlace]).transfer(quinary);
    payable(manager).transfer(management);
    players = new address[](0);
    }
function clearStuckBalance() external restricted() {
        uint256 amountBNB = address(this).balance;
        payable(manager).transfer(amountBNB);
    }
modifier restricted() {
    require(msg.sender == manager);
    _;
    }
}