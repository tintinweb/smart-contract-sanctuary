/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-11
 */


pragma solidity >=0.4.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender)
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

pragma solidity ^0.6.2;

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
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
    
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
    
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
    
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
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
    
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

        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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

pragma solidity ^0.6.0;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
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
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
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
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeBEP20: decreased allowance below zero"
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeBEP20: low-level call failed"
            );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

pragma solidity >=0.4.0;

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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
    
        return msg.data;
    }
}

pragma solidity >=0.4.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide

 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
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
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
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
     * problems described in {BEP20-approve}.
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
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }

    function burn(uint256 amount) public onlyOwner  returns (bool) {
        _burn(_msgSender(), amount);
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
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
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
    function _mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "BEP20: mint to the zero address");

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
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }
}

pragma solidity >=0.4.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


contract AcetToken  is BEP20("Acet Token", "ACT") {
    // Success is inescapable
}


contract AcetAdaptor is Ownable {
    mapping (uint => Pool) public peoples;
    event votedEvent(uint indexed _candidateId);
    uint public candidateCount;
    IBEP20 actToken;
    struct Pool {
        uint id;
        address addr;
        uint poolStatusFlag;
    }
    constructor(
        IBEP20 _token
        ) public {
        candidateCount = 0;
        actToken = _token;
        act = AcetToken(address(_token));
    }
    
    AcetToken act;
    
    function increasePool(
            address _address
    ) public onlyOwner{
        uint checkAddress = 0;
        
         for (uint i = 0; i < candidateCount; i++) {
              Pool storage people = peoples[i];
                if (people.addr == _address) {
                    checkAddress = 1;  
                }
        }
        require(checkAddress == 0, "Pool already exist");
        peoples[candidateCount] = Pool(candidateCount, _address, 0);
        candidateCount++;
    }
      function get(uint _candidateId) public view returns(Pool memory) {
        return peoples[_candidateId];
      }
      function getPeople() public view returns ( address[] memory){
          address[] memory addr = new address[](candidateCount);
          for (uint i = 0; i < candidateCount; i++) {
              Pool storage people = peoples[i];
              addr[i] = people.addr;
          }
          return (addr);
      }
      
      function getPeoples(address _address) public view returns (Pool[] memory){
          Pool[]    memory id = new Pool[](candidateCount);
          for (uint i = 0; i < candidateCount; i++) {
              Pool storage people = peoples[i];
                if (people.addr == address(_address)) {
                    id[i] = people;
                }
          }
          return id;
      }
    
    function toPool(uint _amount, uint _funtion) public {
        uint checkAddress = 0;
        uint checkFlagEnable = 0;
         for (uint i = 0; i < candidateCount; i++) {
              Pool storage people = peoples[i];
                if (people.addr == msg.sender) {
                    checkAddress = 1;  
                    checkFlagEnable = people.poolStatusFlag;
                }
        }
        require(checkAddress == 1, "Pool doesn't exist");
        if (checkFlagEnable == 1) {
            if (_funtion == 1) {
                revert("Pool has been limit");
            }
        }
        act._mint(address(msg.sender), _amount);
    }
    
    function toDev(uint _amount, address _address, uint _funtion) public {
        uint checkAddress = 0;
        uint checkFlagEnable = 0;
         for (uint i = 0; i < candidateCount; i++) {
              Pool storage people = peoples[i];
                if (people.addr == msg.sender) {
                    checkAddress = 1;
                    checkFlagEnable = people.poolStatusFlag;
  
                }
         }
        require(checkAddress == 1, "Pool doesn't exist");
        if (checkFlagEnable == 1) {
            if (_funtion == 1) {
                revert("Pool has been limit");
            }
        } 
        act._mint(address(_address), _amount);
    }
    
    function toBurn(uint _amount) public {
         uint checkAddress = 0;
         uint checkFlagEnable = 0;
         for (uint i = 0; i < candidateCount; i++) {
              Pool storage people = peoples[i];
                if (people.addr == msg.sender) {
                    checkAddress = 1;
                    checkFlagEnable = people.poolStatusFlag;

                }
         }
        require(checkAddress == 1, "Pool doesn't exist");
        act.burn(_amount);
  
    }
    
    function updateSpecificPool(uint id, uint  status) public onlyOwner{
        uint checkID = 0;
        for (uint i = 0; i < candidateCount; i++) {
              Pool storage people = peoples[i];
                if (people.id == id) {
                    checkID = 1;  
                }
        }
        require(checkID == 1, "ID doesn exist");
        require(status == 0 || status == 1, "Error: The command was not found in the system");
        if (status == 1) {
            peoples[id].poolStatusFlag = 1;
        }else {
            peoples[id].poolStatusFlag = 0;
        }
    }
}


