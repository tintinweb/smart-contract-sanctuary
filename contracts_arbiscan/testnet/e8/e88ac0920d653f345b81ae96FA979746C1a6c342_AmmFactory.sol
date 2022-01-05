// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./Amm.sol";
import "./interfaces/IAmmFactory.sol";

contract AmmFactory is IAmmFactory {
    address public immutable override upperFactory; // PairFactory
    address public immutable override config;
    address public override feeTo;
    address public override feeToSetter;

    // baseToken => quoteToken => amm
    mapping(address => mapping(address => address)) public override getAmm;

    modifier onlyUpper() {
        require(msg.sender == upperFactory, "AmmFactory: FORBIDDEN");
        _;
    }

    constructor(
        address upperFactory_,
        address config_,
        address feeToSetter_
    ) {
        require(config_ != address(0) && feeToSetter_ != address(0), "AmmFactory: ZERO_ADDRESS");
        upperFactory = upperFactory_;
        config = config_;
        feeToSetter = feeToSetter_;
    }

    function createAmm(address baseToken, address quoteToken) external override onlyUpper returns (address amm) {
        require(baseToken != quoteToken, "AmmFactory.createAmm: IDENTICAL_ADDRESSES");
        require(baseToken != address(0) && quoteToken != address(0), "AmmFactory.createAmm: ZERO_ADDRESS");
        require(getAmm[baseToken][quoteToken] == address(0), "AmmFactory.createAmm: AMM_EXIST");
        bytes32 salt = keccak256(abi.encodePacked(baseToken, quoteToken));
        bytes memory ammBytecode = type(Amm).creationCode;
        assembly {
            amm := create2(0, add(ammBytecode, 32), mload(ammBytecode), salt)
        }
        getAmm[baseToken][quoteToken] = amm;
        emit AmmCreated(baseToken, quoteToken, amm);
    }

    function initAmm(
        address baseToken,
        address quoteToken,
        address margin
    ) external override onlyUpper {
        address amm = getAmm[baseToken][quoteToken];
        Amm(amm).initialize(baseToken, quoteToken, margin);
    }

    function setFeeTo(address feeTo_) external override {
        require(msg.sender == feeToSetter, "AmmFactory.setFeeTo: FORBIDDEN");
        feeTo = feeTo_;
    }

    function setFeeToSetter(address feeToSetter_) external override {
        require(msg.sender == feeToSetter, "AmmFactory.setFeeToSetter: FORBIDDEN");
        feeToSetter = feeToSetter_;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./LiquidityERC20.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IMarginFactory.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IMargin.sol";
import "./interfaces/IPairFactory.sol";
import "../utils/Reentrant.sol";
import "../libraries/UQ112x112.sol";
import "../libraries/Math.sol";
import "../libraries/FullMath.sol";

contract Amm is IAmm, LiquidityERC20, Reentrant {
    using UQ112x112 for uint224;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;

    address public immutable override factory;
    address public override config;
    address public override baseToken;
    address public override quoteToken;
    address public override margin;

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;
    uint256 public kLast;
    uint256 public override lastPrice;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    uint112 private baseReserve; // uses single storage slot, accessible via getReserves
    uint112 private quoteReserve; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    modifier onlyMargin() {
        require(margin == msg.sender, "Amm: ONLY_MARGIN");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external override {
        require(msg.sender == factory, "Amm.initialize: FORBIDDEN"); // sufficient check
        baseToken = baseToken_;
        quoteToken = quoteToken_;
        margin = margin_;
        config = IAmmFactory(factory).config();
    }

    /// @notice add liquidity
    /// @dev  calculate the liquidity according to the real baseReserve.
    function mint(address to)
        external
        override
        nonReentrant
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        // get real baseReserve
        int256 baseTokenOfNetPosition = IMargin(margin).netPosition();
        require(int256(uint256(_baseReserve)) + baseTokenOfNetPosition <= 2**112, "Amm.mint:NetPosition_VALUE_WRONT");

        int256 realBaseReserveSigned = int256(uint256(_baseReserve)) + baseTokenOfNetPosition;
        uint256 realBaseReserve = uint256(realBaseReserveSigned);

        baseAmount = IERC20(baseToken).balanceOf(address(this));
        require(baseAmount > 0, "Amm.mint: ZERO_BASE_AMOUNT");

        bool feeOn = _mintFee(_baseReserve, _quoteReserve);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            quoteAmount = IPriceOracle(IConfig(config).priceOracle()).quote(baseToken, quoteToken, baseAmount);

            require(quoteAmount > 0, "Amm.mint: INSUFFICIENT_QUOTE_AMOUNT");
            liquidity = Math.sqrt(baseAmount * quoteAmount) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            quoteAmount = (baseAmount * _quoteReserve) / _baseReserve;

            // realBaseReserve
            liquidity = (baseAmount * _totalSupply) / realBaseReserve;
        }
        require(liquidity > 0, "Amm.mint: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(_baseReserve + baseAmount, _quoteReserve + quoteAmount, _baseReserve, _quoteReserve);
        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        _safeTransfer(baseToken, margin, baseAmount);
        IVault(margin).deposit(msg.sender, baseAmount);

        emit Mint(msg.sender, to, baseAmount, quoteAmount, liquidity);
    }

    /// @notice add liquidity
    /// @dev  calculate the liquidity according to the real baseReserve.
    function burn(address to)
        external
        override
        nonReentrant
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        liquidity = balanceOf[address(this)];

        // get real baseReserve
        int256 baseTokenOfNetPosition = IMargin(margin).netPosition();
        int256 realBaseReserveSigned = int256(uint256(_baseReserve)) + baseTokenOfNetPosition;
        uint256 realBaseReserve = uint256(realBaseReserveSigned);

        bool feeOn = _mintFee(_baseReserve, _quoteReserve);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        baseAmount = (liquidity * realBaseReserve) / _totalSupply; // using balances ensures pro-rata distribution

        // quoteAmount = (liquidity * _quoteReserve) / _totalSupply; // using balances ensures pro-rata distribution
        quoteAmount = (baseAmount * _quoteReserve) / _baseReserve;

        require(baseAmount > 0 && quoteAmount > 0, "Amm.burn: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _update(_baseReserve - baseAmount, _quoteReserve - quoteAmount, _baseReserve, _quoteReserve);
        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        IVault(margin).withdraw(msg.sender, to, baseAmount);
        emit Burn(msg.sender, to, baseAmount, quoteAmount, liquidity);
    }

    /// @notice
    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override nonReentrant onlyMargin returns (uint256[2] memory amounts) {
        uint256[2] memory reserves;
        (reserves, amounts) = _estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
        //check trade slippage
        _checkTradeSlippage(reserves[0], reserves[1], baseReserve, quoteReserve);
        _update(reserves[0], reserves[1], baseReserve, quoteReserve);

        emit Swap(inputToken, outputToken, amounts[0], amounts[1]);
    }

    /// @notice  use in the situation  of forcing closing position
    function forceSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override nonReentrant onlyMargin {
        require(inputToken == baseToken || inputToken == quoteToken, "Amm.forceSwap: WRONG_INPUT_TOKEN");
        require(outputToken == baseToken || outputToken == quoteToken, "Amm.forceSwap: WRONG_OUTPUT_TOKEN");
        require(inputToken != outputToken, "Amm.forceSwap: SAME_TOKENS");
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        bool feeOn = _mintFee(_baseReserve, _quoteReserve);

        uint256 reserve0;
        uint256 reserve1;
        if (inputToken == baseToken) {
            reserve0 = _baseReserve + inputAmount;
            reserve1 = _quoteReserve - outputAmount;
        } else {
            reserve0 = _baseReserve - outputAmount;
            reserve1 = _quoteReserve + inputAmount;
        }
        _update(reserve0, reserve1, _baseReserve, _quoteReserve);

        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        emit ForceSwap(inputToken, outputToken, inputAmount, outputAmount);
    }

    /// @notice  invoke when price gap is larger  than  "gap" percent;
    /// @notice gap is in config contract
    function rebase() external override nonReentrant returns (uint256 quoteReserveAfter) {
        require(msg.sender == tx.origin, "Amm.rebase: ONLY_EOA");
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();

        bool feeOn = _mintFee(_baseReserve, _quoteReserve);

        quoteReserveAfter = IPriceOracle(IConfig(config).priceOracle()).quote(baseToken, quoteToken, _baseReserve);
        uint256 gap = IConfig(config).rebasePriceGap();
        require(
            quoteReserveAfter * 100 >= uint256(_quoteReserve) * (100 + gap) ||
                quoteReserveAfter * 100 <= uint256(_quoteReserve) * (100 - gap),
            "Amm.rebase: NOT_BEYOND_PRICE_GAP"
        );
        _update(_baseReserve, quoteReserveAfter, _baseReserve, _quoteReserve);

        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        emit Rebase(_quoteReserve, quoteReserveAfter);
    }

    /// notice view method for estimating swap
    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view override returns (uint256[2] memory amounts) {
        (, amounts) = _estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
    }

    function getReserves()
        public
        view
        override
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        )
    {
        reserveBase = baseReserve;
        reserveQuote = quoteReserve;
        blockTimestamp = blockTimestampLast;
    }

    function _checkTradeSlippage(
        uint256 baseReserveNew,
        uint256 quoteReserveNew,
        uint112 baseReserveOld,
        uint112 quoteReserveOld
    ) internal view {
        // check trade slippage for every transaction
        uint256 numerator = quoteReserveNew * baseReserveOld * 100;
        uint256 demominator = baseReserveNew * quoteReserveOld;
        uint256 tradingSlippage = IConfig(config).tradingSlippage();
        require(
            (numerator < (100 + tradingSlippage) * demominator) && (numerator > (100 - tradingSlippage) * demominator),
            "AMM._update: TRADINGSLIPPAGE_TOO_LARGE_THAN_LAST_TRANSACTION"
        );
        require(
            (quoteReserveNew * 100 < ((100 + tradingSlippage) * baseReserveNew * lastPrice) / 2**112) &&
                (quoteReserveNew * 100 > ((100 - tradingSlippage) * baseReserveNew * lastPrice) / 2**112),
            "AMM._update: TRADINGSLIPPAGE_TOO_LARGE_THAN_LAST_BLOCK"
        );
    }

    function _estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) internal view returns (uint256[2] memory reserves, uint256[2] memory amounts) {
        require(inputToken == baseToken || inputToken == quoteToken, "Amm._estimateSwap: WRONG_INPUT_TOKEN");
        require(outputToken == baseToken || outputToken == quoteToken, "Amm._estimateSwap: WRONG_OUTPUT_TOKEN");
        require(inputToken != outputToken, "Amm._estimateSwap: SAME_TOKENS");
        require(inputAmount > 0 || outputAmount > 0, "Amm._estimateSwap: INSUFFICIENT_AMOUNT");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        uint256 reserve0;
        uint256 reserve1;
        if (inputAmount > 0 && inputToken != address(0)) {
            // swapInput
            if (inputToken == baseToken) {
                outputAmount = _getAmountOut(inputAmount, _baseReserve, _quoteReserve);
                reserve0 = _baseReserve + inputAmount;
                reserve1 = _quoteReserve - outputAmount;
            } else {
                outputAmount = _getAmountOut(inputAmount, _quoteReserve, _baseReserve);
                reserve0 = _baseReserve - outputAmount;
                reserve1 = _quoteReserve + inputAmount;
            }
        } else {
            //swapOutput
            if (outputToken == baseToken) {
                require(outputAmount < _baseReserve, "AMM._estimateSwap: INSUFFICIENT_LIQUIDITY");
                inputAmount = _getAmountIn(outputAmount, _quoteReserve, _baseReserve);
                reserve0 = _baseReserve - outputAmount;
                reserve1 = _quoteReserve + inputAmount;
            } else {
                require(outputAmount < _quoteReserve, "AMM._estimateSwap: INSUFFICIENT_LIQUIDITY");
                inputAmount = _getAmountIn(outputAmount, _baseReserve, _quoteReserve);
                reserve0 = _baseReserve + inputAmount;
                reserve1 = _quoteReserve - outputAmount;
            }
        }
        reserves = [reserve0, reserve1];
        amounts = [inputAmount, outputAmount];
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Amm._getAmountOut: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Amm._getAmountOut: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 999;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "Amm._getAmountIn: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Amm._getAmountIn: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 999;
        amountIn = (numerator / denominator) + 1;
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    //todo
    function _mintFee(uint112 reserve0, uint112 reserve1) private returns (bool feeOn) {
        address feeTo = IAmmFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(reserve0) * reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);

                    uint256 feeParameter = IConfig(config).feeParameter();
                    uint256 denominator = (rootK * feeParameter) / 100 + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _update(
        uint256 baseReserveNew,
        uint256 quoteReserveNew,
        uint112 baseReserveOld,
        uint112 quoteReserveOld
    ) private {
        require(baseReserveNew <= type(uint112).max && quoteReserveNew <= type(uint112).max, "AMM._update: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // last price means last block price.
        if (timeElapsed > 0 && baseReserveOld != 0 && quoteReserveOld != 0) {
            // * never overflows, and + overflow is desired
            lastPrice = uint256(UQ112x112.encode(quoteReserveOld).uqdiv(baseReserveOld));
            price0CumulativeLast += uint256(UQ112x112.encode(quoteReserveOld).uqdiv(baseReserveOld)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(baseReserveOld).uqdiv(quoteReserveOld)) * timeElapsed;
        }

        // keep lastprice not equal zero
        if (lastPrice == 0 && baseReserveNew != 0) {
            lastPrice = uint256(UQ112x112.encode(uint112(quoteReserveNew)).uqdiv(uint112(baseReserveNew)));
        }

        baseReserve = uint112(baseReserveNew);
        quoteReserve = uint112(quoteReserveNew);
        blockTimestampLast = blockTimestamp;
        emit Sync(baseReserve, quoteReserve);
    }


    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "AMM._safeTransfer: TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmmFactory {
    event AmmCreated(address indexed baseToken, address indexed quoteToken, address amm);

    function createAmm(address baseToken, address quoteToken) external returns (address amm);

    function initAmm(
        address baseToken,
        address quoteToken,
        address margin
    ) external;

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function upperFactory() external view returns (address);

    function config() external view returns (address);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address amm);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/ILiquidityERC20.sol";

contract LiquidityERC20 is ILiquidityERC20 {
    string public constant override name = "APEX LP";
    string public constant override symbol = "APEX-LP";
    uint8 public constant override decimals = 18;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public immutable override DOMAIN_SEPARATOR;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public override nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "LiquidityERC20: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "LiquidityERC20: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IConfig {
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event RebasePriceGapChanged(uint256 oldGap, uint256 newGap);
    event TradingSlippageChanged(uint256 oldTradingSlippage, uint256 newTradingSlippage);
    event RouterRegistered(address indexed router);
    event RouterUnregistered(address indexed router);
    event SetLiquidateFeeRatio(uint256 oldLiquidateFeeRatio, uint256 liquidateFeeRatio);
    event SetLiquidateThreshold(uint256 oldLiquidateThreshold, uint256 liquidateThreshold);
    event SetInitMarginRatio(uint256 oldInitMarginRatio, uint256 initMarginRatio);
    event SetBeta(uint256 oldBeta, uint256 beta);
    event SetFeeParameter(uint256 oldFeeParameter, uint256 feeParameter);
    event SetMaxCPFBoost(uint256 oldMaxCPFBoost, uint256 maxCPFBoost);

    /// @notice get price oracle address.
    function priceOracle() external view returns (address);

    /// @notice get beta of amm.
    function beta() external view returns (uint8);

    /// @notice get feeParameter of amm.
    function feeParameter() external view returns (uint256);

    /// @notice get init margin ratio of margin.
    function initMarginRatio() external view returns (uint256);

    /// @notice get liquidate threshold of margin.
    function liquidateThreshold() external view returns (uint256);

    /// @notice get liquidate fee ratio of margin.
    function liquidateFeeRatio() external view returns (uint256);

    /// @notice get trading slippage  of amm.
    function tradingSlippage() external view returns (uint256);

    /// @notice get rebase gap of amm.
    function rebasePriceGap() external view returns (uint256);

    function routerMap(address) external view returns (bool);

    function maxCPFBoost() external view returns (uint256);

    function registerRouter(address router) external;

    function unregisterRouter(address router) external;

    /// @notice Set a new oracle
    /// @param newOracle new oracle address.
    function setPriceOracle(address newOracle) external;

    /// @notice Set a new beta of amm
    /// @param newBeta new beta.
    function setBeta(uint8 newBeta) external;

    /// @notice Set a new rebase gap of amm
    /// @param newGap new gap.
    function setRebasePriceGap(uint256 newGap) external;

    /// @notice Set a new trading slippage of amm
    /// @param newTradingSlippage .
    function setTradingSlippage(uint256 newTradingSlippage) external;

    /// @notice Set a new init margin ratio of margin
    /// @param marginRatio new init margin ratio.
    function setInitMarginRatio(uint256 marginRatio) external;

    /// @notice Set a new liquidate threshold of margin
    /// @param threshold new liquidate threshold of margin.
    function setLiquidateThreshold(uint256 threshold) external;

    /// @notice Set a new liquidate fee of margin
    /// @param feeRatio new liquidate fee of margin.
    function setLiquidateFeeRatio(uint256 feeRatio) external;

    /// @notice Set a new feeParameter.
    /// @param newFeeParameter New feeParameter get from AMM swap fee.
    /// @dev feeParameter = (1/fee -1 ) *100 where fee set by owner.
    function setFeeParameter(uint256 newFeeParameter) external;

    function setMaxCPFBoost(uint256 newMaxCPFBoost) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPriceOracle {
    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);

    function getIndexPrice(address amm) external view returns (uint256);

    function getMarkPrice(address amm) external view returns (uint256 price);

    function getMarkPriceAcc(
        address amm,
        uint8 beta,
        uint256 quoteAmount,
        bool negative
    ) external view returns (uint256 baseAmount);

    function getPremiumFraction(address amm) external view returns (int256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMarginFactory {
    event MarginCreated(address indexed baseToken, address indexed quoteToken, address margin);

    function createMargin(address baseToken, address quoteToken) external returns (address margin);

    function initMargin(
        address baseToken,
        address quoteToken,
        address amm
    ) external;

    function upperFactory() external view returns (address);

    function config() external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address margin);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Swap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteReserveBefore, uint256 quoteReserveAfter);
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    // only factory can call this function
    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external;

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function burn(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    // only binding margin can call this function
    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external returns (uint256[2] memory amounts);

    // only binding margin can call this function
    function forceSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external;

    function rebase() external returns (uint256 quoteReserveAfter);

    function factory() external view returns (address);

    function config() external view returns (address);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function margin() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function lastPrice() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, address indexed receiver, uint256 amount);

    /// @notice deposit baseToken to user
    function deposit(address user, uint256 amount) external;

    /// @notice withdraw user's baseToken from margin contract to receiver
    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external;

    /// @notice get baseToken amount in margin
    function reserve() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMargin {
    struct Position {
        int256 quoteSize; //quote amount of position
        int256 baseSize; //margin + fundingFee + unrealizedPnl + deltaBaseWhenClosePosition
        uint256 tradeSize; //if quoteSize>0 unrealizedPnl = baseValueOfQuoteSize - tradeSize; if quoteSize<0 unrealizedPnl = tradeSize - baseValueOfQuoteSize;
    }

    event AddMargin(address indexed trader, uint256 depositAmount, Position position);
    event RemoveMargin(
        address indexed trader,
        address indexed to,
        uint256 withdrawAmount,
        int256 fundingFee,
        uint256 withdrawAmountFromMargin,
        Position position
    );
    event OpenPosition(address indexed trader, uint8 side, uint256 baseAmount, uint256 quoteAmount, Position position);
    event ClosePosition(
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        int256 fundingFee,
        Position position
    );
    event Liquidate(
        address indexed liquidator,
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 bonus,
        Position position
    );
    event UpdateCPF(uint256 timeStamp, int256 cpf);

    /// @notice only factory can call this function
    /// @param baseToken_ margin's baseToken.
    /// @param quoteToken_ margin's quoteToken.
    /// @param amm_ amm address.
    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_
    ) external;

    /// @notice add margin to trader
    /// @param trader .
    /// @param depositAmount base amount to add.
    function addMargin(address trader, uint256 depositAmount) external;

    /// @notice remove margin to msg.sender
    /// @param withdrawAmount base amount to withdraw.
    function removeMargin(
        address trader,
        address to,
        uint256 withdrawAmount
    ) external;

    /// @notice open position with side and quoteAmount by msg.sender
    /// @param side long or short.
    /// @param quoteAmount quote amount.
    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external returns (uint256 baseAmount);

    /// @notice close msg.sender's position with quoteAmount
    /// @param quoteAmount quote amount to close.
    function closePosition(address trader, uint256 quoteAmount) external returns (uint256 baseAmount);

    /// @notice liquidate trader
    function liquidate(address trader)
        external
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        );

    function updateCPF() external returns (int256);

    /// @notice get factory address
    function factory() external view returns (address);

    /// @notice get config address
    function config() external view returns (address);

    /// @notice get base token address
    function baseToken() external view returns (address);

    /// @notice get quote token address
    function quoteToken() external view returns (address);

    /// @notice get amm address of this margin
    function amm() external view returns (address);

    /// @notice get all users' net position of base
    function netPosition() external view returns (int256 netBasePosition);

    /// @notice get trader's position
    function getPosition(address trader)
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );

    /// @notice get withdrawable margin of trader
    function getWithdrawable(address trader) external view returns (uint256 amount);

    /// @notice check if can liquidate this trader's position
    function canLiquidate(address trader) external view returns (bool);

    /// @notice calculate the latest funding fee with current position
    function calFundingFee(address trader) external view returns (int256 fundingFee);

    /// @notice calculate the latest debt ratio with Pnl and funding fee
    function calDebtRatio(address trader) external view returns (uint256 debtRatio);

    function calUnrealizedPnl(address trader) external view returns (int256);

    function getNewLatestCPF() external view returns (int256);

    function querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPairFactory {
    event NewPair(address indexed baseToken, address indexed quoteToken, address amm, address margin);

    function createPair(address baseToken, address quotoToken) external returns (address amm, address margin);

    function ammFactory() external view returns (address);

    function marginFactory() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x > y) {
            return y;
        }
        return x;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        // todo unchecked
        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ILiquidityERC20 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);
}