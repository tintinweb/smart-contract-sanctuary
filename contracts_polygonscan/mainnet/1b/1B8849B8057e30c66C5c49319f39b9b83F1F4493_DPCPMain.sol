/**
 *Submitted for verification at polygonscan.com on 2021-10-26
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-08-10
*/

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

interface ICore{
    // 是否超卖
    function isOverSold() external view returns(bool);
    // 是否可提取奖励
    function ifGetReward() external view returns(bool);
    // 获取产生的总奖励
    function getTotalReward() external view returns(uint256);
}
interface  IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    // dpcp铸币
    function mint(address to,uint256 amount) external;
    
}
interface IERC721{
    function mintDnft(address _to) external returns(uint256);
    function totalSupply() external view returns (uint256);
}

contract DPCPMain {
    using SafeMath for uint256;

    event DepositeToken(address indexed ethAddress, uint256 pool, uint256 orderId, uint256 value);
    event TakeBackToken(address indexed ethAddress, uint256 pool, uint256 orderId, uint256 value);
    event CastingToken(address indexed ethAddress, uint256 pool, uint256 orderId, uint256 amount);
    event CastingInvietToken(address indexed ethAddress, uint256 pool, uint256 orderId, uint256 amount);
    event UseInviteCode(address ethAddress, address parentAddress);
    event ReceiveRescuerToken(address indexed ethAddress, uint256 amount);
    event TransferOrder(address fromAddr, address toAddr, uint256 orderId);

    struct PoolModel{
        uint256 weight;             //权重,实际铸币系数=基础铸币系数*权重*(目标比例 / 实际比例)
        uint256 expectedRate;       //期待铸币占比 例:50% 转为 50
        uint256 tokenPool;          //池子token数
        uint256 totalToken;         //历史所有质押数
        uint256 totalCasted;        //已铸造token数
        uint256 totalPledged;       //所有订单数
        uint256 pledgeCount;        //质押中的订单数
    }
    struct Pledge {
        uint32 pool;
        uint256 investAmount;   // 质押数量
        uint256 dayEarnings;    // 每日收益
        uint256 rate;           // 收益比例
        uint256 vipRate;        // 会员收益率
        uint256 createTime;     // 质押时间
        uint256 receivedDay;    // 已经领取收益的天数
        uint256 inviteReceivedDay; // 已领取邀请收益的天数
        uint256 endTime;            // 是否结束, 0=未结束, 其他=结束时间戳
        uint256 inviteYieldRate;    // 邀请收益率
        uint256 left;               //最佳质押量最小值
        uint256 right;              //最佳质押量最大值
    }

    mapping(uint32 => PoolModel) POOL_MAP;
    uint256 public vipRate;
    address public token;
    uint8 tokenDecimals;                                  // token 精度
    mapping(bytes4 => address) public inviteCodeMap;           // 用户邀请码 => 用户地址
    mapping(address => bytes4) public superiorMap;         // 用户地址 => 用户邀请人的邀请码
    mapping(address => address[]) public addressToInvitee;  // 用户地址 => 被邀请人列表
    mapping(address => uint256[]) private userToOrder;
    mapping(uint256 => Pledge) public orderMap;     //订单map
    mapping(address => uint256[]) public userToInviteOrder; //用户邀请订单
    mapping(address => uint256) public userToRescuer; //拯救者算力
    uint256 public rescuePool; //拯救者算力池 
    bool public supportRescuer; //是否支持拯救者
    uint256 public leastRate; //最少质押比例(占最佳铸币量百分比)
    uint256 public mintRescuerToken; //铸造拯救者奖励数
    uint256 public bestLeft; //最佳质押数量左区间, %
    uint256 public bestRight; //最佳质押数量右区间, %
    mapping(uint256 => uint256) public orderBestAmount; 
    
    address public NFTToken;
    uint256 timeMod;
    address public owner;                   //管理员
    address private coreAddr;

    constructor(address tokenAddr, address nftAddr){
        PoolModel memory pool7 = PoolModel(1, 25, 500*10**18,500*10**18, 50*10**18, 1, 1);
        PoolModel memory pool30 = PoolModel(2, 25, 500*10**18,500*10**18, 20*10**18, 1, 1);
        PoolModel memory pool90 = PoolModel(3, 25, 500*10**18,500*10**18, 20*10**18, 1, 1);
        PoolModel memory pool180 = PoolModel(4, 25, 500*10**18,500*10**18, 10*10**18, 1, 1);
        POOL_MAP[7] = pool7;
        POOL_MAP[30] = pool30;
        POOL_MAP[90] = pool90;
        POOL_MAP[180] = pool180;
        vipRate = 110;
        token = tokenAddr;
        tokenDecimals = 18;
        owner = msg.sender;
        NFTToken = nftAddr;
        supportRescuer = false;
        timeMod = 60;
        bestRight = 100;
        bestLeft = 50;
    }

    //用户进行质押铸币
    function depositToken(uint32 _poolName, uint256  _amount) external {
        require(_amount >= bestAmount(_poolName).mul(leastRate).div(100), "The token of too little!");
        IERC20 ercToken = IERC20(token);
        IERC721 nft = IERC721(NFTToken);
        ICore core = ICore(coreAddr);
        uint256 nftId = nft.mintDnft(msg.sender);
        require(ercToken.balanceOf(msg.sender) >=  _amount, "Not sufficient funds");
        uint256 dayEarnings = getDayCast(_poolName, _amount);
        uint256 userRate = 100;
        if(superiorMap[msg.sender] != 0x00000000){
            dayEarnings = dayEarnings.mul(vipRate).div(100);
            userRate = vipRate;
            address orderInviter = inviteCodeMap[superiorMap[msg.sender]];
            userToInviteOrder[orderInviter].push(nftId);
        }
        uint256 best = bestAmount(_poolName);
        orderMap[nftId] = Pledge(
            _poolName,
            _amount,
            dayEarnings,
            getCastCoef(_poolName),
            userRate,
            block.timestamp,
            0,
            0,
            0,
            getInviteRate(),
            best.sub(best.mul(bestLeft).div(10**2)),
            best.add(best.mul(bestRight).div(10**2))
        );
        
        orderBestAmount[nftId] = bestAmount(_poolName);
        
        //如果没有邀请码,则生成
        if (inviteCodeMap[_randomBytes4(msg.sender)] == 0x0000000000000000000000000000000000000000){
            inviteCodeMap[_randomBytes4(msg.sender)] = msg.sender;
        }
        //token转账
        ercToken.transferFrom(msg.sender, address(this),  _amount);
        userToOrder[msg.sender].push(nftId);
        POOL_MAP[_poolName].tokenPool = POOL_MAP[_poolName].tokenPool.add( _amount);
        POOL_MAP[_poolName].totalToken = POOL_MAP[_poolName].totalToken.add( _amount);
        POOL_MAP[_poolName].totalPledged = POOL_MAP[_poolName].totalPledged.add(1);
        POOL_MAP[_poolName].pledgeCount = POOL_MAP[_poolName].pledgeCount.add(1);
        POOL_MAP[_poolName].totalCasted = POOL_MAP[_poolName].totalCasted.add(dayEarnings.mul(_poolName));
        if(supportRescuer){
            //拯救者算力
            if (core.isOverSold()){
                rescuePool = rescuePool.add(_amount);
                userToRescuer[msg.sender] = userToRescuer[msg.sender].add(_amount.mul(_poolName));
            }
        }
        emit DepositeToken(msg.sender, _poolName, nftId,  _amount);
    }

    //用户领取铸币收益 poolName:订单的天数类型, orderIds:订单号
    function receiveToken(uint256[] memory _orderIds, bool _isReceiveInvite) public{
        if(_orderIds.length != 0){
            IERC20 ercToken = IERC20(token);
            for(uint32 i = 0; i < _orderIds.length; i++){
                uint256 orderId = _orderIds[i];
                uint32 poolName = orderMap[orderId].pool;
                require(_checkOrderExist(msg.sender, orderId), "Order is not exist");
                uint256 inTime = block.timestamp.sub(orderMap[orderId].createTime);
                if(inTime >= timeMod.mul(poolName) && orderMap[orderId].endTime == 0){
                    ercToken.transfer(msg.sender, orderMap[orderId].investAmount);
                    POOL_MAP[poolName].tokenPool = POOL_MAP[poolName].tokenPool.sub(orderMap[orderId].investAmount);
                    POOL_MAP[poolName].pledgeCount = POOL_MAP[poolName].pledgeCount.sub(1);
                    orderMap[orderId].endTime = block.timestamp;
                    //如果用没领取铸币奖励，则一并领取
                    uint256 canCast= _updateAndStatisticsCast(orderId);
                    if(canCast != 0){
                        ercToken.mint(msg.sender, canCast);
                        emit CastingToken(msg.sender, poolName, orderId, canCast);
                    }
                    emit TakeBackToken(msg.sender, poolName, orderId, orderMap[orderId].investAmount);
                }else if(inTime < timeMod.mul(poolName) && orderMap[orderId].endTime == 0){
                    uint256 receiveAmount;
                    uint256 amount = _updateAndStatisticsCast(_orderIds[i]);
                    receiveAmount = receiveAmount.add(amount);
                    uint32 pool = orderMap[_orderIds[i]].pool;
                    emit CastingToken(msg.sender, pool, _orderIds[i], amount);
                      
                    //邀请收益
                    if(_isReceiveInvite){
                        receiveAmount = receiveAmount.add(_receiveInviteToken());
                    }
                    //转账
                    if (receiveAmount > 0){
                        ercToken.mint(msg.sender, receiveAmount);
                    }
                }
            }
        }
    }

    
    //用户领取拯救者奖励
    function receiveRescuerToken()external{
        ICore core = ICore(coreAddr);
        IERC20 ercToken = IERC20(token);
        require(userToRescuer[msg.sender] != 0, "Yuor rescuer counts power is zero");
        require(core.ifGetReward(), "Can't pick it up now!");
        uint256 total = core.getTotalReward();
        uint256 rate = (userToRescuer[msg.sender].mul(10 ** 6)).div(rescuePool);
        uint256 amount = rate.mul(total).div(10 ** 6);
        mintRescuerToken = mintRescuerToken.add(amount);
        ercToken.mint(msg.sender, amount);
        
        userToRescuer[msg.sender] = 0;
        
        emit ReceiveRescuerToken(msg.sender, amount);
    }
    
    //订单转移
    function transferOrder(address _from, address _to, uint256 _orderId)external{
        require(msg.sender == NFTToken, "Only NFT Contract");
        require(_checkOrderExist(_from, _orderId), "order is not exist");
        uint256[] memory orderIds = userToOrder[_from];
        for(uint256 i = 0; i < orderIds.length; i++){
            if (orderIds[i] == _orderId){
                userToOrder[_from] = _removeAtIndex(orderIds, i);
            }
        }
        userToOrder[_to].push(_orderId);
        emit TransferOrder(_from, _to, _orderId);
    }
    
    function _removeAtIndex(uint256[] memory  _array, uint256 _index)internal pure returns(uint256[] memory) {
        require(_index <= _array.length, "Index Out of Bounds");
        uint256[] memory newArray = new uint256[](_array.length-1);
        for (uint i = _index; i<_array.length-1; i++){
            _array[i] = _array[i+1];
        }
        for(uint256 i = 0; i < _array.length-1; i++){
            newArray[i] = _array[i];
        }
        return newArray;
    }
    
    
    //获取订单可领邀请奖励
    function _statisticsInviteAmount(uint256 _orderId) public view returns(uint256, uint256){
        uint256 validDay;
        uint256 elapsedDay = block.timestamp.sub(orderMap[_orderId].createTime).div(timeMod);
        if(elapsedDay > orderMap[_orderId].pool){
            validDay = orderMap[_orderId].pool;
        }else{
            validDay = elapsedDay;
        }
        uint256 amount = orderMap[_orderId].dayEarnings.mul(validDay.sub(orderMap[_orderId].inviteReceivedDay)).mul(orderMap[_orderId].inviteYieldRate).div(10**3);
        return (amount, validDay);
    }
    
    //获取订单可领铸币奖励(质押收益)
    function _statisticsCastAmount(uint256 _orderId) public view returns(uint256, uint256){
        uint256 validDay;
        uint256 elapsedDay = block.timestamp.sub(orderMap[_orderId].createTime).div(timeMod);
        if(elapsedDay > orderMap[_orderId].pool){
            validDay = orderMap[_orderId].pool;
        }else{
            validDay = elapsedDay;
        }
        uint256 amount = orderMap[_orderId].dayEarnings.mul(validDay.sub(orderMap[_orderId].receivedDay));
        return (amount, validDay);
    }
    function _updateAndStatisticsCast(uint256 _orderId)internal returns(uint256){
        (uint256 amount, uint256 validDay) = _statisticsCastAmount(_orderId);
        orderMap[_orderId].receivedDay = validDay;
        return amount;
    }
    
    //更新用户所有邀请奖励
    function _receiveInviteToken()internal returns(uint256){
        uint256 inviteAmount;
        uint256[] memory orders = userToInviteOrder[msg.sender];
        if(orders.length != 0){
            for(uint32 j = 0; j < orders.length; j++){
                    //判断是否是vip订单
                    if(orderMap[orders[j]].vipRate > 100){
                    (uint256 amount, uint256 validDay) = _statisticsInviteAmount(orders[j]);
                    orderMap[orders[j]].inviteReceivedDay = validDay;
                    inviteAmount = inviteAmount.add(amount);
                    emit CastingInvietToken(msg.sender, orderMap[orders[j]].pool, orders[j], amount);
                }
            }
        }
        return inviteAmount;
    }

    //获取用户的下级列表
    function getUserInvitees(address _addr)external view returns(address[] memory addrs){
        return addressToInvitee[_addr];
    }
    
    //查询邀请人地址
    function getInviter(address _addr)external view returns (address){
        return inviteCodeMap[superiorMap[_addr]];
    }

    //获取最佳质押数量, 返回0时,质押多少则显示多少
    function getBestAmount() external view returns(uint256, uint256, uint256, uint256){     
        return (bestAmount(7), bestAmount(30), bestAmount(90), bestAmount(180));
    }

    //获取池子详细
    function getPoolMod(uint32 _poolName) external view returns(PoolModel memory mod){
        return POOL_MAP[_poolName];
    }

    //获取每日收益
    function getDayCast(uint32 _poolName, uint256 _tokenAmount)public view returns(uint256){
        uint256 b = getCastCoef(_poolName); 
        PoolModel memory pool = POOL_MAP[_poolName];
        uint256 a = pool.totalToken.div(pool.totalPledged);
        uint256 right = a.add(a.mul(bestRight).div(100));
        uint256 left = a.sub(a.mul(bestLeft).div(100));
        uint256 rate = 0;
        //乘 10**10, 相当于保留10位小数(b原本已经乘 10**10)
        // a * b
        uint256 f1 = a.mul(b);
        if(_tokenAmount < left){
            //((n * a) + a) - x
            uint256 f2 = (a.mul(bestLeft).div(100)).add(a).sub(_tokenAmount);
            rate = f1.div(f2);
        }else if(_tokenAmount > right){
            // x - a * m
            uint256 f2 = _tokenAmount.sub(a.mul(bestRight).div(100));
            rate = f1.div(f2);
        }else if(left <= _tokenAmount && _tokenAmount <= right){
            rate = b;
        }
        //乘以日利率后还原小数位
        return _tokenAmount.mul(rate).div(10 ** 10);
    }

    //获取铸币系数
    function getCastCoef(uint32 _poolName) public view returns (uint256){
        //获取总质押数量
        uint256 allCasted = POOL_MAP[7].tokenPool.add( POOL_MAP[30].tokenPool).add( POOL_MAP[90].tokenPool).add( POOL_MAP[180].tokenPool);
        uint256 initCoef = getInitCoef();
        //实际质押比例
        uint256 actualRate = POOL_MAP[_poolName].tokenPool.mul(10**6).div(allCasted);
        //最终铸币系数, 共10位小数 基础 X 权重 X （目标比例 / 实际比例）
        return initCoef.mul(POOL_MAP[_poolName].weight).mul(POOL_MAP[_poolName].expectedRate.mul(10**14).div(actualRate)).div(10**8);
    }

    //获取用户所有邀请奖励
    function getInviteToken(address _addr)public view returns(uint256){
        uint256 inviteAmount;
        address[] memory addrs = addressToInvitee[_addr];
        for(uint32 i = 0; i < addrs.length; i++){
             for(uint32 j = 0; j < userToOrder[addrs[i]].length; j++){
                 (uint256 amount, ) = _statisticsInviteAmount(userToOrder[addrs[i]][j]);
                 inviteAmount = inviteAmount.add(amount);
             }
        }
        return inviteAmount;
    }
    
    //获取地址所有未领取资产
    function getAddressAsset(address _addr) external view returns(uint256){
        uint256[] memory orderIds = userToOrder[_addr];
        uint256 totalAsset;
        for(uint32 i = 0; i < orderIds.length; i++){
            if(orderMap[orderIds[i]].createTime.add(uint256(orderMap[orderIds[i]].pool).mul(timeMod)) >= block.timestamp) {
                totalAsset = totalAsset.add(orderMap[orderIds[i]].investAmount);
            }
        }
        uint256[] memory inviteOrderIds = userToInviteOrder[_addr];
        for(uint32 i = 0; i < inviteOrderIds.length; i++){
            (uint256 amount, ) = _statisticsInviteAmount(inviteOrderIds[i]);
            totalAsset = totalAsset.add(amount);
        }
        return totalAsset;
    }
    
    //根据池子和订单id获取订单详情
    function getOrderById(address _addr, uint256 _orderId) external view returns(Pledge memory order){
        bool isOrder = _checkOrderExist(_addr, _orderId);
        require(isOrder, "order is not exist");
        return orderMap[_orderId];
    }

    //使用邀请码
    function useInviteCode(bytes4 _code)public {
        require(_code != _randomBytes4(msg.sender));
        require(superiorMap[msg.sender] == 0x00000000, "You have already used the invitation code");
        superiorMap[msg.sender] = _code;
        addressToInvitee[inviteCodeMap[_code]].push(msg.sender);
        emit UseInviteCode(msg.sender, inviteCodeMap[_code]);
    }

    //获取最佳质押数量
    function bestAmount(uint32 _poolName) public view returns(uint256){
        if (POOL_MAP[_poolName].totalPledged == 0){
            return 0;
        }
        uint256 amount = POOL_MAP[_poolName].totalToken.div(POOL_MAP[_poolName].totalPledged);
        return amount;
    }
    
    function getOrderIds(address _addr) external view returns(uint256[] memory orderIds){
        return userToOrder[_addr];
    }
    
    //以数组方式返回订单详情
    function orderValues(uint256 _orderId) external view returns(uint256[] memory){
        uint256[] memory value = new uint256[](12);
        Pledge memory p = orderMap[_orderId];
        value[0] = uint256(p.pool);
        value[1] = p.investAmount;
        value[2] = p.dayEarnings;
        value[3] = p.rate;
        value[4] = p.vipRate;
        value[5] = p.createTime;
        value[6] = p.receivedDay;
        value[7] = p.inviteReceivedDay;
        value[8] = p.endTime;
        value[9] = p.inviteYieldRate;
        value[10] = p.left;
        value[11] = p.right;
        return value;
    }
    
    //获取用户可领取拯救者奖励数
    function getCanReceiveRescuerToken(address _addr)external view returns(uint256){
        ICore core = ICore(coreAddr);
        if (userToRescuer[_addr] == 0 || !core.ifGetReward()){
            return 0;
        }
        uint256 rate = (userToRescuer[_addr].mul(10 ** 6)).div(rescuePool);
        return rate.mul(core.getTotalReward()).div(10 ** 6);
    }
    
    //用户获取邀请码
    function getInviteCode(address _addr)public view returns(bytes4){
        if (inviteCodeMap[_randomBytes4(_addr)] == 0x0000000000000000000000000000000000000000){
            return 0x00000000;
        }
        return _randomBytes4(_addr);
    }
    //生成邀请码
    function _randomBytes4(address _addr) internal pure returns(bytes4){
        return bytes4(keccak256(abi.encodePacked(_addr)));
    }

    function _toWei(uint256 _amount)internal view returns(uint256){
        return _amount * 10 ** tokenDecimals;
    }
    
    //判断订单是否存在
    function _checkOrderExist(address _addr, uint256 _orderId) internal view returns(bool){
        uint256[] memory orderIds = userToOrder[_addr];
        for(uint256 i = 0; i < orderIds.length; i++){
            if (orderIds[i] == _orderId){
                return true;
            }
        }
        return false;
    }
    
    function orderIdsArr(address _addr)external view returns(uint256[] memory){
        return userToOrder[_addr];
    }
    
    function getInviteRate() public view returns(uint256){
        IERC20 ercToken = IERC20(token);
        //初始发行量
        return uint256(_toWei(2000000).mul(10**4)).div(_toWei(2000000).add(ercToken.totalSupply()).sub(_toWei(1000000)));
    }
    
    function getInitCoef()public view returns(uint256){
        IERC20 ercToken = IERC20(token);
        //基础铸币系数, 8位小数   10000/2000000+X, x = 发行量
        return uint256(_toWei(10000) * 10**8).div(uint256(_toWei(2000000)).add(ercToken.totalSupply()));
    }
    
    //设置期望铸币比例, 100 = 100%.
    function setExpectedRate(uint32 _poolName, uint256 _newRate)public onlyOwner{
        POOL_MAP[_poolName].expectedRate = _newRate;
    }
    
    //配置质押参数
    function configPledge(uint256 _newLeastRate, uint256 _newBestLeft, uint256 _newBestRight, bool _isOpenRescuer)external onlyOwner{
        //最少质押比例, 基于最佳质押数
        leastRate = _newLeastRate;
        //最佳质押数左区间
        bestLeft = _newBestLeft;
        //最佳质押数右区间
        bestRight = _newBestRight;
        //切换拯救者算力开关
        supportRescuer = _isOpenRescuer;
    }
    
    function setOwner(address _newOwner)external onlyOwner{
        owner = _newOwner;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "caller is not owner");
        _;
    }
}