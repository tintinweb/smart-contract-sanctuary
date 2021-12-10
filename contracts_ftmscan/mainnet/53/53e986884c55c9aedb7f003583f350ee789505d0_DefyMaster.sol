/**
 *Submitted for verification at FtmScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// website: www.defyswap.finance

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
interface IERC20 {
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
abstract contract ReentrancyGuard {
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

// 
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ERC20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

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
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
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
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
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
     * @dev See {ERC20-transferFrom}.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
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
     * problems described in {ERC20-approve}.
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
            _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
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
    function mint(uint256 amount) public virtual onlyOwner returns (bool) {
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
    ) internal virtual{
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
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
        require(account != address(0), 'ERC20: mint to the zero address');

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
        require(account != address(0), 'ERC20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
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
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

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
            _allowances[account][_msgSender()].sub(amount, 'ERC20: burn amount exceeds allowance')
        );
    }
}

// DFYToken with Governance.
contract DfyToken is ERC20('DefySwap', 'DFY') {
    
    
    mapping (address => bool) private _isRExcludedFromFee; // excluded list from receive 
    mapping (address => bool) private _isSExcludedFromFee; // excluded list from send
    mapping (address => bool) private _isPair;
    
    uint256 public _burnFee = 40;
    uint256 public _ilpFee = 5;
    uint256 public _devFee = 4;
    
    uint256 public _maxTxAmount = 10 * 10**6 * 1e18;
    uint256 public constant _maxSupply = 10 * 10**6 * 1e18;
    
    address public BURN_VAULT;
    address public ILP_VAULT;
    address public defyMaster;
    address public dev;
    address public router;
    
    event NewDeveloper(address);
    event ExcludeFromFeeR(address);	
    event ExcludeFromFeeS(address);	
    event IncludeInFeeR(address);
    event IncludeInFeeS(address);
    event SetRouter(address);
    event SetPair(address,bool);
    event BurnFeeUpdated(uint256,uint256);
    event IlpFeeUpdated(uint256,uint256);
    event DevFeeUpdated(uint256,uint256);
    event SetBurnVault(address);
    event SetIlpVault(address);
    event SetDefyMaster(address);
    event Burn(uint256);
    
    modifier onlyDev() {
        require(msg.sender == owner() || msg.sender == dev , "Error: Require developer or Owner");
        _;
    }
    modifier onlyMaster() {
        require(msg.sender == defyMaster , "Error: Only DefyMaster");
        _;
    }
    
    constructor(address _dev, address _bunVault,  uint256 _initAmount) public {
     	require(_dev != address(0), 'DEFY: dev cannot be the zero address');
     	require(_bunVault != address(0), 'DEFY: burn vault cannot be the zero address');
     	dev = _dev;
     	BURN_VAULT = _bunVault;
     	defyMaster = msg.sender;
     	mint(msg.sender,_initAmount);
        _isRExcludedFromFee[msg.sender] = true;
        _isRExcludedFromFee[_bunVault] = true;
        _isRExcludedFromFee[_dev] = true;
        _isSExcludedFromFee[msg.sender] = true;
        _isSExcludedFromFee[_bunVault] = true;
        _isSExcludedFromFee[_dev] = true;
    }
    
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (DefyMaster).
    function mint(address _to, uint256 _amount) public onlyMaster returns (bool) {
        require(_maxSupply >= totalSupply().add(_amount) , "Error : Total Supply Reached" );
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
        return true;
    }
    
    function mint(uint256 amount) public override onlyMaster returns (bool) {
        require(_maxSupply >= totalSupply().add(amount) , "Error : Total Supply Reached" );
        _mint(_msgSender(), amount);
        _moveDelegates(address(0), _delegates[_msgSender()], amount);
        return true;
    }
    
    // Exclude an account from receive fee
    function excludeFromFeeR(address account) external onlyOwner {
        require(!_isRExcludedFromFee[account], "Account is already excluded From receive Fee");
        _isRExcludedFromFee[account] = true;	
        emit ExcludeFromFeeR(account);	
    }
    // Exclude an account from send fee
    function excludeFromFeeS(address account) external onlyOwner {
        require(!_isSExcludedFromFee[account], "Account is already excluded From send Fee");
        _isSExcludedFromFee[account] = true;	
        emit ExcludeFromFeeS(account);	
    }
    // Include an account in receive fee	
    function includeInFeeR(address account) external onlyOwner {	
         require( _isRExcludedFromFee[account], "Account is not excluded From receive Fee");	
        _isRExcludedFromFee[account] = false;	
        emit IncludeInFeeR(account);	
    }
    // Include an account in send fee
    function includeInFeeS(address account) external onlyOwner {	
         require( _isSExcludedFromFee[account], "Account is not excluded From send Fee");	
        _isSExcludedFromFee[account] = false;	
        emit IncludeInFeeS(account);	
    }
    
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), 'DEFY: Router cannot be the zero address');
        router = _router;	
        emit SetRouter(_router);	
    }
    
    function setPair(address _pair, bool _status) external onlyOwner {
        require(_pair != address(0), 'DEFY: Pair cannot be the zero address');
        _isPair[_pair] = _status;	
        emit SetPair(_pair , _status);	
    }
    	
    function setBurnFee(uint256 burnFee) external onlyOwner() {	
        require(burnFee <= 80 , "Error : MaxBurnFee is 8%");
        uint256 _previousBurnFee = _burnFee;	
        _burnFee = burnFee;	
        emit BurnFeeUpdated(_previousBurnFee,_burnFee);	
    }	
    	
    function setDevFee(uint256 devFee) external onlyOwner() {	
        require(devFee <= 20 , "Error : MaxDevFee is 2%");
        uint256 _previousDevFee = _devFee;	
        _devFee = devFee;	
        	
        emit DevFeeUpdated(_previousDevFee,_devFee);	
    }
    
    function setIlpFee(uint256 ilpFee) external onlyOwner() {	
        require(ilpFee <= 50 , "Error : MaxIlpFee is 5%");
        uint256 _previousIlpFee = _ilpFee;	
        _ilpFee = ilpFee;	
        	
        emit IlpFeeUpdated(_previousIlpFee,_ilpFee);	
    }
   	
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent >= 5 , "Error : Minimum maxTxLimit is 5%");
        require(maxTxPercent <= 100 , "Error : Maximum maxTxLimit is 100%");
        _maxTxAmount = totalSupply().mul(maxTxPercent).div(	
            10**2	
        );	
    }
    
    function setDev(address _dev) external onlyDev {
        require(dev != address(0), 'DEFY: dev cannot be the zero address');
        _isRExcludedFromFee[dev] = false;
        _isSExcludedFromFee[dev] = false;
        dev = _dev ;
        _isRExcludedFromFee[_dev] = true;
        _isSExcludedFromFee[_dev] = true;	
        emit NewDeveloper(_dev);
    }
    
    function setBurnVault(address _burnVault) external onlyMaster {
        _isRExcludedFromFee[BURN_VAULT] = false;	
        _isSExcludedFromFee[BURN_VAULT] = false;	
        BURN_VAULT = _burnVault ;
        _isRExcludedFromFee[_burnVault] = true;
        _isSExcludedFromFee[_burnVault] = true;
        emit SetBurnVault(_burnVault);
    }
    
    function setIlpVault(address _ilpVault) external onlyOwner {
        _isRExcludedFromFee[ILP_VAULT] = false;
        _isSExcludedFromFee[ILP_VAULT] = false;
        ILP_VAULT = _ilpVault;
        _isRExcludedFromFee[_ilpVault] = true;
        _isSExcludedFromFee[_ilpVault] = true;
        emit SetIlpVault(_ilpVault);
    }
    
    
    
    function setMaster(address master) public onlyMaster {
        require(master!= address(0), 'DEFY: DefyMaster cannot be the zero address');
        defyMaster = master;
        _isRExcludedFromFee[master] = true;
        _isSExcludedFromFee[master] = true;
        emit SetDefyMaster(master);
    }
    
    function isExcludedFromFee(address account) external view returns(bool Rfee , bool SFee) {	
        return (_isRExcludedFromFee[account] , _isSExcludedFromFee[account] );
    }
    function isPair(address account) external view returns(bool) {	
        return _isPair[account];
    }
    
    function burnToVault(uint256 amount) public {
        _transfer(msg.sender, BURN_VAULT, amount);
    }
    
   //  @notice Destroys `amount` tokens from `account`, reducing the total supply.
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        _moveDelegates(address(0), _delegates[msg.sender], amount);
        emit Burn(amount);
    }
    
    function transferTaxFree(address recipient, uint256 amount) public returns (bool) {
        require(_isPair[_msgSender()] || _msgSender() == router , "DFY: Only DefySwap Router or Defy pair");
        super._transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFromTaxFree(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_isPair[_msgSender()] || _msgSender() == router , "DFY: Only DefySwap Router or Defy pair");
        super._transfer(sender, recipient, amount);
        super._approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }
    
    /// @dev overrides transfer function to meet tokenomics of DEFY
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        
        //if any account belongs to _isExcludedFromFee account then remove the fee	

        if (_isSExcludedFromFee[sender] || _isRExcludedFromFee[recipient]) {
            super._transfer(sender, recipient, amount);
        }
        else {
            // A percentage of every transfer goes to Burn Vault ,ILP Vault & Dev
            uint256 burnAmount = amount.mul(_burnFee).div(1000);
            uint256 ilpAmount = amount.mul(_ilpFee).div(1000);
            uint256 devAmount = amount.mul(_devFee).div(1000);
            
            // Remainder of transfer sent to recipient
            uint256 sendAmount = amount.sub(burnAmount).sub(ilpAmount).sub(devAmount);
            require(amount == sendAmount + burnAmount + ilpAmount + devAmount , "DEFY Transfer: Fee value invalid");

            super._transfer(sender, BURN_VAULT, burnAmount);
            super._transfer(sender, ILP_VAULT, ilpAmount);
            super._transfer(sender, dev, devAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DEFY::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DEFY::delegateBySig: invalid nonce");
        require(now <= expiry, "DEFY::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "DEFY::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying DEFYs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "DEFY::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// 
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}

// DefySTUB interface.
interface DefySTUB is IERC20 {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (DefyMaster).
    function mint(address _to, uint256 _amount) external ;
    function burn(address _from ,uint256 _amount) external ;
}

//BurnVault
contract BurnVault is Ownable {
    
    DfyToken public defy;
    address public defyMaster;
    
    event SetDefyMaster(address);
    event Burn(uint256);
    
    modifier onlyDefy() {
        require(msg.sender == owner() || msg.sender == defyMaster , "Error: Require developer or Owner");
        _;
    }
    
    function setDefyMaster (address master) external onlyDefy{
        defyMaster = master ;
        emit SetDefyMaster(master);
    }
    
    function setDefy (address _defy) external onlyDefy{
        defy = DfyToken(_defy);
    }
    
    function burn () public onlyDefy {
        uint256 amount = defy.balanceOf(address(this));
        defy.burn(amount);
        emit Burn(amount);
    }
    
    function burnPortion (uint256 amount) public onlyDefy {
        defy.burn(amount);
        emit Burn(amount);
    }
    
    
    
}

//ILP Interface.
interface ImpermanentLossProtection{
	//IMPERMANENT LOSS PROTECTION ABI
    function add(address _lpToken, IERC20 _token0, IERC20 _token1, bool _offerILP) external; 
    function set(uint256 _pid, IERC20 _token0,IERC20 _token1, bool _offerILP) external;
    function getDepositValue(uint256 amount, uint256 _pid) external view returns (uint256 userDepValue);
    function defyTransfer(address _to, uint256 _amount) external;
    function getDefyPrice(uint256 _pid) external view returns (uint256 defyPrice);
}

// DefyMaster is the master of Defy. He can make Dfy and he is a fair guy.
// Have fun reading it. Hopefully it's bug-free. God bless.
contract DefyMaster is Ownable , ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below. (same as rewardDebt)
        uint256 rewardDebtDR; // Reward debt Secondary reward. See explanation below.
        uint256 depositTime; // Time when the user deposit LP tokens.
		uint256 depVal; // LP token value at the deposit time.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DFYs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDefyPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDefyPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;                 // Address of LP token contract.
        DefySTUB stubToken;             // STUB / Receipt Token for farmers.
        uint256 allocPoint;             // How many allocation points assigned to this pool. DFYs to distribute per Second.
        uint256 allocPointDR;           // How many allocation points assigned to this pool for Secondary Reward. 
        uint256 depositFee;             // LP Deposit fee.
        uint256 withdrawalFee;          // LP Withdrawal fee
        uint256 lastRewardTimestamp;    // Last timestamp that DFYs distribution occurs.
        uint256 lastRewardTimestampDR;  // Last timestamp that Secondary Reward distribution occurs.
        uint256 rewardEndTimestamp;     // Reward ending Timestamp.
        uint256 accDefyPerShare;        // Accumulated DFYs per share, times 1e12. See below.
        uint256 accSecondRPerShare;     // Accumulated Second Reward Tokens per share, times 1e24. See below.
        uint256 lpSupply;               // Total Lp tokens Staked in farm.
		bool impermanentLossProtection; // ILP availability
		bool issueStub;                 // STUB Availability.
    }

    // The DFY TOKEN!
    DfyToken public defy;
    // Secondary Reward Token.
    IERC20 public secondR;
    // BurnVault.
    BurnVault public burn_vault;
    //ILP Contract
    ImpermanentLossProtection public ilp;
    // Dev address.
    address public devaddr;
    // Emergency Dev
    address public emDev;
    // Deposit/Withdrawal Fee address
    address public feeAddress;
    // DFY tokens created per second.
    uint256 public defyPerSec;
    // Secondary Reward distributed per second.
    uint256 public secondRPerSec;
    // Bonus muliplier for early dfy makers.
    uint256 public BONUS_MULTIPLIER = 1;
    //Max uint256
    uint256 constant MAX_INT = type(uint256).max ;
    // Seconds per burn cycle.
    uint256 public SECONDS_PER_CYCLE = 365 * 2 days ; 
    // Max DFY Supply.
    uint256 public constant MAX_SUPPLY = 10 * 10**6 * 1e18;
    // Next minting cycle start timestamp.
    uint256 public nextCycleTimestamp;
    // The Timestamp when Secondary Reward mining ends.
    uint256 public endTimestampDR = MAX_INT;

    // Info of each pool.
  PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // Total allocation points for Dual Reward. Must be the sum of all Dual reward allocation points in all pools.
    uint256 public totalAllocPointDR = 0;
    // The Timestamp when DFY mining starts.
    uint256 public startTimestamp;
    
    modifier onlyDev() {
        require(msg.sender == owner() || msg.sender == devaddr , "Error: Require developer or Owner");
        _;
    }
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
    event SetFeeAddress(address newAddress);
    event SetDevAddress(address newAddress);
    event SetDFY(address dfy);
    event SetSecondaryReward(address newToken);
    event UpdateEmissionRate(uint256 defyPerSec);
    event UpdateSecondaryEmissionRate(uint256 secondRPerSec);
    event DFYOwnershipTransfer(address newOwner);
    event RenounceEmDev();
    
    event addPool(
        uint256 indexed pid, 
        address lpToken, 
        uint256 allocPoint, 
        uint256 allocPointDR, 
        uint256 depositFee, 
        uint256 withdrawalFee, 
        bool offerILP, 
        bool issueStub,
        uint256 rewardEndTimestamp);
    
    event setPool(
        uint256 indexed pid, 
        uint256 allocPoint, 
        uint256 allocPointDR, 
        uint256 depositFee, 
        uint256 withdrawalFee, 
        bool offerILP, 
        bool issueStub,
        uint256 rewardEndTimestamp);
        
    event UpdateStartTimestamp(uint256 newStartTimestamp);

    constructor(
        DfyToken _defy,
        DefySTUB _stub,
        BurnVault _burnvault,
        address _devaddr,
        address _emDev,
        address _feeAddress,
        uint256 _startTimestamp,
        uint256 _initMint
    ) public {
        
        require(_devaddr != address(0), 'DEFY: dev cannot be the zero address');
        require(_feeAddress != address(0), 'DEFY: FeeAddress cannot be the zero address');
        require(_startTimestamp >= block.timestamp , 'DEFY: Invalid start time');
        
        defy = _defy;
        burn_vault = _burnvault;
        devaddr = _devaddr;
        emDev = _emDev;
        feeAddress = _feeAddress;
        startTimestamp = _startTimestamp;
        
        defyPerSec = (MAX_SUPPLY.sub(_initMint)).div(SECONDS_PER_CYCLE);
        nextCycleTimestamp = startTimestamp.add(SECONDS_PER_CYCLE);

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _defy,
            stubToken: _stub,
            allocPoint: 400,
            allocPointDR: 0,
            depositFee: 0,        
            withdrawalFee: 0,
            lastRewardTimestamp: startTimestamp,
            lastRewardTimestampDR: startTimestamp,
            rewardEndTimestamp: MAX_INT,
            accDefyPerShare: 0,
            accSecondRPerShare: 0,
            lpSupply: 0,
            impermanentLossProtection: false,
            issueStub: true
        }));

        totalAllocPoint = 400;

    }

    function setImpermanentLossProtection(address _ilp)public onlyDev returns (bool){        
        require(_ilp != address(0), 'DEFY: ILP cannot be the zero address');
        ilp = ImpermanentLossProtection(_ilp);
    }
    
    function setFeeAddress(address _feeAddress)public onlyDev returns (bool){        
        require(_feeAddress != address(0), 'DEFY: FeeAddress cannot be the zero address');
        feeAddress = _feeAddress;
        emit SetFeeAddress(_feeAddress);
        return true;
    }
    
    function setDFY(DfyToken _dfy)public onlyDev returns (bool){        
        require(_dfy != DfyToken(0), 'DEFY: DFY cannot be the zero address');
        defy = _dfy;
        emit SetDFY(address(_dfy));
        return true;
    }
    
    function setSecondaryReward(IERC20 _rewardToken)public onlyDev returns (bool){        
        require(_rewardToken != IERC20(0), 'DEFY: SecondaryReward cannot be the zero address');
        secondR = _rewardToken;
        emit SetSecondaryReward(address(_rewardToken));
        return true;
    }
    
    function getUserInfo(uint256 pid, address userAddr) 
		public 
		view 
		returns(uint256 deposit, uint256 rewardDebt, uint256 rewardDebtDR, uint256 daysSinceDeposit, uint256 depVal)
	{
		UserInfo storage user = userInfo[pid][userAddr];
		return (user.amount, user.rewardDebt, user.rewardDebtDR, _getDaysSinceDeposit(pid, userAddr), user.depVal);
	}
	
	//Time Functions
    function getDaysSinceDeposit(uint256 pid, address userAddr)
        external
        view
        returns (uint256 daysSinceDeposit)
    {
        return _getDaysSinceDeposit(pid, userAddr);
    }
    function _getDaysSinceDeposit(uint256 _pid, address _userAddr)
        internal
        view
        returns (uint256)
    {
		UserInfo storage user = userInfo[_pid][_userAddr];
		
        if (block.timestamp < user.depositTime){	
             return 0;	
        }else{	
             return (block.timestamp.sub(user.depositTime)) / 1 days;	
        }
    }
	
    function checkForIL(uint256 pid, address userAddr)
        external
        view
        returns (uint256 extraDefy)
    {
		UserInfo storage user = userInfo[pid][userAddr];
		return _checkForIL(pid, user);
    }
    function _checkForIL(uint256 _pid, UserInfo storage user)
        internal
        view
        returns (uint256)
    {
		uint256 defyPrice = ilp.getDefyPrice(_pid);
		uint256 currentVal = ilp.getDepositValue(user.amount, _pid);
		
		if(currentVal < user.depVal){
			uint256 difference = user.depVal.sub(currentVal);
			return difference.div(defyPrice);
		}else return 0;
    }
    
    function setStartTimestamp(uint256 sTimestamp) public onlyDev{
        require(sTimestamp > block.timestamp, "Invalid Timestamp");
        startTimestamp = sTimestamp;
        emit UpdateStartTimestamp(sTimestamp);
    }
    
    function updateMultiplier(uint256 multiplierNumber) public onlyDev {
        require(multiplierNumber != 0, " multiplierNumber should not be null");
        BONUS_MULTIPLIER = multiplierNumber;
    }
    
    function updateEmissionRate(uint256 endTimestamp) external  {
        require(endTimestamp > ((block.timestamp).add(182 days)), "Minimum duration is 6 months");
        require ( msg.sender == devaddr , "only dev!");
        massUpdatePools();
        SECONDS_PER_CYCLE = endTimestamp.sub(block.timestamp);
        defyPerSec = MAX_SUPPLY.sub(defy.totalSupply()).div(SECONDS_PER_CYCLE);
        nextCycleTimestamp = endTimestamp;
        
        emit UpdateEmissionRate(defyPerSec);
        
    }
    
    function updateReward() internal {
        uint256 burnAmount = defy.balanceOf(address(burn_vault));
        defyPerSec = burnAmount.div(SECONDS_PER_CYCLE);
        
        burn_vault.burn();
        
        emit UpdateEmissionRate(defyPerSec);
    }
    
    function updateSecondReward(uint256 _reward, uint256 _endTimestamp) public onlyOwner{
        
       require(_endTimestamp > block.timestamp , "invalid End timestamp");
       
        massUpdatePools();
        endTimestampDR = _endTimestamp;
        secondRPerSec = 0;
        massUpdatePools();
       
        secondRPerSec = _reward.div((_endTimestamp).sub(block.timestamp));
        
        emit UpdateSecondaryEmissionRate(secondRPerSec);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // XXX DO NOT set ILP for non DFY pairs. 
    function add(
    uint256 _allocPoint,
    uint256 _allocPointDR,
    IERC20 _lpToken,
    DefySTUB _stub,
    IERC20 _token0, 
    IERC20 _token1, 
    uint256 _depositFee,
    uint256 _withdrawalFee,
    bool _offerILP, 
    bool _issueSTUB,
    uint256 _rewardEndTimestamp
    
    ) public onlyDev {
        
        require(_depositFee <= 600, "Add : Max Deposit Fee is 6%");
        require(_withdrawalFee <= 600, "Add : Max Deposit Fee is 6%");
        require(_rewardEndTimestamp > block.timestamp , "Add: invalid rewardEndTimestamp");
        
        massUpdatePools();
        
        ilp.add(address(_lpToken), _token0, _token1, _offerILP);
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        totalAllocPointDR = totalAllocPointDR.add(_allocPointDR);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            stubToken: _stub,
            allocPoint: _allocPoint,
            allocPointDR: _allocPointDR,
            depositFee: _depositFee,        
            withdrawalFee: _withdrawalFee,
            lastRewardTimestamp: lastRewardTimestamp,
            lastRewardTimestampDR: lastRewardTimestamp,
            rewardEndTimestamp: _rewardEndTimestamp,
            accDefyPerShare: 0,
            accSecondRPerShare: 0,
            lpSupply: 0,
            impermanentLossProtection: _offerILP,
            issueStub: _issueSTUB
        }));
        
        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _allocPointDR, _depositFee, _withdrawalFee, _offerILP, _issueSTUB, _rewardEndTimestamp);

    }

    // Update the given pool's DFY allocation point. Can only be called by the owner.
    function set(
    uint256 _pid, 
    uint256 _allocPoint,
    uint256 _allocPointDR,
    IERC20 _token0, 
    IERC20 _token1, 
    uint256 _depositFee,
    uint256 _withdrawalFee,
    bool _offerILP, 
    bool _issueSTUB,
    uint256 _rewardEndTimestamp
    
    ) public onlyOwner {
        
        require(_depositFee <= 600, "Add : Max Deposit Fee is 6%");
        require(_withdrawalFee <= 600, "Add : Max Deposit Fee is 6%");
        require(_rewardEndTimestamp > block.timestamp , "Add: invalid rewardEndTimestamp");

        massUpdatePools();

        ilp.set(_pid, _token0, _token1, _offerILP);
        
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        totalAllocPointDR = totalAllocPointDR.sub(poolInfo[_pid].allocPointDR).add(_allocPointDR);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].allocPointDR = _allocPointDR;
        poolInfo[_pid].depositFee = _depositFee;
        poolInfo[_pid].withdrawalFee = _withdrawalFee;
        poolInfo[_pid].rewardEndTimestamp = _rewardEndTimestamp;
		poolInfo[_pid].impermanentLossProtection = _offerILP;
		poolInfo[_pid].issueStub = _issueSTUB;
		
        emit setPool(_pid , _allocPoint, _allocPointDR, _depositFee, _withdrawalFee, _offerILP, _issueSTUB, _rewardEndTimestamp);
    }


    // Return reward multiplier over the given _from to _to Timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending DFYs on frontend.
    function pendingDefy(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDefyPerShare = pool.accDefyPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.timestamp  > pool.lastRewardTimestamp && lpSupply != 0 && totalAllocPoint != 0) {
            
            uint256 blockTimestamp;
        
            if(block.timestamp  < nextCycleTimestamp){
                blockTimestamp = block.timestamp < pool.rewardEndTimestamp ? block.timestamp : pool.rewardEndTimestamp;
            }
            else{
                blockTimestamp = nextCycleTimestamp;
            }
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, blockTimestamp);
            uint256 defyReward = multiplier.mul(defyPerSec).mul(pool.allocPoint).div(totalAllocPoint);
            accDefyPerShare = accDefyPerShare.add(defyReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accDefyPerShare).div(1e12).sub(user.rewardDebt);
    }
    
    // View function to see pending Secondary Reward on frontend.
    function pendingSecondR(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSecondRPerShare = pool.accSecondRPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.timestamp  > pool.lastRewardTimestampDR && lpSupply != 0 && totalAllocPointDR != 0) {
            
            uint256 blockTimestamp;
        
            if(block.timestamp  < endTimestampDR){
                blockTimestamp = block.timestamp < pool.rewardEndTimestamp ? block.timestamp : pool.rewardEndTimestamp;
            }
            else{
                blockTimestamp = endTimestampDR;
            }
            uint256 multiplier = getMultiplier(pool.lastRewardTimestampDR, blockTimestamp);
            uint256 secondRReward = multiplier.mul(secondRPerSec).mul(pool.allocPointDR).div(totalAllocPointDR);
            accSecondRPerShare = accSecondRPerShare.add(secondRReward.mul(1e24).div(lpSupply));
        }
        return user.amount.mul(accSecondRPerShare).div(1e24).sub(user.rewardDebtDR);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
        if (block.timestamp > nextCycleTimestamp){
            nextCycleTimestamp = (block.timestamp).add(SECONDS_PER_CYCLE);
            defyPerSec = 0;
            
            for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
             }
            updateReward();
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePoolPb(uint256 _pid) public {
        if (block.timestamp > nextCycleTimestamp){
            massUpdatePools();
        }
        else {
            updatePool(_pid);
        }
    }
    
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp  <= pool.lastRewardTimestamp && block.timestamp  <= pool.lastRewardTimestampDR) {
            return;
        }
        
        uint256 lpSupply = pool.lpSupply;
        
        uint256 blockTimestamp;
        
            if(block.timestamp  < nextCycleTimestamp){
                blockTimestamp = block.timestamp < pool.rewardEndTimestamp ? block.timestamp : pool.rewardEndTimestamp;
            }
            else{
                blockTimestamp = nextCycleTimestamp;
            }
        
            
        uint256 blockTimestampDR;
        
            if(block.timestamp  < endTimestampDR){
                blockTimestampDR = block.timestamp < pool.rewardEndTimestamp ? block.timestamp : pool.rewardEndTimestamp;
            }
            else{
                blockTimestampDR = endTimestampDR;
            }
        
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = blockTimestamp;
            pool.lastRewardTimestampDR = blockTimestampDR;
            return;
        }
        
        if (pool.allocPoint == 0 && pool.allocPointDR == 0) {
            pool.lastRewardTimestamp = blockTimestamp;
            pool.lastRewardTimestampDR = blockTimestampDR;
            return;
        }

        uint256 defyReward = 0 ;
        uint256 secondRReward = 0 ;

        if(totalAllocPoint != 0){
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, blockTimestamp);
            defyReward = multiplier.mul(defyPerSec).mul(pool.allocPoint).div(totalAllocPoint);
        }
        if(totalAllocPointDR != 0){
            uint256 multiplier = getMultiplier(pool.lastRewardTimestampDR, blockTimestampDR);
            secondRReward = multiplier.mul(secondRPerSec).mul(pool.allocPointDR).div(totalAllocPointDR);
        }
        
        if(defyReward > 0 ){
            defy.mint(address(this), defyReward);
        }
        pool.accDefyPerShare = pool.accDefyPerShare.add(defyReward.mul(1e12).div(lpSupply));
        pool.accSecondRPerShare = pool.accSecondRPerShare.add(secondRReward.mul(1e24).div(lpSupply));
        
        pool.lastRewardTimestamp = blockTimestamp;
        pool.lastRewardTimestampDR = blockTimestampDR;
        
    }

    // Deposit LP tokens to DefyMaster for DFY allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePoolPb(_pid);
        
        uint256 amount_ = _amount;
        //If the LP token balance is lower than _amount,
        //total LP tokens in the wallet will be deposited 
		if(amount_ > pool.lpToken.balanceOf(msg.sender)){
			amount_ = pool.lpToken.balanceOf(msg.sender);
		}
		
		//check for ILP DFY
		uint256 extraDefy = 0;
		if(pool.impermanentLossProtection && user.amount > 0 && _getDaysSinceDeposit(_pid, msg.sender) >= 30){
					extraDefy = _checkForIL(_pid, user);	
		}
        
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accDefyPerShare).div(1e12).sub(user.rewardDebt);
            uint256 pendingDR = user.amount.mul(pool.accSecondRPerShare).div(1e24).sub(user.rewardDebtDR);
            if(pending > 0) {
                safeDefyTransfer(msg.sender, pending);
            }
            if(pendingDR > 0) {
                safeSecondRTransfer(msg.sender, pendingDR);
            }
            if(extraDefy > 0 && extraDefy > pending){
				ilp.defyTransfer(msg.sender, extraDefy.sub(pending));
            }
        }
        if (amount_ > 0) {
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), amount_);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            amount_ = _after.sub(before); // Real amount of LP transfer to this address
            
             if (pool.depositFee > 0) {
                uint256 depositFee = amount_.mul(pool.depositFee).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                if (pool.issueStub){
                pool.stubToken.mint(msg.sender, amount_.sub(depositFee));
                }
                user.amount = user.amount.add(amount_).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(amount_).sub(depositFee);
            } else {
                user.amount = user.amount.add(amount_);
                pool.lpSupply = pool.lpSupply.add(amount_);
                
                if (pool.issueStub){
                pool.stubToken.mint(msg.sender, amount_);
                }
            }
            
        }
        user.depVal = ilp.getDepositValue(user.amount, _pid);
		user.depositTime = block.timestamp;
        user.rewardDebt = user.amount.mul(pool.accDefyPerShare).div(1e12);
        user.rewardDebtDR = user.amount.mul(pool.accSecondRPerShare).div(1e24);
        emit Deposit(msg.sender, _pid, amount_);
    }

    // Withdraw LP tokens from DefyMaster.
    function withdraw(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0 , "withdraw: nothing to withdraw");
        updatePoolPb(_pid);
        
        uint256 amount_ = _amount;
        //If the User LP token balance in farm is lower than _amount,
        //total User LP tokens in the farm will be withdrawn 
		if(amount_ > user.amount){
			amount_ = user.amount;
		}
		
		
		//ILP
		uint256 extraDefy = 0;
		if(pool.impermanentLossProtection && user.amount > 0 && _getDaysSinceDeposit(_pid, msg.sender) >= 30){
		    extraDefy = _checkForIL(_pid, user);	
		}
        
        uint256 pending = user.amount.mul(pool.accDefyPerShare).div(1e12).sub(user.rewardDebt);
        uint256 pendingDR = user.amount.mul(pool.accSecondRPerShare).div(1e24).sub(user.rewardDebtDR);
        
        if(pending > 0) {
            safeDefyTransfer(msg.sender, pending);
        }
        if(pendingDR > 0) {
            safeSecondRTransfer(msg.sender, pendingDR);
        }
        if(extraDefy > 0 && extraDefy > pending){
			ilp.defyTransfer(msg.sender, extraDefy.sub(pending));
        }

        if(amount_ > 0) {
            if (pool.issueStub){
                require(pool.stubToken.balanceOf(msg.sender) >= amount_ , "withdraw : No enough STUB tokens!");
                pool.stubToken.burn(msg.sender, amount_);
            }
            if (pool.withdrawalFee > 0) {
                uint256 withdrawalFee = amount_.mul(pool.withdrawalFee).div(10000);
                pool.lpToken.safeTransfer(feeAddress, withdrawalFee);
                pool.lpToken.safeTransfer(address(msg.sender), amount_.sub(withdrawalFee));
            } else {
                pool.lpToken.safeTransfer(address(msg.sender), amount_);
            }
            user.amount = user.amount.sub(amount_);
            pool.lpSupply = pool.lpSupply.sub(amount_);
        }
        user.depVal = ilp.getDepositValue(user.amount, _pid);
		user.depositTime = block.timestamp;
        user.rewardDebt = user.amount.mul(pool.accDefyPerShare).div(1e12);
        user.rewardDebtDR = user.amount.mul(pool.accSecondRPerShare).div(1e24);
        
        emit Withdraw(msg.sender, _pid, amount_);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        pool.lpSupply = pool.lpSupply.sub(user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardDebtDR = 0;
    }

    // Safe defy transfer function, just in case if rounding error causes pool to not have enough DFYs.
    function safeDefyTransfer(address _to, uint256 _amount) internal {
        uint256 defyBal = defy.balanceOf(address(this));
        bool successfulTansfer = false;
        if (_amount > defyBal) {
            successfulTansfer = defy.transfer(_to, defyBal);
        } else {
            successfulTansfer = defy.transfer(_to, _amount);
        }
        require(successfulTansfer, "safeDefyTransfer: transfer failed");
    }
    
    // Safe SecondR transfer function, just in case if rounding error causes pool to not have enough Secondary reward tokens.
    function safeSecondRTransfer(address _to, uint256 _amount) internal {
        uint256 secondRBal = secondR.balanceOf(address(this));
        bool successfulTansfer = false;
        if (_amount > secondRBal) {
            successfulTansfer = secondR.transfer(_to, secondRBal);
        } else {
            successfulTansfer = secondR.transfer(_to, _amount);
        }
        require(successfulTansfer, "safeSecondRTransfer: transfer failed");
    }

    // only in an Emergency by emDev
    function transferOwnerDfy(address _newOwner) external {
        require (msg.sender == emDev , "only emergency dev");
        defy.transferOwnership(_newOwner);
        emit DFYOwnershipTransfer(_newOwner);
    }

    function renounceEmDev() external {
        require (msg.sender == emDev , "only emergency dev");
        emDev = address(0);
        emit RenounceEmDev();
    }


    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(_devaddr != address(0), 'DEFY: dev cannot be the zero address');
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}