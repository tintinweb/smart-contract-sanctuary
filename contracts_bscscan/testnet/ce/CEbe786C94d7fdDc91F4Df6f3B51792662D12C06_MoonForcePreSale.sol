/**
 *Submitted for verification at BscScan.com on 2021-12-09
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

contract MoonForcePreSale is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    
    uint256 public ownerFee = 10;

    struct PoolInfo {
        uint256 poolID;
        address poolCreator;
        uint256 startTime;
        uint256 endTime;
        IBEP20 rewardToken;
        uint256 perBNB;
        uint256 RewardAmount;
        uint256 depositAmount;
        bool active;
    }
    
    PoolInfo[] public poolInfo;

    event FailSafe(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenAmount );
    event CreatePool(address indexed poolCreator, PoolInfo indexed poolDetails);
    event DepositReward(address indexed poolAdmin, uint256 indexed depositAmount );
    event UpdatePool(uint256 indexed poolID,address poolCreator, uint256 indexed startTime, uint256 indexed endTime);
    event UpdateAdminFee(address indexed owner, uint256 indexed AdminFee);
    event ClaimToken(address indexed depositor, uint256 poolID, uint256 indexed BNBvalue, uint256 indexed tokenAmount);
    event CreatorClaim(address indexed creator, uint256 indexed poolID, uint256 indexed claimAmount);
    event WithdrawBalanceToken(uint256 poolID, IBEP20 indexed tokenAddress, address indexed poolCreator, uint256 indexed balanceAmount);
    
    constructor () {}
    
    receive()external payable {}
    
    function createPool(PoolInfo calldata _poolParams) external {
        uint256 poolid = poolInfo.length;
        poolInfo.push(PoolInfo({
            poolID: poolid,
            poolCreator: _poolParams.poolCreator,
            startTime: _poolParams.startTime,
            endTime: _poolParams.endTime,
            rewardToken: _poolParams.rewardToken,
            perBNB: _poolParams.perBNB,
            RewardAmount: _poolParams.RewardAmount,
            depositAmount: _poolParams.depositAmount,
            active: _poolParams.active
        }));
        
        _poolParams.rewardToken.transferFrom(msg.sender,address(this),_poolParams.RewardAmount);
        
        emit CreatePool(msg.sender, _poolParams);
        emit DepositReward(msg.sender, _poolParams.RewardAmount);
    }
    
    function updatePool(uint256 _poolID,uint256 startingTime, uint256 endingTime) external {
        PoolInfo storage pool = poolInfo[_poolID];
        require(pool.poolCreator == msg.sender,"caller is a not a pool creator" );
        pool.startTime = startingTime;
        pool.endTime = endingTime;
        emit UpdatePool(_poolID, msg.sender, startingTime, endingTime);
    }
    
    function updateAdminFee(uint256 _fee) external onlyOwner {
        ownerFee = _fee;
        emit UpdateAdminFee(msg.sender, _fee);
    }
    
    function claimTokens(uint256 _poolID)external payable nonReentrant {
        PoolInfo storage pool = poolInfo[_poolID];
        require (pool.startTime <= block.timestamp && pool.endTime >= block.timestamp,"Deposit time" );
        require (pool.active,"Pool not active");
        
        pool.depositAmount = pool.depositAmount.add(msg.value);
        uint256 perBNBToken = (pool.perBNB.mul(1e6).div(1e18));
        uint256 tokenAmount = (perBNBToken.mul(msg.value).div(1e6));
        pool.RewardAmount = pool.RewardAmount.sub(tokenAmount,"Pool reward amount exceed");
        pool.rewardToken.transfer(msg.sender, tokenAmount);
        emit ClaimToken(msg.sender, _poolID, msg.value, tokenAmount);
    }
    
    function withdrawBalance(uint256 _poolID) external {
        PoolInfo storage pool = poolInfo[_poolID];
        require (pool.endTime <= block.timestamp,"Deposit time" );
        require (pool.poolCreator == msg.sender,"Caller is not a pool Admin");
        uint256 balance = pool.rewardToken.balanceOf(address(this));
        pool.rewardToken.transfer(msg.sender, balance);
        
        emit WithdrawBalanceToken(_poolID, pool.rewardToken, msg.sender, balance);
    }
    
    function poolLength() external view returns(uint256){
        return poolInfo.length;
    }
    
    function creatorClaim(uint256 _poolID) external nonReentrant{
        PoolInfo storage pool = poolInfo[_poolID];
        require(pool.endTime <= block.timestamp,"pool time not end");
        require(pool.poolCreator == msg.sender,"caller is not a pool creator");
        require(pool.active,"Pool already claimed");
        pool.active = false;
        uint256 Fee = pool.depositAmount.mul(ownerFee).div(1000);
        require(payable(owner()).send(Fee),"Admin Fee Transaction Failed");
        require(payable(msg.sender).send(pool.depositAmount.sub(Fee)),"Pool Creator Transaction Failed");
        
        emit CreatorClaim(msg.sender, _poolID, pool.depositAmount);
    }
    
    function failSafe(address token, address to, uint256 amount)external onlyOwner{
        if(token == address(0x0)){
            payable(to).transfer(amount);
        } else  {
            IBEP20(token).transfer(to, amount);
        }
        emit FailSafe(to, token, amount);
    }
}