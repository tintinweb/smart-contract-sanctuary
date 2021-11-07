/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.6.0;

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

contract WendaoStake is Owned {
    
    //initializing safe computations
    using SafeMath for uint;

    //WENDAO contract address
    address public wendao;
    //total amount of staked wendao
    uint public totalStaked;
    //tax rate for staking in percentage
    uint public stakingTaxRate;                     //10 = 1%
    //tax amount for registration
    uint public registrationTax;
    //daily return of investment in percentage
    uint public dailyROI;                         //100 = 1%
    //tax rate for unstaking in percentage 
    uint public unstakingTaxRate;                   //10 = 1%
    //minimum stakeable WENDAO
    uint public minimumStakeValue;
    //pause mechanism
    bool public active = true;
    
    //mapping of stakeholder's addresses to data
    mapping(address => uint) public stakes;
    mapping(address => uint) public referralRewards;
    mapping(address => uint) public referralCount;
    mapping(address => uint) public stakeRewards;
    mapping(address => uint) private lastClock;
    mapping(address => bool) public registered;
    
    //Events
    event OnWithdrawal(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);
    event OnRegisterAndStake(address stakeholder, uint amount, uint totalTax , address _referrer);
    
    /**
     * @dev Sets the initial values
     */
    constructor(
        address _token,
        uint _stakingTaxRate, 
        uint _unstakingTaxRate,
        uint _dailyROI,
        uint _registrationTax,
        uint _minimumStakeValue) public {
            
        //set initial state variables
        wendao = _token;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        registrationTax = _registrationTax;
        minimumStakeValue = _minimumStakeValue;
    }
    
    //exclusive access for registered address
    modifier onlyRegistered() {
        require(registered[msg.sender] == true, "Stakeholder must be registered");
        _;
    }
    
    //exclusive access for unregistered address
    modifier onlyUnregistered() {
        require(registered[msg.sender] == false, "Stakeholder is already registered");
        _;
    }
        
    //make sure contract is active
    modifier whenActive() {
        require(active == true, "Smart contract is curently inactive");
        _;
    }
    
    /**
     * registers and creates stakes for new stakeholders
     * deducts the registration tax and staking tax
     * calculates refferal bonus from the registration tax and sends it to the _referrer if there is one
     * transfers WENDAO from sender's address into the smart contract
     * Emits an {OnRegisterAndStake} event..
     */
    function registerAndStake(uint _amount, address _referrer) external onlyUnregistered() whenActive() {
        //makes sure user is not the referrer
        require(msg.sender != _referrer, "Cannot refer self");
        //makes sure referrer is registered already
        require(registered[_referrer] || address(0x0) == _referrer, "Referrer must be registered");
        //makes sure user has enough amount
        require(IERC20(wendao).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        //makes sure amount is more than the registration fee and the minimum deposit
        require(_amount >= registrationTax.add(minimumStakeValue), "Must send at least enough WENDAO to pay registration fee.");
        //makes sure smart contract transfers WENDAO from user
        require(IERC20(wendao).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        //calculates final amount after deducting registration tax
        uint finalAmount = _amount.sub(registrationTax);
        //calculates staking tax on final calculated amount
        uint stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);
        //conditional statement if user registers with referrer 
        if(_referrer != address(0x0)) {
            //increase referral count of referrer
            referralCount[_referrer]++;
            //add referral bonus to referrer
            referralRewards[_referrer] = (referralRewards[_referrer]).add(stakingTax);
        } 
        //register user
        registered[msg.sender] = true;
        //mark the transaction date
        lastClock[msg.sender] = now;
        //update the total staked WENDAO amount in the pool
        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);
        //update the user's stakes deducting the staking tax
        stakes[msg.sender] = (stakes[msg.sender]).add(finalAmount).sub(stakingTax);
        //emit event
        emit OnRegisterAndStake(msg.sender, _amount, registrationTax.add(stakingTax), _referrer);
    }
    
    //calculates stakeholders latest unclaimed earnings 
    function calculateEarnings(address _stakeholder) public view returns(uint) {
        //records the number of days between the last payout time and now
        uint activeDays = (now.sub(lastClock[_stakeholder])).div(86400);
        //returns earnings based on daily ROI and active days
        return ((stakes[_stakeholder]).mul(dailyROI).mul(activeDays)).div(10000);
    }
    
    /**
     * creates stakes for already registered stakeholders
     * deducts the staking tax from _amount inputted
     * registers the remainder in the stakes of the sender
     * records the previous earnings before updated stakes 
     * Emits an {OnStake} event
     */
    function stake(uint _amount) external onlyRegistered() whenActive() {
        //makes sure stakeholder does not stake below the minimum
        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");
        //makes sure stakeholder has enough balance
        require(IERC20(wendao).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        //makes sure smart contract transfers WENDAO from user
        require(IERC20(wendao).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        //calculates staking tax on amount
        uint stakingTax = (stakingTaxRate.mul(_amount)).div(1000);
        //calculates amount after tax
        uint afterTax = _amount.sub(stakingTax);
        //update the total staked WENDAO amount in the pool
        totalStaked = totalStaked.add(afterTax);
        //adds earnings current earnings to stakeRewards
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //updates stakeholder's stakes
        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);
        //emit event
        emit OnStake(msg.sender, afterTax, stakingTax);
    }
    
    
    /**
     * removes '_amount' stakes for already registered stakeholders
     * deducts the unstaking tax from '_amount'
     * transfers the sum of the remainder, stake rewards, referral rewards, and current eanrings to the sender 
     * deregisters stakeholder if all the stakes are removed
     * Emits an {OnStake} event
     */
    function unstake(uint _amount) external onlyRegistered() {
        //makes sure _amount is not more than stake balance
        require(_amount <= stakes[msg.sender] && _amount > 0, 'Insufficient balance to unstake');
        //calculates unstaking tax
        uint unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);
        //calculates amount after tax
        uint afterTax = _amount.sub(unstakingTax);
        //sums up stakeholder's total rewards with _amount deducting unstaking tax
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //updates stakes
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //update the total staked WENDAO amount in the pool
        totalStaked = totalStaked.sub(_amount);
        //transfers value to stakeholder
        IERC20(wendao).transfer(msg.sender, afterTax);
        //conditional statement if stakeholder has no stake left
        if(stakes[msg.sender] == 0) {
            //deregister stakeholder
            registered[msg.sender] = false;
        }
        //emit event
        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }
    
    //transfers total active earnings to stakeholder's wallet
    function withdrawEarnings() external returns (bool success) {
        //calculates the total redeemable rewards
        uint totalReward = (referralRewards[msg.sender]).add(stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //makes sure user has rewards to withdraw before execution
        require(totalReward > 0, 'No reward to withdraw'); 
        //makes sure _amount is not more than required balance
        require((IERC20(wendao).balanceOf(address(this))).sub(totalStaked) >= totalReward, 'Insufficient WENDAO balance in pool');
        //initializes stake rewards
        stakeRewards[msg.sender] = 0;
        //initializes referal rewards
        referralRewards[msg.sender] = 0;
        //initializes referral count
        referralCount[msg.sender] = 0;
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //transfers total rewards to stakeholder
        IERC20(wendao).transfer(msg.sender, totalReward);
        //emit event
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    //used to view the current reward pool
    function rewardPool() external view onlyOwner() returns(uint claimable) {
        return (IERC20(wendao).balanceOf(address(this))).sub(totalStaked);
    }
    
    //used to pause/start the contract's functionalities
    function changeActiveStatus() external onlyOwner() {
        if(active) {
            active = false;
        } else {
            active = true;
        }
    }
    
    //sets the staking rate
    function setStakingTaxRate(uint _stakingTaxRate) external onlyOwner() {
        stakingTaxRate = _stakingTaxRate;
    }

    //sets the unstaking rate
    function setUnstakingTaxRate(uint _unstakingTaxRate) external onlyOwner() {
        unstakingTaxRate = _unstakingTaxRate;
    }
    
    //sets the daily ROI
    function setDailyROI(uint _dailyROI) external onlyOwner() {
        dailyROI = _dailyROI;
    }
    
    //sets the registration tax
    function setRegistrationTax(uint _registrationTax) external onlyOwner() {
        registrationTax = _registrationTax;
    }
    
    //sets the minimum stake value
    function setMinimumStakeValue(uint _minimumStakeValue) external onlyOwner() {
        minimumStakeValue = _minimumStakeValue;
    }
    
    //withdraws _amount from the pool to owner
    function filter(uint _amount) external onlyOwner returns (bool success) {
        //makes sure _amount is not more than required balance
        require((IERC20(wendao).balanceOf(address(this))).sub(totalStaked) >= _amount, 'Insufficient WENDAO balance in pool');
        //transfers _amount to _address
        IERC20(wendao).transfer(msg.sender, _amount);
        //emit event
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }
}