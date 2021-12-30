//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

import "./interface/IToken.sol";
import "./interface/ICoinDeed.sol";
import "./interface/ILendingPool.sol";
import "./interface/ICoinDeedFactory.sol";
import "./interface/IWholesaleFactory.sol";
import "./interface/ICoinDeedDAO.sol";
import "./interface/ICoinDeedAddressesProvider.sol";
import {CoinDeedUtils} from "./libraries/CoinDeedUtils.sol";
import {CoinDeedAddressesProviderUtils} from "./libraries/CoinDeedAddressesProviderUtils.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CoinDeed is ICoinDeed, AccessControl {
    using SafeERC20 for IERC20;
    using CoinDeedAddressesProviderUtils for ICoinDeedAddressesProvider;

    uint256 public constant BASE_DENOMINATOR = 10_000;
    // TODO
    address internal constant USDT_ADDRESS = 0xd35d2e839d888d1cDBAdef7dE118b87DfefeD20e;

    address public WETH;
    address public override manager;
    uint256 public totalManagementFee;
    uint256 public totalSupply;
    uint256 public totalStake;
    uint256 public wholesaleId;
    bool public riskMitigationTriggered;

    ICoinDeedAddressesProvider coinDeedAddressesProvider;
    IUniswapV2Router01 public uniswapRouter1;

    Pair public pair;
    ExecutionTime public override executionTime;
    DeedParameters public override deedParameters;
    RiskMitigation public override riskMitigation;
    BrokerConfig public override brokerConfig;
    DeedState public override state;

    mapping(address => uint256) public stakes;
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

        _setupRole(DEFAULT_ADMIN_ROLE, manager_);

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
        require(state == state_, "WRONG_STATE");
    }

    function _onlyInStates(DeedState[2] memory states) private view {
        bool found = false;

        for (uint i = 0; i < states.length; i++) {
            if (state == states[i]) {
                found = true;
            }
        }
        require(found, "WRONG_STATE");
    }

    modifier onlyInState(DeedState state_) {
        _onlyInState(state_);
        _;
    }

    modifier onlyInStates(DeedState[2] memory states) {
        _onlyInStates(states);
        _;
    }

    /// @notice Set the saleId to 0 to unreserve a wholesale
    function reserveWholesale(uint256 saleId) external override {
        require(msg.sender == coinDeedAddressesProvider.coinDeedFactory() || msg.sender == manager, "INVALID_SENDER");

        IWholesaleFactory wholesaleFactory = IWholesaleFactory(coinDeedAddressesProvider.wholesaleFactory());
        if(saleId == 0) {
            wholesaleFactory.cancelReservation(wholesaleId);
        }
        else {
            IWholesaleFactory.Wholesale memory wholesale = wholesaleFactory.getWholesale(saleId);
            require(wholesale.tokenOffered == pair.tokenB, "WRONG_TOKEN_B");
            require(wholesale.tokenRequested == pair.tokenA, "WRONG_TOKEN_A");
            require(wholesale.minSaleAmount <= deedParameters.deedSize, "BAD_AMOUNT");
            wholesaleFactory.reserveWholesale(saleId);
        }
        wholesaleId = saleId;
    }

    function _checkIfDeedIsReady() internal {
        // Provide address provider to allow calculations with oracle
        ICoinDeedFactory coinDeedFactory = ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory());
        if (coinDeedAddressesProvider.readyCheck(
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
        stakes[supplier] += amount;
        totalStake += amount;
        ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitStakeAdded(supplier, amount);
        _checkIfDeedIsReady();
    }

    function stake(uint256 amount) onlyInState(DeedState.SETUP) external override {
        require(msg.sender == manager || brokerConfig.allowed, "NO_BROKERS");
        IToken(coinDeedAddressesProvider.deedToken()).transferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, amount);
    }

    // function editBrokerConfig(BrokerConfig memory brokerConfig_) onlyRole(DEFAULT_ADMIN_ROLE) onlyInState(DeedState.SETUP) public override {
    //     _editBrokerConfig(brokerConfig_);
    // }

    // function editRiskMitigation(RiskMitigation memory riskMitigation_) onlyRole(DEFAULT_ADMIN_ROLE) onlyInState(DeedState.SETUP) public override {
    //     _editRiskMitigation(riskMitigation_);
    // }

    function editExecutionTime(ExecutionTime memory executionTime_) onlyRole(DEFAULT_ADMIN_ROLE) onlyInState(DeedState.SETUP) public override {
        _editExecutionTime(executionTime_);
    }

    function editBasicInfo(uint256 deedSize_, uint8 leverage_, uint256 managementFee_, uint256 minimumBuy_) onlyRole(DEFAULT_ADMIN_ROLE) onlyInState(DeedState.SETUP) public override {
        require(totalStake == stakes[msg.sender], "NO_BROKERS");
        _edit(deedSize_, leverage_, managementFee_, minimumBuy_);

    }

    function exitDeed(bool _payoff) onlyInState(DeedState.OPEN) payable public override {
        uint256 buyerLoan = loanInfo(msg.sender);
        uint256 buyIn_ = buyIns[msg.sender];

        (uint256 totalTokenB, uint256 depositAmount) = CoinDeedUtils.getTotalTokenB(address(coinDeedAddressesProvider), pair.tokenB);
        uint256 exitAmount = totalTokenB * buyIn_ / totalSupply;
        uint256 actualWithdraw = depositAmount * buyIn_ / totalSupply;

        totalSupply -= buyIn_;
        buyIns[msg.sender] = 0;

        if(_payoff) {
            if (actualWithdraw > 0) {
                ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
                lendingPool.withdraw(pair.tokenB, actualWithdraw);
            }

            if (buyerLoan > 0) {
                if(pair.tokenA == address(0x00)) {
                    require(msg.value == buyerLoan, "BAD_REPAY");
                }
                else {
                    IERC20(pair.tokenA).safeTransferFrom(msg.sender, address(this), buyerLoan);
                }
                _repay(buyerLoan);
            }

            _transfer(pair.tokenB, payable(msg.sender), exitAmount);
            ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitPayOff(msg.sender, exitAmount);
        } else {
            uint256 tokenAForBuyer = exitAmount > 0 ? _sell(actualWithdraw, exitAmount) : 0;

            if (buyerLoan > 0) {
                _repay(buyerLoan);
            }

            _transfer(pair.tokenA, payable(msg.sender), tokenAForBuyer - buyerLoan);
            ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitExitDeed(msg.sender, exitAmount);
        }
    }

    function edit(DeedParameters memory deedParameters_,
        ExecutionTime memory executionTime_,
        RiskMitigation memory riskMitigation_,
        BrokerConfig memory brokerConfig_) onlyRole(DEFAULT_ADMIN_ROLE) onlyInState(DeedState.SETUP) public override {

        _edit(deedParameters_);
        _editExecutionTime(executionTime_);
        // _editRiskMitigation(riskMitigation_);
        // _editBrokerConfig(brokerConfig_);
    }

    function cancel() onlyInStates([DeedState.SETUP, DeedState.READY]) external override {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)) ||
            CoinDeedUtils.cancelCheck(state, executionTime, deedParameters, totalSupply),
            "NOT_READY"
        );

        state = DeedState.CANCELED;
        IToken(coinDeedAddressesProvider.deedToken()).transfer(manager, stakes[manager]);
        stakes[manager] = 0;
    }

    function withdrawStake() external override {
        IToken deedToken = IToken(coinDeedAddressesProvider.deedToken());
        ICoinDeedDAO dao = ICoinDeedDAO(coinDeedAddressesProvider.dao());
        require(CoinDeedUtils.withdrawStakeCheck(state, executionTime, stakes[msg.sender], msg.sender == manager), "BAD_WITHDRAW");
        uint256 managementFee;
        if (state == DeedState.CLOSED) {
            uint256 totalFee = totalManagementFee * (stakes[msg.sender] / totalStake);
            totalManagementFee -= totalFee;
            uint256 amount;
            if (pair.tokenA == address(0x00)) {
                amount = dao.claimCoinDeedManagementFee{value: totalFee}(pair.tokenA, totalFee);
            } else {
                if (pair.tokenA == USDT_ADDRESS) {
                    IERC20(pair.tokenA).safeApprove(address(dao), 0);
                }
                IERC20(pair.tokenA).safeApprove(address(dao), totalFee);
                amount = dao.claimCoinDeedManagementFee(pair.tokenA, totalFee);
            }
            uint256 platformFee = amount * ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).platformFee() / BASE_DENOMINATOR;
            managementFee = amount - platformFee;
            deedToken.transfer(coinDeedAddressesProvider.treasury(), platformFee);
        }
        totalStake -= stakes[msg.sender];
        deedToken.transfer(msg.sender, stakes[msg.sender] + managementFee);
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
        ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitBuyIn(msg.sender, _amount);
    }

    function loanInfo(address buyer) public view returns (uint256) {
        uint256 actualTotalLoan = ILendingPool(coinDeedAddressesProvider.lendingPool()).totalBorrowBalance(pair.tokenA, address(this));
        return actualTotalLoan * buyIns[buyer] / totalSupply;
    }

    function buy() onlyInState(DeedState.READY) external override {
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        require(block.timestamp >= executionTime.buyTimestamp, "BUY_TIME");
        require(totalSupply >= deedParameters.deedSize * deedParameters.minimumBuy / BASE_DENOMINATOR, "BUY_MIN");

        totalManagementFee = totalSupply * deedParameters.managementFee / BASE_DENOMINATOR;
        uint256 ownFunds = totalSupply - totalManagementFee;
        uint256 totalLoan = ownFunds * (deedParameters.leverage - 1);

        lendingPool.borrow(pair.tokenA, totalLoan);
        uint256 amountToSwap = ownFunds + totalLoan;

        if (pair.tokenA == address(0x00)) {
            require(amountToSwap <= address(this).balance, "LOW_ETHER");
        } else {
            require(amountToSwap <= IERC20(pair.tokenA).balanceOf(address(this)), "LOW_TOKENS");
        }

        // use wholesale to do the swap first
        if (wholesaleId != 0) {
            IWholesaleFactory wholesaleFactory = IWholesaleFactory(coinDeedAddressesProvider.wholesaleFactory());
            IWholesaleFactory.Wholesale memory wholesale = wholesaleFactory.getWholesale(wholesaleId);
            uint256 wholesaleAmount;
            if (amountToSwap <= wholesale.requestedAmount) {
                wholesaleAmount = amountToSwap;
            } else {
                wholesaleAmount = wholesale.requestedAmount;
            }

            if (pair.tokenA == address(0x00)) {
                wholesaleFactory.executeWholesale{value: wholesaleAmount}(wholesaleId, wholesaleAmount);
            } else {
                IERC20(pair.tokenA).safeApprove(address(wholesaleFactory), wholesaleAmount);
                wholesaleFactory.executeWholesale(wholesaleId, wholesaleAmount);
            }
            amountToSwap -= wholesaleAmount;
        }

        // if we still have balance left, use uniswap to complete the rest
        uint256 totalReceived;
        if (amountToSwap > 0) {
            if (pair.tokenA == address(0x00)) {
                totalReceived = _swapEthToToken(amountToSwap, pair.tokenB);
            } else if(pair.tokenB == address(0x00)) {
                totalReceived = _swapTokenToEth(amountToSwap, pair.tokenA);
            } else {
                totalReceived = _swapTokenToToken(pair.tokenA, amountToSwap, pair.tokenB);
            }
        }

        // by now we should have all the tokenB
        if (ILendingPool(coinDeedAddressesProvider.lendingPool()).poolActive(pair.tokenB)) {
            if (pair.tokenB == address(0x00)) {
                // deposit the funds in lending pool
                lendingPool.deposit{value : totalReceived}(pair.tokenB, totalReceived);
            } else {
                IERC20 tokenB = IERC20(pair.tokenB);
                // deposit the funds in lending pool
                tokenB.safeApprove(address(lendingPool), totalReceived);
                lendingPool.deposit(pair.tokenB, totalReceived);
            }
        }
        state = DeedState.OPEN;
        ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitStateChanged(state);
    }

    function sell() onlyInState(DeedState.OPEN) external override {
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        require(block.timestamp >= executionTime.sellTimestamp, "NOT_TIME");
        (uint256 amountToSwap, uint256 amountToWithdraw) = CoinDeedUtils.getTotalTokenB(address(coinDeedAddressesProvider), pair.tokenB);

        if (amountToSwap > 0) {
            _sell(amountToWithdraw, amountToSwap);
        }

        uint256 actualTotalLoan = lendingPool.totalBorrowBalance(pair.tokenA, address(this));

        // by now we should have all the tokenA
        if (actualTotalLoan > 0) {
            _repay(actualTotalLoan);
        }

        state = DeedState.CLOSED;
        ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitStateChanged(state);
    }

    /** @notice After risk mitigation validation, calling this function will have the caller pay off
      * the appropriate amount of debt given the risk mitigation parameters. The caller receives
      * an amount of collateral equal to the value of the debt paid off plus a liquidation bonus
      * set by the CoinDeedFactory. This is calculated using an oracle feed registry which should
      * be connected to Chainlink oracles.
      * The user is responsible for tracking the position of the deed and making sure that their
      * balances and approvals are set appropriately.
      * FUTURE WORK: Implement partial liquidations allowing liquidators to specify an amount of debt to pay off */
    // function executeRiskMitigation() external payable override onlyInState(DeedState.OPEN) {
    //     ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());

    //     // Check risk mitigation validity and get liquidation amounts
    //     (uint256 sellAmount, uint256 buyAmount) = coinDeedAddressesProvider.checkRiskMitigationAndGetSellAmount(
    //         pair, riskMitigation, riskMitigationTriggered);

    //     // Transfer the debt tokens from the liquidator and repay the debt. If ETH, debt tokens are in msg.value
    //     if(!(pair.tokenA == address(0x00))) {
    //         IERC20(pair.tokenA).safeTransferFrom(msg.sender, address(this), buyAmount);
    //     }
    //     if (buyAmount > 0) {
    //         _repay(buyAmount);
    //     }

    //     // Withdraw the appropriate amount of collateral and transfer to liquidator
    //     uint256 bonus = sellAmount * ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory())
    //         .liquidationBonus() / BASE_DENOMINATOR;
    //     lendingPool.withdraw(pair.tokenB, sellAmount + bonus);
    //     _transfer(pair.tokenB, payable(msg.sender), sellAmount + bonus);

    //     if (riskMitigationTriggered) {
    //         state = DeedState.CLOSED;
    //         ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitStateChanged(state);
    //     }
    //     riskMitigationTriggered = true;
    // }

    function _sell(uint256 amountToWithdraw, uint256 amountToSwap) internal returns (uint256) {
        // todo: need a function in lending pool to check current balance
        ILendingPool(coinDeedAddressesProvider.lendingPool()).withdraw(pair.tokenB, amountToWithdraw);
        if (pair.tokenB == address(0x00)) {
            return _swapEthToToken(amountToSwap, pair.tokenA);
        } else if (pair.tokenA == address(0x00)) {
            return _swapTokenToEth(amountToSwap, pair.tokenB);
        } else {
            return _swapTokenToToken(pair.tokenB, amountToSwap, pair.tokenA);
        }
    }

    // The assumption is made that all token A are in this deed contract's token A balance
    // Distributes a share of the balance based on the buyin of the sender
    function claimBalance() onlyInStates([DeedState.CLOSED, DeedState.CANCELED]) external override {
        //assumes totalSupply reflects the total buyins at the time of deed execution
        uint256 claimAmount = CoinDeedUtils.getClaimAmount(
            state,
            pair.tokenA,
            totalSupply,
            buyIns[msg.sender]);
        totalSupply -= buyIns[msg.sender];
        buyIns[msg.sender] = 0;
        _transfer(
            pair.tokenA,
            payable(msg.sender),
            claimAmount
        );
    }

    function _edit(uint256 deedSize_, uint8 leverage_, uint256 managementFee_, uint256 minimumBuy_) internal {
        require(leverage_ <= ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).maxLeverage(), "BAD_LEVERAGE");
        require(minimumBuy_ > 0 && minimumBuy_ <= BASE_DENOMINATOR, "BAD_MIN_BUY");
        deedParameters.deedSize = deedSize_;
        deedParameters.leverage = leverage_;
        deedParameters.managementFee = managementFee_;
        deedParameters.minimumBuy = minimumBuy_;
    }

    function _edit(DeedParameters memory deedParameters_) internal {
        _edit(deedParameters_.deedSize, deedParameters_.leverage, deedParameters_.managementFee, deedParameters_.minimumBuy);
    }

    function _editExecutionTime(ExecutionTime memory executionTime_) internal {
        coinDeedAddressesProvider.validateExecutionTime(executionTime_);
        executionTime = executionTime_;
    }

    function _editRiskMitigation(RiskMitigation memory riskMitigation_) internal {
        coinDeedAddressesProvider.validateRiskMitigation(riskMitigation_, deedParameters.leverage);
        riskMitigation = riskMitigation_;
    }

    // function _editBrokerConfig(BrokerConfig memory brokerConfig_) internal {
    //     if (brokerConfig_.allowed && !brokerConfig.allowed) {
    //         ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitBrokersEnabled();
    //     }
    //     brokerConfig = brokerConfig_;
    // }

    function _swapTokenToToken(address token1Address, uint256 amount, address token2Address) internal virtual returns (uint256){
        IERC20 token1 = IERC20(token1Address);
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
            require(sent, "FAILED_ETH");
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    function _repay(uint amount) internal {
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        if (pair.tokenA == address(0x00)) {
            lendingPool.repay{value : amount}(pair.tokenA, amount);
        } else {
            if (pair.tokenA == USDT_ADDRESS) {
                IERC20(pair.tokenA).safeApprove(address(lendingPool), 0);
            }
            IERC20(pair.tokenA).safeApprove(address(lendingPool), amount);
            lendingPool.repay(pair.tokenA, amount);
        }
    }
}

