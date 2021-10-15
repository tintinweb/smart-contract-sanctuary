/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function mint(address, uint256) external;

    function burn(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// om gan ganpate namah

interface RandomNumberGenerator {
    function getRandomNumber() external returns (bytes32 requestId);

    function randomResult() external returns (uint256);

    function expand(uint256 randomValue, uint256 n)
        external
        pure
        returns (uint256[] memory expandedValues);
}

interface IERC1155 {
    function addNewNFT(uint256 initialSupply, string memory uri) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

contract Lottery is Ownable, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using Counters for Counters.Counter;
    // state variables
    // Instance of our x22 token
    IERC20 internal _x22;
    // instance of RandomNumberGenerator
    RandomNumberGenerator internal _randomGenerator;
    // keeping lotteryIdCount
    // Counters.Counter private _lotteryIdCounter;
    // instance of NFT contract
    uint256 public LotteryStart;
    // Events
    event LotteryCreated(uint256 lotteryId);
    event TicketPurchased(
        address buyer,
        uint256 lotteryId,
        uint256 price,
        uint256 Tickets,
        string ticketType
    );
    event AmountWithdrawn(uint256 amount);
    event WinnerRewarded(address user);
    event RandomNumber(uint256 value, uint256 round, uint256 price, bool NFT);
    event Lotterycanceled(address owner, bool iscanceld);
    // event randomString(bytes32 value);
    // event requestNumber(bytes32 requestId);
    event WinningAmount(uint256 amount);
    enum Status {
        NotStarted, // the lottery hasn't started yet
        Open, // the lottery is open for ticket purchases
        Closed, // the lottery is no longer open for ticket purchases
        Completed // the lottery has been closed and winners are declared
    }
    // Info about a lottery
    struct LotteryInfo {
        uint256 lotteryId;
        Status lotteryStatus;
        uint256 costPerTicket;
        string[] nftlinks;
        uint256[] nftQuantity;
        uint8[] prizeDistribution; // 5, 0, 0
        uint256 startingTimestamp;
        uint256 closingTimestamp;
        uint256 minTicketsToBuy;
    }
    // lotteryId to LotteryInfo
    mapping(uint256 => LotteryInfo) allLotteries;
    // lotteryId => ticketsSold
    mapping(uint256 => uint256) public ticketsSold;
    // lotteryId => prizePool
    mapping(uint256 => uint256) public prizePool;
    // lotteryId => winners
    mapping(uint256 => address[]) public winnersList;
    //Amount of X22 transfered to contract from buytickets for every lottery

    mapping(uint256=>mapping(address => uint256[])) private lotteryOfAddress;

    struct TicketInfo {
        address owner;
        uint256 ticketNumber;
        uint256 lotteryId;
    }
    // tokenId => tokenInformation
    mapping(uint256 => TicketInfo) internal _allTickets;
    // User Address => lotteryId => ticket IDs
    mapping(address => mapping(uint256 => uint256[])) public userTickets;
    // lotteryId to tickets corresponding that lottery
    mapping(uint256 => uint256[]) public ticketsToALottery;
    // Storing the data if user contains the 4play NFT
    // address of user => contains the nft or not
    mapping(address => bool) public containsNFT;
    // lotteryId => ticketId => owner
    mapping(uint256 => mapping(uint256 => address)) public lotteryTicketOwner;
    //requests for extra benefits on buying of tickes
    // lotteryId => address of any user => how much token requested
    mapping(uint256 => mapping(address => uint256)) public requests;

    address[] private requesters;

    uint256 private _lotteryIdCounter;
    uint256 public lotteryId;
    uint256 private _ticketIdCounter;
    uint256 public timesTicket = 200;

    constructor(address x22, address randomGenerator) {
        _x22 = IERC20(x22);
        _randomGenerator = RandomNumberGenerator(randomGenerator);
    }

    function createNewLottery(
        uint8[] calldata _prizeDistribution,
        string[] calldata _nftlinks,
        uint256[] calldata _nftQuantity,
        uint256 _costPerTicket,
        uint256 _minTicketsToBuy,
        uint256 _closingTimestamp
    ) external onlyOwner {
        // checking for starting time is strictly greater than current time
        if (_lotteryIdCounter == 0) {
            _ticketIdCounter = 0;
        } else {
            require(
                allLotteries[_lotteryIdCounter].lotteryStatus ==
                    Status.Completed,
                "Past lottery is still in progress, you can't create New!"
            );
            _ticketIdCounter = 0;
        }
        require(_costPerTicket != 0, "cost cannot be zero");
        require(
            LotteryStart != 0 &&
                LotteryStart < _closingTimestamp &&
                LotteryStart > block.timestamp,
            "Timestamps for lottery Invalid"
        );
        require(_nftlinks.length == 3, "NFTs ID Invalid");
        require(_nftQuantity.length == 3, "NFT Quantity is Invalid");
        require(_prizeDistribution.length == 3, "Prize Distribution Invalid");
        require(
            _minTicketsToBuy >= 3,
            "Min tickets to purchase should be more than or equal to No. of winners!"
        );
        uint256 prizeDistributionTotal = 0;
        for (uint256 i = 0; i < _prizeDistribution.length; i++) {
            prizeDistributionTotal = prizeDistributionTotal.add(
                uint256(_prizeDistribution[i])
            );
        }
        require(prizeDistributionTotal < 100, "Total Prize is above 100");

        // counter for lottery IDs
        _lotteryIdCounter += 1;
        lotteryId = _lotteryIdCounter;
        Status lotteryStatus;
        lotteryStatus = Status.NotStarted;
        // saving data in struct
        allLotteries[lotteryId].lotteryId = lotteryId;
        allLotteries[lotteryId].lotteryStatus = lotteryStatus;
        allLotteries[lotteryId].costPerTicket = _costPerTicket;
        for (uint8 i = 0; i < 3; i++) {
            allLotteries[lotteryId].nftlinks.push(_nftlinks[i]);
        }
        allLotteries[lotteryId].nftQuantity = _nftQuantity;
        allLotteries[lotteryId].prizeDistribution = _prizeDistribution;
        allLotteries[lotteryId].startingTimestamp = LotteryStart;
        allLotteries[lotteryId].closingTimestamp = _closingTimestamp;
        allLotteries[lotteryId].minTicketsToBuy = _minTicketsToBuy;
        // setting ticketIdCounter to 0
        _ticketIdCounter = 0;
        emit LotteryCreated(lotteryId);
    }

    // withdrawing x22 by the treasury
    function withdrawx22(uint256 _amount) external onlyOwner {
        _x22.transfer(msg.sender, _amount);
        emit AmountWithdrawn(_amount);
    }

    function costToBuyTickets(uint256 _lotteryId, uint256 _numberOfTickets)
        public
        view
        returns (uint256 totalCost)
    {
        uint256 costPerTicket = allLotteries[_lotteryId].costPerTicket;
        totalCost = costPerTicket.mul(_numberOfTickets);
    }

    function buyTickets(
        uint256 _lotteryId,
        uint256 _numberOfTickets,
        bool _benefits
    ) external {
        // Ensure valid timings for the lottery
        require(
            block.timestamp >= allLotteries[_lotteryId].startingTimestamp,
            "Invalid time to start"
        );
        require(
            block.timestamp < allLotteries[_lotteryId].closingTimestamp,
            "Invalid time: lottery time up"
        );

        if (allLotteries[_lotteryId].lotteryStatus == Status.NotStarted) {
            allLotteries[_lotteryId].lotteryStatus = Status.Open;
        }
        require(
            allLotteries[_lotteryId].lotteryStatus == Status.Open,
            "lottery not in open state"
        );
        require(_numberOfTickets != 0, "Enter non-zero number");

        uint256 totalCost = costToBuyTickets(_lotteryId, _numberOfTickets);

        // transfer the amount in x22 to this contract
        _x22.transferFrom(msg.sender, address(this), totalCost);

        // calculate current tickets sold,
        //
        // assign the ticket number
        // User Address => lotteryId => ticket IDs
        if (_ticketIdCounter == 0) {
            _ticketIdCounter++;
        }

        for (uint256 i = 0; i < _numberOfTickets; i++) {
            TicketInfo memory newTicket = TicketInfo(
                msg.sender,
                _ticketIdCounter,
                _lotteryId
            );
            _allTickets[_ticketIdCounter] = newTicket;
            userTickets[msg.sender][_lotteryId].push(_ticketIdCounter);
            ticketsToALottery[_lotteryId].push(_ticketIdCounter);
            lotteryTicketOwner[_lotteryId][_ticketIdCounter] = msg.sender;
            lotteryOfAddress[_lotteryId][msg.sender].push(_ticketIdCounter);
            _ticketIdCounter++;
        }
        // updating total number of ticketsSold for the lotteryId
        ticketsSold[_lotteryId] = ticketsSold[_lotteryId].add(_numberOfTickets);

        // updating prizePool for the lotteryId
        prizePool[_lotteryId] = prizePool[_lotteryId].add(totalCost);

        // posting user's request for extra benefits
        if (_benefits == true) {
            if (!(requests[_lotteryId][msg.sender] > 0)) {
                requesters.push(msg.sender);
            }
            requests[_lotteryId][msg.sender] = requests[_lotteryId][msg.sender]
                .add((_numberOfTickets.mul(timesTicket)).div(100));
        }
        emit TicketPurchased(
            msg.sender,
            _lotteryId,
            totalCost,
            _numberOfTickets,
            "Bought"
        );
    }

    function drawWinners(uint256 _lotteryId) external onlyOwner {
        // check for lottery status and timestamps
        // firstly the status of lottery must be open, then we update the status to be closed,
        // After awarding the winners, update lotteryStatus to be Closed
        require(
            allLotteries[_lotteryId].lotteryStatus == Status.Open,
            "Lottery status is not open"
        );
        require(
            allLotteries[_lotteryId].closingTimestamp <= block.timestamp,
            "Lottery time is not up!"
        );

        if (allLotteries[_lotteryId].lotteryStatus == Status.Open) {
            allLotteries[_lotteryId].lotteryStatus = Status.Closed;
        }
        // require(allLotteries[_lotteryId].lotteryStatus == Status.Closed, "Lottery is not closed, cant drow winners");

        if (
            ticketsSold[_lotteryId] < allLotteries[_lotteryId].minTicketsToBuy
        ) {
            // cancelling the lottery and sending tokens back to buyers
            uint256 totalTickets = ticketsSold[_lotteryId];
            uint256 amount = allLotteries[_lotteryId].costPerTicket;

            for (uint256 i = 0; i < totalTickets; i++) {
                // user to transfer amount back, the amount
                uint256 ticketId = i.add(1);
                address user = lotteryTicketOwner[_lotteryId][ticketId];
                // transfer the money
                _x22.transfer(user, amount);
            }
            allLotteries[_lotteryId].lotteryStatus = Status.Completed;
        }
        // check if ticketsSold is more than the minLimitToBuy
        // require(ticketsSold[_lotteryId] >= allLotteries[_lotteryId].minTicketsToBuy, "Minimum Number of Tickets not sold, lottery is being cancelled!");
        // if ticketsSold is less, than transfer the x22 amounts to those buyers
        // else, draw winners and transfer winning amounts to them
        _randomGenerator.getRandomNumber();
        uint256 index = _randomGenerator.randomResult();
        uint256[] memory AllIndex = _randomGenerator.expand(index, 3);
        for (uint256 i = 0; i < 3; i++) {
            AllIndex[i] = AllIndex[i].mod(ticketsSold[_lotteryId]);
            AllIndex[i]++;
            uint256 price = allLotteries[_lotteryId].prizeDistribution[i];
            bool isNFT = keccak256(
                bytes(allLotteries[_lotteryId].nftlinks[i])
            ) != keccak256(bytes(""))
                ? true
                : false;
            emit RandomNumber(AllIndex[i], lotteryId, price, isNFT);
            winnersList[_lotteryId].push(
                lotteryTicketOwner[_lotteryId][AllIndex[i]]
            );
        }
        // draw three winning numbers
        uint256 balance = _x22.balanceOf(address(this));
        for (uint256 i = 0; i < 3; i++) {
            address user = winnersList[_lotteryId][i];
            uint256 amount = balance
                .mul(allLotteries[_lotteryId].prizeDistribution[i])
                .div(100);
            if (amount > 0) {
                _x22.transfer(user, amount);
            }
        }

        allLotteries[_lotteryId].lotteryStatus = Status.Completed;
    }

    function setLotteryTiming(uint256 _time) external onlyOwner {
        require(
            _time > block.timestamp,
            "Start timestamp for lottery is not valid!"
        );
        LotteryStart = _time;
    }

    function fullFillRequests() external onlyOwner {
        uint256 totalTickets;
        for (uint256 i = 0; i < requesters.length; i++) {
            address temp = requesters[i];
            if (containsNFT[temp] == true) {
                uint256 _numberOfTickets = requests[lotteryId][temp];
                for (uint256 j = 0; j < _numberOfTickets; j++) {
                    TicketInfo memory newTicket = TicketInfo(
                        msg.sender,
                        _ticketIdCounter,
                        lotteryId
                    );
                    _allTickets[_ticketIdCounter] = newTicket;
                    userTickets[msg.sender][lotteryId].push(_ticketIdCounter);
                    ticketsToALottery[lotteryId].push(_ticketIdCounter);
                    lotteryTicketOwner[lotteryId][_ticketIdCounter] = msg
                        .sender;
                    _ticketIdCounter++;
                }
                totalTickets = totalTickets.add(_numberOfTickets);
                delete containsNFT[temp];
                emit TicketPurchased(
                    temp,
                    lotteryId,
                    0,
                    _numberOfTickets,
                    "Benefit"
                );
            }
        }

        // updating total number of ticketsSold for the lotteryId
        ticketsSold[lotteryId] = ticketsSold[lotteryId].add(totalTickets);
    }

    function cancel() external onlyOwner {
        require(
            (allLotteries[lotteryId].startingTimestamp > block.timestamp) ||
                (allLotteries[lotteryId].closingTimestamp < block.timestamp),
            "The lottery is started but not finished yet you can not cancel it!"
        );
        if (allLotteries[lotteryId].closingTimestamp < block.timestamp) {
            require(
                ticketsSold[lotteryId] == 0,
                "Users bought tickets so you are not able to cancel the lottery!"
            );
        }
        delete (allLotteries[lotteryId]);
        _lotteryIdCounter--;
        lotteryId = _lotteryIdCounter;
        emit Lotterycanceled(msg.sender, true);
    }

    function fetchLottery(uint256 _LotteryId)
        external
        view
        returns (LotteryInfo memory info)
    {
        return (allLotteries[_LotteryId]);
    }

    function SaveNFTContainers(address[] memory user) external onlyOwner {
        for (uint256 i = 0; i < user.length; i++) {
            containsNFT[user[i]] = true;
        }
    }

    function fetchRequesters() external view returns (address[] memory) {
        return requesters;
    }

    function ChangeBenefits(uint256 _timesTicket) external onlyOwner {
        // give the timesTicket mutiplied by 100 like if 3 then 300
        timesTicket = _timesTicket;
    }

    function FectchTicketOfAddress(uint256 _lotteryId,address user)
        external
        view
        returns (uint256[] memory)
    {
        return lotteryOfAddress[_lotteryId][user];
    }
}