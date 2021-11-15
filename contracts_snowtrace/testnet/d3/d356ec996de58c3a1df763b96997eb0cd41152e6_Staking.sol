/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-10
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
 * @title IToken
 * @dev   Contract interface for token contract 
 */
contract IToken {
    function balanceOf(address) public pure returns (uint256);
    function allowance(address, address) public pure returns (uint256);
    function transfer(address, uint256) public pure returns (bool);
    function transferFrom(address, address, uint256) public pure returns (bool);
    function approve(address , uint256) public pure returns (bool);
 }

/**
 * @title Staking
 * @dev   Staking Contract for Native token staking
 */
contract Staking {
    
  using SafeMath for uint256;
  address private _owner;                                           // variable for Owner of the Contract.
  uint256 private _withdrawTime;                                    // variable to manage withdraw time for Native Token
  uint256 constant public PERIOD_SILVER            = 30;            // variable constant for time period managemnt
  uint256 constant public PERIOD_GOLD              = 60;            // variable constant for time period managemnt
  uint256 constant public PERIOD_PLATINUM          = 90;            // variable constant for time period managemnt
  uint256 constant public REWARD_PERCENT_SILVER      = 1332;    // variable constant to manage eward percentage for silver
  uint256 constant public REWARD_PERCENT_GOLD        = 3203;    // variable constant to manage reward percentage for gold
  uint256 constant public REWARD_PERCENT_PLATINUM    = 5347;    // variable constant to manage reward percentage for platinum
  
  // events to handle staking pause or unpause for Native token
  event Paused();
  event Unpaused();
  
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
  constructor(address owner) public {
     _owner = owner;
  }
  
  // Interface declaration for contract
  IToken itoken;
    
  // function to set Contract Address for Token Transfer Functions
  function setContractAddress(address tokenContractAddress) external onlyOwner returns(bool){
    itoken = IToken(tokenContractAddress);
    return true;
  }
  
   /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Owner functions of get value, set value and other Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // function to add reward in contract
  function addReward() external payable onlyOwner returns(bool){
    _ownerAllowance = _ownerAllowance.add(msg.value);
    return true;
  }
  
  // function to withdraw added eward in contract
  function withdrawAddedReward(uint256 amount) external onlyOwner returns(bool){
    require(amount < _ownerAllowance, "Value is not feasible, Please Try Again!!!");
    _ownerAllowance = _ownerAllowance.sub(amount);
    msg.sender.transfer(_ownerAllowance);
    return true;
  }
  
  // function to get reward in contract
  function getReward() public view returns(uint256){
    return _ownerAllowance;
  }
  
  
  // function to pause staking
  function pauseStaking() public onlyOwner {
    stakingPaused = true;
    emit Paused();
  }

  // function to unpause Staking
  function unpauseStaking() public onlyOwner {
    stakingPaused = false;
    emit Unpaused();
  }
  
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Variable, Mapping for Native Token Staking Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // mapping for users with id => address Staking Address
  mapping (uint256 => address) private _stakingAddress;
  
  // mapping for user with address => id staking id
  mapping (address => uint256[]) private _stakingId;
  
  // mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _stakingStartTime;

  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _stakingEndTime;

  // mapping for users with id => Amount to keep track for amount of staked native token by user 
  mapping (uint256 => uint256) private _usersAmount;
  
  // mapping for users with id => Status
  mapping (uint256 => bool) private _transactionstatus; 
  
  // mapping to keep track of final withdraw value of staked native token
  mapping(uint256=>uint256) private _finalStakeWithdraw;
  
  // mapping to keep track total number of staking days
  mapping(uint256=>uint256) private _totalDays;

  // mapping for Native token deposited by user 
  mapping(address=>uint256) private _amountStakedByUser;
  
  // variable to keep count of native token Staking
  uint256 private _stakingCount = 0;
  
  // variable to keep track on native token reward added by owner
  uint256 private _ownerAllowance = 0;

  // variable for native token time management
  uint256 private _time;

  // variable for native token staking pause and unpause mechanism
  bool public stakingPaused = false;
  
  // variable for total staked native token by user
  uint256 public totalStakedAmount = 0;
  
  // variable for total staked native token in contract
  uint256 public totalStakesInContract = 0;
  
  // modifier to check time and input value for Staking 
  modifier stakeCheck(uint256 timePeriod){
    require(msg.value > 0, "Invalid Amount, Please Try Again!!! ");
    require(timePeriod == PERIOD_SILVER || timePeriod == PERIOD_GOLD || timePeriod == PERIOD_PLATINUM, "Enter the Valid Time Period and Try Again !!!");
    _;
  }

   /*
  * -----------------------------------------------------------------------------------------------------------------------------------
  * Functions for Native Token Staking Functionality
  * -----------------------------------------------------------------------------------------------------------------------------------
  */
 
  // function to performs staking for user native token for a specific period of time
  function stakeNativeToken(uint256 time) external payable stakeCheck(time) returns(bool){
    require(stakingPaused == false, "Staking is Paused, Please try after staking get unpaused!!!");
    _time = now + (time);
    _stakingCount = _stakingCount + 1 ;
    _totalDays[_stakingCount] = time;
    _stakingAddress[_stakingCount] = msg.sender;
    _stakingId[msg.sender].push(_stakingCount);
    _stakingEndTime[_stakingCount] = _time;
    _stakingStartTime[_stakingCount] = now;
    _usersAmount[_stakingCount] = msg.value;
    _amountStakedByUser[msg.sender] = _amountStakedByUser[msg.sender].add(msg.value);
    _transactionstatus[_stakingCount] = false;
    totalStakesInContract = totalStakesInContract.add(msg.value);
    totalStakedAmount = totalStakedAmount.add(msg.value);
    return true;
  }

  // function to get staking count for native token
  function getStakingCount() public view returns(uint256){
    return _stakingCount;
  }
  
  // function to get total Staked native token
  function getTotalStakedAmount() public view returns(uint256){
    return totalStakedAmount;
  }
  
  // function to calculate reward for the message sender for stake
  function getRewardDetailsByStakingId(uint256 id) public view returns(uint256){
    if(_totalDays[id] == PERIOD_SILVER) {
        return (_usersAmount[id]*REWARD_PERCENT_SILVER/100000);
    } else if(_totalDays[id] == PERIOD_GOLD) {
               return (_usersAmount[id]*REWARD_PERCENT_GOLD/100000);
      } else if(_totalDays[id] == PERIOD_PLATINUM) { 
                 return (_usersAmount[id]*REWARD_PERCENT_PLATINUM/100000);
        } else{
              return 0;
          }
  }
  
  // function for withdrawing staked Native Token
  function withdrawStakedNativeToken(uint256 stakingId) public returns(bool){
    require(_stakingAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_transactionstatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
      if(_totalDays[stakingId] == PERIOD_SILVER){
            require(now >= _stakingStartTime[stakingId], "Unable to Withdraw Stake amount before staking start time, Please Try Again Later!!!");
            _transactionstatus[stakingId] = true;
            if(now >= _stakingEndTime[stakingId]){
                _finalStakeWithdraw[stakingId] = _usersAmount[stakingId].add(getRewardDetailsByStakingId(stakingId));
                _stakingAddress[stakingId].transfer(_usersAmount[stakingId]);
                itoken.transfer(msg.sender, getRewardDetailsByStakingId(stakingId));
                totalStakesInContract = totalStakesInContract.sub(_usersAmount[stakingId]);
            } else {
                _finalStakeWithdraw[stakingId] = _usersAmount[stakingId];
                _stakingAddress[stakingId].transfer(_finalStakeWithdraw[stakingId]);
                totalStakesInContract = totalStakesInContract.sub(_usersAmount[stakingId]);
              }
      } else if(_totalDays[stakingId] == PERIOD_GOLD){
           require(now >= _stakingStartTime[stakingId], "Unable to Withdraw Stake amount before staking start time, Please Try Again Later!!!");
           _transactionstatus[stakingId] = true;
            if(now >= _stakingEndTime[stakingId]){
                _finalStakeWithdraw[stakingId] = _usersAmount[stakingId].add(getRewardDetailsByStakingId(stakingId));
                _stakingAddress[stakingId].transfer(_usersAmount[stakingId]);
                itoken.transfer(msg.sender, getRewardDetailsByStakingId(stakingId));
                totalStakesInContract = totalStakesInContract.sub(_usersAmount[stakingId]);
            } else {
                _finalStakeWithdraw[stakingId] = _usersAmount[stakingId];
                _stakingAddress[stakingId].transfer(_finalStakeWithdraw[stakingId]);
                totalStakesInContract = totalStakesInContract.sub(_usersAmount[stakingId]);
              }
      } else if(_totalDays[stakingId] == PERIOD_PLATINUM){
           require(now >= _stakingStartTime[stakingId], "Unable to Withdraw Stake amount before staking start time, Please Try Again Later!!!");
           _transactionstatus[stakingId] = true;
           if(now >= _stakingEndTime[stakingId]){
                _finalStakeWithdraw[stakingId] = _usersAmount[stakingId].add(getRewardDetailsByStakingId(stakingId));
                _stakingAddress[stakingId].transfer(_usersAmount[stakingId]);
                itoken.transfer(msg.sender, getRewardDetailsByStakingId(stakingId));
                totalStakesInContract = totalStakesInContract.sub(_usersAmount[stakingId]);
            } else {
                _finalStakeWithdraw[stakingId] = _usersAmount[stakingId];
                _stakingAddress[stakingId].transfer(_finalStakeWithdraw[stakingId]);
                totalStakesInContract = totalStakesInContract.sub(_usersAmount[stakingId]);
              }
      } else {
          return false;
        }
    return true;
  }
  
  // function to get Final Withdraw Staked value for native token
  function getFinalStakeWithdraw(uint256 id) public view returns(uint256){
    return _finalStakeWithdraw[id];
  }
  
  // function to get total native token stake in contract
  function getTotalStakesInContract() public view returns(uint256){
      return totalStakesInContract;
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------
  * Get Functions for Stake Native Token Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------
  */

  // function to get Staking address by id
  function getStakingAddressById(uint256 id) external view returns (address){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakingAddress[id];
  }
  
  // function to get Staking id by address
  function getStakingIdByAddress(address add) external view returns(uint256[]){
    require(add != address(0),"Invalid Address, Pleae Try Again!!!");
    return _stakingId[add];
  }
  
  // function to get Staking Starting time by id
  function getStakingStartTimeById(uint256 id) external view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakingStartTime[id];
  }
  
  // function to get Staking End time by id
  function getStakingEndTimeById(uint256 id) external view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakingEndTime[id];
  }
  
  // function to get Staking Total Days by Id
  function getStakingTotalDaysById(uint256 id) external view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _totalDays[id];
  }
  
  // function to get Staked Native token by id
  function getStakedNativeTokenById(uint256 id) external view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersAmount[id];
  }

  // function to get Staked Native token by address
  function getStakedByUser(address add) external view returns(uint256){
    require(add != address(0),"Invalid Address, Please try again!!");
    return _amountStakedByUser[add];
  }

  // function to get lockstatus by id
  function getLockStatus(uint256 id) external view returns(bool){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _transactionstatus[id];
  }

}