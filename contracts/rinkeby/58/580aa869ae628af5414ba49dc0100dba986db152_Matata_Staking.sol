/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: MATATA

pragma solidity ^0.8.11;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function mint(address _to, uint256 _amount) external returns (bool success);
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

    constructor() {
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

contract Matata_Staking is Owned {
    
    using SafeMath for uint;

    address public token;
    address public proofToken;
    address public feeWallet;
    uint public totalStaked;
    uint public stakingTaxRate; 
    uint public registrationTax;
    uint public dailyROI;                         //100 = 1%
    uint public unstakingTaxRate;                   //10 = 1%
    uint public minimumStakeValue;
    bool public active = true;
    bool public registered = true;

    
    mapping(address => uint) public stakes;
    mapping(address => uint) public referralRewards;
    mapping(address => uint) public referralCount;
    mapping(address => uint) public stakeRewards;
    mapping(address => uint) private lastClock;
    
    event OnWithdrawal(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);
    event OnRegisterAndStake(address stakeholder, uint amount, uint totalTax , address _referrer);
    
    constructor(
        address _token,
        address _proofToken,
        address _feeWallet,
        uint _stakingTaxRate, 
        uint _unstakingTaxRate,
        uint _dailyROI,
        uint _registrationTax,
        uint _minimumStakeValue) {
            
        token = _token;
        proofToken = _proofToken;
        feeWallet = _feeWallet;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        registrationTax = _registrationTax;
        minimumStakeValue = _minimumStakeValue;
    }
    
    
        
    modifier whenActive() {
        require(active == true, "Smart contract is curently inactive");
        _;
    }
    
    
    function calculateEarnings(address _stakeholder) public view returns(uint) {
        uint activeDays = ((block.timestamp).sub(lastClock[_stakeholder])).div(86400);
        return ((stakes[_stakeholder]).mul(dailyROI).mul(activeDays)).div(10000);
    }
    
    function stake(uint _amount) external whenActive() {
        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");
        require(IERC20(token).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        require(IERC20(token).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        uint stakingTax = (stakingTaxRate.mul(_amount)).div(1000);
        uint afterTax = _amount.sub(stakingTax);
        totalStaked = totalStaked.add(afterTax);
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        uint remainder = ((block.timestamp).sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = (block.timestamp).sub(remainder);
        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);
        IERC20(proofToken).mint(msg.sender, afterTax);
        IERC20(token).transfer(feeWallet, stakingTax);
        emit OnStake(msg.sender, afterTax, stakingTax);
    }
    
    
    function unstake(uint _amount) external {
        require(_amount <= stakes[msg.sender] && _amount > 0, 'Insufficient balance to unstake');
        uint unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);
        uint afterTax = _amount.sub(unstakingTax);
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);
        uint remainder = ((block.timestamp).sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = (block.timestamp).sub(remainder);
        totalStaked = totalStaked.sub(_amount);
        IERC20(token).transfer(msg.sender, afterTax);
        IERC20(token).transfer(feeWallet, unstakingTax);
        IERC20(proofToken).transferFrom(msg.sender, address(this), afterTax);

        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }
    
    function withdrawEarnings() external returns (bool success) {
        uint totalReward = (calculateEarnings(msg.sender) + 10);
        uint unstakingTax = (unstakingTaxRate.mul(totalReward)).div(1000);
        uint afterTax = totalReward - unstakingTax;
        require(totalReward > 0, 'No reward to withdraw'); 
        require((IERC20(token).balanceOf(address(this))).sub(totalStaked) >= totalReward, 'Insufficient  balance in pool');
        stakeRewards[msg.sender] = 0;
        referralRewards[msg.sender] = 0;
        referralCount[msg.sender] = 0;
        uint remainder = ((block.timestamp).sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = (block.timestamp).sub(remainder);
        require(IERC20(token).transfer(msg.sender, afterTax), 'insufficient input in pool');
        IERC20(token).transfer(feeWallet, unstakingTax);
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    function rewardPool() external view onlyOwner() returns(uint claimable) {
        return (IERC20(token).balanceOf(address(this))).sub(totalStaked);
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
        require((IERC20(token).balanceOf(address(this))).sub(totalStaked) >= _amount, 'Insufficient  balance in pool');
        IERC20(token).transfer(msg.sender, _amount);
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }
}