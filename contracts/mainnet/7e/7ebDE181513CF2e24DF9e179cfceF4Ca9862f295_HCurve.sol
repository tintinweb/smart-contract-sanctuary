// File: localhost/contracts/handlers/curve/IOneSplit.sol

pragma solidity ^0.5.0;

interface IOneSplit {
    function getExpectedReturn(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 parts,
        uint256 featureFlags
    )
        external
        view
        returns (uint256 returnAmount, uint256[] memory distribution);

    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 featureFlags
    ) external payable;
}

// File: localhost/contracts/handlers/curve/ICurveDeposit.sol

pragma solidity ^0.5.0;

// Curve compound, y, busd, pax and susd pools have this wrapped contract called
// deposit used to manipulate liquidity.
interface ICurveDeposit {
    function underlying_coins(int128 arg0) external view returns (address);

    function token() external view returns (address);

    // compound pool
    function add_liquidity(
        uint256[2] calldata uamounts,
        uint256 min_mint_amount
    ) external;

    // usdt(deprecated) pool
    function add_liquidity(
        uint256[3] calldata uamounts,
        uint256 min_mint_amount
    ) external;

    // y, busd and pax pools
    function add_liquidity(
        uint256[4] calldata uamounts,
        uint256 min_mint_amount
    ) external;

    // compound, y, busd, pax and susd pools
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount,
        bool donate_dust
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);
}

// File: localhost/contracts/handlers/curve/ICurveSwap.sol

pragma solidity ^0.5.0;

interface ICurveSwap {
    function coins(int128 arg0) external view returns (address);

    function underlying_coins(int128 arg0) external view returns (address);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    // ren pool
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;

    // sbtc pool
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    // susd pool
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    // Curve ren and sbtc pools
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);
}

// File: localhost/contracts/Config.sol

pragma solidity ^0.5.0;


contract Config {
    // function signature of "postProcess()"
    bytes4 constant POSTPROCESS_SIG = 0xc2722916;

    // Handler post-process type. Others should not happen now.
    enum HandlerType {Token, Custom, Others}
}

// File: localhost/contracts/lib/LibCache.sol

pragma solidity ^0.5.0;


library LibCache {
    function setAddress(bytes32[] storage _cache, address _input) internal {
        _cache.push(bytes32(uint256(uint160(_input))));
    }

    function set(bytes32[] storage _cache, bytes32 _input) internal {
        _cache.push(_input);
    }

    function setHandlerType(bytes32[] storage _cache, uint256 _input) internal {
        require(_input < uint96(-1), "Invalid Handler Type");
        _cache.push(bytes12(uint96(_input)));
    }

    function setSender(bytes32[] storage _cache, address _input) internal {
        require(_cache.length == 0, "cache not empty");
        setAddress(_cache, _input);
    }

    function getAddress(bytes32[] storage _cache)
        internal
        returns (address ret)
    {
        ret = address(uint160(uint256(peek(_cache))));
        _cache.pop();
    }

    function getSig(bytes32[] storage _cache) internal returns (bytes4 ret) {
        ret = bytes4(peek(_cache));
        _cache.pop();
    }

    function get(bytes32[] storage _cache) internal returns (bytes32 ret) {
        ret = peek(_cache);
        _cache.pop();
    }

    function peek(bytes32[] storage _cache)
        internal
        view
        returns (bytes32 ret)
    {
        require(_cache.length > 0, "cache empty");
        ret = _cache[_cache.length - 1];
    }

    function getSender(bytes32[] storage _cache)
        internal
        returns (address ret)
    {
        require(_cache.length > 0, "cache empty");
        ret = address(uint160(uint256(_cache[0])));
    }
}

// File: localhost/contracts/Cache.sol

pragma solidity ^0.5.0;



/// @notice A cache structure composed by a bytes32 array
contract Cache {
    using LibCache for bytes32[];

    bytes32[] cache;

    modifier isCacheEmpty() {
        require(cache.length == 0, "Cache not empty");
        _;
    }
}

// File: localhost/contracts/handlers/HandlerBase.sol

pragma solidity ^0.5.0;




