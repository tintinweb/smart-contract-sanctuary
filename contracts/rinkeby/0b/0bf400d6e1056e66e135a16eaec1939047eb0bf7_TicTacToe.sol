/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity ^0.4.11;

contract TicTacToe {
  struct Game {
    mapping (uint => uint[2][]) moves;
  }
  mapping (uint => Game) games;

  function getCurrentPlayerId(uint _gameId) private constant returns (uint) {
    return (games[_gameId].moves[0].length + games[_gameId].moves[1].length) % 2;
  }

  function makeMove(uint _gameId, uint[2] _moveCoordinates) public {
    games[_gameId].moves[getCurrentPlayerId(_gameId)].push(_moveCoordinates);
  }

  function getPlayerMoves(uint _gameId, uint _player) public constant returns (uint[2][]) {
    return games[_gameId].moves[_player];
  }
}