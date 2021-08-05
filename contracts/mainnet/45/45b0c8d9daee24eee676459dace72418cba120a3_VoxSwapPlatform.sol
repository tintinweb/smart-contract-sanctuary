/**
 *Submitted for verification at Etherscan.io on 2021-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// Inheritance
// https://docs.synthetix.io/contracts/Pausable
abstract contract Pausable is Owned {
    uint256 public lastPauseTime;
    bool public paused;

    constructor() internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = now;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(
            !paused,
            "This action cannot be performed while the contract is paused"
        );
        _;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Lib {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/utils/Address.sol
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

// File: contracts/token/ERC20/ERC20.sol
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20Lib is Context, IERC20Lib {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
library SafeERC20Lib {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20Lib token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20Lib token,
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
        IERC20Lib token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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
        IERC20Lib token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
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
        IERC20Lib token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Lib token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IUSDv is IERC20Lib {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

/*

website: vox.finance

 _    ______ _  __   ___________   _____    _   ______________
| |  / / __ \ |/ /  / ____/  _/ | / /   |  / | / / ____/ ____/
| | / / / / /   /  / /_   / //  |/ / /| | /  |/ / /   / __/   
| |/ / /_/ /   |_ / __/ _/ // /|  / ___ |/ /|  / /___/ /___   
|___/\____/_/|_(_)_/   /___/_/ |_/_/  |_/_/ |_/\____/_____/   
                                                              
*/