contract HandlerBase is Cache, Config {
    function postProcess() external payable {
        revert("Invalid post process");
        /* Implementation template
        bytes4 sig = cache.getSig();
        if (sig == bytes4(keccak256(bytes("handlerFunction_1()")))) {
            // Do something
        } else if (sig == bytes4(keccak256(bytes("handlerFunction_2()")))) {
            bytes32 temp = cache.get();
            // Do something
        } else revert("Invalid post process");
        */
    }

    function _updateToken(address token) internal {
        cache.setAddress(token);
        // Ignore token type to fit old handlers
        // cache.setHandlerType(uint256(HandlerType.Token));
    }

    function _updatePostProcess(bytes32[] memory params) internal {
        for (uint256 i = params.length; i > 0; i--) {
            cache.set(params[i - 1]);
        }
        cache.set(msg.sig);
        cache.setHandlerType(uint256(HandlerType.Custom));
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: localhost/contracts/handlers/curve/HCurve.sol

pragma solidity ^0.5.0;







contract HCurve is HandlerBase {
    using SafeERC20 for IERC20;

    address public constant ONE_SPLIT = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

    // Curve fixed input used for susd, ren and sbtc pools
    function exchange(
        address swap,
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external payable {
        ICurveSwap curveSwap = ICurveSwap(swap);
        IERC20(curveSwap.coins(i)).safeApprove(address(curveSwap), dx);
        curveSwap.exchange(i, j, dx, minDy);
        IERC20(curveSwap.coins(i)).safeApprove(address(curveSwap), 0);

        _updateToken(curveSwap.coins(j));
    }

    // Curve fixed input used for compound, y, busd and pax pools
    function exchangeUnderlying(
        address swap,
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external payable {
        ICurveSwap curveSwap = ICurveSwap(swap);
        IERC20(curveSwap.underlying_coins(i)).safeApprove(
            address(curveSwap),
            dx
        );
        curveSwap.exchange_underlying(i, j, dx, minDy);
        IERC20(curveSwap.underlying_coins(i)).safeApprove(
            address(curveSwap),
            0
        );

        _updateToken(curveSwap.underlying_coins(j));
    }

    // OneSplit fixed input used for Curve swap
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 featureFlags
    ) external payable {
        IOneSplit oneSplit = IOneSplit(ONE_SPLIT);
        IERC20(fromToken).safeApprove(address(oneSplit), amount);
        oneSplit.swap(
            fromToken,
            toToken,
            amount,
            minReturn,
            distribution,
            featureFlags
        );
        IERC20(fromToken).safeApprove(address(oneSplit), 0);

        _updateToken(toToken);
    }

    // Curve add liquidity used for susd, ren and sbtc pools which don't use
    // underlying tokens.
    function addLiquidity(
        address swapAddress,
        address pool,
        uint256[] calldata amounts,
        uint256 minMintAmount
    ) external payable {
        ICurveSwap curveSwap = ICurveSwap(swapAddress);

        // Approve non-zero amount erc20 token
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;
            IERC20(curveSwap.coins(int128(i))).safeApprove(
                address(curveSwap),
                amounts[i]
            );
        }

        // Execute add_liquidity according to amount array size
        if (amounts.length == 4) {
            uint256[4] memory amts = [
                amounts[0],
                amounts[1],
                amounts[2],
                amounts[3]
            ];
            curveSwap.add_liquidity(amts, minMintAmount);
        } else if (amounts.length == 3) {
            uint256[3] memory amts = [amounts[0], amounts[1], amounts[2]];
            curveSwap.add_liquidity(amts, minMintAmount);
        } else if (amounts.length == 2) {
            uint256[2] memory amts = [amounts[0], amounts[1]];
            curveSwap.add_liquidity(amts, minMintAmount);
        } else {
            revert("invalid amount array size");
        }

        // Reset zero amount for approval
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;
            IERC20(curveSwap.coins(int128(i))).safeApprove(
                address(curveSwap),
                0
            );
        }

        // Update post process
        _updateToken(address(pool));
    }

    // Curve add liquidity used for compound, y, busd and pax pools using
    // zap which is wrapped contract called deposit.
    function addLiquidityZap(
        address deposit,
        uint256[] calldata uamounts,
        uint256 minMintAmount
    ) external payable {
        ICurveDeposit curveDeposit = ICurveDeposit(deposit);

        // Approve non-zero amount erc20 token
        for (uint256 i = 0; i < uamounts.length; i++) {
            if (uamounts[i] == 0) continue;
            IERC20(curveDeposit.underlying_coins(int128(i))).safeApprove(
                address(curveDeposit),
                uamounts[i]
            );
        }

        // Execute add_liquidity according to uamount array size
        if (uamounts.length == 4) {
            uint256[4] memory amts = [
                uamounts[0],
                uamounts[1],
                uamounts[2],
                uamounts[3]
            ];
            curveDeposit.add_liquidity(amts, minMintAmount);
        } else if (uamounts.length == 3) {
            uint256[3] memory amts = [uamounts[0], uamounts[1], uamounts[2]];
            curveDeposit.add_liquidity(amts, minMintAmount);
        } else if (uamounts.length == 2) {
            uint256[2] memory amts = [uamounts[0], uamounts[1]];
            curveDeposit.add_liquidity(amts, minMintAmount);
        } else {
            revert("invalid uamount array size");
        }

        // Reset zero amount for approval
        for (uint256 i = 0; i < uamounts.length; i++) {
            if (uamounts[i] == 0) continue;
            IERC20(curveDeposit.underlying_coins(int128(i))).safeApprove(
                address(curveDeposit),
                0
            );
        }

        // Update post process
        _updateToken(curveDeposit.token());
    }

    // Curve remove liquidity one coin used for ren and sbtc pools which don't
    // use underlying tokens.
    function removeLiquidityOneCoin(
        address swapAddress,
        address pool,
        uint256 tokenAmount,
        int128 i,
        uint256 minAmount
    ) external payable {
        ICurveSwap curveSwap = ICurveSwap(swapAddress);
        IERC20(pool).safeApprove(address(curveSwap), tokenAmount);
        curveSwap.remove_liquidity_one_coin(tokenAmount, i, minAmount);
        IERC20(pool).safeApprove(address(curveSwap), 0);

        // Update post process
        _updateToken(curveSwap.coins(i));
    }

    // Curve remove liquidity one coin used for compound, y, busd, pax and susd
    // pools using zap which is wrapped contract called deposit. Note that if we
    // use susd remove_liquidity_one_coin() it must be the one in deposit
    // instead of swap contract.
    function removeLiquidityOneCoinZap(
        address deposit,
        uint256 tokenAmount,
        int128 i,
        uint256 minUamount
    ) external payable {
        ICurveDeposit curveDeposit = ICurveDeposit(deposit);
        IERC20(curveDeposit.token()).safeApprove(
            address(curveDeposit),
            tokenAmount
        );
        curveDeposit.remove_liquidity_one_coin(
            tokenAmount,
            i,
            minUamount,
            true
        );
        IERC20(curveDeposit.token()).safeApprove(address(curveDeposit), 0);

        // Update post process
        _updateToken(curveDeposit.underlying_coins(i));
    }
}