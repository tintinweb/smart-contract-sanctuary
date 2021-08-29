pragma solidity >=0.7.6;
pragma abicoder v2;

import '../libraries/SafeMath.sol'; 
import '../libraries/Address.sol'; 
import '../libraries/trademint/PoolAddress.sol'; 
import '../interface/IERC20.sol'; 
import '../interface/ITokenIssue.sol'; 
import '../libraries/SafeERC20.sol'; 
import '../interface/trademint/ISummaSwapV3Manager.sol'; 
import '../interface/trademint/ITradeMint.sol'; 
import '../libraries/Context.sol'; 
import '../libraries/Owned.sol'; 
import '../libraries/FixedPoint128.sol';
import '../libraries/FullMath.sol';
import '../interface/ISummaPri.sol'; 

/*
    计算用户交易奖励金额跟流动性挖矿奖励金额。

    交易奖励 ： 
    1、在 一个结算区间内，交易应该发放的总奖励  totalReward 
    2、在 一个结算区间内，交易产生的交易总额  totalTradeAmount
    3、在 一个结算区间内，该用户的交易总额   selfTradeAmount

    tradeRewade =  selfTradeAmount/totalTradeAmount * totalReward

    流动性挖矿奖励：

    1、在 一个结算区间内。流动性应该发放的奖励  totalReward
    2、在 一个结算区间内，交易产生的交易总额    totalTradeAmount
    3、在 一个结算区间内，在某一个tickLower 至 tickUpper之间产生的交易总额 positionTradeAmount
    4、在 该 positionTradeAmount  对应的流动性 为 liquidity
    5、那么该区间在这一个结算区间获得的奖励为  liquidityRewade = positionTradeAmount/totalTradeAmount *totalReward
    6、要计算用户流动性，因为交易的区间基本上不可能是用户刚刚好设定的区间内交易，大部分上的交易都是位于每一个用户的流动性区间的其中一个tick的跟另外一个用户
    的其中一个tick组成的区间。所以无法精确计算每一个用户该获得的奖励。
    7、在这里利用全局的每一个单位流动性应该获得的奖励 减去某一个区间外部 获得的单位流动性奖励。得到该区间一单位流动性应该获得的奖励。
    8、用户在某一个区间存在的流动性 乘以该区间一单位流动性的奖励 即可算出用户应该获得的奖励。
    9、在这里无法实时结算，无法采用资金池的结算方法。
    10、在该合约中设置了两个值，一个是全局单位流动性交易量的增量。表示未结算的奖励。一个全局单位流动性奖励的增量，表示已计算的奖励金额
    11、记录穿过某一个Tick的时候，记录一个该tick外部单位流动性交易量增量。同时记录该tick下外部单位流动性奖励的增量。
    12、 根据第五点，我们可以得到   在某一个区间。 单位流动性奖励增量 liquidityVolumeGrowth = positionTradeAmount *totalReward / liquidity /totalTradeAmount
    13、我们可以将  positionTradeAmount/liquidity 表示 一 单位流动性交易量的增量。这个可以实时记录。在某一个结算区间结束的时候，下一个用户发起交易时，
    根据该结算区间应该发放的奖励，跟该结算区间的交易总量 结算 单位流动性奖励的增量。liquidityVolumeGrowth
 */
