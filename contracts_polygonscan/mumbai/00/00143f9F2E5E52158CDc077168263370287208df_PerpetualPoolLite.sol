// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../polygon/Interfaces.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./library/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../polygon/governance/FuturesProtocolParameters.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract PerpetualPoolLite is IPerpetualPoolLite, Initializable {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    int256 private constant ONE = 10**18;

    uint256 private  _decimals;

    address private  _bTokenAddress;
    address private  _lTokenAddress;
    address private  _pTokenAddress;
    address private  _liquidatorQualifierAddress;
    address private  _protocolFeeCollector;
    address private  _underlyingAddress;
    address private immutable _protocolAddress;
    FuturesProtocolParameters immutable private _protocolParameters;

    int256 private _liquidity;

    uint256 private _lastUpdateBlock;
    int256 private _protocolFeeAccrued;

    // symbolId => SymbolInfo
    SymbolInfo private _symbol;

    bool private _mutex;
    modifier _lock_() {
        require(!_mutex, "reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    constructor(address[2] memory addresses) {
        _protocolAddress = addresses[0];
        _protocolParameters = FuturesProtocolParameters(addresses[0]);
        _decimals = 18;
    }

    function initialize(address[6] memory addresses) external initializer {
        _bTokenAddress = addresses[0];
        _lTokenAddress = addresses[1];
        _pTokenAddress = addresses[2];
        _liquidatorQualifierAddress = addresses[3];
        _protocolFeeCollector = addresses[4];
        _underlyingAddress = addresses[5];
    }

    function getSymbolPriceAndMultiplier() external view returns (int256 price, int256 multiplier) {
        return (_symbol.price, _protocolParameters.futuresMultiplier());
    }

    function getParameters()
        external
        view
        override
        returns (
            int256 minPoolMarginRatio,
            int256 minInitialMarginRatio,
            int256 minMaintenanceMarginRatio,
            int256 minLiquidationReward,
            int256 maxLiquidationReward,
            int256 liquidationCutRatio,
            int256 protocolFeeCollectRatio
        )
    {
        return (
            _protocolParameters.minPoolMarginRatio(),
            _protocolParameters.minInitialMarginRatio(),
            _protocolParameters.minMaintenanceMarginRatio(),
            _protocolParameters.minLiquidationReward(),
            _protocolParameters.maxLiquidationReward(),
            _protocolParameters.liquidationCutRatio(),
            _protocolParameters.protocolFeeCollectRatio()
        );
    }

    function getAddresses()
        external
        view
        override
        returns (
            address bTokenAddress,
            address lTokenAddress,
            address pTokenAddress,
            address liquidatorQualifierAddress,
            address protocolFeeCollector,
            address underlyingAddress,
            address protocolAddress
        )
    {
        return (
            _bTokenAddress,
            _lTokenAddress,
            _pTokenAddress,
            _liquidatorQualifierAddress,
            _protocolFeeCollector,
            _underlyingAddress,
            _protocolAddress
        );
    }

    function getSymbol() external view override returns (SymbolInfo memory) {
        return _symbol;
    }

    function getLiquidity() external view override returns (int256) {
        return _liquidity;
    }

    function getLastUpdateBlock() external view override returns (uint256) {
        return _lastUpdateBlock;
    }

    function getProtocolFeeAccrued() external view override returns (int256) {
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

    //================================================================================
    // Interactions with onchain oracles
    //================================================================================

    function addLiquidity(uint256 bAmount) external override {
        require(bAmount > 0, "PerpetualPool: 0 bAmount");
        _addLiquidity(msg.sender, bAmount);
    }

    function removeLiquidity(uint256 lShares) external override {
        require(lShares > 0, "PerpetualPool: 0 lShares");
        _removeLiquidity(msg.sender, lShares);
    }

    function addMargin(uint256 bAmount) external override {
        require(bAmount > 0, "PerpetualPool: 0 bAmount");
        _addMargin(msg.sender, bAmount);
    }

    function removeMargin(uint256 bAmount) external override {
        require(bAmount > 0, "PerpetualPool: 0 bAmount");
        _removeMargin(msg.sender, bAmount);
    }

    function trade(int256 tradeVolume) external override {
        require(
            tradeVolume != 0 && (tradeVolume / ONE) * ONE == tradeVolume,
            "PerpetualPool: invalid tradeVolume"
        );
        _trade(msg.sender, tradeVolume);
    }

    function liquidate(address account) external override {
        address liquidator = msg.sender;
        require(
            _liquidatorQualifierAddress == address(0) ||
                ILiquidatorQualifier(_liquidatorQualifierAddress).isQualifiedLiquidator(liquidator),
            "PerpetualPool: not qualified liquidator"
        );
        _liquidate(liquidator, account);
    }

    //================================================================================
    // Interactions with offchain oracles
    //================================================================================

    function addLiquidity(uint256 bAmount, SignedPrice memory price) external override {
        require(bAmount > 0, "PerpetualPool: 0 bAmount");
        _updateSymbolOracles(price);
        _addLiquidity(msg.sender, bAmount);
    }

    function removeLiquidity(uint256 lShares, SignedPrice memory price) external override {
        require(lShares > 0, "PerpetualPool: 0 lShares");
        _updateSymbolOracles(price);
        _removeLiquidity(msg.sender, lShares);
    }

    function addMargin(uint256 bAmount, SignedPrice memory price) external override {
        require(bAmount > 0, "PerpetualPool: 0 bAmount");
        _updateSymbolOracles(price);
        _addMargin(msg.sender, bAmount);
    }

    function removeMargin(uint256 bAmount, SignedPrice memory price) external override {
        require(bAmount > 0, "PerpetualPool: 0 bAmount");
        _updateSymbolOracles(price);
        _removeMargin(msg.sender, bAmount);
    }

    function trade(int256 tradeVolume, SignedPrice memory price) external override {
        require(
            tradeVolume != 0 && (tradeVolume / ONE) * ONE == tradeVolume,
            "PerpetualPool: invalid tradeVolume"
        );
        _updateSymbolOracles(price);
        _trade(msg.sender, tradeVolume);
    }

    function liquidate(address account, SignedPrice memory price) external override {
        address liquidator = msg.sender;
        require(
            _liquidatorQualifierAddress == address(0) ||
                ILiquidatorQualifier(_liquidatorQualifierAddress).isQualifiedLiquidator(liquidator),
            "PerpetualPool: not qualified liquidator"
        );
        _updateSymbolOracles(price);
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
            lShares = (bAmount * totalSupply) / totalDynamicEquity.itou();
        }

        lToken.mint(account, lShares);
        _liquidity += bAmount.utoi();

        emit AddLiquidity(account, lShares, bAmount);
    }

    function _removeLiquidity(address account, uint256 lShares) internal _lock_ {
        (int256 totalDynamicEquity, int256 totalAbsCost) = _updateSymbolPricesAndFundingRates();
        ILTokenLite lToken = ILTokenLite(_lTokenAddress);

        uint256 totalSupply = lToken.totalSupply();
        uint256 bAmount = (lShares * totalDynamicEquity.itou()) / totalSupply;

        _liquidity -= bAmount.utoi();

        require(
            totalAbsCost == 0 ||
                ((totalDynamicEquity - bAmount.utoi()) * ONE) / totalAbsCost >=
                _protocolParameters.minPoolMarginRatio(),
            "PerpetualPool: pool insufficient margin"
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
        (IPTokenLite.Position memory position, int256 margin) = _settleTraderFundingFee(account);

        int256 amount = bAmount.utoi();
        if (amount >= margin) {
            amount = margin;
            bAmount = amount.itou();
            margin = 0;
        } else {
            margin -= amount;
        }

        require(
            _getTraderMarginRatio(position, margin) >= _protocolParameters.minInitialMarginRatio(),
            "PerpetualPool: insufficient margin"
        );

        _updateTraderPortfolio(account, position, margin);
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

    function _trade(address account, int256 tradeVolume) internal _lock_ {
        (int256 totalDynamicEquity, int256 totalAbsCost) = _updateSymbolPricesAndFundingRates();
        (IPTokenLite.Position memory position, int256 margin) = _settleTraderFundingFee(account);

        TradeParams memory params;

        params.tradersNetVolume = _symbol.tradersNetVolume;
        params.price = _symbol.price;
        params.multiplier = _protocolParameters.futuresMultiplier();
        params.curCost = (((tradeVolume * params.price) / ONE) * params.multiplier) / ONE;
        params.fee = (params.curCost.abs() * _protocolParameters.futuresFeeRatio()) / ONE;

        if (!(position.volume >= 0 && tradeVolume >= 0) && !(position.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = position.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                // previous position is totally closed
                params.realizedCost = (params.curCost * absVolume) / absTradeVolume + position.cost;
            } else {
                // previous position is partially closed
                params.realizedCost = (position.cost * absTradeVolume) / absVolume + params.curCost;
            }
        }

        // adjust totalAbsCost after trading
        totalAbsCost +=
            (((((params.tradersNetVolume + tradeVolume).abs() - params.tradersNetVolume.abs()) *
                params.price) / ONE) * params.multiplier) /
            ONE;

        position.volume += tradeVolume;
        position.cost += params.curCost - params.realizedCost;
        position.lastCumulativeFundingRate = _symbol.cumulativeFundingRate;
        margin -= params.fee + params.realizedCost;

        _symbol.tradersNetVolume += tradeVolume;
        _symbol.tradersNetCost += params.curCost - params.realizedCost;
        params.protocolFee = (params.fee * _protocolParameters.protocolFeeCollectRatio()) / ONE;
        _protocolFeeAccrued += params.protocolFee;
        _liquidity += params.fee - params.protocolFee + params.realizedCost;

        require(
            totalAbsCost == 0 ||
                (totalDynamicEquity * ONE) / totalAbsCost >= _protocolParameters.minPoolMarginRatio(),
            "PerpetualPool: insufficient liquidity"
        );
        require(
            _getTraderMarginRatio(position, margin) >= _protocolParameters.minInitialMarginRatio(),
            "PerpetualPool: insufficient margin"
        );

        _updateTraderPortfolio(account, position, margin);

        emit Trade(account, tradeVolume, params.price.itou());
    }

    function _liquidate(address liquidator, address account) internal _lock_ {
        _updateSymbolPricesAndFundingRates();
        (IPTokenLite.Position memory position, int256 margin) = _settleTraderFundingFee(account);
        require(
            _getTraderMarginRatio(position, margin) < _protocolParameters.minMaintenanceMarginRatio(),
            "PerpetualPool: cannot liquidate"
        );

        int256 netEquity = margin;
        if (position.volume != 0) {
            _symbol.tradersNetVolume -= position.volume;
            _symbol.tradersNetCost -= position.cost;
            netEquity +=
                (((position.volume * _symbol.price) / ONE) * _protocolParameters.futuresMultiplier()) /
                ONE -
                position.cost;
        }

        int256 reward;
        int256 minLiquidationReward = _protocolParameters.minLiquidationReward();
        int256 maxLiquidationReward = _protocolParameters.maxLiquidationReward();
        if (netEquity <= minLiquidationReward) {
            reward = minLiquidationReward;
        } else if (netEquity >= maxLiquidationReward) {
            reward = maxLiquidationReward;
        } else {
            reward =
                ((netEquity - minLiquidationReward) * _protocolParameters.liquidationCutRatio()) /
                ONE +
                minLiquidationReward;
        }

        _liquidity += margin - reward;
        IPTokenLite(_pTokenAddress).burn(account);
        _transferOut(liquidator, reward.itou());

        emit Liquidate(account, liquidator, reward.itou());
    }

    //================================================================================
    // Helpers
    //================================================================================

    function _updateSymbolOracles(SignedPrice memory price) internal {
        IOracleWithUpdate(_protocolParameters.futuresOracleAddress()).updatePrice(
            _underlyingAddress,
            price.timestamp,
            price.price,
            price.v,
            price.r,
            price.s
        );
    }

    function _updateSymbolPricesAndFundingRates()
        internal
        returns (int256 totalDynamicEquity, int256 totalAbsCost)
    {
        uint256 preBlockNumber = _lastUpdateBlock;
        uint256 curBlockNumber = block.number;
        totalDynamicEquity = _liquidity;

        if (curBlockNumber > preBlockNumber) {
            _symbol.price = IOracle(_protocolParameters.futuresOracleAddress()).getPrice().utoi();
        }
        if (_symbol.tradersNetVolume != 0) {
            int256 cost = (((_symbol.tradersNetVolume * _symbol.price) / ONE) *
                _protocolParameters.futuresMultiplier()) / ONE;
            totalDynamicEquity -= cost - _symbol.tradersNetCost;
            totalAbsCost += cost.abs();
        }

        if (curBlockNumber > preBlockNumber) {
            if (_symbol.tradersNetVolume != 0) {
                int256 ratePerBlock = (((((((((_symbol.tradersNetVolume * _symbol.price) / ONE) *
                    _symbol.price) / ONE) * _protocolParameters.futuresMultiplier()) / ONE) *
                    _protocolParameters.futuresMultiplier()) / ONE) *
                    _protocolParameters.futuresFundingRateCoefficient()) / totalDynamicEquity;
                int256 delta = ratePerBlock * int256(curBlockNumber - preBlockNumber);
                unchecked {
                    _symbol.cumulativeFundingRate += delta;
                }
            }
        }

        _lastUpdateBlock = curBlockNumber;
    }

    function getTraderPortfolio(address account)
        public
        view
        returns (IPTokenLite.Position memory position, int256 margin)
    {
        IPTokenLite pToken = IPTokenLite(_pTokenAddress);
        position = pToken.getPosition(account);
        margin = pToken.getMargin(account);
    }

    function _updateTraderPortfolio(
        address account,
        IPTokenLite.Position memory position,
        int256 margin
    ) internal {
        IPTokenLite pToken = IPTokenLite(_pTokenAddress);
        pToken.updatePosition(account, position);
        pToken.updateMargin(account, margin);
    }

    function _settleTraderFundingFee(address account)
        internal
        returns (IPTokenLite.Position memory position, int256 margin)
    {
        (position, margin) = getTraderPortfolio(account);
        int256 funding;
        if (position.volume != 0) {
            int256 cumulativeFundingRate = _symbol.cumulativeFundingRate;
            int256 delta;
            unchecked {
                delta = cumulativeFundingRate - position.lastCumulativeFundingRate;
            }
            funding += (position.volume * delta) / ONE;

            position.lastCumulativeFundingRate = cumulativeFundingRate;
        }
        if (funding != 0) {
            margin -= funding;
            _liquidity += funding;
        }
    }

    function _getTraderMarginRatio(IPTokenLite.Position memory position, int256 margin)
        internal
        view
        returns (int256)
    {
        int256 totalDynamicEquity = margin;
        int256 totalAbsCost;
        if (position.volume != 0) {
            int256 cost = (((position.volume * _symbol.price) / ONE) *
                _protocolParameters.futuresMultiplier()) / ONE;
            totalDynamicEquity += cost - position.cost;
            totalAbsCost += cost.abs();
        }
        return totalAbsCost == 0 ? type(int256).max : (totalDynamicEquity * ONE) / totalAbsCost;
    }

    function _deflationCompatibleSafeTransferFrom(
        address from,
        address to,
        uint256 bAmount
    ) internal returns (uint256) {
        IERC20 bToken = IERC20(_bTokenAddress);
        uint256 balance1 = bToken.balanceOf(to);
        bToken.safeTransferFrom(from, to, bAmount);
        uint256 balance2 = bToken.balanceOf(to);
        return balance2 - balance1;
    }

    function _transferIn(address from, uint256 bAmount) internal returns (uint256) {
        uint256 amount = _deflationCompatibleSafeTransferFrom(
            from,
            address(this),
            bAmount.rescale(18, _decimals)
        );
        return amount.rescale(_decimals, 18);
    }

    function _transferOut(address to, uint256 bAmount) internal {
        uint256 amount = bAmount.rescale(18, _decimals);
        uint256 leftover = bAmount - amount.rescale(_decimals, 18);
        // leftover due to decimal precision is accrued to _protocolFeeAccrued
        _protocolFeeAccrued += leftover.utoi();
        IERC20(_bTokenAddress).safeTransfer(to, amount);
    }

    // function migrationTimestamp() external view override returns (uint256) {
    //     // TODO: Implement
    // }

    // function migrationDestination() external view override returns (address) {
    //     // TODO: Implement
    // }

    // function prepareMigration(address target, uint256 graceDays) external override {
    //     // TODO: Implement
    // }

    // function approveMigration() external override {
    //     // TODO: Implement
    // }

    // function executeMigration(address source) override external {
    //     // TODO: Implement
    // }

    // function controller() external view override returns (address) {
    //     // TODO: Implement
    // }

    // function setNewController(address newController) external override {
    //     // TODO: Implement
    // }

    // function claimNewController() external override {
    //     // TODO: Implement
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IFlipCoinGenerator {
    function generateRandom() external view returns (uint8);
}

interface ISyntheticNFT is IERC721Metadata {

    function setMetadata(uint256 tokenId,string memory metadata) external;

    function isVerified(uint256 tokenId) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function safeMint(
        address to,
        uint256 tokenId,
        string memory metadata
    ) external;

    function safeBurn(uint256 tokenId) external;
}

interface ICollectionManagerFactory {
    function deploy(
        address originalCollectionAddress_,
        string memory name_,
        string memory symbol_
    ) external returns (address);
}

interface IJot is IERC20 {
    function uniswapV2Pair() external view returns (address);

    function safeMint(address account, uint256 amount) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IOwnable {
    event ChangeController(address oldController, address newController);

    function controller() external view returns (address);

    function setNewController(address newController) external;

    function claimNewController() external;
}

interface IMigratable is IOwnable {
    event PrepareMigration(uint256 migrationTimestamp, address source, address target);

    event ExecuteMigration(uint256 migrationTimestamp, address source, address target);

    function migrationTimestamp() external view returns (uint256);

    function migrationDestination() external view returns (address);

    function prepareMigration(address target, uint256 graceDays) external;

    function approveMigration() external;

    function executeMigration(address source) external;
}

interface IPerpetualPoolLite {
// struct SymbolInfo {
//         uint256 symbolId;
//         string symbol;
//         address oracleAddress;
//         int256 multiplier;
//         int256 feeRatio;
//         int256 fundingRateCoefficient;
//         int256 price;
//         int256 cumulativeFundingRate;
//         int256 tradersNetVolume;
//         int256 tradersNetCost;
//     }

    struct SymbolInfo {
        int256 price;
        int256 cumulativeFundingRate;
        int256 tradersNetVolume;
        int256 tradersNetCost;
    }

    struct SignedPrice {
        uint256 timestamp;
        uint256 price;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event AddLiquidity(address indexed account, uint256 lShares, uint256 bAmount);

    event RemoveLiquidity(address indexed account, uint256 lShares, uint256 bAmount);

    event AddMargin(address indexed account, uint256 bAmount);

    event RemoveMargin(address indexed account, uint256 bAmount);

    event Trade(address indexed account, int256 tradeVolume, uint256 price);

    event Liquidate(address indexed account, address indexed liquidator, uint256 reward);

    event ProtocolFeeCollection(address indexed collector, uint256 amount);

    function getParameters()
        external
        view
        returns (
            int256 minPoolMarginRatio,
            int256 minInitialMarginRatio,
            int256 minMaintenanceMarginRatio,
            int256 minLiquidationReward,
            int256 maxLiquidationReward,
            int256 liquidationCutRatio,
            int256 protocolFeeCollectRatio
        );

    function getAddresses()
        external
        view
        returns (
            address bTokenAddress,
            address lTokenAddress,
            address pTokenAddress,
            address liquidatorQualifierAddress,
            address protocolFeeCollector,
            address underlyingAddress,
            address protocolAddress
        );

    function getSymbol() external view returns (SymbolInfo memory);

    function getLiquidity() external view returns (int256);

    function getLastUpdateBlock() external view returns (uint256);

    function getProtocolFeeAccrued() external view returns (int256);

    function collectProtocolFee() external;

    function addLiquidity(uint256 bAmount) external;

    function removeLiquidity(uint256 lShares) external;

    function addMargin(uint256 bAmount) external;

    function removeMargin(uint256 bAmount) external;

    function trade(int256 tradeVolume) external;

    function liquidate(address account) external;

    function addLiquidity(uint256 bAmount, SignedPrice memory price) external;

    function removeLiquidity(uint256 lShares, SignedPrice memory price) external;

    function addMargin(uint256 bAmount, SignedPrice memory price) external;

    function removeMargin(uint256 bAmount, SignedPrice memory price) external;

    function trade(int256 tradeVolume, SignedPrice memory price) external;

    function liquidate(address account, SignedPrice memory price) external;
}

interface IPTokenLite is IERC721 {
    struct Position {
        // position volume, long is positive and short is negative
        int256 volume;
        // the cost the establish this position
        int256 cost;
        // the last cumulativeFundingRate since last funding settlement for this position
        // the overflow for this value in intended
        int256 lastCumulativeFundingRate;
    }

    event UpdateMargin(address indexed owner, int256 amount);

    event UpdatePosition(address indexed owner, int256 volume, int256 cost, int256 lastCumulativeFundingRate);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function setPool(address newPool) external;

    function pool() external view returns (address);

    function totalMinted() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getNumPositionHolders() external view returns (uint256);

    function exists(address owner) external view returns (bool);

    function getMargin(address owner) external view returns (int256);

    function updateMargin(address owner, int256 margin) external;

    function addMargin(address owner, int256 delta) external;

    function getPosition(address owner) external view returns (Position memory);

    function updatePosition(address owner, Position memory position) external;

    function mint(address owner) external;

    function burn(address owner) external;
}

interface ILiquidatorQualifier {
    function isQualifiedLiquidator(address liquidator) external view returns (bool);
}

interface ILTokenLite is IERC20 {
    function pool() external view returns (address);

    function setPool(address newPool) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

interface IOracle {
    function getPrice() external returns (uint256);
}

interface IOracleWithUpdate {
    function getPrice() external returns (uint256);

    function updatePrice(
        address address_,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
    uint256 internal constant UMAX = 2**255 - 1;
    int256 internal constant IMIN = -2**255;

    /// convert uint256 to int256
    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, "UIO");
        return int256(a);
    }

    /// convert int256 to uint256
    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, "IUO");
        return uint256(a);
    }

    /// take abs of int256
    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, "AO");
        return a >= 0 ? a : -a;
    }

    /// rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(
        uint256 a,
        uint256 decimals1,
        uint256 decimals2
    ) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : (a * (10**decimals2)) / (10**decimals1);
    }

    /// rescale a int256 from base 10**decimals1 to 10**decimals2
    function rescale(
        int256 a,
        uint256 decimals1,
        uint256 decimals2
    ) internal pure returns (int256) {
        return decimals1 == decimals2 ? a : (a * utoi(10**decimals2)) / utoi(10**decimals1);
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Structs.sol";

// ! TODO: EMIT THE EVENTS AND ADD VALIDATIONS

/**
 * @title future parameters controlled by governance
 * @notice the owner of this contract is the timelock controller of the governance feature
 */
contract FuturesProtocolParameters is Ownable {
    int256 public minPoolMarginRatio;
    int256 public minInitialMarginRatio;
    int256 public minMaintenanceMarginRatio;
    int256 public minLiquidationReward;
    int256 public maxLiquidationReward;
    int256 public liquidationCutRatio;
    int256 public protocolFeeCollectRatio;
    address public futuresOracleAddress;
    int256 public futuresMultiplier;
    int256 public futuresFeeRatio;
    int256 public futuresFundingRateCoefficient;
    uint256 public oracleDelay;

    event MinPoolMarginRatioUpdated(address value);
    event MinInitialMarginRatioUpdated(address value);
    event MinMaintenanceMarginRatioUpdated(address value);
    event MinLiquidationRewardUpdated(address value);
    event MaxLiquidationRewardUpdated(address value);
    event LiquidationCutRatioUpdated(address value);
    event ProtocolFeeCollectRatioUpdated(address value);
    event OracleDelayUpdated(address value);
    event FuturesOracleAddressUpdated(address value);
    event FuturesMultiplierUpdated(int256 value);
    event FuturesFeeRatioUpdated(int256 value);
    event FuturesFundingRateCoefficientUpdated(int256 value);

    /**
     * @dev set initial state of the data
     */
    constructor(
        MainParams memory mainParams,
        address _futuresOracleAddress,
        int256 _futuresMultiplier,
        int256 _futuresFeeRatio,
        int256 _futuresFundingRateCoefficient,
        uint256 _oracleDelay,
        address _governanceContractAddress
    ) {
        require(_futuresOracleAddress != address(0), "Oracle address can't be zero");
        require(_futuresMultiplier > 0, "Invalid futures multiplier");
        require(_futuresFeeRatio > 0, "Invalid futures fee ratio");
        require(_futuresFundingRateCoefficient > 0, "Invalid futures funding rate coefficient");

        minPoolMarginRatio = mainParams.minPoolMarginRatio;
        minInitialMarginRatio = mainParams.minInitialMarginRatio;
        minMaintenanceMarginRatio = mainParams.minMaintenanceMarginRatio;
        minLiquidationReward = mainParams.minLiquidationReward;
        maxLiquidationReward = mainParams.maxLiquidationReward;
        liquidationCutRatio = mainParams.liquidationCutRatio;
        protocolFeeCollectRatio = mainParams.protocolFeeCollectRatio;
        futuresOracleAddress = _futuresOracleAddress;
        futuresMultiplier = _futuresMultiplier;
        futuresFeeRatio = _futuresFeeRatio;
        futuresFundingRateCoefficient = _futuresFundingRateCoefficient;
        oracleDelay = _oracleDelay;

        // transfer ownership
        transferOwnership(_governanceContractAddress);
    }

    function setMinPoolMarginRatio(int256 _minPoolMarginRatio) external onlyOwner {
        minPoolMarginRatio = _minPoolMarginRatio;
    }

    function setMinInitialMarginRatio(int256 _minInitialMarginRatio) external onlyOwner {
        minInitialMarginRatio = _minInitialMarginRatio;
    }

    function setMinMaintenanceMarginRatio(int256 _minMaintenanceMarginRatio) external onlyOwner {
        minMaintenanceMarginRatio = _minMaintenanceMarginRatio;
    }

    function setMinLiquidationReward(int256 _minLiquidationReward) external onlyOwner {
        minLiquidationReward = _minLiquidationReward;
    }

    function setMaxLiquidationReward(int256 _maxLiquidationReward) external onlyOwner {
        maxLiquidationReward = _maxLiquidationReward;
    }

    function setLiquidationCutRatio(int256 _liquidationCutRatio) external onlyOwner {
        liquidationCutRatio = _liquidationCutRatio;
    }

    function setProtocolFeeCollectRatio(int256 _protocolFeeCollectRatio) external onlyOwner {
        protocolFeeCollectRatio = _protocolFeeCollectRatio;
    }

    function setFuturesOracleAddress(address futuresOracleAddress_) external onlyOwner {
        require(futuresOracleAddress_ != address(0), "Oracle address can't be zero");
        futuresOracleAddress = futuresOracleAddress_;
        emit FuturesOracleAddressUpdated(futuresOracleAddress_);
    }

    function setFuturesMultiplier(int256 futuresMultiplier_) external onlyOwner {
        require(futuresMultiplier_ > 1 hours, "Invalid futures multiplier");
        futuresMultiplier = futuresMultiplier_;
        emit FuturesMultiplierUpdated(futuresMultiplier_);
    }

    function setFuturesFeeRatio(int256 futuresFeeRatio_) external onlyOwner {
        require(futuresFeeRatio_ > 1 hours, "Invalid futures fee ratio");
        futuresFeeRatio = futuresFeeRatio_;
        emit FuturesFeeRatioUpdated(futuresFeeRatio_);
    }

    function setFuturesFundingRateCoefficient(int256 futuresFundingRateCoefficient_) external onlyOwner {
        require(futuresFundingRateCoefficient_ > 1 hours, "Invalid futures funding rate coefficient");
        futuresFundingRateCoefficient = futuresFundingRateCoefficient_;
        emit FuturesFundingRateCoefficientUpdated(futuresFundingRateCoefficient_);
    }

    function setOracleDelay(uint256 _oracleDelay) external onlyOwner {
        oracleDelay = _oracleDelay;
    }
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct MainParams {
    int256 minPoolMarginRatio;
    int256 minInitialMarginRatio;
    int256 minMaintenanceMarginRatio;
    int256 minLiquidationReward;
    int256 maxLiquidationReward;
    int256 liquidationCutRatio;
    int256 protocolFeeCollectRatio;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}