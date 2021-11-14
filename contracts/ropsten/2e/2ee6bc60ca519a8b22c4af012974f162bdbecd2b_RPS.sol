/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    
    // player status
    /*
    uint constant STATUS_WIN = 1;
    uint constant STATUS_LOSE = 2;
    uint constant STATUS_TIE = 3;
    uint constant STATUS_PENDING = 4;
    
    
    // game status
    uint constant STATUS_NOT_STARTED = 1;
    uint constant STATUS_STARTED = 2;
    uint constant STATUS_COMPLETE = 3;
    uin constant STATUS_ERROR = 4;
    */
    
    constructor () payable {}
    
    event gameCreated(address originator, uint256 originator_bet);
    event gameJoined(address originator, address taker, uint256 originator_bet, uint256 taker_bet);
    event originatorWin(address originator, address taker, uint256 betAmount);
    event takerWin(address originator, address taker, uint256 betAmount);
   
    enum Hand {
        none, rock, paper, scissors
    }
    
    enum PlayerStatus{
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }
    
    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }
    
    // player structure
    struct Player {
        Hand hand;
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
    
    Game game;
    
    modifier isValidHand (Hand _hand) {
        require(_hand != Hand.none);
        _;
    }
    
    modifier isPlayer (address sender) {
        require(sender == game.originator.addr || sender == game.taker.addr);
        _;
    }
    
    modifier isGameComplete {
        require(game.gameStatus == GameStatus.STATUS_COMPLETE);
        _;
    }
    
    function createRPS (Hand _hand) public payable isValidHand(_hand) {
        game = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({ // will change
                hand: Hand.none,
                addr: payable(msg.sender),  
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        emit gameCreated(msg.sender, msg.value);
    }
    
    function joinRPS(Hand _hand) public payable isValidHand(_hand) {
        emit gameJoined(game.originator.addr, msg.sender, game.betAmount, msg.value);

        game.taker = Player({
            hand: _hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        game.betAmount = game.betAmount + msg.value;
        compareHands();
    }
    
    function payout() public payable isPlayer(msg.sender) isGameComplete{
        if (game.originator.playerStatus == PlayerStatus.STATUS_TIE && game.taker.playerStatus == PlayerStatus.STATUS_TIE) {
            game.originator.addr.transfer(game.originator.playerBetAmount);
            game.taker.addr.transfer(game.taker.playerBetAmount);
        } else {
            if (game.originator.playerStatus == PlayerStatus.STATUS_WIN) {
                game.originator.addr.transfer(game.betAmount);
            } else if (game.taker.playerStatus == PlayerStatus.STATUS_WIN) {
                game.taker.addr.transfer(game.betAmount);
            } else {
                game.originator.addr.transfer(game.originator.playerBetAmount);
                game.taker.addr.transfer(game.taker.playerBetAmount);
            }
        }
        
    }
    
    function compareHands() private{
        uint8 originator = uint8(game.originator.hand);
        uint8 taker = uint8(game.taker.hand);
        
        game.gameStatus = GameStatus.STATUS_STARTED;
        
        if (taker == originator){ //draw
            game.originator.playerStatus = PlayerStatus.STATUS_TIE;
            game.taker.playerStatus = PlayerStatus.STATUS_TIE;
            
        }
        else if ((taker +1) % 4 == originator) { // originator wins
            game.originator.playerStatus = PlayerStatus.STATUS_WIN;
            game.taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if ((originator + 1)%4 == taker){
            game.originator.playerStatus = PlayerStatus.STATUS_LOSE;
            game.taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {
            game.gameStatus = GameStatus.STATUS_ERROR;
        }
        game.gameStatus = GameStatus.STATUS_COMPLETE;
    }
}