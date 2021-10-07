// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "../interface/IAccessControl.sol";
import "../interface/IGovernor.sol";
import "../interface/IPoolCreatorFull.sol";
import "../interface/ISymbolService.sol";

import "../libraries/SafeMathExt.sol";
import "../libraries/OrderData.sol";
import "../libraries/Utils.sol";

import "./AMMModule.sol";
import "./CollateralModule.sol";
import "./MarginAccountModule.sol";
import "./PerpetualModule.sol";

import "../Type.sol";

library LiquidityPoolModule {
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using SafeMathExt for int256;
    using SafeMathExt for uint256;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    using OrderData for uint32;
    using AMMModule for LiquidityPoolStorage;
    using CollateralModule for LiquidityPoolStorage;
    using MarginAccountModule for PerpetualStorage;
    using PerpetualModule for PerpetualStorage;

    uint256 public constant OPERATOR_CHECK_IN_TIMEOUT = 10 days;
    uint256 public constant MAX_PERPETUAL_COUNT = 48;

    event AddLiquidity(
        address indexed trader,
        int256 addedCash,
        int256 mintedShare,
        int256 addedPoolMargin
    );
    event RemoveLiquidity(
        address indexed trader,
        int256 returnedCash,
        int256 burnedShare,
        int256 removedPoolMargin
    );
    event UpdatePoolMargin(int256 poolMargin);
    event TransferOperatorTo(address indexed newOperator);
    event ClaimOperator(address indexed newOperator);
    event RevokeOperator();
    event SetLiquidityPoolParameter(int256[4] value);
    event CreatePerpetual(
        uint256 perpetualIndex,
        address governor,
        address shareToken,
        address operator,
        address oracle,
        address collateral,
        int256[9] baseParams,
        int256[8] riskParams
    );
    event RunLiquidityPool();
    event OperatorCheckIn(address indexed operator);
    event DonateInsuranceFund(int256 amount);
    event TransferExcessInsuranceFundToLP(int256 amount);
    event SetTargetLeverage(uint256 perpetualIndex, address indexed trader, int256 targetLeverage);
    event AddAMMKeeper(uint256 perpetualIndex, address indexed keeper);
    event RemoveAMMKeeper(uint256 perpetualIndex, address indexed keeper);
    event AddTraderKeeper(uint256 perpetualIndex, address indexed keeper);
    event RemoveTraderKeeper(uint256 perpetualIndex, address indexed keeper);

    /**
     * @dev     Get the vault's address of the liquidity pool
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @return  vault           The vault's address of the liquidity pool
     */
    function getVault(LiquidityPoolStorage storage liquidityPool)
        public
        view
        returns (address vault)
    {
        vault = IPoolCreatorFull(liquidityPool.creator).getVault();
    }

    function getShareTransferDelay(LiquidityPoolStorage storage liquidityPool)
        public
        view
        returns (uint256 delay)
    {
        delay = liquidityPool.shareTransferDelay.max(1);
    }

    function getOperator(LiquidityPoolStorage storage liquidityPool)
        internal
        view
        returns (address)
    {
        return
            block.timestamp <= liquidityPool.operatorExpiration
                ? liquidityPool.operator
                : address(0);
    }

    function getTransferringOperator(LiquidityPoolStorage storage liquidityPool)
        internal
        view
        returns (address)
    {
        return
            block.timestamp <= liquidityPool.operatorExpiration
                ? liquidityPool.transferringOperator
                : address(0);
    }

    /**
     * @dev     Get the vault fee rate of the liquidity pool
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @return  vaultFeeRate    The vault fee rate.
     */
    function getVaultFeeRate(LiquidityPoolStorage storage liquidityPool)
        public
        view
        returns (int256 vaultFeeRate)
    {
        vaultFeeRate = IPoolCreatorFull(liquidityPool.creator).getVaultFeeRate();
    }

    /**
     * @dev     Get the available pool cash(collateral) of the liquidity pool excluding the specific perpetual. Available cash
     *          in a perpetual means: margin - initial margin
     *
     * @param   liquidityPool       The reference of liquidity pool storage.
     * @param   exclusiveIndex      The index of perpetual in the liquidity pool to exclude,
     *                              set to liquidityPool.perpetualCount to skip excluding.
     * @return  availablePoolCash   The available pool cash(collateral) of the liquidity pool excluding the specific perpetual
     */
    function getAvailablePoolCash(
        LiquidityPoolStorage storage liquidityPool,
        uint256 exclusiveIndex
    ) public view returns (int256 availablePoolCash) {
        uint256 length = liquidityPool.perpetualCount;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            if (i == exclusiveIndex || perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            int256 markPrice = perpetual.getMarkPrice();
            availablePoolCash = availablePoolCash.add(
                perpetual.getMargin(address(this), markPrice).sub(
                    perpetual.getInitialMargin(address(this), markPrice)
                )
            );
        }
        return availablePoolCash.add(liquidityPool.poolCash);
    }

    /**
     * @dev     Get the available pool cash(collateral) of the liquidity pool.
     *          Sum of available cash of AMM in every perpetual in the liquidity pool, and add the pool cash.
     *
     * @param   liquidityPool       The reference of liquidity pool storage.
     * @return  availablePoolCash   The available pool cash(collateral) of the liquidity pool
     */
    function getAvailablePoolCash(LiquidityPoolStorage storage liquidityPool)
        public
        view
        returns (int256 availablePoolCash)
    {
        return getAvailablePoolCash(liquidityPool, liquidityPool.perpetualCount);
    }

    /**
     * @dev     Check if Trader is maintenance margin safe in the perpetual.
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool.
     * @param   trader          The address of the trader
     * @param   tradeAmount     The amount of positions actually traded in the transaction
     * @return  isSafe          True if Trader is maintenance margin safe in the perpetual.
     */
    function isTraderMarginSafe(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address trader,
        int256 tradeAmount
    ) public view returns (bool isSafe) {
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        bool hasOpened = Utils.hasOpenedPosition(perpetual.getPosition(trader), tradeAmount);
        int256 markPrice = perpetual.getMarkPrice();
        return
            hasOpened
                ? perpetual.isInitialMarginSafe(trader, markPrice)
                : perpetual.isMarginSafe(trader, markPrice);
    }

    /**
     * @dev     Initialize the liquidity pool and set up its configuration.
     *
     * @param   liquidityPool       The reference of liquidity pool storage.
     * @param   collateral          The collateral's address of the liquidity pool.
     * @param   collateralDecimals  The collateral's decimals of the liquidity pool.
     * @param   operator            The operator's address of the liquidity pool.
     * @param   governor            The governor's address of the liquidity pool.
     * @param   initData            The byte array contains data to initialize new created liquidity pool.
     */
    function initialize(
        LiquidityPoolStorage storage liquidityPool,
        address creator,
        address collateral,
        uint256 collateralDecimals,
        address operator,
        address governor,
        bytes memory initData
    ) public {
        require(collateral != address(0), "collateral is invalid");
        require(governor != address(0), "governor is invalid");
        (
            bool isFastCreationEnabled,
            int256 insuranceFundCap,
            uint256 liquidityCap,
            uint256 shareTransferDelay
        ) = abi.decode(initData, (bool, int256, uint256, uint256));
        require(liquidityCap >= 0, "liquidity cap should be greater than 0");
        require(shareTransferDelay >= 1, "share transfer delay should be at lease 1");

        liquidityPool.initializeCollateral(collateral, collateralDecimals);
        liquidityPool.creator = creator;
        liquidityPool.accessController = IPoolCreatorFull(creator).getAccessController();

        liquidityPool.operator = operator;
        liquidityPool.operatorExpiration = block.timestamp.add(OPERATOR_CHECK_IN_TIMEOUT);
        liquidityPool.governor = governor;
        liquidityPool.shareToken = governor;

        liquidityPool.isFastCreationEnabled = isFastCreationEnabled;
        liquidityPool.insuranceFundCap = insuranceFundCap;
        liquidityPool.liquidityCap = liquidityCap;
        liquidityPool.shareTransferDelay = shareTransferDelay;
    }

    /**
     * @dev     Create and initialize new perpetual in the liquidity pool. Can only called by the operator
     *          if the liquidity pool is running or isFastCreationEnabled is set to true.
     *          Otherwise can only called by the governor
     * @param   liquidityPool       The reference of liquidity pool storage.
     * @param   oracle              The oracle's address of the perpetual
     * @param   baseParams          The base parameters of the perpetual
     * @param   riskParams          The risk parameters of the perpetual, must between minimum value and maximum value
     * @param   minRiskParamValues  The risk parameters' minimum values of the perpetual
     * @param   maxRiskParamValues  The risk parameters' maximum values of the perpetual
     */
    function createPerpetual(
        LiquidityPoolStorage storage liquidityPool,
        address oracle,
        int256[9] calldata baseParams,
        int256[8] calldata riskParams,
        int256[8] calldata minRiskParamValues,
        int256[8] calldata maxRiskParamValues
    ) public {
        require(
            liquidityPool.perpetualCount < MAX_PERPETUAL_COUNT,
            "perpetual count exceeds limit"
        );
        uint256 perpetualIndex = liquidityPool.perpetualCount;
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        perpetual.initialize(
            perpetualIndex,
            oracle,
            baseParams,
            riskParams,
            minRiskParamValues,
            maxRiskParamValues
        );
        ISymbolService service = ISymbolService(
            IPoolCreatorFull(liquidityPool.creator).getSymbolService()
        );
        service.allocateSymbol(address(this), perpetualIndex);
        if (liquidityPool.isRunning) {
            perpetual.setNormalState();
        }
        liquidityPool.perpetualCount++;

        emit CreatePerpetual(
            perpetualIndex,
            liquidityPool.governor,
            liquidityPool.shareToken,
            getOperator(liquidityPool),
            oracle,
            liquidityPool.collateralToken,
            baseParams,
            riskParams
        );
    }

    /**
     * @dev     Run the liquidity pool. Can only called by the operator. The operator can create new perpetual before running
     *          or after running if isFastCreationEnabled is set to true
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     */
    function runLiquidityPool(LiquidityPoolStorage storage liquidityPool) public {
        uint256 length = liquidityPool.perpetualCount;
        require(length > 0, "there should be at least 1 perpetual to run");
        for (uint256 i = 0; i < length; i++) {
            liquidityPool.perpetuals[i].setNormalState();
        }
        liquidityPool.isRunning = true;
        emit RunLiquidityPool();
    }

    /**
     * @dev     Set the parameter of the liquidity pool. Can only called by the governor.
     *
     * @param   liquidityPool  The reference of liquidity pool storage.
     * @param   params         The new value of the parameter
     */
    function setLiquidityPoolParameter(
        LiquidityPoolStorage storage liquidityPool,
        int256[4] memory params
    ) public {
        validateLiquidityPoolParameter(params);
        liquidityPool.isFastCreationEnabled = (params[0] != 0);
        liquidityPool.insuranceFundCap = params[1];
        liquidityPool.liquidityCap = uint256(params[2]);
        liquidityPool.shareTransferDelay = uint256(params[3]);
        emit SetLiquidityPoolParameter(params);
    }

    /**
     * @dev     Validate the liquidity pool parameter:
     *            1. insurance fund cap >= 0
     * @param   liquidityPoolParams  The parameters of the liquidity pool.
     */
    function validateLiquidityPoolParameter(int256[4] memory liquidityPoolParams) public pure {
        require(liquidityPoolParams[1] >= 0, "insuranceFundCap < 0");
        require(liquidityPoolParams[2] >= 0, "liquidityCap < 0");
        require(liquidityPoolParams[3] >= 1, "shareTransferDelay < 1");
    }

    /**
     * @dev     Add an account to the whitelist, accounts in the whitelist is allowed to call `liquidateByAMM`.
     *          If never called, the whitelist in poolCreator will be used instead.
     *          Once called, the local whitelist will be used and the the whitelist in poolCreator will be ignored.
     *
     * @param   keeper          The account of keeper.
     * @param   perpetualIndex  The index of perpetual in the liquidity pool
     */
    function addAMMKeeper(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address keeper
    ) public {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        EnumerableSetUpgradeable.AddressSet storage whitelist = liquidityPool
            .perpetuals[perpetualIndex]
            .ammKeepers;
        require(!whitelist.contains(keeper), "keeper is already added");
        bool success = whitelist.add(keeper);
        require(success, "fail to add keeper to whitelist");
        emit AddAMMKeeper(perpetualIndex, keeper);
    }

    /**
     * @dev     Remove an account from the `liquidateByAMM` whitelist.
     *
     * @param   keeper          The account of keeper.
     * @param   perpetualIndex  The index of perpetual in the liquidity pool
     */
    function removeAMMKeeper(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address keeper
    ) public {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        EnumerableSetUpgradeable.AddressSet storage whitelist = liquidityPool
            .perpetuals[perpetualIndex]
            .ammKeepers;
        require(whitelist.contains(keeper), "keeper is not added");
        bool success = whitelist.remove(keeper);
        require(success, "fail to remove keeper from whitelist");
        emit RemoveAMMKeeper(perpetualIndex, keeper);
    }

    function setPerpetualOracle(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address newOracle
    ) public {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        perpetual.setOracle(newOracle);
    }

    /**
     * @dev     Set the base parameter of the perpetual. Can only called by the governor
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of perpetual in the liquidity pool
     * @param   baseParams      The new value of the base parameter
     */
    function setPerpetualBaseParameter(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        int256[9] memory baseParams
    ) public {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        perpetual.setBaseParameter(baseParams);
    }

    /**
     * @dev     Set the risk parameter of the perpetual, including minimum value and maximum value.
     *          Can only called by the governor
     * @param   liquidityPool       The reference of liquidity pool storage.
     * @param   perpetualIndex      The index of perpetual in the liquidity pool
     * @param   riskParams          The new value of the risk parameter, must between minimum value and maximum value
     * @param   minRiskParamValues  The minimum value of the risk parameter
     * @param   maxRiskParamValues  The maximum value of the risk parameter
     */
    function setPerpetualRiskParameter(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        int256[8] memory riskParams,
        int256[8] memory minRiskParamValues,
        int256[8] memory maxRiskParamValues
    ) public {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        perpetual.setRiskParameter(riskParams, minRiskParamValues, maxRiskParamValues);
    }

    /**
     * @dev     Set the risk parameter of the perpetual. Can only called by the governor
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of perpetual in the liquidity pool
     * @param   riskParams      The new value of the risk parameter, must between minimum value and maximum value
     */
    function updatePerpetualRiskParameter(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        int256[8] memory riskParams
    ) public {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        perpetual.updateRiskParameter(riskParams);
    }

    /**
     * @dev     Set the state of the perpetual to "EMERGENCY". Must rebalance first.
     *          After that the perpetual is not allowed to trade, deposit and withdraw.
     *          The price of the perpetual is freezed to the settlement price
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool
     */
    function setEmergencyState(LiquidityPoolStorage storage liquidityPool, uint256 perpetualIndex)
        public
    {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        rebalance(liquidityPool, perpetualIndex);
        liquidityPool.perpetuals[perpetualIndex].setEmergencyState();
        if (!isAnyPerpetualIn(liquidityPool, PerpetualState.NORMAL)) {
            refundDonatedInsuranceFund(liquidityPool);
        }
    }

    /**
     * @dev     Check if all the perpetuals in the liquidity pool are not in a state.
     */
    function isAnyPerpetualIn(LiquidityPoolStorage storage liquidityPool, PerpetualState state)
        internal
        view
        returns (bool)
    {
        uint256 length = liquidityPool.perpetualCount;
        for (uint256 i = 0; i < length; i++) {
            if (liquidityPool.perpetuals[i].state == state) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev     Check if all the perpetuals in the liquidity pool are not in normal state.
     */
    function isAllPerpetualIn(LiquidityPoolStorage storage liquidityPool, PerpetualState state)
        internal
        view
        returns (bool)
    {
        uint256 length = liquidityPool.perpetualCount;
        for (uint256 i = 0; i < length; i++) {
            if (liquidityPool.perpetuals[i].state != state) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev     Refund donated insurance fund to current operator.
     *           - If current operator address is non-zero, all the donated funds will be forward to the operator address;
     *           - If no operator, the donated funds will be dispatched to the LPs according to the ratio of owned shares.
     */
    function refundDonatedInsuranceFund(LiquidityPoolStorage storage liquidityPool) internal {
        address operator = getOperator(liquidityPool);
        if (liquidityPool.donatedInsuranceFund > 0 && operator != address(0)) {
            int256 toRefund = liquidityPool.donatedInsuranceFund;
            liquidityPool.donatedInsuranceFund = 0;
            liquidityPool.transferToUser(operator, toRefund);
        }
    }

    /**
     * @dev     Set the state of all the perpetuals to "EMERGENCY". Use special type of rebalance.
     *          After rebalance, pool cash >= 0 and margin / initialMargin is the same in all perpetuals.
     *          Can only called when AMM is not maintenance margin safe in all perpetuals.
     *          After that all the perpetuals are not allowed to trade, deposit and withdraw.
     *          The price of every perpetual is freezed to the settlement price
     * @param   liquidityPool   The reference of liquidity pool storage.
     */
    function setAllPerpetualsToEmergencyState(LiquidityPoolStorage storage liquidityPool) public {
        require(liquidityPool.perpetualCount > 0, "no perpetual to settle");
        int256 margin;
        int256 maintenanceMargin;
        int256 initialMargin;
        uint256 length = liquidityPool.perpetualCount;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            int256 markPrice = perpetual.getMarkPrice();
            maintenanceMargin = maintenanceMargin.add(
                perpetual.getMaintenanceMargin(address(this), markPrice)
            );
            initialMargin = initialMargin.add(perpetual.getInitialMargin(address(this), markPrice));
            margin = margin.add(perpetual.getMargin(address(this), markPrice));
        }
        margin = margin.add(liquidityPool.poolCash);
        require(
            margin < maintenanceMargin ||
                IPoolCreatorFull(liquidityPool.creator).isUniverseSettled(),
            "AMM's margin >= maintenance margin or not universe settled"
        );
        // rebalance for settle all perps
        // Floor to make sure poolCash >= 0
        int256 rate = initialMargin != 0 ? margin.wdiv(initialMargin, Round.FLOOR) : 0;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            int256 markPrice = perpetual.getMarkPrice();
            // Floor to make sure poolCash >= 0
            int256 newMargin = perpetual.getInitialMargin(address(this), markPrice).wmul(
                rate,
                Round.FLOOR
            );
            margin = perpetual.getMargin(address(this), markPrice);
            int256 deltaMargin = newMargin.sub(margin);
            if (deltaMargin > 0) {
                // from pool to perp
                perpetual.updateCash(address(this), deltaMargin);
                transferFromPoolToPerpetual(liquidityPool, i, deltaMargin);
            } else if (deltaMargin < 0) {
                // from perp to pool
                perpetual.updateCash(address(this), deltaMargin);
                transferFromPerpetualToPool(liquidityPool, i, deltaMargin.neg());
            }
            liquidityPool.perpetuals[i].setEmergencyState();
        }
        require(liquidityPool.poolCash >= 0, "negative poolCash after settle all");
        refundDonatedInsuranceFund(liquidityPool);
    }

    /**
     * @dev     Set the state of the perpetual to "CLEARED". Add the collateral of AMM in the perpetual to the pool cash.
     *          Can only called when all the active accounts in the perpetual are cleared
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool
     */
    function setClearedState(LiquidityPoolStorage storage liquidityPool, uint256 perpetualIndex)
        public
    {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        perpetual.countMargin(address(this));
        perpetual.setClearedState();
        int256 marginToReturn = perpetual.settle(address(this));
        transferFromPerpetualToPool(liquidityPool, perpetualIndex, marginToReturn);
    }

    /**
     * @dev     Specify a new address to be operator. See transferOperator in Governance.sol.
     * @param   liquidityPool    The liquidity pool storage.
     * @param   newOperator      The address of new operator to transfer to
     */
    function transferOperator(LiquidityPoolStorage storage liquidityPool, address newOperator)
        public
    {
        require(newOperator != address(0), "new operator is invalid");
        require(newOperator != getOperator(liquidityPool), "cannot transfer to current operator");
        liquidityPool.transferringOperator = newOperator;
        liquidityPool.operatorExpiration = block.timestamp.add(OPERATOR_CHECK_IN_TIMEOUT);
        emit TransferOperatorTo(newOperator);
    }

    /**
     * @dev     A lease mechanism to check if the operator is alive as the pool manager.
     *          When called the operatorExpiration will be extended according to OPERATOR_CHECK_IN_TIMEOUT.
     *          After OPERATOR_CHECK_IN_TIMEOUT, the operator will no longer be the operator.
     *          New operator will only be raised by voting.
     *          Transfer operator to another account will renew the expiration.
     *
     * @param   liquidityPool   The liquidity pool storage.
     */
    function checkIn(LiquidityPoolStorage storage liquidityPool) public {
        liquidityPool.operatorExpiration = block.timestamp.add(OPERATOR_CHECK_IN_TIMEOUT);
        emit OperatorCheckIn(getOperator(liquidityPool));
    }

    /**
     * @dev  Claim the ownership of the liquidity pool to claimer. See `transferOperator` in Governance.sol.
     * @param   liquidityPool   The liquidity pool storage.
     * @param   claimer         The address of claimer
     */
    function claimOperator(LiquidityPoolStorage storage liquidityPool, address claimer) public {
        require(claimer == getTransferringOperator(liquidityPool), "caller is not qualified");
        liquidityPool.operator = claimer;
        liquidityPool.operatorExpiration = block.timestamp.add(OPERATOR_CHECK_IN_TIMEOUT);
        liquidityPool.transferringOperator = address(0);
        IPoolCreatorFull(liquidityPool.creator).registerOperatorOfLiquidityPool(
            address(this),
            claimer
        );
        emit ClaimOperator(claimer);
    }

    /**
     * @dev  Revoke operator of the liquidity pool.
     * @param   liquidityPool   The liquidity pool object
     */
    function revokeOperator(LiquidityPoolStorage storage liquidityPool) public {
        liquidityPool.operator = address(0);
        IPoolCreatorFull(liquidityPool.creator).registerOperatorOfLiquidityPool(
            address(this),
            address(0)
        );
        emit RevokeOperator();
    }

    /**
     * @dev     Update the funding state of each perpetual of the liquidity pool. Funding payment of every account in the
     *          liquidity pool is updated
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   currentTime     The current timestamp
     */
    function updateFundingState(LiquidityPoolStorage storage liquidityPool, uint256 currentTime)
        public
    {
        if (liquidityPool.fundingTime >= currentTime) {
            // invalid time
            return;
        }
        int256 timeElapsed = currentTime.sub(liquidityPool.fundingTime).toInt256();
        uint256 length = liquidityPool.perpetualCount;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            perpetual.updateFundingState(timeElapsed);
        }
        liquidityPool.fundingTime = currentTime;
    }

    /**
     * @dev     Update the funding rate of each perpetual of the liquidity pool
     * @param   liquidityPool   The reference of liquidity pool storage.
     */
    function updateFundingRate(LiquidityPoolStorage storage liquidityPool) public {
        (int256 poolMargin, bool isAMMSafe) = liquidityPool.getPoolMargin();
        emit UpdatePoolMargin(poolMargin);
        if (!isAMMSafe) {
            poolMargin = 0;
        }
        uint256 length = liquidityPool.perpetualCount;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            perpetual.updateFundingRate(poolMargin);
        }
    }

    /**
     * @dev     Update the oracle price of each perpetual of the liquidity pool.
     *          If oracle is terminated, set market to EMERGENCY.
     *
     * @param   liquidityPool       The liquidity pool object
     * @param   ignoreTerminated    Ignore terminated oracle if set to True.
     */
    function updatePrice(LiquidityPoolStorage storage liquidityPool, bool ignoreTerminated) public {
        uint256 length = liquidityPool.perpetualCount;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            perpetual.updatePrice();
            if (IOracle(perpetual.oracle).isTerminated() && !ignoreTerminated) {
                setEmergencyState(liquidityPool, perpetual.id);
            }
        }
    }

    /**
     * @dev     Donate collateral to the insurance fund of the liquidity pool to make the liquidity pool safe.
     *
     * @param   liquidityPool   The liquidity pool object
     * @param   amount          The amount of collateral to donate
     */
    function donateInsuranceFund(
        LiquidityPoolStorage storage liquidityPool,
        address donator,
        int256 amount
    ) public {
        require(amount > 0, "invalid amount");
        liquidityPool.transferFromUser(donator, amount);
        liquidityPool.donatedInsuranceFund = liquidityPool.donatedInsuranceFund.add(amount);
        emit DonateInsuranceFund(amount);
    }

    /**
     * @dev     Update the collateral of the insurance fund in the liquidity pool.
     *          If the collateral of the insurance fund exceeds the cap, the extra part of collateral belongs to LP.
     *          If the collateral of the insurance fund < 0, the donated insurance fund will cover it.
     *
     * @param   liquidityPool   The liquidity pool object
     * @param   deltaFund       The update collateral amount of the insurance fund in the perpetual
     * @return  penaltyToLP     The extra part of collateral if the collateral of the insurance fund exceeds the cap
     */
    function updateInsuranceFund(LiquidityPoolStorage storage liquidityPool, int256 deltaFund)
        public
        returns (int256 penaltyToLP)
    {
        if (deltaFund != 0) {
            int256 newInsuranceFund = liquidityPool.insuranceFund.add(deltaFund);
            if (deltaFund > 0) {
                if (newInsuranceFund > liquidityPool.insuranceFundCap) {
                    penaltyToLP = newInsuranceFund.sub(liquidityPool.insuranceFundCap);
                    newInsuranceFund = liquidityPool.insuranceFundCap;
                    emit TransferExcessInsuranceFundToLP(penaltyToLP);
                }
            } else {
                if (newInsuranceFund < 0) {
                    liquidityPool.donatedInsuranceFund = liquidityPool.donatedInsuranceFund.add(
                        newInsuranceFund
                    );
                    require(
                        liquidityPool.donatedInsuranceFund >= 0,
                        "negative donated insurance fund"
                    );
                    newInsuranceFund = 0;
                }
            }
            liquidityPool.insuranceFund = newInsuranceFund;
        }
    }

    /**
     * @dev     Deposit collateral to the trader's account of the perpetual. The trader's cash will increase.
     *          Activate the perpetual for the trader if the account in the perpetual is empty before depositing.
     *          Empty means cash and position are zero.
     *
     * @param   liquidityPool   The liquidity pool object
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool
     * @param   trader          The address of the trader
     * @param   amount          The amount of collateral to deposit
     */
    function deposit(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address trader,
        int256 amount
    ) public {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        transferFromUserToPerpetual(liquidityPool, perpetualIndex, trader, amount);
        if (liquidityPool.perpetuals[perpetualIndex].deposit(trader, amount)) {
            IPoolCreatorFull(liquidityPool.creator).activatePerpetualFor(trader, perpetualIndex);
        }
    }

    /**
     * @dev     Withdraw collateral from the trader's account of the perpetual. The trader's cash will decrease.
     *          Trader must be initial margin safe in the perpetual after withdrawing.
     *          Deactivate the perpetual for the trader if the account in the perpetual is empty after withdrawing.
     *          Empty means cash and position are zero.
     *
     * @param   liquidityPool   The liquidity pool object
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool
     * @param   trader          The address of the trader
     * @param   amount          The amount of collateral to withdraw
     */
    function withdraw(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address trader,
        int256 amount
    ) public {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        rebalance(liquidityPool, perpetualIndex);
        if (perpetual.withdraw(trader, amount)) {
            IPoolCreatorFull(liquidityPool.creator).deactivatePerpetualFor(trader, perpetualIndex);
        }
        transferFromPerpetualToUser(liquidityPool, perpetualIndex, trader, amount);
    }

    /**
     * @dev     If the state of the perpetual is "CLEARED", anyone authorized withdraw privilege by trader can settle
     *          trader's account in the perpetual. Which means to calculate how much the collateral should be returned
     *          to the trader, return it to trader's wallet and clear the trader's cash and position in the perpetual.
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool.
     * @param   trader          The address of the trader.
     */
    function settle(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address trader
    ) public {
        require(trader != address(0), "invalid trader");
        int256 marginToReturn = liquidityPool.perpetuals[perpetualIndex].settle(trader);
        require(marginToReturn > 0, "no margin to settle");
        transferFromPerpetualToUser(liquidityPool, perpetualIndex, trader, marginToReturn);
    }

    /**
     * @dev     Clear the next active account of the perpetual which state is "EMERGENCY" and send gas reward of collateral
     *          to sender. If all active accounts are cleared, the clear progress is done and the perpetual's state will
     *          change to "CLEARED". Active means the trader's account is not empty in the perpetual.
     *          Empty means cash and position are zero.
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool
     */
    function clear(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address trader
    ) public {
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        if (
            perpetual.keeperGasReward > 0 && perpetual.totalCollateral >= perpetual.keeperGasReward
        ) {
            transferFromPerpetualToUser(
                liquidityPool,
                perpetualIndex,
                trader,
                perpetual.keeperGasReward
            );
        }
        if (
            perpetual.activeAccounts.length() == 0 ||
            perpetual.clear(perpetual.getNextActiveAccount())
        ) {
            setClearedState(liquidityPool, perpetualIndex);
        }
    }

    /**
     * @dev Add collateral to the liquidity pool and get the minted share tokens.
     *      The share token is the credential and use to get the collateral back when removing liquidity.
     *      Can only called when at least 1 perpetual is in NORMAL state.
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param trader The address of the trader that adding liquidity
     * @param cashToAdd The cash(collateral) to add
     */
    function addLiquidity(
        LiquidityPoolStorage storage liquidityPool,
        address trader,
        int256 cashToAdd
    ) public {
        require(cashToAdd > 0, "cash amount must be positive");
        uint256 length = liquidityPool.perpetualCount;
        bool allowAdd;
        for (uint256 i = 0; i < length; i++) {
            if (liquidityPool.perpetuals[i].state == PerpetualState.NORMAL) {
                allowAdd = true;
                break;
            }
        }
        require(allowAdd, "all perpetuals are NOT in NORMAL state");
        liquidityPool.transferFromUser(trader, cashToAdd);

        IGovernor shareToken = IGovernor(liquidityPool.shareToken);
        int256 shareTotalSupply = shareToken.totalSupply().toInt256();

        (int256 shareToMint, int256 addedPoolMargin) = liquidityPool.getShareToMint(
            shareTotalSupply,
            cashToAdd
        );
        require(shareToMint > 0, "received share must be positive");
        // pool cash cannot be added before calculation, DO NOT use transferFromUserToPool

        increasePoolCash(liquidityPool, cashToAdd);
        shareToken.mint(trader, shareToMint.toUint256());

        emit AddLiquidity(trader, cashToAdd, shareToMint, addedPoolMargin);
    }

    /**
     * @dev     Remove collateral from the liquidity pool and redeem the share tokens when the liquidity pool is running.
     *          Only one of shareToRemove or cashToReturn may be non-zero.
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   trader          The address of the trader that removing liquidity.
     * @param   shareToRemove   The amount of the share token to redeem.
     * @param   cashToReturn    The amount of cash(collateral) to return.
     */
    function removeLiquidity(
        LiquidityPoolStorage storage liquidityPool,
        address trader,
        int256 shareToRemove,
        int256 cashToReturn
    ) public {
        IGovernor shareToken = IGovernor(liquidityPool.shareToken);
        int256 shareTotalSupply = shareToken.totalSupply().toInt256();
        int256 removedInsuranceFund;
        int256 removedDonatedInsuranceFund;
        int256 removedPoolMargin;
        if (cashToReturn == 0 && shareToRemove > 0) {
            (
                cashToReturn,
                removedInsuranceFund,
                removedDonatedInsuranceFund,
                removedPoolMargin
            ) = liquidityPool.getCashToReturn(shareTotalSupply, shareToRemove);
            require(cashToReturn > 0, "cash to return must be positive");
        } else if (cashToReturn > 0 && shareToRemove == 0) {
            (
                shareToRemove,
                removedInsuranceFund,
                removedDonatedInsuranceFund,
                removedPoolMargin
            ) = liquidityPool.getShareToRemove(shareTotalSupply, cashToReturn);
            require(shareToRemove > 0, "share to remove must be positive");
        } else {
            revert("invalid parameter");
        }
        require(
            shareToRemove.toUint256() <= shareToken.balanceOf(trader),
            "insufficient share balance"
        );
        int256 removedCashFromPool = cashToReturn.sub(removedInsuranceFund).sub(
            removedDonatedInsuranceFund
        );
        require(
            removedCashFromPool <= getAvailablePoolCash(liquidityPool),
            "insufficient pool cash"
        );
        shareToken.burn(trader, shareToRemove.toUint256());

        liquidityPool.transferToUser(trader, cashToReturn);
        liquidityPool.insuranceFund = liquidityPool.insuranceFund.sub(removedInsuranceFund);
        liquidityPool.donatedInsuranceFund = liquidityPool.donatedInsuranceFund.sub(
            removedDonatedInsuranceFund
        );
        decreasePoolCash(liquidityPool, removedCashFromPool);
        emit RemoveLiquidity(trader, cashToReturn, shareToRemove, removedPoolMargin);
    }

    /**
     * @dev     Add collateral to the liquidity pool without getting share tokens.
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   trader          The address of the trader that adding liquidity
     * @param   cashToAdd       The cash(collateral) to add
     */
    function donateLiquidity(
        LiquidityPoolStorage storage liquidityPool,
        address trader,
        int256 cashToAdd
    ) public {
        require(cashToAdd > 0, "cash amount must be positive");
        (, int256 addedPoolMargin) = liquidityPool.getShareToMint(0, cashToAdd);
        liquidityPool.transferFromUser(trader, cashToAdd);
        // pool cash cannot be added before calculation, DO NOT use transferFromUserToPool
        increasePoolCash(liquidityPool, cashToAdd);
        emit AddLiquidity(trader, cashToAdd, 0, addedPoolMargin);
    }

    /**
     * @dev     To keep the AMM's margin equal to initial margin in the perpetual as possible.
     *          Transfer collateral between the perpetual and the liquidity pool's cash, then
     *          update the AMM's cash in perpetual. The liquidity pool's cash can be negative,
     *          but the available cash can't. If AMM need to transfer and the available cash
     *          is not enough, transfer all the rest available cash of collateral.
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool
     * @return  The amount of rebalanced margin. A positive amount indicates the collaterals
     *          are moved from perpetual to pool, and a negative amount indicates the opposite.
     *          0 means no rebalance happened.
     */
    function rebalance(LiquidityPoolStorage storage liquidityPool, uint256 perpetualIndex)
        public
        returns (int256)
    {
        require(perpetualIndex < liquidityPool.perpetualCount, "perpetual index out of range");
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        if (perpetual.state != PerpetualState.NORMAL) {
            return 0;
        }
        int256 rebalanceMargin = perpetual.getRebalanceMargin();
        if (rebalanceMargin == 0) {
            // nothing to rebalance
            return 0;
        } else if (rebalanceMargin > 0) {
            // from perp to pool
            rebalanceMargin = rebalanceMargin.min(perpetual.totalCollateral);
            perpetual.updateCash(address(this), rebalanceMargin.neg());
            transferFromPerpetualToPool(liquidityPool, perpetualIndex, rebalanceMargin);
        } else {
            // from pool to perp
            int256 availablePoolCash = getAvailablePoolCash(liquidityPool, perpetualIndex);
            if (availablePoolCash <= 0) {
                // pool has no more collateral, nothing to rebalance
                return 0;
            }
            rebalanceMargin = rebalanceMargin.abs().min(availablePoolCash);
            perpetual.updateCash(address(this), rebalanceMargin);
            transferFromPoolToPerpetual(liquidityPool, perpetualIndex, rebalanceMargin);
        }
        return rebalanceMargin;
    }

    /**
     * @dev     Increase the liquidity pool's cash(collateral).
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   amount          The amount of cash(collateral) to increase.
     */
    function increasePoolCash(LiquidityPoolStorage storage liquidityPool, int256 amount) internal {
        require(amount >= 0, "increase negative pool cash");
        liquidityPool.poolCash = liquidityPool.poolCash.add(amount);
    }

    /**
     * @dev     Decrease the liquidity pool's cash(collateral).
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   amount          The amount of cash(collateral) to decrease.
     */
    function decreasePoolCash(LiquidityPoolStorage storage liquidityPool, int256 amount) internal {
        require(amount >= 0, "decrease negative pool cash");
        liquidityPool.poolCash = liquidityPool.poolCash.sub(amount);
    }

    // user <=> pool (addLiquidity/removeLiquidity)
    function transferFromUserToPool(
        LiquidityPoolStorage storage liquidityPool,
        address account,
        int256 amount
    ) public {
        liquidityPool.transferFromUser(account, amount);
        increasePoolCash(liquidityPool, amount);
    }

    function transferFromPoolToUser(
        LiquidityPoolStorage storage liquidityPool,
        address account,
        int256 amount
    ) public {
        if (amount == 0) {
            return;
        }
        liquidityPool.transferToUser(account, amount);
        decreasePoolCash(liquidityPool, amount);
    }

    // user <=> perpetual (deposit/withdraw)
    function transferFromUserToPerpetual(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address account,
        int256 amount
    ) public {
        liquidityPool.transferFromUser(account, amount);
        liquidityPool.perpetuals[perpetualIndex].increaseTotalCollateral(amount);
    }

    function transferFromPerpetualToUser(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address account,
        int256 amount
    ) public {
        if (amount == 0) {
            return;
        }
        liquidityPool.transferToUser(account, amount);
        liquidityPool.perpetuals[perpetualIndex].decreaseTotalCollateral(amount);
    }

    // pool <=> perpetual (fee/rebalance)
    function transferFromPerpetualToPool(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        int256 amount
    ) public {
        if (amount == 0) {
            return;
        }
        liquidityPool.perpetuals[perpetualIndex].decreaseTotalCollateral(amount);
        increasePoolCash(liquidityPool, amount);
    }

    function transferFromPoolToPerpetual(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        int256 amount
    ) public {
        if (amount == 0) {
            return;
        }
        liquidityPool.perpetuals[perpetualIndex].increaseTotalCollateral(amount);
        decreasePoolCash(liquidityPool, amount);
    }

    /**
     * @dev Check if the trader is authorized the privilege by the grantee. Any trader is authorized by himself
     * @param liquidityPool The reference of liquidity pool storage.
     * @param trader The address of the trader
     * @param grantee The address of the grantee
     * @param privilege The privilege
     * @return isGranted True if the trader is authorized
     */
    function isAuthorized(
        LiquidityPoolStorage storage liquidityPool,
        address trader,
        address grantee,
        uint256 privilege
    ) public view returns (bool isGranted) {
        isGranted =
            trader == grantee ||
            IAccessControl(liquidityPool.accessController).isGranted(trader, grantee, privilege);
    }

    /**
     * @dev     Deposit or withdraw to let effective leverage == target leverage
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool.
     * @param   trader          The address of the trader.
     * @param   deltaPosition   The update position of the trader's account in the perpetual.
     * @param   deltaCash       The update cash(collateral) of the trader's account in the perpetual.
     * @param   totalFee        The total fee collected from the trader after the trade.
     */
    function adjustMarginLeverage(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address trader,
        int256 deltaPosition,
        int256 deltaCash,
        int256 totalFee
    ) public {
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        // read perp
        int256 position = perpetual.getPosition(trader);
        int256 adjustCollateral;
        (int256 closePosition, int256 openPosition) = Utils.splitAmount(
            position.sub(deltaPosition),
            deltaPosition
        );
        if (closePosition != 0 && openPosition == 0) {
            // close only
            adjustCollateral = adjustClosedMargin(
                perpetual,
                trader,
                closePosition,
                deltaCash,
                totalFee
            );
        } else {
            // open only or close + open
            adjustCollateral = adjustOpenedMargin(
                perpetual,
                trader,
                deltaPosition,
                deltaCash,
                closePosition,
                openPosition,
                totalFee
            );
        }
        // real deposit/withdraw
        if (adjustCollateral > 0) {
            deposit(liquidityPool, perpetualIndex, trader, adjustCollateral);
        } else if (adjustCollateral < 0) {
            withdraw(liquidityPool, perpetualIndex, trader, adjustCollateral.neg());
        }
    }

    function adjustClosedMargin(
        PerpetualStorage storage perpetual,
        address trader,
        int256 closePosition,
        int256 deltaCash,
        int256 totalFee
    ) public view returns (int256 adjustCollateral) {
        int256 markPrice = perpetual.getMarkPrice();
        int256 position2 = perpetual.getPosition(trader);
        if (position2 == 0) {
            // close all, withdraw all
            return perpetual.getAvailableCash(trader).neg().min(0);
        }
        // when close, keep the margin ratio
        // -withdraw == (availableCash2 * close - (deltaCash - fee) * position2 + reservedValue) / position1
        // reservedValue = 0 if position2 == 0 else keeperGasReward * (-deltaPos)
        adjustCollateral = perpetual.getAvailableCash(trader).wmul(closePosition);
        adjustCollateral = adjustCollateral.sub(deltaCash.sub(totalFee).wmul(position2));
        if (position2 != 0) {
            adjustCollateral = adjustCollateral.sub(perpetual.keeperGasReward.wmul(closePosition));
        }
        adjustCollateral = adjustCollateral.wdiv(position2.sub(closePosition));
        // withdraw only when IM is satisfied
        adjustCollateral = adjustCollateral.max(
            perpetual.getAvailableMargin(trader, markPrice).neg()
        );
        // never deposit when close positions
        adjustCollateral = adjustCollateral.min(0);
    }

    // open only or close + open
    function adjustOpenedMargin(
        PerpetualStorage storage perpetual,
        address trader,
        int256 deltaPosition,
        int256 deltaCash,
        int256 closePosition,
        int256 openPosition,
        int256 totalFee
    ) public view returns (int256 adjustCollateral) {
        int256 markPrice = perpetual.getMarkPrice();
        int256 oldMargin = perpetual.getMargin(trader, markPrice);
        int256 leverage = perpetual.getTargetLeverage(trader);
        require(leverage > 0, "target leverage = 0");
        // openPositionMargin
        adjustCollateral = openPosition.abs().wfrac(markPrice, leverage);
        if (perpetual.getPosition(trader).sub(deltaPosition) != 0 && closePosition == 0) {
            // open from non-zero position
            // adjustCollateral = openPositionMargin + fee - pnl
            adjustCollateral = adjustCollateral
                .add(totalFee)
                .sub(markPrice.wmul(deltaPosition))
                .sub(deltaCash);
        } else {
            // open from 0 or close + open
            adjustCollateral = adjustCollateral.add(perpetual.keeperGasReward).sub(oldMargin);
        }
        // make sure after adjust: trader is initial margin safe
        adjustCollateral = adjustCollateral.max(
            perpetual.getAvailableMargin(trader, markPrice).neg()
        );
    }

    function setTargetLeverage(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        address trader,
        int256 targetLeverage
    ) public {
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        require(perpetual.initialMarginRate != 0, "initialMarginRate is not set");
        require(
            targetLeverage != perpetual.marginAccounts[trader].targetLeverage,
            "targetLeverage is already set"
        );
        int256 maxLeverage = Constant.SIGNED_ONE.wdiv(perpetual.initialMarginRate);
        require(targetLeverage <= maxLeverage, "targetLeverage exceeds maxLeverage");
        perpetual.setTargetLeverage(trader, targetLeverage);
        emit SetTargetLeverage(perpetualIndex, trader, targetLeverage);
    }

    // A readonly version of adjustMarginLeverage. This function was written post-audit. So there's a lot of repeated logic here.
    function readonlyAdjustMarginLeverage(
        PerpetualStorage storage perpetual,
        MarginAccount memory trader,
        int256 deltaPosition,
        int256 deltaCash,
        int256 totalFee
    ) public view returns (int256 adjustCollateral) {
        // read perp
        (int256 closePosition, int256 openPosition) = Utils.splitAmount(
            trader.position.sub(deltaPosition),
            deltaPosition
        );
        if (closePosition != 0 && openPosition == 0) {
            // close only
            adjustCollateral = readonlyAdjustClosedMargin(
                perpetual,
                trader,
                closePosition,
                deltaCash,
                totalFee
            );
        } else {
            // open only or close + open
            adjustCollateral = readonlyAdjustOpenedMargin(
                perpetual,
                trader,
                deltaPosition,
                deltaCash,
                closePosition,
                openPosition,
                totalFee
            );
        }
    }

    // A readonly version of adjustClosedMargin. This function was written post-audit. So there's a lot of repeated logic here.
    function readonlyAdjustClosedMargin(
        PerpetualStorage storage perpetual,
        MarginAccount memory trader,
        int256 closePosition,
        int256 deltaCash,
        int256 totalFee
    ) public view returns (int256 adjustCollateral) {
        int256 markPrice = perpetual.getMarkPrice();
        int256 position2 = trader.position;
        // was perpetual.getAvailableCash(trader)
        adjustCollateral = trader.cash.sub(position2.wmul(perpetual.unitAccumulativeFunding));
        if (position2 == 0) {
            // close all, withdraw all
            return adjustCollateral.neg().min(0);
        }
        // was adjustClosedMargin
        adjustCollateral = adjustCollateral.wmul(closePosition);
        adjustCollateral = adjustCollateral.sub(deltaCash.sub(totalFee).wmul(position2));
        if (position2 != 0) {
            adjustCollateral = adjustCollateral.sub(perpetual.keeperGasReward.wmul(closePosition));
        }
        adjustCollateral = adjustCollateral.wdiv(position2.sub(closePosition));
        // withdraw only when IM is satisfied
        adjustCollateral = adjustCollateral.max(
            readonlyGetAvailableMargin(perpetual, trader, markPrice).neg()
        );
        // never deposit when close positions
        adjustCollateral = adjustCollateral.min(0);
    }

    // A readonly version of adjustOpenedMargin. This function was written post-audit. So there's a lot of repeated logic here.
    function readonlyAdjustOpenedMargin(
        PerpetualStorage storage perpetual,
        MarginAccount memory trader,
        int256 deltaPosition,
        int256 deltaCash,
        int256 closePosition,
        int256 openPosition,
        int256 totalFee
    ) public view returns (int256 adjustCollateral) {
        int256 markPrice = perpetual.getMarkPrice();
        int256 oldMargin = readonlyGetMargin(perpetual, trader, markPrice);
        // was perpetual.getTargetLeverage
        int256 leverage = trader.targetLeverage;
        {
            require(perpetual.initialMarginRate != 0, "initialMarginRate is not set");
            int256 maxLeverage = Constant.SIGNED_ONE.wdiv(perpetual.initialMarginRate);
            leverage = leverage == 0 ? perpetual.defaultTargetLeverage.value : leverage;
            leverage = leverage.min(maxLeverage);
        }
        require(leverage > 0, "target leverage = 0");
        // openPositionMargin
        adjustCollateral = openPosition.abs().wfrac(markPrice, leverage);
        if (trader.position.sub(deltaPosition) != 0 && closePosition == 0) {
            // open from non-zero position
            // adjustCollateral = openPositionMargin + fee - pnl
            adjustCollateral = adjustCollateral
                .add(totalFee)
                .sub(markPrice.wmul(deltaPosition))
                .sub(deltaCash);
        } else {
            // open from 0 or close + open
            adjustCollateral = adjustCollateral.add(perpetual.keeperGasReward).sub(oldMargin);
        }
        // make sure after adjust: trader is initial margin safe
        adjustCollateral = adjustCollateral.max(
            readonlyGetAvailableMargin(perpetual, trader, markPrice).neg()
        );
    }

    // A readonly version of getMargin. This function was written post-audit. So there's a lot of repeated logic here.
    function readonlyGetMargin(
        PerpetualStorage storage perpetual,
        MarginAccount memory account,
        int256 price
    ) public view returns (int256 margin) {
        margin = account.position.wmul(price).add(
            account.cash.sub(account.position.wmul(perpetual.unitAccumulativeFunding))
        );
    }

    // A readonly version of getAvailableMargin. This function was written post-audit. So there's a lot of repeated logic here.
    function readonlyGetAvailableMargin(
        PerpetualStorage storage perpetual,
        MarginAccount memory account,
        int256 price
    ) public view returns (int256 availableMargin) {
        int256 threshold = account.position == 0
            ? 0 // was getInitialMargin
            : account.position.wmul(price).wmul(perpetual.initialMarginRate).abs().add(
                perpetual.keeperGasReward
            );
        // was getAvailableMargin
        availableMargin = readonlyGetMargin(perpetual, account, price).sub(threshold);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

interface IAccessControl {
    function grantPrivilege(address trader, uint256 privilege) external;

    function revokePrivilege(address trader, uint256 privilege) external;

    function isGranted(
        address owner,
        address trader,
        uint256 privilege
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IGovernor {
    function initialize(
        string memory name,
        string memory symbol,
        address minter,
        address target_,
        address rewardToken,
        address poolCreator
    ) external;

    function totalSupply() external view returns (uint256);

    function getTarget() external view returns (address);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

import "./IAccessControl.sol";
import "./IPoolCreator.sol";
import "./ITracer.sol";
import "./IVersionControl.sol";
import "./IVariables.sol";
import "./IKeeperWhitelist.sol";

interface IPoolCreatorFull is
    IPoolCreator,
    IVersionControl,
    ITracer,
    IVariables,
    IAccessControl,
    IKeeperWhitelist
{
    /**
     * @notice Owner of version control.
     */
    function owner() external view override(IVersionControl, IVariables) returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

interface ISymbolService {
    function isWhitelistedFactory(address factory) external view returns (bool);

    function addWhitelistedFactory(address factory) external;

    function removeWhitelistedFactory(address factory) external;

    function getPerpetualUID(uint256 symbol)
        external
        view
        returns (address liquidityPool, uint256 perpetualIndex);

    function getSymbols(address liquidityPool, uint256 perpetualIndex)
        external
        view
        returns (uint256[] memory symbols);

    function allocateSymbol(address liquidityPool, uint256 perpetualIndex) external;

    function assignReservedSymbol(
        address liquidityPool,
        uint256 perpetualIndex,
        uint256 symbol
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

import "./Constant.sol";
import "./Utils.sol";

enum Round {
    CEIL,
    FLOOR
}

library SafeMathExt {
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    /*
     * @dev Always half up for uint256
     */
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y).add(Constant.UNSIGNED_ONE / 2) / Constant.UNSIGNED_ONE;
    }

    /*
     * @dev Always half up for uint256
     */
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(Constant.UNSIGNED_ONE).add(y / 2).div(y);
    }

    /*
     * @dev Always half up for uint256
     */
    function wfrac(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256 r) {
        r = x.mul(y).add(z / 2).div(z);
    }

    /*
     * @dev Always half up if no rounding parameter
     */
    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = roundHalfUp(x.mul(y), Constant.SIGNED_ONE) / Constant.SIGNED_ONE;
    }

    /*
     * @dev Always half up if no rounding parameter
     */
    function wdiv(int256 x, int256 y) internal pure returns (int256 z) {
        if (y < 0) {
            y = neg(y);
            x = neg(x);
        }
        z = roundHalfUp(x.mul(Constant.SIGNED_ONE), y).div(y);
    }

    /*
     * @dev Always half up if no rounding parameter
     */
    function wfrac(
        int256 x,
        int256 y,
        int256 z
    ) internal pure returns (int256 r) {
        int256 t = x.mul(y);
        if (z < 0) {
            z = neg(z);
            t = neg(t);
        }
        r = roundHalfUp(t, z).div(z);
    }

    function wmul(
        int256 x,
        int256 y,
        Round round
    ) internal pure returns (int256 z) {
        z = div(x.mul(y), Constant.SIGNED_ONE, round);
    }

    function wdiv(
        int256 x,
        int256 y,
        Round round
    ) internal pure returns (int256 z) {
        z = div(x.mul(Constant.SIGNED_ONE), y, round);
    }

    function wfrac(
        int256 x,
        int256 y,
        int256 z,
        Round round
    ) internal pure returns (int256 r) {
        int256 t = x.mul(y);
        r = div(t, z, round);
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : neg(x);
    }

    function neg(int256 a) internal pure returns (int256) {
        return SignedSafeMathUpgradeable.sub(int256(0), a);
    }

    /*
     * @dev ROUND_HALF_UP rule helper.
     *      You have to call roundHalfUp(x, y) / y to finish the rounding operation.
     *      0.5 ≈ 1, 0.4 ≈ 0, -0.5 ≈ -1, -0.4 ≈ 0
     */
    function roundHalfUp(int256 x, int256 y) internal pure returns (int256) {
        require(y > 0, "roundHalfUp only supports y > 0");
        if (x >= 0) {
            return x.add(y / 2);
        }
        return x.sub(y / 2);
    }

    /*
     * @dev Division, rounding ceil or rounding floor
     */
    function div(
        int256 x,
        int256 y,
        Round round
    ) internal pure returns (int256 divResult) {
        require(y != 0, "division by zero");
        divResult = x.div(y);
        if (x % y == 0) {
            return divResult;
        }
        bool isSameSign = Utils.hasTheSameSign(x, y);
        if (round == Round.CEIL && isSameSign) {
            divResult = divResult.add(1);
        }
        if (round == Round.FLOOR && !isSameSign) {
            divResult = divResult.sub(1);
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../libraries/Utils.sol";
import "../Type.sol";

library OrderData {
    uint32 internal constant MASK_CLOSE_ONLY = 0x80000000;
    uint32 internal constant MASK_MARKET_ORDER = 0x40000000;
    uint32 internal constant MASK_STOP_LOSS_ORDER = 0x20000000;
    uint32 internal constant MASK_TAKE_PROFIT_ORDER = 0x10000000;
    uint32 internal constant MASK_USE_TARGET_LEVERAGE = 0x08000000;

    // old domain, will be removed in future
    string internal constant DOMAIN_NAME = "Mai Protocol v3";
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(abi.encodePacked("EIP712Domain(string name)"));
    bytes32 internal constant DOMAIN_SEPARATOR =
        keccak256(abi.encodePacked(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(DOMAIN_NAME))));
    bytes32 internal constant EIP712_ORDER_TYPE =
        keccak256(
            abi.encodePacked(
                "Order(address trader,address broker,address relayer,address referrer,address liquidityPool,",
                "int256 minTradeAmount,int256 amount,int256 limitPrice,int256 triggerPrice,uint256 chainID,",
                "uint64 expiredAt,uint32 perpetualIndex,uint32 brokerFeeLimit,uint32 flags,uint32 salt)"
            )
        );

    /*
     * @dev Check if the order is close-only order. Close-only order means the order can only close position
     *      of the trader
     * @param order The order object
     * @return bool True if the order is close-only order
     */
    function isCloseOnly(Order memory order) internal pure returns (bool) {
        return (order.flags & MASK_CLOSE_ONLY) > 0;
    }

    /*
     * @dev Check if the order is market order. Market order means the order which has no limit price, should be
     *      executed immediately
     * @param order The order object
     * @return bool True if the order is market order
     */
    function isMarketOrder(Order memory order) internal pure returns (bool) {
        return (order.flags & MASK_MARKET_ORDER) > 0;
    }

    /*
     * @dev Check if the order is stop-loss order. Stop-loss order means the order will trigger when the
     *      price is worst than the trigger price
     * @param order The order object
     * @return bool True if the order is stop-loss order
     */
    function isStopLossOrder(Order memory order) internal pure returns (bool) {
        return (order.flags & MASK_STOP_LOSS_ORDER) > 0;
    }

    /*
     * @dev Check if the order is take-profit order. Take-profit order means the order will trigger when
     *      the price is better than the trigger price
     * @param order The order object
     * @return bool True if the order is take-profit order
     */
    function isTakeProfitOrder(Order memory order) internal pure returns (bool) {
        return (order.flags & MASK_TAKE_PROFIT_ORDER) > 0;
    }

    /*
     * @dev Check if the flags contain close-only flag
     * @param flags The flags
     * @return bool True if the flags contain close-only flag
     */
    function isCloseOnly(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_CLOSE_ONLY) > 0;
    }

    /*
     * @dev Check if the flags contain market flag
     * @param flags The flags
     * @return bool True if the flags contain market flag
     */
    function isMarketOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_MARKET_ORDER) > 0;
    }

    /*
     * @dev Check if the flags contain stop-loss flag
     * @param flags The flags
     * @return bool True if the flags contain stop-loss flag
     */
    function isStopLossOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_STOP_LOSS_ORDER) > 0;
    }

    /*
     * @dev Check if the flags contain take-profit flag
     * @param flags The flags
     * @return bool True if the flags contain take-profit flag
     */
    function isTakeProfitOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_TAKE_PROFIT_ORDER) > 0;
    }

    function useTargetLeverage(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_USE_TARGET_LEVERAGE) > 0;
    }

    /*
     * @dev Get the hash of the order
     * @param order The order object
     * @return bytes32 The hash of the order
     */
    function getOrderHash(Order memory order) internal pure returns (bytes32) {
        bytes32 result = keccak256(abi.encode(EIP712_ORDER_TYPE, order));
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, result));
    }

    /*
     * @dev Decode the signature from the data
     * @param data The data object to decode
     * @return signature The signature
     */
    function decodeSignature(bytes memory data) internal pure returns (bytes memory signature) {
        require(data.length >= 350, "broken data");
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 signType;
        assembly {
            r := mload(add(data, 318))
            s := mload(add(data, 350))
            v := byte(24, mload(add(data, 292)))
            signType := byte(25, mload(add(data, 292)))
        }
        signature = abi.encodePacked(r, s, v, signType);
    }

    /*
     * @dev Decode the order from the data
     * @param data The data object to decode
     * @return order The order
     */
    function decodeOrderData(bytes memory data) internal pure returns (Order memory order) {
        require(data.length >= 256, "broken data");
        bytes32 tmp;
        assembly {
            // trader / 20
            mstore(add(order, 0), mload(add(data, 20)))
            // broker / 20
            mstore(add(order, 32), mload(add(data, 40)))
            // relayer / 20
            mstore(add(order, 64), mload(add(data, 60)))
            // referrer / 20
            mstore(add(order, 96), mload(add(data, 80)))
            // liquidityPool / 20
            mstore(add(order, 128), mload(add(data, 100)))
            // minTradeAmount / 32
            mstore(add(order, 160), mload(add(data, 132)))
            // amount / 32
            mstore(add(order, 192), mload(add(data, 164)))
            // limitPrice / 32
            mstore(add(order, 224), mload(add(data, 196)))
            // triggerPrice / 32
            mstore(add(order, 256), mload(add(data, 228)))
            // chainID / 32
            mstore(add(order, 288), mload(add(data, 260)))
            // expiredAt + perpetualIndex + brokerFeeLimit + flags + salt + v + signType / 26
            tmp := mload(add(data, 292))
        }
        order.expiredAt = uint64(bytes8(tmp));
        order.perpetualIndex = uint32(bytes4(tmp << 64));
        order.brokerFeeLimit = uint32(bytes4(tmp << 96));
        order.flags = uint32(bytes4(tmp << 128));
        order.salt = uint32(bytes4(tmp << 160));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./SafeMathExt.sol";

library Utils {
    using SafeMathExt for int256;
    using SafeMathExt for uint256;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    /*
     * @dev Check if two numbers have the same sign. Zero has the same sign with any number
     */
    function hasTheSameSign(int256 x, int256 y) internal pure returns (bool) {
        if (x == 0 || y == 0) {
            return true;
        }
        return (x ^ y) >> 255 == 0;
    }

    /**
     * @dev     Check if the trader has opened position in the trade.
     *          Example: 2, 1 => true; 2, -1 => false; -2, -3 => true
     * @param   amount  The position of the trader after the trade
     * @param   delta   The update position amount of the trader after the trade
     * @return  True if the trader has opened position in the trade
     */
    function hasOpenedPosition(int256 amount, int256 delta) internal pure returns (bool) {
        if (amount == 0) {
            return false;
        }
        return Utils.hasTheSameSign(amount, delta);
    }

    /*
     * @dev Split the delta to two numbers.
     *      Use for splitting the trading amount to the amount to close position and the amount to open position.
     *      Examples: 2, 1 => 0, 1; 2, -1 => -1, 0; 2, -3 => -2, -1
     */
    function splitAmount(int256 amount, int256 delta) internal pure returns (int256, int256) {
        if (Utils.hasTheSameSign(amount, delta)) {
            return (0, delta);
        } else if (amount.abs() >= delta.abs()) {
            return (delta, 0);
        } else {
            return (amount.neg(), amount.add(delta));
        }
    }

    /*
     * @dev Check if amount will be away from zero or cross zero if added the delta.
     *      Use for checking if trading amount will make trader open position.
     *      Example: 2, 1 => true; 2, -1 => false; 2, -3 => true
     */
    function isOpen(int256 amount, int256 delta) internal pure returns (bool) {
        return Utils.hasTheSameSign(amount, delta) || amount.abs() < delta.abs();
    }

    /*
     * @dev Get the id of the current chain
     */
    function chainID() internal pure returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    // function toArray(
    //     EnumerableSet.AddressSet storage set,
    //     uint256 begin,
    //     uint256 end
    // ) internal view returns (address[] memory result) {
    //     require(end > begin, "begin should be lower than end");
    //     uint256 length = set.length();
    //     if (begin >= length) {
    //         return result;
    //     }
    //     uint256 safeEnd = end.min(length);
    //     result = new address[](safeEnd.sub(begin));
    //     for (uint256 i = begin; i < safeEnd; i++) {
    //         result[i.sub(begin)] = set.at(i);
    //     }
    //     return result;
    // }

    function toArray(
        EnumerableSetUpgradeable.AddressSet storage set,
        uint256 begin,
        uint256 end
    ) internal view returns (address[] memory result) {
        require(end > begin, "begin should be lower than end");
        uint256 length = set.length();
        if (begin >= length) {
            return result;
        }
        uint256 safeEnd = end.min(length);
        result = new address[](safeEnd.sub(begin));
        for (uint256 i = begin; i < safeEnd; i++) {
            result[i.sub(begin)] = set.at(i);
        }
        return result;
    }

    function toArray(
        EnumerableSetUpgradeable.Bytes32Set storage set,
        uint256 begin,
        uint256 end
    ) internal view returns (bytes32[] memory result) {
        require(end > begin, "begin should be lower than end");
        uint256 length = set.length();
        if (begin >= length) {
            return result;
        }
        uint256 safeEnd = end.min(length);
        result = new bytes32[](safeEnd.sub(begin));
        for (uint256 i = begin; i < safeEnd; i++) {
            result[i.sub(begin)] = set.at(i);
        }
        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

import "../libraries/Constant.sol";
import "../libraries/Math.sol";
import "../libraries/SafeMathExt.sol";
import "../libraries/Utils.sol";

import "../module/MarginAccountModule.sol";
import "../module/PerpetualModule.sol";

import "../Type.sol";

library AMMModule {
    using Math for int256;
    using SafeMathExt for int256;
    using SignedSafeMathUpgradeable for int256;
    using SafeCastUpgradeable for uint256;

    using MarginAccountModule for PerpetualStorage;
    using PerpetualModule for PerpetualStorage;

    struct Context {
        int256 indexPrice;
        int256 position;
        int256 positionValue;
        // squareValue is 10^36, others are 10^18
        int256 squareValue;
        int256 positionMargin;
        int256 availableCash;
    }

    /**
     * @dev     Get the trading result when trader trades with AMM, divided into two parts:
     *            - AMM closes its position
     *            - AMM opens its position.
     *
     * @param   liquidityPool   The liquidity pool object of AMM.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool to trade.
     * @param   tradeAmount     The trading amount of position, positive if AMM longs, negative if AMM shorts.
     * @param   partialFill     Whether to allow partially trading. Set to true when liquidation trading,
     *                          set to false when normal trading.
     * @return  deltaCash       The update cash(collateral) of AMM after the trade.
     * @return  deltaPosition   The update position of AMM after the trade.
     */
    function queryTradeWithAMM(
        LiquidityPoolStorage storage liquidityPool,
        uint256 perpetualIndex,
        int256 tradeAmount,
        bool partialFill
    ) public view returns (int256 deltaCash, int256 deltaPosition) {
        require(tradeAmount != 0, "trading amount is zero");
        Context memory context = prepareContext(liquidityPool, perpetualIndex);
        PerpetualStorage storage perpetual = liquidityPool.perpetuals[perpetualIndex];
        (int256 closePosition, int256 openPosition) = Utils.splitAmount(
            context.position,
            tradeAmount
        );
        // AMM close position
        int256 closeBestPrice;
        (deltaCash, closeBestPrice) = ammClosePosition(context, perpetual, closePosition);
        context.availableCash = context.availableCash.add(deltaCash);
        context.position = context.position.add(closePosition);
        // AMM open position
        (int256 openDeltaCash, int256 openDeltaPosition, int256 openBestPrice) = ammOpenPosition(
            context,
            perpetual,
            openPosition,
            partialFill
        );
        deltaCash = deltaCash.add(openDeltaCash);
        deltaPosition = closePosition.add(openDeltaPosition);
        int256 bestPrice = closePosition != 0 ? closeBestPrice : openBestPrice;
        // If price is better(for trader) than best price, change price to best price
        deltaCash = deltaCash.max(bestPrice.wmul(deltaPosition).neg());
    }

    /**
     * @dev     Calculate the amount of share token to mint when liquidity provider adds liquidity to the liquidity pool.
     *          If adding liquidity at first time, which means total supply of share token is zero,
     *          the amount of share token to mint equals to the pool margin after adding liquidity.
     *
     * @param   liquidityPool       The liquidity pool object of AMM.
     * @param   shareTotalSupply    The total supply of the share token before adding liquidity.
     * @param   cashToAdd           The amount of cash(collateral) added to the liquidity pool.
     * @return  shareToMint         The amount of share token to mint.
     * @return  addedPoolMargin     The added amount of pool margin after adding liquidity.
     */
    function getShareToMint(
        LiquidityPoolStorage storage liquidityPool,
        int256 shareTotalSupply,
        int256 cashToAdd
    ) public view returns (int256 shareToMint, int256 addedPoolMargin) {
        Context memory context = prepareContext(liquidityPool);
        (int256 poolMargin, ) = getPoolMargin(context);
        context.availableCash = context.availableCash.add(cashToAdd);
        (int256 newPoolMargin, ) = getPoolMargin(context);
        require(
            liquidityPool.liquidityCap == 0 ||
                newPoolMargin <= liquidityPool.liquidityCap.toInt256(),
            "liquidity reaches cap"
        );
        addedPoolMargin = newPoolMargin.sub(poolMargin);
        if (shareTotalSupply == 0) {
            // first time, if there is pool margin left in pool, it belongs to the first person who adds liquidity
            shareToMint = newPoolMargin;
        } else {
            // If share token's total supply is not zero and there is no money in pool,
            // these share tokens have no value. This case should be avoided.
            require(poolMargin > 0, "share token has no value");
            shareToMint = newPoolMargin.sub(poolMargin).wfrac(shareTotalSupply, poolMargin);
        }
    }

    /**
     * @dev     Calculate the amount of cash to add when liquidity provider adds liquidity to the liquidity pool.
     *          If adding liquidity at first time, which means total supply of share token is zero,
     *          the amount of cash to add equals to the share amount to mint minus pool margin before adding liquidity.
     *
     * @param   liquidityPool       The liquidity pool object of AMM.
     * @param   shareTotalSupply    The total supply of the share token before adding liquidity.
     * @param   shareToMint         The amount of share token to mint.
     * @return  cashToAdd           The amount of cash(collateral) to add to the liquidity pool.
     */
    function getCashToAdd(
        LiquidityPoolStorage storage liquidityPool,
        int256 shareTotalSupply,
        int256 shareToMint
    ) public view returns (int256 cashToAdd) {
        Context memory context = prepareContext(liquidityPool);
        (int256 poolMargin, ) = getPoolMargin(context);
        if (shareTotalSupply == 0) {
            // first time, if there is pool margin left in pool, it belongs to the first person who adds liquidity
            cashToAdd = shareToMint.sub(poolMargin).max(0);
            int256 newPoolMargin = cashToAdd.add(poolMargin);
            require(
                liquidityPool.liquidityCap == 0 ||
                    newPoolMargin <= liquidityPool.liquidityCap.toInt256(),
                "liquidity reaches cap"
            );
        } else {
            // If share token's total supply is not zero and there is no money in pool,
            // these share tokens have no value. This case should be avoided.
            require(poolMargin > 0, "share token has no value");
            int256 newPoolMargin = shareTotalSupply.add(shareToMint).wfrac(
                poolMargin,
                shareTotalSupply
            );
            require(
                liquidityPool.liquidityCap == 0 ||
                    newPoolMargin <= liquidityPool.liquidityCap.toInt256(),
                "liquidity reaches cap"
            );
            int256 minPoolMargin = context.squareValue.div(2).sqrt();
            int256 newCash;
            if (newPoolMargin <= minPoolMargin) {
                // pool is still unsafe after adding liquidity
                newCash = newPoolMargin.mul(2).sub(context.positionValue);
            } else {
                // context.squareValue is 10^36, so use div instead of wdiv
                newCash = context.squareValue.div(newPoolMargin).div(2).add(newPoolMargin).sub(
                    context.positionValue
                );
            }
            cashToAdd = newCash.sub(context.availableCash);
        }
    }

    /**
     * @dev     Calculate the amount of cash(collateral) to return when liquidity provider removes liquidity from the liquidity pool.
     *          Removing liquidity is forbidden at several cases:
     *            1. AMM is unsafe before removing liquidity
     *            2. AMM is unsafe after removing liquidity
     *            3. AMM will offer negative price at any perpetual after removing liquidity
     *            4. AMM will exceed maximum leverage at any perpetual after removing liquidity
     *
     * @param   liquidityPool                The liquidity pool object of AMM.
     * @param   shareTotalSupply             The total supply of the share token before removing liquidity.
     * @param   shareToRemove                The amount of share token to redeem.
     * @return  cashToReturn                 The amount of cash(collateral) to return.
     * @return  removedInsuranceFund         The part of insurance fund returned to LP if all perpetuals are in CLEARED state.
     * @return  removedDonatedInsuranceFund  The part of donated insurance fund returned to LP if all perpetuals are in CLEARED state.
     * @return  removedPoolMargin            The removed amount of pool margin after removing liquidity.
     */
    function getCashToReturn(
        LiquidityPoolStorage storage liquidityPool,
        int256 shareTotalSupply,
        int256 shareToRemove
    )
        public
        view
        returns (
            int256 cashToReturn,
            int256 removedInsuranceFund,
            int256 removedDonatedInsuranceFund,
            int256 removedPoolMargin
        )
    {
        require(
            shareTotalSupply > 0,
            "total supply of share token is zero when removing liquidity"
        );
        Context memory context = prepareContext(liquidityPool);
        require(isAMMSafe(context, 0), "AMM is unsafe before removing liquidity");
        removedPoolMargin = calculatePoolMarginWhenSafe(context, 0);
        require(removedPoolMargin > 0, "pool margin must be positive");
        int256 poolMargin = shareTotalSupply.sub(shareToRemove).wfrac(
            removedPoolMargin,
            shareTotalSupply
        );
        removedPoolMargin = removedPoolMargin.sub(poolMargin);
        {
            int256 minPoolMargin = context.squareValue.div(2).sqrt();
            require(poolMargin >= minPoolMargin, "AMM is unsafe after removing liquidity");
        }
        cashToReturn = calculateCashToReturn(context, poolMargin);
        require(cashToReturn >= 0, "received margin is negative");
        uint256 length = liquidityPool.perpetualCount;
        bool allCleared = true;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            if (perpetual.state != PerpetualState.CLEARED) {
                allCleared = false;
            }
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            // prevent AMM offering negative price
            require(
                perpetual.getPosition(address(this)) <=
                    poolMargin.wdiv(perpetual.openSlippageFactor.value).wdiv(
                        perpetual.getIndexPrice()
                    ),
                "AMM is unsafe after removing liquidity"
            );
        }
        // prevent AMM exceeding max leverage
        require(
            context.availableCash.add(context.positionValue).sub(cashToReturn) >=
                context.positionMargin,
            "AMM exceeds max leverage after removing liquidity"
        );
        if (allCleared) {
            // get insurance fund proportionally
            removedInsuranceFund = liquidityPool.insuranceFund.wfrac(
                shareToRemove,
                shareTotalSupply,
                Round.FLOOR
            );
            removedDonatedInsuranceFund = liquidityPool.donatedInsuranceFund.wfrac(
                shareToRemove,
                shareTotalSupply,
                Round.FLOOR
            );
            cashToReturn = cashToReturn.add(removedInsuranceFund).add(removedDonatedInsuranceFund);
        }
    }

    /**
     * @dev     Calculate the amount of share token to redeem when liquidity provider removes liquidity from the liquidity pool.
     *          Removing liquidity is forbidden at several cases:
     *            1. AMM is unsafe before removing liquidity
     *            2. AMM is unsafe after removing liquidity
     *            3. AMM will offer negative price at any perpetual after removing liquidity
     *            4. AMM will exceed maximum leverage at any perpetual after removing liquidity
     *
     * @param   liquidityPool                The liquidity pool object of AMM.
     * @param   shareTotalSupply             The total supply of the share token before removing liquidity.
     * @param   cashToReturn                 The cash(collateral) to return.
     * @return  shareToRemove                The amount of share token to redeem.
     * @return  removedInsuranceFund         The part of insurance fund returned to LP if all perpetuals are in CLEARED state.
     * @return  removedDonatedInsuranceFund  The part of donated insurance fund returned to LP if all perpetuals are in CLEARED state.
     * @return  removedPoolMargin            The removed amount of pool margin after removing liquidity.
     */
    function getShareToRemove(
        LiquidityPoolStorage storage liquidityPool,
        int256 shareTotalSupply,
        int256 cashToReturn
    )
        public
        view
        returns (
            int256 shareToRemove,
            int256 removedInsuranceFund,
            int256 removedDonatedInsuranceFund,
            int256 removedPoolMargin
        )
    {
        require(
            shareTotalSupply > 0,
            "total supply of share token is zero when removing liquidity"
        );
        Context memory context = prepareContext(liquidityPool);
        require(isAMMSafe(context, 0), "AMM is unsafe before removing liquidity");
        int256 poolMargin = calculatePoolMarginWhenSafe(context, 0);
        context.availableCash = context.availableCash.sub(cashToReturn);
        require(isAMMSafe(context, 0), "AMM is unsafe after removing liquidity");
        int256 newPoolMargin = calculatePoolMarginWhenSafe(context, 0);
        removedPoolMargin = poolMargin.sub(newPoolMargin);
        shareToRemove = poolMargin.sub(newPoolMargin).wfrac(shareTotalSupply, poolMargin);
        uint256 length = liquidityPool.perpetualCount;
        bool allCleared = true;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            if (perpetual.state != PerpetualState.CLEARED) {
                allCleared = false;
            }
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            // prevent AMM offering negative price
            require(
                perpetual.getPosition(address(this)) <=
                    newPoolMargin.wdiv(perpetual.openSlippageFactor.value).wdiv(
                        perpetual.getIndexPrice()
                    ),
                "AMM is unsafe after removing liquidity"
            );
        }
        // prevent AMM exceeding max leverage
        require(
            context.availableCash.add(context.positionValue) >= context.positionMargin,
            "AMM exceeds max leverage after removing liquidity"
        );
        if (allCleared) {
            // get insurance fund proportionally
            (
                shareToRemove,
                removedInsuranceFund,
                removedDonatedInsuranceFund,
                removedPoolMargin
            ) = getShareToRemoveWhenAllCleared(
                liquidityPool,
                cashToReturn,
                poolMargin,
                shareTotalSupply
            );
        }
    }

    /**
     * @dev     Calculate the amount of share token to redeem when liquidity provider removes liquidity from the liquidity pool.
     *          Only called when all perpetuals in the liquidity pool are in CLEARED state.
     *
     * @param   liquidityPool                The liquidity pool object of AMM.
     * @param   cashToReturn                 The cash(collateral) to return.
     * @param   poolMargin                   The pool margin before removing liquidity.
     * @param   shareTotalSupply             The total supply of the share token before removing liquidity.
     * @return  shareToRemove                The amount of share token to redeem.
     * @return  removedInsuranceFund         The part of insurance fund returned to LP if all perpetuals are in CLEARED state.
     * @return  removedDonatedInsuranceFund  The part of donated insurance fund returned to LP if all perpetuals are in CLEARED state.
     * @return  removedPoolMargin            The part of pool margin returned to LP if all perpetuals are in CLEARED state.
     */
    function getShareToRemoveWhenAllCleared(
        LiquidityPoolStorage storage liquidityPool,
        int256 cashToReturn,
        int256 poolMargin,
        int256 shareTotalSupply
    )
        public
        view
        returns (
            int256 shareToRemove,
            int256 removedInsuranceFund,
            int256 removedDonatedInsuranceFund,
            int256 removedPoolMargin
        )
    {
        // get insurance fund proportionally
        require(
            poolMargin.add(liquidityPool.insuranceFund).add(liquidityPool.donatedInsuranceFund) > 0,
            "all cleared, insufficient liquidity"
        );
        shareToRemove = shareTotalSupply.wfrac(
            cashToReturn,
            poolMargin.add(liquidityPool.insuranceFund).add(liquidityPool.donatedInsuranceFund)
        );
        removedInsuranceFund = liquidityPool.insuranceFund.wfrac(
            shareToRemove,
            shareTotalSupply,
            Round.FLOOR
        );
        removedDonatedInsuranceFund = liquidityPool.donatedInsuranceFund.wfrac(
            shareToRemove,
            shareTotalSupply,
            Round.FLOOR
        );
        removedPoolMargin = poolMargin.wfrac(shareToRemove, shareTotalSupply, Round.FLOOR);
    }

    /**
     * @dev     Calculate the pool margin of AMM when AMM is safe.
     *          Pool margin is how much collateral of the pool considering the AMM's positions of perpetuals.
     *
     * @param   context         Context object of AMM, but current perpetual is not included.
     * @param   slippageFactor  The slippage factor of current perpetual.
     * @return  poolMargin      The pool margin of AMM.
     */
    function calculatePoolMarginWhenSafe(Context memory context, int256 slippageFactor)
        internal
        pure
        returns (int256 poolMargin)
    {
        // The context doesn't include the current perpetual, add them.
        int256 positionValue = context.indexPrice.wmul(context.position);
        int256 margin = positionValue.add(context.positionValue).add(context.availableCash);
        // 10^36, the same as context.squareValue
        int256 tmp = positionValue.wmul(positionValue).mul(slippageFactor).add(context.squareValue);
        int256 beforeSqrt = margin.mul(margin).sub(tmp.mul(2));
        require(beforeSqrt >= 0, "AMM is unsafe when calculating pool margin");
        poolMargin = beforeSqrt.sqrt().add(margin).div(2);
        require(poolMargin >= 0, "pool margin is negative when calculating pool margin");
    }

    /**
     * @dev     Check if AMM is safe
     * @param   context         Context object of AMM, but current perpetual is not included.
     * @param   slippageFactor  The slippage factor of current perpetual.
     * @return  bool            True if AMM is safe.
     */
    function isAMMSafe(Context memory context, int256 slippageFactor) internal pure returns (bool) {
        int256 positionValue = context.indexPrice.wmul(context.position);
        // 10^36, the same as context.squareValue
        int256 minAvailableCash = positionValue.wmul(positionValue).mul(slippageFactor);
        minAvailableCash = minAvailableCash.add(context.squareValue).mul(2).sqrt().sub(
            context.positionValue.add(positionValue)
        );
        return context.availableCash >= minAvailableCash;
    }

    /**
     * @dev     Get the trading result when AMM closes its position.
     *          If the AMM is unsafe, the trading price is the best price.
     *          If trading price is too bad, it will be limited to index price * (1 +/- max close price discount)
     *
     * @param   context     Context object of AMM, but current perpetual is not included.
     * @param   perpetual   The perpetual object to trade.
     * @param   tradeAmount The amount of position to trade.
     *                      Positive for long and negative for short from AMM's perspective.
     * @return  deltaCash   The update cash(collateral) of AMM after the trade.
     * @return  bestPrice   The best price, is used for clipping to spread price if needed outside.
     *                      If AMM is safe, best price = middle price * (1 +/- half spread).
     *                      If AMM is unsafe and normal case, best price = index price.
     */
    function ammClosePosition(
        Context memory context,
        PerpetualStorage storage perpetual,
        int256 tradeAmount
    ) internal view returns (int256 deltaCash, int256 bestPrice) {
        if (tradeAmount == 0) {
            return (0, 0);
        }
        int256 positionBefore = context.position;
        int256 indexPrice = context.indexPrice;
        int256 slippageFactor = perpetual.closeSlippageFactor.value;
        int256 maxClosePriceDiscount = perpetual.maxClosePriceDiscount.value;
        int256 halfSpread = tradeAmount < 0
            ? perpetual.halfSpread.value
            : perpetual.halfSpread.value.neg();
        if (isAMMSafe(context, slippageFactor)) {
            int256 poolMargin = calculatePoolMarginWhenSafe(context, slippageFactor);
            require(poolMargin > 0, "pool margin must be positive");
            bestPrice = getMidPrice(poolMargin, indexPrice, positionBefore, slippageFactor).wmul(
                halfSpread.add(Constant.SIGNED_ONE)
            );
            deltaCash = getDeltaCash(
                poolMargin,
                positionBefore,
                positionBefore.add(tradeAmount),
                indexPrice,
                slippageFactor
            );
        } else {
            bestPrice = indexPrice;
            deltaCash = bestPrice.wmul(tradeAmount).neg();
        }
        int256 priceLimit = tradeAmount > 0
            ? Constant.SIGNED_ONE.add(maxClosePriceDiscount)
            : Constant.SIGNED_ONE.sub(maxClosePriceDiscount);
        // prevent too bad price
        deltaCash = deltaCash.max(indexPrice.wmul(priceLimit).wmul(tradeAmount).neg());
        // prevent negative price
        require(
            !Utils.hasTheSameSign(deltaCash, tradeAmount),
            "price is negative when AMM closes position"
        );
    }

    /**
     * @dev     Get the trading result when AMM opens its position.
     *          AMM can't open position when unsafe and can't open position to exceed the maximum position
     *
     * @param   context     Context object of AMM, but current perpetual is not included.
     * @param   perpetual   The perpetual object to trade
     * @param   tradeAmount The trading amount of position, positive if AMM longs, negative if AMM shorts
     * @param   partialFill Whether to allow partially trading. Set to true when liquidation trading,
     *                      set to false when normal trading
     * @return  deltaCash       The update cash(collateral) of AMM after the trade
     * @return  deltaPosition   The update position of AMM after the trade
     * @return  bestPrice       The best price, is used for clipping to spread price if needed outside.
     *                          Equal to middle price * (1 +/- half spread)
     */
    function ammOpenPosition(
        Context memory context,
        PerpetualStorage storage perpetual,
        int256 tradeAmount,
        bool partialFill
    )
        internal
        view
        returns (
            int256 deltaCash,
            int256 deltaPosition,
            int256 bestPrice
        )
    {
        if (tradeAmount == 0) {
            return (0, 0, 0);
        }
        int256 slippageFactor = perpetual.openSlippageFactor.value;
        if (!isAMMSafe(context, slippageFactor)) {
            require(partialFill, "AMM is unsafe when open");
            return (0, 0, 0);
        }
        int256 poolMargin = calculatePoolMarginWhenSafe(context, slippageFactor);
        require(poolMargin > 0, "pool margin must be positive");
        int256 indexPrice = context.indexPrice;
        int256 positionBefore = context.position;
        int256 positionAfter = positionBefore.add(tradeAmount);
        int256 maxPosition = getMaxPosition(
            context,
            poolMargin,
            perpetual.ammMaxLeverage.value,
            slippageFactor,
            positionAfter > 0
        );
        if (positionAfter.abs() > maxPosition.abs()) {
            require(partialFill, "trade amount exceeds max amount");
            // trade to max position if partialFill
            deltaPosition = maxPosition.sub(positionBefore);
            // current position already exeeds max position before trade, can't open
            if (Utils.hasTheSameSign(deltaPosition, tradeAmount.neg())) {
                return (0, 0, 0);
            }
            positionAfter = maxPosition;
        } else {
            deltaPosition = tradeAmount;
        }
        deltaCash = getDeltaCash(
            poolMargin,
            positionBefore,
            positionAfter,
            indexPrice,
            slippageFactor
        );
        // prevent negative price
        require(
            !Utils.hasTheSameSign(deltaCash, deltaPosition),
            "price is negative when AMM opens position"
        );
        int256 halfSpread = tradeAmount < 0
            ? perpetual.halfSpread.value
            : perpetual.halfSpread.value.neg();
        bestPrice = getMidPrice(poolMargin, indexPrice, positionBefore, slippageFactor).wmul(
            halfSpread.add(Constant.SIGNED_ONE)
        );
    }

    /**
     * @dev     Calculate the status of AMM
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @return  context         Context object of AMM, but current perpetual is not included.
     */
    function prepareContext(LiquidityPoolStorage storage liquidityPool)
        internal
        view
        returns (Context memory context)
    {
        context = prepareContext(liquidityPool, liquidityPool.perpetualCount);
    }

    /**
     * @dev     Calculate the status of AMM, but specified perpetual index is not included.
     *
     * @param   liquidityPool   The reference of liquidity pool storage.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool to distinguish,
     *                          set to liquidityPool.perpetualCount to skip distinguishing.
     * @return  context         Context object of AMM.
     */
    function prepareContext(LiquidityPoolStorage storage liquidityPool, uint256 perpetualIndex)
        internal
        view
        returns (Context memory context)
    {
        int256 maintenanceMargin;
        uint256 length = liquidityPool.perpetualCount;
        for (uint256 i = 0; i < length; i++) {
            PerpetualStorage storage perpetual = liquidityPool.perpetuals[i];
            // only involve normal market
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            int256 position = perpetual.getPosition(address(this));
            int256 indexPrice = perpetual.getIndexPrice();
            require(indexPrice > 0, "index price must be positive");
            context.availableCash = context.availableCash.add(
                perpetual.getAvailableCash(address(this))
            );
            maintenanceMargin = maintenanceMargin.add(
                indexPrice.wmul(position).wmul(perpetual.maintenanceMarginRate).abs()
            );
            if (i == perpetualIndex) {
                context.indexPrice = indexPrice;
                context.position = position;
            } else {
                // To avoid returning more cash than pool has because of precision error,
                // cashToReturn should be smaller, which means positionValue should be smaller, squareValue should be bigger
                context.positionValue = context.positionValue.add(
                    indexPrice.wmul(position, Round.FLOOR)
                );
                // 10^36
                context.squareValue = context.squareValue.add(
                    position
                        .wmul(position, Round.CEIL)
                        .wmul(indexPrice, Round.CEIL)
                        .wmul(indexPrice, Round.CEIL)
                        .mul(perpetual.openSlippageFactor.value)
                );
                context.positionMargin = context.positionMargin.add(
                    indexPrice.wmul(position).abs().wdiv(perpetual.ammMaxLeverage.value)
                );
            }
        }
        context.availableCash = context.availableCash.add(liquidityPool.poolCash);
        // prevent margin balance < maintenance margin.
        // call setEmergencyState(SET_ALL_PERPETUALS_TO_EMERGENCY_STATE) when AMM is maintenance margin unsafe
        require(
            context.availableCash.add(context.positionValue).add(
                context.indexPrice.wmul(context.position)
            ) >= maintenanceMargin,
            "AMM is mm unsafe"
        );
    }

    /**
     * @dev     Calculate the cash(collateral) to return when removing liquidity.
     *
     * @param   context         Context object of AMM, but current perpetual is not included.
     * @param   poolMargin      The pool margin of AMM before removing liquidity.
     * @return  cashToReturn    The cash(collateral) to return.
     */
    function calculateCashToReturn(Context memory context, int256 poolMargin)
        public
        pure
        returns (int256 cashToReturn)
    {
        if (poolMargin == 0) {
            // remove all
            return context.availableCash;
        }
        require(poolMargin > 0, "pool margin must be positive when removing liquidity");
        // context.squareValue is 10^36, so use div instead of wdiv
        cashToReturn = context.squareValue.div(poolMargin).div(2).add(poolMargin).sub(
            context.positionValue
        );
        cashToReturn = context.availableCash.sub(cashToReturn);
    }

    /**
     * @dev     Get the middle price offered by AMM
     *
     * @param   poolMargin      The pool margin of AMM.
     * @param   indexPrice      The index price of the perpetual.
     * @param   position        The position of AMM in the perpetual.
     * @param   slippageFactor  The slippage factor of AMM in the perpetual.
     * @return  midPrice        A middle price offered by AMM.
     */
    function getMidPrice(
        int256 poolMargin,
        int256 indexPrice,
        int256 position,
        int256 slippageFactor
    ) internal pure returns (int256 midPrice) {
        midPrice = Constant
            .SIGNED_ONE
            .sub(indexPrice.wmul(position).wfrac(slippageFactor, poolMargin))
            .wmul(indexPrice);
    }

    /**
     * @dev     Get update cash(collateral) of AMM if trader trades against AMM.
     *
     * @param   poolMargin      The pool margin of AMM.
     * @param   positionBefore  The position of AMM in the perpetual before trading.
     * @param   positionAfter   The position of AMM in the perpetual after trading.
     * @param   indexPrice      The index price of the perpetual.
     * @param   slippageFactor  The slippage factor of AMM in the perpetual.
     * @return  deltaCash       The update cash(collateral) of AMM after trading.
     */
    function getDeltaCash(
        int256 poolMargin,
        int256 positionBefore,
        int256 positionAfter,
        int256 indexPrice,
        int256 slippageFactor
    ) internal pure returns (int256 deltaCash) {
        deltaCash = positionAfter.add(positionBefore).wmul(indexPrice).div(2).wfrac(
            slippageFactor,
            poolMargin
        );
        deltaCash = Constant.SIGNED_ONE.sub(deltaCash).wmul(indexPrice).wmul(
            positionBefore.sub(positionAfter)
        );
    }

    /**
     * @dev     Get the max position of AMM in the perpetual when AMM is opening position, calculated by three restrictions:
     *          1. AMM must be safe after the trade.
     *          2. AMM mustn't exceed maximum leverage in any perpetual after the trade.
     *          3. AMM must offer positive price in any perpetual after the trade. It's easy to prove that, in the
     *             perpetual, AMM definitely offers positive price when AMM holds short position.
     *
     * @param   context         Context object of AMM, but current perpetual is not included.
     * @param   poolMargin      The pool margin of AMM.
     * @param   ammMaxLeverage  The max leverage of AMM in the perpetual.
     * @param   slippageFactor  The slippage factor of AMM in the perpetual.
     * @return  maxPosition     The max position of AMM in the perpetual.
     */
    function getMaxPosition(
        Context memory context,
        int256 poolMargin,
        int256 ammMaxLeverage,
        int256 slippageFactor,
        bool isLongSide
    ) internal pure returns (int256 maxPosition) {
        int256 indexPrice = context.indexPrice;
        int256 beforeSqrt = poolMargin.mul(poolMargin).mul(2).sub(context.squareValue).wdiv(
            slippageFactor
        );
        if (beforeSqrt <= 0) {
            // 1. already unsafe, can't open position
            // 2. initial AMM is also this case, position = 0, available cash = 0, pool margin = 0
            return 0;
        }
        int256 maxPosition3 = beforeSqrt.sqrt().wdiv(indexPrice);
        int256 maxPosition2;
        // context.squareValue is 10^36, so use div instead of wdiv
        beforeSqrt = poolMargin.sub(context.positionMargin).add(
            context.squareValue.div(poolMargin).div(2)
        );
        beforeSqrt = beforeSqrt.wmul(ammMaxLeverage).wmul(ammMaxLeverage).wmul(slippageFactor);
        beforeSqrt = poolMargin.sub(beforeSqrt.mul(2));
        if (beforeSqrt < 0) {
            // never exceed max leverage
            maxPosition2 = type(int256).max;
        } else {
            // might be negative, clip to zero
            maxPosition2 = poolMargin.sub(beforeSqrt.mul(poolMargin).sqrt()).max(0);
            maxPosition2 = maxPosition2.wdiv(ammMaxLeverage).wdiv(slippageFactor).wdiv(indexPrice);
        }
        maxPosition = maxPosition3.min(maxPosition2);
        if (isLongSide) {
            // long side has one more restriction than short side
            int256 maxPosition1 = poolMargin.wdiv(slippageFactor).wdiv(indexPrice);
            maxPosition = maxPosition.min(maxPosition1);
        } else {
            maxPosition = maxPosition.neg();
        }
    }

    /**
     * @dev     Get pool margin of AMM, equal to 1/2 margin of AMM when AMM is unsafe.
     *          Marin of AMM: cash + index price1 * position1 + index price2 * position2 + ...
     *
     * @param   context     Context object of AMM, but current perpetual is not included.
     * @return  poolMargin  The pool margin of AMM.
     * @return  isSafe      True if AMM is safe or false.
     */
    function getPoolMargin(Context memory context)
        internal
        pure
        returns (int256 poolMargin, bool isSafe)
    {
        isSafe = isAMMSafe(context, 0);
        if (isSafe) {
            poolMargin = calculatePoolMarginWhenSafe(context, 0);
        } else {
            poolMargin = context.availableCash.add(context.positionValue).div(2);
            require(poolMargin >= 0, "pool margin is negative when getting pool margin");
        }
    }

    /**
     * @dev Get pool margin of AMM, prepare context first.
     * @param liquidityPool The liquidity pool object
     * @return int256 The pool margin of AMM
     * @return bool True if AMM is safe
     */
    function getPoolMargin(LiquidityPoolStorage storage liquidityPool)
        public
        view
        returns (int256, bool)
    {
        return getPoolMargin(prepareContext(liquidityPool));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "../interface/IDecimals.sol";

import "../libraries/Constant.sol";

import "../Type.sol";

/**
 * @title   Collateral Module
 * @dev     Handle underlying collaterals.
 *          In this file, parameter named with:
 *              - [amount] means internal amount
 *              - [rawAmount] means amount in decimals of underlying collateral
 */
library CollateralModule {
    using SafeMathUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using SafeCastUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant SYSTEM_DECIMALS = 18;

    /**
     * @notice  Initialize the collateral of the liquidity pool. Set up address, scaler and decimals of collateral
     * @param   liquidityPool       The liquidity pool object
     * @param   collateral          The address of the collateral
     * @param   collateralDecimals  The decimals of the collateral, must less than SYSTEM_DECIMALS,
     *                              must equal to decimals() if the function exists
     */
    function initializeCollateral(
        LiquidityPoolStorage storage liquidityPool,
        address collateral,
        uint256 collateralDecimals
    ) public {
        require(collateralDecimals <= SYSTEM_DECIMALS, "collateral decimals is out of range");
        try IDecimals(collateral).decimals() returns (uint8 decimals) {
            require(decimals == collateralDecimals, "decimals not match");
        } catch {}
        uint256 factor = 10**(SYSTEM_DECIMALS.sub(collateralDecimals));
        liquidityPool.scaler = (factor == 0 ? 1 : factor);
        liquidityPool.collateralToken = collateral;
        liquidityPool.collateralDecimals = collateralDecimals;
    }

    /**
     * @notice  Transfer collateral from the account to the liquidity pool.
     * @param   liquidityPool   The liquidity pool object
     * @param   account         The address of the account
     * @param   amount          The amount of erc20 token to transfer. Always use decimals 18.
     */
    function transferFromUser(
        LiquidityPoolStorage storage liquidityPool,
        address account,
        int256 amount
    ) public {
        if (amount <= 0) {
            return;
        }
        uint256 rawAmount = _toRawAmountRoundUp(liquidityPool, amount);
        IERC20Upgradeable collateralToken = IERC20Upgradeable(liquidityPool.collateralToken);
        uint256 previousBalance = collateralToken.balanceOf(address(this));
        collateralToken.safeTransferFrom(account, address(this), rawAmount);
        uint256 postBalance = collateralToken.balanceOf(address(this));
        require(postBalance.sub(previousBalance) == rawAmount, "incorrect transferred in amount");
    }

    /**
     * @notice  Transfer collateral from the liquidity pool to the account.
     * @param   liquidityPool   The liquidity pool object
     * @param   account         The address of the account
     * @param   amount          The amount of collateral to transfer. always use decimals 18.
     */
    function transferToUser(
        LiquidityPoolStorage storage liquidityPool,
        address account,
        int256 amount
    ) public {
        if (amount <= 0) {
            return;
        }
        uint256 rawAmount = _toRawAmount(liquidityPool, amount);
        IERC20Upgradeable collateralToken = IERC20Upgradeable(liquidityPool.collateralToken);
        uint256 previousBalance = collateralToken.balanceOf(address(this));
        collateralToken.safeTransfer(account, rawAmount);
        uint256 postBalance = collateralToken.balanceOf(address(this));
        require(previousBalance.sub(postBalance) == rawAmount, "incorrect transferred out amount");
    }

    function _toRawAmount(LiquidityPoolStorage storage liquidityPool, int256 amount)
        private
        view
        returns (uint256 rawAmount)
    {
        rawAmount = amount.toUint256().div(liquidityPool.scaler);
    }

    function _toRawAmountRoundUp(LiquidityPoolStorage storage liquidityPool, int256 amount)
        private
        view
        returns (uint256 rawAmount)
    {
        rawAmount = amount.toUint256();
        rawAmount = rawAmount.div(liquidityPool.scaler).add(
            rawAmount % liquidityPool.scaler > 0 ? 1 : 0
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "../libraries/SafeMathExt.sol";
import "../libraries/Utils.sol";

import "../Type.sol";

library MarginAccountModule {
    using SafeMathExt for int256;
    using SafeCastUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    /**
     * @dev Get the initial margin of the trader in the perpetual.
     *      Initial margin = price * abs(position) * initial margin rate
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @param price The price to calculate the initial margin
     * @return initialMargin The initial margin of the trader in the perpetual
     */
    function getInitialMargin(
        PerpetualStorage storage perpetual,
        address trader,
        int256 price
    ) internal view returns (int256 initialMargin) {
        initialMargin = perpetual
            .marginAccounts[trader]
            .position
            .wmul(price)
            .wmul(perpetual.initialMarginRate)
            .abs();
    }

    /**
     * @dev Get the maintenance margin of the trader in the perpetual.
     *      Maintenance margin = price * abs(position) * maintenance margin rate
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @param price The price to calculate the  maintenance margin
     * @return maintenanceMargin The maintenance margin of the trader in the perpetual
     */
    function getMaintenanceMargin(
        PerpetualStorage storage perpetual,
        address trader,
        int256 price
    ) internal view returns (int256 maintenanceMargin) {
        maintenanceMargin = perpetual
            .marginAccounts[trader]
            .position
            .wmul(price)
            .wmul(perpetual.maintenanceMarginRate)
            .abs();
    }

    /**
     * @dev Get the available cash of the trader in the perpetual.
     *      Available cash = cash - position * unit accumulative funding
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @return availableCash The available cash of the trader in the perpetual
     */
    function getAvailableCash(PerpetualStorage storage perpetual, address trader)
        internal
        view
        returns (int256 availableCash)
    {
        MarginAccount storage account = perpetual.marginAccounts[trader];
        availableCash = account.cash.sub(account.position.wmul(perpetual.unitAccumulativeFunding));
    }

    /**
     * @dev Get the position of the trader in the perpetual
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @return position The position of the trader in the perpetual
     */
    function getPosition(PerpetualStorage storage perpetual, address trader)
        internal
        view
        returns (int256 position)
    {
        position = perpetual.marginAccounts[trader].position;
    }

    /**
     * @dev Get the margin of the trader in the perpetual.
     *      Margin = available cash + position * price
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @param price The price to calculate the margin
     * @return margin The margin of the trader in the perpetual
     */
    function getMargin(
        PerpetualStorage storage perpetual,
        address trader,
        int256 price
    ) internal view returns (int256 margin) {
        margin = perpetual.marginAccounts[trader].position.wmul(price).add(
            getAvailableCash(perpetual, trader)
        );
    }

    /**
     * @dev Get the settleable margin of the trader in the perpetual.
     *      This is the margin trader can withdraw when the state of the perpetual is "CLEARED".
     *      If the state of the perpetual is not "CLEARED", the settleable margin is always zero
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @param price The price to calculate the settleable margin
     * @return margin The settleable margin of the trader in the perpetual
     */
    function getSettleableMargin(
        PerpetualStorage storage perpetual,
        address trader,
        int256 price
    ) internal view returns (int256 margin) {
        margin = getMargin(perpetual, trader, price);
        if (margin > 0) {
            int256 rate = (getPosition(perpetual, trader) == 0)
                ? perpetual.redemptionRateWithoutPosition
                : perpetual.redemptionRateWithPosition;
            // make sure total redemption margin < total collateral of perpetual
            margin = margin.wmul(rate, Round.FLOOR);
        } else {
            margin = 0;
        }
    }

    /**
     * @dev     Get the available margin of the trader in the perpetual.
     *          Available margin = margin - (initial margin + keeper gas reward), keeper gas reward = 0 if position = 0
     * @param   perpetual   The perpetual object
     * @param   trader      The address of the trader
     * @param   price       The price to calculate available margin
     * @return  availableMargin The available margin of the trader in the perpetual
     */
    function getAvailableMargin(
        PerpetualStorage storage perpetual,
        address trader,
        int256 price
    ) internal view returns (int256 availableMargin) {
        int256 threshold = getPosition(perpetual, trader) == 0
            ? 0
            : getInitialMargin(perpetual, trader, price).add(perpetual.keeperGasReward);
        availableMargin = getMargin(perpetual, trader, price).sub(threshold);
    }

    /**
     * @dev     Check if the trader is initial margin safe in the perpetual, which means available margin >= 0
     * @param   perpetual   The perpetual object
     * @param   trader      The address of the trader
     * @param   price       The price to calculate the available margin
     * @return  isSafe      True if the trader is initial margin safe in the perpetual
     */
    function isInitialMarginSafe(
        PerpetualStorage storage perpetual,
        address trader,
        int256 price
    ) internal view returns (bool isSafe) {
        isSafe = (getAvailableMargin(perpetual, trader, price) >= 0);
    }

    /**
     * @dev Check if the trader is maintenance margin safe in the perpetual, which means
     *      margin >= maintenance margin + keeper gas reward. Keeper gas reward = 0 if position = 0
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @param price The price to calculate the maintenance margin
     * @return isSafe True if the trader is maintenance margin safe in the perpetual
     */
    function isMaintenanceMarginSafe(
        PerpetualStorage storage perpetual,
        address trader,
        int256 price
    ) internal view returns (bool isSafe) {
        int256 threshold = getPosition(perpetual, trader) == 0
            ? 0
            : getMaintenanceMargin(perpetual, trader, price).add(perpetual.keeperGasReward);
        isSafe = getMargin(perpetual, trader, price) >= threshold;
    }

    /**
     * @dev Check if the trader is margin safe in the perpetual, which means margin >= keeper gas reward.
     *      Keeper gas reward = 0 if position = 0
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @param price The price to calculate the margin
     * @return isSafe True if the trader is margin safe in the perpetual
     */
    function isMarginSafe(
        PerpetualStorage storage perpetual,
        address trader,
        int256 price
    ) internal view returns (bool isSafe) {
        int256 threshold = getPosition(perpetual, trader) == 0 ? 0 : perpetual.keeperGasReward;
        isSafe = getMargin(perpetual, trader, price) >= threshold;
    }

    /**
     * @dev Check if the account of the trader is empty in the perpetual, which means cash = 0 and position = 0
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @return isEmpty True if the account of the trader is empty in the perpetual
     */
    function isEmptyAccount(PerpetualStorage storage perpetual, address trader)
        internal
        view
        returns (bool isEmpty)
    {
        MarginAccount storage account = perpetual.marginAccounts[trader];
        isEmpty = (account.cash == 0 && account.position == 0);
    }

    /**
     * @dev Update the trader's cash in the perpetual
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @param deltaCash The update cash(collateral) of the trader's account in the perpetual
     */
    function updateCash(
        PerpetualStorage storage perpetual,
        address trader,
        int256 deltaCash
    ) internal {
        if (deltaCash == 0) {
            return;
        }
        MarginAccount storage account = perpetual.marginAccounts[trader];
        account.cash = account.cash.add(deltaCash);
    }

    /**
     * @dev Update the trader's account in the perpetual
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     * @param deltaPosition The update position of the trader's account in the perpetual
     * @param deltaCash The update cash(collateral) of the trader's account in the perpetual
     */
    function updateMargin(
        PerpetualStorage storage perpetual,
        address trader,
        int256 deltaPosition,
        int256 deltaCash
    ) internal returns (int256 deltaOpenInterest) {
        MarginAccount storage account = perpetual.marginAccounts[trader];
        int256 oldPosition = account.position;
        account.position = account.position.add(deltaPosition);
        account.cash = account.cash.add(deltaCash).add(
            perpetual.unitAccumulativeFunding.wmul(deltaPosition)
        );
        if (oldPosition > 0) {
            deltaOpenInterest = oldPosition.neg();
        }
        if (account.position > 0) {
            deltaOpenInterest = deltaOpenInterest.add(account.position);
        }
        perpetual.openInterest = perpetual.openInterest.add(deltaOpenInterest);
    }

    /**
     * @dev Reset the trader's account in the perpetual to empty, which means position = 0 and cash = 0
     * @param perpetual The perpetual object
     * @param trader The address of the trader
     */
    function resetAccount(PerpetualStorage storage perpetual, address trader) internal {
        MarginAccount storage account = perpetual.marginAccounts[trader];
        account.cash = 0;
        account.position = 0;
    }

    function setTargetLeverage(
        PerpetualStorage storage perpetual,
        address trader,
        int256 targetLeverage
    ) internal {
        perpetual.marginAccounts[trader].targetLeverage = targetLeverage;
    }

    function getTargetLeverage(PerpetualStorage storage perpetual, address trader)
        internal
        view
        returns (int256)
    {
        require(perpetual.initialMarginRate != 0, "initialMarginRate is not set");
        int256 maxLeverage = Constant.SIGNED_ONE.wdiv(perpetual.initialMarginRate);
        int256 targetLeverage = perpetual.marginAccounts[trader].targetLeverage;
        targetLeverage = targetLeverage == 0
            ? perpetual.defaultTargetLeverage.value
            : targetLeverage;
        return targetLeverage.min(maxLeverage);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "../interface/IOracle.sol";
import "../libraries/SafeMathExt.sol";
import "../libraries/Utils.sol";
import "../Type.sol";
import "./MarginAccountModule.sol";

library PerpetualModule {
    using SafeMathUpgradeable for uint256;
    using SafeMathExt for int256;
    using SafeCastUpgradeable for int256;
    using SafeCastUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SignedSafeMathUpgradeable for int256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using MarginAccountModule for PerpetualStorage;

    int256 constant FUNDING_INTERVAL = 3600 * 8;

    uint256 internal constant INDEX_INITIAL_MARGIN_RATE = 0;
    uint256 internal constant INDEX_MAINTENANCE_MARGIN_RATE = 1;
    uint256 internal constant INDEX_OPERATOR_FEE_RATE = 2;
    uint256 internal constant INDEX_LP_FEE_RATE = 3;
    uint256 internal constant INDEX_REFERRAL_REBATE_RATE = 4;
    uint256 internal constant INDEX_LIQUIDATION_PENALTY_RATE = 5;
    uint256 internal constant INDEX_KEEPER_GAS_REWARD = 6;
    uint256 internal constant INDEX_INSURANCE_FUND_RATE = 7;
    uint256 internal constant INDEX_MAX_OPEN_INTEREST_RATE = 8;

    uint256 internal constant INDEX_HALF_SPREAD = 0;
    uint256 internal constant INDEX_OPEN_SLIPPAGE_FACTOR = 1;
    uint256 internal constant INDEX_CLOSE_SLIPPAGE_FACTOR = 2;
    uint256 internal constant INDEX_FUNDING_RATE_LIMIT = 3;
    uint256 internal constant INDEX_AMM_MAX_LEVERAGE = 4;
    uint256 internal constant INDEX_AMM_CLOSE_PRICE_DISCOUNT = 5;
    uint256 internal constant INDEX_FUNDING_RATE_FACTOR = 6;
    uint256 internal constant INDEX_DEFAULT_TARGET_LEVERAGE = 7;

    event Deposit(uint256 perpetualIndex, address indexed trader, int256 amount);
    event Withdraw(uint256 perpetualIndex, address indexed trader, int256 amount);
    event Clear(uint256 perpetualIndex, address indexed trader);
    event Settle(uint256 perpetualIndex, address indexed trader, int256 amount);
    event SetNormalState(uint256 perpetualIndex);
    event SetEmergencyState(uint256 perpetualIndex, int256 settlementPrice, uint256 settlementTime);
    event SetClearedState(uint256 perpetualIndex);
    event UpdateUnitAccumulativeFunding(uint256 perpetualIndex, int256 unitAccumulativeFunding);
    event SetPerpetualBaseParameter(uint256 perpetualIndex, int256[9] baseParams);
    event SetPerpetualRiskParameter(
        uint256 perpetualIndex,
        int256[8] riskParams,
        int256[8] minRiskParamValues,
        int256[8] maxRiskParamValues
    );
    event UpdatePerpetualRiskParameter(uint256 perpetualIndex, int256[8] riskParams);
    event SetOracle(uint256 perpetualIndex, address indexed oldOracle, address indexed newOracle);
    event UpdatePrice(
        uint256 perpetualIndex,
        address indexed oracle,
        int256 markPrice,
        uint256 markPriceUpdateTime,
        int256 indexPrice,
        uint256 indexPriceUpdateTime
    );
    event UpdateFundingRate(uint256 perpetualIndex, int256 fundingRate);

    /**
     * @dev     Get the mark price of the perpetual. If the state of the perpetual is not "NORMAL",
     *          return the settlement price
     * @param   perpetual   The reference of perpetual storage.
     * @return  markPrice   The mark price of current perpetual.
     */
    function getMarkPrice(PerpetualStorage storage perpetual)
        internal
        view
        returns (int256 markPrice)
    {
        markPrice = perpetual.state == PerpetualState.NORMAL
            ? perpetual.markPriceData.price
            : perpetual.settlementPriceData.price;
    }

    /**
     * @dev     Get the index price of the perpetual. If the state of the perpetual is not "NORMAL",
     *          return the settlement price
     * @param   perpetual   The reference of perpetual storage.
     * @return  indexPrice  The index price of current perpetual.
     */
    function getIndexPrice(PerpetualStorage storage perpetual)
        internal
        view
        returns (int256 indexPrice)
    {
        indexPrice = perpetual.state == PerpetualState.NORMAL
            ? perpetual.indexPriceData.price
            : perpetual.settlementPriceData.price;
    }

    /**
     * @dev     Get the margin to rebalance in the perpetual.
     *          Margin to rebalance = margin - initial margin
     * @param   perpetual The perpetual object
     * @return  marginToRebalance The margin to rebalance in the perpetual
     */
    function getRebalanceMargin(PerpetualStorage storage perpetual)
        public
        view
        returns (int256 marginToRebalance)
    {
        int256 price = getMarkPrice(perpetual);
        marginToRebalance = perpetual.getMargin(address(this), price).sub(
            perpetual.getInitialMargin(address(this), price)
        );
    }

    /**
     * @dev     Initialize the perpetual. Set up its configuration and validate parameters.
     *          If the validation passed, set the state of perpetual to "INITIALIZING"
     *          [minRiskParamValues, maxRiskParamValues] represents the range that the operator could
     *          update directly without proposal.
     *
     * @param   perpetual           The reference of perpetual storage.
     * @param   id                  The id of the perpetual (currently the index of perpetual)
     * @param   oracle              The address of oracle contract.
     * @param   baseParams          An int array of base parameter values.
     * @param   riskParams          An int array of risk parameter values.
     * @param   minRiskParamValues  An int array of minimal risk parameter values.
     * @param   maxRiskParamValues  An int array of maximum risk parameter values.
     */
    function initialize(
        PerpetualStorage storage perpetual,
        uint256 id,
        address oracle,
        int256[9] calldata baseParams,
        int256[8] calldata riskParams,
        int256[8] calldata minRiskParamValues,
        int256[8] calldata maxRiskParamValues
    ) public {
        perpetual.id = id;
        setOracle(perpetual, oracle);
        setBaseParameter(perpetual, baseParams);
        setRiskParameter(perpetual, riskParams, minRiskParamValues, maxRiskParamValues);
        perpetual.state = PerpetualState.INITIALIZING;
    }

    /**
     * @dev     Set oracle address of perpetual. New oracle must be different from the old one.
     *
     * @param   perpetual   The reference of perpetual storage.
     * @param   newOracle   The address of new oracle contract.
     */
    function setOracle(PerpetualStorage storage perpetual, address newOracle) public {
        require(newOracle != perpetual.oracle, "oracle not changed");
        validateOracle(newOracle);
        emit SetOracle(perpetual.id, perpetual.oracle, newOracle);
        perpetual.oracle = newOracle;
    }

    /**
     * @dev     Set the base parameter of the perpetual. Can only called by the governor
     * @param   perpetual   The perpetual object
     * @param   baseParams  The new value of the base parameter
     */
    function setBaseParameter(PerpetualStorage storage perpetual, int256[9] memory baseParams)
        public
    {
        validateBaseParameters(perpetual, baseParams);
        perpetual.initialMarginRate = baseParams[INDEX_INITIAL_MARGIN_RATE];
        perpetual.maintenanceMarginRate = baseParams[INDEX_MAINTENANCE_MARGIN_RATE];
        perpetual.operatorFeeRate = baseParams[INDEX_OPERATOR_FEE_RATE];
        perpetual.lpFeeRate = baseParams[INDEX_LP_FEE_RATE];
        perpetual.referralRebateRate = baseParams[INDEX_REFERRAL_REBATE_RATE];
        perpetual.liquidationPenaltyRate = baseParams[INDEX_LIQUIDATION_PENALTY_RATE];
        perpetual.keeperGasReward = baseParams[INDEX_KEEPER_GAS_REWARD];
        perpetual.insuranceFundRate = baseParams[INDEX_INSURANCE_FUND_RATE];
        perpetual.maxOpenInterestRate = baseParams[INDEX_MAX_OPEN_INTEREST_RATE];
        emit SetPerpetualBaseParameter(perpetual.id, baseParams);
    }

    /**
     * @dev     Set the risk parameter of the perpetual. New parameters will be validate first to apply.
     *          Using group set instead of one-by-one set to avoid revert due to constrains between values.
     *
     * @param   perpetual           The reference of perpetual storage.
     * @param   riskParams          An int array of risk parameter values.
     * @param   minRiskParamValues  An int array of minimal risk parameter values.
     * @param   maxRiskParamValues  An int array of maximum risk parameter values.
     */
    function setRiskParameter(
        PerpetualStorage storage perpetual,
        int256[8] memory riskParams,
        int256[8] memory minRiskParamValues,
        int256[8] memory maxRiskParamValues
    ) public {
        validateRiskParameters(perpetual, riskParams);
        setOption(
            perpetual.halfSpread,
            riskParams[INDEX_HALF_SPREAD],
            minRiskParamValues[INDEX_HALF_SPREAD],
            maxRiskParamValues[INDEX_HALF_SPREAD]
        );
        setOption(
            perpetual.openSlippageFactor,
            riskParams[INDEX_OPEN_SLIPPAGE_FACTOR],
            minRiskParamValues[INDEX_OPEN_SLIPPAGE_FACTOR],
            maxRiskParamValues[INDEX_OPEN_SLIPPAGE_FACTOR]
        );
        setOption(
            perpetual.closeSlippageFactor,
            riskParams[INDEX_CLOSE_SLIPPAGE_FACTOR],
            minRiskParamValues[INDEX_CLOSE_SLIPPAGE_FACTOR],
            maxRiskParamValues[INDEX_CLOSE_SLIPPAGE_FACTOR]
        );
        setOption(
            perpetual.fundingRateLimit,
            riskParams[INDEX_FUNDING_RATE_LIMIT],
            minRiskParamValues[INDEX_FUNDING_RATE_LIMIT],
            maxRiskParamValues[INDEX_FUNDING_RATE_LIMIT]
        );
        setOption(
            perpetual.ammMaxLeverage,
            riskParams[INDEX_AMM_MAX_LEVERAGE],
            minRiskParamValues[INDEX_AMM_MAX_LEVERAGE],
            maxRiskParamValues[INDEX_AMM_MAX_LEVERAGE]
        );
        setOption(
            perpetual.maxClosePriceDiscount,
            riskParams[INDEX_AMM_CLOSE_PRICE_DISCOUNT],
            minRiskParamValues[INDEX_AMM_CLOSE_PRICE_DISCOUNT],
            maxRiskParamValues[INDEX_AMM_CLOSE_PRICE_DISCOUNT]
        );
        setOption(
            perpetual.fundingRateFactor,
            riskParams[INDEX_FUNDING_RATE_FACTOR],
            minRiskParamValues[INDEX_FUNDING_RATE_FACTOR],
            maxRiskParamValues[INDEX_FUNDING_RATE_FACTOR]
        );
        setOption(
            perpetual.defaultTargetLeverage,
            riskParams[INDEX_DEFAULT_TARGET_LEVERAGE],
            minRiskParamValues[INDEX_DEFAULT_TARGET_LEVERAGE],
            maxRiskParamValues[INDEX_DEFAULT_TARGET_LEVERAGE]
        );
        emit SetPerpetualRiskParameter(
            perpetual.id,
            riskParams,
            minRiskParamValues,
            maxRiskParamValues
        );
    }

    /**
     * @dev     Adjust the risk parameter. New values should always satisfied the constrains and min/max limit.
     *
     * @param   perpetual   The reference of perpetual storage.
     * @param   riskParams  An int array of risk parameter values.
     */
    function updateRiskParameter(PerpetualStorage storage perpetual, int256[8] memory riskParams)
        public
    {
        validateRiskParameters(perpetual, riskParams);
        updateOption(perpetual.halfSpread, riskParams[INDEX_HALF_SPREAD]);
        updateOption(perpetual.openSlippageFactor, riskParams[INDEX_OPEN_SLIPPAGE_FACTOR]);
        updateOption(perpetual.closeSlippageFactor, riskParams[INDEX_CLOSE_SLIPPAGE_FACTOR]);
        updateOption(perpetual.fundingRateLimit, riskParams[INDEX_FUNDING_RATE_LIMIT]);
        updateOption(perpetual.ammMaxLeverage, riskParams[INDEX_AMM_MAX_LEVERAGE]);
        updateOption(perpetual.maxClosePriceDiscount, riskParams[INDEX_AMM_CLOSE_PRICE_DISCOUNT]);
        updateOption(perpetual.fundingRateFactor, riskParams[INDEX_FUNDING_RATE_FACTOR]);
        updateOption(perpetual.defaultTargetLeverage, riskParams[INDEX_DEFAULT_TARGET_LEVERAGE]);
        emit UpdatePerpetualRiskParameter(perpetual.id, riskParams);
    }

    /**
     * @dev     Update the unitAccumulativeFunding variable in perpetual.
     *          After that, funding payment of every account in the perpetual is updated,
     *
     *          nextUnitAccumulativeFunding = unitAccumulativeFunding
     *                                       + index * fundingRate * elapsedTime / fundingInterval
     *
     * @param   perpetual   The reference of perpetual storage.
     * @param   timeElapsed The elapsed time since last update.
     */
    function updateFundingState(PerpetualStorage storage perpetual, int256 timeElapsed) public {
        int256 deltaUnitLoss = timeElapsed
            .mul(getIndexPrice(perpetual))
            .wmul(perpetual.fundingRate)
            .div(FUNDING_INTERVAL);
        perpetual.unitAccumulativeFunding = perpetual.unitAccumulativeFunding.add(deltaUnitLoss);
        emit UpdateUnitAccumulativeFunding(perpetual.id, perpetual.unitAccumulativeFunding);
    }

    /**
     * @dev     Update the funding rate of the perpetual.
     *
     *            - funding rate = - index * position * limit / pool margin
     *            - funding rate = (+/-)limit when
     *                - pool margin = 0 and position != 0
     *                - abs(funding rate) > limit
     *
     * @param   perpetual   The reference of perpetual storage.
     * @param   poolMargin  The pool margin of liquidity pool.
     */
    function updateFundingRate(PerpetualStorage storage perpetual, int256 poolMargin) public {
        int256 newFundingRate = 0;
        int256 position = perpetual.getPosition(address(this));
        if (position != 0) {
            int256 fundingRateLimit = perpetual.fundingRateLimit.value;
            if (poolMargin != 0) {
                newFundingRate = getIndexPrice(perpetual).wfrac(position, poolMargin).neg().wmul(
                    perpetual.fundingRateFactor.value
                );
                newFundingRate = newFundingRate.min(fundingRateLimit).max(fundingRateLimit.neg());
            } else if (position > 0) {
                newFundingRate = fundingRateLimit.neg();
            } else {
                newFundingRate = fundingRateLimit;
            }
        }
        perpetual.fundingRate = newFundingRate;
        emit UpdateFundingRate(perpetual.id, newFundingRate);
    }

    /**
     * @dev     Update the oracle price of the perpetual, including the index price and the mark price
     * @param   perpetual   The reference of perpetual storage.
     */
    function updatePrice(PerpetualStorage storage perpetual) internal {
        IOracle oracle = IOracle(perpetual.oracle);
        updatePriceData(perpetual.markPriceData, oracle.priceTWAPLong);
        updatePriceData(perpetual.indexPriceData, oracle.priceTWAPShort);
        emit UpdatePrice(
            perpetual.id,
            address(oracle),
            perpetual.markPriceData.price,
            perpetual.markPriceData.time,
            perpetual.indexPriceData.price,
            perpetual.indexPriceData.time
        );
    }

    /**
     * @dev     Set the state of the perpetual to "NORMAL". The state must be "INITIALIZING" before
     * @param   perpetual   The reference of perpetual storage.
     */
    function setNormalState(PerpetualStorage storage perpetual) public {
        require(
            perpetual.state == PerpetualState.INITIALIZING,
            "perpetual should be in initializing state"
        );
        perpetual.state = PerpetualState.NORMAL;
        emit SetNormalState(perpetual.id);
    }

    /**
     * @dev     Set the state of the perpetual to "EMERGENCY". The state must be "NORMAL" before.
     *          The settlement price is the mark price at this time
     * @param   perpetual   The reference of perpetual storage.
     */
    function setEmergencyState(PerpetualStorage storage perpetual) public {
        require(perpetual.state == PerpetualState.NORMAL, "perpetual should be in NORMAL state");
        // use mark price as final price when emergency
        perpetual.settlementPriceData = perpetual.markPriceData;
        perpetual.totalAccount = perpetual.activeAccounts.length();
        perpetual.state = PerpetualState.EMERGENCY;
        emit SetEmergencyState(
            perpetual.id,
            perpetual.settlementPriceData.price,
            perpetual.settlementPriceData.time
        );
    }

    /**
     * @dev     Set the state of the perpetual to "CLEARED". The state must be "EMERGENCY" before.
     *          And settle the collateral of the perpetual, which means
     *          determining how much collateral should returned to every account.
     * @param   perpetual   The reference of perpetual storage.
     */
    function setClearedState(PerpetualStorage storage perpetual) public {
        require(
            perpetual.state == PerpetualState.EMERGENCY,
            "perpetual should be in emergency state"
        );
        settleCollateral(perpetual);
        perpetual.state = PerpetualState.CLEARED;
        emit SetClearedState(perpetual.id);
    }

    /**
     * @dev     Deposit collateral to the trader's account of the perpetual, that will increase the cash amount in
     *          trader's margin account.
     *
     *          If this is the first time the trader deposits in current perpetual, the address of trader will be
     *          push to a list, then the trader is defined as an 'Active' trader for this perpetual.
     *          List of active traders will be used during clearing.
     *
     * @param   perpetual           The reference of perpetual storage.
     * @param   trader              The address of the trader.
     * @param   amount              The amount of collateral to deposit.
     * @return  isInitialDeposit    True if the trader's account is empty before depositing.
     */
    function deposit(
        PerpetualStorage storage perpetual,
        address trader,
        int256 amount
    ) public returns (bool isInitialDeposit) {
        require(amount > 0, "amount should greater than 0");
        perpetual.updateCash(trader, amount);
        isInitialDeposit = registerActiveAccount(perpetual, trader);
        emit Deposit(perpetual.id, trader, amount);
    }

    /**
     * @dev     Withdraw collateral from the trader's account of the perpetual, that will increase the cash amount in
     *          trader's margin account.
     *
     *          Trader must be initial margin safe in the perpetual after withdrawing.
     *          Making the margin account 'Empty' will mark this account as a 'Deactive' trader then be removed from
     *          list of active traders.
     *
     * @param   perpetual           The reference of perpetual storage.
     * @param   trader              The address of the trader.
     * @param   amount              The amount of collateral to withdraw.
     * @return  isLastWithdrawal    True if the trader's account is empty after withdrawing.
     */
    function withdraw(
        PerpetualStorage storage perpetual,
        address trader,
        int256 amount
    ) public returns (bool isLastWithdrawal) {
        require(
            perpetual.getPosition(trader) == 0 || !IOracle(perpetual.oracle).isMarketClosed(),
            "market is closed"
        );
        require(amount > 0, "amount should greater than 0");
        perpetual.updateCash(trader, amount.neg());
        int256 markPrice = getMarkPrice(perpetual);
        require(
            perpetual.isInitialMarginSafe(trader, markPrice),
            "margin is unsafe after withdrawal"
        );
        isLastWithdrawal = perpetual.isEmptyAccount(trader);
        if (isLastWithdrawal) {
            deregisterActiveAccount(perpetual, trader);
        }
        emit Withdraw(perpetual.id, trader, amount);
    }

    /**
     * @dev     Clear the active account of the perpetual which state is "EMERGENCY" and send gas reward of collateral
     *          to sender.
     *          If all active accounts are cleared, the clear progress is done and the perpetual's state will
     *          change to "CLEARED".
     *
     * @param   perpetual       The reference of perpetual storage.
     * @param   trader          The address of the trader to clear.
     * @return  isAllCleared    True if all the active accounts are cleared.
     */
    function clear(PerpetualStorage storage perpetual, address trader)
        public
        returns (bool isAllCleared)
    {
        require(perpetual.activeAccounts.length() > 0, "no account to clear");
        require(
            perpetual.activeAccounts.contains(trader),
            "account cannot be cleared or already cleared"
        );
        countMargin(perpetual, trader);
        perpetual.activeAccounts.remove(trader);
        isAllCleared = (perpetual.activeAccounts.length() == 0);
        emit Clear(perpetual.id, trader);
    }

    /**
     * @dev     Check the margin balance of trader's account, update total margin.
     *          If the margin of the trader's account is not positive, it will be counted as 0.
     *
     * @param   perpetual   The reference of perpetual storage.
     * @param   trader      The address of the trader to be counted.
     */
    function countMargin(PerpetualStorage storage perpetual, address trader) public {
        int256 margin = perpetual.getMargin(trader, getMarkPrice(perpetual));
        if (margin <= 0) {
            return;
        }
        if (perpetual.getPosition(trader) != 0) {
            perpetual.totalMarginWithPosition = perpetual.totalMarginWithPosition.add(margin);
        } else {
            perpetual.totalMarginWithoutPosition = perpetual.totalMarginWithoutPosition.add(margin);
        }
    }

    /**
     * @dev     Get the address of the next active account in the perpetual.
     *
     * @param   perpetual   The reference of perpetual storage.
     * @return  account     The address of the next active account.
     */
    function getNextActiveAccount(PerpetualStorage storage perpetual)
        public
        view
        returns (address account)
    {
        require(perpetual.activeAccounts.length() > 0, "no active account");
        account = perpetual.activeAccounts.at(0);
    }

    /**
     * @dev     If the state of the perpetual is "CLEARED".
     *          The traders is able to settle all margin balance left in account.
     *          How much collateral can be returned is determined by the ratio of margin balance left in account to the
     *          total amount of collateral in perpetual.
     *          The priority is:
     *              - accounts withou position;
     *              - accounts with positions;
     *              - accounts with negative margin balance will get nothing back.
     *
     * @param   perpetual       The reference of perpetual storage.
     * @param   trader          The address of the trader to settle.
     * @param   marginToReturn  The actual collateral will be returned to the trader.
     */
    function settle(PerpetualStorage storage perpetual, address trader)
        public
        returns (int256 marginToReturn)
    {
        int256 price = getMarkPrice(perpetual);
        marginToReturn = perpetual.getSettleableMargin(trader, price);
        perpetual.resetAccount(trader);
        emit Settle(perpetual.id, trader, marginToReturn);
    }

    /**
     * @dev     Settle the total collateral of the perpetual, which means update redemptionRateWithPosition
     *          and redemptionRateWithoutPosition variables.
     *          If the total collateral is not enough for the accounts without position,
     *          all the total collateral is given to them proportionally.
     *          If the total collateral is more than the accounts without position needs,
     *          the extra part of collateral is given to the accounts with position proportionally.
     *
     * @param   perpetual   The reference of perpetual storage.
     */
    function settleCollateral(PerpetualStorage storage perpetual) public {
        int256 totalCollateral = perpetual.totalCollateral;
        // 2. cover margin without position
        if (totalCollateral < perpetual.totalMarginWithoutPosition) {
            // margin without positions get balance / total margin
            // smaller rate to make sure total redemption margin < total collateral of perpetual
            perpetual.redemptionRateWithoutPosition = perpetual.totalMarginWithoutPosition > 0
                ? totalCollateral.wdiv(perpetual.totalMarginWithoutPosition, Round.FLOOR)
                : 0;
            // margin with positions will get nothing
            perpetual.redemptionRateWithPosition = 0;
        } else {
            // 3. covere margin with position
            perpetual.redemptionRateWithoutPosition = Constant.SIGNED_ONE;
            // smaller rate to make sure total redemption margin < total collateral of perpetual
            perpetual.redemptionRateWithPosition = perpetual.totalMarginWithPosition > 0
                ? totalCollateral.sub(perpetual.totalMarginWithoutPosition).wdiv(
                    perpetual.totalMarginWithPosition,
                    Round.FLOOR
                )
                : 0;
        }
    }

    /**
     * @dev     Register the trader's account to the active accounts in the perpetual
     * @param   perpetual   The reference of perpetual storage.
     * @param   trader      The address of the trader.
     * @return  True if the trader is added to account for the first time.
     */
    function registerActiveAccount(PerpetualStorage storage perpetual, address trader)
        internal
        returns (bool)
    {
        return perpetual.activeAccounts.add(trader);
    }

    /**
     * @dev     Deregister the trader's account from the active accounts in the perpetual
     * @param   perpetual   The reference of perpetual storage.
     * @param   trader      The address of the trader.
     * @return  True if the trader is removed to account for the first time.
     */
    function deregisterActiveAccount(PerpetualStorage storage perpetual, address trader)
        internal
        returns (bool)
    {
        return perpetual.activeAccounts.remove(trader);
    }

    /**
     * @dev     Update the price data, which means the price and the update time
     * @param   priceData   The price data to update.
     * @param   priceGetter The function pointer to retrieve current price data.
     */
    function updatePriceData(
        OraclePriceData storage priceData,
        function() external returns (int256, uint256) priceGetter
    ) internal {
        (int256 price, uint256 time) = priceGetter();
        require(price > 0 && time != 0, "invalid price data");
        if (time >= priceData.time) {
            priceData.price = price;
            priceData.time = time;
        }
    }

    /**
     * @dev     Increase the total collateral of the perpetual
     * @param   perpetual   The reference of perpetual storage.
     * @param   amount      The amount of collateral to increase
     */
    function increaseTotalCollateral(PerpetualStorage storage perpetual, int256 amount) internal {
        require(amount >= 0, "amount is negative");
        perpetual.totalCollateral = perpetual.totalCollateral.add(amount);
    }

    /**
     * @dev     Decrease the total collateral of the perpetual
     * @param   perpetual   The reference of perpetual storage.
     * @param   amount      The amount of collateral to decrease
     */
    function decreaseTotalCollateral(PerpetualStorage storage perpetual, int256 amount) internal {
        require(amount >= 0, "amount is negative");
        perpetual.totalCollateral = perpetual.totalCollateral.sub(amount);
        require(perpetual.totalCollateral >= 0, "collateral is negative");
    }

    /**
     * @dev     Update the option
     * @param   option      The option to update
     * @param   newValue    The new value of the option, must between the minimum value and the maximum value
     */
    function updateOption(Option storage option, int256 newValue) internal {
        require(newValue >= option.minValue && newValue <= option.maxValue, "value out of range");
        option.value = newValue;
    }

    /**
     * @dev     Set the option value, with constraints that newMinValue <= newValue <= newMaxValue.
     *
     * @param   option      The reference of option storage.
     * @param   newValue    The new value of the option, must be within range of [newMinValue, newMaxValue].
     * @param   newMinValue The minimum value of the option.
     * @param   newMaxValue The maximum value of the option.
     */
    function setOption(
        Option storage option,
        int256 newValue,
        int256 newMinValue,
        int256 newMaxValue
    ) internal {
        require(newValue >= newMinValue && newValue <= newMaxValue, "value out of range");
        option.value = newValue;
        option.minValue = newMinValue;
        option.maxValue = newMaxValue;
    }

    /**
     * @dev     Validate oracle contract, including each method of oracle
     *
     * @param   oracle   The address of oracle contract.
     */
    function validateOracle(address oracle) public {
        require(oracle != address(0), "invalid oracle address");
        require(oracle.isContract(), "oracle must be contract");
        bool success;
        bytes memory data;
        (success, data) = oracle.call(abi.encodeWithSignature("isMarketClosed()"));
        require(success && data.length == 32, "invalid function: isMarketClosed");
        (success, data) = oracle.call(abi.encodeWithSignature("isTerminated()"));
        require(success && data.length == 32, "invalid function: isTerminated");
        require(!abi.decode(data, (bool)), "oracle is terminated");
        (success, data) = oracle.call(abi.encodeWithSignature("collateral()"));
        require(success && data.length > 0, "invalid function: collateral");
        string memory result;
        result = abi.decode(data, (string));
        require(keccak256(bytes(result)) != keccak256(bytes("")), "oracle's collateral is empty");
        (success, data) = oracle.call(abi.encodeWithSignature("underlyingAsset()"));
        require(success && data.length > 0, "invalid function: underlyingAsset");
        result = abi.decode(data, (string));
        require(
            keccak256(bytes(result)) != keccak256(bytes("")),
            "oracle's underlyingAsset is empty"
        );
        (success, data) = oracle.call(abi.encodeWithSignature("priceTWAPLong()"));
        require(success && data.length > 0, "invalid function: priceTWAPLong");
        (int256 price, uint256 timestamp) = abi.decode(data, (int256, uint256));
        require(price > 0 && timestamp > 0, "oracle's twap long price is not updated");
        (success, data) = oracle.call(abi.encodeWithSignature("priceTWAPShort()"));
        require(success && data.length > 0, "invalid function: priceTWAPShort");
        (price, timestamp) = abi.decode(data, (int256, uint256));
        require(price > 0 && timestamp > 0, "oracle's twap short price is not updated");
    }

    /**
     * @dev     Validate the base parameters of the perpetual:
     *            1. initial margin rate > 0
     *            2. 0 < maintenance margin rate <= initial margin rate
     *            3. 0 <= operator fee rate <= 0.01
     *            4. 0 <= lp fee rate <= 0.01
     *            5. 0 <= liquidation penalty rate < maintenance margin rate
     *            6. keeper gas reward >= 0
     *
     * @param   perpetual   The reference of perpetual storage.
     * @param   baseParams  The base parameters of the perpetual.
     */
    function validateBaseParameters(PerpetualStorage storage perpetual, int256[9] memory baseParams)
        public
        view
    {
        require(baseParams[INDEX_INITIAL_MARGIN_RATE] > 0, "initialMarginRate <= 0");
        require(
            perpetual.initialMarginRate == 0 ||
                baseParams[INDEX_INITIAL_MARGIN_RATE] <= perpetual.initialMarginRate,
            "cannot increase initialMarginRate"
        );
        int256 maxLeverage = Constant.SIGNED_ONE.wdiv(baseParams[INDEX_INITIAL_MARGIN_RATE]);
        require(
            perpetual.defaultTargetLeverage.value <= maxLeverage,
            "default target leverage exceeds max leverage"
        );
        require(
            perpetual.maintenanceMarginRate == 0 ||
                baseParams[INDEX_MAINTENANCE_MARGIN_RATE] <= perpetual.maintenanceMarginRate,
            "cannot increase maintenanceMarginRate"
        );
        require(baseParams[INDEX_MAINTENANCE_MARGIN_RATE] > 0, "maintenanceMarginRate <= 0");
        require(
            baseParams[INDEX_MAINTENANCE_MARGIN_RATE] <= baseParams[INDEX_INITIAL_MARGIN_RATE],
            "maintenanceMarginRate > initialMarginRate"
        );
        require(baseParams[INDEX_OPERATOR_FEE_RATE] >= 0, "operatorFeeRate < 0");
        require(
            baseParams[INDEX_OPERATOR_FEE_RATE] <= (Constant.SIGNED_ONE / 100),
            "operatorFeeRate > 1%"
        );
        require(baseParams[INDEX_LP_FEE_RATE] >= 0, "lpFeeRate < 0");
        require(baseParams[INDEX_LP_FEE_RATE] <= (Constant.SIGNED_ONE / 100), "lpFeeRate > 1%");

        require(baseParams[INDEX_REFERRAL_REBATE_RATE] >= 0, "referralRebateRate < 0");
        require(
            baseParams[INDEX_REFERRAL_REBATE_RATE] <= Constant.SIGNED_ONE,
            "referralRebateRate > 100%"
        );

        require(baseParams[INDEX_LIQUIDATION_PENALTY_RATE] >= 0, "liquidationPenaltyRate < 0");
        require(
            baseParams[INDEX_LIQUIDATION_PENALTY_RATE] <= baseParams[INDEX_MAINTENANCE_MARGIN_RATE],
            "liquidationPenaltyRate > maintenanceMarginRate"
        );
        require(baseParams[INDEX_KEEPER_GAS_REWARD] >= 0, "keeperGasReward < 0");
        require(baseParams[INDEX_INSURANCE_FUND_RATE] >= 0, "insuranceFundRate < 0");
        require(baseParams[INDEX_MAX_OPEN_INTEREST_RATE] > 0, "maxOpenInterestRate <= 0");
    }

    /**
     * @dev     alidate the risk parameters of the perpetual
     *            1. 0 <= half spread < 1
     *            2. open slippage factor > 0
     *            3. 0 < close slippage factor <= open slippage factor
     *            4. funding rate limit >= 0
     *            5. AMM max leverage > 0
     *            6. 0 <= max close price discount < 1
     *
     * @param   perpetual   The reference of perpetual storage.
     */
    function validateRiskParameters(PerpetualStorage storage perpetual, int256[8] memory riskParams)
        public
        view
    {
        // must set risk parameters after setting base parameters
        require(perpetual.initialMarginRate > 0, "need to set base parameters first");
        require(riskParams[INDEX_HALF_SPREAD] >= 0, "halfSpread < 0");
        require(riskParams[INDEX_HALF_SPREAD] < Constant.SIGNED_ONE, "halfSpread >= 100%");
        require(riskParams[INDEX_OPEN_SLIPPAGE_FACTOR] > 0, "openSlippageFactor < 0");
        require(riskParams[INDEX_CLOSE_SLIPPAGE_FACTOR] > 0, "closeSlippageFactor < 0");
        require(
            riskParams[INDEX_CLOSE_SLIPPAGE_FACTOR] <= riskParams[INDEX_OPEN_SLIPPAGE_FACTOR],
            "closeSlippageFactor > openSlippageFactor"
        );
        require(riskParams[INDEX_FUNDING_RATE_FACTOR] >= 0, "fundingRateFactor < 0");
        require(riskParams[INDEX_FUNDING_RATE_LIMIT] >= 0, "fundingRateLimit < 0");
        require(riskParams[INDEX_AMM_MAX_LEVERAGE] >= 0, "ammMaxLeverage < 0");
        require(
            riskParams[INDEX_AMM_MAX_LEVERAGE] <=
                Constant.SIGNED_ONE.wdiv(perpetual.initialMarginRate, Round.FLOOR),
            "ammMaxLeverage > 1 / initialMarginRate"
        );
        require(riskParams[INDEX_AMM_CLOSE_PRICE_DISCOUNT] >= 0, "maxClosePriceDiscount < 0");
        require(
            riskParams[INDEX_AMM_CLOSE_PRICE_DISCOUNT] < Constant.SIGNED_ONE,
            "maxClosePriceDiscount >= 100%"
        );
        require(perpetual.initialMarginRate != 0, "initialMarginRate is not set");
        int256 maxLeverage = Constant.SIGNED_ONE.wdiv(perpetual.initialMarginRate);
        require(
            riskParams[INDEX_DEFAULT_TARGET_LEVERAGE] <= maxLeverage,
            "default target leverage exceeds max leverage"
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

/**
 * @notice  Perpetual state:
 *          - INVALID:      Uninitialized or not non-existent perpetual;
 *          - INITIALIZING: Only when LiquidityPoolStorage.isRunning == false. Traders cannot perform operations;
 *          - NORMAL:       Full functional state. Traders is able to perform all operations;
 *          - EMERGENCY:    Perpetual is unsafe and only clear is available;
 *          - CLEARED:      All margin account is cleared. Trade could withdraw remaining margin balance.
 */
enum PerpetualState {
    INVALID,
    INITIALIZING,
    NORMAL,
    EMERGENCY,
    CLEARED
}
enum OrderType {
    LIMIT,
    MARKET,
    STOP
}

/**
 * @notice  Data structure to store risk parameter value.
 */
struct Option {
    int256 value;
    int256 minValue;
    int256 maxValue;
}

/**
 * @notice  Data structure to store oracle price data.
 */
struct OraclePriceData {
    int256 price;
    uint256 time;
}

/**
 * @notice  Data structure to store user margin information. See MarginAccountModule.sol for details.
 */
struct MarginAccount {
    int256 cash;
    int256 position;
    int256 targetLeverage;
}

/**
 * @notice  Data structure of an order object.
 */
struct Order {
    address trader;
    address broker;
    address relayer;
    address referrer;
    address liquidityPool;
    int256 minTradeAmount;
    int256 amount;
    int256 limitPrice;
    int256 triggerPrice;
    uint256 chainID;
    uint64 expiredAt;
    uint32 perpetualIndex;
    uint32 brokerFeeLimit;
    uint32 flags;
    uint32 salt;
}

/**
 * @notice  Core data structure, a core .
 */
struct LiquidityPoolStorage {
    bool isRunning;
    bool isFastCreationEnabled;
    // addresses
    address creator;
    address operator;
    address transferringOperator;
    address governor;
    address shareToken;
    address accessController;
    bool reserved3; // isWrapped
    uint256 scaler;
    uint256 collateralDecimals;
    address collateralToken;
    // pool attributes
    int256 poolCash;
    uint256 fundingTime;
    uint256 reserved5;
    uint256 operatorExpiration;
    mapping(address => int256) reserved1;
    bytes32[] reserved2;
    // perpetuals
    uint256 perpetualCount;
    mapping(uint256 => PerpetualStorage) perpetuals;
    // insurance fund
    int256 insuranceFundCap;
    int256 insuranceFund;
    int256 donatedInsuranceFund;
    address reserved4;
    uint256 liquidityCap;
    uint256 shareTransferDelay;
    // reserved slot for future upgrade
    bytes32[14] reserved;
}

/**
 * @notice  Core data structure, storing perpetual information.
 */
struct PerpetualStorage {
    uint256 id;
    PerpetualState state;
    address oracle;
    int256 totalCollateral;
    int256 openInterest;
    // prices
    OraclePriceData indexPriceData;
    OraclePriceData markPriceData;
    OraclePriceData settlementPriceData;
    // funding state
    int256 fundingRate;
    int256 unitAccumulativeFunding;
    // base parameters
    int256 initialMarginRate;
    int256 maintenanceMarginRate;
    int256 operatorFeeRate;
    int256 lpFeeRate;
    int256 referralRebateRate;
    int256 liquidationPenaltyRate;
    int256 keeperGasReward;
    int256 insuranceFundRate;
    int256 reserved1;
    int256 maxOpenInterestRate;
    // risk parameters
    Option halfSpread;
    Option openSlippageFactor;
    Option closeSlippageFactor;
    Option fundingRateLimit;
    Option fundingRateFactor;
    Option ammMaxLeverage;
    Option maxClosePriceDiscount;
    // users
    uint256 totalAccount;
    int256 totalMarginWithoutPosition;
    int256 totalMarginWithPosition;
    int256 redemptionRateWithoutPosition;
    int256 redemptionRateWithPosition;
    EnumerableSetUpgradeable.AddressSet activeAccounts;
    // insurance fund
    int256 reserved2;
    int256 reserved3;
    // accounts
    mapping(address => MarginAccount) marginAccounts;
    Option defaultTargetLeverage;
    // keeper
    address reserved4;
    EnumerableSetUpgradeable.AddressSet ammKeepers;
    EnumerableSetUpgradeable.AddressSet reserved5;
    // reserved slot for future upgrade
    bytes32[12] reserved;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

import "./IProxyAdmin.sol";

interface IPoolCreator {
    function upgradeAdmin() external view returns (IProxyAdmin proxyAdmin);

    /**
     * @notice  Create a liquidity pool with the latest version.
     *          The sender will be the operator of pool.
     *
     * @param   collateral              he collateral address of the liquidity pool.
     * @param   collateralDecimals      The collateral's decimals of the liquidity pool.
     * @param   nonce                   A random nonce to calculate the address of deployed contracts.
     * @param   initData                A bytes array contains data to initialize new created liquidity pool.
     * @return  liquidityPool           The address of the created liquidity pool.
     */
    function createLiquidityPool(
        address collateral,
        uint256 collateralDecimals,
        int256 nonce,
        bytes calldata initData
    ) external returns (address liquidityPool, address governor);

    /**
     * @notice  Upgrade a liquidity pool and governor pair then call a patch function on the upgraded contract (optional).
     *          This method checks the sender and forwards the request to ProxyAdmin to do upgrading.
     *
     * @param   targetVersionKey        The key of version to be upgrade up. The target version must be compatible with
     *                                  current version.
     * @param   dataForLiquidityPool    The patch calldata for upgraded liquidity pool.
     * @param   dataForGovernor         The patch calldata of upgraded governor.
     */
    function upgradeToAndCall(
        bytes32 targetVersionKey,
        bytes memory dataForLiquidityPool,
        bytes memory dataForGovernor
    ) external;

    /**
     * @notice  Indicates the universe settle state.
     *          If the flag set to true:
     *              - all the pereptual created by this poolCreator can be settled immediately;
     *              - all the trading method will be unavailable.
     */
    function isUniverseSettled() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

import "./IProxyAdmin.sol";

interface ITracer {
    /**
     * @notice  Activate the perpetual for the trader. Active means the trader's account is not empty in
     *          the perpetual. Empty means cash and position are zero. Can only called by a liquidity pool.
     *
     * @param   trader          The address of the trader.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool.
     * @return  True if the activation is successful.
     */
    function activatePerpetualFor(address trader, uint256 perpetualIndex) external returns (bool);

    /**
     * @notice  Deactivate the perpetual for the trader. Active means the trader's account is not empty in
     *          the perpetual. Empty means cash and position are zero. Can only called by a liquidity pool.
     *
     * @param   trader          The address of the trader.
     * @param   perpetualIndex  The index of the perpetual in the liquidity pool.
     * @return  True if the deactivation is successful.
     */
    function deactivatePerpetualFor(address trader, uint256 perpetualIndex) external returns (bool);

    /**
     * @notice  Liquidity pool must call this method when changing its ownership to the new operator.
     *          Can only be called by a liquidity pool. This method does not affect 'ownership' or privileges
     *          of operator but only make a record for further query.
     *
     * @param   liquidityPool   The address of the liquidity pool.
     * @param   operator        The address of the new operator, must be different from the old operator.
     */
    function registerOperatorOfLiquidityPool(address liquidityPool, address operator) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

import "./IProxyAdmin.sol";

interface IVersionControl {
    function owner() external view returns (address);

    function getLatestVersion() external view returns (bytes32 latestVersionKey);

    /**
     * @notice  Get the details of the version.
     *
     * @param   versionKey              The key of the version to get.
     * @return  liquidityPoolTemplate   The address of the liquidity pool template.
     * @return  governorTemplate        The address of the governor template.
     * @return  compatibility           The compatibility of the specified version.
     */
    function getVersion(bytes32 versionKey)
        external
        view
        returns (
            address liquidityPoolTemplate,
            address governorTemplate,
            uint256 compatibility
        );

    /**
     * @notice  Get the description of the implementation of liquidity pool.
     *          Description contains creator, create time, compatibility and note
     *
     * @param  liquidityPool        The address of the liquidity pool.
     * @param  governor             The address of the governor.
     * @return appliedVersionKey    The version key of given liquidity pool and governor.
     */
    function getAppliedVersionKey(address liquidityPool, address governor)
        external
        view
        returns (bytes32 appliedVersionKey);

    /**
     * @notice  Check if a key is valid (exists).
     *
     * @param   versionKey  The key of the version to test.
     * @return  isValid     Return true if the version of given key is valid.
     */
    function isVersionKeyValid(bytes32 versionKey) external view returns (bool isValid);

    /**
     * @notice  Check if the implementation of liquidity pool target is compatible with the implementation base.
     *          Being compatible means having larger compatibility.
     *
     * @param   targetVersionKey    The key of the version to be upgraded to.
     * @param   baseVersionKey      The key of the version to be upgraded from.
     * @return  isCompatible        True if the target version is compatible with the base version.
     */
    function isVersionCompatible(bytes32 targetVersionKey, bytes32 baseVersionKey)
        external
        view
        returns (bool isCompatible);

    /**
     * @dev     Get a certain number of implementations of liquidity pool within range [begin, end).
     *
     * @param   begin       The index of first element to retrieve.
     * @param   end         The end index of element, exclusive.
     * @return  versionKeys An array contains current version keys.
     */
    function listAvailableVersions(uint256 begin, uint256 end)
        external
        view
        returns (bytes32[] memory versionKeys);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

import "./IProxyAdmin.sol";

interface IVariables {
    function owner() external view returns (address);

    /**
     * @notice Get the address of the vault
     * @return address The address of the vault
     */
    function getVault() external view returns (address);

    /**
     * @notice Get the vault fee rate
     * @return int256 The vault fee rate
     */
    function getVaultFeeRate() external view returns (int256);

    /**
     * @notice Get the address of the access controller. It's always its own address.
     *
     * @return address The address of the access controller.
     */
    function getAccessController() external view returns (address);

    /**
     * @notice  Get the address of the symbol service.
     *
     * @return  Address The address of the symbol service.
     */
    function getSymbolService() external view returns (address);

    /**
     * @notice  Set the vault address. Can only called by owner.
     *
     * @param   newVault    The new value of the vault fee rate
     */
    function setVault(address newVault) external;

    /**
     * @notice  Get the address of the mcb token.
     * @dev     [ConfirmBeforeDeployment]
     *
     * @return  Address The address of the mcb token.
     */
    function getMCBToken() external pure returns (address);

    /**
     * @notice  Set the vault fee rate. Can only called by owner.
     *
     * @param   newVaultFeeRate The new value of the vault fee rate
     */
    function setVaultFeeRate(int256 newVaultFeeRate) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

interface IKeeperWhitelist {
    /**
     * @notice Add an address to keeper whitelist.
     */
    function addKeeper(address keeper) external;

    /**
     * @notice Remove an address from keeper whitelist.
     */
    function removeKeeper(address keeper) external;

    /**
     * @notice Check if an address is in keeper whitelist.
     */
    function isKeeper(address keeper) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

interface IProxyAdmin {
    function getProxyImplementation(address proxy) external view returns (address);

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(address proxy, address implementation) external;

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        address proxy,
        address implementation,
        bytes memory data
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

library Constant {
    address internal constant INVALID_ADDRESS = address(0);

    int256 internal constant SIGNED_ONE = 10**18;
    uint256 internal constant UNSIGNED_ONE = 10**18;

    uint256 internal constant PRIVILEGE_DEPOSIT = 0x1;
    uint256 internal constant PRIVILEGE_WITHDRAW = 0x2;
    uint256 internal constant PRIVILEGE_TRADE = 0x4;
    uint256 internal constant PRIVILEGE_LIQUIDATE = 0x8;
    uint256 internal constant PRIVILEGE_GUARD =
        PRIVILEGE_DEPOSIT | PRIVILEGE_WITHDRAW | PRIVILEGE_TRADE | PRIVILEGE_LIQUIDATE;
    // max number of uint256
    uint256 internal constant SET_ALL_PERPETUALS_TO_EMERGENCY_STATE =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSetUpgradeable {
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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.4;

library Math {
    /**
     * @dev Get the most significant bit of the number,
            example: 0 ~ 1 => 0, 2 ~ 3 => 1, 4 ~ 7 => 2, 8 ~ 15 => 3,
            about use 606 ~ 672 gas
     * @param x The number
     * @return uint8 The significant bit of the number
     */
    function mostSignificantBit(uint256 x) internal pure returns (uint8) {
        uint256 t;
        uint8 r;
        if ((t = (x >> 128)) > 0) {
            x = t;
            r += 128;
        }
        if ((t = (x >> 64)) > 0) {
            x = t;
            r += 64;
        }
        if ((t = (x >> 32)) > 0) {
            x = t;
            r += 32;
        }
        if ((t = (x >> 16)) > 0) {
            x = t;
            r += 16;
        }
        if ((t = (x >> 8)) > 0) {
            x = t;
            r += 8;
        }
        if ((t = (x >> 4)) > 0) {
            x = t;
            r += 4;
        }
        if ((t = (x >> 2)) > 0) {
            x = t;
            r += 2;
        }
        if ((t = (x >> 1)) > 0) {
            x = t;
            r += 1;
        }
        return r;
    }

    // https://en.wikipedia.org/wiki/Integer_square_root
    /**
     * @dev Get the square root of the number
     * @param x The number, usually 10^36
     * @return int256 The square root of the number, usually 10^18
     */
    function sqrt(int256 x) internal pure returns (int256) {
        require(x >= 0, "negative sqrt");
        if (x < 3) {
            return (x + 1) / 2;
        }

        // binary estimate
        // inspired by https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_estimates
        uint8 n = mostSignificantBit(uint256(x));
        // make sure initial estimate > sqrt(x)
        // 2^ceil((n + 1) / 2) as initial estimate
        // 2^(n + 1) > x
        // => 2^ceil((n + 1) / 2) > 2^((n + 1) / 2) > sqrt(x)
        n = (n + 1) / 2 + 1;

        // modified babylonian method
        int256 next = int256(1 << n);
        int256 y;
        do {
            y = next;
            next = (next + x / next) >> 1;
        } while (next < y);
        return y;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

interface IOracle {
    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external returns (bool);

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() external returns (bool);

    /**
     * @dev Get collateral symbol.
     */
    function collateral() external view returns (string memory);

    /**
     * @dev Get underlying asset symbol.
     */
    function underlyingAsset() external view returns (string memory);

    /**
     * @dev Mark price.
     */
    function priceTWAPLong() external returns (int256 newPrice, uint256 newTimestamp);

    /**
     * @dev Index price.
     */
    function priceTWAPShort() external returns (int256 newPrice, uint256 newTimestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

interface IDecimals {
    function decimals() external view returns (uint8);
}