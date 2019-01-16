pragma solidity ^0.4.16;
contract rspContract {

    enum  gameState {GAME_PENDING, P1_SIGNED_UP, GAME_STARTED}
    
    // GAME_PENDING
    //      Players have not signed up
    // P1_SIGNED_UP
    //	    First player signed up game
    // GAME_STARTED
    //      Both players signed up for game

    
    address player1;                // Ethereum acccountof player 1
    address player2;                // Ethereum account of player 2
    address game_host;		        // Ethereum account of game sponsor
    address sensor;                 // Address (public key) of ML sensor reporting 
    uint price_money;               // Price Money
    gameState game_state;           // Game State
    
    // Game Contract creation 
    function rspContract(address the_sensor, uint the_price) public payable{
        game_host       = msg.sender;
        price_money     = the_price;
	    sensor		    = the_sensor;
   	    player1	        = 0;
        player2         = 0;
        game_state      = gameState.GAME_PENDING;
    }

    // Player Sign Up
    function playerSignUp(address the_player) public payable {
    	if ( game_state == gameState.GAME_PENDING ) {
	        player1 = the_player;
	        game_state= gameState.P1_SIGNED_UP;
	    }
	    else if ( game_state == gameState.P1_SIGNED_UP ) {
	        player2 = the_player;
	    game_state = gameState.GAME_STARTED;
	    }	
    }

    // Sensor report outcome of the game 
    // 0 => Rock  1 => Paper 2 => Scissors 
    // Contract validate data & correct origin (i.e coming from dedicated sensor)
    // Contract evaluates the 9 possible outcomes according to below.
    // Contract transfers price money to winner - no transfer at draw.
    // 1. Rock vs paper   	     => Paper wins
    // 2. Rock vs scissors	     => Scissors wins
    // 3. Rock vs rock 	     	     => Draw
    // 4. Scissors vs rock	     => Rock Wins
    // 5. Scissors vs paper          => Scissor wins
    // 6. scissors vs scissors       => Draw
    // 7. Paper vs rock 	     => Paper wins
    // 8. paper vs scissors          => Scissor wins
    // 9. paper vs paper	     => Draw

    function reportGame(string message, uint8 v, bytes32 r, bytes32 s)  public {
	address the_winner = 0;
        //require(game_state == gameState.GAME_STARTED);
        
        // Hash message (string)
        bytes32 h = keccak256(message);
        // Hash Ethereum prefix
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, h);
        
        // Recover the EC Public key
        require(ecrecover(prefixedHash, v, r, s) == sensor);

	// P1 Rock vs P2 Rock => Draw
	if ( h == keccak256("00") )  {
	     the_winner = 0;
	}		
	
	// P1 Rock vs P2 paper =>  P2 Wins
	if ( h == keccak256("01") ) {
	   the_winner = player2;
	}	

	// P1 Paper vs P2 rock => P1 Wins
	if ( h == keccak256("10") )  {
	   the_winner = player1;
	}

	// P1 paper vs P2 paper => Draw
	if ( h == keccak256("11") ) {
	   the_winner = 0;
	}

	// P1 Rock vs P2 scissors => P1 Wins
	if ( h == keccak256("02") ) {
	   the_winner = player1;
	}


	// P1 Paper vs P2 Scissors => P2 Wins
	if ( h == keccak256("12") ) {
	   the_winner = player2;
	}	

	// P1 Scissors vs P2 rock => P2 Wins
	if ( h == keccak256("20") ) {
	   the_winner = player2;
	}

	// P1 Scissors pvs P2 paper => P1 Wins
	if ( h == keccak256("21") ) {
	   the_winner = player1;
	}



	// P1 scissors vs P2 scissors  => Draw
	if ( h == keccak256("22") ) {
	   the_winner = 0;
	}

        
       // At this point the message & sender is validated - transfer price money
        if ( the_winner != 0 ) {
		the_winner.transfer(price_money);
	    }         
    }
    

    // Check state of contract
    function getContractState() public view returns (gameState){
        return game_state;
    }

    // Get the price money
    function getPriceMoney() public view returns (uint) {
        return price_money;
    }

    // Get the ML sensor address 
    function getSensorAddress() public view returns (address) {
        return sensor;
    }

   // Debug utility allowing contract reset
   function resetContract(uint the_price) public {
    	player1        = 0;	
        player2        = 0;
	// New Price
        price_money     = the_price;
        game_state = gameState.GAME_PENDING;
    }

    
}