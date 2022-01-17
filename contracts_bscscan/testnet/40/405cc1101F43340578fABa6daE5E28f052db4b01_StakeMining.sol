/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

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

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakeMining is Ownable {
    using SafeMath for uint256;

    address public immutable stakeToken;
    address public immutable rewardToken;

    struct PeriodPool {
        uint256 lastRewardTime; // Last reward time that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
        uint256 bonusStartTime; // The timestamp when CAKE mining starts.
        uint256 bonusEndTime; // The timestamp when CAKE mining ends.
        uint256 rewardPerDay;
        uint256 finalStake;
    }
    mapping(uint256 => PeriodPool) public pools;

    struct UserInfo {
        uint256 calcVersion;
        uint256 stakeAmount;
        uint256 rewardDebt;
    }
    mapping(address => UserInfo) public userInfos;

    uint256 public currentVersion;
    uint256 private constant secendsPerDay = 24*60*60;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _stakeToken, address _rewardToken) {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to, uint256 _version) private view returns (uint256)
    {
        uint256 startTime = _from;
        if (_from < pools[_version].bonusStartTime) {
            startTime = pools[_version].bonusStartTime;
        }

        if (_to <= pools[_version].bonusEndTime) {
            return _to.sub(startTime);
        } else if (_from >= pools[_version].bonusEndTime) {
            return 0;
        } else {
            return pools[_version].bonusEndTime.sub(startTime);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        if (userInfos[_user].stakeAmount == 0) {
            return 0;
        }
        uint256 pending;
        uint256 userCalcVersion = userInfos[_user].calcVersion;
        while (userCalcVersion < currentVersion){
            if (userCalcVersion == userInfos[_user].calcVersion) {
                pending += userInfos[_user].stakeAmount.mul(pools[userCalcVersion].accCakePerShare).div(1e12).sub(userInfos[_user].rewardDebt);
            } else {
                pending += userInfos[_user].stakeAmount.mul(pools[userCalcVersion].accCakePerShare).div(1e12);
            }
            userCalcVersion++;
        }

        uint256 accCakePerShare = pools[userCalcVersion].accCakePerShare;
        uint256 stakeSupply = IERC20(stakeToken).balanceOf(address(this));
        if (block.timestamp > pools[userCalcVersion].lastRewardTime && stakeSupply != 0) {
            uint256 multiplier = getMultiplier(pools[userCalcVersion].lastRewardTime, block.timestamp, currentVersion);
            uint256 cakeReward = multiplier.mul(pools[userCalcVersion].rewardPerDay).div(secendsPerDay);
            accCakePerShare = accCakePerShare.add( cakeReward.mul(1e12).div(stakeSupply) );
        }
        pending += userInfos[_user].stakeAmount.mul(accCakePerShare).div(1e12).sub(userInfos[_user].rewardDebt);
        return pending;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _version) private {
        uint256 timestamp = block.timestamp;
        if (block.timestamp <= pools[_version].lastRewardTime) {
            return;
        }
        uint256 stakeSupply = IERC20(stakeToken).balanceOf(address(this));
        if (stakeSupply == 0) { 
            pools[_version].lastRewardTime = timestamp;
            return;
        }
        if (timestamp >= pools[_version].bonusEndTime && pools[_version].finalStake == 0) {
            pools[_version].finalStake = stakeSupply;
        }
        uint256 multiplier = getMultiplier(pools[_version].lastRewardTime, timestamp, _version);
        uint256 cakeReward = multiplier.mul(pools[_version].rewardPerDay).div(secendsPerDay);
        pools[_version].accCakePerShare = pools[_version].accCakePerShare.add(
            cakeReward.mul(1e12).div(stakeSupply)
        );
        pools[_version].lastRewardTime = timestamp;
    }

    function deposit(uint256 _amount) public {
        updatePool(currentVersion);

        uint256 pending;
        if (userInfos[msg.sender].stakeAmount > 0) {
            uint256 userCalcVersion = userInfos[msg.sender].calcVersion;
            while (userCalcVersion <= currentVersion){
                if (userCalcVersion == userInfos[msg.sender].calcVersion) {
                    pending += userInfos[msg.sender].stakeAmount.mul(pools[userCalcVersion].accCakePerShare).div(1e12).sub(userInfos[msg.sender].rewardDebt);
                } else {
                    pending += userInfos[msg.sender].stakeAmount.mul(pools[userCalcVersion].accCakePerShare).div(1e12);
                }
                userCalcVersion++;
            }
        
            if (pending > 0) {
                TransferHelper.safeTransfer(rewardToken, msg.sender, pending);
            }
        }
        if (_amount > 0) {
            TransferHelper.safeTransferFrom(stakeToken, msg.sender, address(this), _amount);
            userInfos[msg.sender].stakeAmount = userInfos[msg.sender].stakeAmount.add(_amount);
        }

        userInfos[msg.sender].rewardDebt = userInfos[msg.sender].stakeAmount.mul(pools[currentVersion].accCakePerShare).div(1e12);
        userInfos[msg.sender].calcVersion = currentVersion;

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw tokens from STAKING and reward.
    function withdraw(uint256 _amount) public {
        require(userInfos[msg.sender].stakeAmount >= _amount && userInfos[msg.sender].stakeAmount > 0, "withdraw: staking token is not enough");
        updatePool(currentVersion);

        uint256 pending;
        uint256 userCalcVersion = userInfos[msg.sender].calcVersion;
        while (userCalcVersion <= currentVersion){
            if (userCalcVersion == userInfos[msg.sender].calcVersion) {
                pending += userInfos[msg.sender].stakeAmount.mul(pools[userCalcVersion].accCakePerShare).div(1e12).sub(userInfos[msg.sender].rewardDebt);
            } else {
                pending += userInfos[msg.sender].stakeAmount.mul(pools[userCalcVersion].accCakePerShare).div(1e12);
            }
            userCalcVersion++;
        }

        if (pending > 0) {
            TransferHelper.safeTransfer(rewardToken, msg.sender, pending);
        }

        if (_amount > 0) {
            userInfos[msg.sender].stakeAmount -= _amount;
            TransferHelper.safeTransfer(stakeToken, msg.sender, _amount);
        }
        userInfos[msg.sender].rewardDebt = userInfos[msg.sender].stakeAmount.mul(pools[currentVersion].accCakePerShare).div(1e12);
        userInfos[msg.sender].calcVersion = currentVersion;

        emit Withdraw(msg.sender, _amount);
    }

    function addVersion(uint256 _version, uint256 _bonusStartTime, uint256 _bonusEndTime, uint256 _rewardPerDay) public onlyOwner() {
        require(_version == currentVersion + 1, 'StakeMining: mining version error');
        uint256 timestamp = block.timestamp;
        require(timestamp >= pools[currentVersion].bonusEndTime, 'StakeMining: last version is not end');
        if (pools[currentVersion].finalStake == 0) {
            updatePool(currentVersion);
        }
        require(_bonusStartTime >= timestamp, 'StakeMining: bonusStartTime set error');
        require(_bonusEndTime > _bonusStartTime, 'StakeMining: bonusEndTime set error');
        currentVersion++;

        pools[_version].bonusStartTime = _bonusStartTime;
        pools[_version].bonusEndTime = _bonusEndTime;
        pools[_version].rewardPerDay = _rewardPerDay;
        pools[_version].lastRewardTime = timestamp;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        uint256 trans_amount = userInfos[msg.sender].stakeAmount;
        delete userInfos[msg.sender];
        TransferHelper.safeTransfer(stakeToken, msg.sender, trans_amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner() {
        TransferHelper.safeTransfer(rewardToken, msg.sender, _amount);
    }

    function transferETH(uint256 _value) public onlyOwner() {
        TransferHelper.safeTransferETH(msg.sender, _value);
    }

    function transferAsset(address _token, uint256 _value) public onlyOwner() {
        require(stakeToken != _token, 'StakeMining: no permission');
        TransferHelper.safeTransfer(_token, msg.sender, _value);
    }

}