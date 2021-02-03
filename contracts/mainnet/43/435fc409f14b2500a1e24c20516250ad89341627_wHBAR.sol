/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// File: eip1996/contracts/libraries/StringUtil.sol

pragma solidity ^0.5.9;


library StringUtil {
    function toHash(string memory _s) internal pure returns (bytes32) {
        return keccak256(abi.encode(_s));
    }

    function isEmpty(string memory _s) internal pure returns (bool) {
        return bytes(_s).length == 0;
    }
}

// File: contracts/AccountCreator.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


contract AccountCreator {
    using StringUtil for string;

    enum RequestStatus {
        Nonexistent,
        Requested,
        Confirmed,
        Failed,
        Refunded
    }

    struct AccountRequest {
        string hederaPublicKey;
        address payable requestor;
        uint256 paid;
        RequestStatus status;
    }

    mapping(bytes32 => AccountRequest) private requests;
    address public accountCreator;
    uint256 private fee;

    constructor(
        address creator, 
        uint256 accountCreationFee
    ) public {
        accountCreator = creator;
        fee = accountCreationFee;
    }

    function getAccountCreator() public view returns (address) {
        return accountCreator;
    }

    function getAccountCreationFee() external view returns (uint256) {
        return fee;
    }

    function setAccountCreationFee(uint256 feeInWei) external returns (bool) {
        require(
            msg.sender == accountCreator,
            "Only the account creator can call this function"
        );
        fee = feeInWei;
        return true;
    }

    // User calls createAccount
    function _createAccount(
        string memory operationId,
        string memory hederaPublicKey
    ) internal returns (bool) {
        bytes32 operationIdHash = operationId.toHash();
        AccountRequest storage request = requests[operationIdHash];

        require(!hederaPublicKey.isEmpty(), "Hedera Public Key cannot be empty");
        require(request.paid == 0, "A request with this id already exists");

        request.requestor = msg.sender;
        request.hederaPublicKey = hederaPublicKey;
        request.status = RequestStatus.Requested;
        request.paid = msg.value;

        emit CreateAccountRequest(
            operationId,
            msg.sender,
            hederaPublicKey
        );

        return true;
    }

    function createAccount(
        string calldata operationId, 
        string calldata hederaPublicKey
    ) external payable returns (bool) {
        require(
            msg.value == fee, 
            "Incorrect fee amount, call getAccountCreationFee"
        );

        // Make accountcreator a payable address, then transfer the value
        address(uint160(accountCreator)).transfer(msg.value);

        return _createAccount(
            operationId,
            hederaPublicKey
        );
    }

    // contract creates record and emits
    event CreateAccountRequest(
        string operationId, 
        address requestor, 
        string hederaPublicKey
    );
    // request is created with status Requested
    
    // Bridge program sees HederaAccountRequest
    // Tries to create a hedera account using the oracle, 
    // and if successful, should call
    function createAccountSuccess(
        string calldata operationId, 
        string calldata hederaAccountId
    ) external returns (bool) {
        require(
            msg.sender == accountCreator,
            "Only the account creator can call this function"
        );

        bytes32 operationIdHash = operationId.toHash();
        AccountRequest storage request = requests[operationIdHash];
        
        require(
            request.status == RequestStatus.Requested, 
            "Account Request must have status Requested to be set to status Confirmed"
        );
        
        request.status = RequestStatus.Confirmed;

        emit CreateAccountSuccess(
            operationId,
            request.requestor,
            request.hederaPublicKey,
            hederaAccountId
        );

        return true;
    }

    //which emits
    event CreateAccountSuccess(
        string operationId, 
        address requestor, 
        string hederaPublicKey, 
        string hederaAccountId
    );
    // request has status Confirmed

    // if Hedera account creation fails, bridge program should call
    function createAccountFail(
        string calldata operationId, 
        string calldata reason
    ) external returns (bool) {
        require(
            msg.sender == accountCreator,
            "Only the account creator can call this function"
        );

        bytes32 operationIdHash = operationId.toHash();
        AccountRequest storage request = requests[operationIdHash];
        
        require(
            request.status == RequestStatus.Requested, 
            "Account Request must have status Requested to be set to status Failed"
        );
        
        request.status = RequestStatus.Failed;

        emit CreateAccountFail(
            operationId,
            request.requestor,
            request.hederaPublicKey,
            request.paid,
            reason
        );

        return true;
    }
    
    // which emits
    event CreateAccountFail(
        string operationId,
        address requestor,
        string hederaPublicKey,
        uint256 amount,
        string reason
    );
    // request has status Failed

    // Set to Refunded for confirmation
    function createAccountRefund(
        string calldata operationId
    ) external returns (bool) {
        require(
            msg.sender == accountCreator,
            "Only the account creator can call this function"
        );

        bytes32 operationIdHash = operationId.toHash();
        AccountRequest storage request = requests[operationIdHash];

        require(
            request.status == RequestStatus.Failed,
            "Account Request must have status Failed to be refunded"
        );

        request.status = RequestStatus.Refunded;

        emit CreateAccountRefund(operationId, request.requestor, request.paid);
        return true;
    }

    // emits
    event CreateAccountRefund(
        string id, 
        address requestor, 
        uint256 refundAmountWei
    );
}

