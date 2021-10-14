/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// File: contracts/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/BetGameID.sol

pragma solidity ^0.5.3;


contract SportsBet {
    using SafeMath for uint256;

    address payable owner;
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
        owner = msg.sender;
        minBet = 1000000000000000;
      
        
    }
    
    function configureOracle(address _oracle) external onlyAdmin{
        oracle = _oracle;  
    }
    
    function kill() public onlyAdmin {
      if(msg.sender == owner) selfdestruct(owner);
    }

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