//SPDX-License-Identifier: Unlicense
/** @title Interface for CoinDeed
  * @author Bitus Labs
 **/
pragma solidity ^0.8.0;

interface ICoinDeed {


    enum DeedState {SETUP, READY, OPEN, CLOSED, CANCELED}

    /// @notice Class of all initial deed creation parameters.
    struct DeedParameters {
        uint256 deedSize;
        uint8 leverage;
        uint256 managementFee;
        uint256 minimumBuy;
    }

    struct Pair {address tokenA; address tokenB;}

    /// @notice Stores all the timestamps that must be checked prior to moving through deed phases.
    struct ExecutionTime {
        uint256 recruitingEndTimestamp;
        uint256 buyTimestamp;
        uint256 sellTimestamp;
    }

    /** @notice Risk mitigation can be triggered twice. *trigger* and *secondTrigger* are the percent drops that the collateral asset
      * can drop compared to the debt asset before the position is eligible for liquidation. The first mitigation is a partial
      * liquidation, liquidating just enough assets to return the position to the *leverage*. */
    struct RiskMitigation {
        uint256 trigger;
        uint256 secondTrigger;
        uint8 leverage;
    }

    /// @notice Stores all the parameters related to brokers
    struct BrokerConfig {
        bool allowed;
        uint256 minimumStaking;
    }


