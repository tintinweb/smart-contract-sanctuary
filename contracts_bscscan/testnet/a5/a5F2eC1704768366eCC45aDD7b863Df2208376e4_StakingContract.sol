/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

 /**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    if (a == 0){
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


interface IronToken {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}

interface WarriorToken {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}


contract StakingContract {

  using SafeMath for uint256;
  
  address private _owner;                                 // Owner of the Contract.
  bool    private _stopped = false;                       // state variable to check fail-safe for contract.
  mapping(uint8 => address) private _tokenPoolAddress;    // Pool Address to manage Staking user's Token.
   
  address _iron;
  address _warrior;
  
  IronToken _ironToken;
  WarriorToken _warriorToken;
  
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
 
  constructor (address Owner, address _ironTokenPoolAddress, address _warriorTokenPoolAddress) {
    _owner = Owner;
    _iron = _ironTokenPoolAddress;
    _ironToken = IronToken(_iron);
    _warrior = _warriorTokenPoolAddress;
    _warriorToken = WarriorToken(_warrior);
    _tokenPoolAddress[0] = _ironTokenPoolAddress;
    _tokenPoolAddress[1] = _warriorTokenPoolAddress;
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for owner
  * ----------------------------------------------------------------------------------------------------------------------------------------------
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
  
  /* POOL TOKEN IDs
  *
  * IRON Token = 0 
  * WARRIOR Token = 1
  */
  
  
  // Mapping for pool token ID to users with id => address Staked Address
  mapping(uint8 => mapping (uint256 => address) ) private _stakerAddress;
  
  // Mapping for pool token ID to staking IDs => address Staked Address
  mapping(uint8 => mapping (address => uint256[]) ) private _stakedIDs;

  // Mapping for pool token ID to users with id => Tokens 
  mapping(uint8 => mapping (uint256 => uint256) ) private _usersTokens;
  
  // Mapping for pool token ID to users with id => Staking Time
  mapping(uint8 => mapping (uint256 => uint256) ) private _stakingStartTime;

  // Mapping for pool token ID to users with id => Status
  mapping(uint8 => mapping (uint256 => bool) ) private _TokenTransactionstatus;  
 
  // Mapping for pool token ID to keep track of final withdraw value of staked token
  mapping(uint8 => mapping (uint256=>uint256) ) private _finalWithdrawlStake;
  
  // Reward Percentage
  uint256 private _rewardPercentage= 15; 
  
  // Mappint for pool token ID to Count of no of staking
  mapping(uint8 => uint256) private _stakingCount;

  // Withdraw Time limit
  uint256 _withdrawLimit = 0;

  
  /** 
   * @dev modifier to check the failsafe
   */
  modifier failSafe(){
    require(_stopped == false, "Fail Safe check failed");
    _;
  }

 /*
  * ------------------------------------------------------------------------------------
  * Owner functions of get value, set value, blacklist and withdraw ETH Functionality
  * ------------------------------------------------------------------------------------
  */

  /**
   * @dev Function to secure contract from fail by toggling _stopped variable
   */
  function toggleContractActive() public onlyOwner{
    _stopped = !_stopped;
  }


  /**
   * @dev Function to set token pool address
   * @param add Address for token pool that manages supplies for stakes.
   */
  function setIronTokenPoolAddress(address add) public onlyOwner returns(bool){
    require(add != address(0),"Invalid Address");
    _iron = add;
    _ironToken = IronToken(_iron);
    return true;
  }

  function setWarriorTokenPoolAddress(address add) public onlyOwner returns(bool){
    require(add != address(0),"Invalid Address");
    _warrior = add;
    _warriorToken = WarriorToken(_warrior);
    return true;
  }
  
 
  /**
   * @dev Function to get Token Pool addresss
   */
  function getTokenpoolAddress() public view returns(address [] memory){
      address[] memory _arr = new address[](2);
      _arr[0] = _iron;
      _arr[1] = _warrior;
      return _arr;
  }


  /**
   * @dev Function for setting rewards percentage by owner
   * @param rewardsPercentage Reward percentage
   */
  function setRewardPercentage(uint256 rewardsPercentage) public onlyOwner returns(bool){
    require(rewardsPercentage > 0, "Invalid Percentage");
    _rewardPercentage = rewardsPercentage;
    return true;
  }

  /**
   * @dev Function for getting rewards percentage by owner
   */
  function getRewardPercentage() public view returns(uint256){
    return _rewardPercentage;
  }

  
  /**
   * @dev Function to blacklist any stake
   * @param status true/false
   * @param stakingId stake id for that particular stake
   */
  function blacklistStake(uint8 poolID, bool status,uint256 stakingId) external onlyOwner{
    _TokenTransactionstatus[poolID][stakingId] = status;
  }

   /**
   * @dev function to get total ethers in contract
   */
    function getContractETHBalance() public view returns(uint256){
        return(address(this).balance);
    }

   /** 
   * @dev function to withdraw total ethers from contract
   */
    function withdrawETH() external onlyOwner returns(bool){
    msg.sender.transfer(address(this).balance);
    return true;
    }

 
