// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './IERC20.sol';
import './safeMath.sol';
import './Ireceive.sol';
import './Irelation.sol';

contract Mine {
    using SafeMath for uint;
    
    struct userInfo {
        uint256 amount;
        uint256 share;
        uint256 award;
    }
    
    struct poolInfo {
        IERC20 IERC20Address;
        uint256 share;//邀请奖励
        uint256 weight;//高度
        uint256 lastBlock;//最后领取区块
        uint256 singleBlockreward;//块奖励
        uint256 totalReward;//已取出奖励
        uint256 totalAmounts;//总量
    }
    
    uint256 public decimal;
    uint256 public totalWeight;
    address public owner;
    IERC20 public gift;
    uint256 public singleBlockrewardInit;//块奖励配置量
    
    uint256 public startBlock;
    
    mapping( address => mapping(address => bool)) public userHistory;
    mapping(address => uint256) public userTotal;
    
    mapping(address => bool) public poolSwitch;

    address public Receive;
    address public Relation;
    
    // uint256 public blockNumber;
    
    
    mapping(address => mapping(address => userInfo)) public userList;
    mapping(address => poolInfo) public poolList;
    address[] poolArr;

    constructor (IERC20 _gift,uint256 _singleBlockrewardInit, uint256 _startBlock , uint256 _decimal) public {
        owner = msg.sender;
        // decimal = _decimal;
        decimal = 10 ** _decimal;
        gift = _gift;
        singleBlockrewardInit = _singleBlockrewardInit * decimal;
        startBlock = _startBlock;
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner,'who are you');
        _;
    }
    
    function getNowBlockHeight() view public returns(uint256) {
        return  block.number;
    }
    
    // function changeblockNumber(uint256 _blockNumber) public {
    //     blockNumber = _blockNumber;
    // }
    
    function setRelation(address _addr) public ownerOnly{
        Relation = _addr;
    }

    function setReceive(address _addr) public ownerOnly{
        Receive = _addr;
    }
    
    function changePoolSwitch(address _addr, bool _bool) public ownerOnly{
        poolSwitch[_addr] = _bool;
    }
    
    function adminGetgift() external ownerOnly{
        uint amounts = gift.balanceOf(address(this));
        gift.transfer(address(msg.sender),amounts);
    }
    
    function adminGetToken(IERC20 _IERC20) external ownerOnly{
        uint amounts = _IERC20.balanceOf(address(this));
        _IERC20.transfer(address(msg.sender),amounts);
    }
    
    function setPoolWeight (IERC20 _IERC20Address,uint256 _weight) external ownerOnly {
        poolInfo storage pool = poolList[address(_IERC20Address)];
        updataAllPool();
        totalWeight = totalWeight.sub(pool.weight).add(_weight);
        pool.weight = _weight;
    }

    function delPool(IERC20 _IERC20Address) external ownerOnly{
        require(poolList[address(_IERC20Address)].weight != 0,'no ');
        poolInfo storage pool = poolList[address(_IERC20Address)];
        updataAllPool();
        totalWeight = totalWeight.sub(pool.weight);
        pool.weight = 0;
        _IERC20Address.transfer(address(msg.sender),pool.totalAmounts);
        pool.totalAmounts = 0;
        delete poolList[address(_IERC20Address)];
        for(uint256 i = 0;i < poolArr.length; ++i){
            if(poolArr[i] == address(_IERC20Address)) {
                delete poolArr[i];
            }
        }
    }

    function add(IERC20 _IERC20Address,uint256 _weight) external ownerOnly {
        require(poolList[address(_IERC20Address)].weight == 0,'no again');
        poolList[address(_IERC20Address)] = poolInfo({
            IERC20Address : _IERC20Address,
            share:0,
            weight:_weight,
            lastBlock:  startBlock,
            singleBlockreward: singleBlockrewardInit,
            totalReward: 0,
            totalAmounts: 0
        });
        poolArr.push(address(_IERC20Address));
        updataAllPool();
        totalWeight = totalWeight.add(_weight);
    }
    
    function calcInterest(IERC20 _IERC20Address) public view returns(uint256){
            poolInfo storage pool = poolList[address(_IERC20Address)];
            userInfo storage user = userList[address(_IERC20Address)][msg.sender];
            uint256 balance = pool.totalAmounts;
            
            if(user.amount == 0){
                return user.award;
            }

            if( block.number < startBlock){
                return 0;
            }
            
            uint256 lastBlock = pool.lastBlock;
            uint256 singleBlockreward = pool.singleBlockreward;
            uint256 poolShare = pool.share;
            uint256 m;
            uint256 d;
            m = block.number.sub(lastBlock,'22222222222').mul(pool.weight).mul(singleBlockreward);
            d = balance.mul(totalWeight);
            require(d != 0,'none');
            poolShare = poolShare.add(decimal.mul(m).div(d));
            uint256 amounts = poolShare.sub(user.share).mul(user.amount).div(decimal).add(user.award);
            return amounts;
    }
    
    function deposit(IERC20 _IERC20Address,uint256 _amount,address _up) external {
        require(poolList[address(_IERC20Address)].weight != 0,'no');
        poolInfo storage pool = poolList[address(_IERC20Address)];
        userInfo storage user = userList[address(_IERC20Address)][msg.sender];

        Irelation(Relation).add(_up,msg.sender); 

        if(userHistory[address(_IERC20Address)][msg.sender] == false){
            userTotal[address(_IERC20Address)] = userTotal[address(_IERC20Address)].add(1);
            userHistory[address(_IERC20Address)][msg.sender] = true;
        }
        if(userList[address(_IERC20Address)][msg.sender].amount == 0){
            _Deposit(_IERC20Address,_amount);
        }else {
            uint256 amounts = calcInterest(_IERC20Address);
            user.award = amounts;
            updataPool(_IERC20Address); 
            _IERC20Address.transferFrom(address(msg.sender), address(this), _amount);
            pool.totalAmounts = pool.totalAmounts.add(_amount);
            user.share = pool.share;
            user.amount = user.amount.add(_amount);  
        }
    }
    
    function _Deposit(IERC20 _IERC20Address,uint256 _amount) internal {
        require(poolSwitch[address(_IERC20Address)],'close pool');
        poolInfo storage pool = poolList[address(_IERC20Address)];
        userInfo storage user = userList[address(_IERC20Address)][msg.sender];
        updataPool(_IERC20Address); 
        _IERC20Address.transferFrom(address(msg.sender), address(this), _amount);
        pool.totalAmounts = pool.totalAmounts.add(_amount);
        user.share = pool.share;
        user.amount = user.amount.add(_amount);
    }
    
    function updataAllPool() internal{
        for(uint256 i = 0;i < poolArr.length; ++i){
            updataPool(IERC20(poolArr[i]));
        }
    }
    
    function getAllpool() external view returns(address[] memory){
        return poolArr;
    }
    
    function updataPool(IERC20 _IERC20Address) internal{
        poolInfo storage pool = poolList[address(_IERC20Address)];
        uint256 balance = pool.totalAmounts;
        if(balance == 0 || totalWeight ==0){
            pool.share = 0;
            pool.lastBlock = block.number;
            return;
        }
        if(pool.lastBlock < startBlock) {
            pool.lastBlock = startBlock;
        }
        if(startBlock > block.number){
            pool.share = 0;
            return;
        }
        uint256 m;
        uint256 d;
        m = block.number.sub(pool.lastBlock,'22222222222').mul(pool.weight).mul(pool.singleBlockreward);
        d = balance.mul(totalWeight);

        pool.lastBlock = block.number;
        pool.share = pool.share.add(decimal.mul(m).div(d));
    }
    
    // 取出所有奖励
    function  settlementAll(IERC20 _IERC20Address) external {
        poolInfo storage pool = poolList[address(_IERC20Address)];
        userInfo storage user = userList[address(_IERC20Address)][msg.sender];
        pullAll(_IERC20Address);
        user.share = pool.share;
    }
    
    // 取出多少本金
    function getPrincipal(IERC20 _IERC20Address ,uint256 _amounts) external {
        poolInfo storage pool = poolList[address(_IERC20Address)];
        userInfo storage user = userList[address(_IERC20Address)][msg.sender];

        updataPool(_IERC20Address);
        uint256 amounts = calcInterest(_IERC20Address);
        user.award = amounts;
        require(user.amount >= _amounts,'Error not sufficient funds');
        user.amount = user.amount.sub(_amounts);
        user.share = pool.share;
        _IERC20Address.transfer(address(msg.sender),_amounts);
        pool.totalAmounts = pool.totalAmounts.sub(_amounts);
    } 
    
    function emergency(IERC20 _IERC20Address)external{
        poolInfo storage pool = poolList[address(_IERC20Address)];
        userInfo storage user = userList[address(_IERC20Address)][msg.sender];
        
        pool.totalAmounts = pool.totalAmounts.sub(user.amount);
        _IERC20Address.transfer(address(msg.sender),user.amount);
        pool.totalAmounts = pool.totalAmounts.sub(user.amount);
        updataPool(_IERC20Address);
        user.amount = 0;
        user.share = 0;
    }
    
    function pullAll(IERC20 _IERC20Address) internal{
        poolInfo storage pool = poolList[address(_IERC20Address)];
        userInfo storage user = userList[address(_IERC20Address)][msg.sender];
        updataPool(_IERC20Address);
        uint256 amounts;
        if(user.amount == 0){
             amounts = user.award;
        }else {
            //提取总量 = 奖池分享 - 用户分享 * 用户质押总量/小数位+用户奖励
             amounts = pool.share.sub(user.share,'1111111').mul(user.amount).div(decimal).add(user.award);
        }
        user.award = 0;

        pool.totalReward = pool.totalReward.add(amounts);
        // gift.transfer(address(msg.sender),amounts);
        Ireceive(Receive).add(msg.sender,amounts);
    }
    
}