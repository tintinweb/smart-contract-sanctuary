/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

/*
  _  ___                      __   _   _            _    _ _ _ _ 
 | |/ (_)                    / _| | | | |          | |  | (_) | |
 | ' / _ _ __   __ _    ___ | |_  | |_| |__   ___  | |__| |_| | |
 |  < | | '_ \ / _` |  / _ \|  _| | __| '_ \ / _ \ |  __  | | | |
 | . \| | | | | (_| | | (_) | |   | |_| | | |  __/ | |  | | | | |
 |_|\_\_|_| |_|\__, |  \___/|_|    \__|_| |_|\___| |_|  |_|_|_|_|
                __/ |                                            
               |___/                                             
Don't forget MetaMask!
***************************
HeyHo! 
Who Wants to Become King of the Hill? Everybody wants!
What to get the king of the hill? All the riches!
Become the king of the mountain and claim all the riches saved on this contract! Trust me, it's worth it!
Who will be in charge and take everything, and who will lose? It's up to you to decide. Take action!
*/

pragma solidity ^0.6.12;

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract KingOfTheHill{
    using SafeMath for uint256;

    //It's me
    address payable private _owner;

    //Last income block
    uint256 public lastKingBlock;

    //Current King of Hill
    address payable public currentKing;

    //Current balance
    uint256 public currentBalance = 0;

    //Min participant bid (25 cent)
    uint256 public minBid = 10000000 gwei;

    //Min Bid increase for every bid
    uint public BID_INCREASE = 1500000 gwei;

    //Revenue for me :)
    uint public OWNER_REVENUE_PERCENT = 3;

    //Wait for 6000 block to claim all money on game start
    uint public START_BLOCK_DISTANCE = 50;

    //Wait for 5 blocks in game barely finished
    uint public MIN_BLOCK_DISTANCE = 50;

    //Current block distance
    uint public blockDistance = START_BLOCK_DISTANCE;
    
    uint public NEXT_GAME_REV_PERCENTAGE = 7;
    uint public nextGameBalance;


    //We have a new king! All glory to new king!
    event NewKing(address indexed user, uint256 amount);

    //We have a winner
    event Winner(address indexed user, uint256 amount);

    /**
     * Were we go
     */
    constructor () public payable {
        _owner = msg.sender;
        lastKingBlock = block.number;
    }
    
    function changeMinBid(uint _newMinBid) public {
        require(msg.sender == _owner);
        minBid = _newMinBid;
    }
    function changeBidIncrease(uint _newBidIncrease) public {
        require(msg.sender == _owner);
        BID_INCREASE = _newBidIncrease;
    }
    function changeOwnerRevenue(uint _newRev) public {
        require(msg.sender == _owner);
        OWNER_REVENUE_PERCENT = _newRev;
    }
    function changeNextGameRevPercentage(uint _newNextGameRev) public {
        require(msg.sender == _owner);
        NEXT_GAME_REV_PERCENTAGE = _newNextGameRev;
    }
    function changeStartBlockDistance(uint _newStartBlockDistance) public {
        require(msg.sender == _owner);
        START_BLOCK_DISTANCE = _newStartBlockDistance;
        blockDistance = _newStartBlockDistance;
    }
    function changeMinBlockDistance(uint _newMinBlockDistance) public {
        require(msg.sender == _owner);
        MIN_BLOCK_DISTANCE = _newMinBlockDistance;
    }
    
    /**
     * Place a bid for game
     */
    function placeABid() public payable{
      uint256 income = msg.value;

      require(income >= minBid, "Bid should be greater than min bid");

      //Calculate owner revenue
      uint256 ownerRevenue = income.mul(OWNER_REVENUE_PERCENT).div(100);
      
      uint256 nextGameIncome = income.mul(NEXT_GAME_REV_PERCENTAGE).div(100);
      nextGameBalance = nextGameBalance + nextGameIncome;
      
      //Calculate real income value
      uint256 realIncome = income.sub(ownerRevenue + nextGameIncome);
    //   realIncome = income.sub(nextGameIncome);
        
      //Check is ok
      require(ownerRevenue != 0 && realIncome !=0 && nextGameIncome !=0,"Income too small");


      //Change current contract balance
      currentBalance = currentBalance.add(realIncome);

      //Save all changes
      currentKing = msg.sender;
      lastKingBlock = block.number;

      //Change block distance
      blockDistance = blockDistance - 1;
      if(blockDistance < MIN_BLOCK_DISTANCE){
          blockDistance = MIN_BLOCK_DISTANCE;
      }

      //Change minimal bid
      minBid = minBid.add(BID_INCREASE);


      //Send owner revenue
      _owner.transfer(ownerRevenue);

      //We have a new King!
      emit NewKing(msg.sender, realIncome);
    }

    receive() external payable {
        placeABid();
    }

    /**
     * Claim the revenue
     */
    function claim() public payable {

        //Check King is a king
        require(currentKing == msg.sender, "You are not king");

        //Check balance
        require(currentBalance > 0, "The treasury is empty");

        //Check wait
        require(block.number - lastKingBlock >= blockDistance, "You can pick up the reward only after waiting for the minimum time");


        //Transfer money to winner
        currentKing.transfer(currentBalance);

        //Emit winner event
        emit Winner(msg.sender, currentBalance);

        
        //Reset game
        currentBalance = 0;
        
        if (nextGameBalance > 0) {
            currentBalance = nextGameBalance;
        }
        nextGameBalance = 0;
        currentKing = address(0x0);
        lastKingBlock = block.number;
        blockDistance = START_BLOCK_DISTANCE;
        minBid = 10000000 gwei;
    }

    /**
     * How many blocks remain for claim
     */
    function blocksRemain() public view returns (uint){

        if(block.number - lastKingBlock > blockDistance){
            return 0;
        }

        return blockDistance - (block.number - lastKingBlock);
    }

}