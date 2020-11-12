// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
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

// File: contracts/uniswapv2/interfaces/IUniswapV2Factory.sol

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// File: @openzeppelin/contracts/utils/Address.sol

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name, string memory symbol) public {
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/strategies/IStrategy.sol

// Assume the strategy generates `TOKEN`.
interface IStrategy {

    function approve(IERC20 _token) external;

    function getValuePerShare(address _vault) external view returns(uint256);
    function pendingValuePerShare(address _vault) external view returns (uint256);

    // Deposit tokens to a farm to yield more tokens.
    function deposit(address _vault, uint256 _amount) external;

    // Claim the profit from a farm.
    function claim(address _vault) external;

    // Withdraw the principal from a farm.
    function withdraw(address _vault, uint256 _amount) external;

    // Target farming token of this strategy.
    function getTargetToken() external view returns(address);
}

// File: contracts/SodaMaster.sol

/*

Here we have a list of constants. In order to get access to an address
managed by SodaMaster, the calling contract should copy and define
some of these constants and use them as keys.

Keys themselves are immutable. Addresses can be immutable or mutable.

a) Vault addresses are immutable once set, and the list may grow:

K_VAULT_WETH = 0;
K_VAULT_USDT_ETH_SUSHI_LP = 1;
K_VAULT_SOETH_ETH_UNI_V2_LP = 2;
K_VAULT_SODA_ETH_UNI_V2_LP = 3;
K_VAULT_GT = 4;
K_VAULT_GT_ETH_UNI_V2_LP = 5;


b) SodaMade token addresses are immutable once set, and the list may grow:

K_MADE_SOETH = 0;


c) Strategy addresses are mutable:

K_STRATEGY_CREATE_SODA = 0;
K_STRATEGY_EAT_SUSHI = 1;
K_STRATEGY_SHARE_REVENUE = 2;


d) Calculator addresses are mutable:

K_CALCULATOR_WETH = 0;

Solidity doesn't allow me to define global constants, so please
always make sure the key name and key value are copied as the same
in different contracts.

*/


// SodaMaster manages the addresses all the other contracts of the system.
// This contract is owned by Timelock.
contract SodaMaster is Ownable {

    address public pool;
    address public bank;
    address public revenue;
    address public dev;

    address public soda;
    address public wETH;
    address public usdt;

    address public uniswapV2Factory;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isSodaMade;
    mapping(uint256 => address) public sodaMadeByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;

    mapping(address => bool) public isCalculator;
    mapping(uint256 => address) public calculatorByKey;

    // Immutable once set.
    function setPool(address _pool) external onlyOwner {
        require(pool == address(0));
        pool = _pool;
    }

    // Immutable once set.
    // Bank owns all the SodaMade tokens.
    function setBank(address _bank) external onlyOwner {
        require(bank == address(0));
        bank = _bank;
    }

    // Mutable in case we want to upgrade this module.
    function setRevenue(address _revenue) external onlyOwner {
        revenue = _revenue;
    }

    // Mutable in case we want to upgrade this module.
    function setDev(address _dev) external onlyOwner {
        dev = _dev;
    }

    // Mutable, in case Uniswap has changed or we want to switch to sushi.
    // The core systems, Pool and Bank, don't rely on Uniswap, so there is no risk.
    function setUniswapV2Factory(address _uniswapV2Factory) external onlyOwner {
        uniswapV2Factory = _uniswapV2Factory;
    }

    // Immutable once set.
    function setWETH(address _wETH) external onlyOwner {
       require(wETH == address(0));
       wETH = _wETH;
    }

    // Immutable once set. Hopefully Tether is reliable.
    // Even if it fails, not a big deal, we only used USDT to estimate APY.
    function setUSDT(address _usdt) external onlyOwner {
        require(usdt == address(0));
        usdt = _usdt;
    }
 
    // Immutable once set.
    function setSoda(address _soda) external onlyOwner {
        require(soda == address(0));
        soda = _soda;
    }

    // Immutable once added, and you can always add more.
    function addVault(uint256 _key, address _vault) external onlyOwner {
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }

    // Immutable once added, and you can always add more.
    function addSodaMade(uint256 _key, address _sodaMade) external onlyOwner {
        require(sodaMadeByKey[_key] == address(0), "sodaMade: key is taken");

        isSodaMade[_sodaMade] = true;
        sodaMadeByKey[_key] = _sodaMade;
    }

    // Mutable and removable.
    function addStrategy(uint256 _key, address _strategy) external onlyOwner {
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    function removeStrategy(uint256 _key) external onlyOwner {
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }

    // Mutable and removable.
    function addCalculator(uint256 _key, address _calculator) external onlyOwner {
        isCalculator[_calculator] = true;
        calculatorByKey[_key] = _calculator;
    }

    function removeCalculator(uint256 _key) external onlyOwner {
        isCalculator[calculatorByKey[_key]] = false;
        delete calculatorByKey[_key];
    }
}

// File: contracts/tokens/SodaVault.sol

// SodaVault is owned by Timelock
contract SodaVault is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 constant PER_SHARE_SIZE = 1e12;

    mapping (address => uint256) public lockedAmount;
    mapping (address => mapping(uint256 => uint256)) public rewards;
    mapping (address => mapping(uint256 => uint256)) public debts;

    IStrategy[] public strategies;

    SodaMaster public sodaMaster;

    constructor (SodaMaster _sodaMaster, string memory _name, string memory _symbol) ERC20(_name, _symbol) public  {
        sodaMaster = _sodaMaster;
    }

    function setStrategies(IStrategy[] memory _strategies) public onlyOwner {
        delete strategies;
        for (uint256 i = 0; i < _strategies.length; ++i) {
            strategies.push(_strategies[i]);
        }
    }

    function getStrategyCount() view public returns(uint count) {
        return strategies.length;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by SodaPool.
    function mintByPool(address _to, uint256 _amount) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        _deposit(_amount);
        _updateReward(_to);
        if (_amount > 0) {
            _mint(_to, _amount);
        }
        _updateDebt(_to);
    }

    // Must only be called by SodaPool.
    function burnByPool(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        uint256 balance = balanceOf(_account);
        require(lockedAmount[_account] + _amount <= balance, "Vault: burn too much");

        _withdraw(_amount);
        _updateReward(_account);
        _burn(_account, _amount);
        _updateDebt(_account);
    }

    // Must only be called by SodaBank.
    function transferByBank(address _from, address _to, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        uint256 balance = balanceOf(_from);
        require(lockedAmount[_from] + _amount <= balance);

        _claim();
        _updateReward(_from);
        _updateReward(_to);
        _transfer(_from, _to, _amount);
        _updateDebt(_to);
        _updateDebt(_from);
    }

    // Any user can transfer to another user.
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        uint256 balance = balanceOf(_msgSender());
        require(lockedAmount[_msgSender()] + _amount <= balance, "transfer: <= balance");

        _updateReward(_msgSender());
        _updateReward(_to);
        _transfer(_msgSender(), _to, _amount);
        _updateDebt(_to);
        _updateDebt(_msgSender());

        return true;
    }

    // Must only be called by SodaBank.
    function lockByBank(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        uint256 balance = balanceOf(_account);
        require(lockedAmount[_account] + _amount <= balance, "Vault: lock too much");
        lockedAmount[_account] += _amount;
    }

    // Must only be called by SodaBank.
    function unlockByBank(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        require(_amount <= lockedAmount[_account], "Vault: unlock too much");
        lockedAmount[_account] -= _amount;
    }

    // Must only be called by SodaPool.
    function clearRewardByPool(address _who) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        for (uint256 i = 0; i < strategies.length; ++i) {
            rewards[_who][i] = 0;
        }
    }

    function getPendingReward(address _who, uint256 _index) public view returns (uint256) {
        uint256 total = totalSupply();
        if (total == 0 || _index >= strategies.length) {
            return 0;
        }

        uint256 value = strategies[_index].getValuePerShare(address(this));
        uint256 pending = strategies[_index].pendingValuePerShare(address(this));
        uint256 balance = balanceOf(_who);

        return balance.mul(value.add(pending)).div(PER_SHARE_SIZE).sub(debts[_who][_index]);
    }

    function _deposit(uint256 _amount) internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].deposit(address(this), _amount);
        }
    }

    function _withdraw(uint256 _amount) internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].withdraw(address(this), _amount);
        }
    }

    function _claim() internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].claim(address(this));
        }
    }

    function _updateReward(address _who) internal {
        uint256 balance = balanceOf(_who);
        if (balance > 0) {
            for (uint256 i = 0; i < strategies.length; ++i) {
                uint256 value = strategies[i].getValuePerShare(address(this));
                rewards[_who][i] = rewards[_who][i].add(balance.mul(
                    value).div(PER_SHARE_SIZE).sub(debts[_who][i]));
            }
        }
    }

    function _updateDebt(address _who) internal {
        uint256 balance = balanceOf(_who);
        for (uint256 i = 0; i < strategies.length; ++i) {
            uint256 value = strategies[i].getValuePerShare(address(this));
            debts[_who][i] = balance.mul(value).div(PER_SHARE_SIZE);
        }
    }
}

