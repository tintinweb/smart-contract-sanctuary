//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ITaxService.sol";
import "./interfaces/IERC20Burnable.sol";

contract TaxService is Ownable, ITaxService, Initializable {
    using SafeERC20 for IERC20Burnable;

    address public titan_;
    address public lottery_;
    address public prizeReservePool_;

    uint256 public reservePoolRatio_ = 300000; // 30%
    uint256 public burnTitanPoolRatio_ = 700000; // 70%

    uint256 private constant PRECISION = 1e6;

    function initialize(
        address _titan,
        address _lottery,
        address _prizeReservePool
    ) external initializer onlyOwner() {
        require(
            _titan != address(0) && _lottery != address(0) && _prizeReservePool != address(0),
            "Contracts cannot be 0 address"
        );
        titan_ = _titan;
        lottery_ = _lottery;
        prizeReservePool_ = _prizeReservePool;
    }

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    /**
     * @notice  Restricts to only the lottery contract.
     */
    modifier onlyLottery() {
        require(address(msg.sender) == lottery_, "Caller is not the lottery");
        _;
    }

    //==============================
    // STATE MODIFYING FUNCTIONS
    //==============================

    function setPrizeReservePool(address _prizeReservePool) external onlyOwner {
        require(_prizeReservePool != address(0), "Contracts cannot be 0 address");
        prizeReservePool_ = _prizeReservePool;
    }

    function setLottery(address _lottery) external onlyOwner {
        lottery_ = _lottery;
    }

    function setDistribution(uint256 _reservePoolRatio, uint256 _burnTitanPoolRatio) external onlyOwner {
        reservePoolRatio_ = _reservePoolRatio;
        burnTitanPoolRatio_ = _burnTitanPoolRatio;
    }

    function collect(uint256 amount) external override onlyLottery {
        uint256 _totalRatio = burnTitanPoolRatio_ + reservePoolRatio_;
        uint256 _burnTitanAmount = (amount * burnTitanPoolRatio_) / _totalRatio;
        uint256 _prizeReserve = amount - _burnTitanAmount;

        IERC20Burnable _titan = IERC20Burnable(titan_);
        _titan.safeTransferFrom(lottery_, address(this), amount);

        if (_prizeReserve > 0) {
            _titan.safeTransfer(prizeReservePool_, _prizeReserve);
        }

        if (_burnTitanAmount > 0) {
            _titan.burn(_burnTitanAmount);
        }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITaxService {
    /**
     * collect iron
     * @param amount amount of IRON
     */
    function collect(uint256 amount) external;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./interfaces/ITicket.sol";
import "./utils/Testable.sol";
import "./interfaces/ITaxService.sol";
import "./interfaces/IPrizeReservePool.sol";

contract Lottery is Ownable, Initializable, Testable {
    // using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Represents the status of the lottery
    enum Status {
        NotStarted, // The lottery has not started yet
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The numbers drawn
    }

    // All the needed info around a lottery
    struct LottoInfo {
        uint256 lotteryID; // ID for lotto
        Status lotteryStatus; // Status for lotto
        uint256 prizePool; // The amount of TITAN for prize money
        uint256 costPerTicket; // Cost per ticket in $TITAN
        uint256[] prizeDistribution; // The distribution for prize money
        uint256 startingTimestamp; // Block timestamp for star of lotto
        uint256 closingTimestamp; // Block timestamp for end of entries
        uint16[] winningNumbers; // The winning numbers
        uint256[] winners; // the winners of each prize
    }

    // State variables
    // Instance of TITAN token (collateral currency for lotto)
    IERC20 internal titan_;
    // Storing of the NFT
    ITicket internal ticket_;

    // Random number generator
    // Storing of the randomness generator
    IRandomNumberGenerator internal randomGenerator_;
    // Instance of TaxCollection
    ITaxService internal taxService_;
    // Request ID for random number
    bytes32 internal requestId_;

    // Counter for lottery IDs
    uint256 private lotteryIdCounter_;

    // These stated is fixed due to technical implementation
    // Lottery size, power number not included
    uint8 public constant sizeOfLottery_ = 4;
    // support 2 numbers match, if require 3 numbers match, use value of 5
    // uint8 public constant sizeOfIndex_ = 5;

    // precision for all distribution
    uint256 public constant PRECISION = 1e6;
    uint256 public unclaimedPrize_;
    address public controller_;
    address public zap_;

    // Max range for numbers (starting at 0)
    uint16 public maxValidRange_;
    uint16 public powerBallRange_;

    // settings for lotto, will be applied to newly created lotto
    uint256 public startingPrize_;
    uint256 public costPerTicket_; // Cost per ticket in $TITAN

    // The distribution for prize money, highest first
    uint256[] public prizeDistribution_;

    uint256 public taxRate_;
    address public prizeReservePool_;

    // Lottery ID's to info
    mapping(uint256 => LottoInfo) internal allLotteries_;

    bool public upgraded_ = false;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event NewBatchMint(address indexed minter, uint256[] ticketIDs, uint16[] numbers, uint256 pricePaid);

    event RequestNumbers(uint256 lotteryId, bytes32 requestId);

    event LotterySettingsUpdated(
        uint16 maxValidRange,
        uint16 powerBallRange,
        uint256[] prizeDistribution,
        uint256 startingPrize,
        uint256 costPerTicket
    );

    event LotteryOpened(uint256 lotteryId, uint256 ticketSupply);

    event LotteryClosed(uint256 lotteryId, uint256 ticketSupply);

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
        // solhint-disable-next-line avoid-tx-origin
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

    // solhint-disable-next-line no-empty-blocks
    constructor(address _timer) Testable(_timer) {}

    function initialize(
        address _titan,
        address _ticket,
        address _randomNumberGenerator,
        address _prizeReservePool,
        address _taxService,
        address _controller
    ) external initializer onlyOwner {
        require(
            _ticket != address(0) &&
                _randomNumberGenerator != address(0) &&
                _prizeReservePool != address(0) &&
                _taxService != address(0) &&
                _titan != address(0),
            "Contracts cannot be 0 address"
        );
        titan_ = IERC20(_titan);
        ticket_ = ITicket(_ticket);
        randomGenerator_ = IRandomNumberGenerator(_randomNumberGenerator);
        prizeReservePool_ = _prizeReservePool;
        taxService_ = ITaxService(_taxService);
        controller_ = _controller;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function costToBuyTickets(uint256 _lotteryId, uint256 _numberOfTickets) external view returns (uint256 totalCost) {
        uint256 pricePer = allLotteries_[_lotteryId].costPerTicket;
        totalCost = pricePer * _numberOfTickets; // solidity 0.8 auto handle overflow
    }

    function getBasicLottoInfo(uint256 _lotteryId) external view returns (LottoInfo memory) {
        return (allLotteries_[_lotteryId]);
    }

    function getCurrentLotto() external view returns (LottoInfo memory) {
        require(lotteryIdCounter_ > 0, "no lottery created");
        return allLotteries_[lotteryIdCounter_];
    }

    function getCurrentTotalPrize() public view returns (uint256 totalPrize) {
        totalPrize = titan_.balanceOf(address(this)) - unclaimedPrize_;
    }

    function getMaxRange() external view returns (uint16) {
        return maxValidRange_;
    }

    function getCurrentPrizes() public view returns (uint256[] memory prizes) {
        require(lotteryIdCounter_ > 0, "no lottery created");
        LottoInfo storage lotto = allLotteries_[lotteryIdCounter_];
        prizes = new uint256[](lotto.prizeDistribution.length);

        uint256 totalPrize = getCurrentTotalPrize();
        for (uint256 i = 0; i < lotto.prizeDistribution.length; i++) {
            prizes[i] = (totalPrize * lotto.prizeDistribution[i]) / PRECISION;
        }
    }

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyOwner)

    /**
     * manually start by admin, by pass auto duration
     */
    function manualStartLotto(uint256 _startingTime, uint256 _closingTime) external onlyController returns (uint256) {
        return _createNewLotto(_startingTime, _closingTime);
    }

    function manuallyOpenLotto() external onlyController {
        require(lotteryIdCounter_ > 0, "no lottery created");
        LottoInfo storage _currLotto = allLotteries_[lotteryIdCounter_];
        uint256 currentTime = getCurrentTime();
        require(currentTime >= _currLotto.startingTimestamp, "Invalid time for mint:start");
        require(currentTime < _currLotto.closingTimestamp, "Invalid time for mint:end");
        if (_currLotto.lotteryStatus == Status.NotStarted) {
            if (_currLotto.startingTimestamp <= getCurrentTime()) {
                _currLotto.lotteryStatus = Status.Open;
            }
        }
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= PRECISION, "total must lower than 100%");
        taxRate_ = _taxRate;
    }

    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "Contracts cannot be 0 address");
        controller_ = _controller;
    }

    function setPrizeReservePool(address _prizeReservePool) external onlyOwner {
        require(_prizeReservePool != address(0), "Contracts cannot be 0 address");
        prizeReservePool_ = _prizeReservePool;
    }

    function setTaxService(address _taxService) external onlyOwner {
        require(_taxService != address(0), "Contracts cannot be 0 address");
        taxService_ = ITaxService(_taxService);
    }

    function setRandomGenerator(address _randomGenerator) external onlyOwner {
        require(_randomGenerator != address(0), "Contracts cannot be 0 address");
        randomGenerator_ = IRandomNumberGenerator(_randomGenerator);
    }

    function setTicket(address _ticket) external onlyOwner {
        require(_ticket != address(0), "Contracts cannot be 0 address");
        ticket_ = ITicket(_ticket);
    }

    function withdrawFund(address receiver) external onlyOwner {
        require(receiver != address(0), "Invalid address");
        uint256 _movableAmount = getCurrentTotalPrize();
        upgraded_ = true;
        titan_.safeTransfer(receiver, _movableAmount);
    }

    /**
     * @param   _prizeDistribution An array defining the distribution of the
     *          prize pool. I.e if a lotto has 5 numbers, the distribution could
     *          be [5, 10, 15, 20, 30] = 100%. This means if you get one number
     *          right you get 5% of the pool, 2 matching would be 10% and so on.
     */
    function updateLottoSettings(
        uint16 _maxValidRange,
        uint16 _powerBallRange,
        uint256[] calldata _prizeDistribution,
        uint256 _costPerTicket,
        uint256 _startingPrize
    ) external onlyOwner {
        require(_maxValidRange >= 4, "Range of number must be 4 atleast");
        require(_powerBallRange != 0, "Power number range can not be 0");
        require(_startingPrize != 0 && _costPerTicket != 0, "Prize or cost cannot be 0");
        // Ensuring that prize distribution total is 100%
        uint256 prizeDistributionTotal = 0;
        for (uint256 j = 0; j < _prizeDistribution.length; j++) {
            prizeDistributionTotal = prizeDistributionTotal + uint256(_prizeDistribution[j]);
        }
        require(prizeDistributionTotal == PRECISION, "Prize distribution is not 100%");

        maxValidRange_ = _maxValidRange;
        powerBallRange_ = _powerBallRange;
        prizeDistribution_ = _prizeDistribution;
        startingPrize_ = _startingPrize;
        costPerTicket_ = _costPerTicket;

        emit LotterySettingsUpdated(
            maxValidRange_,
            powerBallRange_,
            prizeDistribution_,
            startingPrize_,
            costPerTicket_
        );
    }

    function drawWinningNumbers(uint256 _lotteryId) external onlyController notUpgraded {
        LottoInfo storage _currLotto = allLotteries_[_lotteryId];
        // Checks that the lottery is past the closing block
        require(_currLotto.closingTimestamp <= getCurrentTime(), "Cannot set winning numbers during lottery");
        // Checks lottery numbers have not already been drawn
        require(_currLotto.lotteryStatus == Status.Open, "Lottery State incorrect for draw");
        // Sets lottery status to closed
        _currLotto.lotteryStatus = Status.Closed;
        // Sets prize pool
        _currLotto.prizePool = getCurrentTotalPrize();
        // Requests a random number from the generator
        requestId_ = randomGenerator_.getRandomNumber(_lotteryId);
        // Emits that random number has been requested
        emit RequestNumbers(_lotteryId, requestId_);
    }

    function retryDrawWinningNumbers(uint256 _lotteryId) external onlyController notUpgraded {
        LottoInfo storage _currLotto = allLotteries_[_lotteryId];
        require(_currLotto.closingTimestamp <= getCurrentTime(), "Cannot set winning numbers during lottery");
        require(_currLotto.lotteryStatus == Status.Closed, "Lottery State incorrect for retry");
        requestId_ = randomGenerator_.getRandomNumber(_lotteryId);
        emit RequestNumbers(_lotteryId, requestId_);
    }

    function numbersDrawn(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    ) external onlyRandomGenerator() notUpgraded {
        LottoInfo storage _currLotto = allLotteries_[_lotteryId];
        require(_currLotto.lotteryStatus == Status.Closed, "Draw numbers first");
        if (requestId_ == _requestId) {
            _currLotto.winningNumbers = _split(_randomNumber);
            uint256[] memory matches = ticket_.countMatch(_lotteryId, maxValidRange_, _currLotto.winningNumbers);
            _currLotto.lotteryStatus = Status.Completed;
            uint256 _actualPrizeDistribution = 0;
            for (uint256 i = 0; i < _currLotto.prizeDistribution.length; i++) {
                _currLotto.winners[i] = matches[i];
                if (matches[i] > 0) {
                    _actualPrizeDistribution = _actualPrizeDistribution + _currLotto.prizeDistribution[i];
                }
            }
            uint256 _totalPrize = (getCurrentTotalPrize() * _actualPrizeDistribution) / PRECISION;
            if (_totalPrize > 0) {
                uint256 _taxAmount = (_totalPrize * taxRate_) / PRECISION;
                uint256 _prizeAfterTax = _totalPrize - _taxAmount;
                _addUnclaimedPrize(_prizeAfterTax);
                _collectTax(_taxAmount);
            }
        }

        emit LotteryClosed(_lotteryId, ticket_.getTotalSupply());
    }

    //-------------------------------------------------------------------------
    // General Access Functions

    function batchBuyLottoTicket(
        uint256 _lotteryId,
        uint8 _numberOfTickets,
        uint16[] calldata _chosenNumbersForEachTicket
    ) external notContract() notUpgraded {
        // Ensuring the lottery is within a valid time
        uint256 currentTime = getCurrentTime();
        LottoInfo storage _currLotto = allLotteries_[_lotteryId];
        require(currentTime >= _currLotto.startingTimestamp, "Invalid time for mint:start");
        require(currentTime < _currLotto.closingTimestamp, "Invalid time for mint:end");

        if (_currLotto.lotteryStatus == Status.NotStarted) {
            if (_currLotto.startingTimestamp <= getCurrentTime()) {
                _currLotto.lotteryStatus = Status.Open;
            }
        }

        require(_currLotto.lotteryStatus == Status.Open, "Lottery not in state for mint");
        validateTicketNumbers(_numberOfTickets, _chosenNumbersForEachTicket);
        uint256 totalCost = this.costToBuyTickets(_lotteryId, _numberOfTickets);

        // Batch mints the user their tickets
        uint256[] memory ticketIds = ticket_.batchMint(
            msg.sender,
            _lotteryId,
            _numberOfTickets,
            maxValidRange_,
            _chosenNumbersForEachTicket
        );

        // Emitting event with all information
        emit NewBatchMint(msg.sender, ticketIds, _chosenNumbersForEachTicket, totalCost);

        // Transfers the required titan to this contract
        titan_.safeTransferFrom(msg.sender, address(this), totalCost);
    }

    function claimReward(uint256 _lotteryId, uint256 _tokenId) external notContract() {
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
        // Transfering the user their winnings
        _claimPrize(msg.sender, prizeAmount);
    }

    function batchClaimRewards(uint256 _lotteryId, uint256[] calldata _tokeIds) external notContract() {
        require(_tokeIds.length <= 50, "Batch claim too large");
        // Checking the lottery is in a valid time for claiming
        require(allLotteries_[_lotteryId].closingTimestamp <= getCurrentTime(), "Wait till end to claim");
        // Checks the lottery winning numbers are available
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Completed, "Winning Numbers not chosen yet");
        // Creates a storage for all winnings
        uint256 totalPrize = 0;
        // Loops through each submitted token
        for (uint256 i = 0; i < _tokeIds.length; i++) {
            // Checks user is owner (will revert entire call if not)
            require(ticket_.getOwnerOfTicket(_tokeIds[i]) == msg.sender, "Only the owner can claim");
            // If token has already been claimed, skip token
            if (ticket_.getTicketClaimStatus(_tokeIds[i])) {
                continue;
            }
            // Claims the ticket (will only revert if numbers invalid)
            require(ticket_.claimTicket(_tokeIds[i], _lotteryId), "Numbers for ticket invalid");
            // Getting the number of matching tickets
            uint8 matchingNumbers = _getNumberOfMatching(
                ticket_.getTicketNumbers(_tokeIds[i]),
                allLotteries_[_lotteryId].winningNumbers
            );
            // Getting the prize amount for those matching tickets
            uint256 prizeAmount = _prizeForMatching(matchingNumbers, _lotteryId);
            totalPrize = totalPrize + prizeAmount;
        }
        // Transferring the user their winnings
        _claimPrize(msg.sender, totalPrize);
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @param   _startingTimestamp The block timestamp for the beginning of the
     *          lottery.
     * @param   _closingTimestamp The block timestamp after which no more tickets
     *          will be sold for the lottery. Note that this timestamp MUST
     *          be after the starting block timestamp.
     */
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
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_ + 1);
        uint256[] memory winnersCount = new uint256[](prizeDistribution_.length);
        Status lotteryStatus;
        if (_startingTimestamp > getCurrentTime()) {
            lotteryStatus = Status.NotStarted;
        } else {
            lotteryStatus = Status.Open;
        }

        //transfer from reserve pool to poolPrize if current < minPrize
        if (getCurrentTotalPrize() < startingPrize_) {
            IPrizeReservePool(prizeReservePool_).fund(startingPrize_ - getCurrentTotalPrize());
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
            winnersCount
        );
        allLotteries_[lotteryId] = newLottery;

        // Emitting important information around new lottery.
        emit LotteryOpened(lotteryId, ticket_.getTotalSupply());
    }

    function _getNumberOfMatching(uint16[] memory _usersNumbers, uint16[] memory _winningNumbers)
        internal
        pure
        returns (uint8 noOfMatching)
    {
        // Loops through all winning numbers
        for (uint256 i = 0; i < _winningNumbers.length - 1; i++) {
            for (uint256 j = 0; j < _usersNumbers.length - 1; j++) {
                // If the winning numbers and user numbers match
                if (_usersNumbers[i] == _winningNumbers[j]) {
                    // The number of matching numbers increases
                    noOfMatching += 1;
                }
            }
        }

        // compare power number
        if (
            noOfMatching == sizeOfLottery_ &&
            _winningNumbers[_winningNumbers.length - 1] == _usersNumbers[_usersNumbers.length - 1]
        ) {
            noOfMatching += 1;
        }
    }

    function _claimPrize(address _winner, uint256 _amount) internal {
        unclaimedPrize_ = unclaimedPrize_ - _amount;
        titan_.safeTransfer(_winner, _amount);
    }

    function _addUnclaimedPrize(uint256 amount) internal {
        unclaimedPrize_ = unclaimedPrize_ + amount;
    }

    function _collectTax(uint256 _taxAmount) internal {
        titan_.safeApprove(address(taxService_), 0);
        titan_.safeApprove(address(taxService_), _taxAmount);
        taxService_.collect(_taxAmount);
    }

    /**
     * @param   _noOfMatching: The number of matching numbers the user has
     * @param   _lotteryId: The ID of the lottery the user is claiming on
     * @return  prize  The prize amount in cake the user is entitled to
     */
    function _prizeForMatching(uint8 _noOfMatching, uint256 _lotteryId) public view returns (uint256 prize) {
        prize = 0;
        if (_noOfMatching > 0) {
            // Getting the percentage of the pool the user has won
            uint256 prizeIndex = sizeOfLottery_ + 1 - _noOfMatching;
            uint256 perOfPool = allLotteries_[_lotteryId].prizeDistribution[prizeIndex];
            uint256 numberOfWinners = allLotteries_[_lotteryId].winners[prizeIndex];

            if (numberOfWinners > 0) {
                prize =
                    (allLotteries_[_lotteryId].prizePool * perOfPool * (PRECISION - taxRate_)) /
                    numberOfWinners /
                    (PRECISION**2);
            }
        }
    }

    function _split(uint256 _randomNumber) internal view returns (uint16[] memory) {
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_ + 1);

        uint16[] memory array = new uint16[](maxValidRange_);
        for (uint16 i = 0; i < maxValidRange_; i++) {
            array[i] = i + 1;
        }

        uint16 temp;

        for (uint256 i = array.length - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % i;
            temp = array[i];
            array[i] = array[j];
            array[j] = temp;
        }

        for (uint256 i = 0; i < sizeOfLottery_; i++) {
            winningNumbers[i] = array[i];
        }

        winningNumbers[sizeOfLottery_] = (uint16(_randomNumber) % powerBallRange_) + 1;
        return winningNumbers;
    }

    function validateTicketNumbers(uint8 _numberOfTickets, uint16[] memory _numbers) internal view {
        require(_numberOfTickets <= 50, "Batch mint too large");
        require(_numbers.length == _numberOfTickets * (sizeOfLottery_ + 1), "Invalid chosen numbers");

        for (uint256 i = 0; i < _numbers.length; i++) {
            uint256 k = i % (sizeOfLottery_ + 1);
            if (k == sizeOfLottery_) {
                require(_numbers[i] > 0 && _numbers[i] <= powerBallRange_, "out of range: power number");
            } else {
                require(_numbers[i] > 0 && _numbers[i] <= maxValidRange_, "out of range: number");
            }
            if (k > 0 && k != sizeOfLottery_) {
                for (uint256 j = i - k; j <= i - 1; j++) {
                    require(_numbers[i] != _numbers[j], "duplicate number");
                }
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 lotteryId) external returns (bytes32 requestId);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface ITicket {
    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns (uint256);

    function getTicketNumbers(uint256 _ticketID) external view returns (uint16[] memory);

    function getOwnerOfTicket(uint256 _ticketID) external view returns (address);

    function getTicketClaimStatus(uint256 _ticketID) external view returns (bool);

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

    function claimTicket(uint256 _ticketId, uint256 _lotteryId) external returns (bool);

    function countMatch(
        uint256 _lotteryId,
        uint16 _maxValidRange,
        uint16[] calldata _winningNumbers
    ) external view returns (uint256[] memory results);
}

// SPDX-License-Identifier: MIT
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

pragma solidity 0.8.4;

interface IPrizeReservePool {
    /**
     * Funding a minimal amount when prize pool is empty
     * @param amount amount of IRON to be set as prize
     */
    function fund(uint256 amount) external;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPrizeReservePool.sol";
import "./interfaces/IERC20Burnable.sol";

contract PrizeReservePool is Ownable {
    using SafeERC20 for IERC20Burnable;
    IERC20Burnable public titan_;
    address public lottery_;

    constructor(address _titan, address _lottery) {
        require(_titan != address(0), "!address");
        require(_lottery != address(0), "!address");
        titan_ = IERC20Burnable(_titan);
        lottery_ = _lottery;
    }

    modifier onlyLottery() {
        require(address(msg.sender) == lottery_, "Caller is not the lottery");
        _;
    }

    function setLottery(address _lottery) external onlyOwner {
        lottery_ = _lottery;
    }

    function balance() external view returns (uint256) {
        return titan_.balanceOf(address(this));
    }

    function fund(uint256 amount) external onlyLottery {
        titan_.safeTransfer(lottery_, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        titan_.burn(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ILottery.sol";

contract Ticket is ERC1155, Ownable {
    // Libraries

    // State variables
    address internal lotteryContract_;

    uint256 internal totalSupply_;

     // Token name
    string private _name;

    // Token symbol
    string private _symbol;


    // Storage for ticket information
    struct TicketInfo {
        address owner;
        uint16[] numbers;
        bool claimed;
        uint256 lotteryId;
    }
    // Token ID => Token information
    mapping(uint256 => TicketInfo) internal ticketInfo_;
    // lottery ID => tickets count
    mapping(uint256 => uint256) internal ticketsCount_;
    // User address => Lottery ID => Ticket IDs
    mapping(address => mapping(uint256 => uint256[])) internal userTickets_;

    // These stated is fixed due to technical implementation
    // Lottery size, power number not included
    uint8 public constant sizeOfLottery_ = 4;
    // support 2 numbers match, if require 3 numbers match, use value of 5
    // uint8 public constant sizeOfIndex_ = 5;
    // lotteryId => hash => count
    // the hash is combined from ticked numbers
    mapping(uint256 => mapping(uint256 => uint256)) internal ticketHashes_;
      // Combo hash => Bool
    mapping(uint256 =>  bool) internal mintedCombo_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event InfoBatchMint(address indexed receiving, uint256 lotteryId, uint256 amountOfTokens, uint256[] tokenIds);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    /**
     * @notice  Restricts minting of new tokens to only the lotto contract.
     */
    modifier onlyLotto() {
        require(msg.sender == lotteryContract_, "Only Lotto can mint");
        _;
    }

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    /**
     * @param   _uri A dynamic URI that enables individuals to view information
     *          around their NFT token. To see the information replace the
     *          `\{id\}` substring with the actual token type ID. For more info
     *          visit:
     *          https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     * @param   _lotto The address of the lotto contract. The lotto contract has
     *          elevated permissions on this contract.
     */
      constructor(string memory _uri,string memory name_, string memory symbol_, address _lotto) ERC1155(_uri) {
        // Only Lotto contract will be able to mint new tokens
        lotteryContract_ = _lotto;
        _name = name_;
        _symbol = symbol_;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @param   _ticketID: The unique ID of the ticket
     * @return  uint32[]: The chosen numbers for that ticket
     */
    function getTicketNumbers(uint256 _ticketID) external view returns (uint16[] memory) {
        return ticketInfo_[_ticketID].numbers;
    }

    /**
     * @param   _ticketID: The unique ID of the ticket
     * @return  address: Owner of ticket
     */
    function getOwnerOfTicket(uint256 _ticketID) external view returns (address) {
        return ticketInfo_[_ticketID].owner;
    }

    function getTicketClaimStatus(uint256 _ticketID) external view returns (bool) {
        return ticketInfo_[_ticketID].claimed;
    }

    function getTicketClaimStatuses(uint256[] calldata ticketIds) external view returns (bool[] memory ticketStatuses) {
        ticketStatuses = new bool[](ticketIds.length);
        for (uint256 i = 0; i < ticketIds.length; i++) {
            ticketStatuses[i] = ticketInfo_[ticketIds[i]].claimed;
        }
    }

    function getUserTickets(uint256 _lotteryId, address _user) external view returns (uint256[] memory) {
        return userTickets_[_user][_lotteryId];
    }

    function getListTicketNumbers(uint256[] calldata ticketIds)
        external
        view
        returns (uint256[] memory ticketNumbers, uint256 sizeOfLottery)
    {
        sizeOfLottery = sizeOfLottery_ + 1;
        ticketNumbers = new uint256[](ticketIds.length * sizeOfLottery);
        for (uint256 i = 0; i < ticketIds.length; i++) {
            uint16[] memory ticketNumber = ticketInfo_[ticketIds[i]].numbers;
            if (ticketNumber.length != sizeOfLottery) {
                ticketNumber = new uint16[](sizeOfLottery);
            }
            for (uint256 j = 0; j < ticketNumber.length; j++) {
                ticketNumbers[sizeOfLottery * i + j] = ticketNumber[j];
            }
        }
    }

    function getNumberOfTickets(uint256 _lotteryId) external view returns (uint256) {
        return ticketsCount_[_lotteryId];
    }

    function getUserTicketsPagination(
        address _user,
        uint256 _lotteryId,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > userTickets_[_user][_lotteryId].length - cursor) {
            length = userTickets_[_user][_lotteryId].length - cursor;
        }
        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userTickets_[_user][_lotteryId][cursor + i];
        }
        return (values, cursor + length);
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

        function generateNumberHash(uint16[] memory numbers)
        public
        pure
        returns (uint256)
    {
   
        uint256 len = numbers.length;
        uint256 hash=0;

        for (uint256 i = 0; i < len; i++) {
            
            if(numbers[i]>9){
                hash= hash*10;
                 hash += numbers[i] * 10**(len - i);
            }
            else{
          hash += numbers[i] * 10**(len - i);
            }
            hash= hash*10;
        }
        
        hash =hash/100;
        
        return hash;

    }

    function CheckmintedCombo(
        uint16[] memory _numbers
    ) internal  returns (bool){
        uint256  hash = generateNumberHash(_numbers);
      require(mintedCombo_[hash] != true, "Combo already minted");
       mintedCombo_[hash] = true;
    return false;
    }

    /**
     * @param   _to The address being minted to
     * @param   _numberOfTickets The number of NFT's to mint
     * @notice  Only the lotto contract is able to mint tokens.
        // uint8[][] calldata _lottoNumbers
     */

    function batchMint(
        address _to,
        uint256 _lotteryId,
        uint8 _numberOfTickets,
        uint16 _maxValidRange,
        uint16[] calldata _numbers
    ) external onlyLotto() returns (uint256[] memory) {
        // Storage for the amount of tokens to mint (always 1)
        uint256[] memory amounts = new uint256[](_numberOfTickets);
        // Storage for the token IDs
        uint256[] memory tokenIds = new uint256[](_numberOfTickets);
        for (uint8 i = 0; i < _numberOfTickets; i++) {
            // Incrementing the tokenId counter
            totalSupply_ = totalSupply_ + 1;
            tokenIds[i] = totalSupply_;
            amounts[i] = 1;
            // Getting the start and end position of numbers for this ticket
            uint16 start = uint16(i * (sizeOfLottery_ + 1));
            uint16 end = uint16((i + 1) * (sizeOfLottery_ + 1));
            // Splitting out the chosen numbers
            uint16[] calldata numbers = _numbers[start:end];
             // Checking if combo is avaliable to mint
            CheckmintedCombo(numbers);
            // Storing the ticket information
            ticketInfo_[totalSupply_] = TicketInfo(_to, numbers, false, _lotteryId);
            userTickets_[_to][_lotteryId].push(totalSupply_);
            indexTicket(_lotteryId, _maxValidRange, numbers);
        }
        // Minting the batch of tokens
        _mintBatch(_to, tokenIds, amounts, msg.data);
        ticketsCount_[_lotteryId] = ticketsCount_[_lotteryId] + _numberOfTickets;
        // Emitting relevant info
        emit InfoBatchMint(_to, _lotteryId, _numberOfTickets, tokenIds);
        // Returns the token IDs of minted tokens
        return tokenIds;
    }

    function indexTicket(
        uint256 _lotteryId,
        uint16 _maxValidRange,
        uint16[] memory _numbers
    ) internal {
        uint256[2] memory indexes = generateNumberIndexKey(_maxValidRange, _numbers);
        for (uint256 j = 0; j < indexes.length; j++) {
            ticketHashes_[_lotteryId][indexes[j]]++;
        }
    }

    function claimTicket(uint256 _ticketID, uint256 _lotteryId) external onlyLotto() returns (bool) {
        require(ticketInfo_[_ticketID].claimed == false, "Ticket already claimed");
        require(ticketInfo_[_ticketID].lotteryId == _lotteryId, "Ticket not for this lottery");
        uint256 maxRange = ILottery(lotteryContract_).getMaxRange();
        for (uint256 i = 0; i < ticketInfo_[_ticketID].numbers.length; i++) {
            if (ticketInfo_[_ticketID].numbers[i] > maxRange) {
                return false;
            }
        }

        ticketInfo_[_ticketID].claimed = true;
        return true;
    }

    function setLottery(address _lottery) external onlyOwner {
        require(_lottery != address(0), "Invalid address");
        lotteryContract_ = _lottery;
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    /**
     * calculate the index for matching
     * eg: 0x0102030402 <- mean ticket 01 02 03 04 missing 2 numbers
     * eg: 0x0102030400 <- mean ticket 01 02 03 04 missing 0 numbers
     * the last element is Jackpot index.
     * eg: ticket 01 02 03 04 21 has index: 0x010203040021
     */
    function generateNumberIndexKey(uint16 _maxValidRange, uint16[] memory numbers)
        public
        pure
        returns (uint256[2] memory result)
    {
        uint16 power = numbers[numbers.length - 1];
        uint256 len = numbers.length - 1;
        uint256 key;
        for (uint256 index = 0; index < len; index++) {
            key += 1 << (numbers[index] - 1);
        }

        result[0] = key;
        result[1] = key + (1 << _maxValidRange) * power;
    }


    function countMatch(
        uint256 _lotteryId,
        uint16 _maxValidRange,
        uint16[] calldata _winningNumbers
    ) external view returns (uint256[] memory results) {
        results = new uint256[](sizeOfLottery_ + 1);
        uint256[2] memory keys = generateNumberIndexKey(_maxValidRange, _winningNumbers);
        uint256 match4Key = keys[0];
        uint256 jackpotKey = keys[1];
        results[0] = ticketHashes_[_lotteryId][jackpotKey];
        results[1] = ticketHashes_[_lotteryId][match4Key] - results[0];

        // count match 3 numbers
        // remove each number and replace with others
        uint256 key;
        for (uint256 i = 0; i < sizeOfLottery_; i++) {
            uint256 base = match4Key - (1 << (_winningNumbers[i] - 1));
            for (uint256 j = 1; j < _maxValidRange + 1; j++) {
                if (j == _winningNumbers[i]) {
                    continue;
                }
                key = 1 << (j - 1);

                if ((key & base) == 0) {
                    results[2] += ticketHashes_[_lotteryId][base + key];
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ILottery {
    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getMaxRange() external view returns (uint32);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function numbersDrawn(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    ) external;

    function costToBuyTickets(uint256 _lotteryId, uint256 _numberOfTickets) external view returns (uint256 totalCost);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILottery.sol";

contract RandomNumberGenerator is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;
    address internal requester;
    uint256 public randomResult;
    uint256 public currentLotteryId;

    address public lottery;

    modifier onlyLottery() {
        require(msg.sender == lottery, "Only Lottery can call function");
        _;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        address _lottery,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;
        lottery = _lottery;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 lotteryId) public onlyLottery returns (bytes32 requestId) {
        require(keyHash != bytes32(0), "Must have valid key hash");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requester = msg.sender;
        currentLotteryId = lotteryId;
        return requestRandomness(keyHash, fee);
    }

    function setLottery(address _lottery) external onlyOwner {
        lottery = _lottery;
    }

    function withdrawAllLink() external onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        ILottery(requester).numbersDrawn(currentLotteryId, requestId, randomness);
        randomResult = randomness;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}