/*
   * -------------------------------------------------------------------------------------
   * Functions for Staking Functionlaity
   * -------------------------------------------------------------------------------------
   */

  /**
   * @dev Function to get Final Withdraw Staked value
   * @param id stake id for the stake
   */
  function getFinalWithdrawlStake(uint8 poolID, uint256 id) public view returns(uint256){
    return _finalWithdrawlStake[poolID][id];
  }

  /**
   * @dev Function to get Staking address by id
   * @param id stake id for the stake
   */
  function getStakingAddressById(uint8 poolID, uint256 id) public view returns (address){
    require(id <= _stakingCount[poolID],"Unable to reterive data on specified id, Please try again!!");
    return _stakerAddress[poolID][id];
  }
  
  /**
   * @dev Function to get Staking IDs by address
   * @param user address used for the staking
   */
  function getStakingIDsByAddress(uint8 poolID, address user) public view returns (uint256[] memory){
    // require(id <= _stakingCount[poolID],"Unable to reterive data on specified id, Please try again!!");
    uint256[] memory stakedIDs = _stakedIDs[poolID][user];
    return stakedIDs;
  }
  
  /**
   * @dev Function to get Staking Starting time by id
   * @param id stake id for the stake
   */
  function getStakingStartTimeById(uint8 poolID, uint256 id) public view returns(uint256){
    require(id <= _stakingCount[poolID],"Unable to reterive data on specified id, Please try again!!");
    return _stakingStartTime[poolID][id];
  }
  
  /**
   * @dev Function to get Staking tokens by id
   * @param id stake id for the stake
   */
  function getStakingTokenById(uint8 poolID, uint256 id)public view returns(uint256){
    require(id <= _stakingCount[poolID],"Unable to reterive data on specified id, Please try again!!");
    return _usersTokens[poolID][id];
  }
  
  /**
   * @dev Function to get active Staking tokens by id
   * @param id stake id for the stake
   */
  function getActiveStakesById(uint8 poolID, uint256 id)public view returns(address){
    return _stakerAddress[poolID][id];
  }

  /**
   * @dev Function to get Token lockstatus by id
   * @param id stake id for the stake
   */
  function getTokenLockstatus(uint8 poolID, uint256 id)public view returns(bool){
    return _TokenTransactionstatus[poolID][id];
  }

  /**
   * @dev Function to get staking count
   */
  function getStakingCount(uint8 poolID) public view returns(uint256){
      return _stakingCount[poolID];
  }

  /**
   * @dev Function to get Rewards on the stake
   * @param id stake id for the stake
   */
  function getRewardsDetailsOfUserById(uint8 poolID, uint256 id) public view returns(uint256){
      return (_usersTokens[poolID][id].mul(_rewardPercentage).mul((block.timestamp - _stakingStartTime[poolID][id])/86400)).div(36500);
  }

  /**
   * @dev Function for setting withdraw time limit by owner
   * @param withdrawLimit Withdraw Limit
   */
  function setWithdrawLimit(uint256 withdrawLimit) public onlyOwner returns(bool){
    require(withdrawLimit > 0, "Invalid Time");
    _withdrawLimit = withdrawLimit;
    return true;
  }

  /**
   * @dev Function for getting withdraw limit by owner
   */
  function getWithdrawLimit() public view returns(uint256){
    return _withdrawLimit;
  }

  /**
   * @dev Function to performs staking for user tokens for a specific period of time
   * @param tokens number of tokens
   */
  function performStaking(uint8 poolID, uint256 tokens) public failSafe returns(bool){
    require(tokens > 0, "tokens cannot be zero");  
    uint256[] storage stakedIDs = _stakedIDs[poolID][msg.sender];
    _stakingCount[poolID] = _stakingCount[poolID] +1 ;
    stakedIDs.push(_stakingCount[poolID]);
    _stakedIDs[poolID][msg.sender] = stakedIDs;
    _stakerAddress[poolID][_stakingCount[poolID]] = msg.sender;
    _stakingStartTime[poolID][_stakingCount[poolID]] = block.timestamp;
    _usersTokens[poolID][_stakingCount[poolID]] = tokens;
    _TokenTransactionstatus[poolID][_stakingCount[poolID]] = false;
    if(poolID == 0) {
        _ironToken.transferFrom(msg.sender, address(this), tokens);
    }
    else if(poolID == 1) {
        _warriorToken.transferFrom(msg.sender, address(this), tokens);
    }
    return true;
  }

  /**
   * @dev Function for withdrawing staked tokens
   * @param stakingId stake id for the stake
   */
  function withdrawStakedTokens(uint8 poolID, uint256 stakingId) public failSafe returns(bool){
    require(_stakerAddress[poolID][stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_TokenTransactionstatus[poolID][stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    
    _TokenTransactionstatus[poolID][stakingId] = true;
    
    if (block.timestamp > _stakingStartTime[poolID][_stakingCount[poolID]].add(_withdrawLimit)){
        _finalWithdrawlStake[poolID][stakingId] = _usersTokens[poolID][stakingId].add(getRewardsDetailsOfUserById(poolID, stakingId));
        if(poolID == 0) {
            require(
                _ironToken.balanceOf(_owner) >= getRewardsDetailsOfUserById(poolID, stakingId),
                "Not enough Iron Token reward"
            );
            _ironToken.approve(address(this), _usersTokens[poolID][stakingId].add(getRewardsDetailsOfUserById(poolID, stakingId)));
            _ironToken.transferFrom(address(this), msg.sender, _usersTokens[poolID][stakingId]);
            _ironToken.transferFrom(_owner, msg.sender, getRewardsDetailsOfUserById(poolID, stakingId));
        }
        else if(poolID == 1) {
            require(
                _warriorToken.balanceOf(_owner) >= getRewardsDetailsOfUserById(poolID, stakingId),
                "Not enough Warrior Token reward"
            );
            _warriorToken.approve(address(this), _usersTokens[poolID][stakingId].add(getRewardsDetailsOfUserById(poolID, stakingId)));
            _warriorToken.transferFrom(address(this), msg.sender, _usersTokens[poolID][stakingId]);
            _warriorToken.transferFrom(_owner, msg.sender, getRewardsDetailsOfUserById(poolID, stakingId));
        }
    }
    else {
        if(poolID == 0) {
            _ironToken.approve(address(this), _usersTokens[poolID][stakingId]);
            _ironToken.transferFrom(address(this), msg.sender, _usersTokens[poolID][stakingId]);
        }
        else if(poolID == 1) {
            _warriorToken.approve(address(this), _usersTokens[poolID][stakingId]);
            _warriorToken.transferFrom(address(this), msg.sender, _usersTokens[poolID][stakingId]);
        }
    }
    return true;
  }

}