// File: contracts/calculators/ICalculator.sol

// `TOKEN` can be any ERC20 token. The first one is WETH.
abstract contract ICalculator {

    function rate() external view virtual returns(uint256);
    function minimumLTV() external view virtual returns(uint256);
    function maximumLTV() external view virtual returns(uint256);

    // Get next loan Id.
    function getNextLoanId() external view virtual returns(uint256);

    // Get loan creator address.
    function getLoanCreator(uint256 _loanId) external view virtual returns (address);

    // Get the locked `TOKEN` amount by the loan.
    function getLoanLockedAmount(uint256 _loanId) external view virtual returns (uint256);

    // Get the time by the loan.
    function getLoanTime(uint256 _loanId) external view virtual returns (uint256);

    // Get the rate by the loan.
    function getLoanRate(uint256 _loanId) external view virtual returns (uint256);

    // Get the minimumLTV by the loan.
    function getLoanMinimumLTV(uint256 _loanId) external view virtual returns (uint256);

    // Get the maximumLTV by the loan.
    function getLoanMaximumLTV(uint256 _loanId) external view virtual returns (uint256);

    // Get the SoMade amount of the loan principal.
    function getLoanPrincipal(uint256 _loanId) external view virtual returns (uint256);

    // Get the SoMade amount of the loan interest.
    function getLoanInterest(uint256 _loanId) external view virtual returns (uint256);

    // Get the SoMade amount that the user needs to pay back in full.
    function getLoanTotal(uint256 _loanId) external view virtual returns (uint256);

    // Get the extra fee for collection in SoMade.
    function getLoanExtra(uint256 _loanId) external view virtual returns (uint256);

    // Lend SoMade to create a new loan.
    //
    // Only SodaPool can call this contract, and SodaPool should make sure the
    // user has enough `TOKEN` deposited.
    function borrow(address _who, uint256 _amount) external virtual;

    // Pay back to a loan fully.
    //
    // Only SodaPool can call this contract.
    function payBackInFull(uint256 _loanId) external virtual;

    // Collect debt if someone defaults.
    //
    // Only SodaPool can call this contract, and SodaPool should send `TOKEN` to
    // the debt collector.
    function collectDebt(uint256 _loanId) external virtual;
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/components/SodaPool.sol

// This contract is owned by Timelock.
contract SodaPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;           // Address of token contract.
        SodaVault vault;           // Address of vault contract.
        uint256 startTime;
    }

    // Info of each pool.
    mapping (uint256 => PoolInfo) public poolMap;  // By poolId

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event Claim(address indexed user, uint256 indexed poolId);

    constructor() public {
    }

    function setPoolInfo(uint256 _poolId, IERC20 _token, SodaVault _vault, uint256 _startTime) public onlyOwner {
        poolMap[_poolId].token = _token;
        poolMap[_poolId].vault = _vault;
        poolMap[_poolId].startTime = _startTime;
    }

    function _handleDeposit(SodaVault _vault, IERC20 _token, uint256 _amount) internal {
        uint256 count = _vault.getStrategyCount();
        require(count == 1 || count == 2, "_handleDeposit: count");

        // NOTE: strategy0 is always the main strategy.
        address strategy0 = address(_vault.strategies(0));
        _token.safeTransferFrom(address(msg.sender), strategy0, _amount);
    }

    function _handleWithdraw(SodaVault _vault, IERC20 _token, uint256 _amount) internal {
        uint256 count = _vault.getStrategyCount();
        require(count == 1 || count == 2, "_handleWithdraw: count");

        address strategy0 = address(_vault.strategies(0));
        _token.safeTransferFrom(strategy0, address(msg.sender), _amount);
    }

    function _handleRewards(SodaVault _vault) internal {
        uint256 count = _vault.getStrategyCount();

        for (uint256 i = 0; i < count; ++i) {
            uint256 rewardPending = _vault.rewards(msg.sender, i);
            if (rewardPending > 0) {
                IERC20(_vault.strategies(i).getTargetToken()).safeTransferFrom(
                    address(_vault.strategies(i)), msg.sender, rewardPending);
            }
        }

        _vault.clearRewardByPool(msg.sender);
    }

    // Deposit tokens to SodaPool for SODA allocation.
    // If we have a strategy, then tokens will be moved there.
    function deposit(uint256 _poolId, uint256 _amount) public {
        PoolInfo storage pool = poolMap[_poolId];
        require(now >= pool.startTime, "deposit: after startTime");

        _handleDeposit(pool.vault, pool.token, _amount);
        pool.vault.mintByPool(msg.sender, _amount);

        emit Deposit(msg.sender, _poolId, _amount);
    }

    // Claim SODA (and potentially other tokens depends on strategy).
    function claim(uint256 _poolId) public {
        PoolInfo storage pool = poolMap[_poolId];
        require(now >= pool.startTime, "claim: after startTime");

        pool.vault.mintByPool(msg.sender, 0);
        _handleRewards(pool.vault);

        emit Claim(msg.sender, _poolId);
    }

    // Withdraw tokens from SodaPool (from a strategy first if there is one).
    function withdraw(uint256 _poolId, uint256 _amount) public {
        PoolInfo storage pool = poolMap[_poolId];
        require(now >= pool.startTime, "withdraw: after startTime");

        pool.vault.burnByPool(msg.sender, _amount);

        _handleWithdraw(pool.vault, pool.token, _amount);
        _handleRewards(pool.vault);

        emit Withdraw(msg.sender, _poolId, _amount);
    }
}

