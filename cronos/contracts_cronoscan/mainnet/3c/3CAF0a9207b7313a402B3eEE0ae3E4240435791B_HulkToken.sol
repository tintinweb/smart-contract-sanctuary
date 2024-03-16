/**
 *Submitted for verification at cronoscan.com on 2022-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
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
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `msg.sender`, decreasing the total supply.
     *
     */
    function burn(uint256 amount) public returns (bool) {
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
    ) internal virtual {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
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
        require(account != address(0), 'BEP20: mint to the zero address');

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
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
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
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

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
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

interface ISphynxPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function swapFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
}

interface ISphynxFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setSwapFee(address _pair, uint32 _swapFee) external;
}

interface ISphynxRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface ISphynxRouter02 is ISphynxRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract HulkToken is BEP20 {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    ISphynxRouter02 public sphynxSwapRouter;
    address public sphynxSwapPair;

    bool private swapping;
    address payable public liquidityWallet = payable(0xecd8fdC64dcb405c0d4b4aF6a0Fb1f2d829c0884);

    address payable public marketingWallet =
        payable(0xa6Ae6E2FeeC175d0054668F377B5E37fA313D109);
    address payable public buyBackWallet = payable(0xBEB84d710591056BE939331FeC43f02eca005580);
    address payable public serviceWallet = payable(0xecd8fdC64dcb405c0d4b4aF6a0Fb1f2d829c0884);
    address payable public otherWallet = payable(0x10e1450b7D6273ffDC660a1e2f914629b765aAEc);

    uint256 public nativeAmountToSwap = 1 ether;

    uint256 public marketingFeeOnBuy;
    uint256 public buyBackFeeOnBuy;
    uint256 public buyBackFeeOnSell;
    uint256 public totalFeesOnBuy;
    uint256 public marketingFeeOnSell;
    uint256 public liquidityFeeOnBuy;
    uint256 public liquidityFeeOnSell;
    uint256 public burnFeeOnSell;
    uint256 public burnFeeOnBuy;
    uint256 public totalFeesOnSell;
    uint256 public blockNumber;
    uint256 public serviceTokenAmount;
    uint256 public serviceFee = 2;
    uint256 public liquidityShare = 2;
    uint256 public marketingShare = 4;
    uint256 public buyBackShare = 4;
    uint256 public totalShares = 10;

    bool public SwapAndLiquifyEnabled = false;
    uint256 public maxTxAmount = 1000000000 * (10**9); // Initial Max Tx Amount

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // getting fee addresses
    mapping(address => bool) public _isGetFees;

    // store addresses that are automated market maker pairs. Any transfer to these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

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

    // Contract Events
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event GetFee(address indexed account, bool isGetFee);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event MarketingWalletUpdated(
        address indexed newMarketingWallet,
        address indexed oldMarketingWallet
    );

