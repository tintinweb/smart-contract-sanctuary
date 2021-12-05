pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


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

    bool public active;


    mapping(address => uint) public referralRewards;


    mapping (address => stakerini[]) public Staker;


    mapping(uint => address) private refUser;
    mapping (address => mapping (uint256 => uint256)) public balances;
    mapping(address => uint) public userRef;

    mapping(address => bool) public registered;
    bool private initialized;


    event OnWithdrawal(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnRelock(address sender, uint amount);
    event OnUnstake(address sender, uint amount, uint tax);
    event OnRegisterAndStake(address stakeholder, uint amount, uint totalTax, uint countDays, address _referrer);



    function initialize(
        address _token,
        address _owner,
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
        require(!initialized, "Contract instance has already been initialized");

        owner = _owner;


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
        active = true;
        initialized = true;
    }


    constructor(
        address _token,
        address _owner,
        uint _stakingTaxRate,
        uint _unstakingTaxRate,
        uint _dailyROI,
        uint _weekROI,
        uint _monthROI,
        uint _month3ROI,
        uint _month6ROI,
        uint _yearROI,
        uint _registrationTax,
        uint _minimumStakeValue) ReentrancyGuard() public {

        owner = _owner;


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
        active = true;
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


    function registerAndStake(uint _amount ,  uint _days, uint _referrers) nonReentrant() external onlyUnregistered() whenActive() {

        address _referrer = getRefUser(_referrers);


        require(_days == 1 || _days == 2 || _days == 3 || _days == 4 || _days == 5 || _days == 6,"Days must be compatible");


        require(msg.sender != _referrer, "Cannot refer self");

        require(registered[_referrer] || address(0x0) == _referrer, "Referrer must be registered");


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

        uint stakingTax = (stakingTaxRate.mul(finalAmount)).div(10000);


        if(_referrer != address(0x0)) {

            referralRewards[_referrer] = (referralRewards[_referrer]).add(stakingTax);
        }



        registered[msg.sender] = true;





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



        emit OnRegisterAndStake(msg.sender, _amount, registrationTax.add(stakingTax), day, _referrer);
    }




    function stake(uint _amount , uint _days) nonReentrant() external onlyRegistered() whenActive() {


        require(_days == 1 || _days == 2 || _days == 3 || _days == 4 || _days == 5 || _days == 6,"Days must be compatible");

        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");

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



        uint stakingTax = (stakingTaxRate.mul(_amount)).div(10000);

        uint afterTax = _amount.sub(stakingTax);

        totalStaked = totalStaked.add(afterTax);


        Staker[msg.sender].push(stakerini({
          rewardClocks: block.timestamp,
          lastClocks: block.timestamp,
          stakeDayss: day,
          totalStakeds:_amount.sub(stakingTax),
          idRandomer:random(),
          _address:msg.sender
              }));


        emit OnStake(msg.sender, afterTax, stakingTax);
    }




    function unstake(address _addressr,uint256 _idRandom) nonReentrant() external whenActive onlyRegistered() {

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



        uint unstakingTax = (unstakingTaxRate.mul(tsotalStakeds)).div(10000);

        uint afterTax = tsotalStakeds.sub(unstakingTax).add(referralRewards[msg.sender]).add(calcStakingAll(msg.sender));


        totalStaked = totalStaked.sub(tsotalStakeds);


        IERC20(tth).transfer(msg.sender, afterTax);


        if(Staker[_addressr].length == 0) {

            registered[msg.sender] = false;
        }else{
          RewardNew(msg.sender);
        }

        emit OnUnstake(msg.sender, tsotalStakeds, unstakingTax);
    }


    function withdrawEarnings() nonReentrant() whenActive external returns (bool success) {

        uint totalReward = (referralRewards[msg.sender]).add(calcStakingAll(msg.sender));


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


    function Relock(address _addressr,uint idrandom) nonReentrant() whenActive public returns (bool success){
      require(_addressr == msg.sender, 'Must be same User.');


        for(uint i = 0;i < Staker[_addressr].length;i++){
          if(idrandom == Staker[_addressr][i].idRandomer){
            require(block.timestamp > Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)), 'Your staking still in lock mode!');

           Staker[_addressr][i].lastClocks = block.timestamp.add(Staker[_addressr][i].stakeDayss);

         }
        }


        //emit OnRelock(msg.sender, tsotalStakeds);
        return true;
    }



    function calcStakingAll(address _addressr) public view returns(uint){
      uint dd = 0;
        for(uint i = 0;i < Staker[_addressr].length;i++){

          if(Staker[_addressr][i].stakeDayss == 1){


            if(block.timestamp < (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)))){
              uint activeDays = (block.timestamp.sub(Staker[_addressr][i].rewardClocks)).div(1);
              dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(dailyROI).mul(activeDays)).div(100000).div(1)) / 86400);
            }else if((Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400))) < Staker[_addressr][i].rewardClocks){

              dd = dd + 0;

            }else{

              uint activeDays = (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)).sub(Staker[_addressr][i].rewardClocks)).div(1);
              dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(dailyROI).mul(activeDays)).div(100000).div(1)) / 86400);

            }

        }else if(Staker[_addressr][i].stakeDayss == 7){

          if(block.timestamp < (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)))){

            uint activeDays = (block.timestamp.sub(Staker[_addressr][i].rewardClocks)).div(1);

            dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(weekROI).mul(activeDays)).div(10000).div(7)) / 86400);
          }else if((Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400))) < Staker[_addressr][i].rewardClocks){

            dd = dd + 0;

          }else{
            uint activeDays = (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)).sub(Staker[_addressr][i].rewardClocks)).div(1);

            dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(weekROI).mul(activeDays)).div(10000).div(7)) / 86400);
          }


        }else if(Staker[_addressr][i].stakeDayss == 30){

        if(block.timestamp < (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)))){

            uint activeDays = (block.timestamp.sub(Staker[_addressr][i].rewardClocks)).div(1);

          dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(monthROI).mul(activeDays)).div(10000).div(30)) / 86400);
        }else if((Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400))) < Staker[_addressr][i].rewardClocks){

          dd = dd + 0;

        }else{
          uint activeDays = (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)).sub(Staker[_addressr][i].rewardClocks)).div(1);

          dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(monthROI).mul(activeDays)).div(10000).div(30)) / 86400);
        }

        }else if(Staker[_addressr][i].stakeDayss == 90){

          if(block.timestamp < (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)))){

            uint activeDays = (block.timestamp.sub(Staker[_addressr][i].rewardClocks)).div(1);

          dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(month3ROI).mul(activeDays)).div(10000).div(90)) / 86400);
        }else if((Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400))) < Staker[_addressr][i].rewardClocks){

          dd = dd + 0;

        }else{
          uint activeDays = (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)).sub(Staker[_addressr][i].rewardClocks)).div(1);

          dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(month3ROI).mul(activeDays)).div(10000).div(90)) / 86400);
        }

        }else if(Staker[_addressr][i].stakeDayss == 180){
          if(block.timestamp < (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)))){
            uint activeDays = (block.timestamp.sub(Staker[_addressr][i].rewardClocks)).div(1);

          dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(month6ROI).mul(activeDays)).div(10000).div(180)) / 86400);
        }else if((Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400))) < Staker[_addressr][i].rewardClocks){

          dd = dd + 0;

        }else{
          uint activeDays = (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)).sub(Staker[_addressr][i].rewardClocks)).div(1);

          dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(month6ROI).mul(activeDays)).div(10000).div(180)) / 86400);

        }

        }else if(Staker[_addressr][i].stakeDayss == 365){
          if(block.timestamp < (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)))){
            uint activeDays = (block.timestamp.sub(Staker[_addressr][i].rewardClocks)).div(1);

          dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(yearROI).mul(activeDays)).div(10000).div(365)) / 86400);
        }else if((Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400))) < Staker[_addressr][i].rewardClocks){

          dd = dd + 0;

        }else{
          uint activeDays = (Staker[_addressr][i].lastClocks.add(Staker[_addressr][i].stakeDayss.mul(86400)).sub(Staker[_addressr][i].rewardClocks)).div(1);
          dd = dd + ((((Staker[_addressr][i].totalStakeds).mul(yearROI).mul(activeDays)).div(10000).div(365)) / 86400);



        }

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


    function filters(uint _amount) nonReentrant() external onlyOwner returns (bool success) {

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}