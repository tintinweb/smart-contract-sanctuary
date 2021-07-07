/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


// 
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
        this; // silence state mutability warning without generating bytecode 
        return msg.data;
    }
}

// 
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

// 
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
     * 
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

// 
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

// 
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
     * 
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
     * - the calling contract must have an BNB balance of at least `value`.
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

// 
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

        _beforeTokenTransfer(sender, recipient, amount);
  
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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');
        
        _beforeTokenTransfer(account, address(0), amount);

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}



contract SellPrivate is Ownable{
    using SafeMath for uint256;

    BEP20 public tokenReward;

    uint256 public totalBNBDeposit= 0;
    
    uint256 public dayUnlock = 1620655200;
    
    uint256 public percentMaxPayout= 300; ///Max reward can claim (unit %totalBNBDeposit)
    
    struct User {
        uint256 totalBNB;
        uint256 totalPGSDeposit;
        uint256 totalPGS;
        uint256 totalPGSLock;
        uint256 totalREFLock;
        uint256 totalREF;
        uint256 refLevel;
        address refParent;
    }
    struct Order {
        uint256 id;
        address userId;
        uint256 timestampCreated;
        uint256 amountBNB;
        bool [7] times;
        uint256 rewarded;
        uint256 totalReward;
        address address_refer;
        uint256 timestampLastWithDraw;
    }
 
 
    uint32 [72] private arrPriceBNBToPGS  = [ 3000 , 2609 , 2308 , 2070 , 1875 , 1714 , 1579 , 1463 , 1364 ,
                                              1277 , 1200 , 1132 , 1071 , 1017 , 968 , 923 , 882 , 845 ,
                                              811 , 779 , 741 , 706 , 674 , 645 , 619 , 595 , 571 ,
                                              550 , 531 , 513 , 492 , 472 , 454 , 438 , 422 , 408 ,
                                              395 , 382 , 370 , 359 , 347 , 335 , 324 , 315 , 305 ,
                                              296 , 287 , 279 , 271 , 265 , 256 , 249 , 242 , 235 ,
                                              230 , 223 , 217 , 212 , 207 , 202 , 197 , 193 , 189 ,
                                              185 , 181 , 177 , 173 , 170 , 166 , 163 , 160 , 157 ];
                              
    uint256 [73] private totalBNBRewardToPGS =  [ 34 , 91 , 156 , 228 , 308 , 396 , 491 , 593 , 703 ,
                                                821 , 946 , 1078 , 1218 , 1366 , 1521 , 1683 , 1853 , 2031 ,
                                                2216 , 2408 , 2678 , 2962 , 3258 , 3568 , 3892 , 4228 , 4578 , 
                                                4942 , 5318 , 5708 , 6217 , 6746 , 7295 , 7867 , 8458 , 9071 ,
                                                9704 , 10358 , 11033 , 11729 , 12594 , 13489 , 14414 , 15369 , 16354 ,
                                                17369 , 18414 , 19489 , 20594 , 21729 , 23094 , 24500 , 25947 , 27434 ,
                                                28963 , 30532 , 32142 , 33793 , 35484 , 37217 , 38990 , 40804 , 42659 ,
                                                44555 , 46492 , 48469 , 50488 , 52547 , 54647 , 56788 , 58970 , 61192 , 63000];
                                
    

    mapping (address => uint256) public balanceOf;
    


    mapping(address => User) public users;
    mapping(uint256 => Order) public orders;
    uint256 public orderCount;
    address public dev_adress = 0xB5329de92DaefD46dC570FAF240CeDD686FA9626;
    address public address_refer = 0x353Bd5864e1b0Efad21B90275164ABDfEA6e4605;
    address payable address_admin = 0x74dBdc24ea6ac7A3433b6cbA3a6bF7818Ff81728;
    
    address default_adress = 0x0000000000000000000000000000000000000000;
    uint256 percent_withDraw = 300000000000000000; ///(*)
    

    event Deposit(address indexed user, uint256 amount);
    event Transfer(address sender, address receiver, uint256 amount);
    mapping(address => address) public userIdsOrders;

    constructor(address _PGSToken) public {
        tokenReward = BEP20(_PGSToken);
    }

    function getName() public view returns (string memory) {
        return tokenReward.name();
    }

    function getTotalSupply() public view returns (uint256) {
        return tokenReward.totalSupply();
    }

    function getBalanceOf(address _owner) public view returns (uint256) {
        return tokenReward.balanceOf(_owner);
    }

    function getBalance() public view returns (uint256) {
        return tokenReward.balanceOf(address(this));
    }

    function sendTransferReward(address _to, uint256 _value) public {
        tokenReward.transfer(_to, _value);
    }

    function setTokenPGSReward(address _token) public onlyOwner {
        tokenReward = BEP20(_token);
    }

    function setDevReward(address _dev) public onlyOwner {
        dev_adress = _dev;
    }
    
    function setReferReward(address _ref) public onlyOwner {
        address_refer = _ref;
    }

    function setDayUnlock(uint256 _dayUnlock) public onlyOwner {
        dayUnlock = _dayUnlock;
    }
    
    function setPercentMaxPayout(uint256 _percent) public onlyOwner {
        percentMaxPayout = _percent;
    }

    function setAddressAdmin(address payable _address_admin) public onlyOwner {
        address_admin = _address_admin;
    }

    function setAddressRefer(address  _address_refer) public onlyOwner {
        address_refer = _address_refer;
    }
    
    function setPercent_withDraw(uint256  _percent_withDraw) public onlyOwner {
        percent_withDraw = _percent_withDraw;
    }
    
    function checkLimitAndSentReward(
        address _refer,
        uint256 bonus
    ) private {
        User storage user = users[_refer];
        uint256 currentTotalPGS = user.totalREF.add(bonus);
        uint256 totalPGSonBNBReward = user.totalPGSDeposit.mul(percentMaxPayout).div(100); //  percent on total BNB
        if (currentTotalPGS <= totalPGSonBNBReward) {
            user.totalREF = user.totalREF.add(bonus);
        } else {
            user.totalREF = totalPGSonBNBReward;
        }
    }
    
    
    function getBonus(uint256 _amountBNB, uint8 _level)  public view returns (uint256) {
        uint8 [3] memory arrBonus = [3,2,1];
        uint256 reward = 0;
        reward = (_amountBNB.mul(getRateTokenReward(_amountBNB))).div(100);
        return reward.mul(arrBonus[_level]);
    }
    
    function calBonusRefer(
        address _refer,
        uint256 _amountBNB
    ) private {
        User storage user = users[_refer];
        uint256 minTotalBNB = 1e18; /// Minimum to get reward is 1 BNB
        
        if (_refer == address_refer) {
            sendTransferReward(_refer, getBonus(_amountBNB,0));
        } else {
            if (user.totalBNB >= minTotalBNB) {
                checkLimitAndSentReward(_refer, getBonus(_amountBNB,0));
            }
    
            User storage userLevel1 = users[user.refParent];
            if (user.refParent == address_refer || (userLevel1.totalBNB >= minTotalBNB && user.refParent != address_refer)) {
                checkLimitAndSentReward(user.refParent, getBonus(_amountBNB,1));
            }
    
            User storage userLevel2 = users[userLevel1.refParent];
            if (
                userLevel1.refParent == address_refer || 
                (userLevel2.totalBNB >= minTotalBNB && userLevel1.refParent != address_refer)) {
                checkLimitAndSentReward(userLevel1.refParent, getBonus(_amountBNB,2));
            }
        }
    }
    
    function getRateTotalDeposit() public view returns (uint32) {
        uint32[72] memory arrPriceSale = arrPriceBNBToPGS;
        if (totalBNBDeposit < totalBNBRewardToPGS[0].mul(1e18)) {
           return arrPriceSale[0];
        }

        for(uint i = 1; i <= 71; i++) {
            if (totalBNBDeposit >= totalBNBRewardToPGS[i-1].mul(1e18) && totalBNBDeposit < totalBNBRewardToPGS[i].mul(1e18)) {
            return arrPriceSale[i];
            }
        }
    }

    function getRateTokenReward(
        uint256 _amountBNB
        ) public view returns (uint32) {
        uint32[72] memory arrPriceSale = arrPriceBNBToPGS;
        uint256 totalAmountAndBNBDeposit = _amountBNB.add(totalBNBDeposit);
        if (totalAmountAndBNBDeposit <= totalBNBRewardToPGS[0].mul(1e18)) {
           return arrPriceSale[0];
        }

        for(uint i = 1; i <= 71; i++) {
            if (totalAmountAndBNBDeposit > totalBNBRewardToPGS[i-1].mul(1e18) && totalAmountAndBNBDeposit <= totalBNBRewardToPGS[i].mul(1e18)) {
            return arrPriceSale[i];
            }
        }
    }
    
    function getRateTokenBuy() public view returns (uint32) {
        uint32[72] memory arrPriceBuy = arrPriceBNBToPGS;
        require(totalBNBDeposit >= totalBNBRewardToPGS[3], 'Coming soon');

        for(uint i = 3; i <= 71; i++) {
            if (totalBNBDeposit > totalBNBRewardToPGS[i-1].mul(1e18) && totalBNBDeposit <= totalBNBRewardToPGS[i].mul(1e18)) {
            return arrPriceBuy[i-3];
            }
        }
    }

    // Buy token PGS by deposit BNB
    function buyToken(
        uint256 _amountBNB,
        address _refer,
        uint256 _referLevel
    ) payable  public {
        require(msg.value == _amountBNB, 'Insufficient BNB balance');
        
        // minimum deposit 0.5 BNB
        require(_amountBNB >= 5e17, 'minimum deposit 0.5 BNB');   
        
        address userIdOrder = userIdsOrders[msg.sender];
        // insert or update amount for user

        User storage user = users[msg.sender];

        if (_refer == dev_adress) {
            user.refLevel = 1;
        } else {
            user.refLevel = _referLevel;
        }

        user.refParent = _refer;
        uint256 _rate_token_reward = getRateTokenReward(_amountBNB);
        
        // call bonus
        if (_refer != default_adress && userIdOrder == default_adress) {
            calBonusRefer(_refer, _amountBNB);
        }

        // calculator reward
        uint256 reward = _amountBNB.mul(_rate_token_reward);

        // create order
        userIdsOrders[msg.sender] = msg.sender;
        bool [7] memory times = [ false, false, false, false, false, false, false ];
        orders[orderCount] = Order(
            orderCount,
            msg.sender,
            block.timestamp,
            _amountBNB,
            times,
            0,
            reward,
            _refer,
            block.timestamp
        );
        if(msg.value>0){
            // sent amount to wallet addmin
            sentTransferBNB(address_admin);    
        }

        // update totalBNB deposit
        user.totalBNB = user.totalBNB.add(_amountBNB);
        user.totalPGSDeposit = user.totalPGSDeposit.add(reward);
        user.totalPGSLock = user.totalPGSLock.add(reward);
        totalBNBDeposit = totalBNBDeposit.add(_amountBNB);
        orderCount++;
    }
    
    ///Subtract Token PGS
    function tranferTotalREFtoTotalREFLock(address _address, uint256 _amountPGS)  public {
        User storage user = users[_address];
        user.totalREFLock = user.totalREFLock.add(_amountPGS);
        user.totalREF = user.totalREF.sub(_amountPGS);
    }
    
    function confirmTranferPartnerReward(address _address, uint256 _amountPGS)  public {
        User storage user = users[_address];
        user.totalREFLock = user.totalREFLock.sub(_amountPGS);
    }
    
    function rejectTranferPartnerReward(address _address, uint256 _amountPGS)  public {
        User storage user = users[_address];
        user.totalREF = user.totalREF.add(_amountPGS);
        user.totalREFLock = user.totalREFLock.sub(_amountPGS);
    }
    
    

    function withDrawToken(uint256 _orderId, uint256 _milestone) public {
        Order storage order = orders[_orderId];
        require(order.userId == msg.sender, 'Require created by sender');
        uint8 [7] memory arrmMilestone = [1,2,3,4,5,6,7];
        uint256 rewardPending = 0;
        uint256 feePending = 0;
        bool isWithDraw = false;
        uint256 milestone = 0;
        if (order.times[0] != true  && _milestone == arrmMilestone[0]) {
            milestone = 5;
            isWithDraw = true;
            order.times[0] = true;
        }

        if (order.times[1] != true && _milestone == arrmMilestone[1]) {
            milestone = 8;
            isWithDraw = true;
            order.times[1] = true;
        }

        if (order.times[2] != true && _milestone == arrmMilestone[2]) {
            milestone = 12;
            isWithDraw = true;
            order.times[2]= true;
        }

        if (order.times[3] != true && _milestone == arrmMilestone[3]) {
            milestone = 15;
            isWithDraw = true;
            order.times[3]= true;
        }
    
        if (order.times[4] != true && _milestone == arrmMilestone[4]) {
            milestone = 20;
            isWithDraw = true;
            order.times[4]= true;
        }
        if (order.times[5] != true && _milestone == arrmMilestone[5]) {
            milestone = 20;
            isWithDraw = true;
            order.times[5]= true;
        }
        if (order.times[6] != true && _milestone == arrmMilestone[6]) {
            milestone = 20;
            isWithDraw = true;
            order.times[6]= true;
        }
        
        if (isWithDraw) {
            rewardPending = getRewardByPercent(_orderId, milestone);
            feePending = (rewardPending.mul(percent_withDraw).div(1e18)).div(100); // percent 0.3%
            order.rewarded = order.rewarded.add(rewardPending);
            order.timestampLastWithDraw = block.timestamp;

            // sent transfer to sender
            sendTransferReward(msg.sender, rewardPending.sub(feePending));

            // sent fee to dev
            sendTransferReward(dev_adress, feePending);

            User storage user = users[order.userId];
            user.totalPGS = user.totalPGS.add(rewardPending);
            if (rewardPending > 0) {
                user.totalPGSLock = user.totalPGSLock.sub(rewardPending);
            }
        }
    }
    
    function withDrawReward(address _address) public {
        require(block.timestamp >= dayUnlock, 'Comming soon');
        User storage user = users[_address];
        uint256 rewardPending = 0;
        uint256 feePending = 0;
        rewardPending = user.totalREF;
        feePending = (rewardPending.mul(percent_withDraw).div(1e18).div(100));
        
        // sent tranfer to sender
        sendTransferReward(msg.sender, rewardPending.sub(feePending));
        
        // sent fee to dev
        sendTransferReward(dev_adress, feePending);
        
       
        user.totalPGS = user.totalPGS.add(rewardPending);
        if (rewardPending > 0) {
            user.totalREF = user.totalREF.sub(rewardPending);   
        }
    }
    
    function getRewardByPercent(uint256 _orderId, uint256 _milestone) public view returns (uint256) {
        Order memory order = orders[_orderId];
        uint256 rewardPending = 0;
        rewardPending = order.totalReward.mul(_milestone).div(100);
        return rewardPending;
    }

    function getOrder(uint256 _orderId) public view returns (Order memory) {
        return orders[_orderId];
    }

    function getUser(address _adr) public view returns (User memory) {
        return users[_adr];
    }

    function getOrders(address _user) public view returns (Order[] memory) {
        Order[] memory ordersTemp = new Order[](orderCount);
        uint256 count;
        for (uint256 i = 0; i < orderCount; i++) {
            if (orders[i].userId == _user) {
                ordersTemp[count] = orders[i];
                count += 1;
            }
        }
        Order[] memory filteredOrders = new Order[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredOrders[i] = ordersTemp[i];
        }
        return filteredOrders;
    }
    
    function getMaxPGSReward(address _user) public view returns (uint256) {
        User memory user = users[_user];
        return user.totalREF;
        
    }
    
    function getMaxPGSRewardLock(address _user) public view returns (uint256) {
        User memory user = users[_user];
        return user.totalREFLock;
        
    }
    
    function getTotalPGS(address _user) public view returns (uint256){
        User memory user = users[_user];
        return user.totalPGS; 
    }
    
    function getTotalPGSLock(address _user) public view returns (uint256) {
        User memory user = users[_user];
        return user.totalPGSLock;
    }
    
    function getPartnerReward(address _user) public view returns (address) {
        User memory user = users[_user];
        return user.refParent;
    }

    function sentTransferBNB(address payable _to) private {
       _to.transfer(msg.value);
    }   
}