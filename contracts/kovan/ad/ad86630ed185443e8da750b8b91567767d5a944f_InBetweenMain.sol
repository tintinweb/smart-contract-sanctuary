/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract InBetweenMain {
    /********************
    * Constructor
    * Create Deck
    ********************/
    struct Card {
        string cardName;
        uint256 rank;
    }
    mapping(uint256 => Card) cards;
    constructor() {
        cards[1] = Card("Ace of Hearts", 14);
        cards[2] = Card("King of Hearts", 13);
        cards[3] = Card("Queen of Hearts", 12);
        cards[4] = Card("Jack of Hearts", 11);
        cards[5] = Card("Ten of Hearts", 10);
        cards[6] = Card("Nine of Hearts", 9);
        cards[7] = Card("Eight of Hearts", 8);
        cards[8] = Card("Seven of Hearts", 7);
        cards[9] = Card("Six of Hearts", 6);
        cards[10] = Card("Five of Hearts", 5);
        cards[11] = Card("Four of Hearts", 4);
        cards[12] = Card("Three of Hearts", 3);
        cards[13] = Card("Two of Hearts", 2);
        
        cards[14] = Card("Ace of Diamonds", 14);
        cards[15] = Card("King of Diamonds", 13);
        cards[16] = Card("Queen of Diamonds", 12);
        cards[17] = Card("Jack of Diamonds", 11);
        cards[18] = Card("Ten of Diamonds", 10);
        cards[19] = Card("Nine of Diamonds", 9);
        cards[20] = Card("Eight of Diamonds", 8);
        cards[21] = Card("Seven of Diamonds", 7);
        cards[22] = Card("Six of Diamonds", 6);
        cards[23] = Card("Five of Diamonds", 5);
        cards[24] = Card("Four of Diamonds", 4);
        cards[25] = Card("Three of Diamonds", 3);
        cards[26] = Card("Two of Diamonds", 2);
        
        cards[27] = Card("Ace of Spades", 14);
        cards[28] = Card("King of Spades", 13);
        cards[29] = Card("Queen of Spades", 12);
        cards[30] = Card("Jack of Spades", 11);
        cards[31] = Card("Ten of Spades", 10);
        cards[32] = Card("Nine of Spades", 9);
        cards[33] = Card("Eight of Spades", 8);
        cards[34] = Card("Seven of Spades", 7);
        cards[35] = Card("Six of Spades", 6);
        cards[36] = Card("Five of Spades", 5);
        cards[37] = Card("Four of Spades", 4);
        cards[38] = Card("Three of Spades", 3);
        cards[39] = Card("Two of Spades", 2);
        
        cards[40] = Card("Ace of Clubs", 14);
        cards[41] = Card("King of Clubs", 13);
        cards[42] = Card("Queen of Clubs", 12);
        cards[43] = Card("Jack of Clubs", 11);
        cards[44] = Card("Ten of Clubs", 10);
        cards[45] = Card("Nine of Clubs", 9);
        cards[46] = Card("Eight of Clubs", 8);
        cards[47] = Card("Seven of Clubs", 7);
        cards[48] = Card("Six of Clubs", 6);
        cards[49] = Card("Five of Clubs", 5);
        cards[50] = Card("Four of Clubs", 4);
        cards[51] = Card("Three of Clubs", 3);
        cards[52] = Card("Two of Clubs", 2);
    }
  
        /********************
        * Game Variables
        * 
        ********************/
        uint256 turnSelector = 1;
        uint256 playerCount;
        uint256 ante_amount;
        bool game_started;
        bool isRoundOne;
        bool cardsDealt;
        uint256 pot;
        uint256 time_left = 30;
        string whos_turn;
        string[5] Whos_Turn_Array = ["", "It's Player_1's turn.", "It's Player_2's turn.", "It's Player_3's turn.", "It's Player_4's turn."];
        string message;
        string[3] Message_Array = ["Game has not started yet.", "Write 'Deal Cards' to see your first two cards.", "Write 'Bet' to see the third card or 'Pass' to pass the turn."];
        string card_one;
        string card_two;
        uint256 card1rank;
        uint256 card2rank;
        string card_three;
        uint256 card3rank;
        string result;
        string[6] Result_Array = ["", "Bet won!", "Bet lost!", "Turn passed", "Cards too close in rank, turn passed."]; //we have to ignore posts for now because there is no way to pull funds from a player, 
                                                                                                    //kinda jank to make players bet twice as much in the event they post
        uint256 rand1;
        uint256 rand2;
        uint256 rand3;
        /********************
        * Player Data Arrays
        *
        ********************/
        string[5] playerIndexToName; //set player names
        uint256[5] playerIndexToAcePref = [1,1,1,1,1]; //set first ace prefs, 0 = prefer low, 1 = prefer high
        string[2] acePrefStatement = ["Aces are Low", "Aces are High"];
        string[3] activityStatement = ["Position is empty", "Player is active", "Player is AFK, their turn will be passed"];
        address[5] playerIndexToAddress; //set player 1 2 3 & 4 addresses
        uint256[5] playerIndexIsInGame; //show whether a player is in the game, 1=ingame, 0=notingane useful for turn selector. using ints so i can add them
        uint256[5] playerIndexIsAFK; //shows whether a player is afk,0=empty position 1=active, 2=afk. using ints so I can add them.
        /********************
        * Set Ante Amount
        * (before someone
        *  antes up)
        ********************/
        function Set_Ante_Amt(uint256 Ante_Amount) public {
            require((game_started == false),  "You cannot change this if the game has started or if there are people in the lobby.");
            require((playerIndexIsInGame[1] + playerIndexIsInGame[2] + playerIndexIsInGame[3] + playerIndexIsInGame[4]) == 0, "You cannot change the ante amount while players are in the lobby.");
            ante_amount = Ante_Amount;
            pot = address(this).balance;
        }
        /********************
        * Ante Up
        * Pay Ante
        *(before game starts)
        ********************/
        function Ante_Up(uint256 _PlayerNumber,uint256 HighAce1_LowAce0,string memory Name) public payable {
            require(ante_amount != 0, "Please set an ante amount using the 'Set_Ante_Amt' function.");
            require(msg.sender != playerIndexToAddress[1], "You are already in the lobby (Player_1)");
            require(msg.sender != playerIndexToAddress[2], "You are already in the lobby (Player_2)");
            require(msg.sender != playerIndexToAddress[3], "You are already in the lobby (Player_3)");
            require(msg.sender != playerIndexToAddress[4], "You are already in the lobby (Player_4)");
            require(game_started == false, "The game has already started. You can only ante up before the game starts.");
            require(msg.value == ante_amount, "You must pay the ante amount exactly.");
            require(playerIndexIsAFK[_PlayerNumber] == 0, "There is already a player in this position.");
            playerIndexToName[_PlayerNumber] = Name;
            playerIndexToAcePref[_PlayerNumber] = HighAce1_LowAce0;
            playerIndexToAddress[_PlayerNumber] = msg.sender;
            playerIndexIsInGame[_PlayerNumber] = 1;
            playerIndexIsAFK[_PlayerNumber] = 1;
            pot = address(this).balance;
            playerCount++;
        }
        /********************
        * Remove Players
        * Return Ante
        *(before game starts)
        ********************/
        function Remove_Player(uint256 _PlayerNumber) public {
            require(game_started == false, "You can only remove players from lobbies before the game starts. Try starting a timer if a player is AFK.");
            payable(playerIndexToAddress[_PlayerNumber]).transfer(ante_amount);
            delete playerIndexToName[_PlayerNumber];
            delete playerIndexToAcePref[_PlayerNumber];
            delete playerIndexToAddress[_PlayerNumber];
            playerIndexIsInGame[_PlayerNumber] = 0;
            playerIndexIsAFK[_PlayerNumber] = 0;
            playerCount = playerCount - 1;
            pot = address(this).balance;
        }
        /********************
        * Toggle aces preference
        * (anytime)
        ********************/
        function Toggle_Aces() public {
            for(uint256 i=1; i<=4; i++) {
                
                if(msg.sender == playerIndexToAddress[i]) {
                    if(playerIndexToAcePref[i] == 1) {
                        playerIndexToAcePref[i] = 0;
                    }
                    else {
                    playerIndexToAcePref[i] = 1;
                    }
                }
            }
        }
        /********************
        * Toggle to "go AFK"
        * (anytime)
        ********************/
        function Toggle_AFK() public {
            for(uint256 i=1; i<=4; i++) {
                
                if(msg.sender == playerIndexToAddress[i]) {
                    if(playerIndexIsAFK[i] == 1) {
                        playerIndexIsAFK[i] = 2;
                    }
                    else {
                    playerIndexIsAFK[i] = 1;
                    }
                }
            }
        }
        /********************
        * Request Player Info
        * (anytime)
        ********************/
        function Player_1() public view returns(string memory, string memory, string memory,  address) {
            return (playerIndexToName[1], acePrefStatement[playerIndexToAcePref[1]], activityStatement[playerIndexIsAFK[1]], playerIndexToAddress[1]);
        }
        function Player_2() public view returns(string memory, string memory, string memory, address) {
            return (playerIndexToName[2], acePrefStatement[playerIndexToAcePref[2]], activityStatement[playerIndexIsAFK[2]], playerIndexToAddress[2]);
        }
        function Player_3() public view returns(string memory, string memory, string memory, address) {
            return (playerIndexToName[3], acePrefStatement[playerIndexToAcePref[3]], activityStatement[playerIndexIsAFK[3]], playerIndexToAddress[3]);
        }
        function Player_4() public view returns(string memory, string memory, string memory, address) {
            return (playerIndexToName[4], acePrefStatement[playerIndexToAcePref[4]], activityStatement[playerIndexIsAFK[4]], playerIndexToAddress[4]);
        }
        /********************
        * Request Game Status
        * (anytime)
        ********************/
        function Game_Status() public view 
        returns(bool Game_Started, uint256 Player_Count, uint256 Ante_Amount, uint256 Pot, uint256 Time_Left, string memory Whos_Turn, string memory Message, string memory Card_1, string memory Card_2, string memory Card_3, string memory Result) {
            return (game_started, playerCount, ante_amount, pot, time_left, whos_turn, message, card_one, card_two, card_three, result);
        }
        /********************
        * Start the Game
        *
        ********************/
        function Start_Game() public {
            require(game_started == false, "The game has already started.");
            // require at least 2 players are in the lobby
            playerCount = playerIndexIsInGame[1] + playerIndexIsInGame[2] + playerIndexIsInGame[3] + playerIndexIsInGame[4];
            require(playerCount >=2, "There must be at least two players in the lobby to start a game.");
            game_started = true;
            isRoundOne = true;
            message = Message_Array[1];
            pot = address(this).balance;
            if (playerIndexIsInGame[1] == 1) {
                turnSelector = 1;
                whos_turn = Whos_Turn_Array[1];
            }
            else if (playerIndexIsInGame[2] == 1) {
                turnSelector = 2;
                whos_turn = Whos_Turn_Array[2];
            }
            else if (playerIndexIsInGame[3] == 1) {
                turnSelector = 3;
                whos_turn = Whos_Turn_Array[3];
            }
            else if (playerIndexIsInGame[4] == 1) {
                turnSelector = 4;
                whos_turn = Whos_Turn_Array[4];
            }
        }
        /********************
        * Turn Selector
        *
        ********************/
        function UpdateTurn() private {
            cardsDealt = false;
            message = Message_Array[1];
            if (turnSelector == 1) {
                if (playerIndexIsInGame[2] == 1) {
                    turnSelector = 2;
                    whos_turn = Whos_Turn_Array[2];
                }
                else if (playerIndexIsInGame[3] == 1) {
                    turnSelector = 3;
                    whos_turn = Whos_Turn_Array[3];
                }
                else if (playerIndexIsInGame[4] == 1) {
                    turnSelector = 4;
                    whos_turn = Whos_Turn_Array[4];
                }
                else {
                    turnSelector = 1;
                    whos_turn = Whos_Turn_Array[1];
                    isRoundOne = false;
                }
            }
            else if (turnSelector == 2) {
                if (playerIndexIsInGame[3] == 1) {
                    turnSelector = 3;
                    whos_turn = Whos_Turn_Array[3];
                }
                else if (playerIndexIsInGame[4] == 1) {
                    turnSelector = 4;
                    whos_turn = Whos_Turn_Array[4];
                }
                else if (playerIndexIsInGame[1] == 1) {
                    turnSelector = 1;
                    whos_turn = Whos_Turn_Array[1];
                    isRoundOne = false;
                }
                else {
                    turnSelector = 2;
                    whos_turn = Whos_Turn_Array[2];
                    isRoundOne = false;
                }
            }
            else if (turnSelector == 3) {
                if (playerIndexIsInGame[4] == 1) {
                    turnSelector = 4;
                    whos_turn = Whos_Turn_Array[4];
                }
                else if (playerIndexIsInGame[1] == 1) {
                    turnSelector = 1;
                    whos_turn = Whos_Turn_Array[1];
                    isRoundOne = false;
                }
                else if (playerIndexIsInGame[2] == 1) {
                    turnSelector = 2;
                    whos_turn = Whos_Turn_Array[2];
                    isRoundOne = false;
                }
                else {
                    turnSelector = 3;
                    whos_turn = Whos_Turn_Array[3];
                    isRoundOne = false;
                }
            }
            else if (turnSelector == 4) {
                if (playerIndexIsInGame[1] == 1) {
                    turnSelector = 1;
                    whos_turn = Whos_Turn_Array[1];
                    isRoundOne = false;
                }
                else if (playerIndexIsInGame[2] == 1) {
                    turnSelector = 2;
                    whos_turn = Whos_Turn_Array[2];
                    isRoundOne = false;
                }
                else if (playerIndexIsInGame[3] == 1) {
                    turnSelector = 3;
                    whos_turn = Whos_Turn_Array[3];
                    isRoundOne = false;
                }
                else {
                    turnSelector = 4;
                    whos_turn = Whos_Turn_Array[4];
                    isRoundOne = false;
                }
            }
        }
        /********************
        * Generate (kinda) Random Number
        * Need to fix this later
        ********************/
        function randomnumbersx2() private {
            uint256 number = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender)));
            bool continueloop1 = true;
            bool continueloop2 = true;
            while (continueloop1) {
                rand1 = uint256(number % 100);
                number = number/100;
                    if ((rand1 >= 1) && (rand1 <=52)) {
                        continueloop1 = false;
                    }
            }
            
            while (continueloop2 || (rand1 == rand2)) {
                rand2 = uint256(number % 100);
                number = number/100;
                if ((rand2 >= 1) && (rand2 <=52)) {
                    continueloop2 = false;
                }
            }
        }
        function randomnumbersx1() private {
            uint256 number = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender)));
            bool continueloop1 = true;
            while (continueloop1 || (rand3 == rand2) || (rand3 == rand2)) {
                rand3 = uint256(number % 100);
                number = number/100;
                if ((rand3 >= 1) && (rand3 <=52)) {
                    continueloop1 = false;
                }
            }
        }
        /********************
        * Deal Cards
        *
        ********************/
        function Deal_Cards() public {
            
            require(game_started == true, "The game hasn't started yet.");
            require(playerIndexToAddress[turnSelector] == msg.sender, "You can only do this on your turn.");
            require(cardsDealt == false, "You have already been dealt cards.");
            result = Result_Array[0];
            randomnumbersx2();
            card_one = cards[rand1].cardName;
            card_two = cards[rand2].cardName;
            card_three = "";
            card1rank = cards[rand1].rank;
            card2rank = cards[rand2].rank;
            cardsDealt = true;
            message = Message_Array[2];
            if ((card1rank == card2rank) || (card1rank == card2rank +1) || (card1rank + 1 == card2rank)) {
                UpdateTurn();
                result = Result_Array[4];
            }
        }
        /********************
        * Bet
        *
        ********************/
        function Bet() public payable {
            require(game_started == true, "The game hasn't started yet.");
            require(playerIndexToAddress[turnSelector] == msg.sender, "You can only do this on your turn.");
            require(cardsDealt == true, "Your cards have not been dealt yet.");
            require(msg.value <= pot, "You cannot bet more than what is in the pot.");
            if (isRoundOne) {
                require(msg.value <= ante_amount, "You cannot bet more than the ante amount during round one.");
            }
            bool betWon = false;
            bool cardoneislow;
            if (cards[rand1].rank < cards[rand2].rank) {
                cardoneislow = true;
            }
            if (cards[rand1].rank > cards[rand2].rank) {
                cardoneislow = false;
            }
            randomnumbersx1();
            card_three = cards[rand3].cardName;
            card3rank = cards[rand3].rank;
            if ((playerIndexToAcePref[turnSelector] == 0) && (cards[rand1].rank == 14)) { //aces low
                if(cards[rand3].rank < cards[rand2].rank) {
                    betWon = true;
                }
            } 
            if (cardoneislow) {
                if ((cards[rand3].rank > cards[rand1].rank) && (cards[rand3].rank < cards[rand2].rank)) {
                    betWon = true;
                }
            }
            if (!cardoneislow) {
                if ((cards[rand3].rank < cards[rand1].rank) && (cards[rand3].rank > cards[rand2].rank)) {
                    betWon = true;
                }
            }
            if (betWon == true) {
                payable(msg.sender).transfer(2*msg.value);
                result = Result_Array[1];
            }
            if (betWon == false) {
                result = Result_Array[2];
            }
            UpdateTurn();
            cardsDealt = false;
            pot = address(this).balance;
            if (address(this).balance <= 0) {
                End_Game();
            }
        }
        /********************
        * Pass
        *
        ********************/
        function Pass() public {
            require(game_started == true, "The game hasn't started yet.");
            require(playerIndexToAddress[turnSelector] == msg.sender, "You can only do this on your turn.");
            result = Result_Array[3];
            UpdateTurn();
            cardsDealt = false;
        }
        /********************
        * End Game
        *
        ********************/
        function End_Game() private {
            if (pot > 0) {
                //divide the remaining pot equally between addresses in the player array
                if (playerIndexIsInGame[1] == 1) {
                    payable(playerIndexToAddress[1]).transfer(pot/playerCount);
                }
                if (playerIndexIsInGame[2] == 1) {
                    payable(playerIndexToAddress[2]).transfer(pot/playerCount);
                }
                if (playerIndexIsInGame[3] == 1) {
                    payable(playerIndexToAddress[3]).transfer(pot/playerCount);
                }
                if (playerIndexIsInGame[4] == 1) {
                    payable(playerIndexToAddress[4]).transfer(pot/playerCount);
                }
                payable(msg.sender).transfer(address(this).balance);
            }
            //reset the game Variables
            game_started = false;
            turnSelector = 1;
            cardsDealt = false;
            playerCount = 0;
            playerIndexToName = ["","","","",""]; //reset player names
            playerIndexToAcePref = [1,1,1,1,1]; //reset first ace prefs, 0 = prefer low, 1 = prefer high
            delete playerIndexToAddress[1];
            delete playerIndexToAddress[2];
            delete playerIndexToAddress[3];
            delete playerIndexToAddress[4];
            playerIndexIsInGame = [0,0,0,0,0]; //reset player is in the game, 1=ingame, 0=notingane useful for turn selector. using ints so i can add them
            playerIndexIsAFK = [0,0,0,0,0]; //reset a player is afk,0=empty position 1=active, 2=afk. using ints so I can add them.
            message = Message_Array[0];
            whos_turn = Whos_Turn_Array[0];
            card_one = "";
            card_two = "";
            card_three = "";
            result = Result_Array[0];
            pot = address(this).balance;
        }
}