/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Calculation error");
        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Calculation error");
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        require(b <= a,"Calculation error");
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a,"Calculation error");
        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b != 0,"Calculation error");
        return a % b;
    }
}

/**
 * @title IStaking
 * @dev   Contract interface for Staking contract 
 */
interface IStaking {
    function getTokenStakingAddressById(uint256) external view returns(address);
    function getTokenStakingIdByAddress(address) external view returns(uint256);
    function getTokenStakingStartTimeById(uint256) external view returns(uint256);
    function getTokenStakingEndTimeById(uint256) external view returns(uint256);
    function getTokenStakingTotalDaysById(uint256) external view returns(uint256);
    function getStakingTokenById(uint256) external view returns(uint256);
    function getTokenLockStatus(uint256) external view returns(bool);
    function getTokenRewardDetailsByStakingId(uint256) external view returns(uint256);
    function getTokenPenaltyDetailByStakingId(uint256) external view returns(uint256);
    function getTotalTokenStakesInContract(uint256) external view returns(uint256);
    function getFinalTokenStakeWithdraw(uint256) external view returns(uint256);


    function withdrawStakedTokens(uint256 stakingId) external returns(bool);
    function balanceOf(address) external pure returns (uint256);
    function transfer(address, uint256) external pure returns (bool);
    function transferFrom(address, address, uint256) external pure returns (bool);
 }
 
 /**
 * @title ICliq
 * @dev   Contract interface for token contract 
 */
