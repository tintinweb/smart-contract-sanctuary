/**
 *Submitted for verification at cronoscan.com on 2022-06-05
*/

/**
 *Submitted for verification at cronoscan.com on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

contract GemWingsFarm is Auth {

    struct Stake {
        uint256 stakedAmount;
        uint256 rewardsEitherPaidOutAlreadyOrNeverEligibleFor;
        uint256 totalRewardsCollectedAlready;
        uint256 lastStaked;
        uint256 lockedUntil;
    }

    address public stakingToken;

    uint256 public totalRewardsSentOutAlready;
    uint256 public totalStakedTokens;

    mapping (address => Stake) public stakes;

	event Realised(address account, uint amount);
    event Staked(address account, uint stakedAmount);
    event Unstaked(address account, uint amount);

    constructor (address _stakingToken) Auth(msg.sender) {
        stakingToken = _stakingToken;
    }

    uint256 _accuracyFactor = 10 ** 36;
    uint256 public _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed;
    uint256 public _currentContractBalanceOfRewards;
    uint256 public _lastContractBalanceOfRewards;
    uint256 public _lockDuration = 0;

    function getTotalRewards() external view  returns (uint256) {
        return totalRewardsSentOutAlready + IBEP20(stakingToken).balanceOf(address(this)) - totalStakedTokens;
    }

    function getCumulativeRewardsPerLP() external view returns (uint256) {
        return _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed;
    }

    function getLastContractBalance() external view returns (uint256) {
        return _lastContractBalanceOfRewards;
    }

    function getAccuracyFactor() external view returns (uint256) {
        return _accuracyFactor;
    }

    function getStake(address account) public view returns (uint256) {
        return stakes[account].stakedAmount;
    }

    function getRealisedEarnings(address staker) external view returns (uint256) {
        return stakes[staker].totalRewardsCollectedAlready; // realised gains plus outstanding earnings
    }

    function getUnrealisedEarnings(address staker) external view returns (uint256) {
        if(stakes[staker].stakedAmount == 0){ return 0; }

        uint256 totalRewardsIfFirstStakerAndNeverClaimed = stakes[staker].stakedAmount * getCurrentRewardsPerLP() / _accuracyFactor;
        uint256 stakerrewardsEitherPaidOutAlreadyOrNeverEligibleFor = stakes[staker].rewardsEitherPaidOutAlreadyOrNeverEligibleFor;

        if (totalRewardsIfFirstStakerAndNeverClaimed <= stakerrewardsEitherPaidOutAlreadyOrNeverEligibleFor) {
			return 0;
		}

        return totalRewardsIfFirstStakerAndNeverClaimed - stakerrewardsEitherPaidOutAlreadyOrNeverEligibleFor;
    }

    function getCumulativeRewards(uint256 amount) public view returns (uint256) {
        return amount * _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed / _accuracyFactor;
    }

    

    function stake(uint amount) external {
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function stakeFor(address staker, uint amount) external {
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(staker, amount);
    }
    
    function stakeAll() external {
        uint256 amount = IBEP20(stakingToken).balanceOf(msg.sender);
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    

    function unstake(uint amount) external {
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function unstakeAll() external {
        uint256 amount = getStake(msg.sender);
        require(amount > 0);

        _unstake(msg.sender, amount);
    }
    function realiseFromTokenContract(address staker) external {
        require(msg.sender == stakingToken, "Only the tokencontract can use this");
        _realise(staker);
    }

    function realise() external {
        _realise(msg.sender);
    }

    function balanceOfRewards() public view returns (uint256) {
        return IBEP20(stakingToken).balanceOf(address(this)) - totalStakedTokens;
    }

    function _realise(address staker) internal {
        _currentContractBalanceOfRewards = balanceOfRewards();

        if (_currentContractBalanceOfRewards > _lastContractBalanceOfRewards && totalStakedTokens != 0) {
            uint256 newRewards = _currentContractBalanceOfRewards - _lastContractBalanceOfRewards;
            uint256 additionalAmountPerStakedToken = newRewards * _accuracyFactor / totalStakedTokens;
            _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed += additionalAmountPerStakedToken;
        }

        if (totalStakedTokens > 0) {
			_lastContractBalanceOfRewards = _currentContractBalanceOfRewards;
		}

        uint256 totalRewardsIfFirstStakerAndNeverClaimed = stakes[staker].stakedAmount *  _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed / _accuracyFactor;

        if(stakes[staker].stakedAmount == 0 || totalRewardsIfFirstStakerAndNeverClaimed <= stakes[staker].rewardsEitherPaidOutAlreadyOrNeverEligibleFor){
            return;
        }

        uint256 rewardsBeingSentToStaker = totalRewardsIfFirstStakerAndNeverClaimed - stakes[staker].rewardsEitherPaidOutAlreadyOrNeverEligibleFor;

        stakes[staker].totalRewardsCollectedAlready += rewardsBeingSentToStaker;
        stakes[staker].rewardsEitherPaidOutAlreadyOrNeverEligibleFor += rewardsBeingSentToStaker;
        totalRewardsSentOutAlready += rewardsBeingSentToStaker;

        IBEP20(stakingToken).transfer(staker, rewardsBeingSentToStaker);

        if (totalStakedTokens > 0) {
			_lastContractBalanceOfRewards = balanceOfRewards();
		}

        emit Realised(staker, rewardsBeingSentToStaker);
    }

    function _stake(address staker, uint256 stakedAmount) internal {
        require(stakedAmount > 0);

        _realise(staker);

        // add to current address' stake
        stakes[staker].stakedAmount += stakedAmount;
        stakes[staker].rewardsEitherPaidOutAlreadyOrNeverEligibleFor = stakes[staker].stakedAmount * _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed / _accuracyFactor;
        totalStakedTokens += stakedAmount;
        stakes[staker].lastStaked = block.timestamp;
        stakes[staker].lockedUntil = block.timestamp + _lockDuration;

        emit Staked(staker, stakedAmount);
    }

    function _unstake(address staker, uint256 amount) internal {
        require(stakes[staker].stakedAmount >= amount, "Insufficient Stake");
        require(stakes[staker].lockedUntil <= block.timestamp, "Your staked tokens ares still locked, please try again later");

        _realise(staker); // realise staking gains

        // remove stake
        stakes[staker].stakedAmount -= amount;
        stakes[staker].rewardsEitherPaidOutAlreadyOrNeverEligibleFor = stakes[staker].stakedAmount * _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed / _accuracyFactor;
        totalStakedTokens -= amount;

        IBEP20(stakingToken).transfer(staker, amount);
        emit Unstaked(staker, amount);
    }

    function getCurrentRewardsPerLP() public view returns (uint256 currentRewardsPerLP) {
        if(balanceOfRewards() > _lastContractBalanceOfRewards && totalStakedTokens != 0){
            uint256 newRewards = balanceOfRewards() - _lastContractBalanceOfRewards;
            uint256 additionalAmountPerStakedToken = newRewards * _accuracyFactor / totalStakedTokens;
            currentRewardsPerLP = _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed + additionalAmountPerStakedToken;
        }
    }

    function setAccuracyFactor(uint256 newFactor) external authorized {
        _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed = _rewardsPerTokenStakedIfStakedSinceStartAndNeverClaimed * newFactor / _accuracyFactor;
        _accuracyFactor = newFactor;
    }

    
    
    
    
    
    
    
    
    
    
    
    
    function emergencyUnstakeAll() external {
        require(stakes[msg.sender].stakedAmount > 0, "No Stake");

        IBEP20(stakingToken).transfer(msg.sender, stakes[msg.sender].stakedAmount);
        totalStakedTokens -= stakes[msg.sender].stakedAmount;
        stakes[msg.sender].stakedAmount = 0;
    }

    function stakeAllFromTokenContract(address staker) external {
        require(msg.sender == stakingToken, "Only the tokencontract can use this");
        uint256 amount = IBEP20(stakingToken).balanceOf(staker);
        require(amount > 0);
        IBEP20(stakingToken).transferFrom(staker, address(this), amount);
        _stake(staker, amount);
    }

    function stakeFromTokenContract(address staker, uint256 amount) external {
        require(msg.sender == stakingToken, "Only the tokencontract can use this");
        IBEP20(stakingToken).transferFrom(staker, address(this), amount);
        _stake(staker, amount);
    }

    function unstakeAllFromTokenContract(address staker) external {
        require(msg.sender == stakingToken, "Only the tokencontract can use this");
        uint256 amount = getStake(staker);
        require(amount > 0);
        _unstake(staker, amount);
    }

    function unstakeFromTokenContract(address staker, uint amount) external {
        require(msg.sender == stakingToken, "Only the tokencontract can use this");
        require(amount > 0);
        _unstake(staker, amount);
    }
}