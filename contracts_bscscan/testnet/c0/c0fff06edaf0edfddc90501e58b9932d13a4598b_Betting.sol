/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

pragma solidity ^0.4.2;


contract Betting {
   address public owner;
   event EtherTransfer(address beneficiary, uint amount);
   /* Boolean to verify if betting period is active */
    bool bettingActive = false;

   uint256 public minimumBet;
   uint256 public totalBetsOne;
   uint256 public totalBetsTwo;
   address[] public players;
   struct Player {
      uint256 amountBet;
      uint16 teamSelected;
    }
// The address of the player and => the user info
   mapping(address => Player) public playerInfo;
   function() public payable {}
  function Betting() public {
      owner = msg.sender;
      minimumBet = 100000000000000;
    }
function kill() public {
      if(msg.sender == owner) selfdestruct(owner);
    }
function checkPlayerExists(address player) public constant returns(bool){
      for(uint256 i = 0; i < players.length; i++){
         if(players[i] == player) return true;
      }
      return false;
    }/* Function to enable betting */
    function beginVotingPeriod()  public returns(bool) {
        bettingActive = true;
        return true;
    }
    


    function bet(uint8 _teamSelected) public payable {
      require(bettingActive);
      //The first require is used to check if the player already exist
      require(!checkPlayerExists(msg.sender));
      //The second one is used to see if the value sended by the player is
      //Higher than the minimum value
      require(msg.value >= minimumBet);

      //We set the player informations : amount of the bet and selected team
      playerInfo[msg.sender].amountBet = msg.value;
      playerInfo[msg.sender].teamSelected = _teamSelected;

      //then we add the address of the player to the players array
      players.push(msg.sender);

      //at the end, we increment the stakes of the team selected with the player bet
      if ( _teamSelected == 1){
          totalBetsOne += msg.value;
      }
      else{
          totalBetsTwo += msg.value;
      }
    }
    // Generates a number between 1 and 10 that will be the winner
    function distributePrizes(uint16 teamWinner) public {
      require(bettingActive == false);
      address[1000] memory winners;
      //We have to create a temporary in memory array with fixed size
      //Let's choose 1000
      uint256 count = 0; // This is the count for the array of winners
      uint256 LoserBet = 0; //This will take the value of all losers bet
      uint256 WinnerBet = 0; //This will take the value of all winners bet

      //We loop through the player array to check who selected the winner team
      for(uint256 i = 0; i < players.length; i++){
         address playerAddress = players[i];

         //If the player selected the winner team
         //We add his address to the winners array
         if(playerInfo[playerAddress].teamSelected == teamWinner){
            winners[count] = playerAddress;
            count++;
         }
      }

      //We define which bet sum is the Loser one and which one is the winner
      if ( teamWinner == 1){
         LoserBet = totalBetsTwo;
         WinnerBet = totalBetsOne;
      }
      else{
          LoserBet = totalBetsOne;
          WinnerBet = totalBetsTwo;
      }


      //We loop through the array of winners, to give ethers to the winners
      for(uint256 j = 0; j < count; j++){
          // Check that the address in this fixed array is not empty
         if(winners[j] != address(0))
            address add = winners[j];
            uint256 bet = playerInfo[add].amountBet;
            //Transfer the money to the user
            winners[j].transfer(    (bet*(5000+(LoserBet*5000/WinnerBet)))/5000 );
      }
      delete playerInfo[playerAddress]; // Delete all the players
      players.length = 0; // Delete all the players array
      LoserBet = 0; //reinitialize the bets
      WinnerBet = 0;
      totalBetsOne = 0;
      totalBetsTwo = 0;
    }
     function withdrawEther(address beneficiary) public {
        beneficiary.transfer(address(this).balance);
    }
    /* Function to close voting and handle payout. Can only be called by the owner. */
    function closeVoting() public returns (bool) {
        // Close the betting period
        bettingActive = false;
        return true;
    }

    function AmountOne() public view returns(uint256){
       return totalBetsOne;
    }

    function AmountTwo() public view returns(uint256){
       return totalBetsTwo;
    }
}