    event BuyBackWalletUpdated(
        address indexed newBuyBackWallet,
        address indexed oldBuyBackWallet
    );
    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );
    event UpdateSphynxSwapRouter(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 nativeReceived,
        uint256 tokensIntoLiqudity
    );
    event UpdateSwapAndLiquify(bool value);
    event SetMarketingFee(uint256 onBuy, uint256 onSell);
    event SetBuyBackFee(uint256 onBuy, uint256 onSell);
    event SetDistribution(
        uint256 liquidity,
        uint256 marketing,
        uint256 buyback
    );
    event SetLiquidityFee(uint256 onBuy, uint256 onSell);
    event SetBurnFee(uint256 onBuy, uint256 onSell);
    event SetNativeAmountToSwap(uint256 nativeAmountToSwap);
    event SetBlockNumber(uint256 blockNumber);
    event UpdateMaxTxAmount(uint256 txAmount);

    constructor() public BEP20("InCROdible Hulk", "Incrodible", 9) {
        marketingFeeOnBuy = 4;
        marketingFeeOnSell = 4;
        buyBackFeeOnBuy = 4;
        buyBackFeeOnSell = 4;
        liquidityFeeOnBuy = 2;
        liquidityFeeOnSell = 2;
        burnFeeOnBuy = 1;
        burnFeeOnSell = 1;
        totalFeesOnBuy = marketingFeeOnBuy
            .add(liquidityFeeOnBuy)
            .add(buyBackFeeOnBuy)
            .add(burnFeeOnBuy)
            .add(serviceFee);
        totalFeesOnSell = marketingFeeOnSell
            .add(liquidityFeeOnSell)
            .add(buyBackFeeOnSell)
            .add(burnFeeOnSell)
            .add(serviceFee);
        blockNumber = 0;

        ISphynxRouter02 _sphynxSwapRouter = ISphynxRouter02(
            0xF8de99b34175bC66d12129Ec6345F4d875d2f049
        ); // mainnet
        // Create a sphynxswap pair for SPHYNX
        address _sphynxSwapPair = ISphynxFactory(_sphynxSwapRouter.factory())
            .createPair(address(this), _sphynxSwapRouter.WETH());

        sphynxSwapRouter = _sphynxSwapRouter;
        sphynxSwapPair = _sphynxSwapPair;

        _setAutomatedMarketMakerPair(sphynxSwapPair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(buyBackWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        // set getFee addresses
        _isGetFees[_sphynxSwapPair] = true;

        _mint(owner(), 100000000 * (10**9));

        _status = _NOT_ENTERED;
    }

    receive() external payable {}

    function updateSwapAndLiquifiy(bool value) public onlyOwner {
        SwapAndLiquifyEnabled = value;
        emit UpdateSwapAndLiquify(value);
    }

    function setMarketingFee(uint256 _onBuy, uint256 _onSell)
        external
        onlyOwner
    {
        require(_onBuy <= 10 && _onSell <= 10, "Invalid marketingFee");
        marketingFeeOnBuy = _onBuy;
        marketingFeeOnSell = _onSell;
        totalFeesOnBuy = marketingFeeOnBuy
            .add(liquidityFeeOnBuy)
            .add(buyBackFeeOnBuy)
            .add(burnFeeOnBuy)
            .add(serviceFee);
        totalFeesOnSell = marketingFeeOnSell
            .add(liquidityFeeOnSell)
            .add(buyBackFeeOnSell)
            .add(burnFeeOnSell)
            .add(serviceFee);
        emit SetMarketingFee(_onBuy, _onSell);
    }

    function setBuyBackFee(uint256 _onBuy, uint256 _onSell)
        external
        onlyOwner
    {
        require(_onBuy <= 10 && _onSell <= 10, "Invalid buyBackFee");
        buyBackFeeOnBuy = _onBuy;
        buyBackFeeOnSell = _onSell;
        totalFeesOnBuy = buyBackFeeOnBuy
            .add(marketingFeeOnBuy)
            .add(liquidityFeeOnBuy)
            .add(burnFeeOnBuy)
            .add(serviceFee);
        totalFeesOnSell = buyBackFeeOnSell
            .add(marketingFeeOnSell)
            .add(liquidityFeeOnSell)
            .add(burnFeeOnSell)
            .add(serviceFee);
        emit SetBuyBackFee(_onBuy, _onSell);
    }

    function setLiquidityFee(uint256 _onBuy, uint256 _onSell)
        external
        onlyOwner
    {
        require(_onBuy <= 10 && _onSell <= 10, "Invalid Liquidity Fee");
        liquidityFeeOnBuy = _onBuy;
        liquidityFeeOnSell = _onSell;
        totalFeesOnBuy = liquidityFeeOnBuy
            .add(marketingFeeOnBuy)
            .add(buyBackFeeOnBuy)
            .add(burnFeeOnBuy)
            .add(serviceFee);
        totalFeesOnSell = liquidityFeeOnSell
            .add(marketingFeeOnSell)
            .add(buyBackFeeOnSell)
            .add(burnFeeOnSell)
            .add(serviceFee);
        emit SetLiquidityFee(_onBuy, _onSell);
    }

    function setBurnFee(uint256 _onBuy, uint256 _onSell)
        external
        onlyOwner
    {
        require(_onBuy <= 10 && _onSell <= 10, "Invalid Burn Fee");
        burnFeeOnBuy = _onBuy;
        burnFeeOnSell = _onSell;
        totalFeesOnBuy = liquidityFeeOnBuy
            .add(marketingFeeOnBuy)
            .add(buyBackFeeOnBuy)
            .add(burnFeeOnBuy)
            .add(serviceFee);
        totalFeesOnSell = liquidityFeeOnSell
            .add(marketingFeeOnSell)
            .add(buyBackFeeOnSell)
            .add(burnFeeOnSell)
            .add(serviceFee);
        emit SetBurnFee(_onBuy, _onSell);
    }

    function updateShares(
        uint256 _liquidity,
        uint256 _marketing,
        uint256 _buyBack
    ) external onlyOwner {
        liquidityShare = _liquidity;
        marketingShare = _marketing;
        buyBackShare = _buyBack;
        totalShares = liquidityShare
            .add(marketingShare)
            .add(buyBackShare);

        emit SetDistribution(_liquidity, _marketing, _buyBack);
    }

    function updateSphynxSwapRouter(address newAddress) public onlyOwner {
        require(
            newAddress != address(sphynxSwapRouter),
            "The router already has that address"
        );
        emit UpdateSphynxSwapRouter(newAddress, address(sphynxSwapRouter));
        sphynxSwapRouter = ISphynxRouter02(newAddress);
        address _sphynxSwapPair;
        _sphynxSwapPair = ISphynxFactory(sphynxSwapRouter.factory()).getPair(
            address(this),
            sphynxSwapRouter.WETH()
        );
        if (_sphynxSwapPair == address(0)) {
            _sphynxSwapPair = ISphynxFactory(sphynxSwapRouter.factory())
                .createPair(address(this), sphynxSwapRouter.WETH());
        }
        _setAutomatedMarketMakerPair(sphynxSwapPair, false);
        sphynxSwapPair = _sphynxSwapPair;
        _setAutomatedMarketMakerPair(sphynxSwapPair, true);
    }

    function excludeFromFees(address account, bool excluded)
        public
        onlyOwner
    {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setFeeAccount(address account, bool isGetFee) public onlyOwner {
        require(
            _isGetFees[account] != isGetFee,
            "Account is already the value of 'isGetFee'"
        );
        _isGetFees[account] = isGetFee;

        emit GetFee(account, isGetFee);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setNativeAmountToSwap(uint256 _nativeAmount) public onlyOwner {
        nativeAmountToSwap = _nativeAmount;
        emit SetNativeAmountToSwap(nativeAmountToSwap);
    }

    function updateMarketingWallet(address newMarketingWallet)
        public
        onlyOwner
    {
        require(
            newMarketingWallet != marketingWallet,
            "The marketing wallet is already this address"
        );
        excludeFromFees(newMarketingWallet, true);
        excludeFromFees(marketingWallet, false);
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = payable(newMarketingWallet);
    }

    function updateLiquidityWallet(address _liquidityWallet)
        external
        onlyOwner
    {
        require(
            _liquidityWallet != liquidityWallet,
            "The liquidity Wallet is already this address"
        );
        excludeFromFees(_liquidityWallet, true);
        emit LiquidityWalletUpdated(_liquidityWallet, liquidityWallet);
        liquidityWallet = payable(_liquidityWallet);
    }

    function updateBuyBackWallet(address newBuyBackWallet)
        public
        onlyOwner
    {
        require(
            newBuyBackWallet != buyBackWallet,
            "The buyback wallet is already this address"
        );
        excludeFromFees(newBuyBackWallet, true);
        excludeFromFees(buyBackWallet, false);
        buyBackWallet = payable(newBuyBackWallet);
        emit BuyBackWalletUpdated(newBuyBackWallet, buyBackWallet);
    }

    function setBlockNumber() public onlyOwner {
        blockNumber = block.number;
        emit SetBlockNumber(blockNumber);
    }

    function updateMaxTxAmount(uint256 _amount) public onlyOwner {
        maxTxAmount = _amount;
        emit UpdateMaxTxAmount(_amount);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount <= maxTxAmount, "max-tx-amount-overflow");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (SwapAndLiquifyEnabled) {
            uint256 contractTokenBalance = balanceOf(address(this));
            uint256 nativeTokenAmount = _getTokenAmountFromNative();

            bool canSwap = contractTokenBalance >= nativeTokenAmount;

            if (canSwap && !swapping && !automatedMarketMakerPairs[from]) {
                swapping = true;
                // Set number of tokens to sell to nativeTokenAmount
                contractTokenBalance = nativeTokenAmount;
                swapTokens(contractTokenBalance);
                swapping = false;
            }
        }

        if (_isGetFees[to] && blockNumber == 0) {
            blockNumber = block.number;
        }

        // indicates if fee should be deducted from transfer
        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            if (block.number - blockNumber <= 10) {
                uint256 afterBalance = balanceOf(to) + amount;
                require(
                    afterBalance <= 250000 * (10**18),
                    "Owned amount exceeds the maxOwnedAmount"
                );
            }
            uint256 fees;
            if (_isGetFees[from] || _isGetFees[to]) {
                if (block.number - blockNumber <= 10) {
                    fees = amount.mul(99).div(10**2);
                    super._transfer(from, address(this), fees);
                } else {
                    if (_isGetFees[from]) {
                        fees = amount.mul(totalFeesOnBuy).div(10**2);
                        super._transfer(from, address(this), fees);
                        serviceTokenAmount = serviceTokenAmount.add(fees.mul(serviceFee).div(totalFeesOnBuy));
                        super._burn(address(this), amount.mul(burnFeeOnBuy).div(100));
                    } else {
                        fees = amount.mul(totalFeesOnSell).div(10**2);
                        super._transfer(from, address(this), fees);
                        serviceTokenAmount = serviceTokenAmount.add(fees.mul(serviceFee).div(totalFeesOnSell));
                        super._burn(address(this), amount.mul(burnFeeOnSell).div(100));
                    }
                }
                amount = amount.sub(fees);
            }
        }

        super._transfer(from, to, amount);
    }

    function swapTokens(uint256 tokenAmount) private {
        uint256 sphynxSwapAmount = tokenAmount.mul(serviceTokenAmount).div(super.balanceOf(address(this)));
        uint256 tokensForLiquidity = tokenAmount.mul(liquidityShare).div(
            totalShares
        );
        uint256 swapTokenAmount = tokenAmount.sub(tokensForLiquidity);
        swapTokensForNative(swapTokenAmount);
        uint256 swappedNative = address(this).balance;
        uint256 sphynxNative = swappedNative.mul(sphynxSwapAmount).div(swapTokenAmount);
        swappedNative = swappedNative.sub(sphynxNative);
        serviceTokenAmount = serviceTokenAmount.sub(sphynxSwapAmount);
        uint256 nativeForLiquidity = swappedNative.mul(liquidityShare).div(
            totalShares
        );
        uint256 nativeForBuyBack = swappedNative.mul(buyBackShare).div(
            totalShares
        );
        uint256 nativeForMarketing = swappedNative
            .sub(nativeForLiquidity)
            .sub(nativeForBuyBack);
        if (sphynxNative > 0) {
            transferNativeToServiceWallet(sphynxNative);
        }
        if (tokensForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, nativeForLiquidity);
        }
        if (nativeForBuyBack > 0) {
            transferNativeToBuyBackWallet(nativeForBuyBack);
        }
        if (nativeForMarketing > 0) {
            transferNativeToMarketingWallet(nativeForMarketing);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 nativeAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(sphynxSwapRouter), tokenAmount);

        // add the liquidity
        sphynxSwapRouter.addLiquidityETH{value: nativeAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    // Swap tokens on SphynxSwap
    function swapTokensForNative(uint256 tokenAmount) private {
        // generate the sphynxswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = sphynxSwapRouter.WETH();

        _approve(address(this), address(sphynxSwapRouter), tokenAmount);

        // make the swap
        sphynxSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Native
            path,
            address(this),
            block.timestamp + 120
        );
    }

    function _getTokenAmountFromNative() internal view returns (uint256) {
        uint256 tokenAmount;
        address[] memory path = new address[](2);
        path[0] = sphynxSwapRouter.WETH();
        path[1] = address(this);
        uint256[] memory amounts = sphynxSwapRouter.getAmountsOut(
            nativeAmountToSwap,
            path
        );
        tokenAmount = amounts[1];
        return tokenAmount;
    }

    function transferNativeToMarketingWallet(uint256 amount) private {
        marketingWallet.transfer(amount);
    }

    function transferNativeToBuyBackWallet(uint256 amount) private {
        buyBackWallet.transfer(amount);
    }

    function transferNativeToServiceWallet(uint256 amount) private {
        uint256 serviceAmount = amount.div(2);
        uint256 otherAmount = amount.sub(serviceAmount);
        serviceWallet.transfer(serviceAmount);
        otherWallet.transfer(otherAmount);
    }
}