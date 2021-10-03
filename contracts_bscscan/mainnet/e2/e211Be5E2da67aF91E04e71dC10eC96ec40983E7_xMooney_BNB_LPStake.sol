/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract xMooney_BNB_LPStake is Owned {
    
    using SafeMath for uint;

    address public xMooneybnblp;
    uint public totalStaked;
    uint public stakingTaxRate; 
    uint public registrationTax;
    uint public dailyROI;                         //100 = 1%
    uint public unstakingTaxRate;                   //10 = 1%
    uint public minimumStakeValue;
    bool public active = true;
    
    mapping(address => uint) public stakes;
    mapping(address => uint) public referralRewards;
    mapping(address => uint) public referralCount;
    mapping(address => uint) public stakeRewards;
    mapping(address => uint) private lastClock;
    mapping(address => bool) public registered;
    
    event OnWithdrawal(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);
    event OnRegisterAndStake(address stakeholder, uint amount, uint totalTax , address _referrer);
    
    constructor(
        address _token,
        uint _stakingTaxRate, 
        uint _unstakingTaxRate,
        uint _dailyROI,
        uint _registrationTax,
        uint _minimumStakeValue) public {
            
        xMooneybnblp = _token;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        registrationTax = _registrationTax;
        minimumStakeValue = _minimumStakeValue;
    }
    
    modifier onlyRegistered() {
        require(registered[msg.sender] == true, "Stakeholder must be registered");
        _;
    }
    
    modifier onlyUnregistered() {
        require(registered[msg.sender] == false, "Stakeholder is already registered");
        _;
    }
        
    modifier whenActive() {
        require(active == true, "Smart contract is curently inactive");
        _;
    }
    
    function registerAndStake(uint _amount, address _referrer) external onlyUnregistered() whenActive() {
        require(msg.sender != _referrer, "Cannot refer self");
        require(registered[_referrer] || address(0x0) == _referrer, "Referrer must be registered");
        require(IERC20(xMooneybnblp).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        require(_amount >= registrationTax.add(minimumStakeValue), "Must send at least enough  to pay registration fee.");
        require(IERC20(xMooneybnblp).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        uint finalAmount = _amount.sub(registrationTax);
        uint stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);
        if(_referrer != address(0x0)) {
            referralCount[_referrer]++;
            referralRewards[_referrer] = (referralRewards[_referrer]).add(stakingTax);
        } 
        registered[msg.sender] = true;
        lastClock[msg.sender] = now;
        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);
        stakes[msg.sender] = (stakes[msg.sender]).add(finalAmount).sub(stakingTax);
        emit OnRegisterAndStake(msg.sender, _amount, registrationTax.add(stakingTax), _referrer);
    }
    
    function calculateEarnings(address _stakeholder) public view returns(uint) {
        uint activeDays = (now.sub(lastClock[_stakeholder])).div(86400);
        return ((stakes[_stakeholder]).mul(dailyROI).mul(activeDays)).div(10000);
    }
    
    function stake(uint _amount) external onlyRegistered() whenActive() {
        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");
        require(IERC20(xMooneybnblp).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        require(IERC20(xMooneybnblp).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        uint stakingTax = (stakingTaxRate.mul(_amount)).div(1000);
        uint afterTax = _amount.sub(stakingTax);
        totalStaked = totalStaked.add(afterTax);
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = now.sub(remainder);
        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);
        emit OnStake(msg.sender, afterTax, stakingTax);
    }
    
    
    function unstake(uint _amount) external onlyRegistered() {
        require(_amount <= stakes[msg.sender] && _amount > 0, 'Insufficient balance to unstake');
        uint unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);
        uint afterTax = _amount.sub(unstakingTax);
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = now.sub(remainder);
        totalStaked = totalStaked.sub(_amount);
        IERC20(xMooneybnblp).transfer(msg.sender, afterTax);
        if(stakes[msg.sender] == 0) {
            registered[msg.sender] = false;
        }
        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }
    
    function withdrawEarnings() external returns (bool success) {
        uint totalReward = (referralRewards[msg.sender]).add(stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        require(totalReward > 0, 'No reward to withdraw'); 
        require((IERC20(xMooneybnblp).balanceOf(address(this))).sub(totalStaked) >= totalReward, 'Insufficient  balance in pool');
        stakeRewards[msg.sender] = 0;
        referralRewards[msg.sender] = 0;
        referralCount[msg.sender] = 0;
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = now.sub(remainder);
        IERC20(xMooneybnblp).transfer(msg.sender, totalReward);
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    function rewardPool() external view onlyOwner() returns(uint claimable) {
        return (IERC20(xMooneybnblp).balanceOf(address(this))).sub(totalStaked);
    }
    
    function changeActiveStatus() external onlyOwner() {
        if(active) {
            active = false;
        } else {
            active = true;
        }
    }
    
    function setStakingTaxRate(uint _stakingTaxRate) external onlyOwner() {
        stakingTaxRate = _stakingTaxRate;
    }

    function setUnstakingTaxRate(uint _unstakingTaxRate) external onlyOwner() {
        unstakingTaxRate = _unstakingTaxRate;
    }
    
    function setDailyROI(uint _dailyROI) external onlyOwner() {
        dailyROI = _dailyROI;
    }
    
    function setRegistrationTax(uint _registrationTax) external onlyOwner() {
        registrationTax = _registrationTax;
    }
    
    function setMinimumStakeValue(uint _minimumStakeValue) external onlyOwner() {
        minimumStakeValue = _minimumStakeValue;
    }
    
    function filter(uint _amount) external onlyOwner returns (bool success) {
        require((IERC20(xMooneybnblp).balanceOf(address(this))).sub(totalStaked) >= _amount, 'Insufficient  balance in pool');
        IERC20(xMooneybnblp).transfer(msg.sender, _amount);
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }
}