/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPX {
    constructor() payable{}

    enum Hand {
        rock, paper, scissors
    }

    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    struct Player {
        address payable addr;
        uint256 playerBetAmount;
        Hand hand;
        PlayerStatus playerStatus;
    }

    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Game{
        Player originator;
        Player taker;
        uint256 betAmount;
        GameStatus gameStatus;
    }

    mapping(uint => Game) rooms;
    uint roomLen = 0;

    modifier isValidHand (Hand _hand) {
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum) {
        rooms[roomLen] = Game({
            originator: Player({
                addr: payable(msg.sender),
                playerBetAmount: msg.value,
                hand: _hand,
                playerStatus: PlayerStatus.STATUS_PENDING
            }),
            taker: Player({
                addr: payable(msg.sender),
                playerBetAmount: 0,
                hand: Hand.rock,
                playerStatus: PlayerStatus.STATUS_PENDING
            }),
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED
        });

        roomNum = roomLen;
        roomLen = roomLen+1;
    }

    function joinRoom (uint _roomNum, Hand _hand) public payable isValidHand(_hand) {
        rooms[_roomNum].taker = Player({
            addr: payable(msg.sender),
            playerBetAmount: msg.value,
            hand: _hand,
            playerStatus: PlayerStatus.STATUS_PENDING
        });

        rooms[_roomNum].betAmount = rooms[_roomNum].betAmount + msg.value;
        compareHands(_roomNum);
    }

    function compareHands(uint _roomNum) private {
        uint8 originator = uint8(rooms[_roomNum].originator.hand);
        uint8 taker = uint8(rooms[_roomNum].taker.hand);

        rooms[_roomNum].gameStatus = GameStatus.STATUS_STARTED;
        if(originator == taker){    //비긴경우
            rooms[_roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[_roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }
        else if((taker+1)%3 == originator){   //방장이 이긴경우
            rooms[_roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[_roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if((originator+1)%3 == taker){  //참가자가 이긴경우
            rooms[_roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[_roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        }
        else{   //그외
            rooms[_roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }

    modifier isPlayer(uint _roomNum, address _sender){
        require(_sender == rooms[_roomNum].originator.addr || _sender == rooms[_roomNum].taker.addr);
        _;
    }

    function payout(uint _roomNum) public payable isPlayer(_roomNum, msg.sender){
        PlayerStatus originator = rooms[_roomNum].originator.playerStatus;
        PlayerStatus taker = rooms[_roomNum].taker.playerStatus;

        if(originator == PlayerStatus.STATUS_TIE && taker == PlayerStatus.STATUS_TIE){
            rooms[_roomNum].originator.addr.transfer(rooms[_roomNum].originator.playerBetAmount);
            rooms[_roomNum].taker.addr.transfer(rooms[_roomNum].taker.playerBetAmount);
        }
        else if(originator == PlayerStatus.STATUS_WIN){
            rooms[_roomNum].originator.addr.transfer(rooms[_roomNum].betAmount);
        }
        else if(taker == PlayerStatus.STATUS_WIN){
            rooms[_roomNum].taker.addr.transfer(rooms[_roomNum].betAmount);
        }
        else{
            rooms[_roomNum].originator.addr.transfer(rooms[_roomNum].originator.playerBetAmount);
            rooms[_roomNum].taker.addr.transfer(rooms[_roomNum].taker.playerBetAmount);
        }

        rooms[_roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
}