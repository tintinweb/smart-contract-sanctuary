/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^ 0.8.3;

abstract contract ERC20{
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool success);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {return counter._value;}

    function increment(Counter storage counter) internal {unchecked {counter._value += 1;}}

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {counter._value = value - 1;}
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

library SafeMath {
    /* 加 : a + b */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /* 减 : a - b */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    /* 减 : a - b */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    /* 乘 : a * b */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /* 除 : a / b */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    /* 除 : a / b */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    /* 除 : a / b */
    function divFloat(uint256 a, uint256 b,uint decimals) internal pure returns (uint256){
        require(b > 0, "SafeMath: division by zero");
        uint256 aPlus = a * (10 ** uint256(decimals));
        uint256 c = aPlus/b;
        return c;
    }
    /* 末 : a % b */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    /* 末 : a % b */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    /*
     * @dev 转换位
     * @param amout 金额
     * @param decimals 代币的精度
     */
    function toWei(uint256 amout, uint decimals) internal pure returns (uint256){
        return mul(amout,10 ** uint256(decimals));
    }

    /*
     * @dev 回退位
     * @param amout 金额
     * @param decimals 代币的精度
     */
    function backWei(uint256 amout, uint decimals) internal pure returns (uint256){
        return div(amout,(10 ** uint256(decimals)));
    }
}

contract Comn {
    address internal owner;                                //合约创建者
    address internal approveAddress;                       //授权地址
    bool internal running = true;                          //true:开启(默认); false:关闭;
    mapping(address => bool) takeLpPairFrozenMapping;      //<地址,是否冻结> (提取LP冻结)
    mapping(address => bool) takeProfitFrozenMapping;      //<地址,是否冻结> (提取收益冻结)

    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"Modifier: The caller is not the creator");
        _;
    }
    modifier onlyApprove(){
        require(msg.sender == approveAddress || msg.sender == owner,"Modifier: The caller is not the approveAddress or creator");
        _;
    }
    modifier isRunning {
        require(running,"Modifier: System maintenance in progress");
        _;
    }
    modifier nonReentrant() {//防重入攻击
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    modifier isFrozenTakeLp(){//冻结提取LP
        require(takeLpPairFrozenMapping[msg.sender] == false,"Modifier: The caller is frozen");
        _;
    }
    modifier isFrozenTakeProfit(){//冻结提取收益
        require(takeProfitFrozenMapping[msg.sender] == false,"Modifier: The caller is frozen");
        _;
    }
    constructor() {
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }
    /*
     * @dev 设置授权的地址
     * @param externalAddress 外部地址
     */
    function setApproveAddress(address externalAddress) public onlyOwner returns (bool) {
        approveAddress = externalAddress;
        return true;
    }
    /*
     * @dev 设置合约运行状态
     * @param state true:开启; false:关闭;
     */
    function setRunning (bool state) public onlyOwner returns (bool) {
        running = state;
        return true;
    }
    /* 获取授权的地址 */
    function getApproveAddress() internal view returns(address){
        return approveAddress;
    }
    /* 获取合约运行的状态 */
    function getRunning() internal view returns(bool){
        return running;
    }
    /* 设置(冻结/解冻)提取LP地址 */
    function setFrozenTakeLp(address _address,bool isFrozen) public onlyOwner {
        takeLpPairFrozenMapping[_address] = isFrozen;
    }
    /* 设置(冻结/解冻)提取收益地址 */
    function setFrozenTakeProfit(address _address,bool isFrozen) public onlyOwner {
        takeProfitFrozenMapping[_address] = isFrozen;
    }
    
    //当一个合约需要进行以太交易时，需要加两个函数
    fallback () payable external {}
    receive () payable external {}
}

