/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Bet {
    uint256 public prize;
    uint256 private _amount;
    Player[] private betOnHol;
    Player[] private betOnZak;
    
    uint256 public totalHolSize;
    uint256 public totalZakSize;
    
    uint256 public totalSupply = 1000;
    mapping(address => uint256) private _balances;
    
    struct Player {
        address player;
        uint256 size;
    }

    // struct Game {
    //   Player players;
    //   uint256 size;
    // }

    /* Providing Event !! */
    // Send Functions
    event Betting(Player player, uint8 direction);
    event Mint(uint256 amount);
    event Play(uint winNumber, Player[] winners); // Winner function
    
    constructor() {
        _balances[msg.sender] = totalSupply;
    }
    
    function bet(uint256 size, uint8 direction) public {
        _amount += size;
        _balances[msg.sender] -= size;
        prize += size;
        
        Player memory player = Player(msg.sender, size);
        
        // @direction: Bet on hol(1) or zak(0) 
        if (direction == 1) {
            betOnHol.push(player);
            totalHolSize += size;
        } 
        if (direction == 0) {
            betOnZak.push(player);
            totalZakSize += size;
        }
        emit Betting(player, direction);
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function showBetOnHol() public view returns (Player[] memory) {
        return betOnHol;
    }
    
    function showBetOnZak() public view returns (Player[] memory) {
        return betOnZak;
    }
    
    function play() public view returns (uint) {
        uint dice = roll();
        return dice;
    }
    
    function roll() internal view returns (uint) {
        return ( (_amount + 1) * block.number) % 2;
    }
    
    function winner() public payable {
        uint winNumber = play();
        Player[] memory winners;
        if (winNumber == 0) {
            winners = betOnZak;
            for (uint i=0; i<winners.length; i++) {
                uint256 betSize = prize / totalZakSize;
                uint256 take = betSize * winners[i].size;
                address taker = winners[i].player;
                _balances[taker] += take;
                prize -= take;
            }
        }
        if (winNumber == 1) {
            winners = betOnHol;
            for (uint i=0; i<winners.length; i++) {
                uint256 betSize = prize / totalHolSize;
                uint256 take = betSize * winners[i].size;
                address taker = winners[i].player;
                _balances[taker] += take;
                prize -= take;
            }
        }
        emit Play(winNumber, winners);
        initGame();
    }
    
    function initGame() internal {
        // Clear players array
        delete betOnHol;
        delete betOnZak;
        
        // Clear bet sizes 
        totalHolSize = 0;
        totalZakSize = 0;
    }
    
    function mint(uint256 amount) public returns (bool) {
        _balances[msg.sender] += amount;
        totalSupply -= amount;
        emit Mint(amount);
        return true;
    }
}