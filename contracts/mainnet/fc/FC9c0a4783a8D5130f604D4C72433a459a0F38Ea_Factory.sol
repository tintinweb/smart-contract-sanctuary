// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

// ============ Contract information ============

/**
 * @title  InterestRateSwapFactory
 * @notice A deployment contract for Greenwood basis swap pools
 * @author Greenwood Labs
 */

 // ============ Imports ============

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import './libraries/FactoryUtils.sol';

contract Factory {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Immutable storage ============

    address private immutable governance;

    // ============ Mutable storage ============

    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => address))))) public getPool;
    mapping(uint256 => bool) public swapDurations;
    mapping(uint256 => bool) public protocols;
    mapping(uint256 => mapping(address => bool)) public protocolMarkets;
    mapping(uint256 => address) public protocolAdapters;
    mapping(address => uint256) public underlierDecimals;
    mapping(address => Params) public getParamsByPool;
    address[] public allPools;
    uint256 public swapDurationCount;
    uint256 public protocolCount;
    uint256 public protocolMarketCount;
    bool public isPaused;

    // ============ Structs ============

    struct Params {
        uint256 durationInSeconds;
        uint256 position;
        uint256 protocol0;
        uint256 protocol1;
        address underlier;
    }

    struct FeeParams {
        uint256 rateLimit;
        uint256 rateSensitivity;
        uint256 utilizationInflection;
        uint256 rateMultiplier;
    }

    // ============ Events ============

    event PoolCreated(        
        uint256 durationInSeconds,
        address pool,
        uint256 position,
        uint256[] protocols,
        address indexed underlier,
        uint256 poolLength
    );

    // ============ Constructor ============

    constructor(
        address _governance
    ) {
        governance = _governance;
    }

    // ============ Modifiers ============

    modifier onlyGovernance {
        // assert that the caller is governance
        require(msg.sender == governance);
        _;
    }

    // ============ External methods ============

    // ============ Get the number of created pools ============

    function allPoolsLength() external view returns (uint256) {
        
        // return the length of the allPools array
        return allPools.length;
    }

    // ============ Pause and unpause the factory ============

    function togglePause() external onlyGovernance() returns (bool){

        // toggle the value of isPaused
        isPaused = !isPaused;

        return true;
    }

    // ============ Update the supported swap durations ============

    function updateSwapDurations(
        uint256 _duration,
        bool _is_supported
    ) external onlyGovernance() returns (bool){

        // get the initial value
        bool initialValue = swapDurations[_duration];

        // update the swapDurations mapping
        swapDurations[_duration] = _is_supported;

        // check if a swapDuration is being added
        if (initialValue == false && _is_supported == true) {

            // increment the swapDurationCount
            swapDurationCount = swapDurationCount.add(1);

        }

        // check if a swapDuration is being removed
        else if (initialValue == true && _is_supported == false) {
            
            // decrement the swapDurationCount
            swapDurationCount = swapDurationCount.sub(1);

        }

        return true;

    }

    // ============ Update the supported protocols ============

    function updateProtocols(
        uint256 _protocol,
        bool _is_supported
    ) external onlyGovernance() returns (bool){

        // get the initial value
        bool initialValue = protocols[_protocol];

        // update the protocols mapping
        protocols[_protocol] = _is_supported;

        // check if a protocol is being added
        if (initialValue == false && _is_supported == true) {

            // increment the protocolCount
            protocolCount = protocolCount.add(1);

        }

        // check if a protocol is being removed
        else if (initialValue == true && _is_supported == false) {

            // decrement the protocolCount
            protocolCount = protocolCount.sub(1);

        }

        return true;

    }

    // ============ Update the supported protocol markets ============

    function updateProtocolMarkets(
        uint256 _protocol,
        address _market,
        bool _is_supported
    ) external onlyGovernance() returns (bool){

        // get the initial value
        bool initialValue = protocolMarkets[_protocol][_market];

        // update the protocolMarkets mapping
        protocolMarkets[_protocol][_market] = _is_supported;

        // check if a protocol market is being added
        if (initialValue == false && _is_supported == true) {

            // increment the protocolMarketCount
            protocolMarketCount = protocolMarketCount.add(1);

        }

        // check if a protocol market is being removed
        else if (initialValue == true && _is_supported == false) {

            // decrement the protocolMarketCount
            protocolMarketCount = protocolMarketCount.sub(1);

        }

        return true;

    }

    // ============ Update the protocol adapters mapping ============

    function updateProtocolAdapters(
        uint256 _protocol,
        address _adapter
    ) external onlyGovernance() returns(bool) {

        // update the protocolMarkets mapping
        protocolAdapters[_protocol] = _adapter;

        return true;
        
    }

    // ============ Update the underlier decimals mapping ============

    function updateUnderlierDecimals (
        address _underlier,
        uint256 _decimals
    ) external onlyGovernance() returns (bool) {

        require(_decimals <= 18, '20');

        // update the underlierDecimals mapping
        underlierDecimals[_underlier] = _decimals;

        return true;

    }


    // ============ Create a new pool ============

    function createPool(
        uint256 _duration,
        uint256 _position,
        uint256[] memory _protocols,
        address _underlier,
        uint256 _initialDeposit,
        uint256 _rateLimit,
        uint256 _rateSensitivity,
        uint256 _utilizationInflection,
        uint256 _rateMultiplier
    ) external returns (address pool) {

        // assert that the factory is not paused
        require(isPaused == false, '1');

        // assert that the duration of the swap is supported
        require(swapDurations[_duration] == true, '2');

        // assert that the position is supported
        require(_position == 0 || _position == 1, '3');

        // assert that the protocols are not the same
        require(_protocols[0] != _protocols[1], '4');

        // assert that both protocols are supported
        require(protocols[_protocols[0]] && protocols[_protocols[1]], '4');

        // assert that the specified protocols support the specified underlier
        require(protocolMarkets[_protocols[0]][_underlier] && protocolMarkets[_protocols[1]][_underlier], '5');

        // assert that the pool has not already been created
        require(getPool[_underlier][_protocols[0]][_protocols[1]][_duration][_position] == address(0), '6');

        // assert that the adapter for the specified protocol0 is defined
        require(protocolAdapters[_protocols[0]] != address(0), '7');

        // assert that the adapter for the specified protocol1 is defined
        require(protocolAdapters[_protocols[1]] != address(0), '7');

        // assert that the decimals for the underlier is defined
        require(underlierDecimals[_underlier] != 0, '8');

        FeeParams memory feeParams;
        bytes memory initCode;
        bytes32 salt;

        // scope to avoid stack too deep errors
        {
            feeParams = FeeParams(
                _rateLimit,
                _rateSensitivity,
                _utilizationInflection,
                _rateMultiplier
            );
        }

        // scope to avoid stack too deep errors
        {
            // generate byte code
            (bytes memory encodedParams, bytes memory encodedPackedParams) = _generateByteCode(
                _duration,
                _position,
                _protocols,
                _underlier,
                _initialDeposit,
                feeParams
            );

            // generate the init code
            initCode = FactoryUtils.generatePoolInitCode(encodedParams);

            // generate the salt
            salt = keccak256(encodedPackedParams);
        }

        // get the address of the pool
        assembly {
            pool := create2(0, add(initCode, 32), mload(initCode), salt)
        }

        // add the pool to the registry
        getPool[_underlier][_protocols[0]][_protocols[1]][_duration][_position] = pool;
        getParamsByPool[pool] = Params(_duration, _position, _protocols[0], _protocols[1], _underlier);
        allPools.push(pool);

        // transfer the initial deposit into the pool
        IERC20(_underlier).safeTransferFrom(
            msg.sender,
            pool,
            _initialDeposit
        );

        // emit a PoolCreated event
        emit PoolCreated(
            _duration,
            pool,
            _position,
            _protocols,
            _underlier,
            allPools.length
        );

    }

    // ============ Internal functions ============

    // ============ Generates byte code for pool creation ============

    function _generateByteCode(
        uint256 _duration,
        uint256 _position,
        uint256[] memory _protocols,
        address _underlier,
        uint256 _initialDeposit,
        FeeParams memory feeParams
    ) internal view returns (bytes memory encodedParams, bytes memory encodedPackedParams) {
        
        // create the initcode
        encodedParams = abi.encode(
                _underlier,
                underlierDecimals[_underlier],
                protocolAdapters[_protocols[0]],
                protocolAdapters[_protocols[1]],
                _protocols[0],
                _protocols[1],
                _position,
                _duration,
                _initialDeposit,
                feeParams.rateLimit,
                feeParams.rateSensitivity,
                feeParams.utilizationInflection,
                feeParams.rateMultiplier,
                msg.sender
        );

        // create the salt
        encodedPackedParams = abi.encodePacked(
                 _underlier,
                underlierDecimals[_underlier],
                protocolAdapters[_protocols[0]],
                protocolAdapters[_protocols[1]],
                _protocols[0],
                _protocols[1],
                _position,
                _duration,
                _initialDeposit,
                feeParams.rateLimit,
                feeParams.rateSensitivity,
                feeParams.utilizationInflection,
                feeParams.rateMultiplier,
                msg.sender
        );
    }   
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

