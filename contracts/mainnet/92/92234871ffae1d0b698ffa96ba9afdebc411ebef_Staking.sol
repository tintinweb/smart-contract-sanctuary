/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
        if(a == 0) {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Staking is Ownable {
    using SafeMath for uint256;

    mapping (address => uint) private _userStakeDay;
    mapping (address => uint256) private _userRewards;
    mapping (address => uint256) private _userDailyReward;
    mapping (address => uint256) private _usersAmountStaked;
    mapping (address => uint256) private _usersStartTime;

    address[] private _usersStaked;
    bool private _stakingEnabled = true;

    IERC20 private _PIXIEAddress = IERC20(0x856eE6A073386b2Dd440a8CFc9D961B64AA78fe0);
    
    uint256 private _totalStaked;

    function totalBalanceWithoutStakes() public view returns (uint256) {
        require (totalBalance() > 0, 'Balance is 0');
        return _PIXIEAddress.balanceOf(address(this)).sub(_totalStaked);
    }

    function totalBalance() public view returns (uint256) {
        return _PIXIEAddress.balanceOf(address(this));
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function getStakers() public view returns (address[] memory) {
        return _usersStaked;
    }

    function getStakeDay(address staker) public view returns (uint256) {
        return _userStakeDay[staker];
    }

    function getAmountsStaked(address staker) public view returns (uint256) {
        return _usersAmountStaked[staker];
    }

    function getStakedTimes(address staker) public view returns (uint256) {
        return _usersStartTime[staker];
    }

    function getTotalUserReward(address staker) public view returns (uint256) {
        return _userRewards[staker];
    }

    function getDailyUserReward(address staker) public view returns (uint256) {
        return _userDailyReward[staker];
    }

    function getEmission() public view returns(uint256) {
        uint256 _totalPIXIE = totalBalanceWithoutStakes();
        uint256 _totalEmissions = _totalPIXIE.div(2);
        uint256 _totalSupply = 1e12 * 10**9;

        if (_totalStaked > _totalSupply.div(100).mul(4) && _totalStaked < _totalSupply.div(100).mul(8)) {
            _totalEmissions = _totalPIXIE.div(100).mul(60);
        } else if (_totalStaked > _totalSupply.div(100).mul(8) && _totalStaked < _totalSupply.div(100).mul(12)) {
            _totalEmissions = _totalPIXIE.div(100).mul(70);
        } else if (_totalStaked > _totalSupply.div(100).mul(12) && _totalStaked < _totalSupply.div(100).mul(16)) {
            _totalEmissions = _totalPIXIE.div(100).mul(80);
        } else if (_totalStaked > _totalSupply.div(100).mul(16) && _totalStaked < _totalSupply.div(100).mul(20)) {
            _totalEmissions = _totalPIXIE.div(100).mul(90);
        } else if (_totalStaked > _totalSupply.div(100).mul(20)) {
            _totalEmissions = _totalPIXIE;
        }

        return _totalEmissions.div(30);
    }

    function setDailyRewards() public {
        uint256 _emission = getEmission();

        for (uint i = 0; i < _usersStaked.length; i += 1) {
            address _user = _usersStaked[i];

            uint256 _userAmountStaked = _usersAmountStaked[_user];
            uint _previousUserStakeDay = _userStakeDay[_user];

            uint256 _userTimeStamp = _usersStartTime[_user];
            uint256 _timestamp = block.timestamp;
            uint _stakeDay;

            if (_userTimeStamp == _timestamp) {
                _stakeDay = 0;
            } else {
                uint256 _userStakeDayTimestamp = _timestamp.sub(_userTimeStamp);
                _stakeDay = _userStakeDayTimestamp.div(1 days);

            }

            if (_userDailyReward[_user] <= 0) {
                _userDailyReward[_user] = _emission.mul(_userAmountStaked).div(_totalStaked);
            }
            
            if (_previousUserStakeDay != _stakeDay) {
                _userRewards[_user] += _userDailyReward[_user];
            }
            
            _userStakeDay[_user] = _stakeDay;
            _userDailyReward[_user] = _emission.mul(_userAmountStaked).div(_totalStaked);
        }
    }

    function stake(uint256 toStake) external {
        require(_stakingEnabled, 'Staking has been disabled. Please contact staff to find out why.');
        require(_PIXIEAddress.balanceOf(msg.sender) > toStake, "Insufficient Funds in wallet");
        
        bool _hasStaked = false;

        for (uint i = 0; i < _usersStaked.length; i += 1) {
            if (_usersStaked[i] == msg.sender) {
                _hasStaked = true;
            }
        }

        _usersAmountStaked[msg.sender] += toStake;
        _usersStartTime[msg.sender] = block.timestamp;

        if (!_hasStaked) _usersStaked.push(msg.sender);

        _totalStaked += toStake;

        // Calculate new daily rewards
        setDailyRewards();

        _PIXIEAddress.transferFrom(msg.sender, address(this), toStake);
    }

    function unStake() external {
        require(_stakingEnabled, 'Staking has been disabled. Please contact staff to find out why and how to unstake your initial amount');
        require(_userStakeDay[msg.sender] > 0, 'You must have staked your tokens for at least 24h');

        uint256 _initial = _usersAmountStaked[msg.sender];
        uint256 _reward = _userRewards[msg.sender];

        // Remove from staking array
        for (uint i = 0; i < _usersStaked.length; i += 1) {
            if (_usersStaked[i] == msg.sender) {
                delete _usersStaked[i];
            }
        }

        // Reset all the vars
        _userStakeDay[msg.sender] = 0;
        _usersAmountStaked[msg.sender] = 0;
        _userRewards[msg.sender] = 0;
        _userDailyReward[msg.sender] = 0;
        _usersStartTime[msg.sender] = 0;

        _PIXIEAddress.transfer(msg.sender, _initial.add(_reward));
        _totalStaked -= _initial;

        // Calculate new daily rewards
        if (_totalStaked > 0) setDailyRewards();
    }

    function unstakeInitial() external {
        require(!_stakingEnabled, 'Staking is enabled, use the unStake function');

        _PIXIEAddress.transfer(msg.sender, _usersAmountStaked[msg.sender]);
    }

    function withdrawAll() external onlyOwner() {
        _PIXIEAddress.transfer(msg.sender, totalBalance());
    }

    function setStakingState(bool onoff) external onlyOwner() {
        // In case of staking malfunctioning or amounts being totally off
        _stakingEnabled = onoff;
    }

    receive() external payable {}
}