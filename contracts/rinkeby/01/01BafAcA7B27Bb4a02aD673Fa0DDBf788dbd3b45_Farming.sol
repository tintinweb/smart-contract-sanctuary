/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "BoringMath: Division by Zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    event Mint(address to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

pragma solidity 0.6.12;
library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// P1 - P3: OK
pragma solidity 0.6.12;
// solhint-disable avoid-low-level-calls
// T1 - T4: OK
contract BaseBoringBatchable {
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }    
    
    // F3 - F9: OK
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C1 - C21: OK
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory successes, bytes[] memory results) {
        // Interactions
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

// T1 - T4: OK
contract BoringBatchable is BaseBoringBatchable {
    // F1 - F9: OK
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    // C1 - C21: OK
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        // Interactions
        // X1 - X5
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

pragma solidity 0.6.12;

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }
}

interface UniswapPair {
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

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
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
        // else z = 0
    }
}

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
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

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

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair,
        bool isToken0
    ) internal view returns (uint priceCumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = UniswapPair(pair).getReserves();
        if (isToken0) {
          priceCumulative = UniswapPair(pair).price0CumulativeLast();

          // if time has elapsed since the last update on the pair, mock the accumulated price values
          if (blockTimestampLast != blockTimestamp) {
              // subtraction overflow is desired
              uint32 timeElapsed = blockTimestamp - blockTimestampLast;
              // addition overflow is desired
              // counterfactual
              priceCumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
          }
        } else {
          priceCumulative = UniswapPair(pair).price1CumulativeLast();
          // if time has elapsed since the last update on the pair, mock the accumulated price values
          if (blockTimestampLast != blockTimestamp) {
              // subtraction overflow is desired
              uint32 timeElapsed = blockTimestamp - blockTimestampLast;
              // addition overflow is desired
              // counterfactual
              priceCumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
          }
        }

    }
}

// pragma solidity 0.6.12;

// interface IRewarder {
//     using BoringERC20 for IERC20;
//     function onX0Reward(uint256 pid, address user, address recipient, uint256 x0Amount, uint256 newLpAmount) external;
//     function pendingTokens(uint256 pid, address user, uint256 x0Amount) external view returns (IERC20[] memory, uint256[] memory);
// }

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IMasterChef {
    using BoringERC20 for IERC20;
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. X0 to distribute per block.
        uint256 lastRewardBlock;  // Last block number that X0 distribution occurs.
        uint256 accX0PerShare; // Accumulated X0 per share, times 1e12. See below.
    }

    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);
    function totalAllocPoint() external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
}

pragma solidity 0.6.12;

interface IMigratorChef {
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    function migrate(IERC20 token) external returns (IERC20);
}

