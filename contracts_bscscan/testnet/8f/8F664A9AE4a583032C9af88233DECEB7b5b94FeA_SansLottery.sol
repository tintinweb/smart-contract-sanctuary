/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// File: @sansfinance\sans-lib\contracts\math\SafeMath.sol

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

// File: node_modules\@sansfinance\sans-lib\contracts\GSN\Context.sol

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

// File: @sansfinance\sans-lib\contracts\access\Ownable.sol

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

// File: node_modules\@sansfinance\sans-lib\contracts\token\BEP20\IBEP20.sol

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

// File: node_modules\@sansfinance\sans-lib\contracts\utils\Address.sol

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

// File: @sansfinance\sans-lib\contracts\token\BEP20\BEP20.sol

pragma solidity >=0.4.0;






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
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _totalSupply = totalSupply;

        _balances[msg.sender] = _totalSupply;
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

// File: contracts\interfaces\IRandomNumberGenerator.sol

pragma solidity 0.6.12;

interface IRandomNumberGenerator {
    function requestRandomNumber() external returns (bytes32 requestId);

    function isRequestCompleted() external view returns (bool);

    function getRandomNumber() external view returns (uint256);
}

// File: contracts\SansLottery.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;





contract SansLottery is Ownable {
    using SafeMath for uint256;

    struct Ticket {
        uint256 id;
        uint256 price;
        address owner;
        uint256 buyTime;
        uint256 indexInLottery;
        uint256 indexInUser;
    }

    struct Result {
        uint256 startTime;
        uint256 completeTime;
        uint256 totalAward;
        uint256 awardPerWinner;
        address[] winners;
    }

    mapping(uint256 => Ticket) public ticketMap;

    uint256[] public ticketIdList;

    mapping(address => uint256[]) public userTicketIdMap;

    Result[] public resultList;

    uint256 public ticketIdCounter;

    address public sansTokenAddress;

    uint256 public duration;

    uint256 public startTime;

    uint256 public ticketPrice;

    uint256 public minimumAward;

    uint256 public depositPercentage;

    bool public active;

    address internal rngAddress;

    uint256 public maxTicketCountPerBuy;

    uint256 public totalAwardedAmount;

    uint256 internal defaultDuration;

    bool internal lotteryInProgress;

    bool internal awardingInProgress;

    event Deposit(address indexed user, uint256 amount);
    event BuyTicket(address indexed user, uint256 ticketId, uint256 price);
    event ReturnTicket(address indexed user, uint256 ticketId, uint256 price);
    event StartLottery();
    event StartAward();
    event AwardUser(uint256 indexed resultId, address indexed user, uint256 ticketId, uint256 award);
    event CompleteAward(
        uint256 indexed resultId,
        uint256 startTime,
        uint256 completeTime,
        uint256 totalAward,
        uint256 awardPerWinner,
        uint256 ticketCount,
        uint256 winnerCount
    );

    constructor(
        address _sansTokenAddress,
        uint256 _duration,
        uint256 _ticketPrice,
        uint256 _minimumAward,
        uint256 _depositPercentage,
        address _rngAddress,
        uint256 _maxTicketCountPerBuy
    ) public {
        sansTokenAddress = _sansTokenAddress;
        duration = _duration;
        defaultDuration = _duration;
        ticketPrice = _ticketPrice;
        minimumAward = _minimumAward;
        depositPercentage = _depositPercentage;
        rngAddress = _rngAddress;
        maxTicketCountPerBuy = _maxTicketCountPerBuy;
        active = true;
    }

    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function buyTicket(uint256 _amount) external {
        require(_amount > 0, 'Lottery: Amount must be greater than 0');
        require(_amount <= maxTicketCountPerBuy, 'Lottery: Amount must be less than or equal to maxTicketCountPerBuy');
        require(active, 'Lottery: Not active');

        uint256 totalPrice = ticketPrice * _amount;

        require(
            BEP20(sansTokenAddress).transferFrom(address(msg.sender), address(this), totalPrice),
            'Lottery: Cannot transfer price'
        );

        for (uint256 i = 0; i < _amount; i++) {
            ticketIdCounter += 1;

            Ticket memory ticket = Ticket(
                ticketIdCounter,
                ticketPrice,
                msg.sender,
                block.timestamp,
                ticketIdList.length,
                userTicketIdMap[msg.sender].length
            );

            ticketMap[ticketIdCounter] = ticket;

            ticketIdList.push(ticketIdCounter);

            userTicketIdMap[msg.sender].push(ticketIdCounter);

            emit BuyTicket(msg.sender, ticketIdCounter, ticketPrice);
        }
    }

    function returnTicket(uint256[] calldata _ticketIdList) external {
        require(_ticketIdList.length > 0, 'Lottery: Ticket list is empty');
        require(
            _ticketIdList.length <= maxTicketCountPerBuy,
            'Lottery: Ticket list length must be less than or equal to maxTicketCountPerBuy'
        );

        for (uint256 i = 0; i < _ticketIdList.length; i++) {
            Ticket storage ticket = ticketMap[_ticketIdList[i]];
            uint256 returnTicketId = ticket.id;

            require(returnTicketId > 0, 'Lottery: Ticket cannot be found');
            require(ticket.owner == msg.sender, "Lottery: Ticket doesn't belong to the sender");
            require(
                BEP20(sansTokenAddress).transfer(address(msg.sender), ticket.price),
                'Lottery: Refund unsuccessful'
            );

            // Replace user ticket with the last user ticket
            uint256[] storage userTicketIdList = userTicketIdMap[msg.sender];
            if (ticket.indexInUser != userTicketIdList.length - 1) {
                Ticket storage replacedUserTicket = ticketMap[userTicketIdList[userTicketIdList.length - 1]];
                replacedUserTicket.indexInUser = ticket.indexInUser;
            }
            userTicketIdList[ticket.indexInUser] = userTicketIdList[userTicketIdList.length - 1];
            userTicketIdList.pop();

            // Replace lottery ticket with the last lottery ticket
            if (ticket.indexInLottery != ticketIdList.length - 1) {
                Ticket storage replacedLotteryTicket = ticketMap[ticketIdList[ticketIdList.length - 1]];
                replacedLotteryTicket.indexInLottery = ticket.indexInLottery;
            }
            ticketIdList[ticket.indexInLottery] = ticketIdList[ticketIdList.length - 1];
            ticketIdList.pop();

            delete ticketMap[returnTicketId];

            emit ReturnTicket(msg.sender, returnTicketId, ticketPrice);
        }
    }

    function startNewLottery() external onlyOwner {
        require(!lotteryInProgress, 'Lottery: Already in progress');
        require(!awardingInProgress, 'Lottery: Awarding in progress');

        startTime = block.timestamp;
        lotteryInProgress = true;
        awardingInProgress = false;
        duration = defaultDuration;

        emit StartLottery();
    }

    function startAward() external onlyOwner {
        require(block.timestamp >= startTime + duration, "Lottery: Duration hasn't completed yet");
        require(address(this).balance > 0, 'Lottery: Insufficent balance for award');
        require(!awardingInProgress, 'Lottery: Awarding in progress');

        IRandomNumberGenerator(rngAddress).requestRandomNumber();

        awardingInProgress = true;
        lotteryInProgress = false;

        emit StartAward();
    }

    function completeAward() external onlyOwner {
        require(block.timestamp >= startTime + duration, "Lottery: Duration hasn't completed yet");
        require(awardingInProgress, 'Lottery: Start awarding first');
        require(
            IRandomNumberGenerator(rngAddress).isRequestCompleted(),
            "Lottery: Random number request hasn't completed yet."
        );

        uint256 completeTime = block.timestamp;
        uint256 resultId = resultList.length + 1;

        if (ticketIdList.length == 0) {
            Result memory result = Result(startTime, completeTime, 0, 0, new address[](0));

            resultList.push(result);

            awardingInProgress = false;

            emit CompleteAward(resultId, startTime, completeTime, 0, 0, 0, 0);

            return;
        }

        uint256 randomNumber = IRandomNumberGenerator(rngAddress).getRandomNumber();
        uint256 awardPerWinner = minimumAward;
        uint256 winnerCount = 1;
        uint256 totalAward = address(this).balance;

        if (totalAward > minimumAward) {
            winnerCount = totalAward.div(minimumAward);

            if (winnerCount > ticketIdList.length) {
                winnerCount = ticketIdList.length;
            }

            if (winnerCount > 1) {
                awardPerWinner = totalAward.div(winnerCount);
            }
        } else {
            awardPerWinner = totalAward;
        }

        uint256 partitionLength = 1;
        uint256 remainder = 0;

        if (ticketIdList.length > winnerCount) {
            partitionLength = ticketIdList.length.div(winnerCount);
            remainder = ticketIdList.length.mod(winnerCount);
        }

        uint256 lastPartitionLength = partitionLength;

        if (remainder > 0) {
            lastPartitionLength = remainder;
        }

        address[] memory winners = new address[](winnerCount);

        for (uint256 i = 0; i < winnerCount; i++) {
            uint256 winnerIndex = i;

            if (ticketIdList.length > winnerCount) {
                uint256 nextRandom = uint256(keccak256(abi.encode(randomNumber, i)));
                uint256 winnerStartIndex = i.mul(partitionLength);

                if (i == winnerCount - 1) {
                    partitionLength = lastPartitionLength;
                }

                winnerIndex = winnerStartIndex.add(nextRandom.mod(partitionLength));
            }

            Ticket memory winnerTicket = ticketMap[ticketIdList[winnerIndex]];

            payable(winnerTicket.owner).transfer(awardPerWinner);

            winners[i] = winnerTicket.owner;

            emit AwardUser(resultId, winnerTicket.owner, winnerTicket.id, awardPerWinner);
        }

        Result memory result = Result(startTime, completeTime, totalAward, awardPerWinner, winners);

        resultList.push(result);

        awardingInProgress = false;

        totalAwardedAmount += totalAward;

        emit CompleteAward(
            resultId,
            startTime,
            completeTime,
            totalAward,
            awardPerWinner,
            ticketIdList.length,
            winners.length
        );
    }

    function getTicketCount() external view returns (uint256) {
        return ticketIdList.length;
    }

    function getUserTicketCount(address _user) external view returns (uint256) {
        return userTicketIdMap[_user].length;
    }

    function getUserTicketsPaged(
        address _user,
        uint256 _from,
        uint256 _to
    ) external view returns (Ticket[] memory) {
        uint256[] memory userTicketIdList = userTicketIdMap[_user];

        if (_to <= _from || _from >= userTicketIdList.length) {
            return new Ticket[](0);
        }

        if (_to > userTicketIdList.length) {
            _to = userTicketIdList.length;
        }

        uint256 listSize = _to.sub(_from);

        Ticket[] memory userTicketList = new Ticket[](listSize);

        for (uint256 i = 0; i < listSize; i++) {
            userTicketList[i] = ticketMap[userTicketIdList[_from.add(i)]];
        }

        return userTicketList;
    }

    function getUserTickets(address _user) external view returns (Ticket[] memory) {
        uint256[] memory userTicketIdList = userTicketIdMap[_user];
        Ticket[] memory userTicketList = new Ticket[](userTicketIdList.length);

        for (uint256 i = 0; i < userTicketIdList.length; i++) {
            userTicketList[i] = ticketMap[userTicketIdList[i]];
        }

        return userTicketList;
    }

    function getResultCount() external view returns (uint256) {
        return resultList.length;
    }

    function getResult(uint256 _index) external view returns (Result memory) {
        return resultList[_index];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, 'Lottery: Duration must be greater than 0');

        duration = _duration;
    }

    function setTicketPrice(uint256 _ticketPrice) external onlyOwner {
        require(_ticketPrice > 0, 'Lottery: Ticket price must be greater than 0');

        ticketPrice = _ticketPrice;
    }

    function setMinimumAward(uint256 _minimumAward) external onlyOwner {
        require(_minimumAward > 0, 'Lottery: Minimum award must be greater than 0');

        minimumAward = _minimumAward;
    }

    function setDepositPercentage(uint256 _depositPercentage) external onlyOwner {
        require(_depositPercentage > 0, 'Lottery: Deposit percentage must be greater than 0');

        depositPercentage = _depositPercentage;
    }

    function setRngAddress(address _rngAddress) external onlyOwner {
        require(_rngAddress != address(0), 'Lottery: Address must be different from 0');

        rngAddress = _rngAddress;
    }

    function setActive(bool _active) external onlyOwner {
        active = _active;
    }

    function setMaxTicketCountPerBuy(uint256 _maxTicketCountPerBuy) external onlyOwner {
        require(_maxTicketCountPerBuy > 0, 'Lottery: Ticket count must be greater than 0');

        maxTicketCountPerBuy = _maxTicketCountPerBuy;
    }
}