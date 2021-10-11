/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-08
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

interface IBEP20 {
    
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

contract TestStake is Ownable{
    using SafeMath for uint256;
    
    IBEP20 public EazyRaizeToken;
    uint256 currentPool;
    uint256 public RewardAmount;
    uint256 public lockDays;
    
    struct UserDetails{
        address user;
        uint256 stakeID;
        uint256 stakeAmount;
        uint256 stakeTime;
        bool claim;
    }
    
    struct PoolDetails{
        IBEP20 stakeToken;
        uint256 currentID;
        uint256 APYpercent;
    }
    
    struct _StakeingId{
        uint256[] stakingId;
    }
    
    mapping(address => mapping(uint256 => _StakeingId)) stakings;
    mapping(uint256 => mapping(uint256 => UserDetails)) public userInfo;
    mapping(uint256 => PoolDetails) public poolInfo;
    
    event Staking(address staker, uint256 stakeAmount, uint256 stakeTime, uint256 poolID, uint256 stakeID);
    event Unsatking(address staker, uint256 reward, uint256 stakeAmount);
    event AdminDeposit(address owner, uint256 depositAmount);
    event EmergencySafe(address owner,address receiver, address tokenAddress, uint256 tokenAmount);
    event UpdateLockDays(address owner,uint256 lockDays);

    constructor(address _EazyToken, uint256 _lockDays ){
        EazyRaizeToken = IBEP20(_EazyToken);
        lockDays = _lockDays;
    }

    function updateLockDays(uint256 _lockdays) external onlyOwner{
        lockDays = _lockdays;
        emit UpdateLockDays(msg.sender, _lockdays);
    }
    
    function addStakingPool(address _stakeToken, uint256 _APYpercentage)external onlyOwner {
        currentPool++;
        PoolDetails storage pool = poolInfo[currentPool];
        pool.stakeToken = IBEP20(_stakeToken);
        pool.APYpercent = _APYpercentage;
    }
    
    function stakeTokens(uint256 _poolID,uint256 _tokenAmount)public returns(bool){
        PoolDetails storage pool = poolInfo[_poolID];
        require(_tokenAmount > 0,"Stake:: Invalid token amount");
        require(address(pool.stakeToken) != address(0),"Stake :: pool not found");
        
        pool.currentID++;
        UserDetails storage user = userInfo[_poolID][pool.currentID];
        user.stakeID = pool.currentID;
        user.stakeAmount = _tokenAmount;
        user.stakeTime = block.timestamp;
        user.user = msg.sender;
        stakings[msg.sender][_poolID].stakingId.push(pool.currentID);
        pool.stakeToken.transferFrom(msg.sender, address(this), _tokenAmount);
        
        emit Staking(msg.sender, _tokenAmount, block.timestamp, _poolID, pool.currentID);
        
        return true;
    }
    
    function unSatkeTokens(uint256 _stakeID, uint256 _poolID) external returns(bool){
        UserDetails storage user = userInfo[_poolID][_stakeID];
        require(user.user == msg.sender, "unStake :: caller is not the owner of the StakeID");
        require(!user.claim,"unStake :: ID already unstaked");
        require(user.stakeTime.add(lockDays.mul(86400)) <= block.timestamp,"unStake :: unstake time not reached");
        
        uint256 reward = calculateReward(_stakeID, _poolID);
        user.claim = true;
        RewardAmount = RewardAmount.sub(reward,"reward amount exceed");
        EazyRaizeToken.transfer(msg.sender, reward);
        poolInfo[_poolID].stakeToken.transfer(msg.sender, user.stakeAmount);
        
        emit Unsatking(msg.sender, reward, user.stakeAmount);
        user.stakeAmount = 0;
        return true;
    }
    
    function calculateReward(uint256 _stakeID, uint256 _poolID)public view returns(uint256 reward){
        UserDetails storage user = userInfo[_poolID][_stakeID];
        PoolDetails storage pool = poolInfo[_poolID];
        if((block.timestamp.sub(user.stakeTime)).div(86400) >= 365 ){
            return reward = user.stakeAmount.mul(pool.APYpercent).div(100);
        }
        uint256 percentage = (pool.APYpercent).mul(1e18).div(365);
        uint256 stakeDays = block.timestamp.sub(user.stakeTime);
        reward = user.stakeAmount.mul(percentage).mul(stakeDays).div(100e18).div(86400);
    }
    
    function adminDeposit(uint256 _tokenAmount)external onlyOwner{
        RewardAmount = RewardAmount.add(_tokenAmount);
        EazyRaizeToken.transferFrom(msg.sender, address(this), _tokenAmount);
        
        emit AdminDeposit(msg.sender, _tokenAmount);
    }
    
    function emergencySafe(address _token,address _to, uint256 _amount)external onlyOwner{
        if(_token != address(0)){
            IBEP20(_token).transfer( _to, _amount);
        }else {
            require(payable(_to).send(_amount),"Safe :: transaction Failed");
        }
        emit EmergencySafe(msg.sender, _to, _token, _amount);
    }
}