/// @notice The (older) MasterChef contract gives out a constant number of X0 tokens per block.
/// It is the only address with minting rights for X0.
/// The idea for this MasterChef V2 (MCV2) contract is therefore to be the owner of a dummy token
/// that is deposited into the MasterChef V1 (MCV1) contract.
/// The allocation point for this pool on MCV1 is the total allocation point for all pools that receive double incentives.
contract Farming is BoringOwnable, BoringBatchable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of X0 entitled to the user.
    struct UserPeriodInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256 depositTime;
        uint256 withdrawTime;
    }

    struct UserInfo { UserPeriodInfo[4] userPeriod; }
    
    // Info of each pool.
    struct FarmPeriod {
        IERC20 lpToken;          // Address of LP token contract.
        uint128 accX0PerShare;   // Accumulated X0 per share, times 1e12. See below.
        uint256 lastRewardTime;  // Last block number that X0 distribution occurs.
        uint256 allocPoint;
        uint256 allocPointShare;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of X0 to distribute per block.
    struct PoolInfo { 
        FarmPeriod farmPeriod1; 
        FarmPeriod farmPeriod2; 
        FarmPeriod farmPeriod3; 
        FarmPeriod farmPeriod4; 
        uint256 allocPoint; 
    }
    
    // Dev address.
    address public devaddr;

    // Dev fund (10%, initially)
    uint256 public devFundDivRate = 10;

    /// @notice Address of X0 contract.
    IERC20 public immutable x0;
    
    /// @notice Address of xUSD contract.
    IERC20 public xusd;
    
    address public factory;
    
    /// @notice pair for reserveToken <> Xusd
    address public trade_pair;
    
    /// @notice Whether or not this token is first in uniswap Xusd<>Reserve pair
    bool public isToken0;
    
    /// @notice last TWAP update time
    uint32 public blockTimestampLast;
    
    /// @notice Time of TWAP initialization
    uint256 public timeOfTWAPInit;
    
    /// @notice last TWAP cumulative price;
    uint256 public priceCumulativeLastXusdX0;
    
    uint256 public constant BASE = 10**18;

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) private userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public x0PerSecond;
    uint256 private constant ACC_X0_PRECISION = 1e12;

    uint256 public constant dayInSeconds = 86400;
    uint256[4] public periodInDays;
    uint256[4] public periodShares;
    uint256[4] public periodInSeconds;

    event Deposit(address indexed user, uint256 indexed pid, uint256 indexed mid, uint256 amount, uint256 depositBlock, uint256 withdrawBlock);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 indexed mid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 indexed mid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 indexed mid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardTime, uint256 lpSupply, uint256 accX0PerShare);
    event LogX0PerSecond(uint256 x0PerSecond);

    /// @param _x0 The X0 token contract address.
    constructor(
        IERC20 _x0,
        IERC20 _xusd,
        address _factory,
        address _devaddr,
        uint256 _x0PerSecond,
        uint256[4] memory _periodInDays,
        uint256[4] memory _periodShares
    ) public {
        (address token0, address token1) = sortTokens(address(_x0), address(_xusd));

        // used for interacting with uniswap
        if (token0 == address(_xusd)) {
          isToken0 = true;
        } else {
          isToken0 = false;
        }
        
        // X0/xUSD pair
        trade_pair = pairForX0(_factory, token0, token1);
        
        x0 = _x0;
        xusd = _xusd;
        factory = _factory;
        devaddr = _devaddr;
        x0PerSecond = _x0PerSecond;
        totalAllocPoint = 0;
        periodInDays = _periodInDays;
        periodShares = _periodShares;
        for(uint256 i=0; i<4; ++i){
            periodInSeconds[i] = periodInDays[i]*dayInSeconds;
        }
    }
    
    /** @notice Initializes TWAP start point, starts countdown to first rebase
    *
    */
    function init_twap()
        public
    {
        require(timeOfTWAPInit == 0, "already activated");
        (uint priceCumulative, uint32 blockTimestamp) =
           UniswapV2OracleLibrary.currentCumulativePrices(trade_pair, isToken0);

        require(blockTimestamp > 0, "no trades");
        blockTimestampLast = blockTimestamp;
        priceCumulativeLastXusdX0 = priceCumulative;
        timeOfTWAPInit = blockTimestamp;
    }
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    )
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    
    function pairForX0(
        address _factory,
        address _tokenA,
        address _tokenB
    )
        internal
        pure
        returns (address pair)
    {
        (address token0, address token1) = sortTokens(_tokenA, _tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                _factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'be5f45c18decae5efcc7ed7cd2084d9ec19d11a86d2566a8ee202504b65b9a64' // init code hash
            ))));
    }

    function getUserInfo(uint256 _pid) external view returns (UserInfo memory) {
        return userInfo[_pid][msg.sender];
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param _allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    function add(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        FarmPeriod[4] memory fps;
        for (uint256 periodId = 0; periodId < 4; ++periodId) {
            FarmPeriod memory fp = FarmPeriod({
                lpToken: _lpToken,
                allocPoint: _allocPoint*periodShares[periodId]/100,
                lastRewardTime: block.timestamp,
                accX0PerShare: 0,
                allocPointShare: periodShares[periodId]
            });
            fps[periodId]=fp;
        }    
        poolInfo.push(PoolInfo({farmPeriod1:fps[0], farmPeriod2:fps[1], farmPeriod3:fps[2], farmPeriod4:fps[3], allocPoint: _allocPoint}));

        emit LogPoolAddition(poolInfo.length.sub(1), _allocPoint, _lpToken);
    }

    /// @notice Update the given pool's X0 allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        FarmPeriod[4] memory fps;
        for (uint256 fpid = 0; fpid < 4; ++fpid) {
            FarmPeriod memory fp = getFarmPeriod(_pid,fpid);
            fp.allocPoint = _allocPoint*fp.allocPointShare/100;
            fps[fpid]=fp;
        }
        poolInfo[_pid].farmPeriod1 = fps[0];
        poolInfo[_pid].farmPeriod2 = fps[1];
        poolInfo[_pid].farmPeriod3 = fps[2];
        poolInfo[_pid].farmPeriod4 = fps[3];
        poolInfo[_pid].allocPoint = _allocPoint;
        
        emit LogSetPool(_pid, _allocPoint);
    }

    /// @notice Sets the x0 per second to be distributed. Can only be called by the owner.
    /// @param _x0PerSecond The amount of X0 to be distributed per second.
    function setX0PerSecond(uint256 _x0PerSecond) public onlyOwner {
        x0PerSecond = _x0PerSecond;
        emit LogX0PerSecond(_x0PerSecond);
    }
    
    function setXusd(IERC20 _xusd) external onlyOwner{
        (address token0, address token1) = sortTokens(address(x0), address(_xusd));

        // used for interacting with uniswap
        if (token0 == address(_xusd)) {
          isToken0 = true;
        } else {
          isToken0 = false;
        }
        
        // X0/xUSD pair
        trade_pair = pairForX0(factory, token0, token1);
        
        xusd = _xusd;
    }

    function getFarmPeriod(uint256 _poolId, uint256 _periodId) public view returns (FarmPeriod memory){
        require(_periodId<4, "getPeriod: wrong farmPeriod Index");
        
        PoolInfo memory pool = poolInfo[_poolId];
        if (_periodId == 0) {
            return pool.farmPeriod1;
        } else if (_periodId == 1) {
            return pool.farmPeriod2;
        } else if (_periodId == 2) {
            return pool.farmPeriod3;
        } else {
            return pool.farmPeriod4;
        }
    }

    /// @notice View function to see pending X0 on frontend.
    /// @param _pid The index of the pool.
    /// @param _fpid The index of the farming pool.
    /// @param _user Address of user.
    /// @return pending X0 reward for a given user.
    function pendingX0(uint256 _pid, uint256 _fpid, address _user) external view returns (uint256 pending) {
        FarmPeriod memory farmPeriod = getFarmPeriod(_pid,_fpid);
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accX0PerShare = farmPeriod.accX0PerShare;
        uint256 lpSupply = farmPeriod.lpToken.balanceOf(address(this));
        if (block.timestamp > farmPeriod.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(farmPeriod.lastRewardTime);
            uint256 x0Reward = time.mul(x0PerSecond).mul(farmPeriod.allocPoint) / totalAllocPoint;
            accX0PerShare = accX0PerShare.add(x0Reward.mul(ACC_X0_PRECISION) / lpSupply);
        }
        pending = int256(user.userPeriod[_fpid].amount.mul(accX0PerShare) / ACC_X0_PRECISION).sub(user.userPeriod[_fpid].rewardDebt).toUInt256();
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 len = poolInfo.length;
        for (uint256 pid = 0; pid < len; ++pid) {
            for (uint256 fpid = 0; fpid < 4; ++fpid) {
                updatePool(pid,fpid);
            } 
        }
    }
    
    function getPrice()
        public view
        returns (uint256)
    {
        (uint priceCumulative, uint32 blockTimestamp) =
           UniswapV2OracleLibrary.currentCumulativePrices(trade_pair, isToken0);

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

       // no period check as is done in isRebaseWindow

       uint256 priceAverageXusdX0 = uint256(uint224((priceCumulative - priceCumulativeLastXusdX0) / timeElapsed));

       // BASE is on order of 1e18, which takes 2^60 bits
       // multiplication will revert if priceAverage > 2^196
       // (which it can because it overflows intentially)
       uint256 XusdX0Price;
       if (priceAverageXusdX0 > uint192(-1)) {
          // eat loss of precision
          // effectively: (x / 2**112) * 1e18
          XusdX0Price = (priceAverageXusdX0 >> 112) * BASE;
       } else {
         // cant overflow
         // effectively: (x * 1e18 / 2**112)
         XusdX0Price = (priceAverageXusdX0 * BASE) >> 112;
       }

       return XusdX0Price;
    }

    /// @notice Update reward variables of the given pool.
    /// @param _pid The index of the pool.
    /// @param _fpid The index of the farming pool.
    /// @return farm Returns the pool that was updated.
    function updatePool(uint256 _pid, uint256 _fpid) public returns (FarmPeriod memory farm) {
        farm = getFarmPeriod(_pid, _fpid);
        if (block.timestamp > farm.lastRewardTime) {
            uint256 lpSupply = farm.lpToken.balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(farm.lastRewardTime);
                uint256 x0Reward = time.mul(x0PerSecond).mul(farm.allocPoint) / totalAllocPoint;
                
                uint256 x0Bal = x0.balanceOf(address(this));
                uint256 x0Amount = x0Reward / devFundDivRate;
                
                if(x0Bal >= x0Amount){
                    x0.safeTransfer(devaddr, x0Amount);
                } else{
                    if(x0Bal > 0){ x0.safeTransfer(devaddr, x0Bal); }
                    uint256 xusdAmount = x0Amount.sub(x0Bal);
                    xusdAmount = xusdAmount.mul(BASE).div(getPrice());
                    xusd.mint(devaddr, xusdAmount);
                }
                
                farm.accX0PerShare = farm.accX0PerShare.add((x0Reward.mul(ACC_X0_PRECISION) / lpSupply).to128());
            }
            farm.lastRewardTime = block.timestamp;
            
            PoolInfo memory pool = poolInfo[_pid];
            if (_fpid == 0) {
                pool.farmPeriod1 = farm;
            } else if (_fpid == 1) {
                pool.farmPeriod2 = farm;
            } else if (_fpid == 2) {
                pool.farmPeriod3 = farm;
            } else {
                pool.farmPeriod4 = farm;
            }
            
            emit LogUpdatePool(_pid, farm.lastRewardTime, lpSupply, farm.accX0PerShare);
        }
    }

    /// @notice Deposit LP tokens to MCV2 for X0 allocation.
    /// @param _pid The index of the pool.
    /// @param _fpid The index of the farming pool.
    /// @param _amount LP token amount to deposit.
    function deposit(uint256 _pid, uint256 _fpid, uint256 _amount) public {
        FarmPeriod memory farmPeriod = updatePool(_pid, _fpid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserPeriodInfo memory upi;

        uint upLength = user.userPeriod.length;

        if (upLength > 0){
            upi = user.userPeriod[_fpid];
            upi.amount = upi.amount.add(_amount);
            upi.rewardDebt = upi.rewardDebt.add(int256(_amount.mul(farmPeriod.accX0PerShare) / ACC_X0_PRECISION));
            user.userPeriod[_fpid] = upi;
        } else{
            for (uint256 fpid = 0; fpid < 4; ++fpid) {
                user.userPeriod[fpid].amount = 0;
                user.userPeriod[fpid].rewardDebt = 0;
            }
            user.userPeriod[_fpid].amount = _amount;
            user.userPeriod[_fpid].rewardDebt = int256(_amount.mul(farmPeriod.accX0PerShare) / ACC_X0_PRECISION);
        }

        farmPeriod.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        user.userPeriod[_fpid].depositTime = block.timestamp;
        user.userPeriod[_fpid].withdrawTime = user.userPeriod[_fpid].depositTime + periodInSeconds[_fpid];

        emit Deposit(msg.sender, _pid, _fpid, _amount, user.userPeriod[_fpid].depositTime, user.userPeriod[_fpid].withdrawTime);
    }
    
    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param _pid The index of the pool.
    /// @param _pid The index of the farming pool.
    /// @param _amount LP token amount to withdraw.
    function withdraw(uint256 _pid, uint256 _fpid, uint256 _amount) public {
        FarmPeriod memory farmPeriod = updatePool(_pid, _fpid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(block.timestamp > user.userPeriod[_fpid].withdrawTime, "withdraw: still in lock period");
        require(user.userPeriod[_fpid].amount >= _amount, "withdraw: insufficient balance");

        int256 accumulatedX0 = int256(user.userPeriod[_fpid].amount.mul(farmPeriod.accX0PerShare) / ACC_X0_PRECISION);
        uint256 _pendingX0 = accumulatedX0.sub(user.userPeriod[_fpid].rewardDebt).toUInt256();

        // Effects
        user.userPeriod[_fpid].rewardDebt = accumulatedX0.sub(int256(_amount.mul(farmPeriod.accX0PerShare) / ACC_X0_PRECISION));
        user.userPeriod[_fpid].amount = user.userPeriod[_fpid].amount.sub(_amount);
        
        // Interactions
        uint256 x0Bal = x0.balanceOf(address(this));
        
        if(x0Bal >= _pendingX0){
            x0.safeTransfer(msg.sender, _pendingX0);
        } else{
            if(x0Bal > 0){ x0.safeTransfer(msg.sender, x0Bal); }
            uint256 _pendingXusd = _pendingX0.sub(x0Bal);
            _pendingXusd = _pendingXusd.mul(BASE).div(getPrice());
            xusd.mint(msg.sender, _pendingXusd);
        }

        farmPeriod.lpToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _pid, _fpid, _amount);
        emit Harvest(msg.sender, _pid, _fpid, _pendingX0);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool.
    /// @param _pid The index of the farming pool.
    function emergencyWithdraw(uint256 _pid, uint256 _fpid) public {
        FarmPeriod memory farmPeriod = getFarmPeriod(_pid,_fpid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.userPeriod[_fpid].amount;
        user.userPeriod[_fpid].amount = 0;
        user.userPeriod[_fpid].rewardDebt = 0;

        // Note: transfer can fail or succeed if `amount` is zero.
        farmPeriod.lpToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, _fpid, amount);
    }

    function setDev(address _dev) public onlyOwner {
        require(devaddr != address(0), "setDev: invalid address");
        devaddr = _dev;
    }
    
    // * Additional functions separate from the original MC contract *
    function config(uint256[4] memory _periodInDays,  uint256[4] memory _periodShares) public onlyOwner {
        massUpdatePools();
        periodInDays = _periodInDays;
        periodShares = _periodShares;
        for(uint256 i=0; i<4; ++i){
            periodInSeconds[i] = periodInDays[i]*dayInSeconds;
        }
    }

    function setDevFundDivRate(uint256 _devFundDivRate) public onlyOwner {
        require(_devFundDivRate > 0, "!devFundDivRate-0");
        devFundDivRate = _devFundDivRate;
    }
}