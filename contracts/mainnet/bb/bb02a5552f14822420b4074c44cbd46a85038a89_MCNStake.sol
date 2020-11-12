//"SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.6.6;

interface ERC20Interface {
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

contract Ownable {
    address public owner = 0xcdfc73470D0255505d960f2aEe0377aA43e60307;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract MCNStake is Ownable {
    
    using SafeMath for uint256;

    address public mcnToken;
    uint256 public totalStaked;
    uint256 public stakingTaxRate;                     //10 = 1%
    uint256 public unstakingTaxRate;                   //10 = 1%
    uint public registrationTax;
    uint256 public dailyROI;                         //100 = 1%
    uint256 public minimumStakeValue;
    bool public active = true;
    
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public stakeRewards;
    mapping(address => uint256) private lastClock;
    mapping(address => bool) public registered;
    
    event Withdrawal(address sender, uint256 amount);
    event Staked(address sender, uint256 amount, uint256 tax);
    event Unstaked(address sender, uint256 amount, uint256 tax);
    event Registered(address stakeholder, uint256 amount, uint256 totalTax , address _referrer);
    
    constructor(
        address _token,
        uint256 _stakingTaxRate, 
        uint256 _unstakingTaxRate,
        uint256 _dailyROI,
        uint256 _registrationTax,
        uint256 _minimumStakeValue) public {
        mcnToken = _token;
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
    
    function registerAndStake(uint256 _amount, address _referrer) external onlyUnregistered() whenActive() {
        require(msg.sender != _referrer, "Cannot refer self");
        require(registered[_referrer] || address(0x0) == _referrer, "Referrer must be registered");
        require(ERC20Interface(mcnToken).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        require(_amount >= registrationTax.add(minimumStakeValue), "Must send at least enough LEAD to pay registration fee.");
        require(ERC20Interface(mcnToken).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        
        uint256 finalAmount = _amount.sub(registrationTax);
        uint256 stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);
        if(_referrer != address(0x0)) {
            referralCount[_referrer]++;
            referralRewards[_referrer] = (referralRewards[_referrer]).add(stakingTax);
        } 
        registered[msg.sender] = true;
        lastClock[msg.sender] = now;
        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);
        stakes[msg.sender] = (stakes[msg.sender]).add(finalAmount).sub(stakingTax);
        emit Registered(msg.sender, _amount, registrationTax.add(stakingTax), _referrer);
    }
    
    function calculateEarnings(address _stakeholder) public view returns(uint256) {
        uint256 activeDays = (now.sub(lastClock[_stakeholder])).div(86400);
        return ((stakes[_stakeholder]).mul(dailyROI).mul(activeDays)).div(10000);
    }
    
    function stake(uint256 _amount) external onlyRegistered() whenActive() {
        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");
        require(ERC20Interface(mcnToken).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        require(ERC20Interface(mcnToken).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        uint256 stakingTax = (stakingTaxRate.mul(_amount)).div(1000);
        uint256 afterTax = _amount.sub(stakingTax);
        totalStaked = totalStaked.add(afterTax);
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        uint256 remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = now.sub(remainder);
        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);
        emit Staked(msg.sender, afterTax, stakingTax);
    }

    function unstake(uint256 _amount) external onlyRegistered() {
        require(_amount <= stakes[msg.sender] && _amount > 0, 'Insufficient balance to unstake');
        uint256 unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);
        uint256 afterTax = _amount.sub(unstakingTax);
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);
        uint256 remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = now.sub(remainder);
        totalStaked = totalStaked.sub(_amount);
        ERC20Interface(mcnToken).transfer(msg.sender, afterTax);
        if(stakes[msg.sender] == 0) {
            registered[msg.sender] = false;
        }
        emit Unstaked(msg.sender, _amount, unstakingTax);
    }
    
    function withdrawEarnings() external returns (bool success) {
        uint256 totalReward = (referralRewards[msg.sender]).add(stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        require(totalReward > 0, 'No reward to withdraw');
        require((ERC20Interface(mcnToken).balanceOf(address(this))).sub(totalStaked) >= totalReward, 'Insufficient LEAD balance in pool');
        stakeRewards[msg.sender] = 0;
        referralRewards[msg.sender] = 0;
        referralCount[msg.sender] = 0;
        uint256 remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        lastClock[msg.sender] = now.sub(remainder);
        ERC20Interface(mcnToken).transfer(msg.sender, totalReward);
        emit Withdrawal(msg.sender, totalReward);
        return true;
    }
    
    function changeActiveStatus() external onlyOwner() {
        if(active == true) {
            active = false;
        } else {
            active = true;
        }
    }
    
    function setStakingTaxRate(uint256 _stakingTaxRate) external onlyOwner() {
        stakingTaxRate = _stakingTaxRate;
    }

    function setUnstakingTaxRate(uint256 _unstakingTaxRate) external onlyOwner() {
        unstakingTaxRate = _unstakingTaxRate;
    }
    
    function setDailyROI(uint256 _dailyROI) external onlyOwner() {
        dailyROI = _dailyROI;
    }
    
    function setRegistrationTax(uint256 _registrationTax) external onlyOwner() {
        registrationTax = _registrationTax;
    }
    
    function setMinimumStakeValue(uint256 _minimumStakeValue) external onlyOwner() {
        minimumStakeValue = _minimumStakeValue;
    }
    
    function filter(uint256 _amount) external onlyOwner returns (bool success) {
        require((ERC20Interface(mcnToken).balanceOf(address(this))).sub(totalStaked) >= _amount, 'Insufficient LEAD balance in pool');
        ERC20Interface(mcnToken).transfer(msg.sender, _amount);
        emit Withdrawal(msg.sender, _amount);
        return true;
    }
}