// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

interface IOUROVesting {
    function vest(address account, uint256 amount) external;
    function setPaymentAccount(address paymentAccount) external;
}

/**
 * @dev OURO Staking contract
 */
contract OUROStaking is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
    uint256 internal constant SHARE_MULTIPLIER = 1e18; // share multiplier to avert division underflow
    
    address public constant ouroContract = 0x0a4FC79921f960A4264717FeFEE518E088173a79;
    address public constant ogsContract = 0x416947e6Fc78F158fd9B775fA846B72d768879c2;
    address public ogsPaymentAccount = 0x71FfD4175Eef64d455B7eaa0e1d952B0F08c0675;
    address public immutable vestingContract;

    mapping (address => uint256) private _balances; // tracking staker's value
    mapping (address => uint256) internal _rewardBalance; // tracking staker's claimable reward tokens
    uint256 private _totalStaked; // track total staked value
    
    /// @dev initial block reward
    uint256 public BlockReward = 0;
    /// @dev hard cap of ogs reward
    uint256 public constant TokenRewardHardCap = 50000000000 * 1e18;
    // @dev token rewarded counting
    uint256 public TokenRewarded = 0;
    
    /// @dev round index mapping to accumulate share.
    mapping (uint => uint) private _accShares;
    /// @dev mark staker's highest settled round.
    mapping (address => uint) private _settledRounds;
    /// @dev a monotonic increasing round index, STARTS FROM 1
    uint256 private _currentRound = 1;
    // @dev last rewarded block
    uint256 private _lastRewardBlock = block.number;
    
    /**
     * ======================================================================================
     * 
     * SYSTEM FUNCTIONS
     *
     * ======================================================================================
     */
    constructor() public {
        vestingContract = address(new OUROVesting());
    }
    
    /**
     * @dev set block reward
     */
    function setBlockReward(uint256 reward) external onlyOwner {
        // settle previous rewards
        _updateReward();
        // set new block reward
        BlockReward = reward;
            
        // log
        emit BlockRewardSet(reward);
    }
    

    /**
     * @dev set block reward payment account
     */
    function setPaymentAccount(address paymentAccount) external onlyOwner {
        require(paymentAccount != address(0));
        ogsPaymentAccount = paymentAccount;

        // log
        emit PaymentAccountSet(paymentAccount);

        // also, set ouro vesting payment account;
        IOUROVesting(vestingContract).setPaymentAccount(paymentAccount);
    }
    
    /**
     * @dev called by the owner to pause, triggers stopped state
     **/
    function pause() onlyOwner external { _pause(); }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner external { _unpause(); }
    /**
     * ======================================================================================
     * 
     * STAKING FUNCTIONS
     *
     * ======================================================================================
     */
     
    /**
     * @dev stake OURO
     */
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "zero deposit");
        // settle previous rewards
        _settleStaker(msg.sender);
        
        // modifiy
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalStaked = _totalStaked.add(amount);
        
        // transfer asset from AssetContract
        IERC20(ouroContract).safeTransferFrom(msg.sender, address(this), amount);
        
        // log
        emit Deposit(msg.sender, amount);
    }
    
    /**
     * @dev vest OGS rewards
     */
    function vestReward() external {
        // settle previous rewards
        _settleStaker(msg.sender);
        
        // reward balance modification
        uint amountReward = _rewardBalance[msg.sender];
        delete _rewardBalance[msg.sender]; // zero reward balance

        // vest reward to sender
        IOUROVesting(vestingContract).vest(msg.sender, amountReward);

        // log
        emit RewardVested(msg.sender, amountReward);
    }
    
    /**
     * @dev withdraw the staked OURO
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount <= _balances[msg.sender], "balance exceeded");

        // settle previous rewards
        _settleStaker(msg.sender);

        // modifiy
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalStaked = _totalStaked.sub(amount);
        
        // transfer assets back
        IERC20(ouroContract).safeTransfer(msg.sender, amount);
        
        // log
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev settle a staker
     */
    function _settleStaker(address account) internal {
        // update reward snapshot
        _updateReward();
        
        // settle this account
        uint accountCollateral = _balances[account];
        uint lastSettledRound = _settledRounds[account];
        uint newSettledRound = _currentRound - 1;
        
        // round rewards
        uint roundReward = _accShares[newSettledRound].sub(_accShares[lastSettledRound])
                                .mul(accountCollateral)
                                .div(SHARE_MULTIPLIER);  // remember to div by SHARE_MULTIPLIER    
        
        // update reward balance
        _rewardBalance[account] += roundReward;
        
        // mark new settled reward round
        _settledRounds[account] = newSettledRound;
    }
     
    /**
     * @dev update accumulated block reward until current block
     */
    function _updateReward() internal {
        // skip round changing in the same block
        if (_lastRewardBlock == block.number) {
            return;
        }
    
        // postpone rewarding if there is none staker
        if (_totalStaked == 0) {
            return;
        } 

        // settle reward share for [_lastRewardBlock, block.number]
        uint blocksToReward = block.number.sub(_lastRewardBlock);
        uint mintedReward = BlockReward.mul(blocksToReward);
        uint penalty = IERC20(ogsContract).balanceOf(address(this));
        
        // IMPORTANT!
        // bound to mint hard cap
        if (TokenRewarded.add(mintedReward) > TokenRewardHardCap) {
            mintedReward = TokenRewardHardCap.sub(TokenRewarded);
        }
        
        // count rewarded tokens
        TokenRewarded = TokenRewarded.add(mintedReward);

        // reward share(including penalty)
        uint roundShare = penalty.add(mintedReward)
                                    .mul(SHARE_MULTIPLIER)
                                    .div(_totalStaked);
                                
        // mark block rewarded;
        _lastRewardBlock = block.number;
            
        // accumulate reward share
        _accShares[_currentRound] = roundShare.add(_accShares[_currentRound-1]); 
        
        // IMPORTANT!
        // transfer penalty token to ogsPaymentAccount after setting reward share
        IERC20(ogsContract).safeTransfer(ogsPaymentAccount, penalty);
       
        // next round setting                                 
        _currentRound++;
    }
    
    /**
     * ======================================================================================
     * 
     * VIEW FUNCTIONS
     *
     * ======================================================================================
     */
        
    /**
     * @dev return value staked for an account
     */
    function numStaked(address account) external view returns (uint256) { return _balances[account]; }

    /**
     * @dev return total staked value
     */
    function totalStaked() external view returns (uint256) { return _totalStaked; }
     
    /**
     * @notice sum unclaimed reward;
     */
    function checkReward(address account) external view returns(uint256 rewards) {
        uint accountCollateral = _balances[account];
        uint lastSettledRound = _settledRounds[account];
        
        // reward = settled rewards + unsettled rewards + newMined rewards
        uint unsettledShare = _accShares[_currentRound-1].sub(_accShares[lastSettledRound]);
        
        uint newShare;
        if (_totalStaked > 0) {
            uint blocksToReward = block.number.sub(_lastRewardBlock);
            uint mintedReward = BlockReward.mul(blocksToReward);
            uint penalty = IERC20(ogsContract).balanceOf(address(this));

            // align to mint hard cap
            if (TokenRewarded.add(mintedReward) > TokenRewardHardCap) {
                mintedReward = TokenRewardHardCap.sub(TokenRewarded);
            }
            
            // reward share(including penalty)
            newShare = penalty.add(mintedReward)
                                    .mul(SHARE_MULTIPLIER)
                                    .div(_totalStaked);
        }
        
        return _rewardBalance[account] + (unsettledShare + newShare).mul(accountCollateral)
                                            .div(SHARE_MULTIPLIER);  // remember to div by SHARE_MULTIPLIER;
    }
    
    /**
     * ======================================================================================
     * 
     * STAKING EVENTS
     *
     * ======================================================================================
     */
     event Deposit(address account, uint256 amount);
     event Withdraw(address account, uint256 amount);
     event RewardVested(address account, uint256 amount);
     event BlockRewardSet(uint256 reward);
     event PaymentAccountSet(address account);
}


