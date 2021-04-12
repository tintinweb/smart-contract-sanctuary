// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @dev LP Staking Contract for LP token
 */
contract LPStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IBIMToken;
    using SafeERC20 for IERC20;

    uint256 constant DAY = 86400;
    uint256 constant WEEK = DAY * 7;
    uint256 constant MONTH = DAY * 30;
    
    IBIMToken public BIMContract;
    IERC20 public LPToken;
    IBIMVesting public BIMVestingContract;
    
    mapping (address => uint256) private _balances; // staker's balance
    uint256 private _totalStaked; // sum of balance
    
    constructor(IBIMToken bimContract, IERC20 lpToken, IBIMVesting bimVesting) 
        public {
        BIMContract = bimContract;
        LPToken = lpToken;
        BIMVestingContract = bimVesting;
    }

    /**
     * @dev deposit LP token
     */
    function deposit(uint256 amount) external {
        settleStakerBIMReward(msg.sender);
                
        // transfer LP token from msg.sender
        LPToken.safeTransferFrom(msg.sender, address(this), amount);
        // modify sender's balance
        _balances[msg.sender] += amount;
        // sum up total staked LP tokens
        _totalStaked += amount;
        
        // log
        emit Deposit(msg.sender, amount);
    }
        
    /**
     * @dev withdraw LP token previously deposited
     */
    function withdraw(uint256 amount) external {
        require(amount <= _balances[msg.sender], "balance exceeded");
        
        settleStakerBIMReward(msg.sender);
                
        // modify account
        _balances[msg.sender] -= amount;
        // sub total staked
        _totalStaked -= amount;
        
        // transfer LP token back to msg.sender
        LPToken.safeTransfer(msg.sender, amount);
        
        // log
        emit Withdraw(msg.sender, amount);
    }
    
    /**
     * @dev return value staked for an account
     */
    function numStaked(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev return total staked value
     */
    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    /**
     * @dev BIM Rewarding
     * ----------------------------------------------------------------------------------
     */
     
    mapping (address => uint256) internal _bimBalance;  // tracking staker's claimable bim
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
    /// @dev last BIM balance
    uint256 private _lastBIMBalance;
    
    uint256 internal constant SHARE_MULTIPLIER = 1e18; // share multiplier to avert division underflow

    /**
     * @dev set BIM reward per height
     */
    function setBIMBlockReward(uint256 reward) external onlyOwner {
        // settle previous BIM round first
        updateBIMRound();
        
        // set new block reward
        BIMBlockReward = reward;
    }
    
    /**
     * @dev claim bonus BIMs with redirect BIMS to IBIM
     */
    function claimBIMReward() external {
        settleStakerBIMReward(msg.sender);
        
        // BIM balance modification
        uint bims = _bimBalance[msg.sender];
        delete _bimBalance[msg.sender]; // zero balance

        // vest new minted BIM
        BIMVestingContract.vest(msg.sender, bims);
        
        // log
        emit BIMClaimed(msg.sender, bims);
    }
    
    /**
     * @notice sum unclaimed rewards;
     */
    function checkBIMReward(address account) external view returns(uint256 bim) {
        // reward = settled + unsettled + newMined
        uint lastSettledRound = _settledBIMRounds[account];
        uint unsettledShare = _accBIMShares[_currentBIMRound-1].sub(_accBIMShares[lastSettledRound]);
        
        uint newBIMShare;
        if (_totalStaked > 0 && BIMContract.maxSupply() > BIMContract.totalSupply()) {
            uint blocksToReward = block.number.sub(_lastBIMRewardBlock);
            uint bimsToMint = BIMBlockReward.mul(blocksToReward);
            uint remain = BIMContract.maxSupply().sub(BIMContract.totalSupply());
            // cap to BIM max supply
            if (remain < bimsToMint) {
                bimsToMint = remain;
            }
    
            // BIM share
            newBIMShare = bimsToMint.mul(SHARE_MULTIPLIER)
                                        .div(_totalStaked);
        }
        
        return _bimBalance[account] + (unsettledShare + newBIMShare)
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
     * @dev update accumulated BIM block reward until current block
     */
    function updateBIMRound() internal {
         // skip round changing in the same block
        if (_lastBIMRewardBlock == block.number) {
            return;
        }
    
        // postpone BIM rewarding if there is none staker
        if (_totalStaked == 0) {
            return;
        }
        
        // mint BIM
        uint bimsToMint;
        if (BIMContract.maxSupply() > BIMContract.totalSupply()) {
            // mint BIM for (_lastRewardBlock, block.number]
            uint blocksToReward = block.number.sub(_lastBIMRewardBlock);
            bimsToMint = BIMBlockReward.mul(blocksToReward);
            uint remain = BIMContract.maxSupply().sub(BIMContract.totalSupply());
            // cap to BIM max supply
            if (remain < bimsToMint) {
                bimsToMint = remain;
            }
            
            if (bimsToMint > 0) {
                // BIM mint to BIMVestingContract
                BIMContract.mint(address(BIMVestingContract), bimsToMint); 
            }
        }

        // BIM share
        uint roundBIMShare = bimsToMint.mul(SHARE_MULTIPLIER)
                                    .div(_totalStaked);
                                
        // mark block rewarded;
        _lastBIMRewardBlock = block.number;
            
        // accumulate BIM share
        _accBIMShares[_currentBIMRound] = roundBIMShare.add(_accBIMShares[_currentBIMRound-1]); 
       
        // next round setting                                 
        _currentBIMRound++;
    }
    
        
    /**
     * @dev Events
     * ----------------------------------------------------------------------------------
     */
     
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event BIMClaimed(address account, uint256 amount);
}