/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity >=0.7.0 <0.8.0; 
 
 contract RouletteGame{
     
     struct player{
         uint player_balance; //balnce of a given player
         uint bet_for_x; //0 or 1 
         uint value_of_bet; //how many tokens they bet
         bool already_recieved_winnings; //variable to ensure that the player cannot cheat and run the winnings function multiple times
     }
     
    //Global variables and initializations 
     address public dealer; //assigns a public address to the dealer 
     bytes32 c;
     bytes32 c_check;
     uint number_of_players;
     uint xrev;
     uint rrev;
     bytes32 crev;
     player[] players_ledger; //an array of all players
     mapping(address => uint256) public player_id; //Player will assign a player to this address
     uint dealer_balance; 
     
     
     //specify who the dealer is
     constructor(){
         dealer = msg.sender;
         dealer_balance=10000; //we will arbitrarily assign this as the dealer's balance
         players_ledger.push(); //increments the player struct data
         number_of_players=0; //initialize the number of players before anyone joins the game room 
     } 
     
     //Function to join game room; each player is given a starting balance
     function Join_Game_Room() public{
        require(msg.sender != dealer, "Error: You are already the dealer in the game!");
        require(player_id[msg.sender]==0, "Error: You are already a player in the game!");
        require(number_of_players <= 8, "Error: There's too many players!");
        number_of_players +=1; //increments the number of players in the game by 1
        player_id[msg.sender]=number_of_players; //assigns a number 1,2...,8 to the address of a given player
        players_ledger.push(); //increments the player struct data
        players_ledger[player_id[msg.sender]].player_balance=2000; //each player is given a starting balance of 2000
        players_ledger[player_id[msg.sender]].already_recieved_winnings=false; //assume that the player has not already been paid their earnings, so they can't cheat
     }
    
    //Dealer chooses x and r, and returns c to the public 
    function dealerChoosesValues(uint x, uint r) public returns( bytes32 c) {
        require(msg.sender == dealer, "Error: You are not the dealer, so you can't set x or r!");
        require(x == 0 || x == 1,"Error: The value of x must be 0 or 1!");
        c = keccak256(abi.encodePacked(x,r)); //hash of x and r 
    } 
   
   //Players place bets (input, player.bet_for_x and player.value_of_bet)
   function bet(uint x_bet, uint betVal) public {
     require(msg.sender !=dealer, "Error: You are the dealer, you cannot bet!"); 
     require(player_id[msg.sender] != 0, "Error: You are not in the game!");
     require(x_bet==0 || x_bet==1, "Error: The balue of x must be 0 or 1!");
     require(betVal>=5 && betVal<=500, "Error: You're bet value is not acceptable!");
     players_ledger[player_id[msg.sender]].bet_for_x = x_bet; //transfers x_bet to the player struct data
     players_ledger[player_id[msg.sender]].value_of_bet = betVal; //transfers betVal to the player struct data
   }
   
 
   //Dealer reveals x and r to players 
   function reveal(uint x, uint r) public view returns(uint xrev, uint rrev, bytes32 crev){
        require(msg.sender == dealer, "Error: Only the dealer can reveal x and r!");
        xrev=x; //rename the global variable for convenience of returning it
        rrev = r; //rename the global variable for convenience of returning it
        crev=keccak256(abi.encodePacked(xrev,rrev));
    }
    
    //Player can check that the c hash for the revealed x and r values is legitimate
    function checkC(uint x, uint r) public view returns(bytes32 c_check){
        require(msg.sender != dealer, "Error: You are the dealer, you cant check this!");
        c_check = keccak256(abi.encodePacked(x,r)); //hash function for x and r
    }

   //Players hash their x and r values 
   function winnings() public {
       require(msg.sender != dealer, "Error: Only the players can run this function!");
       require(players_ledger[player_id[msg.sender]].already_recieved_winnings == false, "Error: You've already received your winnings!");
       require(player_id[msg.sender] != 0, "You are not in the game!");
             if(c_check==c){ //condition if the dealer is not cheating 
                if(players_ledger[player_id[msg.sender]].bet_for_x == xrev){ 
                    players_ledger[player_id[msg.sender]].player_balance += players_ledger[player_id[msg.sender]].value_of_bet; //player earns v tokens if they guess x correctly
                    dealer_balance -= players_ledger[player_id[msg.sender]].value_of_bet; //dealer loses v tokens if the player guesses x correctly
                }else{
                    players_ledger[player_id[msg.sender]].player_balance -= players_ledger[player_id[msg.sender]].value_of_bet; //player loses v tokens if they guess x incorrectly 
                    dealer_balance += players_ledger[player_id[msg.sender]].value_of_bet; //dealer gains v tokens if the player guesses x incorrectly
                }
            }else{ //condition if the dealer is cheating
                players_ledger[player_id[msg.sender]].player_balance += 100; //players gains 100 tokens each
                dealer_balance -= 100; //dealer loses 100 tokens for each player in the game 
            }
   }
   
   //Player or dealer can view their token balance depending on who is running the function
   function viewBalance() public view returns(uint balance_current){
      if (msg.sender == dealer){ 
          balance_current=dealer_balance; //if the dealer is running this function, they can view their token balance
      }else{
          balance_current=players_ledger[player_id[msg.sender]].player_balance; //if a player is running this function, they can view their token balance
      }
   }
   
  
 } //end of contract