// File: contracts/tokens/SodaMade.sol

// All SodaMade tokens should be owned by SodaBank.
contract SodaMade is ERC20, Ownable {

    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) public  {
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (SodaBank).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /// @notice Burns `_amount` token in `account`. Must only be called by the owner (SodaBank).
    function burnFrom(address account, uint256 amount) public onlyOwner {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// File: contracts/components/SodaBank.sol


// SodaBank produces SoETH (and other SodaMade assets) by locking user's vault assets.
// This contract is owned by Timelock.
contract SodaBank is Ownable {
    using SafeMath for uint256;

    // Info of each pool.
    struct PoolInfo {
        SodaMade made;
        SodaVault vault;           // Address of vault contract.
        ICalculator calculator;
    }

    // PoolInfo by poolId.
    mapping(uint256 => PoolInfo) public poolMap;

    // Info of each loan.
    struct LoanInfo {
        uint256 poolId;  // Corresponding asset of the loan.
        uint256 loanId;  // LoanId of the loan.
    }

    // Loans of each user.
    mapping (address => LoanInfo[]) public loanList;

    SodaMaster public sodaMaster;

    event Borrow(address indexed user, uint256 indexed index, uint256 indexed poolId, uint256 amount);
    event PayBackInFull(address indexed user, uint256 indexed index);
    event CollectDebt(address indexed user, uint256 indexed poolId, uint256 loanId);

    constructor(
        SodaMaster _sodaMaster
    ) public {
        sodaMaster = _sodaMaster;
    }

    // Set pool info.
    function setPoolInfo(uint256 _poolId, SodaMade _made, SodaVault _vault, ICalculator _calculator) public onlyOwner {
        poolMap[_poolId].made = _made;
        poolMap[_poolId].vault = _vault;
        poolMap[_poolId].calculator = _calculator;
    }

    // Return length of address loan
    function getLoanListLength(address _who) external view returns (uint256) {
        return loanList[_who].length;
    }

    // Lend SoETH to create a new loan by locking vault.
    function borrow(uint256 _poodId, uint256 _amount) external {
        PoolInfo storage pool = poolMap[_poodId];
        require(address(pool.calculator) != address(0), "no calculator");

        uint256 loanId = pool.calculator.getNextLoanId();
        pool.calculator.borrow(msg.sender, _amount);
        uint256 lockedAmount = pool.calculator.getLoanLockedAmount(loanId);
        // Locks in vault.
        pool.vault.lockByBank(msg.sender, lockedAmount);

        // Give user SoETH or other SodaMade tokens.
        pool.made.mint(msg.sender, _amount);

        // Records the loan.
        LoanInfo memory loanInfo;
        loanInfo.poolId = _poodId;
        loanInfo.loanId = loanId;
        loanList[msg.sender].push(loanInfo);

        emit Borrow(msg.sender, loanList[msg.sender].length - 1, _poodId, _amount);
    }

    // Pay back to a loan fully.
    function payBackInFull(uint256 _index) external {
        require(_index < loanList[msg.sender].length, "getTotalLoan: index out of range");
        PoolInfo storage pool = poolMap[loanList[msg.sender][_index].poolId];
        require(address(pool.calculator) != address(0), "no calculator");

        uint256 loanId = loanList[msg.sender][_index].loanId;
        uint256 lockedAmount = pool.calculator.getLoanLockedAmount(loanId);
        uint256 principal = pool.calculator.getLoanPrincipal(loanId);
        uint256 interest = pool.calculator.getLoanInterest(loanId);
        // Burn principal.
        pool.made.burnFrom(msg.sender, principal);
        // Transfer interest to sodaRevenue.
        pool.made.transferFrom(msg.sender, sodaMaster.revenue(), interest);
        pool.calculator.payBackInFull(loanId);
        // Unlocks in vault.
        pool.vault.unlockByBank(msg.sender, lockedAmount);

        emit PayBackInFull(msg.sender, _index);
    }

    // Collect debt if someone defaults. Collector keeps half of the profit.
    function collectDebt(uint256 _poolId, uint256 _loanId) external {
        PoolInfo storage pool = poolMap[_poolId];
        require(address(pool.calculator) != address(0), "no calculator");

        address loanCreator = pool.calculator.getLoanCreator(_loanId);
        uint256 principal = pool.calculator.getLoanPrincipal(_loanId);
        uint256 interest = pool.calculator.getLoanInterest(_loanId);
        uint256 extra = pool.calculator.getLoanExtra(_loanId);
        uint256 lockedAmount = pool.calculator.getLoanLockedAmount(_loanId);

        // Pay principal + interest + extra.
        // Burn principal.
        pool.made.burnFrom(msg.sender, principal);
        // Transfer interest and extra to sodaRevenue.
        pool.made.transferFrom(msg.sender, sodaMaster.revenue(), interest + extra);

        // Clear the loan.
        pool.calculator.collectDebt(_loanId);
        // Unlocks in vault.
        pool.vault.unlockByBank(loanCreator, lockedAmount);

        pool.vault.transferByBank(loanCreator, msg.sender, lockedAmount);

        emit CollectDebt(msg.sender, _poolId, _loanId);
    }
}

// File: contracts/tokens/SodaToken.sol

// This token is owned by ../strategies/CreateSoda.sol
contract SodaToken is ERC20("SodaToken", "SODA"), Ownable {

    /// @notice Creates `_amount` token to `_to`.
    /// Must only be called by the owner (CreateSoda).
    /// CreateSoda gurantees the maximum supply of SODA is 330,000,000
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // transfers delegate authority when sending a token.
    // https://medium.com/bulldax-finance/sushiswap-delegation-double-spending-bug-5adcc7b3830f
    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        super._transfer(sender, recipient, amount);
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    }

    /// @notice A record of each accounts delegate
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
        require(signatory != address(0), "SODA::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SODA::delegateBySig: invalid nonce");
        require(now <= expiry, "SODA::delegateBySig: signature expired");
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
        require(blockNumber < block.number, "SODA::getPriorVotes: not yet determined");

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
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SODAs (not scaled);
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
        uint32 blockNumber = safe32(block.number, "SODA::_writeCheckpoint: block number exceeds 32 bits");

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

// File: contracts/strategies/CreateSoda.sol

// This contract has the power to change SODA allocation among
// different pools, but can't mint more than 100,000 SODA tokens.
// With ALL_BLOCKS_AMOUNT and SODA_PER_BLOCK,
// we have 100,000 * 1 = 100,000
//
// For the remaining 900,000 SODA, we will need to deploy a new contract called
// CreateMoreSoda after the community can make a decision by voting.
//
// Currently this contract is the only owner of SodaToken and is itself owned by
// Timelock, and it has a function transferToCreateMoreSoda to transfer the
// ownership to CreateMoreSoda once all the 100,000 tokens are out.
contract CreateSoda is IStrategy, Ownable {
    using SafeMath for uint256;

    uint256 public constant ALL_BLOCKS_AMOUNT = 100000;
    uint256 public constant SODA_PER_BLOCK = 1 * 1e18;

    uint256 constant PER_SHARE_SIZE = 1e12;

    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint;       // How many allocation points assigned to this pool. SODAs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SODAs distribution occurs.
    }

    // Info of each pool.
    mapping (address => PoolInfo) public poolMap;  // By vault address.
    // pool length
    mapping (uint256 => address) public vaultMap;
    uint256 public poolLength;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The first block.
    uint256 public startBlock;

    // startBlock + ALL_BLOCKS_AMOUNT
    uint256 public endBlock;

    // The SODA Pool.
    SodaMaster public sodaMaster;

    mapping(address => uint256) private valuePerShare;  // By vault.

    constructor(
        SodaMaster _sodaMaster
    ) public {
        sodaMaster = _sodaMaster;

        // Approve all.
        IERC20(sodaMaster.soda()).approve(sodaMaster.pool(), type(uint256).max);
    }

    // Admin calls this function.
    function setPoolInfo(
        uint256 _poolId,
        address _vault,
        IERC20 _token,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        if (_poolId >= poolLength) {
            poolLength = _poolId + 1;
        }

        vaultMap[_poolId] = _vault;

        totalAllocPoint = totalAllocPoint.sub(poolMap[_vault].allocPoint).add(_allocPoint);
        poolMap[_vault].allocPoint = _allocPoint;

        _token.approve(sodaMaster.pool(), type(uint256).max);
    }

    // Admin calls this function.
    function approve(IERC20 _token) external override onlyOwner {
        _token.approve(sodaMaster.pool(), type(uint256).max);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to > endBlock) {
            _to = endBlock;
        }

        if (_from >= _to) {
            return 0;
        }

        return _to.sub(_from);
    }

    function getValuePerShare(address _vault) external view override returns(uint256) {
        return valuePerShare[_vault];
    }

    function pendingValuePerShare(address _vault) external view override returns (uint256) {
        PoolInfo storage pool = poolMap[_vault];

        uint256 amountInVault = IERC20(_vault).totalSupply();
        if (block.number > pool.lastRewardBlock && amountInVault > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sodaReward = multiplier.mul(SODA_PER_BLOCK).mul(pool.allocPoint).div(totalAllocPoint);
            sodaReward = sodaReward.sub(sodaReward.div(20));
            return sodaReward.mul(PER_SHARE_SIZE).div(amountInVault);
        } else {
            return 0;
        }
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 i = 0; i < poolLength; ++i) {
            _update(vaultMap[i]);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _update(address _vault) public {
        PoolInfo storage pool = poolMap[_vault];

        if (pool.allocPoint <= 0) {
            return;
        }

        if (pool.lastRewardBlock == 0) {
                // This is the first time that we start counting blocks.
            pool.lastRewardBlock = block.number;
        }

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 shareAmount = IERC20(_vault).totalSupply();
        if (shareAmount == 0) {
            // Only after now >= pool.startTime in SodaPool, shareAmount can be larger than 0.
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 allReward = multiplier.mul(SODA_PER_BLOCK).mul(pool.allocPoint).div(totalAllocPoint);
        SodaToken(sodaMaster.soda()).mint(sodaMaster.dev(), allReward.div(20));  // 5% goes to dev.
        uint256 farmerReward = allReward.sub(allReward.div(20));

        SodaToken(sodaMaster.soda()).mint(address(this), farmerReward);  // 95% goes to farmers.

        valuePerShare[_vault] = valuePerShare[_vault].add(farmerReward.mul(PER_SHARE_SIZE).div(shareAmount));
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev See {IStrategy-deposit}.
     */
    function deposit(address _vault, uint256 _amount) external override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");

        if (startBlock == 0) {
            startBlock = block.number;
            endBlock = startBlock + ALL_BLOCKS_AMOUNT;
        }

        _update(_vault);
    }

    /**
     * @dev See {IStrategy-claim}.
     */
    function claim(address _vault) external override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");

        _update(_vault);
    }

    /**
     * @dev See {IStrategy-withdraw}.
     */
    function withdraw(address _vault, uint256 _amount) external override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");

        _update(_vault);
    }

    /**
     * @dev See {IStrategy-getTargetToken}.
     */
    function getTargetToken() external view override returns(address) {
        return sodaMaster.soda();
    }

    // This only happens after all the 100,000 tokens are minted, and should
    // be after the community can vote (I promise by then Timelock will
    // be administrated by GovernorAlpha).
    //
    // Community (of the future), please make sure _createMoreSoda contract is
    // safe enough to pull the trigger.
    function transferToCreateMoreSoda(address _createMoreSoda) external onlyOwner {
        require(block.number > endBlock);
        SodaToken(sodaMaster.soda()).transferOwnership(_createMoreSoda);
    }
}

