/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// File: contracts\interfaces\UniswapRouterInterfaceV5.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface UniswapRouterInterfaceV5{
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
}

// File: contracts\interfaces\AggregatorInterfaceV5.sol

pragma solidity 0.8.7;

interface AggregatorInterfaceV5{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE }
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external view returns(uint);
    function pairMinOpenLimitSlippageP(uint) external view returns(uint);
    function closeFeeP(uint) external view returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function openFeeP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function pairsCount() external view returns(uint);
    function tokenDaiReservesLp() external view returns(uint, uint);
}

// File: contracts\interfaces\TokenInterfaceV5.sol

pragma solidity 0.8.7;

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// File: contracts\interfaces\NftInterfaceV5.sol

pragma solidity 0.8.7;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// File: contracts\interfaces\VaultInterfaceV5.sol

pragma solidity 0.8.7;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
}

// File: contracts\interfaces\StorageInterfaceV5.sol

pragma solidity 0.8.7;






interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint tokenId;
        uint tokenPriceDai;         // PRECISION
        uint openInterestDai;       // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function dev() external view returns(address);
    function dai() external view returns(TokenInterfaceV5);
    function token() external view returns(TokenInterfaceV5);
    function linkErc677() external view returns(TokenInterfaceV5);
    function tokenDaiRouter() external view returns(UniswapRouterInterfaceV5);
    function priceAggregator() external view returns(AggregatorInterfaceV5);
    function vault() external view returns(VaultInterfaceV5);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function handleTokens(address,uint,bool) external;
    function transferDai(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function spreadReductionsP(uint) external view returns(uint);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function nftLimitOrderFeeP() external view returns(uint);
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint, bool, bool) external returns(uint);
    function distributeLpRewards(uint) external;
    function referralP() external view returns(uint);
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestDai(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function nfts(uint) external view returns(NftInterfaceV5);
}

// File: contracts\GFarmTestnetTradingV5.sol

pragma solidity 0.8.7;