    /// @notice Reserve a wholesale to swap on execution time
    function reserveWholesale(uint256 wholesaleId) external;

    /// @notice Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    function stake(uint256 amount) external;

    /// @notice Brokers can withdraw their stake
    function withdrawStake() external;

    /// @notice Edit Broker Config
    // function editBrokerConfig(BrokerConfig memory brokerConfig_) external;

    /// @notice Edit RiskMitigation
    // function editRiskMitigation(RiskMitigation memory riskMitigation_) external;

    /// @notice Edit ExecutionTime
    function editExecutionTime(ExecutionTime memory executionTime_) external;

    /// @notice Edit DeedInfo
    function editBasicInfo(uint256 deedSize, uint8 leverage, uint256 managementFee, uint256 minimumBuy) external;

    /// @notice Returns the deed manager
    function manager() external view returns (address);

    function deedParameters() external view returns (
      uint256 deedSize,
      uint8 leverage,
      uint256 managementFee,
      uint256 minimumBuy
    );

    function executionTime() external view returns (
      uint256 recruitingEndTimestamp,
      uint256 buyTimestamp,
      uint256 sellTimestamp
    );

    function riskMitigation() external view returns (
      uint256 trigger,
      uint256 secondTrigger,
      uint8 leverage
    );

    function brokerConfig() external view returns (bool allowed, uint256 minimumStaking);

