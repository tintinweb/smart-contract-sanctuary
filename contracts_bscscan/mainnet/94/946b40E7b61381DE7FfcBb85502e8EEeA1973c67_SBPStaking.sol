/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract SBPStaking is Ownable, ReentrancyGuard {
    IBEP20 SBP;
    
    uint256[] public storageIds;
    
      struct pool {
         uint amount;
        uint releaseDate;
        bool isSet;
        bool claimed;
        uint PoolRewardPercentage;
        uint256 storageId;
    }
    struct staker {
        bool active;
        
        address staker;
        uint Accountvaluelocked;
        uint256[] StakeIds;
        uint256 tier;
        
    }
    
    
    
    mapping(address => mapping (uint256 => pool) ) public pools;
    mapping(address => staker) public stakers;
    mapping(address => uint256) public totalRewards;
    
    struct dataStorage {
        string name;
        uint256 minAmount;
        uint256 time;
        uint256 rewardPercentage;
    }
    
    
    mapping(uint256 => bool) public isValidStorage;
    mapping(uint256 => dataStorage) public storages;
   
   
   
    uint256 EarlypenaltyFee;
    uint256 rewardBalance;
    uint256 availableReward;
    uint256 TVL;

    event storageCreated(uint256 storageId, string name ,uint256 minAmount, uint256 time, uint256 rewardPercentage );
    event storageUpdated(uint256 storageId, string name,uint256 minAmount, uint256 time, uint256 rewardPercentage );
    event StakedToPool(uint256 amount , uint256 storageId, address indexed staker);

    uint256 Diamond = 4000000 * 10**18;
    uint256 Platinum = 2000000 * 10**18;
    uint256 Gold = 1000000 * 10**18;
    uint256 Silver = 500000 * 10**18;
    uint256 Bronze = 250000 * 10**18;
    
    
    constructor(address _SBP){
        SBP = IBEP20(_SBP);
    }
    
    
    
    function depositRewardSBP(uint256 amount) public onlyOwner{
        SBP.transferFrom(msg.sender , address(this) , amount);
        rewardBalance += amount;
        availableReward += amount;
    }
    
    function getTotalRewardsExpected(address _account) public view returns (uint256){
        return totalRewards[_account];
    }
    
    
    function addStorage(uint256 time , string calldata name , uint256 minAmount, uint256 rewardPercentage) public onlyOwner returns(uint256){
        uint256 storageId =  storageIds.length+1;
        isValidStorage[storageId] = true;
        storages[storageId] = dataStorage(name , minAmount , time * 1 minutes, rewardPercentage);
        storageIds.push(storageId);
        emit storageCreated(storageId , name , minAmount ,storages[storageId].time ,rewardPercentage);  
        return storageId;
    }
    
    
    
    function updateStorage(uint256 storageId, uint256 time , string calldata name , uint256 minAmount, uint256 rewardPercentage) public onlyOwner {
       require(isValidStorage[storageId]  , "not a valid storage ID");
        storages[storageId] = dataStorage(name , minAmount , time * 1 minutes, rewardPercentage);
        emit storageUpdated(storageId , name , minAmount ,storages[storageId].time ,rewardPercentage);  
    }
    
    
    
    function expectedPoolReward(address account,uint256 StakeId) public view returns(uint256){
        require(pools[account][StakeId].isSet && !pools[account][StakeId].claimed , "pool isn't active");
        return (pools[account][StakeId].amount * pools[account][StakeId].PoolRewardPercentage / 100);
        
    }
    
    
    
    function StakingAmount(address account ,uint256 StakeId) public view returns(uint256){
        return pools[account][StakeId].amount;
    }
    
    
    function AccountStakingTotal(address account) public view returns(uint256){
      return stakers[account].Accountvaluelocked;
    } 
    
    function AccountTier(address account) public view returns(uint256){
      return stakers[account].tier;
    } 
    
    
    function StakeIDs(address account) public view returns(uint256[] memory){
        return stakers[account].StakeIds;
    }
    
    
    function StakeStatus(address account, uint256 StakeId) public view returns(bool , bool , bool){
        
        return(pools[account][StakeId].isSet,pools[account][StakeId].claimed , block.timestamp > pools[account][StakeId].releaseDate);
    }
    
   
    function rewardProcessesable(uint256 storageId , uint256 amount) private view returns(bool){
        uint256 expectedReward = amount * storages[storageId].rewardPercentage / 100;
        if(availableReward >= expectedReward) return true;
        return false;
    }
    
    function setPenaltyFee(uint256 _penalty) public onlyOwner {
        require(_penalty < 100 , "invalid percentage");
        EarlypenaltyFee = _penalty;
    }
    
    
    function getStorageNumbers() public view returns(uint256){
        return storageIds.length;
    }

    function getPenaltyFee() public view returns(uint256){
        return EarlypenaltyFee;
    }
    function RewardBalance() public view returns(uint256){
        return rewardBalance;
    }

    function StakerTVL() public view returns(uint256){
        return TVL;
    }

    
    function WithdrawReward(uint256 amount) public onlyOwner {
        require(amount <= rewardBalance, "Ran out of rewards");
        SBP.transfer(owner() ,amount);
    }
    
    
    function SetTierThreshold(uint256 _Diamond, uint256 _Platinum, uint256 _Gold, uint256 _Silver, uint256 _Bronze) public onlyOwner {
        Diamond = _Diamond;
        Platinum = _Platinum;
        Gold = _Gold;
        Silver = _Silver;
        Bronze = _Bronze;
    }

     function StakeSBP(uint256 amount , uint256 storageId) public nonReentrant returns(uint256) {
        require(isValidStorage[storageId]  , "not a valid storage ID");
        require(amount > 0 && amount >=storages[storageId].minAmount , "amount below minimum staking value");
        require(rewardProcessesable(storageId , amount) , "available reward balance insufient");
        SBP.transferFrom(msg.sender , address(this) , amount);
        TVL += amount;
        uint256 StakeID = stakers[msg.sender].StakeIds.length+1;
        pools[msg.sender][StakeID] = pool(amount , block.timestamp + storages[storageId].time , true , false,storages[storageId].rewardPercentage ,storageId ); 
        stakers[msg.sender].StakeIds.push(StakeID);
        stakers[msg.sender].Accountvaluelocked += amount;
        stakers[msg.sender].active = true;
       uint256 expectedReward  = amount * storages[storageId].rewardPercentage / 100;
       totalRewards[msg.sender] += expectedReward;
       availableReward -= expectedReward;

      if (stakers[msg.sender].Accountvaluelocked >= Diamond){
          stakers[msg.sender].tier = 5;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Platinum){
          stakers[msg.sender].tier = 4;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Gold){
          stakers[msg.sender].tier = 3;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Silver){
          stakers[msg.sender].tier = 2;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Bronze){
          stakers[msg.sender].tier = 1;
      }
      else {
          stakers[msg.sender].tier = 0;
      }
       
       emit StakedToPool(amount , storageId  , msg.sender);  
        return StakeID;
    }

    
    function unstakeSBP(uint256 StakeId) public nonReentrant {
         require(pools[msg.sender][StakeId].isSet && !pools[msg.sender][StakeId].claimed , "not active pool");
         require(block.timestamp > pools[msg.sender][StakeId].releaseDate , "not yet time");
         uint256 reward = pools[msg.sender][StakeId].amount * pools[msg.sender][StakeId].PoolRewardPercentage / 100;
         rewardBalance -= reward;
         pools[msg.sender][StakeId].claimed = true;
         SBP.transfer(msg.sender ,pools[msg.sender][StakeId].amount + reward );
         TVL -= pools[msg.sender][StakeId].amount;
         stakers[msg.sender].Accountvaluelocked -= pools[msg.sender][StakeId].amount;
         totalRewards[msg.sender] -= reward;
         
      if (stakers[msg.sender].Accountvaluelocked >= Diamond){
          stakers[msg.sender].tier = 5;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Platinum){
          stakers[msg.sender].tier = 4;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Gold){
          stakers[msg.sender].tier = 3;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Silver){
          stakers[msg.sender].tier = 2;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Bronze){
          stakers[msg.sender].tier = 1;
      }
      else {
          stakers[msg.sender].tier = 0;
      }
    }
    
    
     function earlyClaimSBP(uint256 StakeId) public nonReentrant{
         require(pools[msg.sender][StakeId].isSet && !pools[msg.sender][StakeId].claimed , "not active pool");
         uint256 penalty = pools[msg.sender][StakeId].amount * EarlypenaltyFee / 100;
         rewardBalance += penalty;
         uint256 expectedReward  = pools[msg.sender][StakeId].amount * pools[msg.sender][StakeId].PoolRewardPercentage / 100;
         availableReward += expectedReward;
         pools[msg.sender][StakeId].claimed = true;
         SBP.transfer(msg.sender, pools[msg.sender][StakeId].amount - penalty);
         TVL -= pools[msg.sender][StakeId].amount;
         stakers[msg.sender].Accountvaluelocked -= pools[msg.sender][StakeId].amount;
         totalRewards[msg.sender] = totalRewards[msg.sender] - expectedReward;
         
      if (stakers[msg.sender].Accountvaluelocked >= Diamond){
      stakers[msg.sender].tier = 5;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Platinum){
          stakers[msg.sender].tier = 4;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Gold){
          stakers[msg.sender].tier = 3;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Silver){
          stakers[msg.sender].tier = 2;
      }
      else if (stakers[msg.sender].Accountvaluelocked >= Bronze){
          stakers[msg.sender].tier = 1;
      }
      else {
          stakers[msg.sender].tier = 0;
      }
    } 
    
    

}