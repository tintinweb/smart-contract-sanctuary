/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.9.0;


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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
 */
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








/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
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
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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






contract CuteToken is BEP20 {

    uint private _maxSupply;

    constructor (
        string memory name,
        string memory symbol,
        uint maxSupply

    )  public BEP20(name, symbol)  {
        _maxSupply = maxSupply;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) public onlyOwner {
        uint totalSupply = totalSupply();
        require( totalSupply.add(_amount) <= _maxSupply, 'above maxSupply limit');
        _mint(_to, _amount);
    }


    function burn(uint256 amount) public  onlyOwner {
        _burn(_msgSender(), amount);
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

}




interface ICuteTigerPair {
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}





library CuteTigerLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'CuteTigerLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'CuteTigerLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'bb600ba95884f2c2837114fd2f157d00137e0b65b0fe5226523d720e4a4ce539' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ICuteTigerPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'CuteTigerLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'CuteTigerLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'CuteTigerLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'CuteTigerLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'CuteTigerLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'CuteTigerLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'CuteTigerLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'CuteTigerLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}



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


contract CuteCrowdsale  is Context, ReentrancyGuard, Ownable { 

    using  SafeMath for uint;

  
    uint private constant _multiplier = 10**18;

    struct Sale {
        address investor;
        uint amount;
        bool tokensWithdrawn;
    }

    mapping(address => Sale) private _sales;

    address payable private _wallet;

    CuteToken private _token;
    uint private _openingTime;
    uint private _closingTime;
    uint private _initialIcoPrice;

    uint private _totalRaisedAmount;

    uint private _availableTokens;
    uint private _minPurchase;
    uint private _maxPurchase;
    
    address private _factory = 0x5Fe5cC0122403f06abE2A75DBba1860Edb762985;
    
    address private _busdAddress = 0xE0dFffc2E01A7f051069649aD4eb3F518430B6a4; 
    address private _usdtAddress = 0x7afd064DaE94d73ee37d19ff2D264f5A2903bBB0; 
    address private _usdcAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private _wbnbAddress = 0x0dE8FCAE8421fc79B29adE9ffF97854a424Cad09; 
    address private _daiAddress =  0x3Cf204795c4995cCf9C1a0B3191F00c01B03C56C; 
    address private _vaiAddress =  0x3Cf204795c4995cCf9C1a0B3191F00c01B03C56C; 

    IBEP20 private _busd = IBEP20(_busdAddress);
    IBEP20 private _usdt = IBEP20(_usdtAddress);
    IBEP20 private _usdc = IBEP20(_usdcAddress);
    IBEP20 private _wbnb = IBEP20(_wbnbAddress);
    IBEP20 private _dai =  IBEP20(_daiAddress);
    IBEP20 private _vai =  IBEP20(_vaiAddress);
      
    constructor (
        CuteToken token,
        address payable wallet,
        uint availableTokens,
        uint initialIcoPrice,
        uint minPurchase,
        uint maxPurchase) public  {
        require(  availableTokens > 0 && availableTokens <= token.maxSupply(), 'availableTokens should be > 0 and <= maxSupply');
        require(  minPurchase > 0, 'minPurchase should > 0');
        _token = token;
        _wallet = wallet;
        _availableTokens = availableTokens;
        _initialIcoPrice = initialIcoPrice;
        _minPurchase = minPurchase;
        _maxPurchase = maxPurchase;
    }

    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

    fallback () external  {
      buyTokens(_msgSender());
    }

    function buyTokens(address beneficiary) public nonReentrant icoActive()  payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint wbnbMinPurchase = tokenPrice(_minPurchase, _wbnbAddress);
        uint wbnbMaxPurchase = tokenPrice(_maxPurchase, _wbnbAddress);
        require(weiAmount >= wbnbMinPurchase && weiAmount <= wbnbMaxPurchase, "have to buy between _minPurchase and _maxPurchase");
        uint price = icoPrice();
        uint wbnbPrice = tokenPrice(price, _wbnbAddress);
        uint tokenAmount = weiAmount.div(wbnbPrice) * _multiplier;
        require( tokenAmount <= _availableTokens, 'Not enough tokens left for sale');
        Sale storage sale = _sales[beneficiary];
        uint newContribution = tokenAmount.add(sale.amount);
        _wallet.transfer(weiAmount);
        _processMint(tokenAmount, newContribution);
        _addToRaisedAmount(weiAmount, _wbnbAddress);
    }

    function buyUsingBUSD(uint busdAmount) external nonReentrant icoActive() {
        _preValidatePurchase(msg.sender, busdAmount);
        require(busdAmount >= _minPurchase && busdAmount <= _maxPurchase, "have to buy between _minPurchase and _maxPurchase");
        uint price = icoPrice();
        uint tokenAmount = busdAmount.div(price) * _multiplier;
        require( tokenAmount <= _availableTokens, 'Not enough tokens left for sale');
        Sale storage sale = _sales[msg.sender];
        uint newContribution = tokenAmount.add(sale.amount);
        _busd.transferFrom(msg.sender, _wallet, busdAmount);
        _processMint(tokenAmount, newContribution);
        _totalRaisedAmount = _totalRaisedAmount.add(busdAmount);
    }



    function buyUsingUSDT(uint usdtAmount) external nonReentrant icoActive() {
        _preValidatePurchase(msg.sender, usdtAmount);
        uint usdtMinPurchase = tokenPrice(_minPurchase, _usdtAddress);
        uint usdtMaxPurchase = tokenPrice(_maxPurchase, _usdtAddress);
        require(usdtAmount >= usdtMinPurchase && usdtAmount <= usdtMaxPurchase, "have to buy between _minPurchase and _maxPurchase");
        uint price = icoPrice();
        uint usdtPrice = tokenPrice(price, _usdtAddress);
        uint tokenAmount = usdtAmount.div(usdtPrice) * _multiplier;
        require( tokenAmount <= _availableTokens, 'Not enough tokens left for sale');
        Sale storage sale = _sales[msg.sender];
        uint newContribution = tokenAmount.add(sale.amount);
        _usdt.transferFrom(msg.sender, _wallet, usdtAmount);
        _processMint(tokenAmount, newContribution);
        _addToRaisedAmount(usdtAmount, _usdtAddress);
    }

    function buyUsingUSDC(uint usdcAmount) external nonReentrant icoActive() {
        _preValidatePurchase(msg.sender, usdcAmount);
        uint usdcMinPurchase = tokenPrice(_minPurchase, _usdcAddress);
        uint usdcMaxPurchase = tokenPrice(_maxPurchase, _usdcAddress);
        require(usdcAmount >= usdcMinPurchase && usdcAmount <= usdcMaxPurchase, "have to buy between _minPurchase and _maxPurchase");
        uint price = icoPrice();
        uint usdcPrice = tokenPrice(price, _usdcAddress);
        uint tokenAmount = usdcAmount.div(usdcPrice) * _multiplier;
        require( tokenAmount <= _availableTokens, 'Not enough tokens left for sale');
        Sale storage sale = _sales[msg.sender];
        uint newContribution = tokenAmount.add(sale.amount);
        _usdc.transferFrom(msg.sender, _wallet, usdcAmount);
        _processMint(tokenAmount, newContribution);
        _addToRaisedAmount(usdcAmount, _usdcAddress);
       
    }
    
    function buyUsingWBNB(uint wbnbAmount) external nonReentrant icoActive() {
        _preValidatePurchase(msg.sender, wbnbAmount);
        uint wbnbMinPurchase = tokenPrice(_minPurchase, _wbnbAddress);
        uint wbnbMaxPurchase = tokenPrice(_maxPurchase, _wbnbAddress);
        require(wbnbAmount >= wbnbMinPurchase && wbnbAmount <= wbnbMaxPurchase, "have to buy between _minPurchase and _maxPurchase");
        uint price = icoPrice();
        uint wbnbPrice = tokenPrice(price, _wbnbAddress);
        uint tokenAmount = wbnbAmount.div(wbnbPrice) * _multiplier;
        require( tokenAmount <= _availableTokens, 'Not enough tokens left for sale');
        Sale storage sale = _sales[msg.sender];
        uint newContribution = tokenAmount.add(sale.amount);
        _wbnb.transferFrom(msg.sender, _wallet, wbnbAmount);
        _processMint(tokenAmount, newContribution);
        _addToRaisedAmount(wbnbAmount, _wbnbAddress);
    }
    
    
    function buyUsingDAI(uint daiAmount) external nonReentrant icoActive() {
        _preValidatePurchase(msg.sender, daiAmount);
        uint daiMinPurchase = tokenPrice(_minPurchase, _daiAddress);
        uint daiMaxPurchase = tokenPrice(_maxPurchase, _daiAddress);
        require(daiAmount >= daiMinPurchase && daiAmount <= daiMaxPurchase, "have to buy between _minPurchase and _maxPurchase");
        uint price = icoPrice();
        uint daiPrice = tokenPrice(price, _daiAddress);
        uint tokenAmount = daiAmount.div(daiPrice) * _multiplier;
        require( tokenAmount <= _availableTokens, 'Not enough tokens left for sale');
        Sale storage sale = _sales[msg.sender];
        uint newContribution = tokenAmount.add(sale.amount);
        _dai.transferFrom(msg.sender, _wallet, daiAmount);
        _processMint(tokenAmount, newContribution);
        _addToRaisedAmount(daiAmount, _daiAddress);
    }

    function buyUsingVAI(uint vaiAmount) external nonReentrant icoActive() {
        _preValidatePurchase(msg.sender, vaiAmount);
        uint vaiMinPurchase = tokenPrice(_minPurchase, _vaiAddress);
        uint vaiMaxPurchase = tokenPrice(_maxPurchase, _vaiAddress);
        require(vaiAmount >= vaiMinPurchase && vaiAmount <= vaiMaxPurchase, "have to buy between _minPurchase and _maxPurchase");
        uint price = icoPrice();
        uint vaiPrice = tokenPrice(price, _vaiAddress);
        uint tokenAmount = vaiAmount.div(vaiPrice) * _multiplier;
        require( tokenAmount <= _availableTokens, 'Not enough tokens left for sale');
        Sale storage sale = _sales[msg.sender];
        uint newContribution = tokenAmount.add(sale.amount);
        _vai.transferFrom(msg.sender, _wallet, vaiAmount);
        _processMint(tokenAmount, newContribution);
        _addToRaisedAmount(vaiAmount, _vaiAddress);
    }

    
    function _addToRaisedAmount(uint256 contributionAmount, address token) internal {
        uint256 busdAmount = calculateBUSDPrice(contributionAmount, token);
        _totalRaisedAmount = _totalRaisedAmount.add(busdAmount);
    }


    function _preValidatePurchase(address beneficiary, uint256 amount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(amount != 0, "Crowdsale: amount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _processMint(uint tokenAmount, uint newContribution) internal { 
        _token.mint(address(this), tokenAmount);
        _availableTokens = _availableTokens.sub(tokenAmount);
        _sales[msg.sender] = Sale(
            msg.sender,
            newContribution,
            false
        );
    }


    function mint(uint tokenAmount, address to) public onlyOwner icoActive() { 
        require( tokenAmount <= _availableTokens, 'Not enough tokens left for sale');
        Sale storage sale = _sales[to];
        uint newContribution = tokenAmount.add(sale.amount);
        _token.mint(address(this), tokenAmount);
        _availableTokens = _availableTokens.sub(tokenAmount);
        _sales[to] = Sale(
            to,
            newContribution,
            false
        );
    }

    
    function tokenPrice(uint amountIn, address token) public view returns  (uint amount) {
        address[] memory path = new address[](2);
        path[0] = _busdAddress;
        path[1] = token;
        uint[] memory amounts = getAmountsOut(amountIn, path);
        return  amounts[1];

    }

    function calculateBUSDPrice(uint amountIn, address  token) public view returns  (uint amount) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = _busdAddress;
        uint[] memory amounts = getAmountsOut(amountIn, path);
        return  amounts[1];

    }
    
    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        returns (uint[] memory amounts)
    {
        return CuteTigerLibrary.getAmountsOut(_factory, amountIn, path);
    }



    function icoPrice() public view returns (uint256) {
        if (_openingTime >  0) {
            uint diff = (now - _openingTime) / 60 / 60 / 24;
            return _initialIcoPrice.add(diff * 1000000000000000); // 0.001
        } 
        return _initialIcoPrice;
    }



    function maxPurchase() public view returns (uint256) {
        return _maxPurchase;
    }

    function minPurchase() public view returns (uint256) {
        return _minPurchase;
    }

    function transferOwnershipContract() external onlyOwner {
        _token.transferOwnership(_wallet);
    }


    function increaseAvailableTokens(uint amount) external onlyOwner {
        require( amount > 0 , 'amount should be > 0');
        _availableTokens = _availableTokens.add(amount);
    }


    function modifyInitialIcoPrice(uint newIcoPrice) external onlyOwner {
        require( newIcoPrice > _initialIcoPrice , 'new ico price should be > _initialIcoPrice');
        _initialIcoPrice = newIcoPrice;
    }


    function totalRaisedAmount() public view onlyOwner returns (uint256) {
        return _totalRaisedAmount;
    }

    function cuteBalance() public view returns (uint256) {
      return _sales[msg.sender].amount;
    }

    function withdrawTokens() external nonReentrant icoEnded() {
        Sale storage sale = _sales[msg.sender];
        require(sale.amount > 0, 'only investors');
        require(sale.tokensWithdrawn == false, 'tokens were already withdrawn');
        sale.tokensWithdrawn = true;
        _token.transfer(sale.investor, sale.amount);
    }


    function startCrowdsale(uint256 closingTime) public onlyOwner icoNotActive() {
        require(closingTime > block.timestamp , 'duration should be > block.timestamp');
        _openingTime = block.timestamp;
        _closingTime = closingTime;
    }

    function stopCrowdsale() external onlyOwner icoActive() {
        _closingTime = 0;
    }

    function extendCrowdsaleTime(uint256 newClosingTime) external onlyOwner {
        require(newClosingTime > _closingTime, "New closing time is before current closing time");
        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }

    function endCrowdsale(uint256 newClosingTime) external onlyOwner icoActive() {
        require(newClosingTime < _closingTime, "New closing time is after current closing time");
        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }

    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    function isOpen() public view returns (bool) {
        return _closingTime > 0 && block.timestamp < _closingTime && _availableTokens > 0;
    }

    function hasClosed() public view returns (bool) {
        return block.timestamp > _closingTime;
    }

    modifier icoActive() {
        require(
          _closingTime > 0 && block.timestamp < _closingTime && _availableTokens > 0, 
          'ICO must be active'
        );
        _;
    }
    
    modifier icoNotActive() {
        require(_closingTime == 0, 'ICO should not be active');
        _;
    }
    
    modifier icoEnded() {
        require(
          _closingTime > 0 && (block.timestamp >= _closingTime || _availableTokens == 0), 
          'ICO must have ended'
        );
        _;
    }
    

}