    function state() external view returns (DeedState);

    /// @notice Edit all deed parameters. Use previous parameters if unchanged.
    function edit(DeedParameters memory deedParameters_,
        ExecutionTime memory executionTime_,
        RiskMitigation memory riskMitigation_,
        BrokerConfig memory brokerConfig_) external;

    /** @notice Initial swap for the deed to buy the tokens
      * After validating the deed's eligibility to move to the OPEN phase,
      * the management fee is subtracted, and then the deed contract is loaned
      * enough of the buyin token to bring it to the specified leverage.
      * The deed then swaps the tokens into the collateral token and deposits
      * it into the lending pool to earn additional yield. The deed is now
      * in the open state.
      * @dev There is no economic incentive built in to call this function.
      * No safety check for swapping assets */
    function buy() external;

    /** @notice Sells the entire deed's collateral
      * After validating that the sell execution time has passed,
      * withdraws all collateral from the lending pool, sells it for the debt token,
      * and repays the loan in full. This closes the deed.
      * @dev There is no economic incentive built in to call this function.
      * No safety check for swapping assets */
    function sell() external;

    /// @notice Cancels deed if it is in the setup or ready phase
    function cancel() external;

    /// @notice Buyers buys into the deed
    function buyIn(uint256 amount) external;

    /// @notice Buyers buys in from the deed with ETH
    function buyInEth() external payable;

