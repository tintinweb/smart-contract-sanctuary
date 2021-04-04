/**
 *Submitted for verification at Etherscan.io on 2021-04-04
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

/**
 * @title Staking
 * @dev   Staking Contract 
 */
contract Staking {
    
  using SafeMath for uint256;
  address private _owner;                                           // variable for Owner of the Contract.
  uint256 private _withdrawTime;                                    // variable to manage withdraw time for BNB and Token
  uint256 constant public PERIOD_SILVER            = 30;            // variable constant for time period managemnt
  uint256 constant public PERIOD_GOLD              = 60;            // variable constant for time period managemnt
  uint256 constant public PERIOD_PLATINUM          = 90;            // variable constant for time period managemnt
  uint256 constant public WITHDRAW_TIME_SILVER     = 15 * 1 days;   // variable constant to manage withdraw time lock up 
  uint256 constant public WITHDRAW_TIME_GOLD       = 30 * 1 days;   // variable constant to manage withdraw time lock up
  uint256 constant public WITHDRAW_TIME_PLATINUM   = 45 * 1 days;   // variable constant to manage withdraw time lock up
  uint256 constant public BNB_REWARD_PERCENT_SILVER      = 1721;    // variable constant to manage BNB reward percentage for silver
  uint256 constant public BNB_REWARD_PERCENT_GOLD        = 2083;    // variable constant to manage BNB reward percentage for gold
  uint256 constant public BNB_REWARD_PERCENT_PLATINUM    = 2317;    // variable constant to manage BNB reward percentage for platinum
  uint256 constant public BNB_PENALTY_PERCENT_SILVER     = 1032;    // variable constant to manage BNB penalty percentage for silver
  uint256 constant public BNB_PENALTY_PERCENT_GOLD       = 1249;    // variable constant to manage BNB penalty percentage for silver
  uint256 constant public BNB_PENALTY_PERCENT_PLATINUM   = 1390;    // variable constant to manage BNB penalty percentage for silver
  uint256 constant public TOKEN_REWARD_PERCENT_SILVER    = 10;      // variable constant to manage token reward percentage for silver
  uint256 constant public TOKEN_REWARD_PERCENT_GOLD      = 20;      // variable constant to manage token reward percentage for gold
  uint256 constant public TOKEN_REWARD_PERCENT_PLATINUM  = 30;      // variable constant to manage token reward percentage for platinum
  uint256 constant public TOKEN_PENALTY_PERCENT_SILVER   = 3;       // variable constant to manage token penalty percentage for silver
  uint256 constant public TOKEN_PENALTY_PERCENT_GOLD     = 6;       // variable constant to manage token penalty percentage for silver
  uint256 constant public TOKEN_PENALTY_PERCENT_PLATINUM = 9;       // variable constant to manage token penalty percentage for silver
  
  
   
  // events to handle staking pause or unpause for token and BNB
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
  ICliq icliq;
    
  // function to set Contract Address for Token Transfer Functions
  function setContractAddress(address CliqToken) external onlyOwner returns(bool){
    icliq = ICliq(CliqToken);
    return true;
  }
  
   /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Owner functions of get value, set value and other Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // function to add token reward in contract
  function addTokenReward(uint256 token) external onlyOwner returns(bool){
    _ownerTokenAllowance = _ownerTokenAllowance.add(token);
    icliq.transferFrom(msg.sender, address(this), _ownerTokenAllowance);
    return true;
  }
  
  // function to withdraw added token reward in contract
  function withdrawAddedTokenReward(uint256 token) external onlyOwner returns(bool){
    require(token < _ownerTokenAllowance,"Value is not feasible, Please Try Again!!!");
    _ownerTokenAllowance = _ownerTokenAllowance.sub(token);
    icliq.transferFrom(address(this), msg.sender, _ownerTokenAllowance);
    return true;
  }
  
  // function to get token reward in contract
  function getTokenReward() public view returns(uint256){
    return _ownerTokenAllowance;
  }
  
  // function to add BNB reward in contract
  function addBNBReward() external payable onlyOwner returns(bool){
    _ownerBNBAllowance = _ownerBNBAllowance.add(msg.value);
    return true;
  }
  
  // function to withdraw added BNB reward in contract
  function withdrawAddedBNBReward(uint256 amount) external onlyOwner returns(bool){
    require(amount < _ownerBNBAllowance, "Value is not feasible, Please Try Again!!!");
    _ownerBNBAllowance = _ownerBNBAllowance.sub(amount);
    msg.sender.transfer(_ownerBNBAllowance);
    return true;
  }
  
  // function to get BNB reward in contract
  function getBNBReward() public view returns(uint256){
    return _ownerBNBAllowance;
  }
  
  // function to set BNB limit per user by owner
  function setBNBLimit(uint256 bnb) external onlyOwner returns(bool){
    require(bnb != 0, "Zero Amount not Supported, Please Try Again!!!");
    _bnbLimit = bnb;
    return true;
  }
  
  // function to get BNB limit set by owner
  function getBNBLimit() public view returns(uint256){
    return _bnbLimit;
  }
  
  // function to pause Token Staking
  function pauseTokenStaking() public onlyOwner {
    tokenPaused = true;
    emit Paused();
  }

  // function to unpause Token Staking
  function unpauseTokenStaking() public onlyOwner {
    tokenPaused = false;
    emit Unpaused();
  }
  
  // function to pause BNB Staking
  function pauseBNBStaking() public onlyOwner {
    BNBPaused = true;
    emit Paused();
  }

  // function to unpause BNB Staking
  function unpauseBNBStaking() public onlyOwner {
    BNBPaused = false;
    emit Unpaused();
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Variable, Mapping for Token Staking Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // mapping for users with id => address Staking Address
  mapping (uint256 => address) private _tokenStakingAddress;
  
  // mapping for users with address => id staking id
  mapping (address => uint256[]) private _tokenStakingId;

  // mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _tokenStakingStartTime;
  
  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _tokenStakingEndTime;

  // mapping for users with id => Tokens 
  mapping (uint256 => uint256) private _usersTokens;
  
  // mapping for users with id => Status
  mapping (uint256 => bool) private _TokenTransactionstatus;    
  
  // mapping to keep track of final withdraw value of staked token
  mapping(uint256=>uint256) private _finalTokenStakeWithdraw;
  
  // mapping to keep track total number of staking days
  mapping(uint256=>uint256) private _tokenTotalDays;
  
  // variable to keep count of Token Staking
  uint256 private _tokenStakingCount = 0;
  
  // variable to keep track on reward added by owner
  uint256 private _ownerTokenAllowance = 0;

  // variable for token time management
  uint256 private _tokentime;
  
  // variable for token staking pause and unpause mechanism
  bool public tokenPaused = false;
  
  // variable for total Token staked by user
  uint256 public totalStakedToken = 0;
  
  // variable for total stake token in contract
  uint256 public totalTokenStakesInContract = 0;
  
  // modifier to check the user for staking || Re-enterance Guard
  modifier tokenStakeCheck(uint256 tokens, uint256 timePeriod){
    require(tokens > 0, "Invalid Token Amount, Please Try Again!!! ");
    require(timePeriod == PERIOD_SILVER || timePeriod == PERIOD_GOLD || timePeriod == PERIOD_PLATINUM, "Enter the Valid Time Period and Try Again !!!");
    _;
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Variable, Mapping for BNB Staking Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // mapping for users with id => address Staking Address
  mapping (uint256 => address) private _bnbStakingAddress;
  
  // mapping for user with address => id staking id
  mapping (address => uint256[]) private _bnbStakingId;
  
  // mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _bnbStakingStartTime;

  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _bnbStakingEndTime;

  // mapping for users with id => BNB
  mapping (uint256 => uint256) private _usersBNB;
  
  // mapping for users with id => Status
  mapping (uint256 => bool) private _bnbTransactionstatus; 
  
  // mapping to keep track of final withdraw value of staked BNB
  mapping(uint256=>uint256) private _finalBNBStakeWithdraw;
  
  // mapping to keep track total number of staking days
  mapping(uint256=>uint256) private _bnbTotalDays;

  // mapping for BNB deposited by user 
  mapping(address=>uint256) private _bnbStakedByUser;
  
  // variable to keep count of BNB Staking
  uint256 private _bnbStakingCount = 0;
  
  // variable to keep track on BNB reward added by owner
  uint256 private _ownerBNBAllowance = 0;
  
  // variable to set BNB limit by owner
  uint256 private _bnbLimit = 0;

  // variable for BNB time management
  uint256 private _bnbTime;

  // variable for BNB staking pause and unpause mechanism
  bool public BNBPaused = false;
  
  // variable for total BNB staked by user
  uint256 public totalStakedBNB = 0;
  
  // variable for total stake BNB in contract
  uint256 public totalBNBStakesInContract = 0;
  
  // modifier to check time and input value for BNB Staking 
  modifier BNBStakeCheck(uint256 timePeriod){
    require(msg.value > 0, "Invalid Amount, Please Try Again!!! ");
    require(timePeriod == PERIOD_SILVER || timePeriod == PERIOD_GOLD || timePeriod == PERIOD_PLATINUM, "Enter the Valid Time Period and Try Again !!!");
    _;
  }
    
  /*
  * ------------------------------------------------------------------------------------------------------------------------------
  * Functions for Token Staking Functionality
  * ------------------------------------------------------------------------------------------------------------------------------
  */

  // function to performs staking for user tokens for a specific period of time
  function stakeToken(uint256 tokens, uint256 time) public tokenStakeCheck(tokens, time) returns(bool){
    require(tokenPaused == false, "Staking is Paused, Please try after staking get unpaused!!!");
    _tokentime = now + (time * 1 days);
    _tokenStakingCount = _tokenStakingCount +1;
    _tokenTotalDays[_tokenStakingCount] = time;
    _tokenStakingAddress[_tokenStakingCount] = msg.sender;
    _tokenStakingId[msg.sender].push(_tokenStakingCount);
    _tokenStakingEndTime[_tokenStakingCount] = _tokentime;
    _tokenStakingStartTime[_tokenStakingCount] = now;
    _usersTokens[_tokenStakingCount] = tokens;
    _TokenTransactionstatus[_tokenStakingCount] = false;
    _tokenStakingCount = _tokenStakingCount +1;
    totalStakedToken = totalStakedToken.add(tokens);
    totalTokenStakesInContract = totalTokenStakesInContract.add(tokens);
    icliq.transferFrom(msg.sender, address(this), tokens);
    return true;
  }

  // function to get staking count for token
  function getTokenStakingCount() public view returns(uint256){
    return _tokenStakingCount;
  }
  
  // function to get total Staked tokens
  function getTotalStakedToken() public view returns(uint256){
    return totalStakedToken;
  }
  
  // function to calculate reward for the message sender for token
  function getTokenRewardDetailsByStakingId(uint256 id) public view returns(uint256){
    if(_tokenTotalDays[id] == PERIOD_SILVER) {
        return (_usersTokens[id]*TOKEN_REWARD_PERCENT_SILVER/100);
    } else if(_tokenTotalDays[id] == PERIOD_GOLD) {
               return (_usersTokens[id]*TOKEN_REWARD_PERCENT_GOLD/100);
      } else if(_tokenTotalDays[id] == PERIOD_PLATINUM) { 
                 return (_usersTokens[id]*TOKEN_REWARD_PERCENT_PLATINUM/100);
        } else{
              return 0;
          }
  }

  // function to calculate penalty for the message sender for token
  function getTokenPenaltyDetailByStakingId(uint256 id) public view returns(uint256){
    if(_tokenStakingEndTime[id] > now){
        if(_tokenTotalDays[id]==PERIOD_SILVER){
            return (_usersTokens[id]*TOKEN_PENALTY_PERCENT_SILVER/100);
        } else if(_tokenTotalDays[id] == PERIOD_GOLD) {
              return (_usersTokens[id]*TOKEN_PENALTY_PERCENT_GOLD/100);
          } else if(_tokenTotalDays[id] == PERIOD_PLATINUM) { 
                return (_usersTokens[id]*TOKEN_PENALTY_PERCENT_PLATINUM/100);
            } else {
                return 0;
              }
    } else{
       return 0;
     }
  }
 
  // function for withdrawing staked tokens
  function withdrawStakedTokens(uint256 stakingId) public returns(bool) {
    require(_tokenStakingAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_TokenTransactionstatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    if(_tokenTotalDays[stakingId] == PERIOD_SILVER){
          require(now >= _tokenStakingStartTime[stakingId] + WITHDRAW_TIME_SILVER, "Unable to Withdraw Staked token before 15 days of staking start time, Please Try Again Later!!!");
          _TokenTransactionstatus[stakingId] = true;
          if(now >= _tokenStakingEndTime[stakingId]){
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenRewardDetailsByStakingId(stakingId));
              icliq.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
          } else {
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenPenaltyDetailByStakingId(stakingId));
              icliq.transferFrom(address(this), msg.sender,_usersTokens[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
            }
    } else if(_tokenTotalDays[stakingId] == PERIOD_GOLD){
          require(now >= _tokenStakingStartTime[stakingId] + WITHDRAW_TIME_GOLD, "Unable to Withdraw Staked token before 30 days of staking start time, Please Try Again Later!!!");
          _TokenTransactionstatus[stakingId] = true;
          if(now >= _tokenStakingEndTime[stakingId]){
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenRewardDetailsByStakingId(stakingId));
              icliq.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
          } else {
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenPenaltyDetailByStakingId(stakingId));
              icliq.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
            }
    } else if(_tokenTotalDays[stakingId] == PERIOD_PLATINUM){
          require(now >= _tokenStakingStartTime[stakingId] + WITHDRAW_TIME_PLATINUM, "Unable to Withdraw Staked token before 45 days of staking start time, Please Try Again Later!!!");
          _TokenTransactionstatus[stakingId] = true;
          if(now >= _tokenStakingEndTime[stakingId]){
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenRewardDetailsByStakingId(stakingId));
              icliq.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
          } else {
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenPenaltyDetailByStakingId(stakingId));
              icliq.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
            }
    } else {
        return false;
      }
    return true;
  }
  
  // function to get Final Withdraw Staked value for token
  function getFinalTokenStakeWithdraw(uint256 id) public view returns(uint256){
    return _finalTokenStakeWithdraw[id];
  }
  
  // function to get total token stake in contract
  function getTotalTokenStakesInContract() public view returns(uint256){
      return totalTokenStakesInContract;
  }

   /*
  * -----------------------------------------------------------------------------------------------------------------------------------
  * Functions for BNB Staking Functionality
  * -----------------------------------------------------------------------------------------------------------------------------------
  */
 
  // function to performs staking for user BNB for a specific period of time
  function stakeBNB(uint256 time) external payable BNBStakeCheck(time) returns(bool){
    require(BNBPaused == false, "BNB Staking is Paused, Please try after staking get unpaused!!!");
    require(_bnbStakedByUser[msg.sender].add(msg.value) <= _bnbLimit, "BNB Stake Limit per user is completed, Use different address and try again!!!");
    _bnbTime = now + (time * 1 days);
    _bnbStakingCount = _bnbStakingCount + 1 ;
    _bnbTotalDays[_bnbStakingCount] = time;
    _bnbStakingAddress[_bnbStakingCount] = msg.sender;
    _bnbStakingId[msg.sender].push(_bnbStakingCount);
    _bnbStakingEndTime[_bnbStakingCount] = _bnbTime;
    _bnbStakingStartTime[_bnbStakingCount] = now;
    _usersBNB[_bnbStakingCount] = msg.value;
    _bnbStakedByUser[msg.sender] = _bnbStakedByUser[msg.sender].add(msg.value);
    _bnbTransactionstatus[_bnbStakingCount] = false;
    totalBNBStakesInContract = totalBNBStakesInContract.add(msg.value);
    totalStakedBNB = totalStakedBNB.add(msg.value);
    return true;
  }

  // function to get staking count for BNB
  function getBNBStakingCount() public view returns(uint256){
    return _bnbStakingCount;
  }
  
  // function to get total Staked BNB
  function getTotalStakedBNB() public view returns(uint256){
    return totalStakedBNB;
  }
  
  // function to calculate reward for the message sender for BNB stake
  function getBNBRewardDetailsByStakingId(uint256 id) public view returns(uint256){
    if(_bnbTotalDays[id] == PERIOD_SILVER) {
        return (_usersBNB[id]*BNB_REWARD_PERCENT_SILVER/10000);
    } else if(_bnbTotalDays[id] == PERIOD_GOLD) {
               return (_usersBNB[id]*BNB_REWARD_PERCENT_GOLD/10000);
      } else if(_bnbTotalDays[id] == PERIOD_PLATINUM) { 
                 return (_usersBNB[id]*BNB_REWARD_PERCENT_PLATINUM/10000);
        } else{
              return 0;
          }
  }

  // function to calculate penalty for the message sender for BNB stake
  function getBNBPenaltyDetailByStakingId(uint256 id) public view returns(uint256){
    if(_bnbStakingEndTime[id] > now){
        if(_bnbTotalDays[id] == PERIOD_SILVER){
            return (_usersBNB[id]*BNB_PENALTY_PERCENT_SILVER/10000);
        } else if(_bnbTotalDays[id] == PERIOD_GOLD) {
              return (_usersBNB[id]*BNB_PENALTY_PERCENT_GOLD/10000);
          } else if(_bnbTotalDays[id] == PERIOD_PLATINUM) { 
                return (_usersBNB[id]*BNB_PENALTY_PERCENT_PLATINUM/10000);
            } else {
                return 0;
              }
    } else{
       return 0;
     }
  }
  
  // function for withdrawing staked BNB
  function withdrawStakedBNB(uint256 stakingId) public returns(bool){
    require(_bnbStakingAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_bnbTransactionstatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
      if(_bnbTotalDays[stakingId] == PERIOD_SILVER){
            require(now >= _bnbStakingStartTime[stakingId] + WITHDRAW_TIME_SILVER, "Unable to Withdraw Stake before 15 days of staking start time, Please Try Again Later!!!");
            _bnbTransactionstatus[stakingId] = true;
            if(now >= _bnbStakingEndTime[stakingId]){
                _finalBNBStakeWithdraw[stakingId] = _usersBNB[stakingId].add(getBNBRewardDetailsByStakingId(stakingId));
                _bnbStakingAddress[stakingId].transfer(_finalBNBStakeWithdraw[stakingId]);
                totalBNBStakesInContract = totalBNBStakesInContract.sub(_usersBNB[stakingId]);
            } else {
                _finalBNBStakeWithdraw[stakingId] = _usersBNB[stakingId].add(getBNBPenaltyDetailByStakingId(stakingId));
                _bnbStakingAddress[stakingId].transfer(_finalBNBStakeWithdraw[stakingId]);
                totalBNBStakesInContract = totalBNBStakesInContract.sub(_usersBNB[stakingId]);
              }
      } else if(_bnbTotalDays[stakingId] == PERIOD_GOLD){
           require(now >= _bnbStakingStartTime[stakingId] + WITHDRAW_TIME_GOLD, "Unable to Withdraw Stake before 30 days of staking start time, Please Try Again Later!!!");
           _bnbTransactionstatus[stakingId] = true;
            if(now >= _bnbStakingEndTime[stakingId]){
                _finalBNBStakeWithdraw[stakingId] = _usersBNB[stakingId].add(getBNBRewardDetailsByStakingId(stakingId));
                _bnbStakingAddress[stakingId].transfer(_finalBNBStakeWithdraw[stakingId]);
                totalBNBStakesInContract = totalBNBStakesInContract.sub(_usersBNB[stakingId]);
            } else {
                _finalBNBStakeWithdraw[stakingId] = _usersBNB[stakingId].add(getBNBPenaltyDetailByStakingId(stakingId));
                _bnbStakingAddress[stakingId].transfer(_finalBNBStakeWithdraw[stakingId]);
                totalBNBStakesInContract = totalBNBStakesInContract.sub(_usersBNB[stakingId]);
              }
      } else if(_bnbTotalDays[stakingId] == PERIOD_PLATINUM){
           require(now >= _bnbStakingStartTime[stakingId] + WITHDRAW_TIME_PLATINUM, "Unable to Withdraw Stake before 45 days of staking start time, Please Try Again Later!!!");
           _bnbTransactionstatus[stakingId] = true;
           if(now >= _bnbStakingEndTime[stakingId]){
               _finalBNBStakeWithdraw[stakingId] = _usersBNB[stakingId].add(getBNBRewardDetailsByStakingId(stakingId));
               _bnbStakingAddress[stakingId].transfer(_finalBNBStakeWithdraw[stakingId]);
               totalBNBStakesInContract = totalBNBStakesInContract.sub(_usersBNB[stakingId]);
           } else {
               _finalBNBStakeWithdraw[stakingId] = _usersBNB[stakingId].add(getBNBPenaltyDetailByStakingId(stakingId));
               _bnbStakingAddress[stakingId].transfer(_finalBNBStakeWithdraw[stakingId]);
               totalBNBStakesInContract = totalBNBStakesInContract.sub(_usersBNB[stakingId]);
            }
      } else {
          return false;
        }
    return true;
  }
  
  // function to get Final Withdraw Staked value for BNB
  function getFinalBNBStakeWithdraw(uint256 id) public view returns(uint256){
    return _finalBNBStakeWithdraw[id];
  }
  
  // function to get total BNB stake in contract
  function getTotalBNBStakesInContract() public view returns(uint256){
      return totalBNBStakesInContract;
  }
  
  /*
  * -------------------------------------------------------------------------------------------------------------------------------
  * Get Functions for Stake Token Functionality
  * -------------------------------------------------------------------------------------------------------------------------------
  */

  // function to get Token Staking address by id
  function getTokenStakingAddressById(uint256 id) external view returns (address){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingAddress[id];
  }
  
  // function to get Token staking id by address
  function getTokenStakingIdByAddress(address add) external view returns(uint256[]){
    require(add != address(0),"Invalid Address, Pleae Try Again!!!");
    return _tokenStakingId[add];
  }
  
  // function to get Token Staking Starting time by id
  function getTokenStakingStartTimeById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingStartTime[id];
  }
  
  // function to get Token Staking Ending time by id
  function getTokenStakingEndTimeById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingEndTime[id];
  }
  
  // function to get Token Staking Total Days by Id
  function getTokenStakingTotalDaysById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenTotalDays[id];
  }

  // function to get Staking tokens by id
  function getStakingTokenById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersTokens[id];
  }

  // function to get Token lockstatus by id
  function getTokenLockStatus(uint256 id) external view returns(bool){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _TokenTransactionstatus[id];
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------
  * Get Functions for Stake BNB Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------
  */

  // function to get BNB Staking address by id
  function getBNBStakingAddressById(uint256 id) external view returns (address){
    require(id <= _bnbStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _bnbStakingAddress[id];
  }
  
  // function to get BNB Staking id by address
  function getBNBStakingIdByAddress(address add) external view returns(uint256[]){
    require(add != address(0),"Invalid Address, Pleae Try Again!!!");
    return _bnbStakingId[add];
  }
  
  // function to get BNB Staking Starting time by id
  function getBNBStakingStartTimeById(uint256 id) external view returns(uint256){
    require(id <= _bnbStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _bnbStakingStartTime[id];
  }
  
  // function to get BNB Staking End time by id
  function getBNBStakingEndTimeById(uint256 id) external view returns(uint256){
    require(id <= _bnbStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _bnbStakingEndTime[id];
  }
  
  // function to get BNB Staking Total Days by Id
  function getBNBStakingTotalDaysById(uint256 id) external view returns(uint256){
    require(id <= _bnbStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _bnbTotalDays[id];
  }
  
  // function to get Staked BNB by id
  function getBNBStakedById(uint256 id) external view returns(uint256){
    require(id <= _bnbStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersBNB[id];
  }

  // function to get Staked BNB by address
  function getBNBStakedByUser(address add) external view returns(uint256){
    require(add != address(0),"Invalid Address, Please try again!!");
    return _bnbStakedByUser[add];
  }

  // function to get BNB lockstatus by id
  function getBNBLockStatus(uint256 id) external view returns(bool){
    require(id <= _bnbStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _bnbTransactionstatus[id];
  }

}