/**
 * @dev OURO Vesting contract
 */
contract OUROVesting is Ownable, IOUROVesting {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint256 internal constant DAY = 1 days;
    uint256 internal constant VestingPeriod = DAY * 90;
    
    address public constant ogsContract = 0x416947e6Fc78F158fd9B775fA846B72d768879c2;
    address public ogsPaymentAccount = 0x71FfD4175Eef64d455B7eaa0e1d952B0F08c0675;
    
    // @dev vesting assets are grouped by day
    struct Round {
        mapping (address => uint256) balances;
        uint startDate;
    }
    
    /// @dev round index mapping
    mapping (int256 => Round) public rounds;
    /// @dev a monotonic increasing index
    int256 public currentRound = 0;

    /// @dev current vested rewards    
    mapping (address => uint256) private balances;

    /// @dev keep last lock round for each user
    mapping (address => int256) public lastLockRounds;
    
    /**
    * ======================================================================================
    * 
    * SYSTEM FUNCTIONS
    * 
    * ======================================================================================
    */
    constructor() public {
        rounds[0].startDate = block.timestamp;
    }

    /**
     * @dev round update operation
     */
    function _update() internal {
        uint numDays = block.timestamp.sub(rounds[currentRound].startDate).div(DAY);
        if (numDays > 0) {
            currentRound++;
            rounds[currentRound].startDate = rounds[currentRound-1].startDate + numDays * DAY;
        }
    }
    
    /**
     * ======================================================================================
     * 
     * VESTING FUNCTIONS
     *
     * ======================================================================================
     */
     
    /**
     * @dev vest some OGS tokens for an account
     */
    function vest(address account, uint256 amount) external override onlyOwner {
        _update();

        rounds[currentRound].balances[account] += amount;
        balances[account] += amount;
        
        // keep latest vest round
        lastLockRounds[account] = currentRound;

        // emit amount vested
        emit Vested(account, amount);
    }
    
     /**
     * @dev set block reward payment account
     */
    function setPaymentAccount(address paymentAccount) external override onlyOwner {
        require(paymentAccount != address(0));
        ogsPaymentAccount = paymentAccount;

        // log
        emit PaymentAccountSet(paymentAccount);
    }

    /**
     * @dev claim unlocked rewards without penalty
     */
    function claimUnlocked() external {
        _update();
        
        uint256 unlockedAmount = checkUnlocked(msg.sender);
        balances[msg.sender] -= unlockedAmount;
        IERC20(ogsContract).safeTransferFrom(ogsPaymentAccount, msg.sender, unlockedAmount);
        
        emit Claimed(msg.sender, unlockedAmount);
    }

    /**
     * @dev claim all rewards with penalty(50%)
     */
    function claimAllWithPenalty() external {
        _update();
        
        uint256 lockedAmount = checkLocked(msg.sender);
        uint256 penalty = lockedAmount/2;
        uint256 rewardsToClaim = balances[msg.sender].sub(penalty);

        // reset balances which still locked to 0
        uint256 earliestVestedDate = block.timestamp - VestingPeriod;
        for (int256 i = lastLockRounds[msg.sender]; i>=0; i--) {
            if (rounds[i].startDate < earliestVestedDate) {
                break;
            } else {
                delete rounds[i].balances[msg.sender];
            }
        }
        
        // reset user's total balance to 0
        delete balances[msg.sender];
        
        // transfer rewards to msg.sender        
        if (rewardsToClaim > 0) {
            IERC20(ogsContract).safeTransferFrom(ogsPaymentAccount, msg.sender, rewardsToClaim);
            emit Claimed(msg.sender, rewardsToClaim);
        }
        
        // 50% penalty token goes to OURO staking contract(which is owner)
        if (penalty > 0) {
            IERC20(ogsContract).safeTransferFrom(ogsPaymentAccount, owner(), penalty);
            emit Penalty(msg.sender, penalty);
        }
    }

    /**
     * ======================================================================================
     * 
     * VIEW FUNCTIONS
     *
     * ======================================================================================
     */
    
    /**
     * @dev check total vested token
     */
    function checkVested(address account) public view returns(uint256) { return balances[account]; }
    
    /**
     * @dev check current locked token
     */
    function checkLocked(address account) public view returns(uint256) {
        uint256 earliestVestedDate = block.timestamp - VestingPeriod;
        uint256 lockedAmount;
        for (int256 i = lastLockRounds[account]; i>=0; i--) {
            if (rounds[i].startDate < earliestVestedDate) {
                break;
            } else {
                lockedAmount += rounds[i].balances[account];
            }
        }
        
        return lockedAmount;
    }

    /**
     * @dev check current claimable rewards without penalty
     */
    function checkUnlocked(address account) public view returns(uint256) {
        uint256 lockedAmount = checkLocked(account);
        return balances[account].sub(lockedAmount);
    }
    
    /**
     * @dev Events
     * ----------------------------------------------------------------------------------
     */
    event Vestable(address account);
    event Unvestable(address account);
    event Penalty(address account, uint256 amount);
    event Vested(address account, uint256 amount);
    event Claimed(address account, uint256 amount);
    event PaymentAccountSet(address account);
}