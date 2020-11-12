pragma solidity 0.5.15;

// A contract to facilitate trustless OTC purchases and sales, particularly focused for DAO treasury management where one actor is slow moving.

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
        (bool success, ) = recipient.call.value(amount)("");
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
        (bool success, bytes memory returndata) = target.call.value(weiValue)(data);
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



interface ExpandedERC20 {
  function decimals() external returns (uint8);
}

contract OTC {

    using SafeMath for uint256;

    /// @notice Address of the approved trader
    address public approved_trader;

    /// @notice Token the reserves are selling
    address public reserves_sell_token;

    /// @notice Token the reserves are puchasing
    address public reserves_purchase_token;

    /// @notice For a sale of a specific amount
    uint256 public sell_amount;

    /// @notice For a purchase of a specific amount
    uint256 public purchase_amount;

    /// @notice Denotes if trade is a sale or purchase
    bool public isSale;

    /// @notice Current uniswap pair for purchase & sale tokens
    address public uniswap_pair1;

    /// @notice Second uniswap pair for if TWAP uses two markets to determine price (for liquidity purposes)
    address public uniswap_pair2;

    /// @notice Flag for if purchase token is toke 0 in uniswap pair 2
    bool public purchaseTokenIs0;

    /// @notice Flag for if sale token is token 0 in uniswap pair
    bool public saleTokenIs0;

    /// @notice TWAP for first hop
    uint256 public priceAverageSell;

    /// @notice TWAP for second hop
    uint256 public priceAverageBuy;

    /// @notice last TWAP update time
    uint32 public blockTimestampLast;

    /// @notice last TWAP cumulative price;
    uint256 public priceCumulativeLastSell;

    /// @notice last TWAP cumulative price for two hop pairs;
    uint256 public priceCumulativeLastBuy;

    /// @notice Time between TWAP updates
    uint256 public period;

    /// @notice Grace period after last twap update for a trade to occur
    uint256 public constant GRACE = 60 * 60; // 1 hour

    /// @notice Uniswap Factory
    address public constant uniFact = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    /// @notice constant used for percentage calculations
    uint256 public constant BASE = 10**18;

    /// @notice Reserve to withdraw from
    address public reserve;

    /// @notice % bound away from TWAP price
    uint256 public twap_bounds;

    /// @notice counts number of twaps
    uint256 public twap_counter;

    /// @notice denotes a trade as complete
    bool public complete;

    /// @notice governor
    address public gov;

    /// @notice pending governor
    address public pendingGov;

    event NewPendingGov(address oldPendingGov, address pendingGov);
    event NewGov(address oldGov, address newGov);
    event SaleSetup(address trader, address reserve, address sellToken, address purchaseToken, uint256 sellAmount);
    event BuySetup(address trader, address reserve, address sellToken, address purchaseToken, uint256 buyAmount);

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    constructor() public {
      gov = msg.sender;
    }

    function _setPendingGov(address pending)
        public
        onlyGov
    {
        require(pending != address(0));
        address oldPending = pendingGov;
        pendingGov = pending;
        emit NewPendingGov(oldPending, pending);
    }

    function acceptGov()
        public
    {
        require(msg.sender == pendingGov);
        address old = gov;
        gov = pendingGov;
        emit NewGov(old, pendingGov);
    }



    function setup_sale (
        address trader,
        address sell_token,
        address purchase_token,
        uint256 sell_amount_,
        uint256 twap_period,
        uint256 twap_bounds_,
        address uniswap1,
        address uniswap2, // if two hop
        address reserve_
    )
        public
        onlyGov
    {
        approved_trader = trader;
        reserves_sell_token = sell_token;
        reserves_purchase_token = purchase_token;
        sell_amount = sell_amount_;
        reserve = reserve_;
        isSale = true;
        period = twap_period;
        twap_bounds = twap_bounds_;
        complete = false;
        reset_twap(uniswap1, uniswap2, sell_token, purchase_token);
        emit SaleSetup(trader, reserve_, sell_token, purchase_token, sell_amount_);
    }

    function setup_purchase (
        address trader,
        address sell_token,
        address purchase_token,
        uint256 purchase_amount_,
        uint256 twap_period,
        uint256 twap_bounds_,
        address uniswap1,
        address uniswap2, // if two hop
        address reserve_
    )
        public
        onlyGov
    {
        approved_trader = trader;
        reserves_sell_token = sell_token;
        reserves_purchase_token = purchase_token;
        purchase_amount = purchase_amount_;
        reserve = reserve_;
        isSale = false;
        period = twap_period;
        twap_bounds = twap_bounds_;
        complete = false;
        reset_twap(uniswap1, uniswap2, sell_token, purchase_token);
        emit BuySetup(trader, reserve_, sell_token, purchase_token, purchase_amount_);
    }

    function trade (
        uint256 amount_in,
        uint256 amount_out
    )
        public
    {
        require(msg.sender == approved_trader);
        require(recencyCheck(), "TWAP is not recent enough");
        require(!complete, "Trade has already been performed");

        if (isSale) {
            // ensures trader is getting what they expect
            require(sell_amount >= amount_out, "Trader expected out < out");

            // input amount is how many tokens we are buying from desk
            require(withinBounds(amount_in, sell_amount), "Sale price not within bounds of TWAP");

            // transfers input amount of purchase token from trader to reserve
            SafeERC20.safeTransferFrom(IERC20(reserves_purchase_token), approved_trader, reserve, amount_in);

            // transfers set amount of sale token from reserve to trader
            SafeERC20.safeTransferFrom(IERC20(reserves_sell_token), reserve, approved_trader, sell_amount);
        } else {
            // ensures trader is getting what they expect
            require(purchase_amount <= amount_in, "Purchaser expected_in < in");

            // input amount is how many tokens desk is requesting for a given
            // number of tokens
            require(withinBounds(purchase_amount, amount_out), "Purchase price not within bounds of TWAP");

            // transfers set amount of purchase token from trader to reserve
            SafeERC20.safeTransferFrom(IERC20(reserves_purchase_token), approved_trader, reserve, amount_in);

            // transfers requested amount of sale token from reserve to trader
            SafeERC20.safeTransferFrom(IERC20(reserves_sell_token), reserve, approved_trader, amount_out);
        }

        complete = true;
    }

    function recencyCheck()
        internal
        returns (bool)
    {
        return (block.timestamp - blockTimestampLast < GRACE) && (twap_counter > 0);
    }

    // callable by anyone
    function update_twap()
        public
    {
        (uint256 sell_token_priceCumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswap_pair1, saleTokenIs0);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= period, 'OTC: PERIOD_NOT_ELAPSED');

        // overflow is desired
        priceAverageSell = uint256(uint224((sell_token_priceCumulative - priceCumulativeLastSell) / timeElapsed));
        priceCumulativeLastSell = sell_token_priceCumulative;


        if (uniswap_pair2 != address(0)) {
            // two hop
            (uint256 buy_token_priceCumulative, ) =
                UniswapV2OracleLibrary.currentCumulativePrices(uniswap_pair2, !purchaseTokenIs0);
            priceAverageBuy = uint256(uint224((buy_token_priceCumulative - priceCumulativeLastBuy) / timeElapsed));

            priceCumulativeLastBuy = buy_token_priceCumulative;
        }

        twap_counter = twap_counter.add(1);

        blockTimestampLast = blockTimestamp;
    }


    function consult()
        public
        returns (uint256)
    {
        if (uniswap_pair2 != address(0)) {
            // two hop
            uint256 purchasePrice;
            uint256 salePrice;
            uint256 one;
            if (saleTokenIs0) {
                uint8 decs = ExpandedERC20(reserves_sell_token).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            } else {
                uint8 decs = ExpandedERC20(reserves_sell_token).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            }

            if (priceAverageSell > uint192(-1)) {
               // eat loss of precision
               // effectively: (x / 2**112) * 1e18
               purchasePrice = (priceAverageSell >> 112) * one;
            } else {
              // cant overflow
              // effectively: (x * 1e18 / 2**112)
              purchasePrice = (priceAverageSell * one) >> 112;
            }

            if (purchaseTokenIs0) {
                uint8 decs = ExpandedERC20(UniswapPair(uniswap_pair2).token1()).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            } else {
                uint8 decs = ExpandedERC20(UniswapPair(uniswap_pair2).token0()).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            }

            if (priceAverageBuy > uint192(-1)) {
                salePrice = (priceAverageBuy >> 112) * one;
            } else {
                salePrice = (priceAverageBuy * one) >> 112;
            }

            return purchasePrice.mul(salePrice).div(one);
        } else {
            uint256 one;
            if (saleTokenIs0) {
                uint8 decs = ExpandedERC20(reserves_sell_token).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            } else {
                uint8 decs = ExpandedERC20(reserves_sell_token).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            }
            // single hop
            uint256 purchasePrice;
            if (priceAverageSell > uint192(-1)) {
               // eat loss of precision
               // effectively: (x / 2**112) * 1e18
               purchasePrice = (priceAverageSell >> 112) * one;
            } else {
                // cant overflow
                // effectively: (x * 1e18 / 2**112)
                purchasePrice = (priceAverageSell * one) >> 112;
            }
            return purchasePrice;
        }
    }

    function reset_twap(
        address uniswap1,
        address uniswap2,
        address sell_token,
        address purchase_token
    )
        internal
    {
        uniswap_pair1 = uniswap1;
        uniswap_pair2 = uniswap2;

        blockTimestampLast = 0;
        priceCumulativeLastSell = 0;
        priceCumulativeLastBuy = 0;
        priceAverageBuy = 0;

        if (UniswapPair(uniswap1).token0() == sell_token) {
            saleTokenIs0 = true;
        } else {
            saleTokenIs0 = false;
        }

        if (uniswap2 != address(0)) {
            if (UniswapPair(uniswap2).token0() == purchase_token) {
                purchaseTokenIs0 = true;
            } else {
                purchaseTokenIs0 = false;
            }
        }

        update_twap();
        twap_counter = 0;
    }

    function quote(
      uint256 purchaseAmount,
      uint256 saleAmount
    )
      public
      returns (uint256)
    {
      uint256 decs = uint256(ExpandedERC20(reserves_sell_token).decimals());
      uint256 one = 10**decs;
      return purchaseAmount.mul(one).div(saleAmount);
    }

    function bounds()
        public
        returns (uint256)
    {
        uint256 uniswap_quote = consult();
        uint256 minimum = uniswap_quote.mul(BASE.sub(twap_bounds)).div(BASE);
        return minimum;
    }


    function withinBounds (
        uint256 purchaseAmount,
        uint256 saleAmount
    )
        internal
        returns (bool)
    {
        uint256 quoted = quote(purchaseAmount, saleAmount);
        uint256 minimum = bounds();
        return quoted > minimum;
    }
}