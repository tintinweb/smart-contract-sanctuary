// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "./VaderPool.sol";

import "../../shared/ProtocolConstants.sol";

import "../../interfaces/shared/IERC20Extended.sol";
import "../../interfaces/dex/pool/IVaderPoolFactory.sol";

// TBD
contract VaderPoolFactory is IVaderPoolFactory, ProtocolConstants, Ownable {
    /* ========== STATE VARIABLES ========== */

    // Denotes whether the queue system is active on new pairs, disabled by default
    bool public queueActive;

    // Native Asset of the system
    address public override nativeAsset;

    // Token A -> Token B -> Pool mapping
    mapping(address => mapping(address => IVaderPool)) public override getPool;

    // A list of all pools
    IVaderPool[] public allPools;

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    // NOTE: Between deployment & initialization may be corrupted but chance small
    function createPool(address tokenA, address tokenB)
        external
        override
        returns (IVaderPool pool)
    {
        (address token0, address token1) = tokenA == nativeAsset
            ? (tokenA, tokenB)
            : tokenB == nativeAsset
            ? (tokenB, tokenA)
            : (_ZERO_ADDRESS, _ZERO_ADDRESS);

        require(
            token0 != token1,
            "VaderPoolFactory::createPool: Identical Tokens"
        );

        require(
            token1 != _ZERO_ADDRESS,
            "VaderPoolFactory::createPool: Inexistent Token"
        );

        require(
            getPool[token0][token1] == IVaderPool(_ZERO_ADDRESS),
            "VaderPoolFactory::createPool: Pair Exists"
        ); // single check is sufficient

        pool = new VaderPool(
            queueActive,
            IERC20Extended(tokenA),
            IERC20Extended(tokenB)
        );
        getPool[token0][token1] = pool;
        getPool[token1][token0] = pool; // populate mapping in the reverse direction
        allPools.push(pool);
        emit PoolCreated(token0, token1, pool, allPools.length);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function initialize(address _nativeAsset, address _dao) external onlyOwner {
        require(
            _nativeAsset != _ZERO_ADDRESS && _dao != _ZERO_ADDRESS,
            "VaderPoolFactory::initialize: Incorrect Arguments"
        );

        nativeAsset = _nativeAsset;
        transferOwnership(_dao);
    }

    function toggleQueue(address token0, address token1) external onlyDAO {
        getPool[token0][token1].toggleQueue();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Ensures only the DAO is able to invoke a particular function by validating that
     * the owner is the msg.sender, equivalent to the DAO address, and that the native asset
     * has been set
     */
    function _onlyDAO() private view {
        require(
            nativeAsset != _ZERO_ADDRESS && owner() == _msgSender(),
            "BasePool::_onlyDAO: Insufficient Privileges"
        );
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if invoked by anyone else other than the DAO
     */
    modifier onlyDAO() {
        _onlyDAO();
        _;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

abstract contract ProtocolConstants {
    /* ========== GENERAL ========== */

    // The zero address, utility
    address internal constant _ZERO_ADDRESS = address(0);

    // One year, utility
    uint256 internal constant _ONE_YEAR = 365 days;

    // Basis Points
    uint256 internal constant _MAX_BASIS_POINTS = 100_00;

    /* ========== VADER TOKEN ========== */

    // Max VADER supply
    uint256 internal constant _INITIAL_VADER_SUPPLY = 2_500_000_000 * 1 ether;

    // Allocation for VETH holders
    uint256 internal constant _VETH_ALLOCATION = 1_000_000_000 * 1 ether;

    // Team allocation vested over {VESTING_DURATION} years
    uint256 internal constant _TEAM_ALLOCATION = 250_000_000 * 1 ether;

    // Ecosystem growth fund unlocked for partnerships & USDV provision
    uint256 internal constant _ECOSYSTEM_GROWTH = 250_000_000 * 1 ether;

    // Emission Era
    uint256 internal constant _EMISSION_ERA = 24 hours;

    // Initial Emission Curve, 5
    uint256 internal constant _INITIAL_EMISSION_CURVE = 5;

    // Fee Basis Points
    uint256 internal constant _MAX_FEE_BASIS_POINTS = 1_00;

    /* ========== VESTING ========== */

    // Vesting Duration
    uint256 internal constant _VESTING_DURATION = 2 * _ONE_YEAR;

    /* ========== CONVERTER ========== */

    // Vader -> Vether Conversion Rate (1000:1)
    uint256 internal constant _VADER_VETHER_CONVERSION_RATE = 1000;

    // Burn Address
    address internal constant _BURN =
        0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD;

    /* ========== SWAP QUEUE ========== */

    // A minimum of 10 swaps will be executed per block
    uint256 internal constant _MIN_SWAPS_EXECUTED = 10;

    // Expressed in basis points (50%)
    uint256 internal constant _DEFAULT_SWAPS_EXECUTED = 50_00;

    // The queue size of each block is 100 units
    uint256 internal constant _QUEUE_SIZE = 100;

    /* ========== GAS QUEUE ========== */

    // Address of Chainlink Fast Gas Price Oracle
    address internal constant _FAST_GAS_ORACLE =
        0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

    /* ========== VADER RESERVE ========== */

    // Minimum delay between grants
    uint256 internal constant _GRANT_DELAY = 30 days;

    // Maximum grant size divisor
    uint256 internal constant _MAX_GRANT_BASIS_POINTS = 10_00;
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

interface IAggregator {
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "./IVaderPool.sol";

interface IVaderPoolFactory {
    /* ========== STRUCTS ========== */

    /* ========== FUNCTIONS ========== */

    function createPool(address tokenA, address tokenB)
        external
        returns (IVaderPool);

    function getPool(address tokenA, address tokenB)
        external
        view
        returns (IVaderPool);

    function nativeAsset() external view returns (address);

    /* ========== EVENTS ========== */

    event PoolCreated(
        address token0,
        address token1,
        IVaderPool pool,
        uint256 totalPools
    );
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IBasePool.sol";

interface IVaderPool is IBasePool, IERC721 {
    /* ========== STRUCTS ========== */
    /* ========== FUNCTIONS ========== */

    function burn(uint256 id, address to)
        external
        returns (
            uint256 amountNative,
            uint256 amountForeign,
            uint256 coveredLoss
        );

    function toggleQueue() external;

    /* ========== EVENTS ========== */

    event QueueActive(bool activated);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

interface IBasePool {
    /* ========== STRUCTS ========== */

    struct Position {
        uint256 creation;
        uint256 liquidity;
        uint256 originalNative;
        uint256 originalForeign;
    }

    /* ========== FUNCTIONS ========== */

    function swap(
        uint256 nativeAmountIn,
        uint256 foreignAmountIn,
        address to
    ) external returns (uint256);

    function swap(
        uint256 nativeAmountIn,
        uint256 foreignAmountIn,
        address to,
        bytes calldata
    ) external returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves() external view returns (
            uint112 reserveNative,
            uint112 reserveForeign,
            uint32 blockTimestampLast
        );

    /* ========== EVENTS ========== */

    event Mint(
        address indexed sender,
        address indexed to,
        uint256 amount0,
        uint256 amount1
    ); // Adjustment -> new argument to which didnt exist
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
    event Sync(uint256 reserve0, uint256 reserve1); // Adjustment -> 112 to 256
    event PositionOpened(address indexed sender, uint256 id, uint256 liquidity);
    event PositionClosed(
        address indexed sender,
        uint256 id,
        uint256 liquidity,
        uint256 loss
    );
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

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

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "../../shared/ProtocolConstants.sol";

import "../../interfaces/external/chainlink/IAggregator.sol";

contract GasThrottle is ProtocolConstants {
    modifier validateGas() {
        // TODO: Uncomment prior to launch
        // require(
        //     block.basefee <= tx.gasprice &&
        //         tx.gasprice <=
        //         uint256(IAggregator(_FAST_GAS_ORACLE).latestAnswer()),
        //     "GasThrottle::validateGas: Gas Exceeds Thresholds"
        // );
        _;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "./BasePool.sol";

import "../../interfaces/dex/pool/IVaderPool.sol";

// TBD
contract VaderPool is IVaderPool, BasePool {
    /* ========== STATE VARIABLES ========== */

    // Denotes whether the queue system is active
    bool public queueActive;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        bool _queueActive,
        IERC20Extended _nativeAsset,
        IERC20Extended _foreignAsset
    ) BasePool(_nativeAsset, _foreignAsset) {
        queueActive = _queueActive;
    }

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    // NOTE: IL is only covered via router!
    function burn(uint256 id, address to)
        external
        override
        returns (
            uint256 amountNative,
            uint256 amountForeign,
            uint256 coveredLoss
        )
    {
        (amountNative, amountForeign) = _burn(id, to);

        Position storage position = positions[id];

        uint256 creation = position.creation;
        uint256 originalNative = position.originalNative;
        uint256 originalForeign = position.originalForeign;

        delete positions[id];

        // NOTE: Validate it behaves as expected for non-18 decimal tokens
        uint256 loss = VaderMath.calculateLoss(
            originalNative,
            originalForeign,
            amountNative,
            amountForeign
        );

        // TODO: Original Implementation Applied 100 Days
        coveredLoss =
            (loss * _min(block.timestamp - creation, _ONE_YEAR)) /
            _ONE_YEAR;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // TODO: Investigate Necessity
    function toggleQueue() external override onlyOwner {
        bool _queueActive = !queueActive;
        queueActive = _queueActive;
        emit QueueActive(_queueActive);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Ensures only the DAO is able to invoke a particular function by validating that
     * the owner is the msg.sender, equivalent to the DAO address
     */
    function _onlyDAO() private view {
        require(
            owner() == _msgSender(),
            "BasePool::_onlyDAO: Insufficient Privileges"
        );
    }

    /**
     * @dev Calculates the minimum of the two values
     */
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if invoked by anyone else other than the DAO
     */
    modifier onlyDAO() {
        _onlyDAO();
        _;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../math/VaderMath.sol";
// import "../queue/SwapQueue.sol";
import "../utils/GasThrottle.sol";

import "../../external/libraries/UQ112x112.sol";

import "../../interfaces/dex/pool/IBasePool.sol";
import "../../interfaces/shared/IERC20Extended.sol";

contract BasePool is IBasePool, GasThrottle, ERC721, Ownable, ReentrancyGuard {
    /* ========== LIBRARIES ========== */

    // Used for safe token transfers
    using SafeERC20 for IERC20;

    // Used by Uniswap-like TWAP mechanism
    using UQ112x112 for uint224;

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable nativeAsset;
    IERC20 public immutable foreignAsset;
    uint256 public priceNativeCumulativeLast;
    uint256 public priceForeignCumulativeLast;

    mapping(uint256 => Position) public positions;
    uint256 public positionId;
    uint256 public totalSupply;

    string private _name;

    uint112 private _reserveNative; // uses single storage slot, accessible via getReserves
    uint112 private _reserveForeign; // uses single storage slot, accessible via getReserves
    uint32 private _blockTimestampLast; // uses single storage slot, accessible via getReserves

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20Extended _nativeAsset, IERC20Extended _foreignAsset)
        ERC721("Vader LP", "VLP")
    {
        nativeAsset = IERC20(_nativeAsset);
        foreignAsset = IERC20(_foreignAsset);

        string memory calculatedName = string(
            abi.encodePacked("Vader USDV /", _foreignAsset.symbol(), " LP")
        );
        _name = calculatedName;
    }

    /* ========== VIEWS ========== */

    function getReserves()
        public
        view
        returns (
            uint112 reserveNative,
            uint112 reserveForeign,
            uint32 blockTimestampLast
        )
    {
        reserveNative = _reserveNative;
        reserveForeign = _reserveForeign;
        blockTimestampLast = _blockTimestampLast;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(address to)
        external
        override
        nonReentrant
        returns (uint256 liquidity)
    {
        (uint112 reserveNative, uint112 reserveForeign, ) = getReserves(); // gas savings
        uint256 balanceNative = nativeAsset.balanceOf(address(this));
        uint256 balanceForeign = foreignAsset.balanceOf(address(this));
        uint256 nativeDeposit = balanceNative - reserveNative;
        uint256 foreignDeposit = balanceForeign - reserveForeign;

        uint256 totalLiquidityUnits = totalSupply;
        if (totalLiquidityUnits == 0)
            liquidity = nativeDeposit; // TODO: Contact ThorChain on proper approach
        else
            liquidity = VaderMath.calculateLiquidityUnits(
                nativeDeposit,
                reserveNative,
                foreignDeposit,
                reserveForeign,
                totalLiquidityUnits
            );

        require(
            liquidity > 0,
            "BasePool::mint: Insufficient Liquidity Provided"
        );

        uint256 id = positionId++;

        totalSupply += liquidity;
        _mint(to, id);

        positions[id] = Position(
            block.timestamp,
            liquidity,
            nativeDeposit,
            foreignDeposit
        );

        _update(balanceNative, balanceForeign, reserveNative, reserveForeign);

        emit Mint(msg.sender, to, nativeDeposit, foreignDeposit);
        emit PositionOpened(msg.sender, id, liquidity);
    }

    function _burn(uint256 id, address to)
        internal
        nonReentrant
        returns (uint256 amountNative, uint256 amountForeign)
    {
        require(
            ownerOf(id) == address(this),
            "BasePool::burn: Incorrect Ownership"
        );

        (uint112 reserveNative, uint112 reserveForeign, ) = getReserves(); // gas savings
        IERC20 _nativeAsset = nativeAsset; // gas savings
        IERC20 _foreignAsset = foreignAsset; // gas savings
        uint256 nativeBalance = IERC20(_nativeAsset).balanceOf(address(this));
        uint256 foreignBalance = IERC20(_foreignAsset).balanceOf(address(this));

        uint256 liquidity = positions[id].liquidity;

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amountNative = (liquidity * nativeBalance) / _totalSupply; // using balances ensures pro-rata distribution
        amountForeign = (liquidity * foreignBalance) / _totalSupply; // using balances ensures pro-rata distribution

        require(
            amountNative > 0 && amountForeign > 0,
            "BasePool::burn: Insufficient Liquidity Burned"
        );

        totalSupply -= liquidity;
        _burn(id);

        _nativeAsset.safeTransfer(to, amountNative);
        _foreignAsset.safeTransfer(to, amountForeign);

        nativeBalance = _nativeAsset.balanceOf(address(this));
        foreignBalance = _foreignAsset.balanceOf(address(this));

        _update(nativeBalance, foreignBalance, reserveNative, reserveForeign);

        emit Burn(msg.sender, amountNative, amountForeign, to);
    }

    function swap(
        uint256 nativeAmountIn,
        uint256 foreignAmountIn,
        address to,
        bytes calldata
    ) external override returns (uint256) {
        return swap(nativeAmountIn, foreignAmountIn, to);
    }

    function swap(
        uint256 nativeAmountIn,
        uint256 foreignAmountIn,
        address to
    ) public override nonReentrant validateGas returns (uint256) {
        require(
            (nativeAmountIn > 0 && foreignAmountIn == 0) ||
                (nativeAmountIn == 0 && foreignAmountIn > 0),
            "BasePool::swap: Only One-Sided Swaps Supported"
        );
        (uint112 nativeReserve, uint112 foreignReserve, ) = getReserves(); // gas savings

        uint256 nativeBalance;
        uint256 foreignBalance;
        uint256 nativeAmountOut;
        uint256 foreignAmountOut;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            IERC20 _nativeAsset = nativeAsset;
            IERC20 _foreignAsset = foreignAsset;
            nativeBalance = _nativeAsset.balanceOf(address(this));
            foreignBalance = _foreignAsset.balanceOf(address(this));

            require(
                to != address(_nativeAsset) && to != address(_foreignAsset),
                "BasePool::swap: Invalid Receiver"
            );

            if (foreignAmountIn > 0) {
                require(
                    foreignAmountIn <= foreignBalance - foreignReserve,
                    "BasePool::swap: Insufficient Tokens Provided"
                );
                require(
                    foreignAmountIn <= foreignReserve,
                    "BasePool::swap: Unfavourable Trade"
                );

                nativeAmountOut = VaderMath.calculateSwap(
                    foreignAmountIn,
                    foreignReserve,
                    nativeReserve
                );

                require(
                    nativeAmountOut > 0 && nativeAmountOut <= nativeReserve,
                    "BasePool::swap: Swap Impossible"
                );

                _nativeAsset.safeTransfer(to, nativeAmountOut); // optimistically transfer tokens
            } else {
                require(
                    nativeAmountIn <= nativeBalance - nativeReserve,
                    "BasePool::swap: Insufficient Tokens Provided"
                );
                require(
                    nativeAmountIn <= nativeReserve,
                    "BasePool::swap: Unfavourable Trade"
                );

                foreignAmountOut = VaderMath.calculateSwap(
                    nativeAmountIn,
                    nativeReserve,
                    foreignReserve
                );

                require(
                    foreignAmountOut > 0 && foreignAmountOut <= foreignReserve,
                    "BasePool::swap: Swap Impossible"
                );

                _foreignAsset.safeTransfer(to, foreignAmountOut); // optimistically transfer tokens
            }

            nativeBalance = _nativeAsset.balanceOf(address(this));
            foreignBalance = _foreignAsset.balanceOf(address(this));
        }

        _update(nativeBalance, foreignBalance, nativeReserve, foreignReserve);

        emit Swap(
            msg.sender,
            nativeAmountIn,
            foreignAmountIn,
            nativeAmountOut,
            foreignAmountOut,
            to
        );

        return nativeAmountOut > 0 ? nativeAmountOut : foreignAmountOut;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ========== INTERNAL FUNCTIONS ========== */

    function _update(
        uint256 balanceNative,
        uint256 balanceForeign,
        uint112 reserveNative,
        uint112 reserveForeign
    ) internal {
        require(
            balanceNative <= type(uint112).max &&
                balanceForeign <= type(uint112).max,
            "BasePool::_update: Balance Overflow"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - _blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && reserveNative != 0 && reserveForeign != 0) {
            // * never overflows, and + overflow is desired
            priceNativeCumulativeLast +=
                uint256(UQ112x112.encode(reserveForeign).uqdiv(reserveNative)) *
                timeElapsed;
            priceForeignCumulativeLast +=
                uint256(UQ112x112.encode(reserveNative).uqdiv(reserveForeign)) *
                timeElapsed;
        }
        _reserveNative = uint112(balanceNative);
        _reserveForeign = uint112(balanceForeign);
        _blockTimestampLast = blockTimestamp;
        emit Sync(balanceNative, balanceForeign);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /* ========== MODIFIERS ========== */
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.9;

library VaderMath {
    /* ========== CONSTANTS ========== */

    uint256 public constant ONE = 1 ether;

    /* ========== LIBRARY FUNCTIONS ========== */

    function calculateLiquidityUnits(
        uint256 vaderDeposited,
        uint256 vaderBalance,
        uint256 assetDeposited,
        uint256 assetBalance,
        uint256 totalPoolUnits
    ) public pure returns (uint256) {
        // slipAdjustment
        uint256 slip = calculateSlipAdjustment(
            vaderDeposited,
            vaderBalance,
            assetDeposited,
            assetBalance
        );

        // (Va + vA)
        uint256 poolUnitFactor = (vaderBalance * assetDeposited) +
            (vaderDeposited * assetBalance);

        // 2VA
        uint256 denominator = ONE * 2 * vaderBalance * assetBalance;

        // P * [(Va + vA) / (2 * V * A)] * slipAdjustment
        return ((totalPoolUnits * poolUnitFactor) / denominator) * slip;
    }

    function calculateSlipAdjustment(
        uint256 vaderDeposited,
        uint256 vaderBalance,
        uint256 assetDeposited,
        uint256 assetBalance
    ) public pure returns (uint256) {
        // Va
        uint256 vaderAsset = vaderBalance * assetDeposited;

        // aV
        uint256 assetVader = assetBalance * vaderDeposited;

        // (v + V) * (a + A)
        uint256 denominator = (vaderDeposited + vaderBalance) *
            (assetDeposited + assetBalance);

        // 1 - [|Va - aV| / (v + V) * (a + A)]
        return ONE - (delta(vaderAsset, assetVader) / denominator);
    }

    // TODO: Vader Formula Differs https://github.com/vetherasset/vaderprotocol-contracts/blob/main/contracts/Utils.sol#L347-L356
    function calculateLoss(
        uint256 originalVader,
        uint256 originalAsset,
        uint256 releasedVader,
        uint256 releasedAsset
    ) public pure returns (uint256 loss) {
        // [(A0 * P1) + V0]
        uint256 originalValue = ((originalAsset * releasedVader) /
            releasedAsset) + originalVader;

        // [(A1 * P1) + V1]
        uint256 releasedValue = ((releasedAsset * releasedVader) /
            releasedAsset) + releasedVader;

        // [(A0 * P1) + V0] - [(A1 * P1) + V1]
        if (originalValue > releasedValue) loss = originalValue - releasedValue;
    }

    function calculateSwap(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        // x * Y * X
        uint256 numerator = amountIn * reserveIn * reserveOut;

        // (x + X) ^ 2
        uint256 denominator = pow(amountIn + reserveIn);

        amountOut = numerator / denominator;
    }

    function calculateSwapReverse(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountIn) {
        // X * Y
        uint256 XY = reserveIn * reserveOut;

        // 2y
        uint256 y2 = amountOut * 2;

        // 4y
        uint256 y4 = y2 * 2;

        require(
            y4 < reserveOut,
            "VaderMath::calculateSwapReverse: Desired Output Exceeds Maximum Output Possible (1/4 of Liquidity Pool)"
        );

        // root(-X^2 * Y * (4y - Y))    =>    root(X^2 * Y * (Y - 4y)) as Y - 4y >= 0    =>    Y >= 4y holds true
        uint256 numeratorA = root(XY) * root(reserveIn * (reserveOut - y4));

        // X * (2y - Y)    =>    2yX - XY
        uint256 numeratorB = y2 * reserveIn;
        uint256 numeratorC = XY;

        // -1 * (root(-X^2 * Y * (4y - Y)) + (X * (2y - Y)))    =>    -1 * (root(X^2 * Y * (Y - 4y)) + 2yX - XY)    =>    XY - root(X^2 * Y * (Y - 4y) - 2yX
        uint256 numerator = numeratorC - numeratorA - numeratorB;

        // 2y
        uint256 denominator = y2;

        amountIn = numerator / denominator;
    }

    function delta(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function pow(uint256 a) public pure returns (uint256) {
        return a * a;
    }

    function root(uint256 a) public pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 x = a / 2 + 1;
            while (x < c) {
                c = x;
                x = (a / x + x) / 2;
            }
        } else if (a != 0) {
            c = 1;
        }
    }
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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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