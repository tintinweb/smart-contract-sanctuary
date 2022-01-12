/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

/// @title Roulette 0.1.1
/// @author awphi (https://github.com/awphi)
/// @notice Roulette game from GlassCasino - L3 BSc ComSci Project @ Durham University
/// @dev -

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Roulette {
  // TODO redo history with mappings

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
    address payable player;
    BetType bet_type;
    uint256 bet;
    uint256 bet_amount;
  }

  // Used so dApp can listen to emitted event to update UIs as soon as the outcome is rolled
  event OutcomeDecided(uint256 roll);
  event BetPlaced(Bet bet);

  address house;
  bool ready = true;
  Bet[] bets;

  // Sets the house on minting of the contract, i.e. who controls the flow of the game
  constructor() {
    house = msg.sender;
  }

  function get_bets() public view returns (Bet[] memory) {
    return bets;
  }

  function get_bets_length() public view returns (uint256) {
    return bets.length;
  }

  function deposit(BetType bet_type, uint256 bet) public payable {
    require(ready);
    require(msg.value > 0);
    Bet memory b = Bet(payable(msg.sender), bet_type, bet, msg.value);
    bets.push(b);
    emit BetPlaced(b);
  }

  // Note: Replace with chainlink
  function random(uint256 mod) public view returns (uint256) {
    return
      uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) %
      mod;
  }

  function is_red(uint256 roll) public pure returns (bool) {
    if (roll < 11 || (roll > 18 && roll < 29)) {
      // Red odd, black even
      return roll % 2 == 1;
    } else {
      return roll % 2 == 0;
    }
  }

  function get_winnings(Bet memory bet, uint256 roll)
    public
    pure
    returns (uint256)
  {
    // House edge, contract keeps the money
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

  function play() public {
    require(msg.sender == house);
    require(ready);

    ready = false;

    uint256 roll = random(37);
    //add_history(roll);
    emit OutcomeDecided(roll);

    for (uint256 i = 0; i < bets.length; i++) {
      uint256 w = get_winnings(bets[i], roll);

      if (w > 0) {
        bets[i].player.transfer(w);
      }
    }

    delete bets;
    ready = true;
  }
}