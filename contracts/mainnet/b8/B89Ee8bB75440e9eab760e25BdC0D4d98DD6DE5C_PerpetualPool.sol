// SPDX-License-Identifier: MIT

// Version: 0.1.0, 1/20/2021

pragma solidity >=0.6.2 <0.8.0;

import "../interface/IERC20.sol";
import "../interface/IPToken.sol";
import "../interface/ILToken.sol";
import "../interface/IOracle.sol";
import "../interface/ILiquidatorQualifier.sol";
import "../interface/IMigratablePool.sol";
import "../interface/IPreMiningPool.sol";
import "../interface/IPerpetualPool.sol";
import "../utils/SafeERC20.sol";
import "../math/MixedSafeMathWithUnit.sol";
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

        // // migrate state values from PerpetualPool
        // (int256 cumuFundingRate, uint256 cumuFundingRateBlock, uint256 liquidity, int256 tradersNetVolume, int256 tradersNetCost) = IPerpetualPool(source).getStateValues();
        // _cumuFundingRate = cumuFundingRate;
        // _cumuFundingRateBlock = cumuFundingRateBlock;
        // _liquidity = liquidity;
        // _tradersNetVolume = tradersNetVolume;
        // _tradersNetCost = tradersNetCost;

        // migrate state values from PreMiningPool
        _liquidity = IPreMiningPool(source).getStateValues();

        emit ExecuteMigration(_migrationTimestamp, source, address(this));
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism.
     * `amount` is then deducted from the caller's allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title Deri Protocol non-fungible position token interface
 */
interface IPToken is IERC721 {

