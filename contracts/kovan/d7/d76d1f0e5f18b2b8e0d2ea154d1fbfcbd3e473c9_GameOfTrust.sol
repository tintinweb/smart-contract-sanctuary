/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// File: contracts/GameOfTrustAdminStorage.sol

pragma solidity ^0.6.12;


contract GameOfTrustAdminStorage{
    address public admin;
    address public implementation;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/lib/contracts/libraries/FixedPoint.sol

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

// File: contracts/GameOfTrustStorage.sol

pragma solidity ^0.6.12;




contract GameOfTrustStorage is GameOfTrustAdminStorage {
    using FixedPoint for *;

    struct PoolInfo {
        uint256 marketCap; //解锁市值
        uint256 rewardRate; // 收益比例
        uint256 totalAmountLimit;  // 可认购总额
        uint256 totalAmount; // 认购总量
        uint256 unlockCycle; // 解锁周期（块）
        uint256 unlockBlock; // 解锁高度,默认为0,未解锁
        uint256 liquidateAmount; // 注入的罚金数量
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        bool liquidateClaimed;
    }

    struct LiquidateRate {
        uint256 timeOffset;
        uint256 rate;  // Penalty percentage
    }

  //   uint public constant PERIOD = 24 hours * 15;
   uint public constant PERIOD = 1 seconds * 2;

    IUniswapV2Pair public pair;
    uint256 public priceCumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public priceAverage;
    address public GAN;
    uint256 public startBlock;
    uint256 public stakeEndBlock;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public constant totalRate = 10000;
    uint256 public constant stakeFineRate = 500;
    uint256 public  blocksPerDay;
    LiquidateRate[] public liquidateRates;
    bool public redeemGanClaimed;


    event AddPool(uint256 pid, uint256 marketCap,
        uint256 rewardRate, uint256 unlockCycle, uint256 totalAmountLimit);
    event UpdatePool(uint256 pid, uint256 marketCap,
        uint256 rewardRate, uint256 unlockCycle, uint256 totalAmountLimit);
    event RedeemGAN(address receiver, uint256 redeemAmount);
    event Deposit(uint256 pid, address sender, uint256 amount);
    event Withdraw(uint256 pid, address receiver, uint256 amount, uint256 fine);
    event Harvest(uint256 pid, address receiver, uint256 amout);
    event UpToStandard(uint256 pid, uint256 timestamp, uint256 currentMarketcap);
    event HarvestLiquidateReward(uint256 pid, address receiver, uint256 amount);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

// File: contracts/libraries/UniswapV2OracleLibrary.sol

pragma solidity >=0.5.0;



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

// File: contracts/GameOfTrust.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;







contract GameOfTrust is GameOfTrustStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    modifier onlyAdmin(){
        require(admin == msg.sender, "UNAUTHORIZED");
        _;
    }

    function initialize(uint256 _startBlock,
        uint256 _stakeEndBlock,
        uint256 _blocksDaily,
        address _GAN,
        address _pair) external {
        require(msg.sender == admin, "UNAUTHORIZED");
        require(GAN == address(0), "Already initialized");
        require(_GAN != address(0), "Invalid param");
        require(blocksPerDay==0,"Already initialized");
        require(_blocksDaily!=0,"Invalid param");
        require(_startBlock > block.number, "Start too early");
        require(_stakeEndBlock > _startBlock, "Stake end too early");
        pair = IUniswapV2Pair(_pair);
        startBlock = _startBlock;
        stakeEndBlock = _stakeEndBlock;
        blocksPerDay = _blocksDaily;
        GAN = _GAN;
        initPriceConfig();
    }

    function setLiquidateRates(LiquidateRate[] memory _liquidateRates) external onlyAdmin {
        delete liquidateRates;
        for (uint i = 0; i < _liquidateRates.length; i++) {
            liquidateRates.push(
                _liquidateRates[i]
            );
        }
    }

    function addPool(uint256 _marketCap,
        uint256 _rewardRate,
        uint256 _totalAmountLimit,
        uint256 _unlockCycleDays) external onlyAdmin {
        require(block.number < startBlock, "Activity has started");
        require(_unlockCycleDays > 0, "Must Greater than 0");
        poolInfo.push(
            PoolInfo({
        marketCap : _marketCap,
        rewardRate : _rewardRate,
        totalAmountLimit : _totalAmountLimit,
        totalAmount : 0,
        unlockCycle : _unlockCycleDays.mul(blocksPerDay),
        unlockBlock : 0,
        liquidateAmount : 0
        })
        );

        uint256 pid = poolInfo.length - 1;
        emit AddPool(pid, _marketCap, _rewardRate, _unlockCycleDays.mul(blocksPerDay), _totalAmountLimit);
    }

    function updatePool(uint256 _pid,
        uint256 _marketCap,
        uint256 _rewardRate,
        uint256 _totalAmountLimit,
        uint256 _unlockCycleDays) external onlyAdmin {
        require(poolInfo.length - 1 >= _pid, "Out of bounds");
        require(block.number < startBlock, "Activity has started");
        require(_unlockCycleDays > 0, "Must Greater than 0");
        poolInfo[_pid].marketCap = _marketCap;
        poolInfo[_pid].rewardRate = _rewardRate;
        poolInfo[_pid].totalAmountLimit = _totalAmountLimit;
        poolInfo[_pid].unlockCycle = _unlockCycleDays.mul(blocksPerDay);
        emit UpdatePool(_pid, _marketCap, _rewardRate, poolInfo[_pid].unlockCycle, _totalAmountLimit);
    }

    //  Admin redeem surplus gan token. can only execute once.
    function redeemGAN() external onlyAdmin {
        require(block.number > stakeEndBlock, "Stake period not end");
        require(!redeemGanClaimed, "Have redeemed");
        uint256 totalSurplusAmount;
        for (uint i = 0; i < poolInfo.length; i++) {
            totalSurplusAmount = totalSurplusAmount.add(calculateSurplusGan(poolInfo[i]));
        }
        redeemGanClaimed = true;
        IERC20(GAN).safeTransfer(msg.sender, totalSurplusAmount);
        emit RedeemGAN(msg.sender, totalSurplusAmount);
    }

    //    User deposit token into an agreetment.
    function deposit(uint256 _pid, uint256 _amount) external {
        require(block.number >= startBlock, "Stake period not start");
        require(block.number < stakeEndBlock, "Stake period be end");
        require(poolInfo.length - 1 >= _pid, "Pid out of bounds");
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.totalAmount.add(_amount) > pool.totalAmountLimit) {
            _amount = pool.totalAmountLimit.sub(pool.totalAmount);
        }
        UserInfo storage user = userInfo[_pid][msg.sender];
        IERC20(GAN).safeTransferFrom(msg.sender, address(this), _amount);
        pool.totalAmount = pool.totalAmount.add(_amount);
        user.amount = user.amount.add(_amount);
        emit Deposit(_pid, msg.sender, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        require(block.number >= startBlock, "Activity not start");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 finalQuantity;
        uint256 fine;
        if (pool.unlockBlock > 0) {
            //            unlock (withdraw all )
            (finalQuantity, fine) = unlockedWithdraw(pool, user);
        } else {
            //            lock
            (finalQuantity, fine) = lockedWithdraw(pool, user, _amount);
        }
        emit Withdraw(_pid, msg.sender, finalQuantity, fine);
    }


    // Number of users redeemed and released（Principal + income）
    function harvest(uint256 _pid) external {
        PoolInfo memory pool = poolInfo[_pid];
        require(pool.unlockBlock != 0, "Not reached unlock markedcap");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "No right to share profits");
        uint256 unlockAmount = harvestUnlockReward(pool, user);
        emit Harvest(_pid, msg.sender, unlockAmount);
    }

    function updateMarkedCap() external onlyAdmin {
        updatePriceAverage();
        checkMarketcaps();
    }

    //    Method of obtaining penalty dividend amount
    function getRewardOfFinePool(uint256 _pid,address _user) external view returns (uint256){
        return calculateLiquidateRewardAmount(_pid,_user);
    }

    //   Collection of penalty dividends
    function harvestLiquidateReward(uint256 _pid) external {
        uint256 amount = calculateLiquidateRewardAmount(_pid,msg.sender);
        require(userInfo[_pid][msg.sender].liquidateClaimed == false, "Have received");
        userInfo[_pid][msg.sender].liquidateClaimed = true;
        IERC20(GAN).safeTransfer(msg.sender, amount);
        emit HarvestLiquidateReward(_pid, msg.sender, amount);
    }

    function getAveragePrice() external view returns (uint256){
        return priceAverage.mul(uint(1)).decode144();
    }

    //    ==================================boundary======================================

    function calculateLiquidateRewardAmount(uint256 _pid,address _user) internal view returns (uint256){
        PoolInfo memory pool = poolInfo[_pid];
        require(pool.unlockBlock > 0, "Not reached unlock markedcap");
        uint256 unlockEndHeigh = pool.unlockBlock.add(pool.unlockCycle);
        require(block.number > unlockEndHeigh, "Unlock not finshed");
        UserInfo memory user = userInfo[_pid][_user];
        return user.amount.mul(pool.liquidateAmount).div(pool.totalAmount);
    }

    function unlockedWithdraw(PoolInfo storage _pool,
        UserInfo storage _user) internal returns (uint256, uint256) {
        uint256 endBlock = _pool.unlockBlock.add(_pool.unlockCycle);
        uint256 countBlock = block.number > endBlock ? endBlock : block.number;
        uint256 fine = (_pool.unlockCycle.add(_pool.unlockBlock).sub(countBlock))
        .mul(_user.amount.mul(_pool.rewardRate))
        .div(totalRate.mul(_pool.unlockCycle));
        uint256 totalUnlock = _user.amount.mul(totalRate.add(_pool.rewardRate)).div(totalRate).sub(fine);
        uint256 finalQuantity = totalUnlock.sub(_user.rewardDebt);
        _pool.totalAmount = _pool.totalAmount.sub(_user.amount);
        _pool.liquidateAmount = _pool.liquidateAmount.add(fine);
        _user.amount = 0;
        _user.rewardDebt = totalUnlock;
        IERC20(GAN).safeTransfer(msg.sender, finalQuantity);
        return (finalQuantity, fine);
    }


    function lockedWithdraw(PoolInfo storage _pool,
        UserInfo storage _user,
        uint256 _amount) internal returns (uint256, uint256){
        if (block.number <= stakeEndBlock) {
            //        stake period
            return inStakePeriodWithdraw(_pool, _user, _amount);
        } else {
            //          stake period over
            return afterStakePeriodWithdraw(_pool, _user);
        }

    }


    function inStakePeriodWithdraw(PoolInfo storage _pool
    , UserInfo storage _user
    , uint256 _amount) internal returns (uint256, uint256) {
        require(_user.amount >= _amount, "Insufficient funds");
        return withdrawToken(_pool, _user, _amount, stakeFineRate, 0);
    }


    function withdrawToken(PoolInfo storage _pool,
        UserInfo storage _user,
        uint256 _amount,
        uint256 _fineRate,
        uint256 _potentialReward) internal returns (uint256, uint256){
        uint256 fine = _amount.mul(_fineRate).div(totalRate);
        uint256 finalQuantity = _amount.sub(fine);
        _user.amount = _user.amount.sub(_amount);
        _pool.totalAmount = _pool.totalAmount.sub(_amount);
        _pool.liquidateAmount = _pool.liquidateAmount.add(fine).add(_potentialReward);
        IERC20(GAN).safeTransfer(msg.sender, finalQuantity);
        return (finalQuantity, fine);
    }

    function afterStakePeriodWithdraw(PoolInfo storage _pool,
        UserInfo storage _user) internal returns (uint256, uint256){
        uint256 spandDays = calculateSpandDays(stakeEndBlock, block.number, blocksPerDay);
        uint256 fineRate = judgeFineRate(spandDays);
        uint256 amount = _user.amount;
        // Amount of advance income into penalty pool (calculate advance income)
        uint256 potentialReward = amount.mul(_pool.rewardRate).div(totalRate);
        return withdrawToken(_pool, _user, amount, fineRate, potentialReward);
    }


    function judgeFineRate(uint256 _spandDays) internal view returns (uint256){
        for (uint i = 0; i < liquidateRates.length; i++) {
            LiquidateRate memory current = liquidateRates[i];
            if (_spandDays <= current.timeOffset) {
                return current.rate;
            }
        }
        return 0;
    }


    function harvestUnlockReward(PoolInfo memory _pool, UserInfo storage _user) internal returns (uint256){
        uint256 endBlock = _pool.unlockBlock.add(_pool.unlockCycle);
        uint256 countBlock = block.number > endBlock ? endBlock : block.number;
        uint256 unlockAmount = (countBlock.sub(_pool.unlockBlock))
        .mul(_user.amount)
        .mul(totalRate.add(_pool.rewardRate))
        .div(_pool.unlockCycle.mul(totalRate));
        uint256 pendingUnlockAmount = unlockAmount.sub(_user.rewardDebt);
        _user.rewardDebt = unlockAmount;
        IERC20(GAN).safeTransfer(msg.sender, pendingUnlockAmount);
    }


    function checkMarketcaps() internal {
        uint256 currentMarketcap = calculateMarketcap();
        for (uint i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].marketCap <= currentMarketcap) {
                poolInfo[i].unlockBlock = block.number;
                emit UpToStandard(i, block.number, currentMarketcap);
            }
        }
    }


    function calculateMarketcap() internal returns (uint256 amountOut){
        uint256 totalSupply = IERC20(GAN).totalSupply();
        amountOut = priceAverage.mul(totalSupply).decode144();
    }


    function updatePriceAverage() internal {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
        UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        require(timeElapsed >= PERIOD, 'UpdatePrice: PERIOD_NOT_ELAPSED');
        address token = pair.token0();
        if (token == GAN) {
            priceAverage = FixedPoint.uq112x112(uint224((price0Cumulative - priceCumulativeLast) / timeElapsed));
            priceCumulativeLast = price0Cumulative;
        } else {
            priceAverage = FixedPoint.uq112x112(uint224((price1Cumulative - priceCumulativeLast) / timeElapsed));
            priceCumulativeLast = price1Cumulative;
        }
        blockTimestampLast = blockTimestamp;
    }

    //   Initializing price accumulation (starting after the end of the signing period) is executed only once
    function initPriceConfig() internal {
        address token0 = pair.token0();
        if (token0 == GAN) {
            priceCumulativeLast = pair.price0CumulativeLast();
        } else {
            priceCumulativeLast = pair.price1CumulativeLast();
        }
        (,, blockTimestampLast) = pair.getReserves();
    }


    function calculateSurplusGan(PoolInfo memory pool) internal view returns (uint256){
        return (pool.totalAmountLimit.sub(pool.totalAmount)).mul(pool.rewardRate).div(totalRate);
    }


    function calculateSpandDays(uint256 _start,
        uint256 _end,
        uint256 _blockPerDay) internal pure returns (uint256){
        return _end.sub(_start).div(_blockPerDay);
    }



}