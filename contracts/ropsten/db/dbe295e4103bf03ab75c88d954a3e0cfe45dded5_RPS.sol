/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    Hand private originatorHand;
    Hand private takerHand;
    
    
    constructor () payable {}
    
    /*
    event GameCreated(address originator, uint256 originator_bet);
    event GameJoined(address originator, address taker, uint256 originator_bet, uint256 taker_bet);
    event OriginatorWin(address originator, address taker, uint256 betAmount);
    event TakerWin(address originator, address taker, uint256 betAmount);
   */
   
    enum Hand {
        rock, paper, scissors
    }
    
    enum PlayerStatus{
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }
    
    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }
    
    // player structure
    struct Player {
        address payable addr;
        PlayerStatus playerStatus;
        uint256 playerBetAmount;
    }
    
    struct Game {
        uint256 betAmount;
        GameStatus gameStatus;
        Player originator;
        Player taker;
    }
    
    
    mapping(uint => Game) rooms;
    uint roomLen = 0;
    
    modifier isValidHand (Hand _hand) {
        require((_hand  == Hand.rock) || (_hand  == Hand.paper) || (_hand == Hand.scissors));
        _;
    }
    
    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }
    
    
    function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum) {
        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({ // will change
                addr: payable(msg.sender),  
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        originatorHand = _hand;
        takerHand = Hand.rock;

        roomNum = roomLen;
        roomLen = roomLen+1;
        
       // Emit gameCreated(msg.sender, msg.value);
    }
    
    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand( _hand) {
       // Emit gameJoined(game.originator.addr, msg.sender, game.betAmount, msg.value);
        
        rooms[roomNum].taker = Player({
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        takerHand = _hand;
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        compareHands(roomNum);
    }
    
    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
         rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
    
    function compareHands(uint roomNum) private{
        uint8 originator = uint8(originatorHand);
        uint8 taker = uint8(takerHand);
        
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        
        if (taker == originator){ //draw
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
            
        }
        else if ((taker +1) % 3 == originator) { // originator wins
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if ((originator + 1)%3 == taker){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
       
    }
}