import '../Pool.sol';


library FactoryUtils {

    function generatePoolInitCode(bytes memory encodedParams) external pure returns (bytes memory) {
        // generate the init code
        return abi.encodePacked(
            type(Pool).creationCode, encodedParams
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

// ============ Contract information ============

/**
 * @title  Interest Rate Swaps V1
 * @notice A pool for Interest Rate Swaps
 * @author Greenwood Labs
 */

// ============ Imports ============

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IAdapter.sol';
import '../interfaces/IGreenwoodERC20.sol';
import './GreenwoodERC20.sol';


contract Pool is IPool, GreenwoodERC20 {
    // ============ Import usage ============

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Immutable storage ============

    address private constant GOVERNANCE = 0xe3D5260Cd7F8a4207f41C3B2aC87882489f97213;

    uint256 private constant TEN_EXP_18 = 1000000000000000000;
    uint256 private constant STANDARD_DECIMALS = 18;
    uint256 private constant BLOCKS_PER_DAY = 6570; // 13.15 seconds per block
    uint256 private constant MAX_TO_PAY_BUFFER_NUMERATOR = 10;
    uint256 private constant MAX_TO_PAY_BUFFER_DENOMINATOR = 100;
    uint256 private constant DAYS_PER_YEAR = 360;

    // ============ Mutable storage ============

    address private factory;
    address public adapter0;
    address public adapter1;
    address public underlier;

    uint256 public protocol0;
    uint256 public protocol1;
    uint256 public totalSwapCollateral;
    uint256 public totalSupplementaryCollateral;
    uint256 public totalActiveLiquidity;
    uint256 public totalAvailableLiquidity;
    uint256 public utilization;
    uint256 public totalFees;
    uint256 public fee;
    uint256 public direction;
    uint256 public durationInDays;
    uint256 public underlierDecimals;
    uint256 public decimalDifference;
    uint256 public rateLimit;
    uint256 public rateSensitivity;
    uint256 public utilizationInflection;
    uint256 public rateMultiplier;
    uint256 public maxDepositLimit;

    mapping(bytes32 => Swap) public swaps;
    mapping(address => uint256) public swapNumbers;
    mapping(address => uint256) public liquidityProviderLastDeposit;

    // ============ Structs ============
  
    struct Swap {
        address user;
        bool isClosed;
        uint256 notional;
        uint256 swapCollateral;
        uint256 activeLiquidity;
        uint256 openBlock;
        uint256 underlierProtocol0BorrowIndex;
        uint256 underlierProtocol1BorrowIndex;
    }

    // ============ Modifiers ============
    // None

    // ============ Events ============

    event OpenSwap(address indexed user, uint256 notional, uint256 activeLiquidity, uint256 swapFee);
    event CloseSwap(address indexed user, uint256 notional, uint256 userToPay, uint256 ammToPay);
    event DepositLiquidity(address indexed user, uint256 liquidityAmount);
    event WithdrawLiquidity(address indexed user, uint256 liquidityAmount, uint256 feesAccrued);
    event Liquidate(address indexed liquidator, address indexed user, uint256 swapNumber, uint256 liquidatorReward);
    event Mint(address indexed user, uint256 underlyingTokenAmount, uint256 liquidityTokenAmount);
    event Burn(address indexed user, uint256 underlyingTokenAmount, uint256 liquidityTokenAmount);
    
    // ============ Constructor ============

    constructor(
        address _underlier,
        uint256 _underlierDecimals,
        address _adapter0,
        address _adapter1,
        uint256 _protocol0,
        uint256 _protocol1,
        uint256 _direction,
        uint256 _durationInDays,
        uint256 _initialDeposit,
        uint256 _rateLimit,
        uint256 _rateSensitivity,
        uint256 _utilizationInflection,
        uint256 _rateMultiplier,
        address _poolDeployer
    ) {
        // assert that the pool can be initialized with a non-zero amount
        require(_initialDeposit > 0, 'Initial token amount must be greater than 0');

        // initialize the pool
        factory = msg.sender;
        underlier = _underlier;
        underlierDecimals = _underlierDecimals;
        direction = _direction;
        durationInDays = _durationInDays;
        adapter0 = _adapter0;
        adapter1 = _adapter1;
        protocol0 = _protocol0;
        protocol1 = _protocol1;

        // calculate difference in decimals between underlier and STANDARD_DECIMALS
        decimalDifference = _calculatedDecimalDifference(underlierDecimals, STANDARD_DECIMALS);

        // adjust the token decimals to the standard number
        uint256 adjustedInitialDeposit = _convertToStandardDecimal(_initialDeposit);

        totalAvailableLiquidity = adjustedInitialDeposit;
        rateLimit = _rateLimit;
        rateSensitivity = _rateSensitivity;
        utilizationInflection = _utilizationInflection;
        rateMultiplier = _rateMultiplier;
        maxDepositLimit = 1000000000000000000000000;

        // calculate the initial swap fee
        fee = _calculateFee();

        // Update the pool deployer's deposit block number
        liquidityProviderLastDeposit[_poolDeployer] = block.number;

        // mint LP tokens to the pool deployer
        _mintLPTokens(_poolDeployer, adjustedInitialDeposit);
    }


    // ============ Opens a new basis swap ============

    function openSwap(uint256 _notional) external override returns (bool) {
        // assert that a swap is opened with an non-zero notional
        require(_notional > 0, '9');

        // adjust notional to standard decimal places
        uint256 adjustedNotional = _convertToStandardDecimal(_notional);

        // calculate the swap collateral and trade active liquidity based off the notional
        (uint256 swapCollateral, uint256 activeLiquidity) = _calculateSwapCollateralAndActiveLiquidity(adjustedNotional);

        // assert that there is sufficient liquidity to open this swap
        require(activeLiquidity <= totalAvailableLiquidity, '10');

        // assign the supplementary collateral
        uint256 supplementaryCollateral = activeLiquidity;

        // calculate the fee based on swap collateral
        uint256 swapFee = swapCollateral.mul(fee).div(TEN_EXP_18);

        // calculate the current borrow index for the underlier on protocol 0
        uint256 underlierProtocol0BorrowIndex = IAdapter(adapter0).getBorrowIndex(underlier);

        // calculate the current borrow index for the underlier on protocol 1
        uint256 underlierProtocol1BorrowIndex = IAdapter(adapter1).getBorrowIndex(underlier);

        // create the swap struct
        Swap memory swap = Swap(
            msg.sender,
            false,
            adjustedNotional,
            swapCollateral,
            activeLiquidity,
            block.number,
            underlierProtocol0BorrowIndex,
            underlierProtocol1BorrowIndex
        );
        
        // create a swap key by hashing together the user and their current swap number
        bytes32 swapKey = keccak256(abi.encode(msg.sender, swapNumbers[msg.sender]));
        swaps[swapKey] = swap;

        // update the user's swap number
        swapNumbers[msg.sender] = swapNumbers[msg.sender].add(1);

        // update the total active liquidity
        totalActiveLiquidity = totalActiveLiquidity.add(activeLiquidity);

        // update the total swap collateral
        totalSwapCollateral = totalSwapCollateral.add(swapCollateral);

        // update the total supplementary collateral
        totalSupplementaryCollateral = totalSupplementaryCollateral.add(supplementaryCollateral);

        // update the total available liquidity
        totalAvailableLiquidity = totalAvailableLiquidity.sub(activeLiquidity);

        // update the total fees accrued
        totalFees = totalFees.add(swapFee);

        // the total amount to debit the user (swap collateral + fee + the supplementary collateral)
        uint256 amountToDebit = swapCollateral.add(fee).add(supplementaryCollateral);

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fixed interest rate
        fee = _calculateFee();

        // transfer underlier from the user
        IERC20(underlier).safeTransferFrom(
            msg.sender,
            address(this),
            _convertToUnderlierDecimal(amountToDebit)
        );

        // emit an open swap event
        emit OpenSwap(msg.sender, adjustedNotional, activeLiquidity, swapFee);

        // return true on successful open swap
        return true;
    }


    // ============ Closes an interest rate swap ============

    function closeSwap(uint256 _swapNumber) external override returns (bool) {
        // the key of the swap
        bytes32 swapKey = keccak256(abi.encode(msg.sender, _swapNumber));

        // assert that a swap exists for this user
        require(swaps[swapKey].user == msg.sender, '11');

        // assert that this swap has not already been closed
        require(!swaps[swapKey].isClosed, '12');

        // get the swap to be closed
        Swap memory swap = swaps[swapKey];

        // the amounts that the user and the AMM will pay on this swap, depending on the direction of the swap
        (uint256 userToPay, uint256 ammToPay) = _calculateInterestAccrued(swap);

        // assert that the swap cannot be closed in the same block that it was opened
        require(block.number > swap.openBlock, '13');

        // the total payout for this swap
        uint256 payout = userToPay > ammToPay ? userToPay.sub(ammToPay) : ammToPay.sub(userToPay);

        // the supplementary collateral of this swap
        uint256 supplementaryCollateral = swap.activeLiquidity;

        // the active liquidity recovered upon closure of this swap
        uint256 activeLiquidityRecovered;

        // the amount to reward the user upon closing of the swap
        uint256 redeemableFunds;

        // the user won the swap
        if (ammToPay > userToPay) {
            // ensure the payout does not exceed the active liquidity for this swap
            payout = Math.min(payout, swap.activeLiquidity);

            // active liquidity recovered is the the total active liquidity reduced by the user's payout
            activeLiquidityRecovered = swap.activeLiquidity.sub(payout);

            // User can redeem all of swap collateral, all of supplementary collateral, and the payout
            redeemableFunds = swap.swapCollateral.add(supplementaryCollateral).add(payout);
        }

        // the AMM won the swap
        else if (ammToPay < userToPay) {
            // ensure the payout does not exceed the swap collateral for this swap
            payout = Math.min(payout, swap.swapCollateral);

            // active liquidity recovered is the the total active liquidity increased by the amm's payout
            activeLiquidityRecovered = swap.activeLiquidity.add(payout);

            // user can redeem all of swap collateral, all of supplementary collateral, with the payout subtracted
            redeemableFunds = swap.swapCollateral.add(supplementaryCollateral).sub(payout);
        }

        // neither party won the swap
        else {
            // active liquidity recovered is the the initial active liquidity for the trade
            activeLiquidityRecovered = swap.activeLiquidity;

            // user can redeem all of swap collateral and all of supplementary collateral
            redeemableFunds = swap.swapCollateral.add(supplementaryCollateral);
        }

        // update the total active liquidity
        totalActiveLiquidity = totalActiveLiquidity.sub(swap.activeLiquidity);

        // update the total swap collateral
        totalSwapCollateral = totalSwapCollateral.sub(swap.swapCollateral);

        // update the total supplementary collateral
        totalSupplementaryCollateral = totalSupplementaryCollateral.sub(supplementaryCollateral);

        // update the total available liquidity
        totalAvailableLiquidity = totalAvailableLiquidity.add(activeLiquidityRecovered);

        // close the swap
        swaps[swapKey].isClosed = true;

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fee
        fee = _calculateFee();

        // transfer redeemable funds to the user
        IERC20(underlier).safeTransfer(
            msg.sender, 
            _convertToUnderlierDecimal(redeemableFunds)
        );

        // emit a close swap event
        emit CloseSwap(msg.sender, swap.notional, userToPay, ammToPay);

        return true;
    }

    // ============ Deposit liquidity into the pool ============

    function depositLiquidity(uint256 _liquidityAmount) external override returns (bool) {

        // adjust liquidity amount to standard decimals
        uint256 adjustedLiquidityAmount = _convertToStandardDecimal(_liquidityAmount);

        // asert that liquidity amount must be greater than 0 and amount to less than the max deposit limit
        require(adjustedLiquidityAmount > 0 && adjustedLiquidityAmount.add(totalActiveLiquidity).add(totalAvailableLiquidity) <= maxDepositLimit, '14');

        // transfer the specified amount of underlier into the pool
        IERC20(underlier).safeTransferFrom(msg.sender, address(this), _liquidityAmount);

        // add to the total available liquidity in the pool
        totalAvailableLiquidity = totalAvailableLiquidity.add(adjustedLiquidityAmount);

        // update the most recent deposit block of the liquidity provider
        liquidityProviderLastDeposit[msg.sender] = block.number;

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fee
        fee = _calculateFee();

        // mint LP tokens to the liiquidity provider
        _mintLPTokens(msg.sender, adjustedLiquidityAmount);

        // emit deposit liquidity event
        emit DepositLiquidity(msg.sender, adjustedLiquidityAmount);

        return true;
    }


    // ============ Withdraw liquidity from the pool ============

    function withdrawLiquidity(uint256 _liquidityTokenAmount) external override returns (bool) {
        // assert that withdrawal does not occur in the same block as a deposit
        require(liquidityProviderLastDeposit[msg.sender] < block.number, '19');

        // asert that liquidity amount must be greater than 0
        require(_liquidityTokenAmount > 0, '14');

        // transfer the liquidity tokens from sender to the pool
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), _liquidityTokenAmount);

        // determine the amount of underlying tokens that the liquidity tokens can be redeemed for
        uint256 redeemableUnderlyingTokens = calculateLiquidityTokenValue(_liquidityTokenAmount);

        // assert that there is enough available liquidity to safely withdraw this amount
        require(totalAvailableLiquidity >= redeemableUnderlyingTokens, '10');

        // the fees that this withdraw will yield (total fees accrued * withdraw amount / total liquidity provided)
        uint256 feeShare = totalFees.mul(redeemableUnderlyingTokens).div(totalActiveLiquidity.add(totalAvailableLiquidity));

        // update the total fees remaining in the pool
        totalFees = totalFees.sub(feeShare);

        // remove the withdrawn amount from  the total available liquidity in the pool
        totalAvailableLiquidity = totalAvailableLiquidity.sub(redeemableUnderlyingTokens);

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fee
        fee = _calculateFee();

        // mint LP tokens to the liiquidity provider
        _burnLPTokens(msg.sender, _liquidityTokenAmount);

        // emit withdraw liquidity event
        emit WithdrawLiquidity(msg.sender, redeemableUnderlyingTokens, feeShare);

        return true;
    }

    // ============ Liquidate a swap that has expired ============
    
    function liquidate(address _user, uint256 _swapNumber) external override returns (bool) {
        // the key of the swap
        bytes32 swapKey = keccak256(abi.encode(_user, _swapNumber));

        // assert that a swap exists for this user
        require(swaps[swapKey].user == _user, '11');

        // get the swap to be liquidated
        Swap memory swap = swaps[swapKey];

        // assert that the swap has not already been closed
        require(!swap.isClosed, '12');

        // the expiration block of the swap
        uint256 expirationBlock = swap.openBlock.add(durationInDays.mul(BLOCKS_PER_DAY));

        // assert that the swap has eclipsed the expiration block
        require(block.number >= expirationBlock, '17');
        
        // transfer trade active liquidity from the liquidator
        IERC20(underlier).safeTransferFrom(
            msg.sender,
            address(this),
            _convertToUnderlierDecimal(swap.activeLiquidity)
        );

        // the amounts that the user and the AMM will pay on this swap, depending on the direction of the swap
        (uint256 userToPay, uint256 ammToPay) =_calculateInterestAccrued(swap);

        // the total payout for this swap
        uint256 payout = userToPay > ammToPay ? userToPay.sub(ammToPay) : ammToPay.sub(userToPay);

        // the supplementary collateral of this swap
        uint256 supplementaryCollateral = swap.activeLiquidity;

        // the active liquidity recovered upon liquidation of this swap
        uint256 activeLiquidityRecovered;

        // the amount to reward the liquidator upon liquidation of the swap
        uint256 liquidatorReward;

        // the user won the swap
        if (ammToPay > userToPay) {
            // ensure the payout does not exceed the active liquidity for this swap
            payout = Math.min(payout, swap.activeLiquidity);

            // active liquidity recovered is the the total active liquidity increased by the user's unclaimed payout
            activeLiquidityRecovered = swap.activeLiquidity.add(payout);

            // liquidator is rewarded the supplementary collateral and the difference between the swap collateral and the payout
            liquidatorReward = supplementaryCollateral.add(swap.swapCollateral).sub(payout);
        }

        // the AMM won the swap
        else if (ammToPay < userToPay) {
            // ensure the payout does not exceed the swap collateral for this swap
            payout = Math.min(payout, swap.swapCollateral);

            // active liquidity recovered is the the total active liquidity increased by the entire swap collateral
            activeLiquidityRecovered = swap.activeLiquidity.add(swap.swapCollateral);

            // liquidator is rewarded all of the supplementary collateral
            liquidatorReward = supplementaryCollateral;
        }

        // neither party won the swap
        else {
            // active liquidity recovered is the the total active liquidity for this swap
            activeLiquidityRecovered = swap.activeLiquidity;

            // liquidator is rewarded all of the supplementary collateral and the swap collateral
            liquidatorReward = supplementaryCollateral.add(swap.swapCollateral);
        }

        // update the total active liquidity
        totalActiveLiquidity = totalActiveLiquidity.sub(swap.activeLiquidity);

        // update the total swap collateral
        totalSwapCollateral = totalSwapCollateral.sub(swap.swapCollateral);

        // update the total supplementary collateral
        totalSupplementaryCollateral = totalSupplementaryCollateral.sub(supplementaryCollateral);

        // update the total available liquidity
        totalAvailableLiquidity = totalAvailableLiquidity.add(activeLiquidityRecovered);

        // close the swap
        swaps[swapKey].isClosed = true;

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fee
        fee = _calculateFee();

        // transfer liquidation reward to the liquidator
        IERC20(underlier).safeTransfer(
            msg.sender, 
            _convertToUnderlierDecimal(liquidatorReward)
        );

        // emit liquidate event
        emit Liquidate(msg.sender, _user, _swapNumber, liquidatorReward);

        return true;
    }

    // ============ External view for the interest accrued on a variable rate ============

    function calculateVariableInterestAccrued(uint256 _notional, uint256 _protocol, uint256 _borrowIndex) external view override returns (uint256) {
        return _calculateVariableInterestAccrued(_notional, _protocol, _borrowIndex);
    }

    // ============ Calculates the current variable rate for the underlier on a particular protocol ============

    function calculateVariableRate(uint256 _protocol) external view returns (uint256) {
        // the adapter to use given the particular protocol
        address adapter = _protocol == protocol0 ? adapter0 : adapter1;

        // use the current variable rate for the underlying token
        uint256 variableRate = IAdapter(adapter).getBorrowRate(underlier);
        
        return variableRate;
    }

    function changeMaxDepositLimit(uint256 _limit) external {

        // assert that only governance can adjust the deposit limit
        require(msg.sender == GOVERNANCE, '18');

        // change the deposit limit
        maxDepositLimit = _limit;
    }

    // ============ Calculates the current approximate value of liquidity tokens denoted in the underlying token ============

    function calculateLiquidityTokenValue(uint256 liquidityTokenAmount) public view returns (uint256 redeemableUnderlyingTokens) {

        // get the total underlying token balance in this pool with supplementary and swap collateral amounts excluded
        uint256 adjustedUnderlyingTokenBalance = _convertToStandardDecimal(IERC20(underlier).balanceOf(address(this)))
                                                    .sub(totalSwapCollateral)
                                                    .sub(totalSupplementaryCollateral);

        // the total supply of LP tokens in circulation
        uint256 _totalSupply = totalSupply();

        // determine the amount of underlying tokens that the liquidity tokens can be redeemed for
        redeemableUnderlyingTokens = liquidityTokenAmount.mul(adjustedUnderlyingTokenBalance).div(_totalSupply);
    }

    // ============ Calculates the max variable rate to pay ============

    function calculateMaxVariableRate(address adapter) external view returns (uint256) {
        return _calculateMaxVariableRate(adapter);
    }

    // ============ Internal methods ============

    // ============ Mints LP tokens to users that deposit liquidity to the protocol ============

    function _mintLPTokens(address to, uint256 underlyingTokenAmount) internal {

        // the total supply of LP tokens in circulation
        uint256 _totalSupply = totalSupply();

        // determine the amount of LP tokens to mint
        uint256 mintableLiquidity;

        if (_totalSupply == 0) {
            // initialize the supply of LP tokens
            mintableLiquidity = underlyingTokenAmount;
        } 
        
        else {
            // get the total underlying token balance in this pool
            uint256 underlyingTokenBalance = _convertToStandardDecimal(IERC20(underlier).balanceOf(address(this)));
                                                
            // adjust the underlying token balance to standardize the decimals
            // the supplementary collateral, swap collateral, and newly added liquidity amounts are excluded
            uint256 adjustedUnderlyingTokenBalance = underlyingTokenBalance
                                                        .sub(totalSwapCollateral)
                                                        .sub(totalSupplementaryCollateral)
                                                        .sub(underlyingTokenAmount);

            // mint a proportional amount of LP tokens
            mintableLiquidity = underlyingTokenAmount.mul(_totalSupply).div(adjustedUnderlyingTokenBalance);
        }

        // assert that enough liquidity tokens are available to be minted
        require(mintableLiquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        // mint the tokens directly to the LP
        _mint(to, mintableLiquidity);

        // emit minting of LP token event
        emit Mint(to, underlyingTokenAmount, mintableLiquidity);
    }

    // ============ Burns LP tokens and sends users the equivalent underlying tokens in return ============

    function _burnLPTokens(address to, uint256 liquidityTokenAmount) internal {

        // determine the amount of underlying tokens that the liquidity tokens can be redeemed for
        uint256 redeemableUnderlyingTokens = calculateLiquidityTokenValue(liquidityTokenAmount);

        // assert that enough underlying tokens are available to send to the redeemer
        require(redeemableUnderlyingTokens > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');

        // burn the liquidity tokens
        _burn(address(this), liquidityTokenAmount);

        // transfer the underlying tokens
        IERC20(underlier).safeTransfer(to, _convertToUnderlierDecimal(redeemableUnderlyingTokens));

        // emit burning of LP token event
        emit Mint(to, redeemableUnderlyingTokens, liquidityTokenAmount);
    }

    // ============ Calculate the current pool fee ============

    function _calculateFee() internal view returns (uint256) {

        // the new fee based on updated pool utilization
        uint256 newFee;

        // the fee offered before the utilization inflection is hit  
        // (utilization * rate sensitivity) + rate limit
        int256 preInflectionLeg = int256(utilization.mul(rateSensitivity).div(TEN_EXP_18).add(rateLimit));
     
        // pool utilization is below the inflection
        if (utilization < utilizationInflection) {
            // assert that the leg is positive before converting to uint256
            require(preInflectionLeg > 0);

            newFee = uint256(preInflectionLeg);
        }

        // pool utilization is at or above the inflection
        else {
            // The additional change in the rate after the utilization inflection is hit
            // rate multiplier * (utilization - utilization inflection)
            int256 postInflectionLeg = int256(rateMultiplier.mul(utilization.sub(utilizationInflection)).div(TEN_EXP_18));

            // assert that the addition of the legs is positive before converting to uint256
            require(preInflectionLeg + postInflectionLeg > 0);

            newFee = uint256(preInflectionLeg + postInflectionLeg);
        }

        // adjust the fee value as a percentage
        return newFee.div(100);
    }

    // ============ Calculates the pool utilization ============

    function _calculateUtilization() internal view returns (uint256) {

        // get the total liquidity of this pool
        uint256 totalPoolLiquidity = totalActiveLiquidity.add(totalAvailableLiquidity);

        // pool utilization is the total active liquidity / total pool liquidity
        uint256 newUtilization = totalActiveLiquidity.mul(TEN_EXP_18).div(totalPoolLiquidity);

        // adjust utilization to be an integer between 0 and 100
        uint256 adjustedUtilization = newUtilization * 100;

        return adjustedUtilization;
    }

    // ============ Calculates the swap collateral and active liquidity needed for a given notional ============

    function _calculateSwapCollateralAndActiveLiquidity(uint256 _notional) internal view returns (uint256, uint256) {
        // The maximum rate the user will pay on a swap
        uint256 userMaxRateToPay = direction == 0 ? _calculateMaxVariableRate(adapter0) : _calculateMaxVariableRate(adapter1);

        // the maximum rate the AMM will pay on a swap
        uint256 ammMaxRateToPay = direction == 1 ? _calculateMaxVariableRate(adapter0) : _calculateMaxVariableRate(adapter1);

        // notional * maximum rate to pay * (swap duration in days / days per year)
        uint256 swapCollateral = _calculateMaxAmountToPay(_notional, userMaxRateToPay);
        uint256 activeLiquidity = _calculateMaxAmountToPay(_notional, ammMaxRateToPay);

        return (swapCollateral, activeLiquidity);
    }

    // ============ Calculates the maximum amount to pay over a specific time window with a given notional and rate ============

    function _calculateMaxAmountToPay(uint256 _notional, uint256 _rate) internal view returns (uint256) {
        // the period by which to adjust the rate
        uint256 period = DAYS_PER_YEAR.div(durationInDays);

        // notional * maximum rate to pay / (days per year / swap duration in days)
        return _notional.mul(_rate).div(TEN_EXP_18).div(period);
    }

    // ============ Calculates the maximum variable rate ============

    function _calculateMaxVariableRate(address _adapter) internal view returns (uint256) {

        // use the current variable rate for the underlying token
        uint256 variableRate = IAdapter(_adapter).getBorrowRate(underlier);

        // calculate a variable rate buffer 
        uint256 maxBuffer = MAX_TO_PAY_BUFFER_NUMERATOR.mul(TEN_EXP_18).div(MAX_TO_PAY_BUFFER_DENOMINATOR);
        
        // add the buffer to the current variable rate
        return variableRate.add(maxBuffer);
    }

    // ============ Calculates the interest accrued for both parties on a swap ============

    function _calculateInterestAccrued(Swap memory _swap) internal view returns (uint256, uint256) {
        // the amounts that the user and the AMM will pay on this swap, depending on the direction of the swap
        uint256 userToPay;
        uint256 ammToPay;

        // the fixed interest accrued on this swap
        uint256 protocol0VariableInterestAccrued = _calculateVariableInterestAccrued(_swap.notional, protocol0, _swap.underlierProtocol0BorrowIndex);

        // the variable interest accrued on this swap
        uint256 protocol1VariableInterestAccrued = _calculateVariableInterestAccrued(_swap.notional, protocol1, _swap.underlierProtocol1BorrowIndex);

        // user went long on the variable rate
        if (direction == 0) {
            userToPay = protocol0VariableInterestAccrued;
            ammToPay = protocol1VariableInterestAccrued;
        } 

        // user went short on the variable rate
        else {
            userToPay = protocol1VariableInterestAccrued;
            ammToPay = protocol0VariableInterestAccrued;
        }

        return (userToPay, ammToPay);
    }

    // ============ Calculates the interest accrued on a variable rate ============

    function _calculateVariableInterestAccrued(uint256 _notional, uint256 _protocol, uint256 _openSwapBorrowIndex) internal view returns (uint256) {
        // the adapter to use based on the protocol
        address adapter = _protocol == protocol0 ? adapter0 : adapter1;

        // get the current borrow index of the underlying asset
        uint256 currentBorrowIndex = IAdapter(adapter).getBorrowIndex(underlier);

        // The ratio between the current borrow index and the borrow index at time of open swap
        uint256 indexRatio = currentBorrowIndex.mul(TEN_EXP_18).div(_openSwapBorrowIndex);

        // notional * (current borrow index / borrow index when swap was opened) - notional
        return _notional.mul(indexRatio).div(TEN_EXP_18).sub(_notional);
    }

    // ============ Converts an amount to have the contract standard numfalse,ber of decimals ============

    function _convertToStandardDecimal(uint256 _amount) internal view returns (uint256) {

        // set adjustment direction to false to convert to standard pool decimals
        return _convertToDecimal(_amount, true);
    }


    // ============ Converts an amount to have the underlying token's number of decimals ============

    function _convertToUnderlierDecimal(uint256 _amount) internal view returns (uint256) {

        // set adjustment direction to true to convert to underlier decimals
        return _convertToDecimal(_amount, false);
    }

    // ============ Converts an amount to have a particular number of decimals ============

    
    function _convertToDecimal(uint256 _amount, bool _adjustmentDirection) internal view returns (uint256) {
        // the amount after it has been converted to have the underlier number of decimals
        uint256 convertedAmount;

        // the underlying token has less decimal places
        if (underlierDecimals < STANDARD_DECIMALS) {
            convertedAmount = _adjustmentDirection ? _amount.mul(10 ** decimalDifference) : _amount.div(10 ** decimalDifference);
        }

        // there is no difference in the decimal places
        else {
            convertedAmount = _amount;
        }

        return convertedAmount;
    }

    // ============ Calculates the difference between the underlying decimals and the standard decimals ============

    function _calculatedDecimalDifference(uint256 _x_decimal, uint256 _y_decimal) internal pure returns (uint256) {
        // the difference in decimals
        uint256 difference;

        // the second decimal is greater
        if (_x_decimal < _y_decimal) {
            difference = _y_decimal.sub(_x_decimal);
        }

        return difference;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

interface IPool {
    function openSwap(uint256 _notional) external returns (bool);
    function closeSwap(uint256 _swapNumber) external returns (bool);
    function depositLiquidity(uint256 _liquidityAmount) external returns (bool);
    function withdrawLiquidity(uint256 _liquidityAmount) external returns (bool);
    function liquidate(address _user, uint256 _swapNumber) external returns (bool);
    function calculateVariableInterestAccrued(uint256 _notional, uint256 _protocol, uint256 _borrowIndex) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;


interface IAdapter {
    function getBorrowIndex(address underlier) external view returns (uint256);
    function getBorrowRate(address underlier) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

interface IGreenwoodERC20 {
    function name() external pure returns (string memory); 
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

// ============ Contract information ============

/**
 * @title  Greenwood LP token
 * @notice An LP token for Greenwood Basis Swaps
 * @author Greenwood Labs
 */

 // ============ Imports ============

import '../interfaces/IGreenwoodERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';


contract GreenwoodERC20 is IGreenwoodERC20 {
    // ============ Import usage ============

    using SafeMath for uint256;

    // ============ Immutable storage ============

    string public constant override name = 'Greenwood';
    string public constant override symbol = 'GRN';
    uint256 public constant override decimals = 18;

    // ============ Mutable storage ============

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ============ Events ============

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ============ Constructor ============

    constructor() {}

    // ============ External methods ============

    // ============ Returns the amount of tokens in existence ============
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // ============ Returns the amount of tokens owned by `account` ============

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // ============ Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` ============

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // ============ Sets `amount` as the allowance of `spender` over the caller's tokens ============

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // ============ Moves `amount` tokens from the caller's account to `recipient` ============

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // ============ Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism ============

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, 'GreenwoodERC20: transfer amount exceeds allowance'));
        return true;
    }

    // ============ Internal methods ============

    // ============ Creates `amount` tokens and assigns them to `account`, increasing the total supply ============

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'GreenwoodERC20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);
    }

    // ============ Destroys `amount` tokens from `account`, reducing the total supply ============

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'GreenwoodERC20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'GreenwoodERC20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    // ============ Sets `amount` as the allowance of `spender` over the tokens of the `owner` ============

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'GreenwoodERC20: approve from the zero address');
        require(spender != address(0), 'GreenwoodERC20: approve to the zero address');

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    // ============ Moves tokens `amount` from `sender` to `recipient` ============

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'GreenwoodERC20: transfer from the zero address');
        require(recipient != address(0), 'GreenwoodERC20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'GreenwoodERC20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
}