contract GFarmTestnetTradingV5{

    // Is contract active
    bool public isPaused;

    // Trading storage
    StorageInterfaceV5 public storageT;

    // Variables (specific to this implementation)
    uint public maxPosDaiP = 0.15 * 1e10;                // PRECISION (%)
    uint public minPosDai = 35*1e18;                     // 1e18 ($)
    uint public limitOrdersTimelock = 30;                // block
    uint public orderTimeout = 30;                       // block

    // Events
    event Pause(bool paused);
    event NumberUpdated(string name, uint value);
    event AddressUpdated(string name, address a);
    event MarketOrderInitiated(address trader, uint pairIndex, bool open, uint orderId);
    event NftOrderInitiated(address nftHolder, address trader, uint pairIndex, uint orderId);
    event OpenLimitPlaced(address indexed trader, uint indexed pairIndex, uint index);
    event OpenLimitUpdated(address indexed trader, uint indexed pairIndex, uint index);
    event OpenLimitCanceled(address indexed trader, uint indexed pairIndex, uint index);
    event TpUpdated(address indexed trader, uint indexed pairIndex, uint index);
    event SlUpdated(address indexed trader, uint indexed pairIndex, uint index);
    event ChainlinkCallbackTimeout(uint orderId, StorageInterfaceV5.PendingMarketOrder order);
    event CouldNotCloseTrade(address indexed trader, uint indexed pairIndex, uint index, string message);

    constructor(StorageInterfaceV5 _storageT) {
        require(address(_storageT) != address(0));
        storageT = _storageT;
    }

    // 1. MANAGE STATE

    // Modifiers
    modifier onlyGov(){ require(msg.sender == storageT.gov(), "GOV_ONLY"); _; }

    // Manage trading storage address
    // CAREFUL: IF ADDRESS WRONG, CONTRACT CAN BE STUCK
    function setStorageT(StorageInterfaceV5 _storageT) external onlyGov{
        require(_storageT.gov() == storageT.gov());
        storageT = _storageT;
        emit AddressUpdated("storageT", address(_storageT));
    }

    // Prevent doing anything => during contracts update
    function pause() external onlyGov{ isPaused = !isPaused; emit Pause(isPaused); }

    // Manage variables
    function setMaxPosDaiP(uint _maxP) external onlyGov{
        require(_maxP > 0);
        maxPosDaiP = _maxP;
        emit NumberUpdated("maxPosDaiP", _maxP);
    }
    function setMinPosDai(uint _min) external onlyGov{
        require(_min > 0);
        minPosDai = _min;
        emit NumberUpdated("minPosDai", _min);
    }
    function setLimitOrdersTimelock(uint _blocks) external onlyGov{
        require(_blocks > 0);
        limitOrdersTimelock = _blocks;
        emit NumberUpdated("limitOrdersTimelock", _blocks);
    }
    function setOrderTimeout(uint _orderTimeout) external onlyGov{
        require(_orderTimeout > 0);
        orderTimeout = _orderTimeout;
        emit NumberUpdated("orderTimeout", _orderTimeout);
    }

    // 2. EXTERNAL TRADING FUNCTIONS

    // Modifiers
    modifier notContract(){ require(tx.origin == msg.sender); _; }
    modifier notPaused(){ require(!isPaused, "PAUSED"); _; }

    // Open a new trade (market or limit)
    function openTrade(
        StorageInterfaceV5.Trade memory t,
        bool _limit,
        uint _spreadReductionId,
        uint _slippageP,
        address _referral
    ) external notContract notPaused{

        require(storageT.openTradesCount(msg.sender, t.pairIndex) + storageT.pendingMarketOpenCount(msg.sender, t.pairIndex) 
            + storageT.openLimitOrdersCount(msg.sender, t.pairIndex) < storageT.maxTradesPerPair(), 
            "MAX_TRADES_PER_PAIR");
        require(storageT.tradesPerBlock(block.number) < storageT.maxTradesPerBlock(), 
            "MAX_TRADES_PER_BLOCK");
        require(storageT.pendingOrderIdsCount(msg.sender) < storageT.maxPendingMarketOrders(), 
            "MAX_PENDING_ORDERS");
        (, uint _reserveDai) = storageT.priceAggregator().tokenDaiReservesLp();
        require(t.positionSizeDai <= _reserveDai*maxPosDaiP/100/storageT.PRECISION(), 
            "ABOVE_MAX_POS");
        require(t.positionSizeDai >= minPosDai, "BELOW_MIN_POS");
        require(t.leverage > 0 && t.leverage >= storageT.priceAggregator().pairMinLeverage(t.pairIndex) 
            && t.leverage <= storageT.priceAggregator().pairMaxLeverage(t.pairIndex), 
            "LEVERAGE_INCORRECT");
        require(t.leverage <= storageT.defaultLeverageUnlocked() || t.leverage <= storageT.getLeverageUnlocked(msg.sender),
            "LEVERAGE_NOT_UNLOCKED");
        require(_spreadReductionId == 0 || storageT.nfts(_spreadReductionId-1).balanceOf(msg.sender) > 0,
            "NO_CORRESPONDING_NFT_SPREAD_REDUCTION");
        require(t.positionSizeDai * t.leverage + storageT.openInterestDai(t.pairIndex, t.buy ? 0 : 1) 
            <= storageT.openInterestDai(t.pairIndex, 2), "MAX_OPEN_INTEREST");
        require(t.tp == 0 || t.buy && t.openPrice < t.tp || !t.buy && t.openPrice > t.tp, "WRONG_TP");
        require(t.sl == 0 || t.buy && t.openPrice > t.sl || !t.buy && t.openPrice < t.sl, "WRONG_SL");

        storageT.transferDai(msg.sender, address(storageT), t.positionSizeDai);

        if(_limit){
            require(_slippageP >= storageT.priceAggregator().pairMinOpenLimitSlippageP(t.pairIndex),
                "SLIPPAGE_TOO_SMALL");

            uint slip = t.openPrice*_slippageP/storageT.PRECISION()/100;
            uint index = storageT.firstEmptyOpenLimitIndex(msg.sender, t.pairIndex);

            storageT.storeOpenLimitOrder(StorageInterfaceV5.OpenLimitOrder(
                msg.sender,
                t.pairIndex,
                index,
                t.positionSizeDai,
                _spreadReductionId > 0 ? storageT.spreadReductionsP(_spreadReductionId-1) : 0,
                t.buy,
                t.leverage,
                t.tp,
                t.sl,
                t.buy ? t.openPrice - slip : t.openPrice,
                t.buy ? t.openPrice : t.openPrice + slip,
                block.number,
                0
            ));

            emit OpenLimitPlaced(msg.sender, t.pairIndex, index);
        }else{
            uint order = storageT.priceAggregator().getPrice(
                t.pairIndex, 
                AggregatorInterfaceV5.OrderType.MARKET_OPEN, 
                t.positionSizeDai * t.leverage
            );

            storageT.storePendingMarketOrder(
                StorageInterfaceV5.PendingMarketOrder(
                    StorageInterfaceV5.Trade(
                        msg.sender,
                        t.pairIndex,
                        0, 0,
                        t.positionSizeDai,
                        0, 
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    _slippageP,
                    _spreadReductionId > 0 ? storageT.spreadReductionsP(_spreadReductionId-1) : 0,
                    0
                ), order, true
            );

            emit MarketOrderInitiated(msg.sender, t.pairIndex, true, order);
        }

        storageT.storeReferral(msg.sender, _referral);
    }

    // Update open limit order
    function updateOpenLimitOrder(
        uint _pairIndex, 
        uint _index, 
        uint _price,        // PRECISION
        uint _slippageP,    // PRECISION,
        uint _tp,
        uint _sl
    ) external notContract notPaused{

        require(storageT.hasOpenLimitOrder(msg.sender, _pairIndex, _index), "NO_LIMIT");
        require(_slippageP >= storageT.priceAggregator().pairMinOpenLimitSlippageP(_pairIndex), 
            "MIN_LIMIT_SLIPPAGE_P");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(msg.sender, _pairIndex, _index);
        require(block.number - o.block >= limitOrdersTimelock, 
            "LIMIT_TIMELOCK");

        require(_tp == 0 || o.buy && _price < _tp || !o.buy && _price > _tp, "WRONG_TP");
        require(_sl == 0 || o.buy && _price > _sl || !o.buy && _price < _sl, "WRONG_SL");

        uint slip = _price*_slippageP/storageT.PRECISION()/100;
        o.minPrice = o.buy ? _price - slip : _price;
        o.maxPrice = o.buy ? _price : _price + slip;
        o.tp = _tp;
        o.sl = _sl;

        storageT.updateOpenLimitOrder(o);

        emit OpenLimitUpdated(msg.sender, _pairIndex, _index);
    }

    // Cancel open limit order
    function cancelOpenLimitOrder(uint _pairIndex, uint _index) external notContract notPaused{

        require(storageT.hasOpenLimitOrder(msg.sender, _pairIndex, _index), "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(msg.sender, _pairIndex, _index);
        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        storageT.transferDai(address(storageT), msg.sender, o.positionSize);

        storageT.unregisterOpenLimitOrder(msg.sender, _pairIndex, _index);
        emit OpenLimitCanceled(msg.sender, _pairIndex, _index);
    }

    // Update take profit for an open trade
    // Set to 0 to remove
    // Can be set in loss (for example exit long on a bounce even if in loss)
    // If long and tp is below current price => can be closed instantly
    // If short and tp is above current price => can be closed instantly
    function updateTp(uint _pairIndex, uint _index, uint _newTp) external notContract notPaused{

        StorageInterfaceV5.Trade memory t = storageT.openTrades(msg.sender, _pairIndex, _index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(msg.sender, _pairIndex, _index);

        require(t.leverage > 0, "NO_TRADE");
        require(block.number - i.tpLastUpdated >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        storageT.updateTp(msg.sender, _pairIndex, _index, _newTp);

        emit TpUpdated(msg.sender, _pairIndex, _index);
    }

    // Update stop loss for an open trade
    // Set to 0 to remove
    // If long and sl is above current price => can be closed instantly
    // If short and sl is below current price => can be closed instantly
    // Can be set in profit = stop profit
    // must be above -STOP_LOSS_P profit => if liq at -90% => above -80%
    // otherwise can set at -89% and earn 11% of position size while at -90% liquidation earns 0 to trader
    function updateSl(uint _pairIndex, uint _index, uint _newSl) external notContract notPaused{

        StorageInterfaceV5.Trade memory t = storageT.openTrades(msg.sender, _pairIndex, _index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(msg.sender, _pairIndex, _index);
        require(t.leverage > 0, "NO_TRADE");

        uint maxSlDist = t.openPrice * storageT.maxSlP() / 100 / t.leverage;
        require(_newSl == 0 || t.buy && _newSl >= t.openPrice - maxSlDist 
            || !t.buy && _newSl <= t.openPrice + maxSlDist, "SL_TOO_BIG");
        require(block.number - i.slLastUpdated >= limitOrdersTimelock, "LIMIT_TIMELOCK");
        
        storageT.updateSl(msg.sender, _pairIndex, _index, _newSl);

        emit SlUpdated(msg.sender, _pairIndex, _index);
    }

    // Close open trade at current price
    function closeTradeMarket(uint _pairIndex, uint _index) external notContract notPaused{
        
        StorageInterfaceV5.Trade memory t = storageT.openTrades(msg.sender, _pairIndex, _index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(msg.sender, _pairIndex, _index);
        require(storageT.tradesPerBlock(block.number) < storageT.maxTradesPerBlock(), 
            "MAX_TRADES_PER_BLOCK");
        require(storageT.pendingOrderIdsCount(msg.sender) < storageT.maxPendingMarketOrders(), 
            "MAX_PENDING_ORDERS");
        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        uint order = storageT.priceAggregator().getPrice(
            _pairIndex, 
            AggregatorInterfaceV5.OrderType.MARKET_CLOSE, 
            t.initialPosToken * t.leverage * i.tokenPriceDai / storageT.PRECISION()
        );

        storageT.storePendingMarketOrder(StorageInterfaceV5.PendingMarketOrder(
            StorageInterfaceV5.Trade(
                msg.sender,
                _pairIndex,
                _index,
                0, 0, 0, false, 0, 0, 0
            ),
            0, 0, 0, 0, 0
        ), order, false);
        emit MarketOrderInitiated(msg.sender, _pairIndex, false, order);
    }

    // Try to execute a tp, sl, liquidation, or limit long/short (only done by NFT holders)
    function executeNftOrder(
        StorageInterfaceV5.LimitOrder _orderType, 
        address _trader, 
        uint _pairIndex, 
        uint _index,
        uint _nftId, 
        uint _nftType
    ) external notContract notPaused{

        StorageInterfaceV5.Trade memory t = storageT.openTrades(_trader, _pairIndex, _index);
        require(_nftType > 0 && _nftType < 6, "WRONG_NFT_TYPE");
        require(msg.sender == storageT.gov() || storageT.nfts(_nftType-1).ownerOf(_nftId) == msg.sender,
            "NO_NFT");
        require(block.number >= storageT.nftLastSuccess(_nftId)+storageT.nftSuccessTimelock(),
            "SUCCESS_TIMELOCK");
        require(_orderType != StorageInterfaceV5.LimitOrder.OPEN || storageT.hasOpenLimitOrder(_trader, _pairIndex, _index), 
            "NO_LIMIT");
        require(_orderType == StorageInterfaceV5.LimitOrder.OPEN || t.leverage > 0, "NO_TRADE");
        require(_orderType != StorageInterfaceV5.LimitOrder.SL || t.sl > 0, "NO_SL");

        uint leveragedPosDai;
        if(_orderType == StorageInterfaceV5.LimitOrder.OPEN){
            StorageInterfaceV5.OpenLimitOrder memory l = storageT.getOpenLimitOrder(_trader, _pairIndex, _index);
            leveragedPosDai = l.positionSize * l.leverage;
        }else{
            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(_trader, _pairIndex, _index);
            leveragedPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage / storageT.PRECISION();
        }

        storageT.transferLinkToAggregator(msg.sender, _pairIndex, leveragedPosDai);

        uint order = storageT.priceAggregator().getPrice(
            _pairIndex, 
            _orderType == StorageInterfaceV5.LimitOrder.OPEN ? 
                AggregatorInterfaceV5.OrderType.LIMIT_OPEN : 
                AggregatorInterfaceV5.OrderType.LIMIT_CLOSE,
            leveragedPosDai
        );

        storageT.storePendingNftOrder(StorageInterfaceV5.PendingNftOrder(
            msg.sender,
            _nftId,
            _trader,
            _pairIndex,
            _index,
            _orderType
        ), order);
        emit NftOrderInitiated(msg.sender, _trader, _pairIndex, order);
    }

    // Claim back position size if market order callback not executed by oracle nodes after 50 blocks
    function openTradeMarketTimeout(uint _order) external notContract notPaused{

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);

        require(o.block > 0 && block.number >= o.block + orderTimeout, 
            "WAIT_TIMEOUT");
        require(o.trade.trader == msg.sender, "NOT_YOUR_ORDER");
        require(o.trade.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.transferDai(address(storageT), msg.sender, o.trade.positionSizeDai);
        storageT.unregisterPendingMarketOrder(_order, true);

        emit ChainlinkCallbackTimeout(_order, o);
    }

    // Trigger market close again if market close order callback not executed by oracle nodes after 50 blocks
    function closeTradeMarketTimeout(uint _order) external notContract notPaused{

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        StorageInterfaceV5.Trade memory t = storageT.openTrades(o.trade.trader, o.trade.pairIndex, o.trade.index);

        require(o.block > 0 && block.number >= o.block + orderTimeout, 
            "WAIT_TIMEOUT");
        require(o.trade.trader == msg.sender, "NOT_YOUR_ORDER");
        require(o.trade.leverage == 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, false);

        (bool success, bytes memory data) = address(this).delegatecall(
            abi.encodeWithSignature(
                "closeTradeMarket(uint256,uint256)",
                t.pairIndex,
                t.index
            )
        );

        if(!success){
            emit CouldNotCloseTrade(msg.sender, t.pairIndex, t.index, string(data));
        }

        emit ChainlinkCallbackTimeout(_order, o);
    }
}