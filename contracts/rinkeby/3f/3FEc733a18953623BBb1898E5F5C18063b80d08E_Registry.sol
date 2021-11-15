// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./registry/Investment.sol";
import "./libs/TokenFormat.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title AllianceBlock Registry contract
 * @notice Responsible for investment transactions.
 * @dev Extends Initializable, Investment, OwnableUpgradeable
 */
contract Registry is Initializable, Investment, OwnableUpgradeable {
    using SafeMath for uint256;
    using TokenFormat for uint256;

    // Events
    event InvestmentStarted(uint256 indexed investmentId);
    event InvestmentApproved(uint256 indexed investmentId);
    event InvestmentRejected(uint256 indexed investmentId);

    /**
     * @notice Initialize
     * @dev Constructor of the contract.
     * @param escrowAddress address of the escrow contract
     * @param governanceAddress_ address of the DAO contract
     * @param lendingToken_ address of the Lending Token
     * @param fundingNFT_ address of the Funding NFT
     * @param baseAmountForEachPartition_ The base amount for each partition
     */
    function initialize(
        address escrowAddress,
        address governanceAddress_,
        address lendingToken_,
        address fundingNFT_,
        uint256 baseAmountForEachPartition_
    ) public initializer {
        __Ownable_init();
        escrow = IEscrow(escrowAddress);
        baseAmountForEachPartition = baseAmountForEachPartition_;
        governance = IGovernance(governanceAddress_);
        lendingToken = IERC20(lendingToken_);
        fundingNFT = IERC1155Mint(fundingNFT_);
    }

    /**
     * @notice Initialize Investment
     * @dev This function is called by the owner to initialize the investment type.
     * @param reputationalAlbt The address of the rALBT contract.
     * @param totalTicketsPerRun_ The amount of tickets that will be provided from each run of the lottery.
     * @param rAlbtPerLotteryNumber_ The amount of rALBT needed to allocate one lucky number.
     * @param blocksLockedForReputation_ The amount of blocks needed for a ticket to be locked,
     *        so as investor to get 1 rALBT for locking it.
     */
    function initializeInvestment(
        address reputationalAlbt,
        uint256 totalTicketsPerRun_,
        uint256 rAlbtPerLotteryNumber_,
        uint256 blocksLockedForReputation_,
        uint256 lotteryNumbersForImmediateTicket_
    ) external onlyOwner() {
        require(totalTicketsPerRun == 0, "Cannot initialize twice");
        rALBT = IERC20(reputationalAlbt);
        totalTicketsPerRun = totalTicketsPerRun_;
        rAlbtPerLotteryNumber = rAlbtPerLotteryNumber_;
        blocksLockedForReputation = blocksLockedForReputation_;
        lotteryNumbersForImmediateTicket = lotteryNumbersForImmediateTicket_;
    }

    /**
     * @notice Decide For Investment
     * @dev This function is called by governance to approve or reject a investment request.
     * @param investmentId The id of the investment.
     * @param decision The decision of the governance. [true -> approved] [false -> rejected]
     */
    function decideForInvestment(uint256 investmentId, bool decision) external onlyGovernance() {
        if (decision) _approveInvestment(investmentId);
        else _rejectInvestment(investmentId);
    }

    /**
     * @notice Start Lottery Phase
     * @dev This function is called by governance to start the lottery phase for an investment.
     * @param investmentId The id of the investment.
     */
    function startLotteryPhase(uint256 investmentId) external onlyGovernance() {
        _startInvestment(investmentId);
    }

    /**
     * @notice Approve Investment
     * @param investmentId_ The id of the investment.
     */
    function _approveInvestment(uint256 investmentId_) internal {
        investmentStatus[investmentId_] = InvestmentLibrary.InvestmentStatus.APPROVED;
        investmentDetails[investmentId_].approvalDate = block.timestamp;
        fundingNFT.unpauseTokenTransfer(investmentId_); //UnPause trades for ERC1155s with the specific investment ID.
        ticketsRemaining[investmentId_] = investmentDetails[investmentId_].totalPartitionsToBePurchased;
        governance.storeInvestmentTriggering(investmentId_);
        emit InvestmentApproved(investmentId_);
    }

    /**
     * @notice Reject Investment
     * @param investmentId_ The id of the investment.
     */
    function _rejectInvestment(uint256 investmentId_) internal {
        investmentStatus[investmentId_] = InvestmentLibrary.InvestmentStatus.REJECTED;
        escrow.transferProjectToken(
            investmentDetails[investmentId_].projectToken,
            investmentSeeker[investmentId_],
            investmentDetails[investmentId_].projectTokensAmount
        );
        emit InvestmentRejected(investmentId_);
    }

    /**
     * @notice Start Investment
     * @param investmentId_ The id of the investment.
     */
    function _startInvestment(uint256 investmentId_) internal {
        investmentStatus[investmentId_] = InvestmentLibrary.InvestmentStatus.STARTED;
        investmentDetails[investmentId_].startingDate = block.timestamp;

        emit InvestmentStarted(investmentId_);
    }

    /**
     * @notice Get Investment Metadata
     * @dev This helper function provides a single point for querying the Investment metadata
     * @param investmentId The id of the investment.
     * @dev returns Investment Details, Investment Status, Investment Seeker Address and Repayment Batch Type
     */
    function getInvestmentMetadata(uint256 investmentId)
        public
        view
        returns (
            InvestmentLibrary.InvestmentDetails memory, // the investmentDetails
            InvestmentLibrary.InvestmentStatus, // the investmentStatus
            address // the investmentSeeker
        )
    {
        return (
            investmentDetails[investmentId],
            investmentStatus[investmentId],
            investmentSeeker[investmentId]
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the IERC1155 mint function.
 */
interface IERC1155Mint {
    function mintGen0(
        address to,
        uint256 amount,
        uint256 investmentId
    ) external;

    function mintOfGen(
        address to,
        uint256 amount,
        uint256 generation,
        uint256 investmentId
    ) external;

    function decreaseGenerations(
        uint256 tokenId,
        address user,
        uint256 amount,
        uint256 generationsToDecrease
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function pauseTokenTransfer(uint256 investmentId) external;

    function unpauseTokenTransfer(uint256 tokenId) external;

    function increaseGenerations(
        uint256 tokenId,
        address user,
        uint256 amount,
        uint256 generationsToAdd
    ) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the Escrow.
 */
interface IEscrow {
    function receiveFunding(uint256 loanId, uint256 amount) external;

    function transferFundingNFT(
        uint256 investmentId,
        uint256 partitionsPurchased,
        address receiver
    ) external;

    function transferLendingToken(address seeker, uint256 amount) external;

    function transferProjectToken(
        address projectToken,
        address seeker,
        uint256 amount
    ) external;

    function mintReputationalToken(address recipient, uint256 amount) external;

    function burnReputationalToken(address from, uint256 amount) external;

    function multiMintReputationalToken(address[] memory recipients, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface of the Governance contract.
 */
interface IGovernance {
    function requestApproval(
        uint256 investmentId
    ) external;

    function storeInvestmentTriggering(uint256 investmentId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

/**
 * @title Investment Library
 */
library InvestmentLibrary {
    enum InvestmentStatus {
        REQUESTED, // Status when investment has been requested, but not approved yet.
        APPROVED, // Status when investment has been approved from governors.
        STARTED, // Status when investment has been fully funded.
        SETTLED, // Status when investment has been fully repaid by the seeker.
        DEFAULT, // Status when seeker has not been able to repay the investment.
        REJECTED // Status when investment has been rejected by governors.
    }

    struct InvestmentDetails {
        uint256 investmentId; // The Id of the investment.
        uint256 approvalDate; // The timestamp in which investment was approved.
        uint256 startingDate; // The timestamp in which investment was funded.
        address projectToken; // The address of the token that will be sold to investors.
        uint256 projectTokensAmount; // The amount of project tokens that are deposited for investors by the seeker.
        uint256 totalAmountToBeRaised; // The amount of tokens that seeker of investment will raise after all tickets are purchased.
        uint256 totalPartitionsToBePurchased; // The total partitions or ERC1155 tokens, in which investment is splitted.
        string extraInfo; // The ipfs hash, where all extra info about the investment are stored.
        uint256 partitionsRequested; // The total partitions or ERC1155 tokens that are requested for purchase.
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

/**
 * @title The Token Format library
 */
library TokenFormat {
    // Use a split bit implementation.
    // Store the generation in the upper 128 bits..
    // ..and the non-fungible loan id in the lower 128
    uint256 private constant _LOAN_ID_MASK = uint128(~0);

    /**
     * @notice Format tokenId into generation and index
     * @param tokenId The Id of the token
     * @return generation
     * @return loanId
     */
    function formatTokenId(uint256 tokenId) internal pure returns (uint256 generation, uint256 loanId) {
        generation = tokenId >> 128;
        loanId = tokenId & _LOAN_ID_MASK;
    }

    /**
     * @notice get tokenId from generation and loanId
     * @param gen the generation
     * @param loanId the loanID
     * @return tokenId the token id
     */
    function getTokenId(uint256 gen, uint256 loanId) internal pure returns (uint256 tokenId) {
        return (gen << 128) | loanId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./InvestmentDetails.sol";
import "../libs/TokenFormat.sol";

/**
 * @title AllianceBlock Investment contract.
 * @notice Functionality for Investment.
 * @dev Extends InvestmentDetails.
 */
contract Investment is InvestmentDetails {
    using SafeMath for uint256;
    using TokenFormat for uint256;

    // EVENTS
    event InvestmentRequested(uint256 indexed investmentId, address indexed user, uint256 amount);

    /**
     * @notice Requests investment
     * @dev This function is used for projects to request investment in exchange for project tokens.
     * @dev require valid amount
     * @param investmentToken The token that will be purchased by investors.
     * @param amountOfInvestmentTokens The amount of investment tokens to be purchased.
     * @param totalAmountRequested_ The total amount requested so as all investment tokens to be sold.
     * @param extraInfo The ipfs hash where more specific details for investment request are stored.
     */
    function requestInvestment(
        address investmentToken,
        uint256 amountOfInvestmentTokens,
        uint256 totalAmountRequested_,
        string memory extraInfo
    ) external {
        // TODO - Change 10 ** 18 to decimals if needed.
        require(
            totalAmountRequested_.mod(baseAmountForEachPartition) == 0 &&
                totalAmountRequested_.mul(10**18).mod(amountOfInvestmentTokens) == 0,
            "Token amount and price should result in integer amount of tickets"
        );

        _storeInvestmentDetails(
            totalAmountRequested_,
            investmentToken,
            amountOfInvestmentTokens,
            extraInfo
        );

        IERC20(investmentToken).transferFrom(msg.sender, address(escrow), amountOfInvestmentTokens);

        fundingNFT.mintGen0(address(escrow), investmentDetails[totalInvestments].totalPartitionsToBePurchased, totalInvestments);

        investmentTokensPerTicket[totalInvestments] = amountOfInvestmentTokens.div(investmentDetails[totalInvestments].totalPartitionsToBePurchased);

        fundingNFT.pauseTokenTransfer(totalInvestments); //Pause trades for ERC1155s with the specific investment ID.

        governance.requestApproval(totalInvestments);

        // Add event for investment request
        emit InvestmentRequested(totalInvestments, msg.sender, totalAmountRequested_);

        totalInvestments = totalInvestments.add(1);
    }

    /**
     * @notice user show interest for investment
     * @dev This function is called by the investors who are interested to invest in a specific project.
     * @dev require Approval state and valid partition
     * @param investmentId The id of the investment.
     * @param amountOfPartitions The amount of partitions this specific investor wanna invest in.
     */
    function showInterestForInvestment(uint256 investmentId, uint256 amountOfPartitions) external {
        require(
            investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.APPROVED,
            "Can show interest only in Approved state"
        );
        require(amountOfPartitions > 0, "Cannot show interest for 0 partitions");

        lendingToken.transferFrom(msg.sender, address(escrow), amountOfPartitions.mul(baseAmountForEachPartition));

        investmentDetails[investmentId].partitionsRequested = investmentDetails[investmentId].partitionsRequested.add(
            amountOfPartitions
        );

        uint256 reputationalBalance = _updateReputationalBalanceForPreviouslyLockedTokens();
        uint256 totalLotteryNumbers = reputationalBalance.div(rAlbtPerLotteryNumber);

        if (totalLotteryNumbers == 0) revert("Not elegible for lottery numbers");

        uint256 immediateTickets;

        // TODO - Explain this check to Rachid.
        if (totalLotteryNumbers > lotteryNumbersForImmediateTicket) {
            uint256 rest = totalLotteryNumbers.mod(lotteryNumbersForImmediateTicket);
            immediateTickets = totalLotteryNumbers.sub(rest).div(lotteryNumbersForImmediateTicket);
            totalLotteryNumbers = rest;
        }

        if (immediateTickets > amountOfPartitions) immediateTickets = amountOfPartitions;

        // Just in case we provided immediate tickets and tickets finished, so there is no lottery in this case.
        if (immediateTickets > ticketsRemaining[investmentId]) {
            immediateTickets = ticketsRemaining[investmentId];
            investmentStatus[investmentId] = InvestmentLibrary.InvestmentStatus.SETTLED;

            return;
        }

        if (immediateTickets > 0) {
            ticketsWonPerAddress[investmentId][msg.sender] = immediateTickets;
            ticketsRemaining[investmentId] = ticketsRemaining[investmentId].sub(immediateTickets);
        }

        remainingTicketsPerAddress[investmentId][msg.sender] = amountOfPartitions.sub(immediateTickets);

        uint256 maxLotteryNumber = totalLotteryNumbersPerInvestment[investmentId].add(totalLotteryNumbers);

        for (uint256 i = totalLotteryNumbersPerInvestment[investmentId].add(1); i <= maxLotteryNumber; i++) {
            addressOfLotteryNumber[investmentId][i] = msg.sender;
        }

        totalLotteryNumbersPerInvestment[investmentId] = maxLotteryNumber;
    }

    /**
     * @notice Executes lottery run
     * @dev This function is called by any investor interested in a project to run part of the lottery.
     * @dev requires Started state and available tickets
     * @param investmentId The id of the investment.
     */
    function executeLotteryRun(uint256 investmentId) external {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.STARTED, "Can run lottery only in Started state");
        require(
            remainingTicketsPerAddress[investmentId][msg.sender] > 0,
            "Can run lottery only if has remaining ticket"
        );

        ticketsWonPerAddress[investmentId][msg.sender] = ticketsWonPerAddress[investmentId][msg.sender].add(1);
        remainingTicketsPerAddress[investmentId][msg.sender] = remainingTicketsPerAddress[investmentId][msg.sender].sub(
            1
        );
        ticketsRemaining[investmentId] = ticketsRemaining[investmentId].sub(1);

        uint256 counter = totalTicketsPerRun;
        uint256 maxNumber = totalLotteryNumbersPerInvestment[investmentId];

        if (ticketsRemaining[investmentId] <= counter) {
            investmentStatus[investmentId] = InvestmentLibrary.InvestmentStatus.SETTLED;
            counter = ticketsRemaining[investmentId];
            ticketsRemaining[investmentId] = 0;
        } else {
            ticketsRemaining[investmentId] = ticketsRemaining[investmentId].sub(counter);
        }

        for (uint256 i = counter; i > 0; i--) {
            uint256 randomNumber = _getRandomNumber(maxNumber);
            lotteryNonce = lotteryNonce.add(1);

            address randomAddress = addressOfLotteryNumber[investmentId][randomNumber.add(1)];

            if (remainingTicketsPerAddress[investmentId][randomAddress] > 0) {
                remainingTicketsPerAddress[investmentId][randomAddress] = remainingTicketsPerAddress[investmentId][
                    randomAddress
                ]
                    .sub(1);

                ticketsWonPerAddress[investmentId][randomAddress] = ticketsWonPerAddress[investmentId][randomAddress]
                    .add(1);
            }
        }
    }

    /**
     * @notice Withdraw Investment Tickets
     * @dev This function is called by an investor to withdraw his tickets.
     * @dev require Settled state and enough tickets won
     * @param investmentId The id of the investment.
     * @param ticketsToLock The amount of won tickets to be locked, so as to get more rALBT.
     * @param ticketsToWithdraw The amount of won tickets to be withdrawn instantly.
     */
    function withdrawInvestmentTickets(
        uint256 investmentId,
        uint256 ticketsToLock,
        uint256 ticketsToWithdraw
    ) external {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.SETTLED, "Can withdraw only in Settled state");
        require(
            ticketsWonPerAddress[investmentId][msg.sender] > 0 &&
                ticketsWonPerAddress[investmentId][msg.sender] >= ticketsToLock.add(ticketsToWithdraw),
            "Not enough tickets won"
        );

        ticketsWonPerAddress[investmentId][msg.sender] = ticketsWonPerAddress[investmentId][msg.sender]
            .sub(ticketsToLock)
            .sub(ticketsToWithdraw);

        _updateReputationalBalanceForPreviouslyLockedTokens();

        if (ticketsToLock > 0) {
            lockedTicketsForSpecificInvestmentPerAddress[investmentId][
                msg.sender
            ] = lockedTicketsForSpecificInvestmentPerAddress[investmentId][msg.sender].add(ticketsToLock);

            lockedTicketsPerAddress[msg.sender] = lockedTicketsPerAddress[msg.sender].add(ticketsToLock);
        }

        if (ticketsToWithdraw > 0) {
            uint256 amountToWithdraw = investmentTokensPerTicket[investmentId].mul(ticketsToWithdraw);
            escrow.transferProjectToken(investmentDetails[investmentId].projectToken, msg.sender, amountToWithdraw);
        }

        if (remainingTicketsPerAddress[investmentId][msg.sender] > 0) {
            _withdrawAmountProvidedForNonWonTickets(investmentId);
        }
    }

    /**
     * @dev This function is called by an investor to withdraw lending tokens provided for non-won tickets.
     * @param investmentId The id of the investment.
     */
    function withdrawAmountProvidedForNonWonTickets(uint256 investmentId) external {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.SETTLED, "Can withdraw only in Settled state");
        require(remainingTicketsPerAddress[investmentId][msg.sender] > 0, "No non-won tickets to withdraw");

        _withdrawAmountProvidedForNonWonTickets(investmentId);
    }

    /**
     * @notice Withdraw locked investment ticket.
     * @dev This function is called by an investor to withdraw his locked tickets.
     * @dev requires Settled state and available tickets.
     * @param investmentId The id of the investment.
     * @param ticketsToWithdraw The amount of locked tickets to be withdrawn.
     */
    function withdrawLockedInvestmentTickets(uint256 investmentId, uint256 ticketsToWithdraw) external {
        require(investmentStatus[investmentId] == InvestmentLibrary.InvestmentStatus.SETTLED, "Can withdraw only in Settled state");
        require(
            ticketsToWithdraw > 0 &&
                lockedTicketsForSpecificInvestmentPerAddress[investmentId][msg.sender] >= ticketsToWithdraw,
            "Not enough tickets to withdraw"
        );

        _updateReputationalBalanceForPreviouslyLockedTokens();

        lockedTicketsForSpecificInvestmentPerAddress[investmentId][
            msg.sender
        ] = lockedTicketsForSpecificInvestmentPerAddress[investmentId][msg.sender].sub(ticketsToWithdraw);

        lockedTicketsPerAddress[msg.sender] = lockedTicketsPerAddress[msg.sender].sub(ticketsToWithdraw);

        uint256 amountToWithdraw = investmentTokensPerTicket[investmentId].mul(ticketsToWithdraw);
        escrow.transferProjectToken(investmentDetails[investmentId].projectToken, msg.sender, amountToWithdraw);
    }

    /**
     * @notice Gets Requesting status
     * @dev Returns true if investors have shown interest for equal or more than the total tickets.
     * @param investmentId The id of the investment type to be checked.
     */
    function getRequestingInterestStatus(uint256 investmentId) external view returns (bool) {
        return investmentDetails[investmentId].totalPartitionsToBePurchased <= investmentDetails[investmentId].partitionsRequested;
    }

    /**
     * @notice Generates Random Number
     * @dev This function generates a random number
     * @param maxNumber the max number possible
     * @return randomNumber the random number generated
     */
    function _getRandomNumber(uint256 maxNumber) internal view returns (uint256 randomNumber) {
        randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, lotteryNonce, blockhash(block.number), msg.sender)
            )
        )
            .mod(maxNumber);
    }

    /**
     * @notice Updates reputation balance
     * @dev updates balance of reputation for locked tokens
     * @return the reputation balance of msg.sender
     */
    function _updateReputationalBalanceForPreviouslyLockedTokens() internal returns (uint256) {
        if (lockedTicketsPerAddress[msg.sender] > 0) {
            uint256 amountOfReputationalAlbtPerTicket =
                (block.number.sub(lastBlockCheckedForLockedTicketsPerAddress[msg.sender])).div(
                    blocksLockedForReputation
                );

            uint256 amountOfReputationalAlbtToMint =
                amountOfReputationalAlbtPerTicket.mul(lockedTicketsPerAddress[msg.sender]);

            if (amountOfReputationalAlbtToMint > 0)
                escrow.mintReputationalToken(msg.sender, amountOfReputationalAlbtToMint);

            lastBlockCheckedForLockedTicketsPerAddress[msg.sender] = block.number;
        }

        return rALBT.balanceOf(msg.sender);
    }

    function _withdrawAmountProvidedForNonWonTickets(uint256 investmentId_) internal {
        uint256 amountToReturnForNonWonTickets =
            remainingTicketsPerAddress[investmentId_][msg.sender].mul(baseAmountForEachPartition);
        remainingTicketsPerAddress[investmentId_][msg.sender] = 0;

        escrow.transferLendingToken(msg.sender, amountToReturnForNonWonTickets);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Storage.sol";
import "../libs/TokenFormat.sol";

/**
 * @title AllianceBlock InvestmentDetails contract
 * @notice Functionality for storing investment details and modifiers.
 * @dev Extends Storage
 */
contract InvestmentDetails is Storage {
    using SafeMath for uint256;
    using TokenFormat for uint256;

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "Only Governance");
        _;
    }

    /**
     * @notice Stores Investment Details
     * @dev require a valid interest percentage
     * @param amountRequestedToBeRaised_ the amount requested
     * @param projectToken_ the project token
     * @param projectTokensAmount_ the amount of project tokens provided
     * @param extraInfo_ the IPFS hard data provided
     */
    function _storeInvestmentDetails(
        uint256 amountRequestedToBeRaised_,
        address projectToken_,
        uint256 projectTokensAmount_,
        string memory extraInfo_
    ) internal {
        InvestmentLibrary.InvestmentDetails memory investment;
        investment.investmentId = totalInvestments;
        investment.projectToken = projectToken_;
        investment.projectTokensAmount = projectTokensAmount_;
        investment.totalAmountToBeRaised = amountRequestedToBeRaised_;
        investment.extraInfo = extraInfo_;
        investment.totalPartitionsToBePurchased = amountRequestedToBeRaised_.div(baseAmountForEachPartition);

        investmentDetails[totalInvestments] = investment;

        investmentStatus[totalInvestments] = InvestmentLibrary.InvestmentStatus.REQUESTED;
        investmentSeeker[totalInvestments] = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/InvestmentLibrary.sol";
import "../interfaces/IERC1155Mint.sol";
import "../interfaces/IGovernance.sol";
import "../interfaces/IEscrow.sol";

/**
 * @title AllianceBlock Storage contract
 * @notice Responsible for investment storage
 */
contract Storage {
    uint256 public totalInvestments; // The total amount of investment requests.

    // Mapping from investment id -> details for each and every investment.
    mapping(uint256 => InvestmentLibrary.InvestmentDetails) public investmentDetails;
    // Mapping from investment id -> investment status.
    mapping(uint256 => InvestmentLibrary.InvestmentStatus) public investmentStatus;
    // Mapping from investment id -> investment seeker's address.
    mapping(uint256 => address) public investmentSeeker;
    // The amount of investment tokens each ticket contains.
    mapping(uint256 => uint256) public investmentTokensPerTicket;
    // The amount of tickets remaining to be allocated to investors.
    mapping(uint256 => uint256) public ticketsRemaining;
    // The number lottery numbers allocated from all investors for a specific investment.
    mapping(uint256 => uint256) public totalLotteryNumbersPerInvestment;
    // The address of the investor that has allocated a specific lottery number on a specific investment.
    mapping(uint256 => mapping(uint256 => address)) public addressOfLotteryNumber;
    // The amount of tickets that an investor requested that are still not allocated.
    mapping(uint256 => mapping(address => uint256)) public remainingTicketsPerAddress;
    // The amount of tickets that an investor requested that have been won already.
    mapping(uint256 => mapping(address => uint256)) public ticketsWonPerAddress;
    // The amount of tickets that an investor locked for a specific investment.
    mapping(uint256 => mapping(address => uint256)) public lockedTicketsForSpecificInvestmentPerAddress;
    // The amount of tickets that an investor locked from all investments.
    mapping(address => uint256) public lockedTicketsPerAddress;
    // The last block checked for rewards for the tickets locked per address.
    mapping(address => uint256) public lastBlockCheckedForLockedTicketsPerAddress;

    IGovernance public governance; // Governance's contract address.
    IERC20 public lendingToken; // Lending token's contract address.
    IERC1155Mint public fundingNFT; // Funding nft's contract address.
    IEscrow public escrow; // Escrow's contract address.
    IERC20 public rALBT; // rALBT's contract address.

    // This variable represents the base amount in which every investment amount is divided to. (also the starting value for each ERC1155)
    uint256 public baseAmountForEachPartition;
    // The amount of tickets to be provided by each run of the lottery.
    uint256 public totalTicketsPerRun;
    // The amount of rALBT needed to allocate one lottery number.
    uint256 public rAlbtPerLotteryNumber;
    // The amount of blocks needed for a ticket to be locked, so as the investor to get 1 rALBT.
    uint256 public blocksLockedForReputation;
    // The amount of lottery numbers, that if investor has after number allocation he gets one ticket without lottery.
    uint256 public lotteryNumbersForImmediateTicket;
    // The nonce for the lottery numbers.
    uint256 internal lotteryNonce;
}

