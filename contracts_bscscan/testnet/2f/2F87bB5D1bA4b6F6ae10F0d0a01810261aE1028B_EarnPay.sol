/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
 * EarnPay: SafeEarn/EarnHub v2/SafeVault forked with improvements and additions (Whale timer, whale fee multiplier, reflection pool mechanism, merchant fee)
 */
interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToTokenThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function setShare(address shareholder, uint256 amount, bool distributeEarnings) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function processManually() external;
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

interface IERC20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    bool    private _isLocked;
    bool    private _ownershipRenounced;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _isLocked = false;
        _ownershipRenounced = false;
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
        require(!_isLocked, "Contract is locked, wait until it is unlocked");
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _ownershipRenounced = true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(!_isLocked, "Contract is locked, wait until it is unlocked");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        _isLocked=true;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(_owner != msg.sender, "Contract is already unlocked");
        require(block.timestamp > _lockTime , "Contract is locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
        _isLocked=false;
    }
}

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

/** Forked Distributor from SafeEarn/EarnHub with performance adjustments (credit woofydev) */
contract DividendDistributor is IDividendDistributor {
    
    using SafeMath for uint256;
    using Address for address;
    // EarnPay Contract
    address _token;
    // Share of the SafeEarn/EarnHub Pie
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    // safeearn contract address
    address TOK = 0x6E2c3779b281d0449009f08a3373d3e873aCd532;

    // bnb address
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IUniswapV2Router02 router;
    // shareholder fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    // shares math and fields
    uint256 public          totalShares;
    uint256 public          totalDividends;
    uint256 public          totalDistributed;
    uint256 public          dividendsPerShare;
    uint256 public          dividendsPerShareAccuracyFactor = 10 ** 36;
    // distributes every hour
    uint256 public minPeriod = 1 hours;
    // 1 Million SafeEarn/EarnHub Minimum Distribution
    uint256 public minDistribution = 1 * (10 ** 15);
    // BNB Needed to Swap to SafeEarn/EarnHub for manual claims
    uint256 public swapToTokenThreshold = 1 * (10 ** 18);
    // current index in shareholder array 
    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02(_router)
        : IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //testnet
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToTokenThreshold) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        swapToTokenThreshold = _bnbToTokenThreshold;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function setShare(address shareholder, uint256 amount, bool distributeEarnings) external override onlyToken {
        
        if(distributeEarnings && shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    
    function deposit() external payable override onlyToken {
        uint256 balanceBefore = IERC20(TOK).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(TOK);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
        );


        uint256 amount = IERC20(TOK).balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function depositInternally() internal {
        uint256 balanceBefore = IERC20(TOK).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(TOK);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapToTokenThreshold}(
                0,
                path,
                address(this),
                block.timestamp
        );


        uint256 amount = IERC20(TOK).balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function processManually() external override onlyToken {
        uint256 shareholderCount = shareholders.length;
        
        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        currentIndex = 0;

        while(iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            IERC20(TOK).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        require(shouldDistribute(msg.sender), 'Must wait 1 hour to claim dividend!');
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getTotalEarned(address shareholder) external view returns (uint256) {
        return shares[shareholder].totalRealised;
    }
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
        delete shareholderIndexes[shareholder];
    }
    
    function setTokenAddress(address nToken) external onlyToken {
        TOK = nToken;
    }
    receive() external payable { }

}

/** 
 * Contract: EarnPay 
 * 
 *  This contract is forked from SafeVault (who took it from SafeEarn/EarnHub - credit woofydev) with some small tweaks / improvements to gas.
 *  Additional Whale Timer & Fee Multiplier Mechanism + Custom Transfer Fee + Custom Merchant Fee + Reward Pool Mechanism added by the EarnPay team
 *  Payout dividends during transfer toggle, 
 *  Buyback & Burn have been adjusted to kick off only during Buys/Sells to minimize wallet-wallet gas transfer fees. 
 *  This contract awards SafeEarn/EarnHub daily to holders, weighted by how much you hold
 *  
 *  Buy Fee:            10%
 *  Sell Fee:           20%
 *  Whale Timer Fee:    30%
 * 
 *  Standard Sale Fee Breakdown:
 *  13% SafeEarn/EarnHub Distribution
 *  1.75% Buyback and burn
 *  1.75% Auto Liquidity
 *  3% Reward Pool
 *  0.5% Token Sustainability
 */
contract ERC20 is IERC20, Context, Ownable {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;
    
    // wrapped bnb address for swapping
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //testnet

    // our burn wallet address - separate from SafeEarn/EarnHub's
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    // token data
    string  private _name;
    string  private _symbol;
    uint8   constant _decimals = 9;
    bool    isEnabled;
    // 1 Trillion Max Supply
    uint256 _totalSupply = 1 * 10**12 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(200);           // 0.5% or 5 Billion
    // balances
    mapping (address => uint256) _balances; 
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) _bonusPoolEarnings;
    // registered merchant
    mapping (address => bool) isMerchant;
    // exemptions
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isReflectionPoolExempt;
    mapping (address => bool) enabledTransferDividends;            // "disabled" by default
    mapping (address => bool) disabledTransferEarnings;            // "enabled" by default
    // timer constants 
    uint    private constant DAY = 86400;                          // How many seconds in a day
    // anti-whale settings 
    uint256 public _whaleSellThreshold = 1 * 10**9 * 10**9;        // 1 billion
    uint    public _whaleSellTimer     = DAY.mul(3);               // 72 hours/3 days at Launch
    mapping (address => uint256) private _amountSold;
    mapping (address => uint) private _timeSinceFirstSell;
    uint8   public _whaleFeeMultiplier          = 3;
    uint8   public _whaleFeeDivider             = 2;
    // fees
    uint256 public liquidityFee                 = 175;
    uint256 public buybackFee                   = 175;
    uint256 public reflectionFee                = 1300;
    uint256 public sustainingFee                = 50;
    uint256 public reflectionpoolFee            = 300;
    // total fees
    uint256 totalFeeSells                       = 2000;
    uint256 totalFeeBuys                        = 1000;
    uint256 totalFeeTransfers                   = 100;
    uint256 totalFeeTransfersMerchant           = 50;
    uint256 feeDenominator                      = 10000;
    // reflection pool
    bool    public  _enableReflectionPool       = false;               // Disabled on deployment
    uint256 private _reflectionPool             = 0;                   // How many reflections are in the reflection pool
    uint256 private _bonusPool                  = 0;                   // How many reflections are in the bonus pool
    uint    public  _poolChance                 = 25;                  // 2.5% chance of winning
    uint    public  _poolTransferChance         = 5;                   // 0.5% chance of winning
    uint    public  _bonusChance                = 250;                 // 25% chance of winning at buy
    uint256 public  _poolThreshold              = 10 * 10**6 * 10**9;  // initial 10 million tokens required to be in the pool before reflection pool can be triggered
    uint    public  _poolThresholdDivider       = 100000;              //.001% of circulating supply
    uint256 public  _poolMinimumSpend           = 1 * 10**6 * 10**9;   // initial 1 million tokens required to buy before reflection pool can be triggered
    uint    public  _poolMinimumSpendDivider    = 1000000;             //.0001% of circulating supply
    uint256 public  _poolMinimumTransfer        = 1 * 10**6 * 10**9;   // initial 1 million tokens required to transfer before before reflection pool can be triggered
    uint256 public  _poolMinimumHODL            = 10 * 10**6 * 10**9;  // initial 10 million tokens required to HODL before reflection pool can be triggered
    uint    public  _poolMinimumHODLDivider     = 100000;              //.001% of circulating supply
    address public  _previousWinner;
    uint256 public  _previousWonAmount;
    uint    public  _previousWinTime;
    uint    public  _lastRoll;
    uint256 private _nonce;
    // sustaining wallet & auto LP receiver
    address public sustainingFeeReceiver = 0x41c91157dDbC39178c8034Aba9F835AC812AB188;
    address public autoLiquidityReceiver;
    // target liquidity is 12%
    uint256 targetLiquidity = 12;
    uint256 targetLiquidityDenominator = 100;
    // Pancakeswap V2 Router
    IUniswapV2Router02 public router;
    address public pair;
    // buy back data
    bool public autoBuybackEnabled = false;
    uint256 autoBuybackAccumulator = 0; // Tracks how many tokens have been bought back AND burned from circulation
    uint256 autoBuybackAmount = 1 * 10**18;
    uint256 autoBuybackBlockPeriod = 3600; // 3 hours
    uint256 autoBuybackBlockLast = block.number;
    bool public allowTransferToSustaining = true;
    // gas for distributor
    DividendDistributor distributor;
    uint256 distributorGas = 500000;
    // in charge of swapping
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(1000); // 0.1% or 1 Billion to start
    // true if our threshold decreases with circulating supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 1000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    // Uniswap Router V2
    address private _dexRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //testnet

    // false if we should disable auto liquidity pairing for any reason
    bool public shouldPairLiquidity = true;
    // because transparency is important
    uint256 public totalBNBSustaining = 0;
    uint256 public totalBNBTokenReflections = 0;
    
    // initialize some stuff
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        //ensure Token is transferrable at deployment, disable during presell
        isEnabled = true;
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        // Liquidity Pool Address for BNB -> EarnPay
        pair = IUniswapV2Factory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        // Wrapped BNB Address used for trading on PCS
        WBNB = router.WETH();
        // our dividend Distributor
        distributor = new DividendDistributor(_dexRouter);
        //exempt deployer, contract, the LP, and burn wallet from reflectionPool
        isReflectionPoolExempt[msg.sender] = true;
        isReflectionPoolExempt[sustainingFeeReceiver] = true;
        isReflectionPoolExempt[pair] = true;
        isReflectionPoolExempt[address(this)] = true;
        isReflectionPoolExempt[DEAD] = true;
        // exempt deployer from fees
        isFeeExempt[msg.sender] = true;
        // exempt deployer from TX limit
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[sustainingFeeReceiver] = true;
        // exempt this contract, the LP, and OUR burn wallet from receiving SafeEarn/EarnHub Rewards
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        autoLiquidityReceiver = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function internalApprove(address spender, uint256 amount) internal returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    /** Approve Total Supply */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // if we're in swap perform a basic transfer
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        // make standard checks
        require(isEnabled, "Token transfer is currently disabled to comply with dxSale");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // check if we have reached the transaction limit
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        
        // REFLECTION POOL MECHANISM
        // pool threshold & minimum required to spend for award are updated to always be relative to % of circulating supply
        bool    _isBuy             = (sender == pair);
        bool    _isSell            = (recipient == pair);
        bool    _isTransfer        = !(_isBuy || _isSell);
        uint256 currentSupply      = getCirculatingSupply();
                _poolThreshold     = currentSupply.div(_poolThresholdDivider);
                _poolMinimumSpend  = currentSupply.div(_poolMinimumSpendDivider);
                _poolMinimumHODL   = currentSupply.div(_poolMinimumHODLDivider);
        // If the reflection pool is enabled and the transaction is a buy or transfer, then we roll to see if we award any extra tokens
        if(_enableReflectionPool &&  ((!isReflectionPoolExempt[recipient] && (amount >= _poolMinimumSpend && _isBuy)) || (!isReflectionPoolExempt[sender] && (amount >= _poolMinimumTransfer && _isTransfer && _balances[sender] >= _poolMinimumHODL)))){
            uint256 poolReward = calculatePoolReward(_isTransfer); //calculates pool reward based on the buy or wallet-wallet transfer chance
            if (_isBuy){
                if (poolReward > 0) {
                    _poolTransfer(recipient, poolReward); 
                }
                if (_bonusPool > 0 && (random() <= _bonusChance)) {
                    _bonusTransfer(recipient, _bonusPool); //Awards bonus pool from last sells if won
                }
            }
            if (poolReward > 0 && _isTransfer){
                _poolTransfer(sender, poolReward);
            }
        } 
        uint256 amountReceived;
        // limit gas consumption by splitting up operations
        if(shouldSwapBack(_isBuy || _isSell)) { 
            swapBack();
            amountReceived = handleTransferBody(sender, recipient, amount);
            tryToProcess();
        } else if(shouldAutoBuyback(_isBuy || _isSell)) { 
            triggerAutoBuyback(); 
            amountReceived = handleTransferBody(sender, recipient, amount);
            tryToProcess();
        } else {
            amountReceived = handleTransferBody(sender, recipient, amount);
            if(enabledTransferDividends[sender]){
            tryToProcess();
            }
        }
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    /** Takes Associated Fees and sets holders' new Share for the SafeEarn/EarnHub Distributor */
    function handleTransferBody(address sender, address recipient, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender], !disabledTransferEarnings[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient], !disabledTransferEarnings[sender]) {} catch {} }

        return amountReceived;
    }
    /** Basic Transfer with no swaps for BNB -> EarnPay or EarnPay -> BNB */
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        handleTransferBody(sender, recipient, amount);
        return true;
    }
    /** Tries to process */
    function tryToProcess() internal {
        uint256 gasToUse = distributorGas > gasleft() ? gasleft().mul(3).div(4) : distributorGas;
        try distributor.process(gasToUse) {} catch {}
    }
    /** False if sender is Fee Exempt, True if not */
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    /** Takes Proper Fee (10% buys / transfers, 20% on sells, 30% Whale Timer Tax) and delegate reflection pool allocations and store remaining fees in contract */
    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 _bonusPoolAdd;
        uint256 feeAmount = amount.mul(getTotalFee(sender, receiver, amount)).div(feeDenominator);
        uint256 poolAllocation = feeAmount.mul(reflectionpoolFee).div(totalFeeSells); //calculates fees to allocate towards reflection pool
        //if it's a sell allocate 1/2 of the pool allocation for the buy bonus
        _bonusPoolAdd = (receiver == pair) ? poolAllocation.div(2) : 0;
        _bonusPool = _bonusPool.add(_bonusPoolAdd);
        _reflectionPool = _reflectionPool.add(poolAllocation.sub(_bonusPoolAdd)); //transfer pool allocations to reflection pool
        _balances[address(this)] = _balances[address(this)].add(feeAmount.sub(poolAllocation));//remove pool allocations from total fee amount & add to contract balance
        return amount.sub(feeAmount); //subtract total fee amount (including pool allocations)
    }

    function getTotalFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        //Determine if we are 1. Transferring or 2. Selling, otherwise assign the buy Fee as the fee
        bool    _isSelling         = (receiver == pair);
        bool    _isTransfer        = !(sender == pair || _isSelling);
        if(_isTransfer){
            return (isMerchant[sender] || isMerchant[receiver]) ? totalFeeTransfersMerchant : totalFeeTransfers;
        }
        if(_isSelling){ 
            // We will assume that the normal sell tax rate will apply
            uint256 fee = totalFeeSells;
            // Get the time difference in seconds between now and the first sell
            uint delta = block.timestamp.sub(_timeSinceFirstSell[sender]);
            // Get the new total to see if it has spilled over the threshold
            uint256 newTotal = _amountSold[sender].add(amount);
            // If a known wallet started their selling within the whale sell timer window, check if they're trying to spill over the threshold
            // If they are then increase the tax amount
            if (delta > 0 && delta < _whaleSellTimer && _timeSinceFirstSell[sender] != 0) {
                if (newTotal > _whaleSellThreshold) {
                    fee = fee.mul(_whaleFeeMultiplier).div(_whaleFeeDivider); 
                }
                _amountSold[sender] = newTotal;
            } else if (_timeSinceFirstSell[sender] == 0 && newTotal > _whaleSellThreshold) {
                fee = fee.mul(_whaleFeeMultiplier).div(_whaleFeeDivider);
                _amountSold[sender] = newTotal;
            } else {
                // Otherwise we reset their sold amount and timer
                _timeSinceFirstSell[sender] = block.timestamp;
                _amountSold[sender] = amount;
            }
            return fee; }
        return totalFeeBuys;
    }

    /** True if we should swap from EarnPay => BNB, only swapsback during buy/sell to save transfer gas fees */
    function shouldSwapBack(bool _isBuyOrSell) internal view returns (bool) {
        return _isBuyOrSell
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    /**
     *  Swaps EarnPay for BNB if threshold is reached and the swap is enabled
     *  Uses BNB retrieved to:
     *      fuel the contract for buy/burns
     *      provide distributor with BNB for SafeEarn/EarnHub
     *      send to sustaining wallet
     *      add liquidity if liquidity is low
     */
    function swapBack() internal swapping {
        
        // check if we need to add liquidity
        uint256 _totalFeeSells = totalFeeSells.sub(reflectionpoolFee);
        uint256 dynamicLiquidityFee = (isOverLiquified(targetLiquidity, targetLiquidityDenominator) || !shouldPairLiquidity)? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(_totalFeeSells).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        
        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch{}
        // how much BNB did we swap?
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        
        // total amount of BNB to allocate
        uint256 totalBNBFee = _totalFeeSells.sub(dynamicLiquidityFee.div(2));
        // how much bnb is sent to liquidity, reflections, and sustaining
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBSustaining = amountBNB.mul(sustainingFee).div(totalBNBFee);
        // deposit BNB for reflections and sustaining
        transferToDistributorAndSustaining(amountBNBReflection, amountBNBSustaining);
        
        // add liquidity to liquidity pair if we need to, and send to auto liquidity address
        if(amountToLiquify > 0 && shouldPairLiquidity ){
            try router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            ) {} catch {}
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    /** Transfers BNB to SafeEarn/EarnHub Distributor and Sustaining Wallet */
    /** If sustaining is disabled, sustaining fee will go towards distributor for dividend reflections */
    function transferToDistributorAndSustaining(uint256 distributorBNB, uint256 sustainingBNB) internal {
        if (allowTransferToSustaining) {
            try distributor.deposit{value: distributorBNB}() {totalBNBTokenReflections = totalBNBTokenReflections.add(distributorBNB);} catch {}
            (bool successful,) = payable(sustainingFeeReceiver).call{value: sustainingBNB, gas: 30000}("");
            if (successful) {
                totalBNBSustaining = totalBNBSustaining.add(sustainingBNB);
            }
        }
        else {
            try distributor.deposit{value: distributorBNB.add(sustainingBNB)}() {totalBNBTokenReflections = totalBNBTokenReflections.add(distributorBNB).add(sustainingBNB);} catch {}
        }
    }

    /** Should EarnPay buy/burn right now? */
    function shouldAutoBuyback(bool _isBuyOrSell) internal view returns (bool) {
        return _isBuyOrSell
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && address(this).balance >= autoBuybackAmount;
    }
    /** Buy back tokens to make up for buy fee */
    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
    }
    
    /**
     * Buys EarnPay with bnb in the contract and then sends to the dead wallet
     */ 
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp.add(30)
        );
        if (to == DEAD && canChangeSwapThreshold) {
            swapThreshold = getCirculatingSupply().div(swapThresholdPercentOfCirculatingSupply);
        }
    }
    
    /** 0 = process manually | 1 = process with standard gas | Above 1 = process with custom gas limit */
    function manuallyProcessDividends(uint256 distributorGasFee) external {
        if (distributorGasFee == 0) {
            try distributor.processManually() {} catch {}
        } else if (distributorGasFee == 1) {
            try distributor.process(distributorGas) {} catch {}
        } else {
            try distributor.process(distributorGasFee) {} catch {}
        }
    }
    /** Sets Various Fees */
    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _sustainingFee, uint256 _reflectionpoolFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        sustainingFee = _sustainingFee;
        reflectionpoolFee = _reflectionpoolFee;
        totalFeeSells = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_sustainingFee).add(_reflectionpoolFee);
        feeDenominator = _feeDenominator;
        require(totalFeeSells < feeDenominator/2);
        emit SetFees(_liquidityFee, _buybackFee, _reflectionFee, _sustainingFee, _reflectionpoolFee, _feeDenominator);
    }
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit IsFeeExempt(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit IsTxLimitExempt(holder, exempt);
    }
    
    function getIsFeeExempt(address holder) external view returns (bool) {
        return isFeeExempt[holder];
    }
    
    function getIsDividendExempt(address holder) external view returns (bool) {
        return isDividendExempt[holder];
    }
    
    function getIsTxLimitExempt(address holder) external view returns (bool) {
        return isTxLimitExempt[holder];
    }
    
    function setSustainingFeeReceiver(address _sustainingFeeReceiver) external onlyOwner {
        sustainingFeeReceiver = _sustainingFeeReceiver;
        emit SustainingAddressSet(_sustainingFeeReceiver);
    }

    function setAutoLiquidityReceiver(address _autoLiquidityReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        emit AutoLiquidityReceiverSet(_autoLiquidityReceiver);
    }
    
    function setAutoBuybackSettings(bool _enabled, uint256 _amount, uint256 _period) external onlyOwner {
        autoBuybackEnabled = _enabled;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
        emit AutoBuyBackSettingsSet(_enabled, _amount, _period);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, bool changeSwapThreshold, bool shouldAutomateLiquidity, uint256 percentOfCirculatingSupply) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        canChangeSwapThreshold = changeSwapThreshold;
        swapThresholdPercentOfCirculatingSupply = percentOfCirculatingSupply;
        shouldPairLiquidity = shouldAutomateLiquidity;
        emit SwapBackSettingsSet(_enabled, _amount, changeSwapThreshold, shouldAutomateLiquidity, percentOfCirculatingSupply);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
        emit TargetLiquiditySet(_target, _denominator);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToTokenThreshold) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToTokenThreshold);
        emit DistributionCriteriaSet(_minPeriod, _minDistribution, _bnbToTokenThreshold);
    }

    function setDistributorGas(uint256 gas) external onlyOwner {
        require(gas < 1000000);
        distributorGas = gas;
        emit DistributorGasSet(gas);
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 2500);
        _maxTxAmount = amount;
        emit TxLimitSet(amount);
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair && holder != DEAD);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
        emit ExemptFromDividend(holder, exempt);
    }
    /**
     * Buy and Burn EarnPay with bnb stored in contract
     */
    function triggerEarnPayBuyback(uint256 amount) external onlyOwner {
        buyTokens(amount, DEAD);
        emit EarnPayBuyBackAndBurn(amount);
    }

    function setAllowTransferToSustaining(bool _canSendToSustaining) external onlyOwner {
        allowTransferToSustaining = _canSendToSustaining;
        emit EnableTransferToSustaining(_canSendToSustaining);
    }
    
    function setBuyingFee(uint256 buyFee) external onlyOwner {
        totalFeeBuys = buyFee;
        emit BuyFeeUpdated(buyFee);
    }
    function setWalletToWalletFee(uint256 transferFee) external onlyOwner {
        totalFeeTransfers = transferFee;
        emit TransferFeeUpdated(transferFee);
    }
    function setMerchantFee(uint256 merchantFee) external onlyOwner {
        totalFeeTransfersMerchant = merchantFee;
        emit MerchantFeeUpdated(merchantFee);
    }
    function setDexRouter(address nRouter) external onlyOwner{
        _dexRouter = nRouter;
        router = IUniswapV2Router02(nRouter);
        _allowances[address(this)][address(router)] = _totalSupply;
        emit DexRouterUpdated(nRouter);
    }

    function setAutoBuyBack(bool enable) external onlyOwner {
        autoBuybackEnabled = enable;
        emit AutoBuyBackEnabled(enable);
    }
    
    function setTokenContractAddress(address nToken) external onlyOwner {
        distributor.setTokenAddress(nToken);
        emit SwappedTokenAddresses(nToken);
    }
    
    function getBNBQuantityInContract() public view returns(uint256){
        return address(this).balance;
    }
    
    /** Returns the Circulating Supply of EarnPay ( supply not owned by Burn Wallet ) */
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply()) > target;
    }
    
    function getDistributorAddress() external view returns (address) {
        return address(distributor);
    }
    function getTimeSinceFirstSell(address account) external view returns (uint) {
        return _timeSinceFirstSell[account];
    }

    function amountSold(address account) external view returns (uint256) {
        return _amountSold[account];
    }
    function setWhaleSettings(uint256 sellThreshold, uint time, uint8 feeMultiplier, uint8 feeDivider) external onlyOwner() {
        _whaleSellThreshold = sellThreshold;
        _whaleSellTimer = time;
        _whaleFeeMultiplier = feeMultiplier;
        _whaleFeeDivider = feeDivider;
        emit WhaleSettingsSet(sellThreshold, time, feeMultiplier, feeDivider);
    }
    
    function setTokenStatus(bool _status) external onlyOwner {
        isEnabled = _status;
        emit TokenEnabled(_status);
    }

    function setReflectionPool(bool enablePool) external onlyOwner {
        //Allows the contract owner to enable the reflection pool feature
        _enableReflectionPool = enablePool;
        emit ReflectionPoolEnabled(enablePool);
    }

    //Calculates whether the reflection pool is hit using a random number
    function calculatePoolReward(bool _transferring) private returns (uint256) {
        // If the transfer is a buy or wallet-wallet transfer, and the reflection pool is above a certain token threshold, start to award it
        uint256 reward = 0;
        uint256 poolTokens = _reflectionPool;
        uint _cPoolChance = _transferring ? _poolTransferChance : _poolChance;
        if (poolTokens >= _poolThreshold) {
            // Generates a random number between 1 and 1000
            _lastRoll = random(); 
            if(_lastRoll <= _cPoolChance) {
                reward = poolTokens;
            }
        } 
        return reward;
    }
    function getPoolTokens() external view returns (uint256) {
        //Returns the total reflection pool value
        return _reflectionPool;
    }
    function getBonusTokens() external view returns (uint256) {
        return _bonusPool;
    }
    function random() private returns (uint) {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % 1000);
        r = r.add(1);
        _nonce++;
        return r;
    }
    function _poolTransfer(address winner, uint256 reflectionAmount) private {
        _balances[winner] = _balances[winner].add(reflectionAmount);
        _reflectionPool = 0;
        _previousWinner = winner;
        _previousWonAmount = reflectionAmount;
        _previousWinTime = block.timestamp;
        emit PoolAward(winner, reflectionAmount, block.timestamp);
        emit Transfer(address(this), winner, reflectionAmount);
    }
    function _bonusTransfer(address winner, uint256 reflectionAmount) private {
        _balances[winner] = _balances[winner].add(reflectionAmount);
        _bonusPoolEarnings[winner] = _bonusPoolEarnings[winner].add(reflectionAmount);
        _bonusPool = 0;
        emit BonusAward(winner, reflectionAmount);
        emit Transfer(address(this), winner, reflectionAmount);
    }
    function setPoolSettings(uint thresholdDivider, uint minimumSpendDivider, uint minimumHODLDivider, uint buyChance, uint bonusChance, uint walletToWalletChance, uint256 minimumTransfer)external onlyOwner() {
        _poolThresholdDivider = thresholdDivider;
        _poolMinimumSpendDivider = minimumSpendDivider;
        _poolMinimumHODLDivider = minimumHODLDivider;
        _poolChance = buyChance;
        _bonusChance = bonusChance;
        _poolTransferChance = walletToWalletChance;
        _poolMinimumTransfer = minimumTransfer;
        emit PoolSettingsSet(thresholdDivider, minimumSpendDivider, minimumHODLDivider, buyChance, walletToWalletChance, minimumTransfer);
    }
    function getPoolSettings() external view returns (uint, uint, uint, uint, uint, uint256) {
        return (_poolThresholdDivider, _poolMinimumSpendDivider, _poolMinimumHODLDivider, _poolChance, _poolTransferChance, _poolMinimumTransfer);
    }
    function getCurrentPoolThresholds() external view returns (uint256, uint256, uint256) {
        return (_poolThreshold, _poolMinimumSpend, _poolMinimumTransfer);
    }
    function getLastWinner() external view returns (address, uint256, uint) {
        return (_previousWinner, _previousWonAmount, _previousWinTime);
    }
    function getUserQualifiesForPool(address holder) external view returns (bool) {
        return  _enableReflectionPool && !isReflectionPoolExempt[holder] && (_balances[holder] >= _poolMinimumHODL);
    }
    function getQualifiesForPool() external view returns (bool) {
        return  _enableReflectionPool && !isReflectionPoolExempt[msg.sender] && (_balances[msg.sender] >= _poolMinimumHODL);
    }
    function setIsPoolReflectionExempt(address holder, bool isExempt) external onlyOwner {
        isReflectionPoolExempt[holder] = isExempt;
        emit PoolExempt(holder, isExempt);
    }
    function toggleTransferDividends() external {
        enabledTransferDividends[msg.sender] = !enabledTransferDividends[msg.sender];
    }
    function areTransferDividendsEnabled() external view returns (bool) {
        return enabledTransferDividends[msg.sender];
    }
    function toggleTransferEarnings() external {
        disabledTransferEarnings[msg.sender] = !disabledTransferEarnings[msg.sender];
    }
    function areTransferEarningsEnabled() external view returns (bool) {
        return !disabledTransferEarnings[msg.sender];
    }
    function claimReflectionDividend() external returns (bool) {
        distributor.claimDividend();
        return true;
    }
    function getUnpaidReflectionEarnings() external view returns (uint256) {
        return  distributor.getUnpaidEarnings(msg.sender);
    }
    function getTotalReflectionsEarned() external view returns (uint256) {
        return  distributor.getTotalEarned(msg.sender);
    }
    function getUserReflectionsEarned(address holder) external view returns (uint256) {
        return  distributor.getTotalEarned(holder);
    }
    function getTotalBonusEarned() external view returns (uint256) {
        return  _bonusPoolEarnings[msg.sender];
    }
    function getUserBonusEarned(address holder) external view returns (uint256) {
        return _bonusPoolEarnings[holder];
    }
    /** MEANT TO PERMANENTLY BURN AND REMOVE TOKENS FROM CIRCULATION BASED ON AMOUNT SENT TO THIS FUNCTION*/
    function burnTokens(uint256 tokenAmount) external returns(bool){
        require(tokenAmount > 0, 'tokenAmount needs to be greater than 0');
        require(_balances[msg.sender] >= tokenAmount, 'user does not own enough tokens');
        _balances[msg.sender] = _balances[msg.sender].sub(tokenAmount, 'cannot have negative tokens');
        _totalSupply = _totalSupply.sub(tokenAmount, 'total supply cannot be negative');
        internalApprove(_dexRouter, _totalSupply);
        internalApprove(address(pair), _totalSupply);
        emit Transfer(msg.sender, address(0), tokenAmount);
        return true;
    }
    function contributeToRewardPool(uint256 tokenAmount) external returns(bool){
        require(tokenAmount > 0, 'tokenAmount needs to be greater than 0');
        require(_balances[msg.sender] >= tokenAmount, 'user does not own enough tokens');
        _balances[msg.sender] = _balances[msg.sender].sub(tokenAmount, 'cannot have negative tokens');
        _reflectionPool = _reflectionPool.add(tokenAmount);
        emit ContributedToPool(msg.sender, tokenAmount);
        return true;
    }
    function getIsMerchant(address holder) external view returns (bool) {
        return isMerchant[holder];
    }
    function setIsMerchant(address holder, bool isRegisteredMerchant) external onlyOwner {
        isMerchant[holder] = isRegisteredMerchant;
        emit IsMerchant(holder, isRegisteredMerchant);
    }
    event MerchantFeeUpdated(uint256 merchantFee);
    event SetFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _sustainingFee, uint256 _reflectionpoolFee, uint256 _feeDenominator);
    event IsMerchant(address holder, bool isRegisteredMerchant);
    event IsFeeExempt(address holder, bool exempt);
    event IsTxLimitExempt(address holder, bool exempt);
    event SustainingAddressSet(address _sustainingFeeReceiver);
    event AutoLiquidityReceiverSet(address _autoLiquidityReceiver);
    event AutoBuyBackSettingsSet(bool _enabled, uint256 _amount, uint256 _period);
    event SwapBackSettingsSet(bool _enabled, uint256 _amount, bool changeSwapThreshold, bool shouldAutomateLiquidity, uint256 percentOfCirculatingSupply);
    event TargetLiquiditySet(uint256 _target, uint256 _denominator);
    event DistributionCriteriaSet(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToTokenThreshold);
    event DistributorGasSet(uint256 gas);
    event TxLimitSet(uint256 amount);
    event ExemptFromDividend(address holder, bool exempt);
    event EnableTransferToSustaining(bool _canSendToSustaining);
    event BuyFeeUpdated(uint256 buyFee);
    event TransferFeeUpdated(uint256 transferFee);
    event DexRouterUpdated(address nRouter);
    event AutoBuyBackEnabled(bool enable);
    event WhaleSettingsSet(uint256 sellThreshold, uint time, uint8 feeMultiplier, uint8 feeDivider);
    event TokenEnabled(bool _status);
    event ReflectionPoolEnabled(bool enablePool);
    event PoolSettingsSet(uint thresholdDivider, uint minimumSpendDivider, uint minimumHODLDivider, uint buyChance, uint walletToWalletChance, uint256 minimumTransfer);
    event PoolExempt(address holder, bool isExempt);
    event PoolAward(address winner, uint256 amount, uint time);
    event BonusAward(address winner, uint256 amount);
    event ContributedToPool(address sender, uint256 amount);
    event AutoLiquify(uint256 amountBNB, uint256 amountSR);
    event EarnPayBuyBackAndBurn(uint256 amountBNB);
    event SwappedTokenAddresses(address newToken);
}


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @title IERC1363 Interface
 * @dev Interface for a Payable Token contract as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
     * 0x4bbee2df ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
     */

    /*
     * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
     * 0xfb9ec8ce ===
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

/**
 * @title IERC1363Receiver Interface
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4); // solhint-disable-line  max-line-length
}

/**
 * @title IERC1363Spender Interface
 * @dev Interface for any contract that wants to support approveAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Spender {
    /*
     * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
     * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
     */

    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param owner address The address which called `approveAndCall` function
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
     *  unless throwing
     */
    function onApprovalReceived(address owner, uint256 value, bytes calldata data) external returns (bytes4);
}

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


