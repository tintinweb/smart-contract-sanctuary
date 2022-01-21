/**
 *Submitted for verification at BscScan.com on 2022-01-21
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

contract BettingSabongGameID is Ownable {
   using SafeMath for uint256;
 
   event EtherTransfer(address beneficiary, uint amount);
   /* Boolean to verify if betting period is active */
    bool bettingActive = false;
    
   uint256 devFee = 9500;

   uint256 public minimumBet = 2000000000000000000;
   uint256 public totalBetsOne;
   uint256 public totalBetsTwo;
   address[] public players;
   address add;
   uint256 bets;
   uint256 num;

    enum PlayerStatus {Not_Joined, Joined, Ended}
   enum State {Not_Created, Created, Joined, Finished}
   struct Game {
    uint betId;  
    State state;
    
    }
    uint public gameId;
    mapping(uint => Game) public gameInfo;
    event BetPlayer(address indexed _from, uint256 _amount, uint player);

   mapping (address => bool) public Agent;
   


   struct Player {
      uint256 amountBet;
      uint16 teamSelected;
       PlayerStatus _state;
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

     function newGame() external  onlyAgent {
        
        gameInfo[gameId] = Game(gameId, State.Created);
        gameId++;
        
    }
    

    IERC20 token = IERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    function bet(uint _gameId, uint8 _teamSelected, uint256 amount) public  {
            require(bettingActive);
            Game storage game = gameInfo[_gameId];
            require(game.state == State.Created,"Game has not been created");
            require(playerInfo[msg.sender]._state == PlayerStatus.Not_Joined, "You have already placed a bet");
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
            if ( _teamSelected == 1){
                totalBetsOne += amount;
            }
            else if(_teamSelected == 2){
                totalBetsTwo += amount;
            }

        playerInfo[msg.sender]._state = PlayerStatus.Joined;
        emit BetPlayer(msg.sender, amount, _teamSelected);

        }
    // Generates a number between 1 and 10 that will be the winner
    function distributePrizes(uint _gameId, uint16 teamWinner) public onlyAgent {
        Game storage game = gameInfo[_gameId];
        require(bettingActive == false);
        address[1000] memory winners;
        address[1000] memory draw;
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
        //We loop through the array of winners, to give ethers to the winners
        for(uint256 j = 0; j < count; j++){
            // Check that the address in this fixed array is not empty
            if(winners[j] != address(0))
             add = winners[j];
             bets = playerInfo[add].amountBet;

            token.transfer(winners[j],  (bets*(10000+(LoserBet*devFee /WinnerBet)))/10000 );

        }
        delete playerInfo[playerAddress]; // Delete all the players
        players.length = 0; // Delete all the players array
        LoserBet = 0; //reinitialize the bets
        WinnerBet = 0;
        totalBetsOne = 0;
        totalBetsTwo = 0;
        game.state == State.Finished;
            
        }
        else if(teamWinner == 2){
            LoserBet = totalBetsOne;
            WinnerBet = totalBetsTwo;
        //We loop through the array of winners, to give ethers to the winners
        for(uint256 k = 0; k < count; k++){
            // Check that the address in this fixed array is not empty
            if(winners[k] != address(0))
             add = winners[k];
             bets = playerInfo[add].amountBet;

            token.transfer(winners[k],  (bets*(10000+(LoserBet*devFee /WinnerBet)))/10000 );

        }
        delete playerInfo[playerAddress]; // Delete all the players
        players.length = 0; // Delete all the players array
        LoserBet = 0; //reinitialize the bets
        WinnerBet = 0;
        totalBetsOne = 0;
        totalBetsTwo = 0;
        game.state == State.Finished;
                       
        }
        else if(teamWinner == 3){
            //We loop through the player array to check who selected the winner team
        
        for(uint256 l = 0; l < players.length; l++){
            add = players[l];

            if(playerInfo[add].teamSelected == 1||playerInfo[add].teamSelected == 2){
                draw[num] = add;
                num++;
            }
        }
        //We loop through the array of winners, to give ethers to the winners
        for(uint256 m = 0; m < num; m++){
            // Check that the address in this fixed array is not empty
            if(draw[m] != address(0))
             add = draw[m];
             bets = playerInfo[add].amountBet;

            token.transfer(draw[m], (bets*(devFee))/10000 );

        }
        delete playerInfo[playerAddress]; // Delete all the players
        players.length = 0; // Delete all the players array
        LoserBet = 0; //reinitialize the bets
        WinnerBet = 0;
        totalBetsOne = 0;
        totalBetsTwo = 0;
        game.state == State.Finished;

        }


    
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

     // Allow this agent to call the airdrop functions
    function setAirdropAgent(address _agentAddress, bool state) public onlyOwner {
        Agent[_agentAddress] = state;
    }

    modifier onlyAgent() {
        require(Agent[msg.sender]);
         _;
        
    }
    
}