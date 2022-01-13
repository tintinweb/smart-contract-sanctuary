/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: UNLICENSED

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

pragma solidity >=0.6.2;

interface IPoolToken{
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}



interface IApeRouter01 {
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

interface IApeRouter02 is IApeRouter01 {
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

interface IApeFactory {
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


interface IApePair {
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


struct AppStorage{
    address depositToken;
    address poolToken;
    address apeswapMasterApe;
    address apeswapApeRouter;
    address wETH;
    address testPair;
    address testToken0;
    address testToken1;
}




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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract PoolToken is IPoolToken, ERC20{
    address owner;

    constructor(string memory _NAME,string memory _SYMBOL) ERC20(_NAME,_SYMBOL) {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(_msgSender() == owner,"ONLY_POOL_OWNER");
        _;
    }

    function mint(address account,uint256 amount) external override onlyOwner{
        _mint(account, amount);
    }

    function burn(address account,uint256 amount) external override onlyOwner{ 
        _burn(account, amount);
    }
}


contract PoolFarm is Ownable {
    AppStorage internal s;

    using Address for address;

    struct FarmAmount {
        uint256 amountA;
        uint256 amountB;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    constructor() {
        s.depositToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        s.poolToken = address(new PoolToken("Pool Token", "POOL"));
        s.testPair = 0x2e707261d086687470B515B320478Eb1C88D49bb;
        s.testToken0 = 0x55d398326f99059fF775485246999027B3197955;
        s.testToken1 = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        s.apeswapApeRouter = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
        s.apeswapMasterApe = 0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9;
        s.wETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "INVALID_DEPOSIT_AMOUNT");
        uint256 curDepositTokenBalance = IERC20(s.depositToken).balanceOf(
            address(this)
        );
        uint256 poolTokenReceive;
        if (curDepositTokenBalance == 0) {
            poolTokenReceive = amount;
        } else {
            uint256 curPoolTokenBalance = IERC20(s.poolToken).balanceOf(
                address(this)
            );
            if (curPoolTokenBalance > 0) {
                poolTokenReceive =
                    (amount * curPoolTokenBalance) /
                    ((curDepositTokenBalance + amount) - amount);
            } else {
                poolTokenReceive = curDepositTokenBalance + amount;
            }
        }
        IPoolToken(s.poolToken).mint(msg.sender, poolTokenReceive);
        require(
            IERC20(s.depositToken).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "DEPOSIT: INVALID_AMOUNT"
        );
    }

    function getUserInfo() external view returns (uint256) {
        uint256 pid = _getPID();
        bytes memory result = address(s.apeswapMasterApe).functionStaticCall(
            abi.encodeWithSignature(
                "userInfo(uint256,address)",
                pid,
                address(this)
            )
        );
        PoolFarm.UserInfo memory userInfo = abi.decode(
            result,
            (PoolFarm.UserInfo)
        );

        return userInfo.amount;
    }

    function exitAmountCheck(uint256 amount, uint256 userAmount)
        external
        view
        returns (uint256, uint256)
    {
        uint256 lpRatio = amount / IERC20(s.poolToken).balanceOf(address(this));
        uint256 exitMainAmount;
        uint256 exitFarmAmount;

        if (IERC20(s.depositToken).balanceOf(address(this)) > 0) {
            exitMainAmount =
                lpRatio *
                IERC20(s.depositToken).balanceOf(address(this));
        }

        if (userAmount > 0) {
            exitFarmAmount = lpRatio * userAmount;
        }

        return (exitMainAmount, exitFarmAmount);
    }

    function testBurn(uint256 amount) external {
        IPoolToken(s.poolToken).burn(msg.sender, amount);
    }

    function exit(uint256 amount) external {
        uint256 pid = _getPID();
        bytes memory result = address(s.apeswapMasterApe).functionStaticCall(
            abi.encodeWithSignature(
                "userInfo(uint256,address)",
                pid,
                address(this)
            )
        );
        PoolFarm.UserInfo memory userInfo = abi.decode(
            result,
            (PoolFarm.UserInfo)
        );
        uint256 lpRatio = amount / IERC20(s.poolToken).balanceOf(address(this));
        uint256 exitMainAmount;
        uint256 exitFarmAmount;

        if (IERC20(s.depositToken).balanceOf(address(this)) > 0) {
            exitMainAmount =
                lpRatio *
                IERC20(s.depositToken).balanceOf(address(this));
        }

        if (userInfo.amount > 0) {
            exitFarmAmount = lpRatio * userInfo.amount;
        }

        uint256 exitFarmAmountConvert;
        if (exitFarmAmount > 0) {
            _exitFarm(pid, exitFarmAmount);
            exitFarmAmountConvert = _exitLP(exitFarmAmount);
        }

        if (exitFarmAmountConvert > 0) {
            exitMainAmount = exitMainAmount + exitFarmAmountConvert;
        }

        IPoolToken(s.poolToken).burn(msg.sender, amount);
        require(
            IERC20(s.depositToken).transfer(msg.sender, exitMainAmount),
            "WITHDRAW: FAILED_TRANFER"
        );
    }

    function _getLPToken(
        address tokenA,
        address tokenB,
        FarmAmount memory fAmount
    ) internal returns (address, uint256) {

        require(s.testPair != address(0), "POOL_NOT_FOUND");
        uint256 amountToken;
        uint256 amountA;
        uint256 amountB;
        uint256 amountETH;
        uint256 liquidity;
        if (tokenA == s.wETH || tokenB == s.wETH) {
            address tokenPair = tokenA == s.wETH ? tokenB : tokenA;
            (amountToken, amountETH, liquidity) = IApeRouter02(
                s.apeswapApeRouter
            ).addLiquidityETH(
                    tokenPair,
                    fAmount.amountTokenDesired,
                    fAmount.amountTokenMin,
                    fAmount.amountETHMin,
                    address(this),
                    block.timestamp + 20 minutes
                );
        } else {
            IERC20(tokenA).approve(s.apeswapApeRouter, fAmount.amountADesired);
            IERC20(tokenB).approve(s.apeswapApeRouter, fAmount.amountBDesired);
            (amountA, amountB, liquidity) = IApeRouter02(s.apeswapApeRouter)
                .addLiquidity(
                    tokenA,
                    tokenB,
                    fAmount.amountADesired,
                    fAmount.amountBDesired,
                    fAmount.amountAMin, // amountA min accepted
                    fAmount.amountBMin, // amountB min accepted
                    address(this),
                    block.timestamp + 20 minutes
                );
        }

        require(liquidity > 0, "EMPTY_LP_TOKEN");
        return (s.testPair, liquidity);
    }

    function _getPID() internal pure returns (uint256) {
        return 3;
    }

    struct FarmAssetVar {
        address token0;
        address token1;
        address[] pathCheckTokenA;
        address[] pathToken0;
        address[] pathToken1;
        uint256 amountAOptimal;
        uint256 amountBOptimal;
        uint112 reserve0;
        uint112 reserve1;
    }

    function testFarmFromAsset(uint256 depositAmount) external view returns (FarmAmount memory) {
        FarmAssetVar memory farmAsset;
        farmAsset.token0 = IApePair(s.testPair).token0(); // usdt
        farmAsset.token1 = IApePair(s.testPair).token1(); // busd

        //get usdt
        farmAsset.pathCheckTokenA = new address[](2);
        farmAsset.pathCheckTokenA[0] = farmAsset.token0; // sell busd
        farmAsset.pathCheckTokenA[1] = farmAsset.token1; // buy usdt
        uint256[] memory amountsIn = IApeRouter02(s.apeswapApeRouter)
            .getAmountsIn(depositAmount, farmAsset.pathCheckTokenA);  // amount out expect is [busd]
            // [3001274681479580362,3000000000000000000]

        (farmAsset.reserve0, farmAsset.reserve1, ) = IApePair(s.testPair)
            .getReserves();
        farmAsset.amountBOptimal = IApeRouter02(s.apeswapApeRouter).quote(
            uint256(amountsIn[0]),
            uint256(farmAsset.reserve0),
            uint256(farmAsset.reserve1)
        );

        FarmAmount memory fAmount;
        fAmount.amountADesired = amountsIn[0];
        fAmount.amountAMin = amountsIn[0];
        fAmount.amountBDesired = farmAsset.amountBOptimal;
        fAmount.amountBMin = farmAsset.amountBOptimal;

        return fAmount;
    }

    function farmFromAsset(uint256 depositAmount) external {
        FarmAssetVar memory farmAsset;
        farmAsset.token0 = IApePair(s.testPair).token0(); // usdt
        farmAsset.token1 = IApePair(s.testPair).token1(); // busd

        //get usdt
        farmAsset.pathCheckTokenA = new address[](2);
        farmAsset.pathCheckTokenA[0] = farmAsset.token0; // sell busd
        farmAsset.pathCheckTokenA[1] = farmAsset.token1; // buy usdt
        uint256[] memory amountsIn = IApeRouter02(s.apeswapApeRouter)
            .getAmountsIn(depositAmount, farmAsset.pathCheckTokenA);  // amount out expect is [busd]
            // [3001274681479580362,3000000000000000000]

        (farmAsset.reserve0, farmAsset.reserve1, ) = IApePair(s.testPair)
            .getReserves();
        farmAsset.amountBOptimal = IApeRouter02(s.apeswapApeRouter).quote(
            uint256(amountsIn[0]),
            uint256(farmAsset.reserve0),
            uint256(farmAsset.reserve1)
        );

        //amountA = 3001274681479580362
        //amountB =  3006118334301074842;

        // farmAsset.pathToken0 = new address[](2);
        // farmAsset.pathToken0[0] = farmAsset.token1; // sell busd
        // farmAsset.pathToken0[1] = farmAsset.token0; // buy usdt
        // uint256[] memory amountsIn = IApeRouter02(s.apeswapApeRouter)
        //     .getAmountsIn(farmAsset.amountAOptimal, farmAsset.pathToken0);
        // require(
        //     IERC20(farmAsset.token1).approve(s.apeswapApeRouter, amountsIn[0]),
        //     "FAILED_APPROVE_ROUTER"
        // );
        // IApeRouter02(s.apeswapApeRouter).swapTokensForExactTokens(
        //     farmAsset.amountAOptimal,
        //     amountsIn[0],
        //     farmAsset.pathToken0,
        //     address(this),
        //     block.timestamp + 20 minutes
        // );

        FarmAmount memory fAmount;
        fAmount.amountADesired = amountsIn[0];
        fAmount.amountAMin = amountsIn[0];
        fAmount.amountBDesired = farmAsset.amountBOptimal;
        fAmount.amountBMin = farmAsset.amountBOptimal;

        (address pairAddr, uint256 liquidity) = _getLPToken(
            farmAsset.token0,
            farmAsset.token1,
            fAmount
        );

        require(IApePair(pairAddr).approve(s.apeswapMasterApe, liquidity));

        uint256 pid = _getPID(); //_getPID(pairAddr)

        address(s.apeswapMasterApe).functionCall(
            abi.encodeWithSignature("deposit(uint256,uint256)", pid, liquidity)
        );
    }

    function _exitFarm(uint256 pid, uint256 amount) internal {
        address(s.apeswapMasterApe).functionCall(
            abi.encodeWithSignature("withdraw(uint256,uint256)", pid, amount)
        );
    }

    struct ExitLPVar {
        address token0;
        address token1;
        uint256 preToken0Balance;
        uint256 preToken1Balance;
        uint256 postToken0Balance;
        uint256 postToken1Balance;
        uint256 amountAMin;
        uint256 amountBMin;
        address[] pathToken0;
        address[] pathToken1;
        uint256 swapToken0;
    }

    function _exitLP(uint256 amount) internal returns (uint256) {
        ExitLPVar memory exitLPvar;
        exitLPvar.token0 = IApePair(s.testPair).token0();
        exitLPvar.token1 = IApePair(s.testPair).token1();

        // stamp value before exit farm
        exitLPvar.preToken0Balance = IERC20(exitLPvar.token0).balanceOf(
            address(this)
        );
        exitLPvar.preToken1Balance = IERC20(exitLPvar.token1).balanceOf(
            address(this)
        );

        exitLPvar.amountAMin =
            (amount / IApePair(s.testPair).totalSupply()) *
            IERC20(exitLPvar.token0).balanceOf(s.testPair);

        exitLPvar.amountBMin =
            (amount / IApePair(s.testPair).totalSupply()) *
            IERC20(exitLPvar.token1).balanceOf(s.testPair);

        IApeRouter02(s.apeswapApeRouter).removeLiquidity(
            exitLPvar.token0,
            exitLPvar.token1,
            amount,
            exitLPvar.amountAMin,
            exitLPvar.amountBMin,
            address(this),
            block.timestamp + 20 minutes
        );

        // stamp value before exit farm
        exitLPvar.postToken0Balance =
            IERC20(exitLPvar.token0).balanceOf(address(this)) -
            exitLPvar.preToken0Balance;

        exitLPvar.postToken1Balance =
            IERC20(exitLPvar.token1).balanceOf(address(this)) -
            exitLPvar.preToken1Balance;

        assert(
            exitLPvar.postToken0Balance > 0 && exitLPvar.postToken1Balance > 0
        );

        exitLPvar.pathToken0 = new address[](2);
        exitLPvar.pathToken0[0] = exitLPvar.token0;
        exitLPvar.pathToken0[1] = s.depositToken;
        exitLPvar.swapToken0 = _swapBack(
            exitLPvar.postToken0Balance,
            exitLPvar.pathToken0
        );

        return exitLPvar.swapToken0 + exitLPvar.postToken1Balance;
    }

    function _swapBack(uint256 postTokenBalance, address[] memory swapPathToken)
        internal
        returns (uint256)
    {
        uint256[] memory amountOutsToken = IApeRouter02(s.apeswapApeRouter)
            .getAmountsOut(postTokenBalance, swapPathToken);

        require(amountOutsToken[1] > 0, "INVALID_AMOUNT_OUT");

        uint256[] memory swapOutToken0 = IApeRouter02(s.apeswapApeRouter)
            .swapExactTokensForTokens(
                amountOutsToken[0],
                amountOutsToken[1],
                swapPathToken,
                address(this),
                block.timestamp + 20 minutes
            );

        return swapOutToken0[1];
    }

    function depositToken() external view returns (address) {
        return s.depositToken;
    }

    function poolToken() external view returns (address) {
        return s.poolToken;
    }

    function manaulOut(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}