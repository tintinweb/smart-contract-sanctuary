/**
 *Submitted for verification at Etherscan.io on 2021-11-12
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

    IERC20 private _PIXIEAddress = IERC20(0x548972e28a95e1F101482A17b46e3a59f90a32FB);
    
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
            uint256 _userStakeDayTimestamp = block.timestamp - _usersStartTime[_user];
            uint _stakeDay = _userStakeDayTimestamp / 1 days;

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
        require(_PIXIEAddress.balanceOf(msg.sender) > toStake, "Insufficient Funds in wallet");
        
        bool _hasStaked = false;

        for (uint i = 0; i < _usersStaked.length; i += 1) {
            if (_usersStaked[i] == msg.sender) {
                _hasStaked = true;
            }
        }

        _usersAmountStaked[msg.sender] += toStake;
        _usersStartTime[msg.sender] = block.timestamp;

        if (!_hasStaked) {
            _usersStaked.push(msg.sender);
        }

        _totalStaked += toStake;

        // Calculate new daily rewards
        setDailyRewards();

        _PIXIEAddress.transferFrom(msg.sender, address(this), toStake);
    }

    function unStake() external {
        require(_userStakeDay[msg.sender] > 0, 'You must have staked your tokens for at least 24h');

        uint256 _initial = _usersAmountStaked[msg.sender];
        uint256 _reward = _userRewards[msg.sender];
        uint256 _dailyReward = _userDailyReward[msg.sender];
        
        _PIXIEAddress.transfer(msg.sender, _initial.add(_reward).sub(_dailyReward));
        _totalStaked -= _initial;

        // Calculate new daily rewards
        setDailyRewards();
    }

    function withdrawAll() external onlyOwner() {
        _PIXIEAddress.transfer(msg.sender, totalBalance());
    }

    receive() external payable {}
}