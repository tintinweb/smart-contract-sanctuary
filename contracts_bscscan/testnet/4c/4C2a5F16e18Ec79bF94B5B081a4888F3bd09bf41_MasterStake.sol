/* SPDX-License-Identifier: Unlicensed */
pragma solidity ^0.8.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    mapping(address => bool) private _admin;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        _admin[_owner] = true;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function isAdminCheck(address addressToCheck) external view returns (bool) {
        return _admin[addressToCheck];
    } 

    function updateAdmin(address addressToSet, bool isAdmin) external returns (string memory, address, bool) {
        _admin[addressToSet] = isAdmin;
        return("Admin status", addressToSet, _admin[addressToSet]);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "You are not the Owner!");
        _;
    }

    modifier onlyAdmin() {
        require(_admin[_msgSender()], "You are not an Admin!");
        _;
    }

    function transferOwnership(address _address) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, _address);
        _owner = _address;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MasterStake is Ownable {

struct coinToStake{
    address _address;
    uint256 _decimals;
    uint256 _stakeLimitWholeNumber;
}

struct coinToReward{
    address _address;
    uint256 _decimals;
    uint256 _poolAmount;
    uint256 _stakePercentage;
    uint256 _stakeRateInEpoch;
} 

struct StakePool {
    uint256 _poolID;
    uint256 _stakeFee;
    uint256 _unStakeFee;
    coinToStake _coinToStake;
    coinToReward _coinToReward;
    uint256 _amountStaked;
    uint256 _rewardClaimed;
    uint256 _startTime;
    uint256 _endDate;
}

struct UserStake {
    uint256 _stakeID;
    address _user;
    uint256 _poolID;
    uint256 _amountStaked;
    uint256 _startTime;
    uint256 _rewardClaimed;
}

// How many pools or stakes created
uint256 public nextPoolID;
uint256 public nextStakeID;
address public feeCollector;

mapping (uint256 => StakePool) public stakePoolFromPoolID;
mapping (address => uint256[]) public stakesFromUser;
mapping (uint256 => uint256[]) public stakesFromPoolID;
mapping (uint256 => uint256) public poolFromStakeID;
mapping (uint256 => uint256) public endDateFromPoolID;
mapping (uint256 => bool) public isActiveFromPoolID;
mapping (uint256 => mapping (address => bool)) public isUserStaked;
mapping (uint256 => mapping (address => UserStake)) public userStakeFromPoolID;
event Stake(uint256 indexed poolID, address indexed sender,uint256 newStakeBal);
event UnStake(uint256 indexed poolID, address indexed sender,uint256 unStakeAmount);
event Fee(uint256 indexed poolID, address indexed sender,uint256 feeAmount, string feeType);
event Harvest(uint256 indexed poolID, address indexed sender,uint256 availableHarvest);
event NewStakePool(uint256 indexed poolID, address indexed tokenStake,address indexed tokenReward);
event EndStakePool(uint256 indexed poolID, uint256 endDate);
event UpdateStakeFees(uint256 indexed poolID, uint256 stakeFee, uint256 unStakeFee);

//modifiers
modifier isPoolExist(uint256 _poolID) {
        require(_poolID <= nextPoolID, 'Staking Pool does not exist!');
        _;
}

modifier isPoolActive(uint256 _poolID) {
        require(isActiveFromPoolID[_poolID], 'Staking for this pool is not active!');
        _;
}

modifier isPoolEndTime(uint256 _poolID) {
        require(block.timestamp < endDateFromPoolID[_poolID], 'Staking for this pool has ended!');
        _;
}

function getRewardPaidView(uint256 _poolID,address _sender) public view isPoolExist(_poolID) returns(uint256) {
    require(isUserStaked[_poolID][_sender], 'You have no stake in this pool!');
    UserStake storage currentUserStake = userStakeFromPoolID[_poolID][_sender];
    StakePool storage currentPool = stakePoolFromPoolID[_poolID];
    coinToStake storage cs = currentPool._coinToStake;
    coinToReward storage cr = currentPool._coinToReward;
    uint256 amountStaked = currentUserStake._amountStaked;
    
    if(amountStaked < 0){
        revert('No coins staked!');
    }
    
    if(endDateFromPoolID[_poolID] <= block.timestamp){
        return ( ( amountStaked * cr._stakePercentage / (10 ** cs._decimals) ) * (endDateFromPoolID[_poolID] - currentUserStake._startTime) / cr._stakeRateInEpoch ) * (10 ** cr._decimals) / 100;
    }else{
        return ( ( amountStaked * cr._stakePercentage / (10 ** cs._decimals) ) * (block.timestamp - currentUserStake._startTime) / cr._stakeRateInEpoch ) * (10 ** cr._decimals) / 100;
    }
}

function getRewardPaidPool(uint256 _poolID, uint256 _endDate) internal view isPoolExist(_poolID) returns(uint256) {
    StakePool storage currentPool = stakePoolFromPoolID[_poolID];
    coinToStake storage cs = currentPool._coinToStake;
    coinToReward storage cr = currentPool._coinToReward;
    uint256 amountStaked = currentPool._amountStaked;
    return ( ( amountStaked * cr._stakePercentage / (10 ** cs._decimals) ) * (_endDate - currentPool._startTime) / cr._stakeRateInEpoch ) * (10 ** cr._decimals) / 100;

}

// user functions
function stake(uint256 _poolID, uint256 _stakeAmountWithDecimal) external isPoolExist(_poolID) isPoolEndTime(_poolID){
    address sender = _msgSender();
    StakePool storage currentPool = stakePoolFromPoolID[_poolID];
    coinToStake storage cs = currentPool._coinToStake;
    require(_stakeAmountWithDecimal / (10 ** cs._decimals) <= cs._stakeLimitWholeNumber || cs._stakeLimitWholeNumber == 0, 'You are over the stake limit!');
    uint256 newStakeBal;
    coinToReward storage cr = currentPool._coinToReward;
    uint256 stakeFee = currentPool._stakeFee; 
    uint256 _stakeAmount = _stakeAmountWithDecimal;
    uint256 feeAmount = (_stakeAmount * stakeFee / 100);
    
    if(isUserStaked[_poolID][sender]){
        UserStake storage currentUserStake = userStakeFromPoolID[_poolID][sender];
        uint256 tokenStakeLimitWithZeros;
        if(cs._stakeLimitWholeNumber == 0){
          tokenStakeLimitWithZeros = 0;     
        }else{
          tokenStakeLimitWithZeros = cs._stakeLimitWholeNumber * (10**cs._decimals); 
        }
        require(_stakeAmount + currentUserStake._amountStaked <= tokenStakeLimitWithZeros || tokenStakeLimitWithZeros == 0, 'You are over the stake limit!');
        uint256 availableHarvest  = getRewardPaidView(_poolID,sender);
        
        if(availableHarvest < 0 ){
            availableHarvest = 0;
        }

        // collect stake
        IERC20(cs._address).transferFrom(sender,address(this),_stakeAmount);

        // claim or reStake reward token if same as stake
        if(cs._address == cr._address){ 
            newStakeBal = (_stakeAmount - feeAmount) + availableHarvest;
        }else{
            newStakeBal = _stakeAmount - feeAmount;
            IERC20(cr._address).transfer(sender,availableHarvest);
        }

        // update stake amount
        currentUserStake._rewardClaimed += availableHarvest;
        currentPool._rewardClaimed += availableHarvest;
        currentPool._amountStaked += newStakeBal;
        currentUserStake._amountStaked += newStakeBal;
        currentUserStake._startTime = block.timestamp;
        emit Harvest(_poolID,sender,availableHarvest);
    }else{
        //start newStake
        uint256 userStartTime = block.timestamp;
        IERC20(cs._address).transferFrom(sender,address(this),_stakeAmount);
        newStakeBal = _stakeAmount - feeAmount;

        isUserStaked[_poolID][sender] = true;
        poolFromStakeID[nextStakeID] = _poolID;
        stakesFromPoolID[_poolID].push(nextStakeID);
        stakesFromUser[sender].push(nextStakeID);

        userStakeFromPoolID[_poolID][sender] = UserStake(nextStakeID,sender,_poolID,newStakeBal,userStartTime,0);

        // update stake amount
        currentPool._amountStaked += newStakeBal;
        nextStakeID++; 
    }
    
    //collect fee
    IERC20(cs._address).transfer(feeCollector,feeAmount); 
    emit Fee(_poolID,sender,feeAmount,'Stake');
    emit Stake(_poolID,sender,newStakeBal);
}

function unStake(uint256 _poolID, uint256 _unStakeAmountWithDecimal) external isPoolExist(_poolID) {
    address sender = _msgSender();
    require(isUserStaked[_poolID][sender], 'You have no stake in this pool!');
    UserStake storage currentUserStake = userStakeFromPoolID[_poolID][sender];      
    uint256 amountStaked = currentUserStake._amountStaked;
    StakePool storage currentPool = stakePoolFromPoolID[_poolID];
    coinToStake storage cs = currentPool._coinToStake;
    uint256 _unStakeAmount = _unStakeAmountWithDecimal;
    require(_unStakeAmount <= amountStaked, 'You do not have that amount available!');
    coinToReward storage cr = currentPool._coinToReward;
    uint256 availableHarvest = getRewardPaidView(_poolID,sender);
    
    if(availableHarvest < 0 ){
        availableHarvest = 0;
    }
    
    uint256 unStakeFee = currentPool._unStakeFee;
    uint256 feeAmount = (_unStakeAmount * unStakeFee / 100);

        // unstake
        currentPool._amountStaked -= _unStakeAmount;
        currentUserStake._amountStaked -= _unStakeAmount;
        uint256 newUnStakeBal = _unStakeAmount - feeAmount;
        if(cs._address == cr._address){
            uint256 newUnStakeBalHarvest = _unStakeAmount + availableHarvest - feeAmount ;
            IERC20(cs._address).transfer(sender,newUnStakeBalHarvest);
        }else{
            IERC20(cs._address).transfer(sender,newUnStakeBal);
            IERC20(cr._address).transfer(sender,availableHarvest);
        }

    // update claim
    currentUserStake._rewardClaimed += availableHarvest;
    currentPool._rewardClaimed += availableHarvest;
    currentUserStake._startTime = block.timestamp;
    
    // collect feeAmount
    IERC20(cs._address).transfer(feeCollector,feeAmount);
    emit Fee(_poolID,sender,feeAmount,'unStake');
    emit UnStake(_poolID,sender,_unStakeAmount);
    emit Harvest(_poolID,sender,availableHarvest);
}


function harvest(uint256 _poolID) external isPoolExist(_poolID) {
    address sender = _msgSender();
    require(isUserStaked[_poolID][sender], 'You have no stake in this pool!');
    UserStake storage currentUserStake = userStakeFromPoolID[_poolID][sender];  
    StakePool storage currentPool = stakePoolFromPoolID[_poolID];
    coinToReward storage cr = currentPool._coinToReward;
    uint256 availableHarvest = getRewardPaidView(_poolID,sender);
    if(availableHarvest < 0){
        revert('No rewards available!');
    }
    currentUserStake._rewardClaimed += availableHarvest;
    currentPool._rewardClaimed += availableHarvest;
    IERC20(cr._address).transfer(sender,availableHarvest);
    currentUserStake._startTime = block.timestamp;
    //Emit harvest collected poolID,address,amount 
    emit Harvest(_poolID,sender,availableHarvest);
}


//admin actions
function createStakePool(
uint256 endDate, 
uint256 stakeFee, 
uint256 unStakeFee, 
address tokenStake,
uint256 tokenStakeDecimals,
uint256 tokenStakeLimitWholeNumber,
address tokenReward,
uint256 tokenRewardDecimals,
uint256 tokenRewardPoolAmount,
uint256 tokenRewardStakePercentage,
uint256 tokenRewardStakeRateInEpoch
)
external onlyAdmin {
    address sender = _msgSender();
    uint256 newStartTime = block.timestamp;
    uint256 transferAmount = tokenRewardPoolAmount * (10 ** tokenRewardDecimals);
    IERC20(tokenReward).transferFrom(sender,address(this),transferAmount);
    stakePoolFromPoolID[nextPoolID] = StakePool(
        nextPoolID,
        stakeFee,
        unStakeFee,
        coinToStake(tokenStake,tokenStakeDecimals,tokenStakeLimitWholeNumber),
        coinToReward(tokenReward,tokenRewardDecimals,tokenRewardPoolAmount,tokenRewardStakePercentage,tokenRewardStakeRateInEpoch),
        0,
        0,
        newStartTime,
        endDate
    );
    endDateFromPoolID[nextPoolID] = endDate;
    isActiveFromPoolID[nextPoolID] = true;

    emit NewStakePool(nextPoolID,tokenStake,tokenReward);
    nextPoolID++;

}

function endStakePool(uint256 _poolID) external onlyAdmin isPoolExist(_poolID) isPoolActive(_poolID){
    address sender = _msgSender();
    StakePool storage currentPool = stakePoolFromPoolID[_poolID];
    coinToStake storage cs = currentPool._coinToStake;
    coinToReward storage cr = currentPool._coinToReward;
    uint256 endDate = block.timestamp;
    currentPool._endDate = endDate;
    endDateFromPoolID[_poolID] = endDate;
    isActiveFromPoolID[_poolID] = false;
    uint256 rewardPaid = getRewardPaidPool(_poolID,endDate);
    uint256 availableBal = IERC20(cr._address).balanceOf(address(this));
    uint256 withdrawBal;
    if(cs._address == cr._address){
        withdrawBal = availableBal - currentPool._amountStaked - rewardPaid;
    }else{
        withdrawBal = availableBal - rewardPaid;
    }
    IERC20(cr._address).transfer(sender,withdrawBal);

    emit EndStakePool(_poolID,endDate);
}

function updateStakePoolFee(uint256 _poolID, uint256 stakeFee, uint256 unStakeFee) external onlyAdmin isPoolExist(_poolID) isPoolActive(_poolID){
    StakePool storage currentPool = stakePoolFromPoolID[_poolID];
    currentPool._stakeFee = stakeFee;
    currentPool._unStakeFee = unStakeFee;
    // emit fee updated poolID,stakeFee,unstakeFee
    emit UpdateStakeFees(_poolID,stakeFee,unStakeFee);
}

function updateFeeCollector(address _newAddress) external onlyAdmin {
    feeCollector = _newAddress;
}

}

