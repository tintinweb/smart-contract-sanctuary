/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract PredictionMarket {
    
    AggregatorV3Interface internal priceFeed;
    
    using SafeMath for uint256;

    uint256 public latestConditionIndex;
    address payable public owner;
    
    mapping (uint256 => ConditionInfo) public conditions;
    mapping (uint256 => mapping (address => UserInfo)) public users;
    
    struct ConditionInfo
    {
        address oracle;
        int triggerPrice;
        uint256 settlementTime;
        uint256 totalBelowETHStaked;
        uint256 totalAboveETHStaked;
        address[] aboveParticipants;
        address[] belowParticipants;
        bool isSettled;
        int settledPrice;
    }
    
    struct UserInfo
    {
        uint256 belowETHStaked;
        uint256 aboveETHStaked;
    }
    
    event ConditionPrepared(
        uint256 indexed conditionIndex,
        address indexed oracle,
        uint256 indexed settlementTime,
        int triggerPrice
    );
    
    event UserPrediction(
        uint256 indexed conditionIndex,
        address indexed userAddress,
        uint256 indexed ETHStaked,
        uint8 prediction,
        uint256 timestamp
    );
    
    event UserClaimed(
        uint256 indexed conditionIndex,
        address indexed userAddress,
        uint256 indexed winningAmount
    );
    
    event ConditionSettled(
        uint256 indexed conditionIndex,
        int indexed settledPrice,
        uint256 timestamp
    );
    
    modifier onlyOwner(){
        require(msg.sender == owner,"Not Owner");
        _;
    }
    
    constructor(address payable _owner) public {
        owner = _owner;
    }
    
    function prepareCondition(address _oracle,uint256 _settlementTime, int _triggerPrice) external onlyOwner{
        require(_oracle != address(0),"Can't be 0 address");
        require(_settlementTime > block.timestamp,"Settlement Time should be greater than Trx Confirmed Time");
        latestConditionIndex = latestConditionIndex.add(1);
        ConditionInfo storage conditionInfo = conditions[latestConditionIndex];

        conditionInfo.oracle = _oracle;
        conditionInfo.settlementTime = _settlementTime;
        conditionInfo.triggerPrice = _triggerPrice;
        conditionInfo.isSettled = false;
        
        emit ConditionPrepared(latestConditionIndex, _oracle, _settlementTime, _triggerPrice);
    }
    
    function probabilityRatio(uint256 _conditionIndex) external view returns(uint256 aboveProbability,uint256 belowProbability){
        ConditionInfo storage conditionInfo = conditions[_conditionIndex];
        
        uint256 ethStakedForAbove = conditionInfo.totalAboveETHStaked;
        uint256 ethStakedForBelow = conditionInfo.totalBelowETHStaked;
        
        uint256 totalETHStaked = ethStakedForAbove.add(ethStakedForBelow);
        
        uint256 aboveProbabilityRatio = totalETHStaked > 0 ? ethStakedForAbove.mul(1e18).div(totalETHStaked) : 0;
        uint256 belowProbabilityRatio = totalETHStaked > 0 ? ethStakedForBelow.mul(1e18).div(totalETHStaked) : 0;
                                                    
        return (aboveProbabilityRatio,belowProbabilityRatio);
    }
    
    function userTotalETHStaked(uint256 _conditionIndex,address userAddress) public view returns(uint256){
        UserInfo storage userInfo = users[_conditionIndex][userAddress];
        return userInfo.aboveETHStaked.add(userInfo.belowETHStaked);
    }
    
    function betOnCondition(uint256 _conditionIndex,uint8 _prediction) public payable{
        ConditionInfo storage conditionInfo = conditions[_conditionIndex];
        require(conditionInfo.oracle !=address(0), "Condition doesn't exists");
        require(block.timestamp < conditionInfo.settlementTime,"Cannot bet after Settlement Time");
        uint256 userETHStaked = msg.value;
        require(userETHStaked > 0 wei, "Bet cannot be 0");
        require((_prediction == 0)||(_prediction == 1),"Invalid Prediction");   //prediction = 0 (price will be below), if 1 (price will be above)

        
        address userAddress = msg.sender;
        UserInfo storage userInfo = users[_conditionIndex][userAddress];
        
        if(_prediction == 0) {
            conditionInfo.belowParticipants.push(userAddress);
            conditionInfo.totalBelowETHStaked = conditionInfo.totalBelowETHStaked.add(userETHStaked);
            userInfo.belowETHStaked = userInfo.belowETHStaked.add(userETHStaked);
        }
        else{
            conditionInfo.aboveParticipants.push(userAddress);
            conditionInfo.totalAboveETHStaked = conditionInfo.totalAboveETHStaked.add(userETHStaked);
            userInfo.aboveETHStaked = userInfo.aboveETHStaked.add(userETHStaked);
        }
        emit UserPrediction(_conditionIndex,userAddress,userETHStaked,_prediction,block.timestamp);
    }
    
    function settleCondition(uint256 _conditionIndex) public {
        ConditionInfo storage conditionInfo = conditions[_conditionIndex];
        require(conditionInfo.oracle !=address(0), "Condition doesn't exists");
        require(block.timestamp >= conditionInfo.settlementTime,"Not before Settlement Time");
        require(!conditionInfo.isSettled,"Condition settled already");
        
        conditionInfo.isSettled = true;
        priceFeed = AggregatorV3Interface(conditionInfo.oracle);
        (,int latestPrice,,,) = priceFeed.latestRoundData();
        conditionInfo.settledPrice = latestPrice;
        emit ConditionSettled(_conditionIndex,latestPrice,block.timestamp);
    }
    
    function claim(uint256 _conditionIndex) public{
        ConditionInfo storage conditionInfo = conditions[_conditionIndex];
        address payable userAddress = msg.sender;
        UserInfo storage userInfo = users[_conditionIndex][userAddress];

        require(userTotalETHStaked(_conditionIndex,userAddress) > 0, "Nothing To Claim");
        
        if(!conditionInfo.isSettled){
            settleCondition(_conditionIndex);
        }
        uint256 totalPayout;    //Payout to be distributed among winners(total eth staked by loosing side)
        uint256 winnersTotalETHStaked;   //total eth staked by the winning side
        uint256 userProportion; //User Stake Proportion among the total ETH Staked by winners
        uint256 winnerPayout;
        uint256 winnerRedeemable;   //User can redeem 90% of there total winnerPayout 
        uint256 platformFees;      // remaining 10% will be treated as platformFees  
        uint256 totalWinnerRedeemable; //Amount Redeemable including winnerRedeemable & user initial Stake
        
        if(conditionInfo.settledPrice >= conditionInfo.triggerPrice){    //Users who predicted above price wins 
            totalPayout = conditionInfo.totalBelowETHStaked;
            winnersTotalETHStaked = conditionInfo.totalAboveETHStaked;
            userProportion = userInfo.aboveETHStaked.mul(1e18).div(winnersTotalETHStaked);
            winnerPayout = totalPayout.mul(userProportion).div(1e18);
            winnerRedeemable = (winnerPayout.div(1000)).mul(900);    
            platformFees = (winnerPayout.div(1000)).mul(100);         
            owner.transfer(platformFees);
            totalWinnerRedeemable = winnerRedeemable.add(userInfo.aboveETHStaked);
            userAddress.transfer(totalWinnerRedeemable);
        }
        
        else if(conditionInfo.settledPrice < conditionInfo.triggerPrice){      //Users who predicted below price wins
            totalPayout = conditionInfo.totalAboveETHStaked;
            winnersTotalETHStaked = conditionInfo.totalBelowETHStaked;
            userProportion = userInfo.belowETHStaked.mul(1e18).div(winnersTotalETHStaked);
            winnerPayout = totalPayout.mul(userProportion).div(1e18);
            winnerRedeemable = (winnerPayout.div(1000)).mul(900);     
            platformFees = (winnerPayout.div(1000)).mul(100);        
            owner.transfer(platformFees);
            totalWinnerRedeemable = winnerRedeemable.add(userInfo.belowETHStaked);
            userAddress.transfer(totalWinnerRedeemable);
        }
        emit UserClaimed(_conditionIndex,userAddress,winnerPayout);
    }
}