/**
 * @dev Implementation of an ERC1363 interface
 */
contract ERC1363 is ERC20, IERC1363, ERC165 {
    using Address for address;

    /*
     * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
     * 0x4bbee2df ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
     */
    bytes4 internal constant _INTERFACE_ID_ERC1363_TRANSFER = 0x4bbee2df;

    /*
     * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
     * 0xfb9ec8ce ===
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */
    bytes4 internal constant _INTERFACE_ID_ERC1363_APPROVE = 0xfb9ec8ce;

    // Equals to `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC1363Receiver(0).onTransferReceived.selector`
    bytes4 private constant _ERC1363_RECEIVED = 0x88a7ca5c;

    // Equals to `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
    // which can be also obtained as `IERC1363Spender(0).onApprovalReceived.selector`
    bytes4 private constant _ERC1363_APPROVED = 0x7b04a2d0;

    /**
     * @param name Name of the token
     * @param symbol A symbol to be used as ticker
     */
    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
        // register the supported interfaces to conform to ERC1363 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1363_TRANSFER);
        _registerInterface(_INTERFACE_ID_ERC1363_APPROVE);
    }

    /**
     * @dev Transfer tokens to a specified address and then execute a callback on recipient.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferAndCall(address to, uint256 value) public override returns (bool) {
        return transferAndCall(to, value, "");
    }

    /**
     * @dev Transfer tokens to a specified address and then execute a callback on recipient.
     * @param to The address to transfer to
     * @param value The amount to be transferred
     * @param data Additional data with no specified format
     * @return A boolean that indicates if the operation was successful.
     */
    function transferAndCall(address to, uint256 value, bytes memory data) public override returns (bool) {
        transfer(to, value);
        require(_checkAndCallTransfer(_msgSender(), to, value, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another and then execute a callback on recipient.
     * @param from The address which you want to send tokens from
     * @param to The address which you want to transfer to
     * @param value The amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFromAndCall(address from, address to, uint256 value) public override returns (bool) {
        return transferFromAndCall(from, to, value, "");
    }

    /**
     * @dev Transfer tokens from one address to another and then execute a callback on recipient.
     * @param from The address which you want to send tokens from
     * @param to The address which you want to transfer to
     * @param value The amount of tokens to be transferred
     * @param data Additional data with no specified format
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes memory data) public override returns (bool) {
        transferFrom(from, to, value);
        require(_checkAndCallTransfer(from, to, value, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }

    /**
     * @dev Approve spender to transfer tokens and then execute a callback on recipient.
     * @param spender The address allowed to transfer to
     * @param value The amount allowed to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function approveAndCall(address spender, uint256 value) public override returns (bool) {
        return approveAndCall(spender, value, "");
    }

    /**
     * @dev Approve spender to transfer tokens and then execute a callback on recipient.
     * @param spender The address allowed to transfer to.
     * @param value The amount allowed to be transferred.
     * @param data Additional data with no specified format.
     * @return A boolean that indicates if the operation was successful.
     */
    function approveAndCall(address spender, uint256 value, bytes memory data) public override returns (bool) {
        approve(spender, value);
        require(_checkAndCallApprove(spender, value, data), "ERC1363: _checkAndCallApprove reverts");
        return true;
    }

    /**
     * @dev Internal function to invoke `onTransferReceived` on a target address
     *  The call is not executed if the target address is not a contract
     * @param from address Representing the previous owner of the given token value
     * @param to address Target address that will receive the tokens
     * @param value uint256 The amount mount of tokens to be transferred
     * @param data bytes Optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkAndCallTransfer(address from, address to, uint256 value, bytes memory data) internal returns (bool) {
        if (!to.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Receiver(to).onTransferReceived(
            _msgSender(), from, value, data
        );
        return (retval == _ERC1363_RECEIVED);
    }

    /**
     * @dev Internal function to invoke `onApprovalReceived` on a target address
     *  The call is not executed if the target address is not a contract
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkAndCallApprove(address spender, uint256 value, bytes memory data) internal returns (bool) {
        if (!spender.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(
            _msgSender(), value, data
        );
        return (retval == _ERC1363_APPROVED);
    }
}

/**
 * @dev Allow to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

contract EarnPay is ERC1363, TokenRecover {
    constructor ()
        ERC1363("EarnPay", "PAY")
    {
    }
}