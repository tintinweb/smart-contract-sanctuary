pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "../utils/OperatorParams.sol";
import "../utils/BytesLib.sol";

/// Staking contract stub for testing purposes of copy stake flow.
contract OldTokenStaking {
    using OperatorParams for uint256;
    using BytesLib for bytes;
    ERC20Burnable public token;
    using SafeERC20 for ERC20Burnable;

    event Undelegated(address indexed operator, uint256 undelegatedAt);
    event Staked(address indexed from, uint256 value);

    mapping(address => address[]) public ownerOperators;
    mapping(address => Operator) public operators;

    struct Operator {
        uint256 packedParams;
        address owner;
        address payable beneficiary;
        address authorizer;
    }

    constructor(address _tokenAddress) public {
        require(_tokenAddress != address(0x0), "Token address can't be zero.");
        token = ERC20Burnable(_tokenAddress);
    }

    function operatorsOf(address _address)
        public
        view
        returns (address[] memory)
    {
        return ownerOperators[_address];
    }

    function balanceOf(address _address) public view returns (uint256 balance) {
        return operators[_address].packedParams.getAmount();
    }

    function ownerOf(address _operator) public view returns (address) {
        return operators[_operator].owner;
    }

    function beneficiaryOf(address _operator)
        public
        view
        returns (address payable)
    {
        return operators[_operator].beneficiary;
    }

    function authorizerOf(address _operator) public view returns (address) {
        return operators[_operator].authorizer;
    }

    function getDelegationInfo(address _operator)
        public
        view
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        )
    {
        return operators[_operator].packedParams.unpack();
    }

    function undelegationPeriod() public view returns (uint256) {
        return 5184000; // two months
    }

    function initializationPeriod() public view returns (uint256) {
        return 120;
    }

    function minimumStake() public view returns (uint256) {
        return 10000 * 1e18;
    }

    function undelegate(address _operator) public {
        uint256 oldParams = operators[_operator].packedParams;
        operators[_operator].packedParams = oldParams.setUndelegationTimestamp(
            block.timestamp
        );
        emit Undelegated(_operator, block.timestamp);
    }

    function setOperator(
        address _owner,
        address _operator,
        address payable _beneficiary,
        address _authorizer,
        uint256 _value
    ) public {
        operators[_operator] = Operator(
            OperatorParams.pack(_value, block.timestamp, 0),
            _owner,
            _beneficiary,
            _authorizer
        );
        ownerOperators[_owner].push(_operator);
    }

    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory _extraData
    ) public {
        require(
            ERC20Burnable(_token) == token,
            "Token contract must be the same one linked to this contract."
        );
        require(
            _value >= minimumStake(),
            "Tokens amount must be greater than the minimum stake"
        );
        require(
            _extraData.length == 60,
            "Stake delegation data must be provided."
        );

        address payable beneficiary = address(uint160(_extraData.toAddress(0)));
        address operator = _extraData.toAddress(20);
        require(
            operators[operator].owner == address(0),
            "Operator address is already in use."
        );
        address authorizer = _extraData.toAddress(40);

        // Transfer tokens to this contract.
        token.safeTransferFrom(_from, address(this), _value);

        operators[operator] = Operator(
            OperatorParams.pack(_value, block.timestamp, 0),
            _from,
            beneficiary,
            authorizer
        );
        ownerOperators[_from].push(operator);

        emit Staked(operator, _value);
    }
}

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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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

pragma solidity 0.5.17;

