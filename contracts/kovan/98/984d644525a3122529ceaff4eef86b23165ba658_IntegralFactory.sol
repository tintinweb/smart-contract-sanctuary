// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IIntegralFactory {
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

import 'IERC20.sol';

interface IIntegralERC20 is IERC20 {
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

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IReserves {
    event Sync(uint112 reserve0, uint112 reserve1);
    event Fees(uint256 fee0, uint256 fee1);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 lastTimestamp
        );

    function getReferences()
        external
        view
        returns (
            uint112 reference0,
            uint112 reference1,
            uint32 epoch
        );

    function getFees() external view returns (uint256 fee0, uint256 fee1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralERC20.sol';
import 'IReserves.sol';

interface IIntegralPair is IIntegralERC20, IReserves {
    event Mint(address indexed sender, address indexed to);
    event Burn(address indexed sender, address indexed to);
    event Swap(address indexed sender, address indexed to);
    event SetMintFee(uint256 fee);
    event SetBurnFee(uint256 fee);
    event SetSwapFee(uint256 fee);
    event SetOracle(address account);
    event SetTrader(address trader);
    event SetToken0AbsoluteLimit(uint256 limit);
    event SetToken1AbsoluteLimit(uint256 limit);
    event SetToken0RelativeLimit(uint256 limit);
    event SetToken1RelativeLimit(uint256 limit);
    event SetPriceDeviationLimit(uint256 limit);

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

    function token0AbsoluteLimit() external view returns (uint256);

    function setToken0AbsoluteLimit(uint256 limit) external;

    function token1AbsoluteLimit() external view returns (uint256);

    function setToken1AbsoluteLimit(uint256 limit) external;

    function token0RelativeLimit() external view returns (uint256);

    function setToken0RelativeLimit(uint256 limit) external;

    function token1RelativeLimit() external view returns (uint256);

    function setToken1RelativeLimit(uint256 limit) external;

    function priceDeviationLimit() external view returns (uint256);

    function setPriceDeviationLimit(uint256 limit) external;

    function collect(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external;

    function syncWithOracle() external;

    function fullSync() external;

    function getSpotPrice() external view returns (uint256 spotPrice);

    function getSwapAmount0In(uint256 amount1Out) external view returns (uint256 swapAmount0In);

    function getSwapAmount1In(uint256 amount0Out) external view returns (uint256 swapAmount1In);

    function getSwapAmount0Out(uint256 amount1In) external view returns (uint256 swapAmount0Out);

    function getSwapAmount1Out(uint256 amount0In) external view returns (uint256 swapAmount1Out);

    function getDepositAmount0In(uint256 amount0) external view returns (uint256 depositAmount0In);

    function getDepositAmount1In(uint256 amount1) external view returns (uint256 depositAmount1In);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IReserves.sol';
import 'IERC20.sol';
import 'SafeMath.sol';

contract Reserves is IReserves {
    using SafeMath for uint256;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private lastTimestamp;

    uint112 private reference0;
    uint112 private reference1;
    uint32 private lastEpoch;

    uint256 private fee0;
    uint256 private fee1;

    function getReserves()
        public
        view
        override
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (reserve0, reserve1, lastTimestamp);
    }

    function setReserves(
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _lastTimestamp
    ) private {
        require(_reserve0 != 0 && _reserve1 != 0, 'RS_ZERO');
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        lastTimestamp = _lastTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function getReferences()
        public
        view
        override
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (reference0, reference1, lastEpoch);
    }

    function setReferencesToReserves(uint32 _lastEpoch) internal {
        reference0 = reserve0;
        reference1 = reserve1;
        lastEpoch = _lastEpoch;
    }

    function updateReserves(uint256 balance0, uint256 balance1) internal {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'RS_OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        setReserves(uint112(balance0), uint112(balance1), blockTimestamp);
    }

    function adjustReserves(uint256 balance0, uint256 balance1) internal {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        if (_reserve0 != balance0 || _reserve1 != balance1) {
            updateReserves(balance0, balance1);
            updateReferences(
                uint256(reference0).add(reserve0).sub(_reserve0),
                uint256(reference1).add(reserve1).sub(_reserve1)
            );
        }
    }

    function syncReserves(address token0, address token1) internal {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();

        uint256 oldBalance0 = fee0.add(_reserve0);
        uint256 oldBalance1 = fee1.add(_reserve1);
        fee0 = oldBalance0 != 0 ? fee0.mul(balance0).div(oldBalance0) : fee0;
        fee1 = oldBalance1 != 0 ? fee1.mul(balance1).div(oldBalance1) : fee1;

        uint256 newReserve0 = balance0.sub(fee0);
        uint256 newReserve1 = balance1.sub(fee1);
        if (_reserve0 != newReserve0 || _reserve1 != newReserve1) {
            updateReserves(newReserve0, newReserve1);
            updateReferences(
                uint256(reference0).add(reserve0).sub(_reserve0),
                uint256(reference1).add(reserve1).sub(_reserve1)
            );
        }
    }

    function updateReferences(uint256 _reference0, uint256 _reference1) private {
        require(_reference0 <= uint112(-1) && _reference1 <= uint112(-1), 'RS_OVERFLOW');
        reference0 = uint112(_reference0);
        reference1 = uint112(_reference1);
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

import 'IIntegralERC20.sol';
import 'SafeMath.sol';

abstract contract AbstractERC20 is IIntegralERC20 {
    using SafeMath for uint256;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32
        public constant
        override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    function _init(string memory _name) internal {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
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
        require(currentAllowance >= subtractedValue, 'IA_CANNOT_DECREASE');
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
        require(deadline >= block.timestamp, 'IA_EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'IA_INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'AbstractERC20.sol';

contract IntegralERC20 is AbstractERC20 {
    string public constant override name = 'Integral LP';
    string public constant override symbol = 'ITGR-LP';
    uint8 public constant override decimals = 18;

    constructor() {
        _init(name);
    }

    /**
     * @dev This function should be called on the forked chain to prevent
     * replay attacks
     */
    function updateDomainSeparator() external {
        _init(name);
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

interface IIntegralOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);
    event PriceUpdateIntervalSet(uint32 interval);
    event ParametersSet(uint32 epoch, int256[] bidExponents, int256[] bidQs, int256[] askExponents, int256[] askQs);

    function owner() external view returns (address);

    function setOwner(address) external;

    function epoch() external view returns (uint32);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function getParameters()
        external
        view
        returns (
            int256[] memory bidExponents,
            int256[] memory bidQs,
            int256[] memory askExponents,
            int256[] memory askQs
        );

    function setParameters(
        int256[] calldata bidExponents,
        int256[] calldata bidQs,
        int256[] calldata askExponents,
        int256[] calldata askQs
    ) external;

    function price() external view returns (int256);

    function priceUpdateInterval() external view returns (uint32);

    function updatePrice() external returns (uint32 _epoch);

    function setPriceUpdateInterval(uint32 interval) external;

    function price0CumulativeLast() external view returns (uint256);

    function blockTimestampLast() external view returns (uint32);

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore
    ) external view returns (uint256 yAfter);

    function tradeY(
        uint256 yAfter,
        uint256 xBefore,
        uint256 yBefore
    ) external view returns (uint256 xAfter);

    function getSpotPrice(uint256 xCurrent, uint256 xBefore) external view returns (uint256 spotPrice);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'SafeMath.sol';

library Normalizer {
    using SafeMath for uint256;

    function normalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        } else if (decimals > 18) {
            return amount.div(10**(decimals - 18));
        } else {
            return amount.mul(10**(18 - decimals));
        }
    }

    function denormalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        } else if (decimals > 18) {
            return amount.mul(10**(decimals - 18));
        } else {
            return amount.div(10**(18 - decimals));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralPair.sol';
import 'Reserves.sol';
import 'IntegralERC20.sol';
import 'Math.sol';
import 'IERC20.sol';
import 'IIntegralFactory.sol';
import 'IIntegralOracle.sol';
import 'Normalizer.sol';

contract IntegralPair is Reserves, IntegralERC20, IIntegralPair {
    using SafeMath for uint256;
    using Normalizer for uint256;

    uint256 private constant PRECISION = 10**18;

    uint256 public override mintFee = 0;
    uint256 public override burnFee = 0;
    uint256 public override swapFee = 0;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;
    uint256 private constant TRADE_MOE = 100000001 * 10**10; // Margin Of Error

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override factory;
    address public override token0;
    address public override token1;
    address public override oracle;
    address public override trader;

    uint256 private lastPrice;

    uint256 public override token0AbsoluteLimit = uint256(-1);
    uint256 public override token1AbsoluteLimit = uint256(-1);
    uint256 public override token0RelativeLimit = PRECISION; // 100%
    uint256 public override token1RelativeLimit = PRECISION; // 100%
    uint256 public override priceDeviationLimit = uint256(-1);

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'IP_LOCKED');
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
        require(msg.sender == factory, 'IP_FORBIDDEN');
        mintFee = fee;
        emit SetMintFee(mintFee);
    }

    function setBurnFee(uint256 fee) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        burnFee = fee;
        emit SetBurnFee(burnFee);
    }

    function setSwapFee(uint256 fee) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        swapFee = fee;
        emit SetSwapFee(swapFee);
    }

    function setOracle(address _oracle) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        require(_oracle != address(0), 'IP_ADDRESS_ZERO');
        require(isContract(_oracle), 'IP_ORACLE_MUST_BE_CONTRACT');
        oracle = _oracle;
        setReferencesToReserves(0);
        emit SetOracle(oracle);
    }

    function setTrader(address _trader) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        trader = _trader;
        emit SetTrader(trader);
    }

    function setToken0AbsoluteLimit(uint256 _token0AbsoluteLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        token0AbsoluteLimit = _token0AbsoluteLimit;
        emit SetToken0AbsoluteLimit(token0AbsoluteLimit);
    }

    function setToken1AbsoluteLimit(uint256 _token1AbsoluteLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        token1AbsoluteLimit = _token1AbsoluteLimit;
        emit SetToken1AbsoluteLimit(token1AbsoluteLimit);
    }

    function setToken0RelativeLimit(uint256 _token0RelativeLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        token0RelativeLimit = _token0RelativeLimit;
        emit SetToken0RelativeLimit(token0RelativeLimit);
    }

    function setToken1RelativeLimit(uint256 _token1RelativeLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        token1RelativeLimit = _token1RelativeLimit;
        emit SetToken1RelativeLimit(token1RelativeLimit);
    }

    function setPriceDeviationLimit(uint256 _priceDeviationLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        priceDeviationLimit = _priceDeviationLimit;
        emit SetPriceDeviationLimit(priceDeviationLimit);
    }

    function collect(address to) external override lock {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        require(to != address(0), 'IP_ADDRESS_ZERO');
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
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'IP_TRANSFER_FAILED');
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
        require(msg.sender == factory, 'IP_FORBIDDEN');
        require(_oracle != address(0), 'IP_ADDRESS_ZERO');
        require(isContract(_oracle), 'IP_ORACLE_MUST_BE_CONTRACT');
        require(isContract(_token0) && isContract(_token1), 'IP_TOKEN_MUST_BE_CONTRACT');
        token0 = _token0;
        token1 = _token1;
        oracle = _oracle;
        trader = _trader;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint256 liquidity) {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'IP_ADDRESS_ZERO');
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        uint256 amount0 = balance0.sub(reserve0);
        uint256 amount1 = balance1.sub(reserve1);

