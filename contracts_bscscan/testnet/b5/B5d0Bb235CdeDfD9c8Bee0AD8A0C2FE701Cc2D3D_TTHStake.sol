pragma solidity ^0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }


    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


struct stakerini {
  uint256 lastClocks;
  uint256 totalStakeds;
  uint256 stakeDayss;
  uint256 idRandomer;
  address _address;
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

contract TTHStake is Owned , ReentrancyGuard {


    using SafeMath for uint;


    address public tth;

    uint public totalStaked;

    uint public stakingTaxRate;

    uint public registrationTax;

    uint public dailyROI;
    uint public weekROI;
    uint public monthROI;
    uint public month3ROI;
    uint public month6ROI;
    uint public yearROI;

    uint public unstakingTaxRate;

    uint public minimumStakeValue;

    bool public active = true;


    mapping(address => uint) public stakes;
    mapping(address => uint) public referralRewards;
    mapping(address => uint) public referralCount;
    mapping(address => uint) public stakeRewards;
    mapping(address => uint) public lastClock;
    mapping (address => stakerini[]) public Staker;



    mapping(address => uint) public stakeDays;
    mapping(address => bool) public registered;


    event OnWithdrawal(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);
    event OnRegisterAndStake(address stakeholder, uint amount, uint totalTax, uint countDays, address _referrer);


    constructor(
        address _token,
        uint _stakingTaxRate,
        uint _unstakingTaxRate,
        uint _dailyROI,
        uint _registrationTax,
        uint _minimumStakeValue) public {


        tth = _token;
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


    function registerAndStake(uint _amount ,  uint _days, address _referrer) external onlyUnregistered() whenActive() {

        require(msg.sender != _referrer, "Cannot refer self");

        require(registered[_referrer] || address(0x0) == _referrer, "Referrer must be registered");

        require(IERC20(tth).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");

        require(_amount >= registrationTax.add(minimumStakeValue), "Must send at least enough TTH to pay registration fee.");

        require(IERC20(tth).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");

        uint finalAmount = _amount.sub(registrationTax);

        uint stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);


        if(_referrer != address(0x0)) {
            //increase referral count of referrer
            referralCount[_referrer]++;
            //add referral bonus to referrer
            referralRewards[_referrer] = (referralRewards[_referrer]).add(stakingTax);
        }



        registered[msg.sender] = true;

        lastClock[msg.sender] = block.timestamp;
        stakeDays[msg.sender] = _days;




        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);



        Staker[msg.sender].push(stakerini({
                  lastClocks: block.timestamp,
                  stakeDayss: _days,
                  totalStakeds:(stakes[msg.sender]).add(finalAmount).sub(stakingTax),
                  idRandomer:block.timestamp+15,
                  _address:msg.sender
              }));

        stakes[msg.sender] = (stakes[msg.sender]).add(finalAmount).sub(stakingTax);

        emit OnRegisterAndStake(msg.sender, _amount, registrationTax.add(stakingTax), _days, _referrer);
    }


    function calculateEarnings(address _stakeholder) public view returns(uint) {

        uint activeDays = (block.timestamp.sub(lastClock[_stakeholder])).div(60);

        return ((stakes[_stakeholder]).mul(dailyROI).mul(activeDays)).div(10000);
    }


    function stake(uint _amount , uint _days) external onlyRegistered() whenActive() {

        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");

        require(IERC20(tth).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");

        require(IERC20(tth).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");

        uint stakingTax = (stakingTaxRate.mul(_amount)).div(1000);

        uint afterTax = _amount.sub(stakingTax);

        totalStaked = totalStaked.add(afterTax);

        //stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));

        uint remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(86400);

        lastClock[msg.sender] = block.timestamp.sub(remainder);
        stakeDays[msg.sender] = _days;





        Staker[msg.sender].push(stakerini({
          lastClocks: block.timestamp,
          stakeDayss: _days,
          totalStakeds:_amount.sub(stakingTax),
          idRandomer:block.timestamp+15,
          _address:msg.sender
              }));


        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);

        emit OnStake(msg.sender, afterTax, stakingTax);
    }




    function unstake(uint _amount) external onlyRegistered() {

        require(_amount <= stakes[msg.sender] && _amount > 0, 'Insufficient balance to unstake');
        require(block.timestamp >= lastClock[msg.sender] + stakeDays[msg.sender] * 1 days && _amount > 0, 'Your TTH still in Lock mode.');


        uint unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);

        uint afterTax = _amount.sub(unstakingTax);

        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));

        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);

        uint remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(86400);

        lastClock[msg.sender] = block.timestamp.sub(remainder);

        totalStaked = totalStaked.sub(_amount);

        IERC20(tth).transfer(msg.sender, afterTax);

        if(stakes[msg.sender] == 0) {

            registered[msg.sender] = false;
        }

        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }


    function withdrawEarnings() external returns (bool success) {

        uint totalReward = (referralRewards[msg.sender]).add(stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));

        require(totalReward > 0, 'No reward to withdraw');

        require((IERC20(tth).balanceOf(address(this))).sub(totalStaked) >= totalReward, 'Insufficient TTH balance in pool');

        stakeRewards[msg.sender] = 0;
        //initializes referal rewards
        referralRewards[msg.sender] = 0;
        //initializes referral count
        referralCount[msg.sender] = 0;



        uint remainder = (block.timestamp.sub(lastClock[msg.sender])).mod(86400);

        lastClock[msg.sender] = block.timestamp.sub(remainder);

        IERC20(tth).transfer(msg.sender, totalReward);

        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }


    function rewardPool() external view onlyOwner() returns(uint claimable) {
        return (IERC20(tth).balanceOf(address(this))).sub(totalStaked);
    }

    // function get() public view returns(uint256){
    //
    //     for(uint i = 0;i < Staker[msg.sender].length;i++){
    //         return Staker[msg.sender][i].stakeDayss;
    //     }
    //
    // }

    function getStakeResult(address _address) public view returns(uint){
      require(_address != msg.sender, 'Must be same User.');
      return Staker[_address].length;
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

        require((IERC20(tth).balanceOf(address(this))).sub(totalStaked) >= _amount, 'Insufficient TTH balance in pool');

        IERC20(tth).transfer(msg.sender, _amount);

        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }


}