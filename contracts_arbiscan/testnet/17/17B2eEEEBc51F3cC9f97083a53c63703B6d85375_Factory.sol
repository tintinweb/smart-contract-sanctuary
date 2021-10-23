pragma solidity ^0.8.0;

import './interfaces/IFactory.sol';
import './interfaces/IAmm.sol';
import './interfaces/IMargin.sol';
import './interfaces/IVault.sol';
import './Amm.sol';
import './Margin.sol';
import './Vault.sol';
import './Staking.sol';

contract Factory is IFactory {
    address public override pendingAdmin;
    address public override admin;

    address public override config;

    mapping(address => mapping(address => address)) public override getAmm;
    mapping(address => mapping(address => address)) public override getMargin;
    mapping(address => mapping(address => address)) public override getVault;

    mapping(address => address) public override getStaking;
    
    constructor(address _config) {
        admin = msg.sender;
        config = _config;
    }

    function setPendingAdmin(address newPendingAdmin) external override {
        require(msg.sender == admin, 'Factory: REQUIRE_ADMIN');
        require(pendingAdmin != newPendingAdmin, 'Factory: ALREADY_SET');
        emit NewPendingAdmin(pendingAdmin, newPendingAdmin);
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() external override {
        require(msg.sender == pendingAdmin, 'Factory: REQUIRE_PENDING_ADMIN');
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function createPair(address baseToken, address quoteToken) external override returns (address amm, address margin, address vault) {
        require(baseToken != quoteToken, 'Factory: IDENTICAL_ADDRESSES');
        require(baseToken != address(0) && quoteToken != address(0), 'Factory: ZERO_ADDRESS');
        require(getAmm[baseToken][quoteToken] == address(0), 'Factory: PAIR_EXIST');
        bytes32 salt = keccak256(abi.encodePacked(baseToken, quoteToken));
        bytes memory ammBytecode = type(Amm).creationCode;
        bytes memory marginBytecode = type(Margin).creationCode;
        bytes memory vaultBytecode = type(Vault).creationCode;
        assembly {
            amm := create2(0, add(ammBytecode, 32), mload(ammBytecode), salt)
            margin := create2(0, add(marginBytecode, 32), mload(marginBytecode), salt)
            vault := create2(0, add(vaultBytecode, 32), mload(vaultBytecode), salt)
        }
        IAmm(amm).initialize(baseToken, quoteToken, config, margin, vault);
        IMargin(margin).initialize(baseToken, quoteToken, config, amm, vault);
        IVault(vault).initialize(baseToken, amm, margin);
        getAmm[baseToken][quoteToken] = amm;
        getMargin[baseToken][quoteToken] = margin;
        getVault[baseToken][quoteToken] = vault;
        emit NewPair(baseToken, quoteToken, amm, margin, vault);
    }

    // TODO: 改用创建Staking代理合约
    function createStaking(address baseToken, address quoteToken) external override returns (address staking) {
        address amm = getAmm[baseToken][quoteToken];
        require(amm != address(0), 'Factory: PAIR_NOT_EXIST');
        require(getStaking[amm] == address(0), 'Factory: STAKING_EXIST');
        staking = address(new Staking(config, amm));
        getStaking[amm] = staking;
        emit NewStaking(baseToken, quoteToken, staking);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IFactory {
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPair(address indexed baseToken, address indexed quoteToken, address amm, address margin, address vault);
    event NewStaking(address indexed baseToken, address indexed quoteToken, address staking);

    function pendingAdmin() external view returns (address);

    function admin() external view returns (address);

    function config() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address amm);

    function getMargin(address baseToken, address quoteToken) external view returns (address margin);

    function getVault(address baseToken, address quoteToken) external view returns (address vault);

    function getStaking(address amm) external view returns (address staking);

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;

    function createPair(address baseToken, address quotoToken)
        external
        returns (
            address amm,
            address margin,
            address vault
        );

    function createStaking(address baseToken, address quoteToken) external returns (address staking);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount);
    event Swap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteAmountBefore, uint256 quoteAmountAfter, uint256 baseAmount);
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function factory() external view returns (address);

    function config() external view returns (address);

    function margin() external view returns (address);

    function vault() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    // only factory can call this function
    function initialize(
        address _baseToken,
        address _quoteToken,
        address _config,
        address _margin,
        address _vault
    ) external;

    function mint(address to) external returns (uint256 quoteAmount, uint256 liquidity);

    function burn(address to) external returns (uint256 baseAmount, uint256 quoteAmount);

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

    function rebase() external returns (uint256 amount);

    function swapQuery(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function swapQueryWithAcctSpecMarkPrice(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IMargin {
    event AddMargin(address indexed trader, uint256 depositAmount);
    event RemoveMargin(address indexed trader, uint256 withdrawAmount);
    event OpenPosition(address indexed trader, uint8 side, uint256 baseAmount, uint256 quoteAmount);
    event ClosePosition(address indexed trader, uint256 quoteAmount, uint256 baseAmount);
    event Liquidate(
        address indexed liquidator,
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 bonus
    );

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function factory() external view returns (address);

    function config() external view returns (address);

    function amm() external view returns (address);

    function vault() external view returns (address);

    function getPosition(address trader)
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );

    function getWithdrawable(address trader) external view returns (uint256 amount);

    function canLiquidate(address trader) external view returns (bool);

    function queryMaxOpenPosition(uint8 side, uint256 baseAmount) external view returns (uint256 quoteAmount);

    // only factory can call this function
    function initialize(
        address _baseToken,
        address _quoteToken,
        address _config,
        address _amm,
        address _vault
    ) external;

    function addMargin(address trader, uint256 depositAmount) external;

    function removeMargin(uint256 withdrawAmount) external;

    function openPosition(uint8 side, uint256 baseAmount) external returns (uint256 quoteAmount);

    function closePosition(uint256 quoteAmount) external returns (uint256 baseAmount);

    function liquidate(address trader)
        external
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        );
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IVault {
    event Withdraw(address indexed caller, address indexed to, uint256 amount);

    function baseToken() external view returns (address);

    function factory() external view returns (address);

    function amm() external view returns (address);

    function margin() external view returns (address);

    // only factory can call this function
    function initialize(address _baseToken, address _amm, address _margin) external;

    function setMargin(address _margin) external;

    // only amm or margin can call this function
    function withdraw(address to, uint256 amount) external;
}

pragma solidity ^0.8.0;

import "./interfaces/IAmm.sol";
import "./interfaces/IVault.sol";
import "./LiquidityERC20.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";
import "./libraries/AMMLibrary.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IPriceOracle.sol";
import "./libraries/FullMath.sol";
import "./interfaces/IConfig.sol";
import "./utils/Reentrant.sol";

contract Amm is IAmm, LiquidityERC20, Reentrant {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public override factory;
    address public override baseToken;
    address public override quoteToken;
    address public override config;
    address public override margin;
    address public override vault;

    uint112 private baseReserve; // uses single storage slot, accessible via getReserves
    uint112 private quoteReserve; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    //todo
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    // uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    function getReserves()
        public
        override
        view
        returns (
            uint112 _baseReserve,
            uint112 _quoteReserve,
            uint32 _blockTimestampLast
        )
    {
        _baseReserve = baseReserve;
        _quoteReserve = quoteReserve;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "AMM: TRANSFER_FAILED");
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _baseToken,
        address _quoteToken,
        address _config,
        address _margin,
        address _vault
    ) external override {
        require(msg.sender == factory, "Amm: FORBIDDEN"); // sufficient check
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        config = _config;
        margin = _margin;
        vault = _vault;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "AMM: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        baseReserve = uint112(balance0);
        quoteReserve = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(baseReserve, quoteReserve);
    }

    // this low-level function should be called from a contract which performs important safety checks
    //todo
    function mint(address to) external override nonReentrant returns (uint256 quoteAmount, uint256 liquidity) {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        uint256 baseAmount = IERC20(baseToken).balanceOf(address(this));

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        uint256 quoteAmountMinted;
        if (_totalSupply == 0) {
            quoteAmountMinted = getQuoteAmountByPriceOracle(baseAmount);
            liquidity = Math.sqrt(baseAmount.mul(quoteAmountMinted)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            quoteAmountMinted = getQuoteAmountByCurrentPrice(baseAmount);
            liquidity = Math.minU(
                baseAmount.mul(_totalSupply) / _baseReserve,
                quoteAmountMinted.mul(_totalSupply) / _quoteReserve
            );
        }
        require(liquidity > 0, "AMM: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(_baseReserve + baseAmount, _quoteReserve + quoteAmountMinted, _baseReserve, _quoteReserve);
        _safeTransfer(baseToken, vault, baseAmount);
        quoteAmount = quoteAmountMinted;
        emit Mint(msg.sender, to, baseAmount, quoteAmountMinted, liquidity);
    }

    function getQuoteAmountByCurrentPrice(uint256 baseAmount) internal returns (uint256 quoteAmount) {
        return AMMLibrary.quote(baseAmount, uint256(baseReserve), uint256(quoteReserve));
    }

    function getQuoteAmountByPriceOracle(uint256 baseAmount) internal returns (uint256 quoteAmount) {
        // get price oracle
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        address priceOracle = IConfig(config).priceOracle();
        quoteAmount = IPriceOracle(priceOracle).quote(baseToken, quoteToken, baseAmount);
    }

    //todo
    function getSpotPrice() public returns (uint256) {
        if (quoteReserve == 0) {
            return 0;
        }
        return uint256(UQ112x112.encode(baseReserve).uqdiv(quoteReserve));
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        address _baseToken = baseToken; // gas savings

        uint256 vaultAmount = IERC20(_baseToken).balanceOf(address(vault));
        uint256 liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(_baseReserve) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(_quoteReserve) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "AMM: INSUFFICIENT_LIQUIDITY_BURNED");
        require(amount0 <= vaultAmount, "AMM: not enough base token withdraw");

        _burn(address(this), liquidity);

        uint256 balance0 = _baseReserve - amount0;
        uint256 balance1 = _quoteReserve - amount1;

        _update(balance0, balance1, _baseReserve, _quoteReserve);
        //  if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        // vault withdraw
        IVault(vault).withdraw(to, amount0);
        emit Burn(msg.sender, to, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        address inputAddress,
        address outputAddress,
        uint256 inputAmount,
        uint256 outputAmount
    ) external onlyMargin override nonReentrant returns (uint256[2] memory amounts) {
        require(inputAmount > 0 || outputAmount > 0, "AMM: INSUFFICIENT_OUTPUT_AMOUNT");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();

        require(inputAmount < _baseReserve && outputAmount < _quoteReserve, "AMM: INSUFFICIENT_LIQUIDITY");

        uint256 _inputAmount;
        uint256 _outputAmount;

        if (inputAddress != address(0x0) && inputAmount != 0) {
            _outputAmount = swapInput(inputAddress, inputAmount);
            _inputAmount = inputAmount;
        } else {
            _inputAmount = swapOutput(outputAddress, outputAmount);
            _outputAmount = outputAmount;
        }
        emit Swap(inputAddress, outputAddress, _inputAmount, _outputAmount);
        return [_inputAmount, _outputAmount];
    }

    function swapQuery(
        address inputAddress,
        address outputAddress,
        uint256 inputAmount,
        uint256 outputAmount
    ) public view override returns (uint256[2] memory amounts) {
        require(inputAmount > 0 || outputAmount > 0, "AMM: INSUFFICIENT_OUTPUT_AMOUNT");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        require(inputAmount < _baseReserve && outputAmount < _quoteReserve, "AMM: INSUFFICIENT_LIQUIDITY");

        uint256 _inputAmount;
        uint256 _outputAmount;

        if (inputAddress != address(0x0) && inputAmount != 0) {
            _outputAmount = swapInputQuery(inputAddress, inputAmount);
            _inputAmount = inputAmount;
        } else {
            _inputAmount = swapOutputQuery(outputAddress, outputAmount);
            _outputAmount = outputAmount;
        }

        return [_inputAmount, _outputAmount];
    }

    function forceSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override nonReentrant onlyMargin {
        require((inputToken == baseToken || inputToken == quoteToken), " wrong input address");
        require((outputToken == baseToken || outputToken == quoteToken), " wrong output address");
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        uint256 balance0;
        uint256 balance1;
        if (inputToken == baseToken) {
            balance0 = baseReserve + inputAmount;
            balance1 = quoteReserve - outputAmount;
        } else {
            balance0 = baseReserve - outputAmount;
            balance1 = quoteReserve + inputAmount;
        }
        _update(balance0, balance1, _baseReserve, _quoteReserve);
        emit ForceSwap(inputToken, outputToken, inputAmount, outputAmount);
    }

    function rebase() public override nonReentrant returns (uint256 amount) {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        uint256 quoteReserveDesired = getQuoteAmountByPriceOracle(_baseReserve);
        //todo config
        if (
            quoteReserveDesired.mul(100) >= uint256(_quoteReserve).mul(105) ||
            quoteReserveDesired.mul(100) <= uint256(_quoteReserve).mul(95)
        ) { 
            _update(_baseReserve, quoteReserveDesired, _baseReserve, _quoteReserve);
            
            amount = (quoteReserveDesired > _quoteReserve) ? (quoteReserveDesired -_quoteReserve) : (_quoteReserve - quoteReserveDesired ) ;

            emit Rebase(_quoteReserve, quoteReserveDesired, _baseReserve);
        }
    }

    function swapInput(address inputAddress, uint256 inputAmount) internal returns (uint256 amountOut) {
        require((inputAddress == baseToken || inputAddress == quoteToken), "AMM: wrong input address");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        uint256 balance0;
        uint256 balance1;

        if (inputAddress == baseToken) {
            amountOut = AMMLibrary.getAmountOut(inputAmount, _baseReserve, _quoteReserve);
            balance0 = _baseReserve + inputAmount;
            balance1 = _quoteReserve - amountOut;
            // if necessary open todo
            // uint balance0Adjusted = balance0.mul(1000).sub(inputAmount.mul(3));
            // uint balance1Adjusted = balance1.mul(1000);
            // require(balance0Adjusted.mul(balance1Adjusted) >= uint(_baseReserve).mul(_quoteReserve).mul(1000**2), 'AMM: K');
        } else {
            amountOut = AMMLibrary.getAmountOut(inputAmount, _quoteReserve, _baseReserve);
            balance0 = _baseReserve - amountOut;
            balance1 = _quoteReserve + inputAmount;
        }
        _update(balance0, balance1, _baseReserve, _quoteReserve);
    }

    function swapOutput(address outputAddress, uint256 outputAmount) internal returns (uint256 amountIn) {
        require((outputAddress == baseToken || outputAddress == quoteToken), "AMM: wrong output address");
        uint256 balance0;
        uint256 balance1;
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        if (outputAddress == baseToken) {
            amountIn = AMMLibrary.getAmountIn(outputAmount, _quoteReserve, _baseReserve);
            balance0 = _baseReserve - outputAmount;
            balance1 = _quoteReserve + amountIn;
        } else {
            amountIn = AMMLibrary.getAmountIn(outputAmount, _baseReserve, _quoteReserve);
            balance0 = _baseReserve + amountIn;
            balance1 = _quoteReserve - outputAmount;
        }
        _update(balance0, balance1, _baseReserve, _quoteReserve);
    }

    function swapInputQuery(address inputAddress, uint256 inputAmount) internal view returns (uint256 amountOut) {
        require((inputAddress == baseToken || inputAddress == quoteToken), "AMM: wrong input address");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings

        if (inputAddress == baseToken) {
            amountOut = AMMLibrary.getAmountOut(inputAmount, _baseReserve, _quoteReserve);
        } else {
            amountOut = AMMLibrary.getAmountOut(inputAmount, _quoteReserve, _baseReserve);
        }
    }

    function swapOutputQuery(address outputAddress, uint256 outputAmount) internal view returns (uint256 amountIn) {
        require((outputAddress == baseToken || outputAddress == quoteToken), "AMM: wrong output address");

        uint256 amountIn;
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings

        if (outputAddress == baseToken) {
            amountIn = AMMLibrary.getAmountIn(outputAmount, _quoteReserve, _baseReserve);
        } else {
            amountIn = AMMLibrary.getAmountIn(outputAmount, _baseReserve, _quoteReserve);
        }
    }

    function swapQueryWithAcctSpecMarkPrice(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view override returns (uint256[2] memory amounts) {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();

        uint256 quoteAmount;
        uint256 baseAmount;
        if (inputAmount != 0) {
            quoteAmount = inputAmount;
        } else {
            quoteAmount = outputAmount;
        }

        uint256 inputSquare = quoteAmount * quoteAmount;
        // L/vusd > 10000
        if (FullMath.mulDiv(_baseReserve, _quoteReserve, inputSquare) >= 10000) {
            baseAmount = AMMLibrary.quote(quoteAmount, _quoteReserve, _baseReserve);
        } else {
            // (sqrt(y/x)+ betal * deltay/L)
            uint256 L = uint256(_baseReserve) * uint256(_quoteReserve);
            uint8 beta = IConfig(config).beta();
            require(beta >= 50 && beta <= 100, "beta error");
            //112
            uint256 denominator = _quoteReserve + beta * quoteAmount;
            //224
            denominator = denominator * denominator;

            baseAmount = FullMath.mulDiv(quoteAmount, L, denominator);
        }

        return inputAmount == 0 ? [baseAmount, quoteAmount] : [quoteAmount, baseAmount];
    }

    //fallback

    modifier onlyMargin() {
        require(margin == msg.sender, "AMM:  margin ");
        _;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IMargin.sol";
import "./libraries/Math.sol";
import "./libraries/Decimal.sol";
import "./libraries/SignedDecimal.sol";
import "./utils/Reentrant.sol";

contract Margin is IMargin {
    bool private entered = false;
    using Decimal for uint256;
    using SignedDecimal for int256;

    struct Position {
        int256 quoteSize;
        int256 baseSize;
        uint256 tradeSize;
    }

    uint256 constant MAXRATIO = 10000;

    address public override factory;
    address public override amm;
    address public override baseToken;
    address public override quoteToken;
    address public override vault;
    address public override config;
    mapping(address => Position) public traderPositionMap;

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address _baseToken,
        address _quoteToken,
        address _config,
        address _amm,
        address _vault
    ) external override onlyFactory {
        //todo check if has initialized and address != 0
        amm = _amm;
        vault = _vault;
        config = _config;
        baseToken = _baseToken;
        quoteToken = _quoteToken;
    }

    function addMargin(address _trader, uint256 _depositAmount) external override nonReentrant {
        require(_depositAmount > 0, ">0");
        Position memory traderPosition = traderPositionMap[_trader];

        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        require(_depositAmount <= balance, "wrong deposit amount");

        traderPosition.baseSize = traderPosition.baseSize.addU(_depositAmount);
        IERC20(baseToken).transfer(address(vault), _depositAmount);

        _setPosition(_trader, traderPosition);
        emit AddMargin(_trader, _depositAmount);
    }

    function removeMargin(uint256 _withdrawAmount) external override nonReentrant {
        require(_withdrawAmount > 0, ">0");
        //fixme
        // address trader = msg.sender;
        address trader = tx.origin;

        Position memory traderPosition = traderPositionMap[trader];
        // check before subtract
        require(_withdrawAmount <= getWithdrawable(trader), "preCheck withdrawable");

        traderPosition.baseSize = traderPosition.baseSize.subU(_withdrawAmount);
        if (traderPosition.quoteSize == 0) {
            require(traderPosition.baseSize >= 0, "insufficient withdrawable");
        } else {
            // important! check position health
            _checkInitMarginRatio(traderPosition);
        }
        _setPosition(trader, traderPosition);

        IVault(vault).withdraw(trader, _withdrawAmount);

        emit RemoveMargin(trader, _withdrawAmount);
    }

    function openPosition(uint8 _side, uint256 _baseAmount) external override nonReentrant returns (uint256) {
        require(_baseAmount > 0, ">0");
        //fixme
        // address trader = msg.sender;
        address trader = tx.origin;

        Position memory traderPosition = traderPositionMap[trader];
        bool isLong = _side == 0;
        bool sameDir = traderPosition.quoteSize == 0 ||
            (traderPosition.quoteSize < 0 == isLong) ||
            (traderPosition.quoteSize > 0 == !isLong);

        //swap exact base to quote
        uint256 quoteAmount = _addPositionWithVAmm(isLong, _baseAmount);

        //old: quote -10, base 11; add long 5X position 1: quote -5, base +5; new: quote -15, base 16
        //old: quote 10, base -9; add long 5X position: quote -5, base +5; new: quote 5, base -4
        //old: quote 10, base -9; add long 15X position: quote -15, base +15; new: quote -5, base 6
        if (isLong) {
            traderPosition.quoteSize = traderPosition.quoteSize.subU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.addU(_baseAmount);
        } else {
            traderPosition.quoteSize = traderPosition.quoteSize.addU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.subU(_baseAmount);
        }

        if (sameDir) {
            traderPosition.tradeSize = traderPosition.tradeSize.add(_baseAmount);
        } else {
            traderPosition.tradeSize = traderPosition.tradeSize > _baseAmount
                ? traderPosition.tradeSize.sub(_baseAmount)
                : _baseAmount.sub(traderPosition.tradeSize);
        }

        _checkInitMarginRatio(traderPosition);
        _setPosition(trader, traderPosition);
        emit OpenPosition(trader, _side, _baseAmount, quoteAmount);

        return quoteAmount;
    }

    function closePosition(uint256 _quoteAmount) external override nonReentrant returns (uint256) {
        //fixme
        // address trader = msg.sender;
        address trader = tx.origin;

        Position memory traderPosition = traderPositionMap[trader];
        require(traderPosition.quoteSize != 0 && _quoteAmount != 0, "position cant 0");
        require(_quoteAmount <= traderPosition.quoteSize.abs(), "above position");
        //swap exact quote to base
        bool isLong = traderPosition.quoteSize < 0;
        uint256 baseAmount = _minusPositionWithVAmm(isLong, _quoteAmount);

        //old: quote -10, base 11; close position: quote 5, base -5; new: quote -5, base 6
        //old: quote 10, base -9; close position: quote -5, base +5; new: quote 5, base -4
        if (isLong) {
            traderPosition.quoteSize = traderPosition.quoteSize.addU(_quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.subU(baseAmount);
        } else {
            traderPosition.quoteSize = traderPosition.quoteSize.subU(_quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.addU(baseAmount);
        }
        traderPosition.tradeSize = traderPosition.tradeSize.sub(baseAmount);

        _checkInitMarginRatio(traderPosition);
        _setPosition(trader, traderPosition);
        emit ClosePosition(trader, _quoteAmount, baseAmount);
        return baseAmount;
    }

    function liquidate(address _trader)
        external
        override
        nonReentrant
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        )
    {
        Position memory traderPosition = traderPositionMap[_trader];
        int256 quoteSize = traderPosition.quoteSize;
        require(traderPosition.quoteSize != 0, "position 0");
        require(canLiquidate(_trader), "not liquidatable");

        bool isLong = traderPosition.quoteSize < 0;

        //query swap exact quote to base
        quoteAmount = traderPosition.quoteSize.abs();
        baseAmount = querySwapBaseWithVAmm(isLong, quoteAmount);

        //calc liquidate fee
        uint256 liquidateFeeRatio = IConfig(config).liquidateFeeRatio();
        bonus = baseAmount.mul(liquidateFeeRatio).div(MAXRATIO);
        int256 remainBaseAmount = traderPosition.baseSize.subU(baseAmount.sub(bonus));
        if (remainBaseAmount > 0) {
            _minusPositionWithVAmm(isLong, traderPosition.quoteSize.abs());
            IVault(vault).withdraw(_trader, remainBaseAmount.abs());
        } else {
            //with bad debt, update directly
            if (isLong) {
                IAmm(amm).forceSwap(
                    address(baseToken),
                    address(quoteToken),
                    remainBaseAmount.abs(),
                    traderPosition.quoteSize.abs()
                );
            } else {
                IAmm(amm).forceSwap(
                    address(quoteToken),
                    address(baseToken),
                    traderPosition.quoteSize.abs(),
                    remainBaseAmount.abs()
                );
            }
        }
        IVault(vault).withdraw(msg.sender, bonus);
        traderPosition.baseSize = 0;
        traderPosition.quoteSize = 0;
        traderPosition.tradeSize = 0;
        _setPosition(_trader, traderPosition);
        emit Liquidate(msg.sender, _trader, quoteSize.abs(), baseAmount, bonus);
    }

    function canLiquidate(address _trader) public view override returns (bool) {
        Position memory traderPosition = traderPositionMap[_trader];
        uint256 debtRatio = calDebtRatio(traderPosition.quoteSize, traderPosition.baseSize);
        return debtRatio >= IConfig(config).liquidateThreshold();
    }

    function queryMaxOpenPosition(uint8 _side, uint256 _baseAmount) external view override returns (uint256) {
        bool isLong = _side == 0;
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            _baseAmount,
            address(baseToken)
        );

        uint256[2] memory result = IAmm(amm).swapQueryWithAcctSpecMarkPrice(
            inputToken,
            outputToken,
            inputAmount,
            outputAmount
        );
        return isLong ? result[0] : result[1];
    }

    function getMarginRatio(address _trader) external view returns (uint256) {
        Position memory position = traderPositionMap[_trader];
        return _calMarginRatio(position.quoteSize, position.baseSize);
    }

    function querySwapBaseWithVAmm(bool isLong, uint256 _quoteAmount) public view returns (uint256) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            _quoteAmount,
            address(quoteToken)
        );

        uint256[2] memory result = IAmm(amm).swapQuery(inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    function calDebtRatio(int256 quoteSize, int256 baseSize) public view returns (uint256) {
        if (quoteSize == 0 || (quoteSize > 0 && baseSize >= 0)) {
            return 0;
        } else if (quoteSize < 0 && baseSize <= 0) {
            return MAXRATIO;
        } else if (quoteSize > 0) {
            //calculate asset
            uint256[2] memory result = IAmm(amm).swapQueryWithAcctSpecMarkPrice(
                address(quoteToken),
                address(baseToken),
                quoteSize.abs(),
                0
            );
            //todo need to delete 10, this 10 is for simulating price fluctuation, bad for long
            uint256 baseAmount = result[1] * 10;
            //fixme max debt ratio is MAXRATIO, ok?
            if (baseAmount == 0) {
                return MAXRATIO;
            }
            return baseSize.mul(-1).mulU(MAXRATIO).divU(baseAmount).abs();
        } else {
            //calculate debt
            uint256[2] memory result = IAmm(amm).swapQueryWithAcctSpecMarkPrice(
                address(baseToken),
                address(quoteToken),
                0,
                quoteSize.abs()
            );
            //todo need to delete 10, this 10 is for simulating price fluctuation, bad for long
            uint256 baseAmount = result[0] * 10;
            uint256 ratio = baseAmount.mul(MAXRATIO).div(baseSize.abs());
            if (MAXRATIO < ratio) {
                return MAXRATIO;
            }
            return ratio;
        }
    }

    function getPosition(address _trader)
        external
        view
        override
        returns (
            int256,
            int256,
            uint256
        )
    {
        Position memory position = traderPositionMap[_trader];
        return (position.baseSize, position.quoteSize, position.tradeSize);
    }

    function getWithdrawable(address _trader) public view override returns (uint256) {
        Position memory traderPosition = traderPositionMap[_trader];
        uint256 withdrawableMargin;
        if (traderPosition.quoteSize < 0) {
            uint256[2] memory result = IAmm(amm).swapQuery(
                address(baseToken),
                address(quoteToken),
                0,
                traderPosition.quoteSize.abs()
            );

            uint256 baseAmount = result[0];
            uint256 baseNeeded = baseAmount.mul(MAXRATIO).div(MAXRATIO - IConfig(config).initMarginRatio());
            if (baseAmount.mul(MAXRATIO) % (MAXRATIO - IConfig(config).initMarginRatio()) != 0) {
                baseNeeded += 1;
            }

            if (traderPosition.baseSize.abs() < baseNeeded) {
                withdrawableMargin = 0;
            } else {
                withdrawableMargin = traderPosition.baseSize.abs().sub(baseNeeded);
            }
        } else {
            uint256[2] memory result = IAmm(amm).swapQuery(
                address(quoteToken),
                address(baseToken),
                traderPosition.quoteSize.abs(),
                0
            );

            uint256 baseAmount = result[1];
            uint256 baseNeeded = baseAmount.mul(MAXRATIO - IConfig(config).initMarginRatio()).div(MAXRATIO);
            if (traderPosition.baseSize < int256(-1).mulU(baseNeeded)) {
                withdrawableMargin = 0;
            } else {
                withdrawableMargin = traderPosition.baseSize.sub(int256(-1).mulU(baseNeeded)).abs();
            }
        }
        return withdrawableMargin;
    }

    function _setPosition(address _trader, Position memory _position) internal {
        traderPositionMap[_trader] = _position;
    }

    function _addPositionWithVAmm(bool isLong, uint256 _baseAmount) internal returns (uint256) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            _baseAmount,
            address(baseToken)
        );

        uint256[2] memory result = IAmm(amm).swap(inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    function _minusPositionWithVAmm(bool isLong, uint256 _quoteAmount) internal returns (uint256) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            _quoteAmount,
            address(quoteToken)
        );

        uint256[2] memory result = IAmm(amm).swap(inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    function _getSwapParam(
        bool isLong,
        uint256 _quoteAmount,
        address _quoteToken
    )
        internal
        pure
        returns (
            address inputToken,
            address outputToken,
            uint256 inputAmount,
            uint256 outputAmount
        )
    {
        if (isLong) {
            outputToken = _quoteToken;
            outputAmount = _quoteAmount;
        } else {
            inputToken = _quoteToken;
            inputAmount = _quoteAmount;
        }
    }

    function _checkInitMarginRatio(Position memory traderPosition) internal view {
        require(
            _calMarginRatio(traderPosition.quoteSize, traderPosition.baseSize) >= IConfig(config).initMarginRatio(),
            "initMarginRatio"
        );
    }

    function _calMarginRatio(int256 quoteSize, int256 baseSize) internal view returns (uint256) {
        if (quoteSize == 0 || (quoteSize > 0 && baseSize >= 0)) {
            return MAXRATIO;
        } else if (quoteSize < 0 && baseSize <= 0) {
            return 0;
        } else if (quoteSize > 0) {
            //calculate asset
            uint256[2] memory result = IAmm(amm).swapQuery(address(quoteToken), address(baseToken), quoteSize.abs(), 0);
            uint256 baseAmount = result[1];
            if (baseSize.abs() >= baseAmount || baseAmount == 0) {
                return 0;
            }
            return baseSize.mulU(MAXRATIO).divU(baseAmount).addU(MAXRATIO).abs();
        } else {
            //calculate debt
            uint256[2] memory result = IAmm(amm).swapQuery(address(baseToken), address(quoteToken), 0, quoteSize.abs());

            uint256 baseAmount = result[0];
            uint256 ratio = baseAmount.mul(MAXRATIO).div(baseSize.abs());
            if (MAXRATIO < ratio) {
                return 0;
            }
            return MAXRATIO.sub(ratio);
        }
    }

    modifier onlyFactory() {
        require(factory == msg.sender, "factory");
        _;
    }

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IVault.sol";
import "./utils/Reentrant.sol";
import "./utils/Ownable.sol";

contract Vault is IVault, Reentrant, Ownable {
    address public override baseToken;
    address public override margin;
    address public override amm;
    address public override factory;

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address _baseToken,
        address _amm,
        address _margin
    ) external override onlyFactory {
        baseToken = _baseToken;
        amm = _amm;
        margin = _margin;
    }

    function withdraw(address _receiver, uint256 _amount) external override nonReentrant vAmmOrMargin {
        IERC20(baseToken).transfer(_receiver, _amount);
        emit Withdraw(msg.sender, _receiver, _amount);
    }

    function setMargin(address _margin) external override onlyAdmin {
        margin = _margin;
    }

    function setAmm(address _amm) external onlyAdmin {
        amm = _amm;
    }

    modifier vAmmOrMargin() {
        require(msg.sender == margin || msg.sender == amm, "vAmm or margin");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory);
        _;
    }
}

pragma solidity ^0.8.0;

import "./interfaces/IStaking.sol";
import "./interfaces/ILiquidityERC20.sol";
import "./utils/Reentrant.sol";

contract Staking is IStaking, Reentrant {
    address public override factory;
    address public override config;
    address public override stakingToken;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;

    constructor(address _config, address _stakingToken) {
        factory = msg.sender;
        config = _config;
        stakingToken = _stakingToken;
    }

    function stake(uint256 amount) external override nonReentrant {
        require(amount > 0, "Staking: Cannot stake 0");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        ILiquidityERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override nonReentrant {}
}

pragma solidity ^0.8.0;

import "./interfaces/ILiquidityERC20.sol";
import "./libraries/SafeMath.sol";

contract LiquidityERC20 is ILiquidityERC20 {

    using SafeMath for uint256;

    string public override constant name = "Davion LP";
    string public override constant symbol = "Davion-LP";
    uint8 public override constant decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
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

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
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
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
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
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
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
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "UniswapV2: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library Math {
    function min(int256 x, int256 y) internal pure returns (int256) {
        if (x > y) {
            return y;
        }
        return x;
    }

    function minU(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x > y) {
            return y;
        }
        return x;
    }
    
     // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

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

pragma solidity ^0.8.0;

import "../interfaces/IAmm.sol";

import "./SafeMath.sol";

library AMMLibrary {
    using SafeMath for uint256;

    // fetches and sorts the reserves for a pair
    function getReserves(
        address amm
    ) internal view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast) {

        ( reserve0,  reserve1, blockTimestampLast) = IAmm(amm).getReserves();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "AMMLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "AMMLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "AMMLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "AMMLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(999);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "AMMLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "AMMLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(999);
        amountIn = (numerator / denominator).add(1);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
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
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IPriceOracle {
    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IConfig {
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event LiquidateIncentiveChanged(uint256 oldIncentive, uint256 newIncentive);
    event RebasePriceGapChanged(uint256 oldGap, uint256 newGap);

    function pendingAdmin() external view returns (address);

    function admin() external view returns (address);

    function priceOracle() external view returns (address);

    function beta() external view returns (uint8);

    function liquidateIncentive() external view returns (uint256);

    function initMarginRatio() external view returns (uint256);

    function liquidateThreshold() external view returns (uint256);

    function liquidateFeeRatio() external view returns (uint256);

    function rebasePriceGap() external view returns (uint256);

    function onlyPCV() external view returns (bool);

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;

    function setPriceOracle(address newOracle) external;

    function setBeta(uint8 _beta) external;

    function setLiquidateIncentive(uint256 newIncentive) external;

    function setRebasePriceGap(uint256 newGap) external;
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered = false;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ILiquidityERC20 is IERC20 {
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
}

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library Decimal {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        return x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        return x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        return x / y;
    }

    //example:
    //int is -100 -> 100, uint is 0 -> 200,
    //so 100 -> 200 is -100 -> 0
    function oppo(uint256 x) internal pure returns (int256) {
        int256 _x = 0 - int256(x);
        require(uint256(_x) >= x, "overflow");
        return _x;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library SignedDecimal {
    function abs(int256 x) internal pure returns (uint256) {
        if (x < 0) {
            return uint256(0 - x);
        }
        return uint256(x);
    }

    function add(int256 x, int256 y) internal pure returns (int256) {
        return x + y;
    }

    function sub(int256 x, int256 y) internal pure returns (int256) {
        return x - y;
    }

    function mul(int256 x, int256 y) internal pure returns (int256) {
        return x * y;
    }

    function div(int256 x, int256 y) internal pure returns (int256) {
        return x / y;
    }

    function addU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x + int256(y);
    }

    function subU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x - int256(y);
    }

    function mulU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x * int256(y);
    }

    function divU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x / int256(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public _admin;
    address public _pendingAdmin;

    event OwnershipTransfer(address indexed previousAdmin, address indexed pendingAdmin);
    event OwnershipAccept(address indexed currentAdmin);

    constructor() {
        _admin = msg.sender;
    }

    function _setPendingAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Ownable: new admin is the zero address");
        require(newAdmin != _pendingAdmin, "Ownable: already set");
        _pendingAdmin = newAdmin;
        emit OwnershipTransfer(_admin, newAdmin);
    }

    function _acceptAdmin() public {
        require(msg.sender == _pendingAdmin, "Ownable: not pendingAdmin");
        _admin = _pendingAdmin;
        _pendingAdmin = address(0);
        emit OwnershipAccept(_pendingAdmin);
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender, "Ownable: caller is not the admin");
        _;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IStaking {
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function factory() external view returns (address);
    
    function config() external view returns (address);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;
}