/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;

contract SecureLottery {

  event SecureLotteryWinner(
    address indexed winner
  );

  struct Game {
    address player;
    uint256 candidate;
    bool claimed;
    uint256 blocknumber;
  }

  mapping(uint256 => Game) private games;
  uint256 gameCurrentNb;

  function getCurrentRandom()
      internal
      view
      returns (uint256)
  {
      return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 10;
  }

  function play(uint256 candidate) external returns (uint256 gameId) {
    gameId = gameCurrentNb;
    games[gameId].player = address(tx.origin);
    games[gameId].candidate = candidate;
    games[gameId].claimed = false;
    games[gameId].blocknumber = block.number;
    gameCurrentNb++;
  }

  function claim(uint256 gameId) external {
    require(games[gameId].player == tx.origin, "It is not your game.");
    require(!games[gameId].claimed, "Game already claimed.");
    require(block.number > games[gameId].blocknumber, "Too fast, too furious.");

    uint256 currentRandom = getCurrentRandom();
    Game storage g = games[gameId];

    g.claimed =  true;
    if (g.candidate == currentRandom) {
      emit SecureLotteryWinner(g.player);
    }
  }
 
}