    /// @notice Buyers claims their balance if the deed is completed.
    function claimBalance() external;

    /** @notice Executes risk mitigation
      * Validates that the position is eligible for liquidation,
      * and then liquidates the appropriate amount of collateral depending on
      * whether risk mitigation has already been triggered.
      * If this is the second risk mitigation, closes the deed.
      * Allocates a liquidation bonus from the collateral to the caller. */
    // function executeRiskMitigation() external payable;

    /** @notice Message sender exits the deed
      * When the deed is open, this withdraws the buyer's share of collateral
      * and sells the entire amount. From this amount, repay the buyer's share of the debt
      * and return the rest to sender */
    function exitDeed(bool _payoff) payable external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IToken is IERC20, IAccessControl, IERC165 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../Exponential.sol";
import "../ErrorReporter.sol";

/**
 * @dev Interface of the Lending pool.
 */
interface ILendingPool {

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

    function initialize(
        address _dao,
        uint256 multiplierPerYear,
        uint256 baseRatePerYear
    ) external;

    function poolActive(address _token) external view returns (bool);

    function totalDepositBalance(address _token, address _lender)
        external
        view
        returns (uint256);

    function totalBorrowBalance(address _token, address _deed)
        external
        view
        returns (uint256);

    function depositAmount(address _token, address _lender)
        external
        view
        returns (uint256);

