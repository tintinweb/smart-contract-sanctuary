/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\IXIRSWAP.sol
pragma solidity ^0.5.0;

contract IXIRSWAP is Ownable() {

  //token address
    address payable public TOKEN = 0x17179f506B89D80291B581F200F34B17ff172CD3;

  /**
  * @dev Struct for token locks.
  * @param amount Amount of tokens deposited.
  * @param lockedAt Timestamp the lock was created at.
  * @param unlockAt Timestamp request unlock was created at.
  * @param owner Account that made the deposit.
  * @param m_type Type of stake.
  * @param rewards Rewards be able to get.
  * @param rewardEarned Total earned. It will be changed when holder claim rewards.
  */

  struct Stake {
      uint256 amount;
      uint32 lockedAt;
      uint32 unlockAt;
      uint32 unlockTime;
      address owner;
      uint m_type;
      uint256 rewards;
      uint256 rewardEarned;
  }

  event LockCreated(
    uint256 indexed lockId,
    address indexed account,
    uint256 amountLocked
  );

  event LockDestroyed(
    uint256 indexed lockId,
    address indexed account,
    uint256 amount
  );

  event SetDistribution (
    uint256 amount,
    uint256 distributionTime
  );

    event Distributed(
    address indexed account,
    uint256 amount
  );

  Stake[] public stakes; 

  uint DAY_STAKE = 1;
  uint MONTH_STAKE = 2;
  uint SIX_STAKE = 3;
  uint YEAR_STAKE = 4;

  mapping(uint => uint256) private _stake_denomination;
  mapping(uint => uint256) private _stake_apy;       
  mapping(uint => uint256) private _stake_period;

  constructor () public {
    _stake_denomination[DAY_STAKE] = 1000;
    _stake_denomination[MONTH_STAKE] = 2000;
    _stake_denomination[SIX_STAKE] = 3500;
    _stake_denomination[YEAR_STAKE] = 5000;

    _stake_apy[DAY_STAKE] = 44;
    _stake_apy[MONTH_STAKE] = 80;
    _stake_apy[SIX_STAKE] = 142; 
    _stake_apy[YEAR_STAKE] = 176; 

    _stake_period[DAY_STAKE] = 86400;       //1 day
    _stake_period[MONTH_STAKE] = 2592000;   //1 month
    _stake_period[SIX_STAKE] = 15552000;    //6 months
    _stake_period[YEAR_STAKE] = 31104000;   //1 year

  }
  
    function calcReward() public onlyOwner {

      // get total balance staked
      IERC20 token = IERC20(TOKEN);
      uint256 balanceOfOwner = token.balanceOf(address(this));
      require(balanceOfOwner > 0, "Insufficient balance for rewards.");

      // get totdal days staked
      uint256 days_day = get_days_staked(DAY_STAKE);
      uint256 days_month = get_days_staked(MONTH_STAKE);
      uint256 days_six = get_days_staked(SIX_STAKE);
      uint256 days_year = get_days_staked(YEAR_STAKE);

      // send reward to stackes holder
      if (days_day !=0 ) {
        // rewards for all stacked user (1 day)
        set_reward(DAY_STAKE);
      }

      if (days_month !=0 ) { 
        // rewards for all stacked user (1 month)
        set_reward(MONTH_STAKE);
      }

      if (days_six !=0 ) { 
        // rewards for all stacked user (6 month)
        set_reward(SIX_STAKE);
      }

        if (days_year !=0 ) { 
        // rewards for all stacked user (1 year)
        set_reward(SIX_STAKE);
      }

      emit SetDistribution( balanceOfOwner, block.timestamp);         
    }

  // Get all days for now.
  // All members has diff days so add all days from members.
  function get_days_staked( uint m_type ) internal view returns(uint256) {
    uint256 totaldays = 0;
    for (uint i=0; i< stakes.length; i++) {
      if (stakes[i].m_type == m_type) {
          // stakes[i].unlockAt > stakes[i].lockedAt  :  meaning already requested unlock
          uint256 timeRemaining = 0;
          if (stakes[i].unlockAt == 0)  {
            timeRemaining = block.timestamp - stakes[i].lockedAt;
          } else {
            if (stakes[i].unlockAt > stakes[i].lockedAt) {
              if (stakes[i].unlockAt < block.timestamp) {
                timeRemaining = stakes[i].unlockAt - stakes[i].lockedAt;
              } else {
                continue;
              }
            } else {
              continue;
            }
          }
          uint diff = timeRemaining / 60 / 60 / 24;
          totaldays += diff;
        }
    }
    return totaldays;
  }

  // Transfer rewards to holder.
  // It should be calculated by member type.
  function set_reward(uint m_type) internal {
      for (uint i=0; i< stakes.length; i++) { 
        if (stakes[i].m_type == m_type) {

          uint256 timeRemaining = 0;
          if (stakes[i].unlockAt == 0)  {
            timeRemaining = block.timestamp - stakes[i].lockedAt;
          } else {
            if (stakes[i].unlockAt > stakes[i].lockedAt) {
              if (stakes[i].unlockAt < block.timestamp) {
                timeRemaining = stakes[i].unlockAt - stakes[i].lockedAt;
              } else {
                continue;
              }
            } else {
              continue;
            }
          }

          uint diff = timeRemaining / 60 / 60 / 24;
          
          uint256 rewards = diff * _stake_apy[m_type] / 100 / 365 * stakes[i].amount;
          // set reward's amount to memberrhip holder
          stakes[i].rewards += rewards;
          // initialize lockedAt
          stakes[i].lockedAt = uint32(block.timestamp);
        }                     
      }         
  }

  function Staking(uint256 _amount, uint _type) public payable returns(uint256 lockId) {
      require(msg.value == 0, "IXIR value is supposed to be 0 for ERC20 instance");
      // require(_member_denomination[_type] * 10 ** _decimals == _amount, "Denomination should be matched.");

      bool alreadyStaked = false;
      // check already stacked;
      for (uint i=0; i< stakes.length; i++) { 
        if(stakes[i].owner == msg.sender && (_type ==  stakes[i].m_type)) {
          alreadyStaked = true;
          lockId = i;
        }
      }

      require(!alreadyStaked, "Already staked.");

      lockId = stakes.length;
      stakes.push(Stake({
          amount: _amount,
          lockedAt: uint32(block.timestamp),
          unlockAt:0,
          unlockTime: uint32(block.timestamp + _stake_period[_type]),
          owner: msg.sender,
          m_type: _type,
          rewards: 0,
          rewardEarned: 0
      }));       
      
      emit LockCreated(lockId, stakes[lockId].owner, stakes[lockId].amount); 
  }

  function Unstaking(uint _mtype) public returns(uint256 remainUnlockTime){      
    uint256 lockId;    
    bool alreadyStaked = false;   
    for (uint i=0; i< stakes.length; i++) { 
      if(stakes[i].owner == msg.sender && (_mtype ==  stakes[i].m_type)) {
        alreadyStaked = true;
        lockId = i;
      }
    }

    require(alreadyStaked, "Staking is not exist.");

    bool canbeUnstake = false;

    // check unlocktime
    if (stakes[lockId].unlockTime <= block.timestamp) {
      canbeUnstake = true;
      remainUnlockTime = uint32(block.timestamp) - stakes[lockId].unlockTime;
    }

    require(canbeUnstake, "Unstaking request did not match to unlock time.");

    // set unlock time to membership
    stakes[lockId].unlockAt = uint32(block.timestamp);    
    emit LockDestroyed(lockId, stakes[lockId].owner, stakes[lockId].amount); 
  }

  function claimRewards(uint _type) public { 
    bool canbeClaimed = false;
    uint256 lockId = 0;
    for (uint i=0; i< stakes.length; i++) { 
      if(stakes[i].owner == msg.sender)  {
        if (stakes[i].m_type == _type) {          
          if (stakes[i].rewards != 0)  {
            canbeClaimed = true;   
            lockId = i;           
          }
        }
      }                             
    }
    require(canbeClaimed, "Didn't staked.");
    _processWithdrawRewards(stakes[lockId].owner, stakes[lockId].rewards, lockId);
  }

  function _processWithdrawRewards(address _recipient, uint256 _amount_reward, uint256 lockId) internal {
    IERC20 token = IERC20(TOKEN);
    uint256 balanceOfOwner = token.balanceOf(address(this));
    require(balanceOfOwner >= _amount_reward, "Insufficient Rewards balance. Please try again later.");
    
    stakes[lockId].rewardEarned += _amount_reward;
    delete stakes[lockId];
    emit Distributed( _recipient, _amount_reward);      
  }

  // Get total staked for holder.
  function getMyStaking( uint _type ) public view returns(uint256) {
      uint256 totalstaked = 0;
      for (uint i=0; i< stakes.length; i++) {
        if(stakes[i].owner == msg.sender && (_type ==  stakes[i].m_type)) {
          totalstaked += stakes[i].amount;
        }        
      }
      return totalstaked;
  }

  function getMyRewards( uint _type ) public view returns(uint256) { 
    uint256 rewards = 0;
      for (uint i=0; i< stakes.length; i++) {
        if(stakes[i].owner == msg.sender && (_type ==  stakes[i].m_type)) {
          rewards += stakes[i].rewards;
        }        
      }
      return rewards;
  }

  function getMyTotalEarned( uint _type ) public view returns(uint256) { 
    uint256 earned = 0;
    for (uint i=0; i< stakes.length; i++) {
      if(stakes[i].owner == msg.sender && (_type ==  stakes[i].m_type)) {
        earned += stakes[i].rewardEarned;
      }        
    }
    return earned;
  }
  
}