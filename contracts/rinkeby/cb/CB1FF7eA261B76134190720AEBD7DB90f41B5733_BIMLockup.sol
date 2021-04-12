// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @dev BIM Lockup contract
 */
contract BIMLockup is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IBIMToken;

    uint256 internal constant DAY = 10; // @dev MODIFY TO 86400 BEFORE PUBLIC RELEASE
    uint256 internal constant WEEK = DAY * 7;
    uint256 internal constant MONTH = DAY * 30;
    
    IBIMToken public BIMContract;
    
    // @dev lockup assets deposits are grouped by week
    struct Round {
        mapping (address => uint256) balances; // weekly user's lockup
        uint vestFrom; // [vestfrom -- MONTH -- releaseday]
    }
    
    /// @dev rounds indexing
    mapping (int256 => Round) public rounds;
    /// @dev a monotonic increasing index
    int256 public currentRound = 0;

    /// @dev lockup balance for all rounds sumed
    mapping (address => uint256) private _balances;
    
    /// @dev total locked-up
    uint256 private _totalLockedUp;
    
    constructor(IBIMToken bimContract) 
        public {
        BIMContract = bimContract;
        rounds[0].vestFrom = block.timestamp; // create an week already in vesting
    }

    /**
     * @dev function called before every user's interaction
     */
    function updateWeek() internal {
        // create a new weekly round for deposit if recent week ends.
        if (block.timestamp > rounds[currentRound].vestFrom) {
            currentRound++;
            // lockups are grouped weekly
            rounds[currentRound].vestFrom = rounds[currentRound-1].vestFrom + WEEK;
        }
    }
    
    /**
     * @dev return total value locked
     */
    function tvl() external view returns (uint256) {
        return _totalLockedUp;
    }
    
    /**
     * @dev lockup BIM
     */
    function lockup(uint256 amount) external {
        updateWeek();
        
        // settle the caller's previous BIM rewards before account balance change
        settleStakerBIMReward(msg.sender);
        
        // transfer BIM from msg.sender
        BIMContract.safeTransferFrom(msg.sender, address(this), amount);
        // group deposits in current week to avert unbounded gas consumption in withdraw
        rounds[currentRound].balances[msg.sender] += amount;
        // modify sender's overall lockup balance
        _balances[msg.sender] += amount;
        // bookkeeping total locked BIMs
        _totalLockedUp += amount;
        
        // log
        emit Lockup(msg.sender, amount);
    }
    
    /**
     * @dev withdraw BIM previously(1 month ago) deposited
     */
    function withdraw() external {
        updateWeek();

        uint256 unlockedAmount = checkUnlocked(msg.sender);
        require(unlockedAmount > 0, "0 unlocked");
                
        // settle the caller's previous BIM rewards before account balance change
        settleStakerBIMReward(msg.sender);

        // modify sender's overall lockup balance only
        _balances[msg.sender] -= unlockedAmount;
        
        // sub total locked up
        _totalLockedUp -= unlockedAmount;
        
        // transfer unlocked amount
        BIMContract.safeTransfer(msg.sender, unlockedAmount);
        
        // log
        emit Withdraw(msg.sender, unlockedAmount);
    }
    
    /**
     * @dev check lockup balance
     */
    function checkLockupBalance(address account) public view returns(uint256) {
        return _balances[account];
    }
    
    /**
     * @dev get value still locked up
     */
    function checkLocked(address account) public view returns(uint256) {
        uint256 monthAgo = block.timestamp - MONTH;

        // this loop is bounded to: N = 30days/7days + 1 = 5
        uint256 lockedAmount;
        for (int256 i= currentRound; i>=0; i--) {
            if (rounds[i].vestFrom < monthAgo) {
                break;
            } else {
                // sum weekly balance
                lockedAmount += rounds[i].balances[account];
            }
        }
        
        return lockedAmount;
    }
        
    /**
     * @dev get current unlocked deposits
     */
    function checkUnlocked(address account) public view returns(uint256) {
        uint256 lockedAmount = checkLocked(account);
        return _balances[account].sub(lockedAmount);
    }

    /**
     * @dev BIM Rewarding is based on block.number
     * ----------------------------------------------------------------------------------
     */
     
    /// @dev bim reward balance
    mapping (address => uint256) internal _bimBalance;  
    /// @dev round index mapping to accumulate sharea.
    mapping (uint => uint) private _accBIMShares;
    /// @dev mark holders' highest settled round.
    mapping (address => uint) private _settledBIMRounds;
    /// @dev a monotonic increasing round index, STARTS FROM 1
    uint256 private _currentBIMRound = 1;
    // @dev last BIM reward block
    uint256 private _lastBIMRewardBlock = block.number;
    // @dev BIM rewards per block
    uint256 public BIMBlockReward = 0;
    /// @dev total bim unclaimed rewards in total;
    uint256 private _BIMUnclaimed;
    
    uint256 internal constant SHARE_MULTIPLIER = 1e18; // share multiplier to avert division underflow

    /**
     * @dev set BIM reward per height
     */
    function setBIMBlockReward(uint256 reward) external onlyOwner {
        // settle previous rewards round
        updateBIMRound();
        
        // set new block reward
        BIMBlockReward = reward;
    }
    
    /**
     * @dev claim bonus BIMs for msg.sender
     */
    function claimBIMReward() external {
        // settle the caller's BIM before claim
        settleStakerBIMReward(msg.sender);
        
        // BIM balance modification
        uint bims = _bimBalance[msg.sender];
        delete _bimBalance[msg.sender]; // zero balance
        
        // count unclaimed BIMS
        _BIMUnclaimed -= bims;
        
        // transfer BIM
        BIMContract.safeTransfer(msg.sender, bims);
        
        // log
        emit BIMClaimed(msg.sender, bims);
    }
    
    /**
     * @notice sum unclaimed rewards for an account
     */
    function checkBIMReward(address account) external view returns(uint256 bim) {
        // reward = settled + unsettled + newMined + balance diff
        uint lastSettledRound = _settledBIMRounds[account];
        uint unsettledShare = _accBIMShares[_currentBIMRound-1].sub(_accBIMShares[lastSettledRound]);
        
        // block rewards
        uint bimsToMint;
        if (BIMContract.maxSupply() > BIMContract.totalSupply()) {
            uint blocksToReward = block.number.sub(_lastBIMRewardBlock);
            bimsToMint = BIMBlockReward.mul(blocksToReward);
            uint remain = BIMContract.maxSupply().sub(BIMContract.totalSupply());
            if (remain < bimsToMint) {
                bimsToMint = remain;
            }
        }
        
        // count new bim to reward including penalty
        // Formula:
        // newReward = contract balance - _totalLockedUp - _BIMUnclaimed + bimsToMint
        uint bimToReward = BIMContract.balanceOf(address(this)).sub(_totalLockedUp)
                                                                .add(bimsToMint)
                                                                .sub(_BIMUnclaimed);

        // new distributable share
        uint newShare;
        if (_totalLockedUp > 0) {
            newShare = bimToReward.mul(SHARE_MULTIPLIER)
                                    .div(_totalLockedUp);
        }
        
        return _bimBalance[account] + (unsettledShare + newShare)
                                            .mul(_balances[account])
                                            .div(SHARE_MULTIPLIER);  // remember to div by SHARE_MULTIPLIER;
    }
    
    /**
     * @dev settle a staker's BIM rewards
     */
    function settleStakerBIMReward(address account) internal {
        updateBIMRound();
        
         // settle this account
        uint lastSettledRound = _settledBIMRounds[account];
        uint newSettledRound = _currentBIMRound - 1;
        
        // round BIM
        uint roundBIM = _accBIMShares[newSettledRound].sub(_accBIMShares[lastSettledRound])
                                .mul(_balances[account])
                                .div(SHARE_MULTIPLIER);  // remember to div by SHARE_MULTIPLIER    
        
        // update BIM balance
        _bimBalance[account] += roundBIM;
        
        // mark new settled BIM round
        _settledBIMRounds[account] = newSettledRound;
    }
    
    /**
     * @dev update accumulated BIM block reward until current block, and also penalty received
     */
    function updateBIMRound() internal {
        // postpone BIM rewarding if there is none locked-up
        if (_totalLockedUp == 0) {
            return;
        }
        
        // mint if BIMContract is mintable
        if (BIMContract.maxSupply() > BIMContract.totalSupply()) {
            // mint BIM for (_lastRewardBlock, block.number]
            uint blocksToReward = block.number.sub(_lastBIMRewardBlock);
            uint bimsToMint = BIMBlockReward.mul(blocksToReward);
            uint remain = BIMContract.maxSupply().sub(BIMContract.totalSupply());
            // cap to BIM max supply
            if (remain < bimsToMint) {
                bimsToMint = remain;
            }
            
            if (bimsToMint > 0) {
                // mint to this contract
                BIMContract.mint(address(this), bimsToMint);
            }
            
            // mark block rewarded;
            _lastBIMRewardBlock = block.number;
        }

        // compute new BIMS received since last updateBIMRound this also re-distributes BIM-penalty received from:
        // BIMVesting Contract (early exit)
        //
        // As contract balance consists only of user's locked up assets and UNCLAIMED reward BIMS.
        // Formula:
        //  newReward = contract balance - _totalLockedUp - _BIMUnclaimed
        uint bimToReward = BIMContract.balanceOf(address(this)).sub(_totalLockedUp).sub(_BIMUnclaimed);
        if (bimToReward == 0) {
            return;
        }

        // BIM share
        uint roundBIMShare = bimToReward.mul(SHARE_MULTIPLIER)
                                    .div(_totalLockedUp);
        
        // track bim unclaimed
        _BIMUnclaimed += bimToReward;
            
        // accumulate BIM share
        _accBIMShares[_currentBIMRound] = roundBIMShare.add(_accBIMShares[_currentBIMRound-1]); 
       
        // next round setting                                 
        _currentBIMRound++;
    }
    
    /**
     * @dev Events
     * ----------------------------------------------------------------------------------
     */
     
    event Lockup(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event BIMClaimed(address account, uint256 amount);
}