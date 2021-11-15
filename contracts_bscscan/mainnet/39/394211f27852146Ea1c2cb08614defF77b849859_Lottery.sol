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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./interfaces/ITicket.sol";
import "./utils/Testable.sol";

// TODO raname contract before deploying
contract Lottery is Ownable, Initializable, Testable {
    //Libraries
    using SafeERC20 for IERC20;
    using Address for address;

    uint8 constant keyLengthForEachBuy = 11;

    // Enum to represent the status of the lottery
    enum Status {
        NotStarted, // The lottery has not started yet
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The lottery has been closed and the numbers drawn
    }

    // Struct for all the needed info around a lottery
    struct LottoInfo {
        uint256 lotteryId; // ID for lotto
        Status lotteryStatus; // Status for lotto
        uint256 prizePoolInToken; // The amount of a given token for prize money
        uint256 costPerTicket; // Cost per ticket in $ALLOY or $ORI
        uint256[] prizeDistribution; // The distribution for prize money
        uint256 startingTimestamp; // Block timestamp for star of lotto
        uint256 closingTimestamp; // Block timestamp for end of entries
        uint16[] winningNumbers; // The winning numbers
        uint256[] lotteryAmounts; //[totalAmount, firstMatchAmount, secondMatchingAmount, thirdMatchingAmount]
    }

    /* State Variables */
    // Instance of ALLOY or ORI Token (collateral currency for Lottery)
    IERC20 internal token_;
    // Storage for ticket NFT
    ITicket internal ticket_;
    // Storage for the random number generator
    IRandomNumberGenerator internal randomGenerator_;
    // Request ID for random number
    bytes32 internal requestId_;
    // Counter for lottery IDs
    uint256 private lotteryIdCounter_;

    // Lottery size
    uint8 public sizeOfLottery_ = 4;
    //Unclaimed prize
    uint256 public unclaimedPrize_;
    //Precision for pot distribution
    uint256 public constant PRECISION = 1e6;
    //Address for the controller of the Lottery
    address public controller_;
    // Max range for numbers 1 - maxValidRange_
    uint16 public maxValidRange_;
    // settings applied to a new lotto
    uint256 public startingPrize_;
    uint256 public costPerTicket_;
    // The distribution for prize money
    uint256[] public prizeDistribution_;
    // Lottery ID => info
    mapping(uint256 => LottoInfo) internal allLotteries_;
    // issueId => trickyNumber => buyAmountSum
    mapping(uint256 => mapping(uint64 => uint256)) public userBuyAmountSum;
    //Lottery occurs every week by default
    uint256 public defaultDuration_ = 168 hours;

    bool public upgraded_ = false;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event NewBatchMint(address indexed minter, uint256[] ticketIDs, uint16[] numbers, uint256 totalCost);

    event RequestNumbers(uint256 lotteryId, bytes32 requestId);

    event LotterySettingsUpdated(
        uint16 maxValidRange,
        uint256[] prizeDistribution,
        uint256 startingPrize,
        uint256 costPerTicket
    );

    event LotteryOpen(uint256 lotteryId, uint256 ticketSupply);

    event LotteryClose(uint256 lotteryId, uint256 ticketSupply);

    event WinnersDrawn(uint256[] numbers);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    modifier onlyRandomGenerator() {
        require(msg.sender == address(randomGenerator_), "Only random generator");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller_, "Only controller");
        _;
    }

    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier notUpgraded() {
        require(upgraded_ == false, "This contract was upgraded");
        _;
    }

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    /*
     * This constructor code might be in violatin of the proxy standard
     * Openzeppelin defines that an Initializable shall not use the constructor'
     * Will need to test though
     */
    constructor(address _timer) Testable(_timer) {}

    // INITIALIZER
    function initialize(
        address _token,
        address _ticket,
        address _randomNumberGenerator,
        address _controller
    ) external initializer onlyOwner {
        require(
            _ticket != address(0) &&
                _randomNumberGenerator != address(0) &&
                _token != address(0) &&
                _controller != address(0),
            "Contracts cannot be 0 address"
        );
        token_ = IERC20(_token);
        ticket_ = ITicket(_ticket);
        randomGenerator_ = IRandomNumberGenerator(_randomNumberGenerator);
        controller_ = _controller;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    //Get the cost to buy tickkets given a lottery id and number of tickets
    function costToBuyTickets(uint256 _lotteryId, uint256 _numberOfTickets) external view returns (uint256 totalCost) {
        uint256 pricePer = allLotteries_[_lotteryId].costPerTicket;
        totalCost = pricePer * _numberOfTickets; // solidity 0.8 Safemath
    }

    //View basic info about the lotto
    function getBasicLottoInfo(uint256 _lotteryId) external view returns (LottoInfo memory) {
        return (allLotteries_[_lotteryId]);
    }

    function getCurrentLotto() external view returns (LottoInfo memory) {
        require(lotteryIdCounter_ > 0, "no lottery created");
        return allLotteries_[lotteryIdCounter_];
    }

    function getCurrentTotalPrize() public view returns (uint256 totalPrize) {
        totalPrize = token_.balanceOf(address(this)) - unclaimedPrize_;
    }

    function getMaxRange() external view returns (uint16) {
        return maxValidRange_;
    }

    function generateNumberIndexKey(uint16[4] memory numbers) public pure returns (uint64[keyLengthForEachBuy] memory) {
        uint64[4] memory tempNumber;
        tempNumber[0] = uint64(numbers[0]);
        tempNumber[1] = uint64(numbers[1]);
        tempNumber[2] = uint64(numbers[2]);
        tempNumber[3] = uint64(numbers[3]);

        uint64[keyLengthForEachBuy] memory result;
        result[0] =
            tempNumber[0] *
            256 *
            256 *
            256 *
            256 *
            256 *
            256 +
            1 *
            256 *
            256 *
            256 *
            256 *
            256 +
            tempNumber[1] *
            256 *
            256 *
            256 *
            256 +
            2 *
            256 *
            256 *
            256 +
            tempNumber[2] *
            256 *
            256 +
            3 *
            256 +
            tempNumber[3];

        result[1] =
            tempNumber[0] *
            256 *
            256 *
            256 *
            256 +
            1 *
            256 *
            256 *
            256 +
            tempNumber[1] *
            256 *
            256 +
            2 *
            256 +
            tempNumber[2];
        result[2] =
            tempNumber[0] *
            256 *
            256 *
            256 *
            256 +
            1 *
            256 *
            256 *
            256 +
            tempNumber[1] *
            256 *
            256 +
            3 *
            256 +
            tempNumber[3];
        result[3] =
            tempNumber[0] *
            256 *
            256 *
            256 *
            256 +
            2 *
            256 *
            256 *
            256 +
            tempNumber[2] *
            256 *
            256 +
            3 *
            256 +
            tempNumber[3];
        result[4] =
            1 *
            256 *
            256 *
            256 *
            256 *
            256 +
            tempNumber[1] *
            256 *
            256 *
            256 *
            256 +
            2 *
            256 *
            256 *
            256 +
            tempNumber[2] *
            256 *
            256 +
            3 *
            256 +
            tempNumber[3];

        result[5] = tempNumber[0] * 256 * 256 + 1 * 256 + tempNumber[1];
        result[6] = tempNumber[0] * 256 * 256 + 2 * 256 + tempNumber[2];
        result[7] = tempNumber[0] * 256 * 256 + 3 * 256 + tempNumber[3];
        result[8] = 1 * 256 * 256 * 256 + tempNumber[1] * 256 * 256 + 2 * 256 + tempNumber[2];
        result[9] = 1 * 256 * 256 * 256 + tempNumber[1] * 256 * 256 + 3 * 256 + tempNumber[3];
        result[10] = 2 * 256 * 256 * 256 + tempNumber[2] * 256 * 256 + 3 * 256 + tempNumber[3];

        return result;
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyController)

    function autoStartLotto() external onlyController returns (uint256) {
        uint256 startTime;
        uint256 closingTime;
        uint256 currentTime = getCurrentTime();
        if (lotteryIdCounter_ > 0) {
            startTime = allLotteries_[lotteryIdCounter_].closingTimestamp;
            // check if last closing time is too far ago
            startTime = startTime + defaultDuration_ < currentTime ? currentTime : startTime;
        } else {
            startTime = currentTime;
        }

        closingTime = startTime + defaultDuration_;
        return _createNewLotto(startTime, closingTime);
    }

    function manualStartLotto(uint256 _startingTime, uint256 _closingTime) external onlyController returns (uint256) {
        return _createNewLotto(_startingTime, _closingTime);
    }

    //Controller function to draw the winning numbers
    function drawWinningNumbers(uint256 _lotteryId) external onlyController notUpgraded {
        LottoInfo storage _currLotto = allLotteries_[_lotteryId];
        // Checks that the lottery is past the closing block
        require(_currLotto.closingTimestamp <= getCurrentTime(), "Cannot set winning numbers during lottery");
        // Checks lottery numbers have not already been drawn
        require(_currLotto.lotteryStatus == Status.Open, "Lottery State incorrect for draw");
        // Sets lottery status to closed
        _currLotto.lotteryStatus = Status.Closed;
        // Sets prize pool
        _currLotto.prizePoolInToken = getCurrentTotalPrize();
        // Requests a random number from the generator
        requestId_ = randomGenerator_.getRandomNumber(_lotteryId);
        // Emits that random number has been requested
        emit RequestNumbers(_lotteryId, requestId_);
    }

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyOwner)

    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "Contracts cannot be 0 address");
        controller_ = _controller;
    }

    function setTicket(address _ticket) external onlyOwner {
        require(_ticket != address(0), "Contracts cannot be 0 address");
        ticket_ = ITicket(_ticket);
    }

    function upgradeNewLotoContract(address newLottoContract) external onlyOwner {
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus == Status.Completed,
            "Lottery State must be completed into to upgrade"
        );
        require(newLottoContract != address(0), "Invalid contract");
        uint256 _movableAmount = getCurrentTotalPrize();
        upgraded_ = true;
        token_.safeTransfer(newLottoContract, _movableAmount);
    }

    function updateLottoSettings(
        uint16 _maxValidRange,
        uint256[] calldata _prizeDistribution,
        uint256 _costPerTicket,
        uint256 _startingPrize
    ) external onlyOwner {
        require(_costPerTicket != 0, "Cost cannot be 0");
        // Ensuring that prize/pot distribution total is 100%
        uint256 prizeDistributionTotal = 0;
        for (uint256 j = 0; j < _prizeDistribution.length; j++) {
            prizeDistributionTotal = prizeDistributionTotal + uint256(_prizeDistribution[j]);
        }
        require(prizeDistributionTotal == PRECISION, "Prize distribution is not 100%");

        maxValidRange_ = _maxValidRange;
        prizeDistribution_ = _prizeDistribution;
        startingPrize_ = _startingPrize;
        costPerTicket_ = _costPerTicket;

        emit LotterySettingsUpdated(maxValidRange_, prizeDistribution_, startingPrize_, costPerTicket_);
    }

    //Allows owner to change the duration of the Lottery
    function updateDefaultDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "Duration cannot be 0");
        defaultDuration_ = _duration;
    }

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyOwner)

    function numbersDrawn(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    ) external onlyRandomGenerator notUpgraded {
        LottoInfo storage _currLotto = allLotteries_[_lotteryId];
        require(_currLotto.lotteryStatus == Status.Closed, "Draw numbers first");
        if (requestId_ == _requestId) {
            _currLotto.lotteryStatus = Status.Completed;
            _currLotto.winningNumbers = _split(_randomNumber);
            _currLotto.lotteryAmounts = calculateMatchingRewardAmount(_lotteryId);
            uint256 _totalPrize = _currLotto.lotteryAmounts[0];
            if (_totalPrize > 0) {
                _addUnclaimedPrize(_totalPrize);
            }
        }

        emit LotteryClose(_lotteryId, ticket_.getTotalSupply());
    }

    //-------------------------------------------------------------------------
    // General access functions
    //-------------------------------------------------------------------------

    //Access function to buy one or multiple ticket NFTs
    function batchBuyLottoTicket(
        uint256 _lotteryId,
        uint8 _numberOfTickets,
        uint16[] calldata _chosenNumbersForEachTicket
    ) external notContract notUpgraded {
        // Ensuring the lottery is within a valid time
        require(_numberOfTickets <= 25, "Batch buy limit hit, 25");
        require(getCurrentTime() >= allLotteries_[_lotteryId].startingTimestamp, "Invalid time for mint:start");
        require(getCurrentTime() < allLotteries_[_lotteryId].closingTimestamp, "Invalid time for mint:end");
        if (allLotteries_[_lotteryId].lotteryStatus == Status.NotStarted) {
            if (allLotteries_[_lotteryId].startingTimestamp <= getCurrentTime()) {
                allLotteries_[_lotteryId].lotteryStatus = Status.Open;
            }
        }
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Open, "Lottery not in state for mint");
        //Validating that there are enough numbers for the tickets to be purchased
        uint256 numberCheck = _numberOfTickets * sizeOfLottery_;
        require(_chosenNumbersForEachTicket.length == numberCheck, "Invalid chosen numbers");

        uint16[4] memory ticketNumbers;
        for (uint256 i = 0; i < _chosenNumbersForEachTicket.length; i = i + 4) {
            for (uint256 j = 0; j < 4; j++) {
                require(
                    _chosenNumbersForEachTicket[i + j] <= maxValidRange_ && _chosenNumbersForEachTicket[i + j] > 0,
                    "exceed number scope"
                );
                ticketNumbers[j] = _chosenNumbersForEachTicket[i + j];
            }

            uint64[keyLengthForEachBuy] memory numberIndexKey = generateNumberIndexKey(ticketNumbers);
            for (uint256 k = 0; k < keyLengthForEachBuy; k++) {
                userBuyAmountSum[_lotteryId][numberIndexKey[k]] =
                    userBuyAmountSum[_lotteryId][numberIndexKey[k]] +
                    allLotteries_[_lotteryId].costPerTicket;
            }
        }

        // Getting the cost for the token purchase
        uint256 totalCost = this.costToBuyTickets(_lotteryId, _numberOfTickets);
        // Batch mints tickets to user
        uint256[] memory ticketIds = ticket_.batchMint(
            msg.sender,
            _lotteryId,
            _numberOfTickets,
            maxValidRange_,
            _chosenNumbersForEachTicket
        );
        // Emitting event with all information
        emit NewBatchMint(msg.sender, ticketIds, _chosenNumbersForEachTicket, totalCost);
        // Transfers the required ALLOY/ORI to this contract to purchase tickets
        token_.safeTransferFrom(msg.sender, address(this), totalCost);
    }

    //Access function to claim a ticket's reward
    function claimReward(uint256 _lotteryId, uint256 _tokenId) external notContract {
        // Checking the lottery is in a valid time for claiming
        require(allLotteries_[_lotteryId].closingTimestamp <= getCurrentTime(), "Wait till end to claim");
        // Checks the lottery winning numbers are available
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Completed, "Winning Numbers not chosen yet");
        require(ticket_.getOwnerOfTicket(_tokenId) == msg.sender, "Only the owner can claim");
        // Sets the claim of the ticket to true (if claimed, will revert)
        require(ticket_.claimTicket(_tokenId, _lotteryId), "Numbers for ticket invalid");
        // Getting the number of matching tickets
        uint8 matchingNumbers = _getNumberOfMatching(
            ticket_.getTicketNumbers(_tokenId),
            allLotteries_[_lotteryId].winningNumbers
        );
        // Getting the prize amount for those matching tickets
        uint256 prizeAmount = _prizeForMatching(matchingNumbers, _lotteryId);
        // Removing the prize amount from the pool
        allLotteries_[_lotteryId].prizePoolInToken = allLotteries_[_lotteryId].prizePoolInToken - prizeAmount;
        //updating the unclaimed amount
        unclaimedPrize_ = unclaimedPrize_ - prizeAmount;
        // Transfering the user their winnings
        token_.safeTransfer(address(msg.sender), prizeAmount);
    }

    //Batch reward claiming
    function batchClaimRewards(uint256 _lotteryId, uint256[] calldata _tokenIds) external notContract {
        require(_tokenIds.length <= 25, "Batch claim too large");
        // Checking the lottery is in a valid time for claiming
        require(allLotteries_[_lotteryId].closingTimestamp <= getCurrentTime(), "Wait till end to claim");
        // Checks the lottery winning numbers are available
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Completed, "Winning Numbers not chosen yet");
        // Creates a storage for all winnings
        uint256 totalPrize = 0;
        // Loops through each submitted token
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Checks user is owner (will revert entire call if not)
            require(ticket_.getOwnerOfTicket(_tokenIds[i]) == msg.sender, "Only the owner can claim");
            // If token has already been claimed, skip token
            if (ticket_.getTicketClaimStatus(_tokenIds[i])) {
                continue;
            }
            // Claims the ticket (will only revert if numbers invalid)
            require(ticket_.claimTicket(_tokenIds[i], _lotteryId), "Numbers for ticket invalid");
            // Getting the number of matching tickets
            uint8 matchingNumbers = _getNumberOfMatching(
                ticket_.getTicketNumbers(_tokenIds[i]),
                allLotteries_[_lotteryId].winningNumbers
            );
            // Getting the prize amount for those matching tickets
            uint256 prizeAmount = _prizeForMatching(matchingNumbers, _lotteryId);
            // Removing the prize amount from the pool
            allLotteries_[_lotteryId].prizePoolInToken = allLotteries_[_lotteryId].prizePoolInToken - prizeAmount;
            totalPrize = totalPrize + prizeAmount;
        }
        //updating the unclaimed amount
        unclaimedPrize_ = unclaimedPrize_ - totalPrize;
        // Transferring the user their winnings
        token_.safeTransfer(address(msg.sender), totalPrize);
    }

    function _createNewLotto(uint256 _startingTimestamp, uint256 _closingTimestamp)
        internal
        notUpgraded
        returns (uint256 lotteryId)
    {
        require(_startingTimestamp != 0 && _startingTimestamp < _closingTimestamp, "Timestamps for lottery invalid");
        require(
            lotteryIdCounter_ == 0 || allLotteries_[lotteryIdCounter_].lotteryStatus == Status.Completed,
            "current lottery is not completed"
        );
        // Incrementing lottery ID
        lotteryIdCounter_ = lotteryIdCounter_ + 1;
        lotteryId = lotteryIdCounter_;
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_);
        uint256[] memory lotteryAmounts = new uint256[](sizeOfLottery_);
        Status lotteryStatus;
        if (_startingTimestamp > getCurrentTime()) {
            lotteryStatus = Status.NotStarted;
        } else {
            lotteryStatus = Status.Open;
        }

        // Saving data in struct
        LottoInfo memory newLottery = LottoInfo(
            lotteryId,
            lotteryStatus,
            startingPrize_,
            costPerTicket_,
            prizeDistribution_,
            _startingTimestamp,
            _closingTimestamp,
            winningNumbers,
            lotteryAmounts
        );
        allLotteries_[lotteryId] = newLottery;

        // Emitting important information around new lottery.
        emit LotteryOpen(lotteryId, ticket_.getTotalSupply());
    }

    //Owner function to withdraw ALLOW/ORI from the contract
    function withdrawToken(uint256 _amount) external onlyOwner {
        token_.transfer(msg.sender, _amount);
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    /*
     * Return the number of matching numbers given the user numbers and the winning Numbers
     * Matching is done in order, ie [1,2,3,4] is not a match for [4,3,2,1]
     * [1, 9, 3, 4] matches 3 numbers
     * [1, 9, 9, 4] matches 2 numbers
     */
    function _getNumberOfMatching(uint16[] memory _usersNumbers, uint16[] memory _winningNumbers)
        internal
        pure
        returns (uint8 noOfMatching)
    {
        // Loops through all winning numbers
        for (uint256 i = 0; i < _winningNumbers.length; i++) {
            // If the winning numbers and user numbers match
            if (_usersNumbers[i] == _winningNumbers[i]) {
                // The number of matching numbers incrases
                noOfMatching += 1;
            }
        }
    }

    function _prizeForMatching(uint8 _noOfMatching, uint256 _lotteryId) internal view returns (uint256 prize) {
        //If user matching number is not >=2 their prize is 0
        if (_noOfMatching == 0 || _noOfMatching == 1) {
            return 0;
        }
        LottoInfo storage _currLotto = allLotteries_[_lotteryId];
        // Getting the percentage of the pool the user has won
        uint256 perOfPool = _currLotto.prizeDistribution[_noOfMatching - 1];
        //getting number of winners
        uint256 numberOfWinners = _currLotto.lotteryAmounts[5 - _noOfMatching] / _currLotto.costPerTicket;
        //total prize
        uint256 prizePool = _currLotto.lotteryAmounts[0];
        // Timesing the percentage won by the pool
        prize = prizePool * perOfPool;
        if (numberOfWinners > 0) {
            prize = (prizePool * perOfPool * (PRECISION)) / numberOfWinners / (PRECISION**2);
        }
    }

    function _addUnclaimedPrize(uint256 amount) internal {
        unclaimedPrize_ = unclaimedPrize_ + amount;
    }

    function _split(uint256 _randomNumber) internal view returns (uint16[] memory) {
        // Temparary storage for winning numbers
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_);
        // Loops the size of the number of tickets in the lottery
        for (uint256 i = 0; i < sizeOfLottery_; i++) {
            // Encodes the random number with its position in loop
            bytes32 hashOfRandom = keccak256(abi.encodePacked(_randomNumber, i));
            // Casts random number hash into uint256
            uint256 numberRepresentation = uint256(hashOfRandom);
            // Sets the winning number position to a uint16 of random hash number
            winningNumbers[i] = uint16(numberRepresentation % maxValidRange_);
        }
        return winningNumbers;
    }

    function calculateMatchingRewardAmount(uint256 _lotteryId) internal view returns (uint256[4] memory) {
        uint16[4] memory winningNumbers;
        for (uint256 i = 0; i < allLotteries_[_lotteryId].winningNumbers.length; i++) {
            winningNumbers[i] = allLotteries_[_lotteryId].winningNumbers[i];
        }
        uint64[keyLengthForEachBuy] memory numberIndexKey = generateNumberIndexKey(winningNumbers);

        uint256 totalAmout1 = userBuyAmountSum[_lotteryId][numberIndexKey[0]];

        uint256 sumForTotalAmout2 = userBuyAmountSum[_lotteryId][numberIndexKey[1]];
        sumForTotalAmout2 = sumForTotalAmout2 + userBuyAmountSum[_lotteryId][numberIndexKey[2]];
        sumForTotalAmout2 = sumForTotalAmout2 + userBuyAmountSum[_lotteryId][numberIndexKey[3]];
        sumForTotalAmout2 = sumForTotalAmout2 + userBuyAmountSum[_lotteryId][numberIndexKey[4]];

        uint256 totalAmout2 = sumForTotalAmout2 - (totalAmout1 * 4);

        uint256 sumForTotalAmout3 = userBuyAmountSum[_lotteryId][numberIndexKey[5]];
        sumForTotalAmout3 = sumForTotalAmout3 + userBuyAmountSum[_lotteryId][numberIndexKey[6]];
        sumForTotalAmout3 = sumForTotalAmout3 + userBuyAmountSum[_lotteryId][numberIndexKey[7]];
        sumForTotalAmout3 = sumForTotalAmout3 + userBuyAmountSum[_lotteryId][numberIndexKey[8]];
        sumForTotalAmout3 = sumForTotalAmout3 + userBuyAmountSum[_lotteryId][numberIndexKey[9]];
        sumForTotalAmout3 = sumForTotalAmout3 + userBuyAmountSum[_lotteryId][numberIndexKey[10]];

        uint256 totalAmout3 = sumForTotalAmout3 + (totalAmout1 * 6) - (sumForTotalAmout2 * 3);

        return [allLotteries_[_lotteryId].prizePoolInToken, totalAmout1, totalAmout2, totalAmout3];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRandomNumberGenerator {

    function getRandomNumber(
        uint256 lotteryId
    ) 
        external 
        returns (bytes32 requestId);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface ITicket {
    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns(uint256);

    function getTicketNumbers(uint256 _ticketID) external view returns(uint16[] memory);

    function getOwnerOfTicket(uint256 _ticketID) external view returns(address);

    function getTicketClaimStatus(uint256 _ticketID) external view returns(bool);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function batchMint(
        address _to, 
        uint256 _lottoID, 
        uint8 _numberOfTickets, 
        uint16 _maxValidRange,
        uint16[] calldata _numbers
    ) external returns (uint256[] memory);

    function claimTicket(uint256 _ticketId, uint256 _lotteryId) external returns(bool);

}

//SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 <= 0.8.4;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 <= 0.8.4;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() {
        currentTime = block.timestamp; 
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

