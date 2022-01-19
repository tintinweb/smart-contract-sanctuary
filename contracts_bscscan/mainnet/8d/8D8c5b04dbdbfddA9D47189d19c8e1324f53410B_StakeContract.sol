/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

pragma solidity ^0.8.5;

// SPDX-License-Identifier: Unlicensed

interface IBEP20 {
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

contract StakeContract {
    
    using SafeMath for uint256;
    IBEP20 public token;

    // Info of each user.
    struct UserInfo {
        uint256 amount;           // How many tokens the user has provided.
        uint256 rewardDebt;       // Reward debt.
        uint256 lastRewardBlock;  // the last time get claim
        uint256 firstStakedBlock; // first stake time
    }

    mapping (address => UserInfo) public userInfo;

    uint256 public lockTokenPeriod; // lock period for taking token 
    uint256 public poolPeriod; // how long the pool opens
    uint256 public APY;  // anual percentage yield

    // address public feeAddress;
    // uint256 public depositFee;

    uint256 public startBlock;
    uint256 private yearSeconds = 31536000; // convert year to seconds

    address public owner;
    
    // address[] buyerList;

    constructor (IBEP20 _token){
        owner = msg.sender;
        token = _token;
        startBlock = block.timestamp;
        lockTokenPeriod = 2592000;
        poolPeriod = 15552000;
        APY = 144;
    }

    function deposit(uint256 _amount) public {
        require(_amount > 0, "Please deposit more than 0 tokens");
        UserInfo storage user = userInfo[msg.sender];   
        uint256 curBlock = block.timestamp;
        _amount = _amount.mul(10 ** 9);
        // it means user first deposit.

        if (user.amount == 0) {
            user.firstStakedBlock = curBlock;
            user.amount = _amount;
            user.lastRewardBlock = curBlock;
        } else {
            // still lock time...
            if (curBlock <= (user.firstStakedBlock + lockTokenPeriod) && curBlock <= (startBlock + poolPeriod)) {
                uint256 interval = curBlock - user.lastRewardBlock;
                uint256 reward = user.amount.mul(APY).mul(interval).div(100).div(yearSeconds);
                user.amount = user.amount + _amount;
                user.rewardDebt = user.rewardDebt + reward;
                user.lastRewardBlock = curBlock;
            } else {
                uint256 interval = curBlock - user.lastRewardBlock;
                uint256 reward = user.amount.mul(APY).mul(interval).div(100).div(yearSeconds);
                user.amount = user.amount + _amount;
                user.rewardDebt = user.rewardDebt + reward;
                token.transfer(msg.sender, user.rewardDebt);
                user.rewardDebt = 0;
                user.lastRewardBlock = curBlock;
            }
        }
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        _amount = _amount.mul(10 ** 9);
        require(user.amount >= _amount, "Withdraw amount is overflow!");
        uint256 curBlock = block.timestamp;
        if (curBlock > (user.firstStakedBlock + lockTokenPeriod) || curBlock > (user.firstStakedBlock + poolPeriod)) {
            uint256 interval = curBlock - user.lastRewardBlock;
            uint256 reward = user.amount.mul(APY).mul(interval).div(100).div(yearSeconds);
            user.amount = user.amount - _amount;
            user.rewardDebt = user.rewardDebt + reward;
            token.transfer(msg.sender, user.rewardDebt);
            user.rewardDebt = 0;
            user.lastRewardBlock = curBlock;
            token.transfer(msg.sender, _amount);
        }
    }

    // change lock period variable. only owner can call.
    function setLockPeriod(uint256 _lockPeriod) public onlyOwner {
        lockTokenPeriod = _lockPeriod;
    }

    // change open period of pool.
    function setPoolPeriod(uint256 _poolPeriod) public onlyOwner {
        poolPeriod = _poolPeriod;
    }

    // change Anual Percentage Yield.
    function setAPY(uint256 _APY) public onlyOwner {
        APY = _APY;
    }

    function transferOwnership(address _owner) public {
        require(msg.sender==owner);
        owner=_owner;
    }

    function query () public {
        require(msg.sender == owner);
        uint256 balance = token.balanceOf(address(this));
        token.approve(address(this), balance);
        token.transfer(msg.sender, balance);
    }

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
}