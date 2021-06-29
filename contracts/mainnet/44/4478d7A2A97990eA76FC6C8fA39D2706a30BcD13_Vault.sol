// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Strategies/IStrategy.sol";
import "./lists/RankedList.sol";

import "./library/IterableMap.sol";


contract Vault is ERC20 {
    // Add the library methods
    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableMap for IterableMap.AddressToUintMap;

    //策略总资产
    struct StrategyState {
        uint256 totalAssets;//当前总资产
        uint256 totalDebt;//投入未返还成本
    }

    //协议总资产
    struct ProtocolState {
        uint256 lastReportTime;//计算时间
        uint256 totalAssets;//当前总资产
    }

    //协议APY设置参数
    struct StrategyApy {
        address strategyAddress;//策略地址
        uint256 apy;//策略APY
    }

    //最大百分比100%
    uint256 constant MAX_BPS = 10000;

    //用户提款队列
    IterableMap.AddressToUintMap private userWithdrawMap;

    //用户存款队列
    IterableMap.AddressToUintMap private userDepositMap;

    //策略集合
    EnumerableSet.AddressSet private strategySet;

    //策略状态
    mapping(address => StrategyState) public strategyStates;
    //协议状态
    mapping(uint256 => ProtocolState) public protocolStates;

    //用户存款成本总计，用于计算用户收益
    mapping(address => uint256) public userDebts;

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    mapping (address => bool) public greyList;

    //池子接收的token
    ERC20 public token;
    //池子接收的token的精度，也是池子aToken的精度
    uint8 public myDecimals;

    //池子币种的精度单位，比如精度6，则为10的6次方：1000000
    uint256 public underlyingUnit;

    //精度因子：如果aToken精度为6，则精度因子为10 ** (18-6)；否则精度因子为1
    uint256 public precisionFactor;
    //国库收益地址
    address public rewards;
    //治理方地址
    address public governance;
    //管理者地址
    address public management;
    //定时器账户地址
    address public keeper;
    //收益提成费用
    uint256 public profitManagementFee;
    //每个策略投资金额，不能超过储蓄池的20%
    uint256 public maxPercentPerStrategy;
    //每个协议的所有策略投资金额，不能超过储蓄池的30%
    uint256 public maxPercentPerProtocol;
    //每个策略投资金额，不能超过目标第三方投资池子的20%
    uint256 public maxPercentInvestVault;

    //兑换时允许超出预言机返回汇率的最大百分比,default:2%
    uint256 public maxExchangeRateDeltaThreshold = 200;

    // The minimum number of seconds between doHardWork calls.
    uint256 public minWorkDelay;
    uint256 public lastWorkTime;

    //上次的净值
    uint256 public pricePerShare;

    //上上次的净值
    uint256 public lastPricePerShare;

    uint256 public apy = 0;

    //是否紧急关停
    bool public emergencyShutdown;

    //今天的存款总额，这样不用循环用户存款队列计算总额
    uint256 public todayDepositAmounts;
    //今天的取款份额，这样不用循环用户取款队列计算总额
    uint256 public todayWithdrawShares;

    //所有策略的总资产
    uint256 public strategyTotalAssetsValue;

    /**
    * 限制只能管理员或者治理方可以发起调用
    **/
    modifier onlyGovernance(){
        require(msg.sender == governance || msg.sender == management, "The caller must be management or governance");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == management || msg.sender == governance, 'only keeper');
        _;
    }

    // Only smart contracts will be affected by this modifier
    modifier defense() {
        require((msg.sender == tx.origin) || !greyList[msg.sender], "This smart contract has been grey listed");
        _;
    }

    /**
    * 构建函数
    * @param _token：目前都应该是USDT地址
    * @param _management：管理者地址
    * @param _rewards：国库合约地址
    **/
    constructor(address _token, address _management, address _keeper, address _rewards) ERC20(
        string(abi.encodePacked("PIGGY_", ERC20(_token).name())),
        string(abi.encodePacked("p", ERC20(_token).symbol()))
    ) {
        governance = msg.sender;
        management = _management;
        keeper = _keeper;

        token = ERC20(_token);

        myDecimals = token.decimals();
        require(myDecimals < 256);

        if (myDecimals < 18) {
            precisionFactor = 10 ** (18 - myDecimals);
        } else {
            precisionFactor = 1;
        }
        underlyingUnit = 10 ** myDecimals;
        require(_rewards != address(0), 'rewards: ZERO_ADDRESS');
        rewards = _rewards;

        pricePerShare=underlyingUnit;

        //默认25%的收益管理费
        profitManagementFee = 2500;
        //每个策略投资金额，不能超过储蓄池的20%
        maxPercentPerStrategy = 2000;
        //每个协议的所有策略投资金额，不能超过储蓄池的30%
        maxPercentPerProtocol = 3000;
        //每个策略投资金额，不能超过目标第三方投资池子的20%，则策略投入的资金应该是策略投入前的25%
        maxPercentInvestVault = 2000;

        //最小工作时间间隔
        minWorkDelay = 0;
    }

    function decimals() public view virtual override returns (uint8) {
        return myDecimals;
    }

    function setGovernance(address _governance) onlyGovernance external {
        governance = _governance;
    }

    function setManagement(address _management) onlyGovernance external {
        management = _management;
    }

    function setRewards(address _rewards) onlyGovernance external {
        rewards = _rewards;
    }

    function setProfitManagementFee(uint256 _profitManagementFee) onlyGovernance external {
        require(_profitManagementFee <= MAX_BPS);
        profitManagementFee = _profitManagementFee;
    }

    function setMaxPercentPerStrategy(uint256 _maxPercentPerStrategy) onlyGovernance external {
        require(_maxPercentPerStrategy <= MAX_BPS);
        maxPercentPerStrategy = _maxPercentPerStrategy;
    }

    function setMaxPercentPerProtocole(uint256 _maxPercentPerProtocol) onlyGovernance external {
        require(_maxPercentPerProtocol <= MAX_BPS);
        maxPercentPerProtocol = _maxPercentPerProtocol;
    }

    function setMaxPercentInvestVault(uint256 _maxPercentInvestVault) onlyGovernance external {
        require(_maxPercentInvestVault <= MAX_BPS);
        maxPercentInvestVault = _maxPercentInvestVault;
    }

    function setMinWorkDelay(uint256 _delay) external onlyGovernance {
        minWorkDelay = _delay;
    }

    function setMaxExchangeRateDeltaThreshold(uint256 _threshold) public onlyGovernance {
        require(_threshold <= MAX_BPS);
        maxExchangeRateDeltaThreshold = _threshold;
    }

    function setEmergencyShutdown(bool active) onlyGovernance external {
        emergencyShutdown = active;
    }

    function setKeeper(address keeperAddress) onlyGovernance external {
        keeper = keeperAddress;
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) public onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) public onlyGovernance {
        greyList[_target] = false;
    }

    function totalAssets() public view returns (uint256) {
        return token.balanceOf(address(this)) + strategyTotalAssetsValue;
    }

    //    /**
    //    * 测试临时使用重置Vault
    //    */
    //    function reTestInit() external onlyGovernance () {
    //        //将策略的钱全部取出来
    //        for (uint256 i = 0; i < strategySet.length(); i++)
    //        {
    //            IStrategy(strategySet.at(i)).withdrawToVault(1, 1);
    //            protocolStates[IStrategy(strategySet.at(i)).protocol()].totalAssets =0;
    //            strategyStates[strategySet.at(i)].totalAssets = 0;
    //        }
    //
    //        for (uint256 i = 0; i < userWithdrawMap.length();) {
    //            (address userAddress, uint256 userShares) = userWithdrawMap.at(i);
    //            userWithdrawMap.remove(userAddress);
    //        }
    //
    //        for (uint256 i = 0; i < userDepositMap.length();) {
    //            (address userAddress, uint256 amount) = userDepositMap.at(i);
    //            userDepositMap.remove(userAddress);
    //        }
    //
    //        //上次的净值
    //        pricePerShare=0;
    //        //今天的存款总额，这样不用循环用户存款队列计算总额
    //        todayDepositAmounts=0;
    //        //今天的取款份额，这样不用循环用户取款队列计算总额
    //        todayWithdrawShares=0;
    //        //所有策略的总资产
    //        strategyTotalAssetsValue=0;
    //
    //        token.safeTransfer(rewards, token.balanceOf(address(this)));
    //    }

    /**
    * 返回策略数组
    */
    function strategies() external view returns (address[] memory) {
        address[] memory strategyArray = new address[](strategySet.length());
        for (uint256 i = 0; i < strategySet.length(); i++)
        {
            strategyArray[i] = strategySet.at(i);
        }
        return strategyArray;
    }

    /**
    * 返回策略资产
    */
    function strategyState(address strategyAddress) external view returns (StrategyState memory) {
        return strategyStates[strategyAddress];
    }

    /**
    * 设置策略APY
    */
    function setApys(StrategyApy[] memory strategyApys) external onlyKeeper {
        for (uint i = 0; i < strategyApys.length; i++) {
            StrategyApy memory strategyApy = strategyApys[i];
            if (strategySet.contains(strategyApy.strategyAddress) && strategyStates[strategyApy.strategyAddress].totalAssets <= 0) {
                IStrategy(strategyApy.strategyAddress).updateApy(strategyApy.apy);
            }
        }
    }

    /**
    * 地址to使用amount的token，换取了返回的shares量的股份凭证
    */
    function _issueSharesForAmount(address to, uint256 amount) internal returns (uint256) {
        uint256 shares = 0;
        //如果昨天没有净值价格，则为第一次doHardWork之前的投入，1：1
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            require(pricePerShare != 0);
            //            shares = amount.mul(totalSupply()).div(totalAssets() - todayDepositAmounts);
            shares = amount.mul(underlyingUnit).div(pricePerShare);
        }
        _mint(to, shares);
        return shares;
    }

    /**
    * 转账时，同时转移用户成本
    **/
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override
    {


        super._beforeTokenTransfer(from, to, amount);
        //用户之间转账的时候，需要将成本也随之移动
        if(from != address(0) && to!= address(0)){
            uint256 transferDebt = userDebts[from].mul(balanceOf(from)).div(amount);

            if(transferDebt>userDebts[from]){
                transferDebt = userDebts[from];
            }
            userDebts[from] -= transferDebt;
            userDebts[to] += transferDebt;


        }
    }

    /**
     * 存款，当前只是加入存款队列，每日定时任务处理分派份额
     * @param _amount：目前都应该是USDT数量
     **/
    function deposit(uint256 _amount) external defense {
        require(_amount > 0, "amount should more than 0");
        require(emergencyShutdown == false, "vault has been emergency shutdown");
        userDepositMap.plus(msg.sender, _amount);
        todayDepositAmounts += _amount;
        token.safeTransferFrom(msg.sender, address(this), _amount);

    }

    /**
     * 计算shares份额当前价值多少token
     * @param shares：份额
     **/
    function _shareValue(uint256 shares) internal view returns (uint256) {
        if (totalSupply() == 0) {
            return shares;
        }
        //return shares.mul(totalAssets() - todayDepositAmounts).div(totalSupply());
        return shares.mul(pricePerShare).div(underlyingUnit);
    }

    /**
     * 取款，当前只是加入取款队列，每日定时任务处理取款
     * @param shares：份额
     **/
    function withdraw(uint256 shares) external {
        require(shares > 0, "amount should more than 0");
        require(emergencyShutdown == false, "vault has been emergency shutdown");
        require(shares <= balanceOf(msg.sender), "can not withdraw more than user total");
        userWithdrawMap.plus(msg.sender, shares);
        todayWithdrawShares += shares;
        require(userWithdrawMap.get(msg.sender) <= balanceOf(msg.sender));
    }

    /**
     * 还未处理的用户存款
     * @return USDT 存款USDT数量
     **/
    function inQueueDeposit(address userAddress) public view returns (uint256) {
        return userDepositMap.get(userAddress);
    }

    /**
     * 用户还未赎回的成本
     * @return USDT 成本存款USDT数量
     **/
    function userDebt(address userAddress) public view returns (uint256) {
        return userDebts[userAddress];
    }

    /**
     * 还未处理的用户提取份额
     * @return share 提取的share数量
     **/
    function inQueueWithdraw(address userAddress) public view returns (uint256) {
        return userWithdrawMap.get(userAddress);
    }

    //    /**
    //     * 每个份额等于多少的USDT，基于上一次的hardWork结果
    //     **/
    //    function getPricePerShare() public view returns (uint256) {
    //        return _shareValue(10 ** myDecimals);
    //    }

    /**
     * 添加策略
     **/
    function addStrategy(address strategy) onlyGovernance external {
        require(emergencyShutdown == false, "vault has been emergency shutdown");
        require(strategy != address(0), "strategy address can't be 0");
        require(strategySet.contains(strategy) == false, "strategy already exists");
        require(IStrategy(strategy).vault() == address(this), "strategy's vault error");
        require(IStrategy(strategy).want() == address(token), "strategy's token doesn't match");

        strategySet.add(strategy);
        strategyStates[strategy] = StrategyState({
        totalAssets : 0,
        totalDebt : 0
        });
    }

    /**
     * 移除策略
     **/
    function removeStrategy(address strategy) onlyGovernance external {
        require(strategySet.contains(strategy) == true, "strategy not exists");

        strategySet.remove(strategy);

        uint256 strategyTotalAssets = strategyStates[strategy].totalAssets;
        strategyTotalAssetsValue -= strategyTotalAssets;
        protocolStates[IStrategy(strategy).protocol()].totalAssets -= strategyTotalAssets;
        strategyStates[strategy].totalAssets = 0;

        //将策略的钱全部取回Vault
        (uint256 value, uint256 partialClaimValue, uint256 claimValue) = IStrategy(strategy).withdrawToVault(1, 1);
        uint256 strategyActualTotal = value + claimValue;
        if (strategyStates[strategy].totalDebt <= strategyActualTotal) {
            strategyStates[strategy].totalDebt = 0;
        } else {
            strategyStates[strategy].totalDebt -= strategyActualTotal;
        }
    }

    /**
     * 策略迁移
     **/
    function migrateStrategy(address oldVersion, address newVersion) onlyGovernance external {
        require(newVersion != address(0), "strategy address can't be 0");
        require(strategySet.contains(oldVersion) == true, "strategy will be migrate doesn't exists");
        require(strategySet.contains(newVersion) == false, "new strategy already exists");

        StrategyState memory strategy = strategyStates[oldVersion];
        strategyStates[oldVersion].totalAssets = 0;
        strategyStates[oldVersion].totalDebt = 0;

        protocolStates[IStrategy(oldVersion).protocol()].totalAssets -= strategy.totalAssets;

        strategyStates[newVersion] = StrategyState({
        totalAssets : strategy.totalAssets,
        totalDebt : strategy.totalDebt
        });

        protocolStates[IStrategy(newVersion).protocol()].totalAssets += strategy.totalAssets;

        IStrategy(oldVersion).migrate(newVersion);

        strategySet.add(newVersion);
        strategySet.remove(oldVersion);

    }

    //计算策略是否超出它的贷款限额，并且返回应该提取多少金额返回给池子
    function _calDebt(address strategy,uint256 vaultAssetsLimit,uint256 protocolDebtLimit) internal view returns (uint256 debt) {
        //策略当前已投入资产
        uint256 strategyTotalAssets = strategyStates[strategy].totalAssets;



        //不超过策略投资池子总资金量的20%
        uint256 invest_vault_assets_limit = IStrategy(strategy).getInvestVaultAssets().mul(maxPercentInvestVault).div(MAX_BPS);


        //协议下所有策略总投资资金不超过总资金的30%

        //本策略协议的已投资总资金
        uint256 protocol_debt = protocolStates[IStrategy(strategy).protocol()].totalAssets;

        uint256 strategy_protocol_limit = protocolDebtLimit;
        //如果超出协议资金的30%，则返还可返还的超出部分，然后和上面那个应该返还的，取应该返还的大值
        if (protocol_debt > protocolDebtLimit) {
            //协议还需要退还多少资金
            uint256 shouldProtocolReturn = protocol_debt - protocolDebtLimit;

            //排除本策略资金，其他策略占了多少资金
            uint256 other_strategy_debt = protocol_debt - strategyTotalAssets;

            //如果其他协议加起来，还是超过限制，则超出部分，本策略退还
            if (shouldProtocolReturn > other_strategy_debt) {
                strategy_protocol_limit = strategyTotalAssets - (shouldProtocolReturn - other_strategy_debt);

            }
            //如果后面低APY的协议资金够抽取，则本策略不提取；
        }
        uint256 strategy_limit = Math.min(strategy_protocol_limit, Math.min(vaultAssetsLimit, invest_vault_assets_limit));

        if (strategy_limit > strategyTotalAssets) {
            return 0;
        } else {
            return (strategyTotalAssets - strategy_limit);
        }
    }

    //计算策略是否超出它的贷款限额，并且返回应该提取多少金额返回给池子
    function _calCredit(address strategy,uint256 vaultAssetsLimit,uint256 protocolDebtLimit) internal view returns (uint256 credit) {

        //        //如果紧急情况，全部返还
        //        if (emergencyShutdown) {
        //            return 0;
        //        }

        //策略当前已投入资产
        uint256 strategyTotalAssets = strategyStates[strategy].totalAssets;



        if (strategyTotalAssets >= vaultAssetsLimit) {
            return 0;
        }

        //不超过策略投资池子总资金量的20%
        uint256 invest_vault_assets_limit = IStrategy(strategy).getInvestVaultAssets().mul(maxPercentInvestVault).div(MAX_BPS);


        if (strategyTotalAssets >= invest_vault_assets_limit) {
            return 0;
        }

        //协议下所有策略总投资资金不超过总资金的30%

        //本策略协议的已投资总资金
        uint256 protocol_debt = protocolStates[IStrategy(strategy).protocol()].totalAssets;

        //如果超出协议资金的30%，则返还可返还的超出部分，然后和上面那个应该返还的，取应该返还的大值
        if (protocol_debt >= protocolDebtLimit) {
            return 0;
        }
        uint256 strategy_limit = Math.min((protocolDebtLimit - protocol_debt), Math.min((vaultAssetsLimit - strategyTotalAssets), (invest_vault_assets_limit - strategyTotalAssets)));

        return strategy_limit;
    }

    /**
     * 每日工作的定时任务
     **/
    function doHardWork() onlyKeeper external {
        require(emergencyShutdown == false, "vault has been emergency shutdown");
        uint256 now = block.timestamp;
        require(now.sub(lastWorkTime) >= minWorkDelay, "Should not trigger if not waited long enough since previous doHardWork");

        //1. 先办理未处理的提款
        //根据用户要提取的份额，策略提取出的总金额
        uint256 strategyWithdrawForUserValue = 0;
        //策略用户提取后的总资产，需要重新算
        uint256 newStrategyTotalAssetsValue = 0;
        //按APY对策略进行排序
        RankedList sortedStrategies = new RankedList();
        //策略归属协议的资产也需要重算
        uint256 reportTime = block.timestamp;


        //在从策略提取钱之前，先计算余额多少
        uint256 userWithdrawBalanceTotal = totalSupply() == 0 ? 0 : (token.balanceOf(address(this)) - todayDepositAmounts).mul(todayWithdrawShares).div(totalSupply());

        for (uint256 i = 0; i < strategySet.length(); i++)
        {
            address strategy = strategySet.at(i);
            IStrategy strategyInstant = IStrategy(strategy);

            uint256 strategyWithdrawValue;
            uint256 value;
            uint256 partialClaimValue;
            uint256 claimValue;
            //先进行用户取款
            if (todayWithdrawShares > 0) {
                (value, partialClaimValue, claimValue) = strategyInstant.withdrawToVault(todayWithdrawShares, totalSupply());

            } else {
                //用户取款为0，那就需要手动百分之一，用来评估策略当前净值
                (value, partialClaimValue, claimValue) = strategyInstant.withdrawToVault(1, 100);

            }

            strategyWithdrawValue = value + claimValue;

            strategyWithdrawForUserValue += (value + partialClaimValue);

            //计算用户取款后的策略资产
            uint strategyAssets = strategyInstant.estimatedTotalAssets();

            strategyStates[strategy].totalAssets = strategyAssets;

            if (strategyWithdrawValue > strategyStates[strategy].totalDebt) {
                strategyStates[strategy].totalDebt = 0;
            } else {
                strategyStates[strategy].totalDebt -= strategyWithdrawValue;
            }

            uint256 protocol = strategyInstant.protocol();
            if (protocolStates[protocol].lastReportTime == reportTime) {
                protocolStates[protocol].totalAssets += strategyAssets;
            } else {
                protocolStates[protocol].lastReportTime = reportTime;
                protocolStates[protocol].totalAssets = strategyAssets;
            }


            //评估用户提款后的策略总资产
            newStrategyTotalAssetsValue += strategyAssets;

            //根据策略APY维护排序队列,进行投资
            sortedStrategies.insert(uint256(strategyInstant.apy()), strategy);
        }
        strategyTotalAssetsValue = newStrategyTotalAssetsValue;
        //计算token净值
        lastPricePerShare = pricePerShare;
        pricePerShare = totalSupply() == 0 ? underlyingUnit : (totalAssets() - todayDepositAmounts).mul(underlyingUnit).div(totalSupply());


        if(pricePerShare>lastPricePerShare){
            apy = (pricePerShare-lastPricePerShare).mul(31536000).mul(1e4).div(now-lastWorkTime).div(lastPricePerShare);
        }else{
            apy=0;
        }


        uint256 userWithdrawTotal = strategyWithdrawForUserValue + userWithdrawBalanceTotal;

        //净值增长，表示有收益
        uint256 totalProfitFee = 0;
        for (uint256 i = 0; i < userWithdrawMap.length();) {
            (address userAddress, uint256 userShares) = userWithdrawMap.at(i);

            //用户按成本应该提取的金额
            uint256 userCost= userDebts[userAddress].mul(userShares).div(balanceOf(userAddress));

            //用户现在实际提取的金额
            uint256 toUserAll = userWithdrawTotal.mul(userShares).div(todayWithdrawShares);

            //如果有收益，提取25%
            if (toUserAll > userCost) {
                uint256 profitFee = ((toUserAll - userCost).mul(profitManagementFee).div(MAX_BPS));

                totalProfitFee += profitFee;
                toUserAll -= profitFee;
                userDebts[userAddress] -= userCost;
            } else {

                userDebts[userAddress] -= toUserAll;
            }
            _burn(userAddress, userShares);
            //用户份额都提取完，则成本重置为0
            if(balanceOf(userAddress)==0){
                userDebts[userAddress]=0;
            }

            token.safeTransfer(userAddress, toUserAll);
            userWithdrawMap.remove(userAddress);
        }
        if (totalProfitFee > 0) {

            token.safeTransfer(rewards, totalProfitFee);
        }
        todayWithdrawShares = 0;
        //如果紧急关闭，不做hardWork，储蓄池可以调用removeStrategy移除策略
        //        if (emergencyShutdown) {

        //            //3. 返还未处理的存款
        //            for (uint256 i = 0; i < userDepositMap.length();) {
        //                (address userAddress, uint256 amount) = userDepositMap.at(i);
        //                token.safeTransfer(userAddress, amount);
        //                userDepositMap.remove(userAddress);
        //            }
        //            todayDepositAmounts = 0;
        //        } else {

        //3. 办理未处理的存款，包括提取收益
        //给用户按上次的token净值，分派shares
        for (uint256 i = 0; i < userDepositMap.length();) {
            (address userAddress, uint256 amount) = userDepositMap.at(i);
            userDebts[userAddress] += amount;
            uint shares = _issueSharesForAmount(userAddress, amount);

            userDepositMap.remove(userAddress);
        }
        todayDepositAmounts = 0;


        uint256 vaultTotalAssets = totalAssets();

        //不超过总投资资金的20%
        uint256 vaultAssetsLimit = vaultTotalAssets.mul(maxPercentPerStrategy).div(MAX_BPS);
        uint256 protocolDebtLimit = vaultTotalAssets.mul(maxPercentPerProtocol).div(MAX_BPS);
        //4. 办理策略超额调整
        uint256 strategyPosition = 0;
        uint256 nextId = sortedStrategies.head();
        while (nextId != 0) {
            (uint256 id, uint256 next, uint256 prev, uint256 rank, address strategy) = sortedStrategies.get(nextId);

            //计算策略需要返还vault的金额
            uint256 debt = _calDebt(strategy,vaultAssetsLimit,protocolDebtLimit);

            if (debt > 0) {
                uint256 debtReturn = IStrategy(strategy).cutOffPosition(debt);
                strategyStates[strategy].totalAssets -= debt;
                if (debtReturn > strategyStates[strategy].totalDebt) {
                    strategyStates[strategy].totalDebt = 0;
                } else {
                    strategyStates[strategy].totalDebt -= debtReturn;
                }

                protocolStates[IStrategy(strategy).protocol()].totalAssets -= debt;
                strategyTotalAssetsValue -= debt;

            }
            nextId = next;
            strategyPosition++;
        }

        //5. 办理策略补充资金及投资

        strategyPosition = 0;
        nextId = sortedStrategies.head();
        while (nextId != 0) {
            //没有钱可以投了，就退出
            uint256 vault_balance = token.balanceOf(address(this));

            if (vault_balance <= 0) {

                break;
            }

            (uint256 id, uint256 next, uint256 prev, uint256 rank, address strategy) = sortedStrategies.get(nextId);

            uint256 calCredit = _calCredit(strategy,vaultAssetsLimit,protocolDebtLimit);
            if (calCredit > 0) {
                //计算策略最多可从vault中取走的金额
                uint256 credit = Math.min(calCredit, token.balanceOf(address(this)));

                if (credit > 0) {
                    strategyStates[strategy].totalAssets += credit;
                    strategyStates[strategy].totalDebt += credit;
                    protocolStates[IStrategy(strategy).protocol()].totalAssets += credit;
                    token.safeTransfer(strategy, credit);
                    strategyTotalAssetsValue += credit;



                    //调用策略的invest()开始工作
                    IStrategy(strategy).invest();
                }
            }

            nextId = next;
            strategyPosition++;
        }

        //        }
        lastWorkTime = now;
    }

    /**
     * 治理者可以将错发到本合约的其他货币，转到自己的账户下
     * @param _token：其他货币地址
     **/
    function sweep(address _token) onlyGovernance external {
        require(_token != address(token));
        uint256 value = token.balanceOf(address(this));
        token.safeTransferFrom(address(this), msg.sender, value);
    }

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity >=0.5.17 <0.8.4;

