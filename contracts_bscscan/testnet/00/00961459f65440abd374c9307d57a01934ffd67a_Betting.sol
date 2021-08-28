/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

pragma solidity ^0.4.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Betting is Ownable {
   
   uint256 public minimumBet;
   
   event EtherTransfer(address beneficiary, uint amount);
   //Initialize in 10 matches (It can be improved)
   uint256[] public totalBetHome = new uint256[](10);
   uint256[] public totalBetAway = new uint256[](10);
   uint256[] public totalBetDraw = new uint256[](10);
   uint256 public numberOfBets;
   uint256 public maxAmountOfBets = 1000;
    
   uint256 devFee = 9500;
   
   address[] public players;

   address public owner;
   
   
   
   struct  Bet {
      uint256 amountBet;
      uint16 matchSelected;
      uint16 resultSelected;
   }
   
   struct Player {
      uint256 amountBet;
      uint16 matchSelected;
      uint16 resultSelected;
      uint numFunders;
      mapping (uint => Bet) Bets;
   }
   mapping(uint16 => bool) matchBettingActive;

   mapping(address => Player) public playerInfo;

   function() public payable {}

   constructor() public {
       owner = msg.sender;
      //The minimum Bet defined as 0.0001 ether
      minimumBet = 100000000000000;


   }
   function kill() public {
      if(msg.sender == owner) selfdestruct(owner);
    }

   function checkIfPlayerExists(address player,uint16 matchSelect) public view returns(bool){
    //   for(uint256 i = 0; i < players.length; i++){
    //      if(players[i] == player ) return true;
    //   }
    //   return false;
    
    if(playerInfo[player].matchSelected == matchSelect){
        return true;
   }
    else {
        return false;
    }
      
   }

   function initializeMatches(uint8 _numberMatches) public onlyOwner{
      for(uint256 i = 0; i < _numberMatches; i++){
         totalBetHome[i] = 0;
         totalBetAway[i] = 0;
         totalBetDraw[i] = 0;
      }
   }
   
   function beginVotingPeriodForMatch(uint16 _match)  public onlyOwner returns(bool) {
    matchBettingActive[_match] = true;
    return true;
  }
  
   function closeVotingForMatch(uint16 _match) public onlyOwner returns (bool) {
    // Close the betting period
    matchBettingActive[_match] = false;
    return true;
  }

   function bet(uint16 _matchSelected, uint16 _resultSelected) public payable {
      
      Player storage c = playerInfo[_matchSelected];
      
      require(matchBettingActive[_matchSelected], "Betting: match voting is disabled");
      //Check if the player already exist
      require(!checkIfPlayerExists(msg.sender, _matchSelected));
    
      //Check if the value sended by the player is higher than the min value
      require(msg.value >= minimumBet);
      
      //Set the player informations : amount of the bet, match and result selected
      playerInfo[msg.sender].amountBet = msg.value;
      playerInfo[msg.sender].matchSelected = _matchSelected;
      playerInfo[msg.sender].resultSelected = _resultSelected;
      c.Bets[c.numFunders++] = Bet({ amountBet:msg.value,matchSelected: _matchSelected,resultSelected: _resultSelected});
      
      //Add the address of the player to the players array
      players.push(msg.sender);
    
      //Finally increment the stakes of the team selected with the player bet
      if ( _resultSelected == 1){
          totalBetHome[_matchSelected] += msg.value;
      }
      else if( _resultSelected == 2){
          totalBetAway[_matchSelected] += msg.value;
      }
      else{
          totalBetDraw[_matchSelected] += msg.value;
      }
   }

   function distributePrizes(uint16 matchFinished, uint16 teamWinner) public onlyOwner {
      address[1000] memory winners;
      //Temporary in memory array with fixed size. Let's choose 1000
      uint256 count = 0; // This is the count for the array of winners
      uint256 loserBet = 0; //This will take the value of all losers bet
      uint256 winnerBet = 0; //This will take the value of all winners bet
      address add;
      uint256 bets;
      address playerAddress;
    
      //Check who selected the winner team
      for(uint256 i = 0; i < players.length; i++){
         playerAddress = players[i];
         //If the player selected the winner team, we add his address to the winners array
         if(playerInfo[playerAddress].matchSelected == matchFinished &&
            playerInfo[playerAddress].resultSelected == teamWinner){
            winners[count] = playerAddress;
            count++;
         }
       }
       //We define which bet sum is the Loser one and which one is the winner
       if ( teamWinner == 1){
         loserBet = totalBetAway[matchFinished] + totalBetDraw[matchFinished];
         winnerBet = totalBetHome[matchFinished];
       }
       else if ( teamWinner == 2){
         loserBet = totalBetHome[matchFinished] + totalBetDraw[matchFinished];
         winnerBet = totalBetAway[matchFinished];
       }
       else{
          loserBet = totalBetHome[matchFinished] + totalBetAway[matchFinished];
          winnerBet = totalBetDraw[matchFinished];
       }
      //We loop through the array of winners, to give ethers to the winners
      for(uint256 j = 0; j < count; j++){
          //Check that the address in this fixed array is not empty
         if(winners[j] != address(0))
            add = winners[j];
            bets = playerInfo[add].amountBet;
            uint256 amountToPlayer = (bets * (10000+(loserBet*devFee/winnerBet))) / 10000;
            winners[j].transfer(amountToPlayer);
      }
      //Reset all variables
      delete playerInfo[playerAddress]; 
      players.length = 0; 
      loserBet = 0; 
      winnerBet = 0;
      //10 will be the number of matches (To improve this)
      for(uint256 k = 0; k < 10; k++){
         totalBetHome[k] = 0;
         totalBetAway[k] = 0;
         totalBetDraw[k] = 0;
      }
    }
    
    function withdrawEther(address beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
    
     function setDevFee(uint256 newDevFee) public onlyOwner() {
        devFee = newDevFee;
    }
    
     function setMinBet(uint256 newMinBet) public onlyOwner() {
        minimumBet = newMinBet;
    }

    function AmountHome(uint16 _matchSelected) public view returns(uint256){
       return totalBetHome[_matchSelected];
    }
    function AmountAway(uint16 _matchSelected) public view returns(uint256){
       return totalBetAway[_matchSelected];
    }
    function AmountDraw(uint16 _matchSelected) public view returns(uint256){
       return totalBetDraw[_matchSelected];
    }
}