        _syncWithOracle();

        uint256 _totalSupply = totalSupply; // gas savings
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / reserve0, amount1.mul(_totalSupply) / reserve1);
        }

        require(liquidity > 0, 'IP_INSUFFICIENT_LIQUIDITY_MINTED');
        uint256 fee = liquidity.mul(mintFee).div(PRECISION);
        uint256 effectiveLiquidity = liquidity.sub(fee);
        _mint(to, effectiveLiquidity);
        _mint(factory, fee);

        adjustReserves(balance0, balance1);

        emit Mint(msg.sender, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint256 amount0, uint256 amount1) {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'IP_ADDRESS_ZERO');
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        uint256 liquidity = balanceOf[address(this)];
        uint256 _totalSupply = totalSupply; // gas savings

        _syncWithOracle();

        uint256 fee = 0;
        if (msg.sender != factory) {
            fee = liquidity.mul(burnFee).div(PRECISION);
            _transfer(address(this), factory, fee);
        }
        uint256 effectiveLiquidity = liquidity.sub(fee);
        _burn(address(this), effectiveLiquidity);

        amount0 = effectiveLiquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = effectiveLiquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'IP_INSUFFICIENT_LIQUIDITY_BURNED');

        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        (balance0, balance1) = getBalances(token0, token1);
        adjustReserves(balance0, balance1);

        emit Burn(msg.sender, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external override lock {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'IP_ADDRESS_ZERO');
        require(amount0Out > 0 || amount1Out > 0, 'IP_INSUFFICIENT_OUTPUT_AMOUNT');
        require(amount0Out == 0 || amount1Out == 0, 'IP_MULTIPLE_OUTPUTS_SPECIFIED');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'IP_INSUFFICIENT_LIQUIDITY');

        _syncWithOracle();

        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'IP_INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        }
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'IP_INSUFFICIENT_INPUT_AMOUNT');

        if (amount0Out > 0) {
            // trading token1 for token0
            (uint112 reference0, uint112 reference1, ) = getReferences();

            uint256 fee1 = amount1In.mul(swapFee).div(PRECISION);
            uint256 balance0After = IIntegralOracle(oracle).tradeY(balance1.sub(fee1), reference0, reference1);
            require(balance0 >= balance0After, 'IP_INVALID_SWAP');
            _checkToken0Limits(balance0After, reference0);
            uint256 fee0 = balance0.sub(balance0After);
            addFees(fee0, fee1);
            updateReserves(balance0.sub(fee0), balance1.sub(fee1));
        } else {
            // trading token0 for token1
            (uint112 reference0, uint112 reference1, ) = getReferences();

            uint256 fee0 = amount0In.mul(swapFee).div(PRECISION);
            uint256 balance1After = IIntegralOracle(oracle).tradeX(balance0.sub(fee0), reference0, reference1);
            require(balance1 >= balance1After, 'IP_INVALID_SWAP');
            _checkToken1Limits(balance1After, reference1);
            uint256 fee1 = balance1.sub(balance1After);
            addFees(fee0, fee1);
            updateReserves(balance0.sub(fee0), balance1.sub(fee1));
        }

        _checkPriceDeviationLimit();
        emit Swap(msg.sender, to);
    }

    function _checkPriceDeviationLimit() private view {
        uint256 currentPrice = getSpotPrice();

        if (lastPrice > 0) {
            uint256 difference = lastPrice > currentPrice ? lastPrice.sub(currentPrice) : currentPrice.sub(lastPrice);

            require(difference.mul(PRECISION).div(lastPrice) <= priceDeviationLimit, 'IP_P_LIMIT_EXCEEDED');
        }
    }

    function _checkToken0Limits(uint256 balance0After, uint112 reference0) private view {
        if (balance0After < reference0) {
            uint256 difference = uint256(reference0).sub(balance0After);
            require(difference <= token0AbsoluteLimit, 'IP_A0_LIQUIDITY_LIMIT_EXCEEDED');
            require(difference.mul(PRECISION).div(reference0) <= token0RelativeLimit, 'IP_R0_LIQUIDITY_LIMIT_EXCEEDED');
        }
    }

    function _checkToken1Limits(uint256 balance1After, uint112 reference1) private view {
        if (balance1After < reference1) {
            uint256 difference = uint256(reference1).sub(balance1After);
            require(difference <= token1AbsoluteLimit, 'IP_A1_LIQUIDITY_LIMIT_EXCEEDED');
            require(difference.mul(PRECISION).div(reference1) <= token1RelativeLimit, 'IP_R1_LIQUIDITY_LIMIT_EXCEEDED');
        }
    }

    function sync() public override lock {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
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

    function syncWithOracle() external override {
        _syncWithOracle();
    }

    function fullSync() external override {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        _sync();
        _syncWithOracle();
    }

    function _syncWithOracle() internal {
        uint32 epoch = IIntegralOracle(oracle).updatePrice();
        (, , uint32 lastEpoch) = getReferences();
        if (epoch != lastEpoch) {
            setReferencesToReserves(epoch);
            lastPrice = getSpotPrice();
        }
    }

    function getSpotPrice() public view override returns (uint256 spotPrice) {
        (uint112 reserve0, , ) = getReserves();
        (uint112 reference0, , ) = getReferences();
        return IIntegralOracle(oracle).getSpotPrice(reserve0, reference0);
    }

    function getSwapAmount0In(uint256 amount1Out) public view override returns (uint256 swapAmount0In) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint112 reference0, uint112 reference1, ) = getReferences();
        uint256 balance1After = uint256(reserve1).sub(amount1Out);
        uint256 balance0After = IIntegralOracle(oracle).tradeY(balance1After, reference0, reference1);
        return balance0After.sub(uint256(reserve0)).mul(TRADE_MOE).div(PRECISION.sub(swapFee));
    }

    function getSwapAmount1In(uint256 amount0Out) public view override returns (uint256 swapAmount1In) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint112 reference0, uint112 reference1, ) = getReferences();
        uint256 balance0After = uint256(reserve0).sub(amount0Out);
        uint256 balance1After = IIntegralOracle(oracle).tradeX(balance0After, reference0, reference1);
        return balance1After.sub(uint256(reserve1)).mul(TRADE_MOE).div(PRECISION.sub(swapFee));
    }

    function getSwapAmount0Out(uint256 amount1In) public view override returns (uint256 swapAmount0Out) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint112 reference0, uint112 reference1, ) = getReferences();
        uint256 fee = amount1In.mul(swapFee).div(PRECISION);
        uint256 balance0After = IIntegralOracle(oracle).tradeY(
            uint256(reserve1).add(amount1In).sub(fee),
            reference0,
            reference1
        );
        return uint256(reserve0).sub(balance0After);
    }

    function getSwapAmount1Out(uint256 amount0In) public view override returns (uint256 swapAmount1Out) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint112 reference0, uint112 reference1, ) = getReferences();
        uint256 fee = amount0In.mul(swapFee).div(PRECISION);
        uint256 balance1After = IIntegralOracle(oracle).tradeX(
            uint256(reserve0).add(amount0In).sub(fee),
            reference0,
            reference1
        );
        return uint256(reserve1).sub(balance1After);
    }

    function getDepositAmount0In(uint256 amount0) external view override returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        uint8 decimals0 = IIntegralOracle(oracle).xDecimals();
        uint8 decimals1 = IIntegralOracle(oracle).yDecimals();

        uint256 P = getSpotPrice();
        uint256 a = amount0.normalize(decimals0);
        uint256 A = uint256(reserve0).normalize(decimals0);
        uint256 B = uint256(reserve1).normalize(decimals1);

        // ratio after swap = ratio after second mint
        // (A + x) / (B - x * P) = (A + a) / B
        // x = a * B / (P * (a + A) + B)
        uint256 numeratorTimes1e18 = a.mul(B);
        uint256 denominator = P.mul(a.add(A)).div(1e18).add(B);
        uint256 x = numeratorTimes1e18.div(denominator);
        // Don't swap when numbers are too large. This should actually never happen
        if (x.mul(P).div(1e18) >= B || x >= a) {
            return 0;
        }
        return x.denormalize(decimals0);
    }

    function getDepositAmount1In(uint256 amount1) external view override returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        uint8 decimals0 = IIntegralOracle(oracle).xDecimals();
        uint8 decimals1 = IIntegralOracle(oracle).yDecimals();

        uint256 P = getSpotPrice();
        uint256 b = amount1.normalize(decimals1);
        uint256 A = uint256(reserve0).normalize(decimals0);
        uint256 B = uint256(reserve1).normalize(decimals1);

        // ratio after swap = ratio after second mint
        // (A - x / P) / (B + x) = A / (B + b)
        // x = A * b * P / (A * P + b + B)
        uint256 numeratorTimes1e18 = A.mul(b).div(1e18).mul(P);
        uint256 denominator = A.mul(P).div(1e18).add(b).add(B);
        uint256 x = numeratorTimes1e18.div(denominator);
        // Don't swap when numbers are too large. This should actually never happen
        if (x.mul(1e18).div(P) >= A || x >= b) {
            return 0;
        }
        return x.denormalize(decimals1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralFactory.sol';
import 'IntegralPair.sol';

contract IntegralFactory is IIntegralFactory {
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
        require(msg.sender == owner, 'IF_FORBIDDEN');
        require(tokenA != tokenB, 'IF_IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'IF_ADDRESS_ZERO');
        require(getPair[token0][token1] == address(0), 'IF_PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(IntegralPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IIntegralPair(pair).initialize(token0, token1, oracle, trader);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setMintFee(fee);
    }

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setBurnFee(fee);
    }

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setSwapFee(fee);
    }

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setOracle(oracle);
    }

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setTrader(trader);
    }

    function setToken0AbsoluteLimit(
        address tokenA,
        address tokenB,
        uint256 token0AbsoluteLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setToken0AbsoluteLimit(token0AbsoluteLimit);
    }

    function setToken1AbsoluteLimit(
        address tokenA,
        address tokenB,
        uint256 token1AbsoluteLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setToken1AbsoluteLimit(token1AbsoluteLimit);
    }

    function setToken0RelativeLimit(
        address tokenA,
        address tokenB,
        uint256 token0RelativeLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setToken0RelativeLimit(token0RelativeLimit);
    }

    function setToken1RelativeLimit(
        address tokenA,
        address tokenB,
        uint256 token1RelativeLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setToken1RelativeLimit(token1RelativeLimit);
    }

    function setPriceDeviationLimit(
        address tokenA,
        address tokenB,
        uint256 priceLimit
    ) external {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).setPriceDeviationLimit(priceLimit);
    }

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        _getPair(tokenA, tokenB).collect(to);
    }

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external override {
        require(msg.sender == owner, 'IF_FORBIDDEN');
        IIntegralPair pair = _getPair(tokenA, tokenB);
        pair.transfer(address(pair), amount);
        pair.burn(to);
    }

    function _getPair(address tokenA, address tokenB) internal view returns (IIntegralPair pair) {
        pair = IIntegralPair(getPair[tokenA][tokenB]);
        require(address(pair) != address(0), 'IF_PAIR_DOES_NOT_EXIST');
    }
}

