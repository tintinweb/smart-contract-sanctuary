// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @dev EHC Staking contract
 */
contract EHCStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IEHCToken;
    using SafeERC20 for IBIMToken;
    using SafeMath for uint;
    
    uint256 internal constant SHARE_MULTIPLIER = 1e18; // share multiplier to avert division underflow
    
    IERC20 public ETHContract;
    IBIMToken public BIMContract;
    IBIMVesting public BIMVestingContract;
    IEHCToken public EHCTokenContract; // the EHC token contract
    
    mapping (address => uint256) private _balances; // tracking staker's value
    uint256 private _totalStaked; // track total staked value 
    
    /**
     * @dev ETH Rewarding
     */
    mapping (address => uint256) internal _ethBalance;  // tracking staker's claimable eth
    /// @dev round index mapping to accumulate sharea.
    mapping (uint => uint) private _accETHShares;
    /// @dev mark holders' highest settled round.
    mapping (address => uint) private _settledETHRounds;
    /// @dev a monotonic increasing round index, STARTS FROM 1
    uint256 private _currentETHRound = 1;
    /// @dev record unclaimed ETH
    uint256 private _ethersUnclaimed;
    /// @dev record total received ETH;
    uint256 public accEtherRewards;

    constructor(IERC20 ethContract, IBIMToken bimContract, IEHCToken ehcToken, IBIMVesting bimVesting) 
        public {
        ETHContract = ethContract;
        BIMContract = bimContract;
        EHCTokenContract = ehcToken;
        BIMVestingContract = bimVesting;
    }
    
    /**
     * @dev deposit EHC
     */
    function deposit(uint256 amount) external {
        // settle previous rewards
        settleStakerEthers(msg.sender);
        settleStakerBIM(msg.sender);
        
        // transfer EHC from msg.sender
        EHCTokenContract.safeTransferFrom(msg.sender, address(this), amount);
        
        _balances[msg.sender] += amount;
        _totalStaked += amount;
                
        // log
        emit Deposit(msg.sender, amount);
    }
    
    /**
     * @dev withdraw EHC
     */
    function withdraw(uint256 amount) external {
        require(amount <= _balances[msg.sender], "balance exceeded");
        
        // settle previous rewards
        settleStakerEthers(msg.sender);
        settleStakerBIM(msg.sender);
        
        // modifiy
        _balances[msg.sender] -= amount;
        _totalStaked -= amount;
        
        // transfer EHC back to msg.sender
        EHCTokenContract.safeTransfer(msg.sender, amount);
                
        // log
        emit Withdraw(msg.sender, amount);
    }
    
    /**
     * @dev claim ethers & bims
     */
    function claim() external {
        claimEthers();
        claimBIM();
    }
    
    /**
     * @dev claim ethers
     */
    function claimEthers() public {
        // settle previous rewards
        settleStakerEthers(msg.sender);
        
        // balance modification
        uint ethers = _ethBalance[msg.sender];
        delete _ethBalance[msg.sender]; // zero balance

        // transfer ETH to sender
        ETHContract.safeTransfer(msg.sender, ethers);
        
        // track unclaimed ethers
        _ethersUnclaimed -= ethers;
        
        // log
        emit EthersClaimed(msg.sender, ethers);
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
     * @notice sum unclaimed ether rewards;
     */
    function checkETHReward(address account) external view returns(uint256 ethers) {
        // reward = settled + unsettled + balanceDiff + new mined
        uint lastSettledRound = _settledETHRounds[account];
        uint unsettledShare = _accETHShares[_currentETHRound-1].sub(_accETHShares[lastSettledRound]);
        
        uint balanceDiff = ETHContract.balanceOf(address(this)).sub(_ethersUnclaimed); // received from nowhere, but not settled
        uint undistributedEthers = ETHContract.balanceOf(address(EHCTokenContract)).mul(70).div(100); // expected distribution in EHCTokenContract
        
        uint newShare;
        if (_totalStaked > 0) {
            newShare = undistributedEthers.add(balanceDiff)
                                            .mul(SHARE_MULTIPLIER)
                                            .div(_totalStaked);
        }
        
        return _ethBalance[account] + (unsettledShare + newShare)
                                            .mul(_balances[account])
                                            .div(SHARE_MULTIPLIER);  // remember to div by SHARE_MULTIPLIER;
    }

    /**
     * @dev settle a staker's ethers
     */
    function settleStakerEthers(address account) internal {
        // update ethers snapshot
        updateEthersRound();
        
        // settle this account
        uint lastSettledRound = _settledETHRounds[account];
        uint newSettledRound = _currentETHRound - 1;
        
        // round ether rewards
        uint roundRewards = _accETHShares[newSettledRound].sub(_accETHShares[lastSettledRound]) 
                                .mul(_balances[account])
                                .div(SHARE_MULTIPLIER);  // remember to div by SHARE_MULTIPLIER    
        
        // update ether balance
        _ethBalance[account] += roundRewards;
        
        // mark new settled ethers rewards round
        _settledETHRounds[account] = newSettledRound;
    }
         
     /**
     * @dev update accumulated reward until current block
     */
    function updateEthersRound() internal nonReentrant {
        // postpone BIM rewarding if there is none staker
        if (_totalStaked == 0) {
            return;
        }
        
        // trigger EHCTokenContract to transfer ethers to this contract
        EHCTokenContract.distribute();
        
        // check diff with previous ETH balance
        uint balanceDiff = ETHContract.balanceOf(address(this)).sub(_ethersUnclaimed);
        if (balanceDiff == 0) {
            return;
        }
        
        // ethers share
        uint roundShare = balanceDiff
                            .mul(SHARE_MULTIPLIER)
                            .div(_totalStaked);
            
        // accumulate share
        _accETHShares[_currentETHRound] = roundShare.add(_accETHShares[_currentETHRound-1]); 
       
        // next round setting                                 
        _currentETHRound++;
        
        // update unclaimed ethers
        _ethersUnclaimed += balanceDiff;
        
        // record total ethers received
        accEtherRewards += balanceDiff;
    }
    
    
    /**
     * @dev BIM Rewarding
     * ======================================================================
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

    /**
     * @dev set BIM reward per block
     */
    function setBIMBlockReward(uint256 reward) external onlyOwner {
        // settle previous BIM round first
        updateBIMRound();
        
        // set new block reward
        BIMBlockReward = reward;
        
        // log
        emit BlockRewardSet(msg.sender, reward);
    }
        
    /**
     * @dev claim BIMS
     */
    function claimBIM() public {
        // settle previous rewards
        settleStakerBIM(msg.sender);
        
        // BIM balance modification
        uint bims = _bimBalance[msg.sender];
        delete _bimBalance[msg.sender]; // zero balance
        
        // vest new minted BIM
        BIMVestingContract.vest(msg.sender, bims);
        
        // log
        emit BIMClaimed(msg.sender, bims);
    }
    
    /**
     * @notice sum unclaimed BIM rewards;
     */
    function checkBIMReward(address account) external view returns(uint256 bim) {
        // reward = settled + unsettled + newMined
        uint lastSettledRound = _settledBIMRounds[account];
        uint unsettledShare = _accBIMShares[_currentBIMRound-1].sub(_accBIMShares[lastSettledRound]);
        
        uint newBIMShare;
        if (_totalStaked > 0 && BIMContract.maxSupply() > BIMContract.totalSupply()) {
            uint blocksToReward = block.number.sub(_lastBIMRewardBlock);
            uint bimsToMint = BIMBlockReward.mul(blocksToReward);
    
            // BIM share
            newBIMShare = bimsToMint.mul(SHARE_MULTIPLIER)
                                        .div(_totalStaked);
        }
        
        return _bimBalance[account] + (unsettledShare + newBIMShare)
                                            .mul(_balances[account])
                                            .div(SHARE_MULTIPLIER);  // remember to div by SHARE_MULTIPLIER;
    }
    
    /**
     * @dev settle a staker
     */
    function settleStakerBIM(address account) internal {
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
    function updateBIMRound() internal nonReentrant {
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
    event EthersClaimed(address account, uint256 amount);
    event BlockRewardSet(address account, uint256 amount);

}