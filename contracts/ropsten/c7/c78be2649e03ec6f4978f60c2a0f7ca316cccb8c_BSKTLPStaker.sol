/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}
interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

abstract contract RewardContract {
    function getBalance() external view virtual returns (uint256);
    function giveReward(address recipient, uint256 amount) external virtual returns (bool);
}

contract BSKTLPStaker is Ownable {
    using SafeMath for uint256;

    IERC20 public immutable _BSKTWethPairContract;    	// BSKT-WETH Pair contract
    RewardContract public _rewardContract;                  // reward contract
    
    mapping (address => StakerInfo) private _stakeMap;      // map for stakers
    address[] private _stakers;                             // staker's array
    address private _devWallet;                             // dev _devWallet
    uint256 private _devRewardPct;                          // dev reward percentation;      

    uint256 private _rewardAmountPerBlock = 15046;          // BSKT 1.5046 (15046 / 10^4) per block

    bool private _unstakeAllow;

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastSnapShotIndex;
        uint256 lastClaimBlockNumber;
        uint256 rewardAmount;
    }
    
    uint256 public _lockTime;                               // lock time to unstake from start time
    uint256 public _startTime = 0;
    uint256 public _duration;                               // farming generation
    uint256 public _endTime;
    uint256 public _endBlockNumber;                         // end block number that calcuated by first stake block number + duration / block generation speed
    uint256 public _blockSpeed = 135;                       // block generation speed 13.5s
    
    uint256 public _rewardTokenDecimal = 18;                // decimal of reward token
    
    SNAPSHOT[] private snapShotHistory;
    
    struct SNAPSHOT {
        uint256 blockNumber;
        uint256 totalStakedAmount;
    }
    
    // Events
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Claim(address indexed staker, uint256 amount);
    event RewardContractUpdated(address indexed rewardContract);
    event RewardAmountPerBlockUpdated(uint256 rewardAmountPerBlock);
    event StartTimeUpdated(uint256 liveTimestamp);
    event UnstakeAllowed();
    event DevWalletUpdated(address indexed devWallet);
    event DevRewardPctUpdated(uint256 devRewardPct);
    event LockTimeUpdated(uint256 lockTime);
    event BlockSpeedUpdated(uint256 blockSpeed);
    event DurationUpdated(uint256 duration);
    
    constructor (IERC20 BSKTWethPairContract, address devWallet, uint256 devRewardPct, uint256 duration, uint256 lockTime) public {
        _BSKTWethPairContract = BSKTWethPairContract;
        setDevWallet(devWallet);
        setDevRewardPct(devRewardPct);
        setDuration(duration);
        setLockTime(lockTime);
    }
    
    function stake(uint256 amount) public {
        updateUnstakeAllow();
        
        uint256 currentBlockNumber = block.number;
        uint256 currentTimestamp = now;
        
        require(
            _startTime > 0 &&
            now >= _startTime,
            'BSKTLPStaker: staking not started yet.'
        );
        
        require(
            _BSKTWethPairContract.transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "BSKTLPStaker: stake failed."
        );
        
        if(snapShotHistory.length == 0) {
            _endBlockNumber = currentBlockNumber.add(_duration.mul(10).div(_blockSpeed));
            _endTime = currentTimestamp.add(_duration);
        }
        
        if(_stakeMap[_msgSender()].stakedAmount == 0)
            _stakers.push(_msgSender());
        else
            _stakeMap[_msgSender()].rewardAmount = calcReward(_msgSender(), currentBlockNumber);

        _stakeMap[_msgSender()].stakedAmount = _stakeMap[_msgSender()].stakedAmount.add(amount);
        uint256 currentTotalStakedAmount= snapShotHistory.length > 0 ? snapShotHistory[snapShotHistory.length - 1].totalStakedAmount : 0;
        
        if(snapShotHistory.length > 0 && snapShotHistory[snapShotHistory.length-1].blockNumber == currentBlockNumber) {
            snapShotHistory[snapShotHistory.length-1].totalStakedAmount = currentTotalStakedAmount.add(amount);
        } else {
            SNAPSHOT memory snapShot = SNAPSHOT({
                blockNumber: currentBlockNumber,
                totalStakedAmount: currentTotalStakedAmount.add(amount)
            });
            
            snapShotHistory.push(snapShot);
        }
        
        _stakeMap[_msgSender()].lastSnapShotIndex = snapShotHistory.length - 1;
        _stakeMap[_msgSender()].lastClaimBlockNumber = 0;
        
        emit Staked(_msgSender(), amount);
    }
    
    function unstake(uint256 amount) public {
        updateUnstakeAllow();
        require(_unstakeAllow, "BSKTLPStaker: unstake not allowed");
        require(
            _stakeMap[_msgSender()].stakedAmount >= amount,
            "BSKTLPStaker: unstake amount exceededs the staked amount."
        );
        
        uint256 currentBlockNumber = block.number;

        _stakeMap[_msgSender()].rewardAmount = calcReward(_msgSender(), currentBlockNumber);
        
        _stakeMap[_msgSender()].stakedAmount = _stakeMap[_msgSender()].stakedAmount.sub(amount);
        uint256 currentTotalStakedAmount= snapShotHistory.length > 0 ? snapShotHistory[snapShotHistory.length - 1].totalStakedAmount : 0;
        
        if(snapShotHistory.length > 0 && snapShotHistory[snapShotHistory.length-1].blockNumber == currentBlockNumber) {
            snapShotHistory[snapShotHistory.length-1].totalStakedAmount = currentTotalStakedAmount.sub(amount);
        } else {
            SNAPSHOT memory snapShot = SNAPSHOT({
                blockNumber: currentBlockNumber,
                totalStakedAmount: currentTotalStakedAmount.sub(amount)
            });
            
            snapShotHistory.push(snapShot);
        }
        
        _stakeMap[_msgSender()].lastSnapShotIndex = snapShotHistory.length - 1;
        _stakeMap[_msgSender()].lastClaimBlockNumber = 0;

        require(
            _BSKTWethPairContract.transfer(
                _msgSender(),
                amount
            ),
            "BSKTLPStaker: unstake failed."
        );
        
        if(_stakeMap[_msgSender()].stakedAmount == 0) {
            for(uint i=0; i<_stakers.length; i++) {
                if(_stakers[i] == _msgSender()) {
                    _stakers[i] = _stakers[_stakers.length-1];
                    _stakers.pop();
                    break;
                }
            }
        }
        emit Unstaked(_msgSender(), amount);
    }
    
    function claim() public {
        updateUnstakeAllow();
        uint256 currentBlockNumber = block.number;
        uint256 rewardAmount = calcReward(_msgSender(), currentBlockNumber);
        
        if(_stakeMap[_msgSender()].lastSnapShotIndex != snapShotHistory.length - 1)
            _stakeMap[_msgSender()].lastSnapShotIndex = snapShotHistory.length - 1;
        
        _stakeMap[_msgSender()].lastClaimBlockNumber = currentBlockNumber;
        _stakeMap[_msgSender()].rewardAmount = 0;
        
        require(
            _rewardContract.giveReward(_msgSender(), rewardAmount),
            "BSKTLPStaker: claim failed."
        );

	    emit Claim(_msgSender(), rewardAmount);
    }
    
    function endStake() external {
        unstake(_stakeMap[_msgSender()].stakedAmount);
        claim();
    }
    
    function calcReward(address staker, uint256 currentBlockNumber) private view returns (uint256) {
        uint256 rewardAmount = _stakeMap[staker].rewardAmount;
        uint256 stakedAmount = _stakeMap[staker].stakedAmount;
        uint256 lastClaimBlockNumber = _stakeMap[staker].lastClaimBlockNumber;
        uint256 rewardPctForStakers = uint256(100).sub(_devRewardPct);
        uint256 passedBlockCount;
        uint256 prevBlockNumber;
        uint256 prevTotalStakedAmount;
        
        if(lastClaimBlockNumber >= _endBlockNumber)
            return rewardAmount;
            
        for(uint i = _stakeMap[staker].lastSnapShotIndex; i < snapShotHistory.length; i++) {
            prevBlockNumber = snapShotHistory[i].blockNumber;
            if(prevBlockNumber >= _endBlockNumber)
                break;
            
            prevTotalStakedAmount = snapShotHistory[i].totalStakedAmount;
            if(prevTotalStakedAmount == 0)
                break;

            passedBlockCount = i == snapShotHistory.length - 1 ? min(currentBlockNumber, _endBlockNumber).sub(max(prevBlockNumber, lastClaimBlockNumber)) : min(snapShotHistory[i+1].blockNumber, _endBlockNumber).sub(max(prevBlockNumber, lastClaimBlockNumber));
            rewardAmount = rewardAmount.add(_rewardAmountPerBlock.mul(passedBlockCount).mul(10**(_rewardTokenDecimal - 4)).mul(rewardPctForStakers).div(100).mul(stakedAmount).div(prevTotalStakedAmount));
        }
        return rewardAmount;
    }
    
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function updateUnstakeAllow() private {
        if(!_unstakeAllow && 
            _startTime > 0 &&
            now >= _startTime.add(_lockTime))
            _unstakeAllow = true;
    }
    
    /**
     * Get reward contract
     */
    function getRewardContract() external view returns (address) {
        return address(_rewardContract);
    }
     
    /**
     * Get total staked amount
     */
    function getTotalStakedAmount() external view returns (uint256) {
        return snapShotHistory.length > 0 ? snapShotHistory[snapShotHistory.length - 1].totalStakedAmount : 0;
    }
    
    /**
     * Get reward amount of staker
     */
    function getReward(address staker) external view returns (uint256) {
        return calcReward(staker, block.number);
    }
    
    /**
     * Get reward pool balance (BSKT-WETH LP)
     */
    function getRewardPoolBalance() external view returns (uint256) {
        return _rewardContract.getBalance();
    }

    /**
     * Get staked amount of staker
     */
    function getStakedAmount(address staker) external view returns (uint256) {
        return _stakeMap[staker].stakedAmount;
    }
    
    /**
     * Get rewards portion
     */
    function getRewardAmountPerBlock() external view returns (uint256) {
        return _rewardAmountPerBlock;
    }
    
    /**
     * Get staker count
     */
    function getStakerCount() external view returns (uint256) {
        return _stakers.length;
    }
    
    /**
     * Get dev wallet
     */
    function getDevWallet() external view returns (address) {
        return _devWallet;
    }
    
    /**
     * Get dev reward percentage
     */
    function getDevRewardPct() external view returns (uint256) {
        return _devRewardPct;
    }
    
    /**
     * Get start time
     */
    function getStartTime() external view returns (uint256) {
        return _startTime;
    }
    
    /**
     * Get lock time
     */
    function getLockTime() external view returns (uint256) {
        return _lockTime;
    }
    
    /**
     * Get block generation speed
     */
    function getBlockSpeed() external view returns (uint256) {
        return _blockSpeed;
    }
    
    /**
     * Get duration
     */
    function getDuration() external view returns (uint256) {
        return _duration;
    }

    /**
     * Get unstake allow flag
     */
    function getUnstakeAllow() external view returns (bool) {
        return _unstakeAllow;
    }
    
    /**
     * Get staked rank
     */
    function getStakedRank(address staker) external view returns (uint256) {
        uint256 rank = 1;
        uint256 senderStakedAmount = _stakeMap[staker].stakedAmount;
        
        for(uint i=0; i<_stakers.length; i++) {
            if(_stakers[i] != staker && senderStakedAmount < _stakeMap[_stakers[i]].stakedAmount)
                rank = rank.add(1);
        }
        return rank;
    }
    
    /**
     * Set reward contract address
     */
    function setRewardContract(RewardContract rewardContract) external onlyOwner {
        require(address(rewardContract) != address(0), 'BSKTLPStaker: reward contract address should not be zero address.');

        _rewardContract = rewardContract;
        emit RewardContractUpdated(address(rewardContract));
    }

    /**
     * Set reward amount per block. 
     * ex: 1 => 0.01
     */
    function setRewardAmountPerBlock(uint256 rewardAmountPerBlock) external onlyOwner {
        require(rewardAmountPerBlock >= 1, 'BSKTLPStaker: reward amount per block should be greater than 1.');
        
        _rewardAmountPerBlock = rewardAmountPerBlock;
        emit RewardAmountPerBlockUpdated(rewardAmountPerBlock);
    }
    
    /**
     * Set dev wallet. 
     */
    function setDevWallet(address devWallet) public onlyOwner {
        require(devWallet != address(0), 'BSKTLPStaker: devWallet is zero address.');
        _devWallet = devWallet;
        emit DevWalletUpdated(devWallet);
    }
    
    /**
     * Set dev reward percentage. 
     */
    function setDevRewardPct(uint256 devRewardPct) public onlyOwner {
        require(devRewardPct < 4, 'BSKTLPStaker: devRewardPct should be less than 4.');
        _devRewardPct = devRewardPct;
        emit DevRewardPctUpdated(devRewardPct);
    }
    
    /**
     * Set start time. 
     */
    function setStartTime() external onlyOwner {
        require (
            _startTime == 0 ||
            now > _endTime.add(3 days),
            'BSKTLPStaker: should set start time later.'
        );
        
        uint256 totalStakedAmount = snapShotHistory.length > 0 ? snapShotHistory[snapShotHistory.length - 1].totalStakedAmount : 0;
        if(totalStakedAmount > 0) {
            _BSKTWethPairContract.transfer(
                _devWallet,
                totalStakedAmount
            );
        }
        
        for (uint i=snapShotHistory.length; i>0; i--) {
            snapShotHistory.pop();
        }
        
        for (uint i=_stakers.length; i>0; i--) {
            _stakeMap[_stakers[i-1]].stakedAmount = 0;
            _stakeMap[_stakers[i-1]].rewardAmount = 0;
            _stakeMap[_stakers[i-1]].lastClaimBlockNumber = 0;
            _stakeMap[_stakers[i-1]].lastSnapShotIndex = 0;
            _stakers.pop();
        }
        
        _startTime = now;
        emit StartTimeUpdated(now);
    }
    
    /**
     * Set _unstakeAllow. 
     */
    function setUnstakeAllow() external onlyOwner {
        _unstakeAllow = true;
        emit UnstakeAllowed();
    }
    
    /**
     * Set lockTime. 
     */
    function setLockTime(uint256 lockTime) public onlyOwner {
        _lockTime = lockTime;
        emit LockTimeUpdated(lockTime);
    }
    
    /**
     * Set block generation speed in second. 
     */
    function setBlockSpeed(uint256 blockSpeed) public onlyOwner {
        _blockSpeed = blockSpeed;
        emit BlockSpeedUpdated(blockSpeed);
    }
    
    /**
     * Set staking duration. 
     */
    function setDuration(uint256 duration) public onlyOwner {
        _duration = duration;
        emit DurationUpdated(duration);
    }
    
    
    /**
     * Claim dev reward.
     */
    function claimDevReward() external {
        require(
            _endTime > 0 && now >= _endTime && _stakers.length == 0,
            "BSKTLPStaker: can't claim dev reward yet."
        );
        
        uint256 devRewardAmount = _rewardContract.getBalance();
        require(
            _rewardContract.giveReward(_devWallet, devRewardAmount),
            "BSKTLPStaker: dev reard claim failed."
        );
    }
    
    
}