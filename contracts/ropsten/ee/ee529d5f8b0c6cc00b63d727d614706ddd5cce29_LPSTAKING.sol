/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol



pragma solidity ^0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/stakingvesting.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract LPSTAKING{
 
    struct stake {
        uint256 amount;
        uint256 timeOfStake;
        address stakingWallet;
        bool isUnStaked;
        uint256 unstakeTime;
    }
    
    mapping(address=> stake[])  cumulativeStakes;
    mapping(address=>mapping(uint256=>uint256)) rewards;
    uint256 public multiplier;
    mapping (address => uint256) totalNoOfStakes;
    uint256 stakeEndTime;
    mapping (address => uint256) totalClaimedReward;
    
    address LPAddress;
    address rewardTokenAddress;
    
     IERC20 LPToken;
     IERC20 rewardToken;
    //  IUniswapV2Router01 router;
     
     mapping(address => mapping(uint256 =>bool)) claimed1;
     mapping(address => mapping(uint256 =>bool)) claimed2;
     mapping(address => mapping(uint256 =>bool)) claimed3;
     mapping(address => mapping(uint256 =>bool)) claimed4;
     mapping(address => mapping(uint256 =>bool)) claimed5;
     
     constructor(address _lpAddress,address _rewardTokenAddress,uint256 _multiplier){
        require( _lpAddress!=address(0),'LP Token address cannot be zero address.');
        require(_rewardTokenAddress!=address(0),'Spherium Token address cannot be zero address.');
        LPAddress = _lpAddress;
        LPToken=IERC20(LPAddress);
        rewardTokenAddress=_rewardTokenAddress;
        rewardToken=IERC20(rewardTokenAddress);
        multiplier = _multiplier;
        // router = IUniswapV2Router01(_uniswapRouter);
        stakeEndTime = block.timestamp + 2629746 ;
    }
    
    function _calculateRewards(stake memory _oneStake,uint256 _noOfThisStake)internal{  //change public to internal 
        if(_oneStake.isUnStaked == true)
        {   uint256 currentTime = _oneStake.unstakeTime >= stakeEndTime ? 2629746 : _oneStake.unstakeTime - _oneStake.timeOfStake ;
            rewards[_oneStake.stakingWallet][_noOfThisStake] = _oneStake.amount*multiplier*currentTime;
        }
        else
        {
            uint256 timeStaked = stakeEndTime - _oneStake.timeOfStake;
            rewards[_oneStake.stakingWallet][_noOfThisStake] = _oneStake.amount*multiplier*timeStaked;}
    }
    function stakeLP(uint256 _amount)external returns(bool){
        //approve the token that the user want to stake to address(this) 
        require(_amount > 0 ,'Cannot stake 0 tokens');
        require(block.timestamp < stakeEndTime,'Staking time is completed');
        stake memory newStake=stake({    
            amount:_amount, 
            timeOfStake:block.timestamp, //change _testTime to block.timestamp
            stakingWallet:msg.sender,
            isUnStaked:false,
            unstakeTime:block.timestamp + 2629746 //change _testTime to block.timestamp
        });
        cumulativeStakes[msg.sender].push(newStake);
        totalNoOfStakes[msg.sender]++;
        require(LPToken.transferFrom(msg.sender,address(this),_amount),'There was a problem transferring LP token to contract');
        return true;
    }
    function unstakeSingleLP(uint256 _stakeNum)public returns(uint256){
        require(cumulativeStakes[msg.sender][_stakeNum].isUnStaked == false,'This stake is already unstaked or there is no stake with this ID');
        uint256 _amount = cumulativeStakes[msg.sender][_stakeNum].amount;
        cumulativeStakes[msg.sender][_stakeNum].isUnStaked = true;
        cumulativeStakes[msg.sender][_stakeNum].unstakeTime = block.timestamp;
        require(LPToken.transfer(msg.sender,_amount),'There was a problem transferring LP token to you');
        return _amount;
    }
    function unstakeAllLP()public returns (bool){
        uint256 _amount;
        for(uint256 a=0;a<totalNoOfStakes[msg.sender];a++){
        if(cumulativeStakes[msg.sender][a].isUnStaked == false){
        _amount = _amount + cumulativeStakes[msg.sender][a].amount;
        cumulativeStakes[msg.sender][a].isUnStaked = true;
        cumulativeStakes[msg.sender][a].unstakeTime = block.timestamp;
            }
        }
        require(LPToken.transfer(msg.sender,_amount),'There was a problem transferring LP token to you');   
        return true;
    }
    function claimRewards()public returns (uint256){
        uint256 claimableRewards;
        for(uint256 a=0;a<totalNoOfStakes[msg.sender];a++){
            _calculateRewards(cumulativeStakes[msg.sender][a],a);
             if(block.timestamp > stakeEndTime  && claimed1[msg.sender][a] != true ){
                claimableRewards = claimableRewards + (rewards[msg.sender][a]*20/100);
                claimed1[msg.sender][a] = true;
             }
             if(block.timestamp  > stakeEndTime + 2629746  && claimed2[msg.sender][a] != true ){
                claimableRewards = claimableRewards + (rewards[msg.sender][a]*20/100);
                claimed2[msg.sender][a] = true;
             }
             if(block.timestamp  > stakeEndTime + (2629746*2)  && claimed3[msg.sender][a] != true ){
                claimableRewards = claimableRewards + (rewards[msg.sender][a]*20/100);
                claimed3[msg.sender][a] = true;
             }
             if(block.timestamp  > stakeEndTime+(2629746*3)  && claimed4[msg.sender][a] != true ){
                claimableRewards = claimableRewards + (rewards[msg.sender][a]*20/100);
                claimed4[msg.sender][a] = true;
             }
             if(block.timestamp > stakeEndTime+(2629746*4)  && claimed5[msg.sender][a] != true ){
                claimableRewards = claimableRewards + (rewards[msg.sender][a]*20/100);
                claimed5[msg.sender][a] = true;
             }
             }
             totalClaimedReward[msg.sender] = totalClaimedReward[msg.sender] + claimableRewards;
        require(rewardToken.transfer(msg.sender,claimableRewards),'There was a problem transferring the rewards to you');
        return claimableRewards;
    }
    function _viewCalculateRewards(stake memory _oneStake)internal view returns(uint256){
        uint256 _rewards;
        if(_oneStake.isUnStaked == true)
        {   uint256 currentTime = _oneStake.unstakeTime >= stakeEndTime ? 2629746 : _oneStake.unstakeTime - _oneStake.timeOfStake ;
            _rewards = _oneStake.amount*multiplier*currentTime;
        }
        else
        {
            uint256 timeStaked = stakeEndTime - _oneStake.timeOfStake;
            _rewards = _oneStake.amount*multiplier*timeStaked;}
    
        return _rewards;
    }
    function viewRewards()external view returns(uint256){
         uint256 claimableRewards;
         uint256 _rewards;
         for(uint256 a=0;a<totalNoOfStakes[msg.sender];a++){
            _rewards = _viewCalculateRewards(cumulativeStakes[msg.sender][a]);
             if(block.timestamp  > stakeEndTime){
                claimableRewards = claimableRewards + (_rewards*20/100);
                
             }
             if(block.timestamp > stakeEndTime + (2629746)){
                claimableRewards = claimableRewards + (_rewards*20/100);
                
             }
             if(block.timestamp > stakeEndTime + (2629746*2)){
                claimableRewards = claimableRewards + (_rewards*20/100);
                
             }
             if(block.timestamp > stakeEndTime + (2629746*3)){
                claimableRewards = claimableRewards + (_rewards*20/100);
                
             }
             if(block.timestamp  > stakeEndTime + (2629746*4) ){
                claimableRewards = claimableRewards + (_rewards*20/100);
                
             }
             }
             
             return claimableRewards - totalClaimedReward[msg.sender] ;
    }
    function getAllStakes()public view returns(stake[] memory){
        return cumulativeStakes[msg.sender];
    }
}