//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUselessBypass.sol";
import "./ReentrantGuard.sol";

/**
 *                      _       __                                    __ ___ 
 *        __  ______  (_)___  / /__   ____  _____   __  _____  ___  / //__ \
 *      / / / / __ \/ / __ \/ //_/  / __ \/ ___/  / / / / _ \/ _ \/ __// _/
 *    / /_/ / /_/ / / / / / ,<    / /_/ / /     / /_/ /  __/  __/ /_ /_/  
 *   \__, /\____/_/_/ /_/_/|_|   \____/_/      \__, /\___/\___/\__/(_)   
 * /____/                                    /____/      
 * 
 */
contract YoinkOrYeet is ReentrancyGuard{
    
    using SafeMath for uint256;
    using Address for address;
    // useless
    address token = 0x2cd2664Ce5639e46c6a3125257361e01d0213657;
    // useless swapper    
    IUselessBypass buyer = IUselessBypass(payable(0x253B07ac48Aa0E9476cE80de61710478dF0d63a5));
    // salt
    uint256 private salt;
    // number of tables
    uint256 nTables = 11;
    // table structure
    struct Table {
        address[] yeeters;
        uint256 bet;
        uint256 deadline;
        uint256 roundTimer;
        bool startYeet;
        uint256 blockBet;
    }
    // list of tables
    mapping (uint256 => Table) tables;
    // YEETED 
    event YEETED(address yoinker, uint256 yoinkings);
    
    bool isYoinking;
    modifier yoinking(){isYoinking = true; _; isYoinking = false;}
    
    constructor() {
        // set bets
        tables[0].bet = 10**16;
        tables[1].bet = 25 * 10**15;
        tables[2].bet = 5 * 10**16;
        tables[3].bet = 10 * 10**16;
        tables[4].bet = 25 * 10**16;
        tables[5].bet = 50 * 10**16;
        tables[6].bet = 10**18;
        tables[7].bet = 25 * 10**17;
        tables[8].bet = 5 * 10**18;
        tables[9].bet = 10 * 10**18;
        tables[10].bet = 25 * 10**18;
        // set deadlines
        tables[0].deadline = 1 * 20;
        tables[1].deadline = 2 * 20;
        tables[2].deadline = 3 * 20;
        tables[3].deadline = 4 * 20;
        tables[4].deadline = 5 * 20;
        tables[5].deadline = 6 * 20;
        tables[6].deadline = 7 * 20;
        tables[7].deadline = 8 * 20;
        tables[8].deadline = 15 * 20;
        tables[9].deadline = 30 * 20;
        tables[10].deadline = 60 * 20;
    }
    
    function getTable(uint256 amount) internal view returns (bool, uint256) {
        
        for (uint i = 0; i < nTables; i++) {
            if (amount == tables[i].bet) return (true, i);
        }
        return (false, 0);
    }
    
    function closeTable(uint256 table) external {
        require(
            tables[table].startYeet && 
            tables[table].roundTimer + tables[table].deadline < block.number &&
            tables[table].blockBet + 2 < block.number, 'Not Time');
        YOINK_OR_YEET(table);
    }
    
    function YOINK_OR_YEET(uint256 table) private {
        uint256 roll = (salt*(block.timestamp**2 % block.number) + block.number) % tables[table].yeeters.length;
        uint256 bal = IERC20(token).balanceOf(address(this));
        // winner
        address _win = tables[table].yeeters[roll];
        // use useless bypass
        IERC20(token).approve(address(buyer), bal);
        buyer.uselessBypass(_win, bal);
        // false the yeet
        tables[table].startYeet = false;
        // reset YEETERS
        delete tables[table].yeeters;
        // set winner
        emit YEETED(_win, bal);
    }

    receive() external payable {
        // ensure we have matching amounts
        (bool matchesAmount, uint256 table) = getTable(msg.value);
        require(matchesAmount, 'Must Match Bet Amount Exactly');
        // buy useless with swapper
        (bool success,) = payable(address(buyer)).call{value:msg.value}("");
        require(success,'Failure on Purchase Useless');
        // push buyer to table
        tables[table].yeeters.push(msg.sender);
        tables[table].blockBet = block.number;
        
        if (tables[table].yeeters.length == 2) {
            tables[table].startYeet = true;
            tables[table].roundTimer = block.number;
            salt += block.number.div(17);
        }
    }
}