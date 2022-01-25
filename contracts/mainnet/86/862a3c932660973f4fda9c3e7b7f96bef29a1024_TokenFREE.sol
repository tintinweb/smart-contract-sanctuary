/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

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
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Governance is Context {
    address internal _governance;

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial governance.
     */
    constructor () internal {
        _governance = msg.sender;
        emit GovernanceTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(_governance == msg.sender, "NOT_Governance");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newGovernance`).
     * Can only be called by the current governance.
     */
    function transferGovernance(address newGovernance) public onlyGovernance {
        require(newGovernance != address(0), "ZERO_ADDRESS");
        emit GovernanceTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }
}

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * @dev Emitted when `amount` tokens are moved from one account (`sender`) to
     * another (`recipient`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);
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

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isNotZero(address account) internal pure returns (bool) {
        return account != address(0);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

contract ERC20Std is IERC20 {
    using SafeMath for uint256;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name, string memory symbol, uint8 decimals) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = 0;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");
        require(amount > 0, "TRANSFER_ZERO_AMOUNT");

        _balanceOf[sender] = _balanceOf[sender].sub(amount, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");
        require(_balanceOf[account] > 0, "INSUFFICIENT_FUNDS");

        _balanceOf[account] = _balanceOf[account].sub(amount, "BURN_AMOUNT_EXCEEDS_BALANCE");
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "APPROVE_FROM_THE_ZERO_ADDRESS");
        require(spender != address(0), "APPROVE_TO_THE_ZERO_ADDRESS");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address recipient, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);

        emit Transfer(address(0), recipient, amount);
    }
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
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

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

contract TokenFREE is ERC20Std, Governance {
    using SafeERC20 for IERC20;
    using Address for address;

    struct Package {
        address owner;
        uint256 partI;
        uint256 partII;
        uint256 claimed;
        uint256 claimTimeOfPartI;
        uint256 claimTimeOfPartII;
    }

    mapping(address => Package) public packages;
    IUniswapV2Router02 public swapRouter;
    IERC20 public USDT;
    address public WETH;
    mapping(address => uint8) private _whiteList;//Tokens supported
    uint256 public ratioOfExchange = 100;//1 USDT = 100 FREE
    uint256 private _donationDuration = 30 days;
    uint256 private _lockSlot = 15 days;
    uint256 private _balance4DAO = 0;
    uint256 private _balance4Redeem = 0;
    uint256 private _destUsdtOfDonation;//Destination amount of USDT of donation : 100 millions
    uint256 private _totalUsdtOfDonation;//Total amount of USDT of donation
    uint256 private _endTimeOfDonation;
    bool public canTest;
    mapping(address => uint256) private _amountOfToken;//累计捐赠TOKEN的数量

    event StartDonation(uint256 startTime, uint256 donationDuration, uint256 lockSlot, uint256 destUsdtOfDonation);
    event Redeem(address sender, uint256 amountOfFREE, uint256 usdtReceived);
    event DaoWithdraw(address recipient, uint256 amount);
    event Claimed(address recipient, uint256 amount);

    constructor() public ERC20Std("Freedom of Wealth DAO", "FREE", 18){
        swapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        _whiteList[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 1;//USDT
        _whiteList[0x514910771AF9Ca656af840dff83E8264EcF986CA] = 1;//LINK
        _whiteList[0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE] = 1;//SHIB
        _whiteList[0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984] = 1;//UNI
        _whiteList[0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71] = 1;//PEOPLE

        WETH = swapRouter.WETH();

        _destUsdtOfDonation = 10 ** 8 * 10 ** uint256(USDT.decimals());
        _endTimeOfDonation = block.timestamp.add(_donationDuration);

        canTest = true;
        _governance = 0xEc8342c266A398ab296CA050D951e15846bB34Bd;
    }

    uint8 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier claimable(){
        require(packages[msg.sender].owner == msg.sender, 'NOT_EXISTS');
        require(packages[msg.sender].partI.add(packages[msg.sender].partII) > 0, 'INSUFFICIENT');
        _;
    }

    modifier donationOver(){
        require(isOver(), "DONATION_NOT_OVER");
        _;
    }

    function inWhiteList(address token) public view returns (bool) {
        return _whiteList[token] == 1;
    }

    function addToWhiteList(address token) external onlyGovernance {
        _whiteList[token] = 1;
    }

    function addBatchToWhiteList(address[] calldata tokens) external onlyGovernance {
        for (uint i = 0; i < tokens.length; i++) {
            _whiteList[tokens[i]] = 1;
        }
    }

    function removeFromWhiteList(address token) external onlyGovernance {
        _whiteList[token] = 0;
    }

    receive() external payable {
        address sender = msg.sender;
        if (sender.isContract()) {
            assert(sender == WETH);
        }
        else {
            donateETH();
        }
    }

    function amountOfToken(address token) public view returns (uint256) {
        return _amountOfToken[token];
    }

    function donateETH() lock public payable returns (uint256 halfAmountOfFREE) {
        IWETH(WETH).deposit{value : msg.value}();
        halfAmountOfFREE = _donate(WETH, msg.value);
    }

    //Donate tokens（include USDT）
    function donate(address token, uint256 amount) lock external returns (uint256 halfAmountOfFREE) {
        require(inWhiteList(token), "UNSUPPORTED_TOKEN");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        halfAmountOfFREE = _donate(token, amount);
    }

    function _donate(address token, uint256 amount) internal returns (uint256 halfAmountOfFREE) {
        require(!isOver(), "DONATION_IS_OVER");
        uint256 usdtAmount = 0;
        if (token == address(USDT)) {
            usdtAmount = amount;
        }
        else {
            usdtAmount = _swapForUSDT(token, amount);
        }

        require(usdtAmount > 0, "ZERO_AMOUNT_OF_USDT");
        _amountOfToken[token] = _amountOfToken[token].add(amount);
        _totalUsdtOfDonation = _totalUsdtOfDonation.add(usdtAmount);
        uint256 usdt2DAO = usdtAmount.div(2);
        uint256 usdt2Redeem = usdtAmount.sub(usdt2DAO);
        _balance4DAO = _balance4DAO.add(usdt2DAO);
        _balance4Redeem = _balance4Redeem.add(usdt2Redeem);

        uint256 amountOfFREE = usdtAmount.mul(ratioOfExchange).mul(10 ** uint256(decimals())).div(10 ** uint256(USDT.decimals()));
        halfAmountOfFREE = amountOfFREE.mul(50).div(10 ** 2);
        _mint(msg.sender, halfAmountOfFREE);

        uint256 partI = amountOfFREE.mul(30).div(10 ** 2);
        uint256 partII = amountOfFREE.mul(20).div(10 ** 2);
        Package storage package = packages[msg.sender];
        package.owner = msg.sender;
        package.claimed = package.claimed.add(halfAmountOfFREE);
        package.partI = package.partI.add(partI);
        package.partII = package.partII.add(partII);
        package.claimTimeOfPartI = block.timestamp.add(_lockSlot);
        package.claimTimeOfPartII = block.timestamp.add(_lockSlot * 2);
    }

    function _swapForUSDT(address token, uint256 amount) internal returns (uint256 usdtAmount){
        // generate the uniswap pair path of Token/ETH -> USDT
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = address(USDT);

        IERC20(token).safeApprove(address(swapRouter), amount);
        uint256[] memory amounts = swapRouter.swapExactTokensForTokens(
            amount,
            0, // accept any amount of USDT
            path,
            address(this),
            block.timestamp
        );
        return amounts[1];
    }

    function balance4DAO() public view returns (uint256) {
        return _balance4DAO;
    }

    function balance4Redeem() public view returns (uint256) {
        return _balance4Redeem;
    }

    function destUsdtOfDonation() public view returns (uint256) {
        return _destUsdtOfDonation;
    }

    function totalUsdtOfDonation() public view returns (uint256) {
        return _totalUsdtOfDonation;
    }

    function endTimeOfDonation() public view returns (uint256) {
        return _endTimeOfDonation;
    }

    function isOver() public view returns (bool) {
        return block.timestamp > _endTimeOfDonation || _totalUsdtOfDonation >= _destUsdtOfDonation;
    }

    function nextClaimTime(address account) external view returns (uint256) {
        if (packages[account].partI > 0) {
            return packages[account].claimTimeOfPartI;
        }
        else if (packages[account].partII > 0) {
            return packages[account].claimTimeOfPartII;
        }
        return 0;
    }

    function nextClaimable(address account) external view returns (uint256) {
        if (block.timestamp > packages[account].claimTimeOfPartII) {
            return packages[account].partI.add(packages[account].partII);
        }
        else {
            if (packages[account].partI > 0) {
                return packages[account].partI;
            }
            else if (packages[account].partII > 0) {
                return packages[account].partII;
            }
        }
        return 0;
    }

    function claimed(address account) external view returns (uint256) {
        return packages[account].claimed;
    }

    function locked(address account) public view returns (uint256) {
        return packages[account].partI.add(packages[account].partII);
    }

    function claim() claimable lock external returns (bool){
        Package storage package = packages[msg.sender];
        require(block.timestamp > package.claimTimeOfPartI, 'TIME_IS_NOT_UP_FOR_FIRST_UNLOCK');
        uint256 canClaimThisTime = 0;
        if (package.partI > 0) {
            canClaimThisTime = package.partI;
            package.partI = 0;
        }
        if (block.timestamp > package.claimTimeOfPartII) {
            canClaimThisTime = canClaimThisTime.add(package.partII);
            package.partII = 0;
        }
        require(canClaimThisTime > 0, "TIME_IS_NOT_UP_FOR_SECOND_UNLOCK");
        package.claimed = package.claimed.add(canClaimThisTime);
        _mint(msg.sender, canClaimThisTime);
        emit Claimed(msg.sender, canClaimThisTime);

        return true;
    }

    function redeem(uint256 amountOfFREE) external returns (bool){
        require(amountOfFREE > 0, "ZERO_AMOUNT");
        require(_balance4Redeem > 0, "INSUFFICIENT_USDT_FOR_REDEEM");

        uint256 usdtCanReceived = _balance4Redeem.mul(amountOfFREE).div(_totalSupply);
        USDT.safeTransfer(msg.sender, usdtCanReceived);
        emit Redeem(msg.sender, amountOfFREE, usdtCanReceived);

        _balance4Redeem = _balance4Redeem.sub(usdtCanReceived);
        _burn(msg.sender, amountOfFREE);

        return true;
    }

    //Withdraw for DAO
    function daoWithdraw() donationOver onlyGovernance external {
        require(_balance4DAO > 0, "INSUFFICIENT");
        USDT.safeTransfer(_governance, _balance4DAO);
        emit DaoWithdraw(_governance, _balance4DAO);
        _balance4DAO = 0;
    }

    function startWith(uint256 donationDuration_, uint256 lockSlot_, uint256 destUsdtOfDonation_) onlyGovernance external {
        canTest = false;
        _startDonation(donationDuration_, lockSlot_, destUsdtOfDonation_);
    }

    function start() onlyGovernance external {
        canTest = false;
        _startDonation(30 days, 15 days, 10 ** 8 * 10 ** uint256(USDT.decimals()));
    }

    function startForTest() onlyGovernance external {
        require(canTest, "FORBIDDEN");
        _startDonation(30 minutes, 15 minutes, 500 * 10 ** uint256(USDT.decimals()));
    }

    function _startDonation(uint256 donationDuration_, uint256 lockSlot_, uint256 destUsdtOfDonation_) internal {
        if (donationDuration_ > 0) {
            _donationDuration = donationDuration_;
            _endTimeOfDonation = block.timestamp.add(_donationDuration);
        }
        if (lockSlot_ > 0) {
            _lockSlot = lockSlot_;
        }
        if (destUsdtOfDonation_ > 0) {
            _destUsdtOfDonation = destUsdtOfDonation_;
        }

        emit StartDonation(block.timestamp, _donationDuration, _lockSlot, _destUsdtOfDonation);
    }
}