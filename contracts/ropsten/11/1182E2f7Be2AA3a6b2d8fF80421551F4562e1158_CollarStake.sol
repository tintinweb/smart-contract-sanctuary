/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract CollarStake is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    IERC20 public CollarToken;
    uint256 public stakeDays = 365;
    uint256 public stakeLimit;
    uint256 public totalStakedToken;
    uint256 public rewardDeposit;
    uint256 public coolDownTime = 10;
    uint256 public currentPool;

    struct UserInfo {
        address staker;
        uint256 poolID;
        uint256 stakeID;
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 unstakeTime;
        uint256 withdrawTime;
        uint256 stakingDays;
        uint256 APY_percentage;
        uint256 lastClaim;
        uint256 rewardEndTime;
        uint256 rewardAmount;
        bool claimed;
    }

    struct poolInfo {
        uint256 poolID;
        IERC20 stakeToken;
        uint256 APYpercentage;
        uint256 poolStakeID;
        uint256 totalStakedToken;
        bool UnActive;
    }
    
    struct userID{
        uint256[] stakeIDs;
    }

    mapping(uint256 => mapping(uint256 => UserInfo)) internal userDetails;
    mapping(address => mapping(uint256 => userID)) internal userIDs;
    mapping(uint256 => poolInfo) internal poolDetails;

    event emergencySafe(address indexed receiver, address tokenAddressss, uint256 TokenAmount);
    event CreatePool(address indexed creator,uint256 poolID, address stakeToken,uint256 APYPercentage);
    event stakeing(address indexed staker, uint256 stakeID, uint256 stakeAmount, uint256 stakeTime);
    event unstakeing(address indexed staker, uint256 stakeID, uint256 stakeAmount, uint256 UnstakeTime);
    event setAPYPercentage(address indexed owner,uint256 poolID, uint256 newPercentage);
    event setCollarToken(address indexed owner, address CollarToken);
    event setBUSDToken(address indexed owner, address BUSDToken);
    event withdrawTokens(address indexed staker, uint256 withdrawToken, uint256 withdrawTime);
    event RewardClaimed(address indexed staker,uint256 stakeID, uint256 rewardAmount, uint256 claimTime);
    event setMaxTokenStake(address indexed owner, uint256 maxStakeToken);
    event adminDeposits(address indexed owner, uint256 RewardDepositamount);
    event setCoolDownTime(address indexed owner, uint256 coolDownTime);
    event UpdatePoolStatus(address indexed owner,uint256 poolID,bool status);
     

    constructor ( uint256 _maxTokenStake, address _CollarAddress) {
        stakeLimit = _maxTokenStake;
        CollarToken = IERC20(_CollarAddress);
    }

    function viewUserDetails(uint256 _poolID, uint256 _stakeID) external view returns(UserInfo memory){
        return userDetails[_poolID][_stakeID];
    }

    function veiwPools(uint256 _poolID) external view returns(poolInfo memory){
        return poolDetails[_poolID];
    }

    function userStakeIDs(address _account, uint256 _poolID) external view returns(uint256[] memory stakeIDs){
        return userIDs[_account][_poolID].stakeIDs;
    }

    function updateMaxTokenStake(uint256 _maxTokenStake) external onlyOwner whenNotPaused {
        stakeLimit = _maxTokenStake;
        emit setMaxTokenStake(msg.sender, _maxTokenStake);
    }

    function updatePoolAPYpercentage(uint256 _poolID, uint256 _APYpercentage) external onlyOwner whenNotPaused {
        poolInfo storage pool = poolDetails[_poolID];
        pool.APYpercentage = _APYpercentage;

        emit setAPYPercentage(msg.sender, _poolID, _APYpercentage);
    }

    function updateCoolDownTime(uint256 _coolDownTime ) external onlyOwner whenNotPaused {
        coolDownTime = _coolDownTime;
        emit setCoolDownTime(msg.sender, _coolDownTime);
    }

    function updateCollarToken(address _CollarToken) external onlyOwner whenNotPaused {
        require(_CollarToken != address(0x0),"Collar is not a zero address");
        CollarToken = IERC20(_CollarToken);
        emit setCollarToken(msg.sender, _CollarToken);
    }

    function poolCreation(address _stakeToken, uint256 _APYPercentage) external onlyOwner whenNotPaused {
        currentPool++;
        poolInfo storage pool = poolDetails[currentPool];
        pool.stakeToken = IERC20(_stakeToken);
        pool.APYpercentage = _APYPercentage;
        pool.poolID = currentPool;

        emit CreatePool(msg.sender, currentPool, _stakeToken, _APYPercentage);
    }

    function poolStatus(uint256 poolID, bool status) external onlyOwner whenNotPaused {
        poolInfo storage pool = poolDetails[poolID];
        require(pool.poolID > 0,"Pool Not found");
        pool.UnActive  = status;

        emit UpdatePoolStatus(msg.sender, poolID, status);
    }

    function stake(uint256 _poolID,uint256 _tokenAmount, uint256 _stakeDays) external nonReentrant whenNotPaused {
        require( _tokenAmount > 0 && _tokenAmount < stakeLimit,"incorrect token amount");
        poolInfo storage pool = poolDetails[_poolID];
        require(!pool.UnActive,"pool is not active");
        pool.poolStakeID++;
        UserInfo storage user = userDetails[_poolID][pool.poolStakeID];
        user.staker = msg.sender;
        user.stakeID = pool.poolStakeID;
        user.poolID = _poolID;
        user.stakeAmount = _tokenAmount;
        user.stakeTime = block.timestamp;
        user.lastClaim = block.timestamp;
        user.rewardEndTime = (block.timestamp.add(_stakeDays.mul(86400)));
        user.APY_percentage = pool.APYpercentage;
        user.stakingDays = _stakeDays;
        pool.totalStakedToken = pool.totalStakedToken.add(_tokenAmount);
        userIDs[msg.sender][_poolID].stakeIDs.push(pool.poolStakeID);

        (pool.stakeToken).transferFrom(msg.sender, address(this), _tokenAmount);
        emit stakeing(msg.sender, pool.poolStakeID, _tokenAmount, block.timestamp);
    }

    function unstake(uint256 _poolID,uint256 _stakeID) external nonReentrant whenNotPaused {
        UserInfo storage user = userDetails[_poolID][_stakeID];
        require(user.stakeTime > 0 , "Invalid stake ID");
        require(user.rewardEndTime <= block.timestamp,"");
        require(user.unstakeTime == 0, "user already claim this ID");
        require(user.staker == msg.sender," invalid user ID");
        claimReward( _poolID,_stakeID);
        user.unstakeTime = block.timestamp;
       
        
        emit unstakeing(msg.sender, _stakeID, user.stakeAmount, block.timestamp);
    }

    function withdraw(uint256 _poolID,uint256 _stakeID) external {
        UserInfo storage user = userDetails[_poolID][_stakeID];
        poolInfo storage pool = poolDetails[_poolID];
        require(user.staker == msg.sender," invalid user ID");
        require(user.unstakeTime != 0,"User not unstake the tokens");
        require(user.unstakeTime.add(coolDownTime.mul(86400)) < block.timestamp, "Withdraw time not reached" );
        require(user.withdrawTime == 0, "This ID already withdrawed");
        user.withdrawTime = block.timestamp;
        user.claimed = true;
         pool.totalStakedToken = pool.totalStakedToken.sub(user.stakeAmount);
        (pool.stakeToken).transfer(msg.sender, user.stakeAmount);
       
        emit withdrawTokens(msg.sender, user.stakeAmount, user.withdrawTime);
    }

    function claimReward(uint256 _poolID,uint256 _stakeID) public {
        UserInfo storage user = userDetails[_poolID][_stakeID];
        require(user.staker == msg.sender," invalid user ID");
        uint256 rewardAmount = pendingReward(_poolID,_stakeID);
        if(block.timestamp > user.rewardEndTime){
            user.lastClaim = user.rewardEndTime;
        } else{   user.lastClaim = block.timestamp; }
        user.rewardAmount += rewardAmount;
        CollarToken.transfer(msg.sender, rewardAmount); 

        emit RewardClaimed(msg.sender,_stakeID, rewardAmount, user.lastClaim);
    }

    function pendingReward(uint256 _poolID, uint256 _stakeID) public view returns(uint256 Reward) {
        UserInfo storage user = userDetails[_poolID][_stakeID];
        require(user.unstakeTime == 0, "ID unstaked");
        uint256[3] memory localVar;
        if(user.lastClaim < user.rewardEndTime){
            localVar[2] = block.timestamp;
            if(block.timestamp > user.rewardEndTime){ localVar[2] = user.rewardEndTime; }
            
            localVar[0] = (localVar[2]).sub(user.lastClaim);
            localVar[1] = (user.APY_percentage).mul(1e16).div(stakeDays);
            Reward = user.stakeAmount.mul(localVar[0]).mul(localVar[1]).div(100).div(1e16).div(86400);
        } else {
            Reward = 0;
        }
    }

    function adminDeposit(uint256 _tokenAmount) external onlyOwner {
        rewardDeposit = rewardDeposit.add(_tokenAmount);
        CollarToken.transferFrom(msg.sender, address(this), _tokenAmount);

        emit adminDeposits(msg.sender, _tokenAmount);
    }

    function emergenecy(address token, address to, uint256 amount)external onlyOwner{
        if(token == address(0x0)){
            payable(to).transfer(amount);
        } else  {
            IERC20(token).transfer(to, amount);
        }
        emit emergencySafe(to, token, amount);
    }
}