interface IStrategy {

    //该策略属于的协议类型
    function protocol() external view returns (uint256);

    //该策略需要的token地址
    function want() external view returns (address);

    function name() external view returns (string memory);
    // 获取该策略对应池的apy
    function apy() external view returns (uint256);
    // 更新该策略对应池apy，留给keeper调用
    function updateApy(uint256 _apy) external;
    //该策略的vault地址
    function vault() external view returns (address);

    //    function deposit(uint256 mount) external;

    //需要提取指定数量的token,返回提取导致的loss数量token
    function withdraw(uint256 _amount) external returns (uint256);

    //计算策略的APY
    function calAPY() external returns (uint256);

    //该策略所有的资产（priced in want）
    function estimatedTotalAssets() external view returns (uint256);

    //策略迁移
    function migrate(address _newStrategy) external;

    //查看策略投资池子的总数量（priced in want）
    function getInvestVaultAssets() external view returns (uint256);

    /**
    * correspondingShares：待提取xToken数
    * totalShares：总xToken数
    **/
    function withdrawToVault(uint256 correspondingShares, uint256 totalShares) external returns  (uint256 value, uint256 partialClaimValue, uint256 claimValue) ;

    /**
    * 无人提取时，通过调用该方法计算策略净值
    **/
    function withdrawOneToken() external returns  (uint256 value, uint256 partialClaimValue, uint256 claimValue);



