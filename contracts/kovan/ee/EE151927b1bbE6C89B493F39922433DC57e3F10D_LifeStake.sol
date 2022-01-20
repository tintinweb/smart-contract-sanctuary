// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract LifeStake {

    using SafeMath for uint256;
    using SafeMath for uint8;

    //constant
    uint256 constant public percentDivider = 100_000;
    uint256 public maxStake = 2_500_000_000;
    uint256 public totalStaked;
    uint256 public TimeStep = 1 seconds;
    //address
    IERC20 public TOKEN;
    address payable public Admin;

    
    // structures
    struct Stake{
        uint256 StakePercent;
        uint256 StakePeriod;
    }
    struct Staker {
        uint256 Amount;
        uint256 Claimed;
        uint256 MaxClaimable;
        uint256 TokenPerDay;
        uint256 LastClaimTime;
        uint256 UnStakeTime;
        uint256 StakeTime;
    }

    
    Stake public StakeI;
    Stake public StakeII;
    Stake public StakeIII;
    // mapping & array
    address [] public Team;
    mapping(address => Staker) private PlanI;
    mapping(address => Staker) private PlanII;
    mapping(address => Staker) private PlanIII;


        modifier onlyAdmin(){
        require(msg.sender == Admin,"Stake: Not an Admin");
        _;
    }
    modifier validDepositId(uint256 _depositId) {
        require(_depositId >= 1 && _depositId <= 3, "Invalid depositId");
        _;
    }
    event StakeIIIBUY(address user, uint256 amount,uint256 time);
    event StakeIBUY(address user, uint256 amount,uint256 time);
    event StakeIIBUY(address user, uint256 amount,uint256 time);
    event StakeIIICLAIMED(address user, uint256 amount,uint256 time);
    event StakeICLAIMED(address user, uint256 amount,uint256 time);
    event StakeIICLAIMED(address user, uint256 amount,uint256 time);

    constructor(
    ) {
    Admin = payable(msg.sender);
    TOKEN = IERC20(0x6Cf28d91F1F8302692d231a7D286a37c30Ea36a9);
        StakeI.StakePercent = 2500;
        StakeI.StakePeriod = 30 seconds;

        StakeII.StakePercent = 2916;
        StakeII.StakePeriod = 180 seconds;

        StakeIII.StakePercent = 3250;
        StakeIII.StakePeriod = 360 seconds;

        maxStake = maxStake.mul(10**TOKEN.decimals()) ; 
    }

    receive() external payable {}

    // to buy  token during Stake time => for web3 use
    function deposit(address rewardAddress,uint256 _depositId, uint256 _amount) public validDepositId(_depositId){
        
        require(totalStaked <= maxStake,"MaxStake limit reached");
        TOKEN.transferFrom(msg.sender, address(this), _amount);
        totalStaked  = totalStaked.add(_amount);
        
        if(_depositId == 1)
        {
        PlanI[rewardAddress].TokenPerDay = PlanI[rewardAddress].TokenPerDay.add(CalculatePerDay(_amount.mul(StakeI.StakePercent).div(percentDivider),StakeI.StakePeriod));
        PlanI[rewardAddress].MaxClaimable = PlanI[rewardAddress].MaxClaimable.add(_amount.mul(StakeI.StakePercent).div(percentDivider));
        PlanI[rewardAddress].LastClaimTime = block.timestamp;
        PlanI[msg.sender].StakeTime = block.timestamp;
        PlanI[msg.sender].UnStakeTime = block.timestamp.add(StakeI.StakePeriod);
        PlanI[msg.sender].Amount = PlanI[msg.sender].Amount.add(_amount);
        emit StakeIBUY(msg.sender, _amount.div(10**(TOKEN.decimals())), block.timestamp);
        }else if(_depositId == 2)
        {
        PlanII[rewardAddress].TokenPerDay = PlanII[rewardAddress].TokenPerDay.add(CalculatePerDay(_amount.mul(StakeII.StakePercent).div(percentDivider),StakeII.StakePeriod));
        PlanII[rewardAddress].MaxClaimable = PlanII[rewardAddress].MaxClaimable.add(_amount.mul(StakeII.StakePercent).div(percentDivider));
        PlanII[rewardAddress].LastClaimTime = block.timestamp;
        PlanII[msg.sender].StakeTime = block.timestamp;
        PlanII[msg.sender].UnStakeTime = block.timestamp.add(StakeII.StakePeriod);
        PlanII[msg.sender].Amount = PlanII[msg.sender].Amount.add(_amount);
        emit StakeIIBUY(msg.sender, _amount.div(10**(TOKEN.decimals())), block.timestamp);
        }else if(_depositId == 3)
        {
        PlanIII[rewardAddress].TokenPerDay = PlanIII[rewardAddress].TokenPerDay.add(CalculatePerDay(_amount.mul(StakeIII.StakePercent).div(percentDivider),StakeIII.StakePeriod));
        PlanIII[rewardAddress].MaxClaimable = PlanIII[rewardAddress].MaxClaimable.add(_amount.mul(StakeIII.StakePercent).div(percentDivider));
        PlanIII[rewardAddress].LastClaimTime = block.timestamp;
        PlanIII[msg.sender].StakeTime = block.timestamp;
        PlanIII[msg.sender].UnStakeTime = block.timestamp.add(StakeIII.StakePeriod);
        PlanIII[msg.sender].Amount = PlanIII[msg.sender].Amount.add(_amount);
        emit StakeIIIBUY(msg.sender, _amount.div(10**(TOKEN.decimals())), block.timestamp);
        }
    }
    function withdrawAll(uint256 _depositId) external validDepositId(_depositId) {
        _withdraw(msg.sender, _depositId);
    }
    function _withdraw(address _user,uint256 _depositId) internal validDepositId(_depositId) {
        if(PlanI[_user].TokenPerDay > 0  && _depositId == 1 && PlanI[_user].Claimed <= PlanI[_user].MaxClaimable)
        {  require(block.timestamp > PlanI[_user].LastClaimTime + TimeStep);
            uint256 claimable = PlanI[_user].TokenPerDay.mul((block.timestamp.sub(PlanI[_user].LastClaimTime)).div(TimeStep));
            if(claimable > PlanI[_user].MaxClaimable.sub(PlanI[_user].Claimed)){
                claimable = PlanI[_user].MaxClaimable.sub(PlanI[_user].Claimed);
            }
            PlanI[_user].Claimed = PlanI[_user].Claimed.add(claimable);
            TOKEN.transfer(_user, claimable);
            PlanI[_user].LastClaimTime = block.timestamp;
            emit StakeICLAIMED(_user, PlanI[_user].Claimed.div(10**(TOKEN.decimals())), block.timestamp); 
        }
        if(PlanII[_user].TokenPerDay > 0 && _depositId == 2 && PlanII[_user].Claimed <= PlanII[_user].MaxClaimable)
        { require(block.timestamp > PlanII[_user].LastClaimTime + TimeStep);
            uint256 claimable = PlanII[_user].TokenPerDay.mul((block.timestamp.sub(PlanII[_user].LastClaimTime)).div(TimeStep));
            if(claimable > PlanII[_user].MaxClaimable.sub(PlanII[_user].Claimed)){
                claimable = PlanII[_user].MaxClaimable.sub(PlanII[_user].Claimed);
            }
            PlanII[_user].Claimed = PlanII[_user].Claimed.add(claimable);
            TOKEN.transfer(_user, claimable);
            PlanII[_user].LastClaimTime = block.timestamp;
            emit StakeIICLAIMED(_user, PlanII[_user].Claimed.div(10**(TOKEN.decimals())), block.timestamp); 
        }
        if(PlanIII[_user].TokenPerDay > 0 && _depositId == 3 && PlanIII[_user].Claimed <= PlanIII[_user].MaxClaimable)
        {
            require(block.timestamp > PlanIII[_user].LastClaimTime + TimeStep);
            uint256 claimable = PlanIII[_user].TokenPerDay.mul((block.timestamp.sub(PlanIII[_user].LastClaimTime)).div(TimeStep));
            if(claimable > PlanIII[_user].MaxClaimable.sub(PlanIII[_user].Claimed)){
                claimable = PlanIII[_user].MaxClaimable.sub(PlanIII[_user].Claimed);
            }
            PlanIII[_user].Claimed = PlanIII[_user].Claimed.add(claimable);
            TOKEN.transfer(_user, claimable);
            PlanIII[_user].LastClaimTime = block.timestamp;
            emit StakeIIICLAIMED(_user, PlanIII[_user].Claimed.div(10**(TOKEN.decimals())), block.timestamp);
        }        
    }
    function extendLockup(uint256 _depositId)
        external
        validDepositId(_depositId)
    {
        if(_depositId == 1){
            PlanI[msg.sender].UnStakeTime = PlanI[msg.sender].UnStakeTime.add(StakeI.StakePeriod);
            PlanI[msg.sender].MaxClaimable = PlanI[msg.sender].MaxClaimable.add(PlanI[msg.sender].Amount.mul(StakeI.StakePercent).div(percentDivider));
        }else if(_depositId == 2){
            PlanII[msg.sender].UnStakeTime = PlanII[msg.sender].UnStakeTime.add(StakeII.StakePeriod);
            PlanII[msg.sender].MaxClaimable = PlanII[msg.sender].MaxClaimable.add(PlanII[msg.sender].Amount.mul(StakeII.StakePercent).div(percentDivider));
        }else if(_depositId == 3){
            PlanIII[msg.sender].UnStakeTime = PlanIII[msg.sender].UnStakeTime.add(StakeIII.StakePeriod);
            PlanIII[msg.sender].MaxClaimable = PlanIII[msg.sender].MaxClaimable.add(PlanIII[msg.sender].Amount.mul(StakeIII.StakePercent).div(percentDivider));
        }
    }
    function CompleteWithDraw(uint256 _depositId)
        external
        validDepositId(_depositId)
    {
        if(_depositId == 1){
            require(PlanI[msg.sender].UnStakeTime < block.timestamp);
            TOKEN.transfer(msg.sender, PlanI[msg.sender].Amount);
            _withdraw(msg.sender, _depositId);
            PlanI[msg.sender].Amount = 0;
            PlanI[msg.sender].Claimed = 0;
            PlanI[msg.sender].MaxClaimable = 0;
            PlanI[msg.sender].TokenPerDay = 0;
            PlanI[msg.sender].LastClaimTime = 0;
            PlanI[msg.sender].UnStakeTime = 0;
        }else if(_depositId == 2){
            require(PlanII[msg.sender].UnStakeTime < block.timestamp);
            TOKEN.transfer(msg.sender, PlanII[msg.sender].Amount);
            _withdraw(msg.sender, _depositId);
            PlanII[msg.sender].Amount = 0;
            PlanII[msg.sender].Claimed = 0;
            PlanII[msg.sender].MaxClaimable = 0;
            PlanII[msg.sender].TokenPerDay = 0;
            PlanII[msg.sender].LastClaimTime = 0;
            PlanII[msg.sender].UnStakeTime = 0;
        }else if(_depositId == 3){
            require(PlanIII[msg.sender].UnStakeTime < block.timestamp);
            TOKEN.transfer(msg.sender, PlanI[msg.sender].Amount);
            _withdraw(msg.sender, _depositId);
            PlanIII[msg.sender].Amount = 0;
            PlanIII[msg.sender].Claimed = 0;
            PlanIII[msg.sender].MaxClaimable = 0;
            PlanIII[msg.sender].TokenPerDay = 0;
            PlanIII[msg.sender].LastClaimTime = 0;
            PlanIII[msg.sender].UnStakeTime = 0;
        }
    }
    function calcRewards(address _sender, uint256 _depositId) public view validDepositId(_depositId) returns (uint256 amount) {
        if(_depositId == 1){
            uint256 claimable = PlanI[_sender].TokenPerDay.mul((block.timestamp.sub(PlanI[_sender].LastClaimTime)).div(TimeStep));
            if(claimable > PlanI[_sender].MaxClaimable.sub(PlanI[_sender].Claimed)){
                claimable = PlanI[_sender].MaxClaimable.sub(PlanI[_sender].Claimed);
            }
            return(claimable);
        }
        else if(_depositId == 2){
            uint256 claimable = PlanII[_sender].TokenPerDay.mul((block.timestamp.sub(PlanII[_sender].LastClaimTime)).div(TimeStep));
            if(claimable > PlanII[_sender].MaxClaimable.sub(PlanII[_sender].Claimed)){
                claimable = PlanII[_sender].MaxClaimable.sub(PlanII[_sender].Claimed);
            }
            return(claimable);
        }
        else if(_depositId ==3){
            uint256 claimable = PlanIII[_sender].TokenPerDay.mul((block.timestamp.sub(PlanIII[_sender].LastClaimTime)).div(TimeStep));
            if(claimable > PlanIII[_sender].MaxClaimable.sub(PlanIII[_sender].Claimed)){
                claimable = PlanIII[_sender].MaxClaimable.sub(PlanIII[_sender].Claimed);
            }
            return(claimable);
        }
    }
    function getCurrentBalance(uint256 _depositId, address _sender) public view returns (uint256 addressBalance) {
        if(_depositId == 1){
            return(PlanI[_sender].Amount);
        }
        else if(_depositId == 2){
            return(PlanII[_sender].Amount);
        }
        else if(_depositId ==3){
            return(PlanIII[_sender].Amount);
        }
    }
    function depositDates(address _sender,uint256 _depositId) public view validDepositId(_depositId) returns (uint256 date) {
        if(_depositId == 1){
            return(PlanI[_sender].StakeTime);
        }
        else if(_depositId == 2){
            return(PlanII[_sender].StakeTime);
        }
        else if(_depositId ==3){
            return(PlanIII[_sender].StakeTime);
        }
    }
    function isLockupPeriodExpired(uint256 _depositId) public view validDepositId(_depositId) returns (bool val) {

        if (_depositId == 1) {
            if (block.timestamp > PlanI[msg.sender].UnStakeTime) {
            return true;
        } else {
            return false;
        }
        } else if (_depositId == 2) {
            if (block.timestamp > PlanII[msg.sender].UnStakeTime) {
            return true;
        } else {
            return false;
        }
        } else if (_depositId == 3) {
            if (block.timestamp > PlanIII[msg.sender].UnStakeTime) {
            return true;
        } else {
            return false;
        }
        }
        
    }
    // transfer Adminship
    function transferOwnership(address payable _newAdmin) external onlyAdmin {
        Admin = _newAdmin;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }
    function CalculatePerDay(uint256 amount,uint256 _VestingPeriod) internal view returns (uint256) {
        return amount.mul(TimeStep).div(_VestingPeriod);
    }
}
//library
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}