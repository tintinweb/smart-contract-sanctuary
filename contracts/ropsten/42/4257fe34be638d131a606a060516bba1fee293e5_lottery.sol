pragma solidity ^0.4.25;

//This is a simple contract where 5 participants enter a wager in Ether. 
//This wager is added to the smart contract. A random function computes who will
//receive the funds and all of these funds (minus gas) are transferred to the winner.
contract lottery {
    
    //5 Players are added to this struct. 
    struct Players {
        address[] person;    //address of players
        uint[] wager;        //wager of each player
        uint numPlayers;     //total number of players (up to 5)
    }
    
    Players players;
    uint wagerTotal;
    address owner;                         //in this case, it is the contract
    uint constant PossibleNumPlayers = 5;  //5 and only 5 players can compete
    
    event Transfer(address sender, address receiver, uint amount);
    
   //Constructor to initialize owner and the struct
    function lottery() public {
        //require(owner != 0x0, "Owner already exists. Wait for contract to terminate");
        owner = address(this);
        wagerTotal = 0;
        
        players.person = new address[](PossibleNumPlayers);
        players.wager = new uint[](PossibleNumPlayers);
        
        //sets Players and Wagers in struct to null (0)
        for (uint i = 0; i < PossibleNumPlayers; i++) {
            players.person[i] = 0;
            players.wager[i] = 0;
        }
        players.numPlayers = 0;
    }
    
    //Adds a player to the struct
    //Checks that player has enough Funds
    //checks if there aren&#39;t already 5 players
    //wager must be more than 0
    function addPlayer() public payable {
        address newPlayer = msg.sender;
        uint value = msg.value;
        
        require(value <= msg.sender.balance, "Insufficient Funds Available");
        require(players.numPlayers < PossibleNumPlayers, "Only 5 participants are allowed");
        require(value > 0, "You have to wager something!");
       
        players.numPlayers += 1;
        players.person[players.numPlayers - 1] = newPlayer;
        players.wager[players.numPlayers - 1] = value;
        wagerTotal += value; 
        owner.send(msg.value);
        Transfer(msg.sender, owner, msg.value);
    }
    
    
    //Generates a decision on who is the winner. This is done randomly.
    //All of the funds wagered by each player will be given to the winner
    //returns the winner address
    function decision() public payable returns (address) {
        
        require(players.numPlayers == PossibleNumPlayers, "There must be 5 participants in the contract");
        
        uint index;
        index = random() % players.numPlayers;
        
        address winner = address(players.person[index]);
        
        uint totalWager = owner.balance;
        winner.send(owner.balance);
        Transfer(owner, winner, totalWager);
        
        for (uint i = 0; i < PossibleNumPlayers; i++) {
            players.person[i] = 0;
            players.wager[i] = 0;
        }
        players.numPlayers = 0;
        wagerTotal = 0;
        
        return winner;
    }
    
    //A random number function provided by the university class instructor
    function random () public view returns(uint) {
       return uint(keccak256(block.difficulty, now, players.person));
    }
    
    //Getter function for the total contract balance, or the sum of amounts wagered
    function getContractBalance() public view returns(uint) {
       return address(this).balance;
    }
    
    //Getter function for a player address given an index of the struct array
    //this index should be between 0 and the number of players added -1
    function getPlayerAddress(uint index) public view returns(address) {
        if (players.numPlayers <= index) {
            return 0x0;
        }
        
        return players.person[index];
    }
    
    //Getter function for a player wager given an index of the struct array
    //this index should be between 0 and the number of players added -1
    function getPlayerWager(uint index) public view returns(uint) {
        if (players.numPlayers <= index){
            return 0; 
        }
        
        return players.wager[index];
    }
    
    //Getter function for Number of Players added already
    function getNumPlayers() public view returns(uint) {
        return players.numPlayers;
           
    }
    
}