contract TradeMint is ITradeMint,Context,Owned{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    ITokenIssue public tokenIssue;// 发行合约
    
    ISummaSwapV3Manager public iSummaSwapV3Manager;//管理合约，通过管理合约查询用户的流动性跟区间详情

    uint256 public totalIssueRate = 0.1 * 10000;// 用于该合约奖励用户流动性跟交易的SUM 占 总发行量的比例
    
    uint256 public settlementBlock;// 结算区块。多少个区块结算一次。
    
    mapping(address => bool) public  isReward; //该交易对是否可以获得奖励，只有管理员设定的交易对可以获得奖励
    
    uint256 public totalRewardShare;// 所有交易对获取奖励   SUM的总份额。如ETH-USDT 份额 100.  ETH-SUM 份额 200 总份额为300
    
    address public factory;//工厂地址，用来计算交易对地址
    
    uint256 public tradeShare; //交易对中交易占奖励的比例。指跟流动性挖矿的比率。 采用分数。如设置为 3.则 交易占比为 该交易对获得奖励的3分1 。为 4则为4分1。

    bytes32 public constant PUBLIC_ROLE = keccak256("PUBLIC_ROLE");// 是否激活 的Key

    uint24 public reduceFee;// 激活的地址。交易减少的手续费  设置5  即减少5分之1

    uint24 private superFee;// 激活的地址。转给上级地址的手续费  设置5  即减少5分之1
    
    struct TickInfo{
        uint256 liquidityVolumeGrowthOutside; //记录每一个Tick外部的单位流动性交易量的增量
        
        uint256 liquidityIncentiveGrowthOutside;//记录每一个Tick外部的单位流动性奖励的增量。奖励的增量只有结算的时候根据单位流动性交易量的增量计算。
        
        uint256 settlementBlock;//应该结算的区块
    }
    
    
    struct PoolInfo {
        uint256 lastSettlementBlock;  //上次结算的区块 
        
        mapping(int24 => TickInfo)  ticks;  //记录的Tick信息
        
        uint256 liquidityVolumeGrowth;// 单位流动性交易量的全局增量
        
        uint256 liquidityIncentiveGrowth;// 单位流动性奖励的全局增量
    
        uint256 rewardShare; // 该交易对获得的奖励的份额
    
        int24 currentTick; //记录交易对当前大致的Tick信息。
        
        uint256 unSettlementAmount; //记录交易对未结算的交易量
        
        mapping(uint256 => uint256)  blockSettlementVolume; // 每一次在该结算的区块结算的交易量  用于计算某一个 Tick 单位流动性交易量转换成单位流动性奖励增量。
        
        address poolAddress;//资金池地址
        
        mapping(uint256 => uint256)  tradeSettlementAmountGrowth; // 每一次结算后，记录在结算区块高度的交易应该分到奖励的增量。 奖励除以交易量。
                                                                 //用户计算交易获得的奖励，用在该区间的交易量乘以改值。涉及一些误差记录。在记录的时候会做一些放大一些倍数。
                                                                 //结算的时候需要做相应的处理
        
    }
    
    
    struct UserInfo {
        uint256 tradeSettlementedAmount;     // 用户交易计算的金额。因为如果在用户在多个结算区间都有交易，不做结算，到最后再结算。可能需要大量遍历，导致结算异常。
                                           //用户只会保存一个未结算的区间的交易金额。如果后续该用户继续交易，会将他之前的交易结算在该值。
        
        uint256 tradeUnSettlementedAmount; //用户尚未结算的交易金额
        
        uint256 lastTradeBlock; // 用户最后一次交易的区块高度
        
        uint256 lastRewardGrowthInside; // 用户添加流动性或者提取奖励后，记录该用户单位流动性的奖励增量。计算用户区间流动性奖励增量时，要该区间的单位流动性奖励增量减去用户的单位流动性奖励增量。
        
    }
   
    address[] public poolAddress; // 可以获得奖励的资金池信息
    
    
    uint256 public pledgeRate; // 提取奖励的质押率

    uint256 public minPledge; //提取奖励需要的最小值。 如根据质押率计算的质押值小于该值。那么以该值为最低值结算。即用户账号满足 SUM余额大于该值时才能提取。
    
    address public summaAddress; // 拥有奖励的SUM 合约地址

    address public priAddress; // 推荐关系绑定合约地址。
    
    mapping(address => mapping(address => UserInfo)) public  userInfo;  //记录用户交易 的信息，跟流动性提取的信息
    
    
    mapping(address => PoolInfo) public  poolInfoByPoolAddress; // 根据资金池地址查找 资金池信息。
    
    uint256 public lastWithdrawBlock; //上一个从发行合约提取奖励的区块高度。
    
    
    event Cross(int24 _tick,int24 _nextTick);
    
    event Snapshot(address tradeAddress,int24 tick,uint256 liquidityVolumeGrowth,uint256 tradeVolume);
    
    event SnapshotLiquidity(address tradeAddress,address poolAddress,int24 _tickLower,int24 _tickUpper);
    

    function setTokenIssue(ITokenIssue _tokenIssue) public onlyOwner {
        tokenIssue = _tokenIssue;
    }

    function setISummaSwapV3Manager(ISummaSwapV3Manager _ISummaSwapV3Manager) public onlyOwner {
        iSummaSwapV3Manager = _ISummaSwapV3Manager;
    }

    function setTotalIssueRate(uint256 _totalIssueRate) public onlyOwner {
        totalIssueRate = _totalIssueRate;
    }
    function setSettlementBlock(uint256 _settlementBlock) public onlyOwner {
        settlementBlock = _settlementBlock;
    }
    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }
    function setTradeShare(uint256 _tradeShare) public onlyOwner {
        tradeShare = _tradeShare;
    }
    function setPledgeRate(uint256 _pledgeRate) public onlyOwner {
        pledgeRate = _pledgeRate;
    }
    function setMinPledge(uint256 _minPledge) public onlyOwner {
        minPledge = _minPledge;
    }
    function setSummaAddress(address _summaAddress) public onlyOwner {
        summaAddress = _summaAddress;
    }
    function setPriAddress(address _priAddress) public onlyOwner {
        priAddress = _priAddress;
    }
    function setReduceFee(uint24 _reduceFee) public onlyOwner {
        reduceFee = _reduceFee;
    }
    function setSuperFee(uint24 _superFee) public onlyOwner {
        superFee = _superFee;
    }
    function enableReward(address _poolAddress,bool _isReward,uint256 _rewardShare) public onlyOwner {
        isReward[_poolAddress] = _isReward;
        massUpdatePools();
        if(_isReward){
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            _poolInfo.lastSettlementBlock = block.number.div(settlementBlock).mul(settlementBlock);
            _poolInfo.poolAddress = _poolAddress;
            _poolInfo.rewardShare = _rewardShare;
            totalRewardShare += _rewardShare;
            poolAddress.push(_poolAddress);
        }

    }
    function enableReward(address token0,address token1,uint24 fee,bool _isReward,uint256 _rewardShare) public onlyOwner {
        address _poolAddress = PoolAddress.computeAddress(factory,token0,token1,fee);
        isReward[_poolAddress] = _isReward;
        massUpdatePools();
        if(_isReward){
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            _poolInfo.lastSettlementBlock = block.number.div(settlementBlock).mul(settlementBlock);
            _poolInfo.poolAddress = _poolAddress;
            _poolInfo.rewardShare = _rewardShare;
            totalRewardShare += _rewardShare;
            poolAddress.push(_poolAddress);
        }
    }
    function massUpdatePools() public {
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    function updatePool(uint256 _pid) public {
        address _poolAddress = poolAddress[_pid];
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
        if(poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number){
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to =(form.add(settlementBlock));
                uint256 multiplier = getMultiplier(form, to);
                uint256 summaReward = multiplier.mul(poolInfo.rewardShare).div(totalRewardShare).div(tradeShare);
                settlementTrade(poolInfo.poolAddress,summaReward);
                settlementPoolNewLiquidityIncentiveGrowth(poolInfo.poolAddress);
        }
    }
    
    // 计算未提取的奖励
    function pendingSumma() public view returns(uint256){
        uint256 amount = 0; // 初始化奖励
        uint256 length = poolAddress.length;  // 资金池长度
        for (uint256 pid = 0; pid < length; ++pid) { // 根据资金池长度遍历每一个资金池获得的奖励
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[msg.sender][poolAddress[pid]]; // 根据自己的地址跟资金池地址储存每一个资金池对应的UserInfo
            if(userInfo.lastTradeBlock < poolInfo.lastSettlementBlock){ 
                // 假如用户UserInfo最后交易区块小于 资金池最后结算区块。证明用户的交易已经结算了，用该区块下储存的该结算区间一单位交易量获得的奖励乘以用户未结算的交易量得到用户已结算的奖励
                amount += userInfo.tradeUnSettlementedAmount.mul(poolInfo.tradeSettlementAmountGrowth[(userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(settlementBlock)]);
            }else if((userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(settlementBlock) <= block.number){
                // 假如用户最后交易的时间大于资金池最后结算区块。而且最后交易区块到目前区块已经达到一个结算区块。那么要计算用户结算的奖励
                uint256 form = (userInfo.lastTradeBlock.div(settlementBlock).sub(1)).mul(settlementBlock);
                uint256 to =(userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(settlementBlock);
                uint256 multiplier = getMultiplier(form, to);
                uint256 summaReward = multiplier.mul(poolInfo.rewardShare).div(totalRewardShare).div(tradeShare);
                amount += (summaReward.div(poolInfo.unSettlementAmount).mul(userInfo.tradeUnSettlementedAmount));
           }
           //其他情况。比如用户最后交易区块未达到下一个结算区块。而大于上一次结算区块。未结算的奖励不予以结算。只累计已结算的奖励即可
            amount = amount+userInfo.tradeSettlementedAmount;
        }
        // 根据用户NFT的余额，获取用户添加的流动性。
        uint256 balance = iSummaSwapV3Manager.balanceOf(msg.sender);
        
        for (uint256 pid = 0; pid < balance; ++pid) {
            //遍历用户每一个NFT的储存的position信息。
            (,,address token0,address token1,uint24 fee,int24 tickLower,int24 tickUpper,uint128 liquidity,,,,) =iSummaSwapV3Manager.positions(iSummaSwapV3Manager.tokenOfOwnerByIndex(msg.sender,pid));
            address poolAddress = PoolAddress.computeAddress(factory,token0,token1,fee);
            if(isReward[poolAddress]){ // 如果是管理员已设置能获取奖励的交易对。 计算用户tickLower 到 tickUpper 区间每一单位流动性应该获得的奖励。
                uint256 liquidityIncentiveGrowthInPosition = this.getLiquidityIncentiveGrowthInPosition(tickLower,tickUpper,poolAddress).sub(userInfo[msg.sender][poolAddress].lastRewardGrowthInside);
                // 获取到区间的单位流动性奖励增长，减去用户加入该区间时候或者是上次提取之后的单位流动性增长。得到用户从上次到现在这一段时间应该结算的单位流动性奖励增长。
                amount +=  FullMath.mulDiv(
                liquidityIncentiveGrowthInPosition,
                liquidity,
                FixedPoint128.Q128);
                
                // 利用 用户的流动性乘以 该区间一单位流动性应该获得的奖励。等到用户该段时间应该获得的奖励
            }
        }
        //最后返回用户获得的总奖励。
        return amount;
    }
    function getPoolReward(address  poolAddress) external view returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        // 获取资金池 上一次结算之后。到新的结算区块之间应该获取的奖励。
        uint256 form = poolInfo.lastSettlementBlock;
        uint256 to = poolInfo.lastSettlementBlock.add(settlementBlock);
        uint256 multiplier = getMultiplier(form, to);
        // 用给与流动性挖矿跟交易挖矿的总奖励乘以 资金池的份额除以总份额 除以交易份数。乘以资金池占的份数。 
        uint256 reward =  multiplier.mul(poolInfo.rewardShare).div(totalRewardShare).div(tradeShare).mul(tradeShare.sub(1));    
        return reward;
    }
    
    function getPoolReward(address  poolAddress,uint256 form,uint256 to) external view returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 multiplier = getMultiplier(form, to);
        uint256 reward =  multiplier.mul(poolInfo.rewardShare).div(totalRewardShare).div(tradeShare).mul(tradeShare.sub(1));    
        return reward;
    }
    function getLiquidityIncentiveGrowthInPosition(int24 _tickLower,int24 _tickUpper,address  poolAddress) external view returns (uint256) {
        // 计算用户的tick区间 一单位 流动性的奖励 增量
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress]; // 根据资金池地址拿到资金池信息
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth;// 资金池全局的一单位流动性 对应奖励的增长
        if(poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number){  // 判断该资金池下一个结算区块 是否已经达到。 如果到了下一个结算区块，应该先结算之后再去计算奖励
            newLiquidityIncentiveGrowth = this.getPoolNewLiquidityIncentiveGrowth(poolAddress);
        }
        TickInfo storage tickLower = poolInfo.ticks[_tickLower];

        uint256 newLowerLiquidityIncentiveGrowthOutside = tickLower.liquidityIncentiveGrowthOutside;
        // 获取 tick信息
        if(tickLower.liquidityVolumeGrowthOutside != 0){ // 如果该Tick下存在未结算的交易量。先将单位流动性交易量增长转成单位流动性奖励增长
            uint256 lowerReward = this.getPoolReward(poolAddress,tickLower.settlementBlock.sub(settlementBlock),tickLower.settlementBlock);
            //获取 tick下 结算区间应该发放的SUM
            newLowerLiquidityIncentiveGrowthOutside = newLowerLiquidityIncentiveGrowthOutside +lowerReward.mul(tickLower.liquidityVolumeGrowthOutside).div(poolInfo.blockSettlementVolume[tickLower.settlementBlock]);
            // 奖励乘以 单位流动性交易量增长 除以 该结算区间下的交易总量
        }
       
        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        uint256 newUpLiquidityIncentiveGrowthOutside = tickUpper.liquidityIncentiveGrowthOutside;
        if(tickUpper.liquidityVolumeGrowthOutside != 0){
            uint256 upReward = this.getPoolReward(poolAddress,tickUpper.settlementBlock.sub(settlementBlock),tickUpper.settlementBlock);
            //获取 tick下 结算区间应该发放的SUM
            newUpLiquidityIncentiveGrowthOutside = newUpLiquidityIncentiveGrowthOutside +upReward.mul(tickUpper.liquidityVolumeGrowthOutside).div(poolInfo.blockSettlementVolume[tickUpper.settlementBlock]);
            // 奖励乘以 单位流动性交易量增长 除以 该结算区间下的交易总量
        }
        // calculate fee growth below
        uint256 feeGrowthBelow;
        if (poolInfo.currentTick >= _tickLower) {
            // 如果当前tick在 tickLower 之上。 ticklower外部的 单位流动性奖励增长 就是记录的值。
            feeGrowthBelow = newLowerLiquidityIncentiveGrowthOutside;
        } else {
            // 如果当前tick在 tickLower 之下。 ticklower外部的 单位流动性奖励增长 等于全局单位流动性奖励增长减去 外部的单位流动性增长
            feeGrowthBelow = newLiquidityIncentiveGrowth - newLowerLiquidityIncentiveGrowthOutside;
        }

       
        uint256 feeGrowthAbove;
        if (poolInfo.currentTick < _tickUpper) {
            // 如果当前tick在 _tickUpper 之下。 _tickUpper 单位流动性奖励增长 就是记录的值。
            feeGrowthAbove = newUpLiquidityIncentiveGrowthOutside;
        } else {
             // 如果当前tick在 _tickUpper 之上。 _tickUpper 单位流动性奖励增长 等于全局单位流动性奖励增长减去 外部的单位流动性增长
            feeGrowthAbove = newLiquidityIncentiveGrowth - newUpLiquidityIncentiveGrowthOutside;
        }
        // tickLower 到  _tickUpper 区间之间的 单位流动性奖励 增长 等于 全局单位流动性奖励增长减去 两个tick外部的暂无流动性奖励增长
        uint256 feeGrowthInside = newLiquidityIncentiveGrowth - feeGrowthBelow - feeGrowthAbove ;
        return feeGrowthInside;
    }
    function settlementLiquidityIncentiveGrowthInPosition(int24 _tickLower,int24 _tickUpper,address  poolAddress) internal returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        // 根据资金池信息。如果资金池最后结算的区块，小于当前区块。结算资金池新的单位流动性奖励的增长
        if(poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number){
            settlementPoolNewLiquidityIncentiveGrowth(poolAddress);
        }
        
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth;
        TickInfo storage tickLower = poolInfo.ticks[_tickLower];

        uint256 lowerReward = this.getPoolReward(poolAddress,tickLower.settlementBlock.sub(settlementBlock),tickLower.settlementBlock);
        if(poolInfo.blockSettlementVolume[tickLower.settlementBlock] >0 && tickLower.liquidityVolumeGrowthOutside>0){
            //如果Tick存在未结算的外部单位流动性交易量增长 结算成单位流动性奖励增长
            tickLower.liquidityIncentiveGrowthOutside = tickLower.liquidityIncentiveGrowthOutside+lowerReward.mul(tickLower.liquidityVolumeGrowthOutside).div(poolInfo.blockSettlementVolume[tickLower.settlementBlock]);
        }
        uint256 newLowerLiquidityIncentiveGrowthOutside = tickLower.liquidityIncentiveGrowthOutside;

        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        uint256 upReward = this.getPoolReward(poolAddress,tickUpper.settlementBlock.sub(settlementBlock),tickUpper.settlementBlock);
        if(poolInfo.blockSettlementVolume[tickUpper.settlementBlock] >0 && tickUpper.liquidityVolumeGrowthOutside >0){
            //如果Tick存在未结算的外部单位流动性交易量增长 结算成单位流动性奖励增长
            tickUpper.liquidityIncentiveGrowthOutside = tickUpper.liquidityIncentiveGrowthOutside+upReward.mul(tickUpper.liquidityVolumeGrowthOutside).div(poolInfo.blockSettlementVolume[tickUpper.settlementBlock]);
        }
        uint256 newUpLiquidityIncentiveGrowthOutside  = tickUpper.liquidityIncentiveGrowthOutside;
        // calculate fee growth below
        uint256 feeGrowthBelow;
        if (poolInfo.currentTick >= _tickLower) {
            feeGrowthBelow = newLowerLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthBelow = newLiquidityIncentiveGrowth - newLowerLiquidityIncentiveGrowthOutside;
        }

       
        uint256 feeGrowthAbove;
        if (poolInfo.currentTick < _tickUpper) {
            feeGrowthAbove = newUpLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthAbove = newLiquidityIncentiveGrowth - newUpLiquidityIncentiveGrowthOutside;
        }
        uint256 feeGrowthInside = newLiquidityIncentiveGrowth - feeGrowthBelow - feeGrowthAbove ;
        return feeGrowthInside;
    }
    function settlementPoolNewLiquidityIncentiveGrowth(address  poolAddress) internal returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 reward = this.getPoolReward(poolAddress);
        // 资金池单位流动性奖励增长 等于 资金池单位流动性奖励增长乘以 资金池单位交易量增长除以资金池未结算的交易金额
        poolInfo.liquidityIncentiveGrowth += poolInfo.liquidityIncentiveGrowth+reward.mul(poolInfo.liquidityVolumeGrowth).div(poolInfo.unSettlementAmount);
        poolInfo.liquidityVolumeGrowth = 0;
        // 将资金池未结算的单位流动性增长置0
        poolInfo.blockSettlementVolume[poolInfo.lastSettlementBlock.add(settlementBlock)] = poolInfo.unSettlementAmount;
        // 记录该区间结算的交易量
        poolInfo.unSettlementAmount = 0;
        // 将未结算的交易量置0
        poolInfo.lastSettlementBlock = poolInfo.lastSettlementBlock.add(settlementBlock);
        //更新最后结算区块
        return poolInfo.liquidityIncentiveGrowth;
    }
    function getPoolNewLiquidityIncentiveGrowth(address  poolAddress) external view returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        //计算新的资金池单位流动性 奖励的增长
        uint256 reward = this.getPoolReward(poolAddress); // 获取资金池在新的结算区间应该获得的SUM奖励 
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth.add(reward.mul(poolInfo.liquidityVolumeGrowth).div(poolInfo.unSettlementAmount));
        // 资金池在新的结算区间获得的奖励乘以，单位流动性交易量的增长 除以 该资金池未结算的 交易量。得到单位流动性 奖励的增长
        return newLiquidityIncentiveGrowth;
    }
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 issueTime = tokenIssue.startIssueTime();
         if (_to < issueTime) {
                return 0;
            }
            if (_from < issueTime) {
                return getIssue(issueTime, _to).mul(totalIssueRate).div(10000);
            }
        return getIssue(issueTime, _to).sub(getIssue(issueTime, _from)).mul(totalIssueRate).div(10000);
    }
    function withdraw() public {
        // 提现，计算从上次从发行合约转过来的的区块。到现在新的区块，发行合约应该给交易挖矿的奖励的SUM。
        uint256 summaReward = getMultiplier(lastWithdrawBlock,block.number);
        tokenIssue.transByContract(address(this), summaReward);
        // 从发行合约将该发行的奖励 转移到该合约下。
        uint256 amount = withdrawSettlement();
        // 结算 用户 的奖励。
        uint256 pledge = amount.mul(pledgeRate).div(100);
            if(pledge < 100 * 10 ** 18){
                pledge = 100 * 10 ** 18;
            }
        require(IERC20(summaAddress).balanceOf(msg.sender)>pledge,"Insufficient pledge");
        IERC20(summaAddress).safeTransfer(address(msg.sender), amount);
    }
    function settlementTrade(address tradeAddress,address  poolAddress,uint256 summaReward) internal{
        UserInfo storage userInfo = userInfo[tradeAddress][poolAddress];
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        poolInfo.tradeSettlementAmountGrowth[poolInfo.lastSettlementBlock.add(settlementBlock)] += summaReward.div(poolInfo.unSettlementAmount);
        //结算 上一个结算区间的单位交易量的奖励，并记录在结算区块
        userInfo.tradeSettlementedAmount += userInfo.tradeUnSettlementedAmount.mul(poolInfo.tradeSettlementAmountGrowth[(userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(settlementBlock)]);
        //将用户之前的交易量结算为奖励金额
        userInfo.tradeUnSettlementedAmount = 0;
        //将用户未结算的交易量置0
    }
    function settlementTrade(address  poolAddress,uint256 summaReward) internal{
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        poolInfo.tradeSettlementAmountGrowth[poolInfo.lastSettlementBlock.add(settlementBlock)] += summaReward.div(poolInfo.unSettlementAmount);
    }
    function withdrawSettlement() internal returns(uint256){
        uint256 amount = 0; // 初始化金额 
        uint256 length = poolAddress.length; // 获取资金池长度 
        for (uint256 pid = 0; pid < length; ++pid) {
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[msg.sender][poolAddress[pid]];
            // 获取资金池下每一个用户信息
            if(userInfo.lastTradeBlock != 0){
                if(userInfo.lastTradeBlock < poolInfo.lastSettlementBlock){
                    // 如果用户最后交易的区块 ，已经被结算。那么根据用户未结算的交易量。结算用户的奖励。同时将用户未结算的交易量清0
                    userInfo.tradeSettlementedAmount += userInfo.tradeUnSettlementedAmount.mul(poolInfo.tradeSettlementAmountGrowth[(userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(settlementBlock)]);
                    userInfo.tradeUnSettlementedAmount = 0;
                }else if((userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(settlementBlock) <= block.number){
                    // 如果用户最后交易区块 大于资金池最后结算的区块，而最后的交易应该结算的区块小于当前区间。将该区间结算。
                    uint256 form = (userInfo.lastTradeBlock.div(settlementBlock)).mul(settlementBlock);
                    uint256 to =(form.add(settlementBlock));
                    uint256 multiplier = getMultiplier(form, to);
                    uint256 summaReward = multiplier.mul(poolInfo.rewardShare).div(totalRewardShare).div(tradeShare);
                    poolInfo.tradeSettlementAmountGrowth[form.add(settlementBlock)] += summaReward.div(poolInfo.unSettlementAmount);
                    // 结算资金池 在该结算区间 一单位交易量应该获得的奖励
                    userInfo.tradeSettlementedAmount += userInfo.tradeUnSettlementedAmount.mul(poolInfo.tradeSettlementAmountGrowth[form.add(settlementBlock)]);
                    
                    userInfo.tradeUnSettlementedAmount = 0;
                    // 将用户未结算的金额清0
                }
                amount += userInfo.tradeSettlementedAmount;
                userInfo.tradeSettlementedAmount = 0;
                //结算完毕之后将用户已结算的金额清0、这里只能提取调用。如果提取失败，该数据不会更新。
            }
            
        }
        
        uint256 balance = iSummaSwapV3Manager.balanceOf(msg.sender);

        // 获取用户 NFT的余额
        
        for (uint256 pid = 0; pid < balance; ++pid) {
            (,,address token0,address token1,uint24 fee,int24 tickLower,int24 tickUpper,uint128 liquidity,,,,) =iSummaSwapV3Manager.positions(iSummaSwapV3Manager.tokenOfOwnerByIndex(msg.sender,pid));
            address poolAddress = PoolAddress.computeAddress(factory,token0,token1,fee);
            if(isReward[poolAddress]){
                uint256 newLiquidityIncentiveGrowthInPosition = settlementLiquidityIncentiveGrowthInPosition(tickLower,tickUpper,poolAddress);
                // 结算资金池全局单位流动性奖励增长。
                uint256 liquidityIncentiveGrowthInPosition = newLiquidityIncentiveGrowthInPosition.sub(userInfo[msg.sender][poolAddress].lastRewardGrowthInside);
                userInfo[msg.sender][poolAddress].lastRewardGrowthInside = newLiquidityIncentiveGrowthInPosition;
                // 将用户记录的单位流动性奖励增长记录为提取时的单位流动性奖励增长
                amount += FullMath.mulDiv(
                liquidityIncentiveGrowthInPosition,
                liquidity,
                FixedPoint128.Q128);
            }
        }
        return amount;
    }
    
    function getIssue(uint256 _from, uint256 _to) private view returns (uint256){
        if (_to <= _from || _from <= 0) {
            return 0;
        }
        uint256 timeInterval = _to - _from;
        uint256 monthIndex = timeInterval.div(tokenIssue.MONTH_SECONDS());
        if (monthIndex < 1) {
            return timeInterval.mul(tokenIssue.issueInfo(monthIndex).div(tokenIssue.MONTH_SECONDS()));
        } else if (monthIndex < tokenIssue.issueInfoLength()) {
            uint256 tempTotal = 0;
            for (uint256 j = 0; j < monthIndex; j++) {
                tempTotal = tempTotal.add(tokenIssue.issueInfo(j));
            }
            uint256 calcAmount = timeInterval.sub(monthIndex.mul(tokenIssue.MONTH_SECONDS())).mul(tokenIssue.issueInfo(monthIndex).div(tokenIssue.MONTH_SECONDS())).add(tempTotal);
            if (calcAmount > tokenIssue.TOTAL_AMOUNT().sub(tokenIssue.INIT_MINE_SUPPLY())) {
                return tokenIssue.TOTAL_AMOUNT().sub(tokenIssue.INIT_MINE_SUPPLY());
            }
            return calcAmount;
        } else {
            return 0;
        }
    }
    //交易穿过某一个tick 之后。记录在该tick下的外部单位流动性增长。提供给资金池的接口
    function cross(int24 _tick,int24 _nextTick) external override{
        require(Address.isContract(_msgSender()));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        if(isReward[_msgSender()]){
            poolInfo.currentTick = _nextTick;
            TickInfo storage tick  = poolInfo.ticks[_tick];
            //如果tick存在未结算的单位流动性交易量增长。先结算
            if(tick.liquidityVolumeGrowthOutside >0 ){
                uint256 reward = this.getPoolReward(_msgSender(),tick.settlementBlock.sub(settlementBlock),tick.settlementBlock);
                tick.liquidityIncentiveGrowthOutside = tick.liquidityIncentiveGrowthOutside+reward.mul(tick.liquidityVolumeGrowthOutside).div(poolInfo.blockSettlementVolume[tick.settlementBlock]);
            }
            // 穿过tick之后交易量要翻转。
            tick.liquidityIncentiveGrowthOutside = poolInfo.liquidityIncentiveGrowth - tick.liquidityIncentiveGrowthOutside;
            tick.liquidityVolumeGrowthOutside = poolInfo.liquidityVolumeGrowth - tick.liquidityVolumeGrowthOutside;
            tick.settlementBlock = poolInfo.lastSettlementBlock.add(settlementBlock);
            emit Cross(_tick, _nextTick);
        }
    }
   
    function snapshot(address tradeAddress,int24 tick,uint256 liquidityVolumeGrowth,uint256 tradeVolume) external override {
        require(Address.isContract(_msgSender()));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        if(isReward[_msgSender()]){
            if(poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number){
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to =(form.add(settlementBlock));
                uint256 multiplier = getMultiplier(form, to);
                uint256 summaReward = multiplier.mul(poolInfo.rewardShare).div(totalRewardShare).div(tradeShare);
                settlementTrade(tradeAddress,_msgSender(),summaReward);
                settlementPoolNewLiquidityIncentiveGrowth(_msgSender());
            }
            UserInfo storage userInfo = userInfo[tradeAddress][_msgSender()];
            userInfo.tradeUnSettlementedAmount += tradeVolume;
            userInfo.lastTradeBlock = block.number;
            poolInfo.currentTick = tick;
            poolInfo.liquidityVolumeGrowth += liquidityVolumeGrowth;
            poolInfo.unSettlementAmount += tradeVolume;
            
            emit Snapshot(tradeAddress, tick, liquidityVolumeGrowth, tradeVolume);
        }
    }

    // 提供接口给添加流动性时记录用户区间流动性增长
    function snapshotLiquidity(address tradeAddress,int24 _tickLower,int24 _tickUpper) external override{
        require(Address.isContract(_msgSender()));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        if(isReward[_msgSender()]){
            UserInfo storage userInfo = userInfo[tradeAddress][_msgSender()];
            // 如果达到结算条件，未结算。先结算、
            if(poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number){
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to =(form.add(settlementBlock));
                uint256 multiplier = getMultiplier(form, to);
                uint256 summaReward = multiplier.mul(poolInfo.rewardShare).div(totalRewardShare).div(tradeShare);
                settlementTrade(tradeAddress,_msgSender(),summaReward);
            }
            userInfo.lastRewardGrowthInside = settlementLiquidityIncentiveGrowthInPosition(_tickLower,_tickUpper,_msgSender());
            
            emit SnapshotLiquidity(tradeAddress, _msgSender(), _tickLower, _tickUpper);
        }
    }

    function getFee(address current,uint24 fee) external view  override returns (uint24){
        uint24 newfee = fee;
        if(ISummaPri(priAddress).hasRole(PUBLIC_ROLE, current)){
            newfee = fee - (fee/reduceFee);
        }
        return newfee;
    }

    function getRelation(address current) external view override returns (address){ 
        return ISummaPri(priAddress).getRelation(current);
    }

    function getSuperFee() external view override returns (uint24){ 
        return superFee;
    }
}

pragma solidity =0.7.6;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity =0.7.6;
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity =0.7.6;
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0x9789d418d2a738f5b88b389d22d42e66e082e37140c68d5f3fea56c9197db800;

   
    function computeAddress(address factory, address token0,address token1,uint24 fee) internal pure returns (address pool) {
        require(token0 < token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(token0, token1, fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

pragma solidity >=0.7.6;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.7.6;
interface ITokenIssue {
    function transByContract(address to, uint256 amount) external;

    function issueInfo(uint256 monthIndex) external view returns (uint256);

    function startIssueTime() external view returns (uint256);

    function issueInfoLength() external view returns (uint256);

    function TOTAL_AMOUNT() external view returns (uint256);

    function DAY_SECONDS() external view returns (uint256);

    function MONTH_SECONDS() external view returns (uint256);

    function INIT_MINE_SUPPLY() external view returns (uint256);
}

pragma solidity =0.7.6;

import './SafeMath.sol';
import './Address.sol';
import '../interface/IERC20.sol';

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.7.6;
interface ISummaSwapV3Manager{
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
        
    function balanceOf(address owner) external view  returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view   returns (uint256);
}

pragma solidity >=0.7.6;
interface ITradeMint{
    function getFee(address current,uint24 fee) external view returns (uint24);
    
    function getRelation(address current) external view returns (address);
    
    function cross(int24 tick,int24 nextTick) external;
    
    function snapshot(address tradeAddress,int24 tick,uint256 liquidityVolumeGrowth,uint256 tradeVolume) external;
    
    function snapshotLiquidity(address tradeAddress,int24 _tickLower,int24 _tickUpper) external;
    
    function getSuperFee() external view returns (uint24);
}

pragma solidity =0.7.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.6.12;

/**
 * @title Owned
 * @notice Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

pragma solidity >=0.7.6;
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

pragma solidity >=0.7.6;

library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

pragma solidity >=0.7.6;
interface ISummaPri{
     function getRelation(address addr) external view returns (address);
     
     
     function hasRole(bytes32 role, address account) external view returns (bool);
     
    
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}