library OperatorParams {
    // OperatorParams packs values that are commonly used together
    // into a single uint256 to reduce the cost functions
    // like querying eligibility.
    //
    // An OperatorParams uint256 contains:
    // - the operator's staked token amount (uint128)
    // - the operator's creation timestamp (uint64)
    // - the operator's undelegation timestamp (uint64)
    //
    // These are packed as [amount | createdAt | undelegatedAt]
    //
    // Staked KEEP is stored in an uint128,
    // which is sufficient because KEEP tokens have 18 decimals (2^60)
    // and there will be at most 10^9 KEEP in existence (2^30).
    //
    // Creation and undelegation times are stored in an uint64 each.
    // Thus uint64s would be sufficient for around 3*10^11 years.
    uint256 constant TIMESTAMP_WIDTH = 64;
    uint256 constant AMOUNT_WIDTH = 128;

    uint256 constant TIMESTAMP_MAX = (2**TIMESTAMP_WIDTH) - 1;
    uint256 constant AMOUNT_MAX = (2**AMOUNT_WIDTH) - 1;

    uint256 constant CREATION_SHIFT = TIMESTAMP_WIDTH;
    uint256 constant AMOUNT_SHIFT = 2 * TIMESTAMP_WIDTH;

    function pack(
        uint256 amount,
        uint256 createdAt,
        uint256 undelegatedAt
    ) internal pure returns (uint256) {
        // Check for staked amount overflow.
        // We shouldn't actually ever need this.
        require(amount <= AMOUNT_MAX, "uint128 overflow");
        // Bitwise OR the timestamps together.
        // The resulting number is equal or greater than either,
        // and tells if we have a bit set outside the 64 available bits.
        require(
            (createdAt | undelegatedAt) <= TIMESTAMP_MAX,
            "uint64 overflow"
        );

        return ((amount << AMOUNT_SHIFT) |
            (createdAt << CREATION_SHIFT) |
            undelegatedAt);
    }

    function unpack(uint256 packedParams)
        internal
        pure
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        )
    {
        amount = getAmount(packedParams);
        createdAt = getCreationTimestamp(packedParams);
        undelegatedAt = getUndelegationTimestamp(packedParams);
    }

    function getAmount(uint256 packedParams) internal pure returns (uint256) {
        return (packedParams >> AMOUNT_SHIFT) & AMOUNT_MAX;
    }

    function setAmount(uint256 packedParams, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return
            pack(
                amount,
                getCreationTimestamp(packedParams),
                getUndelegationTimestamp(packedParams)
            );
    }

    function getCreationTimestamp(uint256 packedParams)
        internal
        pure
        returns (uint256)
    {
        return (packedParams >> CREATION_SHIFT) & TIMESTAMP_MAX;
    }

    function setCreationTimestamp(
        uint256 packedParams,
        uint256 creationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                getAmount(packedParams),
                creationTimestamp,
                getUndelegationTimestamp(packedParams)
            );
    }

    function getUndelegationTimestamp(uint256 packedParams)
        internal
        pure
        returns (uint256)
    {
        return packedParams & TIMESTAMP_MAX;
    }

    function setUndelegationTimestamp(
        uint256 packedParams,
        uint256 undelegationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                getAmount(packedParams),
                getCreationTimestamp(packedParams),
                undelegationTimestamp
            );
    }

    function setAmountAndCreationTimestamp(
        uint256 packedParams,
        uint256 amount,
        uint256 creationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                amount,
                creationTimestamp,
                getUndelegationTimestamp(packedParams)
            );
    }
}

pragma solidity 0.5.17;

/*
Verison pulled from https://github.com/summa-tx/bitcoin-spv/blob/2535e4edaeaac4b2b095903fce684ae1c05761bc/solidity/contracts/BytesLib.sol
*/

/*
https://github.com/GNSPS/solidity-bytes-utils/
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
For more information, please refer to <https://unlicense.org>
*/

