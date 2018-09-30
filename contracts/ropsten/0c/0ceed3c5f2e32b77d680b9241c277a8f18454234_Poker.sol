pragma solidity ^0.4.19;

contract Poker {
    event newGame(uint gameNum);
    event player1Bid(uint bet);
    event player2Bid(uint bet);
    event player1Flashed(bool flsh);
    
    uint current_game = 0;
    
    struct gamers{
        address player1;
        address player2;
        uint8 p1Cards;
        uint bid;
        address winner;
    }
    // map a certain address to a given game
    mapping (address => uint) public playersGame;
    // count the numbre of players on a given game
    mapping (uint => uint) public gamePlayerCount;
    // state of the game: active - finished
    mapping (uint => bool) public gameActive;
    // addresses of players in a gamer
    mapping (uint => gamers) public playersInGame;
    
    modifier activeOnly(address gamer){
        require(gameActive[playersGame[gamer]] = true);
        _;
    }
    
    modifier allBidded(address gamer){
        require(playersInGame[playersGame[gamer]].bid > 0);
        _;
    }
    
    modifier fullGame(address gamer){
        require(gamePlayerCount[playersGame[gamer]] == 2);
        _;
    }
    modifier p1Flsh(address gamer){
        require(playersInGame[playersGame[gamer]].p1Cards >0);
        _;
    }
    
    
    constructor() public{
        gameActive[current_game] = false;
        gamePlayerCount[current_game] =2;
    }
    
    //this funtion finds a game for a given player or creates a new game
    function joinCreateGame() public{
        uint usrGame = playersGame[msg.sender];
        bool usrActive = gameActive[usrGame];
        require(usrActive != true);
        //check is there is a game open
        //if so, join the game
        if(gamePlayerCount[current_game]<2){
            playersGame[msg.sender]=current_game;
            playersInGame[current_game].player2 = msg.sender;
            gamePlayerCount[current_game]++;
            
            //trigger the event that a new game has started
            emit newGame(current_game);
        }
        else{
            current_game++;
            playersGame[msg.sender]=current_game;
            gamePlayerCount[current_game] = 1;
            gameActive[current_game] = true;
            playersInGame[current_game].player1 = msg.sender;
            
        }
        
        
    }
    
    
    
    function getPartner() external view activeOnly(msg.sender) fullGame(msg.sender) returns(address){
        uint gameNum =playersGame[msg.sender];
        if(playersInGame[gameNum].player1 == msg.sender){
            return playersInGame[gameNum].player2;
        }
        else{
            return playersInGame[gameNum].player1;
        }
    }
    
    //since player one was the first player to join the gameNum
    // he gets the chance to select the index of his 5 cards from a 
    // shuffled deck
    function playe1Bid() payable activeOnly(msg.sender) fullGame(msg.sender){
        uint gameNum =playersGame[msg.sender];
        //execute only if he is the player 1
        require(playersInGame[gameNum].player1==msg.sender);
        if(msg.value > 0){
            playersInGame[gameNum].bid = msg.value;
            player1Bid(msg.value);
        }
        else{
            gameActive[gameNum]=false;
        }
        
    }
    
    function playe2Bid() payable activeOnly(msg.sender) fullGame(msg.sender){
        uint gameNum =playersGame[msg.sender];
        //execute only if he is the player 2
        require(playersInGame[gameNum].player2==msg.sender);
        //requires that player1 has placed a bid
        require(playersInGame[gameNum].bid > 0);
        if(msg.value >= playersInGame[gameNum].bid){
            playersInGame[gameNum].bid += msg.value;
            player2Bid(msg.value);
        }
        else{
            gameActive[gameNum]=false;
        }
        
    }
    function paleyer1show(uint8 _card1,uint8 _card2,uint8 _card3,uint8 _card4,uint8 _car5) activeOnly(msg.sender) fullGame(msg.sender) allBidded(msg.sender){
        uint gameNum =playersGame[msg.sender];
        require(playersInGame[gameNum].player1==msg.sender);
        playersInGame[gameNum].p1Cards = _car5 + _card4 +_card3 +_card2 + _card1;
        player1Flashed(true);
    }
    
    function paleyer2show(uint8 _card1,uint8 _card2,uint8 _card3,uint8 _card4,uint8 _car5) activeOnly(msg.sender) fullGame(msg.sender) allBidded(msg.sender) p1Flsh(msg.sender){
        uint gameNum =playersGame[msg.sender];
        uint8 p2Cards;
        require(playersInGame[gameNum].player2==msg.sender);
        p2Cards = _car5 + _card4 +_card3 +_card2 + _card1;
        if(playersInGame[gameNum].p1Cards>p2Cards){
            playersInGame[gameNum].winner = playersInGame[gameNum].player1;
        }
        else{
            playersInGame[gameNum].winner = playersInGame[gameNum].player2;
        }
        //end the game
        gameActive[gameNum]=false;
        
    }
    
    
    function withdraw() returns (bool) {
       
        uint gameNum =playersGame[msg.sender];
        uint amount = playersInGame[gameNum].bid;
        require(gameActive[gameNum] = false);
        if (amount > 0) {
          // It is important to set this to zero because the recipient
          // can call this function again as part of the receiving call
          // before `send` returns.
          playersInGame[gameNum].bid = 0;
    
          if (!msg.sender.send(amount)) {
            // No need to call throw here, just reset the amount owing
            playersInGame[gameNum].bid = amount;
            return false;
          }
        }
        return true;
      }
    
}