//质押LP挖矿
contract PledgeLP is Comn{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter _kLineIds;                        // ID自增器,从1开始

    uint public totalLpBalance;                        //当前质押的LP总数
    mapping(uint => uint) public idToKLineMapping;     //<id,K线时间>
    mapping(uint => uint) public kLineMapping;         //<K线时间,K线LP总数>
    mapping(address => uint) lpBalanceMapping;         //<地址,LP质押余额>

    // 矿池总质押额发生改变
    event UpdateTotallpPair (uint beforeAmout, uint afterAmout, address caller);

    /*
     * @dev  查询 | 所有人调用 | 我质押的LP余额
     */
    function queryPledgeLPBalance() public view returns (uint256){
        return lpBalanceMapping[msg.sender];
    }

    /*
     * @dev  创建 | 内部调用 | 增加质押信息K线
     */
    function addKLineMapping(uint totalBalance,uint nowTime) private isRunning returns (bool){
        uint lastId = _kLineIds.current(); //最后一次ID
        uint lastTime = idToKLineMapping[lastId]; //最后一次更新时间
        uint lastBalance = kLineMapping[lastTime]; //最后一次LP质押总额
        if(lastId == 0 || lastBalance == 0){//第一次创建 || 上次余额为0,已经被取完了
            _kLineIds.increment();
            uint256 nextId = _kLineIds.current();     // 获取最新ID (默认从1开始)
            idToKLineMapping[nextId] = nowTime;       // <ID,当前时间>
            kLineMapping[nowTime] = totalBalance;     // <当前时间,LP总数>
        } else {
            uint distance; //差值
            if(lastBalance > totalBalance){
                distance = lastBalance.sub(totalBalance);
            } else {
                distance = totalBalance.sub(lastBalance);
            }
            uint chg = distance.divFloat(lastBalance,18).backWei(15);//涨跌幅(单位:千分之)
            uint timeDistance = nowTime-lastTime;     //对比最后一次更新时间的间隔时间
            //时间差超过更新时间点 || 涨跌幅超过设置的涨跌比
            if(timeDistance >= poolConfigKLineCycle || chg >= poolConfigKLineChg){               
                _kLineIds.increment();
                uint256 nextId = _kLineIds.current();     //获取最新ID
                idToKLineMapping[nextId] = nowTime;       // <ID,当前时间>
                kLineMapping[nowTime] = totalBalance;     // <当前时间,LP总数>
            }
        }
        return true;
    }

    /*
     * @dev 创建 | 所有人调用 | 质押LP
     * @param amountToWei 金额
     */
    function pledgeLP(uint amountToWei) public isRunning nonReentrant returns (bool){
        if(amountToWei < 1){ _status = _NOT_ENTERED; revert("PledgeLP : Pledge quantity must be greater than 1"); }
        lpPair.transferFrom(msg.sender,address(this),amountToWei);
        uint nowTime = block.timestamp;
        createOrUpdateMiningInfo(msg.sender,nowTime);//在LP值未改变之前,把自己的待采集收益采集到待提取收益里,因为LP值的改变会导致每个收益的周期获得的收益发生变化

        lpBalanceMapping[msg.sender] = lpBalanceMapping[msg.sender].add(amountToWei);//加本地额度
        totalLpBalance = totalLpBalance.add(amountToWei);//加总额度
        emit UpdateTotallpPair(totalLpBalance.sub(amountToWei),totalLpBalance,msg.sender);
        
        addKLineMapping(totalLpBalance,nowTime);//增加K线记录
        return true;
    }

    /*
     * @dev 提取 | 所有人调用 | 提取我的所有LP
     * @param amountToWei 金额
     */
    function takeLp(uint amountToWei) public isRunning nonReentrant isFrozenTakeLp returns (bool) {
        if(lpBalanceMapping[msg.sender] <= 0){ _status = _NOT_ENTERED; revert("PledgeLP : Insufficient LP balance"); }
        if(amountToWei < 1){ _status = _NOT_ENTERED; revert("PledgeLP : Retrieval quantity must be greater than 1"); }
        if(amountToWei > lpBalanceMapping[msg.sender]){ _status = _NOT_ENTERED; revert("PledgeLP : Insufficient LP balance"); }
        lpPair.transfer(msg.sender,amountToWei);                                       //退还LP
        uint nowTime = block.timestamp;
        collectProfit(msg.sender,nowTime);                                             //采集待采集收益到待提取收益里
        if(lpBalanceMapping[msg.sender].sub(amountToWei) <= 0){
            miningMapping[msg.sender].isOpen = false;                                  //已经取完了,关闭挖矿状态
        }
        totalLpBalance = totalLpBalance.sub(amountToWei);                              //减总额度
        emit UpdateTotallpPair(totalLpBalance.add(amountToWei),totalLpBalance,msg.sender);
        lpBalanceMapping[msg.sender] = lpBalanceMapping[msg.sender].sub(amountToWei);  //本地LP清0
        
        addKLineMapping(totalLpBalance,nowTime);//增加K线记录
        return true;
    }

    /*--------------------------------------------------------质押挖矿业务-----------------------------------------------------------*/
    Counters.Counter private _MiningIds;                          // ID自增器,记录矿工个数

    mapping(address => uint) public completeTakeMapping;          //<地址,已提取的收益>
    mapping(address => uint) public completeCollectTimeNumMapping;//<地址,已采集时间数>
    mapping(address => uint) public completeCollectAmoutMapping;  //<地址,已采集的收益>
    mapping(address => Mining) public miningMapping;              //<地址,挖矿信息> (矿工信息)
    
    //挖矿信息
    struct Mining {
        bool isOpen;                //挖矿状态
        uint openTime;              //开挖时间
        uint lastCollectTime;       //最后一次采集时间
        uint lastCollectAmout;      //最后一次采集金额
        uint lastCollectTimeNum;    //最后一次采集时间数
        uint sumCollectAmout;       //总采集金额
        uint sumCollectTimeNum;     //总采集时间数
        uint createTime;            //创建时间
    }

    /*
     * @dev  创建 | 内部调用 | 创建或更新挖矿信息(保证地址唯一性)(注意:请在LP值改变之前调用,因为更新操作的时候会把LP值未改变之前的未采集收益,采集到待提取收益,下面会改变当前LP值,导致每个收益的周期获得的收益发生变化)
     * @param  operator 操作人
     */
    function createOrUpdateMiningInfo(address operator,uint nowTime) private isRunning returns (bool){
        collectProfit(operator,nowTime);//在LP值未改变之前,把自己的待采集收益采集到待提取收益里,因为LP值的改变会导致每个收益的周期获得的收益发生变化
        if(miningMapping[operator].createTime == 0){ //创建
            _MiningIds.increment();//新生成一个ID
            miningMapping[operator] = Mining(true,nowTime,0,0,0,0,0,nowTime);//创建挖矿信息
        } else { //更新
            if(miningMapping[operator].isOpen == false){
                miningMapping[operator].isOpen = true;                //开启挖矿状态
                miningMapping[operator].openTime = nowTime;           //重置开挖矿时间
            }
        }
        return true;
    }

    /*
     * @dev  修改 | 内部调用 | 采集收益
     * @param  operator 操作人
     * @param  nowTime 当前时间
     */
    function collectProfit(address operator,uint nowTime) private isRunning returns (uint){
        uint waitCollectProfit = queryWaitCollectProfit(operator,nowTime);                                //查询等待采集的收益
        if(waitCollectProfit > 0){
            uint timeNum = nowTime - miningMapping[operator].openTime;                                    //挖矿时间数
            completeCollectAmoutMapping[operator] = completeCollectAmoutMapping[operator].add(waitCollectProfit);   //更新已采集收益
            completeCollectTimeNumMapping[operator] = completeCollectTimeNumMapping[operator].add(timeNum);         //更新已经采集时间数
            miningMapping[operator].openTime = nowTime;                                                   //更新开挖时间
            miningMapping[operator].lastCollectTime = nowTime;                                            //更新最后一次采集时间
            miningMapping[operator].lastCollectAmout = waitCollectProfit;                                 //更新最后一次采集金额
            miningMapping[operator].lastCollectTimeNum = timeNum;                                         //更新最后一次采集时间数
            miningMapping[operator].sumCollectAmout = miningMapping[operator].sumCollectAmout.add(waitCollectProfit); //更新总采集金额
            miningMapping[operator].sumCollectTimeNum = miningMapping[operator].sumCollectTimeNum.add(timeNum);     //更新总采集时间数
            poolCollectSumAmount = poolCollectSumAmount.add(waitCollectProfit);                           //[统计]  已经产出的挖矿总数量
            poolWaitTakeSumAmount = poolWaitTakeSumAmount.add(waitCollectProfit);                         //[统计]  产出留存的挖矿总数量
        }
        return waitCollectProfit;
    }

    /*
     * @dev  查询 | 内部调用 | 查询指定地址的待采集收益
     * @param  operator 操作人
     * @param  endTime 统计时间
     */
    function queryWaitCollectProfit(address operator,uint endTime) private view returns (uint){
        uint lpBalance = lpBalanceMapping[operator];                            //查询者质押的LP数量
        Mining memory model = miningMapping[operator];                          //查询者的挖矿信息
        //查询者的LP质押数量 > 0 && 采矿状态为正常
        if(lpBalance > 0 && model.isOpen){                                      
            uint256 startTime=model.openTime;                                   //查询开始时间(开挖时间)
            if(endTime > startTime){
                uint lastId = _kLineIds.current();
                uint sumAmoutToWei = 0;                                         //我的总产量
                if(idToKLineMapping[lastId] < startTime){                       //开始时间超过最新K点时间
                    uint lastKBalance = kLineMapping[idToKLineMapping[lastId]];
                    return poolConfigSecondSumNumber.mul(lpBalance.divFloat(lastKBalance,18)).mul(endTime-startTime);
                }
                uint startHalfOpenRightIndex;                                   //左半开区间右下标
                for(uint i = lastId;i >= 1;i--){                                // K线从右到左,查询结算
                    uint kTime = idToKLineMapping[i];                           // 当前K线创建时间
                    uint kBalance = kLineMapping[kTime];                        // 当前K线LP总质押额
                    if(kTime >= startTime && kTime < endTime){
                        if(kBalance == 0){
                            endTime = kTime;
                        } else {
                            uint diff = endTime - kTime;                         // 结算时间段
                            endTime = kTime;                                     // 重置结算时间段
                            //当前区间内我的每秒产量(18位) = 每秒总产量 * 我当前质押的LP额度 / 当前K线LP总质押额
                            uint secondAmoutToWeiKLine = poolConfigSecondSumNumber.mul(lpBalance.divFloat(kBalance,18));
                            //当前区间内我的总产量
                            uint sumAmoutToWeiKLine = secondAmoutToWeiKLine.mul(diff);
                            sumAmoutToWei = sumAmoutToWei.add(sumAmoutToWeiKLine);
                        }
                    } else 
                    if(kTime < startTime){
                        startHalfOpenRightIndex = i+1;
                        break;//已超出用户实际意图想查询区间,不需要再做无谓的查询开销,直接跳出循环
                    }
                }
                //统计第一个半开区间的情况(即:kTimeLeft < startTime < kTimeRight 的第一个覆盖区间)
                uint halfOpenSumAmoutToWei = queryStartHalfOpenIndex(startHalfOpenRightIndex,lpBalance,startTime);
                return sumAmoutToWei.add(halfOpenSumAmoutToWei);
            }
        }
        return 0;
    }

    /* 
     * @dev  查询 | 内部调用 | 查询半开区间的情况 
     * @param  halfOpenRightIndex 半开区间右下标
     * @param  lpBalance 我的LP质押余额
     * @param  startTime 统计开始时间
     */
    function queryStartHalfOpenIndex(uint halfOpenRightIndex,uint lpBalance,uint startTime) private view returns (uint){
        uint halfOpenSumAmoutToWei;//半开区间总金额
        if(halfOpenRightIndex > 0 && halfOpenRightIndex - 1 > 0){
            uint kTimeLeft = idToKLineMapping[halfOpenRightIndex-1];
            uint kTimeRight = idToKLineMapping[halfOpenRightIndex];
            uint diff = kTimeRight - startTime;                     // 统计时间段
            uint kBalance = kLineMapping[kTimeLeft];                // 当前K线LP总质押额
            if(kBalance != 0){
                //当前区间内我的每秒产量(18位) = 每秒总产量 * 我当前质押的LP额度 / 当前K线LP总质押额
                uint secondAmoutToWeiKLine = poolConfigSecondSumNumber.mul(lpBalance.divFloat(kBalance,18));
                //当前区间内我的总产量
                halfOpenSumAmoutToWei = secondAmoutToWeiKLine.mul(diff);
            }
        }
        return halfOpenSumAmoutToWei;
    }

    /*
     * @dev  查询 | 所有人调用 | 查询我的所有收益
     */
    function queryProfitAll() public view returns (uint256,uint256,uint256){
        uint nowTime = block.timestamp;
        if(miningMapping[msg.sender].isOpen == true){
            uint waitCollectProfit = queryWaitCollectProfit(msg.sender,nowTime);    //待采集收益
            uint waitCollectTimeNum = nowTime - miningMapping[msg.sender].openTime; //待采集时间数
            uint completeCollectProfit = completeCollectAmoutMapping[msg.sender];   //已采集收益
            uint completeCollectTimeNum = completeCollectTimeNumMapping[msg.sender];//已采集时间数
            uint waitTakeAmout = waitCollectProfit+completeCollectProfit;           //待提取金额
            uint waitTakeTimeNum = waitCollectTimeNum+completeCollectTimeNum;       //待提取时间数
            return (waitTakeAmout,waitTakeTimeNum,nowTime);
        } else {
            return (0,0,nowTime);
        }
    }

    /*
     * @dev  修改 | 所有人调用 | 提取我的已采集的收益(先采集,再提取)
     */
    function takeProfitAll() public isRunning nonReentrant isFrozenTakeProfit returns (uint256,uint256){
        collectProfit(msg.sender,block.timestamp);                                                   //采集收益到已采集收益
        uint completeCollectProfit = completeCollectAmoutMapping[msg.sender];                        //获取已采集收益
        uint completeCollectTimeNum = completeCollectTimeNumMapping[msg.sender];                     //获取已采集时间数
        if(completeCollectProfit <= 0){ _status = _NOT_ENTERED; revert("PledgeLP : Sorry, your credit is running low"); }
        swt.transfer(msg.sender,completeCollectProfit);                                              //提取收益
        completeTakeMapping[msg.sender] = completeTakeMapping[msg.sender].add(completeCollectProfit);//记录地址已提取的收益
        poolTakeSumAmount = poolTakeSumAmount.add(completeCollectProfit);                            //[统计]  产出提走的挖矿总数量
        poolWaitTakeSumAmount = poolWaitTakeSumAmount.sub(completeCollectProfit);                    //[统计]  产出留存的挖矿总数量
        completeCollectAmoutMapping[msg.sender] = 0;                                                 //提取后,清0已采集收益
        completeCollectTimeNumMapping[msg.sender] = 0;                                               //提取后,清0已采集时间数
        return (completeCollectProfit,completeCollectTimeNum);
    }


    /*---------------------------------------------------管理运营-----------------------------------------------------------*/

    uint256 private poolConfigSecondSumNumber;              //[设置]  配置每秒的总产量(单位:个)
    uint256 private poolConfigKLineCycle;                   //[设置]  配置K线周期时间更新(单位:秒)[参考值:60]
    uint256 private poolConfigKLineChg;                     //[设置]  配置K线周期涨跌幅更新(单位:千分比)[参考值:100]
    ERC20 lpPair;                                           //[设置]  配置矿池质押的lpPair
    ERC20 swt;                                              //[设置]  配置矿池产出的代币


    uint256 private poolCollectSumAmount = 0;               //[统计]  已采集的矿总量
    uint256 private poolTakeSumAmount = 0;                  //[统计]  已提取的矿总量
    uint256 private poolWaitTakeSumAmount = 0;              //[统计]  待提取的矿总数量
    
    /*
     * @dev 设置 | 创建者调用 | 设置挖矿结算参数
     * @param secondSumNumber 每秒的总产出量
     * @param kLineCycle K线周期时间更新(秒)
     * @param kLineChg K线周期涨跌幅更新(千分比)
     * @param lpPairContract lpPairContract
     * @param swtContract swtContract
     */
    function setPoolConfig(uint256 secondSumNumber,uint256 kLineCycle,uint256 kLineChg,address lpPairContract,address swtContract) public onlyOwner {
        poolConfigSecondSumNumber = secondSumNumber;
        poolConfigKLineCycle = kLineCycle;
        poolConfigKLineChg = kLineChg;
        lpPair = ERC20(lpPairContract);
        swt = ERC20(swtContract);
    }

    /*
     * @dev  修改 | 授权者调用 | 提取平台的lpPair
     * @param outAddress 取出地址
     * @param amountToWei 交易金额
     */
    function poolOutLpPair(address outAddress,uint amountToWei) public onlyApprove{
        lpPair.transfer(outAddress,amountToWei);
    }

    /*
     * @dev  修改 | 授权者调用 | 提取平台的Swt代币
     * @param outAddress 取出地址
     * @param amountToWei 交易金额
     */
    function poolOutSwtToken(address outAddress,uint amountToWei) public onlyApprove{
        swt.transfer(outAddress,amountToWei);
    }


    /* 矿池 | 配置信息 */
    function poolConfigs() public view onlyApprove returns (uint256,uint256,uint256){
        return (poolConfigSecondSumNumber,poolConfigKLineCycle,poolConfigKLineChg);
    }
    
    /* 矿池 | 统计信息 */
    function poolStatistics() public view onlyApprove returns (uint256,uint256,uint256,uint256){
        uint poolSumMining = _MiningIds.current();//总矿工数
        return (poolSumMining,poolCollectSumAmount,poolTakeSumAmount,poolWaitTakeSumAmount);
    }

}