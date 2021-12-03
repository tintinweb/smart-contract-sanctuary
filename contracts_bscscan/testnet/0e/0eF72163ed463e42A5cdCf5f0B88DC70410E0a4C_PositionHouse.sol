pragma solidity ^0.8.0;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IPositionManager.sol";
import "./libraries/position/Position.sol";
import "hardhat/console.sol";
import "./PositionManager.sol";
import "./libraries/helpers/Quantity.sol";
import "./libraries/position/PositionLimitOrder.sol";
import "../interfaces/IInsuranceFund.sol";
import "../interfaces/IFeePool.sol";
import {PositionHouseFunction} from "./libraries/position/PositionHouseFunction.sol";

contract PositionHouse is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable
{
    using PositionLimitOrder for mapping(address => mapping(address => PositionLimitOrder.Data[]));
    using Quantity for int256;
    using Quantity for int128;

    using Position for Position.Data;
    using Position for Position.LiquidatedData;
    //    using PositionHouseFunction for PositionHouse;

    enum PnlCalcOption {
        TWAP,
        SPOT_PRICE,
        ORACLE
    }

    struct PositionResp {

        Position.Data position;
        // NOTICE margin to vault can be negative
        int256 marginToVault;

        int256 realizedPnl;

        int256 unrealizedPnl;

        int256 exchangedPositionSize;

        uint256 exchangedQuoteAssetAmount;

        uint256 fundingPayment;

    }


    struct LimitOrderPending {
        bool isBuy;
        uint256 quantity;
        uint256 partialFilled;
        int256 pip;
        uint256 leverage;
        uint256 blockNumber;
        uint256 orderIdOfTrader;
        uint256 orderId;
    }

    struct OpenLimitResp {
        uint64 orderId;
        uint256 sizeOut;
    }

    //    struct PositionManagerData {
    //        uint24 blockNumber;
    //        int256[] cumulativePremiumFraction;
    //        // Position data of each trader
    //        mapping(address => Position.Data) positionMap;
    //        mapping(address => PositionLimitOrder.Data[]) limitOrders;
    //        mapping(address => PositionLimitOrder.Data[]) reduceLimitOrders;
    //        // Amount that trader can claim from exchange
    //        mapping(address => int256) canClaimAmount;
    //    }
    //    // TODO change separate mapping to positionManagerMap
    //    mapping(address => PositionManagerData) public positionManagerMap;

    // Can join positionMap and cumulativePremiumFractionsMap into a map of struct with key is PositionManager's address
    // Mapping from position manager address of each pair to position data of each trader
    mapping(address => mapping(address => Position.Data)) public positionMap;
    //    mapping(address => int256[]) public cumulativePremiumFractionsMap;

    mapping(address => mapping(address => Position.LiquidatedData)) public debtPosition;
    mapping(address => mapping(address => uint256)) public canClaimAmountMap;

    // update added margin type from int256 to uint256
    mapping(address => mapping(address => int256)) public manualMargin;
    //can update with index => no need delete array when close all
    mapping(address => mapping(address => PositionLimitOrder.Data[])) public limitOrders;
    mapping(address => mapping(address => PositionLimitOrder.Data[])) public reduceLimitOrders;

    uint256 maintenanceMarginRatio;
    uint256 partialLiquidationRatio;
    uint256 liquidationFeeRatio;
    uint256 liquidationPenaltyRatio;

    IInsuranceFund public insuranceFund;
    IFeePool public feePool;

    modifier whenNotPause(){
        //TODO implement
        _;
    }

    event OpenMarket(
        address trader,
        int256 quantity,
        uint256 leverage,
        uint256 priceMarket,
        IPositionManager positionManager
    );
    event OpenLimit(
        uint64 orderId,
        address trader,
        int256 quantity,
        uint256 leverage,
        int128 pip,
        IPositionManager positionManager
    );

    event CancelLimit(
        uint64 orderIdOfTrader,
        uint64 orderId,
        address trader,
        int128 pip,
        IPositionManager positionManager
    );

    event AddMargin(address trader, uint256 marginAdded, IPositionManager positionManager);

    event RemoveMargin(address trader, uint256 marginRemoved, IPositionManager positionManager);

    event CancelLimitOrder(address trader, address _positionManager, uint64 orderIdOfTrader, uint64 orderId);

    event Liquidate(address positionManager, address trader);

    function initialize(
        uint256 _maintenanceMarginRatio,
        uint256 _partialLiquidationRatio,
        uint256 _liquidationFeeRatio,
        uint256 _liquidationPenaltyRatio,
        address _insuranceFund,
        address _feePool
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        maintenanceMarginRatio = _maintenanceMarginRatio;
        partialLiquidationRatio = _partialLiquidationRatio;
        liquidationFeeRatio = _liquidationFeeRatio;
        liquidationPenaltyRatio = _liquidationPenaltyRatio;
        insuranceFund = IInsuranceFund(_insuranceFund);
        feePool = IFeePool(_feePool);
    }


    /**
    * @notice open position with price market
    * @param _positionManager IPositionManager address
    * @param _side Side of position LONG or SHORT
    * @param _quantity quantity of size after mul with leverage
    * @param _leverage leverage of position
    */
    function openMarketPosition(
        IPositionManager _positionManager,
        Position.Side _side,
        uint256 _quantity,
        uint256 _leverage
    ) public whenNotPause nonReentrant {
        // TODO update require quantity > minimum amount of each pair
        require(_quantity == (_quantity / 1000000000000000 * 1000000000000000), "IQ");
        //        requirePositionManager(_positionManager);

        address _trader = _msgSender();
        Position.Data memory oldPosition = getPosition(address(_positionManager), _trader);
        if (oldPosition.quantity == 0) {
            oldPosition.leverage = 1;
        }
        require(_leverage >= oldPosition.leverage && _leverage <= 125 && _leverage > 0, "IL");
        PositionResp memory positionResp;
        // check if old position quantity is same side with new
        if (oldPosition.quantity == 0 || oldPosition.side() == _side) {
            positionResp = increasePosition(_positionManager, _side, int256(_quantity), _leverage);
        } else {
            // TODO adjust old position
            positionResp = openReversePosition(_positionManager, _side, _side == Position.Side.LONG ? int256(_quantity) : - int256(_quantity), _leverage);
        }
        // update position sate
        positionMap[address(_positionManager)][_trader].update(
            positionResp.position
        );

        if (positionResp.marginToVault > 0) {
            //transfer from trader to vault
            deposit(_positionManager, _trader, positionResp.marginToVault.abs());
        } else if (positionResp.marginToVault < 0) {
            // withdraw from vault to user
            withdraw(_positionManager, _trader, positionResp.marginToVault.abs());
        }
//        canClaimAmountMap[address(_positionManager)][_trader] += positionResp.marginToVault.abs();
        emit OpenMarket(_trader, _side == Position.Side.LONG ? int256(_quantity) : - int256(_quantity), _leverage, positionResp.exchangedQuoteAssetAmount / _quantity, _positionManager);
    }

    /**
    * @notice open position with price limit
    * @param _positionManager IPositionManager address
    * @param _side Side of position LONG or SHORT
    * @param _quantity quantity of size after mul with leverage
    * @param _pip is pip converted from limit price of position
    * @param _leverage leverage of position
    */
    function openLimitOrder(
        IPositionManager _positionManager,
        Position.Side _side,
        uint256 _quantity,
        int128 _pip,
        uint256 _leverage
    ) public whenNotPause nonReentrant {
        require(_quantity == (_quantity / 1000000000000000 * 1000000000000000), "IQ");
        require(_pip > 0, "IP");
        //        requirePositionManager(_positionManager);
        address _trader = _msgSender();
        OpenLimitResp memory openLimitResp;
        (, openLimitResp.orderId, openLimitResp.sizeOut) = openLimitIncludeMarket(_positionManager, _trader, _pip, int256(_quantity).abs128(), _side == Position.Side.LONG ? true : false, _leverage);
        {
            PositionLimitOrder.Data memory _newOrder = PositionLimitOrder.Data({
            pip : _pip,
            orderId : openLimitResp.orderId,
            leverage : uint16(_leverage),
            isBuy : _side == Position.Side.LONG ? 1 : 2,
            entryPrice : 0,
            reduceLimitOrderId : 0,
            reduceQuantity : 0,
            blockNumber : block.number
            });
            handleLimitOrderInOpenLimit(openLimitResp, _newOrder, _positionManager, _trader, _quantity, _side);
        }
        uint256 depositAmount = _quantity * _positionManager.pipToPrice(_pip) / _leverage / _positionManager.getBaseBasisPoint();
        deposit(_positionManager, _trader, depositAmount);
        canClaimAmountMap[address(_positionManager)][_trader] += depositAmount;
        emit OpenLimit(openLimitResp.orderId, _trader, _side == Position.Side.LONG ? int256(_quantity) : - int256(_quantity), _leverage, _pip, _positionManager);
    }

    // There are 4 cases could happen:
    //      1. Old position created by limit Long and market Long, new limit order has market is Long => increase old quantity
    //      2. Old position created by limit Long and market Long, new limit order has market is Short and quantity < old market part Long => reduce old quantity
    //      3. Old position created by limit Long and market Long, new limit order has market is Short and quantity > old market part Long => close and open reverse old market
    //      4. Old position created by limit Long and market Long, new limit order has market is Short and quantity > old position Long => close and open reverse old position
    function openLimitIncludeMarket(IPositionManager _positionManager, address _trader, int128 _pip, uint128 _quantity, bool _isBuy, uint256 _leverage) internal returns (PositionResp memory positionResp, uint64 orderId, uint256 sizeOut){
        {
            Position.Data memory totalPositionData = getPosition(address(_positionManager), _trader);
            require(_leverage >= totalPositionData.leverage && _leverage <= 125 && _leverage > 0, "IL");
            (int128 currentPip, uint8 isFullBuy) = _positionManager.getCurrentSingleSlot();
            uint256 openNotional;
            //1: buy
            //2: sell
            if (_pip == currentPip && isFullBuy != (_isBuy ? 1 : 2) && _isBuy != (totalPositionData.quantity > 0 ? true : false)) {// not is full buy -> open opposite orders
                uint128 liquidityInCurrentPip = _positionManager.getLiquidityInCurrentPip();
                if (totalPositionData.quantity.abs() <= liquidityInCurrentPip && totalPositionData.quantity.abs() <= _quantity && totalPositionData.quantity.abs() != 0) {
                    {
                        PositionResp memory closePositionResp = internalClosePosition(_positionManager, _trader, PnlCalcOption.SPOT_PRICE, true);
                        if (int256(_quantity) - closePositionResp.exchangedPositionSize == 0) {
                            positionResp = closePositionResp;
                        } else {
                            (orderId, sizeOut, openNotional) = _positionManager.openLimitPosition(_pip, _quantity - (closePositionResp.exchangedPositionSize).abs128(), _isBuy);
                        }
                    }
                } else {
                    (orderId, sizeOut, openNotional) = _positionManager.openLimitPosition(_pip, _quantity, _isBuy);
                }
                handleMarketQuantityInLimitOrder(address(_positionManager), _trader, sizeOut, openNotional, _leverage, _isBuy);
            } else {
                (orderId, sizeOut, openNotional) = _positionManager.openLimitPosition(_pip, _quantity, _isBuy);
//                handleMarketQuantityInLimitOrder(address(_positionManager), _trader, sizeOut, openNotional, _leverage, _isBuy);
            }
        }

    }

    // check the new limit order is fully reduce, increase or both reduce and increase
    function handleLimitOrderInOpenLimit(
        OpenLimitResp memory openLimitResp,
        PositionLimitOrder.Data memory _newOrder,
        IPositionManager _positionManager,
        address _trader,
        uint256 _quantity,
        Position.Side _side
    ) internal {
        Position.Data memory _oldPosition = getPosition(address(_positionManager), _trader);

        if (_oldPosition.quantity == 0 || _side == (_oldPosition.quantity > 0 ? Position.Side.LONG : Position.Side.SHORT)) {
            limitOrders[address(_positionManager)][_trader].push(_newOrder);
        } else {
            // if new limit order is smaller than old position then just reduce old position
            if (_oldPosition.quantity.abs() > _quantity) {
                _newOrder.reduceQuantity = _quantity - openLimitResp.sizeOut;
                _newOrder.entryPrice = _oldPosition.openNotional * _positionManager.getBaseBasisPoint() / _oldPosition.quantity.abs();
                reduceLimitOrders[address(_positionManager)][_trader].push(_newOrder);
            }
            // else new limit order is larger than old position then close old position and open new opposite position
            else {
                _newOrder.reduceQuantity = _oldPosition.quantity.abs();
                _newOrder.reduceLimitOrderId = reduceLimitOrders[address(_positionManager)][_trader].length;
                limitOrders[address(_positionManager)][_trader].push(_newOrder);
                _newOrder.entryPrice = _oldPosition.openNotional * _positionManager.getBaseBasisPoint() / _oldPosition.quantity.abs();
                reduceLimitOrders[address(_positionManager)][_trader].push(_newOrder);
            }
        }
    }

    function cancelLimitOrder(IPositionManager _positionManager, uint64 orderIdOfTrader, int128 pip, uint64 orderId) public whenNotPause nonReentrant {
        //        requirePositionManager(_positionManager);
        address _trader = _msgSender();
        uint256 refundQuantity = _positionManager.cancelLimitOrder(pip, orderId);
        int128 oldOrderPip = limitOrders[address(_positionManager)][_trader][orderIdOfTrader].pip;
        uint64 oldOrderId = limitOrders[address(_positionManager)][_trader][orderIdOfTrader].orderId;
        uint16 leverage;
        PositionLimitOrder.Data memory blankLimitOrderData;
        if (pip == oldOrderPip && orderId == oldOrderId) {

            leverage = limitOrders[address(_positionManager)][_trader][orderIdOfTrader].leverage;
            (,,, uint256 partialFilled) = _positionManager.getPendingOrderDetail(pip, orderId);
            if (partialFilled == 0){
                uint256 reduceLimitOrderId = limitOrders[address(_positionManager)][_trader][orderIdOfTrader].reduceLimitOrderId;
                if (reduceLimitOrderId != 0) {
                    reduceLimitOrders[address(_positionManager)][_trader][reduceLimitOrderId] = blankLimitOrderData;
                }
                limitOrders[address(_positionManager)][_trader][orderIdOfTrader] = blankLimitOrderData;

            }
        } else {
            leverage = reduceLimitOrders[address(_positionManager)][_trader][orderIdOfTrader].leverage;
            (,,, uint256 partialFilled) = _positionManager.getPendingOrderDetail(pip, orderId);
            if (partialFilled == 0){
                reduceLimitOrders[address(_positionManager)][_trader][orderIdOfTrader] = blankLimitOrderData;
            }
        }

        require(leverage >= 0 && leverage <= 125, "IL");

        uint256 refundMargin = refundQuantity * _positionManager.pipToPrice(pip) / uint256(leverage) / _positionManager.getBaseBasisPoint();
        withdraw(_positionManager, _trader, refundMargin);
        canClaimAmountMap[address(_positionManager)][_trader] -= refundMargin;
        emit CancelLimitOrder(_trader, address(_positionManager), orderIdOfTrader, orderId);
    }

    /**
    * @notice close position with close market
    * @param _positionManager IPositionManager address
    * @param _quantity want to close
    */
    function closePosition(
        IPositionManager _positionManager,
//        uint256 _percentQuantity,
        uint256 _quantity
    ) public {
        address _trader = _msgSender();
        Position.Data memory positionData = getPosition(address(_positionManager), _trader);
//        require(_percentQuantity > 0 && _percentQuantity <= 100, "IPQ");
        require(_quantity > 0 && _quantity <= positionData.quantity.abs(), "ICQ");
        //        requirePositionManager(_positionManager);
        // only when close 100% position need to close pending order
        if (_quantity == positionData.quantity.abs()) {
            require(getListOrderPending(_positionManager, _trader).length == 0, "ICP");
        }
        // check conditions
        //        requirePositionManager(_positionManager, true);


        PositionResp memory positionResp;

        if (positionData.quantity > 0) {
//            openMarketPosition(_positionManager, Position.Side.SHORT, uint256(positionData.quantity) * _percentQuantity / 100, positionData.leverage);
            openMarketPosition(_positionManager, Position.Side.SHORT, _quantity, positionData.leverage);
        } else {
//            openMarketPosition(_positionManager, Position.Side.LONG, uint256(- positionData.quantity) * _percentQuantity / 100, positionData.leverage);
            openMarketPosition(_positionManager, Position.Side.LONG, _quantity, positionData.leverage);
        }

    }

    /**
    * @notice close position with close market
    * @param _positionManager IPositionManager address
    * @param _pip limit price want to close
    * @param _quantity want to close
    */
    function closeLimitPosition(
        IPositionManager _positionManager,
        int128 _pip,
//        uint256 _percentQuantity,
        uint256 _quantity
    ) public {
        address _trader = _msgSender();
        Position.Data memory positionData = getPosition(address(_positionManager), _trader);
//        require(_percentQuantity > 0 && _percentQuantity <= 100, "IPQ");
        //        requirePositionManager(_positionManager);
        require(_quantity > 0 && _quantity <= positionData.quantity.abs(), "ICQ");
        if (_quantity == positionData.quantity.abs()) {
            require(getListOrderPending(_positionManager, _trader).length == 0, "ICP");
        }



        if (positionData.quantity > 0) {
//            openLimitOrder(_positionManager, Position.Side.SHORT, uint256(positionData.quantity) * _percentQuantity / 100, _pip, positionData.leverage);
            openLimitOrder(_positionManager, Position.Side.SHORT, _quantity, _pip, positionData.leverage);
        } else {
//            openLimitOrder(_positionManager, Position.Side.LONG, uint256(- positionData.quantity) * _percentQuantity / 100, _pip, positionData.leverage);
            openLimitOrder(_positionManager, Position.Side.LONG, _quantity, _pip, positionData.leverage);
        }
    }

    function getClaimAmount(IPositionManager _positionManager, address _trader) public view returns (int256 totalClaimableAmount) {
        Position.Data memory positionData = getPosition(address(_positionManager), _trader);
        return PositionHouseFunction.getClaimAmount(address(_positionManager), _trader, positionData, limitOrders[address(_positionManager)][_trader], reduceLimitOrders[address(_positionManager)][_trader], positionMap[address(_positionManager)][_trader], canClaimAmountMap[address(_positionManager)][_trader], manualMargin[address(_positionManager)][_trader]);
    }

    function claimFund(IPositionManager _positionManager) public whenNotPause nonReentrant {
        address _trader = _msgSender();
        int256 totalRealizedPnl = getClaimAmount(_positionManager, _trader);
        require(getPosition(address(_positionManager), _trader).quantity == 0 && getListOrderPending(_positionManager, _trader).length == 0, "ICF");
        clearPosition(_positionManager, _trader);
        if (totalRealizedPnl > 0) {
            withdraw(_positionManager, _trader, totalRealizedPnl.abs());
        }
    }

    /**
     * @notice liquidate trader's underwater position. Require trader's margin ratio more than partial liquidation ratio
     * @dev liquidator can NOT open any positions in the same block to prevent from price manipulation.
     * @param _positionManager positionManager address
     * @param _trader trader address
     */
    function liquidate(
        IPositionManager _positionManager,
        address _trader
    ) external whenNotPause nonReentrant {
        //        requirePositionManager(_positionManager);
        address _caller = _msgSender();
        (uint256 maintenanceMargin, int256 marginBalance, uint256 marginRatio) = getMaintenanceDetail(_positionManager, _trader);

        // TODO before liquidate should we check can claimFund, because trader has close position limit before liquidate
        // require trader's margin ratio higher than partial liquidation ratio
        require(marginRatio >= partialLiquidationRatio, "NEMR");

        PositionResp memory positionResp;
        uint256 liquidationPenalty;
        {
            uint256 feeToLiquidator;
            uint256 feeToInsuranceFund;
            Position.Data memory positionData = getPosition(address(_positionManager), _trader);
            // partially liquidate position
            if (marginRatio >= partialLiquidationRatio && marginRatio < 100) {

                // calculate amount quantity of position to reduce
                int256 partiallyLiquidateQuantity = positionData.quantity * int256(liquidationPenaltyRatio) / 100;
                //                uint256 oldPositionLeverage = positionData.openNotional / positionData.margin;
                // partially liquidate position by reduce position's quantity
                if (positionData.quantity > 0) {
                    positionResp = partialLiquidate(_positionManager, Position.Side.SHORT, - partiallyLiquidateQuantity, positionData, _trader);
                } else {
                    positionResp = partialLiquidate(_positionManager, Position.Side.LONG, - partiallyLiquidateQuantity, positionData, _trader);
                }

                // half of the liquidationFee goes to liquidator & another half goes to insurance fund
                liquidationPenalty = uint256(positionResp.marginToVault);
                feeToLiquidator = liquidationPenalty / 2;
                feeToInsuranceFund = liquidationPenalty - feeToLiquidator;
                // TODO take liquidation fee
            } else {
                // fully liquidate trader's position
                liquidationPenalty = positionData.margin + uint256(manualMargin[address(_positionManager)][_trader]);
                withdraw(_positionManager, _trader, (uint256(getClaimAmount(_positionManager, _trader)) + positionData.margin));
                clearPosition(_positionManager, _trader);
                feeToLiquidator = liquidationPenalty * liquidationFeeRatio / 2 / 100;
            }
            withdraw(_positionManager, _caller, feeToLiquidator);
            // count as bad debt, transfer money to insurance fund and liquidator
            // emit event position liquidated
        }
        emit Liquidate(address(_positionManager), _trader);
        // emit event
    }

    /**
     * @notice add margin to decrease margin ratio
     * @param _positionManager IPositionManager address
     * @param _marginAdded added margin
     */
    function addMargin(IPositionManager _positionManager, uint256 _marginAdded) external whenNotPause nonReentrant {

        address _trader = _msgSender();
        Position.Data memory oldPositionData = getPosition(address(_positionManager), _trader);
        require(oldPositionData.quantity != 0, "NPTA");
        if (oldPositionData.quantity != 0) {
            manualMargin[address(_positionManager)][_trader] += int256(_marginAdded);
        }

        deposit(_positionManager, _trader, _marginAdded);

        emit AddMargin(_trader, _marginAdded, _positionManager);
    }

    function getAddedMargin(IPositionManager _positionManager, address _trader) public view returns (int256) {
        return manualMargin[address(_positionManager)][_trader];
    }

    /**
     * @notice add margin to increase margin ratio
     * @param _positionManager IPositionManager address
     * @param _marginRemoved added margin
     */
    function removeMargin(IPositionManager _positionManager, uint256 _marginRemoved) external whenNotPause nonReentrant {

        address _trader = _msgSender();

        Position.Data memory oldPositionData = getPosition(address(_positionManager), _trader);
        require(oldPositionData.quantity != 0, "NPTR");
        uint256 removableMargin = uint256(getRemovableMargin(_positionManager, _trader));
        require(_marginRemoved <= removableMargin, "IRM");

        manualMargin[address(_positionManager)][_trader] -= int256(_marginRemoved);

        withdraw(_positionManager, _trader, _marginRemoved);

        emit RemoveMargin(_trader, _marginRemoved, _positionManager);
    }

    function getRemovableMargin(IPositionManager _positionManager, address _trader) public view returns (int256) {
        int256 addedMargin = manualMargin[address(_positionManager)][_trader];
        (uint256 maintenanceMargin ,int256 marginBalance , ) = getMaintenanceDetail(_positionManager, _trader);
        int256 removableMargin = (marginBalance - int256(maintenanceMargin)) > 0 ? (marginBalance - int256(maintenanceMargin)) : 0;
        return addedMargin <= (marginBalance - int256(maintenanceMargin)) ? addedMargin : removableMargin;
    }

    /**
     * @notice clear all attribute of
     * @param _positionManager IPositionManager address
     * @param _trader address to clean position
     */
    // IMPORTANT UPDATE CLEAR LIMIT ORDER
    function clearPosition(IPositionManager _positionManager, address _trader) internal {
        positionMap[address(_positionManager)][_trader].clear();
        debtPosition[address(_positionManager)][_trader].clearDebt();
        manualMargin[address(_positionManager)][_trader] = 0;
        canClaimAmountMap[address(_positionManager)][_trader] = 0;
//        PositionLimitOrder.Data[] memory listLimitOrder = limitOrders[address(_positionManager)][_trader];
//        PositionLimitOrder.Data[] memory reduceLimitOrder = reduceLimitOrders[address(_positionManager)][_trader];
//        (PositionLimitOrder.Data[] memory subListLimitOrder, PositionLimitOrder.Data[] memory subReduceLimitOrder) = PositionHouseFunction.clearAllFilledOrder(_positionManager, _trader, listLimitOrder, reduceLimitOrder);

        if (limitOrders[address(_positionManager)][_trader].length > 0) {
            delete limitOrders[address(_positionManager)][_trader];
        }
//        for (uint256 i = 0; i < subListLimitOrder.length; i++) {
//            limitOrders[address(_positionManager)][_trader][i] = (subListLimitOrder[i]);
//        }
        if (reduceLimitOrders[address(_positionManager)][_trader].length > 0) {
            delete reduceLimitOrders[address(_positionManager)][_trader];
        }
//        for (uint256 i = 0; i < subReduceLimitOrder.length; i++) {
//            reduceLimitOrders[address(_positionManager)][_trader][i] = (subReduceLimitOrder[i]);
//        }
    }

    // TODO can move to position house function
    function increasePosition(
        IPositionManager _positionManager,
        Position.Side _side,
        int256 _quantity,
        uint256 _leverage
    ) internal returns (PositionResp memory positionResp) {
        address _trader = _msgSender();
        (positionResp.exchangedPositionSize, positionResp.exchangedQuoteAssetAmount) = openMarketOrder(_positionManager, _quantity.abs(), _side);
        if (positionResp.exchangedPositionSize != 0) {
            int256 _newSize = positionMap[address(_positionManager)][_trader].quantity + positionResp.exchangedPositionSize;
            uint256 increaseMarginRequirement = positionResp.exchangedQuoteAssetAmount / _leverage;
            // TODO update function latestCumulativePremiumFraction
            uint256 remainMargin = handleMarginInIncrease(address(_positionManager), _trader, increaseMarginRequirement);

            Position.Data memory positionData = getPosition(address(_positionManager), _trader);
            (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_positionManager, _trader, PnlCalcOption.SPOT_PRICE, positionData);

            // update positionResp
            positionResp.unrealizedPnl = unrealizedPnl;
            positionResp.realizedPnl = 0;
            // checked margin to vault
            positionResp.marginToVault = int256(increaseMarginRequirement);
            positionResp.position = Position.Data(
                _newSize,
                remainMargin,
            // NEW FUNCTION handleNotionalInIncrease
                handleNotionalInIncrease(address(_positionManager), _trader, positionResp.exchangedQuoteAssetAmount),
                0,
                block.number,
                _leverage
            );
        }
    }

    function openReversePosition(
        IPositionManager _positionManager,
        Position.Side _side,
        int256 _quantity,
        uint256 _leverage
    ) internal returns (PositionResp memory positionResp) {

        address _trader = _msgSender();
        Position.Data memory oldPosition = getPosition(address(_positionManager), _trader);

        if (_quantity.abs() < oldPosition.quantity.abs()) {
            uint256 reduceMarginRequirement = oldPosition.margin * _quantity.abs() / oldPosition.quantity.abs();
            int256 totalQuantity = positionMap[address(_positionManager)][_trader].quantity + _quantity;
            (positionResp.exchangedPositionSize,) = openMarketOrder(_positionManager, _quantity.abs(), _side);

            (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_positionManager, _trader, PnlCalcOption.SPOT_PRICE, oldPosition);
            positionResp.realizedPnl = unrealizedPnl * int256(positionResp.exchangedPositionSize) / oldPosition.quantity;
            // NEW FUNCTION handleMarginInOpenReverse
            uint256 remainMargin = handleMarginInOpenReverse(address(_positionManager), _trader, reduceMarginRequirement);
            positionResp.exchangedQuoteAssetAmount = _quantity.abs() * oldPosition.getEntryPrice(address(_positionManager)) / _positionManager.getBaseBasisPoint();
            // NOTICE margin to vault can be negative
            // checked margin to vault
            positionResp.marginToVault = - (int256(reduceMarginRequirement) + positionResp.realizedPnl);
            // NOTICE calc unrealizedPnl after open reverse
            positionResp.unrealizedPnl = unrealizedPnl - positionResp.realizedPnl;
            {
                positionResp.position = Position.Data(
                    totalQuantity,
                    remainMargin,
                    handleNotionalInOpenReverse(address(_positionManager), _trader, positionResp.exchangedQuoteAssetAmount),
                    0,
                    block.number,
                    _leverage
                );
            }
            return positionResp;
        }
        // if new position is larger then close old and open new
        return closeAndOpenReversePosition(_positionManager, _side, _quantity, _leverage, oldPosition.openNotional);
    }

    function closeAndOpenReversePosition(
        IPositionManager _positionManager,
        Position.Side _side,
        int256 _quantity,
        uint256 _leverage,
        uint256 _oldOpenNotional
    ) internal returns (PositionResp memory positionResp) {
        address _trader = _msgSender();
        PositionResp memory closePositionResp = internalClosePosition(_positionManager, _trader, PnlCalcOption.SPOT_PRICE, false);
        if (_quantity - closePositionResp.exchangedPositionSize == 0) {
            positionResp = closePositionResp;
        } else {
            PositionResp memory increasePositionResp = increasePosition(_positionManager, _side, _quantity - closePositionResp.exchangedPositionSize, _leverage);
            positionResp = PositionResp({
            position : increasePositionResp.position,
            exchangedQuoteAssetAmount : closePositionResp.exchangedQuoteAssetAmount + increasePositionResp.exchangedQuoteAssetAmount,
            fundingPayment : 0,
            exchangedPositionSize : closePositionResp.exchangedPositionSize + increasePositionResp.exchangedPositionSize,
            realizedPnl : closePositionResp.realizedPnl + increasePositionResp.realizedPnl,
            unrealizedPnl : 0,
            marginToVault : closePositionResp.marginToVault + increasePositionResp.marginToVault
            });
        }
        return positionResp;
    }

    function internalClosePosition(
        IPositionManager _positionManager,
        address _trader,
        PnlCalcOption _pnlCalcOption,
        bool isInOpenLimit
    ) internal returns (PositionResp memory positionResp) {
        Position.Data memory oldPosition = getPosition(address(_positionManager), _trader);
        //        uint256 _currentPrice = _positionManager.getPrice();
        (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_positionManager, _trader, _pnlCalcOption, oldPosition);
        uint256 openMarketQuantity = oldPosition.quantity.abs();
        require(openMarketQuantity != 0, "IQIC");
        if (isInOpenLimit){
            uint256 liquidityInCurrentPip = uint256(_positionManager.getLiquidityInCurrentPip());
            openMarketQuantity = liquidityInCurrentPip > oldPosition.quantity.abs() ? oldPosition.quantity.abs() : liquidityInCurrentPip;
        }

//         positionResp = PositionHouseFunction.internalClosePosition(address(_positionManager), _trader, _pnlCalcOption, oldPosition, openMarketQuantity);


        if (oldPosition.quantity > 0) {
            //sell
            (positionResp.exchangedPositionSize, positionResp.exchangedQuoteAssetAmount) = openMarketOrder(_positionManager, openMarketQuantity, Position.Side.SHORT);
        } else {
            // buy
            (positionResp.exchangedPositionSize, positionResp.exchangedQuoteAssetAmount) = openMarketOrder(_positionManager, openMarketQuantity, Position.Side.LONG);
        }

        uint256 remainMargin = oldPosition.margin;

        positionResp.realizedPnl = unrealizedPnl;
        // NOTICE remainMargin can be negative
        // unchecked: should be -(remainMargin + unrealizedPnl) and update remainMargin with fundingPayment
        positionResp.marginToVault = -((int256(remainMargin) + positionResp.realizedPnl + manualMargin[address(_positionManager)][_trader]) < 0 ? 0 : (int256(remainMargin) + positionResp.realizedPnl + manualMargin[address(_positionManager)][_trader]));
        positionResp.unrealizedPnl = 0;
        canClaimAmountMap[address(_positionManager)][_trader] = 0;
        clearPosition(_positionManager, _trader);
    }

    function handleMarketQuantityInLimitOrder(address _positionManager, address _trader, uint256 _newQuantity, uint256 _newNotional, uint256 _leverage, bool _isBuy) internal {
        Position.Data memory newData;
        Position.Data memory marketPositionData = positionMap[_positionManager][_trader];
        Position.Data memory totalPositionData = getPosition(_positionManager, _trader);
        int256 newPositionSide = _isBuy == true ? int256(1) : int256(- 1);
        if (newPositionSide * totalPositionData.quantity >= 0) {
//            newData = Position.Data(
//                marketPositionData.quantity.sumWithUint256(_newQuantity),
//                handleMarginInIncrease(address(_positionManager), _trader, _newNotional / _leverage),
//                handleNotionalInIncrease(address(_positionManager), _trader, _newNotional),
//            // TODO update latest cumulative premium fraction
//                0,
//                block.number,
//                _leverage
//            );
            if (newPositionSide * marketPositionData.quantity >= 0) {
                newData = Position.Data(
//                    marketPositionData.quantity >= 0 ? marketPositionData.quantity + int256(_newQuantity) : marketPositionData.quantity - int256(_newQuantity),
                    marketPositionData.quantity.sumWithUint256(_newQuantity),
                    handleMarginInIncrease(address(_positionManager), _trader, _newNotional / _leverage),
                    handleNotionalInIncrease(address(_positionManager), _trader, _newNotional),
                // TODO update latest cumulative premium fraction
                    0,
                    block.number,
                    _leverage
                );
            } else {
                newData = Position.Data(
//                    marketPositionData.quantity <= 0 ? marketPositionData.quantity + int256(_newQuantity) : marketPositionData.quantity - int256(_newQuantity),
                    marketPositionData.quantity.minusWithUint256(_newQuantity),
                    handleMarginInIncrease(address(_positionManager), _trader, _newNotional / _leverage),
                    handleNotionalInIncrease(address(_positionManager), _trader, _newNotional),
                // TODO update latest cumulative premium fraction
                    0,
                    block.number,
                    _leverage
                );
            }
        } else {
//            newData = Position.Data(
//                marketPositionData.quantity.minusWithUint256(_newQuantity),
//                handleMarginInOpenReverse(address(_positionManager), _trader, totalPositionData.margin * _newQuantity / totalPositionData.quantity.abs()),
//                handleNotionalInOpenReverse(address(_positionManager), _trader, _newNotional),
//            // TODO update latest cumulative premium fraction
//                0,
//                block.number,
//                _leverage
//            );
            if (newPositionSide * marketPositionData.quantity >= 0) {
                newData = Position.Data(
//                    marketPositionData.quantity >= 0 ? marketPositionData.quantity + int256(_newQuantity) : marketPositionData.quantity - int256(_newQuantity),
                    marketPositionData.quantity.sumWithUint256(_newQuantity),
                    handleMarginInOpenReverse(address(_positionManager), _trader, totalPositionData.margin * _newQuantity / totalPositionData.quantity.abs()),
                    handleNotionalInOpenReverse(address(_positionManager), _trader, _newNotional),
                // TODO update latest cumulative premium fraction
                    0,
                    block.number,
                    _leverage
                );
            } else {
                newData = Position.Data(
//                    marketPositionData.quantity <= 0 ? marketPositionData.quantity + int256(_newQuantity) : marketPositionData.quantity - int256(_newQuantity),
                    marketPositionData.quantity.minusWithUint256(_newQuantity),
                    handleMarginInOpenReverse(address(_positionManager), _trader, totalPositionData.margin * _newQuantity / totalPositionData.quantity.abs()),
                    handleNotionalInOpenReverse(address(_positionManager), _trader, _newNotional),
                // TODO update latest cumulative premium fraction
                    0,
                    block.number,
                    _leverage
                );
            }
        }
        positionMap[_positionManager][_trader].update(
            newData
        );
    }

    function handleNotionalInOpenReverse(address _positionManager, address _trader, uint256 exchangedQuoteAmount) internal returns (uint256 openNotional) {
        Position.Data memory marketPositionData = positionMap[_positionManager][_trader];
        Position.Data memory totalPositionData = getPosition(_positionManager, _trader);
        openNotional = PositionHouseFunction.handleNotionalInOpenReverse(exchangedQuoteAmount, marketPositionData, totalPositionData);
    }

    function handleMarginInOpenReverse(address _positionManager, address _trader, uint256 reduceMarginRequirement) internal returns (uint256 margin) {
        Position.Data memory marketPositionData = positionMap[_positionManager][_trader];
        Position.Data memory totalPositionData = getPosition(_positionManager, _trader);

        margin = PositionHouseFunction.handleMarginInOpenReverse(reduceMarginRequirement, marketPositionData, totalPositionData);

    }

    function handleNotionalInIncrease(address _positionManager, address _trader, uint256 exchangedQuoteAmount) internal returns (uint256 openNotional) {
        Position.Data memory marketPositionData = positionMap[_positionManager][_trader];
        Position.Data memory totalPositionData = getPosition(_positionManager, _trader);

        openNotional = PositionHouseFunction.handleNotionalInIncrease(exchangedQuoteAmount, marketPositionData, totalPositionData);
    }

    function handleMarginInIncrease(address _positionManager, address _trader, uint256 increaseMarginRequirement) internal returns (uint256 margin) {
        Position.Data memory marketPositionData = positionMap[_positionManager][_trader];
        Position.Data memory totalPositionData = getPosition(_positionManager, _trader);

        margin = PositionHouseFunction.handleMarginInIncrease(
            increaseMarginRequirement,
            marketPositionData,
            totalPositionData);
    }

    function getListOrderPending(IPositionManager _positionManager, address _trader) public view returns (LimitOrderPending[] memory){

        return PositionHouseFunction.getListOrderPending(
            address(_positionManager),
            _trader,
            limitOrders[address(_positionManager)][_trader],
            reduceLimitOrders[address(_positionManager)][_trader]);

    }

    // TODO can move to position house function
    function getPosition(
        address positionManager,
        address _trader
    ) public view returns (Position.Data memory positionData){
        positionData = positionMap[positionManager][_trader];
        PositionLimitOrder.Data[] memory _limitOrders = limitOrders[positionManager][_trader];
        PositionLimitOrder.Data[] memory _reduceOrders = reduceLimitOrders[positionManager][_trader];
        IPositionManager _positionManager = IPositionManager(positionManager);
        for (uint i = 0; i < _limitOrders.length; i++) {
            if (_limitOrders[i].pip != 0) {
                positionData = _accumulateLimitOrderToPositionData(_positionManager, _limitOrders[i], positionData, _limitOrders[i].entryPrice, _limitOrders[i].reduceQuantity);
            }
        }
        for (uint i = 0; i < _reduceOrders.length; i++) {
            if (_reduceOrders[i].pip != 0) {
                positionData = _accumulateLimitOrderToPositionData(_positionManager, _reduceOrders[i], positionData, _reduceOrders[i].entryPrice, _reduceOrders[i].reduceQuantity);
            }
        }
        positionData.margin += uint256(manualMargin[positionManager][_trader]);
        Position.LiquidatedData memory _debtPosition = debtPosition[positionManager][_trader];
        if (_debtPosition.margin != 0) {
            positionData.quantity -= _debtPosition.quantity;
            positionData.margin -= _debtPosition.margin;
            positionData.openNotional -= _debtPosition.notional;
        }
    }


    function getPositionNotionalAndUnrealizedPnl(
        IPositionManager positionManager,
        address _trader,
        PnlCalcOption _pnlCalcOption,
        Position.Data memory oldPosition
    ) public view returns
    (
        uint256 positionNotional,
        int256 unrealizedPnl
    ){
        // TODO remove function getPosition
        oldPosition = getPosition(address(positionManager), _trader);
//        (positionNotional, unrealizedPnl) = PositionHouseFunction.getPositionNotionalAndUnrealizedPnl(address(positionManager), _trader, _pnlCalcOption, oldPosition);

        uint256 oldPositionNotional = oldPosition.openNotional;
        if (_pnlCalcOption == PositionHouse.PnlCalcOption.SPOT_PRICE) {
            positionNotional = positionManager.getPrice() * oldPosition.quantity.abs() / positionManager.getBaseBasisPoint();
        }
        else if (_pnlCalcOption == PositionHouse.PnlCalcOption.TWAP) {
            // TODO get twap price
        }
        else {
            // TODO get oracle price
        }

        if (oldPosition.side() == Position.Side.LONG) {
            unrealizedPnl = int256(positionNotional) - int256(oldPositionNotional);
        } else {
            unrealizedPnl = int256(oldPositionNotional) - int256(positionNotional);
        }
    }

    //    function getLiquidationPrice(
    //        IPositionManager positionManager,
    //        address _trader,
    //        PnlCalcOption _pnlCalcOption
    //    ) public view returns (uint256 liquidationPrice){
    //        Position.Data memory positionData = getPosition(address(positionManager), _trader);
    //        (uint256 maintenanceMargin,,) = getMaintenanceDetail(positionManager, _trader);
    //        if (positionData.side() == Position.Side.LONG) {
    //            liquidationPrice = (maintenanceMargin - positionData.margin + positionData.openNotional) / positionData.quantity.abs();
    //        } else {
    //            liquidationPrice = (positionData.openNotional - maintenanceMargin + positionData.margin) / positionData.quantity.abs();
    //        }
    //    }


    function getMaintenanceDetail(
        IPositionManager _positionManager,
        address _trader
    ) public view returns (uint256 maintenanceMargin, int256 marginBalance, uint256 marginRatio) {
        Position.Data memory positionData = getPosition(address(_positionManager), _trader);
        (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_positionManager, _trader, PnlCalcOption.SPOT_PRICE, positionData);
//        (uint256 maintenanceMargin, int256 marginBalance, uint256 marginRatio) = PositionHouseFunction.calcMaintenanceDetail(positionData, maintenanceMarginRatio, unrealizedPnl);
        maintenanceMargin = (positionData.margin - uint256(manualMargin[address(_positionManager)][_trader])) * maintenanceMarginRatio / 100;
        marginBalance = int256(positionData.margin) + unrealizedPnl;
        if (marginBalance <= 0) {
            marginRatio = 100;
        } else {
            marginRatio = maintenanceMargin * 100 / uint256(marginBalance);
        }
    }

    //    function getLatestCumulativePremiumFraction(IPositionManager _positionManager) public view returns (int256) {
    //        //        uint256 len = positionManagerMap[address(_positionManager)].cumulativePremiumFraction.length;
    //        //        if (len > 0) {
    //        //            return positionManagerMap[address(_positionManager)].cumulativePremiumFraction[len - 1];
    //        //        }
    //        return 0;
    //    }

    //    function payFunding(IPositionManager _positionManager) external onlyOwner {
    //        //            requirePositionManager(_positionManager, true);
    //
    //        int256 premiumFraction = _positionManager.settleFunding();
    //        //            positionManagerMap[address(_positionManager)].cumulativePremiumFraction.push(premiumFraction + getLatestCumulativePremiumFraction(_positionManager));
    //    }

    function calcFee(
        address _trader,
        IPositionManager _positionManager,
        uint256 _positionNotional
    ) internal returns (uint256) {
            // TODO undo comment calcFee
//        return _positionManager.calcFee(_positionNotional);
        return 0;
    }

    function withdraw(IPositionManager _positionManager, address _trader, uint256 amount) internal {
        insuranceFund.withdraw(address(_positionManager.getQuoteAsset()), _trader, amount);
    }

    function deposit(IPositionManager _positionManager, address _trader, uint256 amount) internal {
        insuranceFund.deposit(address(_positionManager.getQuoteAsset()), _trader, amount);


//        insuranceFund.updateTotalFee(fee);
    }

    //
    // REQUIRE FUNCTIONS
    //
    //    function requirePositionManager(
    //        IPositionManager positionManager
    //    ) private view {
    //
    //        //PMNO : Position Manager Not Open
    //        require(positionManager.open() == true, "PMNO");
    //    }

    // TODO define criteria
//    function requireMoreMarginRatio(uint256 _marginRatio) private view {
//        require(_marginRatio >= partialLiquidationRatio, "NEMR");
//    }

//    function requirePositionSize(
//        int256 _quantity
//    ) private pure {
//        require(_quantity != 0, "IQIC");
//    }

    //
    // INTERNAL FUNCTION OF POSITION HOUSE
    //

    function openMarketOrder(
        IPositionManager _positionManager,
        uint256 _quantity,
        Position.Side _side
    ) internal returns (int256 exchangedQuantity, uint256 openNotional) {
        address _trader = _msgSender();

//        (int256 exchangedQuantity, uint256 openNotional) = PositionHouseFunction.openMarketOrder(address(_positionManager), _quantity, _side, _trader);
        uint256 exchangedSize;

        (exchangedSize, openNotional) = _positionManager.openMarketPosition(_quantity, _side == Position.Side.LONG);
        require(exchangedSize == _quantity, "NELQ");
        exchangedQuantity = _side == Position.Side.LONG ? int256(exchangedSize) : - int256(exchangedSize);
    }


    // TODO update function parameter to positionManager, oldPositionData, marginDelta
    //    function calcRemainMarginWithFundingPayment(
    //        uint256 deltaMargin
    //    ) internal view returns (uint256 remainMargin, uint256 fundingPayment, int256 latestCumulativePremiumFraction){
    //
    //        remainMargin = uint256(deltaMargin);
    //    }

    // new function
    //    function calcRemainMarginWithFundingPaymentNew(
    //        IPositionManager _positionManager, Position.Data memory oldPosition, int256 deltaMargin
    //    ) internal view returns (uint256 remainMargin, uint256 badDebt, int256 fundingPayment, int256 latestCumulativePremiumFraction){
    //
    //        // calculate fundingPayment
    //        latestCumulativePremiumFraction = getLatestCumulativePremiumFraction(_positionManager);
    //        if (oldPosition.quantity != 0) {
    //            fundingPayment = (latestCumulativePremiumFraction - oldPosition.lastUpdatedCumulativePremiumFraction) * oldPosition.quantity;
    //        }
    //
    //        // calculate remain margin, if remain margin is negative, set to zero and leave the rest to bad debt
    //        if (deltaMargin + fundingPayment >= 0) {
    //            remainMargin = uint256(deltaMargin + fundingPayment);
    //        } else {
    //            badDebt = uint256(- fundingPayment - deltaMargin);
    //        }
    //
    //        fundingPayment = 0;
    //        latestCumulativePremiumFraction = 0;
    //    }


    // TODO can move to position house function
    function partialLiquidate(
        IPositionManager _positionManager,
        Position.Side _side,
        int256 _quantity,
        Position.Data memory _oldPosition,
        address _trader
    ) internal returns (PositionResp memory positionResp){
//        Position.Data memory oldPosition = getPosition(address(_positionManager), _trader);
        (positionResp.exchangedPositionSize,) = openMarketOrder(_positionManager, _quantity.abs(), _side);
        positionResp.exchangedQuoteAssetAmount = _quantity.abs() * (_oldPosition.openNotional / _oldPosition.quantity.abs());
        (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_positionManager, _trader, PnlCalcOption.SPOT_PRICE, _oldPosition);
        // TODO need to calculate remain margin with funding payment
        uint256 remainMargin = _oldPosition.margin * (100 - liquidationFeeRatio) / 100;
        // unchecked
        positionResp.marginToVault = int256(_oldPosition.margin) - int256(remainMargin);
        positionResp.unrealizedPnl = unrealizedPnl;
        debtPosition[address(_positionManager)][_trader].updateDebt(
            - _quantity,
            _oldPosition.margin - remainMargin,
            positionResp.exchangedQuoteAssetAmount
        );
        return positionResp;
    }

    function _accumulateLimitOrderToPositionData(
        IPositionManager _positionManager,
        PositionLimitOrder.Data memory limitOrder,
        Position.Data memory positionData,
        uint256 entryPrice,
        uint256 reduceQuantity) internal view returns (Position.Data memory) {

        return PositionHouseFunction.accumulateLimitOrderToPositionData(address(_positionManager), limitOrder, positionData, entryPrice, reduceQuantity);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPositionManager {
    function getCurrentPip() external view returns (int128);

    function getBaseBasisPoint() external view returns (uint256);

    function getCurrentSingleSlot() external view returns (int128, uint8);

    function getLiquidityInCurrentPip() external view returns (uint128);

    function updatePartialFilledOrder(int128 pip, uint64 orderId) external;

    function getPendingOrderDetail(int128 pip, uint64 orderId) external view returns (
        bool isFilled,
        bool isBuy,
        uint256 size,
        uint256 partialFilled
    );

    function openLimitPosition(int128 pip, uint128 size, bool isBuy) external returns (uint64 orderId, uint256 sizeOut, uint256 openNotional);

    function openMarketPosition(uint256 size, bool isBuy) external returns (uint256 sizeOut, uint256 openNotional);

    function getPrice() external view returns (uint256);

    function pipToPrice(int128 pip) external view returns (uint256);

    function getQuoteAsset() external view returns (IERC20);

    function calcAdjustMargin(uint256 adjustMargin) external view returns (uint256);

    function calcFee(uint256 _positionNotional) external view returns (uint256);

    function cancelLimitOrder(int128 pip, uint64 orderId) external returns (uint256);

    function settleFunding() external returns (int256 premiumFraction);

    function open() external view returns (bool);
}

pragma solidity ^0.8.0;

import "../helpers/Quantity.sol";
import "hardhat/console.sol";
import "../../../interfaces/IPositionManager.sol";


library Position {

    using Quantity for int256;
    enum Side {LONG, SHORT}
    struct Data {
        // TODO restruct data
        //        Position.Side side;
        int256 quantity;
        uint256 margin;
        uint256 openNotional;
        int256 lastUpdatedCumulativePremiumFraction;
        uint256 blockNumber;
        uint256 leverage;
    }

    struct LiquidatedData {
        int256 quantity;
        uint256 margin;
        uint256 notional;
    }

    function updateDebt(
        Position.LiquidatedData storage self,
        int256 _quantity,
        uint256 _margin,
        uint256 _notional
    ) internal {
        self.quantity += _quantity;
        self.margin += _margin;
        self.notional += _notional;
    }

    function update(
        Position.Data storage self,
        Position.Data memory newPosition
    ) internal {
        self.quantity = newPosition.quantity;
        self.margin = newPosition.margin;
        self.openNotional = newPosition.openNotional;
        self.lastUpdatedCumulativePremiumFraction = newPosition.lastUpdatedCumulativePremiumFraction;
        self.blockNumber = newPosition.blockNumber;
        self.leverage = newPosition.leverage;
    }

    function updateMargin(
        Position.Data storage self,
        uint256 newMargin
    ) internal {
        self.margin = newMargin;
    }

    function updatePartialLiquidate(
        Position.Data storage self,
        Position.Data memory newPosition
    ) internal {
        self.quantity += newPosition.quantity;
        self.margin -= newPosition.margin;
        self.openNotional -= newPosition.openNotional;
        self.lastUpdatedCumulativePremiumFraction += newPosition.lastUpdatedCumulativePremiumFraction;
        self.blockNumber += newPosition.blockNumber;
        self.leverage = self.leverage;
    }

    function clearDebt(Position.LiquidatedData storage self) internal {
        self.quantity = 0;
        self.margin = 0;
        self.notional = 0;
    }

    function clear(
        Position.Data storage self
    ) internal {
        self.quantity = 0;
        self.margin = 0;
        self.openNotional = 0;
        self.lastUpdatedCumulativePremiumFraction = 0;
        // TODO get current block number
        self.blockNumber = 0;
        self.leverage = 0;
    }

    function side(Position.Data memory self) internal view returns (Position.Side) {
        return self.quantity > 0 ? Position.Side.LONG : Position.Side.SHORT;
    }

    function getEntryPrice(
        Position.Data memory self,
        address addressPositionManager
    ) internal view returns (uint256){
        IPositionManager _positionManager = IPositionManager(addressPositionManager);
        return self.openNotional * _positionManager.getBaseBasisPoint() / self.quantity.abs() ;
    }

    function accumulateLimitOrder(
        Position.Data memory self,
        int256 quantity,
        uint256 orderMargin,
        uint256 orderNotional
    ) internal view returns (Position.Data memory positionData) {
        // same side
        if (self.quantity * quantity > 0) {
            positionData.margin = self.margin + orderMargin;
            positionData.openNotional = self.openNotional + orderNotional;
        } else {
            positionData.margin = self.margin > orderMargin ? self.margin - orderMargin : orderMargin - self.margin;
            positionData.openNotional = self.openNotional > orderNotional ? self.openNotional - orderNotional : orderNotional - self.openNotional;
        }
        positionData.quantity = self.quantity + quantity;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity ^0.8.0;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


import "./libraries/position/TickPosition.sol";
import "./libraries/position/LimitOrder.sol";
import "./libraries/position/LiquidityBitmap.sol";
import {IChainLinkPriceFeed} from "../interfaces/IChainLinkPriceFeed.sol";

import "hardhat/console.sol";

contract PositionManager is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using TickPosition for TickPosition.Data;
    using LiquidityBitmap for mapping(int128 => uint256);
    uint256 public basisPoint; //0.01
    uint256 public BASE_BASIC_POINT;
    // fee = quoteAssetAmount / tollRatio (means if fee = 0.001% then tollRatio = 100000)
    uint256 tollRatio;

    int256 public fundingRate;

    uint256 public spotPriceTwapInterval;
    uint256 public fundingPeriod;
    uint256 public fundingBufferPeriod;
    uint256 public nextFundingTime;
    bytes32 public priceFeedKey;
    // Max finding word can be 3500
    int128 public maxFindingWordsIndex;

    address private counterParty;

    bool public isOpen;

    IChainLinkPriceFeed public priceFeed;

    struct SingleSlot {
        int128 pip;
        //0: not set
        //1: buy
        //2: sell
        uint8 isFullBuy;
    }

    IERC20 quoteAsset;

    struct ReserveSnapshot {
        int128 pip;
        uint256 timestamp;
        uint256 blockNumber;
    }

    enum TwapCalcOption {RESERVE_ASSET, INPUT_ASSET}

    struct TwapPriceCalcParams {
        TwapCalcOption opt;
        uint256 snapshotIndex;
    }

    struct SwapState {
        uint256 remainingSize;
        // the tick associated with the current price
        int128 pip;
    }

    struct StepComputations {
        int128 pipNext;
    }

    enum CurrentLiquiditySide {
        NotSet,
        Buy,
        Sell
    }

    // array of reserveSnapshots
    ReserveSnapshot[] public reserveSnapshots;


    SingleSlot public singleSlot;
    mapping(int128 => TickPosition.Data) public tickPosition;
    mapping(int128 => uint256) public tickStore;
    // a packed array of bit, where liquidity is filled or not
    mapping(int128 => uint256) public liquidityBitmap;

    // Events that supports building order book
    event MarketFilled(bool isBuy, uint256 indexed amount, int128 toPip, uint256 passedPipcount, uint128 partialFilledQuantity);
    event LimitOrderCreated(uint64 orderId, int128 pip, uint128 size, bool isBuy);
    event LimitOrderCancelled(uint64 orderId, int128 pip, uint256 size);

    event UpdateMaxFindingWordsIndex(int128 newMaxFindingWordsIndex);
    event UpdateBasisPoint(uint256 newBasicPoint);
    event UpdateBaseBasicPoint(uint256 newBaseBasisPoint);
    event UpdateTollRatio(uint256 newTollRatio);
    event UpdateSpotPriceTwapInterval(uint256 newSpotPriceTwapInterval);
    event ReserveSnapshotted(int128 pip, uint256 timestamp);
    event FundingRateUpdated(int256 fundingRate, uint256 underlyingPrice);
    event LimitOrderUpdated(uint64 orderId, int128 pip, uint256 size);

    modifier whenNotPause(){
        //TODO implement
        _;
    }

    modifier onlyCounterParty(){
        require(counterParty == _msgSender(), "caller is not counterParty");
        _;
    }


    function initialize(
        int128 _initialPip,
        address _quoteAsset,
        bytes32 _priceFeedKey,
        uint256 _basisPoint,
        uint256 _BASE_BASIC_POINT,
        uint256 _tollRatio,
        int128 _maxFindingWordsIndex,
        uint256 _fundingPeriod,
        address _priceFeed,
        address _counterParty
    )
    public initializer {
        require(
            _fundingPeriod != 0 &&
            _quoteAsset != address(0) &&
            _priceFeed != address(0) &&
            _counterParty != address(0),
            "invalid input"
        );

        __ReentrancyGuard_init();
        __Ownable_init();

        priceFeedKey = _priceFeedKey;
        singleSlot.pip = _initialPip;
        reserveSnapshots.push(
            ReserveSnapshot(_initialPip, block.timestamp, block.number)
        );
        quoteAsset = IERC20(_quoteAsset);
        basisPoint = _basisPoint;
        BASE_BASIC_POINT = _BASE_BASIC_POINT;
        tollRatio = _tollRatio;
        spotPriceTwapInterval = 1 hours;
        fundingPeriod = _fundingPeriod;
        fundingBufferPeriod = _fundingPeriod / 2;
        maxFindingWordsIndex = _maxFindingWordsIndex;
        priceFeed = IChainLinkPriceFeed(_priceFeed);
        isOpen = true;
        counterParty = _counterParty;

        emit ReserveSnapshotted(_initialPip, block.timestamp);
    }

    function getBaseBasisPoint() public view returns (uint256) {
        return BASE_BASIC_POINT;
    }

    function getCurrentPip() public view returns (int128) {
        return singleSlot.pip;
    }

    function getCurrentSingleSlot() public view returns (int128, uint8) {
        return (singleSlot.pip, singleSlot.isFullBuy);
    }

    function getPrice() public view returns (uint256) {
        return uint256(uint128(singleSlot.pip)) * BASE_BASIC_POINT / basisPoint;
    }

    function pipToPrice(int128 pip) public view returns (uint256) {
        return uint256(uint128(pip)) * BASE_BASIC_POINT / basisPoint;
    }

    function getLiquidityInCurrentPip() public view returns (uint128){
        return liquidityBitmap.hasLiquidity(singleSlot.pip) ? tickPosition[singleSlot.pip].liquidity : 0;
    }

    function calcAdjustMargin(uint256 adjustMargin) public view returns (uint256) {
        return adjustMargin;
    }

    function hasLiquidity(int128 pip) public view returns (bool) {
        return liquidityBitmap.hasLiquidity(pip);
    }

    function getPendingOrderDetail(int128 pip, uint64 orderId) public view returns (
        bool isFilled,
        bool isBuy,
        uint256 size,
        uint256 partialFilled
    ){
        (isFilled, isBuy, size, partialFilled) = tickPosition[pip].getQueueOrder(orderId);

        if (!liquidityBitmap.hasLiquidity(pip)) {
            isFilled = true;
        }
        if (size != 0 && size == partialFilled) {
            isFilled = true;
        }
    }

    function updatePartialFilledOrder(int128 pip, uint64 orderId) public {
        uint256 newSize = tickPosition[pip].updateOrderWhenClose(orderId);
        emit LimitOrderUpdated(orderId, pip, newSize);
    }

    /**
     * @notice calculate total fee (including toll and spread) by input quote asset amount
     * @param _positionNotional quote asset amount
     * @return total tx fee
     */
    function calcFee(uint256 _positionNotional) external view returns (uint256)
    {
        if (tollRatio != 0) {
            return _positionNotional == 0 ? 0 : _positionNotional / tollRatio;
        }
        return 0;
    }

    function cancelLimitOrder(int128 pip, uint64 orderId) external onlyCounterParty returns (uint256 size) {
        size = tickPosition[pip].cancelLimitOrder(orderId);
        if (orderId == tickPosition[pip].currentIndex && orderId <= tickPosition[pip].filledIndex) {
            liquidityBitmap.toggleSingleBit(pip, false);
        }
        emit LimitOrderCancelled(orderId, pip, size);
    }

    function openLimitPosition(int128 pip, uint128 size, bool isBuy) external whenNotPause onlyCounterParty returns (uint64 orderId, uint256 sizeOut, uint256 openNotional) {
        if (isBuy && singleSlot.pip != 0) {
            require(pip <= singleSlot.pip && pip >= (singleSlot.pip - maxFindingWordsIndex * 250), "!B");
        } else {
            require(pip >= singleSlot.pip && pip <= (singleSlot.pip + maxFindingWordsIndex * 250), "!S");
        }
        SingleSlot memory _singleSlot = singleSlot;
        bool hasLiquidity = liquidityBitmap.hasLiquidity(pip);
        //save gas
        if (pip == _singleSlot.pip && hasLiquidity && _singleSlot.isFullBuy != (isBuy ? 1 : 2)) {
            // open market
            (sizeOut, openNotional) = openMarketPositionWithMaxPip(size, isBuy, pip);
        }
        if (size > sizeOut) {
            if (pip == _singleSlot.pip && _singleSlot.isFullBuy != (isBuy ? 1 : 2)) {
                singleSlot.isFullBuy = isBuy ? 1 : 2;
            }
            //TODO validate pip
            // convert tick to price
            // save at that pip has how many liquidity
            orderId = tickPosition[pip].insertLimitOrder(uint120(size - uint128(sizeOut)), hasLiquidity, isBuy);
            if (!hasLiquidity) {
                //set the bit to mark it has liquidity
                liquidityBitmap.toggleSingleBit(pip, true);
            }
        }
        // TODO update emit event
        emit LimitOrderCreated(orderId, pip, size, isBuy);
    }


    function openMarketPositionWithMaxPip(uint256 size, bool isBuy, int128 maxPip) public whenNotPause onlyCounterParty returns (uint256 sizeOut, uint256 openNotional) {
        return _internalOpenMarketOrder(size, isBuy, maxPip);
    }

    function openMarketPosition(uint256 size, bool isBuy) external whenNotPause onlyCounterParty returns (uint256 sizeOut, uint256 openNotional) {
        return _internalOpenMarketOrder(size, isBuy, 0);
    }

    function _internalOpenMarketOrder(uint256 size, bool isBuy, int128 maxPip) internal returns (uint256 sizeOut, uint256 openNotional) {
        require(size != 0, "!Size");
        // TODO lock
        // get current tick liquidity
        SingleSlot memory _initialSingleSlot = singleSlot;
        //save gas
        SwapState memory state = SwapState({
        remainingSize : size,
        pip : _initialSingleSlot.pip
        });
        int128 startPip;
        //        int128 startWord = _initialSingleSlot.pip >> 8;
        //        int128 wordIndex = startWord;
        uint128 partialFilledQuantity;
        uint8 isFullBuy = 0;
        bool isSkipFirstPip;
        uint256 passedPipCount = 0;
        CurrentLiquiditySide currentLiquiditySide = CurrentLiquiditySide(_initialSingleSlot.isFullBuy);
        if (currentLiquiditySide != CurrentLiquiditySide.NotSet) {
            if (isBuy)
            // if buy and latest liquidity is buy. skip current pip
                isSkipFirstPip = currentLiquiditySide == CurrentLiquiditySide.Buy;
            else
            // if sell and latest liquidity is sell. skip current pip
                isSkipFirstPip = currentLiquiditySide == CurrentLiquiditySide.Sell;
        }
        while (state.remainingSize != 0) {
            StepComputations memory step;
            // updated findHasLiquidityInMultipleWords, save more gas
            (step.pipNext) = liquidityBitmap.findHasLiquidityInMultipleWords(
                state.pip,
                maxFindingWordsIndex,
                !isBuy
            );
            if (maxPip != 0 && step.pipNext != maxPip) break;
            if (step.pipNext == 0) {
                // no more next pip
                // state pip back 1 pip
                if (isBuy) {
                    state.pip--;
                } else {
                    state.pip++;
                }
                break;
            }
            else {
                if (!isSkipFirstPip) {
                    if (startPip == 0) startPip = step.pipNext;

                    // get liquidity at a tick index
                    uint128 liquidity = tickPosition[step.pipNext].liquidity;
                    if (liquidity > state.remainingSize) {
                        // pip position will partially filled and stop here
                        tickPosition[step.pipNext].partiallyFill(uint120(state.remainingSize));
                        openNotional += (state.remainingSize * pipToPrice(step.pipNext) / BASE_BASIC_POINT);
                        // remaining liquidity at current pip
                        partialFilledQuantity = liquidity - uint128(state.remainingSize);
                        state.remainingSize = 0;
                        state.pip = step.pipNext;
                        isFullBuy = uint8(!isBuy ? CurrentLiquiditySide.Buy : CurrentLiquiditySide.Sell);
                    } else if (state.remainingSize > liquidity) {
                        // order in that pip will be fulfilled
                        state.remainingSize = state.remainingSize - liquidity;
                        openNotional += (liquidity * pipToPrice(step.pipNext) / BASE_BASIC_POINT);
                        state.pip = state.remainingSize > 0 ? (isBuy ? step.pipNext + 1 : step.pipNext - 1) : step.pipNext;
                        passedPipCount++;
                    } else {
                        // remaining size = liquidity
                        // only 1 pip should be toggled, so we call it directly here
                        liquidityBitmap.toggleSingleBit(step.pipNext, false);
                        openNotional += (state.remainingSize * pipToPrice(step.pipNext) / BASE_BASIC_POINT);
                        state.remainingSize = 0;
                        state.pip = step.pipNext;
                        isFullBuy = 0;
                        passedPipCount++;
                    }
                } else {
                    isSkipFirstPip = false;
                    state.pip = isBuy ? step.pipNext + 1 : step.pipNext - 1;
                }
            }
        }
        if (_initialSingleSlot.pip != state.pip) {
            // all ticks in shifted range must be marked as filled
            if (!(partialFilledQuantity > 0 && startPip == state.pip)) {
                liquidityBitmap.unsetBitsRange(startPip, partialFilledQuantity > 0 ? (isBuy ? state.pip - 1 : state.pip + 1) : state.pip);
            }
            // TODO write a checkpoint that we shift a range of ticks
        }
        singleSlot.pip = maxPip != 0 ? maxPip : state.pip;
        singleSlot.isFullBuy = isFullBuy;
        sizeOut = size - state.remainingSize;
        addReserveSnapshot();
        emit MarketFilled(isBuy, sizeOut, maxPip != 0 ? maxPip : state.pip, passedPipCount, partialFilledQuantity);
    }

    struct LiquidityOfEachPip {
        int128 pip;
        uint256 liquidity;
    }

    function getLiquidityInPipRange(int128 fromPip, uint256 dataLength, bool toHigher) public view returns (LiquidityOfEachPip[] memory, int128) {
        int128[] memory allInitializedPip = new int128[](uint128(dataLength));
        allInitializedPip = liquidityBitmap.findAllLiquidityInMultipleWords(fromPip, dataLength, toHigher);
        LiquidityOfEachPip[] memory allLiquidity = new LiquidityOfEachPip[](dataLength);


        for (uint i = 0; i < dataLength; i++) {
            allLiquidity[i] = LiquidityOfEachPip({
            pip : allInitializedPip[i],
            liquidity : tickPosition[allInitializedPip[i]].liquidity
            });
        }
        return (allLiquidity, allInitializedPip[dataLength - 1]);
    }

    function getQuoteAsset() public view returns (IERC20) {
        return quoteAsset;
    }

    function updateMaxFindingWordsIndex(int128 _newMaxFindingWordsIndex) public onlyOwner {
        maxFindingWordsIndex = _newMaxFindingWordsIndex;
        emit  UpdateMaxFindingWordsIndex(_newMaxFindingWordsIndex);
    }

    function updateBasisPoint(uint256 _newBasisPoint) public onlyOwner {
        basisPoint = _newBasisPoint;
        emit UpdateBasisPoint(_newBasisPoint);
    }

    function updateBaseBasicPoint(uint256 _newBaseBasisPoint) public onlyOwner {
        BASE_BASIC_POINT = _newBaseBasisPoint;
        emit UpdateBaseBasicPoint(_newBaseBasisPoint);
    }

    function updateTollRatio(uint256 newTollRatio) public onlyOwner {
        tollRatio = newTollRatio;
        emit UpdateTollRatio(newTollRatio);
    }

    function setOpen(bool _open) public onlyOwner {
        if (isOpen == _open) return;
        isOpen = _open;
    }

    function open() public view returns (bool) {
        return isOpen;
    }

    function setCounterParty(address _counterParty) public onlyOwner {
        require(_counterParty != address(0), "Invalid address");
        counterParty = _counterParty;
    }

    function updateSpotPriceTwapInterval(uint256 _spotPriceTwapInterval) public onlyOwner {

        spotPriceTwapInterval = _spotPriceTwapInterval;
        emit UpdateSpotPriceTwapInterval(_spotPriceTwapInterval);

    }

    /**
     * @notice update funding rate
     * @dev only allow to update while reaching `nextFundingTime`
     * @return premiumFraction of this period in 18 digits
     */
    function settleFunding() external onlyCounterParty returns (int256 premiumFraction) {
        require(block.timestamp >= nextFundingTime, "settle funding too early");

        // premium = twapMarketPrice - twapIndexPrice
        // timeFraction = fundingPeriod(1 hour) / 1 day
        // premiumFraction = premium * timeFraction
        uint256 underlyingPrice = getUnderlyingTwapPrice(spotPriceTwapInterval);
        int256 premium = int256(getTwapPrice(spotPriceTwapInterval)) - int256(underlyingPrice);
        premiumFraction = premium * int256(fundingPeriod) / int256(1 days);

        // update funding rate = premiumFraction / twapIndexPrice
        updateFundingRate(premiumFraction, underlyingPrice);

        // in order to prevent multiple funding settlement during very short time after network congestion
        uint256 minNextValidFundingTime = block.timestamp + fundingBufferPeriod;

        // floor((nextFundingTime + fundingPeriod) / 3600) * 3600
        uint256 nextFundingTimeOnHourStart = (nextFundingTime + fundingPeriod) / (1 hours) * (1 hours);

        // max(nextFundingTimeOnHourStart, minNextValidFundingTime)
        nextFundingTime = nextFundingTimeOnHourStart > minNextValidFundingTime
        ? nextFundingTimeOnHourStart
        : minNextValidFundingTime;

        return premiumFraction;
    }

    /**
     * @notice get underlying price provided by oracle
     * @return underlying price
     */
    function getUnderlyingPrice() public view returns (uint256) {
        return priceFeed.getPrice(priceFeedKey) * BASE_BASIC_POINT;
    }

    /**
     * @notice get underlying twap price provided by oracle
     * @return underlying price
     */
    function getUnderlyingTwapPrice(uint256 _intervalInSeconds) public view returns (uint256) {
        return priceFeed.getTwapPrice(priceFeedKey, _intervalInSeconds) * BASE_BASIC_POINT;
    }

    /**
     * @notice get twap price
     */
    function getTwapPrice(uint256 _intervalInSeconds) public view returns (uint256) {
        return implGetReserveTwapPrice(_intervalInSeconds);
    }

    function implGetReserveTwapPrice(uint256 _intervalInSeconds) public view returns (uint256) {
        TwapPriceCalcParams memory params;
        // Can remove this line
        params.opt = TwapCalcOption.RESERVE_ASSET;
        params.snapshotIndex = reserveSnapshots.length - 1;
        return calcTwap(params, _intervalInSeconds);
    }

    function calcTwap(TwapPriceCalcParams memory _params, uint256 _intervalInSeconds)
    public
    view
    returns (uint256)
    {
        uint256 currentPrice = getPriceWithSpecificSnapshot(_params);
        if (_intervalInSeconds == 0) {
            return currentPrice;
        }

        uint256 baseTimestamp = block.timestamp - _intervalInSeconds;
        ReserveSnapshot memory currentSnapshot = reserveSnapshots[_params.snapshotIndex];
        // return the latest snapshot price directly
        // if only one snapshot or the timestamp of latest snapshot is earlier than asking for
        if (reserveSnapshots.length == 1 || currentSnapshot.timestamp <= baseTimestamp) {
            return currentPrice;
        }

        uint256 previousTimestamp = currentSnapshot.timestamp;
        // period same as cumulativeTime
        uint256 period = block.timestamp - previousTimestamp;
        uint256 weightedPrice = currentPrice * period;
        while (true) {
            // if snapshot history is too short
            if (_params.snapshotIndex == 0) {
                return weightedPrice / period;
            }

            _params.snapshotIndex = _params.snapshotIndex - 1;
            currentSnapshot = reserveSnapshots[_params.snapshotIndex];
            currentPrice = getPriceWithSpecificSnapshot(_params);

            // check if current snapshot timestamp is earlier than target timestamp
            if (currentSnapshot.timestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, _intervalInSeconds is 100, then target timestamp is 900. If timestamp of current snapshot is 970,
                // and timestamp of NEXT snapshot is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice = weightedPrice + (currentPrice * (previousTimestamp - baseTimestamp));
                break;
            }

            uint256 timeFraction = previousTimestamp - currentSnapshot.timestamp;
            weightedPrice = weightedPrice + (currentPrice * timeFraction);
            period = period + timeFraction;
            previousTimestamp = currentSnapshot.timestamp;
        }
        return weightedPrice / _intervalInSeconds;
    }

    function getPriceWithSpecificSnapshot(TwapPriceCalcParams memory params)
    internal
    view
    virtual
    returns (uint256)
    {
        return pipToPrice(reserveSnapshots[params.snapshotIndex].pip);
    }

    //
    // INTERNAL FUNCTIONS
    //
    // update funding rate = premiumFraction / twapIndexPrice
    function updateFundingRate(
        int256 _premiumFraction,
        uint256 _underlyingPrice
    ) private {
        fundingRate = _premiumFraction / int256(_underlyingPrice);
        emit FundingRateUpdated(fundingRate, _underlyingPrice);
    }

    function addReserveSnapshot() internal {
        uint256 currentBlock = block.number;
        ReserveSnapshot memory latestSnapshot = reserveSnapshots[reserveSnapshots.length - 1];
        if (currentBlock == latestSnapshot.blockNumber) {
            reserveSnapshots[reserveSnapshots.length - 1].pip = singleSlot.pip;
        } else {
            reserveSnapshots.push(
                ReserveSnapshot(singleSlot.pip, block.timestamp, currentBlock)
            );
        }
        emit ReserveSnapshotted(singleSlot.pip, block.timestamp);
    }

}

pragma solidity ^0.8.0;

library Quantity {
    function abs(int256 quantity) internal pure returns (uint256) {
        return uint256(quantity >= 0 ? quantity : -quantity);
    }
    function abs128(int256 quantity) internal pure returns (uint128) {
        return uint128(abs(quantity));
    }

    function sumWithUint256(int256 a, uint256 b) internal pure returns (int256) {
        return a >= 0 ? a + int256(b) : a - int256(b);
    }

    function minusWithUint256(int256 a, uint256 b) internal pure returns (int256) {
        return a >= 0 ? a - int256(b) : a + int256(b);
    }
}

pragma solidity ^0.8.0;
import "./Position.sol";
import "hardhat/console.sol";
import "../../../interfaces/IPositionManager.sol";

library PositionLimitOrder {
    enum OrderType {
        OPEN_LIMIT,
        CLOSE_LIMIT
    }
    struct Data {
        int128 pip;
        uint64 orderId;
        uint16 leverage;
//        OrderType typeLimitOrder;
        uint8 isBuy;
        uint256 entryPrice;
        uint256 reduceLimitOrderId;
        uint256 reduceQuantity;
        uint256 blockNumber;
    }

//    struct ReduceData {
//        int128 pip;
//        uint64 orderId;
//        uint16 leverage;
////        OrderType typeLimitOrder;
//        uint8 isBuy;
//    }
//
//    function clearLimitOrder(
//        PositionLimitOrder.Data self
//    ) internal {
//        self.pip = 0;
//        self.orderId = 0;
//        self.leverage = 0;
//    }

    function checkFilledToSelfOrders(
        mapping(address => mapping(address => PositionLimitOrder.Data[])) storage limitOrderMap,
        IPositionManager _positionManager,
        address _trader,
        int128 startPip,
        int128 endPip,
        Position.Side side
    ) internal view returns (uint256 selfFilledQuantity) {
        uint256 gasBefore = gasleft();
        // check if fill to self limit orders
        PositionLimitOrder.Data[] memory listLimitOrder = limitOrderMap[address(_positionManager)][_trader];
        for(uint256 i; i<listLimitOrder.length; i++){
            PositionLimitOrder.Data memory limitOrder = listLimitOrder[i];
            if(limitOrder.isBuy == 1 && side == Position.Side.SHORT){
                if(endPip <= limitOrder.pip && startPip >= limitOrder.pip){
                    (,,uint256 size, uint256 partialFilledSize) = _positionManager.getPendingOrderDetail(limitOrder.pip, limitOrder.orderId);
                    selfFilledQuantity += (size > partialFilledSize ? size - partialFilledSize : size);
                }
            }
            if(limitOrder.isBuy == 2 && side == Position.Side.LONG){
                if(endPip >= limitOrder.pip){
                    (,,uint256 size, uint256 partialFilledSize) = _positionManager.getPendingOrderDetail(limitOrder.pip, limitOrder.orderId);
                    selfFilledQuantity += (size > partialFilledSize ? size - partialFilledSize : size);
                }
            }
        }
    }

}

pragma solidity ^0.8.0;


interface IInsuranceFund {
    function deposit(address token, address trader, uint256 amount) external;

    function withdraw(address token, address trader, uint256 amount) external;

    function buyBackAndBurn(address token, uint256 amount) external;

    function transferFeeFromTrader(address token, address trader, uint256 amountFee) external;

    function updateTotalFee(uint256 fee) external;
}

pragma solidity ^0.8.0;


interface IFeePool {

}

pragma solidity ^0.8.0;

import "./Position.sol";
import "../../../interfaces/IPositionManager.sol";
import "./PositionLimitOrder.sol";
import "../../libraries/helpers/Quantity.sol";
import "../../PositionHouse.sol";


library PositionHouseFunction {
    using PositionLimitOrder for mapping(address => mapping(address => PositionLimitOrder.Data[]));
    using Position for Position.Data;
    using Position for Position.LiquidatedData;
    using Quantity for int256;
    using Quantity for int128;


    struct OpenLimitResp {
        uint64 orderId;
        uint256 sizeOut;
    }

    // There are 4 cases could happen:
    //      1. oldPosition created by limitOrder, new marketOrder reversed it => ON = positionResp.exchangedQuoteAssetAmount
    //      2. oldPosition created by marketOrder, new marketOrder reversed it => ON = oldPosition.openNotional - positionResp.exchangedQuoteAssetAmount
    //      3. oldPosition created by both marketOrder and limitOrder, new marketOrder reversed it => ON = oldPosition.openNotional (of marketPosition only) - positionResp.exchangedQuoteAssetAmount
    //      4. oldPosition increased by limitOrder and reversed by marketOrder, new MarketOrder reversed it => ON = oldPosition.openNotional (of marketPosition only) + positionResp.exchangedQuoteAssetAmount
    function handleNotionalInOpenReverse(
        uint256 exchangedQuoteAmount,
        Position.Data memory marketPositionData,
        Position.Data memory totalPositionData
    ) internal pure returns (uint256 openNotional) {
//        int256 newPositionSide = totalPositionData.quantity < 0 ? int256(1) : int256(- 1);
        if (marketPositionData.quantity * totalPositionData.quantity < 0) {
            openNotional = marketPositionData.openNotional + exchangedQuoteAmount;
        } else {
            if (marketPositionData.openNotional > exchangedQuoteAmount) {
                openNotional = marketPositionData.openNotional - exchangedQuoteAmount;
            } else {
                openNotional = exchangedQuoteAmount - marketPositionData.openNotional;
            }
        }
    }

    // There are 5 cases could happen:
    //      1. Old position created by long limit and short market, reverse position is short => margin = oldMarketMargin + reduceMarginRequirement
    //      2. Old position created by long limit and long market, reverse position is short and < old long market => margin = oldMarketMargin - reduceMarginRequirement
    //      3. Old position created by long limit and long market, reverse position is short and > old long market => margin = reduceMarginRequirement - oldMarketMargin
    //      4. Old position created by long limit and no market, reverse position is short => margin = reduceMarginRequirement - oldMarketMargin
    //      5. Old position created by short limit and long market, reverse position is short => margin = oldMarketMargin - reduceMarginRequirement
    function handleMarginInOpenReverse(
        uint256 reduceMarginRequirement,
        Position.Data memory marketPositionData,
        Position.Data memory totalPositionData
    ) internal pure returns (uint256 margin) {
//        int256 newPositionSide = totalPositionData.quantity < 0 ? int256(1) : int256(- 1);
        if (marketPositionData.quantity * totalPositionData.quantity < 0) {
            margin = marketPositionData.margin + reduceMarginRequirement;
        } else {
            if (marketPositionData.margin > reduceMarginRequirement) {
                margin = marketPositionData.margin - reduceMarginRequirement;
            } else {
                margin = reduceMarginRequirement - marketPositionData.margin;
            }
        }
    }

    // There are 5 cases could happen:
    //      1. Old position created by long limit and long market, increase position is long => notional = oldNotional + exchangedQuoteAssetAmount
    //      2. Old position created by long limit and short market, increase position is long and < old short market => notional = oldNotional - exchangedQuoteAssetAmount
    //      3. Old position created by long limit and short market, increase position is long and > old short market => notional = exchangedQuoteAssetAmount - oldNotional
    //      4. Old position created by long limit and no market, increase position is long => notional = oldNotional + exchangedQuoteAssetAmount
    //      5. Old position created by short limit and long market, increase position is long => notional = oldNotional + exchangedQuoteAssetAmount
    function handleNotionalInIncrease(
        uint256 exchangedQuoteAmount,
        Position.Data memory marketPositionData,
        Position.Data memory totalPositionData
    ) internal pure returns (uint256 openNotional) {
        if (marketPositionData.quantity * totalPositionData.quantity < 0) {
            if (marketPositionData.openNotional > exchangedQuoteAmount) {
                openNotional = marketPositionData.openNotional - exchangedQuoteAmount;
            } else {
                openNotional = exchangedQuoteAmount - marketPositionData.openNotional;
            }
        } else {
            openNotional = marketPositionData.openNotional + exchangedQuoteAmount;
        }
    }

    // There are 6 cases could happen:
    //      1. Old position created by long limit and long market, increase position is long market => margin = oldMarketMargin + increaseMarginRequirement
    //      2. Old position created by long limit and short market, increase position is long market and < old short market => margin = oldMarketMargin - increaseMarginRequirement
    //      3. Old position created by long limit and short market, increase position is long market and > old short market => margin = increaseMarginRequirement - oldMarketMargin
    //      4. Old position created by long limit and no market, increase position is long market => margin = increaseMarginRequirement - oldMarketMargin
    //      5. Old position created by short limit and long market, increase position is long market => margin = oldMarketMargin + increaseMarginRequirement
    //      6. Old position created by no limit and long market, increase position is long market => margin = oldMarketMargin + increaseMarginRequirement
    function handleMarginInIncrease(
        uint256 increaseMarginRequirement,
        Position.Data memory marketPositionData,
        Position.Data memory totalPositionData
    ) internal pure returns (uint256 margin) {
        if (marketPositionData.quantity * totalPositionData.quantity < 0) {
            if (marketPositionData.margin > increaseMarginRequirement) {
                margin = marketPositionData.margin - increaseMarginRequirement;
            } else {
                margin = increaseMarginRequirement - marketPositionData.margin;
            }
        } else {
            margin = marketPositionData.margin + increaseMarginRequirement;
        }
    }

    function clearAllFilledOrder(
        IPositionManager _positionManager,
        address _trader,
        PositionLimitOrder.Data[] memory listLimitOrder,
        PositionLimitOrder.Data[] memory reduceLimitOrder
    ) internal returns (PositionLimitOrder.Data[] memory subListLimitOrder, PositionLimitOrder.Data[] memory subReduceLimitOrder) {
        if (listLimitOrder.length > 0) {
            uint256 index = 0;
            for (uint256 i = 0; i < listLimitOrder.length; i++) {
                (bool isFilled,,
                ,) = _positionManager.getPendingOrderDetail(listLimitOrder[i].pip, listLimitOrder[i].orderId);
                if (isFilled != true) {
                    subListLimitOrder[index] = listLimitOrder[i];
                    _positionManager.updatePartialFilledOrder(listLimitOrder[i].pip, listLimitOrder[i].orderId);
                    index++;
                }
            }
        }
        if (reduceLimitOrder.length > 0) {
            uint256 index = 0;
            for (uint256 i = 0; i < reduceLimitOrder.length; i++) {
                (bool isFilled,,
                ,) = _positionManager.getPendingOrderDetail(reduceLimitOrder[i].pip, reduceLimitOrder[i].orderId);
                if (isFilled != true) {
                    subReduceLimitOrder[index] = reduceLimitOrder[i];
                    _positionManager.updatePartialFilledOrder(reduceLimitOrder[i].pip, reduceLimitOrder[i].orderId);
                    index++;
                }
            }
        }
    }


    function accumulateLimitOrderToPositionData(
        address addressPositionManager,
        PositionLimitOrder.Data memory limitOrder,
        Position.Data memory positionData,
        uint256 entryPrice,
        uint256 reduceQuantity) internal view returns (Position.Data memory) {

        IPositionManager _positionManager = IPositionManager(addressPositionManager);

        (bool isFilled, bool isBuy,
        uint256 quantity, uint256 partialFilled) = _positionManager.getPendingOrderDetail(limitOrder.pip, limitOrder.orderId);

        if (isFilled) {
            int256 _orderQuantity;
            if (reduceQuantity == 0 && entryPrice == 0) {
                _orderQuantity = isBuy ? int256(quantity) : - int256(quantity);
            } else if (reduceQuantity != 0 && entryPrice == 0) {
                _orderQuantity = isBuy ? int256(quantity - reduceQuantity) : - int256(quantity - reduceQuantity);
            } else {
                _orderQuantity = isBuy ? int256(reduceQuantity) : - int256(reduceQuantity);
            }
            uint256 _orderNotional = entryPrice == 0 ? (_orderQuantity.abs() * _positionManager.pipToPrice(limitOrder.pip) / _positionManager.getBaseBasisPoint()) : (_orderQuantity.abs() * entryPrice / _positionManager.getBaseBasisPoint());
            // IMPORTANT UPDATE FORMULA WITH LEVERAGE
            uint256 _orderMargin = _orderNotional / limitOrder.leverage;
            positionData = positionData.accumulateLimitOrder(_orderQuantity, _orderMargin, _orderNotional);
        }
        else if (!isFilled && partialFilled != 0) {// partial filled
            int256 _partialQuantity;
            if (reduceQuantity == 0 && entryPrice == 0) {
                _partialQuantity = isBuy ? int256(partialFilled) : - int256(partialFilled);
            } else if (reduceQuantity != 0 && entryPrice == 0) {

                int256 _partialQuantityTemp = partialFilled > reduceQuantity ? int256(partialFilled - reduceQuantity) : 0;
                _partialQuantity = isBuy ? _partialQuantityTemp : - _partialQuantityTemp;
            } else {
                int256 _partialQuantityTemp = partialFilled > reduceQuantity ? int256(reduceQuantity) : int256(partialFilled);
                _partialQuantity = isBuy ? _partialQuantityTemp : - _partialQuantityTemp;
            }
            uint256 _partialOpenNotional = entryPrice == 0 ? (_partialQuantity.abs() * _positionManager.pipToPrice(limitOrder.pip) / _positionManager.getBaseBasisPoint()) : (_partialQuantity.abs() * entryPrice / _positionManager.getBaseBasisPoint());
            // IMPORTANT UPDATE FORMULA WITH LEVERAGE
            uint256 _partialMargin = _partialOpenNotional / limitOrder.leverage;
            positionData = positionData.accumulateLimitOrder(_partialQuantity, _partialMargin, _partialOpenNotional);
        }
        positionData.leverage = positionData.leverage >= limitOrder.leverage ? positionData.leverage : limitOrder.leverage;
        return positionData;
    }


    function getListOrderPending(
        address addressPositionManager,
        address _trader,
        PositionLimitOrder.Data[] memory listLimitOrder,
        PositionLimitOrder.Data[] memory reduceLimitOrder) public view returns (PositionHouse.LimitOrderPending[] memory){

        IPositionManager _positionManager = IPositionManager(addressPositionManager);
        //                PositionHouse.LimitOrderPending[] memory listPendingOrderData = new PositionHouse.LimitOrderPending[](listLimitOrder.length + reduceLimitOrder.length);
        if (listLimitOrder.length + reduceLimitOrder.length > 0) {
            PositionHouse.LimitOrderPending[] memory listPendingOrderData = new PositionHouse.LimitOrderPending[](listLimitOrder.length + reduceLimitOrder.length + 1);
            uint256 index = 0;
            for (uint256 i = 0; i < listLimitOrder.length; i++) {

                (bool isFilled, bool isBuy,
                uint256 quantity, uint256 partialFilled) = _positionManager.getPendingOrderDetail(listLimitOrder[i].pip, listLimitOrder[i].orderId);
//                if (!isFilled && listLimitOrder[i].reduceQuantity == 0) {
                if (!isFilled ) {
                    listPendingOrderData[index] = PositionHouse.LimitOrderPending({
                    isBuy : isBuy,
                    quantity : quantity,
                    partialFilled : partialFilled,
                    pip : listLimitOrder[i].pip,
                    leverage : listLimitOrder[i].leverage,
                    blockNumber : listLimitOrder[i].blockNumber,
                    orderIdOfTrader : i,
                    orderId : listLimitOrder[i].orderId
                    });
                    index++;
                }
            }
            for (uint256 i = 0; i < reduceLimitOrder.length; i++) {
                (bool isFilled, bool isBuy,
                uint256 quantity, uint256 partialFilled) = _positionManager.getPendingOrderDetail(reduceLimitOrder[i].pip, reduceLimitOrder[i].orderId);
                if (!isFilled && reduceLimitOrder[i].reduceLimitOrderId == 0) {
                    listPendingOrderData[index] = PositionHouse.LimitOrderPending({
                    isBuy : isBuy,
                    quantity : quantity,
                    partialFilled : partialFilled,
                    pip : reduceLimitOrder[i].pip,
                    leverage : reduceLimitOrder[i].leverage,
                    blockNumber : reduceLimitOrder[i].blockNumber,
                    orderIdOfTrader : i,
                    orderId : reduceLimitOrder[i].orderId
                    });
                    index++;
                }
            }
            for (uint256 i = 0; i < listPendingOrderData.length; i++) {
                if (listPendingOrderData[i].quantity != 0) {
                    return listPendingOrderData;
                }
            }
//            PositionHouse.LimitOrderPending[] memory blankListPendingOrderData;
//            return blankListPendingOrderData;
//            if (listPendingOrderData[0].quantity == 0 && listPendingOrderData[listPendingOrderData.length - 1].quantity == 0) {
//                PositionHouse.LimitOrderPending[] memory blankListPendingOrderData;
//                return blankListPendingOrderData;
//            }
        }
//        else {
        PositionHouse.LimitOrderPending[] memory blankListPendingOrderData;
        return blankListPendingOrderData;
//        }
    }

    function getPositionNotionalAndUnrealizedPnl(
        address addressPositionManager,
        address _trader,
        PositionHouse.PnlCalcOption _pnlCalcOption,
        Position.Data memory position
    ) public view returns
    (
        uint256 positionNotional,
        int256 unrealizedPnl
    ){
        IPositionManager positionManager = IPositionManager(addressPositionManager);

        uint256 oldPositionNotional = position.openNotional;
        if (_pnlCalcOption == PositionHouse.PnlCalcOption.SPOT_PRICE) {
            positionNotional = positionManager.getPrice() * position.quantity.abs() / positionManager.getBaseBasisPoint();
        }
        else if (_pnlCalcOption == PositionHouse.PnlCalcOption.TWAP) {
            // TODO get twap price
        }
        else {
            // TODO get oracle price
        }

        if (position.side() == Position.Side.LONG) {
            unrealizedPnl = int256(positionNotional) - int256(oldPositionNotional);
        } else {
            unrealizedPnl = int256(oldPositionNotional) - int256(positionNotional);
        }

    }

    function calcMaintenanceDetail(
        Position.Data memory positionData,
        uint256 maintenanceMarginRatio,
        int256 unrealizedPnl
    ) public view returns (uint256 maintenanceMargin, int256 marginBalance, uint256 marginRatio) {

        maintenanceMargin = positionData.margin * maintenanceMarginRatio / 100;
        marginBalance = int256(positionData.margin) + unrealizedPnl;
        if (marginBalance <= 0) {
            marginRatio = 100;
        } else {
            marginRatio = maintenanceMargin * 100 / uint256(marginBalance);
        }
    }

    function getClaimAmount(
        address _positionManagerAddress,
        address _trader,
        Position.Data memory positionData,
        PositionLimitOrder.Data[] memory _limitOrders,
        PositionLimitOrder.Data[] memory _reduceOrders,
        Position.Data memory positionMapData,
        uint256 canClaimAmountInMap,
        int256 manualMarginInMap
    ) public view returns (int256 totalClaimableAmount){
        IPositionManager _positionManager = IPositionManager(_positionManagerAddress);
        uint256 indexReduce = 0;
//        if (_limitOrders.length != 0) {
            bool skipIf;
            uint256 indexLimit = 0;
            for (indexLimit; indexLimit < _limitOrders.length; indexLimit++) {
                {
                    if (_limitOrders[indexLimit].pip == 0 && _limitOrders[indexLimit].orderId == 0) continue;
                    if (_limitOrders[indexLimit].reduceQuantity != 0 || indexLimit == _limitOrders.length - 1) {
                        {
                            for (indexReduce; indexReduce < _reduceOrders.length; indexReduce++) {
                                int256 realizedPnl = int256(_reduceOrders[indexReduce].reduceQuantity * _positionManager.pipToPrice(_reduceOrders[indexReduce].pip) / _positionManager.getBaseBasisPoint())
                                - int256((positionData.openNotional != 0 ? positionData.openNotional : positionMapData.openNotional) * _reduceOrders[indexReduce].reduceQuantity / (positionData.quantity.abs() != 0 ? positionData.quantity.abs() : positionMapData.quantity.abs()));
                                // if limit order is short then return realizedPnl, else return -realizedPnl because of realizedPnl's formula
                                totalClaimableAmount += _reduceOrders[indexReduce].isBuy == 2 ? realizedPnl : (- realizedPnl);
                                positionData = accumulateLimitOrderToPositionData(_positionManagerAddress, _reduceOrders[indexReduce], positionData, _reduceOrders[indexReduce].entryPrice, _reduceOrders[indexReduce].reduceQuantity);
                                if (_reduceOrders[indexReduce].reduceLimitOrderId != 0) {
                                    indexReduce++;
                                    break;
                                }
                            }
                        }
                        positionData = accumulateLimitOrderToPositionData(_positionManagerAddress, _limitOrders[indexLimit], positionData, _limitOrders[indexLimit].entryPrice, _limitOrders[indexLimit].reduceQuantity);
                    } else {
                        positionData = accumulateLimitOrderToPositionData(_positionManagerAddress, _limitOrders[indexLimit], positionData, _limitOrders[indexLimit].entryPrice, _limitOrders[indexLimit].reduceQuantity);
                    }
                }

//                {
//                    (bool isFilled, bool isBuy,
//                    uint256 quantity, uint256 partialFilled) = _positionManager.getPendingOrderDetail(_limitOrders[indexLimit].pip, _limitOrders[indexLimit].orderId);
//                    if (!isFilled) {
//                        totalClaimableAmount -= int256((quantity - partialFilled) * _positionManager.pipToPrice(_limitOrders[indexLimit].pip) / _positionManager.getBaseBasisPoint() / _limitOrders[indexLimit].leverage);
//                    }
//                }
            }
//        }

        totalClaimableAmount = totalClaimableAmount + int256(canClaimAmountInMap) + manualMarginInMap + int256(positionMapData.margin);
        if (totalClaimableAmount <= 0) {
                totalClaimableAmount = 0;
        }
    }

//    function internalClosePosition(
//        address addressPositionManager,
//        address _trader,
//        PositionHouse.PnlCalcOption _pnlCalcOption,
//        Position.Data memory oldPosition,
//        uint256 quantity
//    ) external returns (PositionHouse.PositionResp memory positionResp) {
//
//        IPositionManager _positionManager = IPositionManager(addressPositionManager);
//        (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(addressPositionManager, _trader, _pnlCalcOption, oldPosition);
//
//        if (oldPosition.quantity > 0) {
//            // sell
//            (positionResp.exchangedPositionSize, positionResp.exchangedQuoteAssetAmount) = openMarketOrder(addressPositionManager, quantity, Position.Side.SHORT, _trader);
//        } else {
//            // buy
//            (positionResp.exchangedPositionSize, positionResp.exchangedQuoteAssetAmount) = openMarketOrder(addressPositionManager, quantity, Position.Side.LONG, _trader);
//        }
//
//        uint256 remainMargin = oldPosition.margin;
//
//        positionResp.realizedPnl = unrealizedPnl;
//        // NOTICE remainMargin can be negative
//        // unchecked: should be -(remainMargin + unrealizedPnl) and update remainMargin with fundingPayment
//        positionResp.marginToVault = - ((int256(remainMargin) + positionResp.realizedPnl) < 0 ? 0 : (int256(remainMargin) + positionResp.realizedPnl));
//        positionResp.unrealizedPnl = 0;
//    }
//
//    function openMarketOrder(
//        address addressPositionManager,
//        uint256 _quantity,
//        Position.Side _side,
//        address _trader
//    ) internal returns (int256 exchangedQuantity, uint256 openNotional) {
//        IPositionManager _positionManager = IPositionManager(addressPositionManager);
//
//        uint256 exchangedSize;
//        (exchangedSize, openNotional) = _positionManager.openMarketPosition(_quantity, _side == Position.Side.LONG);
//        require(exchangedSize == _quantity, "NELQ");
//        exchangedQuantity = _side == Position.Side.LONG ? int256(exchangedSize) : - int256(exchangedSize);
//    }

//    function clearPosition(
//        address addressPositionManager,
//        address _trader,
//        PositionLimitOrder.Data[] storage limitOrders,
//        PositionLimitOrder.Data[] storage reduceLimitOrders
//    ) internal {
//        IPositionManager _positionManager = IPositionManager(addressPositionManager);
//
////        positionMapData.clear();
////        debtPositionData.clearDebt();
//        //        PositionLimitOrder.Data[] memory listLimitOrder = limitOrders;
//        //        PositionLimitOrder.Data[] memory reduceLimitOrder = reduceLimitOrders;
//        //        (PositionLimitOrder.Data[] memory subListLimitOrder, PositionLimitOrder.Data[] memory subReduceLimitOrder) = clearAllFilledOrder(_positionManager, _trader, listLimitOrder, reduceLimitOrder);
//        (PositionLimitOrder.Data[] memory subListLimitOrder, PositionLimitOrder.Data[] memory subReduceLimitOrder) = clearAllFilledOrder(_positionManager, _trader, limitOrders, reduceLimitOrders);
//
//        if (limitOrders.length > 0) {
////            limitOrders.pop();
//            delete limitOrders[addressPositionManager][_trader];
//        }
//        for (uint256 i = 0; i < subListLimitOrder.length; i++) {
//            limitOrders.push(subListLimitOrder[i]);
//        }
//        if (reduceLimitOrders.length > 0) {
////            limitOrders.pop();
//            delete reduceLimitOrders[addressPositionManager][_trader];
//        }
//        for (uint256 i = 0; i < subReduceLimitOrder.length; i++) {
//            reduceLimitOrders.push(subReduceLimitOrder[i]);
//        }
//    }


//    function handleLimitOrderInOpenLimit(
//        OpenLimitResp memory openLimitResp,
//        PositionLimitOrder.Data memory _newOrder,
//        address addressPositionManager,
//        address _trader,
//        uint256 _quantity,
//        Position.Side _side,
//        PositionLimitOrder.Data[] storage limitOrders,
//        PositionLimitOrder.Data[] storage reduceLimitOrders,
//        Position.Data memory _oldPosition) internal returns (uint64 orderIdOfUser) {
//
//        IPositionManager _positionManager = IPositionManager(addressPositionManager);
//
//
//        if (_oldPosition.quantity == 0 || _side == (_oldPosition.quantity > 0 ? Position.Side.LONG : Position.Side.SHORT)) {
//            limitOrders.push(_newOrder);
//            orderIdOfUser = uint64(limitOrders.length - 1);
//        } else {
//            // if new limit order is smaller than old position then just reduce old position
//            if (_oldPosition.quantity.abs() > _quantity) {
//                _newOrder.reduceQuantity = _quantity - openLimitResp.sizeOut;
//                _newOrder.entryPrice = _oldPosition.openNotional * _positionManager.getBaseBasisPoint() / _oldPosition.quantity.abs();
//                reduceLimitOrders.push(_newOrder);
//                orderIdOfUser = uint64(reduceLimitOrders.length - 1);
//            }
//            // else new limit order is larger than old position then close old position and open new opposite position
//            else {
//                _newOrder.reduceQuantity = _oldPosition.quantity.abs();
//                limitOrders.push(_newOrder);
//                orderIdOfUser = uint64(limitOrders.length - 1);
//                _newOrder.entryPrice = _oldPosition.openNotional * _positionManager.getBaseBasisPoint() / _oldPosition.quantity.abs();
//                reduceLimitOrders.push(_newOrder);
//            }
//        }
//    }
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

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LimitOrder.sol";

import "hardhat/console.sol";

/*
 * A library storing data and logic at a pip
 */

library TickPosition {
    using SafeMath for uint128;
    using SafeMath for uint64;
    using LimitOrder for LimitOrder.Data;
    struct Data {
        uint128 liquidity;
        uint64 filledIndex;
        uint64 currentIndex;
        // position at a certain tick
        // index => order data
        mapping(uint64 => LimitOrder.Data) orderQueue;
    }

    function insertLimitOrder(
        TickPosition.Data storage self,
        uint120 size,
        bool hasLiquidity,
        bool isBuy
    ) internal returns (uint64) {
        self.currentIndex++;
        if (!hasLiquidity && self.filledIndex != self.currentIndex && self.liquidity != 0) {
            // means it has liquidity but is not set currentIndex yet
            // reset the filledIndex to fill all
            self.filledIndex = self.currentIndex;
            self.liquidity = size;
        } else {
            self.liquidity = self.liquidity + size;
        }
        self.orderQueue[self.currentIndex].update(isBuy, size);
        return self.currentIndex;
    }

    function updateOrderWhenClose(
        TickPosition.Data storage self,
        uint64 orderId
    ) internal returns (uint256) {
        return self.orderQueue[orderId].updateWhenClose();
    }

    function getQueueOrder(
        TickPosition.Data storage self,
        uint64 orderId
    ) internal view returns (
        bool isFilled,
        bool isBuy,
        uint256 size,
        uint256 partialFilled
    ) {
        (isBuy, size, partialFilled) = self.orderQueue[orderId].getData();
        if (self.filledIndex > orderId && size != 0) {
            isFilled = true;
        } else if (self.filledIndex < orderId) {
            isFilled = false;
        } else {
            //            isFilled = partialFilled >= 0 && partialFilled < size ? false : true;
            isFilled = partialFilled >= size && size != 0 ? true : false;
        }
    }

    function partiallyFill(
        TickPosition.Data storage self,
        uint120 amount
    ) internal {
        self.liquidity -= amount;
        unchecked {
            uint64 index = self.filledIndex;
            uint120 totalSize = 0;
            while (totalSize < amount) {
                totalSize += self.orderQueue[index].size;
                index++;
            }
            index--;
            self.filledIndex = index;
            //            self.orderQueue[index].partialFilled = totalSize - amount;
            self.orderQueue[index].updatePartialFill(totalSize - amount);
        }
    }

    function cancelLimitOrder(
        TickPosition.Data storage self,
        uint64 orderId
    ) internal returns(uint256) {
        (bool isBuy,
        uint256 size,
        uint256 partialFilled) = self.orderQueue[orderId].getData();
        self.liquidity = self.liquidity - uint120(size - partialFilled);

        self.orderQueue[orderId].update(isBuy, partialFilled);

        return size - partialFilled;
    }

    function closeLimitOrder(
        TickPosition.Data storage self,
        uint64 orderId,
        uint256 amountClose
    ) internal returns (uint256 remainAmountClose) {

        (bool isBuy,
        uint256 size,
        uint256 partialFilled) = self.orderQueue[orderId].getData();

        uint256 amount = amountClose > partialFilled ? 0 : amountClose;
        if (amountClose > partialFilled) {
            uint256 amount = size - partialFilled;
            self.orderQueue[orderId].update(isBuy, amount);
            remainAmountClose = amountClose - partialFilled;
        } else {
            uint256 amount = partialFilled - amountClose;
            self.orderQueue[orderId].update(isBuy, amount);
            remainAmountClose = 0;
        }


    }
    //    function executeOrder(Data storage self, uint256 size, bool isLong)
    //    internal returns
    //    (
    //        uint256 remainingAmount
    //    ) {
    //        if(self.liquidity > size){
    //            self.liquidity = self.liquidity.sub(size);
    //            // safe to increase by plus 1
    //            //TODO determine index to plus
    ////            self.filledIndex += 1;
    //            remainingAmount = 0;
    //        }else{
    //            // fill all liquidity
    //            // safe to use with out safemath to avoid gas wasting?
    //            remainingAmount = size.sub(self.liquidity);
    //            self.liquidity = 0;
    //            self.filledIndex = self.currentIndex;
    //        }
    //    }

}

pragma solidity ^0.8.0;

import "hardhat/console.sol";

library LimitOrder {
    struct Data {
        // Type order LONG or SHORT
        uint8 isBuy;
        uint120 size;
        // NOTICE need to add leverage
        uint120 partialFilled;
    }

    function getData(LimitOrder.Data storage self) internal view returns (
        bool isBuy,
        uint256 size,
        uint256 partialFilled
    ){
        isBuy = self.isBuy == 1;
        size = uint256(self.size);
        partialFilled = uint256(self.partialFilled);
    }

    function update(
        LimitOrder.Data storage self,
        bool isBuy,
        uint256 size
    ) internal  {
        self.isBuy = isBuy ? 1 : 2;
        self.size = uint120(size);
    }

    function updatePartialFill(
        LimitOrder.Data storage self,
        uint120 remainSize
    ) internal {
        // remainingSize should be negative
        self.partialFilled += self.size - remainSize;
    }

    function updateWhenClose(
        LimitOrder.Data storage self
    ) internal returns (uint256) {
        self.size -= self.partialFilled;
        self.partialFilled = 0;
        return (uint256(self.size));
    }

    function getPartialFilled(
        LimitOrder.Data storage self
    ) internal view returns(bool isPartial, uint256 remainingSize) {
        remainingSize = self.size - self.partialFilled;
        isPartial = remainingSize > 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./BitMath.sol";

library LiquidityBitmap {
    uint256 public constant MAX_UINT256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    /// @notice Get the position in the mapping
    /// @param pip The bip index for computing the position
    /// @return mapIndex the index in the map
    /// @return bitPos the position in the bitmap
    function position(int128 pip) private pure returns (int128 mapIndex, uint8 bitPos) {
        mapIndex = pip >> 8;
        bitPos = uint8(uint128(pip) & 0xff);
        // % 256
    }

    /// @notice find the next pip has liquidity
    /// @param pip The current pip index
    /// @param lte  Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next bit position has liquidity, 0 means no liquidity found
    function findHasLiquidityInOneWords(
        mapping(int128 => uint256) storage self,
        int128 pip,
        bool lte
    ) internal view returns (
        int128 next
    ) {

        if (lte) {
            // main is find the next pip has liquidity
            (int128 wordPos, uint8 bitPos) = position(pip);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;
            //            bool hasLiquidity = (self[wordPos] & 1 << bitPos) != 0;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            bool initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
            ? (pip - int128(bitPos - BitMath.mostSignificantBit(masked)))
            : 0;

            //            if (!hasLiquidity && next != 0) {
            //                next = next + 1;
            //            }

        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int128 wordPos, uint8 bitPos) = position(pip);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;
            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            bool initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
            ? (pip + int128(BitMath.leastSignificantBit(masked) - bitPos))  // +1
            : 0;

            //            if (!hasLiquidity && next != 0) {
            //                next = next + 1;
            //            }
        }
    }

    function findHasLiquidityPipInCertainWord(
        mapping(int128 => uint256) storage self,
        int128 pip,
        int128 word,
        bool lte
    ) internal view returns (
        int128 next
    ) {
        if(lte){

        }else{

        }
    }

    // find nearest pip has liquidity in multiple word
    function findHasLiquidityInMultipleWords(
        mapping(int128 => uint256) storage self,
        int128 pip,
        int128 maxWords,
        bool lte
    ) internal view returns (
        int128 next
    ) {
        int128 startWord = pip >> 8;
        if (lte) {
            for (int128 i = startWord; i > startWord - maxWords; i--) {
                if (self[i] != 0) {
                    next = findHasLiquidityInOneWords(self, i < startWord ? 256 * i + 255 : pip, true);
                    if (next != 0) {
                        return next;
                    }
                }
            }
        } else {
            for (int128 i = startWord; i < startWord + maxWords; i++) {
                if (self[i] != 0) {
                    next = findHasLiquidityInOneWords(self, i > startWord ? 256 * i : pip, false);
                    if (next != 0) {
                        return next;
                    }
                }
            }
        }
    }

    // find all pip has liquidity in multiple word
    function findAllLiquidityInMultipleWords(
        mapping(int128 => uint256) storage self,
        int128 startPip,
        uint256 dataLength,
        bool toHigher
    ) internal view returns (
        int128[] memory
    ) {
        int128 startWord = startPip >> 8;
        uint128 index = 0;
        int128[] memory allPip = new int128[](uint128(dataLength));
        if (!toHigher) {
            for (int128 i = startWord; i >= startWord - 1000; i--) {
                if (self[i] != 0) {
                    int128 next;
                    next = findHasLiquidityInOneWords(self, i < startWord ? 256*i + 255 : startPip, true);
                    if (next != 0) {
                        allPip[index] = next;
                        index ++;
                    }
                    while(true){
                        next = findHasLiquidityInOneWords(self, next-1, true);
                        if (next != 0 && index <= dataLength) {
                            allPip[index] = next;
                            index ++;
                        } else {
                            break;
                        }
                    }
                }
                if (index == dataLength) return allPip;
            }
        } else {
            for (int128 i = startWord; i <= startWord + 1000; i++) {
                if (self[i] != 0) {
                    int128 next;
                    next = findHasLiquidityInOneWords(self, i > startWord ? 256 * i : startPip, false);
                    if (next != 0) {
                        allPip[index] = next;
                        index ++;
                    }
                    while(true){
                        next = findHasLiquidityInOneWords(self, next+1, false);
                        if (next != 0 && index <= dataLength) {
                            allPip[index] = next;
                            index ++;
                        } else {
                            break;
                        }
                    }
                }
            }
            if (index == dataLength) return allPip;
        }

        return allPip;
    }

    function hasLiquidity(
        mapping(int128 => uint256) storage self,
        int128 pip
    ) internal view returns (
        bool
    ) {
        (int128 mapIndex, uint8 bitPos) = position(pip);
        return (self[mapIndex] & 1 << bitPos) != 0;
    }

    /// @notice Set all bits in a given range
    /// @dev WARNING THIS FUNCTION IS NOT READY FOR PRODUCTION
    /// only use for generating test data purpose
    /// @param fromPip the pip to set from
    /// @param toPip the pip to set to
    function setBitsInRange(
        mapping(int128 => uint256) storage self,
        int128 fromPip,
        int128 toPip
    ) internal {
        (int128 fromMapIndex, uint8 fromBitPos) = position(fromPip);
        (int128 toMapIndex, uint8 toBitPos) = position(toPip);
        if (toMapIndex == fromMapIndex) {
            // in the same storage
            // Set all the bits in given range of a number
            self[toMapIndex] |= (((1 << (fromBitPos - 1)) - 1) ^ ((1 << toBitPos) - 1));
        } else {
            // need to shift the map index
            // TODO fromMapIndex needs set separately
            self[fromMapIndex] |= (((1 << (fromBitPos - 1)) - 1) ^ ((1 << 255) - 1));
            for (int128 i = fromMapIndex + 1; i < toMapIndex; i++) {
                // pass uint256.MAX to avoid gas for computing
                self[i] = MAX_UINT256;
            }
            // set bits for the last index
            self[toMapIndex] = MAX_UINT256 >> (256 - toBitPos);
        }
    }

    function unsetBitsRange(
        mapping(int128 => uint256) storage self,
        int128 fromPip,
        int128 toPip
    ) internal {
        if (fromPip == toPip) return toggleSingleBit(self, fromPip, false);
        fromPip++;
        toPip++;
        if (toPip < fromPip) {
            int128 n = fromPip;
            fromPip = toPip;
            toPip = n;
        }
        (int128 fromMapIndex, uint8 fromBitPos) = position(fromPip);
        (int128 toMapIndex, uint8 toBitPos) = position(toPip);
        if (toMapIndex == fromMapIndex) {
            //            if(fromBitPos > toBitPos){
            //                uint8 n = fromBitPos;
            //                fromBitPos = toBitPos;
            //                toBitPos = n;
            //            }
            self[toMapIndex] &= toggleBitsFromLToR(MAX_UINT256, fromBitPos, toBitPos);
        } else {
            //TODO check overflow here
            fromBitPos--;
            self[fromMapIndex] &= ~toggleLastMBits(MAX_UINT256, fromBitPos);
            for (int128 i = fromMapIndex + 1; i < toMapIndex; i++) {
                self[i] = 0;
            }
            self[toMapIndex] &= toggleLastMBits(MAX_UINT256, toBitPos);
        }
    }

    function toggleSingleBit(
        mapping(int128 => uint256) storage self,
        int128 pip,
        bool isSet
    ) internal {
        (int128 mapIndex, uint8 bitPos) = position(pip);
        if (isSet) {
            self[mapIndex] |= 1 << bitPos;
        } else {
            self[mapIndex] &= ~(1 << bitPos);
        }
    }

    function toggleBitsFromLToR(uint256 n, uint8 l, uint8 r) private returns (uint256) {
        // calculating a number 'num'
        // having 'r' number of bits
        // and bits in the range l
        // to r are the only set bits
        uint256 num = ((1 << r) - 1) ^ ((1 << (l - 1)) - 1);

        // toggle the bits in the
        // range l to r in 'n'
        // and return the number
        return (n ^ num);
    }

    // Function to toggle the last m bits
    function toggleLastMBits(uint256 n, uint8 m) private returns (uint256)
    {

        // Calculating a number 'num' having
        // 'm' bits and all are set
        uint256 num = (1 << m) - 1;

        // Toggle the last m bits and
        // return the number
        return (n ^ num);
    }

}

pragma solidity ^0.8.0;


interface IChainLinkPriceFeed {

    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(bytes32 _priceFeedKey) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);

//    function setLatestData(
//        bytes32 _priceFeedKey,
//        uint256 _price,
//        uint256 _timestamp,
//        uint256 _roundId
//    ) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


/// @title BitMath
/// @dev This libraries provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit// SPDX-License-Identifier: GPL-2.0-or-later
    //pragma solidity >=0.5.0;
    //
    ///// @title BitMath
    ///// @dev This libraries provides functionality for computing bit properties of an unsigned integer
    //libraries BitMath {
    //    /// @notice Returns the index of the most significant bit of the number,
    //    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    //    /// @dev The function satisfies the property:
    //    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    //    /// @param x the value for which to compute the most significant bit, must be greater than 0
    //    /// @return r the index of the most significant bit
    //    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
    //        require(x > 0);
    //
    //        if (x >= 0x100000000000000000000000000000000) {
    //            x >>= 128;
    //            r += 128;
    //        }
    //        if (x >= 0x10000000000000000) {
    //            x >>= 64;
    //            r += 64;
    //        }
    //        if (x >= 0x100000000) {
    //            x >>= 32;
    //            r += 32;
    //        }
    //        if (x >= 0x10000) {
    //            x >>= 16;
    //            r += 16;
    //        }
    //        if (x >= 0x100) {
    //            x >>= 8;
    //            r += 8;
    //        }
    //        if (x >= 0x10) {
    //            x >>= 4;
    //            r += 4;
    //        }
    //        if (x >= 0x4) {
    //            x >>= 2;
    //            r += 2;
    //        }
    //        if (x >= 0x2) r += 1;
    //    }
    //
    //    /// @notice Returns the index of the least significant bit of the number,
    //    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    //    /// @dev The function satisfies the property:
    //    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    //    /// @param x the value for which to compute the least significant bit, must be greater than 0
    //    /// @return r the index of the least significant bit
    //    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
    //        require(x > 0);
    //
    //        r = 255;
    //        if (x & type(uint128).max > 0) {
    //            r -= 128;
    //        } else {
    //            x >>= 128;
    //        }
    //        if (x & type(uint64).max > 0) {
    //            r -= 64;
    //        } else {
    //            x >>= 64;
    //        }
    //        if (x & type(uint32).max > 0) {
    //            r -= 32;
    //        } else {
    //            x >>= 32;
    //        }
    //        if (x & type(uint16).max > 0) {
    //            r -= 16;
    //        } else {
    //            x >>= 16;
    //        }
    //        if (x & type(uint8).max > 0) {
    //            r -= 8;
    //        } else {
    //            x >>= 8;
    //        }
    //        if (x & 0xf > 0) {
    //            r -= 4;
    //        } else {
    //            x >>= 4;
    //        }
    //        if (x & 0x3 > 0) {
    //            r -= 2;
    //        } else {
    //            x >>= 2;
    //        }
    //        if (x & 0x1 > 0) r -= 1;
    //    }
    //}
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}