contract ICliq {
    function name() public pure returns (string memory);
    function symbol() public pure returns (string memory);
    function decimals() public pure returns (uint8);
    function totalSupply() public pure returns (uint256);
    function balanceOf(address) public pure returns (uint256);
    function allowance(address, address) public pure returns (uint256);
    function transfer(address, uint256) public pure returns (bool);
    function transferFrom(address, address, uint256) public pure returns (bool);
    function approve(address , uint256) public pure returns (bool);
    function burn(uint256) public pure;
    function mint(uint256) public pure returns(bool);
    function getContractBNBBalance() public pure returns(uint256);
 }
 
 
 contract withdraw {
       
       using SafeMath for uint256;

     
     address private _owner;                                           // variable for Owner of the Contract.
  uint256 constant public PERIOD_SILVER            = 30;            // variable constant for time period managemnt
  uint256 constant public PERIOD_GOLD              = 60;            // variable constant for time period managemnt
  uint256 constant public PERIOD_PLATINUM          = 90;            // variable constant for time period managemnt
  uint256 constant public WITHDRAW_TIME_SILVER     = 15;   // variable constant to manage withdraw time lock up 
  uint256 constant public WITHDRAW_TIME_GOLD       = 30 * 1 days;   // variable constant to manage withdraw time lock up
  uint256 constant public WITHDRAW_TIME_PLATINUM   = 45 * 1 days;   // variable constant to manage withdraw time lock up

 /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functions for owner.
  * ---------------------------------------------------------------------------------------------------------------------------
  */

   /**
   * @dev get address of smart contract owner
   * @return address of owner
   */
   function getowner() public view returns (address) {
     return _owner;
   }

   /**
   * @dev modifier to check if the message sender is owner
   */
   modifier onlyOwner() {
     require(isOwner(),"You are not authenticate to make this transfer");
     _;
   }

   /**
   * @dev Internal function for modifier
   */
   function isOwner() internal view returns (bool) {
      return msg.sender == _owner;
   }

   /**
   * @dev Transfer ownership of the smart contract. For owner only
   * @return request status
   */
   function transferOwnership(address newOwner) public onlyOwner returns (bool){
      _owner = newOwner;
      return true;
   }
   
  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functionality of Constructor and Interface  
  * ---------------------------------------------------------------------------------------------------------------------------
  */
  
  // constructor to declare owner of the contract during time of deploy  
  constructor() public {
     _owner = msg.sender;
  }
  
  // Interface declaration for contract
  IStaking istaking;
    
    
  ICliq icliq;
  
  // function to set Staking Contract Address
  function setStakingContractAddress(address stakingContractAddress) external onlyOwner returns(bool){
    istaking = IStaking(stakingContractAddress);
    return true;
  }
  
  // function to set Contract Address for Token Transfer Functions
  function setTokenContractAddress(address tokenContractAddress) external onlyOwner returns(bool){
    icliq = ICliq(tokenContractAddress);
    return true;
  }
  
function withdrawStakedToken(uint256 stakingId) public returns(bool) {
//    function getStakingTokenById() external view returns(uint256);
    
    
    address stakingAddress = istaking.getTokenStakingAddressById(stakingId);
    uint256 totalDays = istaking.getTokenStakingTotalDaysById(stakingId);
    uint256 tokenStartTime = istaking.getTokenStakingStartTimeById(stakingId);
    uint256 tokenEndTime = istaking.getTokenStakingEndTimeById(stakingId);
    uint256 userToken = istaking.getStakingTokenById(stakingId);
    uint256 tokenReward = istaking.getTokenRewardDetailsByStakingId(stakingId);
    uint256 tokenPenalty = istaking.getTokenPenaltyDetailByStakingId(stakingId);
    uint256 totalStakedToken = istaking.getTotalTokenStakesInContract(stakingId);
    uint256 finalTokenStakeWithdraw = istaking.getFinalTokenStakeWithdraw(stakingId);
    bool transactionStatus = istaking.getTokenLockStatus(stakingId);
    
    require(stakingAddress == msg.sender,"No staked token found on this address and ID");
    require(transactionStatus != true,"Either tokens are already withdrawn or blocked by admin");
    if(totalDays == PERIOD_SILVER){
          require(now >= tokenStartTime + WITHDRAW_TIME_SILVER, "Unable to Withdraw Staked token before 15 days of staking start time, Please Try Again Later!!!");
          transactionStatus = true;
          if(now >= tokenEndTime){
              finalTokenStakeWithdraw = userToken.add(tokenReward);
              icliq.transfer(msg.sender,finalTokenStakeWithdraw);
              totalStakedToken = totalStakedToken.sub(userToken);
          } else {
              finalTokenStakeWithdraw = userToken.add(tokenPenalty);
              icliq.transfer(msg.sender,finalTokenStakeWithdraw);
              totalStakedToken = totalStakedToken.sub(userToken);
            }
    } else if(totalDays == PERIOD_GOLD){
          require(now >= tokenStartTime + WITHDRAW_TIME_GOLD, "Unable to Withdraw Staked token before 30 days of staking start time, Please Try Again Later!!!");
          transactionStatus = true;
          if(now >= tokenEndTime){
              finalTokenStakeWithdraw = userToken.add(tokenReward);
              icliq.transfer(msg.sender,finalTokenStakeWithdraw);
              totalStakedToken = totalStakedToken.sub(userToken);
          } else {
              finalTokenStakeWithdraw = userToken.add(tokenPenalty);
              icliq.transfer(msg.sender,finalTokenStakeWithdraw);
              totalStakedToken = totalStakedToken.sub(userToken);
            }
    } else if(totalDays == PERIOD_PLATINUM){
          require(now >= tokenStartTime + WITHDRAW_TIME_PLATINUM, "Unable to Withdraw Staked token before 45 days of staking start time, Please Try Again Later!!!");
          transactionStatus = true;
          if(now >= tokenEndTime){
              finalTokenStakeWithdraw = userToken.add(tokenReward);
              icliq.transfer(msg.sender, finalTokenStakeWithdraw);
              totalStakedToken = totalStakedToken.sub(userToken);
          } else {
              finalTokenStakeWithdraw = userToken.add(tokenPenalty);
              icliq.transfer(msg.sender,finalTokenStakeWithdraw);
              totalStakedToken = totalStakedToken.sub(userToken);
            }
    } else {
        return false;
      }
    return true;
  }  
     
 }