// File: eip2021/contracts/IPayoutable.sol

pragma solidity ^0.5.0;

interface IPayoutable {
    enum PayoutStatusCode {
        Nonexistent,
        Ordered,
        InProcess,
        FundsInSuspense,
        Executed,
        Rejected,
        Cancelled
    }

    function orderPayout(string calldata operationId, uint256 value, string calldata instructions) external returns (bool);
    function orderPayoutFrom(
        string calldata operationId,
        address walletToBePaidOut,
        uint256 value,
        string calldata instructions
    ) external returns (bool);
    function cancelPayout(string calldata operationId) external returns (bool);
    function processPayout(string calldata operationId) external returns (bool);
    function putFundsInSuspenseInPayout(string calldata operationId) external returns (bool);
    function executePayout(string calldata operationId) external returns (bool);
    function rejectPayout(string calldata operationId, string calldata reason) external returns (bool);
    function retrievePayoutData(string calldata operationId) external view returns (
        address walletToDebit,
        uint256 value,
        string memory instructions,
        PayoutStatusCode status
    );

    function authorizePayoutOperator(address operator) external returns (bool);
    function revokePayoutOperator(address operator) external returns (bool);
    function isPayoutOperatorFor(address operator, address from) external view returns (bool);

    event PayoutOrdered(address indexed orderer, string operationId, address indexed walletToDebit, uint256 value, string instructions);
    event PayoutInProcess(address indexed orderer, string operationId);
    event PayoutFundsInSuspense(address indexed orderer, string operationId);
    event PayoutExecuted(address indexed orderer, string operationId);
    event PayoutRejected(address indexed orderer, string operationId, string reason);
    event PayoutCancelled(address indexed orderer, string operationId);
    event AuthorizedPayoutOperator(address indexed operator, address indexed account);
    event RevokedPayoutOperator(address indexed operator, address indexed account);
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: eip1996/contracts/IHoldable.sol

pragma solidity ^0.5.0;

interface IHoldable {
    enum HoldStatusCode {
        Nonexistent,
        Ordered,
        Executed,
        ExecutedAndKeptOpen,
        ReleasedByNotary,
        ReleasedByPayee,
        ReleasedOnExpiration
    }

