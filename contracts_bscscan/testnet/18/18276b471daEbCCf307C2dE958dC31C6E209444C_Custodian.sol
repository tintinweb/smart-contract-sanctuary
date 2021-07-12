/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// File: contracts/custodian.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IPirateToken{
    function transfer(address receiver, uint256 numTokens) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Custodian {
    using SafeMath for uint256;
    IPirateToken private _token;
    
    address private _owner;

    address[] private _stakers;
    mapping(address => uint) private _stakingBalance;
    mapping(address => bool) private _hasStaked;
    mapping(address => bool) private _isStaking;
    
    uint256 private _totalBalance = 0;
    uint256 private _minimumRate = 10000 ether;
    
    ////Event
    event StakeToken(address indexed);
    event UnstakeToken(address indexed);
    event ChangeMininumRate(uint256);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    constructor(IPirateToken token_) public {
        _token = token_; 
        _owner = msg.sender;
    }

    function stakeTokens(uint amount_) public {
        // Require amount greater than 0
        require(amount_ >= _minimumRate, "amount less then mininum rate");

        // Trasnfer tokens to this contract for staking
        _token.transferFrom(msg.sender, address(this), amount_);

        // Update staking balance
        _stakingBalance[msg.sender] = _stakingBalance[msg.sender].add(amount_);
        
        _totalBalance = _totalBalance.add(amount_);

        // Add user to stakers array *only* if they haven't staked already
        if(!_hasStaked[msg.sender]) {
            _stakers.push(msg.sender);
        }

        // Update staking status
        _isStaking[msg.sender] = true;
        _hasStaked[msg.sender] = true;
        
        emit StakeToken(msg.sender);
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public {
        // Fetch staking balance
        uint balance = _stakingBalance[msg.sender];

        // Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        // Transfer Mock Dai tokens to this contract for staking
        _token.transfer(msg.sender, balance);

        // Reset staking balance
        uint256 amount = _stakingBalance[msg.sender];
        _stakingBalance[msg.sender] = 0;
        
        _totalBalance = _totalBalance.sub(amount);

        // Update staking status
        _isStaking[msg.sender] = false;
        
        emit UnstakeToken(msg.sender);
    }
    
    function token() public view returns (IPirateToken) {
        return _token;
    }

    function owener() public view returns (address) {
        return _owner;
    }

    function balanceOf(address user_) public view returns (uint256) {
        return _stakingBalance[user_];
    }
    
    function hasStaked(address user_) public view returns (bool) {
        return _hasStaked[user_];
    }
    
    function isStaking(address user_) public view returns (bool) {
        return _isStaking[user_];
    }
    
    function staker() public view returns (address [] memory) {
        return _stakers;
    }
    
    function totalBalance() public view returns (uint256) {
        return _totalBalance;
    }
    
    function mininumRate() public view returns (uint256) {
        return _minimumRate;
    }
    
    function setMininumRate(uint256 value) public onlyOwner {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _minimumRate = value;
        emit ChangeMininumRate(value);
    }

    receive() external payable {
        
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}