/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
                case 2 {
                    // Since the new array still fits in the slot, we just need to
                    // update the contents of the slot.
                    // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                    sstore(
                        _preBytes_slot,
                        // all the modifications to the slot are inside this
                        // next block
                        add(
                            // we can just add to the slot contents because the
                            // bytes we want to change are the LSBs
                            fslot,
                            add(
                                mul(
                                    div(
                                        // load the bytes from memory
                                        mload(add(_postBytes, 0x20)),
                                        // zero all bytes to the right
                                        exp(0x100, sub(32, mlength))
                                    ),
                                    // and now shift left the number of bytes to
                                    // leave space for the length in the slot
                                    exp(0x100, sub(32, newlength))
                                ),
                                // increase length by the double of the memory
                                // bytes length
                                mul(mlength, 2)
                            )
                        )
                    )
                }
                case 1 {
                    // The stored value fits in the slot, but the combined value
                    // will exceed it.
                    // get the keccak hash to get the contents of the array
                    mstore(0x0, _preBytes_slot)
                    let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                    // save new length
                    sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                    // The contents of the _postBytes array start 32 bytes into
                    // the structure. Our first read should obtain the `submod`
                    // bytes that can fit into the unused space in the last word
                    // of the stored array. To get this, we read 32 bytes starting
                    // from `submod`, so the data we read overlaps with the array
                    // contents by `submod` bytes. Masking the lowest-order
                    // `submod` bytes allows us to add that value directly to the
                    // stored value.

                    let submod := sub(32, slength)
                    let mc := add(_postBytes, submod)
                    let end := add(_postBytes, mlength)
                    let mask := sub(exp(0x100, submod), 1)

                    sstore(
                        sc,
                        add(
                            and(
                                fslot,
                                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                            ),
                            and(mload(mc), mask)
                        )
                    )

                    for {
                        mc := add(mc, 0x20)
                        sc := add(sc, 1)
                    } lt(mc, end) {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } {
                        sstore(sc, mload(mc))
                    }

                    mask := exp(0x100, sub(mc, end))

                    sstore(sc, mul(div(mload(mc), mask), mask))
                }
                default {
                    // get the keccak hash to get the contents of the array
                    mstore(0x0, _preBytes_slot)
                    // Start copying to the last used word of the stored array.
                    let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                    // save new length
                    sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                    // Copy over the first `submod` bytes of the new data as in
                    // case 1 above.
                    let slengthmod := mod(slength, 32)
                    let mlengthmod := mod(mlength, 32)
                    let submod := sub(32, slengthmod)
                    let mc := add(_postBytes, submod)
                    let end := add(_postBytes, mlength)
                    let mask := sub(exp(0x100, submod), 1)

                    sstore(sc, add(sload(sc), and(mload(mc), mask)))

                    for {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } lt(mc, end) {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } {
                        sstore(sc, mload(mc))
                    }

                    mask := exp(0x100, sub(mc, end))

                    sstore(sc, mul(div(mload(mc), mask), mask))
                }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory res) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

            // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        uint256 _totalLen = _start + 20;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Address conversion out of bounds."
        );
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(
            _bytes.length >= (_start + 1),
            "Uint8 conversion out of bounds."
        );
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        uint256 _totalLen = _start + 32;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Uint conversion out of bounds."
        );
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
                case 1 {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                    let cb := 1

                    let mc := add(_preBytes, 0x20)
                    let end := add(mc, length)

                    for {
                        let cc := add(_postBytes, 0x20)
                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                    } eq(add(lt(mc, end), cb), 2) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        // if any of these checks fails then arrays are not equal
                        if iszero(eq(mload(mc), mload(cc))) {
                            // unsuccess:
                            success := 0
                            cb := 0
                        }
                    }
                }
                default {
                    // unsuccess:
                    success := 0
                }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
                case 1 {
                    // slength can contain both the length and contents of the array
                    // if length < 32 bytes so let's prepare for that
                    // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                    if iszero(iszero(slength)) {
                        switch lt(slength, 32)
                            case 1 {
                                // blank the last byte which is the length
                                fslot := mul(div(fslot, 0x100), 0x100)

                                if iszero(
                                    eq(fslot, mload(add(_postBytes, 0x20)))
                                ) {
                                    // unsuccess:
                                    success := 0
                                }
                            }
                            default {
                                // cb is a circuit breaker in the for loop since there's
                                //  no said feature for inline assembly loops
                                // cb = 1 - don't breaker
                                // cb = 0 - break
                                let cb := 1

                                // get the keccak hash to get the contents of the array
                                mstore(0x0, _preBytes_slot)
                                let sc := keccak256(0x0, 0x20)

                                let mc := add(_postBytes, 0x20)
                                let end := add(mc, mlength)

                                // the next line is the loop condition:
                                // while(uint(mc < end) + cb == 2)
                                for {

                                } eq(add(lt(mc, end), cb), 2) {
                                    sc := add(sc, 1)
                                    mc := add(mc, 0x20)
                                } {
                                    if iszero(eq(sload(sc), mload(mc))) {
                                        // unsuccess:
                                        success := 0
                                        cb := 0
                                    }
                                }
                            }
                    }
                }
                default {
                    // unsuccess:
                    success := 0
                }
        }

        return success;
    }

    function toBytes32(bytes memory _source)
        internal
        pure
        returns (bytes32 result)
    {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes32 result) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