    function hold(
        string calldata operationId,
        address to,
        address notary,
        uint256 value,
        uint256 timeToExpiration
    ) external returns (bool);
    function holdFrom(
        string calldata operationId,
        address from,
        address to,
        address notary,
        uint256 value,
        uint256 timeToExpiration
    ) external returns (bool);
    function releaseHold(string calldata operationId) external returns (bool);
    function executeHold(string calldata operationId, uint256 value) external returns (bool);
    function executeHoldAndKeepOpen(string calldata operationId, uint256 value) external returns (bool);
    function renewHold(string calldata operationId, uint256 timeToExpiration) external returns (bool);
    function retrieveHoldData(string calldata operationId) external view returns (
        address from,
        address to,
        address notary,
        uint256 value,
        uint256 expiration,
        HoldStatusCode status
    );

    function balanceOnHold(address account) external view returns (uint256);
    function netBalanceOf(address account) external view returns (uint256);
    function totalSupplyOnHold() external view returns (uint256);

    function authorizeHoldOperator(address operator) external returns (bool);
    function revokeHoldOperator(address operator) external returns (bool);
    function isHoldOperatorFor(address operator, address from) external view returns (bool);

    event HoldCreated(
        address indexed holdIssuer,
        string  operationId,
        address from,
        address to,
        address indexed notary,
        uint256 value,
        uint256 expiration
    );
    event HoldExecuted(address indexed holdIssuer, string operationId, address indexed notary, uint256 heldValue, uint256 transferredValue);
    event HoldExecutedAndKeptOpen(address indexed holdIssuer, string operationId, address indexed notary, uint256 heldValue,
    uint256 transferredValue);
    event HoldReleased(address indexed holdIssuer, string operationId, HoldStatusCode status);
    event HoldRenewed(address indexed holdIssuer, string operationId, uint256 oldExpiration, uint256 newExpiration);
    event AuthorizedHoldOperator(address indexed operator, address indexed account);
    event RevokedHoldOperator(address indexed operator, address indexed account);
}

// File: eip1996/contracts/Holdable.sol

pragma solidity ^0.5.0;





contract Holdable is IHoldable, ERC20 {

    using SafeMath for uint256;
    using StringUtil for string;

    struct Hold {
        address issuer;
        address origin;
        address target;
        address notary;
        uint256 expiration;
        uint256 value;
        HoldStatusCode status;
    }

    mapping(bytes32 => Hold) internal holds;
    mapping(address => uint256) private heldBalance;
    mapping(address => mapping(address => bool)) private operators;

    uint256 private _totalHeldBalance;

    function hold(
        string memory operationId,
        address to,
        address notary,
        uint256 value,
        uint256 timeToExpiration
    ) public returns (bool)
    {
        require(to != address(0), "Payee address must not be zero address");

        emit HoldCreated(
            msg.sender,
            operationId,
            msg.sender,
            to,
            notary,
            value,
            timeToExpiration
        );

        return _hold(
            operationId,
            msg.sender,
            msg.sender,
            to,
            notary,
            value,
            timeToExpiration
        );
    }

    function holdFrom(
        string memory operationId,
        address from,
        address to,
        address notary,
        uint256 value,
        uint256 timeToExpiration
    ) public returns (bool)
    {
        require(to != address(0), "Payee address must not be zero address");
        require(from != address(0), "Payer address must not be zero address");
        require(operators[from][msg.sender], "This operator is not authorized");

        emit HoldCreated(
            msg.sender,
            operationId,
            from,
            to,
            notary,
            value,
            timeToExpiration
        );

        return _hold(
            operationId,
            msg.sender,
            from,
            to,
            notary,
            value,
            timeToExpiration
        );
    }

    function releaseHold(string memory operationId) public returns (bool) {
        Hold storage releasableHold = holds[operationId.toHash()];

        require(releasableHold.status == HoldStatusCode.Ordered || releasableHold.status == HoldStatusCode.ExecutedAndKeptOpen,"A hold can only be released in status Ordered or ExecutedAndKeptOpen");
        require(
            _isExpired(releasableHold.expiration) ||
            (msg.sender == releasableHold.notary) ||
            (msg.sender == releasableHold.target),
            "A not expired hold can only be released by the notary or the payee"
        );

        _releaseHold(operationId);

        emit HoldReleased(releasableHold.issuer, operationId, releasableHold.status);

        return true;
    }

    function executeHold(string memory operationId, uint256 value) public returns (bool) { 
        return _executeHold(operationId, value, false);
    }

    function executeHoldAndKeepOpen(string memory operationId, uint256 value) public returns (bool) {
        return _executeHold(operationId, value, true);
    }


    function _executeHold(string memory operationId, uint256 value, bool keepOpenIfHoldHasBalance) internal returns (bool) {

        Hold storage executableHold = holds[operationId.toHash()];

        require(executableHold.status == HoldStatusCode.Ordered || executableHold.status == HoldStatusCode.ExecutedAndKeptOpen,"A hold can only be executed in status Ordered or ExecutedAndKeptOpen");
        require(value != 0, "Value must be greater than zero");
        require(executableHold.notary == msg.sender, "The hold can only be executed by the notary");
        require(!_isExpired(executableHold.expiration), "The hold has already expired");
        require(value <= executableHold.value, "The value should be equal or less than the held amount");


        if (keepOpenIfHoldHasBalance && ((executableHold.value - value) > 0)) {
            _decreaseHeldBalance(operationId, value);
            _setHoldToExecutedAndKeptOpen(operationId, value); 
        }else {
            _decreaseHeldBalance(operationId, executableHold.value);
            _setHoldToExecuted(operationId, value);
        }
        
  
        

        _transfer(executableHold.origin, executableHold.target, value);

        return true;
    }


    function renewHold(string memory operationId, uint256 timeToExpiration) public returns (bool) {
        Hold storage renewableHold = holds[operationId.toHash()];

        require(renewableHold.status == HoldStatusCode.Ordered, "A hold can only be renewed in status Ordered");
        require(!_isExpired(renewableHold.expiration), "An expired hold can not be renewed");
        require(
            renewableHold.origin == msg.sender || renewableHold.issuer == msg.sender,
            "The hold can only be renewed by the issuer or the payer"
        );

        uint256 oldExpiration = renewableHold.expiration;

        if (timeToExpiration == 0) {
            renewableHold.expiration = 0;
        } else {
            /* solium-disable-next-line security/no-block-members */
            renewableHold.expiration = now.add(timeToExpiration);
        }

        emit HoldRenewed(
            renewableHold.issuer,
            operationId,
            oldExpiration,
            renewableHold.expiration
        );

        return true;
    }

    function retrieveHoldData(string memory operationId) public view returns (
        address from,
        address to,
        address notary,
        uint256 value,
        uint256 expiration,
        HoldStatusCode status)
    {
        Hold storage retrievedHold = holds[operationId.toHash()];
        return (
            retrievedHold.origin,
            retrievedHold.target,
            retrievedHold.notary,
            retrievedHold.value,
            retrievedHold.expiration,
            retrievedHold.status
        );
    }

    function balanceOnHold(address account) public view returns (uint256) {
        return heldBalance[account];
    }

    function netBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    function totalSupplyOnHold() public view returns (uint256) {
        return _totalHeldBalance;
    }

    function isHoldOperatorFor(address operator, address from) public view returns (bool) {
        return operators[from][operator];
    }

    function authorizeHoldOperator(address operator) public returns (bool) {
        require (operators[msg.sender][operator] == false, "The operator is already authorized");

        operators[msg.sender][operator] = true;
        emit AuthorizedHoldOperator(operator, msg.sender);
        return true;
    }

    function revokeHoldOperator(address operator) public returns (bool) {
        require (operators[msg.sender][operator] == true, "The operator is already not authorized");

        operators[msg.sender][operator] = false;
        emit RevokedHoldOperator(operator, msg.sender);
        return true;
    }

    /// @notice Retrieve the erc20.balanceOf(account) - heldBalance(account)
    function balanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account).sub(heldBalance[account]);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= _value, "Not enough available balance");
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf(_from) >= _value, "Not enough available balance");
        return super.transferFrom(_from, _to, _value);
    }

    function _isExpired(uint256 expiration) internal view returns (bool) {
        /* solium-disable-next-line security/no-block-members */
        return expiration != 0 && (now >= expiration);
    }

    function _hold(
        string memory operationId,
        address issuer,
        address from,
        address to,
        address notary,
        uint256 value,
        uint256 timeToExpiration
    ) internal returns (bool)
    {
        Hold storage newHold = holds[operationId.toHash()];

        require(!operationId.isEmpty(), "Operation ID must not be empty");
        require(value != 0, "Value must be greater than zero");
        require(newHold.value == 0, "This operationId already exists");
        require(notary != address(0), "Notary address must not be zero address");
        require(value <= balanceOf(from), "Amount of the hold can't be greater than the balance of the origin");

        newHold.issuer = issuer;
        newHold.origin = from;
        newHold.target = to;
        newHold.notary = notary;
        newHold.value = value;
        newHold.status = HoldStatusCode.Ordered;

        if (timeToExpiration != 0) {
            /* solium-disable-next-line security/no-block-members */
            newHold.expiration = now.add(timeToExpiration);
        }

        heldBalance[from] = heldBalance[from].add(value);
        _totalHeldBalance = _totalHeldBalance.add(value);

        return true;
    }

    function _releaseHold(string memory operationId) internal returns (bool) {
        Hold storage releasableHold = holds[operationId.toHash()];

        if (_isExpired(releasableHold.expiration)) {
            releasableHold.status = HoldStatusCode.ReleasedOnExpiration;
        } else {
            if (releasableHold.notary == msg.sender) {
                releasableHold.status = HoldStatusCode.ReleasedByNotary;
            } else {
                releasableHold.status = HoldStatusCode.ReleasedByPayee;
            }
        }

        heldBalance[releasableHold.origin] = heldBalance[releasableHold.origin].sub(releasableHold.value);
        _totalHeldBalance = _totalHeldBalance.sub(releasableHold.value);

        return true;
    }

    function _setHoldToExecuted(string memory operationId, uint256 value) internal {
        Hold storage executableHold = holds[operationId.toHash()];
        executableHold.status = HoldStatusCode.Executed;

        emit HoldExecuted(
            executableHold.issuer, 
            operationId,
            executableHold.notary,
            executableHold.value,
            value
        );
    }

    function _setHoldToExecutedAndKeptOpen(string memory operationId, uint256 value) internal {
        Hold storage executableHold = holds[operationId.toHash()];
        executableHold.status = HoldStatusCode.ExecutedAndKeptOpen;
        executableHold.value = executableHold.value.sub(value);

        emit HoldExecutedAndKeptOpen(
            executableHold.issuer,
            operationId,
            executableHold.notary,
            executableHold.value,
            value
            );
    }

    function _decreaseHeldBalance(string memory operationId, uint256 value) internal {
        Hold storage executableHold = holds[operationId.toHash()];
        heldBalance[executableHold.origin] = heldBalance[executableHold.origin].sub(value);
        _totalHeldBalance = _totalHeldBalance.sub(value);
    }
}