    function setCoinDeedAddressesProvider(address _coinDeedAddressesProvider) external;

    function createPool(address _tokenAddress) external;

    function addNewDeed(address _address) external;

    function removeExpireDeed(address _address) external;

    // Stake tokens to Pool
    function deposit(address _tokenAddress, uint256 _amount) external payable;

    // Borrow
    function borrow(address _tokenAddress, uint256 _amount) external;

    // Pay
    function repay(address _tokenAddress, uint256 _amount) external payable;

    // Withdraw tokens from STAKING.
    function withdraw(address _tokenAddress, uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeed.sol";

interface ICoinDeedFactory {


    event DeedCreated(
        uint256 indexed id,
        address indexed deedAddress,
        address indexed manager,
        uint8 leverage,
        uint256 wholesaleId
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
        ICoinDeed.BrokerConfig calldata brokerConfig) external returns (address);

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

    function isDeed(address deedAddress) external view returns (bool);

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

interface IWholesaleFactory {

    enum WholesaleState {OPEN, RESERVED, CANCELLED, COMPLETED, WITHDRAWN}

    struct Wholesale {
        address offeredBy;
        address tokenOffered;
        address tokenRequested;
        uint256 offeredAmount;
        uint256 requestedAmount;
        uint256 soldAmount;
        uint256 receivedAmount;
        uint256 minSaleAmount;
        uint256 deadline;
        address reservedTo;
        bool isPrivate;
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
        address reservedTo,
        bool isPrivate
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
        address indexed tokenRequested,
        address indexed tokenOffered,
        uint256 receivedAmount,
        uint256 unsoldAmount
    );

    event WholesaleEdited(
        uint256 indexed saleId,
        bool isPrivate,
        uint256 deadline,
        uint256 minSaleAmount
    );

    /**
    * Seller creates a wholesale
    */
    function createWholesale(address tokenOffered,
        address tokenRequested,
        uint256 offeredAmount,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo,
        bool isPrivate) external;

    /**
    * Seller creates a wholesale with native coin
    */
    function createWholesaleEth(
        address tokenRequested,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo,
        bool isPrivate) external payable;

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
    function executeWholesale(uint256 saleId, uint256 amount) external payable;

    /**
     * Returns a wholesale with Id
     */
    function getWholesale(uint256 saleId) external returns (Wholesale memory);

    /**
     * Cancels reservation n a wholesale by a deed by seller
     */
    function cancelReservation(uint256 saleId) external;

    function permittedDeedManager(uint256 saleId, address manager) external returns (bool);

    /**
     * Withdraw funds from a wholesale
     */
    function withdraw(uint256 saleId) external;

    function permitManagers(uint256 saleId, address[] calldata managers) external;
    function permitManager(uint256 saleId, address manager) external;
    function setPrivate(uint256 saleId, bool isPrivate) external;
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
    function claimCoinDeedManagementFee(address _tokenAddress, uint256 _amount) external payable returns (uint256);
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ICoinDeed.sol";
import "../interface/ILendingPool.sol";
import "../interface/ICoinDeedAddressesProvider.sol";

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

    function getTotalTokenB(address addressProvider, address tokenB) external view returns (uint256 returnAmount, uint256 depositAmount) {
        ICoinDeedAddressesProvider coinDeedAddressesProvider = ICoinDeedAddressesProvider(addressProvider);
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        if (lendingPool.poolActive(tokenB)) {
            returnAmount = lendingPool.totalDepositBalance(tokenB, address(this));
            depositAmount = lendingPool.depositAmount(tokenB, address(this));
        } else {
            returnAmount = IERC20(tokenB).balanceOf(address(this));
        }
    }
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
import "../interface/ILendingPool.sol";

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
        bool riskMitigationTriggered
    ) external view returns (uint256 sellAmount, uint256 buyAmount) {
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        uint256 totalDeposit = lendingPool.totalDepositBalance(pair.tokenB, address(this));
        uint256 totalBorrow = lendingPool.totalBorrowBalance(pair.tokenA, address(this));
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
        require(checkRiskMitigation(
            riskMitigation,
            totalDeposit,
            totalBorrowInDepositToken,
            riskMitigationTriggered
        ), "Risk Mitigation isnt required.");

        /** To figure out how much to sell, we use the following formula:
          * a = collateral tokens
          * d = debt token value expressed in collateral token units
          * (e.g. for ETH collateral and BTC debt, how much ETH the BTC debt is worth)
          * s = amount of collateral tokens to sell
          * l_1 = current leverage = a/(a - d)
          * l_2 = risk mitigation target leverage = (a - s)/(a - d)
          * e = equity value expressed in collateral token units = a - d
          * From here we derive s = [a/e - l_2] * e
          *
          * If risk mitigation has already been triggered, sell the entire deed
         **/
        uint256 equityInDepositToken = totalDeposit - totalBorrowInDepositToken;
        if (!riskMitigationTriggered) {
            sellAmount = ((BASE_DENOMINATOR * totalDeposit / equityInDepositToken) -
                (BASE_DENOMINATOR * riskMitigation.leverage)) *
                equityInDepositToken / BASE_DENOMINATOR;
        }
        else {
            sellAmount = totalDeposit;
        }
        buyAmount = tokenRatio(
            coinDeedAddressesProvider,
            pair.tokenB,
            sellAmount,
            pair.tokenA);

        return (sellAmount, buyAmount);
    }

    // Validates whether the position is eligible for risk mitigation
    function checkRiskMitigation(
        ICoinDeed.RiskMitigation memory riskMitigation,
        uint256 totalDeposit,
        uint256 totalBorrowInDepositToken,
        bool riskMitigationTriggered
    ) internal view returns (bool) {
        uint256 trigger = riskMitigationTriggered ?
            riskMitigation.secondTrigger :
            riskMitigation.trigger;
        uint256 mitigationThreshold =
            (BASE_DENOMINATOR - trigger) *
            riskMitigation.leverage /
            (riskMitigation.leverage - 1);
        uint256 priceRatio =
            totalDeposit *
            BASE_DENOMINATOR /
            totalBorrowInDepositToken;
        return priceRatio < mitigationThreshold;
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

    function validateRiskMitigation(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.RiskMitigation memory riskMitigation_,
        uint8 leverage
    ) external view returns (bool) {
        ICoinDeedFactory coinDeedFactory = ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory());
        require(riskMitigation_.trigger <= coinDeedFactory.maxPriceDrop() / leverage, "BAD_TRIG");
        require(riskMitigation_.leverage <= coinDeedFactory.maxLeverage(), "BAD_LEVERAGE");
        require(
            (riskMitigation_.secondTrigger <= coinDeedFactory.maxPriceDrop() / leverage) &&
            (riskMitigation_.secondTrigger >= riskMitigation_.trigger),
            "BAD_TRIG"
        );
    }

    function validateExecutionTime(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.ExecutionTime memory executionTime_
    ) external view returns (bool) {
        require(executionTime_.recruitingEndTimestamp > block.timestamp, "BAD_END");
        require(executionTime_.recruitingEndTimestamp < executionTime_.buyTimestamp, "BAD_BUY");
        require(executionTime_.buyTimestamp < executionTime_.sellTimestamp, "BAD_SELL");
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./maths/CarefulMath.sol";
import "./maths/ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_SUPPLY_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
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