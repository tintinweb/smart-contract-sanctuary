/**
 *Submitted for verification at polygonscan.com on 2021-12-20
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
    function referralP(uint) external view returns(uint);
    function nftLimitOrderFeeP(uint) external view returns(uint);
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
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
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
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint, bool, bool) external returns(uint);
    function distributeLpRewards(uint) external;
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

// File: contracts\GNSTradingCallbacksV5.sol


pragma solidity 0.8.7;

contract GNSTradingCallbacksV5{

    // Constants
    uint public constant LIQ_THRESHOLD = 90;   // -90% PNL

    // Is contract active
    bool public isPaused;

    // Trading storage
    StorageInterfaceV5 public immutable storageT;

    // Params
    uint public vaultFeeP = 10; // %

    // Structs
    struct AggregatorAnswer{
        uint order;
        uint price;
        uint spreadP;
    }

    // Events
    event MarketExecuted(
        uint orderId,
        StorageInterfaceV5.Trade t,
        bool open,
        uint price,
        uint positionSizeDai,
        int percentProfit,
        uint tokenPriceDai
    );
    event LimitExecuted(
        uint orderId,
        uint limitIndex,
        StorageInterfaceV5.Trade t,
        StorageInterfaceV5.TradeInfo tInfo,
        address indexed nftHolder,
        StorageInterfaceV5.LimitOrder orderType,
        uint price,
        uint positionSizeDai,
        int percentProfit,
        uint tokenPriceDai
    );
    event MarketCanceled(
        uint orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint wantedPrice,
        uint currentPrice,
        uint slippageToleranceP
    );
    event TradeUpdatedMarketClosed(
        uint orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );
    event AddressUpdated(string name, address a);
    event NumberUpdated(string name,uint value);
    event Pause(bool paused);

    constructor(StorageInterfaceV5 _storageT) {
        require(address(_storageT) != address(0), "ADDRESS_0");
        storageT = _storageT;
    }

    // Modifiers
    modifier onlyGov(){ require(msg.sender == storageT.gov(), "GOV_ONLY"); _; }
    modifier onlyPriceAggregator(){ require(msg.sender == address(storageT.priceAggregator()), "AGGREGATOR_ONLY"); _; }
    modifier notPaused(){ require(!isPaused, "PAUSED"); _; }

    // Manage params
    function setVaultFeeP(uint _vaultFeeP) external onlyGov{
        require(_vaultFeeP <= 50, "ABOVE_50");
        vaultFeeP = _vaultFeeP;
        emit NumberUpdated("vaultFeeP", _vaultFeeP);
    }

    // Prevent doing anything => during contracts update
    function pause() external onlyGov{ isPaused = !isPaused; emit Pause(isPaused); }

    // Called by oracle node to execute the open market order
    function openTradeMarketCallback(AggregatorAnswer memory a) external onlyPriceAggregator notPaused{

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(a.order);
        if(o.block == 0){ return; }

        uint PRECISION = storageT.PRECISION();
        a.spreadP -= a.spreadP * o.spreadReductionP / 100;

        uint priceDiff = a.price * a.spreadP / 100 / PRECISION;
        uint maxSlippage = o.wantedPrice * o.slippageP / 100 / PRECISION;
        
        StorageInterfaceV5.Trade memory t = o.trade;
        t.openPrice = t.buy ? a.price + priceDiff : a.price - priceDiff;

        // 1. Cancel because of slippage or tp/sl already reached or market closed or above max open interest
        if(t.buy && t.openPrice > o.wantedPrice + maxSlippage
        || !t.buy && t.openPrice < o.wantedPrice - maxSlippage
        || t.tp > 0 && t.buy && t.openPrice >= t.tp
        || t.sl > 0 && t.buy && t.openPrice <= t.sl
        || t.tp > 0 && !t.buy && t.openPrice <= t.tp
        || t.sl > 0 && !t.buy && t.openPrice >= t.sl
        || a.price == 0
        || storageT.openInterestDai(t.pairIndex, t.buy ? 0 : 1) + t.positionSizeDai * t.leverage > storageT.openInterestDai(t.pairIndex, 2)){

            t.positionSizeDai -= storageT.handleDevGovFees(
                t.pairIndex, 
                t.positionSizeDai * t.leverage, 
                true, 
                true
            );
            storageT.transferDai(address(storageT), t.trader, t.positionSizeDai);

            emit MarketCanceled(
                a.order,
                t.trader,
                t.pairIndex,
                o.wantedPrice,
                t.openPrice,
                o.slippageP
            );

        // 2. Register the trade (swap DAI pos to GFARM2)
        }else{
            t.index = storageT.firstEmptyTradeIndex(t.trader, t.pairIndex);
            t.tp = correctTp(t.openPrice, t.leverage, t.tp, t.buy);
            t.sl = correctSl(t.openPrice, t.leverage, t.sl, t.buy);

            registerTrade(
                t, 
                storageT.getReferral(t.trader), 
                address(0), 
                0
            );

            StorageInterfaceV5.Trade memory finalTrade = storageT.openTrades(t.trader, t.pairIndex, t.index);
            StorageInterfaceV5.TradeInfo memory finalTradeInfo = storageT.openTradesInfo(t.trader, t.pairIndex, t.index);
            emit MarketExecuted(
                a.order,
                finalTrade,
                true,
                finalTrade.openPrice,
                finalTrade.initialPosToken * finalTradeInfo.tokenPriceDai / PRECISION,
                0,
                finalTradeInfo.tokenPriceDai
            );

        }

        storageT.unregisterPendingMarketOrder(a.order, true);
    }

    // Called by oracle node to execute the close market order
    function closeTradeMarketCallback(AggregatorAnswer memory a) external onlyPriceAggregator notPaused{
        
        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(a.order);
        if(o.block == 0){ return; }

        uint PRECISION = storageT.PRECISION();
        StorageInterfaceV5.Trade memory t = storageT.openTrades(o.trade.trader, o.trade.pairIndex, o.trade.index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(o.trade.trader, o.trade.pairIndex, o.trade.index);

        uint posTokenDynamic = t.initialPosToken * i.tokenPriceDai / storageT.priceAggregator().tokenPriceDai();

        // 1. If market closed => simply take dev/gov fees and reduce position size token
        if(a.price == 0){

            uint feeToken = storageT.handleDevGovFees(
                t.pairIndex, 
                posTokenDynamic * t.leverage,
                false,
                true
            );

            if(t.initialPosToken > feeToken){
                t.initialPosToken -= feeToken;
                storageT.updateTrade(t);
            }else{
                storageT.unregisterTrade(t.trader, t.pairIndex, t.index);
            }

            emit TradeUpdatedMarketClosed(a.order, t.trader, t.pairIndex, t.index);

        // 2. If trade not already closed => close it
        }else if(t.leverage > 0){

            int percentProfit = currentPercentProfit(t.openPrice, a.price, t.buy, t.leverage);

            // 3. Send tokens back => mint/burn GFARM2 PnL & Pos
            handleTokensBack(
                t.trader,
                percentProfit,
                t.initialPosToken * i.tokenPriceDai / PRECISION,
                0,
                posTokenDynamic * t.leverage * storageT.priceAggregator().closeFeeP(t.pairIndex) / 100 / PRECISION
            );

            emit MarketExecuted(
                a.order,
                t,
                false,
                a.price,
                t.initialPosToken * i.tokenPriceDai / PRECISION,
                percentProfit,
                storageT.priceAggregator().tokenPriceDai()
            );

            storageT.unregisterTrade(t.trader, t.pairIndex, t.index);
        }

        storageT.unregisterPendingMarketOrder(a.order, false);
    }

    // Called by oracle node to execute open limit order
    function executeNftOpenOrderCallback(AggregatorAnswer memory a) external onlyPriceAggregator notPaused{

        StorageInterfaceV5.PendingNftOrder memory nftOrder = storageT.reqID_pendingNftOrder(a.order);
        if(nftOrder.trader == address(0)){ return; }

        // 1. If limit order not already triggered and nft not in timelock and market open
        if(storageT.hasOpenLimitOrder(nftOrder.trader, nftOrder.pairIndex, nftOrder.index)
        && block.number >= storageT.nftLastSuccess(nftOrder.nftId) + storageT.nftSuccessTimelock()
        && a.price != 0){

            StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
                nftOrder.trader, 
                nftOrder.pairIndex,
                nftOrder.index
            );

            uint PRECISION = storageT.PRECISION();

            a.spreadP -= a.spreadP * o.spreadReductionP / 100;
            a.price = o.buy ? a.price + a.price * a.spreadP / 100 / PRECISION 
                            : a.price - a.price * a.spreadP / 100 / PRECISION;

            o.tp = correctTp(a.price, o.leverage, o.tp, o.buy);
            o.sl = correctSl(a.price, o.leverage, o.sl, o.buy);

            // 2. If limit order can be triggered
            if(a.price >= o.minPrice && a.price <= o.maxPrice
            && storageT.openInterestDai(o.pairIndex, o.buy ? 0 : 1) + o.positionSize * o.leverage <= storageT.openInterestDai(o.pairIndex, 2)){
                uint index = storageT.firstEmptyTradeIndex(o.trader, o.pairIndex);

                // 3. Trigger it (swap DAI pos to GFARM2)
                registerTrade(
                    StorageInterfaceV5.Trade(
                        o.trader,
                        o.pairIndex,
                        index,
                        0,
                        o.positionSize,
                        a.price,
                        o.buy,
                        o.leverage,
                        o.tp,
                        o.sl
                    ), 
                    storageT.getReferral(o.trader), 
                    nftOrder.nftHolder,
                    nftOrder.nftId
                );

                storageT.unregisterOpenLimitOrder(o.trader, o.pairIndex, o.index);
                StorageInterfaceV5.Trade memory finalTrade = storageT.openTrades(o.trader, o.pairIndex, index);
                StorageInterfaceV5.TradeInfo memory finalTradeInfo = storageT.openTradesInfo(o.trader, o.pairIndex, index);

                emit LimitExecuted(
                    a.order,
                    nftOrder.index,
                    finalTrade,
                    finalTradeInfo,
                    nftOrder.nftHolder,
                    StorageInterfaceV5.LimitOrder.OPEN,
                    finalTrade.openPrice,
                    finalTrade.initialPosToken * finalTradeInfo.tokenPriceDai / PRECISION,
                    0,
                    finalTradeInfo.tokenPriceDai
                );
            }
        }
        storageT.unregisterPendingNftOrder(a.order);
    }

    // Called by oracle node to execute close limit order
    function executeNftCloseOrderCallback(AggregatorAnswer memory a) external onlyPriceAggregator notPaused{
        
        StorageInterfaceV5.PendingNftOrder memory o = storageT.reqID_pendingNftOrder(a.order);
        if(o.trader == address(0)){ return; }

        StorageInterfaceV5.Trade memory t = storageT.openTrades(o.trader, o.pairIndex, o.index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(o.trader, o.pairIndex, o.index);

        // 1. If trade still open and nft not in timelock and market open
        if(t.leverage > 0 && block.number >= storageT.nftLastSuccess(o.nftId) + storageT.nftSuccessTimelock()
        && a.price != 0){ 

            int percentProfit = currentPercentProfit(
                t.openPrice, 
                a.price, 
                t.buy, 
                t.leverage
            );
            uint posTokenDynamic = t.initialPosToken * i.tokenPriceDai / storageT.priceAggregator().tokenPriceDai();

            uint amountNftToken = 
                (o.orderType == StorageInterfaceV5.LimitOrder.TP && t.tp > 0 && t.buy && a.price >= t.tp)
             || (o.orderType == StorageInterfaceV5.LimitOrder.TP && t.tp > 0 && !t.buy && a.price <= t.tp)
             || (o.orderType == StorageInterfaceV5.LimitOrder.SL && t.sl > 0 && t.buy && a.price <= t.sl)
             || (o.orderType == StorageInterfaceV5.LimitOrder.SL && t.sl > 0 && !t.buy && a.price >= t.sl)
               ? storageT.priceAggregator().nftLimitOrderFeeP(t.pairIndex) * posTokenDynamic * t.leverage / 100 / storageT.PRECISION()
               : o.orderType == StorageInterfaceV5.LimitOrder.LIQ 
              && percentProfit <= int(LIQ_THRESHOLD*storageT.PRECISION()) * (-1) ? posTokenDynamic / 20 : 0;

            // 2. If limit order can be triggered
            if(amountNftToken > 0){

                storageT.handleTokens(o.nftHolder, amountNftToken, true); 
                storageT.increaseNftRewards(o.nftId, amountNftToken);

                // 3. Send tokens back => mint/burn GFARM2 & swap
                handleTokensBack(
                    t.trader,
                    percentProfit,
                    t.initialPosToken * i.tokenPriceDai / storageT.PRECISION(),
                    amountNftToken,
                    o.orderType == StorageInterfaceV5.LimitOrder.LIQ ? amountNftToken // Same rewards as NFT (5%)
                    : posTokenDynamic * t.leverage * storageT.priceAggregator().closeFeeP(t.pairIndex) / 100 / storageT.PRECISION()
                );
                    
                storageT.unregisterTrade(t.trader, t.pairIndex, t.index);

                emit LimitExecuted(
                    a.order,
                    o.index,
                    t,
                    i,
                    o.nftHolder,
                    o.orderType,
                    a.price,
                    t.initialPosToken * i.tokenPriceDai / storageT.PRECISION(),
                    percentProfit,
                    storageT.priceAggregator().tokenPriceDai()
                );
            }
        }

        storageT.unregisterPendingNftOrder(a.order);
    }

    // Trade opening & storing
    function registerTrade(
        StorageInterfaceV5.Trade memory _trade, 
        address _referral,
        address _nftHolder, 
        uint _nftId
    ) private{

        uint PRECISION = storageT.PRECISION();

        // 1. Take fee in DAI => fee DAI stays in storage
        _trade.positionSizeDai -= storageT.handleDevGovFees(
            _trade.pairIndex,
            _trade.positionSizeDai * _trade.leverage,
            true,
            true
        );

        // 2. Transfer position size in DAI - fees to the vault
        storageT.vault().receiveDaiFromTrader(
            _trade.trader, 
            _trade.positionSizeDai, 
            _trade.positionSizeDai * _trade.leverage * storageT.priceAggregator().closeFeeP(_trade.pairIndex) * vaultFeeP / 10000 / PRECISION
        );

        // 3. Position size
        uint tokenPriceDai = storageT.priceAggregator().tokenPriceDai();
        _trade.initialPosToken = _trade.positionSizeDai * storageT.PRECISION() / tokenPriceDai;
        _trade.positionSizeDai = 0;

        // 4. Distribute rewards to referral or burn them if no referral
        uint referralTokens = _trade.initialPosToken * _trade.leverage * storageT.priceAggregator().referralP(_trade.pairIndex) / PRECISION / 100;
        if(_referral != address(0)){ 
            referralTokens /= 2;
            storageT.handleTokens(_referral, referralTokens, true);
            storageT.increaseReferralRewards(_referral, referralTokens);
        }
        _trade.initialPosToken -= referralTokens;

        // 5. Distribute fees to NFT holder if relevant
        if(_nftHolder != address(0)){
            uint amountNftToken = _trade.initialPosToken * _trade.leverage * storageT.priceAggregator().nftLimitOrderFeeP(_trade.pairIndex) / 100 / PRECISION;
            storageT.handleTokens(_nftHolder, amountNftToken, true);
            storageT.increaseNftRewards(_nftId, amountNftToken);
            _trade.initialPosToken -= amountNftToken;
        }

        // 6. Store trade in storage
        storageT.storeTrade(
            _trade, 
            StorageInterfaceV5.TradeInfo(
                0, 
                tokenPriceDai, 
                _trade.initialPosToken*_trade.leverage*tokenPriceDai/PRECISION,
                0,
                0,
                false
            )
        );

        // 7. Unlock next leverage
        storageT.setLeverageUnlocked(
            _trade.trader, 
            storageT.getLeverageUnlocked(_trade.trader) == 0 ? 100 : 1000
        );
    }

    // Send tokens to trader & reward liquidity providers
    function handleTokensBack(
        address _trader,
        int _percentProfit,             // PRECISION
        uint _daiPos,                   // 1e18
        uint _amountNftToken,           // 1e18
        uint _lpFeeToken                // 1e18
    ) private{

        uint PRECISION = storageT.PRECISION();

        // 1. Reward LPs
        storageT.distributeLpRewards(_lpFeeToken * (100 - vaultFeeP) / 100);

        // 2. If trade cannot be liquidated
        if(_percentProfit > int(LIQ_THRESHOLD*PRECISION)*(-1)){

            // 3. Calculate PnL in DAI
            int pnlDai = _percentProfit * int(_daiPos) / 100 / int(PRECISION);

            // 4. Deduct LP fee, NFT fee, and Vault fee from PnL
            pnlDai -= int((_lpFeeToken + _amountNftToken) * storageT.priceAggregator().tokenPriceDai() / PRECISION);

            // 5. Send DAI from vault to trader
            storageT.vault().sendDaiToTrader(_trader, uint(int(_daiPos) + pnlDai));
        }
    }

    // Utils
    function currentPercentProfit(uint openPrice, uint currentPrice, bool buy, uint leverage) private view returns(int p){
        int PRECISION = int(storageT.PRECISION());
        int maxGainP = int(storageT.maxGainP());
        p = buy ? (int(currentPrice) - int(openPrice)) * 100 * PRECISION * int(leverage) / int(openPrice)
                : (int(openPrice) - int(currentPrice)) * 100 * PRECISION * int(leverage) / int(openPrice);
        p = p < PRECISION * (-100) ? PRECISION * (-100) : p;
        p = p > maxGainP * PRECISION ? maxGainP * PRECISION : p;
    }
    function correctTp(uint openPrice, uint leverage, uint tp, bool buy) private view returns(uint){
        if(tp == 0 || currentPercentProfit(openPrice, tp, buy, leverage) == int(storageT.maxGainP()*storageT.PRECISION())){
            uint tpDiff = openPrice*storageT.maxGainP()/leverage/1e2;
            if(buy){ return openPrice + tpDiff; }
            else if(tpDiff <= openPrice){ return openPrice - tpDiff; }
            else{
                return 0;
            }
        }
        return tp;
    }
    function correctSl(uint openPrice, uint leverage, uint sl, bool buy) private view returns(uint){
        if(sl > 0 && currentPercentProfit(openPrice, sl, buy, leverage) < int(storageT.maxSlP()*storageT.PRECISION()) * (-1)){
            uint slDiff = openPrice*storageT.maxSlP()/leverage/1e2;
            if(buy){ return openPrice - slDiff; }
            else{ return openPrice + slDiff; }
        }
        return sl;
    }
}