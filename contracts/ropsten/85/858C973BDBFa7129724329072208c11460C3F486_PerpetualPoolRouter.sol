// SPDX-License-Identifier: MIT

import '../interface/IERC20.sol';
import '../interface/IBTokenSwapper.sol';
import '../interface/IOracleWithUpdate.sol';
import '../interface/IPToken.sol';
import '../interface/ILToken.sol';
import '../interface/IPerpetualPool.sol';
import '../interface/IPerpetualPoolRouter.sol';
import '../interface/ILiquidatorQualifier.sol';
import '../library/SafeMath.sol';
import '../utils/Migratable.sol';

pragma solidity >=0.8.0 <0.9.0;

contract PerpetualPoolRouter is IPerpetualPoolRouter, Migratable {

    using SafeMath for uint256;
    using SafeMath for int256;

    address _pool;
    address _liquidatorQualifierAddress;
    address immutable _lTokenAddress;
    address immutable _pTokenAddress;

    constructor (
        address lTokenAddress,
        address pTokenAddress,
        address liquidatorQualifierAddress
    ) {
        _lTokenAddress = lTokenAddress;
        _pTokenAddress = pTokenAddress;
        _liquidatorQualifierAddress = liquidatorQualifierAddress;

        _controller = msg.sender;
    }

    function pool() external override view returns (address) {
        return _pool;
    }

    function liquidatorQualifier() external override view returns (address) {
        return _liquidatorQualifierAddress;
    }

    function setPool(address poolAddress) external override _controller_ {
        _pool = poolAddress;
    }

    function setLiquidatorQualifier(address qualifierAddress) external override _controller_ {
        _liquidatorQualifierAddress = qualifierAddress;
    }

    // during a migration, this function is intended to be called in the source router
    function approveMigration() external override _controller_ {
        require(_migrationTimestamp != 0 && block.timestamp >= _migrationTimestamp, 'migration time not met');
        address targetPool = IPerpetualPoolRouter(_migrationDestination).pool();
        IPerpetualPool(_pool).approvePoolMigration(targetPool);
    }

    // during a migration, this function is intended to be called in the target router
    function executeMigration(address sourceRouter) external override _controller_ {
        uint256 migrationTimestamp_ = IPerpetualPoolRouter(sourceRouter).migrationTimestamp();
        address migrationDestination_ = IPerpetualPoolRouter(sourceRouter).migrationDestination();

        require(migrationTimestamp_ != 0 && block.timestamp >= migrationTimestamp_, 'migration time not met');
        require(migrationDestination_ == address(this), 'migration wrong target');

        address sourcePool = IPerpetualPoolRouter(sourceRouter).pool();
        IPerpetualPool(_pool).executePoolMigration(sourcePool);
    }

    function addBToken(
        address bTokenAddress,
        address swapperAddress,
        address oracleAddress,
        uint256 discount
    )
        external override _controller_
    {
        IPerpetualPool.BTokenInfo memory b;
        b.bTokenAddress = bTokenAddress;
        b.swapperAddress = swapperAddress;
        b.oracleAddress = oracleAddress;
        b.decimals = IERC20(bTokenAddress).decimals();
        b.discount = int256(discount);
        IPerpetualPool(_pool).addBToken(b);
    }

    function addSymbol(
        string memory symbol,
        address oracleAddress,
        uint256 multiplier,
        uint256 feeRatio,
        uint256 fundingRateCoefficient
    )
        external override _controller_
    {
        IPerpetualPool.SymbolInfo memory s;
        s.symbol = symbol;
        s.oracleAddress = oracleAddress;
        s.multiplier = int256(multiplier);
        s.feeRatio = int256(feeRatio);
        s.fundingRateCoefficient = int256(fundingRateCoefficient);
        IPerpetualPool(_pool).addSymbol(s);
    }

    function setBTokenParameters(
        uint256 bTokenId,
        address swapperAddress,
        address oracleAddress,
        uint256 discount
    )
        external override _controller_
    {
        IPerpetualPool(_pool).setBTokenParameters(bTokenId, swapperAddress, oracleAddress, discount);
    }

    function setSymbolParameters(
        uint256 symbolId,
        address oracleAddress,
        uint256 feeRatio,
        uint256 fundingRateCoefficient
    )
        external override _controller_
    {
        IPerpetualPool(_pool).setSymbolParameters(symbolId, oracleAddress, feeRatio, fundingRateCoefficient);
    }


    //================================================================================
    // Interactions Set1
    //================================================================================

    function addLiquidity(uint256 bTokenId, uint256 bAmount) public override {
        IPerpetualPool p = IPerpetualPool(_pool);
        (uint256 blength, uint256 slength) = p.getLengths();

        require(bTokenId < blength, 'invalid bTokenId');

        p.addLiquidity(msg.sender, bTokenId, bAmount, blength, slength);
    }

    function removeLiquidity(uint256 bTokenId, uint256 bAmount) public override {
        IPerpetualPool p = IPerpetualPool(_pool);
        (uint256 blength, uint256 slength) = p.getLengths();

        address owner = msg.sender;
        require(bTokenId < blength, 'invalid bTokenId');
        require(ILToken(_lTokenAddress).exists(owner), 'not lp');

        p.removeLiquidity(owner, bTokenId, bAmount, blength, slength);
    }

    function addMargin(uint256 bTokenId, uint256 bAmount) public override {
        IPerpetualPool p = IPerpetualPool(_pool);
        (uint256 blength, ) = p.getLengths();

        require(bTokenId < blength, 'invalid bTokenId');

        p.addMargin(msg.sender, bTokenId, bAmount);
        if (bTokenId != 0) _checkBTokenMarginLimit(bTokenId);
    }

    function removeMargin(uint256 bTokenId, uint256 bAmount) public override {
        IPerpetualPool p = IPerpetualPool(_pool);
        (uint256 blength, uint256 slength) = p.getLengths();

        address owner = msg.sender;
        require(bTokenId < blength, 'invalid bTokenId');
        require(IPToken(_pTokenAddress).exists(owner), 'no trade / no pos');

        p.removeMargin(owner, bTokenId, bAmount, blength, slength);
    }

    function trade(uint256 symbolId, int256 tradeVolume) public override {
        IPerpetualPool p = IPerpetualPool(_pool);
        (uint256 blength, uint256 slength) = p.getLengths();

        address owner = msg.sender;
        require(symbolId < slength, 'invalid symbolId');
        require(IPToken(_pTokenAddress).exists(owner), 'no trade / no pos');

        p.trade(owner, symbolId, tradeVolume, blength, slength);
    }

    function liquidate(address owner) public override {
        IPerpetualPool p = IPerpetualPool(_pool);
        (uint256 blength, uint256 slength) = p.getLengths();

        address liquidator = msg.sender;
        require(IPToken(_pTokenAddress).exists(owner), 'no trade / no pos');
        require(_liquidatorQualifierAddress == address(0) || ILiquidatorQualifier(_liquidatorQualifierAddress).isQualifiedLiquidator(liquidator),
                'not qualified');

        p.liquidate(liquidator, owner, blength, slength);
    }


    //================================================================================
    // Interactions Set2 (supporting oracles which need manual update)
    //================================================================================

    function addLiquidityWithPrices(uint256 bTokenId, uint256 bAmount, PriceInfo[] memory infos) external override {
        _updateSymbolOracles(infos);
        addLiquidity(bTokenId, bAmount);
    }

    function removeLiquidityWithPrices(uint256 bTokenId, uint256 bAmount, PriceInfo[] memory infos) external override {
        _updateSymbolOracles(infos);
        removeLiquidity(bTokenId, bAmount);
    }

    function addMarginWithPrices(uint256 bTokenId, uint256 bAmount, PriceInfo[] memory infos) external override {
        _updateSymbolOracles(infos);
        addMargin(bTokenId, bAmount);
    }

    function removeMarginWithPrices(uint256 bTokenId, uint256 bAmount, PriceInfo[] memory infos) external override {
        _updateSymbolOracles(infos);
        removeMargin(bTokenId, bAmount);
    }

    function tradeWithPrices(uint256 symbolId, int256 tradeVolume, PriceInfo[] memory infos) external override {
        _updateSymbolOracles(infos);
        trade(symbolId, tradeVolume);
    }

    function liquidateWithPrices(address owner, PriceInfo[] memory infos) external override {
        _updateSymbolOracles(infos);
        liquidate(owner);
    }


    //================================================================================
    // Helpers
    //================================================================================

    function _updateSymbolOracles(PriceInfo[] memory infos) internal {
        for (uint256 i = 0; i < infos.length; i++) {
            address oracle = IPerpetualPool(_pool).getSymbolOracle(infos[i].symbolId);
            IOracleWithUpdate(oracle).updatePrice(infos[i].timestamp, infos[i].price, infos[i].v, infos[i].r, infos[i].s);
        }
    }

    function _checkBTokenMarginLimit(uint256 bTokenId) internal view {
        IPerpetualPool.BTokenInfo memory b = IPerpetualPool(_pool).getBToken(bTokenId);
        IERC20 bToken = IERC20(b.bTokenAddress);
        uint256 balance = bToken.balanceOf(_pool).rescale(bToken.decimals(), 18);
        uint256 marginBX = balance - b.liquidity.itou();
        uint256 limit = IBTokenSwapper(b.swapperAddress).getLimitBX();
        require(marginBX < limit, 'margin in bTokenX exceeds swapper liquidity limit');
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

interface IOracleWithUpdate {

    function getPrice() external returns (uint256);

    function updatePrice(uint256 timestamp, uint256 price, uint8 v, bytes32 r, bytes32 s) external;

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

import '../interface/IMigratable.sol';

interface IPerpetualPoolRouter is IMigratable {

    struct PriceInfo {
        uint256 symbolId;
        uint256 timestamp;
        uint256 price;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function pool() external view returns (address);

    function liquidatorQualifier() external view returns (address);

    function setPool(address poolAddress) external;

    function setLiquidatorQualifier(address qualifier) external;

    function addBToken(
        address bTokenAddress,
        address swapperAddress,
        address oracleAddress,
        uint256 discount
    ) external;

    function addSymbol(
        string memory symbol,
        address oracleAddress,
        uint256 multiplier,
        uint256 feeRatio,
        uint256 fundingRateCoefficient
    ) external;

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
        uint256 fundingRateCoefficient
    ) external;


    function addLiquidity(uint256 bTokenId, uint256 bAmount) external;

    function removeLiquidity(uint256 bTokenId, uint256 bAmount) external;

    function addMargin(uint256 bTokenId, uint256 bAmount) external;

    function removeMargin(uint256 bTokenId, uint256 bAmount) external;

    function trade(uint256 symbolId, int256 tradeVolume) external;

    function liquidate(address owner) external;

    function addLiquidityWithPrices(uint256 bTokenId, uint256 bAmount, PriceInfo[] memory infos) external;

    function removeLiquidityWithPrices(uint256 bTokenId, uint256 bAmount, PriceInfo[] memory infos) external;

    function addMarginWithPrices(uint256 bTokenId, uint256 bAmount, PriceInfo[] memory infos) external;

    function removeMarginWithPrices(uint256 bTokenId, uint256 bAmount, PriceInfo[] memory infos) external;

    function tradeWithPrices(uint256 symbolId, int256 tradeVolume, PriceInfo[] memory infos) external;

    function liquidateWithPrices(address owner, PriceInfo[] memory infos) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ILiquidatorQualifier {

    function isQualifiedLiquidator(address liquidator) external view returns (bool);

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

import '../interface/IMigratable.sol';
import './Ownable.sol';

abstract contract Migratable is IMigratable, Ownable {

    // migration timestamp, zero means not set
    // migration timestamp can only be set with a grace period, e.x. 3-365 days, and the
    // migration destination must also be set when setting migration timestamp
    // users can use this grace period to verify the desination contract code
    uint256 _migrationTimestamp;

    // the destination address the source contract will migrate to, after the grace period
    address _migrationDestination;

    function migrationTimestamp() public override view returns (uint256) {
        return _migrationTimestamp;
    }

    function migrationDestination() public override view returns (address) {
        return _migrationDestination;
    }

    // prepare a migration process, the timestamp and desination will be set at this stage
    // and the migration grace period starts
    function prepareMigration(address target, uint256 graceDays) public override _controller_ {
        require(target != address(0), 'Migratable: target 0');
        require(graceDays >= 3 && graceDays <= 365, 'Migratable: graceDays must be 3-365');

        _migrationTimestamp = block.timestamp + graceDays * 1 days;
        _migrationDestination = target;

        emit PrepareMigration(_migrationTimestamp, address(this), _migrationDestination);
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

import './IOwnable.sol';

interface IMigratable is IOwnable {

    event PrepareMigration(uint256 migrationTimestamp, address source, address target);

    event ExecuteMigration(uint256 migrationTimestamp, address source, address target);

    function migrationTimestamp() external view returns (uint256);

    function migrationDestination() external view returns (address);

    function prepareMigration(address target, uint256 graceDays) external;

    function approveMigration() external;

    function executeMigration(address source) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOwnable {

    event ChangeController(address oldController, address newController);

    function controller() external view returns (address);

    function setNewController(address newController) external;

    function claimNewController() external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IOwnable.sol';

abstract contract Ownable is IOwnable {

    address _controller;

    address _newController;

    modifier _controller_() {
        require(msg.sender == _controller, 'Ownable: only controller');
        _;
    }

    function controller() public override view returns (address) {
        return _controller;
    }

    function setNewController(address newController) public override _controller_ {
        _newController = newController;
    }

    // a claim step is needed to prevent set controller to a wrong address and forever lost control
    function claimNewController() public override {
        require(msg.sender == _newController, 'Ownable: not allowed');
        emit ChangeController(_controller, _newController);
        _controller = _newController;
        delete _newController;
    }

}

