pragma solidity 0.5.16;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./MorpherState.sol";
import "./IMorpherStaking.sol";
import "./MorpherMintingLimiter.sol";

// ----------------------------------------------------------------------------------
// Tradeengine of the Morpher platform
// Creates and processes orders, and computes the state change of portfolio.
// Needs writing/reading access to/from Morpher State. Order objects are stored locally,
// portfolios are stored in state.
// ----------------------------------------------------------------------------------

contract MorpherTradeEngine is Ownable {
    MorpherState state;
    IMorpherStaking staking;
    MorpherMintingLimiter mintingLimiter;
    using SafeMath for uint256;

// ----------------------------------------------------------------------------
// Precision of prices and leverage
// ----------------------------------------------------------------------------
    uint256 constant PRECISION = 10**8;
    uint256 public orderNonce;
    bytes32 public lastOrderId;
    uint256 public deployedTimeStamp;

    address public escrowOpenOrderAddress = 0x1111111111111111111111111111111111111111;
    bool public escrowOpenOrderEnabled;


    //we're locking positions in for this price at a market marketId;
    address public closedMarketPriceLock = 0x0000000000000000000000000000000000000001;


// ----------------------------------------------------------------------------
// Order struct contains all order specific varibles. Variables are completed
// during processing of trade. State changes are saved in the order struct as
// well, since local variables would lead to stack to deep errors *sigh*.
// ----------------------------------------------------------------------------
    struct order {
        address userId;
        bytes32 marketId;
        uint256 closeSharesAmount;
        uint256 openMPHTokenAmount;
        bool tradeDirection; // true = long, false = short
        uint256 liquidationTimestamp;
        uint256 marketPrice;
        uint256 marketSpread;
        uint256 orderLeverage;
        uint256 timeStamp;
        uint256 longSharesOrder;
        uint256 shortSharesOrder;
        uint256 balanceDown;
        uint256 balanceUp;
        uint256 newLongShares;
        uint256 newShortShares;
        uint256 newMeanEntryPrice;
        uint256 newMeanEntrySpread;
        uint256 newMeanEntryLeverage;
        uint256 newLiquidationPrice;
        uint256 orderEscrowAmount;
    }

    mapping(bytes32 => order) private orders;

// ----------------------------------------------------------------------------
// Events
// Order created/processed events are fired by MorpherOracle.
// ----------------------------------------------------------------------------

    event PositionLiquidated(
        address indexed _address,
        bytes32 indexed _marketId,
        bool _longPosition,
        uint256 _timeStamp,
        uint256 _marketPrice,
        uint256 _marketSpread
    );

    event OrderCancelled(
        bytes32 indexed _orderId,
        address indexed _address
    );

    event OrderIdRequested(
        bytes32 _orderId,
        address indexed _address,
        bytes32 indexed _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        bool _tradeDirection,
        uint256 _orderLeverage
    );

    event OrderProcessed(
        bytes32 _orderId,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _liquidationTimestamp,
        uint256 _timeStamp,
        uint256 _newLongShares,
        uint256 _newShortShares,
        uint256 _newAverageEntry,
        uint256 _newAverageSpread,
        uint256 _newAverageLeverage,
        uint256 _liquidationPrice
    );

    event PositionUpdated(
        address _userId,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _newLongShares,
        uint256 _newShortShares,
        uint256 _newMeanEntryPrice,
        uint256 _newMeanEntrySpread,
        uint256 _newMeanEntryLeverage,
        uint256 _newLiquidationPrice,
        uint256 _mint,
        uint256 _burn
    );

    event LinkState(address _address);
    event LinkStaking(address _stakingAddress);
    event LinkMintingLimiter(address _mintingLimiterAddress);

    
    event LockedPriceForClosingPositions(bytes32 _marketId, uint256 _price);


    constructor(address _stateAddress, address _coldStorageOwnerAddress, address _stakingContractAddress, bool _escrowOpenOrderEnabled, uint256 _deployedTimestampOverride, address _mintingLimiterAddress) public {
        setMorpherState(_stateAddress);
        setMorpherStaking(_stakingContractAddress);
        setMorpherMintingLimiter(_mintingLimiterAddress);
        transferOwnership(_coldStorageOwnerAddress);
        escrowOpenOrderEnabled = _escrowOpenOrderEnabled;
        deployedTimeStamp = _deployedTimestampOverride > 0 ? _deployedTimestampOverride : block.timestamp;
    }

    modifier onlyOracle {
        require(msg.sender == state.getOracleContract(), "MorpherTradeEngine: function can only be called by Oracle Contract.");
        _;
    }

    modifier onlyAdministrator {
        require(msg.sender == getAdministrator(), "MorpherTradeEngine: function can only be called by the Administrator.");
        _;
    }

// ----------------------------------------------------------------------------
// Administrative functions
// Set state address, get administrator address
// ----------------------------------------------------------------------------

    function setMorpherState(address _stateAddress) public onlyOwner {
        state = MorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    function setMorpherStaking(address _stakingAddress) public onlyOwner {
        staking = IMorpherStaking(_stakingAddress);
        emit LinkStaking(_stakingAddress);
    }

    function setMorpherMintingLimiter(address _mintingLimiterAddress) public onlyOwner {
        mintingLimiter = MorpherMintingLimiter(_mintingLimiterAddress);
        emit LinkMintingLimiter(_mintingLimiterAddress);
    }

    function getAdministrator() public view returns(address _administrator) {
        return state.getAdministrator();
    }

    function setEscrowOpenOrderEnabled(bool _isEnabled) public onlyOwner {
        escrowOpenOrderEnabled = _isEnabled;
    }
    
    function paybackEscrow(bytes32 _orderId) private {
        //pay back the escrow to the user so he has it back on his balance/**
        if(orders[_orderId].orderEscrowAmount > 0) {
            //checks effects interaction
            uint256 paybackAmount = orders[_orderId].orderEscrowAmount;
            orders[_orderId].orderEscrowAmount = 0;
            state.transfer(escrowOpenOrderAddress, orders[_orderId].userId, paybackAmount);
        }
    }

    function buildupEscrow(bytes32 _orderId, uint256 _amountInMPH) private {
        if(escrowOpenOrderEnabled && _amountInMPH > 0) {
            state.transfer(orders[_orderId].userId, escrowOpenOrderAddress, _amountInMPH);
            orders[_orderId].orderEscrowAmount = _amountInMPH;
        }
    }


    function validateClosedMarketOrderConditions(address _address, bytes32 _marketId, uint256 _closeSharesAmount, uint256 _openMPHTokenAmount, bool _tradeDirection ) internal view {
        //markets active? Still tradeable?
        if(_openMPHTokenAmount > 0) {
            require(state.getMarketActive(_marketId) == true, "MorpherTradeEngine: market unknown or currently not enabled for trading.");
        } else {
            //we're just closing a position, but it needs a forever price locked in if market is not active
            //the user needs to close his complete position
            if(state.getMarketActive(_marketId) == false) {
                require(getDeactivatedMarketPrice(_marketId) > 0, "MorpherTradeEngine: Can't close a position, market not active and closing price not locked");
                if(_tradeDirection) {
                    //long
                    require(_closeSharesAmount == state.getShortShares(_address, _marketId), "MorpherTradeEngine: Deactivated market order needs all shares to be closed");
                } else {
                    //short
                    require(_closeSharesAmount == state.getLongShares(_address, _marketId), "MorpherTradeEngine: Deactivated market order needs all shares to be closed");
                }
            }
        }
    }

    //wrapper for stack too deep errors
    function validateClosedMarketOrder(bytes32 _orderId) internal view {
         validateClosedMarketOrderConditions(orders[_orderId].userId, orders[_orderId].marketId, orders[_orderId].closeSharesAmount, orders[_orderId].openMPHTokenAmount, orders[_orderId].tradeDirection);
    }

// ----------------------------------------------------------------------------
// requestOrderId(address _address, bytes32 _marketId, bool _closeSharesAmount, uint256 _openMPHTokenAmount, bool _tradeDirection, uint256 _orderLeverage)
// Creates a new order object with unique orderId and assigns order information.
// Must be called by MorpherOracle contract.
// ----------------------------------------------------------------------------

    function requestOrderId(
        address _address,
        bytes32 _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        bool _tradeDirection,
        uint256 _orderLeverage
        ) public onlyOracle returns (bytes32 _orderId) {
            
        require(_orderLeverage >= PRECISION, "MorpherTradeEngine: leverage too small. Leverage precision is 1e8");
        require(_orderLeverage <= state.getMaximumLeverage(), "MorpherTradeEngine: leverage exceeds maximum allowed leverage.");

        validateClosedMarketOrderConditions(_address, _marketId, _closeSharesAmount, _openMPHTokenAmount, _tradeDirection);

        //request limits
        require(state.getNumberOfRequests(_address) <= state.getNumberOfRequestsLimit() ||
            state.getLastRequestBlock(_address) < block.number,
            "MorpherTradeEngine: request exceeded maximum permitted requests per block."
        );

        /**
         * The user can't partially close a position and open another one with MPH
         */
        if(_openMPHTokenAmount > 0) {
            if(_tradeDirection) {
                //long
                require(_closeSharesAmount == state.getShortShares(_address, _marketId), "MorpherTradeEngine: Can't partially close a position and open another one in opposite direction");
            } else {
                //short
                require(_closeSharesAmount == state.getLongShares(_address, _marketId), "MorpherTradeEngine: Can't partially close a position and open another one in opposite direction");
            }
        }

        state.setLastRequestBlock(_address);
        state.increaseNumberOfRequests(_address);
        orderNonce++;
        _orderId = keccak256(
            abi.encodePacked(
                _address,
                block.number,
                _marketId,
                _closeSharesAmount,
                _openMPHTokenAmount,
                _tradeDirection,
                _orderLeverage,
                orderNonce
                )
            );
        lastOrderId = _orderId;
        orders[_orderId].userId = _address;
        orders[_orderId].marketId = _marketId;
        orders[_orderId].closeSharesAmount = _closeSharesAmount;
        orders[_orderId].openMPHTokenAmount = _openMPHTokenAmount;
        orders[_orderId].tradeDirection = _tradeDirection;
        orders[_orderId].orderLeverage = _orderLeverage;
        emit OrderIdRequested(
            _orderId,
            _address,
            _marketId,
            _closeSharesAmount,
            _openMPHTokenAmount,
            _tradeDirection,
            _orderLeverage
        );

        /**
         * put the money in escrow here if given MPH to open an order
         * - also, can only close positions if in shares, so it will
         * definitely trigger a mint there.
         * The money must be put in escrow even though we have an existing position
         */
        buildupEscrow(_orderId, _openMPHTokenAmount);

        return _orderId;
    }

// ----------------------------------------------------------------------------
// Getter functions for orders, shares, and positions
// ----------------------------------------------------------------------------

    function getOrder(bytes32 _orderId) public view returns (
        address _userId,
        bytes32 _marketId,
        uint256 _closeSharesAmount,
        uint256 _openMPHTokenAmount,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage
        ) {
        return(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].closeSharesAmount,
            orders[_orderId].openMPHTokenAmount,
            orders[_orderId].marketPrice,
            orders[_orderId].marketSpread,
            orders[_orderId].orderLeverage
            );
    }

    function getPosition(address _address, bytes32 _marketId) public view returns (
        uint256 _positionLongShares,
        uint256 _positionShortShares,
        uint256 _positionAveragePrice,
        uint256 _positionAverageSpread,
        uint256 _positionAverageLeverage,
        uint256 _liquidationPrice
        ) {
        return(
            state.getLongShares(_address, _marketId),
            state.getShortShares(_address, _marketId),
            state.getMeanEntryPrice(_address,_marketId),
            state.getMeanEntrySpread(_address,_marketId),
            state.getMeanEntryLeverage(_address,_marketId),
            state.getLiquidationPrice(_address,_marketId)
        );
    }

    function setDeactivatedMarketPrice(bytes32 _marketId, uint256 _price) public onlyOracle {
         state.setPosition(
            closedMarketPriceLock,
            _marketId,
            now.mul(1000),
            0,
            0,
            _price,
            0,
            0,
            0
        );

        emit LockedPriceForClosingPositions(_marketId, _price);

    }

    function getDeactivatedMarketPrice(bytes32 _marketId) public view returns(uint256) {
        ( , , uint positionForeverClosingPrice, , ,) = state.getPosition(closedMarketPriceLock, _marketId);
        return positionForeverClosingPrice;
    }

// ----------------------------------------------------------------------------
// liquidate(bytes32 _orderId)
// Checks for bankruptcy of position between its last update and now
// Time check is necessary to avoid two consecutive / unorderded liquidations
// ----------------------------------------------------------------------------

    function liquidate(bytes32 _orderId) private {
        address _address = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _liquidationTimestamp = orders[_orderId].liquidationTimestamp;
        if (_liquidationTimestamp > state.getLastUpdated(_address, _marketId)) {
            if (state.getLongShares(_address,_marketId) > 0) {
                state.setPosition(
                    _address,
                    _marketId,
                    orders[_orderId].timeStamp,
                    0,
                    state.getShortShares(_address, _marketId),
                    0,
                    0,
                    PRECISION,
                    0);
                emit PositionLiquidated(
                    _address,
                    _marketId,
                    true,
                    orders[_orderId].timeStamp,
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread
                );
            }
            if (state.getShortShares(_address,_marketId) > 0) {
                state.setPosition(
                    _address,
                    _marketId,
                    orders[_orderId].timeStamp,
                    state.getLongShares(_address, _marketId),
                    0,
                    0,
                    0,
                    PRECISION,
                    0
                );
                emit PositionLiquidated(
                    _address,
                    _marketId,
                    false,
                    orders[_orderId].timeStamp,
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread
                );
            }
        }
    }

// ----------------------------------------------------------------------------
// processOrder(bytes32 _orderId, uint256 _marketPrice, uint256 _marketSpread, uint256 _liquidationTimestamp, uint256 _timeStamp)
// ProcessOrder receives the price/spread/liqidation information from the Oracle and
// triggers the processing of the order. If successful, processOrder updates the portfolio state.
// Liquidation time check is necessary to avoid two consecutive / unorderded liquidations
// ----------------------------------------------------------------------------

    function processOrder(
        bytes32 _orderId,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _liquidationTimestamp,
        uint256 _timeStampInMS
        ) public onlyOracle returns (
            uint256 _newLongShares,
            uint256 _newShortShares,
            uint256 _newAverageEntry,
            uint256 _newAverageSpread,
            uint256 _newAverageLeverage,
            uint256 _liquidationPrice
        ) {
        require(orders[_orderId].userId != address(0), "MorpherTradeEngine: unable to process, order has been deleted.");
        require(_marketPrice > 0, "MorpherTradeEngine: market priced at zero. Buy order cannot be processed.");
        require(_marketPrice >= _marketSpread, "MorpherTradeEngine: market price lower then market spread. Order cannot be processed.");
        
        orders[_orderId].marketPrice = _marketPrice;
        orders[_orderId].marketSpread = _marketSpread;
        orders[_orderId].timeStamp = _timeStampInMS;
        orders[_orderId].liquidationTimestamp = _liquidationTimestamp;
        
        /**
        * If the market is deactivated, then override the price with the locked in market price
        * if the price wasn't locked in: error out.
        */
        if(state.getMarketActive(orders[_orderId].marketId) == false) {
            validateClosedMarketOrder(_orderId);
            orders[_orderId].marketPrice = getDeactivatedMarketPrice(orders[_orderId].marketId);
        }
        
        // Check if previous position on that market was liquidated
        if (_liquidationTimestamp > state.getLastUpdated(orders[_orderId].userId, orders[_orderId].marketId)) {
            liquidate(_orderId);
        }
    

        paybackEscrow(_orderId);

        if (orders[_orderId].tradeDirection) {
            processBuyOrder(_orderId);
        } else {
            processSellOrder(_orderId);
        }

        address _address = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        delete orders[_orderId];
        emit OrderProcessed(
            _orderId,
            _marketPrice,
            _marketSpread,
            _liquidationTimestamp,
            _timeStampInMS,
            _newLongShares,
            _newShortShares,
            _newAverageEntry,
            _newAverageSpread,
            _newAverageLeverage,
            _liquidationPrice
        );

        return (
            state.getLongShares(_address, _marketId),
            state.getShortShares(_address, _marketId),
            state.getMeanEntryPrice(_address,_marketId),
            state.getMeanEntrySpread(_address,_marketId),
            state.getMeanEntryLeverage(_address,_marketId),
            state.getLiquidationPrice(_address,_marketId)
        );
    }

// ----------------------------------------------------------------------------
// function cancelOrder(bytes32 _orderId, address _address)
// Users or Administrator can delete pending orders before the callback went through
// ----------------------------------------------------------------------------
    function cancelOrder(bytes32 _orderId, address _address) public onlyOracle {
        require(_address == orders[_orderId].userId || _address == getAdministrator(), "MorpherTradeEngine: only Administrator or user can cancel an order.");
        require(orders[_orderId].userId != address(0), "MorpherTradeEngine: unable to process, order does not exist.");

        /**
         * Pay back any escrow there
         */
        paybackEscrow(_orderId);

        delete orders[_orderId];
        emit OrderCancelled(_orderId, _address);
    }

// ----------------------------------------------------------------------------
// shortShareValue / longShareValue compute the value of a virtual future
// given current price/spread/leverage of the market and mean price/spread/leverage
// at the beginning of the trade
// ----------------------------------------------------------------------------
    function shortShareValue(
        uint256 _positionAveragePrice,
        uint256 _positionAverageLeverage,
        uint256 _positionTimeStampInMs,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage,
        bool _sell
        ) public view returns (uint256 _shareValue) {

        uint256 _averagePrice = _positionAveragePrice;
        uint256 _averageLeverage = _positionAverageLeverage;

        if (_positionAverageLeverage < PRECISION) {
            // Leverage can never be less than 1. Fail safe for empty positions, i.e. undefined _positionAverageLeverage
            _averageLeverage = PRECISION;
        }
        if (_sell == false) {
            // New short position
            // It costs marketPrice + marketSpread to build up a new short position
            _averagePrice = _marketPrice;
	        // This is the average Leverage
	        _averageLeverage = _orderLeverage;
        }
        if (
            getLiquidationPrice(_averagePrice, _averageLeverage, false, _positionTimeStampInMs) <= _marketPrice
            ) {
	        // Position is worthless
            _shareValue = 0;
        } else {
            // The regular share value is 2x the entry price minus the current price for short positions.
            _shareValue = _averagePrice.mul((PRECISION.add(_averageLeverage))).div(PRECISION);
            _shareValue = _shareValue.sub(_marketPrice.mul(_averageLeverage).div(PRECISION));
            if (_sell == true) {
                // We have to reduce the share value by the average spread (i.e. the average expense to build up the position)
                // and reduce the value further by the spread for selling.
                _shareValue = _shareValue.sub(_marketSpread.mul(_averageLeverage).div(PRECISION));
                uint256 _marginInterest = calculateMarginInterest(_averagePrice, _averageLeverage, _positionTimeStampInMs);
                if (_marginInterest <= _shareValue) {
                    _shareValue = _shareValue.sub(_marginInterest);
                } else {
                    _shareValue = 0;
                }
            } else {
                // If a new short position is built up each share costs value + spread
                _shareValue = _shareValue.add(_marketSpread.mul(_orderLeverage).div(PRECISION));
            }
        }
      
        return _shareValue;
    }

    function longShareValue(
        uint256 _positionAveragePrice,
        uint256 _positionAverageLeverage,
        uint256 _positionTimeStampInMs,
        uint256 _marketPrice,
        uint256 _marketSpread,
        uint256 _orderLeverage,
        bool _sell
        ) public view returns (uint256 _shareValue) {

        uint256 _averagePrice = _positionAveragePrice;
        uint256 _averageLeverage = _positionAverageLeverage;

        if (_positionAverageLeverage < PRECISION) {
            // Leverage can never be less than 1. Fail safe for empty positions, i.e. undefined _positionAverageLeverage
            _averageLeverage = PRECISION;
        }
        if (_sell == false) {
            // New long position
            // It costs marketPrice + marketSpread to build up a new long position
            _averagePrice = _marketPrice;
	        // This is the average Leverage
	        _averageLeverage = _orderLeverage;
        }
        if (
            _marketPrice <= getLiquidationPrice(_averagePrice, _averageLeverage, true, _positionTimeStampInMs)
            ) {
	        // Position is worthless
            _shareValue = 0;
        } else {
            _shareValue = _averagePrice.mul(_averageLeverage.sub(PRECISION)).div(PRECISION);
            // The regular share value is market price times leverage minus entry price times entry leverage minus one.
            _shareValue = (_marketPrice.mul(_averageLeverage).div(PRECISION)).sub(_shareValue);
            if (_sell == true) {
                // We sell a long and have to correct the shareValue with the averageSpread and the currentSpread for selling.
                _shareValue = _shareValue.sub(_marketSpread.mul(_averageLeverage).div(PRECISION));
                
                uint256 _marginInterest = calculateMarginInterest(_averagePrice, _averageLeverage, _positionTimeStampInMs);
                if (_marginInterest <= _shareValue) {
                    _shareValue = _shareValue.sub(_marginInterest);
                } else {
                    _shareValue = 0;
                }
            } else {
                // We buy a new long position and have to pay the spread
                _shareValue = _shareValue.add(_marketSpread.mul(_orderLeverage).div(PRECISION));
            }
        }
        return _shareValue;
    }

// ----------------------------------------------------------------------------
// calculateMarginInterest(uint256 _averagePrice, uint256 _averageLeverage, uint256 _positionTimeStamp)
// Calculates the interest for leveraged positions
// ----------------------------------------------------------------------------


    function calculateMarginInterest(uint256 _averagePrice, uint256 _averageLeverage, uint256 _positionTimeStampInMs) public view returns (uint256 _marginInterest) {
        if (_positionTimeStampInMs.div(1000) < deployedTimeStamp) {
            _positionTimeStampInMs = deployedTimeStamp.mul(1000);
        }
        _marginInterest = _averagePrice.mul(_averageLeverage.sub(PRECISION));
        _marginInterest = _marginInterest.mul((now.sub(_positionTimeStampInMs.div(1000)).div(86400)).add(1));
        _marginInterest = _marginInterest.mul(staking.interestRate()).div(PRECISION).div(PRECISION);
        return _marginInterest;
    }

// ----------------------------------------------------------------------------
// processBuyOrder(bytes32 _orderId)
// Converts orders specified in virtual shares to orders specified in Morpher token
// and computes the number of short shares that are sold and long shares that are bought.
// long shares are bought only if the order amount exceeds all open short positions
// ----------------------------------------------------------------------------

    function processBuyOrder(bytes32 _orderId) private {
        if (orders[_orderId].closeSharesAmount > 0) {
            //calcualte the balanceUp/down first
            //then reopen the position with MPH amount

             // Investment was specified in shares
            if (orders[_orderId].closeSharesAmount <= state.getShortShares(orders[_orderId].userId, orders[_orderId].marketId)) {
                // Partial closing of short position
                orders[_orderId].shortSharesOrder = orders[_orderId].closeSharesAmount;
            } else {
                // Closing of entire short position
                orders[_orderId].shortSharesOrder = state.getShortShares(orders[_orderId].userId, orders[_orderId].marketId);
            }
        }

        //calculate the long shares, but only if the old position is completely closed out (if none exist shortSharesOrder = 0)
        if(
            orders[_orderId].shortSharesOrder == state.getShortShares(orders[_orderId].userId, orders[_orderId].marketId) && 
            orders[_orderId].openMPHTokenAmount > 0
        ) {
            orders[_orderId].longSharesOrder = orders[_orderId].openMPHTokenAmount.div(
                longShareValue(
                    orders[_orderId].marketPrice,
                    orders[_orderId].orderLeverage,
                    now,
                    orders[_orderId].marketPrice,
                    orders[_orderId].marketSpread,
                    orders[_orderId].orderLeverage,
                    false
            ));
        }

        // Investment equals number of shares now.
        if (orders[_orderId].shortSharesOrder > 0) {
            closeShort(_orderId);
        }
        if (orders[_orderId].longSharesOrder > 0) {
            openLong(_orderId);
        }
    }

// ----------------------------------------------------------------------------
// processSellOrder(bytes32 _orderId)
// Converts orders specified in virtual shares to orders specified in Morpher token
// and computes the number of long shares that are sold and short shares that are bought.
// short shares are bought only if the order amount exceeds all open long positions
// ----------------------------------------------------------------------------

    function processSellOrder(bytes32 _orderId) private {
        if (orders[_orderId].closeSharesAmount > 0) {
            //calcualte the balanceUp/down first
            //then reopen the position with MPH amount

            // Investment was specified in shares
            if (orders[_orderId].closeSharesAmount <= state.getLongShares(orders[_orderId].userId, orders[_orderId].marketId)) {
                // Partial closing of long position
                orders[_orderId].longSharesOrder = orders[_orderId].closeSharesAmount;
            } else {
                // Closing of entire long position
                orders[_orderId].longSharesOrder = state.getLongShares(orders[_orderId].userId, orders[_orderId].marketId);
            }
        }

        if(
            orders[_orderId].longSharesOrder == state.getLongShares(orders[_orderId].userId, orders[_orderId].marketId) && 
            orders[_orderId].openMPHTokenAmount > 0
        ) {
        orders[_orderId].shortSharesOrder = orders[_orderId].openMPHTokenAmount.div(
                    shortShareValue(
                        orders[_orderId].marketPrice,
                        orders[_orderId].orderLeverage,
                        now,
                        orders[_orderId].marketPrice,
                        orders[_orderId].marketSpread,
                        orders[_orderId].orderLeverage,
                        false
                ));
        }
        // Investment equals number of shares now.
        if (orders[_orderId].longSharesOrder > 0) {
            closeLong(_orderId);
        }
        if (orders[_orderId].shortSharesOrder > 0) {
            openShort(_orderId);
        }
    }

// ----------------------------------------------------------------------------
// openLong(bytes32 _orderId)
// Opens a new long position and computes the new resulting average entry price/spread/leverage.
// Computation is broken down to several instructions for readability.
// ----------------------------------------------------------------------------
    function openLong(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;

        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;

        // Existing position is virtually liquidated and reopened with current marketPrice
        // orders[_orderId].newMeanEntryPrice = orders[_orderId].marketPrice;
        // _factorLongShares is a factor to adjust the existing longShares via virtual liqudiation and reopening at current market price

        uint256 _factorLongShares = state.getMeanEntryLeverage(_userId, _marketId);
        if (_factorLongShares < PRECISION) {
            _factorLongShares = PRECISION;
        }
        _factorLongShares = _factorLongShares.sub(PRECISION);
        _factorLongShares = _factorLongShares.mul(state.getMeanEntryPrice(_userId, _marketId)).div(orders[_orderId].marketPrice);
        if (state.getMeanEntryLeverage(_userId, _marketId) > _factorLongShares) {
            _factorLongShares = state.getMeanEntryLeverage(_userId, _marketId).sub(_factorLongShares);
        } else {
            _factorLongShares = 0;
        }

        uint256 _adjustedLongShares = _factorLongShares.mul(state.getLongShares(_userId, _marketId)).div(PRECISION);

        // _newMeanLeverage is the weighted leverage of the existing position and the new position
        _newMeanLeverage = state.getMeanEntryLeverage(_userId, _marketId).mul(_adjustedLongShares);
        _newMeanLeverage = _newMeanLeverage.add(orders[_orderId].orderLeverage.mul(orders[_orderId].longSharesOrder));
        _newMeanLeverage = _newMeanLeverage.div(_adjustedLongShares.add(orders[_orderId].longSharesOrder));

        // _newMeanSpread is the weighted spread of the existing position and the new position
        _newMeanSpread = state.getMeanEntrySpread(_userId, _marketId).mul(state.getLongShares(_userId, _marketId));
        _newMeanSpread = _newMeanSpread.add(orders[_orderId].marketSpread.mul(orders[_orderId].longSharesOrder));
        _newMeanSpread = _newMeanSpread.div(_adjustedLongShares.add(orders[_orderId].longSharesOrder));

        orders[_orderId].balanceDown = orders[_orderId].longSharesOrder.mul(orders[_orderId].marketPrice).add(
            orders[_orderId].longSharesOrder.mul(orders[_orderId].marketSpread).mul(orders[_orderId].orderLeverage).div(PRECISION)
        );
        orders[_orderId].balanceUp = 0;
        orders[_orderId].newLongShares = _adjustedLongShares.add(orders[_orderId].longSharesOrder);
        orders[_orderId].newShortShares = state.getShortShares(_userId, _marketId);
        orders[_orderId].newMeanEntryPrice = orders[_orderId].marketPrice;
        orders[_orderId].newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }
// ----------------------------------------------------------------------------
// closeLong(bytes32 _orderId)
// Closes an existing long position. Average entry price/spread/leverage do not change.
// ----------------------------------------------------------------------------
     function closeLong(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _newLongShares  = state.getLongShares(_userId, _marketId).sub(orders[_orderId].longSharesOrder);
        uint256 _balanceUp = calculateBalanceUp(_orderId);
        uint256 _newMeanEntry;
        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;

        if (orders[_orderId].longSharesOrder == state.getLongShares(_userId, _marketId)) {
            _newMeanEntry = 0;
            _newMeanSpread = 0;
            _newMeanLeverage = PRECISION;
        } else {
            _newMeanEntry = state.getMeanEntryPrice(_userId, _marketId);
	        _newMeanSpread = state.getMeanEntrySpread(_userId, _marketId);
	        _newMeanLeverage = state.getMeanEntryLeverage(_userId, _marketId);
            resetTimestampInOrderToLastUpdated(_orderId);
        }

        orders[_orderId].balanceDown = 0;
        orders[_orderId].balanceUp = _balanceUp;
        orders[_orderId].newLongShares = _newLongShares;
        orders[_orderId].newShortShares = state.getShortShares(_userId, _marketId);
        orders[_orderId].newMeanEntryPrice = _newMeanEntry;
        orders[_orderId].newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

event ResetTimestampInOrder(bytes32 _orderId, uint oldTimestamp, uint newTimestamp);
function resetTimestampInOrderToLastUpdated(bytes32 _orderId) internal {
    address userId = orders[_orderId].userId;
    bytes32 marketId = orders[_orderId].marketId;
    uint lastUpdated = state.getLastUpdated(userId, marketId);
    emit ResetTimestampInOrder(_orderId, orders[_orderId].timeStamp, lastUpdated);
    orders[_orderId].timeStamp = lastUpdated;
}

// ----------------------------------------------------------------------------
// closeShort(bytes32 _orderId)
// Closes an existing short position. Average entry price/spread/leverage do not change.
// ----------------------------------------------------------------------------
function calculateBalanceUp(bytes32 _orderId) private view returns (uint256 _balanceUp) {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _shareValue;

        if (orders[_orderId].tradeDirection == false) { //we are selling our long shares
            _balanceUp = orders[_orderId].longSharesOrder;
            _shareValue = longShareValue(
                state.getMeanEntryPrice(_userId, _marketId),
                state.getMeanEntryLeverage(_userId, _marketId),
                state.getLastUpdated(_userId, _marketId),
                orders[_orderId].marketPrice,
                orders[_orderId].marketSpread,
                state.getMeanEntryLeverage(_userId, _marketId),
                true
            );
        } else { //we are going long, we are selling our short shares
            _balanceUp = orders[_orderId].shortSharesOrder;
            _shareValue = shortShareValue(
                state.getMeanEntryPrice(_userId, _marketId),
                state.getMeanEntryLeverage(_userId, _marketId),
                state.getLastUpdated(_userId, _marketId),
                orders[_orderId].marketPrice,
                orders[_orderId].marketSpread,
                state.getMeanEntryLeverage(_userId, _marketId),
                true
            );
        }
        return _balanceUp.mul(_shareValue); 
    }

    function closeShort(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;
        uint256 _newMeanEntry;
        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;
        uint256 _newShortShares = state.getShortShares(_userId, _marketId).sub(orders[_orderId].shortSharesOrder);
        uint256 _balanceUp = calculateBalanceUp(_orderId);
        
        if (orders[_orderId].shortSharesOrder == state.getShortShares(_userId, _marketId)) {
            _newMeanEntry = 0;
            _newMeanSpread = 0;
	        _newMeanLeverage = PRECISION;
        } else {
            _newMeanEntry = state.getMeanEntryPrice(_userId, _marketId);
	        _newMeanSpread = state.getMeanEntrySpread(_userId, _marketId);
	        _newMeanLeverage = state.getMeanEntryLeverage(_userId, _marketId);

            /**
             * we need the timestamp of the old order for partial closes, not the new one
             */
            resetTimestampInOrderToLastUpdated(_orderId);
        }

        orders[_orderId].balanceDown = 0;
        orders[_orderId].balanceUp = _balanceUp;
        orders[_orderId].newLongShares = state.getLongShares(orders[_orderId].userId, orders[_orderId].marketId);
        orders[_orderId].newShortShares = _newShortShares;
        orders[_orderId].newMeanEntryPrice = _newMeanEntry;
        orders[_orderId].newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

// ----------------------------------------------------------------------------
// openShort(bytes32 _orderId)
// Opens a new short position and computes the new resulting average entry price/spread/leverage.
// Computation is broken down to several instructions for readability.
// ----------------------------------------------------------------------------
    function openShort(bytes32 _orderId) private {
        address _userId = orders[_orderId].userId;
        bytes32 _marketId = orders[_orderId].marketId;

        uint256 _newMeanSpread;
        uint256 _newMeanLeverage;
        //
        // Existing position is virtually liquidated and reopened with current marketPrice
        // orders[_orderId].newMeanEntryPrice = orders[_orderId].marketPrice;
        // _factorShortShares is a factor to adjust the existing shortShares via virtual liqudiation and reopening at current market price

        uint256 _factorShortShares = state.getMeanEntryLeverage(_userId, _marketId);
        if (_factorShortShares < PRECISION) {
            _factorShortShares = PRECISION;
        }
        _factorShortShares = _factorShortShares.add(PRECISION);
        _factorShortShares = _factorShortShares.mul(state.getMeanEntryPrice(_userId, _marketId)).div(orders[_orderId].marketPrice);
        if (state.getMeanEntryLeverage(_userId, _marketId) < _factorShortShares) {
            _factorShortShares = _factorShortShares.sub(state.getMeanEntryLeverage(_userId, _marketId));
        } else {
            _factorShortShares = 0;
        }

        uint256 _adjustedShortShares = _factorShortShares.mul(state.getShortShares(_userId, _marketId)).div(PRECISION);

        // _newMeanLeverage is the weighted leverage of the existing position and the new position
        _newMeanLeverage = state.getMeanEntryLeverage(_userId, _marketId).mul(_adjustedShortShares);
        _newMeanLeverage = _newMeanLeverage.add(orders[_orderId].orderLeverage.mul(orders[_orderId].shortSharesOrder));
        _newMeanLeverage = _newMeanLeverage.div(_adjustedShortShares.add(orders[_orderId].shortSharesOrder));

        // _newMeanSpread is the weighted spread of the existing position and the new position
        _newMeanSpread = state.getMeanEntrySpread(_userId, _marketId).mul(state.getShortShares(_userId, _marketId));
        _newMeanSpread = _newMeanSpread.add(orders[_orderId].marketSpread.mul(orders[_orderId].shortSharesOrder));
        _newMeanSpread = _newMeanSpread.div(_adjustedShortShares.add(orders[_orderId].shortSharesOrder));

        orders[_orderId].balanceDown = orders[_orderId].shortSharesOrder.mul(orders[_orderId].marketPrice).add(
            orders[_orderId].shortSharesOrder.mul(orders[_orderId].marketSpread).mul(orders[_orderId].orderLeverage).div(PRECISION)
        );
        orders[_orderId].balanceUp = 0;
        orders[_orderId].newLongShares = state.getLongShares(_userId, _marketId);
        orders[_orderId].newShortShares = _adjustedShortShares.add(orders[_orderId].shortSharesOrder);
        orders[_orderId].newMeanEntryPrice = orders[_orderId].marketPrice;
        orders[_orderId].newMeanEntrySpread = _newMeanSpread;
        orders[_orderId].newMeanEntryLeverage = _newMeanLeverage;

        setPositionInState(_orderId);
    }

    function computeLiquidationPrice(bytes32 _orderId) public returns(uint256 _liquidationPrice) {
        orders[_orderId].newLiquidationPrice = 0;
        if (orders[_orderId].newLongShares > 0) {
            orders[_orderId].newLiquidationPrice = getLiquidationPrice(orders[_orderId].newMeanEntryPrice, orders[_orderId].newMeanEntryLeverage, true, orders[_orderId].timeStamp);
        }
        if (orders[_orderId].newShortShares > 0) {
            orders[_orderId].newLiquidationPrice = getLiquidationPrice(orders[_orderId].newMeanEntryPrice, orders[_orderId].newMeanEntryLeverage, false, orders[_orderId].timeStamp);
        }
        return orders[_orderId].newLiquidationPrice;
    }

    function getLiquidationPrice(uint256 _newMeanEntryPrice, uint256 _newMeanEntryLeverage, bool _long, uint _positionTimestampInMs) public view returns (uint256 _liquidationPrice) {
        if (_long == true) {
            _liquidationPrice = _newMeanEntryPrice.mul(_newMeanEntryLeverage.sub(PRECISION)).div(_newMeanEntryLeverage);
            _liquidationPrice = _liquidationPrice.add(calculateMarginInterest(_newMeanEntryPrice, _newMeanEntryLeverage, _positionTimestampInMs));
        } else {
            _liquidationPrice = _newMeanEntryPrice.mul(_newMeanEntryLeverage.add(PRECISION)).div(_newMeanEntryLeverage);
            _liquidationPrice = _liquidationPrice.sub(calculateMarginInterest(_newMeanEntryPrice, _newMeanEntryLeverage, _positionTimestampInMs));
        }
        return _liquidationPrice;
    }

    
// ----------------------------------------------------------------------------
// setPositionInState(bytes32 _orderId)
// Updates the portfolio in Morpher State. Called by closeLong/closeShort/openLong/openShort
// ----------------------------------------------------------------------------
    function setPositionInState(bytes32 _orderId) private {
        require(state.balanceOf(orders[_orderId].userId).add(orders[_orderId].balanceUp) >= orders[_orderId].balanceDown, "MorpherTradeEngine: insufficient funds.");
        computeLiquidationPrice(_orderId);
        // Net balanceUp and balanceDown
        if (orders[_orderId].balanceUp > orders[_orderId].balanceDown) {
            orders[_orderId].balanceUp.sub(orders[_orderId].balanceDown);
            orders[_orderId].balanceDown = 0;
        } else {
            orders[_orderId].balanceDown.sub(orders[_orderId].balanceUp);
            orders[_orderId].balanceUp = 0;
        }
        if (orders[_orderId].balanceUp > 0) {
            mintingLimiter.mint(orders[_orderId].userId, orders[_orderId].balanceUp);
        }
        if (orders[_orderId].balanceDown > 0) {
            state.burn(orders[_orderId].userId, orders[_orderId].balanceDown);
        }
        state.setPosition(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].timeStamp,
            orders[_orderId].newLongShares,
            orders[_orderId].newShortShares,
            orders[_orderId].newMeanEntryPrice,
            orders[_orderId].newMeanEntrySpread,
            orders[_orderId].newMeanEntryLeverage,
            orders[_orderId].newLiquidationPrice
        );
        emit PositionUpdated(
            orders[_orderId].userId,
            orders[_orderId].marketId,
            orders[_orderId].timeStamp,
            orders[_orderId].newLongShares,
            orders[_orderId].newShortShares,
            orders[_orderId].newMeanEntryPrice,
            orders[_orderId].newMeanEntrySpread,
            orders[_orderId].newMeanEntryLeverage,
            orders[_orderId].newLiquidationPrice,
            orders[_orderId].balanceUp,
            orders[_orderId].balanceDown
        );
    }
}