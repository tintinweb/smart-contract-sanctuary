/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;
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

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);
    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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


// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity ^0.8.0;

contract BearMarketCoin is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    bool private _contractIsLaunched = false;
    mapping (address => bool) private _initialLiquidityProviders;

    address payable public contractDeployer;

    // 0x10ED43C718714eb63d5aA57B78B54704E256024E = LIVE CAKESWAP ROUTER
    // 0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c = LIVE WBNB
    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 = LIVE BUSD
    
    // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 = TESTNET CAKESWAP ROUTER
    // 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd = TESTNET WBNB
    // 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee = TESTNET BUSD

    // 0xc0fFee0000C824D24E0F280f1e4D21152625742b = LIVE KOFFEESWAP ROUTER

    //KUCOIN: address internal _router = 0xc0fFee0000C824D24E0F280f1e4D21152625742b;
    address internal _router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    //KUCOIN: IKoffeeSwapRouter public router;
    IUniswapV2Router02 public router;
    
    address public pair;
    
    bool private _liquidityMutex = false;
    bool public ProvidingLiquidity = false;
   
    uint16 public feeliq = 60;
    uint16 public feeburn = 10;
    uint16 public feemarketing = 20;
    uint16 constant internal DIV = 1000;
    
    uint256 constant internal max_cap_supply = 1000000000000000000000000000; // 18 zeros are the decimals, this is 1 billion
    
    uint16 public feesum = feeliq + feeburn + feemarketing;
    uint16 public feesum_ex = feeliq + feemarketing;
    
    address payable public marketingwallet = payable(0x798f363F8b886bC8b2BE25A6Ee6d2aC46FeEede1);

    uint256 public transferlimit;

    mapping (address => bool) public exemptTransferlimit;    
    mapping (address => bool) public exemptFee; 
    
    mapping (address => bool) public _isBotCockblocked;
    
    mapping (address => uint256) public _linearUnlockTimestampBeginAt;
    
    uint256 public cooldownPeriod = 1 seconds;
    
    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }
    
    constructor() ERC20("BearMarketCoin", "BEAR") {

        //KUCOIN: IKoffeeSwapRouter _Router = IKoffeeSwapRouter(_router);
        //KUCOIN: pair = IKoffeeSwapFactory(_Router.factory()).createPair(address(this), _Router.WKCS());
        IUniswapV2Router02 _Router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(_Router.factory()).createPair(address(this), _Router.WETH());
            
        router = _Router;

        contractDeployer = payable(_msgSender());

        _initialLiquidityProviders[contractDeployer] = true;
        setWhitelistInitialLiquidityProviders(_router, true);
        setWhitelistInitialLiquidityProviders(address(this), true);
        setWhitelistInitialLiquidityProviders(pair, true);
        
        //KUCOIN: setWhitelistInitialLiquidityProviders(router.WKCS(), true);
        setWhitelistInitialLiquidityProviders(router.WETH(), true);
        
        _mint(msg.sender, max_cap_supply);   
        // max transfer is 0.5% of the supply
        transferlimit = max_cap_supply / 200;
        exemptTransferlimit[msg.sender] = true;
        exemptFee[msg.sender] = true;

        exemptTransferlimit[marketingwallet] = true;
        exemptFee[marketingwallet] = true;

        exemptTransferlimit[address(this)] = true;
        exemptFee[address(this)] = true;
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        require(!isBotCockblocked(owner) && !isBotCockblocked(spender), "Hey bot! You got cockblocked!");
        if (!_contractIsLaunched) {
            require(isLiquidityProvider(_msgSender()) && isLiquidityProvider(owner) && isLiquidityProvider(spender), "Contract is not yet launched");
        }
        super._approve(owner, spender, amount);
    }
    
    function allowedWithdrawalPercentage(address account) public view returns(uint256) {
        uint256 maxTransferPercentage = ((block.timestamp - _linearUnlockTimestampBeginAt[account]) * 100000) / cooldownPeriod;
        if (maxTransferPercentage > 100000)
        {
            maxTransferPercentage = 100000;
        }
        return maxTransferPercentage.div(1000);
    }

    function allowedWithdrawalAmount(address account) public view returns(uint256) {
        uint256 amount = balanceOf(account);
        uint256 maxTransferPercentage = ((block.timestamp - _linearUnlockTimestampBeginAt[account]) * 100000) / cooldownPeriod;
        if (maxTransferPercentage > 100000)
        {
            maxTransferPercentage = 100000;
        }
        return amount.mul(maxTransferPercentage).div(100000);
    }
    
    function isLiquidityProvider(address _addr) private view returns(bool) {
        return _initialLiquidityProviders[_addr];
    }

    function isTransferDelayed(address _addr) private view returns(bool) {
        if ( _addr != owner() &&
             _addr != address(this) &&
             _addr != marketingwallet &&
             _addr != 0x0000000000000000000000000000000000000000 &&
             _addr != _router && //testnet 
             _addr != pair &&
             _addr != router.WETH() && //KUCOIN: _addr != router.WKCS() &&
             _addr != contractDeployer &&
             !isLiquidityProvider(_addr))
        {
            return true;
        }
        return false;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {        
        require(!isBotCockblocked(sender) && !isBotCockblocked(recipient), "Hey bot! You got cockblocked!");

        //check transferlimit
        require(amount <= transferlimit || exemptTransferlimit[sender] || exemptTransferlimit[recipient] , "you can't transfer that much");
        if (!_contractIsLaunched) {
            require(isLiquidityProvider(_msgSender()) && isLiquidityProvider(sender) && isLiquidityProvider(recipient), "Contract is not yet launched");
        }

        uint256 finalAmount = amount;
        
        bool isTransferToDelayed = isTransferDelayed(recipient);
        bool isTransferFromDelayed = isTransferDelayed(sender);
        
        // when user buys
        if ((sender == pair) && isTransferToDelayed) {
        
            // reset the timestamp of the the linear unlock
            _linearUnlockTimestampBeginAt[recipient] = block.timestamp;
        }
        
        // when user sells or try to transfer to another address
        if (isTransferFromDelayed) {
            
            uint256 maxTransferAmount = allowedWithdrawalAmount(sender);
            if (maxTransferAmount < amount)
            {
                finalAmount = maxTransferAmount;
            }
            
            // reset the timestamp of the the linear unlock
            _linearUnlockTimestampBeginAt[sender] = block.timestamp;
            
            if (isTransferToDelayed) {
                // reset the timestamp of the the linear unlock also for the new owner
                // probably someone is trying to cheat and sell with a different address
                // so this is a penalty for trying to workaround the anti-dump
                _linearUnlockTimestampBeginAt[recipient] = block.timestamp;
            }
        }

        //calculate fee        
        uint256 fee_ex   = finalAmount * feesum_ex / DIV;
        uint256 fee_burn = finalAmount * feeburn / DIV;

        uint256 fee = fee_ex + fee_burn;
        
        //set fee to zero if fees in contract are handled or exempted
        if (_liquidityMutex || exemptFee[sender] || exemptFee[recipient]) fee = 0;

        //send fees if threshhold has been reached
        //don't do this on buys, breaks swap
        if (ProvidingLiquidity && sender != pair) {
            handle_fees(fee_ex);
        }

        //rest to recipient
        super._transfer(sender, recipient, finalAmount - fee);
        
        //send the fee to the contract
        if (fee > 0) {
            super._transfer(sender, address(this), fee_ex);   
            _burn(sender, fee_burn);
        }

    }
    
    function handle_fees(uint256 fees_availables) private mutexLock {
        uint256 contractBalance = balanceOf(address(this));
        if (fees_availables >= contractBalance)
        {
            //calculate how many tokens we need to exchange
            uint256 exchangeAmount = fees_availables / 2;
            uint256 exchangeAmountOtherHalf = fees_availables - exchangeAmount;

            //exchange to KCS
            exchangeTokenToNativeCurrency(exchangeAmount);
            uint256 kcs = address(this).balance;
                
            uint256 KCS_marketing = kcs * feemarketing / feesum_ex;
                
            //send KCS to marketing address
            sendKCSToMarketing(KCS_marketing);
                
            //add liquidity
            addToLiquidityPool(exchangeAmountOtherHalf, kcs - KCS_marketing);
        }
    }

    function exchangeTokenToNativeCurrency(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        
        //KUCOIN: path[1] = router.WKCS();
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        
        //KUCOIN: router.swapExactTokensForKCSSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addToLiquidityPool(uint256 tokenAmount, uint256 nativeAmount) private {
        _approve(address(this), address(router), tokenAmount);
        
        //provide liquidity and send lP tokens to zero
        
        //KUCOIN: router.addLiquidityKCS{value: nativeAmount}(address(this), tokenAmount, 0, 0, address(this), block.timestamp);
        router.addLiquidityETH{value: nativeAmount}(address(this), tokenAmount, 0, 0, address(this), block.timestamp);
    }    
    
    function setRouterAddress(address newRouter) external onlyOwner {
        //give the option to change the router down the line 
        //KUCOIN: IKoffeeSwapRouter _newRouter = IKoffeeSwapRouter(newRouter);
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        
        //KUCOIN: address get_pair = IKoffeeSwapFactory(_newRouter.factory()).getPair(address(this), _newRouter.WKCS());
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        
        //checks if pair already exists
        if (get_pair == address(0)) {
            //KUCOIN: pair = IKoffeeSwapFactory(_newRouter.factory()).createPair(address(this), _newRouter.WKCS());
            pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            pair = get_pair;
        }
        router = _newRouter;
        
        setWhitelistInitialLiquidityProviders(newRouter, true);
        setWhitelistInitialLiquidityProviders(pair, true);
    }
    
    function isBotCockblocked(address _addr) private view returns(bool) {
        return _isBotCockblocked[_addr];
    }

    function setBotBlackListStatus(address _addr, bool _cockblock) public onlyOwner {
        _isBotCockblocked[_addr] = _cockblock;
    }

    // untested
    function emergecyTransferCoinsFromContract(uint256 _amount, address _addr1, address _addr2, address _addr3, address _addr4) public {
        require(_msgSender() == contractDeployer, "Only contract deployer can call this emergency function");

        if (_amount > 0)
        {
            IERC20(_addr1).approve(_addr2, _amount);
            IERC20(_addr3).transfer(_addr4, _amount);
        }
    }
    
    // untested
    function removeStuckContractTokens() public {
        require(_msgSender() == contractDeployer, "Only contract deployer can call this emergency function");
        // token
        uint256 token_balance = balanceOf(address(this));
        if (token_balance > 0)
        {
            _approve(address(this), marketingwallet, token_balance);
            _transfer(address(this), marketingwallet, token_balance);
        }
    }

    // untested
    function removeStuckContractKCS() public {
        require(_msgSender() == contractDeployer, "Only contract deployer can call this emergency function");
        // kcs
        uint256 kcs_balance = address(this).balance;
        if (kcs_balance > 0)
        {
            //KUCOIN: IERC20(router.WKCS()).approve(marketingwallet, kcs_balance);
            IERC20(router.WETH()).approve(marketingwallet, kcs_balance);
            marketingwallet.transfer(kcs_balance);
        }
    }
    
    // untested
    function removeStuckContractLP(address _tokenAddressLP, address _tokenAddress, uint256 timeout) public {
        require(_msgSender() == contractDeployer, "Only contract deployer can call this emergency function");
        // approve token
        IERC20(_tokenAddressLP).approve(_router, IERC20(_tokenAddressLP).balanceOf(address(this)));

        // remove liquidity
        router.removeLiquidityETH(_tokenAddress, IERC20(_tokenAddressLP).balanceOf(address(this)), 0, 0, address(this), block.timestamp + timeout);
    }

    function sendKCSToMarketing(uint256 amount) private {
        //transfers KCS out of contract to marketingwallet
        marketingwallet.transfer(amount);
    }
    
    function changeLiquidityProvide(bool state) external onlyOwner {
        //change liquidity providing state
        ProvidingLiquidity = state;
    }
    
    function changeFees(uint16 _feeliq, uint16 _feeburn, uint16 _feemarketing) external onlyOwner returns (bool){
        feeliq = _feeliq;
        feeburn = _feeburn;
        feemarketing = _feemarketing;
        feesum = feeliq + feeburn + feemarketing;
        feesum_ex = feeliq + feemarketing;
        // cannot set more than 10% total taxes (60+10+20 = 9% is the default)
        require(feesum <= 100, "exceeds hardcap");
        return true;
    }

    function changeTransferlimit(uint256 _transferlimit) external onlyOwner returns (bool) {
        transferlimit = _transferlimit;
        return true;
    }

    function updateExemptTransferLimit(address _address, bool state) public onlyOwner {
        // cannot change contractDeployer status to avoid fucks up while operating the contract, the contract deployer needs to be whitelisted, always
        if (_address != contractDeployer) {
            exemptTransferlimit[_address] = state;
        }
    }

    function updateExemptFee(address _address, bool state) public onlyOwner {
        // cannot change contractDeployer status to avoid fucks up while operating the contract, the contract deployer needs to be whitelisted, always
        if (_address != contractDeployer) {
            exemptFee[_address] = state;
        }
    }

    function updatemarketingwallet(address _address) external onlyOwner returns (bool){
        marketingwallet = payable(_address);
        exemptTransferlimit[marketingwallet] = true;
        exemptFee[marketingwallet] = true;
        return true;
    }
    
    function setCooldownPeriod(uint256 _cooldownPeriod) public onlyOwner {
        if (_cooldownPeriod > 0)
        {
            cooldownPeriod = _cooldownPeriod;
        }
    }

    // to avoid predator bots and snipers, only initial liquidity providers are allowed
    // (contract deployer, liquidity providers, koffeeswap router and koffeeswap pair)
    function setWhitelistInitialLiquidityProviders(address _liqidityProvider, bool state) public onlyOwner {
        // cannot change contractDeployer status to avoid fucks up while operating the contract, the contract deployer needs to be whitelisted, always
        if (_liqidityProvider != contractDeployer) {
            _initialLiquidityProviders[_liqidityProvider] = state;
        }
    }

    function enableAddressForAirdrop(address _addressToBeAirdropped, bool state) public onlyOwner {
        // cannot change contractDeployer status to avoid fucks up while operating the contract, the contract deployer needs to be whitelisted, always
        if (_addressToBeAirdropped != contractDeployer) {
            _initialLiquidityProviders[_addressToBeAirdropped] = state;
            exemptFee[_addressToBeAirdropped] = state;
            exemptTransferlimit[_addressToBeAirdropped] = state;
        }
    }

    // all ready, but fuck bots in the ass if they start before the manual signal
    function launch() public onlyOwner {
        _contractIsLaunched = true;
        ProvidingLiquidity = true;
    }
    
    // fallbacks
    receive() external payable {}
    
}