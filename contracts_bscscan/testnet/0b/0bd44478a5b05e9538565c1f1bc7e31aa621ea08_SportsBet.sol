/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

pragma solidity >=0.5.3;

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

contract SportsBet {
    using SafeMath for uint256;

    address owner = msg.sender;
    uint minBet;
    
    uint256 totalBetsOne;
    uint256 totalBetsTwo;

    
    address public oracle;
    
    enum PlayerStatus {Not_Joined, Joined, Ended}
    enum State {Not_Created, Created, Joined, Finished}
    
    struct Game {
    uint betId;  
    State state;
    
    }
    
    struct Player {
    address payable players;
    uint256 amountBet;
    uint16 team;
    uint odds;
    PlayerStatus _state;
    }
    
    uint public gameId;
    
    mapping(address => Player) public playerInfo;
    mapping(uint => Game) public gameInfo;
    
    event BetPlayer(address indexed _from, uint256 _amount, uint player);
    
    constructor() public {
    
        minBet = 1000000000000000000;
      
        
    }
    
    // function configureOracle(address _oracle) external onlyAdmin{
    //     oracle = _oracle;  
    // }
    
    // function kill() public onlyAdmin {
    //   if(msg.sender == owner) selfdestruct(owner);
    // }

    function newGame() external  onlyAdmin {
        
        gameInfo[gameId] = Game(gameId, State.Created);
        gameId++;
        
    }
    
    //users can make a bet on team 1 or team 2. 
    function makeBet(uint _gameId, uint8 _team, uint _odds) external payable {
        
        Game storage game = gameInfo[_gameId];
        require(game.state == State.Created,"Game has not been created");
        require(playerInfo[msg.sender]._state == PlayerStatus.Not_Joined, "You have already placed a bet");
        require(msg.value >= minBet, "Not enough sent to bet");
        
        //Player will make a bet and select team 
        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].team = _team;
        playerInfo[msg.sender].odds = _odds;
        
        if(_team == 1){
            totalBetsOne += msg.value;
        }
        else{
            totalBetsTwo += msg.value;
        }
         
        playerInfo[msg.sender]._state = PlayerStatus.Joined;
        emit BetPlayer(msg.sender, msg.value, _team);
        
    }

    
   function pay(uint _gameId, uint _winner) public onlyAdmin {
        Game storage game = gameInfo[_gameId];
        
        address payable[100] memory winners;
        uint256 count = 0;
        uint256 loserBet = 0;
        uint256 winnerBet = 0;
        address add;
   //     uint256 playerOdds;
        uint256 betPlaced;
        address payable playerAddress;
        
        //loop through players to see who selected winning team
        for(uint256 i = 0; i < winners.length; i++){
            playerAddress = winners[i];
            
        //players who selected winning team     
        if(playerInfo[playerAddress].team == _winner){
        winners[count] = playerAddress;
        count++;
        }
        
            
        }
       
       if ( _winner == 1) {
           loserBet = totalBetsTwo;
           winnerBet = totalBetsOne;
       }else{
           loserBet = totalBetsTwo;
           winnerBet = totalBetsOne;
       }
       
       for(uint256 j = 0; j < count; j++){
       if(winners[j] != address(0))
       add = winners[j];
       betPlaced = playerInfo[add].amountBet;
   //    playerOdds = playerInfo[add].odds;
       winners[j].transfer((betPlaced*(10000+(loserBet*10000/winnerBet)))/10000);
       
       }
       //reset data
       delete playerInfo[playerAddress];
       loserBet = 0;
       winnerBet = 0;
       totalBetsOne = 0;
       totalBetsTwo = 0;
       
       game.state == State.Finished;
        
    
    }
   
 
    function teamOne() public view returns(uint256) {
        return totalBetsOne;
    }
    
    function teamTwo() public view returns(uint256) {
        return totalBetsTwo;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == owner);
        _;
    }
}