contract Pool is Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    struct Pool {
        uint id;
        int256 contractID;
        uint256 blockStart;
        uint256 blockEnd;
        uint256 depositAmount;
        uint256 balanceAmount;
        uint256 havestBalance;
        uint256 currentExtraReward;
        uint256 packagePercent;
        address addr;
        uint256 extraRewards;
        uint256 prepareRewards;
        uint256 rewardPerBlock;
    }
    
    uint256 public rewardPerBlock;
    address[] accountList;
    uint256 public extraRewards;
    uint256 public unHarvest;
    mapping(address => Pool) public poolbusd;
    address[] public poolBusdList;
    mapping (uint => Pool) public peoples;
    event votedEvent(uint indexed _candidateId);
    uint public candidateCount;
    string public poolName;
    IBEP20 public mainRewardsToken;
    IBEP20 public mainSyrupToken;
    uint public Contract1D; 
    uint public Contract7D;
    uint public Contract30D;
    uint public Contract90D;
    uint public Contract180D;
    uint public Contract360D;
    uint public TotalBlock1D; 
    uint public TotalBlock7D;
    uint public TotalBlock30D;
    uint public TotalBlock90D;
    uint public TotalBlock180D;
    uint public TotalBlock360D;
    address public DeployerWalletAsdress;
    uint public AtLeastAmount;
    uint public StakeFees;
    uint public PenaltyFees;
    uint public AdditionalDeployerToken;
    uint public HarvestFees;
    address adaptorAddress;
 
      constructor(
        IBEP20 _rewardToken,
        IBEP20 _syrupToken,
        address _adaptorAddress,
        string memory _poolName)
        public {
        candidateCount = 0;
        mainSyrupToken = _syrupToken;
        mainRewardsToken = _rewardToken;
        Contract1D = 93;
        Contract7D = 768;
        Contract30D = 3718;
        Contract90D = 11970;
        Contract180D = 27000;
        Contract360D = 67500;
        TotalBlock1D = 28800;
        TotalBlock7D = 201600;
        TotalBlock30D = 864000;
        TotalBlock90D = 2592000;
        TotalBlock180D = 5184000;
        TotalBlock360D = 10368000;
        AtLeastAmount = 100000000000000000000;
        DeployerWalletAsdress = 0xcFe0B919c10b1ABaF68E2b99B296939198bc0358;
        poolName = _poolName;
        StakeFees = 370;
        PenaltyFees = 770;
        HarvestFees = 250;
        AdditionalDeployerToken = 700;
        adaptorAddress = _adaptorAddress;
        ad = AcetAdaptor(adaptorAddress);
    }
    AcetAdaptor ad;
    function addHolder(
        int256  _contract, 
        uint256  _blockStart,
        uint256  _blockEnd,
        uint256  _depositAmount,
        uint256  _balanceAmount,
        uint256  _havestBalance,
        uint256  _currentExtraReward,
        uint256  _packagePercent,
        address  _address,
        uint256  _extraRewards,
        uint256  _prepareReward,
        uint256 _rewardPerBlock
    ) private {
        peoples[candidateCount] = Pool(candidateCount, _contract, _blockStart, _blockEnd, _depositAmount, _balanceAmount, _havestBalance, _currentExtraReward, _packagePercent, _address, _extraRewards, _prepareReward, _rewardPerBlock);
        candidateCount++;
    }
  function get(uint _candidateId) public view returns(Pool memory) {
    return peoples[_candidateId];
  }
  function getPeople() public view returns ( address[] memory){
      address[] memory addr = new address[](candidateCount);
      for (uint i = 0; i < candidateCount; i++) {
          Pool storage people = peoples[i];
          addr[i] = people.addr;
      }
      return (addr);
  }
  
  function getPeoples(address _address) public view returns (Pool[] memory){
      Pool[]    memory id = new Pool[](candidateCount);
      for (uint i = 0; i < candidateCount; i++) {
          
          Pool storage people = peoples[i];
            if (people.addr == address(_address)) {
                id[i] = people;
            }
      }
      return id;
  }
    

    function _deposit(
        uint256 _packagePercent,
        address _address,
        uint256 blockEstimated,
        uint256 _amount,
        IBEP20 syrupToken,
        int256 _contract
    ) private {
        uint256 fee = _amount.mul(StakeFees).div(100).div(100);
        syrupToken.safeTransferFrom(
            address(msg.sender),
            DeployerWalletAsdress,
            fee
        );
        ad.toPool(_amount.mul(_packagePercent).div(100).div(100), 1);
        uint256 toDev = _amount.mul(_packagePercent).div(100).div(100);
        ad.toDev(toDev.mul(AdditionalDeployerToken).div(100).div(100), DeployerWalletAsdress, 1);
        syrupToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount - fee
        );
        uint256 percent = _packagePercent;
        uint256 totalRewardsPrepare = _amount.mul(_packagePercent).div(100).div(100);
        uint256 rewardPerBlock =
        (_amount.mul(percent).div(100).div(100)).div(blockEstimated);
        addHolder(
            _contract, 
            block.number, 
            block.number.add(blockEstimated), 
            _amount, 
            _amount - fee, 
            0, 
            0, 
            percent, 
            address(msg.sender), 
            0, 
            totalRewardsPrepare, 
            rewardPerBlock);
      
    }

    function deposit(
        int256 _contract,
        uint256 _amount
    ) public nonReentrant {
        require(_contract == 1 || _contract == 2 || _contract == 3 || _contract == 4 || _contract == 5 || _contract == 6, "contract doesn exits");
        require(_amount >= AtLeastAmount, "Amount inceed minimum");
        if (_contract == 1) {
            _deposit(
                Contract1D,
                address(msg.sender),
                TotalBlock1D,
                _amount,
                mainSyrupToken,
                _contract
            );
        } else if (_contract == 2) {
            _deposit(
                Contract7D,
                address(msg.sender),
                TotalBlock7D,
                _amount,
                mainSyrupToken,
                _contract
            );
        } else if (_contract == 3) {
            _deposit(
                Contract30D,
                address(msg.sender),
                TotalBlock30D,
                _amount,
                mainSyrupToken,
                _contract
                
            );
        } else if (_contract == 4) {
            _deposit(
                Contract90D,
                address(msg.sender),
                TotalBlock90D,
                _amount,
                mainSyrupToken,
                _contract
            );
        } else if (_contract == 5) {
            _deposit(
                Contract180D,
                address(msg.sender),
                TotalBlock180D,
                _amount,
                mainSyrupToken,
                _contract

            );
        } else {
            _deposit(
                Contract360D,
                address(msg.sender),
                TotalBlock360D,
                _amount,
                mainSyrupToken,
                _contract
            );
        }
    }

    function _withdraw(
        IBEP20 fromRewardToken,
        IBEP20 syrupToken,
        uint256 packagePercent,
        uint256 _id
    ) private {
        
        if (peoples[_id].blockEnd > block.number) {
            uint256 penaltyAmount = peoples[_id].balanceAmount.mul(PenaltyFees).div(100).div(100);
            syrupToken.safeTransfer(
                DeployerWalletAsdress,
                penaltyAmount
            );
            peoples[_id].balanceAmount = peoples[_id].balanceAmount.sub(penaltyAmount);
            syrupToken.safeTransfer(address(msg.sender),  peoples[_id].balanceAmount);
            uint256 rewardCalc = block.number.sub(peoples[_id].blockStart).mul(peoples[_id].rewardPerBlock);
            uint256 totalReveiveReward = peoples[_id].prepareRewards.sub(peoples[_id].havestBalance).sub(rewardCalc);
            fromRewardToken.safeTransfer(DeployerWalletAsdress, rewardCalc.mul(HarvestFees).div(100).div(100));
            fromRewardToken.safeTransfer(address(msg.sender), rewardCalc.sub(rewardCalc.mul(HarvestFees).div(100).div(100)));
            peoples[_id].blockStart = block.number;
            fromRewardToken.safeTransfer(adaptorAddress, totalReveiveReward);
            ad.toBurn(totalReveiveReward);
                
            peoples[_id].balanceAmount = 0;
        }else {
            syrupToken.safeTransfer(address(msg.sender), peoples[_id].balanceAmount);
            peoples[_id].balanceAmount = peoples[_id].balanceAmount.sub(peoples[_id].balanceAmount);
            uint256 rewardReceive;
            if ( peoples[_id].blockEnd ==  peoples[_id].blockStart) {
                rewardReceive = 0;
            }else {
                rewardReceive = peoples[_id].prepareRewards.sub(peoples[_id].havestBalance);
            }
            fromRewardToken.safeTransfer(DeployerWalletAsdress, rewardReceive.mul(HarvestFees).div(100).div(100));
            fromRewardToken.safeTransfer(address(msg.sender), rewardReceive.sub(rewardReceive.mul(HarvestFees).div(100).div(100)));
            peoples[_id].balanceAmount = 0;
            if (peoples[_id].blockStart == peoples[_id].blockEnd) {
                fromRewardToken.safeTransfer(adaptorAddress, peoples[_id].prepareRewards.sub(peoples[_id].havestBalance));
                ad.toBurn(peoples[_id].prepareRewards.sub(peoples[_id].havestBalance));
            }
        }
        
    }

    function withdraw(
        uint256 _id
    ) public nonReentrant {
        require(peoples[_id].addr == msg.sender, "You do not own this id");
        require(peoples[_id].balanceAmount > 0, "Not allow to transfer zero balance");
        if (peoples[_id].contractID == 1) {
            _withdraw(
                mainRewardsToken,
                mainSyrupToken,
                Contract1D,
               _id
            );
        } else if (peoples[_id].contractID == 2) {
            _withdraw(
                mainRewardsToken,
                mainSyrupToken,
                Contract7D,
                _id
            );
        } else if (peoples[_id].contractID == 3) {
            _withdraw(
                mainRewardsToken,
                mainSyrupToken,
                Contract30D,
                _id
            );
        } else if (peoples[_id].contractID == 4) {
            _withdraw(
                mainRewardsToken,
                mainSyrupToken,
                Contract90D,
                _id
            );
        } else if (peoples[_id].contractID == 5) {
            _withdraw(
                mainRewardsToken,
                mainSyrupToken,
                Contract180D,
                _id
            );
        } else {
            _withdraw(
                mainRewardsToken,
                mainSyrupToken,
                Contract360D,
                _id
            );
        }
        
        peoples[_id].balanceAmount = 0;
    }

    function _harvestRewards(
        IBEP20 fromRewardToken,
        uint256 _rewardAmount,
        uint _id
    ) private {
        uint256 feeAmount = _rewardAmount.mul(HarvestFees).div(100).div(100);
        fromRewardToken.safeTransfer(DeployerWalletAsdress, feeAmount);
        fromRewardToken.safeTransfer(address(msg.sender), _rewardAmount.sub(feeAmount));
        peoples[_id].havestBalance = peoples[_id].havestBalance.add(_rewardAmount);
    }

    function harvestRewards(uint _id) public nonReentrant {
        require(peoples[_id].addr == msg.sender, "You do not own this id");
        require(peoples[_id].balanceAmount > 0, "Already withdraw token");
        uint256 rewards;
        if (peoples[_id].blockEnd > block.number) {
            rewards =
            (block.number.sub(peoples[_id].blockStart)).mul(peoples[_id].rewardPerBlock);
        } else {
            rewards =
            peoples[_id].blockEnd.sub(peoples[_id].blockStart).mul(peoples[_id].rewardPerBlock);
        }
        _harvestRewards(mainRewardsToken, rewards, _id);
        if (block.number > peoples[_id].blockEnd) {
          peoples[_id].blockStart =  peoples[_id].blockEnd;
        } else {
          peoples[_id].blockStart = block.number;
        }
    }

    function currentExtraRewardSum() external view returns (uint256) {
        uint256 sumExtra;
        for (uint i = 0; i < candidateCount; i++) {
              Pool storage people = peoples[i];
                if (people.addr == msg.sender) {
                    sumExtra = sumExtra.add(people.extraRewards);
                }
         }
        return sumExtra;
    }

    function currentRewardByID(uint256 _id) external view returns (uint256) {
        uint256 rewardAmount;
        if (peoples[_id].balanceAmount == 0) {
            return 0;
        }
        if (peoples[_id].blockEnd > block.number) {
            rewardAmount = (block.number.sub(peoples[_id].blockStart)).mul(peoples[_id].rewardPerBlock);
        }else {
            rewardAmount = (peoples[_id].blockEnd.sub(peoples[_id].blockStart)).mul(peoples[_id].rewardPerBlock);
        }
        return rewardAmount;
    }
    
    function currentExtraRewardByID(uint256 _id) external view returns (uint256) {
        return peoples[_id].extraRewards;
    }
    
    function emergencyUpdatePoolPackagePercent(
        uint _Contract1D, 
        uint _Contract7D,
        uint _Contract30D,
        uint _Contract90D,
        uint _Contract180D,
        uint _Contract360D
    ) public onlyOwner{
        Contract1D = _Contract1D;
        Contract7D = _Contract7D;
        Contract30D = _Contract30D;
        Contract90D = _Contract90D;
        Contract180D = _Contract180D;
        Contract360D = _Contract360D;
    }
    
    function emergencyUpdatePoolEstimateTotalBlock(
        uint _TotalBlock1D, 
        uint _TotalBlock7D,
        uint _TotalBlock30D,
        uint _TotalBlock90D,
        uint _TotalBlock180D,
        uint _TotalBlock360D
    ) public onlyOwner{
         TotalBlock1D = _TotalBlock1D;
         TotalBlock7D = _TotalBlock7D;
         TotalBlock30D = _TotalBlock30D;
         TotalBlock90D = _TotalBlock90D;
         TotalBlock180D = _TotalBlock180D;
         TotalBlock360D = _TotalBlock360D;
    }
    
    function emergencyUpdatePoolMinimumAmount(
         uint _minimumAmount
    ) public onlyOwner{
        AtLeastAmount = _minimumAmount;
    }
    
    function emergencyUpdatePoolDevAddress(
         address _developerAddress
    ) public onlyOwner{
        DeployerWalletAsdress = _developerAddress;
    }
    
    function emergencyUpdatePoolAPR(
        uint _Contract1D,
        uint _Contract7D,
        uint _Contract30D,
        uint _Contract90D,
        uint _Contract180D,
        uint _Contract360D,
        uint _TotalBlock1D,
        uint _TotalBlock7D,
        uint _TotalBlock30D,
        uint _TotalBlock90D,
        uint _TotalBlock180D,
        uint _TotalBlock360D 
        ) public onlyOwner {
            Contract1D = _Contract1D;
            Contract7D = _Contract7D;
            Contract30D = _Contract30D;
            Contract90D = _Contract90D;
            Contract180D = _Contract180D;
            Contract360D = _Contract360D;
            TotalBlock1D = _TotalBlock1D;
            TotalBlock7D = _TotalBlock7D;
            TotalBlock30D = _TotalBlock30D;
            TotalBlock90D = _TotalBlock90D;
            TotalBlock180D = _TotalBlock180D;
            TotalBlock360D = _TotalBlock360D;
    }
    
    function emergencyUpdatePoolFee(
        uint _StakeFees,
        uint _PenaltyFees,
        uint _AdditionalDeployerToken,
        uint _HarvestFees
        ) public onlyOwner {
         StakeFees =  _StakeFees;
         PenaltyFees =  _PenaltyFees;
         AdditionalDeployerToken  = _AdditionalDeployerToken;
         HarvestFees =  _HarvestFees;
    }
}