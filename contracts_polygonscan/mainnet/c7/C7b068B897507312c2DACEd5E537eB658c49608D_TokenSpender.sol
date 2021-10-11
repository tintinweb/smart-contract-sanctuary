/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

/**
 *Submitted for verification at Etherscan.io on 2020-03-24
*/

/**

  Source code of Opium Protocol
  Web https://opium.network
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

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

// File: erc721o/contracts/Interfaces/IERC721O.sol

pragma solidity ^0.5.4;

contract IERC721O {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);

  function implementsERC721O() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function balanceOf(address owner) public view returns (uint256);
  function balanceOf(address owner, uint256 tokenId) public view returns (uint256);
  function tokensOwned(address owner) public view returns (uint256[] memory, uint256[] memory);

  function transfer(address to, uint256 tokenId, uint256 quantity) public;
  function transferFrom(address from, address to, uint256 tokenId, uint256 quantity) public;

  // Fungible Safe Transfer From
  function safeTransferFrom(address from, address to, uint256 tokenId, uint256 _amount) public;
  function safeTransferFrom(address from, address to, uint256 tokenId, uint256 _amount, bytes memory data) public;

  // Batch Safe Transfer From
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory tokenIds, uint256[] memory _amounts, bytes memory _data) public;

  // Required Events
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event TransferWithQuantity(address indexed from, address indexed to, uint256 indexed tokenId, uint256 quantity);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event BatchTransfer(address indexed from, address indexed to, uint256[] tokenTypes, uint256[] amounts);
  event Composition(uint256 portfolioId, uint256[] tokenIds, uint256[] tokenRatio);
}

// File: contracts/Lib/Whitelisted.sol

pragma solidity 0.5.16;

/// @title Opium.Lib.Whitelisted contract implements whitelist with modifier to restrict access to only whitelisted addresses
contract Whitelisted {
    // Whitelist array
    address[] internal whitelist;

    /// @notice This modifier restricts access to functions, which could be called only by whitelisted addresses
    modifier onlyWhitelisted() {
        // Allowance flag
        bool allowed = false;

        // Going through whitelisted addresses array
        uint256 whitelistLength = whitelist.length;
        for (uint256 i = 0; i < whitelistLength; i++) {
            // If `msg.sender` is met within whitelisted addresses, raise the flag and exit the loop
            if (whitelist[i] == msg.sender) {
                allowed = true;
                break;
            }
        }

        // Check if flag was raised
        require(allowed, "Only whitelisted allowed");
        _;
    }

    /// @notice Getter for whitelisted addresses array
    /// @return Array of whitelisted addresses
    function getWhitelist() public view returns (address[] memory) {
        return whitelist;
    }
}

// File: contracts/Lib/WhitelistedWithGovernance.sol

pragma solidity 0.5.16;


/// @title Opium.Lib.WhitelistedWithGovernance contract implements Opium.Lib.Whitelisted and adds governance for whitelist controlling
contract WhitelistedWithGovernance is Whitelisted {
    // Emitted when new governor is set
    event GovernorSet(address governor);

    // Emitted when new whitelist is proposed
    event Proposed(address[] whitelist);
    // Emitted when proposed whitelist is committed (set)
    event Committed(address[] whitelist);

    // Proposal life timelock interval
    uint256 public timeLockInterval;

    // Governor address
    address public governor;

    // Timestamp of last proposal
    uint256 public proposalTime;

    // Proposed whitelist
    address[] public proposedWhitelist;

    /// @notice This modifier restricts access to functions, which could be called only by governor
    modifier onlyGovernor() {
        require(msg.sender == governor, "Only governor allowed");
        _;
    }

    /// @notice Contract constructor
    /// @param _timeLockInterval uint256 Initial value for timelock interval
    /// @param _governor address Initial value for governor
    constructor(uint256 _timeLockInterval, address _governor) public {
        timeLockInterval = _timeLockInterval;
        governor = _governor;
        emit GovernorSet(governor);
    }

    /// @notice Calling this function governor could propose new whitelist addresses array. Also it allows to initialize first whitelist if it was not initialized yet.
    function proposeWhitelist(address[] memory _whitelist) public onlyGovernor {
        // Restrict empty proposals
        require(_whitelist.length != 0, "Can't be empty");

        // Consider empty whitelist as not initialized, as proposing of empty whitelists is not allowed
        // If whitelist has never been initialized, we set whitelist right away without proposal
        if (whitelist.length == 0) {
            whitelist = _whitelist;
            emit Committed(_whitelist);

        // Otherwise save current time as timestamp of proposal, save proposed whitelist and emit event
        } else {
            proposalTime = now;
            proposedWhitelist = _whitelist;
            emit Proposed(_whitelist);
        }
    }

    /// @notice Calling this function governor commits proposed whitelist if timelock interval of proposal was passed
    function commitWhitelist() public onlyGovernor {
        // Check if proposal was made
        require(proposalTime != 0, "Didn't proposed yet");

        // Check if timelock interval was passed
        require((proposalTime + timeLockInterval) < now, "Can't commit yet");

        // Set new whitelist and emit event
        whitelist = proposedWhitelist;
        emit Committed(whitelist);

        // Reset proposal time lock
        proposalTime = 0;
    }

    /// @notice This function allows governor to transfer governance to a new governor and emits event
    /// @param _governor address Address of new governor
    function setGovernor(address _governor) public onlyGovernor {
        require(_governor != address(0), "Can't set zero address");
        governor = _governor;
        emit GovernorSet(governor);
    }
}

// File: contracts/Lib/WhitelistedWithGovernanceAndChangableTimelock.sol

pragma solidity 0.5.16;


/// @notice Opium.Lib.WhitelistedWithGovernanceAndChangableTimelock contract implements Opium.Lib.WhitelistedWithGovernance and adds possibility for governor to change timelock interval within timelock interval
contract WhitelistedWithGovernanceAndChangableTimelock is WhitelistedWithGovernance {
    // Emitted when new timelock is proposed
    event Proposed(uint256 timelock);
    // Emitted when new timelock is committed (set)
    event Committed(uint256 timelock);

    // Timestamp of last timelock proposal
    uint256 public timeLockProposalTime;
    // Proposed timelock
    uint256 public proposedTimeLock;

    /// @notice Calling this function governor could propose new timelock
    /// @param _timelock uint256 New timelock value
    function proposeTimelock(uint256 _timelock) public onlyGovernor {
        timeLockProposalTime = now;
        proposedTimeLock = _timelock;
        emit Proposed(_timelock);
    }

    /// @notice Calling this function governor could commit previously proposed new timelock if timelock interval of proposal was passed
    function commitTimelock() public onlyGovernor {
        // Check if proposal was made
        require(timeLockProposalTime != 0, "Didn't proposed yet");
        // Check if timelock interval was passed
        require((timeLockProposalTime + timeLockInterval) < now, "Can't commit yet");

        // Set new timelock and emit event
        timeLockInterval = proposedTimeLock;
        emit Committed(proposedTimeLock);

        // Reset timelock time lock
        timeLockProposalTime = 0;
    }
}

// File: contracts/TokenSpender.sol

pragma solidity 0.5.16;





/// @title Opium.TokenSpender contract holds users ERC20 approvals and allows whitelisted contracts to use tokens
contract TokenSpender is WhitelistedWithGovernanceAndChangableTimelock {
    using SafeERC20 for IERC20;

    // Initial timelock period
    uint256 public constant WHITELIST_TIMELOCK = 1 hours;

    /// @notice Calls constructors of super-contracts
    /// @param _governor address Address of governor, who is allowed to adjust whitelist
    constructor(address _governor) public WhitelistedWithGovernance(WHITELIST_TIMELOCK, _governor) {}

    /// @notice Using this function whitelisted contracts could call ERC20 transfers
    /// @param token IERC20 Instance of token
    /// @param from address Address from which tokens are transferred
    /// @param to address Address of tokens receiver
    /// @param amount uint256 Amount of tokens to be transferred
    function claimTokens(IERC20 token, address from, address to, uint256 amount) external onlyWhitelisted {
        token.safeTransferFrom(from, to, amount);
    }

    /// @notice Using this function whitelisted contracts could call ERC721O transfers
    /// @param token IERC721O Instance of token
    /// @param from address Address from which tokens are transferred
    /// @param to address Address of tokens receiver
    /// @param tokenId uint256 Token ID to be transferred
    /// @param amount uint256 Amount of tokens to be transferred
    function claimPositions(IERC721O token, address from, address to, uint256 tokenId, uint256 amount) external onlyWhitelisted {
        token.safeTransferFrom(from, to, tokenId, amount);
    }
}