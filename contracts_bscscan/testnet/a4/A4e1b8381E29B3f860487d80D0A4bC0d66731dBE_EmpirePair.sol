// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "../interfaces/IEmpireERC20.sol";

import "../libraries/common/EmpireMath.sol";

contract EmpireERC20 is IEmpireERC20 {
    using EmpireMath for uint256;

    string public constant override name = "Empire LP";
    string public constant override symbol = "EMP-LP";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 private immutable CACHED_CHAIN_ID;
    bytes32 private immutable CACHED_DOMAIN_SEPARATOR;
    bytes32 private constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    mapping(address => uint256) public override nonces;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        CACHED_CHAIN_ID = chainId;
        CACHED_DOMAIN_SEPARATOR = _computeSeparator(chainId);
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

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function _computeSeparator(uint256 chainId)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN,
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
    }

    function _getDigest(bytes32 payload) internal view returns (bytes32) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        bytes32 domainSeparator =
            chainId != CACHED_CHAIN_ID
                ? _computeSeparator(chainId)
                : CACHED_DOMAIN_SEPARATOR;

        return
            keccak256(abi.encodePacked("\x19\x01", domainSeparator, payload));
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
        require(deadline >= block.timestamp, "Empire: EXPIRED");
        bytes32 digest =
            _getDigest(
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Empire: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IEmpirePair.sol";
import "../interfaces/IEmpireFactory.sol";
import "../interfaces/IEmpireCallee.sol";

import "../libraries/dex/UQ112x112.sol";

import "./EmpireERC20.sol";

contract EmpirePair is IEmpirePair, EmpireERC20 {
    using UQ112x112 for uint224;

    uint256 private constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant TRANSFER_SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFER_FROM_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    address public immutable override factory;
    address public override token0;
    address public override token1;

    uint112 private override reserve0; // uses single storage slot, accessible via getReserves
    uint112 private override reserve1; // uses single storage slot, accessible via getReserves
    uint32 private override blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;
    uint256 public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 public override liquidityLocked; // By default, liquidity is not locked (timestamp is 0)
    address public override sweepableToken; // By default, no token is sweepable
    uint256 public override sweptAmount; // Tracks how many tokens were swept based on the floor price
    PairType public empirePairType; // Tracks pair type
    uint256 public empireLockTime; // Tracks lock time

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "Empire: LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        override
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        _safeCall(token, abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        _safeCall(
            token,
            abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value)
        );
    }

    function _safeCall(address token, bytes memory payload) private {
        (bool success, bytes memory data) = token.call(payload);
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Empire: TRANSFER_FAILED"
        );
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event Swept(uint256 amount);
    event Unswept(uint256 amount);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        PairType pairType,
        uint256 unlockTime
    ) external override {
        require(msg.sender == factory, "Empire: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;

        if (pairType != PairType.Common) {
            liquidityLocked = unlockTime;
            empirePairType = pairType;

            if (pairType == PairType.SweepableToken0) {
                sweepableToken = _token0;
            } else if (pairType == PairType.SweepableToken1) {
                sweepableToken = _token1;
            }
        }

        empireLockTime = unlockTime;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= uint112(-1) && balance1 <= uint112(-1),
            "Empire: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
                uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address feeTo = IEmpireFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = uint256(_reserve0).mul(_reserve1).sqrt();
                uint256 rootKLast = _kLast.sqrt();
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to)
        external
        override
        lock
        returns (uint256 liquidity)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = _balanceOfSelf(token0);
        uint256 balance1 = _balanceOfSelf(token1);
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = amount0.mul(amount1).sqrt().sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = (amount0.mul(_totalSupply) / _reserve0).min(
                amount1.mul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "Empire: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to)
        external
        override
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        require(block.timestamp >= liquidityLocked, "Empire: LIQUIDITY_LOCKED");
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = _balanceOfSelf(_token0);
        uint256 balance1 = _balanceOfSelf(_token1);
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "Empire: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = _balanceOfSelf(_token0);
        balance1 = _balanceOfSelf(_token1);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "Empire: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "Empire: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Empire: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                IEmpireCallee(to).empireCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = _balanceOfSelf(_token0);
            balance1 = _balanceOfSelf(_token1);
        }
        uint256 amount0In =
            balance0 > _reserve0 - amount0Out
                ? balance0 - (_reserve0 - amount0Out)
                : 0;
        uint256 amount1In =
            balance1 > _reserve1 - amount1Out
                ? balance1 - (_reserve1 - amount1Out)
                : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "Empire: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint256(_reserve0).mul(_reserve1).mul(1000**2),
                "Empire: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, _balanceOfSelf(_token0).sub(reserve0));
        _safeTransfer(_token1, to, _balanceOfSelf(_token1).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(
            _balanceOfSelf(token0),
            _balanceOfSelf(token1),
            reserve0,
            reserve1
        );
    }

    // wrapper ensuring sweeps are accounted for
    function _balanceOfSelf(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == sweepableToken) {
            balance = sweptAmount;
        }
        return balance.add(IERC20(token).balanceOf(address(this)));
    }

    // allow sweeping if enabled
    function sweep(uint256 amount, bytes calldata data) external override lock {
        address _token0 = token0;
        address _token1 = token1;
        uint256 _reserveSwept;
        uint256 _reserveSweeper;
        if (msg.sender == _token0) {
            require(sweepableToken == _token1, "Empire: INCORRECT_CALLER");
            _reserveSwept = reserve1;
            _reserveSweeper = reserve0;
        } else {
            require(
                msg.sender == _token1 && sweepableToken == _token0,
                "Empire: INCORRECT_CALLER"
            );
            _reserveSwept = reserve0;
            _reserveSweeper = reserve1;
        }

        // Calculate necessary sweepable token amount for pool to contain full token supply
        uint256 amountIn = IERC20(msg.sender).totalSupply() - _reserveSweeper;
        uint256 numerator = amountIn.mul(_reserveSwept);
        uint256 denominator = _reserveSweeper.mul(1000).add(amountIn);
        uint256 amountOut = numerator / denominator;
        uint256 maxSweepable = _reserveSwept - amountOut;

        uint256 _sweptAmount = sweptAmount.add(amount);

        require(_sweptAmount <= maxSweepable, "Empire: INCORRECT_SWEEP_AMOUNT");

        sweptAmount = _sweptAmount;

        _safeTransfer(sweepableToken, msg.sender, amount);

        IEmpireCallee(msg.sender).empireSweepCall(amount, data);

        emit Swept(amount);
    }

    function unsweep(uint256 amount) external override lock {
        address _token0 = token0;
        address _token1 = token1;
        if (msg.sender == _token0) {
            require(sweepableToken == _token1, "Empire: INCORRECT_CALLER");
        } else {
            require(
                msg.sender == _token1 && sweepableToken == _token0,
                "Empire: INCORRECT_CALLER"
            );
        }

        _safeTransferFrom(sweepableToken, msg.sender, address(this), amount);
        sweptAmount = sweptAmount.sub(amount);

        emit Unswept(amount);
    }

    function getMaxSweepable() external view override returns (uint256) {
        address _token0 = token0;
        address _token1 = token1;
        address _sweeper;
        uint256 _reserveIn;
        uint256 _reserveOut;
        if (sweepableToken == _token0) {
            _sweeper = _token1;
            _reserveIn = reserve1;
            _reserveOut = reserve0;
        } else {
            require(sweepableToken == token1, "Empire: NON_SWEEPABLE_POOL");
            _sweeper = _token0;
            _reserveIn = reserve0;
            _reserveOut = reserve1;
        }

        uint256 amountIn = IERC20(_sweeper).totalSupply() - _reserveIn;
        uint256 amountOut = getAmountOut(amountIn, _reserveIn, _reserveOut);
        return _reserveOut - amountOut;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) return 0;

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

interface IEmpireCallee {
    function empireCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function empireSweepCall(uint256 amountSwept, bytes calldata data) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

interface IEmpireERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

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

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "./IEmpirePair.sol";

interface IEmpireFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function createPair(
        address tokenA,
        address tokenB,
        PairType pairType,
        uint256 unlockTime
    ) external returns (address pair);

    function createEmpirePair(
        address tokenA,
        address tokenB,
        PairType pairType,
        uint256 unlockTime
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

enum PairType {Common, LiquidityLocked, SweepableToken0, SweepableToken1}

interface IEmpirePair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

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

    function sweptAmount() external view returns (uint256);

    function sweepableToken() external view returns (address);

    function liquidityLocked() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        PairType,
        uint256
    ) external;

    function sweep(uint256 amount, bytes calldata data) external;

    function unsweep(uint256 amount) external;

    function getMaxSweepable() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library EmpireMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
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

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 private constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