    /**
     * @dev Emitted when `owner`'s position is updated
     */
    event Update(
        address indexed owner,
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Position struct
     */
    struct Position {
        // Position volume, long is positive and short is negative
        int256 volume;
        // Position cost, long position cost is positive, short position cost is negative
        int256 cost;
        // The last cumuFundingRate since last funding settlement for this position
        // The overflow for this value is intended
        int256 lastCumuFundingRate;
        // Margin associated with this position
        uint256 margin;
        // Last timestamp this position updated
        uint256 lastUpdateTimestamp;
    }

    /**
     * @dev Set pool address of position token
     * pool is the only controller of this contract
     * can only be called by current pool
     */
    function setPool(address newPool) external;

    /**
     * @dev Returns address of current pool
     */
    function pool() external view returns (address);

    /**
     * @dev Returns the token collection name
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the total number of ever minted position tokens, including those burned
     */
    function totalMinted() external view returns (uint256);

    /**
     * @dev Returns the total number of existent position tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns if `owner` owns a position token in this contract
     */
    function exists(address owner) external view returns (bool);

    /**
     * @dev Returns if position token of `tokenId` exists
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns the position of owner `owner`
     *
     * `owner` must exist
     */
    function getPosition(address owner) external view returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Returns the position of token `tokenId`
     *
     * `tokenId` must exist
     */
    function getPosition(uint256 tokenId) external view returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Mint a position token for `owner` with intial margin of `margin`
     *
     * Can only be called by pool
     * `owner` cannot be zero address
     * `owner` must not exist before calling
     */
    function mint(address owner, uint256 margin) external;

    /**
     * @dev Update the position token for `owner`
     *
     * Can only be called by pool
     * `owner` must exist
     */
    function update(
        address owner,
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) external;

    /**
     * @dev Burn the position token owned of `owner`
     *
     * Can only be called by pool
     * `owner` must exist
     */
    function burn(address owner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC20.sol";

/**
 * @title Deri Protocol liquidity provider token interface
 */
interface ILToken is IERC20 {

    /**
     * @dev Set the pool address of this LToken
     * pool is the only controller of this contract
     * can only be called by current pool
     */
    function setPool(address newPool) external;

    /**
     * @dev Returns address of pool
     */
    function pool() external view returns (address);

    /**
     * @dev Mint LToken to `account` of `amount`
     *
     * Can only be called by pool
     * `account` cannot be zero address
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burn `amount` LToken of `account`
     *
     * Can only be called by pool
     * `account` cannot be zero address
     * `account` must owns at least `amount` LToken
     */
    function burn(address account, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @title Oracle interface
 */
interface IOracle {

    function getPrice() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @title Deri Protocol liquidator qualifier interface
 */
interface ILiquidatorQualifier {

    /**
     * @dev Check if `liquidator` is a qualified liquidator to call the `liquidate` function in PerpetualPool
     */
    function isQualifiedLiquidator(address liquidator) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Deri Protocol migratable pool interface
 */
interface IMigratablePool {

    /**
     * @dev Emitted when migration is prepared
     * `source` pool will be migrated to `target` pool after `migrationTimestamp`
     */
    event PrepareMigration(uint256 migrationTimestamp, address source, address target);

    /**
     * @dev Emmited when migration is executed
     * `source` pool is migrated to `target` pool
     */
    event ExecuteMigration(uint256 migrationTimestamp, address source, address target);

    /**
     * @dev Set controller to `newController`
     *
     * can only be called by current controller or the controller has not been set
     */
    function setController(address newController) external;

    /**
     * @dev Returns address of current controller
     */
    function controller() external view returns (address);

    /**
     * @dev Returns the migrationTimestamp of this pool, zero means not set
     */
    function migrationTimestamp() external view returns (uint256);

    /**
     * @dev Returns the destination pool this pool will migrate to after grace period
     * zero address means not set
     */
    function migrationDestination() external view returns (address);

    /**
     * @dev Prepare a migration from this pool to `newPool` with `graceDays` as grace period
     * `graceDays` must be at least 3 days from now, allow users to verify the `newPool` code
     *
     * can only be called by controller
     */
    function prepareMigration(address newPool, uint256 graceDays) external;

    /**
     * @dev Approve migration to `newPool` when grace period ends
     * after approvement, current pool will stop functioning
     *
     * can only be called by controller
     */
    function approveMigration() external;

    /**
     * @dev Called from the `newPool` to migrate from `source` pool
     * the grace period of `source` pool must ends
     * current pool must be the destination pool set before grace period in the `source` pool
     *
     * can only be called by controller
     */
    function executeMigration(address source) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IMigratablePool.sol";

/**
 * @title Deri Protocol PreMining PerpetualPool Interface
 */
interface IPreMiningPool is IMigratablePool {

    /**
     * @dev Emitted when `owner` add liquidity of `bAmount`,
     * and receive `lShares` liquidity token
     */
    event AddLiquidity(address indexed owner, uint256 lShares, uint256 bAmount);

    /**
     * @dev Emitted when `owner` burn `lShares` of liquidity token,
     * and receive `bAmount` in base token
     */
    event RemoveLiquidity(address indexed owner, uint256 lShares, uint256 bAmount);

    /**
     * @dev Initialize pool
     *
     * addresses:
     *      bToken
     *      lToken
     *
     * parameters:
     *      minAddLiquidity
     *      redemptionFeeRatio
     */
    function initialize(
        string memory symbol_,
        address[2] calldata addresses_,
        uint256[2] calldata parameters_
    ) external;

    /**
     * @dev Returns trading symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns addresses of (bToken, pToken, lToken, oracle) in this pool
     */
    function getAddresses() external view returns (
        address bToken,
        address lToken
    );

    /**
     * @dev Returns parameters of this pool
     */
    function getParameters() external view returns (
        uint256 minAddLiquidity,
        uint256 redemptionFeeRatio
    );

    /**
     * @dev Returns currents state values of this pool
     */
    function getStateValues() external view returns (
        uint256 liquidity
    );

    /**
     * @dev Add liquidity of `bAmount` in base token
     *
     * New liquidity provider token will be issued to the provider
     */
    function addLiquidity(uint256 bAmount) external;

    /**
     * @dev Remove `lShares` of liquidity provider token
     *
     * The liquidity provider token will be burned and
     * the corresponding amount in base token will be sent to provider
     */
    function removeLiquidity(uint256 lShares) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IMigratablePool.sol";

/**
 * @title Deri Protocol PerpetualPool Interface
 */
interface IPerpetualPool is IMigratablePool {

    /**
     * @dev Emitted when `owner` traded `tradeVolume` at `price` in pool
     */
    event Trade(address indexed owner, int256 tradeVolume, uint256 price);

    /**
     * @dev Emitted when `owner` deposit margin of `bAmount` in base token
     */
    event DepositMargin(address indexed owner, uint256 bAmount);

    /**
     * @dev Emitted when `owner` withdraw margin of `bAmount` in base token
     */
    event WithdrawMargin(address indexed owner, uint256 bAmount);

    /**
     * @dev Emitted when `owner` add liquidity of `bAmount`,
     * and receive `lShares` liquidity token
     */
    event AddLiquidity(address indexed owner, uint256 lShares, uint256 bAmount);

    /**
     * @dev Emitted when `owner` burn `lShares` of liquidity token,
     * and receive `bAmount` in base token
     */
    event RemoveLiquidity(address indexed owner, uint256 lShares, uint256 bAmount);

    /**
     * @dev Emitted when `owner`'s position is liquidated
     */
    event Liquidate(
        address indexed owner,
        int256 volume,
        int256 cost,
        uint256 margin,
        uint256 timestamp,
        uint256 price,
        address liquidator,
        uint256 reward
    );

    /**
     * @dev Initialize pool
     *
     * addresses:
     *      bToken
     *      pToken
     *      lToken
     *      oracle
     *      liquidatorQualifier
     *
     * parameters:
     *      multiplier
     *      feeRatio
     *      minPoolMarginRatio
     *      minInitialMarginRatio
     *      minMaintenanceMarginRatio
     *      minAddLiquidity
     *      redemptionFeeRatio
     *      fundingRateCoefficient
     *      minLiquidationReward
     *      maxLiquidationReward
     *      liquidationCutRatio
     *      priceDelayAllowance
     */
    function initialize(
        string memory symbol_,
        address[5] calldata addresses_,
        uint256[12] calldata parameters_
    ) external;

    /**
     * @dev Returns trading symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns addresses of (bToken, pToken, lToken, oracle) in this pool
     */
    function getAddresses() external view returns (
        address bToken,
        address pToken,
        address lToken,
        address oracle,
        address liquidatorQualifier
    );

    /**
     * @dev Returns parameters of this pool
     */
    function getParameters() external view returns (
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
    );

    /**
     * @dev Returns currents state values of this pool
     */
    function getStateValues() external view returns (
        int256 cumuFundingRate,
        uint256 cumuFundingRateBlock,
        uint256 liquidity,
        int256 tradersNetVolume,
        int256 tradersNetCost
    );

    /**
     * @dev Trade `tradeVolume` with pool while deposit margin of `bAmount` in base token
     * This function is the combination of `depositMargin` and `trade`
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function tradeWithMargin(int256 tradeVolume, uint256 bAmount) external;
    function tradeWithMargin(
        int256 tradeVolume,
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Trade `tradeVolume` with pool
     *
     * A trader must hold a Position Token (with sufficient margin in PToken)
     * before calling this function
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function trade(int256 tradeVolume) external;
    function trade(
        int256 tradeVolume,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Deposit margin of `bAmount` in base token
     *
     * If trader does not hold position token, a new position token will be minted
     * to trader with supplied margin
     * Otherwise, the position token of trader will be updated with added margin
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function depositMargin(uint256 bAmount) external;
    function depositMargin(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Withdraw margin of `bAmount` in base token
     *
     * Trader must hold a position token
     * If trader holds any open position in position token, the left margin after withdraw
     * must be sufficient for the open position
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function withdrawMargin(uint256 bAmount) external;
    function withdrawMargin(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Add liquidity of `bAmount` in base token
     *
     * New liquidity provider token will be issued to the provider
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function addLiquidity(uint256 bAmount) external;
    function addLiquidity(
        uint256 bAmount,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Remove `lShares` of liquidity provider token
     *
     * The liquidity provider token will be burned and
     * the corresponding amount in base token will be sent to provider
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function removeLiquidity(uint256 lShares) external;
    function removeLiquidity(
        uint256 lShares,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Liquidate the position owned by `owner`
     * Anyone can call this function to liquidate a position, as long as the liquidation line
     * is touched, the liquidator will be rewarded
     *
     * The first version is implemented with an on-chain oracle contract
     * The second version is implemented with off-chain price provider with signature
     */
    function liquidate(address owner) external;
    function liquidate(
        address owner,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interface/IERC20.sol";
import "../math/UnsignedSafeMath.sol";
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
    using UnsignedSafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Mixed safe math with base unit of 10**18
 */
library MixedSafeMathWithUnit {

    uint256 constant UONE = 10**18;
    uint256 constant UMAX = 2**255 - 1;

    int256 constant IONE = 10**18;
    int256 constant IMIN = -2**255;

    //================================================================================
    // Conversions
    //================================================================================

    /**
     * @dev Convert uint256 to int256
     */
    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, "MixedSafeMathWithUnit: convert uint256 to int256 overflow");
        int256 b = int256(a);
        return b;
    }

    /**
     * @dev Convert int256 to uint256
     */
    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, "MixedSafeMathWithUnit: convert int256 to uint256 overflow");
        uint256 b = uint256(a);
        return b;
    }

    /**
     * @dev Take abs of int256
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, "MixedSafeMathWithUnit: int256 abs overflow");
        if (a >= 0) {
            return a;
        } else {
            return -a;
        }
    }

    /**
     * @dev Take negation of int256
     */
    function neg(int256 a) internal pure returns (int256) {
        require(a != IMIN, "MixedSafeMathWithUnit: int256 negate overflow");
        return -a;
    }

    //================================================================================
    // Rescale and reformat
    //================================================================================

    function _rescale(uint256 a, uint256 decimals1, uint256 decimals2)
        internal pure returns (uint256)
    {
        uint256 scale1 = 10 ** decimals1;
        uint256 scale2 = 10 ** decimals2;
        uint256 b = a * scale2;
        require(b / scale2 == a, "MixedSafeMathWithUnit: rescale uint256 overflow");
        uint256 c = b / scale1;
        return c;
    }

    function _rescale(int256 a, uint256 decimals1, uint256 decimals2)
        internal pure returns (int256)
    {
        int256 scale1 = utoi(10 ** decimals1);
        int256 scale2 = utoi(10 ** decimals2);
        int256 b = a * scale2;
        require(b / scale2 == a, "MixedSafeMathWithUnit: rescale int256 overflow");
        int256 c = b / scale1;
        return c;
    }

    /**
     * @dev Rescales a value from 10**18 base to 10**decimals base
     */
    function rescale(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return _rescale(a, 18, decimals);
    }

    function rescale(int256 a, uint256 decimals) internal pure returns (int256) {
        return _rescale(a, 18, decimals);
    }

    /**
     * @dev Reformat a value to be a valid 10**decimals base value
     * The formatted value is still in 10**18 base
     */
    function reformat(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return _rescale(_rescale(a, 18, decimals), decimals, 18);
    }

    function reformat(int256 a, uint256 decimals) internal pure returns (int256) {
        return _rescale(_rescale(a, 18, decimals), decimals, 18);
    }


    //================================================================================
    // Addition
    //================================================================================

    /**
     * @dev Addition: uint256 + uint256
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "MixedSafeMathWithUnit: uint256 addition overflow");
        return c;
    }

    /**
     * @dev Addition: int256 + int256
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "MixedSafeMathWithUnit: int256 addition overflow"
        );
        return c;
    }

    /**
     * @dev Addition: uint256 + int256
     * uint256(-b) will not overflow when b is IMIN
     */
    function add(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return add(a, uint256(b));
        } else {
            return sub(a, uint256(-b));
        }
    }

    /**
     * @dev Addition: int256 + uint256
     */
    function add(int256 a, uint256 b) internal pure returns (int256) {
        return add(a, utoi(b));
    }

    //================================================================================
    // Subtraction
    //================================================================================

    /**
     * @dev Subtraction: uint256 - uint256
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "MixedSafeMathWithUnit: uint256 subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Subtraction: int256 - int256
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "MixedSafeMathWithUnit: int256 subtraction overflow"
        );
        return c;
    }

    /**
     * @dev Subtraction: uint256 - int256
     * uint256(-b) will not overflow when b is IMIN
     */
    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return sub(a, uint256(b));
        } else {
            return add(a, uint256(-b));
        }
    }

    /**
     * @dev Subtraction: int256 - uint256
     */
    function sub(int256 a, uint256 b) internal pure returns (int256) {
        return sub(a, utoi(b));
    }

    //================================================================================
    // Multiplication
    //================================================================================

    /**
     * @dev Multiplication: uint256 * uint256
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "MixedSafeMathWithUnit: uint256 multiplication overflow");
        return c / UONE;
    }

    /**
     * @dev Multiplication: int256 * int256
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        require(!(a == -1 && b == IMIN), "MixedSafeMathWithUnit: int256 multiplication overflow");
        int256 c = a * b;
        require(c / a == b, "MixedSafeMathWithUnit: int256 multiplication overflow");
        return c / IONE;
    }

    /**
     * @dev Multiplication: uint256 * int256
     */
    function mul(uint256 a, int256 b) internal pure returns (uint256) {
        return mul(a, itou(b));
    }

    /**
     * @dev Multiplication: int256 * uint256
     */
    function mul(int256 a, uint256 b) internal pure returns (int256) {
        return mul(a, utoi(b));
    }

    //================================================================================
    // Division
    //================================================================================

    /**
     * @dev Division: uint256 / uint256
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MixedSafeMathWithUnit: uint256 division by zero");
        uint256 c = a * UONE;
        require(
            c / UONE == a,
            "MixedSafeMathWithUnit: uint256 division internal multiplication overflow"
        );
        uint256 d = c / b;
        return d;
    }

    /**
     * @dev Division: int256 / int256
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "MixedSafeMathWithUnit: int256 division by zero");
        int256 c = a * IONE;
        require(
            c / IONE == a,
            "MixedSafeMathWithUnit: int256 division internal multiplication overflow"
        );
        require(!(c == IMIN && b == -1), "MixedSafeMathWithUnit: int256 division overflow");
        int256 d = c / b;
        return d;
    }

    /**
     * @dev Division: uint256 / int256
     */
    function div(uint256 a, int256 b) internal pure returns (uint256) {
        return div(a, itou(b));
    }

    /**
     * @dev Division: int256 / uint256
     */
    function div(int256 a, uint256 b) internal pure returns (int256) {
        return div(a, utoi(b));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interface/IMigratablePool.sol";

/**
 * @dev Deri Protocol migratable pool implementation
 */
abstract contract MigratablePool is IMigratablePool {

    // Controller address
    address _controller;

    // Migration timestamp of this pool, zero means not set
    // Migration timestamp can only be set with a grace period at least 3 days, and the
    // `migrationDestination` pool address must be also set when setting migration timestamp,
    // users can use this grace period to verify the `migrationDestination` pool code
    uint256 _migrationTimestamp;

    // The new pool this pool will migrate to after grace period, zero address means not set
    address _migrationDestination;

    modifier _controller_() {
        require(msg.sender == _controller, "can only be called by current controller");
        _;
    }

    /**
     * @dev See {IMigratablePool}.{setController}
     */
    function setController(address newController) public override {
        require(newController != address(0), "MigratablePool: setController to 0 address");
        require(
            _controller == address(0) || msg.sender == _controller,
            "MigratablePool: setController can only be called by current controller or not set"
        );
        _controller = newController;
    }

    /**
     * @dev See {IMigratablePool}.{controller}
     */
    function controller() public view override returns (address) {
        return _controller;
    }

    /**
     * @dev See {IMigratablePool}.{migrationTimestamp}
     */
    function migrationTimestamp() public view override returns (uint256) {
        return _migrationTimestamp;
    }

    /**
     * @dev See {IMigratablePool}.{migrationDestination}
     */
    function migrationDestination() public view override returns (address) {
        return _migrationDestination;
    }

    /**
     * @dev See {IMigratablePool}.{prepareMigration}
     */
    function prepareMigration(address newPool, uint256 graceDays) public override _controller_ {
        require(newPool != address(0), "MigratablePool: prepareMigration to 0 address");
        require(graceDays >= 3 && graceDays <= 365, "MigratablePool: graceDays must be 3-365 days");

        _migrationTimestamp = block.timestamp + graceDays * 1 days;
        _migrationDestination = newPool;

        emit PrepareMigration(_migrationTimestamp, address(this), _migrationDestination);
    }

    /**
     * @dev See {IMigratablePool}.{approveMigration}
     *
     * This function will be implemented in inheriting contract
     * This function will change if there is an upgrade to existent pool
     */
    // function approveMigration() public virtual override _controller_ {}

    /**
     * @dev See {IMigratablePool}.{executeMigration}
     *
     * This function will be implemented in inheriting contract
     * This function will change if there is an upgrade to existent pool
     */
    // function executeMigration(address source) public virtual override _controller_ {}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Unsigned safe math
 */
library UnsignedSafeMath {

    /**
     * @dev Addition of unsigned integers, counterpart to `+`
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "UnsignedSafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Subtraction of unsigned integers, counterpart to `-`
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "UnsignedSafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Multiplication of unsigned integers, counterpart to `*`
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "UnsignedSafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Division of unsigned integers, counterpart to `/`
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "UnsignedSafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Modulo of unsigned integers, counterpart to `%`
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "UnsignedSafeMath: modulo by zero");
        uint256 c = a % b;
        return c;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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