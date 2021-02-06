/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

/**
 * Copyright 2017-2020, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "unauthorized");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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
        require(b != 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two numbers, rounding up and truncating the quotient
    */
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return divCeil(a, b, "SafeMath: division by zero");
    }

    /**
    * @dev Integer division of two numbers, rounding up and truncating the quotient
    */
    function divCeil(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);

        if (a == 0) {
            return 0;
        }
        uint256 c = ((a - 1) / b) + 1;

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

    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}

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

/**
 * @dev Library for managing loan sets
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;`.
 *
 */
library EnumerableBytes32Set {

    struct Bytes32Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) index;
        bytes32[] values;
    }

    /**
     * @dev Add an address value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return addBytes32(set, value);
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes an address value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return removeBytes32(set, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function containsAddress(Bytes32Set storage set, address addrvalue)
        internal
        view
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Bytes32Set storage set, uint256 start, uint256 count)
        internal
        view
        returns (bytes32[] memory output)
    {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes32[](end-start);
        for (uint256 i = start; i < end; i++) {
            output[i-start] = set.values[i];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Bytes32Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return set.values[index];
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function getAddress(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (address)
    {
        bytes32 value = set.values[index];
        address addrvalue;
        assembly {
            addrvalue := value
        }
        return addrvalue;
    }
}

contract StakingUpgradeable is Ownable {
    address public implementation;
}

contract StakingState is StakingUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    uint256 public constant initialCirculatingSupply = 1030000000e18 - 889389933e18;
    address internal constant ZERO_ADDRESS = address(0);

    bool public isPaused;

    address public fundsWallet;

    mapping(address => uint256) internal _totalSupplyPerToken;                      // token => value
    mapping(address => mapping(address => uint256)) internal _balancesPerToken;     // token => account => value

    mapping(address => address) public delegate;                                    // user => delegate
    mapping(address => mapping(address => uint256)) public delegatedPerToken;       // token => user => value

    uint256 public bzrxPerTokenStored;
    mapping(address => uint256) public bzrxRewardsPerTokenPaid;                     // user => value
    mapping(address => uint256) public bzrxRewards;                                 // user => value
    mapping(address => uint256) public bzrxVesting;                                 // user => value

    uint256 public stableCoinPerTokenStored;
    mapping(address => uint256) public stableCoinRewardsPerTokenPaid;               // user => value
    mapping(address => uint256) public stableCoinRewards;                           // user => value
    mapping(address => uint256) public stableCoinVesting;                           // user => value

    uint256 public vBZRXWeightStored;
    uint256 public iBZRXWeightStored;
    uint256 public LPTokenWeightStored;

    EnumerableBytes32Set.Bytes32Set internal _delegatedSet;

    uint256 public lastRewardsAddTime;

    mapping(address => uint256) public vestingLastSync;

    mapping(address => address[]) public swapPaths;
    mapping(address => uint256) public stakingRewards;
    uint256 public rewardPercent = 50e18;
    uint256 public maxUniswapDisagreement = 3e18;
    uint256 public maxCurveDisagreement = 3e18;
    uint256 public callerRewardDivisor = 100;

    address[] public currentFeeTokens;
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline)
        external
        returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline)
        external
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline)
        external
        returns (uint256 amountA, uint256 amountB);
}

interface ICurve3Pool {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount)
        external;

    function get_virtual_price()
        external
        view
        returns (uint256);
}

interface IBZxPartial {
    enum FeeClaimType {
        All,
        Lending,
        Trading,
        Borrowing
    }
    
    function withdrawFees(
        address[] calldata tokens,
        address receiver,
        FeeClaimType feeType)
        external
        returns (uint256[] memory amounts);

    function queryFees(
        address[] calldata tokens,
        FeeClaimType feeType)
        external
        view
        returns (uint256[] memory amountsHeld, uint256[] memory amountsPaid);

    function priceFeeds()
        external
        view
        returns (address);
}

contract StakingConstants {

    address public constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address public constant vBZRX = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F;
    address public constant iBZRX = 0x18240BD9C07fA6156Ce3F3f61921cC82b2619157;
    address public constant LPToken = 0xe26A220a341EAca116bDa64cF9D5638A935ae629;
    IERC20 public constant curve3Crv = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IUniswapV2Router public constant uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ICurve3Pool public constant curve3pool = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IBZxPartial public constant bZx = IBZxPartial(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);

    uint256 public constant cliffDuration =                15768000; // 86400 * 365 * 0.5
    uint256 public constant vestingDuration =              126144000; // 86400 * 365 * 4
    uint256 internal constant vestingDurationAfterCliff =  110376000; // 86400 * 365 * 3.5
    uint256 internal constant vestingStartTimestamp =      1594648800; // start_time
    uint256 internal constant vestingCliffTimestamp =      vestingStartTimestamp + cliffDuration;
    uint256 internal constant vestingEndTimestamp =        vestingStartTimestamp + vestingDuration;
    uint256 internal constant _startingVBZRXBalance =      889389933e18; // 889,389,933 BZRX

    uint256 public constant BZRXWeightStored = 1e18;

    struct DelegatedTokens {
        address user;
        uint256 BZRX;
        uint256 vBZRX;
        uint256 iBZRX;
        uint256 LPToken;
        uint256 totalVotes;
    }

    event Stake(
        address indexed user,
        address indexed token,
        address indexed delegate,
        uint256 amount
    );

    event Unstake(
        address indexed user,
        address indexed token,
        address indexed delegate,
        uint256 amount
    );

    event AddRewards(
        address indexed sender,
        uint256 bzrxAmount,
        uint256 stableCoinAmount
    );

    event Claim(
        address indexed user,
        uint256 bzrxAmount,
        uint256 stableCoinAmount
    );

    event ChangeDelegate(
        address indexed user,
        address indexed oldDelegate,
        address indexed newDelegate
    );

    event WithdrawFees(
        address indexed sender
    );

    event ConvertFees(
        address indexed sender,
        uint256 bzrxOutput,
        uint256 stableCoinOutput
    );

    event DistributeFees(
        address indexed sender,
        uint256 bzrxRewards,
        uint256 stableCoinRewards
    );
}

contract IVestingToken is IERC20 {
    function claim()
        external;

    function vestedBalanceOf(
        address _owner)
        external
        view
        returns (uint256);

    function claimedBalanceOf(
        address _owner)
        external
        view
        returns (uint256);

    function totalVested()
        external
        view
        returns (uint256);
}

interface ILoanPool {
    function tokenPrice()
        external
        view
        returns (uint256 price);

    function borrowInterestRate()
        external
        view
        returns (uint256);

    function totalAssetSupply()
        external
        view
        returns (uint256);

    function assetBalanceOf(
        address _owner)
        external
        view
        returns (uint256);
}

interface IPriceFeeds {
    function queryRate(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function amountInEth(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function getFastGasPrice(
        address payToken)
        external
        view
        returns (uint256);
}

contract StakingV1 is StakingState, StakingConstants {

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    modifier checkPause() {
        require(!isPaused, "paused");
        _;
    }

    function stake(
        address[] calldata tokens,
        uint256[] calldata values)
        external
        checkPause
        updateRewards(msg.sender)
    {
        require(tokens.length == values.length, "count mismatch");

        address currentDelegate = delegate[msg.sender];
        if (currentDelegate == address(0)) {
            currentDelegate = msg.sender;
            delegate[msg.sender] = currentDelegate;
            _delegatedSet.addAddress(msg.sender);
        }

        address token;
        uint256 stakeAmount;

        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            require(token == BZRX || token == vBZRX || token == iBZRX || token == LPToken, "invalid token");

            stakeAmount = values[i];
            if (stakeAmount == 0) {
                continue;
            }

            _balancesPerToken[token][msg.sender] = _balancesPerToken[token][msg.sender].add(stakeAmount);
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token].add(stakeAmount);

            delegatedPerToken[currentDelegate][token] = delegatedPerToken[currentDelegate][token]
                .add(stakeAmount);

            IERC20(token).safeTransferFrom(msg.sender, address(this), stakeAmount);

            emit Stake(
                msg.sender,
                token,
                currentDelegate,
                stakeAmount
            );
        }
    }

    function unstake(
        address[] memory tokens,
        uint256[] memory values)
        public
        checkPause
        updateRewards(msg.sender)
    {
        require(tokens.length == values.length, "count mismatch");

        address currentDelegate = delegate[msg.sender];

        address token;
        uint256 unstakeAmount;
        uint256 stakedAmount;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            require(token == BZRX || token == vBZRX || token == iBZRX || token == LPToken, "invalid token");

            unstakeAmount = values[i];
            stakedAmount = _balancesPerToken[token][msg.sender];
            if (unstakeAmount == 0 || stakedAmount == 0) {
                continue;
            }
            if (unstakeAmount > stakedAmount) {
                unstakeAmount = stakedAmount;
            }

            _balancesPerToken[token][msg.sender] = stakedAmount - unstakeAmount; // will not overflow
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token] - unstakeAmount; // will not overflow

            delegatedPerToken[currentDelegate][token] = delegatedPerToken[currentDelegate][token]
                .sub(unstakeAmount);

            if (token == BZRX && IERC20(BZRX).balanceOf(address(this)) < unstakeAmount) {
                // settle vested BZRX only if needed
                IVestingToken(vBZRX).claim();
            }

            IERC20(token).safeTransfer(msg.sender, unstakeAmount);

            emit Unstake(
                msg.sender,
                token,
                currentDelegate,
                unstakeAmount
            );
        }
    }

    /*function changeDelegate(
        address delegateToSet)
        external
        checkPause
    {
        if (delegateToSet == ZERO_ADDRESS) {
            delegateToSet = msg.sender;
        }

        address currentDelegate = delegate[msg.sender];
        if (delegateToSet != currentDelegate) {
            if (currentDelegate != ZERO_ADDRESS) {
                uint256 balance = _balancesPerToken[BZRX][msg.sender];
                if (balance != 0) {
                    delegatedPerToken[currentDelegate][BZRX] = delegatedPerToken[currentDelegate][BZRX]
                        .sub(balance);
                    delegatedPerToken[delegateToSet][BZRX] = delegatedPerToken[delegateToSet][BZRX]
                        .add(balance);
                }

                balance = _balancesPerToken[vBZRX][msg.sender];
                if (balance != 0) {
                    delegatedPerToken[currentDelegate][vBZRX] = delegatedPerToken[currentDelegate][vBZRX]
                        .sub(balance);
                    delegatedPerToken[delegateToSet][vBZRX] = delegatedPerToken[delegateToSet][vBZRX]
                        .add(balance);
                }

                balance = _balancesPerToken[iBZRX][msg.sender];
                if (balance != 0) {
                    delegatedPerToken[currentDelegate][iBZRX] = delegatedPerToken[currentDelegate][iBZRX]
                        .sub(balance);
                    delegatedPerToken[delegateToSet][iBZRX] = delegatedPerToken[delegateToSet][iBZRX]
                        .add(balance);
                }

                balance = _balancesPerToken[LPToken][msg.sender];
                if (balance != 0) {
                    delegatedPerToken[currentDelegate][LPToken] = delegatedPerToken[currentDelegate][LPToken]
                        .sub(balance);
                    delegatedPerToken[delegateToSet][LPToken] = delegatedPerToken[delegateToSet][LPToken]
                        .add(balance);
                }
            }

            delegate[msg.sender] = delegateToSet;
            _delegatedSet.addAddress(delegateToSet);

            emit ChangeDelegate(
                msg.sender,
                currentDelegate,
                delegateToSet
            );

            currentDelegate = delegateToSet;
        }
    }*/

    function claim(
        bool restake)
        external
        checkPause
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        return _claim(restake);
    }

    function claimBzrx()
        external
        checkPause
        returns (uint256 bzrxRewardsEarned)
    {
        bzrxRewardsEarned = _claimBzrx(false);

        emit Claim(
            msg.sender,
            bzrxRewardsEarned,
            0
        );
    }

    function claim3Crv()
        external
        checkPause
        returns (uint256 stableCoinRewardsEarned)
    {
        stableCoinRewardsEarned = _claim3Crv();

        emit Claim(
            msg.sender,
            0,
            stableCoinRewardsEarned
        );
    }

    function _claim(
        bool restake)
        internal
        updateRewards(msg.sender)
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        bzrxRewardsEarned = _claimBzrx(restake);
        stableCoinRewardsEarned = _claim3Crv();

        emit Claim(
            msg.sender,
            bzrxRewardsEarned,
            stableCoinRewardsEarned
        );
    }

    function _claimBzrx(
        bool restake)
        internal
        returns (uint256 bzrxRewardsEarned)
    {
        bzrxRewardsEarned = bzrxRewards[msg.sender];
        if (bzrxRewardsEarned != 0) {
            bzrxRewards[msg.sender] = 0;
            if (restake) {
                _restakeBZRX(
                    msg.sender,
                    bzrxRewardsEarned
                );
            } else {
                if (IERC20(BZRX).balanceOf(address(this)) < bzrxRewardsEarned) {
                    // settle vested BZRX only if needed
                    IVestingToken(vBZRX).claim();
                }

                IERC20(BZRX).transfer(msg.sender, bzrxRewardsEarned);
            }
        }
    }

    function _claim3Crv()
        internal 
        returns (uint256 stableCoinRewardsEarned)
    {
        stableCoinRewardsEarned = stableCoinRewards[msg.sender];
        if (stableCoinRewardsEarned != 0) {
            stableCoinRewards[msg.sender] = 0;
            curve3Crv.transfer(msg.sender, stableCoinRewardsEarned);
        }
    }

    function _restakeBZRX(
        address account,
        uint256 amount)
        internal
    {
        address currentDelegate = delegate[account];
        _balancesPerToken[BZRX][account] = _balancesPerToken[BZRX][account]
            .add(amount);

        _totalSupplyPerToken[BZRX] = _totalSupplyPerToken[BZRX]
            .add(amount);

        delegatedPerToken[currentDelegate][BZRX] = delegatedPerToken[currentDelegate][BZRX]
            .add(amount);

        emit Stake(
            account,
            BZRX,
            currentDelegate,
            amount
        );
    }

    function exit()
        public
        // unstake() does a checkPause
    {
        address[] memory tokens = new address[](4);
        uint256[] memory values = new uint256[](4);
        tokens[0] = iBZRX;
        tokens[1] = LPToken;
        tokens[2] = vBZRX;
        tokens[3] = BZRX;
        values[0] = uint256(-1);
        values[1] = uint256(-1);
        values[2] = uint256(-1);
        values[3] = uint256(-1);
        
        unstake(tokens, values);
        _claim(false);
    }

    /*function getDelegateVotes(
        uint256 start,
        uint256 count)
        external
        view
        returns (DelegatedTokens[] memory delegateArr)
    {
        uint256 end = start.add(count).min256(_delegatedSet.length());
        if (start >= end) {
            return delegateArr;
        }
        count = end-start;

        uint256 idx = count;
        address user;
        delegateArr = new DelegatedTokens[](idx);
        for (uint256 i = --end; i >= start; i--) {
            user = _delegatedSet.getAddress(i);
            delegateArr[count-(idx--)] = DelegatedTokens({
                user: user,
                BZRX: delegatedPerToken[user][BZRX],
                vBZRX: delegatedPerToken[user][vBZRX],
                iBZRX: delegatedPerToken[user][iBZRX],
                LPToken: delegatedPerToken[user][LPToken],
                totalVotes: delegateBalanceOf(user)
            });

            if (i == 0) {
                break;
            }
        }

        if (idx != 0) {
            count -= idx;
            assembly {
                mstore(delegateArr, count)
            }
        }
    }*/

    modifier updateRewards(address account) {
        uint256 _bzrxPerTokenStored = bzrxPerTokenStored;
        uint256 _stableCoinPerTokenStored = stableCoinPerTokenStored;

        (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned, uint256 bzrxRewardsVesting, uint256 stableCoinRewardsVesting) = _earned(
            account,
            _bzrxPerTokenStored,
            _stableCoinPerTokenStored
        );
        bzrxRewardsPerTokenPaid[account] = _bzrxPerTokenStored;
        stableCoinRewardsPerTokenPaid[account] = _stableCoinPerTokenStored;

        // vesting amounts get updated before sync
        bzrxVesting[account] = bzrxRewardsVesting;
        stableCoinVesting[account] = stableCoinRewardsVesting;

        (bzrxRewards[account], stableCoinRewards[account]) = _syncVesting(
            account,
            bzrxRewardsEarned,
            stableCoinRewardsEarned,
            bzrxRewardsVesting,
            stableCoinRewardsVesting
        );
        vestingLastSync[account] = block.timestamp;

        _;
    }

    function earned(
        address account)
        external
        view
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned, uint256 bzrxRewardsVesting, uint256 stableCoinRewardsVesting)
    {
        (bzrxRewardsEarned, stableCoinRewardsEarned, bzrxRewardsVesting, stableCoinRewardsVesting) = _earned(
            account,
            bzrxPerTokenStored,
            stableCoinPerTokenStored
        );

        (bzrxRewardsEarned, stableCoinRewardsEarned) = _syncVesting(
            account,
            bzrxRewardsEarned,
            stableCoinRewardsEarned,
            bzrxRewardsVesting,
            stableCoinRewardsVesting
        );

        // discount vesting amounts for vesting time
        uint256 multiplier = vestedBalanceForAmount(
            1e36,
            0,
            block.timestamp
        );
        bzrxRewardsVesting = bzrxRewardsVesting
            .sub(bzrxRewardsVesting
                .mul(multiplier)
                .div(1e36)
            );
        stableCoinRewardsVesting = stableCoinRewardsVesting
            .sub(stableCoinRewardsVesting
                .mul(multiplier)
                .div(1e36)
            );
    }

    function _earned(
        address account,
        uint256 _bzrxPerToken,
        uint256 _stableCoinPerToken)
        internal
        view
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned, uint256 bzrxRewardsVesting, uint256 stableCoinRewardsVesting)
    {
        uint256 bzrxPerTokenUnpaid = _bzrxPerToken.sub(bzrxRewardsPerTokenPaid[account]);
        uint256 stableCoinPerTokenUnpaid = _stableCoinPerToken.sub(stableCoinRewardsPerTokenPaid[account]);

        bzrxRewardsEarned = bzrxRewards[account];
        stableCoinRewardsEarned = stableCoinRewards[account];
        bzrxRewardsVesting = bzrxVesting[account];
        stableCoinRewardsVesting = stableCoinVesting[account];

        if (bzrxPerTokenUnpaid != 0 || stableCoinPerTokenUnpaid != 0) {
            uint256 value;
            uint256 multiplier;
            uint256 lastSync;

            (uint256 vestedBalance, uint256 vestingBalance) = balanceOfStored(account);

            value = vestedBalance
                .mul(bzrxPerTokenUnpaid);
            value /= 1e36;
            bzrxRewardsEarned = value
                .add(bzrxRewardsEarned);

            value = vestedBalance
                .mul(stableCoinPerTokenUnpaid);
            value /= 1e36;
            stableCoinRewardsEarned = value
                .add(stableCoinRewardsEarned);

            if (vestingBalance != 0 && bzrxPerTokenUnpaid != 0) {
                // add new vesting amount for BZRX
                value = vestingBalance
                    .mul(bzrxPerTokenUnpaid);
                value /= 1e36;
                bzrxRewardsVesting = bzrxRewardsVesting
                    .add(value);

                // true up earned amount to vBZRX vesting schedule
                lastSync = vestingLastSync[account];
                multiplier = vestedBalanceForAmount(
                    1e36,
                    0,
                    lastSync
                );
                value = value
                    .mul(multiplier);
                value /= 1e36;
                bzrxRewardsEarned = bzrxRewardsEarned
                    .add(value);
            }
            if (vestingBalance != 0 && stableCoinPerTokenUnpaid != 0) {
                // add new vesting amount for 3crv
                value = vestingBalance
                    .mul(stableCoinPerTokenUnpaid);
                value /= 1e36;
                stableCoinRewardsVesting = stableCoinRewardsVesting
                    .add(value);

                // true up earned amount to vBZRX vesting schedule
                if (lastSync == 0) {
                    lastSync = vestingLastSync[account];
                    multiplier = vestedBalanceForAmount(
                        1e36,
                        0,
                        lastSync
                    );
                }
                value = value
                    .mul(multiplier);
                value /= 1e36;
                stableCoinRewardsEarned = stableCoinRewardsEarned
                    .add(value);
            }
        }
    }

    function _syncVesting(
        address account,
        uint256 bzrxRewardsEarned,
        uint256 stableCoinRewardsEarned,
        uint256 bzrxRewardsVesting,
        uint256 stableCoinRewardsVesting)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 lastVestingSync = vestingLastSync[account];

        if (lastVestingSync != block.timestamp) {
            uint256 rewardsVested;
            uint256 multiplier = vestedBalanceForAmount(
                1e36,
                lastVestingSync,
                block.timestamp
            );

            if (bzrxRewardsVesting != 0) {
                rewardsVested = bzrxRewardsVesting
                    .mul(multiplier)
                    .div(1e36);
                bzrxRewardsEarned += rewardsVested;
            }

            if (stableCoinRewardsVesting != 0) {
                rewardsVested = stableCoinRewardsVesting
                    .mul(multiplier)
                    .div(1e36);
                stableCoinRewardsEarned += rewardsVested;
            }

            uint256 vBZRXBalance = _balancesPerToken[vBZRX][account];
            if (vBZRXBalance != 0) {
                // add vested BZRX to rewards balance
                rewardsVested = vBZRXBalance
                    .mul(multiplier)
                    .div(1e36);
                bzrxRewardsEarned += rewardsVested;
            }
        }

        return (bzrxRewardsEarned, stableCoinRewardsEarned);
    }

    // note: anyone can contribute rewards to the contract
    function addDirectRewards(
        address[] calldata accounts,
        uint256[] calldata bzrxAmounts,
        uint256[] calldata stableCoinAmounts)
        external
        checkPause
        returns (uint256 bzrxTotal, uint256 stableCoinTotal)
    {
        require(accounts.length == bzrxAmounts.length && accounts.length == stableCoinAmounts.length, "count mismatch");

        for (uint256 i = 0; i < accounts.length; i++) {
            bzrxRewards[accounts[i]] = bzrxRewards[accounts[i]].add(bzrxAmounts[i]);
            bzrxTotal = bzrxTotal.add(bzrxAmounts[i]);
            stableCoinRewards[accounts[i]] = stableCoinRewards[accounts[i]].add(stableCoinAmounts[i]);
            stableCoinTotal = stableCoinTotal.add(stableCoinAmounts[i]);
        }
        if (bzrxTotal != 0) {
            IERC20(BZRX).transferFrom(msg.sender, address(this), bzrxTotal);
        }
        if (stableCoinTotal != 0) {
            curve3Crv.transferFrom(msg.sender, address(this), stableCoinTotal);
        }
    }

    // note: anyone can contribute rewards to the contract
    function addRewards(
        uint256 newBZRX,
        uint256 newStableCoin)
        external
        checkPause
    {
        if (newBZRX != 0 || newStableCoin != 0) {
            _addRewards(newBZRX, newStableCoin);
            if (newBZRX != 0) {
                IERC20(BZRX).transferFrom(msg.sender, address(this), newBZRX);
            }
            if (newStableCoin != 0) {
                curve3Crv.transferFrom(msg.sender, address(this), newStableCoin);
            }
        }
    }

    function _addRewards(
        uint256 newBZRX,
        uint256 newStableCoin)
        internal
    {
        (vBZRXWeightStored, iBZRXWeightStored, LPTokenWeightStored) = getVariableWeights();

        uint256 totalTokens = totalSupplyStored();
        require(totalTokens != 0, "nothing staked");

        bzrxPerTokenStored = newBZRX
            .mul(1e36)
            .div(totalTokens)
            .add(bzrxPerTokenStored);

        stableCoinPerTokenStored = newStableCoin
            .mul(1e36)
            .div(totalTokens)
            .add(stableCoinPerTokenStored);

        lastRewardsAddTime = block.timestamp;

        emit AddRewards(
            msg.sender,
            newBZRX,
            newStableCoin
        );
    }

    function getVariableWeights()
        public
        view
        returns (uint256 vBZRXWeight, uint256 iBZRXWeight, uint256 LPTokenWeight)
    {
        uint256 totalVested = vestedBalanceForAmount(
            _startingVBZRXBalance,
            0,
            block.timestamp
        );

        vBZRXWeight = SafeMath.mul(_startingVBZRXBalance - totalVested, 1e18) // overflow not possible
            .div(_startingVBZRXBalance);

        iBZRXWeight = ILoanPool(iBZRX).tokenPrice();

        uint256 lpTokenSupply = _totalSupplyPerToken[LPToken];
        if (lpTokenSupply != 0) {
            // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked BZRX)
            uint256 normalizedLPTokenSupply = initialCirculatingSupply +
                totalVested -
                _totalSupplyPerToken[BZRX];

            LPTokenWeight = normalizedLPTokenSupply
                .mul(1e18)
                .div(lpTokenSupply);
        }
    }

    function balanceOfByAsset(
        address token,
        address account)
        public
        view
        returns (uint256 balance)
    {
        balance = _balancesPerToken[token][account];
    }

    function balanceOfByAssets(
        address account)
        external
        view
        returns (
            uint256 bzrxBalance,
            uint256 iBZRXBalance,
            uint256 vBZRXBalance,
            uint256 LPTokenBalance
        )
    {
        return (
            balanceOfByAsset(BZRX, account),
            balanceOfByAsset(iBZRX, account),
            balanceOfByAsset(vBZRX, account),
            balanceOfByAsset(LPToken, account)
        );
    }

    function balanceOfStored(
        address account)
        public
        view
        returns (uint256 vestedBalance, uint256 vestingBalance)
    {
        uint256 balance = _balancesPerToken[vBZRX][account];
        if (balance != 0) {
            vestingBalance = _balancesPerToken[vBZRX][account]
                    .mul(vBZRXWeightStored)
                    .div(1e18);
        }

        vestedBalance = _balancesPerToken[BZRX][account];

        balance = _balancesPerToken[iBZRX][account];
        if (balance != 0) {
            vestedBalance = balance
                .mul(iBZRXWeightStored)
                .div(1e18)
                .add(vestedBalance);
        }

        balance = _balancesPerToken[LPToken][account];
        if (balance != 0) {
            vestedBalance = balance
                .mul(LPTokenWeightStored)
                .div(1e18)
                .add(vestedBalance);
        }
    }

    function delegateBalanceOf(
        address account)
        public
        view
        returns (uint256 totalVotes)
    {
        uint256 vBZRXBalance = _balancesPerToken[vBZRX][account];
        if (vBZRXBalance != 0) {
            // staked vBZRX counts has 1/2 a vote, that's prorated based on total vested
            totalVotes = vBZRXBalance
                .mul(_startingVBZRXBalance -
                    vestedBalanceForAmount( // overflow not possible
                        _startingVBZRXBalance,
                        0,
                        block.timestamp
                    )
                ).div(_startingVBZRXBalance) / 2;

            // user is attributed a staked balance of vested BZRX, from their last update to the present
            totalVotes = vestedBalanceForAmount(
                vBZRXBalance,
                vestingLastSync[account],
                block.timestamp
            ).add(totalVotes);
        }

        totalVotes = _balancesPerToken[BZRX][account]
            .add(bzrxRewards[account]) // unclaimed BZRX rewards count as votes
            .add(totalVotes);

        totalVotes = _balancesPerToken[iBZRX][account]
            .mul(ILoanPool(iBZRX).tokenPrice())
            .div(1e18)
            .add(totalVotes);

        // LPToken votes are measured based on amount of underlying BZRX staked
        totalVotes = IERC20(BZRX).balanceOf(LPToken)
            .mul(_balancesPerToken[LPToken][account])
            .div(IERC20(LPToken).totalSupply())
            .add(totalVotes);
    }

    function totalSupplyByAsset(
        address token)
        external
        view
        returns (uint256)
    {
        return _totalSupplyPerToken[token];
    }

    function totalSupplyStored()
        public
        view
        returns (uint256 supply)
    {
        supply = _totalSupplyPerToken[vBZRX]
            .mul(vBZRXWeightStored)
            .div(1e18);

        supply = _totalSupplyPerToken[BZRX]
            .add(supply);

        supply = _totalSupplyPerToken[iBZRX]
            .mul(iBZRXWeightStored)
            .div(1e18)
            .add(supply);

        supply = _totalSupplyPerToken[LPToken]
            .mul(LPTokenWeightStored)
            .div(1e18)
            .add(supply);
    }

    function vestedBalanceForAmount(
        uint256 tokenBalance,
        uint256 lastUpdate,
        uint256 vestingEndTime)
        public
        view
        returns (uint256 vested)
    {
        vestingEndTime = vestingEndTime.min256(block.timestamp);
        if (vestingEndTime > lastUpdate) {
            if (vestingEndTime <= vestingCliffTimestamp ||
                lastUpdate >= vestingEndTimestamp) {
                // time cannot be before vesting starts
                // OR all vested token has already been claimed
                return 0;
            }
            if (lastUpdate < vestingCliffTimestamp) {
                // vesting starts at the cliff timestamp
                lastUpdate = vestingCliffTimestamp;
            }
            if (vestingEndTime > vestingEndTimestamp) {
                // vesting ends at the end timestamp
                vestingEndTime = vestingEndTimestamp;
            }

            uint256 timeSinceClaim = vestingEndTime.sub(lastUpdate);
            vested = tokenBalance.mul(timeSinceClaim) / vestingDurationAfterCliff; // will never divide by 0
        }
    }


    // Fee Conversion Logic //

    function sweepFees()
        public
        // sweepFeesByAsset() does checkPause
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        return sweepFeesByAsset(currentFeeTokens);
    }

    function sweepFeesByAsset(
        address[] memory assets)
        public
        checkPause
        onlyEOA
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        uint256[] memory amounts = _withdrawFees(assets);
        _convertFees(assets, amounts);
        (bzrxRewards, crv3Rewards) = _distributeFees();
    }

    function _withdrawFees(
        address[] memory assets)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory amounts = bZx.withdrawFees(assets, address(this), IBZxPartial.FeeClaimType.All);

        for (uint256 i = 0; i < assets.length; i++) {
            stakingRewards[assets[i]] = stakingRewards[assets[i]]
                .add(amounts[i]);
        }

        emit WithdrawFees(
            msg.sender
        );

        return amounts;
    }

    function _convertFees(
        address[] memory assets,
        uint256[] memory amounts)
        internal
        returns (uint256 bzrxOutput, uint256 crv3Output)
    {
        require(assets.length == amounts.length, "count mismatch");
 
        IPriceFeeds priceFeeds = IPriceFeeds(bZx.priceFeeds());
        (uint256 bzrxRate,) = priceFeeds.queryRate(
            BZRX,
            WETH
        );
        uint256 maxDisagreement = maxUniswapDisagreement;

        address asset;
        uint256 daiAmount;
        uint256 usdcAmount;
        uint256 usdtAmount;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i];
            if (asset == BZRX) {
                continue;
            } else if (asset == DAI) {
                daiAmount = daiAmount.add(amounts[i]);
                continue;
            } else if (asset == USDC) {
                usdcAmount = usdcAmount.add(amounts[i]);
                continue;
            } else if (asset == USDT) {
                usdtAmount = usdtAmount.add(amounts[i]);
                continue;
            }

            if (amounts[i] != 0) {
                bzrxOutput += _convertFeeWithUniswap(asset, amounts[i], priceFeeds, bzrxRate, maxDisagreement);
            }
        }
        if (bzrxOutput != 0) {
            stakingRewards[BZRX] += bzrxOutput;
        }

        if (daiAmount != 0 || usdcAmount != 0 || usdtAmount != 0) {
            crv3Output = _convertFeesWithCurve(
                daiAmount,
                usdcAmount,
                usdtAmount
            );
            stakingRewards[address(curve3Crv)] += crv3Output;
        }

        emit ConvertFees(
            msg.sender,
            bzrxOutput,
            crv3Output
        );
    }

    function _distributeFees()
        internal
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        bzrxRewards = stakingRewards[BZRX];
        crv3Rewards = stakingRewards[address(curve3Crv)];
        if (bzrxRewards != 0 || crv3Rewards != 0) {
            address _fundsWallet = fundsWallet;
            uint256 rewardAmount;
            uint256 callerReward;
            if (bzrxRewards != 0) {
                stakingRewards[BZRX] = 0;

                rewardAmount = bzrxRewards
                    .mul(rewardPercent)
                    .div(1e20);
                IERC20(BZRX).transfer(
                    _fundsWallet,
                    bzrxRewards - rewardAmount
                );
                bzrxRewards = rewardAmount;

                callerReward = bzrxRewards / callerRewardDivisor;
                IERC20(BZRX).transfer(
                    msg.sender,
                    callerReward
                );
                bzrxRewards = bzrxRewards
                    .sub(callerReward);
            }
            if (crv3Rewards != 0) {
                stakingRewards[address(curve3Crv)] = 0;

                rewardAmount = crv3Rewards
                    .mul(rewardPercent)
                    .div(1e20);
                curve3Crv.transfer(
                    _fundsWallet,
                    crv3Rewards - rewardAmount
                );
                crv3Rewards = rewardAmount;

                callerReward = crv3Rewards / callerRewardDivisor;
                curve3Crv.transfer(
                    msg.sender,
                    callerReward
                );
                crv3Rewards = crv3Rewards
                    .sub(callerReward);
            }

            _addRewards(bzrxRewards, crv3Rewards);
        }

        emit DistributeFees(
            msg.sender,
            bzrxRewards,
            crv3Rewards
        );
    }

    function _convertFeeWithUniswap(
        address asset,
        uint256 amount,
        IPriceFeeds priceFeeds,
        uint256 bzrxRate,
        uint256 maxDisagreement)
        internal
        returns (uint256 returnAmount)
    {
        uint256 stakingReward = stakingRewards[asset];
        if (stakingReward != 0) {
            if (amount > stakingReward) {
                amount = stakingReward;
            }
            stakingRewards[asset] = stakingReward
                .sub(amount);

            uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
                amount,
                1, // amountOutMin
                swapPaths[asset],
                address(this),
                block.timestamp
            );

            returnAmount = amounts[amounts.length - 1];

            // will revert if disagreement found
            _checkUniDisagreement(
                asset,
                amount,
                returnAmount,
                priceFeeds,
                bzrxRate,
                maxDisagreement
            );
        }
    }

    function _convertFeesWithCurve(
        uint256 daiAmount,
        uint256 usdcAmount,
        uint256 usdtAmount)
        internal
        returns (uint256 returnAmount)
    {
        uint256[3] memory curveAmounts;
        uint256 curveTotal;
        uint256 stakingReward;

        if (daiAmount != 0) {
            stakingReward = stakingRewards[DAI];
            if (stakingReward != 0) {
                if (daiAmount > stakingReward) {
                    daiAmount = stakingReward;
                }
                stakingRewards[DAI] = stakingReward
                    .sub(daiAmount);
                curveAmounts[0] = daiAmount;
                curveTotal = daiAmount;
            }
        }
        if (usdcAmount != 0) {
            stakingReward = stakingRewards[USDC];
            if (stakingReward != 0) {
                if (usdcAmount > stakingReward) {
                    usdcAmount = stakingReward;
                }
                stakingRewards[USDC] = stakingReward
                    .sub(usdcAmount);
                curveAmounts[1] = usdcAmount;
                curveTotal = curveTotal.add(usdcAmount.mul(1e12)); // normalize to 18 decimals
            }
        }
        if (usdtAmount != 0) {
            stakingReward = stakingRewards[USDT];
            if (stakingReward != 0) {
                if (usdtAmount > stakingReward) {
                    usdtAmount = stakingReward;
                }
                stakingRewards[USDT] = stakingReward
                    .sub(usdtAmount);
                curveAmounts[2] = usdtAmount;
                curveTotal = curveTotal.add(usdtAmount.mul(1e12)); // normalize to 18 decimals
            }
        }

        uint256 beforeBalance = curve3Crv.balanceOf(address(this));
        curve3pool.add_liquidity(curveAmounts, 0);

        returnAmount = curve3Crv.balanceOf(address(this)) - beforeBalance;

        // will revert if disagreement found
        _checkCurveDisagreement(
            curveTotal,
            returnAmount,
            maxCurveDisagreement
        );
    }    

    function _checkUniDisagreement(
        address asset,
        uint256 assetAmount,
        uint256 bzrxAmount,
        IPriceFeeds priceFeeds,
        uint256 bzrxRate,
        uint256 maxDisagreement)
        internal
        view
    {
        (uint256 rate, uint256 precision) = priceFeeds.queryRate(
            asset,
            WETH
        );

        rate = rate
            .mul(1e36)
            .div(precision)
            .div(bzrxRate);

        uint256 sourceToDestSwapRate = bzrxAmount
            .mul(1e18)
            .div(assetAmount);

        uint256 spreadValue = sourceToDestSwapRate > rate ?
            sourceToDestSwapRate - rate :
            rate - sourceToDestSwapRate;

        if (spreadValue != 0) {
            spreadValue = spreadValue
                .mul(1e20)
                .div(sourceToDestSwapRate);

            require(
                spreadValue <= maxDisagreement,
                "uniswap price disagreement"
            );
        }
    }

    function _checkCurveDisagreement(
        uint256 sendAmount, // deposit tokens
        uint256 actualReturn, // returned lp token
        uint256 maxDisagreement)
        internal
        view
    {
        uint256 expectedReturn = sendAmount
            .mul(1e18)
            .div(curve3pool.get_virtual_price());

        uint256 spreadValue = actualReturn > expectedReturn ?
            actualReturn - expectedReturn :
            expectedReturn - actualReturn;

        if (spreadValue != 0) {
            spreadValue = spreadValue
                .mul(1e20)
                .div(actualReturn);

            require(
                spreadValue <= maxDisagreement,
                "curve price disagreement"
            );
        }
    }

    // OnlyOwner functions

    function togglePause(
        bool _isPaused)
        external
        onlyOwner
    {
        isPaused = _isPaused;
    }

    function setFundsWallet(
        address _fundsWallet)
        external
        onlyOwner
    {
        fundsWallet = _fundsWallet;
    }

    function setFeeTokens(
        address[] calldata tokens)
        external
        onlyOwner
    {
        currentFeeTokens = tokens;
    }

    // path should start with the asset to swap and end with BZRX
    // only one path allowed per asset
    // ex: asset -> WETH -> BZRX
    function setPaths(
        address[][] calldata paths)
        external
        onlyOwner
    {
        address[] memory path;
        for (uint256 i = 0; i < paths.length; i++) {
            path = paths[i];
            require(path.length >= 2 &&
                path[0] != path[path.length - 1] &&
                path[path.length - 1] == BZRX,
                "invalid path"
            );
            
            // check that the path exists
            uint256[] memory amountsOut = uniswapRouter.getAmountsOut(1e10, path);
            require(amountsOut[amountsOut.length - 1] != 0, "path does not exist");
            
            swapPaths[path[0]] = path;
            IERC20(path[0]).safeApprove(address(uniswapRouter), 0);
            IERC20(path[0]).safeApprove(address(uniswapRouter), uint256(-1));
        }
    }

    function setCurveApproval()
        external
        onlyOwner
    {
        IERC20(DAI).safeApprove(address(curve3pool), 0);
        IERC20(DAI).safeApprove(address(curve3pool), uint256(-1));
        IERC20(USDC).safeApprove(address(curve3pool), 0);
        IERC20(USDC).safeApprove(address(curve3pool), uint256(-1));
        IERC20(USDT).safeApprove(address(curve3pool), 0);
        IERC20(USDT).safeApprove(address(curve3pool), uint256(-1));
    }

    function setRewardPercent(
        uint256 _rewardPercent)
        external
        onlyOwner
    {
        require(_rewardPercent <= 1e20, "value too high");
        rewardPercent = _rewardPercent;
    }

    function setMaxUniswapDisagreement(
        uint256 _maxUniswapDisagreement)
        external
        onlyOwner
    {
        require(_maxUniswapDisagreement != 0, "invalid param");
        maxUniswapDisagreement = _maxUniswapDisagreement;
    }

    function setMaxCurveDisagreement(
        uint256 _maxCurveDisagreement)
        external
        onlyOwner
    {
        require(_maxCurveDisagreement != 0, "invalid param");
        maxCurveDisagreement = _maxCurveDisagreement;
    }

    function setCallerRewardDivisor(
        uint256 _callerRewardDivisor)
        external
        onlyOwner
    {
        require(_callerRewardDivisor != 0, "invalid param");
        callerRewardDivisor = _callerRewardDivisor;
    }
}