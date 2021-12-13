/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
  constructor() payable {}

  enum Hand {
    rock,
    paper,
    scissors
  }

  enum PlayerStatus {
    STATUS_WIN,
    STATUS_LOSE,
    STATUS_TIE,
    STATUS_PENDING
  }

  enum GameStatus {
    STATUS_NOT_STRTED,
    STATUS_STARTED,
    STATUS_COMPLETE,
    STATUS_ERROR
  }

  struct Player {
    address payable addr; 
    uint256 playerBetAmount; 
    bytes32 hand;
    PlayerStatus playerStatus;
    uint result;
    uint count;
  }

  struct Game {
    Player originator; 
    Player taker; 
    uint256 betAmount; 
    GameStatus gameStatus; 
  }

  mapping(uint256 => Game) rooms; 
  uint256 roomLen = 0; 

  function keccak(uint256 _hand, string memory _key) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_hand, _key));
  }

  function createRoom(bytes32 _hand) public payable returns (uint256 roomNum) {
    rooms[roomLen] = Game({
      betAmount: msg.value,
      gameStatus: GameStatus.STATUS_NOT_STRTED,
      originator: Player({
        hand: _hand,
        addr: payable(msg.sender),
        playerStatus: PlayerStatus.STATUS_PENDING,
        playerBetAmount: msg.value,
        result : 0,
        count : 0
      }),
      taker: Player({
        hand: 0,
        addr: payable(msg.sender),
        playerStatus: PlayerStatus.STATUS_PENDING,
        playerBetAmount: 0,
        result : 0,
        count : 0

      })
    });
    roomNum = roomLen;
    roomLen = roomLen + 1;
  }

  function joinRoom(uint256 roomNum, bytes32 _hand) public payable {
    require(msg.value == rooms[roomNum].betAmount);
    rooms[roomNum].taker = Player({
      hand: _hand,
      addr: payable(msg.sender),
      playerStatus: PlayerStatus.STATUS_PENDING,
      playerBetAmount: msg.value,
      result : 0,
      count : 0
      
    });
    rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
  }


  function useOriginator(uint256  _roomNum, uint256 _hand, string memory _secretKey) public {
    require(msg.sender == rooms[_roomNum].originator.addr);
    require(rooms[_roomNum].originator.hand == keccak(_hand,_secretKey));
    rooms[_roomNum].originator.result = _hand;
    rooms[_roomNum].originator.count = 1;
  }

    function useTaker(uint256  _roomNum, uint256 _hand, string memory _secretKey) public {
    require(msg.sender == rooms[_roomNum].taker.addr);
    require(rooms[_roomNum].taker.hand == keccak(_hand,_secretKey));
    rooms[_roomNum].taker.result = _hand;
    rooms[_roomNum].taker.count = 1;
  }


  function compareHands(uint256 roomNum) private {
    require(rooms[roomNum].taker.count==1 && rooms[roomNum].originator.count ==1);
    uint8 originator = uint8(rooms[roomNum].originator.result);
    uint8 taker = uint8(rooms[roomNum].taker.result);

    rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

    if (taker == originator) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
    } else if ((taker + 1) % 3 == originator) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
    } else if ((originator + 1) % 3 == taker) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
    } else {
      rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
    }
  }

  modifier isPlayer(uint256 roomNum, address sender) {
    require(
      sender == rooms[roomNum].originator.addr ||
        sender == rooms[roomNum].taker.addr
    );
    _;
  }

  function payout(uint256 roomNum) public payable isPlayer(roomNum, msg.sender) {
    compareHands(roomNum);
    if (
      rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE &&
      rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE
    ) {
      rooms[roomNum].originator.addr.transfer(
        rooms[roomNum].originator.playerBetAmount
      );
      rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
    } else {
      if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
      } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
      } else {
        rooms[roomNum].originator.addr.transfer(
          rooms[roomNum].originator.playerBetAmount
        );
        rooms[roomNum].taker.addr.transfer(
          rooms[roomNum].taker.playerBetAmount
        );
    }
    rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE; 
  }
}
}