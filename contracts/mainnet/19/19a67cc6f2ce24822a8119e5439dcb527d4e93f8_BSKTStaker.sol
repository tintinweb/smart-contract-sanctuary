/**
 *Submitted for verification at Etherscan.io on 2021-02-16
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

interface BSKToken {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

abstract contract RewardContract {
    function getBalance() external view virtual returns (uint256);
    function giveReward(address recipient, uint256 amount) external virtual returns (bool);
}

contract BSKTStaker is Ownable {
    using SafeMath for uint256;

    BSKToken public immutable _bskToken;    		        // BSKT contract
    RewardContract public _rewardContract;                  // reward contract

    mapping (address => StakerInfo) private _stakeMap;      // map for stakers

    address[] private _stakers;                             // staker's array
    
    uint256 private _totalStakedAmount = 0;                 // total staked amount
    uint256 private _minStakeAmount = 10000e18;             // min stakable amount
    
    uint256 private _rewardPortion = 10;                    // reward portion 10%
    
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 rewardAmount;
        uint256 lastClaimTimestamp;
    }
    
    // Events
    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);
    event Claim(address staker, uint256 amount);
    
    constructor (BSKToken bskToken) public {
        _bskToken = bskToken;
        
    }
    
    function stake(uint256 amount) public {
        require(
            amount >= _minStakeAmount,
            "BSKTStaker: stake amount is less than min stake amount."
        );

        uint256 initialBalance = _bskToken.balanceOf(address(this));
        
        require(
            _bskToken.transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "BSKTStaker: stake failed."
        );

        uint256 realStakedAmount = _bskToken.balanceOf(address(this)).sub(initialBalance);
        uint256 currentTimestamp = uint256(now);

        if(_stakeMap[_msgSender()].stakedAmount == 0)
            _stakers.push(_msgSender());
        else
            _stakeMap[_msgSender()].rewardAmount = calcReward(_msgSender(), currentTimestamp);
        _stakeMap[_msgSender()].lastClaimTimestamp = currentTimestamp;
            
        _stakeMap[_msgSender()].stakedAmount = _stakeMap[_msgSender()].stakedAmount.add(realStakedAmount);
        _totalStakedAmount = _totalStakedAmount.add(realStakedAmount);
        
        emit Staked(_msgSender(), realStakedAmount);
    }
    
    function unstake(uint256 amount) public {
        require(
            _stakeMap[_msgSender()].stakedAmount >= amount,
            "BSKTStaker: unstake amount exceededs the staked amount."
        );

        uint256 currentTimestamp = uint256(now);
        _stakeMap[_msgSender()].rewardAmount = calcReward(_msgSender(), currentTimestamp);
        _stakeMap[_msgSender()].lastClaimTimestamp = currentTimestamp;
        _stakeMap[_msgSender()].stakedAmount = _stakeMap[_msgSender()].stakedAmount.sub(amount);
        _totalStakedAmount = _totalStakedAmount.sub(amount);

        require(
            _bskToken.transfer(
                _msgSender(),
                amount
            ),
            "BSKTStaker: unstake failed."
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
        uint256 currentTimestamp = uint256(now);
        uint256 rewardAmount = calcReward(_msgSender(), currentTimestamp);
        _stakeMap[_msgSender()].lastClaimTimestamp = currentTimestamp;
        _stakeMap[_msgSender()].rewardAmount = 0;
        
        require(
            _rewardContract.giveReward(_msgSender(), rewardAmount),
            "BSKTStaker: claim failed."
        );
        
	    emit Claim(_msgSender(), rewardAmount);
    }
    
    function endStake() external {
        unstake(_stakeMap[_msgSender()].stakedAmount);
        claim();
    }
    
    function calcReward(address account, uint256 currentTimestamp) internal view returns (uint256) {
        if(_totalStakedAmount == 0)
            return 0;
        uint256 rewardPoolBalance = _rewardContract.getBalance();
        uint256 passTime = currentTimestamp.sub(_stakeMap[account].lastClaimTimestamp);
        uint256 rewardAmountForStakers = rewardPoolBalance.mul(_rewardPortion).div(100);
        uint256 rewardAmount = rewardAmountForStakers.mul(passTime).div(86400).mul(_stakeMap[account].stakedAmount).div(_totalStakedAmount);
        return _stakeMap[account].rewardAmount.add(rewardAmount);
    }
    
    /**
     * Get store wallet
     */
    function getRewardContract() external view returns (address) {
        return address(_rewardContract);
    }
     
    /**
     * Get total staked amount
     */
    function getTotalStakedAmount() external view returns (uint256) {
        return _totalStakedAmount;
    }
    
    /**
     * Get reward amount of staker
     */
    function getReward(address account) external view returns (uint256) {
        return calcReward(account, now);
    }
    
    /**
     * Get reward pool balance (LAVA)
     */
    function getRewardPoolBalance() external view returns (uint256) {
        return _rewardContract.getBalance();
    }
    
    /**
     * Get last claim timestamp
     */
    function getLastClaimTimestamp() external view returns (uint256) {
        return _stakeMap[_msgSender()].lastClaimTimestamp;
    }
    
    /**
     * Get staked amount of staker
     */
    function getStakedAmount(address staker) external view returns (uint256) {
        return _stakeMap[staker].stakedAmount;
    }
    
    /**
     * Get min stake amount
     */
    function getMinStakeAmount() external view returns (uint256) {
        return _minStakeAmount;
    }
    
    /**
     * Get rewards portion
     */
    function getRewardPortion() external view returns (uint256) {
        return _rewardPortion;
    }
    
    /**
     * Get staker count
     */
    function getStakerCount() external view returns (uint256) {
        return _stakers.length;
    }

    /**
     * Get staked rank
     */
    function getStakedRank(address account) external view returns (uint256) {
        uint256 rank = 1;
        uint256 senderStakedAmount = _stakeMap[account].stakedAmount;
        
        for(uint i=0; i<_stakers.length; i++) {
            if(_stakers[i] != account && senderStakedAmount < _stakeMap[_stakers[i]].stakedAmount)
                rank = rank.add(1);
        }
        return rank;
    }
    
    /**
     * Set store wallet contract address
     */
    function setRewardContract(RewardContract rewardContract) external onlyOwner returns (bool) {
        require(address(rewardContract) != address(0), 'BSKTStaker: reward contract address should not be zero address.');

        _rewardContract = rewardContract;
        return true;
    }

    /**
     * Set rewards portion in store balance. 
     */
    function setRewardPortion(uint256 rewardPortion) external onlyOwner returns (bool) {
        require(rewardPortion >= 10 && rewardPortion <= 100, 'BSKTStaker: reward portion should be in 10 ~ 100.');

        _rewardPortion = rewardPortion;
        return true;
    }
}