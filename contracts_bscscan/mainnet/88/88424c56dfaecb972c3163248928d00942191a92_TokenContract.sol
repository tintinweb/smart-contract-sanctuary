/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

/**Cashio Token is built upon the fundamentals of Deflation, Reflections, Distribution, Buy-Back, LP Acquisition
    
Main features by default are:

1) 3% Liquidity
2) 3% Token Reflections 
3) 4% Jackpot Lotto Game in BNB
4) 5% Team/Marketing/Development in BNB
5) 7.77% Distributions in BNB
6) 10.23% Buy-Back System
7) Max Wallet up to 1.5% of totat Supply
8) Max Buy/Sell 0.2% of total Supply
9) 65% of Cashio Casino Earnings Distributed to Cashio Token Holders

                                                                     $$
  
 $$$$$$$       $$        $$$$$$$   $$      $$  $$   $$$$$$$$         $$   $$$$$$$$ 
$$            $$$$      $$         $$      $$  $$  $$      $$        $$  $$      $$
$$           $$  $$      $$$$$$$   $$      $$  $$  $$      $$        $$  $$      $$
$$          $$$$$$$$           $$  $$$$$$$$$$  $$  $$      $$        $$  $$      $$
$$         $$      $$          $$  $$      $$  $$  $$      $$  $$$$  $$  $$      $$
 $$$$$$$  $$        $$  $$$$$$$$   $$      $$  $$   $$$$$$$$   $$$$  $$   $$$$$$$$ 
 
 
 On every Buy -----> Tokens are deducted from the fee ( 15% by default ) -----> 3% goes to liquidity -----> 3 % Token Reflections
 -----> 9% of Tokens are swapped back to BNB when Tokens are > 77,700 ( Default Threshold ) 5% goes to Team/Marketing/Development Wallet
 and 4% goes to Jackpot Wallet.
 
 On every Sell -----> Tokens are deducted from the fee ( 21% by default ) -----> 3% goes to liquidity -----> 18% of Tokens are swapped 
 back to BNB when Tokens are > 77,700 ( Default Threshold ) 7,77% goes to BNB distribution system and 10,23% goes to the Buy-Back System.
 
 Buy-Back System is triggered automatically when BNB > 0.02 ( by default ) -----> goes through a new Buy Fee ----> 40% of Tokens are 
 swapped back to BNB when Tokens are > 77,700 ( Default Threshold ) 25% goes to Team/Marketing/Development Wallet and 15% goes to 
 Jackpot Wallet.
 Remaining 60% of Tokens are divided into ( by default ) -----> 36% goes to Team/Marketing/Development -----> 24% goes to Burn Address 
 
  
*/
pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 lastTimeClaim;
    }

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 0;
    uint256 public minTokenToReceiveReward = 77700 * (10 ** 18);

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor() public {
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minTokenForReceiveReward) external override onlyToken {
        minPeriod = _minPeriod;
        minTokenToReceiveReward = _minTokenForReceiveReward;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        uint256 finalAmount = amount;
        if(amount < minTokenToReceiveReward && shares[shareholder].amount > 0){
            finalAmount = 0;
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(finalAmount);
        shares[shareholder].amount = finalAmount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable override{
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            (bool success,) = payable(shareholder).call{value: amount, gas: 3000}("");
            if(success){
                totalDistributed = totalDistributed.add(amount);
                shares[shareholder].lastTimeClaim  = block.timestamp;
                shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            }
        }
    }
    
    function claimReward(address shareholder) external onlyToken{
        require(shares[shareholder].lastTimeClaim + minPeriod <= block.timestamp, "You are only able to take reward once every 12 hours");
        require(shares[shareholder].amount >= minTokenToReceiveReward, "Please check minimum token amount to receive reward");
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getLastTimeClaim(address shareholder)public view returns (uint256) {
        return shares[shareholder].lastTimeClaim;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }
}

contract TokenContract is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private isWalletLimitExempt;
    mapping (address => bool) private isTxLimitExempt;
    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isDividendExempt;
    address[] private dividendExempt;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 777777777 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tTokenDistributionTotal;

    string private _name = "Cashio.io";
    string private _symbol = "CASHIO";
    uint8 private _decimals = 18;

    bool public enabledFee = true;
    uint256 public _PERCENR_NOMINATOR = 10000; // 100%
    uint256 public _buyFeeTokenDistribution = 300; // 3%
    uint256 public _buyFeeLiquid = 300; // 3%
    uint256 public _buyFeeMarketing = 500; // 5%
    uint256 public _buyFeeJackpot = 400; // 4%

    uint256 public _sellFeeBNBDistribution = 777; // 7.77%
    uint256 public _sellFeeLiquid = 300; // 3%
    uint256 public _sellFeeBuyback = 1023; // 10.23%

    uint256 public _bbFeeMarketingBNB = 2500; // 25%
    uint256 public _bbFeeJackpot = 1500; // 15%
    uint256 public _bbFeeBurn = 2400; //24%
    uint256 public _bbFeeMarketingToken= 3600; //36%

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _buybackThreshold = 2 * 10**16; // 0.02 BNB
    uint256 public _maxTxAmount = _tTotal / 500;
    uint256 public _swapThreshold = 77700 * 10**18;
    uint256 public _maxWalletAmount = _tTotal / 100;

    address public walletMarketing;
    address public walletJackpot;
    address walletDEAD = 0x000000000000000000000000000000000000dEaD;
    

    uint256 accumulatedAmountTokenForBNBDistribution;
    uint256 accumulatedAmountTokenForBuyback;
    uint256 accumulatedAmountTokenForLiquidity;
    uint256 accumulatedAmountTokenForMarketingAndJackport;

    uint256 accumulatedBNBReward;
    uint256 accumulatedBNBBuyBack;

    uint256 lastTimeAddToReward;
    uint256 rewardPeriod = 12 hours;

    DividendDistributor public distributor;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () public {

        distributor = new DividendDistributor();

        _rOwned[_msgSender()] = _rTotal;
        
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        walletMarketing = _msgSender();
        walletJackpot = _msgSender();
        
        //exclude owner and this contract from fee
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        
        isWalletLimitExempt[uniswapV2Pair] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[walletDEAD] = true;
        
        isDividendExempt[uniswapV2Pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[walletDEAD] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (isDividendExempt[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return isDividendExempt[account];
    }

    function totalDistributedToken() public view returns (uint256) {
        return _tTokenDistributionTotal;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function setIsDividendExempt(address account, bool exempt) public onlyOwner() {
        if(exempt){
            require(!isDividendExempt[account], "Account is already excluded");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            distributor.setShare(account, 0);
            isDividendExempt[account] = true;
            dividendExempt.push(account);
        }else {
            require(isDividendExempt[account], "Account is already included");
            for (uint256 i = 0; i < dividendExempt.length; i++) {
                if (dividendExempt[i] == account) {
                    dividendExempt[i] = dividendExempt[dividendExempt.length - 1];
                    _tOwned[account] = 0;
                    isDividendExempt[account] = false;
                    dividendExempt.pop();
                    break;
                }
            }
            distributor.setShare(account, balanceOf(account));
        }
    }

    function setIsFeeExempt(address account, bool exempt) public onlyOwner {
        isFeeExempt[account] = exempt;
    }

    function setIsTxLimitExempt(address account, bool exempt) public onlyOwner {
        isTxLimitExempt[account] = exempt;
    } 

    function setIsWalletLimitExempt(address account, bool exempt) public onlyOwner {
        isWalletLimitExempt[account] = exempt;
    }

    function setIsMaxWalletExempt(address account, bool exempt) public onlyOwner {
        isWalletLimitExempt[account] = exempt;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        require(balanceOf(recipient).add(amount) <= _maxWalletAmount || isWalletLimitExempt[recipient], "Wallet Amount Limit Exceeded");
    }

    function setWalletAmountLimit(uint256 amount) public onlyOwner {
        require(amount >= _tTotal/1000, "Check minimum Wallet amount");
        _maxWalletAmount = amount;
    }
   
    function setMaxTxAmount(uint256 amount) external onlyOwner() {
        require(amount >= _tTotal/1000, "MaxTX amount must be higher");
        _maxTxAmount = amount;
    }

    function setSwapThreshold(uint256 amount) external onlyOwner() {
        _swapThreshold = amount;
    }

    function setBuybackThreshold(uint256 amount) external onlyOwner() {
        _buybackThreshold = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _reflectTokenDistribution(uint256 rTokenDistributionFee, uint256 tTokenDistributionFee) private {
        _rTotal = _rTotal.sub(rTokenDistributionFee);
        _tTokenDistributionTotal = _tTokenDistributionTotal.add(tTokenDistributionFee);
    }

    function _getValues(uint256 tAmount, bool takeFee, bool isSelling) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getTValues(tAmount, takeFee, isSelling);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee) = _getRValues(tAmount, tTokenDistributionFee, tTotalFeeExceptTokenDistribution, _getRate());
        return (rAmount, rTransferAmount, rTokenDistributionFee, tTransferAmount, tTokenDistributionFee, tTotalFeeExceptTokenDistribution);
    }

    function _getTValues(uint256 tAmount, bool takeFee, bool isSelling) private view returns (uint256, uint256, uint256) {
        uint256 tTokenDistributionFee = 0;
        uint256 tTotalFeeExceptTokenDistribution = 0;
        if(takeFee){
            if(isSelling){
                tTotalFeeExceptTokenDistribution = (_sellFeeBNBDistribution.add(_sellFeeBuyback).add(_sellFeeLiquid)).mul(tAmount).div(_PERCENR_NOMINATOR);
            }else {
                tTotalFeeExceptTokenDistribution = (_buyFeeLiquid.add(_buyFeeMarketing).add(_buyFeeJackpot)).mul(tAmount).div(_PERCENR_NOMINATOR);
                tTokenDistributionFee = tAmount.mul(_buyFeeTokenDistribution).div(_PERCENR_NOMINATOR);
            }
        }
        uint256 tTransferAmount = tAmount.sub(tTokenDistributionFee).sub(tTotalFeeExceptTokenDistribution);
        return (tTransferAmount, tTokenDistributionFee, tTotalFeeExceptTokenDistribution);
    }

    function _getRValues(uint256 tAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTokenDistributionFee = tTokenDistributionFee.mul(currentRate);
        uint256 rTotalFeeExceptTokenDistribution = tTotalFeeExceptTokenDistribution.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTokenDistributionFee).sub(rTotalFeeExceptTokenDistribution);
        return (rAmount, rTransferAmount, rTokenDistributionFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < dividendExempt.length; i++) {
            if (_rOwned[dividendExempt[i]] > rSupply || _tOwned[dividendExempt[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[dividendExempt[i]]);
            tSupply = tSupply.sub(_tOwned[dividendExempt[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeAllFeeExceptTokenDistribution(uint256 tTotalFeeExceptTokenDistribution, bool isSelling) private {
        if(tTotalFeeExceptTokenDistribution > 0){
            if(isSelling){
                uint256 numBnbDistr = tTotalFeeExceptTokenDistribution.mul(_sellFeeBNBDistribution).div(_sellFeeBNBDistribution.add(_sellFeeBuyback).add(_sellFeeLiquid));
                uint256 numLiquid = tTotalFeeExceptTokenDistribution.mul(_sellFeeLiquid).div(_sellFeeBNBDistribution.add(_sellFeeBuyback).add(_sellFeeLiquid));
                uint256 numBuyback = tTotalFeeExceptTokenDistribution.sub(numBnbDistr.add(numLiquid));

                accumulatedAmountTokenForBNBDistribution = accumulatedAmountTokenForBNBDistribution.add(numBnbDistr);
                accumulatedAmountTokenForLiquidity = accumulatedAmountTokenForLiquidity.add(numLiquid);
                accumulatedAmountTokenForBuyback = accumulatedAmountTokenForBuyback.add(numBuyback);
                
                //Token for BNB distribution, liquidity & buyback are kept in token contract
                sendToken(address(this), tTotalFeeExceptTokenDistribution);
            }else {
                uint256 numLiquid = tTotalFeeExceptTokenDistribution.mul(_buyFeeLiquid).div(_buyFeeLiquid.add(_buyFeeMarketing).add(_buyFeeJackpot));
                uint256 numMarketingAndJackpot = tTotalFeeExceptTokenDistribution.sub(numLiquid);

                //Token for Liquidity, Marketing & Jackpot are kept in token contract
                accumulatedAmountTokenForLiquidity = accumulatedAmountTokenForLiquidity.add(numLiquid);
                accumulatedAmountTokenForMarketingAndJackport = accumulatedAmountTokenForMarketingAndJackport.add(numMarketingAndJackpot);
                sendToken(address(this), tTotalFeeExceptTokenDistribution);
            }
        }
    }

    function sendToken(address to, uint256 amount) internal{
        uint256 currentRate =  _getRate();
        uint256 rAmount = amount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if(isDividendExempt[to])
            _tOwned[to] = _tOwned[to].add(amount);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return isFeeExempt[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _maxTxAmount || isTxLimitExempt[from], "Transfer amount exceeds the maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _swapThreshold;
        if (
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            if(overMinTokenBalance){
                swapBack(contractTokenBalance);
            } else if (accumulatedBNBBuyBack >= _buybackThreshold){
                buyback();
            }
        }

        if(lastTimeAddToReward != 0 && lastTimeAddToReward + rewardPeriod < block.timestamp){
            //Send 50% to reward distributor every 12 hours
            uint256 halfBNBReward = accumulatedBNBReward.div(2);
            try distributor.deposit{value: halfBNBReward}() {} catch {}
            lastTimeAddToReward = block.timestamp;
            accumulatedBNBReward = accumulatedBNBReward.sub(halfBNBReward);
        }
        
        _tokenTransfer(from,to,amount);
    }

    function buyback() private lockTheSwap{
        uint256 bbBNBForMakerting = accumulatedBNBBuyBack.mul(_bbFeeMarketingBNB).div(_PERCENR_NOMINATOR);
        uint256 bbBNBForJackpot = accumulatedBNBBuyBack.mul(_bbFeeJackpot).div(_PERCENR_NOMINATOR);
        uint256 bbBNBForBurn = accumulatedBNBBuyBack.mul(_bbFeeBurn).div(_PERCENR_NOMINATOR);
        uint256 bbBNBForMarketingToken = accumulatedBNBBuyBack.sub(bbBNBForMakerting.add(bbBNBForJackpot).add(bbBNBForBurn));

        payable(walletMarketing).transfer(bbBNBForMakerting);
        payable(walletJackpot).transfer(bbBNBForJackpot);
        buyTokens(bbBNBForBurn, walletDEAD);
        buyTokens(bbBNBForMarketingToken, walletMarketing);

        //Reset accumulated BNB for buyback.
        accumulatedBNBBuyBack = 0;
    }

    function swapBack(uint256 contractTokenBalance) private lockTheSwap {

        uint256 amountLiquid = contractTokenBalance.mul(accumulatedAmountTokenForLiquidity).div(accumulatedAmountTokenForBNBDistribution + accumulatedAmountTokenForBuyback + accumulatedAmountTokenForLiquidity + accumulatedAmountTokenForMarketingAndJackport);
        uint256 amountBNBDis = contractTokenBalance.mul(accumulatedAmountTokenForBNBDistribution).div(accumulatedAmountTokenForBNBDistribution + accumulatedAmountTokenForBuyback + accumulatedAmountTokenForLiquidity + accumulatedAmountTokenForMarketingAndJackport);
        uint256 amountMarketingJackpot = contractTokenBalance.mul(accumulatedAmountTokenForMarketingAndJackport).div(accumulatedAmountTokenForBNBDistribution + accumulatedAmountTokenForBuyback + accumulatedAmountTokenForLiquidity + accumulatedAmountTokenForMarketingAndJackport);
        uint256 amountBuyback = contractTokenBalance.sub(amountLiquid + amountBNBDis + amountMarketingJackpot);
        // split the contract balance into halves
        uint256 halfLiquid = amountLiquid.div(2);
        uint256 otherHalfLiquid = amountLiquid.sub(halfLiquid);

        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(amountBNBDis + amountBuyback + halfLiquid + amountMarketingJackpot); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 swapBalance = address(this).balance.sub(initialBalance);
        accumulatedAmountTokenForBNBDistribution = 0;
        accumulatedAmountTokenForBuyback = 0;
        accumulatedAmountTokenForLiquidity = 0;
        accumulatedAmountTokenForMarketingAndJackport = 0;

        uint256 bnbLiqid = swapBalance.mul(halfLiquid).div(amountBNBDis + amountBuyback + amountMarketingJackpot + halfLiquid);
        uint256 bnbReward = swapBalance.mul(amountBNBDis).div(amountBNBDis + amountBuyback + amountMarketingJackpot + halfLiquid);
        uint256 bnbMarketingJackpot = swapBalance.mul(amountMarketingJackpot).div(amountBNBDis + amountBuyback + amountMarketingJackpot + halfLiquid);
        uint256 bnbBuyback = swapBalance.sub(bnbLiqid + bnbReward + bnbMarketingJackpot);

        accumulatedBNBReward = accumulatedBNBReward.add(bnbReward);
        if(lastTimeAddToReward == 0){
            lastTimeAddToReward = block.timestamp;
        }
        accumulatedBNBBuyBack = accumulatedBNBBuyBack.add(bnbBuyback);

        // Send marketing & jackpot fee
        uint256 bnbMarketing = bnbMarketingJackpot.mul(_buyFeeMarketing).div(_buyFeeMarketing.add(_buyFeeJackpot));
        uint256 bnbJackport = bnbMarketingJackpot.sub(bnbMarketing);
        payable(walletMarketing).transfer(bnbMarketing);
        payable(walletJackpot).transfer(bnbJackport);

        // add liquidity to uniswap
        if(otherHalfLiquid > 0 && bnbLiqid > 0){
            addLiquidity(otherHalfLiquid, bnbLiqid);
            emit SwapAndLiquify(halfLiquid, bnbLiqid, otherHalfLiquid);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function buyTokens(uint256 ethAmount, address receiver) internal{
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

        //indicates if fee should be deducted from transfer
        bool takeFee = enabledFee;
        //if any account belongs to isFeeExempt account then remove the fee
        if(isFeeExempt[sender] || isFeeExempt[recipient]){
            takeFee = false;
        }

        bool isSelling = recipient == address(uniswapV2Pair) ? true : false;
        
        if (isDividendExempt[sender] && !isDividendExempt[recipient]) {
            _transferFromExcluded(sender, recipient, amount, takeFee, isSelling);
        } else if (!isDividendExempt[sender] && isDividendExempt[recipient]) {
            _transferToExcluded(sender, recipient, amount, takeFee, isSelling);
        } else if (!isDividendExempt[sender] && !isDividendExempt[recipient]) {
            _transferStandard(sender, recipient, amount, takeFee, isSelling);
        } else if (isDividendExempt[sender] && isDividendExempt[recipient]) {
            _transferBothExcluded(sender, recipient, amount, takeFee, isSelling);
        } else {
            _transferStandard(sender, recipient, amount, takeFee, isSelling);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSelling) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee, uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getValues(tAmount, takeFee, isSelling);
        checkWalletLimit(recipient, tTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeAllFeeExceptTokenDistribution(tTotalFeeExceptTokenDistribution, isSelling);
        _reflectTokenDistribution(rTokenDistributionFee, tTokenDistributionFee);
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSelling) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee, uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getValues(tAmount, takeFee, isSelling);
        checkWalletLimit(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAllFeeExceptTokenDistribution(tTotalFeeExceptTokenDistribution, isSelling);
        _reflectTokenDistribution(rTokenDistributionFee, tTokenDistributionFee);
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSelling) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee, uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getValues(tAmount, takeFee, isSelling);
        checkWalletLimit(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeAllFeeExceptTokenDistribution(tTotalFeeExceptTokenDistribution, isSelling);
        _reflectTokenDistribution(rTokenDistributionFee, tTokenDistributionFee);
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSelling) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee, uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getValues(tAmount, takeFee, isSelling);
        checkWalletLimit(recipient, tTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeAllFeeExceptTokenDistribution(tTotalFeeExceptTokenDistribution, isSelling);
        _reflectTokenDistribution(rTokenDistributionFee, tTokenDistributionFee);
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function getUnpaidEarnings(address account)  public view returns (uint256){
        return distributor.getUnpaidEarnings(account);
    }

    function getLastTimeClaim(address account)  public view returns (uint256){
        return distributor.getLastTimeClaim(account);
    }

    function claimReward() public {
        return distributor.claimReward(msg.sender);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minTokenForReceiveReward) public onlyOwner{
        distributor.setDistributionCriteria(_minPeriod, _minTokenForReceiveReward);
    }

    function updateBuyFee(uint256 tokenDistributionFee, uint256 liquidFee, uint256 marketingFee, uint256 jackpotFee) public onlyOwner {
        _buyFeeTokenDistribution = tokenDistributionFee;
        _buyFeeLiquid = liquidFee;
        _buyFeeMarketing = marketingFee;
        _buyFeeJackpot = jackpotFee;
    }

    function updateSellFee(uint256 liquidFee, uint256 bnbDistributionFee, uint256 buybackFee) public onlyOwner {
        _sellFeeLiquid = liquidFee;
        _sellFeeBNBDistribution = bnbDistributionFee;
        _sellFeeBuyback = buybackFee;
    }

    function updateBuyBackFee(uint256 marketingBNBFee, uint256 jackpotFee, uint256 burnFee, uint256 marketingTokenFee) public onlyOwner {
        require(marketingBNBFee + jackpotFee + burnFee + marketingTokenFee == _PERCENR_NOMINATOR, "Total buyback fee must be 10000");
        _bbFeeMarketingBNB = marketingBNBFee;
        _bbFeeJackpot = jackpotFee;
        _bbFeeBurn = burnFee;
        _bbFeeMarketingToken = marketingTokenFee;
    }

    function enableFeeSystem(bool enabled) public onlyOwner{
        enabledFee =  enabled;
    }

    function updateWalletJackpot(address newJackpot) public onlyOwner {
        walletJackpot = newJackpot;
    }

    function updateWalletMarketing(address newMarketing) public onlyOwner {
        walletMarketing = newMarketing;
    }
}