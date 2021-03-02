/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

/*
*  John Choi
*  Math 4500
*  3/1/21
*/

pragma solidity >=0.7.0 <0.8.0;

struct player {
    uint balance;
    uint bet_x_val;
    uint bet_amount;
    bool bet_played;
}

/*
*                                                   DIRECTIONS
*                                                   HOW TO PLAY:
* Whoever deploys the contract will be set as the dealer.  Dealer can start by DealerSets and then enter x and r value. 
* Choosing another address on the drop down menu is how other players can joinGameRoom.  From there, players can placeBet
* by entering their chosen x value and bet amount.  They can also viewHash which shows the hash value generated from dealer
* x and r value, but if they choose viewX_and_R, they cannot see what x and r value the dealer chose until the dealer enters
* their x and r value in the dealerReveals function.  Once dealerReveals, the viewX_and_R function will show the first x and 
* r value that the dealer chose and players can verify the generated hash value from those values with the hash value from
* the viewHash function.  If they don't match, the dealer has cheated and will pay a penalty (90% of dealer's balance) equally
* to all players who have placed a bet.  payOut which calculates winnings can only be done by a player, and not the dealer.
* Players should be awarded accordingly if they guessed x correctly or not, and can use viewCurrentBalance to check their updated
* balance.  payOut will not work unless at least one player has placed a bet.  Currently, there is no way to start a new game 
* without redeploying the contract.
*/

/*
The player can win using the martingale strategy by betting x to be 0 or 1 always as the chances of
the dealer choosing 0 or 1 goes to 1 as the tokens become infinite.
*/

contract Roulette_Game {
    address public dealer;
    mapping(address => uint) public IDPlayers;
    uint player_count;
    uint dealers_balance;
    uint x_value;
    uint r_value;
    
    uint revealed_x;
    uint revealed_r;
    bytes32 revealed_hash;
    
    bytes32 hash_value;
    bytes32 check_hash;
    //Cechking to see if a player has set a betPlayed
    bool betPlayed;
    //Checking if dealer has set a x, r value
    bool repick;
    player[] playerBalances;
    
    
    constructor() {
        dealer = msg.sender;
        player_count = 0;
        //Starting dealer at same balance as a player joining the game
        dealers_balance = 500;
        playerBalances.push();
        repick = false;
        betPlayed = false;
    }
    //Allows player to join and start betting
   function joinGameRoom() public {
       require(
           msg.sender != dealer,
           "Dealer cannot participate in betting"
        );
        require(
            IDPlayers[msg.sender] == 0,
            "Already participating in current game"
        );
       require(
           player_count < 8,
           "You can only have up to 8 players in the game"
        );
       player_count += 1;
       IDPlayers[msg.sender] = player_count;
       playerBalances.push();
       playerBalances[IDPlayers[msg.sender]].balance = 500;
       playerBalances[IDPlayers[msg.sender]].bet_played = false;
       
   }
   //Dealer picks x and r and generates hash value for all players to view,
   function dealerSets(uint x, uint r) public {
        //
        require(
            msg.sender == dealer,
            "Only dealer can set x and r values"
        );
        require(
            repick == false,
            "Cannot repick x and r values"
        );
        require(
            x == 0 || x == 1,
            "X value can only be 0 or 1"
        );
        repick = true;
        hash_value = keccak256(abi.encodePacked(x,r));
   }
   
   //Allowing all players to see what the hashed value c is
   function viewHash() public view returns(bytes32 hash) {
       hash = hash_value;
   }
   //Lets player view what x and r the dealer has chosen.  Will display
   //0 and 0, and hash of those values until dealer reveals 
   function viewX_and_R() public view returns(uint x, uint r, bytes32 c) {
       x = x_value;
       r = r_value;
       c = keccak256(abi.encodePacked(x,r));
   }
   
   //Lets player place a bet, can't place bets twice, and can't bet more than
   //player balance and limits bet amount to range specified in HW
   function placeBet(uint playerX, uint betAmount) public {
       require(
            msg.sender != dealer,
            "Dealer cannot place a bet"
       );
       require(
             playerX == 1 || playerX == 0,
             "Player can only bet on 0 or 1"
        );
        require(
            playerBalances[IDPlayers[msg.sender]].bet_played == false,
            "Player can only place 1 bet per game"
        );
        require(
            betAmount >= 5 && betAmount <= 500,
            "Can only bet within range set by dealer"
        );
        require(
            betAmount <= playerBalances[IDPlayers[msg.sender]].balance,
            "Can't bet more than you currently have"
        );
        betPlayed = true;
        
        playerBalances[IDPlayers[msg.sender]].bet_played = true;
        playerBalances[IDPlayers[msg.sender]].bet_amount = betAmount;
        playerBalances[IDPlayers[msg.sender]].bet_x_val = playerX;
        playerBalances[IDPlayers[msg.sender]].balance -= betAmount;
   }
   
   //Dealer reveals what x and r value they picked, if they tried to 
   //cheat and switch the values, hash value will be different from 
   //the hash value when dealer initially set so cheating will be detected
   //in payOut function
   function dealerReveals(uint x, uint r) public {
       require(
           msg.sender == dealer,
           "Only the dealer can reveal x and r values chosen"
        );
        require(
            repick == true,
            "Dealer has to set x and r first"
        );
        x_value = x;
        r_value = r;
   }
   
   //Either penalizes dealer if dealer cheats.  Awards players double of their
   //bet value if they match x, returns their wager if they don't
   function payOut() public returns (bool b){
       require(
           msg.sender != dealer,
           "Dealer cannot start payout"
        );
       require(
            betPlayed == true,
            "Dealer cannot do payout if no bets have been placed"
        );
        require(
            playerBalances[IDPlayers[msg.sender]].bet_played == true,
            "Can only receive payout after placing a bet"
        );
        require(
            IDPlayers[msg.sender] > 0,
            "Only players participating in the game can receive winnings"
        );
        
        betPlayed = false;
        repick = false;
        
        check_hash = keccak256(abi.encodePacked(x_value,r_value));
        for(uint i = 1; i <= player_count; i++) {
            playerBalances[i].bet_played = false;
        }
        //If dealer tries to cheat, takes 90% of dealer's balance and distributes
        //it to all players that are playing
        if(hash_value != check_hash) {
            uint penalty = (dealers_balance*9)/10;
            dealers_balance -= penalty;
            uint pen_payments = penalty / player_count;
            for(uint i = 1; i <= player_count; i++) {
                playerBalances[i].balance += playerBalances[IDPlayers[msg.sender]].bet_amount;
                playerBalances[i].balance += pen_payments;
            }
        }
        //Awards payout
        else {
            for(uint i = 1; i <= player_count; i++) {
                if(playerBalances[i].bet_x_val != x_value) {
                    dealers_balance += playerBalances[i].bet_amount;
                }
                else {
                    playerBalances[i].balance += 2 * playerBalances[i].bet_amount;
                }
            }
         
        }
        
        betPlayed = false;
   }
   
   function viewCurrentBalance() public view returns(uint a) {
       if(msg.sender == dealer) {
           a = dealers_balance;
       }
       else {
           a = playerBalances[IDPlayers[msg.sender]].balance;
       }
   }
}