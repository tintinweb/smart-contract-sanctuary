//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface/ICoinDeedFactory.sol";
import "./interface/ICoinDeedDeployer.sol";
import "./CoinDeed.sol";

contract CoinDeedDeployer is ICoinDeedDeployer {
    function deploy(
        address manager,
        address coinDeedAddressesProvider,
        uint256 stakingAmount,
        ICoinDeed.Pair memory pair,
        ICoinDeed.DeedParameters memory deedParameters,
        ICoinDeed.ExecutionTime memory executionTime,
        ICoinDeed.RiskMitigation memory riskMitigation,
        ICoinDeed.BrokerConfig memory brokerConfig
    ) external override returns (address) {

        CoinDeed coinDeed = new CoinDeed(
            manager,
            coinDeedAddressesProvider,
            stakingAmount,
            pair,
            deedParameters,
            executionTime,
            riskMitigation,
            brokerConfig
        );
        return address(coinDeed);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeed.sol";

interface ICoinDeedFactory {


    event DeedCreated(
        uint256 indexed id,
        address indexed deedAddress,
        address indexed manager
    );

    event StakeAdded(
        address indexed coinDeed,
        address indexed broker,
        uint256 indexed amount
    );

    event StateChanged(
        address indexed coinDeed,
        ICoinDeed.DeedState state
    );

    event DeedCanceled(
        address indexed coinDeed,
        address indexed deedAddress
    );

    event SwapExecuted(
        address indexed coinDeed,
        uint256 indexed tokenBought
    );

    event BuyIn(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event ExitDeed(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event PayOff(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event LeverageChanged(
        address indexed coinDeed,
        address indexed salePercentage
    );

    event BrokersEnabled(
        address indexed coinDeed
    );

    /**
    * DeedManager calls to create deed contract
    */
    function createDeed(ICoinDeed.Pair calldata pair,
        uint256 stakingAmount,
        uint256 wholesaleId,
        ICoinDeed.DeedParameters calldata deedParameters,
        ICoinDeed.ExecutionTime calldata executionTime,
        ICoinDeed.RiskMitigation calldata riskMitigation,
        ICoinDeed.BrokerConfig calldata brokerConfig) external;

    /**
    * Returns number of Open deeds to able to browse them
    */
    function openDeedCount() external view returns (uint256);

    /**
    * Returns number of completed deeds to able to browse them
    */
    function completedDeedCount() external view returns (uint256);

    /**
    * Returns number of pending deeds to able to browse them
    */
    function pendingDeedCount() external view returns (uint256);

    function setMaxLeverage(uint8 _maxLeverage) external;

    function setStakingMultiplier(uint256 _stakingMultiplier) external;

    function permitToken(address token) external;

    function unpermitToken(address token) external;

    // All the important addresses
    function getCoinDeedAddressesProvider() external view returns (address);

    // The maximum leverage that any deed can have
    function maxLeverage() external view returns (uint8);

    // The fee the platform takes from all buyins before the swap
    function platformFee() external view returns (uint256);

    // The amount of stake needed per dollar value of the buyins
    function stakingMultiplier() external view returns (uint256);

    // The maximum proportion relative price can drop before a position becomes insolvent is 1/leverage.
    // The maximum price drop a deed can list risk mitigation with is maxPriceDrop/leverage
    function maxPriceDrop() external view returns (uint256);

    function liquidationBonus() external view returns (uint256);

    function setPlatformFee(uint256 _platformFee) external;

    function setMaxPriceDrop(uint256 _maxPriceDrop) external;

    function setLiquidationBonus(uint256 _liquidationBonus) external;

    function managerDeedCount(address manager) external view returns (uint256);

    function emitStakeAdded(
        address broker,
        uint256 amount
    ) external;

    function emitStateChanged(
        ICoinDeed.DeedState state
    ) external;

    function emitDeedCanceled(
        address deedAddress
    ) external;

    function emitSwapExecuted(
        uint256 tokenBought
    ) external;

    function emitBuyIn(
        address buyer,
        uint256 amount
    ) external;

    function emitExitDeed(
        address buyer,
        uint256 amount
    ) external;

    function emitPayOff(
        address buyer,
        uint256 amount
    ) external;

    function emitLeverageChanged(
        address salePercentage
    ) external;

    function emitBrokersEnabled() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeedFactory.sol";

interface ICoinDeedDeployer {

    function deploy(
        address manager,
        address coinDeedAddressesProvider,
        uint256 stakingAmount,
        ICoinDeed.Pair memory pair,
        ICoinDeed.DeedParameters memory deedParameters,
        ICoinDeed.ExecutionTime memory executionTime,
        ICoinDeed.RiskMitigation memory riskMitigation,
        ICoinDeed.BrokerConfig memory brokerConfig
    ) external returns (address);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface/ICoinDeed.sol";
import "./interface/IOracle.sol";
import "./interface/ILendingPool.sol";
import "./interface/ICoinDeedFactory.sol";
import "./interface/IWholesaleFactory.sol";
import "./interface/ICoinDeedDAO.sol";
import "./interface/ICoinDeedAddressesProvider.sol";
import "./libraries/CoinDeedAddressesProviderUtils.sol";
import "./libraries/CoinDeedUtils.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CoinDeed is ICoinDeed, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant BASE_DENOMINATOR = 10_000;
    bytes32 public constant MANAGER = keccak256("MANAGER");
    // TODO
    address internal constant USDT_ADDRESS = 0xd35d2e839d888d1cDBAdef7dE118b87DfefeD20e;

    address public WETH;
    address public manager;
    uint256 public totalManagementFee;
    uint256 public totalSupply;
    uint256 public totalReturn;
    uint256 public totalStake;
    uint256 public totalFeeClaimed;
    uint256 public wholesaleId;
    uint256 public totalTokenB;
    bool public riskMitigationTriggered;

    ICoinDeedAddressesProvider coinDeedAddressesProvider;
    IUniswapV2Router01 public uniswapRouter1;
    ICoinDeedFactory public coinDeedFactory;
    Pair public pair;
    ExecutionTime public executionTime;
    DeedParameters public deedParameters;
    RiskMitigation public riskMitigation;
    BrokerConfig public brokerConfig;
    IERC20 private deedToken;
    DeedState public state;
    ILendingPool public lendingPool;
    ICoinDeedDAO public dao;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public feeClaimed;
    mapping(address => uint256) public buyIns;

    constructor(
        address manager_,
        address coinDeedAddressesProvider_,
        uint256 stakingAmount_,
        Pair memory pair_,
        DeedParameters memory deedParameters_,
        ExecutionTime memory executionTime_,
        RiskMitigation memory riskMitigation_,
        BrokerConfig memory brokerConfig_) {

        coinDeedAddressesProvider = ICoinDeedAddressesProvider(coinDeedAddressesProvider_);
        uniswapRouter1 = IUniswapV2Router01(coinDeedAddressesProvider.swapRouter());
        WETH = uniswapRouter1.WETH();

        _setupRole(MANAGER, manager_);
        _setRoleAdmin(MANAGER, DEFAULT_ADMIN_ROLE);

        coinDeedFactory = ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory());
        lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        deedToken = IERC20(coinDeedAddressesProvider.deedToken());
        dao = ICoinDeedDAO(coinDeedAddressesProvider.dao());
        manager = manager_;
        pair = pair_;

        _edit(deedParameters_);
        _editExecutionTime(executionTime_);
        _editRiskMitigation(riskMitigation_);
        brokerConfig = brokerConfig_;

        state = DeedState.SETUP;
        _stake(manager, stakingAmount_);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    function _onlyInState(DeedState state_) private view {
        require(state == state_, "Deed is not in correct state.");
    }

    function _onlyInStates(DeedState[2] memory states)  private view  {

        bool found = false;

        for (uint i = 0; i < states.length; i++) {
            if (state == states[i]) {
                found = true;
            }
        }
        require(found, "Deed is not in correct state.");
    }

    modifier onlyInState(DeedState state_) {
        _onlyInState(state_);
        _;
    }


    modifier onlyInStates(DeedState[2] memory states) {
        _onlyInStates(states);
        _;
    }

    function reserveWholesale(uint256 saleId) external override {
        require(msg.sender == address(coinDeedFactory) || msg.sender == manager, "Only Deed manager or factory it self can reserve a wholesale.");

        IWholesaleFactory wholesaleFactory = IWholesaleFactory(coinDeedAddressesProvider.wholesaleFactory());
        IWholesaleFactory.Wholesale memory wholesale = wholesaleFactory.getWholesale(saleId);

        require(wholesale.tokenOffered == pair.tokenB, "Offered token in wholesale does not match with the deed.");
        require(wholesale.tokenRequested == pair.tokenA, "Requested token in wholesale does not match with the deed.");
        require(wholesale.minSaleAmount <= deedParameters.deedSize, "minSaleAmount is bigger then the deedsize.");

        wholesaleFactory.reserveWholesale(saleId);
        wholesaleId = saleId;
    }

    function _checkIfDeedIsReady() internal {
        // Provide address provider to allow calculations with oracle
        if (CoinDeedAddressesProviderUtils.readyCheck(
            coinDeedAddressesProvider,
            pair.tokenA,
            totalStake,
            coinDeedFactory.stakingMultiplier(),
            deedParameters.deedSize / deedParameters.leverage))
        {
            state = DeedState.READY;
            coinDeedFactory.emitStateChanged(state);
        }
    }

    function _stake(address supplier, uint256 amount) internal {
        stakes[supplier] = stakes[supplier] + amount;
        totalStake += amount;
        coinDeedFactory.emitStakeAdded(supplier, amount);
        _checkIfDeedIsReady();
    }

    function _managerOrBrokerEnabled() private view {
        require(msg.sender == manager || brokerConfig.allowed, "Brokers are not allowed.");
    }

    function stake(uint256 amount) onlyInState(DeedState.SETUP) external override {
        _managerOrBrokerEnabled();
        deedToken.safeTransferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, amount);
    }

    function editBrokerConfig(BrokerConfig memory brokerConfig_) onlyRole(MANAGER) onlyInState(DeedState.SETUP) public override {
        _editBrokerConfig(brokerConfig_);
    }

    function editRiskMitigation(RiskMitigation memory riskMitigation_) onlyRole(MANAGER) onlyInState(DeedState.SETUP) public override {
        _editRiskMitigation(riskMitigation_);
    }

    function editExecutionTime(ExecutionTime memory executionTime_) onlyRole(MANAGER) onlyInState(DeedState.SETUP) public override {
        _editExecutionTime(executionTime_);
    }

    function editBasicInfo(uint256 deedSize_, uint8 leverage_, uint256 managementFee_, uint256 minimumBuy_) onlyRole(MANAGER) onlyInState(DeedState.SETUP) public override {
        require(totalStake == stakes[msg.sender], "Can not be changed with broker");
        _edit(deedSize_, leverage_, managementFee_, minimumBuy_);

    }

    function exitDeed() onlyInState(DeedState.OPEN) public override {
        uint256 buyerLoan = loanInfo(msg.sender);
        uint256 buyIn_ = buyIns[msg.sender];
        // buyIns[msg.sender] = 0;
        // uint256 exitAmount = 0;
        // if (totalSupply > 0) {
        //     exitAmount = totalTokenB * buyIn_ / totalSupply;
        // }

        // todo: need a function in lending pool to check current balance
        //lendingPool.withdraw(pair.tokenB, exitAmount);

        // uint256 totalTokenB = tokenBBalance();
        uint256 exitAmount = totalTokenB * buyIn_ / totalSupply;
        if (exitAmount > totalTokenB) {
            // exitAmount = exitAmount;
            exitAmount = totalTokenB;
        }
        // todo: need a function in lending pool to check current balance
        // lendingPool.withdraw(pair.tokenB, exitAmount);
        // _transfer(pair.tokenB, payable(msg.sender), exitAmount);
        totalTokenB = totalTokenB - exitAmount;

        totalSupply -= buyIn_;
        buyIns[msg.sender] = 0;

        uint256 tokenAForBuyer = exitAmount > 0 ? _sell(exitAmount) : 0;

        if (buyerLoan > 0) {
            _repay(buyerLoan);
        }

        _transfer(pair.tokenA, payable(msg.sender), tokenAForBuyer - buyerLoan);
        coinDeedFactory.emitExitDeed(msg.sender, exitAmount);

    }

    function edit(DeedParameters memory deedParameters_,
        ExecutionTime memory executionTime_,
        RiskMitigation memory riskMitigation_,
        BrokerConfig memory brokerConfig_) onlyRole(MANAGER) onlyInState(DeedState.SETUP) public override {

        _edit(deedParameters_);
        _editExecutionTime(executionTime_);
        _editRiskMitigation(riskMitigation_);
        _editBrokerConfig(brokerConfig_);
    }

    function cancel() onlyInStates([DeedState.SETUP, DeedState.READY]) external override {
        // bool canCancel = false;
        // if (hasRole(MANAGER, address(msg.sender))) {
        //   canCancel = true;
        // } else if (state == DeedState.SETUP && block.timestamp > executionTime.recruitingEndTimestamp) {
        //   canCancel = true;
        // } else if (totalSupply < deedParameters.deedSize && block.timestamp > executionTime.buyTimestamp) {
        //   canCancel = true;
        // }
        // if (!canCancel) {
        //   revert("Only manager or buy time");
        // }
        require(
            hasRole(MANAGER, address(msg.sender)) ||
            CoinDeedUtils.cancelCheck(state, executionTime, deedParameters, totalSupply),
            "Only manager or buy time"
        );

        state = DeedState.CANCELED;
        deedToken.safeTransfer(manager, stakes[manager]);
        stakes[manager] = 0;
    }

    function withdrawStake() external override {
        CoinDeedUtils.withdrawStakeCheck(state, executionTime, stakes[msg.sender], msg.sender == manager);
        uint256 managementFee;
        if (state == DeedState.CLOSED) {
            uint256 totalFee = totalManagementFee * (stakes[msg.sender] / totalStake);
            totalManagementFee -= totalFee;
            // if (pair.tokenA == address(0x00)) {
            //     amount = _swapEthToToken(totalFee, address(deedToken));
            // } else {
            //     amount = _swapTokenToToken(false, pair.tokenA, totalFee, address(deedToken));
            // }
            if (pair.tokenA == USDT_ADDRESS) {
                IERC20(pair.tokenA).safeApprove(address(dao), 0);
            }
            IERC20(pair.tokenA).safeApprove(address(dao), totalFee);
            uint256 amount = dao.claimCoinDeedManagementFee(pair.tokenA, totalFee);
            uint256 platformFee = amount * coinDeedFactory.platformFee() / BASE_DENOMINATOR;
            managementFee = amount - platformFee;
            deedToken.safeTransfer(coinDeedAddressesProvider.treasury(), platformFee);
        }
        totalStake -= stakes[msg.sender];
        deedToken.safeTransfer(msg.sender, stakes[msg.sender] + managementFee);
        stakes[msg.sender] = 0;

    }

    function buyInEth() onlyInState(DeedState.READY) external payable override {
        // TODO Not adapted for ETH lending pool
        _buyIn(msg.value);
    }

    function buyIn(uint256 amount) onlyInState(DeedState.READY) external override {
        IERC20 tokenA = IERC20(pair.tokenA);
        tokenA.safeTransferFrom(msg.sender, address(this), amount);
        _buyIn(amount);
    }

    function _buyIn(uint256 amount) internal {
        uint256 maxBuyIn = deedParameters.deedSize - totalSupply;

        uint256 _amount = amount;
        if (_amount > maxBuyIn) {
            _amount = maxBuyIn;
            uint256 diff = amount - _amount;
            _transfer(pair.tokenA, payable(msg.sender), diff);
        }

        totalSupply += _amount;
        buyIns[msg.sender] += _amount;
        coinDeedFactory.emitBuyIn(msg.sender, _amount);
    }

    function loanInfo(address buyer) public view returns (uint256) {
        uint256 actualTotalLoan = lendingPool.totalBorrowBalance(pair.tokenA, address(this));
        return actualTotalLoan * buyIns[buyer] / totalSupply;
    }

    function buy() onlyInState(DeedState.READY) external override {
        require(block.timestamp >= executionTime.buyTimestamp, "Buy time has to pass");
        require(totalSupply >= deedParameters.deedSize * deedParameters.minimumBuy / BASE_DENOMINATOR, "Minimum buy not met");

        totalManagementFee = totalSupply * deedParameters.managementFee / BASE_DENOMINATOR;
        uint256 ownFunds = totalSupply - totalManagementFee;
        uint256 totalLoan = ownFunds * (deedParameters.leverage - 1);

        lendingPool.borrow(pair.tokenA, totalLoan);
        uint256 amountToSwap = ownFunds + totalLoan;

        if (pair.tokenA == address(0x00)) {
            require(amountToSwap <= address(this).balance, "Ether balance must be enough.");
        } else {
            require(amountToSwap <= IERC20(pair.tokenA).balanceOf(address(this)), "ERC20 balance must be enough.");
        }

        // use wholesale to do the swap first
        if (wholesaleId != 0) {
            IWholesaleFactory wholesaleFactory = IWholesaleFactory(coinDeedAddressesProvider.wholesaleFactory());
            IWholesaleFactory.Wholesale memory wholesale = wholesaleFactory.getWholesale(wholesaleId);

            // make sure we have enough total supply to execute wholesale
            if (amountToSwap >= wholesale.requestedAmount) {
                if (pair.tokenA == address(0x00)) {
                    wholesaleFactory.executeWholesale{value : wholesale.requestedAmount}(wholesaleId);
                } else {
                    if (pair.tokenA == USDT_ADDRESS) {
                        IERC20(pair.tokenA).safeApprove(address(wholesaleFactory), 0);
                    }
                    IERC20(pair.tokenA).safeApprove(address(wholesaleFactory), wholesale.requestedAmount);
                    wholesaleFactory.executeWholesale(wholesaleId);
                }
                amountToSwap -= wholesale.requestedAmount;
            }
        }

        // if we still have balance left, use uniswap to complete the rest
        if (amountToSwap > 0) {
            if (pair.tokenA == address(0x00)) {
                _swapEthToToken(amountToSwap, pair.tokenB);
            } else if(pair.tokenB == address(0x00)) {
                _swapTokenToEth(amountToSwap, pair.tokenA);
            } else {
                _swapTokenToToken(false, pair.tokenA, amountToSwap, pair.tokenB);
            }
        }

        // by now we should have all the tokenB
        if (ILendingPool(coinDeedAddressesProvider.lendingPool()).poolInfo(pair.tokenB).isCreated) {
            if (pair.tokenB == address(0x00)) {
                totalTokenB = address(this).balance;
                // deposit the funds in lending pool
                lendingPool.deposit{value : totalTokenB}(pair.tokenB, totalTokenB);
            } else {
                IERC20 tokenB = IERC20(pair.tokenB);
                totalTokenB = tokenB.balanceOf(address(this));
                // deposit the funds in lending pool
                if (address(tokenB) == USDT_ADDRESS) {
                    tokenB.safeApprove(address(lendingPool), 0);
                }
                tokenB.safeApprove(address(lendingPool), totalTokenB);
                lendingPool.deposit(pair.tokenB, totalTokenB);
            }
        }
        state = DeedState.OPEN;
        coinDeedFactory.emitStateChanged(state);
    }

    function tokenBBalance() public view returns (uint256) {
        // //TODO use lending pool deposit balance
        // if (pair.tokenB == address(0x00)) {
        //     return address(this).balance;
        // } else {
        //     IERC20 tokenB = IERC20(pair.tokenB);
        //     return tokenB.balanceOf(address(this));
        // }
        // return lendingPool.userAssetInfo(address(this), pair.tokenB).amount;
        return totalTokenB;
    }

    function sell() onlyInState(DeedState.OPEN) external override {
        require(block.timestamp >= executionTime.sellTimestamp, "Sell execution must be waited");
        uint256 amountToSwap = tokenBBalance();
        //TODO get balance from lendingpool
        // uint256 amountToSwap = IERC20(pair.tokenB).balanceOf(address(this));

        if (amountToSwap > 0) {
            _sell(amountToSwap);
        }

        uint256 actualTotalLoan = lendingPool.totalBorrowBalance(pair.tokenA, address(this));

        // by now we should have all the tokenA
        if (actualTotalLoan > 0) {
            _repay(actualTotalLoan);
        }

        state = DeedState.CLOSED;
        coinDeedFactory.emitStateChanged(state);
    }

    function executeRiskMitigation() external override onlyInState(DeedState.OPEN) {
        require(!riskMitigationTriggered, "Can only call RM once");
        // TODO update to get balance from lending pool directly to get the proper balance with interest
        uint256 totalDeposit = deedParameters.leverage * deedParameters.deedSize;
        uint256 totalBorrow = lendingPool.totalBorrowBalance(pair.tokenA, address(this));
         uint256 sellAmount = CoinDeedAddressesProviderUtils.checkRiskMitigationAndGetSellAmount(
            coinDeedAddressesProvider, pair, riskMitigation, totalDeposit, totalBorrow);

        // Commence the sell and repayment
        if (sellAmount > 0) {
            _sell(sellAmount);
        }
        uint256 tokenABalance;
        if (pair.tokenA == address(0x00)) {
            tokenABalance = address(this).balance;
        } else {
            tokenABalance = IERC20(pair.tokenA).balanceOf(address(this));
        }
        if (tokenABalance > 0) {
            _repay(tokenABalance);
        }

    }

    function _edit(uint256 deedSize_, uint8 leverage_, uint256 managementFee_, uint256 minimumBuy_) internal {
        require(leverage_ <= coinDeedFactory.maxLeverage(), "Leverage is to high.");
        require(minimumBuy_ > 0 && minimumBuy_ <= BASE_DENOMINATOR, "Invalid minimum buy.");
        deedParameters.deedSize = deedSize_;
        deedParameters.leverage = leverage_;
        deedParameters.managementFee = managementFee_;
        deedParameters.minimumBuy = minimumBuy_;
    }

    function _edit(DeedParameters memory deedParameters_) internal {
        _edit(deedParameters_.deedSize, deedParameters_.leverage, deedParameters_.managementFee, deedParameters_.minimumBuy);
    }

    function _editExecutionTime(ExecutionTime memory executionTime_) internal {
        require(executionTime_.recruitingEndTimestamp > block.timestamp, "RecruitingEnd action must be in future.");
        require(executionTime_.recruitingEndTimestamp < executionTime_.buyTimestamp, "RecruitingEnd action must be before buy.");
        require(executionTime_.buyTimestamp < executionTime_.sellTimestamp, "Buy action must be before sell.");
        executionTime = executionTime_;
    }

    function _editRiskMitigation(RiskMitigation memory riskMitigation_) internal {
        require(riskMitigation_.trigger <= coinDeedFactory.maxPriceDrop() / deedParameters.leverage, "Invalid trigger");
        require(riskMitigation_.leverage <= coinDeedFactory.maxLeverage(), "Invalid leverage");
        riskMitigation = riskMitigation_;
    }

    function _editBrokerConfig(BrokerConfig memory brokerConfig_) internal {
        if (brokerConfig_.allowed && !brokerConfig.allowed) {
            coinDeedFactory.emitBrokersEnabled();
        }
        brokerConfig = brokerConfig_;
    }

    // function _swapToDeedCoin(bool pullFunds, address tokenAddress, uint256 amount) internal virtual returns (uint256 deedTokenAmount){
    //     return _swapTokenToToken(pullFunds, tokenAddress, amount, address(deedToken));
    // }

    function _swapTokenToToken(bool pullFunds, address token1Address, uint256 amount, address token2Address) internal virtual returns (uint256){
        IERC20 token1 = IERC20(token1Address);
        if (pullFunds) {
            token1.safeTransferFrom(msg.sender, address(this), amount);
        }
        if (address(token1) == USDT_ADDRESS) {
            token1.safeApprove(address(uniswapRouter1), 0);
        }
        token1.safeApprove(address(uniswapRouter1), amount);
        address[] memory path = new address[](2);
        path[0] = token1Address;
        path[1] = token2Address;

        uint[] memory amounts = uniswapRouter1.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp + 15);
        return amounts[1];
    }

    // function _swapEthToDeedCoin(uint256 amount) internal virtual returns (uint256 deedTokenAmount){
    //     return _swapEthToToken(amount, address(deedToken));
    // }

    function _swapEthToToken(uint256 amount, address token) internal virtual returns (uint256){
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(token);

        uint[] memory amounts = uniswapRouter1.swapExactETHForTokens{value : amount}(0, path, address(this), block.timestamp + 15);
        return amounts[1];
    }

    function _swapTokenToEth(uint256 amount, address tokenAddress) internal virtual returns (uint256 deedTokenAmount){
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = WETH;

        IERC20 token = IERC20(tokenAddress);
        if (address(token) == USDT_ADDRESS) {
            token.safeApprove(address(uniswapRouter1), 0);
        }
        token.safeApprove(address(uniswapRouter1), amount);

        uint[] memory amounts = uniswapRouter1.swapExactTokensForETH(amount, 0, path, address(this), block.timestamp + 15);
        return amounts[1];
    }

    function _transfer(address token, address payable recipient, uint256 amount) internal {
        if (token == address(0x00)) {
            (bool sent, ) = recipient.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    function _sell(uint256 amountToSwap) internal returns (uint256) {
        // todo: need a function in lending pool to check current balance
        lendingPool.withdraw(pair.tokenB, amountToSwap);
        if (pair.tokenB == address(0x00)) {
            return _swapEthToToken(amountToSwap, pair.tokenA);
        } else if (pair.tokenA == address(0x00)) {
            return _swapTokenToEth(amountToSwap, pair.tokenB);
        } else {
            return _swapTokenToToken(false, pair.tokenB, amountToSwap, pair.tokenA);
        }
    }

    // The assumption is made that all token A are in this deed contract's token A balance
    // Distributes a share of the balance based on the buyin of the sender
    function claimBalance() onlyInStates([DeedState.CLOSED, DeedState.CANCELED]) external override {
        _transfer(
            pair.tokenA,
            payable(msg.sender),
            CoinDeedUtils.getClaimAmount(
                state,
                pair.tokenA,
                totalSupply,
                buyIns[msg.sender]
            )
        );

        //assumes totalSupply reflects the total buyins at the time of deed execution
        totalSupply -= buyIns[msg.sender];
        buyIns[msg.sender] = 0;
    }

    function _repay(uint amount) internal {
        if (pair.tokenA == address(0x00)) {
            lendingPool.repay{value : amount}(pair.tokenA, amount);
            totalReturn = address(this).balance;
        } else {
            if (pair.tokenA == USDT_ADDRESS) {
                IERC20(pair.tokenA).safeApprove(address(lendingPool), 0);
            }
            IERC20(pair.tokenA).safeApprove(address(lendingPool), amount);
            lendingPool.repay(pair.tokenA, amount);
            totalReturn = IERC20(pair.tokenA).balanceOf(address(this));
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICoinDeed {


    struct DeedParameters {
        uint256 deedSize;
        uint8 leverage;
        uint256 managementFee;
        uint256 minimumBuy;
    }

    enum DeedState {SETUP, READY, OPEN, CLOSED, CANCELED}

    struct Pair {address tokenA; address tokenB;}

    struct ExecutionTime {
        uint256 recruitingEndTimestamp;
        uint256 buyTimestamp;
        uint256 sellTimestamp;
    }

    struct RiskMitigation {
        uint256 trigger;
        uint8 leverage;
    }

    struct BrokerConfig {
        bool allowed;
        uint256 minimumStaking;
    }

    /**
    *  Reserve a wholesale to swap on execution time
    */
    function reserveWholesale(uint256 wholesaleId) external;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    */
    function stake(uint256 amount) external;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    *  Uses exchange to swap token to DeedCoin
    */
    // function stakeEth() external payable;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    *  Uses exchange to swap token to DeedCoin
    */
    // function stakeDifferentToken(address token, uint256 amount) external;

    /**
    *  Brokers can withdraw their stake
    */
    function withdrawStake() external;

    /**
    *  Edit Broker Config
    */
    function editBrokerConfig(BrokerConfig memory brokerConfig) external;

    /**
    *  Edit RiskMitigation
    */
    function editRiskMitigation(RiskMitigation memory riskMitigation) external;

    /**
    *  Edit ExecutionTime
    */
    function editExecutionTime(ExecutionTime memory executionTime) external;

    /**
    *  Edit DeedInfo
    */
    function editBasicInfo(uint256 deedSize, uint8 leverage, uint256 managementFee, uint256 minimumBuy) external;

    /**
    *  Edit
    */
    function edit(DeedParameters memory deedParameters,
        ExecutionTime memory executionTime,
        RiskMitigation memory riskMitigation,
        BrokerConfig memory brokerConfig) external;

    /**
     * Initial swap to buy the tokens
     */
    function buy() external;

    /**
     * Final swap to buy the tokens
     */
    function sell() external;

    /**
    *  Cancels deed if it is not started yet.
    */
    function cancel() external;

    /**
    *  Buyers buys in from the deed
    */
    function buyIn(uint256 amount) external;

    /**
    *  Buyers buys in from the deed with native coin
    */
    function buyInEth() external payable;

    /**
    *  Buyers pays of their loan
    */
    // function payOff(uint256 amount) external;

    /**
    *  Buyers pays of their loan with native coin
    */
    // function payOffEth() external payable;

    /**
     *  Buyers pays of their loan with with another ERC20
     */
    // function payOffDifferentToken(address tokenAddress, uint256 amount) external;

    /**
    *  Buyers claims their balance if the deed is completed.
    */
    function claimBalance() external;

    /**
    *  Brokers and DeedManager claims their rewards.
    */
    // function claimManagementFee() external;

    /**
    *  System changes leverage to be sure that the loan can be paid.
    */
    function executeRiskMitigation() external;

    /**
    *  Buyers can leave deed before escrow closes.
    */
    function exitDeed() external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IOracle {
    function decimals() external view returns (uint256);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

//SPDX-License-Identifier: MIT

import "../interface/IOracle.sol";

pragma solidity >=0.7.0;

interface ILendingPool {
    struct AccrueInterestVars {
        uint256 blockDelta;
        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 simpleInterestSupplyFactor;
        uint256 borrowIndexNew;
        uint256 totalBorrowNew;
        uint256 totalReservesNew;
        uint256 supplyIndexNew;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 borrowIndex;
        uint256 supplyIndex;
        uint256 accrualBlockNumber;
        bool isCreated;
        uint256 decimals;
        uint256 sypplyIndexDebt;
        uint256 accTokenPerShare; // Accumulated DTokens per share, time 1e18. See below
    }

    // Info of each deed.
    struct DeedInfo {
        uint256 borrow;
        uint256 totalBorrow;
        uint256 borrowIndex;
        bool isValid;
    }

    struct UserAssetInfo {
        uint256 amount; // How many tokens the lender has provided
        uint256 supplyIndex;
    }

    event PoolAdded(address indexed token, uint256 decimals);
    event PoolUpdated(
        address indexed token,
        uint256 decimals,
        address oracle,
        uint256 oracleDecimals
    );
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Collateral(address indexed user, uint256 amount);


    /**
  * @notice Event emitted when interest is accrued
  */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves,
        uint256 supplyIndex
    );

    function initialize(address _ethOracle) external;

    function POOL_DECIMALS() external returns (uint256);

    function poolInfo(address) external returns (PoolInfo memory);

    function userAssetInfo(address lender, address token) external view returns (UserAssetInfo memory);


    // Stake tokens to Pool
    function deposit(address _tokenAddress, uint256 _amount) external payable;

    // Borrow
    function borrow(address _tokenAddress, uint256 _amount) external;

    function addNewDeed(address _address) external;

    function removeExpireDeed(address _address) external;
/*
    function getDtokenExchange(address _token, uint256 reward)
    external
    view
    returns (uint256);
*/
    // Withdraw tokens from STAKING.
    function withdraw(address _tokenAddress, uint256 _amount) external;

    function totalBorrowBalance(address _token, address _deed)
    external
    view
    returns (uint256);

    function pendingDToken(address _token, address _lender) external view returns (uint256);

    function repay(address _tokenAddress, uint256 _amount)
    external
    payable;

    function borrowIndex(address _token) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWholesaleFactory {

    enum WholesaleState {OPEN, RESERVED, CANCELLED, COMPLETED, WITHDRAWN}

    struct Wholesale {
        address offeredBy;
        address tokenOffered;
        address tokenRequested;
        uint256 offeredAmount;
        uint256 requestedAmount;
        uint256 minSaleAmount;
        uint256 deadline;
        address reservedTo;
        WholesaleState state;

    }


    event WholesaleCreated(
        uint256 indexed saleId,
        address indexed offeredBy,
        address tokenOffered,
        address tokenRequested,
        uint256 offeredAmount,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo
    );

    event WholesaleCanceled(
        uint256 indexed saleId
    );

    event WholesaleReserved(
        uint256 indexed saleId,
        address indexed reservedBy
    );

    event WholesaleUnreserved(
        uint256 indexed saleId
    );

    event WholesaleExecuted(
        uint256 indexed saleId,
        uint256 indexed tokenOfferedAmount
    );

    event WholesaleWithdrawn(
        uint256 indexed saleId,
        address indexed tokenAddress,
        uint256 indexed amount
    );

    /**
    * Returns number of Open sales to able to browse them
    */
    function openSaleCount() external view returns (uint256);

    /**
    * Returns number of Reserved sales to able to browse them
    */
    function reservedSaleCount() external view returns (uint256);

    /**
    * Returns number of completed sales to able to browse them
    */
    function completedSaleCount() external view returns (uint256);

    /**
    * Returns number of cancelled sales to able to browse them
    */
    function cancelledSaleCount() external view returns (uint256);

    /**
    * Seller creates a wholesale
    */
    function createWholesale(address tokenOffered,
        address tokenRequested,
        uint256 offeredAmount,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo) external;

    /**
    * Seller creates a wholesale with native coin
    */
    function createWholesaleEth(
        address tokenRequested,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo) external payable;

    /**
    * Seller cancels a wholesale before it is reserved
    */
    function cancelWholesale(uint256 saleId) external;

    /**
     * Deed reserves a wholesale
     */
    function reserveWholesale(uint256 saleId) external;

    /**
     * Deed triggers a wholesale
     */
    function executeWholesale(uint256 saleId) external payable;

    /**
     * Returns a wholesale with Id
     */
    function getWholesale(uint256 saleId) external returns (Wholesale memory);

    /**
     * Reserves a wholesale to a deed by seller
     */
    function reserveWholesaleToDeed(uint256 saleId, address deedAddress) external;

    /**
     * Cancels reservation n a wholesale by a deed by seller
     */
    function cancelReservation(uint256 saleId) external;

    /**
     * Withdraw funds from a wholesale
     */
    function withdraw(uint256 saleId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Dao.
 */
interface ICoinDeedDAO {
    event Mint(address indexed user, uint256 amount);

    function addOracleForToken(address _token, address _tokenOracle, uint256 _oracleDecimals) external;
    function claimDToken(address _tokenAddress,address _to, uint256 _amount) external;
    function exchangRewardToken(address _tokenAddress, uint256 _amount) external view returns (uint256);
    function claimCoinDeedManagementFee(address _tokenAddress, uint256 _amount) external returns (uint256);
    function getCoinDeedManagementFee(address _tokenAddress, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinDeedAddressesProvider {
    event FeedRegistryChanged(address feedRegistry);
    event SwapRouterChanged(address router);
    event LendingPoolChanged(address lendingPool);
    event CoinDeedFactoryChanged(address coinDeedFactory);
    event WholesaleFactoryChanged(address wholesaleFactory);
    event DeedTokenChanged(address deedToken);
    event CoinDeedDeployerChanged(address coinDeedDeployer);
    event TreasuryChanged(address treasury);
    event DaoChanged(address dao);

    function feedRegistry() external view returns (address);
    function swapRouter() external view returns (address);
    function lendingPool() external view returns (address);
    function coinDeedFactory() external view returns (address);
    function wholesaleFactory() external view returns (address);
    function deedToken() external view returns (address);
    function coinDeedDeployer() external view returns (address);
    function treasury() external view returns (address);
    function dao() external view returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "../interface/ICoinDeed.sol";
import "../interface/ICoinDeedFactory.sol";
import "../interface/ICoinDeedAddressesProvider.sol";

library CoinDeedAddressesProviderUtils {
    uint256 public constant BASE_DENOMINATOR = 10_000;

    function tokenRatio(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address tokenA,
        uint256 tokenAAmount,
        address tokenB
    ) internal view returns (uint256 tokenBAmount){
        FeedRegistryInterface feedRegistry = FeedRegistryInterface(coinDeedAddressesProvider.feedRegistry());
        uint256 answerA = uint256(feedRegistry.latestAnswer(tokenA, Denominations.USD));
        uint256 answerB = uint256(feedRegistry.latestAnswer(tokenB, Denominations.USD));
        uint8 decimalsA = feedRegistry.decimals(tokenA, Denominations.USD);
        uint8 decimalsB = feedRegistry.decimals(tokenB, Denominations.USD);
        require(answerA > 0 && answerB > 0, "Invalid oracle answer");
        return tokenAAmount * (answerA / (10 ** decimalsA)) * ((10 ** decimalsB) / answerB);
    }

    function readyCheck(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address tokenA,
        uint256 totalStake,
        uint256 stakingMultiplier,
        uint256 deedSize
    ) external view returns (bool){
        // RINKEBY:
        IUniswapV2Router01 uniswapRouter1 = IUniswapV2Router01(coinDeedAddressesProvider.swapRouter());
        address[] memory path = new address[](2);
        path[0] = tokenA == address(0) ? uniswapRouter1.WETH() : tokenA;
        path[1] = address(coinDeedAddressesProvider.deedToken());
        uint[] memory amounts = uniswapRouter1.getAmountsOut(deedSize, path);
        if (totalStake >= (amounts[0] * stakingMultiplier / BASE_DENOMINATOR)) {

        // MAINNET
        // FeedRegistryInterface feedRegistry = FeedRegistryInterface(coinDeedAddressesProvider.feedRegistry());
        // uint256 answer = uint256(feedRegistry.latestAnswer(tokenA, Denominations.USD));
        // uint8 decimals = feedRegistry.decimals(tokenA, Denominations.USD);
        // require(answer > 0, "Invalid oracle answer");
        // if (
        //     totalStake >=
        //     deedSize *
        //     answer /
        //     (10 ** decimals) * // Oracle Price in USD
        //     stakingMultiplier /
        //     BASE_DENOMINATOR // Staking multiplier
        // )
        // {
            return true;
        }
        return false;
    }

    // Token B is the collateral token
    // Token A is the debt token
    function checkRiskMitigationAndGetSellAmount(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair,
        ICoinDeed.RiskMitigation memory riskMitigation,
        uint256 totalDeposit,
        uint256 totalBorrow
    ) external view returns (uint256 sellAmount) {
        // Debt value expressed in collateral token units
        uint256 totalBorrowInDepositToken = tokenRatio(
            coinDeedAddressesProvider,
            pair.tokenA,
            totalBorrow,
            pair.tokenB);
        /** With leverage L, the ratio of total value of assets / debt is L/L-1.
          * To track an X% price drop, we set the mitigation threshold to (1-X) * L/L-1.
          * For example, if the initial leverage is 3 and we track a price drop of 5%,
          * risk mitigation can be triggered when the ratio of assets to debt falls
          * below 0.95 * 3/2 = 0.1485.
         **/

        uint256 mitigationThreshold =
            (BASE_DENOMINATOR - riskMitigation.trigger) *
            riskMitigation.leverage /
            (riskMitigation.leverage - 1);
        uint256 priceRatio =
            totalDeposit *
            BASE_DENOMINATOR /
            totalBorrowInDepositToken;
        require(priceRatio < mitigationThreshold, "Risk Mitigation isnt required.");

        /** To figure out how much to sell, we use the following formula:
          * a = collateral tokens
          * d = debt token value expressed in collateral token units
          * (e.g. for ETH collateral and BTC debt, how much ETH the BTC debt is worth)
          * s = amount of collateral tokens to sell
          * l_1 = current leverage = a/(a - d)
          * l_2 = risk mitigation target leverage = (a - s)/(a - d)
          * e = equity value expressed in collateral token units = a - d
          * From here we derive s = [a/e - l_2] * e
         **/
        uint256 equityInDepositToken = totalDeposit - totalBorrowInDepositToken;
        sellAmount = ((BASE_DENOMINATOR * totalDeposit / equityInDepositToken) -
                            (BASE_DENOMINATOR * riskMitigation.leverage)) *
                            equityInDepositToken / BASE_DENOMINATOR;
    }

    function validateTokens(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair
        ) external view returns (bool) {
        FeedRegistryInterface feedRegistry = FeedRegistryInterface(coinDeedAddressesProvider.feedRegistry());
        return(
            feedRegistry.latestAnswer(pair.tokenA, Denominations.USD) > 0 &&
            feedRegistry.latestAnswer(pair.tokenB, Denominations.USD) > 0
        );
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ICoinDeed.sol";
import "../interface/ICoinDeedFactory.sol";

library CoinDeedUtils {
    uint256 public constant BASE_DENOMINATOR = 10_000;

    function cancelCheck(
        ICoinDeed.DeedState state,
        ICoinDeed.ExecutionTime memory executionTime,
        ICoinDeed.DeedParameters memory deedParameters,
        uint256 totalSupply
    ) external view returns (bool) {
        if (
            state == ICoinDeed.DeedState.SETUP && 
            block.timestamp > executionTime.recruitingEndTimestamp
        ) 
        {
            return true;
        } 
        else if (
            totalSupply < deedParameters.deedSize * deedParameters.minimumBuy / BASE_DENOMINATOR && 
            block.timestamp > executionTime.buyTimestamp
        ) 
        {
            return true;
        }
        else {
            return false;
        }
    }

    function withdrawStakeCheck(
        ICoinDeed.DeedState state,
        ICoinDeed.ExecutionTime memory executionTime,
        uint256 stake,
        bool isManager
    ) external view returns (bool) {
        require(
            state != ICoinDeed.DeedState.READY &&
            state != ICoinDeed.DeedState.OPEN, 
            "Deed is not in correct state"
        );
        require(stake > 0, "No stake");
        require(
            state == ICoinDeed.DeedState.CLOSED || 
            !isManager, 
            "Can not withdraw your stake."
        );
        require(
            state != ICoinDeed.DeedState.SETUP || 
            executionTime.recruitingEndTimestamp < block.timestamp, 
            "Recruiting did not end."
        );
        return true;
    }


    function getClaimAmount(
        ICoinDeed.DeedState state,
        address tokenA,
        uint256 totalSupply,
        uint256 buyIn
    ) external view returns (uint256 claimAmount)
    {
        require(buyIn > 0, "No share.");
        uint256 balance;
        // Get balance. Assuming delegate call as a library function
        if (tokenA == address(0x00)) {
            balance = address(this).balance;
        }
        else {
            balance = IERC20(tokenA).balanceOf(address(this));
        }

        // Assign claim amount
        if (state == ICoinDeed.DeedState.CLOSED) {
            // buyer can claim tokenA in the same proportion as their buyins
            claimAmount = balance * buyIn / (totalSupply);

            // just a sanity check in case division rounds up
            if (claimAmount > balance) {
                claimAmount = balance;
            }
        } else {
            // buyer can claim tokenA back
            claimAmount = buyIn;
        }
        return claimAmount;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(
    address base,
    address quote
  )
    external
    view
    returns (
      uint8
    );

  function description(
    address base,
    address quote
  )
    external
    view
    returns (
      string memory
    );

  function version(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256
    );

  function latestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(
    address base,
    address quote
  )
    external
    view
    returns (
      int256 answer
    );

  function latestTimestamp(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 timestamp
    );

  function latestRound(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 roundId
    );

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      int256 answer
    );

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      uint256 timestamp
    );

  // Registry getters

  function getFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function isFeedEnabled(
    address aggregator
  )
    external
    view
    returns (
      bool
    );

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      Phase memory phase
    );

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    );

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 previousRoundId
    );

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 nextRoundId
    );

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    );

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(
    address base,
    address quote
  )
    external
    view
    returns (
      uint16 currentPhaseId
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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