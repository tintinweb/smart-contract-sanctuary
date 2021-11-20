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
  uint256 rewardClocks;
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

    mapping (address => stakerini[]) public Staker;

    mapping(uint => address) private refUser;
    mapping(address => uint) public userRef;




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
        uint _weekROI,
        uint _monthROI,
        uint _month3ROI,
        uint _month6ROI,
        uint _yearROI,
        uint _registrationTax,
        uint _minimumStakeValue) public {


        tth = _token;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        weekROI = _weekROI;
        monthROI = _monthROI;
        month3ROI = _month3ROI;
        month6ROI = _month6ROI;
        yearROI = _yearROI;
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


    function registerAndStake(uint _amount ,  uint _days, uint _referrers) external onlyUnregistered() whenActive() {

        address _referrer = getRefUser(_referrers);


        require(_days == 1 || _days == 2 || _days == 3 || _days == 4 || _days == 5 || _days == 6,"Days must be compatible");




        require(msg.sender != _referrer, "Cannot refer self");

        require(registered[_referrer] || address(0x0) == _referrer, "Referrer must be registered");

        require(IERC20(tth).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");

        require(_amount >= registrationTax.add(minimumStakeValue), "Must send at least enough TTH to pay registration fee.");

        require(IERC20(tth).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");

        uint day = 1;


        if(_days == 1){
          day = 1;
        }else if(_days == 2){
          day = 7;
        }else if(_days == 3){
          day = 30;
        }else if(_days == 4){
          day = 90;
        }else if(_days == 5){
          day = 180;
        }else if(_days == 6){
          day = 365;
        }else {
          day = 1;
        }

        uint finalAmount = _amount.sub(registrationTax);

        uint stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);


        if(_referrer != address(0x0)) {
            //increase referral count of referrer
            referralCount[_referrer]++;
            //add referral bonus to referrer
            referralRewards[_referrer] = (referralRewards[_referrer]).add(stakingTax);
        }



        registered[msg.sender] = true;

        //lastClock[msg.sender] = block.timestamp;
        stakeDays[msg.sender] = day;




        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);




        uint refuas = random();





        refUser[refuas] =  msg.sender;
        userRef[msg.sender] = refuas;






        Staker[msg.sender].push(stakerini({
                  rewardClocks: block.timestamp,
                  lastClocks: block.timestamp,
                  stakeDayss: day,
                  totalStakeds:finalAmount.sub(stakingTax),
                  idRandomer:random(),
                  _address:msg.sender
              }));

        //stakes[msg.sender] = (stakes[msg.sender]).add(finalAmount).sub(stakingTax);

        emit OnRegisterAndStake(msg.sender, _amount, registrationTax.add(stakingTax), day, _referrer);
    }


    // function calculateEarnings(address _stakeholder, uint256 _sidRandomer) public view returns(uint) {
    //     uint activeDays = (block.timestamp.sub(getStaking(_stakeholder,_sidRandomer))).div(120);
    //     return ((dailyROI).mul(activeDays)).div(10000);
    // }


    function stake(uint _amount , uint _days) external onlyRegistered() whenActive() {


        require(_days == 1 || _days == 2 || _days == 3 || _days == 4 || _days == 5 || _days == 6,"Days must be compatible");

        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");

        require(IERC20(tth).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");

        require(IERC20(tth).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");



        uint day = 1;


        if(_days == 1){
          day = 1;
        }else if(_days == 2){
          day = 7;
        }else if(_days == 3){
          day = 30;
        }else if(_days == 4){
          day = 90;
        }else if(_days == 5){
          day = 180;
        }else if(_days == 6){
          day = 365;
        }else {
          day = 1;
        }



        uint stakingTax = (stakingTaxRate.mul(_amount)).div(1000);

        uint afterTax = _amount.sub(stakingTax);

        totalStaked = totalStaked.add(afterTax);

        //stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));

        //uint remainder = block.timestamp;

        //lastClock[msg.sender] = block.timestamp;
        stakeDays[msg.sender] = day;





        Staker[msg.sender].push(stakerini({
          rewardClocks: block.timestamp,
          lastClocks: block.timestamp,
          stakeDayss: day,
          totalStakeds:_amount.sub(stakingTax),
          idRandomer:random(),
          _address:msg.sender
              }));

        //stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);

        emit OnStake(msg.sender, afterTax, stakingTax);
    }




    function unstake(address _addressr,uint256 _idRandom) external onlyRegistered() {

      uint256 rsewardClocks = 0;
      uint256 lsastClocks = 0;
      uint256 sstakeDayss = 0;
      uint256 tsotalStakeds = 0;
      uint256 isdRandomer = 0;

      for(uint i = 0;i < Staker[_addressr].length;i++){
        if(_idRandom == Staker[_addressr][i].idRandomer && msg.sender == Staker[_addressr][i]._address){
          rsewardClocks = Staker[_addressr][i].rewardClocks;
          lsastClocks = Staker[_addressr][i].lastClocks;
          sstakeDayss = Staker[_addressr][i].stakeDayss;
          tsotalStakeds = Staker[_addressr][i].totalStakeds;
          isdRandomer = Staker[_addressr][i].idRandomer;
          delete Staker[_addressr][i];
          Staker[_addressr][i] = Staker[_addressr][Staker[_addressr].length - 1];
          Staker[_addressr].pop();
        }
      }



        require(block.timestamp > lsastClocks.add(sstakeDayss.mul(86400)), 'Your staking still in lock mode!');


        require(tsotalStakeds > 0, 'Insufficient balance to unstake');



        uint unstakingTax = (unstakingTaxRate.mul(tsotalStakeds)).div(1000);

        uint afterTax = tsotalStakeds.sub(unstakingTax);


        totalStaked = totalStaked.sub(tsotalStakeds);

        IERC20(tth).transfer(msg.sender, afterTax);

        if(Staker[_addressr].length == 0) {

            registered[msg.sender] = false;
        }

        emit OnUnstake(msg.sender, tsotalStakeds, unstakingTax);
    }


    function withdrawEarnings() external returns (bool success) {

        uint totalReward = 50000000000;//(referralRewards[msg.sender]).add(calcStakingAll(msg.sender));


        require(totalReward > 0, 'No reward to withdraw');

        require((IERC20(tth).balanceOf(address(this))).sub(totalStaked) >= totalReward, 'Insufficient TTH balance in pool');

        referralRewards[msg.sender] = 0;


        RewardNew(msg.sender);


        IERC20(tth).transfer(msg.sender, totalReward);

        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }


    function rewardPool() external view onlyOwner() returns(uint claimable) {
        return (IERC20(tth).balanceOf(address(this))).sub(totalStaked);
    }



    function getRefUser(uint _refUser) private view returns(address){
        return refUser[_refUser];
    }


    function RewardNew(address _addressr) private returns (bool success){
      require(_addressr == msg.sender, 'Must be same User.');
      if(_addressr == msg.sender){
        for(uint i = 0;i < Staker[_addressr].length;i++){

           Staker[_addressr][i].rewardClocks = block.timestamp;

        }
        }

        return true;
    }


    function Relock(address _addressr,uint idrandom) public returns (bool success){
      require(_addressr == msg.sender, 'Must be same User.');


        for(uint i = 0;i < Staker[_addressr].length;i++){
          if(idrandom == Staker[_addressr][i].idRandomer){
            //if(block.timestamp > block.timestamp.add(Staker[_addressr][i].stakeDayss.mul(86400))){
            require(block.timestamp > Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)), 'Your staking still in lock mode!');

           Staker[_addressr][i].rewardClocks = block.timestamp;
           Staker[_addressr][i].lastClocks = block.timestamp.add(Staker[_addressr][i].stakeDayss);
         // }else{
         //   revert('Your staking still in lock mode!');
         // }
         }
        }

        return true;
    }



    function calcStakingAll(address _addressr) public view returns(uint){
      uint dd = 0;
        for(uint i = 0;i < Staker[_addressr].length;i++){
          uint activeDays = (block.timestamp.sub(Staker[_addressr][i].rewardClocks)).div(120);
          if(Staker[_addressr][i].stakeDayss == 1){
          dd = dd + ((Staker[_addressr][i].totalStakeds).mul(dailyROI).mul(activeDays)).div(10000).div(1);
        }else if(Staker[_addressr][i].stakeDayss == 7){
          dd = dd + ((Staker[_addressr][i].totalStakeds).mul(weekROI).mul(activeDays)).div(10000).div(7);
        }else if(Staker[_addressr][i].stakeDayss == 30){
          dd = dd + ((Staker[_addressr][i].totalStakeds).mul(monthROI).mul(activeDays)).div(10000).div(30);
        }else if(Staker[_addressr][i].stakeDayss == 90){
          dd = dd + ((Staker[_addressr][i].totalStakeds).mul(month3ROI).mul(activeDays)).div(10000).div(90);
        }else if(Staker[_addressr][i].stakeDayss == 180){
          dd = dd + ((Staker[_addressr][i].totalStakeds).mul(month6ROI).mul(activeDays)).div(10000).div(180);
        }else if(Staker[_addressr][i].stakeDayss == 365){
          dd = dd + ((Staker[_addressr][i].totalStakeds).mul(yearROI).mul(activeDays)).div(10000).div(365);
        }
        }
        return dd;
    }

    function calcUserStakingStored(address _addressr) public view returns(uint){
      uint dd = 0;
        for(uint i = 0;i < Staker[_addressr].length;i++){

          dd = dd + Staker[_addressr][i].totalStakeds;
        }
        return dd;
    }

    function getStakeResult(address _address) public view returns(uint){
      //require(_address == msg.sender, 'Must be same User.');
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

    function setWeekROI(uint _weekROI) external onlyOwner() {
        weekROI = _weekROI;
    }

    function setMonthROI(uint _monthROI) external onlyOwner() {
        monthROI = _monthROI;
    }

    function setMonth3ROI(uint _month3ROI) external onlyOwner() {
        month3ROI = _month3ROI;
    }

    function setMonth6ROI(uint _month6ROI) external onlyOwner() {
        month6ROI = _month6ROI;
    }

    function setYearROI(uint _yearROI) external onlyOwner() {
        yearROI = _yearROI;
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

    function random() private view returns(uint){
     uint source = block.difficulty + block.timestamp;
     return uint(keccak256(abi.encodePacked(source))) / 9 ** 59;
   }




}