    /**
    * 退回超出部分金额
    **/
    function cutOffPosition(uint256 _debtOutstanding) external returns (uint256);

    /**
    * 将空置资金进行投资
    **/
    function invest() external;
}

pragma solidity ^0.8.0;


/**
 * @title RankedList
 * @dev Doubly linked list of ranked objects. The head will always have the highest rank and
 * elements will be ordered down towards the tail.
 * @author Alberto Cuesta Cañada
 */
contract RankedList {

    event ObjectCreated(uint256 id, uint256 rank, address data);
    event ObjectsLinked(uint256 prev, uint256 next);
    event ObjectRemoved(uint256 id);
    event NewHead(uint256 id);
    event NewTail(uint256 id);

    struct Object{
        uint256 id;
        uint256 next;
        uint256 prev;
        uint256 rank;
        address data;
    }

    uint256 public head;
    uint256 public tail;
    uint256 public idCounter;
    mapping (uint256 => Object) public objects;

    /**
     * @dev Creates an empty list.
     */
    constructor() public {
        head = 0;
        tail = 0;
        idCounter = 1;
    }

    /**
     * @dev Retrieves the Object denoted by `_id`.
     */
    function get(uint256 _id)
    public
    virtual
    view
    returns (uint256, uint256, uint256, uint256, address)
    {
        Object memory object = objects[_id];
        return (object.id, object.next, object.prev, object.rank, object.data);
    }

    /**
     * @dev Return the id of the first Object with a lower or equal rank, starting from the head.
     */
    function findRank(uint256 _rank)
    public
    virtual
    view
    returns (uint256)
    {
        Object memory object = objects[head];
        while (object.rank > _rank) {
            object = objects[object.next];
        }
        return object.id;
    }

    /**
     * @dev Insert the object immediately before the one with the closest lower rank.
     * WARNING: This method loops through the whole list before inserting, and therefore limits the
     * size of the list to a few tens of thousands of objects before becoming unusable. For a scalable
     * contract make _insertBefore public but check prev and next on insertion.
     */
    function insert(uint256 _rank, address _data)
    public
    virtual
    {
        uint256 nextId = findRank(_rank);
        if (nextId == 0) {
            _addTail(_rank, _data);
        }
        else {
            _insertBefore(nextId, _rank, _data);
        }
    }

    /**
     * @dev Remove the Object denoted by `_id` from the List.
     */
    function remove(uint256 _id)
    public
    virtual
    {
        Object memory removeObject = objects[_id];
        if (head == _id && tail == _id) {
            _setHead(0);
            _setTail(0);
        }
        else if (head == _id) {
            _setHead(removeObject.next);
            objects[removeObject.next].prev = 0;
        }
        else if (tail == _id) {
            _setTail(removeObject.prev);
            objects[removeObject.prev].next = 0;
        }
        else {
            _link(removeObject.prev, removeObject.next);
        }
        delete objects[removeObject.id];
        emit ObjectRemoved(_id);
    }

    /**
     * @dev Insert a new Object as the new Head with `_data` in the data field.
     */
    function _addHead(uint256 _rank, address _data)
    internal
    {
        uint256 objectId = _createObject(_rank, _data);
        _link(objectId, head);
        _setHead(objectId);
        if (tail == 0) _setTail(objectId);
    }

    /**
     * @dev Insert a new Object as the new Tail with `_data` in the data field.
     */
    function _addTail(uint256 _rank, address _data)
    internal
    {
        if (head == 0) {
            _addHead(_rank, _data);
        }
        else {
            uint256 objectId = _createObject(_rank, _data);
            _link(tail, objectId);
            _setTail(objectId);
        }
    }

    /**
     * @dev Insert a new Object after the Object denoted by `_id` with `_data` in the data field.
     */
    function _insertAfter(uint256 _prevId, uint256 _rank, address _data)
    internal
    {
        if (_prevId == tail) {
            _addTail(_rank, _data);
        }
        else {
            Object memory prevObject = objects[_prevId];
            Object memory nextObject = objects[prevObject.next];
            uint256 newObjectId = _createObject(_rank, _data);
            _link(newObjectId, nextObject.id);
            _link(prevObject.id, newObjectId);
        }
    }

    /**
     * @dev Insert a new Object before the Object denoted by `_id` with `_data` in the data field.
     */
    function _insertBefore(uint256 _nextId, uint256 _rank, address _data)
    internal
    {
        if (_nextId == head) {
            _addHead(_rank, _data);
        }
        else {
            _insertAfter(objects[_nextId].prev, _rank, _data);
        }
    }

    /**
     * @dev Internal function to update the Head pointer.
     */
    function _setHead(uint256 _id)
    internal
    {
        head = _id;
        emit NewHead(_id);
    }

    /**
     * @dev Internal function to update the Tail pointer.
     */
    function _setTail(uint256 _id)
    internal
    {
        tail = _id;
        emit NewTail(_id);
    }

    /**
     * @dev Internal function to create an unlinked Object.
     */
    function _createObject(uint256 _rank, address _data)
    internal
    returns (uint256)
    {
        uint256 newId = idCounter;
        idCounter += 1;
        Object memory object = Object(
            newId,
            0,
            0,
            _rank,
            _data
        );
        objects[object.id] = object;
        emit ObjectCreated(
            object.id,
            object.rank,
            object.data
        );
        return object.id;
    }

    /**
     * @dev Internal function to link an Object to another.
     */
    function _link(uint256 _prevId, uint256 _nextId)
    internal
    {
        if (_prevId != 0 && _nextId != 0) {
            objects[_prevId].next = _nextId;
            objects[_nextId].prev = _prevId;
            emit ObjectsLinked(_prevId, _nextId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library IterableMap {

    using EnumerableSet for EnumerableSet.AddressSet;

    struct Map {
        // Storage of keys
        EnumerableSet.AddressSet _keys;

        mapping (address => uint256) _values;
    }

    /**
    * @dev Adds a key-value pair to a map, or updates the value for an existing
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _set(Map storage map, address key, uint256 value) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
    * @dev plus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _plus(Map storage map, address key, uint256 value) private {
        map._values[key] += value;
        map._keys.add(key);
    }

    /**
    * @dev minus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _minus(Map storage map, address key, uint256 value) private {
        map._values[key] -= value;
        map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, address key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, address key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (address, uint256) {
        address key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, address key) private view returns (uint256) {
        uint256 value = map._values[key];
        return value;
    }
    
    struct AddressToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    /**
    * @dev plus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function plus(AddressToUintMap storage map, address key, uint256 value) internal {
        return _plus(map._inner, key, value);
    }

    /**
    * @dev minus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function minus(AddressToUintMap storage map, address key, uint256 value) internal {
        return _minus(map._inner, key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return _get(map._inner, key);
    }
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
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