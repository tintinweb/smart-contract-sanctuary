/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/* 
This is direction guessing game.
Simply random choice between 0 and 1.
Player bet a direction with certain amount of size.
Play game. As a result, winners take all prizes.
Losers lose their betting size.
Play token(betable) is NRM(Norem Token)
 */

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract HolzakGame {
  uint256 public prize;

  Player[] private bettingOnHol;
  Player[] private bettingOnZak;

  uint256 public totalHolSize;
  uint256 public totalZakSize;

  struct Player {
    address player;
    uint256 size;
  }

  // Using NRM token as a game coin
  address constant private NRM_ADDRESS = 0xA8E10018A3883d903b5f8ff62F476525Ee3762D7;
  IERC20 token = IERC20(NRM_ADDRESS);

  event Betting(Player player, uint8 direction);
  event Play(uint winNumber, Player[] players);

  function bet(uint256 size, uint8 direction) public payable returns (bool) {
    size = size * 10 ** token.decimals();
    require(size > 0, "You need bet some money");
    require(direction == 0 || direction == 1, "Direction is 0 or 1");

    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= size, "Check the asset allowance");

    token.transferFrom(msg.sender, address(this), size);
    prize += size;

    Player memory player = Player(msg.sender, size);

    if (direction == 0) {
      bettingOnZak.push(player);
      totalZakSize += size;
    }
    if (direction == 1) {
      bettingOnHol.push(player);
      totalHolSize += size;
    }
    emit Betting(player, direction);
    return true;
  }

  function showBettingOnHol() public view returns (Player[] memory) {
    return bettingOnHol;
  }
  function showBettingOnZak() public view returns (Player[] memory) {
    return bettingOnZak;
  }

  function randomNumberGenerator() public view returns (uint) {
    return addmod(block.number, block.timestamp, 2);
  }

  function play() public returns (bool success) {
    uint winNumber = randomNumberGenerator();
    Player[] memory winners;
    if (winNumber == 0) {
      winners = bettingOnZak;
      for (uint i=0; i<winners.length; i++) {
        uint256 bettingSize = prize / totalZakSize;
        uint256 take = bettingSize * winners[i].size;
        address taker = winners[i].player;
        token.transfer(taker, take);
        prize -= take;
      }
      if (winNumber == 1) {
        winners = bettingOnHol;
        for (uint i=0; i<winners.length; i++) {
          uint256 bettingSize = prize / totalHolSize;
          uint256 take = bettingSize * winners[i].size;
          address taker = winners[i].player;
          token.transfer(taker, take);
          prize -= take;
        }
      }
      emit Play(winNumber, winners);
      initGame();
      return true;
    }
  }

  function initGame() internal {
    // Clear players array
    delete bettingOnHol;
    delete bettingOnZak;

    totalHolSize = 0;
    totalZakSize = 0;
  }

}