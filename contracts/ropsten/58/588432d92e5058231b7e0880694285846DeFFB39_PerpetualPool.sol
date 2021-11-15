// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IERC20.sol';
import '../interface/IOracle.sol';
import '../interface/IBTokenSwapper.sol';
import '../interface/IPToken.sol';
import '../interface/ILToken.sol';
import '../interface/IPerpetualPool.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';

/*
Revert Code:

reentry         : reentry is blocked
router only     : can only called by router
wrong dec       : wrong bToken decimals
insuf't b0      : pool insufficient bToken0
insuf't liq     : pool insufficient liquidity
insuf't margin  : trader insufficient margin
cant liquidate  : cannot liquidate trader
*/

contract PerpetualPool is IPerpetualPool {

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    int256  constant ONE = 10**18;

    // decimals for bToken0 (settlement token), make this immutable to save gas
    uint256 immutable _decimals0;
    int256  immutable _minBToken0Ratio;
    int256  immutable _minPoolMarginRatio;
    int256  immutable _minInitialMarginRatio;
    int256  immutable _minMaintenanceMarginRatio;
    int256  immutable _minLiquidationReward;
    int256  immutable _maxLiquidationReward;
    int256  immutable _liquidationCutRatio;
    int256  immutable _protocolFeeCollectRatio;

    address immutable _lTokenAddress;
    address immutable _pTokenAddress;
    address immutable _routerAddress;
    address immutable _protocolFeeCollector;

    uint256 _lastUpdateBlock;
    int256  _protocolFeeAccrued;

    BTokenInfo[] _bTokens;   // bTokenId indexed
    SymbolInfo[] _symbols;   // symbolId indexed

    bool private _mutex;
    modifier _lock_() {
        require(!_mutex, 'reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _router_() {
        require(msg.sender == _routerAddress, 'router only');
        _;
    }

    constructor (uint256[9] memory parameters, address[4] memory addresses) {
        _decimals0 = parameters[0];
        _minBToken0Ratio = int256(parameters[1]);
        _minPoolMarginRatio = int256(parameters[2]);
        _minInitialMarginRatio = int256(parameters[3]);
        _minMaintenanceMarginRatio = int256(parameters[4]);
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
        int256  minInitialMarginRatio,
        int256  minMaintenanceMarginRatio,
        int256  minLiquidationReward,
        int256  maxLiquidationReward,
        int256  liquidationCutRatio,
        int256  protocolFeeCollectRatio
    ) {
        decimals0 = _decimals0;
        minBToken0Ratio = _minBToken0Ratio;
        minPoolMarginRatio = _minPoolMarginRatio;
        minInitialMarginRatio = _minInitialMarginRatio;
        minMaintenanceMarginRatio = _minMaintenanceMarginRatio;
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

    function getBTokenOracle(uint256 bTokenId) external override view returns (address) {
        return _bTokens[bTokenId].oracleAddress;
    }

    function getSymbolOracle(uint256 symbolId) external override view returns (address) {
        return _symbols[symbolId].oracleAddress;
    }

    function getLastUpdateBlock() external override view returns (uint256) {
        return _lastUpdateBlock;
    }

    function getProtocolFeeAccrued() external override view returns (int256) {
        return _protocolFeeAccrued;
    }

    function collectProtocolFee() external override {
        IERC20 token = IERC20(_bTokens[0].bTokenAddress);
        uint256 amount = _protocolFeeAccrued.itou().rescale(18, _decimals0);
        if (amount > token.balanceOf(address(this))) amount = token.balanceOf(address(this));
        _protocolFeeAccrued -= amount.rescale(_decimals0, 18).utoi();
        token.safeTransfer(_protocolFeeCollector, amount);
        emit ProtocolFeeCollection(_protocolFeeCollector, amount.rescale(_decimals0, 18));
    }

    function addBToken(BTokenInfo memory info) external override _router_ {
        if (_bTokens.length > 0) {
            // approve for non bToken0 swappers
            IERC20(_bTokens[0].bTokenAddress).safeApprove(info.swapperAddress, type(uint256).max);
            IERC20(info.bTokenAddress).safeApprove(info.swapperAddress, type(uint256).max);
            info.price = IOracle(info.oracleAddress).getPrice().utoi();
        } else {
            require(info.decimals == _decimals0, 'wrong dec');
            info.price = ONE;
        }
        _bTokens.push(info);
        ILToken(_lTokenAddress).setNumBTokens(_bTokens.length);
        IPToken(_pTokenAddress).setNumBTokens(_bTokens.length);
    }

    function addSymbol(SymbolInfo memory info) external override _router_ {
        _symbols.push(info);
        IPToken(_pTokenAddress).setNumSymbols(_symbols.length);
    }

    function setBTokenParameters(uint256 bTokenId, address swapperAddress, address oracleAddress, uint256 discount) external override _router_ {
        BTokenInfo storage b = _bTokens[bTokenId];
        b.swapperAddress = swapperAddress;
        if (bTokenId != 0) {
            IERC20(_bTokens[0].bTokenAddress).safeApprove(swapperAddress, 0);
            IERC20(_bTokens[bTokenId].bTokenAddress).safeApprove(swapperAddress, 0);
            IERC20(_bTokens[0].bTokenAddress).safeApprove(swapperAddress, type(uint256).max);
            IERC20(_bTokens[bTokenId].bTokenAddress).safeApprove(swapperAddress, type(uint256).max);
        }
        b.oracleAddress = oracleAddress;
        b.discount = int256(discount);
    }

    function setSymbolParameters(uint256 symbolId, address oracleAddress, uint256 feeRatio, uint256 fundingRateCoefficient) external override _router_ {
        SymbolInfo storage s = _symbols[symbolId];
        s.oracleAddress = oracleAddress;
        s.feeRatio = int256(feeRatio);
        s.fundingRateCoefficient = int256(fundingRateCoefficient);
    }

    // during a migration, this function is intended to be called in the source pool
    function approvePoolMigration(address targetPool) external override _router_ {
        for (uint256 i = 0; i < _bTokens.length; i++) {
            IERC20(_bTokens[i].bTokenAddress).safeApprove(targetPool, type(uint256).max);
        }
        ILToken(_lTokenAddress).setPool(targetPool);
        IPToken(_pTokenAddress).setPool(targetPool);
    }

    // during a migration, this function is intended to be called in the target pool
    function executePoolMigration(address sourcePool) external override _router_ {
        // (uint256 blength, uint256 slength) = IPerpetualPool(sourcePool).getLengths();
        // for (uint256 i = 0; i < blength; i++) {
        //     BTokenInfo memory b = IPerpetualPool(sourcePool).getBToken(i);
        //     IERC20(b.bTokenAddress).safeTransferFrom(sourcePool, address(this), IERC20(b.bTokenAddress).balanceOf(sourcePool));
        //     _bTokens.push(b);
        // }
        // for (uint256 i = 0; i < slength; i++) {
        //     _symbols.push(IPerpetualPool(sourcePool).getSymbol(i));
        // }
        // _protocolFeeAccrued = IPerpetualPool(sourcePool).getProtocolFeeAccrued();
    }


    //================================================================================
    // Core Logics
    //================================================================================

    function addLiquidity(address owner, uint256 bTokenId, uint256 bAmount, uint256 blength, uint256 slength) external override _router_ _lock_ {
        ILToken lToken = ILToken(_lTokenAddress);
        if(!lToken.exists(owner)) lToken.mint(owner);

        _updateBTokenPrice(bTokenId);
        _updatePricesAndDistributePnl(blength, slength);

        BTokenInfo storage b = _bTokens[bTokenId];
        bAmount = _deflationCompatibleSafeTransferFrom(b.bTokenAddress, b.decimals, owner, address(this), bAmount);

        int256 cumulativePnl = b.cumulativePnl;
        ILToken.Asset memory asset = lToken.getAsset(owner, bTokenId);

        int256 delta; // owner's liquidity change amount for bTokenId
        int256 pnl = (cumulativePnl - asset.lastCumulativePnl) * asset.liquidity / ONE; // owner's pnl as LP since last settlement
        if (bTokenId == 0) {
            delta = bAmount.utoi() + pnl.reformat(_decimals0);
            b.pnl -= pnl; // this pnl comes from b.pnl, thus should be deducted from b.pnl
            _protocolFeeAccrued += pnl - pnl.reformat(_decimals0); // deal with accuracy tail
        } else {
            delta = bAmount.utoi();
            asset.pnl += pnl;
        }
        asset.liquidity += delta;
        asset.lastCumulativePnl = cumulativePnl;
        b.liquidity += delta;

        lToken.updateAsset(owner, bTokenId, asset);

        (int256 totalDynamicEquity, int256[] memory dynamicEquities) = _getBTokenDynamicEquities(blength);
        require(_getBToken0Ratio(totalDynamicEquity, dynamicEquities) >= _minBToken0Ratio, "insuf't b0");

        emit AddLiquidity(owner, bTokenId, bAmount);
    }

    function removeLiquidity(address owner, uint256 bTokenId, uint256 bAmount, uint256 blength, uint256 slength) external override _router_ _lock_ {
        _updateBTokenPrice(bTokenId);
        _updatePricesAndDistributePnl(blength, slength);

        BTokenInfo storage b = _bTokens[bTokenId];
        ILToken lToken = ILToken(_lTokenAddress);
        ILToken.Asset memory asset = lToken.getAsset(owner, bTokenId);
        uint256 decimals = b.decimals;
        bAmount = bAmount.reformat(decimals);

        { // scope begin
        int256 cumulativePnl = b.cumulativePnl;
        int256 amount = bAmount.utoi();
        int256 pnl = (cumulativePnl - asset.lastCumulativePnl) * asset.liquidity / ONE;
        int256 deltaLiquidity;
        int256 deltaPnl;
        if (bTokenId == 0) {
            deltaLiquidity = pnl.reformat(_decimals0);
            deltaPnl = -pnl;
            _protocolFeeAccrued += pnl - pnl.reformat(_decimals0); // deal with accuracy tail
        } else {
            asset.pnl += pnl;
            if (asset.pnl < 0) {
                (uint256 amountB0, uint256 amountBX) = IBTokenSwapper(b.swapperAddress).swapBXForExactB0(
                    (-asset.pnl).ceil(_decimals0).itou(), asset.liquidity.itou(), b.price.itou()
                );
                deltaLiquidity = -amountBX.utoi();
                deltaPnl = amountB0.utoi();
                asset.pnl += amountB0.utoi();
            } else if (asset.pnl > 0 && amount >= asset.liquidity) {
                (, uint256 amountBX) = IBTokenSwapper(b.swapperAddress).swapExactB0ForBX(asset.pnl.itou(), b.price.itou());
                deltaLiquidity = amountBX.utoi();
                deltaPnl = -asset.pnl;
                _protocolFeeAccrued += asset.pnl - asset.pnl.reformat(_decimals0); // deal with accuracy tail
                asset.pnl = 0;
            }
        }
        asset.lastCumulativePnl = cumulativePnl;

        if (amount >= asset.liquidity || amount >= asset.liquidity + deltaLiquidity) {
            bAmount = (asset.liquidity + deltaLiquidity).itou();
            b.liquidity -= asset.liquidity;
            asset.liquidity = 0;
        } else {
            asset.liquidity += deltaLiquidity - amount;
            b.liquidity += deltaLiquidity - amount;
        }
        b.pnl += deltaPnl;
        lToken.updateAsset(owner, bTokenId, asset);
        } // scope end

        (int256 totalDynamicEquity, ) = _getBTokenDynamicEquities(blength);
        require(_getPoolMarginRatio(totalDynamicEquity, slength) >= _minPoolMarginRatio, "insuf't liq");

        IERC20(b.bTokenAddress).safeTransfer(owner, bAmount.rescale(18, decimals));
        emit RemoveLiquidity(owner, bTokenId, bAmount);
    }

    function addMargin(address owner, uint256 bTokenId, uint256 bAmount) external override _router_ _lock_ {
        IPToken pToken = IPToken(_pTokenAddress);
        if (!pToken.exists(owner)) pToken.mint(owner);

        BTokenInfo storage b = _bTokens[bTokenId];
        bAmount = _deflationCompatibleSafeTransferFrom(b.bTokenAddress, b.decimals, owner, address(this), bAmount);

        int256 margin = pToken.getMargin(owner, bTokenId) + bAmount.utoi();

        pToken.updateMargin(owner, bTokenId, margin);
        emit AddMargin(owner, bTokenId, bAmount);
    }

    function removeMargin(address owner, uint256 bTokenId, uint256 bAmount, uint256 blength, uint256 slength) external override _router_ _lock_ {
        _updatePricesAndDistributePnl(blength, slength);
        _settleTraderFundingFee(owner, slength);
        _coverTraderDebt(owner, blength);

        IPToken pToken = IPToken(_pTokenAddress);
        BTokenInfo storage b = _bTokens[bTokenId];
        uint256 decimals = b.decimals;
        bAmount = bAmount.reformat(decimals);

        int256 amount = bAmount.utoi();
        int256 margin = pToken.getMargin(owner, bTokenId);

        if (amount >= margin) {
            bAmount = margin.itou();
            if (bTokenId == 0) _protocolFeeAccrued += margin - margin.reformat(_decimals0); // deal with accuracy tail
            margin = 0;
        } else {
            margin -= amount;
        }
        pToken.updateMargin(owner, bTokenId, margin);

        require(_getTraderMarginRatio(owner, blength, slength) >= _minInitialMarginRatio, "insuf't margin");

        IERC20(b.bTokenAddress).safeTransfer(owner, bAmount.rescale(18, decimals));
        emit RemoveMargin(owner, bTokenId, bAmount);
    }

    // struct for temp use in trade function, to prevent stack too deep error
    struct TradeParams {
        int256 curCost;
        int256 fee;
        int256 realizedCost;
        int256 protocolFee;
    }

    function trade(address owner, uint256 symbolId, int256 tradeVolume, uint256 blength, uint256 slength) external override _router_ _lock_ {
        _updatePricesAndDistributePnl(blength, slength);
        _settleTraderFundingFee(owner, slength);

        SymbolInfo storage s = _symbols[symbolId];
        IPToken.Position memory p = IPToken(_pTokenAddress).getPosition(owner, symbolId);

        TradeParams memory params;

        tradeVolume = tradeVolume.reformat(0);
        params.curCost = tradeVolume * s.price / ONE * s.multiplier / ONE;
        params.fee = params.curCost.abs() * s.feeRatio / ONE;

        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                params.realizedCost = params.curCost * absVolume / absTradeVolume + p.cost;
            } else {
                params.realizedCost = p.cost * absTradeVolume / absVolume + params.curCost;
            }
        }

        p.volume += tradeVolume;
        p.cost += params.curCost - params.realizedCost;
        p.lastCumulativeFundingRate = s.cumulativeFundingRate;
        IPToken(_pTokenAddress).updateMargin(
            owner, 0, IPToken(_pTokenAddress).getMargin(owner, 0) - params.fee - params.realizedCost
        );
        IPToken(_pTokenAddress).updatePosition(owner, symbolId, p);

        s.tradersNetVolume += tradeVolume;
        s.tradersNetCost += params.curCost - params.realizedCost;

        params.protocolFee = params.fee * _protocolFeeCollectRatio / ONE;
        _protocolFeeAccrued += params.protocolFee;

        (int256 totalDynamicEquity, int256[] memory dynamicEquities) = _getBTokenDynamicEquities(blength);
        _distributePnlToBTokens(params.fee - params.protocolFee, totalDynamicEquity, dynamicEquities, blength);
        require(_getPoolMarginRatio(totalDynamicEquity, slength) >= _minPoolMarginRatio, "insuf't liq");
        require(_getTraderMarginRatio(owner, blength, slength) >= _minInitialMarginRatio, "insuf't margin");

        emit Trade(owner, symbolId, tradeVolume, s.price.itou());
    }

    function liquidate(address liquidator, address owner, uint256 blength, uint256 slength) external override _router_ _lock_ {
        _updateAllBTokenPrices(blength);
        _updatePricesAndDistributePnl(blength, slength);
        _settleTraderFundingFee(owner, slength);
        require(_getTraderMarginRatio(owner, blength, slength) < _minMaintenanceMarginRatio, 'cant liquidate');

        IPToken pToken = IPToken(_pTokenAddress);
        IPToken.Position[] memory positions = pToken.getPositions(owner);
        int256 netEquity;
        for (uint256 i = 0; i < slength; i++) {
            if (positions[i].volume != 0) {
                _symbols[i].tradersNetVolume -= positions[i].volume;
                _symbols[i].tradersNetCost -= positions[i].cost;
                netEquity += positions[i].volume * _symbols[i].price / ONE * _symbols[i].multiplier / ONE - positions[i].cost;
            }
        }

        int256[] memory margins = pToken.getMargins(owner);
        netEquity += margins[0];
        for (uint256 i = 1; i < blength; i++) {
            if (margins[i] > 0) {
                (uint256 amountB0, ) = IBTokenSwapper(_bTokens[i].swapperAddress).swapExactBXForB0(margins[i].itou(), _bTokens[i].price.itou());
                netEquity += amountB0.utoi();
            }
        }

        int256 reward;
        int256 minReward = _minLiquidationReward;
        int256 maxReward = _maxLiquidationReward;
        if (netEquity <= minReward) {
            reward = minReward;
        } else if (netEquity >= maxReward) {
            reward = maxReward;
        } else {
            reward = ((netEquity - minReward) * _liquidationCutRatio / ONE + minReward).reformat(_decimals0);
        }

        (int256 totalDynamicEquity, int256[] memory dynamicEquities) = _getBTokenDynamicEquities(blength);
        _distributePnlToBTokens(netEquity - reward, totalDynamicEquity, dynamicEquities, blength);

        pToken.burn(owner);
        IERC20(_bTokens[0].bTokenAddress).safeTransfer(liquidator, reward.itou().rescale(18, _decimals0));

        emit Liquidate(owner, liquidator, reward.itou());
    }


    //================================================================================
    // Helpers
    //================================================================================

    // update bTokens/symbols prices
    // distribute pnl to bTokens, which is generated since last update, including pnl and funding fees for opening positions
    // by calling this function at the beginning of each block, all LP/Traders status are settled
    function _updatePricesAndDistributePnl(uint256 blength, uint256 slength) internal {
        uint256 blocknumber = block.number;
        if (blocknumber > _lastUpdateBlock) {
            (int256 totalDynamicEquity, int256[] memory dynamicEquities) = _getBTokenDynamicEquities(blength);
            int256 undistributedPnl = _updateSymbolPrices(totalDynamicEquity, slength);
            _distributePnlToBTokens(undistributedPnl, totalDynamicEquity, dynamicEquities, blength);
            _lastUpdateBlock = blocknumber;
        }
    }

    function _updateAllBTokenPrices(uint256 blength) internal {
        for (uint256 i = 1; i < blength; i++) {
            _bTokens[i].price = IOracle(_bTokens[i].oracleAddress).getPrice().utoi();
        }
    }

    function _updateBTokenPrice(uint256 bTokenId) internal {
        if (bTokenId != 0) _bTokens[bTokenId].price = IOracle(_bTokens[bTokenId].oracleAddress).getPrice().utoi();
    }

    function _getBTokenDynamicEquities(uint256 blength) internal view returns (int256, int256[] memory) {
        int256 totalDynamicEquity;
        int256[] memory dynamicEquities = new int256[](blength);
        for (uint256 i = 0; i < blength; i++) {
            BTokenInfo storage b = _bTokens[i];
            int256 liquidity = b.liquidity;
            // dynamic equities for bTokens are discounted
            int256 equity = liquidity * b.price / ONE * b.discount / ONE + b.pnl;
            if (liquidity > 0 && equity > 0) {
                totalDynamicEquity += equity;
                dynamicEquities[i] = equity;
            }
        }
        return (totalDynamicEquity, dynamicEquities);
    }

    function _distributePnlToBTokens(int256 pnl, int256 totalDynamicEquity, int256[] memory dynamicEquities, uint256 blength) internal {
        if (totalDynamicEquity > 0 && pnl != 0) {
            for (uint256 i = 0; i < blength; i++) {
                if (dynamicEquities[i] > 0) {
                    BTokenInfo storage b = _bTokens[i];
                    int256 distributedPnl = pnl * dynamicEquities[i] / totalDynamicEquity;
                    b.pnl += distributedPnl;
                    // cumulativePnl is as in per liquidity, thus b.liquidity in denominator
                    b.cumulativePnl += distributedPnl * ONE / b.liquidity;
                }
            }
        }
    }

    // update symbol prices and calculate funding and unrealized pnl for all positions since last call
    // the returned undistributedPnl will be distributed and shared by all LPs
    //
    //                 tradersNetVolume * price * multiplier
    // ratePerBlock = --------------------------------------- * price * multiplier * fundingRateCoefficient
    //                         totalDynamicEquity
    //
    function _updateSymbolPrices(int256 totalDynamicEquity, uint256 slength) internal returns (int256) {
        if (totalDynamicEquity <= 0) return 0;
        int256 undistributedPnl;
        for (uint256 i = 0; i < slength; i++) {
            SymbolInfo storage s = _symbols[i];
            int256 price = IOracle(s.oracleAddress).getPrice().utoi();
            int256 tradersNetVolume = s.tradersNetVolume;
            if (tradersNetVolume != 0) {
                int256 multiplier = s.multiplier;
                int256 ratePerBlock = tradersNetVolume * price / ONE * price / ONE * multiplier / ONE * multiplier / ONE * s.fundingRateCoefficient / totalDynamicEquity;
                int256 delta = ratePerBlock * int256(block.number - _lastUpdateBlock);

                undistributedPnl += tradersNetVolume * delta / ONE;
                undistributedPnl -= tradersNetVolume * (price - s.price) / ONE * multiplier / ONE;

                unchecked { s.cumulativeFundingRate += delta; }
            }
            s.price = price;
        }
        return undistributedPnl;
    }

    function _getBToken0Ratio(int256 totalDynamicEquity, int256[] memory dynamicEquities) internal pure returns (int256) {
        return totalDynamicEquity == 0 ? type(int256).max : dynamicEquities[0] * ONE / totalDynamicEquity;
    }

    function _getPoolMarginRatio(int256 totalDynamicEquity, uint256 slength) internal view returns (int256) {
        int256 totalCost;
        for (uint256 i = 0; i < slength; i++) {
            SymbolInfo storage s = _symbols[i];
            int256 tradersNetVolume = s.tradersNetVolume;
            if (tradersNetVolume != 0) {
                int256 cost = tradersNetVolume * s.price / ONE * s.multiplier / ONE;
                totalDynamicEquity -= cost - s.tradersNetCost;
                totalCost += cost.abs(); // netting costs cross symbols is forbidden
            }
        }
        return totalCost == 0 ? type(int256).max : totalDynamicEquity * ONE / totalCost;
    }

    // setting funding fee on trader's side
    // this funding fee is already settled to bTokens in `_update`, thus distribution is not needed
    function _settleTraderFundingFee(address owner, uint256 slength) internal {
        IPToken pToken = IPToken(_pTokenAddress);
        int256 funding;
        IPToken.Position[] memory positions = pToken.getPositions(owner);
        for (uint256 i = 0; i < slength; i++) {
            IPToken.Position memory p = positions[i];
            if (p.volume != 0) {
                int256 cumulativeFundingRate = _symbols[i].cumulativeFundingRate;
                int256 delta;
                unchecked { delta = cumulativeFundingRate - p.lastCumulativeFundingRate; }
                funding += p.volume * delta / ONE;

                p.lastCumulativeFundingRate = cumulativeFundingRate;
                pToken.updatePosition(owner, i, p);
            }
        }
        if (funding != 0) {
            int256 margin = pToken.getMargin(owner, 0) - funding;
            pToken.updateMargin(owner, 0, margin);
        }
    }

    function _coverTraderDebt(address owner, uint256 blength) internal {
        IPToken pToken = IPToken(_pTokenAddress);
        int256[] memory margins = pToken.getMargins(owner);
        if (margins[0] < 0) {
            uint256 amountB0;
            uint256 amountBX;
            for (uint256 i = blength - 1; i > 0; i--) {
                if (margins[i] > 0) {
                    (amountB0, amountBX) = IBTokenSwapper(_bTokens[i].swapperAddress).swapBXForExactB0(
                        (-margins[0]).ceil(_decimals0).itou(), margins[i].itou(), _bTokens[i].price.itou()
                    );
                    margins[0] += amountB0.utoi();
                    margins[i] -= amountBX.utoi();
                }
                if (margins[0] >= 0) break;
            }
            pToken.updateMargins(owner, margins);
        }
    }

    function _getTraderMarginRatio(address owner, uint256 blength, uint256 slength) internal view returns (int256) {
        IPToken pToken = IPToken(_pTokenAddress);

        int256[] memory margins = pToken.getMargins(owner);
        int256 totalDynamicEquity = margins[0];
        int256 totalCost;
        for (uint256 i = 1; i < blength; i++) {
            totalDynamicEquity += margins[i] * _bTokens[i].price / ONE * _bTokens[i].discount / ONE;
        }

        IPToken.Position[] memory positions = pToken.getPositions(owner);
        for (uint256 i = 0; i < slength; i++) {
            if (positions[i].volume != 0) {
                int256 cost = positions[i].volume * _symbols[i].price / ONE * _symbols[i].multiplier / ONE;
                totalDynamicEquity += cost - positions[i].cost;
                totalCost += cost.abs(); // netting costs cross symbols is forbidden
            }
        }

        return totalCost == 0 ? type(int256).max : totalDynamicEquity * ONE / totalCost;
    }

    function _deflationCompatibleSafeTransferFrom(address bTokenAddress, uint256 decimals, address from, address to, uint256 bAmount)
        internal returns (uint256)
    {
        IERC20 token = IERC20(bTokenAddress);

        uint256 balance1 = token.balanceOf(to);
        token.safeTransferFrom(from, to, bAmount.rescale(18, decimals));
        uint256 balance2 = token.balanceOf(to);

        return (balance2 - balance1).rescale(decimals, 18);
    }

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

interface IPerpetualPool {

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

