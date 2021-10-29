// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IPerpetualPoolOld.sol';
import '../interface/IPerpetualPool.sol';
import '../interface/IERC20.sol';
import '../interface/IOracle.sol';
import '../interface/IPToken.sol';
import '../interface/ILToken.sol';
import '../interface/IBTokenSwapper.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';
import '../library/DpmmPricerFutures.sol';

contract PerpetualPool is IPerpetualPool {

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    int256  constant ONE = 10**18;

    // decimals for bToken0 (settlement token), make this immutable to save gas
    uint256 immutable _decimals0;
    int256  immutable _minBToken0Ratio;
    int256  immutable _minPoolMarginRatio;
    int256  immutable _initialMarginRatio;
    int256  immutable _maintenanceMarginRatio;
    int256  immutable _minLiquidationReward;
    int256  immutable _maxLiquidationReward;
    int256  immutable _liquidationCutRatio;
    int256  immutable _protocolFeeCollectRatio;

    address immutable _lTokenAddress;
    address immutable _pTokenAddress;
    address immutable _routerAddress;
    address immutable _protocolFeeCollector;

    BTokenInfo[] _bTokens;   // bTokenId indexed
    SymbolInfo[] _symbols;   // symbolId indexed

    // funding period in seconds, funding collected for each volume during this period will be (dpmmPrice - indexPrice)
    int256 constant _fundingPeriod = 3 * 24 * 3600 * ONE;

    uint256 _lastTimestamp;
    int256  _protocolFeeAccrued;

    bool private _mutex;
    modifier _lock_() {
        require(!_mutex, 'reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    constructor (uint256[9] memory parameters, address[4] memory addresses) {
        _decimals0 = parameters[0];
        _minBToken0Ratio = int256(parameters[1]);
        _minPoolMarginRatio = int256(parameters[2]);
        _initialMarginRatio = int256(parameters[3]);
        _maintenanceMarginRatio = int256(parameters[4]);
        _minLiquidationReward = int256(parameters[5]);
        _maxLiquidationReward = int256(parameters[6]);
        _liquidationCutRatio = int256(parameters[7]);
        _protocolFeeCollectRatio = int256(parameters[8]);

        _lTokenAddress = addresses[0];
        _pTokenAddress = addresses[1];
        _routerAddress = addresses[2];
        _protocolFeeCollector = addresses[3];
    }

    function getParameters() external override view returns (
        uint256 decimals0,
        int256  minBToken0Ratio,
        int256  minPoolMarginRatio,
        int256  initialMarginRatio,
        int256  maintenanceMarginRatio,
        int256  minLiquidationReward,
        int256  maxLiquidationReward,
        int256  liquidationCutRatio,
        int256  protocolFeeCollectRatio
    ) {
        decimals0 = _decimals0;
        minBToken0Ratio = _minBToken0Ratio;
        minPoolMarginRatio = _minPoolMarginRatio;
        initialMarginRatio = _initialMarginRatio;
        maintenanceMarginRatio = _maintenanceMarginRatio;
        minLiquidationReward = _minLiquidationReward;
        maxLiquidationReward = _maxLiquidationReward;
        liquidationCutRatio = _liquidationCutRatio;
        protocolFeeCollectRatio = _protocolFeeCollectRatio;
    }

    function getAddresses() external override view returns (
        address lTokenAddress,
        address pTokenAddress,
        address routerAddress,
        address protocolFeeCollector
    ) {
        lTokenAddress = _lTokenAddress;
        pTokenAddress = _pTokenAddress;
        routerAddress = _routerAddress;
        protocolFeeCollector = _protocolFeeCollector;
    }

    function getLengths() external override view returns (uint256, uint256) {
        return (_bTokens.length, _symbols.length);
    }

    function getBToken(uint256 bTokenId) external override view returns (BTokenInfo memory) {
        return _bTokens[bTokenId];
    }

    function getSymbol(uint256 symbolId) external override view returns (SymbolInfo memory) {
        return _symbols[symbolId];
    }

    function getSymbolOracle(uint256 symbolId) external override view returns (address) {
        return _symbols[symbolId].oracleAddress;
    }

    function getPoolStateValues() external override view returns (uint256 lastTimestamp, int256 protocolFeeAccrued) {
        return (_lastTimestamp, _protocolFeeAccrued);
    }

    function collectProtocolFee() external override {
        IERC20 token = IERC20(_bTokens[0].bTokenAddress);
        uint256 amount = _protocolFeeAccrued.itou().rescale(18, _decimals0);
        // if (amount > token.balanceOf(address(this))) amount = token.balanceOf(address(this));
        _protocolFeeAccrued -= amount.rescale(_decimals0, 18).utoi();
        token.safeTransfer(_protocolFeeCollector, amount);
        emit ProtocolFeeCollection(_protocolFeeCollector, amount.rescale(_decimals0, 18));
    }

    function addBToken(BTokenInfo memory info) external override {
        _checkRouter();
        _addBToken(info);
        ILToken(_lTokenAddress).setNumBTokens(_bTokens.length);
        IPToken(_pTokenAddress).setNumBTokens(_bTokens.length);
    }

    function addSymbol(SymbolInfo memory info) external override {
        _checkRouter();
        _symbols.push(info);
        IPToken(_pTokenAddress).setNumSymbols(_symbols.length);
    }

    function setBTokenParameters(
        uint256 bTokenId,
        address swapperAddress,
        address oracleAddress,
        uint256 discount
    ) external override {
        _checkRouter();
        BTokenInfo storage b = _bTokens[bTokenId];
        b.swapperAddress = swapperAddress;
        if (bTokenId != 0) {
            IERC20(_bTokens[0].bTokenAddress).safeApprove(swapperAddress, 0);
            IERC20(_bTokens[bTokenId].bTokenAddress).safeApprove(swapperAddress, 0);
            IERC20(_bTokens[0].bTokenAddress).safeApprove(swapperAddress, type(uint256).max);
            IERC20(_bTokens[bTokenId].bTokenAddress).safeApprove(swapperAddress, type(uint256).max);
        }
        b.oracleAddress = oracleAddress;
        b.discount = discount.utoi();
    }

    function setSymbolParameters(
        uint256 symbolId,
        address oracleAddress,
        uint256 feeRatio,
        uint256 alpha
    ) external override {
        _checkRouter();
        SymbolInfo storage s = _symbols[symbolId];
        s.oracleAddress = oracleAddress;
        s.feeRatio = feeRatio.utoi();
        s.alpha = alpha.utoi();
    }


    //================================================================================
    // Migration, can only be called during migration process
    //================================================================================

    function approveBTokenForTargetPool(uint256 bTokenId, address targetPool) external override {
        _checkRouter();
        IERC20(_bTokens[bTokenId].bTokenAddress).safeApprove(targetPool, type(uint256).max);
    }

    function setPoolForLTokenAndPToken(address targetPool) external override {
        _checkRouter();
        ILToken(_lTokenAddress).setPool(targetPool);
        IPToken(_pTokenAddress).setPool(targetPool);
    }

    function migrateBToken(
        address sourcePool,
        uint256 balance,
        address bTokenAddress,
        address swapperAddress,
        address oracleAddress,
        uint256 decimals,
        int256  discount,
        int256  liquidity,
        int256  pnl,
        int256  cumulativePnl
    ) external override {
        _checkRouter();
        IERC20(bTokenAddress).safeTransferFrom(sourcePool, address(this), balance);
        BTokenInfo memory b;
        b.bTokenAddress = bTokenAddress;
        b.swapperAddress = swapperAddress;
        b.oracleAddress = oracleAddress;
        b.decimals = decimals;
        b.discount = discount;
        b.liquidity = liquidity;
        b.pnl = pnl;
        b.cumulativePnl = cumulativePnl;
        _addBToken(b);
    }

    function migrateSymbol(
        string memory symbol,
        address oracleAddress,
        int256  multiplier,
        int256  feeRatio,
        int256  alpha,
        int256  distributedUnrealizedPnl,
        int256  tradersNetVolume,
        int256  tradersNetCost,
        int256  cumulativeFundingRate
    ) external override {
        _checkRouter();
        SymbolInfo memory s;
        s.symbol = symbol;
        s.oracleAddress = oracleAddress;
        s.multiplier = multiplier;
        s.feeRatio = feeRatio;
        s.alpha = alpha;
        s.distributedUnrealizedPnl = distributedUnrealizedPnl;
        s.tradersNetVolume = tradersNetVolume;
        s.tradersNetCost = tradersNetCost;
        s.cumulativeFundingRate = cumulativeFundingRate;
        _symbols.push(s);
    }

    function migratePoolStateValues(uint256 lastTimestamp, int256 protocolFeeAccrued) external override {
        _checkRouter();
        _lastTimestamp = lastTimestamp;
        _protocolFeeAccrued = protocolFeeAccrued;
    }


    //================================================================================
    // Interactions
    //================================================================================

    function addLiquidity(address lp, uint256 bTokenId, uint256 bAmount) external override _lock_ {
        _checkRouter();
        Data memory data = _getBTokensAndSymbols(bTokenId, type(uint256).max);
        _distributePnlToBTokens(data);
        BTokenData memory b = data.bTokens[bTokenId];

        ILToken lToken = ILToken(_lTokenAddress);
        if(!lToken.exists(lp)) lToken.mint(lp);
        ILToken.Asset memory asset = lToken.getAsset(lp, bTokenId);

        bAmount = _transferIn(b.bTokenAddress, b.decimals, lp, bAmount);

        int256 deltaLiquidity = bAmount.utoi(); // lp's liquidity change amount for bTokenId
        int256 deltaEquity = deltaLiquidity * b.price / ONE * b.discount / ONE;
        b.equity += deltaEquity;
        data.totalEquity += deltaEquity;

        asset.pnl += (b.cumulativePnl - asset.lastCumulativePnl) * asset.liquidity / ONE; // lp's pnl as LP since last settlement
        if (bTokenId == 0) {
            deltaLiquidity += _accrueTail(asset.pnl);
            b.pnl -= asset.pnl; // this pnl comes from b.pnl, thus should be deducted
            asset.pnl = 0;
        }

        asset.liquidity += deltaLiquidity;
        asset.lastCumulativePnl = b.cumulativePnl;
        b.liquidity += deltaLiquidity;

        _updateBTokensAndSymbols(data);
        lToken.updateAsset(lp, bTokenId, asset);

        require(data.bTokens[0].equity * ONE >= data.totalEquity * _minBToken0Ratio, "insuf't b0");

        emit AddLiquidity(lp, bTokenId, bAmount);
    }

    function removeLiquidity(address lp, uint256 bTokenId, uint256 bAmount) external override _lock_ {
        _checkRouter();
        Data memory data = _getBTokensAndSymbols(bTokenId, type(uint256).max);
        BTokenData memory b = data.bTokens[bTokenId];

        ILToken lToken = ILToken(_lTokenAddress);
        ILToken.Asset memory asset = lToken.getAsset(lp, bTokenId);

        int256 amount = bAmount.utoi();
        if (amount > asset.liquidity) amount = asset.liquidity;

        // compensation caused by dpmmPrice change when removing liquidity
        int256 totalEquity = data.totalEquity + data.undistributedPnl - amount * b.price / ONE * b.discount / ONE;
        if (totalEquity > 0) {
            int256 compensation;
            for (uint256 i = 0; i < data.symbols.length; i++) {
                SymbolData memory s = data.symbols[i];
                if (s.active) {
                    int256 K = DpmmPricerFutures._calculateK(s.indexPrice, totalEquity, s.alpha);
                    int256 newPnl = -DpmmPricerFutures._calculateDpmmCost(s.indexPrice, K, s.tradersNetPosition, -s.tradersNetPosition) - s.tradersNetCost;
                    compensation += newPnl - s.pnl;
                }
            }
            asset.pnl -= compensation;
            b.pnl -= compensation;
            b.equity -= compensation;
            data.totalEquity -= compensation;
            data.undistributedPnl += compensation;
        }

        _distributePnlToBTokens(data);

        int256 deltaLiquidity;
        int256 pnl = (b.cumulativePnl - asset.lastCumulativePnl) * asset.liquidity / ONE;
        asset.pnl += pnl;
        if (bTokenId == 0) {
            deltaLiquidity = _accrueTail(asset.pnl);
            b.pnl -= asset.pnl;
            asset.pnl = 0;
        } else {
            if (asset.pnl < 0) {
                (uint256 amountB0, uint256 amountBX) = IBTokenSwapper(_bTokens[bTokenId].swapperAddress).swapBXForExactB0(
                    (-asset.pnl).ceil(_decimals0).itou(), asset.liquidity.itou(), b.price.itou()
                );
                (int256 b0, int256 bx) = (amountB0.utoi(), amountBX.utoi());
                deltaLiquidity = -bx;
                asset.pnl += b0;
                b.pnl += b0;
            } else if (asset.pnl > 0 && amount >= asset.liquidity) {
                (, uint256 amountBX) = IBTokenSwapper(_bTokens[bTokenId].swapperAddress).swapExactB0ForBX(
                    asset.pnl.itou(), b.price.itou()
                );
                deltaLiquidity = amountBX.utoi();
                b.pnl -= asset.pnl;
                _accrueTail(asset.pnl);
                asset.pnl = 0;
            }
        }

        asset.lastCumulativePnl = b.cumulativePnl;
        if (amount >= asset.liquidity || amount >= asset.liquidity + deltaLiquidity) {
            amount = asset.liquidity + deltaLiquidity;
            b.liquidity -= asset.liquidity;
            asset.liquidity = 0;
        } else {
            b.liquidity -= amount - deltaLiquidity;
            asset.liquidity -= amount - deltaLiquidity;
        }

        int256 deltaEquity = amount * b.price / ONE * b.discount / ONE;
        b.equity -= deltaEquity;
        data.totalEquity -= deltaEquity;

        _updateBTokensAndSymbols(data);
        lToken.updateAsset(lp, bTokenId, asset);

        require(data.totalEquity * ONE >= data.totalNotional * _minPoolMarginRatio, "insuf't liq");

        _transferOut(b.bTokenAddress, b.decimals, lp, amount.itou());
        emit RemoveLiquidity(lp, bTokenId, bAmount);
    }

    function addMargin(address trader, uint256 bTokenId, uint256 bAmount) external override _lock_ {
        _checkRouter();
        IPToken pToken = IPToken(_pTokenAddress);
        if (!pToken.exists(trader)) pToken.mint(trader);

        BTokenInfo storage bb = _bTokens[bTokenId];
        bAmount = _transferIn(bb.bTokenAddress, bb.decimals, trader, bAmount);

        int256 margin = pToken.getMargin(trader, bTokenId) + bAmount.utoi();

        pToken.updateMargin(trader, bTokenId, margin);
        emit AddMargin(trader, bTokenId, bAmount);
    }

    function removeMargin(address trader, uint256 bTokenId, uint256 bAmount) external override _lock_ {
        _checkRouter();
        Data memory data = _getBTokensAndSymbols(bTokenId, type(uint256).max);
        BTokenData memory b = data.bTokens[bTokenId];

        _distributePnlToBTokens(data);
        _getMarginsAndPositions(data, trader);
        _coverTraderDebt(data);

        int256 amount = bAmount.utoi();
        int256 margin = data.margins[bTokenId];
        if (amount >= margin) {
            if (bTokenId == 0) amount = _accrueTail(margin);
            bAmount = amount.itou();
            data.margins[bTokenId] = 0;
        } else {
            data.margins[bTokenId] -= amount;
        }
        b.marginUpdated = true;
        data.totalTraderEquity -= amount * b.price / ONE * b.discount / ONE;

        _updateBTokensAndSymbols(data);
        _updateMarginsAndPositions(data);

        require(data.totalTraderEquity * ONE >= data.totalTraderNontional * _initialMarginRatio, "insuf't margin");

        _transferOut(b.bTokenAddress, b.decimals, trader, bAmount);
        emit RemoveMargin(trader, bTokenId, bAmount);
    }

    function trade(address trader, uint256 symbolId, int256 tradeVolume) external override _lock_ {
        _checkRouter();
        Data memory data = _getBTokensAndSymbols(type(uint256).max, symbolId);
        _getMarginsAndPositions(data, trader);
        SymbolData memory s = data.symbols[symbolId];
        IPToken.Position memory p = data.positions[symbolId];

        tradeVolume = tradeVolume.reformat(0);
        require(tradeVolume != 0, '0 tradeVolume');

        int256 curCost = DpmmPricerFutures._calculateDpmmCost(
            s.indexPrice,
            s.K,
            s.tradersNetPosition,
            tradeVolume * s.multiplier / ONE
        );
        int256 fee = curCost.abs() * s.feeRatio / ONE;

        int256 realizedCost;
        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                realizedCost = curCost * absVolume / absTradeVolume + p.cost;
            } else {
                realizedCost = p.cost * absTradeVolume / absVolume + curCost;
            }
        }

        int256 preVolume = p.volume;
        p.volume += tradeVolume;
        p.cost += curCost - realizedCost;
        p.lastCumulativeFundingRate = s.cumulativeFundingRate;
        s.positionUpdated = true;

        data.margins[0] -= fee + realizedCost;

        int256 protocolFee = fee * _protocolFeeCollectRatio / ONE;
        _protocolFeeAccrued += protocolFee;
        data.undistributedPnl += fee - protocolFee;

        s.distributedUnrealizedPnl += realizedCost;
        _distributePnlToBTokens(data);

        s.tradersNetVolume += tradeVolume;
        s.tradersNetCost += curCost - realizedCost;

        data.totalTraderNontional += (p.volume.abs() - preVolume.abs()) * s.indexPrice / ONE * s.multiplier / ONE;
        data.totalNotional += s.tradersNetVolume.abs() * s.indexPrice / ONE * s.multiplier / ONE - s.notional;

        IPToken(_pTokenAddress).updatePosition(trader, symbolId, p);
        _updateBTokensAndSymbols(data);
        _updateMarginsAndPositions(data);

        require(data.totalEquity * ONE >= data.totalNotional * _minPoolMarginRatio, "insuf't liq");
        require(data.totalTraderEquity * ONE >= data.totalTraderNontional * _initialMarginRatio, "insuf't margin");

        emit Trade(trader, symbolId, s.indexPrice, tradeVolume, curCost, fee);
    }

    function liquidate(address liquidator, address trader) external override _lock_ {
        _checkRouter();
        Data memory data = _getBTokensAndSymbols(type(uint256).max, type(uint256).max);
        _getMarginsAndPositions(data, trader);

        require(data.totalTraderEquity * ONE < data.totalTraderNontional * _maintenanceMarginRatio, 'cant liq');

        int256 netEquity = data.margins[0];
        for (uint256 i = 1; i < data.bTokens.length; i++) {
            if (data.margins[i] > 0) {
                (uint256 amountB0, ) = IBTokenSwapper(_bTokens[i].swapperAddress).swapExactBXForB0(
                    data.margins[i].itou(), data.bTokens[i].price.itou()
                );
                netEquity += amountB0.utoi();
            }
        }

        for (uint256 i = 0; i < data.symbols.length; i++) {
            IPToken.Position memory p = data.positions[i];
            if (p.volume != 0) {
                SymbolData memory s = data.symbols[i];
                s.distributedUnrealizedPnl -= s.traderPnl;
                s.tradersNetVolume -= p.volume;
                s.tradersNetCost -= p.cost;
                emit Trade(trader, i, s.indexPrice, -p.volume, -p.cost - s.traderPnl, -1);
            }
        }
        netEquity += data.totalTraderPnl;

        int256 reward;
        if (netEquity <= _minLiquidationReward) {
            reward = _minLiquidationReward;
        } else {
            reward = ((netEquity - _minLiquidationReward) * _liquidationCutRatio / ONE + _minLiquidationReward).reformat(_decimals0);
            if (reward > _maxLiquidationReward) reward = _maxLiquidationReward;
        }

        data.undistributedPnl += netEquity - reward;
        _distributePnlToBTokens(data);

        IPToken(_pTokenAddress).burn(trader);
        _updateBTokensAndSymbols(data);

        _transferOut(_bTokens[0].bTokenAddress, _decimals0, liquidator, reward.itou());
        emit Liquidate(trader, liquidator, reward.itou());
    }


    //================================================================================
    // Helpers
    //================================================================================

    function _addBToken(BTokenInfo memory info) internal {
        if (_bTokens.length > 0) {
            // approve for non bToken0 swappers
            IERC20(_bTokens[0].bTokenAddress).safeApprove(info.swapperAddress, type(uint256).max);
            IERC20(info.bTokenAddress).safeApprove(info.swapperAddress, type(uint256).max);
        } else {
            require(info.decimals == _decimals0, 'wrong dec');
        }
        _bTokens.push(info);
    }

    function _checkRouter() internal view {
        require(msg.sender == _routerAddress, 'router only');
    }

    struct BTokenData {
        address bTokenAddress;
        uint256 decimals;
        int256  discount;
        int256  liquidity;
        int256  pnl;
        int256  cumulativePnl;
        int256  price;
        int256  equity;
        // trader
        bool    marginUpdated;
    }

    struct SymbolData {
        bool    active;
        int256  multiplier;
        int256  feeRatio;
        int256  alpha;
        int256  K;
        int256  indexPrice;
        int256  dpmmPrice;
        int256  distributedUnrealizedPnl;
        int256  tradersNetVolume;
        int256  tradersNetCost;
        int256  cumulativeFundingRate;
        int256  tradersNetPosition; // tradersNetVolume * multiplier / ONE
        int256  notional;
        int256  pnl;
        // trader
        bool    positionUpdated;
        int256  traderPnl;
    }

    struct Data {
        BTokenData[] bTokens;
        SymbolData[] symbols;
        uint256 preTimestamp;
        uint256 curTimestamp;
        int256  totalEquity;
        int256  totalNotional;
        int256  undistributedPnl;

        address trader;
        int256[] margins;
        IPToken.Position[] positions;
        int256 totalTraderPnl;
        int256 totalTraderNontional;
        int256 totalTraderEquity;
    }

    function _getBTokensAndSymbols(uint256 bTokenId, uint256 symbolId) internal returns (Data memory data) {
        data.preTimestamp = _lastTimestamp;
        data.curTimestamp = block.timestamp;

        data.bTokens = new BTokenData[](_bTokens.length);
        for (uint256 i = 0; i < data.bTokens.length; i++) {
            BTokenData memory b = data.bTokens[i];
            BTokenInfo storage bb = _bTokens[i];
            b.liquidity = bb.liquidity;
            if (i == bTokenId) {
                b.bTokenAddress = bb.bTokenAddress;
                b.decimals = bb.decimals;
            }
            b.discount = bb.discount;
            b.pnl = bb.pnl;
            b.cumulativePnl = bb.cumulativePnl;
            b.price = i == 0 ? ONE : IOracle(bb.oracleAddress).getPrice().utoi();
            b.equity = b.liquidity * b.price / ONE * b.discount / ONE + b.pnl;
            data.totalEquity += b.equity;
        }

        data.symbols = new SymbolData[](_symbols.length);
        int256 fundingPeriod = _fundingPeriod;
        for (uint256 i = 0; i < data.symbols.length; i++) {
            SymbolData memory s = data.symbols[i];
            SymbolInfo storage ss = _symbols[i];
            s.tradersNetVolume = ss.tradersNetVolume;
            s.tradersNetCost = ss.tradersNetCost;
            if (i == symbolId || s.tradersNetVolume != 0 || s.tradersNetCost != 0) {
                s.active = true;
                s.multiplier = ss.multiplier;
                s.feeRatio = ss.feeRatio;
                s.alpha = ss.alpha;
                s.indexPrice = IOracle(ss.oracleAddress).getPrice().utoi();
                s.K = DpmmPricerFutures._calculateK(s.indexPrice, data.totalEquity, s.alpha);
                s.dpmmPrice = DpmmPricerFutures._calculateDpmmPrice(s.indexPrice, s.K, s.tradersNetVolume * s.multiplier / ONE);
                s.distributedUnrealizedPnl = ss.distributedUnrealizedPnl;
                s.cumulativeFundingRate = ss.cumulativeFundingRate;

                s.tradersNetPosition = s.tradersNetVolume * s.multiplier / ONE;
                s.notional = (s.tradersNetPosition * s.indexPrice / ONE).abs();
                data.totalNotional += s.notional;
                s.pnl = -DpmmPricerFutures._calculateDpmmCost(s.indexPrice, s.K, s.tradersNetPosition, -s.tradersNetPosition) - s.tradersNetCost;
                data.undistributedPnl -= s.pnl - s.distributedUnrealizedPnl;
                s.distributedUnrealizedPnl = s.pnl;

                if (data.curTimestamp > data.preTimestamp) {
                    int256 ratePerSecond = (s.dpmmPrice - s.indexPrice) * s.multiplier / fundingPeriod;
                    int256 diff = ratePerSecond * int256(data.curTimestamp - data.preTimestamp);
                    data.undistributedPnl += s.tradersNetVolume * diff / ONE;
                    unchecked { s.cumulativeFundingRate += diff; }
                }
            }
        }
    }

    function _updateBTokensAndSymbols(Data memory data) internal {
        _lastTimestamp = data.curTimestamp;

        for (uint256 i = 0; i < data.bTokens.length; i++) {
            BTokenData memory b = data.bTokens[i];
            BTokenInfo storage bb = _bTokens[i];
            bb.liquidity = b.liquidity;
            bb.pnl = b.pnl;
            bb.cumulativePnl = b.cumulativePnl;
        }

        for (uint256 i = 0; i < data.symbols.length; i++) {
            SymbolData memory s = data.symbols[i];
            SymbolInfo storage ss = _symbols[i];
            if (s.active) {
                ss.distributedUnrealizedPnl = s.distributedUnrealizedPnl;
                ss.tradersNetVolume = s.tradersNetVolume;
                ss.tradersNetCost = s.tradersNetCost;
                ss.cumulativeFundingRate = s.cumulativeFundingRate;
            }
        }
    }

    function _distributePnlToBTokens(Data memory data) internal pure {
        if (data.undistributedPnl != 0 && data.totalEquity > 0) {
            for (uint256 i = 0; i < data.bTokens.length; i++) {
                BTokenData memory b = data.bTokens[i];
                if (b.liquidity > 0) {
                    int256 pnl = data.undistributedPnl * b.equity / data.totalEquity;
                    b.pnl += pnl;
                    b.cumulativePnl += pnl * ONE / b.liquidity;
                    b.equity += pnl;
                }
            }
            data.totalEquity += data.undistributedPnl;
            data.undistributedPnl = 0;
        }
    }

    function _getMarginsAndPositions(Data memory data, address trader) internal view {
        data.trader = trader;
        IPToken pToken = IPToken(_pTokenAddress);
        data.margins = pToken.getMargins(trader);
        data.positions = pToken.getPositions(trader);

        data.bTokens[0].marginUpdated = true;

        for (uint256 i = 0; i < data.symbols.length; i++) {
            IPToken.Position memory p = data.positions[i];
            if (p.volume != 0) {
                SymbolData memory s = data.symbols[i];

                int256 diff;
                unchecked { diff = s.cumulativeFundingRate - p.lastCumulativeFundingRate; }
                data.margins[0] -= p.volume * diff / ONE;
                p.lastCumulativeFundingRate = s.cumulativeFundingRate;
                s.positionUpdated = true;

                data.totalTraderNontional += (p.volume * s.indexPrice / ONE * s.multiplier / ONE).abs();
                s.traderPnl = -DpmmPricerFutures._calculateDpmmCost(s.indexPrice, s.K, s.tradersNetPosition, -p.volume * s.multiplier / ONE) - p.cost;
                data.totalTraderPnl += s.traderPnl;
            }
        }

        data.totalTraderEquity = data.totalTraderPnl + data.margins[0];
        for (uint256 i = 1; i < data.bTokens.length; i++) {
            if (data.margins[i] != 0) {
                data.totalTraderEquity += data.margins[i] * data.bTokens[i].price / ONE * data.bTokens[i].discount / ONE;
            }
        }
    }

    function _coverTraderDebt(Data memory data) internal {
        int256[] memory margins = data.margins;
        if (margins[0] < 0) {
            uint256 amountB0;
            uint256 amountBX;
            for (uint256 i = margins.length - 1; i > 0; i--) {
                if (margins[i] > 0) {
                    (amountB0, amountBX) = IBTokenSwapper(_bTokens[i].swapperAddress).swapBXForExactB0(
                        (-margins[0]).ceil(_decimals0).itou(), margins[i].itou(), data.bTokens[i].price.itou()
                    );
                    (int256 b0, int256 bx) = (amountB0.utoi(), amountBX.utoi());
                    margins[0] += b0;
                    margins[i] -= bx;
                    data.totalTraderEquity += b0 - bx * data.bTokens[i].price / ONE * data.bTokens[i].discount / ONE;
                    data.bTokens[i].marginUpdated = true;
                }
                if (margins[0] >= 0) break;
            }
        }
    }

    function _updateMarginsAndPositions(Data memory data) internal {
        IPToken pToken = IPToken(_pTokenAddress);
        for (uint256 i = 0; i < data.margins.length; i++) {
            if (data.bTokens[i].marginUpdated) {
                pToken.updateMargin(data.trader, i, data.margins[i]);
            }
        }
        for (uint256 i = 0; i < data.positions.length; i++) {
            if (data.symbols[i].positionUpdated) {
                pToken.updatePosition(data.trader, i, data.positions[i]);
            }
        }
    }

    function _transferIn(address bTokenAddress, uint256 decimals, address from, uint256 bAmount) internal returns (uint256) {
        bAmount = bAmount.rescale(18, decimals);
        require(bAmount > 0, '0 bAmount');

        IERC20 bToken = IERC20(bTokenAddress);
        uint256 balance1 = bToken.balanceOf(address(this));
        bToken.safeTransferFrom(from, address(this), bAmount);
        uint256 balance2 = bToken.balanceOf(address(this));

        return (balance2 - balance1).rescale(decimals, 18);
    }

    function _transferOut(address bTokenAddress, uint256 decimals, address to, uint256 bAmount) internal {
        bAmount = bAmount.rescale(18, decimals);
        IERC20(bTokenAddress).safeTransfer(to, bAmount);
    }

    function _accrueTail(int256 amount) internal returns (int256) {
        int256 head = amount.reformat(_decimals0);
        if (head == amount) return head;
        if (head > amount) head -= int256(10**(18 - _decimals0));
        _protocolFeeAccrued += amount - head;
        return head;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IPerpetualPoolOld {

    struct BTokenInfo {
        address bTokenAddress;
        address swapperAddress;
        address oracleAddress;
        uint256 decimals;
        int256  discount;
        int256  price;
        int256  liquidity;
        int256  pnl;
        int256  cumulativePnl;
    }

    struct SymbolInfo {
        string  symbol;
        address oracleAddress;
        int256  multiplier;
        int256  feeRatio;
        int256  fundingRateCoefficient;
        int256  price;
        int256  cumulativeFundingRate;
        int256  tradersNetVolume;
        int256  tradersNetCost;
    }

    event AddLiquidity(address indexed owner, uint256 indexed bTokenId, uint256 bAmount);

    event RemoveLiquidity(address indexed owner, uint256 indexed bTokenId, uint256 bAmount);

    event AddMargin(address indexed owner, uint256 indexed bTokenId, uint256 bAmount);

    event RemoveMargin(address indexed owner, uint256 indexed bTokenId, uint256 bAmount);

    event Trade(address indexed owner, uint256 indexed symbolId, int256 tradeVolume, uint256 price);

    event Liquidate(address indexed owner, address indexed liquidator, uint256 reward);

    event ProtocolFeeCollection(address indexed collector, uint256 amount);

    function getParameters() external view returns (
        uint256 decimals0,
        int256  minBToken0Ratio,
        int256  minPoolMarginRatio,
        int256  minInitialMarginRatio,
        int256  minMaintenanceMarginRatio,
        int256  minLiquidationReward,
        int256  maxLiquidationReward,
        int256  liquidationCutRatio,
        int256  protocolFeeCollectRatio
    );

    function getAddresses() external view returns (
        address lTokenAddress,
        address pTokenAddress,
        address routerAddress,
        address protocolFeeCollector
    );

    function getLengths() external view returns (uint256, uint256);

    function getBToken(uint256 bTokenId) external view returns (BTokenInfo memory);

    function getSymbol(uint256 symbolId) external view returns (SymbolInfo memory);

    function getBTokenOracle(uint256 bTokenId) external view returns (address);

    function getSymbolOracle(uint256 symbolId) external view returns (address);

    function getLastUpdateBlock() external view returns (uint256);

    function getProtocolFeeAccrued() external view returns (int256);

    function collectProtocolFee() external;

    function addBToken(BTokenInfo memory info) external;

    function addSymbol(SymbolInfo memory info) external;

    function setBTokenParameters(uint256 bTokenId, address swapperAddress, address oracleAddress, uint256 discount) external;

    function setSymbolParameters(uint256 symbolId, address oracleAddress, uint256 feeRatio, uint256 fundingRateCoefficient) external;

    function approvePoolMigration(address targetPool) external;

    function executePoolMigration(address sourcePool) external;

    function addLiquidity(address owner, uint256 bTokenId, uint256 bAmount, uint256 blength, uint256 slength) external;

    function removeLiquidity(address owner, uint256 bTokenId, uint256 bAmount, uint256 blength, uint256 slength) external;

    function addMargin(address owner, uint256 bTokenId, uint256 bAmount) external;

    function removeMargin(address owner, uint256 bTokenId, uint256 bAmount, uint256 blength, uint256 slength) external;

    function trade(address owner, uint256 symbolId, int256 tradeVolume, uint256 blength, uint256 slength) external;

    function liquidate(address liquidator, address owner, uint256 blength, uint256 slength) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IPerpetualPool {

    struct BTokenInfo {
        address bTokenAddress;
        address swapperAddress;
        address oracleAddress;
        uint256 decimals;
        int256  discount;
        int256  liquidity;
        int256  pnl;
        int256  cumulativePnl;
    }

    struct SymbolInfo {
        string  symbol;
        address oracleAddress;
        int256  multiplier;
        int256  feeRatio;
        int256  alpha;
        int256  distributedUnrealizedPnl;
        int256  tradersNetVolume;
        int256  tradersNetCost;
        int256  cumulativeFundingRate;
    }

    event AddLiquidity(address indexed lp, uint256 indexed bTokenId, uint256 bAmount);

    event RemoveLiquidity(address indexed lp, uint256 indexed bTokenId, uint256 bAmount);

    event AddMargin(address indexed trader, uint256 indexed bTokenId, uint256 bAmount);

    event RemoveMargin(address indexed trader, uint256 indexed bTokenId, uint256 bAmount);

    event Trade(
        address indexed trader,
        uint256 indexed symbolId,
        int256 indexPrice,
        int256 tradeVolume,
        int256 tradeCost,
        int256 tradeFee // a -1 tradeFee corresponds to a liquidation trade
    );

    event Liquidate(address indexed trader, address indexed liquidator, uint256 reward);

    event ProtocolFeeCollection(address indexed collector, uint256 amount);

    function getParameters() external view returns (
        uint256 decimals0,
        int256  minBToken0Ratio,
        int256  minPoolMarginRatio,
        int256  initialMarginRatio,
        int256  maintenanceMarginRatio,
        int256  minLiquidationReward,
        int256  maxLiquidationReward,
        int256  liquidationCutRatio,
        int256  protocolFeeCollectRatio
    );

    function getAddresses() external view returns (
        address lTokenAddress,
        address pTokenAddress,
        address routerAddress,
        address protocolFeeCollector
    );

    function getLengths() external view returns (uint256, uint256);

    function getBToken(uint256 bTokenId) external view returns (BTokenInfo memory);

    function getSymbol(uint256 symbolId) external view returns (SymbolInfo memory);

    function getSymbolOracle(uint256 symbolId) external view returns (address);

    function getPoolStateValues() external view returns (uint256 lastTimestamp, int256 protocolFeeAccrued);

    function collectProtocolFee() external;

    function addBToken(BTokenInfo memory info) external;

    function addSymbol(SymbolInfo memory info) external;

    function setBTokenParameters(
        uint256 bTokenId,
        address swapperAddress,
        address oracleAddress,
        uint256 discount
    ) external;

    function setSymbolParameters(
        uint256 symbolId,
        address oracleAddress,
        uint256 feeRatio,
        uint256 alpha
    ) external;

    function approveBTokenForTargetPool(uint256 bTokenId, address targetPool) external;

    function setPoolForLTokenAndPToken(address targetPool) external;

    function migrateBToken(
        address sourcePool,
        uint256 balance,
        address bTokenAddress,
        address swapperAddress,
        address oracleAddress,
        uint256 decimals,
        int256  discount,
        int256  liquidity,
        int256  pnl,
        int256  cumulativePnl
    ) external;

    function migrateSymbol(
        string memory symbol,
        address oracleAddress,
        int256  multiplier,
        int256  feeRatio,
        int256  alpha,
        int256  dpmmPrice,
        int256  tradersNetVolume,
        int256  tradersNetCost,
        int256  cumulativeFundingRate
    ) external;

    function migratePoolStateValues(uint256 lastTimestamp, int256 protocolFeeAccrued) external;

    function addLiquidity(address lp, uint256 bTokenId, uint256 bAmount) external;

    function removeLiquidity(address lp, uint256 bTokenId, uint256 bAmount) external;

    function addMargin(address trader, uint256 bTokenId, uint256 bAmount) external;

    function removeMargin(address trader, uint256 bTokenId, uint256 bAmount) external;

    function trade(address trader, uint256 symbolId, int256 tradeVolume) external;

    function liquidate(address liquidator, address trader) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOracle {

    function getPrice() external returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721.sol';

interface IPToken is IERC721 {

    struct Position {
        // position volume, long is positive and short is negative
        int256 volume;
        // the cost the establish this position
        int256 cost;
        // the last cumulativeFundingRate since last funding settlement for this position
        // the overflow for this value in intended
        int256 lastCumulativeFundingRate;
    }

    event UpdateMargin(address indexed owner, uint256 indexed bTokenId, int256 amount);

    event UpdatePosition(address indexed owner, uint256 indexed symbolId, int256 volume, int256 cost, int256 lastCumulativeFundingRate);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function pool() external view returns (address);

    function totalMinted() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function numBTokens() external view returns (uint256);

    function numSymbols() external view returns (uint256);

    function setPool(address newPool) external;

    function setNumBTokens(uint256 num) external;

    function setNumSymbols(uint256 num) external;

    function exists(address owner) external view returns (bool);

    function getMargin(address owner, uint256 bTokenId) external view returns (int256);

    function getMargins(address owner) external view returns (int256[] memory);

    function getPosition(address owner, uint256 symbolId) external view returns (Position memory);

    function getPositions(address owner) external view returns (Position[] memory);

    function updateMargin(address owner, uint256 bTokenId, int256 amount) external;

    function updateMargins(address owner, int256[] memory margins) external;

    function updatePosition(address owner, uint256 symbolId, Position memory position) external;

    function mint(address owner) external;

    function burn(address owner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721.sol';

interface ILToken is IERC721 {

    struct Asset {
        // amount of base token lp provided, i.e. WETH
        // this will be used as the weight to distribute future pnls
        int256 liquidity;
        // lp's pnl in bToken0
        int256 pnl;
        // snapshot of cumulativePnl for lp at last settlement point (add/remove liquidity), in bToken0, i.e. USDT
        int256 lastCumulativePnl;
    }

    event UpdateAsset(
        address owner,
        uint256 bTokenId,
        int256  liquidity,
        int256  pnl,
        int256  lastCumulativePnl
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function pool() external view returns (address);

    function totalMinted() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function numBTokens() external view returns (uint256);

    function setPool(address newPool) external;

    function setNumBTokens(uint256 num) external;

    function exists(address owner) external view returns (bool);

    function getAsset(address owner, uint256 bTokenId) external view returns (Asset memory);

    function getAssets(address owner) external view returns (Asset[] memory);

    function updateAsset(address owner, uint256 bTokenId, Asset memory asset) external;

    function mint(address owner) external;

    function burn(address owner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IBTokenSwapper {

    function swapExactB0ForBX(uint256 amountB0, uint256 referencePrice) external returns (uint256 resultB0, uint256 resultBX);

    function swapExactBXForB0(uint256 amountBX, uint256 referencePrice) external returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactBX(uint256 amountB0, uint256 amountBX, uint256 referencePrice) external returns (uint256 resultB0, uint256 resultBX);

    function swapBXForExactB0(uint256 amountB0, uint256 amountBX, uint256 referencePrice) external returns (uint256 resultB0, uint256 resultBX);

    function getLimitBX() external view returns (uint256);

    function sync() external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2**255 - 1;
    int256  constant IMIN = -2**255;

    /// convert uint256 to int256
    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'UIO');
        return int256(a);
    }

    /// convert int256 to uint256
    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'IUO');
        return uint256(a);
    }

    /// take abs of int256
    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'AO');
        return a >= 0 ? a : -a;
    }


    /// rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * (10 ** decimals2) / (10 ** decimals1);
    }

    /// rescale a int256 from base 10**decimals1 to 10**decimals2
    function rescale(int256 a, uint256 decimals1, uint256 decimals2) internal pure returns (int256) {
        return decimals1 == decimals2 ? a : a * utoi(10 ** decimals2) / utoi(10 ** decimals1);
    }

    /// reformat a uint256 to be a valid 10**decimals base value
    /// the reformatted value is still in 10**18 base
    function reformat(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return decimals == 18 ? a : rescale(rescale(a, 18, decimals), decimals, 18);
    }

    /// reformat a int256 to be a valid 10**decimals base value
    /// the reformatted value is still in 10**18 base
    function reformat(int256 a, uint256 decimals) internal pure returns (int256) {
        return decimals == 18 ? a : rescale(rescale(a, 18, decimals), decimals, 18);
    }

    /// ceiling value away from zero, return a valid 10**decimals base value, but still in 10**18 based
    function ceil(int256 a, uint256 decimals) internal pure returns (int256) {
        if (reformat(a, decimals) == a) {
            return a;
        } else {
            int256 b = rescale(a, 18, decimals);
            b += a > 0 ? int256(1) : int256(-1);
            return rescale(b, decimals, 18);
        }
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../interface/IERC20.sol";
import "./Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library DpmmPricerFutures {

    int256 constant ONE = 1e18;

    function _calculateK(int256 indexPrice, int256 liquidity, int256 alpha) internal pure returns (int256) {
        return indexPrice * alpha / liquidity;
    }

    function _calculateDpmmPrice(int256 indexPrice, int256 K, int256 tradersNetPosition) internal pure returns (int256) {
        return indexPrice * (ONE + K * tradersNetPosition / ONE) / ONE;
    }

    function _calculateDpmmCost(int256 indexPrice, int256 K, int256 tradersNetPosition, int256 tradePosition) internal pure returns (int256) {
        int256 r = ((tradersNetPosition + tradePosition) ** 2 - tradersNetPosition ** 2) / ONE * K / ONE / 2 + tradePosition;
        return indexPrice * r / ONE;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `operator` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the 'tokenId' owned by 'owner'
     *
     * Requirements:
     *
     *  - `owner` must exist
     */
    function getTokenId(address owner) external view returns (uint256);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Gives permission to `operator` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address
     * clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address operator, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     *   by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first
     * that contract recipients are aware of the ERC721 protocol to prevent
     * tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token
     *   by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     *   by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

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