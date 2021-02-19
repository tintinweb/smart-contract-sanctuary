/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint balance);
    function transfer(address to, uint amount) external returns (bool);
    
    function allowance(address account, address from) external view returns (uint256);
    function approve(address from, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed account, address indexed from, uint amount);
}

contract TokenWraper {
    
    using SafeMath for uint256;
    
    ERC20Interface public _token = ERC20Interface(0xBd3f621732288233aa355b9E1445b77637Df8036);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    function _save(uint256 amount) internal {
        _token.transferFrom(msg.sender, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }

    function _withdraw(uint256 amount) internal {
        _token.transfer(msg.sender, amount);
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
    }

    function _removeReward(address founder, uint256 amount) internal {
        _token.transfer(msg.sender, amount);
        _totalSupply = _totalSupply.sub(amount);
        _balances[founder] = _balances[founder].sub(amount);
    }
}

contract Saving is TokenWraper {
    
    using SafeMath for uint256;
    
    address public founder;
    uint256 public timeLock = 10 minutes; // return unix epoch
    uint256 public yearly = 1 days;
    uint256 public percentRewardYearly; // % yearly
    mapping(address => uint256) public savedAmount;
    mapping(address => uint256) public claimRewardTimestamp;
    mapping(address => uint256) public lockedUntil;
    
    ERC20Interface public token = ERC20Interface(0xBd3f621732288233aa355b9E1445b77637Df8036);
    
    event Saved(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Donate(address indexed user, uint256 reward);
    
    modifier isFounder() {
        require(msg.sender == founder);
        _;
    }
    
    constructor(uint256 _percentRewardYearly) {
        percentRewardYearly = _percentRewardYearly;
        founder = msg.sender;
    }
    
    function setNewFounder(address newAddress) public isFounder {
        founder = newAddress;
    }
    
    function setPercentRewardYearly(uint256 _percent) public isFounder {
        percentRewardYearly = _percent;
    }
    
    function rewardBalance() public view returns(uint256) {
        return balanceOf(founder);
    }
    
    function _rewardEarnedPerSecond(address account) public view returns(uint256) {
        if(account == founder) {
            return 0;
        }
        uint256 _savedAmount = savedAmount[account];
        uint256 _expectedRewardYearly = _savedAmount.mul(percentRewardYearly);
        _expectedRewardYearly = _expectedRewardYearly.div(100);
        uint256 _reward = _expectedRewardYearly.div(yearly);
        return _reward;
    }
    
    function rewardEarned(address account) public view returns(uint256) {
        uint256 _rewardPerSecond = _rewardEarnedPerSecond(account);
        uint256 _claimRewardTimestamp = claimRewardTimestamp[account];
        uint256 _currentTime = block.timestamp;
        uint256 _rangeTime = _currentTime.sub(_claimRewardTimestamp);
        uint256 _rewardEarned;
        if(_rangeTime >= timeLock) {
            _rewardEarned = _rewardPerSecond.mul(timeLock);
        }else {
            _rewardEarned = _rewardPerSecond.mul(_rangeTime);
        }
        return _rewardEarned;
    }
    
    function save(uint256 _amount) public {
        require(_amount > 0, "Cannot save 0");
        super._save(_amount);
        uint256 _currentTime = block.timestamp;
        claimRewardTimestamp[msg.sender] = _currentTime;
        lockedUntil[msg.sender] = _currentTime.add(timeLock);
        savedAmount[msg.sender] = _amount;
        emit Saved(msg.sender, _amount);
    }
    
    function withdraw(uint256 _amount) public {
        require(msg.sender != founder, "Founder not allowed to withdraw");
        require(lockedUntil[msg.sender] > 0, "No user found.");
        require(lockedUntil[msg.sender] < block.timestamp, "Not unlocked yet.");
        require(_amount > 0, "Cannot withdraw 0");
        super._withdraw(_amount);
        claimRewardTimestamp[msg.sender] = 0;
        emit Withdrawn(msg.sender, _amount);
    }
    
    function getReward() public {
        uint256 _rewardEarned = rewardEarned(msg.sender);
        require(_rewardEarned > 0, "Doesn't have a reward.");
        require(rewardBalance() > _rewardEarned, "Reward balance not enough.");
        super._removeReward(founder, _rewardEarned);
        savedAmount[msg.sender] = 0;
        claimRewardTimestamp[msg.sender] = block.timestamp;
        emit RewardPaid(msg.sender, _rewardEarned);
    }
}