// File: contracts/Payoutable.sol
pragma solidity >=0.5.0;



// modification: allow Suspense --> User
contract Payoutable is IPayoutable, Holdable {

    struct OrderedPayout {
        string instructions;
        PayoutStatusCode status;
    }

    mapping(bytes32 => OrderedPayout) private orderedPayouts;
    mapping(address => mapping(address => bool)) private payoutOperators;
    address public payoutAgent;
    address public suspenseAccount;

    constructor(address _suspenseAccount) public {
        require(_suspenseAccount != address(0), "Suspense account must not be the zero address");
        suspenseAccount = _suspenseAccount;

        payoutAgent = _suspenseAccount;
    }

    function orderPayout(string calldata operationId, uint256 value, string calldata instructions) external returns (bool) {
        _orderPayout(
            msg.sender,
            operationId,
            msg.sender,
            value,
            instructions
        );

        emit PayoutOrdered(
            msg.sender,
            operationId,
            msg.sender,
            value,
            instructions
        );

        return true;
    }

    function orderPayoutFrom(
        string calldata operationId,
        address walletToBePaidOut,
        uint256 value,
        string calldata instructions
    ) external returns (bool)
    {
        require(walletToBePaidOut != address(0), "walletToBePaidOut address must not be zero address");
        require(payoutOperators[walletToBePaidOut][msg.sender], "This operator is not authorized");

        emit PayoutOrdered(
            msg.sender,
            operationId,
            walletToBePaidOut,
            value,
            instructions
        );

        return _orderPayout(
            msg.sender,
            operationId,
            walletToBePaidOut,
            value,
            instructions
        );
    }

    function cancelPayout(string calldata operationId) external returns (bool) {
        bytes32 operationIdHash = operationId.toHash();

        OrderedPayout storage cancelablePayout = orderedPayouts[operationIdHash];
        Hold storage cancelableHold = holds[operationIdHash];

        require(cancelablePayout.status == PayoutStatusCode.Ordered, "A payout can only be cancelled in status Ordered");
        require(
            msg.sender == cancelableHold.issuer || msg.sender == cancelableHold.origin,
            "A payout can only be cancelled by the orderer or the walletToBePaidOut"
        );

        _releaseHold(operationId);

        cancelablePayout.status = PayoutStatusCode.Cancelled;

        emit PayoutCancelled(
            cancelableHold.issuer,
            operationId
        );

        return true;
    }

    function processPayout(string calldata operationId) external returns (bool) {
        revert("Function not supported in this implementation");
    }

    function putFundsInSuspenseInPayout(string calldata operationId) external returns (bool) {
        revert("Function not supported in this implementation");
    }

    event PayoutFundsReady(string operationId, uint256 amount, string instructions);
    function transferPayoutToSuspenseAccount(string calldata operationId) external returns (bool) {
        bytes32 operationIdHash = operationId.toHash();

        OrderedPayout storage inSuspensePayout = orderedPayouts[operationIdHash];

        require(inSuspensePayout.status == PayoutStatusCode.Ordered, "A payout can only be set to FundsInSuspense from status Ordered");
        require(msg.sender == payoutAgent, "A payout can only be set to in suspense by the payout agent");

        Hold storage inSuspenseHold = holds[operationIdHash];

        super._transfer(inSuspenseHold.origin, inSuspenseHold.target, inSuspenseHold.value);
        super._setHoldToExecuted(operationId, inSuspenseHold.value);

        _releaseHold(operationId);
        inSuspensePayout.status = PayoutStatusCode.FundsInSuspense;

        emit PayoutFundsInSuspense(
            inSuspenseHold.issuer,
            operationId
        );

        emit PayoutFundsReady(
            operationId,
            inSuspenseHold.value,
            inSuspensePayout.instructions
        );

        return true;
    }

    // New
    event PayoutFundsReturned(string operationId);
    function returnPayoutFromSuspenseAccount(string calldata operationId) external returns (bool) {
        bytes32 operationIdHash = operationId.toHash();

        OrderedPayout storage inSuspensePayout = orderedPayouts[operationIdHash];

        require(inSuspensePayout.status == PayoutStatusCode.FundsInSuspense, "A payout can only be set back to Ordered from status FundsInSuspense");
        require(msg.sender == payoutAgent, "A payout can only be set back to Ordered by the payout agent");

        Hold storage inSuspenseHold = holds[operationIdHash];

        super._transfer(inSuspenseHold.target, inSuspenseHold.origin, inSuspenseHold.value);

        inSuspensePayout.status = PayoutStatusCode.Ordered;

        emit PayoutFundsReturned(
            operationId
        );

        return true;
    }

    function executePayout(string calldata operationId) external returns (bool) {
        bytes32 operationIdHash = operationId.toHash();

        OrderedPayout storage executedPayout = orderedPayouts[operationIdHash];

        require(executedPayout.status == PayoutStatusCode.FundsInSuspense, "A payout can only be executed from status FundsInSuspense");
        require(msg.sender == payoutAgent, "A payout can only be executed by the payout agent");

        Hold storage executedHold = holds[operationIdHash];

        _burn(executedHold.target, executedHold.value);

        executedPayout.status = PayoutStatusCode.Executed;

        emit PayoutExecuted(
            executedHold.issuer,
            operationId
        );

        return true;
    }

    function rejectPayout(string calldata operationId, string calldata reason) external returns (bool) {
        bytes32 operationIdHash = operationId.toHash();

        OrderedPayout storage rejectedPayout = orderedPayouts[operationIdHash];

        require(rejectedPayout.status == PayoutStatusCode.Ordered, "A payout can only be rejected from status Ordered");
        require(msg.sender == payoutAgent, "A payout can only be rejected by the payout agent");

        Hold storage rejectedHold = holds[operationIdHash];

        rejectedPayout.status = PayoutStatusCode.Rejected;

        emit PayoutRejected(
            rejectedHold.issuer,
            operationId,
            reason
        );

        return true;
    }

    function retrievePayoutData(string calldata operationId) external view returns (
        address walletToDebit,
        uint256 value,
        string memory instructions,
        PayoutStatusCode status
    )
    {
        bytes32 operationIdHash = operationId.toHash();

        OrderedPayout storage retrievedPayout = orderedPayouts[operationIdHash];
        Hold storage retrievedHold = holds[operationIdHash];

        return (
            retrievedHold.origin,
            retrievedHold.value,
            retrievedPayout.instructions,
            retrievedPayout.status
        );
    }

    function isPayoutOperatorFor(address operator, address from) external view returns (bool) {
        return payoutOperators[from][operator];
    }

    function authorizePayoutOperator(address operator) external returns (bool) {
        require(payoutOperators[msg.sender][operator] == false, "The operator is already authorized");

        payoutOperators[msg.sender][operator] = true;
        emit AuthorizedPayoutOperator(operator, msg.sender);
        return true;
    }

    function revokePayoutOperator(address operator) external returns (bool) {
        require(payoutOperators[msg.sender][operator], "The operator is already not authorized");

        payoutOperators[msg.sender][operator] = false;
        emit RevokedPayoutOperator(operator, msg.sender);
        return true;
    }

    function _orderPayout(
        address orderer,
        string memory operationId,
        address walletToBePaidOut,
        uint256 value,
        string memory instructions
    ) internal returns (bool)
    {
        OrderedPayout storage newPayout = orderedPayouts[operationId.toHash()];

        require(!instructions.isEmpty(), "Instructions must not be empty");

        newPayout.instructions = instructions;
        newPayout.status = PayoutStatusCode.Ordered;

        return _hold(
            operationId,
            orderer,
            walletToBePaidOut,
            suspenseAccount,
            payoutAgent,
            value,
            0
        );
    }
}

// File: contracts/Token.sol
pragma solidity >=0.5.0;



contract wHBAR is Payoutable, AccountCreator {
    string _name;
    string _symbol;
    uint8 _decimals;

    address _owner;

    uint256 _accountCreateFee;
    
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        address __customOwner

    )
    public
    Payoutable(__customOwner) 
    AccountCreator(__customOwner, 50000000000000) 
    { // AccountCreator ERC20 Holdable SafeMath, 50k gwei hedera account creation fee
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _owner = __customOwner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function mint(address to, uint256 amount) public returns (bool) {
        require(_msgSender() == _owner, "unauthorized");
        super._mint(to, amount);
        return true;
    }
}