// File: contracts/SodaDataBoard.sol


// Query data related to soda.
// This contract is owned by Timelock.
contract SodaDataBoard is Ownable {

    SodaMaster public sodaMaster;

    constructor(SodaMaster _sodaMaster) public {
        sodaMaster = _sodaMaster;
    }

    function getCalculatorStat(uint256 _poolId) public view returns(uint256, uint256, uint256) {
        ICalculator calculator;
        (,, calculator) = SodaBank(sodaMaster.bank()).poolMap(_poolId);
        uint256 rate = calculator.rate();
        uint256 minimumLTV = calculator.minimumLTV();
        uint256 maximumLTV = calculator.maximumLTV();
        return (rate, minimumLTV, maximumLTV);
    }

    function getPendingReward(uint256 _poolId, uint256 _index) public view returns(uint256) {
        SodaVault vault;
        (, vault,) = SodaPool(sodaMaster.pool()).poolMap(_poolId);
        return vault.getPendingReward(msg.sender, _index);
    }

    // get APY * 100
    function getAPY(uint256 _poolId, address _token, bool _isLPToken) public view returns(uint256) {
        (, SodaVault vault,) = SodaPool(sodaMaster.pool()).poolMap(_poolId);

        uint256 MK_STRATEGY_CREATE_SODA = 0;
        CreateSoda createSoda = CreateSoda(sodaMaster.strategyByKey(MK_STRATEGY_CREATE_SODA));
        (uint256 allocPoint,) = createSoda.poolMap(address(vault));
        uint256 totalAlloc = createSoda.totalAllocPoint();

        if (totalAlloc == 0) {
            return 0;
        }

        uint256 vaultSupply = vault.totalSupply();

        uint256 factor = 1;  // 1 SODA per block

        if (vaultSupply == 0) {
            // Assume $1 is put in.
            return getSodaPrice() * factor * 5760 * 100 * allocPoint / totalAlloc / 1e6;
        }

        // 2250000 is the estimated yearly block number of ethereum.
        // 1e18 comes from vaultSupply.
        if (_isLPToken) {
            uint256 lpPrice = getEthLpPrice(_token);
            if (lpPrice == 0) {
                return 0;
            }

            return getSodaPrice() * factor * 2250000 * 100 * allocPoint * 1e18 / totalAlloc / lpPrice / vaultSupply;
        } else {
            uint256 tokenPrice = getTokenPrice(_token);
            if (tokenPrice == 0) {
                return 0;
            }

            return getSodaPrice() * factor * 2250000 * 100 * allocPoint * 1e18 / totalAlloc / tokenPrice / vaultSupply;
        }
    }

    // return user loan record size.
    function getUserLoanLength(address _who) public view returns (uint256) {
        return SodaBank(sodaMaster.bank()).getLoanListLength(_who);
    }

    // return loan info (loanId,principal, interest, lockedAmount, time, rate, maximumLTV)
    function getUserLoan(address _who, uint256 _index) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        uint256 poolId;
        uint256 loanId;
        (poolId, loanId) = SodaBank(sodaMaster.bank()).loanList(_who, _index);

        ICalculator calculator;
        (,, calculator) = SodaBank(sodaMaster.bank()).poolMap(poolId);

        uint256 lockedAmount = calculator.getLoanLockedAmount(loanId);
        uint256 principal = calculator.getLoanPrincipal(loanId);
        uint256 interest = calculator.getLoanInterest(loanId);
        uint256 time = calculator.getLoanTime(loanId);
        uint256 rate = calculator.getLoanRate(loanId);
        uint256 maximumLTV = calculator.getLoanMaximumLTV(loanId);

        return (loanId, principal, interest, lockedAmount, time, rate, maximumLTV);
    }

    function getEthLpPrice(address _token) public view returns (uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(sodaMaster.uniswapV2Factory());
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(_token, sodaMaster.wETH()));
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        if (pair.token0() == _token) {
            return reserve1 * getEthPrice() * 2 / pair.totalSupply();
        } else {
            return reserve0 * getEthPrice() * 2 / pair.totalSupply();
        }
    }

    // Return the 6 digit price of eth on uniswap.
    function getEthPrice() public view returns (uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(sodaMaster.uniswapV2Factory());
        IUniswapV2Pair ethUSDTPair = IUniswapV2Pair(factory.getPair(sodaMaster.wETH(), sodaMaster.usdt()));
        require(address(ethUSDTPair) != address(0), "ethUSDTPair need set by owner");
        (uint reserve0, uint reserve1,) = ethUSDTPair.getReserves();
        // USDT has 6 digits and WETH has 18 digits.
        // To get 6 digits after floating point, we need 1e18.
        if (ethUSDTPair.token0() == sodaMaster.wETH()) {
            return reserve1 * 1e18 / reserve0;
        } else {
            return reserve0 * 1e18 / reserve1;
        }
    }

    // Return the 6 digit price of soda on uniswap.
    function getSodaPrice() public view returns (uint256) {
        return getTokenPrice(sodaMaster.soda());
    }

    // Return the 6 digit price of any token on uniswap.
    function getTokenPrice(address _token) public view returns (uint256) {
        if (_token == sodaMaster.wETH()) {
            return getEthPrice();
        }

        IUniswapV2Factory factory = IUniswapV2Factory(sodaMaster.uniswapV2Factory());
        IUniswapV2Pair tokenETHPair = IUniswapV2Pair(factory.getPair(_token, sodaMaster.wETH()));
        require(address(tokenETHPair) != address(0), "tokenETHPair need set by owner");
        (uint reserve0, uint reserve1,) = tokenETHPair.getReserves();

        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }

        // For 18 digits tokens, we will return 6 digits price.
        if (tokenETHPair.token0() == _token) {
            return getEthPrice() * reserve1 / reserve0;
        } else {
            return getEthPrice() * reserve0 / reserve1;
        }
    }
}