/**
 *Submitted for verification at BscScan.com on 2022-01-20
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        //   require(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        //   require(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Token {
   function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BettingERC20 is Ownable {
  
 
   event EtherTransfer(address beneficiary, uint amount);
   /* Boolean to verify if betting period is active */
   bool bettingActive = false;
    
   uint256 devFee = 9000;

   uint256 public minimumBet;
   uint256 public totalBetsOne;
   uint256 public totalBetsTwo;
   uint256 public totalBetsDraw;
   IERC20 tokenAdd;
   address[] public players;

   mapping (address => bool) public Agent;
   struct Player {
      uint256 amountBet;
      uint16 teamSelected;
    }
// The address of the player and => the user info
   mapping(address => Player) public playerInfo;
   function() public payable {}
   
    function kill() public {
        if(msg.sender == owner) selfdestruct(owner);
        }
    function checkPlayerExists(address player) public constant returns(bool){
        for(uint256 i = 0; i < players.length; i++){
            if(players[i] == player) return true;
        }
        return false;
        }/* Function to enable betting */
    function beginVotingPeriod()  public onlyAgent returns(bool) {
        bettingActive = true;
        return true;
    }

    function setTokenAddress(IERC20 tknAddress) public onlyOwner {
            tokenAdd = tknAddress;
    }

    
    IERC20 token = tokenAdd;
    function bet(uint8 _teamSelected, uint256 amount) public  {
            require(bettingActive);
            //The first require is used to check if the player already exist
            require(!checkPlayerExists(msg.sender));
            //The second one is used to see if the value sended by the player is
            //Higher than the minimum value
            require(amount >= minimumBet);
    
    
            //To roll in the Token, this line of code is executed on the condition that the user has approved a contract to use his Token
            //IERC20 is Token
            token.transferFrom(msg.sender,address(this),amount);
    
            //We set the player informations : amount of the bet and selected team
            playerInfo[msg.sender].amountBet = amount;
            playerInfo[msg.sender].teamSelected = _teamSelected;
    
            //then we add the address of the player to the players array
            players.push(msg.sender);
    
            //at the end, we increment the stakes of the team selected with the player bet
            if ( _teamSelected == 0){
                totalBetsOne += amount;
            }
            else if(_teamSelected == 1){
                 totalBetsTwo += amount;
            }
            else{
                 totalBetsDraw += amount;
            }
        }
    // Generates a number between 1 and 10 that will be the winner
    function distributePrizes(uint16 teamWinner) public onlyAgent {
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
        if ( teamWinner == 0){
            LoserBet = totalBetsTwo;
            WinnerBet = totalBetsOne;
            LoserBet = totalBetsDraw;
        }
        else if (teamWinner == 1){
            LoserBet = totalBetsOne;
            WinnerBet = totalBetsTwo;
            LoserBet = totalBetsDraw;
        }
        else{
            LoserBet = totalBetsOne;
            LoserBet = totalBetsTwo;
            WinnerBet = totalBetsDraw;
        }


        //We loop through the array of winners, to give ethers to the winners
        for(uint256 j = 0; j < count; j++){
            // Check that the address in this fixed array is not empty
            if(winners[j] != address(0))
             address add = winners[j];
             uint256 bets = playerInfo[add].amountBet;
            //Transfer the money to the user
//            winners[j].transfer(    (bet*(10000+(LoserBet*devFee /WinnerBet)))/10000 );

            token.transfer(winners[j],  (bets*(10000+(LoserBet*devFee /WinnerBet)))/10000 );

        }
        delete playerInfo[playerAddress]; // Delete all the players
        players.length = 0; // Delete all the players array
        LoserBet = 0; //reinitialize the bets
        WinnerBet = 0;
        totalBetsOne = 0;
        totalBetsTwo = 0;
    }
     function withdrawEther(address beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
    function withdrawTokens(address beneficiary) public onlyOwner {
        require(Token(token).transfer(beneficiary, Token(token).balanceOf(this)));
    }
    /* Function to close voting and handle payout. Can only be called by the owner. */
    function closeVoting() public onlyAgent returns (bool) {
        // Close the betting period
        bettingActive = false;
        return true;
    }
    function setDevFee(uint256 newDevFee) public onlyOwner() {
    devFee = newDevFee;
  }
  function setMinBet(uint256 newMinBet) public onlyOwner() {
    minimumBet = newMinBet;
  }

    function AmountOne() public view returns(uint256){
       return totalBetsOne;
    }

    function AmountTwo() public view returns(uint256){
       return totalBetsTwo;
    }

    function AmountDraw() public view returns(uint256) {
    return totalBetsDraw;
    }

     // Allow this agent to call the airdrop functions
    function setAirdropAgent(address _agentAddress, bool state) public onlyOwner {
        Agent[_agentAddress] = state;
    }

    modifier onlyAgent() {
        require(Agent[msg.sender]);
         _;
        
    }
    
}