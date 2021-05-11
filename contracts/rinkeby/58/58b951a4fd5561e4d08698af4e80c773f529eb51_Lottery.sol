/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.4.17;

contract Lottery{
    mapping(address => bool) public managers;
    mapping(address => playerEntry) public players;
    address[] private playerList;
    address public lastWinner;
    struct playerEntry {
        uint index;
        uint amount;
    }
   
    
    modifier onlyManagers() {
        // Ensure the participant awarding the ether is the manager
        require(managers[msg.sender]);
        _;
    }
    
    modifier notEntered() {
        // only allow players to enter once
        require(players[msg.sender].index == 0);
        require(players[msg.sender].amount == 0);
        _;
    }
    
    modifier hasEntered() {
        // only allow players to enter once
        require(players[msg.sender].amount != 0);
        _;
    }
    
    //Student: Not sure if we want to use the index or amount to track if a player has entered but even then, using not sure how we actually check if someone has entered or not this way.
    //I feel like doing a "if msg.sender is in playerList, allow" is viable, but I don't know how to implement that either

    constructor() public{
        managers[msg.sender] = true;
    }
    
    //Student: Doesn't this make any person a manager by default?
    
    function addManager(address newManager) public onlyManagers {
        // add a new manager
        managers[newManager] = true;
    }
    
    function removeManager(address manager) public onlyManagers {
        // remove a manager
        managers[manager] = false;
    }
    
    function enter() public notEntered payable{
        // enforce a minimum bet
        require(msg.value > 0.001 ether);
        
        // add sender address to the list
        playerList.push(msg.sender);
        
        // create new playerEntry
        uint newIndex = playerList.length;
        players[msg.sender] = playerEntry(newIndex , msg.value);
    }
    
    function withdraw() public hasEntered {
        // save amount to withdraw into a variable
        uint withdrawAmt = players[msg.sender].amount;
        
        // first remove from the array
        removeFromLottery(players[msg.sender].index);
        
        //Student: Remove what from the array?? I'm guessing here
        
        // remove from mapping
        delete players[msg.sender];
        
        // finally, send withdrawn funds to account (good practice to do last)
        lastWinner.transfer(withdrawAmt);
    }

    function pickWinner() public onlyManagers {
        // specify the winner
        lastWinner = playerList[ random() % playerList.length ];

        // setup for another lottery
        resetLottery();
        

        // transfer all money from lottery contract to the player
        uint contractAmnt = address(this).balance;
        players[lastWinner].amount = contractAmnt;
    }

    function getPlayers() public view returns (address[]) {
        // Return list of players
        return playerList;
    }
    
    function resetLottery() private {
        // clear player mapping
        for (uint i  = 0; i < playerList.length + 1; i++) { //update for 
            delete players[playerList[i]];
        }
        
        
        //Not sure if that is what it wants
   
        
        // reinitialize the playerList
        playerList = new address[](0);
    }
    
    // iterate through the playerList and remove the withdrawn player
    function removeFromLottery(uint indx) private {
        // check that index is not too big
        
        //Student: I changed the variable that's passed in to "indx" so it's not confused with "index" for a player in "players"
        //if (index >= playerList.length) return;

        // move entries above index down by one
        //Student: Remove the entries in what down by one?
    
        //iterator = players.length;
        //for (addy in playerList){
           // if (players[addy].index > indx){
             //   players[addy].index = players[addy].indx - 1;
        //    }
        //}
        //}
        
        //Student: Right now I am using a counter so each player's index just counts up each time. ie the first player gets the index 1. 
        //This iteration is meant to decrease the index of any player in "players" by 1.
            
        
        // actually remove the entry
        //delete playerList[indx];
        //???
        //Student: Remove the entry from what? There's the players AND the playerList but in the function that calls "removeFromLottery", it says that the entry in "players" is removed after "removeFromLottery" is called. 
        //Thus, I assumed this meant to remove it from the "playerList". However, this function doesn't take the address of the player that needs to be removed, just the index and since
        //I can't find a way to call the address corresponding to that index (reverse mapping), I don't know how I'm supposed to know what address to remove form "playerList"
        //
        //Edit: Ok I think I achieved what I described above in the code, but unsure
    }
    
    // helper function to find the winner
    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, now, playerList)));
    }
}