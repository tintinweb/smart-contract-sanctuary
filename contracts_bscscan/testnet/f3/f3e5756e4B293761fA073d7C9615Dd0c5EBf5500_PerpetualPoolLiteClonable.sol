// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IPerpetualPoolLite.sol';
import './ILTokenLite.sol';
import './IPTokenLite.sol';
import './IERC20.sol';
import './IOracle.sol';
import './IOracleWithUpdate.sol';
import './ILiquidatorQualifier.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './Migratable.sol';

contract PerpetualPoolLiteClonable is IPerpetualPoolLite, Migratable {

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    int256  constant ONE = 10**18;

    uint256 _decimals;
    int256  _minPoolMarginRatio;
    int256  _minInitialMarginRatio;
    int256  _minMaintenanceMarginRatio;
    int256  _minLiquidationReward;
    int256  _maxLiquidationReward;
    int256  _liquidationCutRatio;
    int256  _protocolFeeCollectRatio;

    address _bTokenAddress;
    address _lTokenAddress;
    address _pTokenAddress;
    address _liquidatorQualifierAddress;
    address _protocolFeeCollector;

    int256  _liquidity;

    uint256 _lastUpdateBlock;
    int256  _protocolFeeAccrued;

    // symbolId => SymbolInfo
    mapping (uint256 => SymbolInfo) _symbols;

    bool private _mutex;
    modifier _lock_() {
        require(!_mutex, 'reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    constructor (uint256[7] memory parameters, address[5] memory addresses) {
        _controller = msg.sender;

        _minPoolMarginRatio = int256(parameters[0]);
        _minInitialMarginRatio = int256(parameters[1]);
        _minMaintenanceMarginRatio = int256(parameters[2]);
        _minLiquidationReward = int256(parameters[3]);
        _maxLiquidationReward = int256(parameters[4]);
        _liquidationCutRatio = int256(parameters[5]);
        _protocolFeeCollectRatio = int256(parameters[6]);

        _bTokenAddress = addresses[0];
        _lTokenAddress = addresses[1];
        _pTokenAddress = addresses[2];
        _liquidatorQualifierAddress = addresses[3];
        _protocolFeeCollector = addresses[4];

        _decimals = IERC20(addresses[0]).decimals();
    }

    // to initialize a cloned version of this contract
    function initialize(address controller_, uint256[7] memory parameters, address[5] memory addresses) external {
        require(_bTokenAddress == address(0) && _controller == address(0), 'PerpetualPool: already initialized');
        require(controller_ != address(0), 'PerpetualPool: invalid controller');

        _controller = controller_;

        _minPoolMarginRatio = int256(parameters[0]);
        _minInitialMarginRatio = int256(parameters[1]);
        _minMaintenanceMarginRatio = int256(parameters[2]);
        _minLiquidationReward = int256(parameters[3]);
        _maxLiquidationReward = int256(parameters[4]);
        _liquidationCutRatio = int256(parameters[5]);
        _protocolFeeCollectRatio = int256(parameters[6]);

        _bTokenAddress = addresses[0];
        _lTokenAddress = addresses[1];
        _pTokenAddress = addresses[2];
        _liquidatorQualifierAddress = addresses[3];
        _protocolFeeCollector = addresses[4];

        _decimals = IERC20(addresses[0]).decimals();
    }

    // during a migration, this function is intended to be called in the source pool
    function approveMigration() external override _controller_ {
        require(_migrationTimestamp != 0 && block.timestamp >= _migrationTimestamp, 'PerpetualPool: migrationTimestamp not met yet');
        // approve new pool to pull all base tokens from this pool
        IERC20(_bTokenAddress).safeApprove(_migrationDestination, type(uint256).max);
        // set lToken/pToken to new pool, after redirecting pToken/lToken to new pool, this pool will stop functioning
        ILTokenLite(_lTokenAddress).setPool(_migrationDestination);
        IPTokenLite(_pTokenAddress).setPool(_migrationDestination);
    }

    // during a migration, this function is intended to be called in the target pool
    function executeMigration(address source) external override _controller_ {
        uint256 migrationTimestamp_ = IPerpetualPoolLite(source).migrationTimestamp();
        address migrationDestination_ = IPerpetualPoolLite(source).migrationDestination();
        require(migrationTimestamp_ != 0 && block.timestamp >= migrationTimestamp_, 'PerpetualPool: migrationTimestamp not met yet');
        require(migrationDestination_ == address(this), 'PerpetualPool: not destination pool');

        // transfer bToken to this address
        IERC20(_bTokenAddress).safeTransferFrom(source, address(this), IERC20(_bTokenAddress).balanceOf(source));

        // transfer symbol infos
        uint256[] memory symbolIds = IPTokenLite(_pTokenAddress).getActiveSymbolIds();
        for (uint256 i = 0; i < symbolIds.length; i++) {
            _symbols[symbolIds[i]] = IPerpetualPoolLite(source).getSymbol(symbolIds[i]);
        }

        // transfer state values
        _liquidity = IPerpetualPoolLite(source).getLiquidity();
        _lastUpdateBlock = IPerpetualPoolLite(source).getLastUpdateBlock();
        _protocolFeeAccrued = IPerpetualPoolLite(source).getProtocolFeeAccrued();

        emit ExecuteMigration(migrationTimestamp_, source, migrationDestination_);
    }

    function getParameters() external override view returns (
        int256 minPoolMarginRatio,
        int256 minInitialMarginRatio,
        int256 minMaintenanceMarginRatio,
        int256 minLiquidationReward,
        int256 maxLiquidationReward,
        int256 liquidationCutRatio,
        int256 protocolFeeCollectRatio
    ) {
        return (
            _minPoolMarginRatio,
            _minInitialMarginRatio,
            _minMaintenanceMarginRatio,
            _minLiquidationReward,
            _maxLiquidationReward,
            _liquidationCutRatio,
            _protocolFeeCollectRatio
        );
    }

    function getAddresses() external override view returns (
        address bTokenAddress,
        address lTokenAddress,
        address pTokenAddress,
        address liquidatorQualifierAddress,
        address protocolFeeCollector
    ) {
        return (
            _bTokenAddress,
            _lTokenAddress,
            _pTokenAddress,
            _liquidatorQualifierAddress,
            _protocolFeeCollector
        );
    }

    function getSymbol(uint256 symbolId) external override view returns (SymbolInfo memory) {
        return _symbols[symbolId];
    }

    function getLiquidity() external override view returns (int256) {
        return _liquidity;
    }

    function getLastUpdateBlock() external override view returns (uint256) {
        return _lastUpdateBlock;
    }

    function getProtocolFeeAccrued() external override view returns (int256) {
        return _protocolFeeAccrued;
    }

    function collectProtocolFee() external override {
        uint256 balance = IERC20(_bTokenAddress).balanceOf(address(this)).rescale(_decimals, 18);
        uint256 amount = _protocolFeeAccrued.itou();
        if (amount > balance) amount = balance;
        _protocolFeeAccrued -= amount.utoi();
        _transferOut(_protocolFeeCollector, amount);
        emit ProtocolFeeCollection(_protocolFeeCollector, amount);
    }

    function addSymbol(
        uint256 symbolId,
        string  memory symbol,
        address oracleAddress,
        uint256 multiplier,
        uint256 feeRatio,
        uint256 fundingRateCoefficient
    ) external override _controller_ {
        SymbolInfo storage s = _symbols[symbolId];
        s.symbolId = symbolId;
        s.symbol = symbol;
        s.oracleAddress = oracleAddress;
        s.multiplier = int256(multiplier);
        s.feeRatio = int256(feeRatio);
        s.fundingRateCoefficient = int256(fundingRateCoefficient);

        IPTokenLite(_pTokenAddress).addSymbolId(symbolId);
    }

    function removeSymbol(uint256 symbolId) external override _controller_ {
        delete _symbols[symbolId];
        IPTokenLite(_pTokenAddress).removeSymbolId(symbolId);
    }

    function toggleCloseOnly(uint256 symbolId) external override _controller_ {
        IPTokenLite(_pTokenAddress).toggleCloseOnly(symbolId);
    }

    function setSymbolParameters(uint256 symbolId, address oracleAddress, uint256 feeRatio, uint256 fundingRateCoefficient) external override _controller_ {
        SymbolInfo storage s = _symbols[symbolId];
        s.oracleAddress = oracleAddress;
        s.feeRatio = int256(feeRatio);
        s.fundingRateCoefficient = int256(fundingRateCoefficient);
    }


    //================================================================================
    // Interactions with onchain oracles
    //================================================================================

    function addLiquidity(uint256 bAmount) external override {
        require(bAmount > 0, 'PerpetualPool: 0 bAmount');
        _addLiquidity(msg.sender, bAmount);
    }

    function removeLiquidity(uint256 lShares) external override {
        require(lShares > 0, 'PerpetualPool: 0 lShares');
        _removeLiquidity(msg.sender, lShares);
    }

    function addMargin(uint256 bAmount) external override {
        require(bAmount > 0, 'PerpetualPool: 0 bAmount');
        _addMargin(msg.sender, bAmount);
    }

    function removeMargin(uint256 bAmount) external override {
        require(bAmount > 0, 'PerpetualPool: 0 bAmount');
        _removeMargin(msg.sender, bAmount);
    }

    function trade(uint256 symbolId, int256 tradeVolume) external override {
        require(IPTokenLite(_pTokenAddress).isActiveSymbolId(symbolId), 'PerpetualPool: invalid symbolId');
        require(tradeVolume != 0 && tradeVolume / ONE * ONE == tradeVolume, 'PerpetualPool: invalid tradeVolume');
        _trade(msg.sender, symbolId, tradeVolume);
    }

    function liquidate(address account) external override {
        address liquidator = msg.sender;
        require(
            _liquidatorQualifierAddress == address(0) || ILiquidatorQualifier(_liquidatorQualifierAddress).isQualifiedLiquidator(liquidator),
            'PerpetualPool: not qualified liquidator'
        );
        _liquidate(liquidator, account);
    }


    //================================================================================
    // Interactions with offchain oracles
    //================================================================================

    function addLiquidity(uint256 bAmount, SignedPrice[] memory prices) external override {
        require(bAmount > 0, 'PerpetualPool: 0 bAmount');
        _updateSymbolOracles(prices);
        _addLiquidity(msg.sender, bAmount);
    }

    function removeLiquidity(uint256 lShares, SignedPrice[] memory prices) external override {
        require(lShares > 0, 'PerpetualPool: 0 lShares');
        _updateSymbolOracles(prices);
        _removeLiquidity(msg.sender, lShares);
    }

    function addMargin(uint256 bAmount, SignedPrice[] memory prices) external override {
        require(bAmount > 0, 'PerpetualPool: 0 bAmount');
        _updateSymbolOracles(prices);
        _addMargin(msg.sender, bAmount);
    }

    function removeMargin(uint256 bAmount, SignedPrice[] memory prices) external override {
        require(bAmount > 0, 'PerpetualPool: 0 bAmount');
        _updateSymbolOracles(prices);
        _removeMargin(msg.sender, bAmount);
    }

    function trade(uint256 symbolId, int256 tradeVolume, SignedPrice[] memory prices) external override {
        require(IPTokenLite(_pTokenAddress).isActiveSymbolId(symbolId), 'PerpetualPool: invalid symbolId');
        require(tradeVolume != 0 && tradeVolume / ONE * ONE == tradeVolume, 'PerpetualPool: invalid tradeVolume');
        _updateSymbolOracles(prices);
        _trade(msg.sender, symbolId, tradeVolume);
    }

    function liquidate(address account, SignedPrice[] memory prices) external override {
        address liquidator = msg.sender;
        require(
            _liquidatorQualifierAddress == address(0) || ILiquidatorQualifier(_liquidatorQualifierAddress).isQualifiedLiquidator(liquidator),
            'PerpetualPool: not qualified liquidator'
        );
        _updateSymbolOracles(prices);
        _liquidate(liquidator, account);
    }


    //================================================================================
    // Core logics
    //================================================================================

    function _addLiquidity(address account, uint256 bAmount) internal _lock_ {
        (int256 totalDynamicEquity, ) = _updateSymbolPricesAndFundingRates();
        bAmount = _transferIn(account, bAmount);
        ILTokenLite lToken = ILTokenLite(_lTokenAddress);

        uint256 totalSupply = lToken.totalSupply();
        uint256 lShares;
        if (totalSupply == 0) {
            lShares = bAmount;
        } else {
            lShares = bAmount * totalSupply / totalDynamicEquity.itou();
        }

        lToken.mint(account, lShares);
        _liquidity += bAmount.utoi();

        emit AddLiquidity(account, lShares, bAmount);
    }

    function _removeLiquidity(address account, uint256 lShares) internal _lock_ {
        (int256 totalDynamicEquity, int256 totalAbsCost) = _updateSymbolPricesAndFundingRates();
        ILTokenLite lToken = ILTokenLite(_lTokenAddress);

        uint256 totalSupply = lToken.totalSupply();
        uint256 bAmount = lShares * totalDynamicEquity.itou() / totalSupply;

        _liquidity -= bAmount.utoi();

        require(
            totalAbsCost == 0 || (totalDynamicEquity - bAmount.utoi()) * ONE / totalAbsCost >= _minPoolMarginRatio,
            'PerpetualPool: pool insufficient margin'
        );

        lToken.burn(account, lShares);
        _transferOut(account, bAmount);

        emit RemoveLiquidity(account, lShares, bAmount);
    }

    function _addMargin(address account, uint256 bAmount) internal _lock_ {
        bAmount = _transferIn(account, bAmount);

        IPTokenLite pToken = IPTokenLite(_pTokenAddress);
        if (!pToken.exists(account)) pToken.mint(account);

        pToken.addMargin(account, bAmount.utoi());
        emit AddMargin(account, bAmount);
    }

    function _removeMargin(address account, uint256 bAmount) internal _lock_ {
        _updateSymbolPricesAndFundingRates();
        (uint256[] memory symbolIds,
         IPTokenLite.Position[] memory positions,
         bool[] memory positionUpdates,
         int256 margin) = _settleTraderFundingFee(account);

        int256 amount = bAmount.utoi();
        if (amount >= margin) {
            amount = margin;
            bAmount = amount.itou();
            margin = 0;
        } else {
            margin -= amount;
        }

        require(_getTraderMarginRatio(symbolIds, positions, margin) >= _minInitialMarginRatio, 'PerpetualPool: insufficient margin');

        _updateTraderPortfolio(account, symbolIds, positions, positionUpdates, margin);
        _transferOut(account, bAmount);

        emit RemoveMargin(account, bAmount);
    }

    // struct for temp use in trade function, to prevent stack too deep error
    struct TradeParams {
        int256 tradersNetVolume;
        int256 price;
        int256 multiplier;
        int256 curCost;
        int256 fee;
        int256 realizedCost;
        int256 protocolFee;
    }

    function _trade(address account, uint256 symbolId, int256 tradeVolume) internal _lock_ {
        (int256 totalDynamicEquity, int256 totalAbsCost) = _updateSymbolPricesAndFundingRates();
        (uint256[] memory symbolIds,
         IPTokenLite.Position[] memory positions,
         bool[] memory positionUpdates,
         int256 margin) = _settleTraderFundingFee(account);

        uint256 index;
        for (uint256 i = 0; i < symbolIds.length; i++) {
            if (symbolId == symbolIds[i]) {
                index = i;
                break;
            }
        }

        TradeParams memory params;

        params.tradersNetVolume = _symbols[symbolId].tradersNetVolume;
        params.price = _symbols[symbolId].price;
        params.multiplier = _symbols[symbolId].multiplier;
        params.curCost = tradeVolume * params.price / ONE * params.multiplier / ONE;
        params.fee = params.curCost.abs() * _symbols[symbolId].feeRatio / ONE;

        if (!(positions[index].volume >= 0 && tradeVolume >= 0) && !(positions[index].volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = positions[index].volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                // previous position is totally closed
                params.realizedCost = params.curCost * absVolume / absTradeVolume + positions[index].cost;
            } else {
                // previous position is partially closed
                params.realizedCost = positions[index].cost * absTradeVolume / absVolume + params.curCost;
            }
        }

        // adjust totalAbsCost after trading
        totalAbsCost += ((params.tradersNetVolume + tradeVolume).abs() - params.tradersNetVolume.abs()) *
                        params.price / ONE * params.multiplier / ONE;

        positions[index].volume += tradeVolume;
        positions[index].cost += params.curCost - params.realizedCost;
        positions[index].lastCumulativeFundingRate = _symbols[symbolId].cumulativeFundingRate;
        margin -= params.fee + params.realizedCost;
        positionUpdates[index] = true;

        _symbols[symbolId].tradersNetVolume += tradeVolume;
        _symbols[symbolId].tradersNetCost += params.curCost - params.realizedCost;
        params.protocolFee = params.fee * _protocolFeeCollectRatio / ONE;
        _protocolFeeAccrued += params.protocolFee;
        _liquidity += params.fee - params.protocolFee + params.realizedCost;

        require(totalAbsCost == 0 || totalDynamicEquity * ONE / totalAbsCost >= _minPoolMarginRatio, 'PerpetualPool: insufficient liquidity');
        require(_getTraderMarginRatio(symbolIds, positions, margin) >= _minInitialMarginRatio, 'PerpetualPool: insufficient margin');

        _updateTraderPortfolio(account, symbolIds, positions, positionUpdates, margin);

        emit Trade(account, symbolId, tradeVolume, params.price.itou());
    }

    function _liquidate(address liquidator, address account) internal _lock_ {
        _updateSymbolPricesAndFundingRates();
        (uint256[] memory symbolIds, IPTokenLite.Position[] memory positions, , int256 margin) = _settleTraderFundingFee(account);
        require(_getTraderMarginRatio(symbolIds, positions, margin) < _minMaintenanceMarginRatio, 'PerpetualPool: cannot liquidate');

        int256 netEquity = margin;
        for (uint256 i = 0; i < symbolIds.length; i++) {
            if (positions[i].volume != 0) {
                _symbols[symbolIds[i]].tradersNetVolume -= positions[i].volume;
                _symbols[symbolIds[i]].tradersNetCost -= positions[i].cost;
                netEquity += positions[i].volume * _symbols[symbolIds[i]].price / ONE * _symbols[symbolIds[i]].multiplier / ONE - positions[i].cost;
            }
        }

        int256 reward;
        if (netEquity <= _minLiquidationReward) {
            reward = _minLiquidationReward;
        } else if (netEquity >= _maxLiquidationReward) {
            reward = _maxLiquidationReward;
        } else {
            reward = (netEquity - _minLiquidationReward) * _liquidationCutRatio / ONE + _minLiquidationReward;
        }

        _liquidity += margin - reward;
        IPTokenLite(_pTokenAddress).burn(account);
        _transferOut(liquidator, reward.itou());

        emit Liquidate(account, liquidator, reward.itou());
    }


    //================================================================================
    // Helpers
    //================================================================================

    function _updateSymbolOracles(SignedPrice[] memory prices) internal {
        for (uint256 i = 0; i < prices.length; i++) {
            uint256 symbolId = prices[i].symbolId;
            IOracleWithUpdate(_symbols[symbolId].oracleAddress).updatePrice(
                prices[i].timestamp,
                prices[i].price,
                prices[i].v,
                prices[i].r,
                prices[i].s
            );
        }
    }

    function _updateSymbolPricesAndFundingRates() internal returns (int256 totalDynamicEquity, int256 totalAbsCost) {
        uint256 preBlockNumber = _lastUpdateBlock;
        uint256 curBlockNumber = block.number;
        uint256[] memory symbolIds = IPTokenLite(_pTokenAddress).getActiveSymbolIds();
        totalDynamicEquity = _liquidity;

        for (uint256 i = 0; i < symbolIds.length; i++) {
            SymbolInfo storage s = _symbols[symbolIds[i]];
            if (curBlockNumber > preBlockNumber) {
                s.price = IOracle(s.oracleAddress).getPrice().utoi();
            }
            if (s.tradersNetVolume != 0) {
                int256 cost = s.tradersNetVolume * s.price / ONE * s.multiplier / ONE;
                totalDynamicEquity -= cost - s.tradersNetCost;
                totalAbsCost += cost.abs();
            }
        }

        if (curBlockNumber > preBlockNumber) {
            for (uint256 i = 0; i < symbolIds.length; i++) {
                SymbolInfo storage s = _symbols[symbolIds[i]];
                if (s.tradersNetVolume != 0) {
                    int256 ratePerBlock = s.tradersNetVolume * s.price / ONE * s.price / ONE * s.multiplier / ONE * s.multiplier / ONE * s.fundingRateCoefficient / totalDynamicEquity;
                    int256 delta = ratePerBlock * int256(curBlockNumber - preBlockNumber);
                    unchecked { s.cumulativeFundingRate += delta; }
                }
            }
        }

        _lastUpdateBlock = curBlockNumber;
    }

    function _getTraderPortfolio(address account) internal view returns (
        uint256[] memory symbolIds,
        IPTokenLite.Position[] memory positions,
        bool[] memory positionUpdates,
        int256 margin
    ) {
        IPTokenLite pToken = IPTokenLite(_pTokenAddress);
        symbolIds = pToken.getActiveSymbolIds();

        positions = new IPTokenLite.Position[](symbolIds.length);
        positionUpdates = new bool[](symbolIds.length);
        for (uint256 i = 0; i < symbolIds.length; i++) {
            positions[i] = pToken.getPosition(account, symbolIds[i]);
        }

        margin = pToken.getMargin(account);
    }

    function _updateTraderPortfolio(
        address account,
        uint256[] memory symbolIds,
        IPTokenLite.Position[] memory positions,
        bool[] memory positionUpdates,
        int256 margin
    ) internal {
        IPTokenLite pToken = IPTokenLite(_pTokenAddress);
        for (uint256 i = 0; i < symbolIds.length; i++) {
            if (positionUpdates[i]) {
                pToken.updatePosition(account, symbolIds[i], positions[i]);
            }
        }
        pToken.updateMargin(account, margin);
    }

    function _settleTraderFundingFee(address account) internal returns (
        uint256[] memory symbolIds,
        IPTokenLite.Position[] memory positions,
        bool[] memory positionUpdates,
        int256 margin
    ) {
        (symbolIds, positions, positionUpdates, margin) = _getTraderPortfolio(account);
        int256 funding;
        for (uint256 i = 0; i < symbolIds.length; i++) {
            if (positions[i].volume != 0) {
                int256 cumulativeFundingRate = _symbols[symbolIds[i]].cumulativeFundingRate;
                int256 delta;
                unchecked { delta = cumulativeFundingRate - positions[i].lastCumulativeFundingRate; }
                funding += positions[i].volume * delta / ONE;

                positions[i].lastCumulativeFundingRate = cumulativeFundingRate;
                positionUpdates[i] = true;
            }
        }
        if (funding != 0) {
            margin -= funding;
            _liquidity += funding;
        }
    }

    function _getTraderMarginRatio(
        uint256[] memory symbolIds,
        IPTokenLite.Position[] memory positions,
        int256 margin
    ) internal view returns (int256) {
        int256 totalDynamicEquity = margin;
        int256 totalAbsCost;
        for (uint256 i = 0; i < symbolIds.length; i++) {
            if (positions[i].volume != 0) {
                int256 cost = positions[i].volume * _symbols[symbolIds[i]].price / ONE * _symbols[symbolIds[i]].multiplier / ONE;
                totalDynamicEquity += cost - positions[i].cost;
                totalAbsCost += cost.abs();
            }
        }
        return totalAbsCost == 0 ? type(int256).max : totalDynamicEquity * ONE / totalAbsCost;
    }

    function _deflationCompatibleSafeTransferFrom(address from, address to, uint256 bAmount) internal returns (uint256) {
        IERC20 bToken = IERC20(_bTokenAddress);
        uint256 balance1 = bToken.balanceOf(to);
        bToken.safeTransferFrom(from, to, bAmount);
        uint256 balance2 = bToken.balanceOf(to);
        return balance2 - balance1;
    }

    function _transferIn(address from, uint256 bAmount) internal returns (uint256) {
        uint256 amount = _deflationCompatibleSafeTransferFrom(from, address(this), bAmount.rescale(18, _decimals));
        return amount.rescale(_decimals, 18);
    }

    function _transferOut(address to, uint256 bAmount) internal {
        uint256 amount = bAmount.rescale(18, _decimals);
        uint256 leftover = bAmount - amount.rescale(_decimals, 18);
        // leftover due to decimal precision is accrued to _protocolFeeAccrued
        _protocolFeeAccrued += leftover.utoi();
        IERC20(_bTokenAddress).safeTransfer(to, amount);
    }

}