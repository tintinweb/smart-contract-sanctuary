/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;
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

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

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

pragma solidity 0.6.12;

library DEFXConstants {
    string private constant _name = "DeFinity";
    string private constant _symbol = "DEFX";
    uint8 private constant _decimals = 18;
    address private constant _tokenOwner = 0x5ca46B14691d9Ea4ce2D8e66e3550DE268cA6E2E;

    function getName() internal pure returns (string memory) {
        return _name;
    }

    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }

    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }

    function getTokenOwner() internal pure returns (address) {
        return _tokenOwner;
    }

}

contract DEFX is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 _totalSupply = 171516755 * 10**18;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    IUniswapV2Router02 public uniRouter;
    IUniswapV2Factory public uniFactory;
    address public launchPool;

    uint256 private _tradingTime;
    uint256 private _restrictionLiftTime;
    uint256 private _restrictionGas = 487000000000;
    uint256 private _maxRestrictionAmount = 40000 * 10**18;
    mapping (address => bool) private _isWhitelisted;
    mapping (address => bool) private _openSender;
    mapping (address => uint256) private _lastTx;

    constructor () 
        public 
    {
        _balances[owner()] = _totalSupply; 
        emit Transfer(address(0), DEFXConstants.getTokenOwner(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return DEFXConstants.getName();
    }

    function symbol() public view returns (string memory) {
        return DEFXConstants.getSymbol();
    }

    function decimals() public view returns (uint8) {
        return DEFXConstants.getDecimals();
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "DEFX: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "DEFX: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private launchRestrict(sender, recipient, amount) {
        require(sender != address(0), "DEFX: transfer from the zero address");
        require(recipient != address(0), "DEFX: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "DEFX: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "DEFX: approve from the zero address");
        require(spender != address(0), "DEFX: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setRestrictionAmount(uint256 amount) external onlyOwner() {
        _maxRestrictionAmount = amount;
    }

    function setRestrictionGas(uint256 price) external onlyOwner() {
        _restrictionGas = price;
    }

    function whitelistAccount(address account) external onlyOwner() {
        _isWhitelisted[account] = true;
    }

    function addSender(address account) external onlyOwner() {
        _openSender[account] = true;
    }

    modifier launchRestrict(address sender, address recipient, uint256 amount) {
        _;
    }
}

contract DEFXStakingPool is Ownable {
    using SafeMath for uint;
    struct StakedBalance { uint time; uint amount; }

    DEFX public defxToken;
    uint public rewardTimeSpan;
    uint public annualInterestRate;
    
    address[] private stakers;
    mapping (address => StakedBalance[]) private stakedBalances;
    mapping (address => uint) private totalStakedBalances;
    uint public totalStakedAmount;
    mapping (address => uint) private earnedRewards;

    constructor(address _tokenContractAddress, uint _annualInterestRate, uint _rewardTimeSpan)
        public
    {
        defxToken = DEFX(_tokenContractAddress);
        annualInterestRate = _annualInterestRate;
        rewardTimeSpan = _rewardTimeSpan;

        stakers = new address[](0);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Owner configuration
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Allows contract owner to change annual interest rate. Reward earned up to that moment is calculated
     * using previous interest rate.
     */
    function setAnnualInterestRate(uint _interestRate)
        external
        onlyOwner
    {
        collectRewardForAllStakers();
        annualInterestRate = _interestRate;
    }

    /**
     * @notice Allows contract owner to change reward time span. Reward earned up to that moment is calculated using
     * previous timespan.
     */
    function setRewardTimeSpan(uint _timeSpan)
        external
        onlyOwner
    {
        collectRewardForAllStakers();
        rewardTimeSpan = _timeSpan;
    }

    /**
     * @notice Allows contract owner to withdraw any DEFX balance from the contract which exceeds minimum needed DEFX
     * balance. Minimum DEFX balance is calculated as a sum of all staked DEFX and reward that would be earned in the
     * next year with the current annual interest rate.
     */
    function withdrawUnusedBalance(uint _amount)
        external
        onlyOwner
    {
        require(defxToken.balanceOf(address(this)) - _amount >= getMinContractBalance(), "Max withdrawal amount exceeded.");
        require(defxToken.transfer(owner(), _amount), "Transfer failed");
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Staking
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Allows any DEFX holder to stake certain amount of DEFX and earn reward. Reward is calculated based on
     * the annual interest rate specified by annualInterestRate attribute and paid on basis specified by rewardTimeSpan
     * attribute (daily, weekly, etc.). There is no automatic transfer of the reward, but stakers should redeem reward
     * instead.
     * Pre-condition for staking of DEFX is that the staker should approve address of this smart contract to spend
     * their DEFX.
     */
    function stake(uint _amount) 
        external
    {
        totalStakedAmount = totalStakedAmount.add(_amount);
        require(defxToken.balanceOf(address(this)) + _amount >= getMinContractBalance(), "Pool's balance too low for covering annual reward");

        if(totalStakedBalances[_msgSender()] == 0)
            stakers.push(_msgSender());
        stakedBalances[_msgSender()].push(StakedBalance(block.timestamp, _amount));

        totalStakedBalances[_msgSender()] = totalStakedBalances[_msgSender()].add(_amount);

        require(defxToken.transferFrom(_msgSender(), address(this), _amount), "Transfer failed");
    }

    /**
     * @notice Allows any DEFX holder who has previously staked DEFX to unstake it, up to the amount specified by input
     * parameter. All reward earned up to that moment is calculated and needs to be redeemed sperately from unstaking.
     * It can be done any time before or any time after unstaking.
     */
    function unstake(uint _amount) 
        external
    {
        require(_amount <= totalStakedBalances[_msgSender()], "Maximum staked amount is exceeded.");
        collectReward(_msgSender());
        uint amountToUnstake = _amount;

        for(uint i = stakedBalances[_msgSender()].length; i > 0; i--) 
        {
            uint amount = stakedBalances[_msgSender()][i-1].amount;

            if (amountToUnstake >= amount) {
                amountToUnstake = amountToUnstake.sub(amount);
                delete stakedBalances[_msgSender()][i-1];
            }
            else { 
                stakedBalances[_msgSender()][i-1].amount = amount.sub(amountToUnstake);
                amountToUnstake = 0;    
            }

            if (amountToUnstake == 0)
                break;  
        }

        totalStakedBalances[_msgSender()] = totalStakedBalances[_msgSender()].sub(_amount);
        totalStakedAmount = totalStakedAmount.sub(_amount);
        require(defxToken.transfer(_msgSender(), _amount), "Transfer failed");
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Redeeming reward
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Allows token owner to transfer earned reward to the staker.
     */
    function redeemRewardToStaker(address _staker, uint _amount)
        external
        onlyOwner
    {
        redeemReward(_staker, _amount);
    }

    /**
     * @notice Allows staker to transfer earned reward to themselves.
     */
    function redeemReward(uint _amount)
        external
    {
        redeemReward(_msgSender(), _amount);
    }

    function redeemReward(address _staker, uint _amount) 
        private
    {
        collectReward(_staker);
        require(_amount <= earnedRewards[_staker], "Maximum redeemable reward is exceeded.");

        earnedRewards[_staker] = earnedRewards[_staker].sub(_amount);
        require(defxToken.transfer(_staker, _amount), "Transfer failed.");
    }

    function collectReward(address _staker)
        private 
    {
        for (uint i = 0; i < stakedBalances[_staker].length; i++) 
        {
            uint time = stakedBalances[_staker][i].time;
            uint amount = stakedBalances[_staker][i].amount;

            uint reward = calculateReward(time, amount);
            earnedRewards[_staker] = earnedRewards[_staker].add(reward);

            stakedBalances[_staker][i].time = getNewTime(time);
        }
    }

    function collectRewardForAllStakers()
        private 
    {
         for (uint i = 0; i < stakers.length; i++) 
        {
            if (totalStakedBalances[stakers[i]] > 0) 
            {
                collectReward(stakers[i]);
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Reading functions
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @return Earned reward for the staker up to that moment for specified staker's address
     */
    function getEarnedReward(address _staker)
        external
        view
        returns (uint)
    {
        uint totalAmount = earnedRewards[_staker];

        for (uint i = 0; i < stakedBalances[_staker].length; i++) 
        {
            uint time = stakedBalances[_staker][i].time;
            uint amount = stakedBalances[_staker][i].amount;

            totalAmount = totalAmount.add(calculateReward(time, amount));
        }

        return totalAmount;
    }

    /**
     * @return Staked amount of DEFX for specified staker's address
     */
    function getStakedAmount(address _staker)
        external
        view
        returns (uint)
    {
        return totalStakedBalances[_staker];
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Helper functions
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Calculates reward based on the DEFX amount that is staked and the moment in time when it is staked.
     * It first calculates number of periods (i.e weeks) passed between now and time when DEFX amount is staked 
     * (timeSpanUnits). Then, it calculates interest rate for that period (i.e. weekly interest rate) as 
     * unitInterestRate. Finally reward is equal to period interest rate x staked amount x number of periods.
     */
    function calculateReward(uint _time, uint _amount) 
        private
        view
        returns (uint)
    {
        uint timeSpanUnits = (block.timestamp.sub(_time)).div(rewardTimeSpan);
        uint unitInterestRate = annualInterestRate.mul(rewardTimeSpan).div(365 days);
        return timeSpanUnits.mul(unitInterestRate).mul(_amount).div(10**18);
    }

    function getMinContractBalance() 
        private
        view
        returns(uint)
    {
        uint expectedAnnualRewards = totalStakedAmount.div(10**18).mul(annualInterestRate);
        return totalStakedAmount + expectedAnnualRewards;
    }

    /**
     * @dev Calculates beginning of the current period for which reward is still not calculated.
     */
    function getNewTime(uint _time)
        private
        view
        returns (uint)
    {
        uint timeSpanUnits = (block.timestamp.sub(_time)).div(rewardTimeSpan);
        return _time.add(timeSpanUnits.mul(rewardTimeSpan));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Miscellaneous
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Enable recovery of ether sent by mistake to this contract's address.
     */
    function drainStrayEther(uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        payable(owner()).transfer(_amount);
        return true;
    }

    /**
     * @notice Enable recovery of any ERC20 compatible token sent by mistake to this contract's address.
     * The only token that cannot be drained is DEFX.
     */
    function drainStrayTokens(IERC20 _token, uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        require(address(_token) != address(defxToken), "DEFX cannot be drained");
        return _token.transfer(owner(), _amount);
    }
}