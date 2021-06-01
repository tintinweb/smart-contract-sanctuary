// SPDX-License-Identifier: MIT

// Version: 0.1.0, 1/20/2021

pragma solidity >=0.6.2 <0.8.0;

import "./IERC20.sol";
import "./IPToken.sol";
import "./ILToken.sol";
import "./IOracle.sol";
import "./ILiquidatorQualifier.sol";
import "./IMigratablePool.sol";
import "./IPreMiningPool.sol";
import "./IPerpetualPool.sol";
import "./SafeERC20.sol";
import "./MixedSafeMathWithUnit.sol";
import "./MigratablePool.sol";

/**
 * @title Deri Protocol PerpetualPool Implementation
 */
contract PerpetualPool is IMigratablePool, IPerpetualPool, MigratablePool {

    using MixedSafeMathWithUnit for uint256;
    using MixedSafeMathWithUnit for int256;
    using SafeERC20 for IERC20;

    // Trading symbol
    string private _symbol;

    // Last price
    uint256 private _price;
    // Last price timestamp
    uint256 private _lastPriceTimestamp;
    // Last price block number
    uint256 private _lastPriceBlockNumber;

    // Base token contract, all settlements are done in base token
    IERC20  private _bToken;
    // Base token decimals
    uint256 private _bDecimals;
    // Position token contract
    IPToken private _pToken;
    // Liquidity provider token contract
    ILToken private _lToken;
    // For on-chain oracle, it is a contract and must have getPrice() method to fetch current price
    // For off-chain signed price oracle, it is an EOA
    // and its address is used to verify price signature
    IOracle private _oracle;
    // Is on-chain oracle, or off-chain oracle with signed price
    bool private _isContractOracle;
    // LiquidatorQualifier contract to check if an address can call liquidate function
    // If this address is 0, means no liquidator qualification check, anyone can call liquidate
    ILiquidatorQualifier private _liquidatorQualifier;

    // Contract multiplier
    uint256 private _multiplier;
    // Trading fee ratio
    uint256 private _feeRatio;
    // Minimum pool margin ratio
    uint256 private _minPoolMarginRatio;
    // Minimum initial margin ratio for trader
    uint256 private _minInitialMarginRatio;
    // Minimum maintenance margin ratio for trader
    uint256 private _minMaintenanceMarginRatio;
    // Minimum amount requirement when add liquidity
    uint256 private _minAddLiquidity;
    // Redemption fee ratio when removing liquidity
    uint256 private _redemptionFeeRatio;
    // Funding rate coefficient
    uint256 private _fundingRateCoefficient;
    // Minimum liquidation reward
    uint256 private _minLiquidationReward;
    // Maximum liquidation reward
    uint256 private _maxLiquidationReward;
    // Cutting ratio for liquidator
    uint256 private _liquidationCutRatio;
    // Price delay allowance in seconds
    uint256 private _priceDelayAllowance;

    // Recorded cumulative funding rate, overflow of this value is intended
    int256  private _cumuFundingRate;
    // Last block number when cumulative funding rate was recorded
    uint256 private _cumuFundingRateBlock;
    // Total liquidity pool holds
    uint256 private _liquidity;
    // Total net volume of all traders in the pool
    int256  private _tradersNetVolume;
    // Total cost of current traders net volume
    // The cost for a long position is positive, and short position is negative
    int256  private _tradersNetCost;

    bool private _mutex;
    // Locker to prevent reentry
    modifier _lock_() {
        require(!_mutex, "PerpetualPool: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    /**
     * @dev A dummy constructor, which deos not initialize any storage variables
     * A template will be deployed with no initialization and real pool will be cloned
     * from this template (same as create_forwarder_to mechanism in Vyper),
     * and use `initialize` to initialize all storage variables
     */
    constructor () {}

    /**
     * @dev See {IPerpetualPool}.{initialize}
     */
    function initialize(
        string memory symbol_,
        address[5] calldata addresses_,
        uint256[12] calldata parameters_
    ) public override {
        require(bytes(_symbol).length == 0 && _controller == address(0), "PerpetualPool: already initialized");

        _controller = msg.sender;
        _symbol = symbol_;

        _bToken = IERC20(addresses_[0]);
        _bDecimals = _bToken.decimals();
        _pToken = IPToken(addresses_[1]);
        _lToken = ILToken(addresses_[2]);
        _oracle = IOracle(addresses_[3]);
        _isContractOracle = _isContract(address(_oracle));
        _liquidatorQualifier = ILiquidatorQualifier(addresses_[4]);

        _multiplier = parameters_[0];
        _feeRatio = parameters_[1];
        _minPoolMarginRatio = parameters_[2];
        _minInitialMarginRatio = parameters_[3];
        _minMaintenanceMarginRatio = parameters_[4];
        _minAddLiquidity = parameters_[5];
        _redemptionFeeRatio = parameters_[6];
        _fundingRateCoefficient = parameters_[7];
        _minLiquidationReward = parameters_[8];
        _maxLiquidationReward = parameters_[9];
        _liquidationCutRatio = parameters_[10];
        _priceDelayAllowance = parameters_[11];
    }

    /**
     * @dev See {IMigratablePool}.{approveMigration}
     */
    function approveMigration() public override _controller_ {
        require(_migrationTimestamp != 0 && block.timestamp >= _migrationTimestamp, "PerpetualPool: migrationTimestamp not met yet");
        // approve new pool to pull all base tokens from this pool
        _bToken.safeApprove(_migrationDestination, uint256(-1));
        // set pToken/lToken to new pool, after redirecting pToken/lToken to new pool, this pool will stop functioning
        _pToken.setPool(_migrationDestination);
        _lToken.setPool(_migrationDestination);
    }

    function setParameters(
        uint256 feeRatio,
        uint256 minPoolMarginRatio,
        uint256 minInitialMarginRatio,
        uint256 minMaintenanceMarginRatio,
        uint256 minAddLiquidity,
        uint256 redemptionFeeRatio,
        uint256 fundingRateCoefficient,
        uint256 minLiquidationReward,
        uint256 maxLiquidationReward,
        uint256 liquidationCutRatio,
        uint256 priceDelayAllowance,
        address oracleAddress,
        address liquidatorQualifierAddress
    ) public _controller_ {
        _feeRatio = feeRatio;
        _minPoolMarginRatio = minPoolMarginRatio;
        _minInitialMarginRatio = minInitialMarginRatio;
        _minMaintenanceMarginRatio = minMaintenanceMarginRatio;
        _minAddLiquidity = minAddLiquidity;
        _redemptionFeeRatio = redemptionFeeRatio;
        _fundingRateCoefficient = fundingRateCoefficient;
        _minLiquidationReward = minLiquidationReward;
        _maxLiquidationReward = maxLiquidationReward;
        _liquidationCutRatio = liquidationCutRatio;
        _priceDelayAllowance = priceDelayAllowance;

        _oracle = IOracle(oracleAddress);
        _isContractOracle = _isContract(oracleAddress);
        _liquidatorQualifier = ILiquidatorQualifier(liquidatorQualifierAddress);
    }

    /**
     * @dev See {IMigratablePool}.{executeMigration}
     */
    function executeMigration(address source) public override _controller_ {
        uint256 migrationTimestamp_ = IPerpetualPool(source).migrationTimestamp();
        address migrationDestination_ = IPerpetualPool(source).migrationDestination();
        require(migrationTimestamp_ != 0 && block.timestamp >= migrationTimestamp_, "PerpetualPool: migrationTimestamp not met yet");
        require(migrationDestination_ == address(this), "PerpetualPool: executeMigration to not destination pool");

        // migrate base token
        _bToken.safeTransferFrom(source, address(this), _bToken.balanceOf(source));

        // migrate state values from PerpetualPool
        (int256 cumuFundingRate, uint256 cumuFundingRateBlock, uint256 liquidity, int256 tradersNetVolume, int256 tradersNetCost) = IPerpetualPool(source).getStateValues();
        _cumuFundingRate = cumuFundingRate;
        _cumuFundingRateBlock = cumuFundingRateBlock;
        _liquidity = liquidity;
        _tradersNetVolume = tradersNetVolume;
        _tradersNetCost = tradersNetCost;

        // // migrate state values from PreMiningPool
        // _liquidity = IPreMiningPool(source).getStateValues();

        emit ExecuteMigration(migrationTimestamp_, source, address(this));
    }


    /**
     * @dev See {IPerpetualPool}.{symbol}
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IPerpetualPool}.{getAddresses}
     */
    function getAddresses() public view override returns (
        address bToken,
        address pToken,
        address lToken,
        address oracle,
        address liquidatorQualifier
    ) {
        return (
            address(_bToken),
            address(_pToken),
            address(_lToken),
            address(_oracle),
            address(_liquidatorQualifier)
        );
    }

    /**
     * @dev See {IPerpetualPool}.{getParameters}
     */
    function getParameters() public view override returns (
        uint256 multiplier,
        uint256 feeRatio,
        uint256 minPoolMarginRatio,
        uint256 minInitialMarginRatio,
        uint256 minMaintenanceMarginRatio,
        uint256 minAddLiquidity,
        uint256 redemptionFeeRatio,
        uint256 fundingRateCoefficient,
        uint256 minLiquidationReward,
        uint256 maxLiquidationReward,
        uint256 liquidationCutRatio,
        uint256 priceDelayAllowance
    ) {
        return (
            _multiplier,
            _feeRatio,
            _minPoolMarginRatio,
            _minInitialMarginRatio,
            _minMaintenanceMarginRatio,
            _minAddLiquidity,
            _redemptionFeeRatio,
            _fundingRateCoefficient,
            _minLiquidationReward,
            _maxLiquidationReward,
            _liquidationCutRatio,
            _priceDelayAllowance
        );
    }

    /**
     * @dev See {IPerpetualPool}.{getStateValues}
     */
    function getStateValues() public view override returns (
        int256 cumuFundingRate,
        uint256 cumuFundingRateBlock,
        uint256 liquidity,
        int256 tradersNetVolume,
        int256 tradersNetCost
    ) {
        return (
            _cumuFundingRate,
            _cumuFundingRateBlock,
            _liquidity,
            _tradersNetVolume,
            _tradersNetCost
        );
    }


    //================================================================================
    // Pool interactions
    //================================================================================

    /**
     * @dev See {IPerpetualPool}.{tradeWithMargin}
     */
    function tradeWithMargin(int256 tradeVolume, uint256 bAmount) public override {
        _updatePriceFromOracle();
        _tradeWithMargin(tradeVolume, bAmount);
    }

    /**
     * @dev See {IPerpetualPool}.{tradeWithMargin}
     */
    function tradeWithMargin(
        int256 tradeVolume,
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        _updatePriceWithSignature(timestamp, price, v, r, s);
        _tradeWithMargin(tradeVolume, bAmount);
    }

    /**
     * @dev See {IPerpetualPool}.{trade}
     */
    function trade(int256 tradeVolume) public override {
        _updatePriceFromOracle();
        _trade(tradeVolume);
    }

    /**
     * @dev See {IPerpetualPool}.{trade}
     */
    function trade(
        int256 tradeVolume,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        _updatePriceWithSignature(timestamp, price, v, r, s);
        _trade(tradeVolume);
    }

    /**
     * @dev See {IPerpetualPool}.{depositMargin}
     */
    function depositMargin(uint256 bAmount) public override {
        _updatePriceFromOracle();
        _depositMargin(bAmount);
    }

    /**
     * @dev See {IPerpetualPool}.{depositMargin}
     */
    function depositMargin(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        _updatePriceWithSignature(timestamp, price, v, r, s);
        _depositMargin(bAmount);
    }

    /**
     * @dev See {IPerpetualPool}.{withdrawMargin}
     */
    function withdrawMargin(uint256 bAmount) public override {
        _updatePriceFromOracle();
        _withdrawMargin(bAmount);
    }

    /**
     * @dev See {IPerpetualPool}.{withdrawMargin}
     */
    function withdrawMargin(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        _updatePriceWithSignature(timestamp, price, v, r, s);
        _withdrawMargin(bAmount);
    }

    /**
     * @dev See {IPerpetualPool}.{addLiquidity}
     */
    function addLiquidity(uint256 bAmount) public override {
        _updatePriceFromOracle();
        _addLiquidity(bAmount);
    }

    /**
     * @dev See {IPerpetualPool}.{addLiquidity}
     */
    function addLiquidity(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        _updatePriceWithSignature(timestamp, price, v, r, s);
        _addLiquidity(bAmount);
    }

    /**
     * @dev See {IPerpetualPool}.{removeLiquidity}
     */
    function removeLiquidity(uint256 lShares) public override {
        _updatePriceFromOracle();
        _removeLiquidity(lShares);
    }

    /**
     * @dev See {IPerpetualPool}.{removeLiquidity}
     */
    function removeLiquidity(
        uint256 lShares,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        _updatePriceWithSignature(timestamp, price, v, r, s);
        _removeLiquidity(lShares);
    }

    /**
     * @dev See {IPerpetualPool}.{liquidate}
     */
    function liquidate(address owner) public override {
        require(
            address(_liquidatorQualifier) == address(0) || _liquidatorQualifier.isQualifiedLiquidator(msg.sender),
            "PerpetualPool: not quanlified liquidator"
        );
        _updatePriceFromOracle();
        _liquidate(owner, block.timestamp, _price);
    }

    /**
     * @dev See {IPerpetualPool}.{liquidate}
     *
     * A price signature with timestamp after position's lastUpdateTimestamp
     * will be a valid liquidation price
     */
    function liquidate(
        address owner,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        require(
            address(_liquidatorQualifier) == address(0) || _liquidatorQualifier.isQualifiedLiquidator(msg.sender),
            "PerpetualPool: not quanlified liquidator"
        );
        _checkPriceSignature(timestamp, price, v, r, s);
        _liquidate(owner, timestamp, price);
    }


    //================================================================================
    // Pool critic logics
    //================================================================================

    /**
     * @dev Low level tradeWithMargin implementation
     * _lock_ is not need in this function, as sub-functions will apply _lock_
     */
    function _tradeWithMargin(int256 tradeVolume, uint256 bAmount) internal {
        if (bAmount == 0) {
            _trade(tradeVolume);
        } else if (tradeVolume == 0) {
            _depositMargin(bAmount);
        } else {
            _depositMargin(bAmount);
            _trade(tradeVolume);
        }
    }

    /**
     * @dev Low level trade implementation
     */
    function _trade(int256 tradeVolume) internal _lock_ {
        require(tradeVolume != 0, "PerpetualPool: trade with 0 volume");
        require(tradeVolume.reformat(0) == tradeVolume, "PerpetualPool: trade volume must be int");

        // get trader's position, trader must have a position token to call this function
        (int256 volume, int256 cost, int256 lastCumuFundingRate, uint256 margin,) = _pToken.getPosition(msg.sender);

        // update cumulative funding rate
        _updateCumuFundingRate(_price);

        // calculate trader's funding fee
        int256 funding = volume.mul(_cumuFundingRate - lastCumuFundingRate);

        // calculate trading fee for this transaction
        int256 curCost = tradeVolume.mul(_price).mul(_multiplier);
        uint256 fee = _feeRatio.mul(curCost.abs());

        // calculate realized cost
        int256 realizedCost = 0;
        if ((volume >= 0 && tradeVolume >= 0) || (volume <= 0 && tradeVolume <= 0)) {
            // open in same direction, no realized cost
        } else if (volume.abs() <= tradeVolume.abs()) {
            // previous position is flipped
            realizedCost = curCost.mul(volume.abs()).div(tradeVolume.abs()).add(cost);
        } else {
            // previous position is partially closed
            realizedCost = cost.mul(tradeVolume.abs()).div(volume.abs()).add(curCost);
        }

        // total paid in this transaction, could be negative if there is realized pnl
        // this paid amount should be a valid value in base token decimals representation
        int256 paid = funding.add(fee).add(realizedCost).reformat(_bDecimals);

        // settlements
        volume = volume.add(tradeVolume);
        cost = cost.add(curCost).sub(realizedCost);
        margin = margin.sub(paid);
        _tradersNetVolume = _tradersNetVolume.add(tradeVolume);
        _tradersNetCost = _tradersNetCost.add(curCost).sub(realizedCost);
        _liquidity = _liquidity.add(paid);
        lastCumuFundingRate = _cumuFundingRate;

        // check margin requirements
        require(volume == 0 || _calculateMarginRatio(volume, cost, _price, margin) >= _minInitialMarginRatio,
                "PerpetualPool: trader insufficient margin");
        require(_tradersNetVolume == 0 || _calculateMarginRatio(_tradersNetVolume.neg(), _tradersNetCost.neg(), _price, _liquidity) >= _minPoolMarginRatio,
                "PerpetualPool: pool insufficient liquidity");

        _pToken.update(msg.sender, volume, cost, lastCumuFundingRate, margin, block.timestamp);
        emit Trade(msg.sender, tradeVolume, _price);
    }

    /**
     * @dev Low level depositMargin implementation
     */
    function _depositMargin(uint256 bAmount) internal _lock_ {
        require(bAmount != 0, "PerpetualPool: deposit zero margin");
        require(bAmount.reformat(_bDecimals) == bAmount, "PerpetualPool: _depositMargin bAmount not valid");

        bAmount = _deflationCompatibleSafeTransferFrom(msg.sender, address(this), bAmount);
        if (!_pToken.exists(msg.sender)) {
            _pToken.mint(msg.sender, bAmount);
        } else {
            (int256 volume, int256 cost, int256 lastCumuFundingRate, uint256 margin,) = _pToken.getPosition(msg.sender);
            margin = margin.add(bAmount);
            _pToken.update(msg.sender, volume, cost, lastCumuFundingRate, margin, block.timestamp);
        }
        emit DepositMargin(msg.sender, bAmount);
    }

    /**
     * @dev Low level withdrawMargin implementation
     */
    function _withdrawMargin(uint256 bAmount) internal _lock_ {
        require(bAmount != 0, "PerpetualPool: withdraw zero margin");
        require(bAmount.reformat(_bDecimals) == bAmount, "PerpetualPool: _withdrawMargin bAmount not valid");

        (int256 volume, int256 cost, int256 lastCumuFundingRate, uint256 margin,) = _pToken.getPosition(msg.sender);
        _updateCumuFundingRate(_price);

        int256 funding = volume.mul(_cumuFundingRate - lastCumuFundingRate).reformat(_bDecimals);
        margin = margin.sub(funding).sub(bAmount);
        _liquidity = _liquidity.add(funding);
        lastCumuFundingRate = _cumuFundingRate;

        require(volume == 0 || _calculateMarginRatio(volume, cost, _price, margin) >= _minInitialMarginRatio,
                "PerpetualPool: withdraw cause insufficient margin");

        _pToken.update(msg.sender, volume, cost, lastCumuFundingRate, margin, block.timestamp);
        _bToken.safeTransfer(msg.sender, bAmount.rescale(_bDecimals));
        emit WithdrawMargin(msg.sender, bAmount);
    }

    /**
     * @dev Low level addLiquidity implementation
     */
    function _addLiquidity(uint256 bAmount) internal _lock_ {
        require(bAmount >= _minAddLiquidity, "PerpetualPool: add liquidity less than minimum requirement");
        require(bAmount.reformat(_bDecimals) == bAmount, "PerpetualPool: _addLiquidity bAmount not valid");

        _updateCumuFundingRate(_price);

        bAmount = _deflationCompatibleSafeTransferFrom(msg.sender, address(this), bAmount);

        uint256 poolDynamicEquity = _liquidity.add(_tradersNetCost.sub(_tradersNetVolume.mul(_price).mul(_multiplier)));
        uint256 totalSupply = _lToken.totalSupply();
        uint256 lShares;
        if (totalSupply == 0) {
            lShares = bAmount;
        } else {
            lShares = bAmount.mul(totalSupply).div(poolDynamicEquity);
        }

        _lToken.mint(msg.sender, lShares);
        _liquidity = _liquidity.add(bAmount);

        emit AddLiquidity(msg.sender, lShares, bAmount);
    }

    /**
     * @dev Low level removeLiquidity implementation
     */
    function _removeLiquidity(uint256 lShares) internal _lock_ {
        require(lShares > 0, "PerpetualPool: remove 0 liquidity");
        uint256 balance = _lToken.balanceOf(msg.sender);
        require(lShares == balance || balance.sub(lShares) >= 10**18, "PerpetualPool: remaining liquidity shares must be 0 or at least 1");

        _updateCumuFundingRate(_price);

        uint256 poolDynamicEquity = _liquidity.add(_tradersNetCost.sub(_tradersNetVolume.mul(_price).mul(_multiplier)));
        uint256 totalSupply = _lToken.totalSupply();
        uint256 bAmount = lShares.mul(poolDynamicEquity).div(totalSupply);
        if (lShares < totalSupply) {
            bAmount = bAmount.sub(bAmount.mul(_redemptionFeeRatio));
        }
        bAmount = bAmount.reformat(_bDecimals);

        _liquidity = _liquidity.sub(bAmount);
        require(_tradersNetVolume == 0 || _calculateMarginRatio(_tradersNetVolume.neg(), _tradersNetCost.neg(), _price, _liquidity) >= _minPoolMarginRatio,
                "PerpetualPool: remove liquidity cause pool insufficient liquidity");

        _lToken.burn(msg.sender, lShares);
        _bToken.safeTransfer(msg.sender, bAmount.rescale(_bDecimals));

        emit RemoveLiquidity(msg.sender, lShares, bAmount);
    }

    /**
     * @dev Low level liquidate implementation
     */
    function _liquidate(address owner, uint256 timestamp, uint256 price) internal _lock_ {
        (int256 volume, int256 cost, , uint256 margin, uint256 lastUpdateTimestamp) = _pToken.getPosition(owner);
        require(timestamp > lastUpdateTimestamp, "PerpetualPool: liquidate price is before position timestamp");

        int256 pnl = volume.mul(price).mul(_multiplier).sub(cost);
        require(pnl.add(margin) <= 0 || _calculateMarginRatio(volume, cost, price, margin) < _minMaintenanceMarginRatio, "PerpetualPool: cannot liquidate");

        _liquidity = _liquidity.add(margin);
        _tradersNetVolume = _tradersNetVolume.sub(volume);
        _tradersNetCost = _tradersNetCost.sub(cost);
        _pToken.update(owner, 0, 0, 0, 0, 0);

        uint256 reward;
        if (margin <= _minLiquidationReward) {
            reward = _minLiquidationReward;
        } else if (margin >= _maxLiquidationReward) {
            reward = _maxLiquidationReward;
        } else {
            reward = margin.sub(_minLiquidationReward).mul(_liquidationCutRatio).add(_minLiquidationReward);
        }
        reward = reward.reformat(_bDecimals);

        _liquidity = _liquidity.sub(reward);
        _bToken.safeTransfer(msg.sender, reward.rescale(_bDecimals));

        emit Liquidate(owner, volume, cost, margin, timestamp, price, msg.sender, reward);
    }


    //================================================================================
    // Helpers
    //================================================================================

    /**
     * @dev Check if an address is a contract
     */
    function _isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     *                            margin + unrealizedPnl
     *@dev margin ratio = --------------------------------------
     *                       abs(volume) * price * multiplier
     *
     * volume cannot be zero
     */
    function _calculateMarginRatio(int256 volume, int256 cost, uint256 price, uint256 margin)
        internal view returns (uint256)
    {
        int256 value = volume.mul(price).mul(_multiplier);
        uint256 ratio = margin.add(value.sub(cost)).div(value.abs());
        return ratio;
    }

    /**
     *                          _tradersNetVolume * price * multiplier
     * @dev rate per block = ------------------------------------------- * coefficient
     *                                      _liquidity
     */
    function _updateCumuFundingRate(uint256 price) private {
        if (block.number > _cumuFundingRateBlock) {
            int256 rate;
            if (_liquidity != 0) {
                rate = _tradersNetVolume.mul(price).mul(_multiplier).mul(_fundingRateCoefficient).div(_liquidity);
            } else {
                rate = 0;
            }
            int256 delta = rate * (int256(block.number.sub(_cumuFundingRateBlock))); // overflow is intended
            _cumuFundingRate += delta; // overflow is intended
            _cumuFundingRateBlock = block.number;
        }
    }

    /**
     * @dev Check price signature
     */
    function _checkPriceSignature(uint256 timestamp, uint256 price, uint8 v, bytes32 r, bytes32 s)
        internal view
    {
        require(v == 27 || v == 28, "PerpetualPool: v not valid");
        bytes32 message = keccak256(abi.encodePacked(_symbol, timestamp, price));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address signer = ecrecover(hash, v, r, s);
        require(signer == address(_oracle), "PerpetualPool: price not signed by oracle");
    }

    /**
     * @dev Check price signature to verify if price is authorized, and update _price
     * only check/update once for one block
     */
    function _updatePriceWithSignature(
        uint256 timestamp, uint256 price, uint8 v, bytes32 r, bytes32 s
    ) internal
    {
        if (block.number != _lastPriceBlockNumber) {
            require(timestamp >= _lastPriceTimestamp, "PerpetualPool: price is not the newest");
            require(block.timestamp - timestamp <= _priceDelayAllowance, "PerpetualPool: price is older than allowance");

            _checkPriceSignature(timestamp, price, v, r, s);

            _price = price;
            _lastPriceTimestamp = timestamp;
            _lastPriceBlockNumber = block.number;
        }
    }

    /**
     * @dev Update price from on-chain Oracle
     */
    function _updatePriceFromOracle() internal {
        require(_isContractOracle, "PerpetualPool: wrong type of orcale");
        if (block.number != _lastPriceBlockNumber) {
            _price = _oracle.getPrice();
            _lastPriceBlockNumber = block.number;
        }
    }

    /**
     * @dev safeTransferFrom for base token with deflation protection
     * Returns the actual received amount in base token (as base 10**18)
     */
    function _deflationCompatibleSafeTransferFrom(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 preBalance = _bToken.balanceOf(to);
        _bToken.safeTransferFrom(from, to, amount.rescale(_bDecimals));
        uint256 curBalance = _bToken.balanceOf(to);

        uint256 a = curBalance.sub(preBalance);
        uint256 b = 10**18;
        uint256 c = a * b;
        require(c / b == a, "PreMiningPool: _deflationCompatibleSafeTransferFrom multiplication overflows");

        uint256 actualReceivedAmount = c / (10 ** _bDecimals);
        return actualReceivedAmount;
    }

}