contract VoxSwapPlatform is ReentrancyGuard, Pausable {
    using SafeERC20Lib for IERC20Lib;
    using Address for address;
    using SafeMath for uint256;

    IUSDv internal usdv;
    IERC20Lib internal vox;

    // UNDERLYING
    address private usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private tusd = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address private susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

    address[4] public coins;
    uint256[4] public decimals;
    uint256[4] public balances;
    uint256[4] public fees;

    uint256 public minimumVoxBalance = 0;
    uint256 public voxHolderDiscount = 25;

    uint256 public swapFee = 35;
    uint256 public swapFeeMax = 40;
    uint256 public swapFeeBase = 100000;

    uint256 public redeemFee = 15;
    uint256 public redeemFeeMax = 30;
    uint256 public redeemFeeBase = 100000;

    address public treasury;
    address public admin;

    uint256 private _redeemFees;
    mapping(address => uint8) private _supported;
    mapping(address => uint256) private _minted;
    mapping(address => uint256) private _redeemed;
    mapping(address => uint256) private _depositedAt;

    // CONSTRUCTOR

    constructor(
        address _owner,
        address _usdv,
        address _vox
    ) public Owned(_owner) {
        usdv = IUSDv(_usdv);
        vox = IERC20Lib(_vox);

        coins[0] = usdc;
        coins[1] = usdt;
        coins[2] = tusd;
        coins[3] = susd;

        decimals[0] = 6;
        decimals[1] = 6;
        decimals[2] = 18;
        decimals[3] = 18;

        _supported[usdc] = 1;
        _supported[usdt] = 2;
        _supported[tusd] = 3;
        _supported[susd] = 4;
    }

    // VIEWS

    function shares() public view returns (uint256[4] memory _shares) {
        uint256[4] memory basket;
        uint256 total;

        for(uint256 i = 0; i < coins.length; i++) {
            uint256 balance = balanceOf(i);
            uint256 delta = uint256(18).sub(decimals[i]);
            basket[i] = balance.mul(10 ** delta);
            total = total.add(balance.mul(10 ** delta));
        }

        for(uint256 i = 0; i < basket.length; i++) {
            _shares[i] = basket[i].mul(1e18).div(total);
        }

        return _shares;
    }

    function mintedOf(address account) external view returns (uint256) {
        return _minted[account];
    }

    function redeemedOf(address account) external view returns (uint256) {
        return _redeemed[account];
    }

    function balanceOf(uint256 index) public view returns (uint256) {
        return balances[index];
    }

    // PUBLIC FUNCTIONS

    function mint(uint256[4] memory amounts)
        external
        nonReentrant
        notPaused 
    {
        require(vox.balanceOf(msg.sender) > minimumVoxBalance, '!vox');
        _mint(amounts);
    }

    function _mint(uint256[4] memory amounts)
        internal
    {
        uint256 toMint;

        for(uint256 i = 0; i < coins.length; i++) {
            uint256 amount = amounts[i];
            if (amount > 0) {
                IERC20Lib token = IERC20Lib(coins[i]);
                require(token.balanceOf(msg.sender) >= amount, '!balance');
                token.safeTransferFrom(msg.sender, address(this), amount);

                uint256 delta = uint256(18).sub(decimals[i]);
                uint256 usdvAmount = amount.mul(10 ** delta);
                balances[i] = balances[i].add(amount);
                toMint = toMint.add(usdvAmount);
            }
        }

        if (toMint > 0) {
            _minted[msg.sender] = _minted[msg.sender].add(toMint);
            usdv.mint(msg.sender, toMint);
            _depositedAt[msg.sender] = block.number;
            emit Minted(msg.sender, toMint);
        }
    }

    function swap(address _from, address _to, uint256 amount)
        external
        nonReentrant
        notPaused 
    {
        require(amount > 0, '!amount');
        require(_supported[_from] > 0, '!from');
        require(_supported[_to] > 0, '!to');
        require(_to != address(usdv), '!usdv');

        IERC20Lib from = IERC20Lib(_from);
        IERC20Lib to = IERC20Lib(_to);
        require(from.balanceOf(msg.sender) >= amount, '!balance');

        uint256 indexFrom = _supported[_from] - 1;
        uint256 indexTo = _supported[_to] - 1;
        uint256 receiveAmount;
        uint256 fee;

        if (decimals[indexFrom] <= decimals[indexTo]) {
            uint256 delta = uint256(decimals[indexTo]).sub(decimals[indexFrom]);
            require(to.balanceOf(address(this)) >= amount.mul(10 ** delta), '!underlying');

            from.safeTransferFrom(msg.sender, address(this), amount);

            fee = amount.mul(swapFee).div(swapFeeBase);
            if (vox.balanceOf(msg.sender) > minimumVoxBalance) {
                fee = fee.mul(voxHolderDiscount).div(100);
            }
            fees[indexFrom] = fees[indexFrom].add(fee);
            
            uint256 leftover = amount.sub(fee);
            balances[indexFrom] = balances[indexFrom].add(leftover);

            receiveAmount = leftover.mul(10 ** delta);
        } else {
            uint256 delta = uint256(decimals[indexFrom]).sub(decimals[indexTo]);
            require(to.balanceOf(address(this)) >= amount.div(10 ** delta), '!underlying');

            from.safeTransferFrom(msg.sender, address(this), amount);

            fee = amount.mul(swapFee).div(swapFeeBase);
            if (vox.balanceOf(msg.sender) > minimumVoxBalance) {
                fee = fee.mul(voxHolderDiscount).div(100);
            }
            fees[indexFrom] = fees[indexFrom].add(fee);
            
            uint256 leftover = amount.sub(fee);
            balances[indexFrom] = balances[indexFrom].add(leftover);

            receiveAmount = leftover.div(10 ** delta);
        }

        if (receiveAmount > 0) {
            balances[indexTo] = balances[indexTo].sub(receiveAmount);
            IERC20Lib(_to).safeTransfer(msg.sender, receiveAmount);
            emit Swapped(msg.sender, _from, amount, _to, receiveAmount, fee);
        }
    }

    function swapToUSDv(address _from, uint256 amount)
        external
        nonReentrant
        notPaused 
    {
        require(amount > 0, '!amount');
        require(_supported[_from] > 0, '!from');
        
        IERC20Lib from = IERC20Lib(_from);
        uint256 indexFrom = _supported[_from] - 1;

        require(from.balanceOf(msg.sender) >= amount, '!balance');
        from.safeTransferFrom(msg.sender, address(this), amount);

        uint256 fee = amount.mul(swapFee).div(swapFeeBase);
        if (vox.balanceOf(msg.sender) > minimumVoxBalance) {
            fee = fee.mul(voxHolderDiscount).div(100);
        }
        fees[indexFrom] = fees[indexFrom].add(fee);
        uint256 leftover = amount.sub(fee);
        balances[indexFrom] = balances[indexFrom].add(leftover);

        uint256[4] memory amounts;
        amounts[indexFrom] = leftover;
        _mint(amounts);
        uint256 delta = uint256(18).sub(decimals[indexFrom]);
        uint256 usdvAmount = leftover.mul(10 ** delta);
        emit Swapped(msg.sender, _from, amount, address(usdv), usdvAmount, fee);
    }

    function redeemSingle(address _underlying, uint256 amount)
        external
        nonReentrant
    {
        require(amount > 0, '!amount');
        require(_supported[_underlying] > 0, '!underlying');
        require(block.number > _depositedAt[msg.sender], '!same_block');

        require(usdv.balanceOf(msg.sender) >= amount, '!balance');
        IERC20Lib(address(usdv)).safeTransferFrom(msg.sender, address(this), amount);

        uint256 fee = amount.mul(redeemFee).div(redeemFeeBase);
        _redeemFees = _redeemFees.add(fee);
        uint256 leftover = amount.sub(fee);
        usdv.burn(address(this), leftover);
        _redeemed[msg.sender] = _redeemed[msg.sender].add(amount);

        uint256 indexTo = _supported[_underlying] - 1;
        uint256 delta = uint256(18).sub(decimals[indexTo]);
        uint256 receiveAmount = leftover.div(10 ** delta);

        IERC20Lib underlying = IERC20Lib(_underlying);
        require(underlying.balanceOf(address(this)) >= receiveAmount, '!underlying');

        balances[indexTo] = balances[indexTo].sub(receiveAmount);
        underlying.safeTransfer(msg.sender, receiveAmount);
        uint256[4] memory amounts;
        amounts[indexTo] = receiveAmount;
        emit Redeemed(msg.sender, amount, amounts, fee);
    }

    function redeemProportional(uint256 amount)
        public
        nonReentrant
    {
        require(amount > 0, '!amount');
        require(block.number > _depositedAt[msg.sender], '!same_block');

        require(usdv.balanceOf(msg.sender) >= amount, '!balance');
        IERC20Lib(address(usdv)).safeTransferFrom(msg.sender, address(this), amount);

        uint256 fee = amount.mul(redeemFee).div(redeemFeeBase);
        _redeemFees = _redeemFees.add(fee);
        uint256 leftover = amount.sub(fee);
        usdv.burn(address(this), leftover);
        _redeemed[msg.sender] = _redeemed[msg.sender].add(amount);

        uint256[4] memory _shares = shares();
        uint256[4] memory receiveAmounts;

        for(uint256 i = 0; i < _shares.length; i++) {
            uint256 delta = uint256(18).sub(decimals[i]);
            uint256 _amount = leftover.mul(_shares[i]).div(1e18);
            receiveAmounts[i] = _amount.div(10 ** delta);
        }

        for(uint256 i = 0; i < receiveAmounts.length; i++) {
            IERC20Lib underlying = IERC20Lib(coins[i]);
            require(underlying.balanceOf(address(this)) >= receiveAmounts[i], '!underlying');
            balances[i] = balances[i].sub(receiveAmounts[i]);
            underlying.safeTransfer(msg.sender, receiveAmounts[i]);
        }

        emit Redeemed(msg.sender, amount, receiveAmounts, fee);
    }

    function redeemAll()
        external
    {
        uint256 balance = usdv.balanceOf(msg.sender);
        redeemProportional(balance);
    }

    // RESTRICTED FUNCTIONS

    function salvage(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(_token != tusd, '!tusd');
        require(_token != susd, '!susd');
        require(_token != usdc, '!usdc');
        require(_token != usdt, '!usdt');

        IERC20Lib(_token).safeTransfer(owner, _amount);
        emit Recovered(_token, _amount);
    }

    function setMinimumVoxBalance(uint256 _minimumVoxBalance)
        external
        onlyOwner
    {
        minimumVoxBalance = _minimumVoxBalance;
    }

    function setVoxHolderDiscount(uint256 _voxHolderDiscount)
        external
        onlyOwner
    {
        voxHolderDiscount = _voxHolderDiscount;
    }

    function setSwapFee(uint256 _swapFee)
        external
        onlyOwner
    {
        require(_swapFee <= swapFeeMax, '!max');
        swapFee = _swapFee;
    }

    function setRedeemFee(uint256 _redeemFee)
        external
        onlyOwner
    {
        require(_redeemFee <= redeemFeeMax, '!max');
        redeemFee = _redeemFee;
    }

    function setAdmin(address _admin)
        external
        onlyOwner
    {
        require (_admin != address(0), '!address');
        admin = _admin;
    }

    function setTreasury(address _treasury)
        external
        onlyOwner
    {
        require (_treasury != address(0), '!address');
        treasury = _treasury;
    }

    function collectFees()
        external
        onlyOwner
    {
        for(uint256 i = 0; i < coins.length; i++) {
            if (fees[i] > 0) {
                uint256 _admin = fees[i].div(2);
                uint256 _treasury = fees[i].sub(_admin);

                fees[i] = 0;

                IERC20Lib(coins[i]).safeTransfer(admin, _admin);
                IERC20Lib(coins[i]).safeTransfer(treasury, _treasury);
            }
        }

        uint256 balance = usdv.balanceOf(address(this));
        if (_redeemFees > balance) {
            _redeemFees = balance;
        }

        uint256 _treasury = _redeemFees;
        _redeemFees = 0;
        IERC20Lib(address(usdv)).safeTransfer(treasury, _treasury);
    }

    // EVENTS

    event Swapped(address beneficiary, address from, uint256 fromAmount, address to, uint256 toAmount, uint256 fee);
    event Minted(address beneficiary, uint256 amount);
    event Redeemed(address beneficiary, uint256 amount, uint256[4] receivedAmounts, uint256 fee);
    event Recovered(address token, uint256 amount);
}