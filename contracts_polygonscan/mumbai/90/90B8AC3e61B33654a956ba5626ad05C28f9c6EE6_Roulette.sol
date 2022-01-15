/**
 *Submitted for verification at polygonscan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;


/// @title Bank 0.0.1
/// @author awphi (https://github.com/awphi)
/// @notice Bank from GlassCasino - L3 BSc ComSci Project @ Durham University
/// @dev -
// 
contract Bank {
    address public house;
    mapping(address => uint) public funds;
    mapping (address => bool) public games;

    constructor() {
        house = msg.sender;
    }

    modifier onlyHouse {
        require(msg.sender == house);
        _;
    }

    modifier onlyGames {
        require(games[msg.sender]);
        _;
    }

    // ---- FOR HOUSE ----
    function registerGame(address game) public onlyHouse {
        games[game] = true;
    }

    function unregisterGame(address game) public onlyHouse {
        games[game] = false;
    }

    // ---- FOR USERS ----
    receive() external payable {
        funds[msg.sender] += msg.value;
    }

    function withdrawFunds(uint amount) public {
        require(funds[msg.sender] >= amount);
        require(address(this).balance >= amount);

        funds[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // ---- FOR GAMES (CONTRACTS) ----
    // Compiler (0.8+) takes care of under/overflows
    function addFunds(address player, uint amount) public onlyGames {
        funds[player] += amount;
    }

    function removeFunds(address player, uint amount) public onlyGames {
        funds[player] -= amount;
    }
}

/// @title Roulette 0.2.0
/// @author awphi (https://github.com/awphi)
/// @notice Roulette game from GlassCasino - L3 BSc ComSci Project @ Durham University
/// @dev -
// 
contract Roulette {
  enum BetType {
    COLOUR,
    ODDEVEN,
    STRAIGHTUP
    /*
    HIGHLOW, 
    COLUMN, 
    DOZENS, 
    SPLIT, 
    STREET, 
    CORNER, 
    LINE, 
    FIVE, 
    BASKET, 
    SNAKE 
    */
  }

  struct Bet {
    address player;
    BetType bet_type;
    uint bet;
    uint bet_amount;
    uint timestamp;
  }

  // Used so dApp can listen to emitted event to update UIs as soon as the outcome is rolled
  event OutcomeDecided(uint roll);
  event BetPlaced(Bet bet);

  address public house;
  Bank public bank;
  Bet[] bets;

  // Sets the house on minting of the contract, i.e. who controls the flow of the game
  constructor(Bank _bank) {
    house = msg.sender;
    bank = _bank;
  }

  modifier onlyHouse {
    require(msg.sender == house);
    _;
  }

  modifier hasMinimumValue(uint value) {
    require(msg.value >= value);
    _;
  }

  function get_bets() public view returns (Bet[] memory) {
    return bets;
  }

  function get_bets_length() public view returns (uint) {
    return bets.length;
  }

  function placeBet(BetType bet_type, uint bet, uint bet_amount) public {
    require(bank.funds(msg.sender) >= bet_amount);
    bank.removeFunds(msg.sender, bet_amount);

    Bet memory b = Bet(msg.sender, bet_type, bet, bet_amount, block.timestamp);
    bets.push(b);
    
    emit BetPlaced(b);
  }

  // Note: Replace with chainlink
  function random(uint mod) public view returns (uint) {
    return
      uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % mod;
  }

  function is_red(uint roll) public pure returns (bool) {
    if (roll < 11 || (roll > 18 && roll < 29)) {
      // Red odd, black even
      return roll % 2 == 1;
    } else {
      return roll % 2 == 0;
    }
  }

  function get_winnings(Bet memory bet, uint roll) public pure returns (uint) {
    // House edge
    if (roll == 0) {
      return 0;
    }

    if (bet.bet_type == BetType.COLOUR) {
      // 0 = red, 1 = black
      if (bet.bet == (is_red(roll) ? 0 : 1)) {
        return bet.bet_amount * 2;
      }
    } else if (bet.bet_type == BetType.ODDEVEN) {
      // 0 = even, 1 = odd
      if (bet.bet == (roll % 2)) {
        return bet.bet_amount * 2;
      }
    } else if (bet.bet_type == BetType.STRAIGHTUP) {
      if (bet.bet == roll) {
        return bet.bet_amount * 35;
      }
    }

    return 0;
  }


  function play() public onlyHouse {
    uint roll = random(37);
    emit OutcomeDecided(roll);

    for (uint i = 0; i < bets.length; i++) {
      uint w = get_winnings(bets[i], roll);

      if (w > 0) {
        bank.addFunds(bets[i].player, w);
      }
    }
  }
}