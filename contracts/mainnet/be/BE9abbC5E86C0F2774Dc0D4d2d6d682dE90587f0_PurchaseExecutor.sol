// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/GeneralTokenVesting.sol";
import "./interfaces/Finance.sol";

/**
 * @title PurchaseExecutor
 * @dev allow a whitelisted set of addresses to purchase SARCO tokens, for stablecoins (USDC), at a set rate
 */
contract PurchaseExecutor is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public USDC_TOKEN;
    IERC20 public SARCO_TOKEN;
    address public GENERAL_TOKEN_VESTING;
    address public SARCO_DAO;
    uint256 public usdc_to_sarco_precision = 10**18;
    uint256 public sarco_to_usdc_decimal_fix = 10**(18 - 6);

    uint256 public usdc_to_sarco_rate;
    uint256 public sarco_allocations_total;
    mapping(address => uint256) public sarco_allocations;

    // Timing in seconds
    uint256 public offer_expiration_delay;
    uint256 public offer_started_at;
    uint256 public offer_expires_at;
    uint256 public vesting_end_delay;

    // The purchase has been executed exchanging USDC to vested SARCO
    event PurchaseExecuted(
        // the address that has received the vested SARCO tokens
        address indexed sarco_receiver,
        // the number of SARCO tokens vested to sarco_receiver
        uint256 sarco_allocation,
        // the amount of USDC that was paid and forwarded to the DAO
        uint256 usdc_cost
    );

    // Creates a window of time which the whitelisted set of addresses may purchase SARCO
    event OfferStarted(
        // Window start time
        uint256 started_at,
        // Window end time
        uint256 expires_at
    );

    // If tokens have not been purchased after time window, the DAO can recover tokens
    event TokensRecovered(
        // Amount of Tokens
        uint256 amount
    );

    /**
     * @dev inits/sets sarco purchase enviorment
     * @param _usdc_to_sarco_rate How much SARCO one gets for one USDC
     * @param _vesting_end_delay Delay from the purchase moment to the vesting end moment, in seconds
     * @param _offer_expiration_delay Delay from the contract deployment to offer expiration, in seconds
     * @param _sarco_purchasers  List of valid SARCO purchasers
     * @param _sarco_allocations List of SARCO token allocations, should include decimals 10 ** 18
     * @param _sarco_allocations_total Checksum of SARCO token allocations, should include decimals 10 ** 18
     * @param _usdc_token USDC token address
     * @param _sarco_token Sarco token address
     * @param _general_token_vesting GeneralTokenVesting contract address
     * @param _sarco_dao Sarco DAO contract address
     */
    constructor(
        uint256 _usdc_to_sarco_rate,
        uint256 _vesting_end_delay,
        uint256 _offer_expiration_delay,
        address[] memory _sarco_purchasers,
        uint256[] memory _sarco_allocations,
        uint256 _sarco_allocations_total,
        address _usdc_token,
        address _sarco_token,
        address _general_token_vesting,
        address _sarco_dao
    ) {
        require(
            _usdc_to_sarco_rate > 0,
            "PurchaseExecutor: _usdc_to_sarco_rate must be greater than 0"
        );
        require(
            _vesting_end_delay > 0,
            "PurchaseExecutor: end_delay must be greater than 0"
        );
        require(
            _offer_expiration_delay > 0,
            "PurchaseExecutor: offer_expiration must be greater than 0"
        );
        require(
            _sarco_purchasers.length == _sarco_allocations.length,
            "PurchaseExecutor: purchasers and allocations lengths must be equal"
        );
        require(
            _usdc_token != address(0),
            "PurchaseExecutor: _usdc_token cannot be 0 address"
        );
        require(
            _sarco_token != address(0),
            "PurchaseExecutor: _sarco_token cannot be 0 address"
        );
        require(
            _general_token_vesting != address(0),
            "PurchaseExecutor: _general_token_vesting cannot be 0 address"
        );
        require(
            _sarco_dao != address(0),
            "PurchaseExecutor: _sarco_dao cannot be 0 address"
        );

        // Set global variables
        usdc_to_sarco_rate = _usdc_to_sarco_rate;
        vesting_end_delay = _vesting_end_delay;
        offer_expiration_delay = _offer_expiration_delay;
        sarco_allocations_total = _sarco_allocations_total;
        USDC_TOKEN = IERC20(_usdc_token);
        SARCO_TOKEN = IERC20(_sarco_token);
        GENERAL_TOKEN_VESTING = _general_token_vesting;
        SARCO_DAO = _sarco_dao;

        uint256 allocations_sum = 0;

        for (uint256 i = 0; i < _sarco_purchasers.length; i++) {
            address purchaser = _sarco_purchasers[i];
            require(
                purchaser != address(0),
                "PurchaseExecutor: Purchaser cannot be the ZERO address"
            );
            require(
                sarco_allocations[purchaser] == 0,
                "PurchaseExecutor: Allocation has already been set"
            );
            uint256 allocation = _sarco_allocations[i];
            require(
                allocation > 0,
                "PurchaseExecutor: No allocated Sarco tokens for address"
            );
            sarco_allocations[purchaser] = allocation;
            allocations_sum += allocation;
        }
        require(
            allocations_sum == _sarco_allocations_total,
            "PurchaseExecutor: Allocations_total does not equal the sum of passed allocations"
        );

        // Approve SarcoDao - PurchaseExecutor's total USDC tokens (Execute Purchase)
        USDC_TOKEN.approve(
            _sarco_dao,
            get_usdc_cost(_sarco_allocations_total)
        );

        // Approve full SARCO amount to GeneralTokenVesting contract
        SARCO_TOKEN.approve(GENERAL_TOKEN_VESTING, _sarco_allocations_total);

        // Approve SarcoDao - Purchase Executor's total SARCO tokens (Recover Tokens)
        SARCO_TOKEN.approve(_sarco_dao, _sarco_allocations_total);
    }

    function get_usdc_cost(uint256 sarco_amount)
        internal
        view
        returns (uint256)
    {
        return
            ((sarco_amount * usdc_to_sarco_precision) / usdc_to_sarco_rate) /
            sarco_to_usdc_decimal_fix;
    }

    function offer_started() public view returns (bool) {
        return offer_started_at != 0;
    }

    function offer_expired() public view returns (bool) {
        return block.timestamp >= offer_expires_at;
    }

    /**
     * @notice Starts the offer if it 1) hasn't been started yet and 2) has received funding in full.
     */
    function _start_unless_started() internal {
        require(
            offer_started_at == 0,
            "PurchaseExecutor: Offer has already started"
        );
        require(
            SARCO_TOKEN.balanceOf(address(this)) == sarco_allocations_total,
            "PurchaseExecutor: Insufficient Sarco contract balance to start offer"
        );

        offer_started_at = block.timestamp;
        offer_expires_at = block.timestamp + offer_expiration_delay;
        emit OfferStarted(offer_started_at, offer_expires_at);
    }

    function start() external {
        _start_unless_started();
    }

    /**
     * @dev Returns the Sarco allocation and the USDC cost to purchase the Sarco Allocation of the whitelisted Sarco Purchaser
     * @param sarco_receiver Whitelisted Sarco Purchaser
     * @return A tuple: the first element is the amount of SARCO available for purchase (zero if
        the purchase was already executed for that address), the second element is the
        USDC cost of the purchase.
     */
    function get_allocation(address sarco_receiver)
        public
        view
        returns (uint256, uint256)
    {
        uint256 sarco_allocation = sarco_allocations[sarco_receiver];
        uint256 usdc_cost = get_usdc_cost(sarco_allocation);

        return (sarco_allocation, usdc_cost);
    }

    /**
     * @dev Purchases Sarco for the specified address in exchange for USDC.
     * @notice Sends USDC tokens used to purchase Sarco to Sarco DAO, 
     Approves GeneralTokenVesting contract Sarco Tokens to utilizes allocated Sarco funds,
     Starts token vesting via GeneralTokenVesting contract.
     * @param sarco_receiver Whitelisted Sarco Purchaser
     */
    function execute_purchase(address sarco_receiver) external {
        if (offer_started_at == 0) {
            _start_unless_started();
        }
        require(
            block.timestamp < offer_expires_at,
            "PurchaseExecutor: Purchases cannot be made after the offer has expired"
        );

        (uint256 sarco_allocation, uint256 usdc_cost) = get_allocation(msg.sender);

        // Check sender's allocation
        require(
            sarco_allocation > 0,
            "PurchaseExecutor: sender does not have a SARCO allocation"
        );

        // Clear sender's allocation
        sarco_allocations[msg.sender] = 0;

        // transfer sender's USDC to this contract
        USDC_TOKEN.safeTransferFrom(msg.sender, address(this), usdc_cost);

        // Dynamically Build finance app's "message" string
        string memory _executedPurchaseString = string(
            abi.encodePacked(
                "Purchase Executed by account: ",
                Strings.toHexString(uint160(msg.sender), 20),
                " for account: ",
                Strings.toHexString(uint160(sarco_receiver), 20),
                ". Total SARCOs Purchased: ",
                Strings.toString(sarco_allocation),
                "."
            )
        );

        // Forward USDC cost of the purchase to the DAO contract via the Finance Deposit method
        Finance(SARCO_DAO).deposit(
            address(USDC_TOKEN),
            usdc_cost,
            _executedPurchaseString
        );

        // Call GeneralTokenVesting startVest method
        GeneralTokenVesting(GENERAL_TOKEN_VESTING).startVest(
            sarco_receiver,
            sarco_allocation,
            vesting_end_delay,
            address(SARCO_TOKEN)
        );

        emit PurchaseExecuted(sarco_receiver, sarco_allocation, usdc_cost);
    }

    /**
     * @dev If unsold_sarco_amount > 0 after the offer expired, sarco tokens are send back to Sarco Dao via Finance Contract.
     */
    function recover_unsold_tokens() external {
        require(
            offer_started(),
            "PurchaseExecutor: Purchase offer has not yet started"
        );
        require(
            offer_expired(),
            "PurchaseExecutor: Purchase offer has not yet expired"
        );

        uint256 unsold_sarco_amount = SARCO_TOKEN.balanceOf(address(this));

        require(
            unsold_sarco_amount > 0,
            "PurchaseExecutor: There are no Sarco tokens to recover"
        );

        // Dynamically Build finance app's "message" string
        string memory _recoverTokensString = "Recovered unsold SARCO tokens";

        // Forward recoverable SARCO tokens to the DAO contract via the Finance Deposit method
        Finance(SARCO_DAO).deposit(
            address(SARCO_TOKEN),
            unsold_sarco_amount,
            _recoverTokensString
        );

        // zero out token approvals that this contract has given in its constructor
        USDC_TOKEN.approve(SARCO_DAO, 0);
        SARCO_TOKEN.approve(GENERAL_TOKEN_VESTING, 0);
        SARCO_TOKEN.approve(SARCO_DAO, 0);

        emit TokensRecovered(unsold_sarco_amount);
    }

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     * @param recipientAddress The address to send tokens to
     */
    function recover_erc20(address tokenAddress, uint256 tokenAmount, address recipientAddress) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(recipientAddress, tokenAmount);
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
    constructor () {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface GeneralTokenVesting {
    function startVest(
        address beneficiary,
        uint256 tokensToVest,
        uint256 vestDuration,
        address tokenAddress
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Finance {
    function deposit(
        address _token,
        uint256 _value,
        string memory _reference
    ) external payable;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}