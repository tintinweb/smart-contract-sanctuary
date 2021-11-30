// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import './interfaces/ITwapPair.sol';
import './libraries/Reserves.sol';
import './TwapLPToken.sol';
import './libraries/Math.sol';
import './interfaces/IERC20.sol';
import './interfaces/ITwapFactory.sol';
import './interfaces/ITwapOracle.sol';

contract TwapPair is Reserves, TwapLPToken, ITwapPair {
    using SafeMath for uint256;

    uint256 private constant PRECISION = 10**18;

    uint256 public override mintFee = 0;
    uint256 public override burnFee = 0;
    uint256 public override swapFee = 0;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override factory;
    address public override token0;
    address public override token1;
    address public override oracle;
    address public override trader;

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'TP_LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setMintFee(uint256 fee) external override {
        require(msg.sender == factory, 'TP_FORBIDDEN');
        mintFee = fee;
        emit SetMintFee(mintFee);
    }

    function setBurnFee(uint256 fee) external override {
        require(msg.sender == factory, 'TP_FORBIDDEN');
        burnFee = fee;
        emit SetBurnFee(burnFee);
    }

    function setSwapFee(uint256 fee) external override {
        require(msg.sender == factory, 'TP_FORBIDDEN');
        swapFee = fee;
        emit SetSwapFee(swapFee);
    }

    function setOracle(address _oracle) external override {
        require(msg.sender == factory, 'TP_FORBIDDEN');
        require(_oracle != address(0), 'TP_ADDRESS_ZERO');
        require(isContract(_oracle), 'TP_ORACLE_MUST_BE_CONTRACT');
        oracle = _oracle;
        emit SetOracle(oracle);
    }

    function setTrader(address _trader) external override {
        require(msg.sender == factory, 'TP_FORBIDDEN');
        trader = _trader;
        emit SetTrader(trader);
    }

    function collect(address to) external override lock {
        require(msg.sender == factory, 'TP_FORBIDDEN');
        require(to != address(0), 'TP_ADDRESS_ZERO');
        (uint256 fee0, uint256 fee1) = getFees();
        if (fee0 > 0) _safeTransfer(token0, to, fee0);
        if (fee1 > 0) _safeTransfer(token1, to, fee1);
        setFees(0, 0);
        _sync();
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TP_TRANSFER_FAILED');
    }

    function canTrade(address user) private view returns (bool) {
        return user == trader || user == factory || trader == address(-1);
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external override {
        require(msg.sender == factory, 'TP_FORBIDDEN');
        require(_oracle != address(0), 'TP_ADDRESS_ZERO');
        require(isContract(_oracle), 'TP_ORACLE_MUST_BE_CONTRACT');
        require(isContract(_token0) && isContract(_token1), 'TP_TOKEN_MUST_BE_CONTRACT');
        token0 = _token0;
        token1 = _token1;
        oracle = _oracle;
        trader = _trader;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint256 liquidity) {
        require(canTrade(msg.sender), 'TP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'TP_ADDRESS_ZERO');
        (uint112 reserve0, uint112 reserve1) = getReserves();
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        uint256 amount0 = balance0.sub(reserve0);
        uint256 amount1 = balance1.sub(reserve1);

        uint256 _totalSupply = totalSupply; // gas savings
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / reserve0, amount1.mul(_totalSupply) / reserve1);
        }

        require(liquidity > 0, 'TP_INSUFFICIENT_LIQUIDITY_MINTED');
        if (mintFee > 0) {
            uint256 fee = liquidity.mul(mintFee).div(PRECISION);
            liquidity = liquidity.sub(fee);
            _mint(factory, fee);
        }
        _mint(to, liquidity);

        setReserves(balance0, balance1);

        emit Mint(msg.sender, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint256 amount0, uint256 amount1) {
        require(canTrade(msg.sender), 'TP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'TP_ADDRESS_ZERO');
        uint256 _totalSupply = totalSupply; // gas savings
        require(_totalSupply > 0, 'TP_INSUFFICIENT_TOTAL_SUPPLY');
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        uint256 liquidity = balanceOf[address(this)];

        if (msg.sender != factory && burnFee > 0) {
            uint256 fee = liquidity.mul(burnFee).div(PRECISION);
            liquidity = liquidity.sub(fee);
            _transfer(address(this), factory, fee);
        }
        _burn(address(this), liquidity);

        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'TP_INSUFFICIENT_LIQUIDITY_BURNED');

        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        (balance0, balance1) = getBalances(token0, token1);
        setReserves(balance0, balance1);

        emit Burn(msg.sender, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override lock {
        require(canTrade(msg.sender), 'TP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'TP_ADDRESS_ZERO');
        require(
            (amount0Out > 0 && amount1Out == 0) || (amount1Out > 0 && amount0Out == 0),
            'TP_INVALID_OUTPUT_AMOUNTS'
        );
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'TP_INSUFFICIENT_LIQUIDITY');

        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'TP_INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        }
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);

        if (amount0Out > 0) {
            // trading token1 for token0
            uint256 amount1In = balance1 > _reserve1 ? balance1 - _reserve1 : 0;
            require(amount1In > 0, 'TP_INSUFFICIENT_INPUT_AMOUNT');

            uint256 fee1 = amount1In.mul(swapFee).div(PRECISION);
            uint256 balance1After = balance1.sub(fee1);
            uint256 balance0After = ITwapOracle(oracle).tradeY(balance1After, _reserve0, _reserve1, data);
            require(balance0 >= balance0After, 'TP_INVALID_SWAP');
            uint256 fee0 = balance0.sub(balance0After);
            addFees(fee0, fee1);
            setReserves(balance0After, balance1After);
        } else {
            // trading token0 for token1
            uint256 amount0In = balance0 > _reserve0 ? balance0 - _reserve0 : 0;
            require(amount0In > 0, 'TP_INSUFFICIENT_INPUT_AMOUNT');

            uint256 fee0 = amount0In.mul(swapFee).div(PRECISION);
            uint256 balance0After = balance0.sub(fee0);
            uint256 balance1After = ITwapOracle(oracle).tradeX(balance0After, _reserve0, _reserve1, data);
            require(balance1 >= balance1After, 'TP_INVALID_SWAP');
            uint256 fee1 = balance1.sub(balance1After);
            addFees(fee0, fee1);
            setReserves(balance0After, balance1After);
        }

        emit Swap(msg.sender, to);
    }

    function sync() external override lock {
        require(canTrade(msg.sender), 'TP_UNAUTHORIZED_TRADER');
        _sync();
    }

    // force reserves to match balances
    function _sync() internal {
        syncReserves(token0, token1);
        uint256 tokens = balanceOf[address(this)];
        if (tokens > 0) {
            _transfer(address(this), factory, tokens);
        }
    }

    function getSwapAmount0In(uint256 amount1Out, bytes calldata data)
        public
        view
        override
        returns (uint256 swapAmount0In)
    {
        (uint112 reserve0, uint112 reserve1) = getReserves();
        uint256 balance1After = uint256(reserve1).sub(amount1Out);
        uint256 balance0After = ITwapOracle(oracle).tradeY(balance1After, reserve0, reserve1, data);
        return balance0After.sub(uint256(reserve0)).mul(PRECISION).ceil_div(PRECISION.sub(swapFee));
    }

    function getSwapAmount1In(uint256 amount0Out, bytes calldata data)
        public
        view
        override
        returns (uint256 swapAmount1In)
    {
        (uint112 reserve0, uint112 reserve1) = getReserves();
        uint256 balance0After = uint256(reserve0).sub(amount0Out);
        uint256 balance1After = ITwapOracle(oracle).tradeX(balance0After, reserve0, reserve1, data);
        return balance1After.add(1).sub(uint256(reserve1)).mul(PRECISION).ceil_div(PRECISION.sub(swapFee));
    }

    function getSwapAmount0Out(uint256 amount1In, bytes calldata data)
        public
        view
        override
        returns (uint256 swapAmount0Out)
    {
        (uint112 reserve0, uint112 reserve1) = getReserves();
        uint256 fee = amount1In.mul(swapFee).div(PRECISION);
        uint256 balance0After = ITwapOracle(oracle).tradeY(
            uint256(reserve1).add(amount1In).sub(fee),
            reserve0,
            reserve1,
            data
        );
        return uint256(reserve0).sub(balance0After);
    }

    function getSwapAmount1Out(uint256 amount0In, bytes calldata data)
        public
        view
        override
        returns (uint256 swapAmount1Out)
    {
        (uint112 reserve0, uint112 reserve1) = getReserves();
        uint256 fee = amount0In.mul(swapFee).div(PRECISION);
        uint256 balance1After = ITwapOracle(oracle).tradeX(
            uint256(reserve0).add(amount0In).sub(fee),
            reserve0,
            reserve1,
            data
        );
        return uint256(reserve1).sub(balance1After);
    }

    function getDepositAmount0In(uint256 amount0, bytes calldata data) external view override returns (uint256) {
        (uint112 reserve0, uint112 reserve1) = getReserves();
        return ITwapOracle(oracle).depositTradeXIn(amount0, reserve0, reserve1, data);
    }

    function getDepositAmount1In(uint256 amount1, bytes calldata data) external view override returns (uint256) {
        (uint112 reserve0, uint112 reserve1) = getReserves();
        return ITwapOracle(oracle).depositTradeYIn(amount1, reserve0, reserve1, data);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import './ITwapERC20.sol';
import './IReserves.sol';

interface ITwapPair is ITwapERC20, IReserves {
    event Mint(address indexed sender, address indexed to);
    event Burn(address indexed sender, address indexed to);
    event Swap(address indexed sender, address indexed to);
    event SetMintFee(uint256 fee);
    event SetBurnFee(uint256 fee);
    event SetSwapFee(uint256 fee);
    event SetOracle(address account);
    event SetTrader(address trader);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function oracle() external view returns (address);

    function trader() external view returns (address);

    function mintFee() external view returns (uint256);

    function setMintFee(uint256 fee) external;

    function mint(address to) external returns (uint256 liquidity);

    function burnFee() external view returns (uint256);

    function setBurnFee(uint256 fee) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swapFee() external view returns (uint256);

    function setSwapFee(uint256 fee) external;

    function setOracle(address account) external;

    function setTrader(address account) external;

    function collect(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external;

    function getSwapAmount0In(uint256 amount1Out, bytes calldata data) external view returns (uint256 swapAmount0In);

    function getSwapAmount1In(uint256 amount0Out, bytes calldata data) external view returns (uint256 swapAmount1In);

    function getSwapAmount0Out(uint256 amount1In, bytes calldata data) external view returns (uint256 swapAmount0Out);

    function getSwapAmount1Out(uint256 amount0In, bytes calldata data) external view returns (uint256 swapAmount1Out);

    function getDepositAmount0In(uint256 amount0, bytes calldata data) external view returns (uint256 depositAmount0In);

    function getDepositAmount1In(uint256 amount1, bytes calldata data) external view returns (uint256 depositAmount1In);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import '../interfaces/IReserves.sol';
import '../interfaces/IERC20.sol';
import '../libraries/SafeMath.sol';

contract Reserves is IReserves {
    using SafeMath for uint256;

    uint112 private reserve0;
    uint112 private reserve1;

    uint256 private fee0;
    uint256 private fee1;

    function getReserves() public view override returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function setReserves(uint256 balance0MinusFee, uint256 balance1MinusFee) internal {
        require(balance0MinusFee != 0 && balance1MinusFee != 0, 'RS_ZERO');
        reserve0 = balance0MinusFee.toUint112();
        reserve1 = balance1MinusFee.toUint112();
    }

    function syncReserves(address token0, address token1) internal {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 oldBalance0 = fee0.add(reserve0);
        uint256 oldBalance1 = fee1.add(reserve1);

        if (balance0 != oldBalance0 || balance1 != oldBalance1) {
            if (oldBalance0 != 0) {
                fee0 = fee0.mul(balance0).div(oldBalance0);
            }
            if (oldBalance1 != 0) {
                fee1 = fee1.mul(balance1).div(oldBalance1);
            }

            setReserves(balance0.sub(fee0), balance1.sub(fee1));
        }
    }

    function getFees() public view override returns (uint256, uint256) {
        return (fee0, fee1);
    }

    function addFees(uint256 _fee0, uint256 _fee1) internal {
        setFees(fee0.add(_fee0), fee1.add(_fee1));
    }

    function setFees(uint256 _fee0, uint256 _fee1) internal {
        fee0 = _fee0;
        fee1 = _fee1;
        emit Fees(fee0, fee1);
    }

    function getBalances(address token0, address token1) internal returns (uint256, uint256) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        if (fee0 > balance0) {
            fee0 = balance0;
            emit Fees(fee0, fee1);
        }
        if (fee1 > balance1) {
            fee1 = balance1;
            emit Fees(fee0, fee1);
        }
        return (balance0.sub(fee0), balance1.sub(fee1));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import './libraries/AbstractERC20.sol';

contract TwapLPToken is AbstractERC20 {
    constructor() {
        name = 'Twap LP';
        symbol = 'TWAP-LP';
        decimals = 18;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
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

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface ITwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event OwnerSet(address owner);

    function owner() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external returns (address pair);

    function setOwner(address) external;

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external;

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external;

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external;

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface ITwapOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);

    function decimalsConverter() external view returns (int256);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function owner() external view returns (address);

    function uniswapPair() external view returns (address);

    function getPriceInfo() external view returns (uint256 priceAccumulator, uint32 priceTimestamp);

    function getSpotPrice() external view returns (uint256);

    function getAveragePrice(uint256 priceAccumulator, uint32 priceTimestamp) external view returns (uint256);

    function setOwner(address _owner) external;

    function setUniswapPair(address _uniswapPair) external;

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 yAfter);

    function tradeY(
        uint256 yAfter,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 xAfter);

    function depositTradeXIn(
        uint256 xLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 xIn);

    function depositTradeYIn(
        uint256 yLeft,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 yIn);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import './IERC20.sol';

interface ITwapERC20 is IERC20 {
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

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IReserves {
    event Fees(uint256 fee0, uint256 fee1);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getFees() external view returns (uint256 fee0, uint256 fee1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    int256 private constant _INT256_MIN = -2**255;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM_ADD_OVERFLOW');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM_SUB_UNDERFLOW');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint256 c = a / b;
        return c;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (c == mul(a, b)) {
            return c;
        } else {
            return add(c, 1);
        }
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, 'SM_EXCEEDS_32_BITS');
        return uint32(n);
    }

    function toUint112(uint256 n) internal pure returns (uint112) {
        require(n <= type(uint112).max, 'SM_EXCEEDS_112_BITS');
        return uint112(n);
    }

    function toInt256(uint256 unsigned) internal pure returns (int256 signed) {
        require(unsigned <= uint256(type(int256).max), 'SM_INVALID_INT_CONVERSION');
        signed = int256(unsigned);
    }

    // int256

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SM_ADDITION_OVERFLOW');

        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SM_SUBTRACTION_OVERFLOW');

        return c;
    }

    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SM_MULTIPLICATION_OVERFLOW');

        int256 c = a * b;
        require(c / a == b, 'SM_MULTIPLICATION_OVERFLOW');

        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SM_DIVISION_BY_ZERO');
        require(!(b == -1 && a == _INT256_MIN), 'SM_DIVISION_OVERFLOW');

        int256 c = a / b;

        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import '../interfaces/ITwapERC20.sol';
import './SafeMath.sol';

abstract contract AbstractERC20 is ITwapERC20 {
    using SafeMath for uint256;

    string public override name;
    string public override symbol;
    uint8 public override decimals;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

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
    ) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, 'TA_CANNOT_DECREASE');
        _approve(msg.sender, spender, currentAllowance.sub(subtractedValue));
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
        if (allowance[from][msg.sender] != uint256(-1)) {
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
        require(deadline >= block.timestamp, 'TA_EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                getDomainSeparator(),
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'TA_INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function getDomainSeparator() public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes('1')), chainId, address(this))
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma abicoder v2;

import './interfaces/ITwapReader.sol';
import './interfaces/ITwapPair.sol';
import './interfaces/ITwapOracle.sol';

contract TwapReader is ITwapReader {
    function isContract(address addressToCheck) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addressToCheck)
        }
        return size > 0;
    }

    function getPairParameters(address pairAddress)
        external
        view
        override
        returns (
            bool exists,
            uint112 reserve0,
            uint112 reserve1,
            uint256 price,
            uint256 mintFee,
            uint256 burnFee,
            uint256 swapFee
        )
    {
        exists = isContract(pairAddress);
        if (exists) {
            ITwapPair pair = ITwapPair(pairAddress);
            (reserve0, reserve1) = pair.getReserves();
            price = ITwapOracle(pair.oracle()).getSpotPrice();
            mintFee = pair.mintFee();
            burnFee = pair.burnFee();
            swapFee = pair.swapFee();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma abicoder v2;

interface ITwapReader {
    function getPairParameters(address pair)
        external
        view
        returns (
            bool exists,
            uint112 reserve0,
            uint112 reserve1,
            uint256 price,
            uint256 mintFee,
            uint256 burnFee,
            uint256 swapFee
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../TwapOracle.sol';
import '../interfaces/ITwapPair.sol';

contract TwapOracleTest is TwapOracle {
    constructor(uint8 _xDecimals, uint8 _yDecimals) TwapOracle(_xDecimals, _yDecimals) {}

    function testGetAveragePriceForNoTimeElapsed() external view returns (uint256) {
        (uint256 priceAccumulator, uint32 priceTimestamp) = getPriceInfo();
        return getAveragePrice(priceAccumulator, priceTimestamp);
    }

    function testEncodePriceInfo(uint256 priceAccumulator, uint32 priceTimestamp)
        external
        view
        returns (bytes memory priceInfo, uint256 price)
    {
        // Copied from TwapDelay
        price = getAveragePrice(priceAccumulator, priceTimestamp);
        // Pack everything as 32 bytes / uint256 to simplify decoding
        priceInfo = abi.encode(price);
    }

    function testEncodeGivenPrice(uint256 price) external pure returns (bytes memory) {
        return abi.encode(price);
    }

    function testDecodePriceInfo(bytes memory data) external pure returns (uint256 price) {
        return decodePriceInfo(data);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import './interfaces/ITwapOracle.sol';
import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';
import '@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol';

contract TwapOracle is ITwapOracle {
    using SafeMath for uint256;
    using SafeMath for int256;
    uint8 public immutable override xDecimals;
    uint8 public immutable override yDecimals;
    int256 public immutable override decimalsConverter;
    address public override owner;
    address public override uniswapPair;

    constructor(uint8 _xDecimals, uint8 _yDecimals) {
        require(_xDecimals <= 75 && _yDecimals <= 75, 'TO_DECIMALS_HIGHER_THAN_75');
        if (_yDecimals > _xDecimals) {
            require(_yDecimals - _xDecimals <= 18, 'TO_DECIMALS_DIFFERENCE_TOO_BIG');
        } else {
            require(_xDecimals - _yDecimals <= 18, 'TO_DECIMALS_DIFFERENCE_TOO_BIG');
        }
        owner = msg.sender;
        xDecimals = _xDecimals;
        yDecimals = _yDecimals;
        decimalsConverter = (10**(18 + _xDecimals - _yDecimals)).toInt256();
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TO_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setUniswapPair(address _uniswapPair) external override {
        require(msg.sender == owner, 'TO_FORBIDDEN');
        require(_uniswapPair != address(0), 'TO_ADDRESS_ZERO');
        require(isContract(_uniswapPair), 'TO_UNISWAP_PAIR_MUST_BE_CONTRACT');
        uniswapPair = _uniswapPair;

        IUniswapV2Pair pairContract = IUniswapV2Pair(uniswapPair);
        require(
            IERC20(pairContract.token0()).decimals() == xDecimals &&
                IERC20(pairContract.token1()).decimals() == yDecimals,
            'TO_DIFFERENT_DECIMALS'
        );

        (uint112 reserve0, uint112 reserve1, ) = pairContract.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'TO_NO_UNISWAP_RESERVES');
        emit UniswapPairSet(uniswapPair);
    }

    // based on: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2OracleLibrary.sol
    function getPriceInfo() public view override returns (uint256 priceAccumulator, uint32 priceTimestamp) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        priceAccumulator = pair.price0CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();

        // uint32 can be cast directly until Sun, 07 Feb 2106 06:28:15 GMT
        priceTimestamp = uint32(block.timestamp);
        if (blockTimestampLast != priceTimestamp) {
            // allow overflow to stay consistent with Uniswap code and save some gas
            uint32 timeElapsed = priceTimestamp - blockTimestampLast;
            priceAccumulator += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
        }
    }

    function decodePriceInfo(bytes memory data) internal pure returns (uint256 price) {
        assembly {
            price := mload(add(data, 32))
        }
    }

    function getSpotPrice() external view override returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(uniswapPair).getReserves();
        return uint256(reserve1).mul(uint256(decimalsConverter)).div(uint256(reserve0));
    }

    function getAveragePrice(uint256 priceAccumulator, uint32 priceTimestamp) public view override returns (uint256) {
        (uint256 currentPriceAccumulator, uint32 currentPriceTimestamp) = getPriceInfo();

        require(priceTimestamp < currentPriceTimestamp, 'TO_NO_TIME_ELAPSED');

        // overflow is desired
        uint32 timeElapsed = currentPriceTimestamp - priceTimestamp;

        FixedPoint.uq112x112 memory price0Average = FixedPoint.uq112x112(
            // overflow is desired
            uint224((currentPriceAccumulator - priceAccumulator) / timeElapsed)
        );

        return uint256(price0Average._x).mul(uint256(decimalsConverter)).div(2**112);
    }

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256 yAfter) {
        int256 xAfterInt = xAfter.toInt256();
        int256 xBeforeInt = xBefore.toInt256();
        int256 yBeforeInt = yBefore.toInt256();
        int256 averagePriceInt = decodePriceInfo(data).toInt256();

        int256 yTradedInt = xAfterInt.sub(xBeforeInt).mul(averagePriceInt);

        // yAfter = yBefore - yTraded = yBefore - ((xAfter - xBefore) * price)
        // we are multiplying yBefore by decimalsConverter to push division to the very end
        int256 yAfterInt = yBeforeInt.mul(decimalsConverter).sub(yTradedInt).div(decimalsConverter);
        require(yAfterInt >= 0, 'TO_NEGATIVE_Y_BALANCE');
        yAfter = uint256(yAfterInt);
    }

    function tradeY(
        uint256 yAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256 xAfter) {
        int256 yAfterInt = yAfter.toInt256();
        int256 xBeforeInt = xBefore.toInt256();
        int256 yBeforeInt = yBefore.toInt256();
        int256 averagePriceInt = decodePriceInfo(data).toInt256();

        int256 xTradedInt = yAfterInt.sub(yBeforeInt).mul(decimalsConverter);

        // xAfter = xBefore - xTraded = xBefore - ((yAfter - yBefore) * price)
        // we are multiplying xBefore by averagePriceInt to push division to the very end
        int256 xAfterInt = xBeforeInt.mul(averagePriceInt).sub(xTradedInt).div(averagePriceInt);
        require(xAfterInt >= 0, 'TO_NEGATIVE_X_BALANCE');

        xAfter = uint256(xAfterInt);
    }

    function depositTradeXIn(
        uint256 xLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256) {
        if (xBefore == 0 || yBefore == 0) {
            return 0;
        }

        // ratio after swap = ratio after second mint
        // (xBefore + xIn) / (yBefore - xIn * price) = (xBefore + xLeft) / yBefore
        // xIn = xLeft * yBefore / (price * (xLeft + xBefore) + yBefore)
        uint256 price = decodePriceInfo(data);
        uint256 numerator = xLeft.mul(yBefore);
        uint256 denominator = price.mul(xLeft.add(xBefore)).add(yBefore.mul(uint256(decimalsConverter)));
        uint256 xIn = numerator.mul(uint256(decimalsConverter)).div(denominator);

        // Don't swap when numbers are too large. This should actually never happen.
        if (xIn.mul(price).div(uint256(decimalsConverter)) >= yBefore || xIn >= xLeft) {
            return 0;
        }

        return xIn;
    }

    function depositTradeYIn(
        uint256 yLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256) {
        if (xBefore == 0 || yBefore == 0) {
            return 0;
        }

        // ratio after swap = ratio after second mint
        // (xBefore - yIn / price) / (yBefore + yIn) = xBefore / (yBefore + yLeft)
        // yIn = price * xBefore * yLeft / (price * xBefore + yLeft + yBefore)
        uint256 price = decodePriceInfo(data);
        uint256 numerator = price.mul(xBefore).mul(yLeft);
        uint256 denominator = price.mul(xBefore).add(yLeft.add(yBefore).mul(uint256(decimalsConverter)));
        uint256 yIn = numerator.div(denominator);

        // Don't swap when numbers are too large. This should actually never happen.
        if (yIn.mul(uint256(decimalsConverter)).div(price) >= xBefore || yIn >= yLeft) {
            return 0;
        }

        return yIn;
    }
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/SafeMath.sol';
import '../libraries/Math.sol';

contract SafeMathTest {
    using SafeMath for int256;

    function add(int256 a, int256 b) external pure returns (int256) {
        return a.add(b);
    }

    function sub(int256 a, int256 b) external pure returns (int256) {
        return a.sub(b);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import '../libraries/Math.sol';

contract MathC {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) public pure returns (uint256 z) {
        return Math.sqrt(y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import './TransferHelper.sol';
import './SafeMath.sol';
import './Math.sol';
import '../interfaces/ITwapPair.sol';
import '../interfaces/ITwapOracle.sol';

library AddLiquidity {
    using SafeMath for uint256;

    function _quote(
        uint256 amount0,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256 amountB) {
        require(amount0 > 0, 'AL_INSUFFICIENT_AMOUNT');
        require(reserve0 > 0 && reserve1 > 0, 'AL_INSUFFICIENT_LIQUIDITY');
        amountB = amount0.mul(reserve1) / reserve0;
    }

    function addLiquidity(
        address pair,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal view returns (uint256 amount0, uint256 amount1) {
        if (amount0Desired == 0 || amount1Desired == 0) {
            return (0, 0);
        }
        (uint256 reserve0, uint256 reserve1) = ITwapPair(pair).getReserves();
        if (reserve0 == 0 && reserve1 == 0) {
            (amount0, amount1) = (amount0Desired, amount1Desired);
        } else {
            uint256 amount1Optimal = _quote(amount0Desired, reserve0, reserve1);
            if (amount1Optimal <= amount1Desired) {
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = _quote(amount1Desired, reserve1, reserve0);
                assert(amount0Optimal <= amount0Desired);
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }
        }
    }

    function addLiquidityAndMint(
        address pair,
        address to,
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        (uint256 amount0, uint256 amount1) = addLiquidity(pair, amount0Desired, amount1Desired);
        if (amount0 == 0 || amount1 == 0) {
            return (amount0Desired, amount1Desired);
        }
        TransferHelper.safeTransfer(token0, pair, amount0);
        TransferHelper.safeTransfer(token1, pair, amount1);
        ITwapPair(pair).mint(to);

        amount0Left = amount0Desired.sub(amount0);
        amount1Left = amount1Desired.sub(amount1);
    }

    function swapDeposit0(
        address pair,
        address token0,
        uint256 amount0,
        uint256 minSwapPrice,
        bytes calldata data
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount0In = ITwapPair(pair).getDepositAmount0In(amount0, data);
        amount1Left = ITwapPair(pair).getSwapAmount1Out(amount0In, data);
        if (amount1Left == 0) {
            return (amount0, amount1Left);
        }
        uint256 price = getPrice(amount0In, amount1Left, pair);
        require(minSwapPrice == 0 || price >= minSwapPrice, 'AL_PRICE_TOO_LOW');
        TransferHelper.safeTransfer(token0, pair, amount0In);
        ITwapPair(pair).swap(0, amount1Left, address(this), data);
        amount0Left = amount0.sub(amount0In);
    }

    function swapDeposit1(
        address pair,
        address token1,
        uint256 amount1,
        uint256 maxSwapPrice,
        bytes calldata data
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount1In = ITwapPair(pair).getDepositAmount1In(amount1, data);
        amount0Left = ITwapPair(pair).getSwapAmount0Out(amount1In, data);
        if (amount0Left == 0) {
            return (amount0Left, amount1);
        }
        uint256 price = getPrice(amount0Left, amount1In, pair);
        require(maxSwapPrice == 0 || price <= maxSwapPrice, 'AL_PRICE_TOO_HIGH');
        TransferHelper.safeTransfer(token1, pair, amount1In);
        ITwapPair(pair).swap(amount0Left, 0, address(this), data);
        amount1Left = amount1.sub(amount1In);
    }

    function getPrice(
        uint256 amount0,
        uint256 amount1,
        address pair
    ) internal view returns (uint256) {
        ITwapOracle oracle = ITwapOracle(ITwapPair(pair).oracle());
        return amount1.mul(uint256(oracle.decimalsConverter())).div(amount0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, 'TH_ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma abicoder v2;

import './interfaces/ITwapPair.sol';
import './interfaces/ITwapDelay.sol';
import './interfaces/IWETH.sol';
import './libraries/SafeMath.sol';
import './libraries/Orders.sol';
import './libraries/TokenShares.sol';
import './libraries/AddLiquidity.sol';
import './libraries/WithdrawHelper.sol';

contract TwapDelay is ITwapDelay {
    using SafeMath for uint256;
    using Orders for Orders.Data;
    using TokenShares for TokenShares.Data;
    Orders.Data internal orders;
    TokenShares.Data internal tokenShares;

    string public TEST_TEST = 'TEST';
    uint256 public constant ORDER_CANCEL_TIME = 24 hours;
    uint256 public constant BOT_EXECUTION_TIME = 20 minutes;
    uint256 private constant ORDER_LIFESPAN = 48 hours;

    address public override owner;
    mapping(address => bool) public override isBot;

    constructor(
        address _factory,
        address _weth,
        address _bot
    ) {
        orders.factory = _factory;
        owner = msg.sender;
        isBot[_bot] = true;
        orders.gasPrice = tx.gasprice - (tx.gasprice % 1e6);
        tokenShares.setWeth(_weth);
        orders.delay = 30 minutes;
        orders.maxGasLimit = 5000000;
        orders.gasPriceInertia = 20000000;
        orders.maxGasPriceImpact = 1000000;
    }

    function getTransferGasCost(address token) external view override returns (uint256 gasCost) {
        return orders.transferGasCosts[token];
    }

    function getDepositOrder(uint256 orderId) external view override returns (Orders.DepositOrder memory order) {
        return orders.getDepositOrder(orderId);
    }

    function getWithdrawOrder(uint256 orderId) external view override returns (Orders.WithdrawOrder memory order) {
        return orders.getWithdrawOrder(orderId);
    }

    function getSellOrder(uint256 orderId) external view override returns (Orders.SellOrder memory order) {
        return orders.getSellOrder(orderId);
    }

    function getBuyOrder(uint256 orderId) external view override returns (Orders.BuyOrder memory order) {
        return orders.getBuyOrder(orderId);
    }

    function getDepositDisabled(address pair) external view override returns (bool) {
        return orders.getDepositDisabled(pair);
    }

    function getWithdrawDisabled(address pair) external view override returns (bool) {
        return orders.getWithdrawDisabled(pair);
    }

    function getBuyDisabled(address pair) external view override returns (bool) {
        return orders.getBuyDisabled(pair);
    }

    function getSellDisabled(address pair) external view override returns (bool) {
        return orders.getSellDisabled(pair);
    }

    function getOrderStatus(uint256 orderId) external view override returns (Orders.OrderStatus) {
        return orders.getOrderStatus(orderId);
    }

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'TD_LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function factory() external view override returns (address) {
        return orders.factory;
    }

    function totalShares(address token) external view override returns (uint256) {
        return tokenShares.totalShares[token];
    }

    function weth() external view override returns (address) {
        return tokenShares.weth;
    }

    function delay() external view override returns (uint32) {
        return orders.delay;
    }

    function lastProcessedOrderId() external view returns (uint256) {
        return orders.lastProcessedOrderId;
    }

    function newestOrderId() external view returns (uint256) {
        return orders.newestOrderId;
    }

    function getOrder(uint256 orderId) external view returns (Orders.OrderType orderType, uint32 validAfterTimestamp) {
        return orders.getOrder(orderId);
    }

    function isOrderCanceled(uint256 orderId) external view returns (bool) {
        return orders.canceled[orderId];
    }

    function maxGasLimit() external view override returns (uint256) {
        return orders.maxGasLimit;
    }

    function maxGasPriceImpact() external view override returns (uint256) {
        return orders.maxGasPriceImpact;
    }

    function gasPriceInertia() external view override returns (uint256) {
        return orders.gasPriceInertia;
    }

    function gasPrice() external view override returns (uint256) {
        return orders.gasPrice;
    }

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external override {
        require(msg.sender == owner, 'TD_FORBIDDEN');
        orders.setOrderDisabled(pair, orderType, disabled);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TD_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setBot(address _bot, bool _isBot) external override {
        require(msg.sender == owner, 'TD_FORBIDDEN');
        isBot[_bot] = _isBot;
        emit BotSet(_bot, _isBot);
    }

    function setMaxGasLimit(uint256 _maxGasLimit) external override {
        require(msg.sender == owner, 'TD_FORBIDDEN');
        orders.setMaxGasLimit(_maxGasLimit);
    }

    function setDelay(uint32 _delay) external override {
        require(msg.sender == owner, 'TD_FORBIDDEN');
        orders.delay = _delay;
        emit DelaySet(_delay);
    }

    function setGasPriceInertia(uint256 _gasPriceInertia) external override {
        require(msg.sender == owner, 'TD_FORBIDDEN');
        orders.setGasPriceInertia(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external override {
        require(msg.sender == owner, 'TD_FORBIDDEN');
        orders.setMaxGasPriceImpact(_maxGasPriceImpact);
    }

    function setTransferGasCost(address token, uint256 gasCost) external override {
        require(msg.sender == owner, 'TD_FORBIDDEN');
        orders.setTransferGasCost(token, gasCost);
    }

    function deposit(Orders.DepositParams calldata depositParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.deposit(depositParams, tokenShares);
        return orders.newestOrderId;
    }

    function withdraw(Orders.WithdrawParams calldata withdrawParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.withdraw(withdrawParams);
        return orders.newestOrderId;
    }

    function sell(Orders.SellParams calldata sellParams) external payable override lock returns (uint256 orderId) {
        orders.sell(sellParams, tokenShares);
        return orders.newestOrderId;
    }

    function buy(Orders.BuyParams calldata buyParams) external payable override lock returns (uint256 orderId) {
        orders.buy(buyParams, tokenShares);
        return orders.newestOrderId;
    }

    function execute(uint256 n) external override lock {
        emit Execute(msg.sender, n);
        uint256 gasBefore = gasleft();
        bool orderExecuted = false;
        bool senderCanExecute = isBot[msg.sender] || isBot[address(0)];
        for (uint256 i = 0; i < n; i++) {
            if (orders.canceled[orders.lastProcessedOrderId + 1]) {
                orders.dequeueCanceledOrder();
                continue;
            }
            (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getNextOrder();
            if (orderType == Orders.OrderType.Empty || validAfterTimestamp >= block.timestamp) {
                break;
            }
            require(senderCanExecute || block.timestamp >= validAfterTimestamp + BOT_EXECUTION_TIME, 'TD_FORBIDDEN');
            orderExecuted = true;
            if (orderType == Orders.OrderType.Deposit) {
                executeDeposit();
            } else if (orderType == Orders.OrderType.Withdraw) {
                executeWithdraw();
            } else if (orderType == Orders.OrderType.Sell) {
                executeSell();
            } else if (orderType == Orders.OrderType.Buy) {
                executeBuy();
            }
        }
        if (orderExecuted) {
            orders.updateGasPrice(gasBefore.sub(gasleft()));
        }
    }

    function executeDeposit() internal {
        uint256 gasStart = gasleft();
        Orders.DepositOrder memory depositOrder = orders.dequeueDepositOrder();
        (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: depositOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[token0]).add(orders.transferGasCosts[token1])
            )
        }(abi.encodeWithSelector(this._executeDeposit.selector, depositOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundTokens(
                depositOrder.to,
                token0,
                depositOrder.share0,
                token1,
                depositOrder.share1,
                depositOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(
            depositOrder.gasLimit,
            depositOrder.gasPrice,
            gasStart,
            depositOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeWithdraw() internal {
        uint256 gasStart = gasleft();
        Orders.WithdrawOrder memory withdrawOrder = orders.dequeueWithdrawOrder();
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: withdrawOrder.gasLimit.sub(Orders.ORDER_BASE_COST.add(Orders.PAIR_TRANSFER_COST))
        }(abi.encodeWithSelector(this._executeWithdraw.selector, withdrawOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            refundSuccess = refundLiquidity(pair, withdrawOrder.to, withdrawOrder.liquidity);
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(
            withdrawOrder.gasLimit,
            withdrawOrder.gasPrice,
            gasStart,
            withdrawOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeSell() internal {
        uint256 gasStart = gasleft();
        Orders.SellOrder memory sellOrder = orders.dequeueSellOrder();
        (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: sellOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[sellOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeSell.selector, sellOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                sellOrder.inverse ? token1 : token0,
                sellOrder.to,
                sellOrder.shareIn,
                sellOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(sellOrder.gasLimit, sellOrder.gasPrice, gasStart, sellOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeBuy() internal {
        uint256 gasStart = gasleft();
        Orders.BuyOrder memory buyOrder = orders.dequeueBuyOrder();
        (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: buyOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[buyOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeBuy.selector, buyOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                buyOrder.inverse ? token1 : token0,
                buyOrder.to,
                buyOrder.shareInMax,
                buyOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(buyOrder.gasLimit, buyOrder.gasPrice, gasStart, buyOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function finalizeOrder(bool refundSuccess) private {
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
    }

    function refund(
        uint256 gasLimit,
        uint256 gasPriceInOrder,
        uint256 gasStart,
        address to
    ) private returns (uint256 gasUsed, uint256 leftOver) {
        uint256 feeCollected = gasLimit.mul(gasPriceInOrder);
        gasUsed = gasStart.sub(gasleft()).add(Orders.REFUND_BASE_COST);
        uint256 actualRefund = Math.min(feeCollected, gasUsed.mul(orders.gasPrice));
        leftOver = feeCollected.sub(actualRefund);
        require(refundEth(msg.sender, actualRefund), 'TD_ETH_REFUND_FAILED');
        refundEth(payable(to), leftOver);
    }

    function refundEth(address payable to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return true;
        }
        success = to.send(value);
        emit EthRefund(to, success, value);
    }

    function refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) private returns (bool) {
        if (share == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: orders.transferGasCosts[token] }(
            abi.encodeWithSelector(this._refundToken.selector, token, to, share, unwrap)
        );
        if (!success) {
            emit RefundFailed(to, token, share, data);
        }
        return success;
    }

    function refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) private returns (bool) {
        (bool success, bytes memory data) = address(this).call{
            gas: orders.transferGasCosts[token0].add(orders.transferGasCosts[token1])
        }(abi.encodeWithSelector(this._refundTokens.selector, to, token0, share0, token1, share1, unwrap));
        if (!success) {
            emit RefundFailed(to, token0, share0, data);
            emit RefundFailed(to, token1, share1, data);
        }
        return success;
    }

    function _refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) external {
        // no need to check sender, because it is checked in _refundToken
        _refundToken(token0, to, share0, unwrap);
        _refundToken(token1, to, share1, unwrap);
    }

    function _refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) public {
        require(msg.sender == address(this), 'TD_FORBIDDEN');
        if (token == tokenShares.weth && unwrap) {
            uint256 amount = tokenShares.sharesToAmount(token, share);
            IWETH(tokenShares.weth).withdraw(amount);
            payable(to).transfer(amount);
        } else {
            TransferHelper.safeTransfer(token, to, tokenShares.sharesToAmount(token, share));
        }
    }

    function refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) private returns (bool) {
        if (liquidity == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: Orders.PAIR_TRANSFER_COST }(
            abi.encodeWithSelector(this._refundLiquidity.selector, pair, to, liquidity, false)
        );
        if (!success) {
            emit RefundFailed(to, pair, liquidity, data);
        }
        return success;
    }

    function _refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) external {
        require(msg.sender == address(this), 'TD_FORBIDDEN');
        return TransferHelper.safeTransfer(pair, to, liquidity);
    }

    function _executeDeposit(Orders.DepositOrder memory depositOrder) external {
        require(msg.sender == address(this), 'TD_FORBIDDEN');
        require(depositOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD_EXPIRED');

        (address pair, address token0, address token1, uint256 amount0Left, uint256 amount1Left) = _initialDeposit(
            depositOrder
        );
        if (depositOrder.swap) {
            if (amount0Left != 0) {
                (amount0Left, amount1Left) = AddLiquidity.swapDeposit0(
                    pair,
                    token0,
                    amount0Left,
                    depositOrder.minSwapPrice,
                    encodePriceInfo(pair, depositOrder.priceAccumulator, depositOrder.timestamp)
                );
            } else if (amount1Left != 0) {
                (amount0Left, amount1Left) = AddLiquidity.swapDeposit1(
                    pair,
                    token1,
                    amount1Left,
                    depositOrder.maxSwapPrice,
                    encodePriceInfo(pair, depositOrder.priceAccumulator, depositOrder.timestamp)
                );
            }
        }
        if (amount0Left != 0 && amount1Left != 0) {
            (amount0Left, amount1Left) = AddLiquidity.addLiquidityAndMint(
                pair,
                depositOrder.to,
                token0,
                token1,
                amount0Left,
                amount1Left
            );
        }

        _refundDeposit(depositOrder.to, token0, token1, amount0Left, amount1Left);
    }

    function _initialDeposit(Orders.DepositOrder memory depositOrder)
        private
        returns (
            address pair,
            address token0,
            address token1,
            uint256 amount0Left,
            uint256 amount1Left
        )
    {
        (pair, token0, token1) = orders.getPairInfo(depositOrder.pairId);
        uint256 amount0Desired = tokenShares.sharesToAmount(token0, depositOrder.share0);
        uint256 amount1Desired = tokenShares.sharesToAmount(token1, depositOrder.share1);
        ITwapPair(pair).sync();
        (amount0Left, amount1Left) = AddLiquidity.addLiquidityAndMint(
            pair,
            depositOrder.to,
            token0,
            token1,
            amount0Desired,
            amount1Desired
        );
    }

    function _refundDeposit(
        address to,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) private {
        if (amount0 > 0) {
            TransferHelper.safeTransfer(token0, to, amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransfer(token1, to, amount1);
        }
    }

    function _executeWithdraw(Orders.WithdrawOrder memory withdrawOrder) external {
        require(msg.sender == address(this), 'TD_FORBIDDEN');
        require(withdrawOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD_EXPIRED');

        (address pair, address token0, address token1) = orders.getPairInfo(withdrawOrder.pairId);
        ITwapPair(pair).sync();
        TransferHelper.safeTransfer(pair, pair, withdrawOrder.liquidity);

        (uint256 wethAmount, uint256 amount0, uint256 amount1) = (0, 0, 0);
        if (withdrawOrder.unwrap && (token0 == tokenShares.weth || token1 == tokenShares.weth)) {
            bool success;
            (success, wethAmount, amount0, amount1) = WithdrawHelper.withdrawAndUnwrap(
                token0,
                token1,
                pair,
                tokenShares.weth,
                withdrawOrder.to
            );
            if (!success) {
                tokenShares.onUnwrapFailed(withdrawOrder.to, wethAmount);
            }
        } else {
            (amount0, amount1) = ITwapPair(pair).burn(withdrawOrder.to);
        }
        require(amount0 >= withdrawOrder.amount0Min && amount1 >= withdrawOrder.amount1Min, 'TD_INSUFFICIENT_AMOUNT');
    }

    function _executeBuy(Orders.BuyOrder memory buyOrder) external {
        require(msg.sender == address(this), 'TD_FORBIDDEN');
        require(buyOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD_EXPIRED');

        (address pairAddress, address tokenIn, address tokenOut) = _getPairAndTokens(buyOrder.pairId, buyOrder.inverse);
        uint256 amountInMax = tokenShares.sharesToAmount(tokenIn, buyOrder.shareInMax);
        ITwapPair pair = ITwapPair(pairAddress);
        pair.sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, buyOrder.priceAccumulator, buyOrder.timestamp);
        uint256 amountIn = buyOrder.inverse
            ? pair.getSwapAmount1In(buyOrder.amountOut, priceInfo)
            : pair.getSwapAmount0In(buyOrder.amountOut, priceInfo);
        require(amountInMax >= amountIn, 'TD_INSUFFICIENT_INPUT_AMOUNT');
        if (amountInMax > amountIn) {
            if (tokenIn == tokenShares.weth && buyOrder.unwrap) {
                _forceEtherTransfer(buyOrder.to, amountInMax.sub(amountIn));
            } else {
                TransferHelper.safeTransfer(tokenIn, buyOrder.to, amountInMax.sub(amountIn));
            }
        }
        (uint256 amount0Out, uint256 amount1Out) = buyOrder.inverse
            ? (buyOrder.amountOut, uint256(0))
            : (uint256(0), buyOrder.amountOut);
        TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        if (tokenOut == tokenShares.weth && buyOrder.unwrap) {
            pair.swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(buyOrder.to, buyOrder.amountOut);
        } else {
            pair.swap(amount0Out, amount1Out, buyOrder.to, priceInfo);
        }
    }

    function _executeSell(Orders.SellOrder memory sellOrder) external {
        require(msg.sender == address(this), 'TD_FORBIDDEN');
        require(sellOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD_EXPIRED');

        (address pairAddress, address tokenIn, address tokenOut) = _getPairAndTokens(
            sellOrder.pairId,
            sellOrder.inverse
        );
        uint256 amountIn = tokenShares.sharesToAmount(tokenIn, sellOrder.shareIn);
        ITwapPair pair = ITwapPair(pairAddress);
        pair.sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, sellOrder.priceAccumulator, sellOrder.timestamp);
        uint256 amountOut = sellOrder.inverse
            ? pair.getSwapAmount0Out(amountIn, priceInfo)
            : pair.getSwapAmount1Out(amountIn, priceInfo);
        require(amountOut >= sellOrder.amountOutMin, 'TD_INSUFFICIENT_OUTPUT_AMOUNT');
        (uint256 amount0Out, uint256 amount1Out) = sellOrder.inverse
            ? (amountOut, uint256(0))
            : (uint256(0), amountOut);
        TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        if (tokenOut == tokenShares.weth && sellOrder.unwrap) {
            pair.swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(sellOrder.to, amountOut);
        } else {
            pair.swap(amount0Out, amount1Out, sellOrder.to, priceInfo);
        }
    }

    function _getPairAndTokens(uint32 pairId, bool pairInversed)
        private
        view
        returns (
            address,
            address,
            address
        )
    {
        (address pairAddress, address token0, address token1) = orders.getPairInfo(pairId);
        (address tokenIn, address tokenOut) = pairInversed ? (token1, token0) : (token0, token1);
        return (pairAddress, tokenIn, tokenOut);
    }

    function _forceEtherTransfer(address to, uint256 amount) internal {
        IWETH(tokenShares.weth).withdraw(amount);
        (bool success, ) = to.call{ value: amount, gas: Orders.ETHER_TRANSFER_CALL_COST }('');
        if (!success) {
            tokenShares.onUnwrapFailed(to, amount);
        }
    }

    function performRefund(
        Orders.OrderType orderType,
        uint256 validAfterTimestamp,
        uint256 orderId,
        bool shouldRefundEth
    ) internal {
        require(orderType != Orders.OrderType.Empty, 'TD_EMPTY_ORDER');
        bool canOwnerRefund = validAfterTimestamp.add(365 days) < block.timestamp;

        if (orderType == Orders.OrderType.Deposit) {
            Orders.DepositOrder memory depositOrder = orders.getDepositOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
            address to = canOwnerRefund ? owner : depositOrder.to;
            require(
                refundTokens(to, token0, depositOrder.share0, token1, depositOrder.share1, depositOrder.unwrap),
                'TD_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = depositOrder.gasPrice.mul(depositOrder.gasLimit);
                require(refundEth(payable(to), value), 'TD_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Withdraw) {
            Orders.WithdrawOrder memory withdrawOrder = orders.getWithdrawOrder(orderId);
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            address to = canOwnerRefund ? owner : withdrawOrder.to;
            require(refundLiquidity(pair, to, withdrawOrder.liquidity), 'TD_REFUND_FAILED');
            if (shouldRefundEth) {
                uint256 value = withdrawOrder.gasPrice.mul(withdrawOrder.gasLimit);
                require(refundEth(payable(to), value), 'TD_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Sell) {
            Orders.SellOrder memory sellOrder = orders.getSellOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
            address to = canOwnerRefund ? owner : sellOrder.to;
            require(
                refundToken(sellOrder.inverse ? token1 : token0, to, sellOrder.shareIn, sellOrder.unwrap),
                'TD_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = sellOrder.gasPrice.mul(sellOrder.gasLimit);
                require(refundEth(payable(to), value), 'TD_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Buy) {
            Orders.BuyOrder memory buyOrder = orders.getBuyOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
            address to = canOwnerRefund ? owner : buyOrder.to;
            require(
                refundToken(buyOrder.inverse ? token1 : token0, to, buyOrder.shareInMax, buyOrder.unwrap),
                'TD_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = buyOrder.gasPrice.mul(buyOrder.gasLimit);
                require(refundEth(payable(to), value), 'TD_ETH_REFUND_FAILED');
            }
        }
        orders.forgetOrder(orderId);
    }

    function retryRefund(uint256 orderId) external override lock {
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getFailedOrderType(orderId);
        performRefund(orderType, validAfterTimestamp, orderId, false);
    }

    function cancelOrder(uint256 orderId) external override lock {
        require(orders.canceled[orderId] == false, 'TD_ALREADY_CANCELED');
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getOrder(orderId);
        require(
            validAfterTimestamp.sub(orders.delay).add(ORDER_CANCEL_TIME) < block.timestamp,
            'TD_ORDER_NOT_EXCEEDED'
        );
        orders.canceled[orderId] = true;
        performRefund(orderType, validAfterTimestamp, orderId, true);
    }

    function encodePriceInfo(
        address pair,
        uint256 priceAccumulator,
        uint32 priceTimestamp
    ) internal view returns (bytes memory data) {
        uint256 price = ITwapOracle(ITwapPair(pair).oracle()).getAveragePrice(priceAccumulator, priceTimestamp);
        // Pack everything as 32 bytes / uint256 to simplify decoding
        data = abi.encode(price);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma abicoder v2;

import '../libraries/Orders.sol';

interface ITwapDelay {
    event OrderExecuted(uint256 indexed id, bool indexed success, bytes data, uint256 gasSpent, uint256 ethRefunded);
    event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);
    event EthRefund(address indexed to, bool indexed success, uint256 value);
    event OwnerSet(address owner);
    event BotSet(address bot, bool isBot);
    event DelaySet(uint256 delay);
    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);
    event OrderDisabled(address pair, Orders.OrderType orderType, bool disabled);
    event UnwrapFailed(address to, uint256 amount);
    event Execute(address sender, uint256 n);

    function factory() external returns (address);

    function owner() external returns (address);

    function isBot(address bot) external returns (bool);

    function gasPriceInertia() external returns (uint256);

    function gasPrice() external returns (uint256);

    function maxGasPriceImpact() external returns (uint256);

    function maxGasLimit() external returns (uint256);

    function delay() external returns (uint32);

    function totalShares(address token) external returns (uint256);

    function weth() external returns (address);

    function getTransferGasCost(address token) external returns (uint256);

    function getDepositOrder(uint256 orderId) external returns (Orders.DepositOrder memory order);

    function getWithdrawOrder(uint256 orderId) external returns (Orders.WithdrawOrder memory order);

    function getSellOrder(uint256 orderId) external returns (Orders.SellOrder memory order);

    function getBuyOrder(uint256 orderId) external returns (Orders.BuyOrder memory order);

    function getDepositDisabled(address pair) external returns (bool);

    function getWithdrawDisabled(address pair) external returns (bool);

    function getBuyDisabled(address pair) external returns (bool);

    function getSellDisabled(address pair) external returns (bool);

    function getOrderStatus(uint256 orderId) external returns (Orders.OrderStatus);

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external;

    function setOwner(address _owner) external;

    function setBot(address _bot, bool _isBot) external;

    function setMaxGasLimit(uint256 _maxGasLimit) external;

    function setDelay(uint32 _delay) external;

    function setGasPriceInertia(uint256 _gasPriceInertia) external;

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external;

    function setTransferGasCost(address token, uint256 gasCost) external;

    function deposit(Orders.DepositParams memory depositParams) external payable returns (uint256 orderId);

    function withdraw(Orders.WithdrawParams memory withdrawParams) external payable returns (uint256 orderId);

    function sell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    function buy(Orders.BuyParams memory buyParams) external payable returns (uint256 orderId);

    function execute(uint256 n) external;

    function retryRefund(uint256 orderId) external;

    function cancelOrder(uint256 orderId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity =0.7.5;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma abicoder v2;

import './SafeMath.sol';
import '../libraries/Math.sol';
import '../interfaces/ITwapFactory.sol';
import '../interfaces/ITwapPair.sol';
import '../interfaces/ITwapOracle.sol';
import '../libraries/TokenShares.sol';

library Orders {
    using SafeMath for uint256;
    using TokenShares for TokenShares.Data;
    using TransferHelper for address;

    enum OrderType {
        Empty,
        Deposit,
        Withdraw,
        Sell,
        Buy
    }
    enum OrderStatus {
        NonExistent,
        EnqueuedWaiting,
        EnqueuedReady,
        ExecutedSucceeded,
        ExecutedFailed,
        Canceled
    }

    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);

    event DepositEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event WithdrawEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event SellEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event BuyEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);

    event OrderDisabled(address pair, Orders.OrderType orderType, bool disabled);

    uint8 private constant DEPOSIT_TYPE = 1;
    uint8 private constant WITHDRAW_TYPE = 2;
    uint8 private constant BUY_TYPE = 3;
    uint8 private constant BUY_INVERTED_TYPE = 4;
    uint8 private constant SELL_TYPE = 5;
    uint8 private constant SELL_INVERTED_TYPE = 6;

    uint8 private constant UNWRAP_NOT_FAILED = 0;
    uint8 private constant KEEP_NOT_FAILED = 1;
    uint8 private constant UNWRAP_FAILED = 2;
    uint8 private constant KEEP_FAILED = 3;

    uint256 private constant ETHER_TRANSFER_COST = 2300;
    uint256 private constant BUFFER_COST = 10000;
    uint256 private constant ORDER_EXECUTED_EVENT_COST = 3700;
    uint256 private constant EXECUTE_PREPARATION_COST = 55000; // dequeue + getPair in execute

    uint256 public constant ETHER_TRANSFER_CALL_COST = 10000;
    uint256 public constant PAIR_TRANSFER_COST = 55000;
    uint256 public constant REFUND_BASE_COST = 2 * ETHER_TRANSFER_COST + BUFFER_COST + ORDER_EXECUTED_EVENT_COST;
    uint256 public constant ORDER_BASE_COST = EXECUTE_PREPARATION_COST + REFUND_BASE_COST;

    // Masks used for setting order disabled
    // Different bits represent different order types
    uint8 private constant DEPOSIT_MASK = uint8(1) << uint8(OrderType.Deposit); //   00000010
    uint8 private constant WITHDRAW_MASK = uint8(1) << uint8(OrderType.Withdraw); // 00000100
    uint8 private constant SELL_MASK = uint8(1) << uint8(OrderType.Sell); //         00001000
    uint8 private constant BUY_MASK = uint8(1) << uint8(OrderType.Buy); //           00010000

    struct PairInfo {
        address pair;
        address token0;
        address token1;
    }

    struct Data {
        uint32 delay;
        uint256 newestOrderId;
        uint256 lastProcessedOrderId;
        mapping(uint256 => StoredOrder) orderQueue;
        address factory;
        uint256 maxGasLimit;
        uint256 gasPrice;
        uint256 gasPriceInertia;
        uint256 maxGasPriceImpact;
        mapping(uint32 => PairInfo) pairs;
        mapping(address => uint256) transferGasCosts;
        mapping(uint256 => bool) canceled;
        // Bit on specific positions indicates whether order type is disabled (1) or enabled (0) on specific pair
        mapping(address => uint8) orderDisabled;
    }

    struct StoredOrder {
        // slot 0
        uint8 orderType;
        uint32 validAfterTimestamp;
        uint8 unwrapAndFailure;
        uint32 timestamp;
        uint32 gasLimit;
        uint32 gasPrice;
        uint112 liquidity;
        // slot 1
        uint112 value0;
        uint112 value1;
        uint32 pairId;
        // slot2
        address to;
        uint32 minSwapPrice;
        uint32 maxSwapPrice;
        bool swap;
        // slot3
        uint256 priceAccumulator;
    }

    struct DepositOrder {
        uint32 pairId;
        uint256 share0;
        uint256 share1;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool unwrap;
        bool swap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint32 validAfterTimestamp;
        uint256 priceAccumulator;
        uint32 timestamp;
    }

    struct WithdrawOrder {
        uint32 pairId;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint32 validAfterTimestamp;
    }

    struct SellOrder {
        uint32 pairId;
        bool inverse;
        uint256 shareIn;
        uint256 amountOutMin;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint32 validAfterTimestamp;
        uint256 priceAccumulator;
        uint32 timestamp;
    }

    struct BuyOrder {
        uint32 pairId;
        bool inverse;
        uint256 shareInMax;
        uint256 amountOut;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint32 validAfterTimestamp;
        uint256 priceAccumulator;
        uint32 timestamp;
    }

    function decodeType(uint256 internalType) internal pure returns (OrderType orderType) {
        if (internalType == DEPOSIT_TYPE) {
            orderType = OrderType.Deposit;
        } else if (internalType == WITHDRAW_TYPE) {
            orderType = OrderType.Withdraw;
        } else if (internalType == BUY_TYPE) {
            orderType = OrderType.Buy;
        } else if (internalType == BUY_INVERTED_TYPE) {
            orderType = OrderType.Buy;
        } else if (internalType == SELL_TYPE) {
            orderType = OrderType.Sell;
        } else if (internalType == SELL_INVERTED_TYPE) {
            orderType = OrderType.Sell;
        } else {
            orderType = OrderType.Empty;
        }
    }

    function getOrder(Data storage data, uint256 orderId)
        public
        view
        returns (OrderType orderType, uint32 validAfterTimestamp)
    {
        StoredOrder storage order = data.orderQueue[orderId];
        uint8 internalType = order.orderType;
        validAfterTimestamp = order.validAfterTimestamp;
        orderType = decodeType(internalType);
    }

    function getOrderStatus(Data storage data, uint256 orderId) external view returns (OrderStatus orderStatus) {
        if (orderId > data.newestOrderId) {
            return OrderStatus.NonExistent;
        }
        if (data.canceled[orderId]) {
            return OrderStatus.Canceled;
        }
        if (isRefundFailed(data, orderId)) {
            return OrderStatus.ExecutedFailed;
        }
        (OrderType orderType, uint32 validAfterTimestamp) = getOrder(data, orderId);
        if (orderType == OrderType.Empty) {
            return OrderStatus.ExecutedSucceeded;
        }
        if (validAfterTimestamp >= block.timestamp) {
            return OrderStatus.EnqueuedWaiting;
        }
        return OrderStatus.EnqueuedReady;
    }

    function getPair(
        Data storage data,
        address tokenA,
        address tokenB
    )
        internal
        returns (
            address pair,
            uint32 pairId,
            bool inverted
        )
    {
        inverted = tokenA > tokenB;
        (address token0, address token1) = inverted ? (tokenB, tokenA) : (tokenA, tokenB);
        pair = ITwapFactory(data.factory).getPair(token0, token1);
        require(pair != address(0), 'OS_PAIR_NONEXISTENT');
        pairId = uint32(bytes4(keccak256(abi.encodePacked(pair))));
        if (data.pairs[pairId].pair == address(0)) {
            data.pairs[pairId] = PairInfo(pair, token0, token1);
        }
    }

    function getPairInfo(Data storage data, uint32 pairId)
        external
        view
        returns (
            address pair,
            address token0,
            address token1
        )
    {
        PairInfo storage info = data.pairs[pairId];
        pair = info.pair;
        token0 = info.token0;
        token1 = info.token1;
    }

    function getDepositDisabled(Data storage data, address pair) public view returns (bool) {
        return data.orderDisabled[pair] & DEPOSIT_MASK != 0;
    }

    function getWithdrawDisabled(Data storage data, address pair) public view returns (bool) {
        return data.orderDisabled[pair] & WITHDRAW_MASK != 0;
    }

    function getSellDisabled(Data storage data, address pair) public view returns (bool) {
        return data.orderDisabled[pair] & SELL_MASK != 0;
    }

    function getBuyDisabled(Data storage data, address pair) public view returns (bool) {
        return data.orderDisabled[pair] & BUY_MASK != 0;
    }

    function getDepositOrder(Data storage data, uint256 index) public view returns (DepositOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == DEPOSIT_TYPE, 'OS_INVALID_ORDER_TYPE');
        order.pairId = stored.pairId;
        order.share0 = stored.value0;
        order.share1 = stored.value1;
        order.minSwapPrice = float32ToUint(stored.minSwapPrice);
        order.maxSwapPrice = float32ToUint(stored.maxSwapPrice);
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.swap = stored.swap;
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.validAfterTimestamp = stored.validAfterTimestamp;
        order.priceAccumulator = stored.priceAccumulator;
        order.timestamp = stored.timestamp;
    }

    function getWithdrawOrder(Data storage data, uint256 index) public view returns (WithdrawOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == WITHDRAW_TYPE, 'OS_INVALID_ORDER_TYPE');
        order.pairId = stored.pairId;
        order.liquidity = stored.liquidity;
        order.amount0Min = stored.value0;
        order.amount1Min = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.validAfterTimestamp = stored.validAfterTimestamp;
    }

    function getSellOrder(Data storage data, uint256 index) public view returns (SellOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == SELL_TYPE || stored.orderType == SELL_INVERTED_TYPE, 'OS_INVALID_ORDER_TYPE');
        order.pairId = stored.pairId;
        order.inverse = stored.orderType == SELL_INVERTED_TYPE;
        order.shareIn = stored.value0;
        order.amountOutMin = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.validAfterTimestamp = stored.validAfterTimestamp;
        order.priceAccumulator = stored.priceAccumulator;
        order.timestamp = stored.timestamp;
    }

    function getBuyOrder(Data storage data, uint256 index) public view returns (BuyOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == BUY_TYPE || stored.orderType == BUY_INVERTED_TYPE, 'OS_INVALID_ORDER_TYPE');
        order.pairId = stored.pairId;
        order.inverse = stored.orderType == BUY_INVERTED_TYPE;
        order.shareInMax = stored.value0;
        order.amountOut = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.validAfterTimestamp = stored.validAfterTimestamp;
        order.timestamp = stored.timestamp;
        order.priceAccumulator = stored.priceAccumulator;
    }

    function getFailedOrderType(Data storage data, uint256 orderId)
        external
        view
        returns (OrderType orderType, uint32 validAfterTimestamp)
    {
        require(isRefundFailed(data, orderId), 'OS_NO_POSSIBLE_REFUND');
        (orderType, validAfterTimestamp) = getOrder(data, orderId);
    }

    function getUnwrap(uint8 unwrapAndFailure) private pure returns (bool) {
        return unwrapAndFailure == UNWRAP_FAILED || unwrapAndFailure == UNWRAP_NOT_FAILED;
    }

    function getUnwrapAndFailure(bool unwrap) private pure returns (uint8) {
        return unwrap ? UNWRAP_NOT_FAILED : KEEP_NOT_FAILED;
    }

    function timestampToUint32(uint256 timestamp) private pure returns (uint32 timestamp32) {
        if (timestamp == type(uint256).max) {
            return type(uint32).max;
        }
        timestamp32 = timestamp.toUint32();
    }

    function gasPriceToUint32(uint256 gasPrice) private pure returns (uint32 gasPrice32) {
        require((gasPrice / 1e6) * 1e6 == gasPrice, 'OS_GAS_PRICE_PRECISION');
        gasPrice32 = (gasPrice / 1e6).toUint32();
    }

    function uint32ToGasPrice(uint32 gasPrice32) public pure returns (uint256 gasPrice) {
        gasPrice = uint256(gasPrice32) * 1e6;
    }

    function uintToFloat32(uint256 number) internal pure returns (uint32 float32) {
        // Number is encoded on 4 bytes. 3 bytes for mantissa and 1 for exponent.
        // If the number fits in the mantissa we set the exponent to zero and return.
        if (number < 2 << 24) {
            return uint32(number << 8);
        }
        // We find the exponent by counting the number of trailing zeroes.
        // Simultaneously we remove those zeroes from the number.
        uint32 exponent;
        for (exponent = 0; exponent < 256 - 24; exponent++) {
            // Last bit is one.
            if (number & 1 == 1) {
                break;
            }
            number = number >> 1;
        }
        // The number must fit in the mantissa.
        require(number < 2 << 24, 'OS_OVERFLOW_FLOAT_ENCODE');
        // Set the first three bytes to the number and the fourth to the exponent.
        float32 = uint32(number << 8) | exponent;
    }

    function float32ToUint(uint32 float32) internal pure returns (uint256 number) {
        // Number is encoded on 4 bytes. 3 bytes for mantissa and 1 for exponent.
        // We get the exponent by extracting the last byte.
        uint256 exponent = float32 & 0xFF;
        // Sanity check. Only triggered for values not encoded with uintToFloat32.
        require(exponent <= 256 - 24, 'OS_OVERFLOW_FLOAT_DECODE');
        // We get the mantissa by extracting the first three bytes and removing the fourth.
        uint256 mantissa = (float32 & 0xFFFFFF00) >> 8;
        // We add exponent number zeroes after the mantissa.
        number = mantissa << exponent;
    }

    function setOrderDisabled(
        Data storage data,
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external {
        require(orderType != Orders.OrderType.Empty, 'OS_INVALID_ORDER_TYPE');
        uint8 currentSettings = data.orderDisabled[pair];

        // zeros with 1 bit set at position specified by orderType
        uint8 mask = uint8(1) << uint8(orderType);

        // set/unset a bit accordingly to 'disabled' value
        if (disabled) {
            // OR operation to disable order
            // e.g. for disable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // mask for DEPOSIT  = 00000010
            // the result of OR  = 00010110
            data.orderDisabled[pair] = currentSettings | mask;
        } else {
            // AND operation with a mask negation to enable order
            // e.g. for enable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // 0xff              = 11111111
            // mask for Deposit  = 00000010
            // mask negation     = 11111101
            // the result of AND = 00010100
            data.orderDisabled[pair] = currentSettings & (mask ^ 0xff);
        }

        emit OrderDisabled(pair, orderType, disabled);
    }

    function enqueueDepositOrder(Data storage data, DepositOrder memory depositOrder) internal {
        data.newestOrderId++;
        emit DepositEnqueued(data.newestOrderId, depositOrder.validAfterTimestamp, depositOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            DEPOSIT_TYPE,
            depositOrder.validAfterTimestamp,
            getUnwrapAndFailure(depositOrder.unwrap),
            depositOrder.timestamp,
            depositOrder.gasLimit.toUint32(),
            gasPriceToUint32(depositOrder.gasPrice),
            0, // liquidity
            depositOrder.share0.toUint112(),
            depositOrder.share1.toUint112(),
            depositOrder.pairId,
            depositOrder.to,
            uintToFloat32(depositOrder.minSwapPrice),
            uintToFloat32(depositOrder.maxSwapPrice),
            depositOrder.swap,
            depositOrder.priceAccumulator
        );
    }

    function enqueueWithdrawOrder(Data storage data, WithdrawOrder memory withdrawOrder) internal {
        data.newestOrderId++;
        emit WithdrawEnqueued(data.newestOrderId, withdrawOrder.validAfterTimestamp, withdrawOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            WITHDRAW_TYPE,
            withdrawOrder.validAfterTimestamp,
            getUnwrapAndFailure(withdrawOrder.unwrap),
            0, // timestamp
            withdrawOrder.gasLimit.toUint32(),
            gasPriceToUint32(withdrawOrder.gasPrice),
            withdrawOrder.liquidity.toUint112(),
            withdrawOrder.amount0Min.toUint112(),
            withdrawOrder.amount1Min.toUint112(),
            withdrawOrder.pairId,
            withdrawOrder.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            0 // priceAccumulator
        );
    }

    function enqueueSellOrder(Data storage data, SellOrder memory sellOrder) internal {
        data.newestOrderId++;
        emit SellEnqueued(data.newestOrderId, sellOrder.validAfterTimestamp, sellOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            sellOrder.inverse ? SELL_INVERTED_TYPE : SELL_TYPE,
            sellOrder.validAfterTimestamp,
            getUnwrapAndFailure(sellOrder.unwrap),
            sellOrder.timestamp,
            sellOrder.gasLimit.toUint32(),
            gasPriceToUint32(sellOrder.gasPrice),
            0, // liquidity
            sellOrder.shareIn.toUint112(),
            sellOrder.amountOutMin.toUint112(),
            sellOrder.pairId,
            sellOrder.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            sellOrder.priceAccumulator
        );
    }

    function enqueueBuyOrder(Data storage data, BuyOrder memory buyOrder) internal {
        data.newestOrderId++;
        emit BuyEnqueued(data.newestOrderId, buyOrder.validAfterTimestamp, buyOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            buyOrder.inverse ? BUY_INVERTED_TYPE : BUY_TYPE,
            buyOrder.validAfterTimestamp,
            getUnwrapAndFailure(buyOrder.unwrap),
            buyOrder.timestamp,
            buyOrder.gasLimit.toUint32(),
            gasPriceToUint32(buyOrder.gasPrice),
            0, // liquidity
            buyOrder.shareInMax.toUint112(),
            buyOrder.amountOut.toUint112(),
            buyOrder.pairId,
            buyOrder.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            buyOrder.priceAccumulator
        );
    }

    function isRefundFailed(Data storage data, uint256 index) internal view returns (bool) {
        uint8 unwrapAndFailure = data.orderQueue[index].unwrapAndFailure;
        return unwrapAndFailure == UNWRAP_FAILED || unwrapAndFailure == KEEP_FAILED;
    }

    function markRefundFailed(Data storage data) internal {
        StoredOrder storage stored = data.orderQueue[data.lastProcessedOrderId];
        stored.unwrapAndFailure = stored.unwrapAndFailure == UNWRAP_NOT_FAILED ? UNWRAP_FAILED : KEEP_FAILED;
    }

    function getNextOrder(Data storage data) internal view returns (OrderType orderType, uint256 validAfterTimestamp) {
        return getOrder(data, data.lastProcessedOrderId + 1);
    }

    function dequeueCanceledOrder(Data storage data) external {
        data.lastProcessedOrderId++;
    }

    function dequeueDepositOrder(Data storage data) external returns (DepositOrder memory order) {
        data.lastProcessedOrderId++;
        order = getDepositOrder(data, data.lastProcessedOrderId);
    }

    function dequeueWithdrawOrder(Data storage data) external returns (WithdrawOrder memory order) {
        data.lastProcessedOrderId++;
        order = getWithdrawOrder(data, data.lastProcessedOrderId);
    }

    function dequeueSellOrder(Data storage data) external returns (SellOrder memory order) {
        data.lastProcessedOrderId++;
        order = getSellOrder(data, data.lastProcessedOrderId);
    }

    function dequeueBuyOrder(Data storage data) external returns (BuyOrder memory order) {
        data.lastProcessedOrderId++;
        order = getBuyOrder(data, data.lastProcessedOrderId);
    }

    function forgetOrder(Data storage data, uint256 orderId) internal {
        delete data.orderQueue[orderId];
    }

    function forgetLastProcessedOrder(Data storage data) internal {
        delete data.orderQueue[data.lastProcessedOrderId];
    }

    struct DepositParams {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool wrap;
        bool swap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function deposit(
        Data storage data,
        DepositParams calldata depositParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 token0TransferCost = data.transferGasCosts[depositParams.token0];
        uint256 token1TransferCost = data.transferGasCosts[depositParams.token1];
        require(token0TransferCost != 0 && token1TransferCost != 0, 'OS_TOKEN_TRANSFER_GAS_COST_UNSET');
        checkOrderParams(
            data,
            depositParams.to,
            depositParams.gasLimit,
            depositParams.submitDeadline,
            ORDER_BASE_COST.add(token0TransferCost).add(token1TransferCost)
        );
        require(depositParams.amount0 != 0 || depositParams.amount1 != 0, 'OS_NO_AMOUNT');
        (address pairAddress, uint32 pairId, bool inverted) = getPair(data, depositParams.token0, depositParams.token1);
        require(!getDepositDisabled(data, pairAddress), 'OS_DEPOSIT_DISABLED');
        {
            // scope for value, avoids stack too deep errors
            uint256 value = msg.value;

            // allocate gas refund
            if (depositParams.wrap) {
                if (depositParams.token0 == tokenShares.weth) {
                    value = value.sub(depositParams.amount0, 'OS_NOT_ENOUGH_FUNDS');
                } else if (depositParams.token1 == tokenShares.weth) {
                    value = value.sub(depositParams.amount1, 'OS_NOT_ENOUGH_FUNDS');
                }
            }
            allocateGasRefund(data, value, depositParams.gasLimit);
        }

        uint256 shares0 = tokenShares.amountToShares(depositParams.token0, depositParams.amount0, depositParams.wrap);
        uint256 shares1 = tokenShares.amountToShares(depositParams.token1, depositParams.amount1, depositParams.wrap);

        (uint256 priceAccumulator, uint32 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();
        enqueueDepositOrder(
            data,
            DepositOrder(
                pairId,
                inverted ? shares1 : shares0,
                inverted ? shares0 : shares1,
                depositParams.minSwapPrice,
                depositParams.maxSwapPrice,
                depositParams.wrap,
                depositParams.swap,
                depositParams.to,
                data.gasPrice,
                depositParams.gasLimit,
                timestamp + data.delay, // validAfterTimestamp
                priceAccumulator,
                timestamp
            )
        );
    }

    struct WithdrawParams {
        address token0;
        address token1;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function withdraw(Data storage data, WithdrawParams calldata withdrawParams) external {
        (address pair, uint32 pairId, bool inverted) = getPair(data, withdrawParams.token0, withdrawParams.token1);
        require(!getWithdrawDisabled(data, pair), 'OS_WITHDRAW_DISABLED');
        checkOrderParams(
            data,
            withdrawParams.to,
            withdrawParams.gasLimit,
            withdrawParams.submitDeadline,
            ORDER_BASE_COST.add(PAIR_TRANSFER_COST)
        );
        require(withdrawParams.liquidity != 0, 'OS_NO_LIQUIDITY');

        allocateGasRefund(data, msg.value, withdrawParams.gasLimit);
        pair.safeTransferFrom(msg.sender, address(this), withdrawParams.liquidity);
        enqueueWithdrawOrder(
            data,
            WithdrawOrder(
                pairId,
                withdrawParams.liquidity,
                inverted ? withdrawParams.amount1Min : withdrawParams.amount0Min,
                inverted ? withdrawParams.amount0Min : withdrawParams.amount1Min,
                withdrawParams.unwrap,
                withdrawParams.to,
                data.gasPrice,
                withdrawParams.gasLimit,
                timestampToUint32(block.timestamp) + data.delay
            )
        );
    }

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function sell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = data.transferGasCosts[sellParams.tokenIn];
        require(tokenTransferCost != 0, 'OS_TOKEN_TRANSFER_GAS_COST_UNSET');
        checkOrderParams(
            data,
            sellParams.to,
            sellParams.gasLimit,
            sellParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );
        require(sellParams.amountIn != 0, 'OS_NO_AMOUNT_IN');
        (address pairAddress, uint32 pairId, bool inverted) = getPair(data, sellParams.tokenIn, sellParams.tokenOut);
        require(!getSellDisabled(data, pairAddress), 'OS_SELL_DISABLED');
        uint256 value = msg.value;

        // allocate gas refund
        if (sellParams.tokenIn == tokenShares.weth && sellParams.wrapUnwrap) {
            value = value.sub(sellParams.amountIn, 'OS_NOT_ENOUGH_FUNDS');
        }
        allocateGasRefund(data, value, sellParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(sellParams.tokenIn, sellParams.amountIn, sellParams.wrapUnwrap);

        (uint256 priceAccumulator, uint32 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();
        enqueueSellOrder(
            data,
            SellOrder(
                pairId,
                inverted,
                shares,
                sellParams.amountOutMin,
                sellParams.wrapUnwrap,
                sellParams.to,
                data.gasPrice,
                sellParams.gasLimit,
                timestamp + data.delay,
                priceAccumulator,
                timestamp
            )
        );
    }

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function buy(
        Data storage data,
        BuyParams calldata buyParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = data.transferGasCosts[buyParams.tokenIn];
        require(tokenTransferCost != 0, 'OS_TOKEN_TRANSFER_GAS_COST_UNSET');
        checkOrderParams(
            data,
            buyParams.to,
            buyParams.gasLimit,
            buyParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );
        require(buyParams.amountOut != 0, 'OS_NO_AMOUNT_OUT');
        (address pairAddress, uint32 pairId, bool inverted) = getPair(data, buyParams.tokenIn, buyParams.tokenOut);
        require(!getBuyDisabled(data, pairAddress), 'OS_BUY_DISABLED');
        uint256 value = msg.value;

        // allocate gas refund
        if (buyParams.tokenIn == tokenShares.weth && buyParams.wrapUnwrap) {
            value = value.sub(buyParams.amountInMax, 'OS_NOT_ENOUGH_FUNDS');
        }
        allocateGasRefund(data, value, buyParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(buyParams.tokenIn, buyParams.amountInMax, buyParams.wrapUnwrap);

        (uint256 priceAccumulator, uint32 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();
        enqueueBuyOrder(
            data,
            BuyOrder(
                pairId,
                inverted,
                shares,
                buyParams.amountOut,
                buyParams.wrapUnwrap,
                buyParams.to,
                data.gasPrice,
                buyParams.gasLimit,
                timestamp + data.delay,
                priceAccumulator,
                timestamp
            )
        );
    }

    function checkOrderParams(
        Data storage data,
        address to,
        uint256 gasLimit,
        uint32 submitDeadline,
        uint256 minGasLimit
    ) private view {
        require(submitDeadline >= block.timestamp, 'OS_EXPIRED');
        require(gasLimit <= data.maxGasLimit, 'OS_GAS_LIMIT_TOO_HIGH');
        require(gasLimit >= minGasLimit, 'OS_GAS_LIMIT_TOO_LOW');
        require(to != address(0), 'OS_NO_ADDRESS');
    }

    function allocateGasRefund(
        Data storage data,
        uint256 value,
        uint256 gasLimit
    ) private returns (uint256 futureFee) {
        futureFee = data.gasPrice.mul(gasLimit);
        require(value >= futureFee, 'OS_NOT_ENOUGH_FUNDS');
        if (value > futureFee) {
            msg.sender.transfer(value.sub(futureFee));
        }
    }

    function updateGasPrice(Data storage data, uint256 gasUsed) external {
        uint256 scale = Math.min(gasUsed, data.maxGasPriceImpact);
        uint256 updated = data.gasPrice.mul(data.gasPriceInertia.sub(scale)).add(tx.gasprice.mul(scale)).div(
            data.gasPriceInertia
        );
        // we lower the precision for gas savings in order queue
        data.gasPrice = updated - (updated % 1e6);
    }

    function setMaxGasLimit(Data storage data, uint256 _maxGasLimit) external {
        require(_maxGasLimit <= 10000000, 'OS_MAX_GAS_LIMIT_TOO_HIGH');
        data.maxGasLimit = _maxGasLimit;
        emit MaxGasLimitSet(_maxGasLimit);
    }

    function setGasPriceInertia(Data storage data, uint256 _gasPriceInertia) external {
        require(_gasPriceInertia >= 1, 'OS_INVALID_INERTIA');
        data.gasPriceInertia = _gasPriceInertia;
        emit GasPriceInertiaSet(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(Data storage data, uint256 _maxGasPriceImpact) external {
        require(_maxGasPriceImpact <= data.gasPriceInertia, 'OS_INVALID_MAX_GAS_PRICE_IMPACT');
        data.maxGasPriceImpact = _maxGasPriceImpact;
        emit MaxGasPriceImpactSet(_maxGasPriceImpact);
    }

    function setTransferGasCost(
        Data storage data,
        address token,
        uint256 gasCost
    ) external {
        data.transferGasCosts[token] = gasCost;
        emit TransferGasCostSet(token, gasCost);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import '../interfaces/IERC20.sol';
import '../interfaces/IWETH.sol';
import './SafeMath.sol';
import './TransferHelper.sol';

library TokenShares {
    using SafeMath for uint256;
    using TransferHelper for address;

    event UnwrapFailed(address to, uint256 amount);

    struct Data {
        mapping(address => uint256) totalShares;
        address weth;
    }

    function setWeth(Data storage data, address _weth) internal {
        data.weth = _weth;
    }

    function sharesToAmount(
        Data storage data,
        address token,
        uint256 share
    ) external returns (uint256) {
        if (share == 0) {
            return 0;
        }
        if (token == data.weth) {
            return share;
        }
        uint256 totalTokenShares = data.totalShares[token];
        require(totalTokenShares >= share, 'TS_INSUFFICIENT_BALANCE');
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = balance.mul(share).div(totalTokenShares);
        data.totalShares[token] = totalTokenShares.sub(share);
        return value;
    }

    function amountToShares(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == data.weth) {
            if (wrap) {
                require(msg.value >= amount, 'TS_INSUFFICIENT_AMOUNT');
                IWETH(token).deposit{ value: amount }();
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            uint256 totalTokenShares = data.totalShares[token];
            require(balanceBefore > 0 || totalTokenShares == 0, 'TS_INVALID_SHARES');
            if (totalTokenShares == 0) {
                totalTokenShares = balanceBefore;
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            require(balanceAfter > balanceBefore, 'TS_INVALID_TRANSFER');
            if (balanceBefore > 0) {
                uint256 newShares = totalTokenShares.mul(balanceAfter).div(balanceBefore);
                data.totalShares[token] = newShares;
                return newShares - totalTokenShares;
            } else {
                data.totalShares[token] = balanceAfter;
                return balanceAfter;
            }
        }
    }

    function onUnwrapFailed(
        Data storage data,
        address to,
        uint256 amount
    ) external {
        emit UnwrapFailed(to, amount);
        IWETH(data.weth).deposit{ value: amount }();
        TransferHelper.safeTransfer(data.weth, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma abicoder v2;

import '../interfaces/ITwapPair.sol';
import '../interfaces/IWETH.sol';
import './Orders.sol';

library WithdrawHelper {
    using SafeMath for uint256;

    function _transferToken(
        uint256 balanceBefore,
        address token,
        address to
    ) internal {
        uint256 tokenAmount = IERC20(token).balanceOf(address(this)).sub(balanceBefore);
        TransferHelper.safeTransfer(token, to, tokenAmount);
    }

    function _unwrapWeth(
        uint256 ethAmount,
        address weth,
        address to
    ) internal returns (bool) {
        IWETH(weth).withdraw(ethAmount);
        (bool success, ) = to.call{ value: ethAmount, gas: Orders.ETHER_TRANSFER_CALL_COST }('');
        return success;
    }

    function withdrawAndUnwrap(
        address token0,
        address token1,
        address pair,
        address weth,
        address to
    )
        external
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        bool isToken0Weth = token0 == weth;
        address otherToken = isToken0Weth ? token1 : token0;

        uint256 balanceBefore = IERC20(otherToken).balanceOf(address(this));
        (uint256 amount0, uint256 amount1) = ITwapPair(pair).burn(address(this));
        _transferToken(balanceBefore, otherToken, to);

        bool success = _unwrapWeth(isToken0Weth ? amount0 : amount1, weth, to);

        return (success, isToken0Weth ? amount0 : amount1, amount0, amount1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/WithdrawHelper.sol';

contract WithdrawHelperTest {
    constructor() {}

    function transferToken(
        uint256 balanceBefore,
        address token,
        address to
    ) public {
        return WithdrawHelper._transferToken(balanceBefore, token, to);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;
pragma abicoder v2;

import '../libraries/Orders.sol';

contract OrdersTest {
    using Orders for Orders.Data;
    Orders.Data orders;

    event DepositEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event WithdrawEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event SellEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);
    event BuyEnqueued(uint256 indexed orderId, uint32 validAfterTimestamp, uint256 gasPrice);

    constructor() {
        orders.delay = 1 weeks;
    }

    function delay() public view returns (uint32) {
        return orders.delay;
    }

    function lastProcessedOrderId() public view returns (uint256) {
        return orders.lastProcessedOrderId;
    }

    function newestOrderId() public view returns (uint256) {
        return orders.newestOrderId;
    }

    function getOrder(uint256 orderId) public view returns (Orders.OrderType orderType, uint32 validAfterTimestamp) {
        return orders.getOrder(orderId);
    }

    function getDepositOrder(uint256 orderId) public view returns (Orders.DepositOrder memory order) {
        return orders.getDepositOrder(orderId);
    }

    function getWithdrawOrder(uint256 orderId) public view returns (Orders.WithdrawOrder memory order) {
        return orders.getWithdrawOrder(orderId);
    }

    function getSellOrder(uint256 orderId) public view returns (Orders.SellOrder memory order) {
        return orders.getSellOrder(orderId);
    }

    function getBuyOrder(uint256 orderId) public view returns (Orders.BuyOrder memory order) {
        return orders.getBuyOrder(orderId);
    }

    function _enqueueDepositOrder(
        uint32 pairId,
        uint256 share0,
        uint256 share1,
        uint256 minSwapPrice,
        uint256 maxSwapPrice,
        bool unwrap,
        bool swap,
        address to,
        uint256 gasPrice,
        uint256 gasLimit,
        uint32 validAfterTimestamp,
        uint256 priceAccumulator
    ) public {
        orders.enqueueDepositOrder(
            Orders.DepositOrder(
                pairId,
                share0,
                share1,
                minSwapPrice,
                maxSwapPrice,
                unwrap,
                swap,
                to,
                gasPrice,
                gasLimit,
                validAfterTimestamp,
                priceAccumulator,
                0
            )
        );
    }

    function _enqueueWithdrawOrder(
        uint32 pairId,
        uint256 amount,
        uint256 amountAMin,
        uint256 amountBMin,
        bool unwrap,
        address to,
        uint256 gasPrice,
        uint256 gasLimit,
        uint32 validAfterTimestamp
    ) public {
        orders.enqueueWithdrawOrder(
            Orders.WithdrawOrder(
                pairId,
                amount,
                amountAMin,
                amountBMin,
                unwrap,
                to,
                gasPrice,
                gasLimit,
                validAfterTimestamp
            )
        );
    }

    function _enqueueSellOrder(
        uint32 pairId,
        bool inverse,
        uint256 shareIn,
        uint256 amountOutMin,
        bool unwrap,
        address to,
        uint256 gasPrice,
        uint256 gasLimit,
        uint32 validAfterTimestamp,
        uint256 priceAccumulator,
        uint32 timestamp
    ) public {
        orders.enqueueSellOrder(
            Orders.SellOrder(
                pairId,
                inverse,
                shareIn,
                amountOutMin,
                unwrap,
                to,
                gasPrice,
                gasLimit,
                validAfterTimestamp,
                priceAccumulator,
                timestamp
            )
        );
    }

    function _enqueueBuyOrder(
        uint32 pairId,
        bool inverse,
        uint256 shareInMax,
        uint256 amountOut,
        bool unwrap,
        address to,
        uint256 gasPrice,
        uint256 gasLimit,
        uint32 validAfterTimestamp,
        uint256 priceAccumulator,
        uint32 timestamp
    ) public {
        orders.enqueueBuyOrder(
            Orders.BuyOrder(
                pairId,
                inverse,
                shareInMax,
                amountOut,
                unwrap,
                to,
                gasPrice,
                gasLimit,
                validAfterTimestamp,
                priceAccumulator,
                timestamp
            )
        );
    }

    function _dequeueDepositOrder() public returns (Orders.DepositOrder memory order) {
        return orders.dequeueDepositOrder();
    }

    function _dequeueWithdrawOrder() public returns (Orders.WithdrawOrder memory order) {
        return orders.dequeueWithdrawOrder();
    }

    function _dequeueSellOrder() public returns (Orders.SellOrder memory order) {
        return orders.dequeueSellOrder();
    }

    function _dequeueBuyOrder() public returns (Orders.BuyOrder memory order) {
        return orders.dequeueBuyOrder();
    }

    function uintToFloat32(uint256 number) public pure returns (uint32 float32) {
        return Orders.uintToFloat32(number);
    }

    function float32ToUint(uint32 float32) public pure returns (uint256 number) {
        return Orders.float32ToUint(float32);
    }

    function forgetLastProcessedOrder() public {
        return orders.forgetLastProcessedOrder();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/TokenShares.sol';

contract TokenSharesTest {
    using TokenShares for TokenShares.Data;
    TokenShares.Data tokenShares;

    event Result(uint256 value);

    constructor(address weth) {
        tokenShares.setWeth(weth);
    }

    function totalShares(address token) public view returns (uint256) {
        return tokenShares.totalShares[token];
    }

    function sharesToAmount(address token, uint256 shares) public {
        uint256 result = tokenShares.sharesToAmount(token, shares);
        emit Result(result);
    }

    function amountToShares(
        address token,
        uint256 amount,
        bool wrap
    ) public payable {
        uint256 result = tokenShares.amountToShares(token, amount, wrap);
        emit Result(result);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/TransferHelper.sol';

// test helper for transfers
contract TransferHelperTest {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) external {
        TransferHelper.safeApprove(token, to, value);
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) external {
        TransferHelper.safeTransfer(token, to, value);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) external {
        TransferHelper.safeTransferFrom(token, from, to, value);
    }

    function safeTransferETH(address to, uint256 value) external {
        TransferHelper.safeTransferETH(to, value);
    }
}

// can revert on failure and returns true if successful
contract TransferHelperTestFakeERC20Compliant {
    bool public success;
    bool public shouldRevert;

    function setup(bool success_, bool shouldRevert_) public {
        success = success_;
        shouldRevert = shouldRevert_;
    }

    function transfer(address, uint256) public view returns (bool) {
        require(!shouldRevert, 'REVERT');
        return success;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public view returns (bool) {
        require(!shouldRevert, 'REVERT');
        return success;
    }

    function approve(address, uint256) public view returns (bool) {
        require(!shouldRevert, 'REVERT');
        return success;
    }
}

// only reverts on failure, no return value
contract TransferHelperTestFakeERC20Noncompliant {
    bool public shouldRevert;

    function setup(bool shouldRevert_) public {
        shouldRevert = shouldRevert_;
    }

    function transfer(address, uint256) public view {
        require(!shouldRevert);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public view {
        require(!shouldRevert);
    }

    function approve(address, uint256) public view {
        require(!shouldRevert);
    }
}

contract TransferHelperTestFakeFallback {
    bool public shouldRevert;

    function setup(bool shouldRevert_) public {
        shouldRevert = shouldRevert_;
    }

    receive() external payable {
        require(!shouldRevert);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../interfaces/IERC20.sol';
import '../libraries/TransferHelper.sol';

contract TokenGasTest {
    using TransferHelper for address;
    event GasUsed(uint256 value);

    uint256 public x = 0;

    function bstx() public {}

    function set(uint256 value) public {
        x = value;
    }

    function setNonZero() public {
        uint256 start = gasleft();
        set(1337);
        uint256 used = start - gasleft();
        emit GasUsed(used);
    }

    function setZero() public {
        uint256 start = gasleft();
        set(0);
        uint256 used = start - gasleft();
        emit GasUsed(used);
    }

    function transferOut(
        address token,
        address to,
        uint256 value
    ) public {
        uint256 start = gasleft();
        token.safeTransfer(to, value);
        uint256 used = start - gasleft();
        emit GasUsed(used);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import './interfaces/ITwapFactory.sol';
import './TwapPair.sol';

contract TwapFactory is ITwapFactory {
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    address public override owner;

    constructor() {
        owner = msg.sender;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external override returns (address pair) {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        require(tokenA != tokenB, 'TF_IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TF_ADDRESS_ZERO');
        require(getPair[token0][token1] == address(0), 'TF_PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(TwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ITwapPair(pair).initialize(token0, token1, oracle, trader);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        _getPair(tokenA, tokenB).setMintFee(fee);
    }

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        _getPair(tokenA, tokenB).setBurnFee(fee);
    }

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        _getPair(tokenA, tokenB).setSwapFee(fee);
    }

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external override {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        _getPair(tokenA, tokenB).setOracle(oracle);
    }

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external override {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        _getPair(tokenA, tokenB).setTrader(trader);
    }

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external override {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        _getPair(tokenA, tokenB).collect(to);
    }

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external override {
        require(msg.sender == owner, 'TF_FORBIDDEN');
        ITwapPair pair = _getPair(tokenA, tokenB);
        pair.transfer(address(pair), amount);
        pair.burn(to);
    }

    function _getPair(address tokenA, address tokenB) internal view returns (ITwapPair pair) {
        pair = ITwapPair(getPair[tokenA][tokenB]);
        require(address(pair) != address(0), 'TF_PAIR_DOES_NOT_EXIST');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;
pragma abicoder v2;

import '../interfaces/ITwapDelay.sol';
import '../interfaces/IERC20.sol';

contract OrderIdTest {
    event OrderId(uint256 orderId);

    address delay;

    constructor(address _delay) {
        delay = _delay;
    }

    function deposit(Orders.DepositParams calldata depositParams) public payable {
        uint256 orderId = ITwapDelay(delay).deposit{ value: msg.value }(depositParams);
        emit OrderId(orderId);
    }

    function withdraw(Orders.WithdrawParams calldata withdrawParams) public payable {
        uint256 orderId = ITwapDelay(delay).withdraw{ value: msg.value }(withdrawParams);
        emit OrderId(orderId);
    }

    function sell(Orders.SellParams calldata sellParams) public payable {
        uint256 orderId = ITwapDelay(delay).sell{ value: msg.value }(sellParams);
        emit OrderId(orderId);
    }

    function buy(Orders.BuyParams calldata buyParams) public payable {
        uint256 orderId = ITwapDelay(delay).buy{ value: msg.value }(buyParams);
        emit OrderId(orderId);
    }

    function approve(
        address token,
        address beneficiary,
        uint256 value
    ) public {
        IERC20(token).approve(beneficiary, value);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../interfaces/ITwapDelay.sol';

contract EtherHater {
    function callExecute(ITwapDelay delay) external {
        delay.execute(1);
    }

    receive() external payable {
        revert('EtherHater: NOPE_SORRY');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;
pragma abicoder v2;

import '../TwapDelay.sol';

contract DelayTest is TwapDelay {
    using Orders for Orders.Data;

    constructor(
        address _factory,
        address _weth,
        address _bot
    ) TwapDelay(_factory, _weth, _bot) {}

    function setGasPrice(uint256 _gasPrice) public {
        orders.gasPrice = _gasPrice;
    }

    function testUpdateGasPrice(uint256 gasUsed) public {
        orders.updateGasPrice(gasUsed);
    }

    function testPerformRefund(
        Orders.OrderType orderType,
        uint256 validAfterTimestamp,
        uint256 orderId,
        bool shouldRefundEth
    ) public {
        performRefund(orderType, validAfterTimestamp, orderId, shouldRefundEth);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;
pragma abicoder v2;

import '../libraries/AddLiquidity.sol';

contract AddLiquidityTest {
    constructor() {}

    function addLiquidity(
        address pair,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) public view returns (uint256 amount0, uint256 amount1) {
        return AddLiquidity.addLiquidity(pair, amount0Desired, amount1Desired);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/SafeMath.sol';

contract FailingERC20 {
    using SafeMath for uint256;

    string public constant name = 'Failing Test Token';
    string public constant symbol = 'FTT';

    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    bool public revertBalanceOf = false;
    bool public wasteTransferGas = false;
    uint32 public revertAfter = uint32(-1);
    uint32 public totalTransfers = 0;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 _totalSupply) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _mint(msg.sender, _totalSupply);
    }

    function _wasteGas(uint256 iterations) internal pure returns (uint256) {
        uint256 result = 2;
        for (uint256 i = 0; i < iterations; i++) {
            result += result**3;
        }
        return result;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(address(0), to, value);
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
        require(totalTransfers < revertAfter, 'FA_TRANSFER_OOPS');
        totalTransfers++;
        if (wasteTransferGas) {
            _wasteGas(100000);
        }
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(!revertBalanceOf, 'FA_BALANCE_OF_OOPS');
        return balances[owner];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function setRevertBalanceOf(bool value) external {
        revertBalanceOf = value;
    }

    function setWasteTransferGas(bool value) external {
        wasteTransferGas = value;
    }

    function setRevertAfter(uint32 value) external {
        revertAfter = value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/SafeMath.sol';

contract DeflatingERC20 {
    using SafeMath for uint256;

    string public constant name = 'Deflating Test Token';
    string public constant symbol = 'DTT';

    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 _totalSupply) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _mint(msg.sender, _totalSupply);
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
        uint256 burnAmount = value / 100;
        _burn(from, burnAmount);
        uint256 transferAmount = value.sub(burnAmount);
        balanceOf[from] = balanceOf[from].sub(transferAmount);
        balanceOf[to] = balanceOf[to].add(transferAmount);
        emit Transfer(from, to, transferAmount);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/Reserves.sol';

contract ReservesTest is Reserves {
    address token0;
    address token1;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function testAddFees(uint256 fee0, uint256 fee1) public {
        addFees(fee0, fee1);
    }

    function testSetReserves() public {
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        setReserves(balance0, balance1);
    }

    function testSyncReserves() public {
        syncReserves(token0, token1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../TwapLPToken.sol';

contract ERC20 is TwapLPToken {
    constructor(uint256 _totalSupply) {
        _mint(msg.sender, _totalSupply);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/AbstractERC20.sol';

contract CustomERC20 is AbstractERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(msg.sender, _totalSupply);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import '../libraries/AbstractERC20.sol';

contract AdjustableERC20 is AbstractERC20 {
    constructor(uint256 _totalSupply) {
        name = 'AdjustableERC20';
        symbol = 'ADJ';
        decimals = 18;
        _mint(msg.sender, _totalSupply);
    }

    function setBalance(address account, uint256 value) public {
        balanceOf[account] = value;
    }
}