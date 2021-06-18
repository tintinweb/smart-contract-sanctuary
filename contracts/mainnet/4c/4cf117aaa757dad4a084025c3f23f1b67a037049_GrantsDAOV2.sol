/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/utils/Address.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/IERC20.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/SafeERC20.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol

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

// File: contracts/GrantsDAOV2.sol

pragma solidity ^0.5.16;





contract GrantsDAOV2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public grantsCount;
    uint256 public initiativesCount;
    uint256 public competitionCount;

    mapping(string => Grant) public grants;
    mapping(string => Initiative) public initiatives;
    mapping(string => Competition) public competitions;

    /**
     * @notice The enum for the possible states that a grant can be in
     * ACTIVE - when the grant is initially created on the contract
     * COMPLETED - when all the milestones are paid out
     * CANCELLED - when a grant fails to reach all milestone payments
     */
    enum GrantState {ACTIVE, COMPLETED, CANCELLED}

    /**
     * @notice The enum for the possible states that a grant can be in
     * OPEN - when an initiative is open for someone to take up
     * ASSIGNED - when an initiative is assigned to someone
     * COMPLETED -  when all the milestones are paid out
     * CANCELLED - when a initiative fails to reach all milestone payments
     */
    enum InitiativeState {OPEN, ASSIGNED, COMPLETED, CANCELLED}

    /**
     * @notice The enum for the possible states that a competition can be in
     * ACTIVE - when the competition is initially created on the contract
     * COMPLETED - when a competition has been concluded successfully
     * CANCELLED - when a competition fails to be completed
     */
    enum CompetitionState {ACTIVE, COMPLETED, CANCELLED}

    /**
     * @notice A struct representing a grant
     */
    struct Grant {
        string grantHash;
        string title;
        string description;
        uint256[] milestones;
        address paymentCurrency;
        string proposer;
        address receivingAddress;
        uint256 currentMilestone;
        uint256 createdAt;
        uint256 modifiedAt;
        GrantState state;
    }

    /**
     * @notice A struct representing a initiative
     */
    struct Initiative {
        string initiativeHash;
        string title;
        string description;
        uint256[] milestones;
        address paymentCurrency;
        address receivingAddress;
        uint256 currentMilestone;
        uint256 createdAt;
        uint256 modifiedAt;
        InitiativeState state;
    }

    /**
     * @notice A struct representing a competition or hackathon bounty
     */
    struct Competition {
        string competitionHash;
        string title;
        string description;
        address paymentCurrency;
        uint256 totalBounty;
        uint256[] placeAmounts;
        uint256 createdAt;
        uint256 modifiedAt;
        CompetitionState state;
    }

    /**
     * @notice Event emitted when a new grant is created
     */
    event NewGrant(string indexed grantHash, string proposer, address receivingAddress);

    /**
     * @notice Event emitted when a new grant is created
     */
    event NewInitiative(string indexed initiativeHash);

    /**
     * @notice Event emitted when a new competition is created
     */
    event NewCompetition(string indexed competitionHash);

    /**
     * @notice Event emitted when an initiative is assigned
     */
    event InitiativeAssigned(string indexed initiativeHash, address assignee);

    /**
     * @notice Event emitted when an grant is re-assigned
     */
    event GrantReassigned(string indexed grantHash, address assignee);

    /**
     * @notice Event emitted when a grant milestone is paid
     */
    event GrantMilestoneReleased(string indexed grantHash, uint256 amount, address receiver, address paymentCurrency);

    /**
     * @notice Event emitted when an initiative milestone is paid
     */
    event InitiativeMilestoneReleased(
        string indexed initiativeHash,
        uint256 amount,
        address receiver,
        address paymentCurrency
    );

    /**
     * @notice Event emitted when an grant is completed
     */
    event GrantCompleted(string indexed grantHash);

    /**
     * @notice Event emitted when an initiative is completed
     */
    event InitiativeCompleted(string indexed initiativeHash);

    /**
     * @notice Event emitted when an competition is completed
     */
    event CompetitionCompleted(string indexed competitionHash);

    /**
     * @notice Event emitted when an grant is cancelled
     */
    event GrantCancelled(string indexed grantHash, string reason);

    /**
     * @notice Event emitted when an initiative is cancelled
     */
    event InitiativeCancelled(string indexed initiativeHash, string reason);

    /**
     * @notice Event emitted when an competition is cancelled
     */
    event CompetitionCancelled(string indexed competitionHash, string reason);

    /**
     * @notice Event emitted when a withdrawal from the contract occurs
     */
    event Withdrawal(address indexed receiver, uint256 amount, address token);

    /**
     * @notice Contract is created by a deployer who then sets the grantsDAO multisig to be the owner
     */
    constructor() public {}

    /**
     * @notice Called by the owners (gDAO multisig) to create a new grant
     * Emits NewGrant event.
     * @param _grantHash The ipfs hash of a grant (retrieved from the snapshot proposal)
     * @param _title The title of the grant
     * @param _description The description of the grant
     * @param _milestones An array specifying the number of milestones and the respective payment amounts
     * @param _paymentCurrency An address specifying the ERC20 token to be paid in
     * @param _proposer The identifier of the proposer
     * @param _receivingAddress The address in which to receive the grant milestones in
     */
    function createGrant(
        string memory _grantHash,
        string memory _title,
        string memory _description,
        uint256[] memory _milestones,
        address _paymentCurrency,
        string memory _proposer,
        address _receivingAddress
    ) public onlyOwner() {
        require(grants[_grantHash].createdAt == 0, "duplicate grants hash");

        grants[_grantHash] = Grant(
            _grantHash,
            _title,
            _description,
            _milestones,
            _paymentCurrency,
            _proposer,
            _receivingAddress,
            0,
            block.timestamp,
            block.timestamp,
            GrantState.ACTIVE
        );

        grantsCount += 1;

        emit NewGrant(_grantHash, _proposer, _receivingAddress);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to create a new initiative
     * Emits NewInitiative event.
     * @param _initiativeHash The ipfs hash of an initiatve, if passed through ipfs should return the content of this initiative
     * @param _title The title of the initiative
     * @param _description The description of the initiative
     * @param _milestones An array specifying the number of milestones and the respective payment amounts
     */
    function createInitiative(
        string memory _initiativeHash,
        string memory _title,
        string memory _description,
        uint256[] memory _milestones,
        address _paymentCurrency
    ) public onlyOwner() {
        require(initiatives[_initiativeHash].createdAt == 0, "duplicate initiatives hash");

        initiatives[_initiativeHash] = Initiative(
            _initiativeHash,
            _title,
            _description,
            _milestones,
            _paymentCurrency,
            address(0),
            0,
            block.timestamp,
            block.timestamp,
            InitiativeState.OPEN
        );

        initiativesCount += 1;

        emit NewInitiative(_initiativeHash);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to create a new competition
     * Emits NewCompetition event.
     * @param _competitionHash The ipfs hash of an competition, if passed through ipfs should return the content of this initiative
     * @param _title The title of the initiative
     * @param _description The description of the initiative
     * @param _paymentCurrency The currency that the bounty is to be paid in
     * @param _totalBounty The total bounty amount allocated to this competition
     * @param _placeAmounts The amounts rewarded for each place, where index [0,1,2] represents 1st, 2nd, 3rd place and so on
     */
    function createCompetition(
        string memory _competitionHash,
        string memory _title,
        string memory _description,
        address _paymentCurrency,
        uint256 _totalBounty,
        uint256[] memory _placeAmounts
    ) public onlyOwner() {
        require(competitions[_competitionHash].createdAt == 0, "duplicate competition hash");

        competitions[_competitionHash] = Competition(
            _competitionHash,
            _title,
            _description,
            _paymentCurrency,
            _totalBounty,
            _placeAmounts,
            block.timestamp,
            block.timestamp,
            CompetitionState.ACTIVE
        );
        competitionCount += 1;
        emit NewCompetition(_competitionHash);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to assign a initiative to a payable address
     * Emits InitiativeAssigned event.
     * @param _hash The hash of the initiative to modify
     * @param _assignee An address to assign the initiative to
     */
    function assignInitiative(string memory _hash, address _assignee) public onlyOwner() {
        Initiative storage initiative = initiatives[_hash];

        initiative.state = InitiativeState.ASSIGNED;

        initiative.receivingAddress = _assignee;

        emit InitiativeAssigned(_hash, _assignee);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to assign a initiative to a payable address
     * Emits InitiativeAssigned event.
     * @param _hash The hash of the initiative to modify
     * @param _assignee An address to assign the initiative to
     */
    function reassignGrant(string memory _hash, address _assignee) public onlyOwner() {
        grants[_hash].receivingAddress = _assignee;

        emit GrantReassigned(_hash, _assignee);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to release a milestone payment on a grant
     * Emits GrantMilestoneReleased event or GrantCompleted
     * @param _hash The hash of the grant to release payment for
     */
    function progressGrant(string memory _hash) public onlyOwner() {
        Grant storage grant = grants[_hash];

        require(grant.state == GrantState.ACTIVE, "grant is not active");

        uint256 currentMilestone = grant.currentMilestone;

        // If the current milestone is the last one, mark the grant as completed
        if (currentMilestone == grant.milestones.length - 1) {
            grant.state = GrantState.COMPLETED;
            emit GrantCompleted(_hash);
        } else {
            grant.currentMilestone += 1;
        }

        grant.modifiedAt = block.timestamp;

        _transferMilestonePayment(grant.milestones[currentMilestone], grant.paymentCurrency, grant.receivingAddress);

        emit GrantMilestoneReleased(
            _hash,
            grant.milestones[currentMilestone],
            grant.receivingAddress,
            grant.paymentCurrency
        );
    }

    /**
     * @notice Called by the owners (gDAO multisig) to release a milestone payment on an initiative
     * Emits InitiativeMilestoneReleased event or InitiativeCompleted
     * @param _hash The hash of the grant to release payment for
     */
    function progressInitiative(string memory _hash) public onlyOwner() {
        Initiative storage initiative = initiatives[_hash];

        require(initiative.state == InitiativeState.ASSIGNED, "initiative has not been assigned");

        uint256 currentMilestone = initiative.currentMilestone;

        // If the current milestone is the last one, mark the initiative as completed
        if (currentMilestone == initiative.milestones.length - 1) {
            initiative.state = InitiativeState.COMPLETED;
            emit InitiativeCompleted(_hash);
        } else {
            initiative.currentMilestone += 1;
        }

        initiative.modifiedAt = block.timestamp;

        _transferMilestonePayment(
            initiative.milestones[currentMilestone],
            initiative.paymentCurrency,
            initiative.receivingAddress
        );

        emit InitiativeMilestoneReleased(
            _hash,
            initiative.milestones[currentMilestone],
            initiative.receivingAddress,
            initiative.paymentCurrency
        );
    }

    /**
     * @notice Called by the owners (gDAO multisig) to release all payments on an grant
     * Emits GrantCompleted
     * @param _hash The hash of the grant to release all payments
     */
    function completeGrant(string memory _hash) public onlyOwner() {
        Grant storage grant = grants[_hash];

        require(grant.state == GrantState.ACTIVE, "grant is not active");

        uint256 currentMilestone = grant.currentMilestone;

        uint256 total;

        for (uint256 i = currentMilestone; i < grant.milestones.length; i++) {
            total += grant.milestones[i];
            emit GrantMilestoneReleased(_hash, grant.milestones[i], grant.receivingAddress, grant.paymentCurrency);
        }

        grant.currentMilestone = grant.milestones.length - 1;

        grant.state = GrantState.COMPLETED;

        grant.modifiedAt = block.timestamp;

        _transferMilestonePayment(total, grant.paymentCurrency, grant.receivingAddress);

        emit GrantCompleted(_hash);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to release a milestone payment on an initiative
     * Emits InitiativeCompleted
     * @param _hash The hash of the initiative to release all payments
     */
    function completeInitiative(string memory _hash) public onlyOwner() {
        Initiative storage initiative = initiatives[_hash];

        require(initiative.state == InitiativeState.ASSIGNED, "initiative has not been assigned");

        uint256 currentMilestone = initiative.currentMilestone;

        uint256 total;

        for (uint256 i = currentMilestone; i < initiative.milestones.length; i++) {
            total += initiative.milestones[i];
            emit InitiativeMilestoneReleased(
                _hash,
                initiative.milestones[i],
                initiative.receivingAddress,
                initiative.paymentCurrency
            );
        }

        initiative.currentMilestone = initiative.milestones.length - 1;

        initiative.state = InitiativeState.COMPLETED;

        initiative.modifiedAt = block.timestamp;

        _transferMilestonePayment(total, initiative.paymentCurrency, initiative.receivingAddress);

        emit InitiativeCompleted(_hash);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to pay out the places of a competition
     * Emits CompetitionCompleted
     * @param _hash The hash of the competition to release payments for
     * @param _winners An array of addresses specifying the winners from (1st...Nth)
     */
    function completeCompetition(string memory _hash, address[] memory _winners) public onlyOwner() {
        Competition storage competition = competitions[_hash];
        IERC20 token = IERC20(competition.paymentCurrency);
        require(_winners.length == competition.placeAmounts.length, "winners length invalid");
        require(competition.state == CompetitionState.ACTIVE, "competition is not active");
        require(token.balanceOf(address(this)) >= competition.totalBounty, "insufficient balance");

        for (uint256 i = 0; i < competition.placeAmounts.length; i++) {
            _transferMilestonePayment(competition.placeAmounts[i], competition.paymentCurrency, _winners[i]);
        }

        competition.state = CompetitionState.COMPLETED;

        emit CompetitionCompleted(_hash);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to cancel a grant
     * Emits GrantCancelled
     * @param _hash The hash of the grant to cancel
     * @param _reason The reason why the grant was cancelled
     */
    function cancelGrant(string memory _hash, string memory _reason) public onlyOwner() {
        Grant storage grant = grants[_hash];

        grant.state = GrantState.CANCELLED;

        grant.modifiedAt = block.timestamp;

        emit GrantCancelled(_hash, _reason);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to cancel a initiative
     * Emits InitiativeCancelled
     * @param _hash The hash of the initiative to cancel
     * @param _reason The reason why the initiative was cancelled
     */
    function cancelInitiative(string memory _hash, string memory _reason) public onlyOwner() {
        Initiative storage initiative = initiatives[_hash];

        initiative.state = InitiativeState.CANCELLED;

        initiative.modifiedAt = block.timestamp;

        emit InitiativeCancelled(_hash, _reason);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to cancel a competition
     * Emits CompetitionCancelled
     * @param _hash The hash of the initiative to cancel
     * @param _reason The reason why the initiative was cancelled
     */
    function cancelCompetition(string memory _hash, string memory _reason) public onlyOwner() {
        Competition storage competition = competitions[_hash];

        competition.state = CompetitionState.CANCELLED;

        competition.modifiedAt = block.timestamp;

        emit CompetitionCancelled(_hash, _reason);
    }

    /**
     * @notice Called by the owners (gDAO multisig) to withdraw any ERC20 deposited in this account
     * Emits Withdrawal
     * @param _receiver The hash of the initiative to release all payments
     * @param _amount The amount of specified erc20 to withdraw
     * @param _token The hash of the initiative to release all payments
     */
    function withdraw(
        address _receiver,
        uint256 _amount,
        address _token
    ) public onlyOwner() {
        IERC20 token = IERC20(_token);

        require(token.balanceOf(address(this)) >= _amount, "insufficient balance");

        token.safeTransfer(_receiver, _amount);

        emit Withdrawal(_receiver, _amount, _token);
    }

    /**
     * @notice An internal function that handles the transfer of funds from the contract to the payable address
     * @param _milestoneAmount The amount to transfer
     * @param _paymentCurrency The ERC20 address of token to transfer
     * @param _receiver The address of the receiver
     */
    function _transferMilestonePayment(
        uint256 _milestoneAmount,
        address _paymentCurrency,
        address _receiver
    ) internal {
        IERC20 token = IERC20(_paymentCurrency);

        require(token.balanceOf(address(this)) >= _milestoneAmount, "insufficient balance");

        token.safeTransfer(_receiver, _milestoneAmount);
    }
}