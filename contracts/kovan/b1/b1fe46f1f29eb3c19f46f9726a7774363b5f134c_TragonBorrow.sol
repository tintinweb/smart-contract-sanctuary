/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

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

interface IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
	
	event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
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
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for BEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IPancakeFactory {
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

interface IPancakePair {
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

interface TragonControllers {
    function getTragonAddressConfig() external view returns (
		address _tgn
		,address _wbnb
		,address _busd
		,address _poolAddress
		,address _treasurryddress
	);
	
	function getTragonFeeConfig() external view returns (
		uint256 _applyFee
		,uint256 _borrowFee
		,uint256 _interestRate
		,uint256 _interestFee
		,uint256 _tgnHold
	);
	
	function applyLend(uint256 _bid, address account) external;
	function payLoan(uint256 _lid) external;
	function getTokenRegistered(address _tokenAddress) external view returns (bool);
}

interface TragonPoolReward {
    function deposit(address account,uint256 _amount) external;
    function withdraw(address account,uint256 _amount) external;
}

interface TragonLend {
    function getLendData(uint256 _lid) external view returns (
		address account
		,address collateralTokenAddress
		,uint256 collateralAmount
		,uint256 lendAmount
		,bool lendActive
		,bool lendFinish
	);
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a pBEPetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

contract Ownable {
   address payable public _owner;
	   
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

}

contract TragonBorrow is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
	
	IPancakeFactory private pancakeFactory;
    IPancakeRouter02 private pancakeRouter;
    TragonControllers public controller;
	TragonPoolReward public poolAddress;
	TragonLend public lendAddress;
	address public treasurryddress;

	address internal tgn;
	address internal wbnb;
	address internal busd;
	
    uint256 private _weiDecimal = 18;
    uint256 private _divRate = 10000;
    uint256 private applyFee;
    uint256 private borrowFee;
    uint256 private interestRate;
    uint256 private interestFee;
    uint256 private minBorrow;
    uint256 private maxBorrow;
    
	struct BorrowData {
        address account;
        address lender;
        address collateralTokenAddress;
        uint256 collateralAmount;
        uint256 borrowAmount;
        uint256 borrowPeriod;
        uint256 borrowStart;
        uint256 borrowEnd;
        uint256 borrowBroadcast;
        uint256 lendId;
        bool borrowActive;
        bool borrowFinish;
    }
	
	uint256 public borrowId;	
	uint256 internal lastIndexFinishId = 0;
	uint256[] internal allBorrowIds;
	
	mapping (address => uint256[]) public borrowsByAddress;
    mapping (uint256 => BorrowData) public borrowData;
    mapping (address => mapping(address => uint256)) public walletTokenBalance;
	mapping(address => uint256) public tokenBalance;
	
	event ApplyBorrow(address TokenCollateral, uint256 BorrowAmount, uint256 CollateralAmount, uint256 BorrowPeriod);
	event CancelBorrow(address TokenCollateral, uint256 BorrowAmount, uint256 CollateralAmount, uint256 BorrowPeriod);

    constructor (
		address _controller
		, uint256 _minBorrow
		, uint256 _maxBorrow
	) public Ownable() {
		pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pancakeFactory = IPancakeFactory(pancakeRouter.factory());
		
		controller = TragonControllers(_controller);
		
		minBorrow = _minBorrow;
		maxBorrow = _maxBorrow;
		
		address _poolAddress;
		
		(tgn, wbnb, busd, _poolAddress, treasurryddress) = controller.getTragonAddressConfig();
		(applyFee, borrowFee, interestRate, interestFee, ) = controller.getTragonFeeConfig();
	
		poolAddress = TragonPoolReward(_poolAddress);
	}	
		
	modifier onlyController() {
        require(isController(), "caller is not the controller");
        _;
    }

    function isController() public view returns (bool) {
        return msg.sender == address(controller);
    }
	
	function setLendAddress(address _lendAddress) external onlyOwner {
		lendAddress = TragonLend(_lendAddress);
	}
	
	function getAllBorrowIds() view public returns (uint256[] memory) {
        return allBorrowIds;
    }
	
	function getBorrowsByAddress(address _borrowAddress) view public returns (uint256[] memory) {
        return borrowsByAddress[_borrowAddress];
    }
	
	function getBorrowData(uint256 _bid) view public returns (address, address, uint256, uint256, bool, bool) {		
	   return(
			borrowData[_bid].account
			,borrowData[_bid].collateralTokenAddress
			,borrowData[_bid].collateralAmount
			,borrowData[_bid].borrowAmount
			,borrowData[_bid].borrowActive
			,borrowData[_bid].borrowFinish
		);
    }
	
	function getBorrowPeriod(uint256 _bid) view public returns (uint256, uint256, uint256, uint256) {		
	   return(
			borrowData[_bid].borrowPeriod
			,borrowData[_bid].borrowStart
			,borrowData[_bid].borrowEnd
			,borrowData[_bid].borrowBroadcast
		);
    }
	
	function applyBorrow(
		address _tokenCollateral
		, uint256 _borrowAmount
		, uint256 _borrowPeriod
	) external returns (uint256 _id) {
		_id = _applyBorrow(_tokenCollateral, msg.sender, _borrowAmount, _borrowPeriod);
	}
	
	function applyBorrowController(
		address _tokenCollateral
		, address account
		, uint256 _borrowAmount
		, uint256 _borrowPeriod
	) external onlyController returns (uint256 _id) {
		_id = _applyBorrow(_tokenCollateral, account, _borrowAmount, _borrowPeriod);
	}
	
	function _applyBorrow(
		address _tokenCollateral
		, address account
		, uint256 _borrowAmount
		, uint256 _borrowPeriod
	) internal returns (uint256 _id) {
		require(controller.getTokenRegistered(_tokenCollateral), 'Token not registered');
		require(_borrowAmount >= minBorrow, 'not meet the min borrow amount');
		require(_borrowAmount <= maxBorrow, 'not meet the max borrow amount');
		require(_borrowPeriod >= 86400, 'min period is 1 day');
		require(_borrowPeriod % 86400 == 0, "period need to be multiple of 1 day" );
		require(_borrowPeriod <= 2419200, 'max period is 28 days');
		
		uint256 enteranceFee = _getEnteranceFee();
		uint256 collateralAmount = _getCollateralAmount(_tokenCollateral, _borrowAmount);
		require(collateralAmount > 0, 'Liquidity is too low');
		
		uint256 userBalance = IBEP20(tgn).balanceOf(account);
		require(userBalance >= enteranceFee, 'Balance insufficient');
		
		IBEP20(tgn).safeTransferFrom(account, address(this), enteranceFee);
		IBEP20(tgn).safeTransfer(address(poolAddress), enteranceFee);
		
		userBalance = IBEP20(_tokenCollateral).balanceOf(account);
		require(userBalance >= collateralAmount, 'Balance insufficient');
		
		IBEP20(_tokenCollateral).safeTransferFrom(account, address(this), collateralAmount);
		
		_id = ++borrowId;
		
        borrowData[_id].account = account;
        borrowData[_id].collateralTokenAddress = _tokenCollateral;
        borrowData[_id].collateralAmount = _getReverseTokenAmount(_tokenCollateral, collateralAmount);
		borrowData[_id].borrowAmount = _borrowAmount;
		borrowData[_id].borrowPeriod = _borrowPeriod;
		borrowData[_id].borrowBroadcast = now;
		
		poolAddress.deposit(account, _borrowAmount);
		
        allBorrowIds.push(_id);
        borrowsByAddress[account].push(_id);
		walletTokenBalance[_tokenCollateral][account] += _getReverseTokenAmount(_tokenCollateral, collateralAmount);
		tokenBalance[_tokenCollateral] += _getReverseTokenAmount(_tokenCollateral, collateralAmount);
		
		emit ApplyBorrow(_tokenCollateral, _borrowAmount, collateralAmount, _borrowPeriod);
	}		
	
	function cancelBorrow(
		uint256 _bid
	) external {
		 require(msg.sender == borrowData[_bid].account, 'Can cancel by Borrower Address only');
		 _cancelBorrow(_bid);
	}	
	
	function cancelBorrowController(
		uint256 _bid
	) external onlyController{
		 _cancelBorrow(_bid);
	}	
	
	function _cancelBorrow(
		uint256 _bid
	) internal {
		 require(!borrowData[_bid].borrowActive, 'cant cancel, Borrow is active');
		 require(!borrowData[_bid].borrowFinish, 'cant cancel, Borrow is finish');
		 
		 borrowData[_bid].borrowFinish = true;
		 IBEP20(borrowData[_bid].collateralTokenAddress).safeTransfer(borrowData[_bid].account, _getTokenAmount(borrowData[_bid].collateralTokenAddress, borrowData[_bid].collateralAmount));
		 poolAddress.withdraw(borrowData[_bid].account, borrowData[_bid].borrowAmount);
		 
		 walletTokenBalance[borrowData[_bid].collateralTokenAddress][borrowData[_bid].account] -= borrowData[_bid].collateralAmount;
		 tokenBalance[borrowData[_bid].collateralTokenAddress] -= borrowData[_bid].collateralAmount;
		
		 emit CancelBorrow(borrowData[_bid].collateralTokenAddress, borrowData[_bid].borrowAmount, borrowData[_bid].collateralAmount, borrowData[_bid].borrowPeriod);
	}	
	
	function applyLend(
		uint256 _bid
	) external {
		require(!borrowData[_bid].borrowActive, 'cant apply, Borrow is active');
		require(!borrowData[_bid].borrowFinish, 'cant apply, Borrow is finish');
		
		controller.applyLend(_bid, msg.sender);
	}	
	
	function applyLendController(
		uint256 _bid
		,uint256 _lid
	) external onlyController {
		require(!borrowData[_bid].borrowActive, 'cant apply, Borrow is active');
		require(!borrowData[_bid].borrowFinish, 'cant apply, Borrow is finish');
		
		_applyLend(_bid, _lid);
	}	
	
	function _applyLend(
		uint256 _bid
		,uint256 _lid
	) internal {
		require(!borrowData[_bid].borrowActive, 'cant apply, Borrow is active');
		require(!borrowData[_bid].borrowFinish, 'cant apply, Borrow is finish');
		
		(address lender, , , , ,) = lendAddress.getLendData(_lid);
			
		uint256 borrowStart = now;
		
		borrowData[_bid].borrowActive = true;
		borrowData[_bid].lender = lender;
		borrowData[_bid].borrowStart = borrowStart;
		borrowData[_bid].borrowEnd = borrowStart + borrowData[_bid].borrowPeriod;
		borrowData[_bid].lendId = _lid;
	}	
	
	function payLoan (
		uint256 _bid
	) external {
		require(msg.sender == borrowData[_bid].account, 'Can pay by Borrower Address only');
		require(borrowData[_bid].borrowActive, 'cant pay, Borrow is not active');
		require(!borrowData[_bid].borrowFinish, 'cant pay, Borrow is finish');
		
		uint256 interestFeeAmount = getInterestFee(_bid);
		uint256 totalPayAmount = borrowData[_bid].borrowAmount + interestFeeAmount;
		
		uint256 userBalance = IBEP20(busd).balanceOf(msg.sender);
		require(userBalance >= totalPayAmount, 'Balance insufficient');
		
		IBEP20(busd).safeTransferFrom(msg.sender, address(this), totalPayAmount);
		IBEP20(borrowData[_bid].collateralTokenAddress).safeTransfer(borrowData[_bid].account, _getTokenAmount(borrowData[_bid].collateralTokenAddress, borrowData[_bid].collateralAmount));
		
		IBEP20(busd).safeTransfer(borrowData[_bid].lender, borrowData[_bid].borrowAmount);
		if(interestFeeAmount > 0){
			uint256 feeAmount = 0;
			if(interestFee > 0){
				feeAmount = interestFeeAmount * interestFee / _divRate;
			}
			
			uint256 interestAmount = interestFeeAmount - feeAmount;
			IBEP20(busd).safeTransfer(borrowData[_bid].lender, interestAmount);
			
			if(feeAmount > 0){
				uint256 poolAmount = feeAmount / 2;
				uint256 treasurryAmount = feeAmount - poolAmount;
				
				IBEP20(busd).safeTransfer(treasurryddress, treasurryAmount);
				IBEP20(busd).safeTransfer(address(poolAddress), poolAmount);
			}			
		}
		
		poolAddress.withdraw(borrowData[_bid].account, borrowData[_bid].borrowAmount);
		 
		walletTokenBalance[borrowData[_bid].collateralTokenAddress][borrowData[_bid].account] -= borrowData[_bid].collateralAmount;
		tokenBalance[borrowData[_bid].collateralTokenAddress] -= borrowData[_bid].collateralAmount;
		
		
		borrowData[_bid].borrowActive = false;
		borrowData[_bid].borrowFinish = true;
		
		controller.payLoan(borrowData[_bid].lendId);
	}
	
	function payLoanWithSell(
		uint256 _bid
	) external {
		require(msg.sender == borrowData[_bid].account, 'Can pay by Borrower Address only');
		_payLoanWithSell(_bid);
	}
	
	function payLoanWithSellController(
		uint256 _bid
	) external onlyController {
		_payLoanWithSell(_bid);
	}
	
	function _payLoanWithSell(
		uint256 _bid
	) internal {		
		require(borrowData[_bid].borrowActive, 'cant pay, Borrow is not active');
		require(!borrowData[_bid].borrowFinish, 'cant pay, Borrow is finish');
		
		uint256 deadline = block.timestamp + 5 minutes;
		uint256 interestFeeAmount = getInterestFee(_bid);
		uint256 totalPayAmount = borrowData[_bid].borrowAmount + interestFeeAmount;
		
		uint256 balanceBeforeSwap = IBEP20(busd).balanceOf(address(this));
		uint256 tokensToSwap = _getTokenAmount(borrowData[_bid].collateralTokenAddress, borrowData[_bid].collateralAmount);
		
		address[] memory path = new address[](3);
		path[0] = address(borrowData[_bid].collateralTokenAddress);
		path[1] = address(wbnb);
		path[2] = address(busd);
		IBEP20(borrowData[_bid].collateralTokenAddress).safeApprove(address(pancakeRouter), 0);
		IBEP20(borrowData[_bid].collateralTokenAddress).safeApprove(address(pancakeRouter), tokensToSwap);
		pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokensToSwap, 0, path, address(this), deadline);
		
		uint256 balanceAfterSwap = IBEP20(busd).balanceOf(address(this));
		
		uint256 userBalance = balanceAfterSwap - balanceBeforeSwap;
		if(userBalance >= totalPayAmount){
			IBEP20(busd).safeTransfer(borrowData[_bid].account, userBalance - totalPayAmount);
			IBEP20(busd).safeTransfer(borrowData[_bid].lender, borrowData[_bid].borrowAmount);
			if(interestFeeAmount > 0){
				uint256 feeAmount = 0;
				if(interestFee > 0){
					feeAmount = interestFeeAmount * interestFee / _divRate;
				}
				
				uint256 interestAmount = interestFeeAmount - feeAmount;
				IBEP20(busd).safeTransfer(borrowData[_bid].lender, interestAmount);
				
				if(feeAmount > 0){
					uint256 poolAmount = feeAmount / 2;
					uint256 treasurryAmount = feeAmount - poolAmount;
					
					IBEP20(busd).safeTransfer(treasurryddress, treasurryAmount);
					IBEP20(busd).safeTransfer(address(poolAddress), poolAmount);
				}			
			}
		} else {
			IBEP20(borrowData[_bid].collateralTokenAddress).safeTransfer(borrowData[_bid].lender, _getTokenAmount(borrowData[_bid].collateralTokenAddress, borrowData[_bid].collateralAmount));
		}	
		
		poolAddress.withdraw(borrowData[_bid].account, borrowData[_bid].borrowAmount);
		 
		walletTokenBalance[borrowData[_bid].collateralTokenAddress][borrowData[_bid].account] -= borrowData[_bid].collateralAmount;
		tokenBalance[borrowData[_bid].collateralTokenAddress] -= borrowData[_bid].collateralAmount;
		
		
		borrowData[_bid].borrowActive = false;
		borrowData[_bid].borrowFinish = true;
		
		controller.payLoan(borrowData[_bid].lendId);
	}	
	
	function cancelCheck(uint256 _bid) public view returns (bool thisCancel){
		thisCancel  = false;
		if(!borrowData[_bid].borrowActive){
			if(now >= borrowData[_bid].borrowBroadcast + 259200){
				thisCancel  = true;
			} else {
				uint256 sellAmount = 0;
				uint256 tokensToSwap = _getTokenAmount(borrowData[_bid].collateralTokenAddress, borrowData[_bid].collateralAmount);
				
				uint256[] memory getAmountsOut;
				address[] memory path = new address[](3);
				
				path[0] = address(borrowData[_bid].collateralTokenAddress);
				path[1] = address(wbnb);
				path[2] = address(busd);
				
				getAmountsOut = pancakeRouter.getAmountsOut(tokensToSwap, path);
				sellAmount = getAmountsOut[2];
				
				if(sellAmount < borrowData[_bid].borrowAmount * 150 / 100){
					thisCancel  = true;
				}
			}
		}
	} 
	
	function sellCheck(uint256 _bid) public view returns (bool thisSell){
		thisSell  = false;
		
		if(borrowData[_bid].borrowActive){
			uint256 sellAmount = 0;
			uint256 tokensToSwap = _getTokenAmount(borrowData[_bid].collateralTokenAddress, borrowData[_bid].collateralAmount);
			
			uint256[] memory getAmountsOut;
			address[] memory path = new address[](3);
			
			if(borrowData[_bid].collateralTokenAddress == wbnb){
				path = new address[](2);
				
				path[0] = address(wbnb);
				path[1] = address(busd);
				
				getAmountsOut = pancakeRouter.getAmountsOut(tokensToSwap, path);
				sellAmount = getAmountsOut[1];
			} else {
				path = new address[](3);
				
				path[0] = address(borrowData[_bid].collateralTokenAddress);
				path[1] = address(wbnb);
				path[2] = address(busd);
				
				getAmountsOut = pancakeRouter.getAmountsOut(tokensToSwap, path);
				sellAmount = getAmountsOut[2];
			}
			
			if(sellAmount < borrowData[_bid].borrowAmount * 150 / 100){
				thisSell  = true;
			} else {
				if(now >= borrowData[_bid].borrowEnd){
					thisSell  = true;
				}
			}
		} else {
			thisSell  = false;
		}	
	} 
	
	function getInterestFee(uint256 _bid) public view returns (uint256){
		uint256 interestFeeAmount = 0;
		
		if(interestRate > 0){
			uint256 borrowDuration = now - borrowData[_bid].borrowStart;
			uint256 interest = (borrowDuration / 86400) + 1;
			
			interestFeeAmount =  borrowData[_bid].borrowAmount * (interest * interestRate) / _divRate;
		}
		
		return interestFeeAmount;
	}
	
	function _getCollateralAmount(address _tokenCollateral, uint256 _borrowAmount) public view returns (uint256){
		uint256 borrowAmountForCollateral = _borrowAmount * 2;
		uint256 collateralAmount = 0;
		
		if(controller.getTokenRegistered(_tokenCollateral)){
			if(_tokenCollateral == address(0)){
				_tokenCollateral = wbnb;
			}
			
			uint256[] memory getAmountsOut;
			address[] memory path = new address[](2);
			
			bool thisBnB = false;
			address checkPair = pancakeFactory.getPair(address(busd),address(_tokenCollateral));
			if(checkPair == address(0)){
				thisBnB = true;
				checkPair = pancakeFactory.getPair(address(wbnb),address(_tokenCollateral));
			}
			
			IPancakePair pancakePair = IPancakePair(checkPair);
			address token0 = pancakePair.token0();
			
			(uint112 reserve0, uint112 reserve1, ) = pancakePair.getReserves();
							
			uint256 liquidity = 0;
			if(token0 == _tokenCollateral){
				liquidity = reserve1;
			} else {
				liquidity = reserve0;
			}
			
			if(thisBnB){
				path[0] = address(wbnb);
				path[1] = address(busd);
				
				getAmountsOut = pancakeRouter.getAmountsOut(liquidity, path);
				liquidity = getAmountsOut[1];
			}
			
			if(liquidity > borrowAmountForCollateral){
				if(_tokenCollateral == wbnb){
					path = new address[](2);
				
					path[0] = address(busd);
					path[1] = address(wbnb);
					
					getAmountsOut = pancakeRouter.getAmountsOut(borrowAmountForCollateral, path);
					collateralAmount = getAmountsOut[1];
				} else {
					path = new address[](3);
					
					path[0] = address(busd);
					path[1] = address(wbnb);
					path[2] = _tokenCollateral;
					
					getAmountsOut = pancakeRouter.getAmountsOut(borrowAmountForCollateral, path);
					collateralAmount = getAmountsOut[2];
				}
			}
		}
		
		return collateralAmount;
	}
	
	function _getEnteranceFee() public view returns (uint256){
		uint256 feeAmount = 0;
		
		uint256[] memory getAmountsOut;
		address[] memory path = new address[](3);
		
		path[0] = address(busd);
		path[1] = address(wbnb);
		path[2] = address(tgn);
		
		getAmountsOut = pancakeRouter.getAmountsOut(applyFee, path);
		feeAmount = getAmountsOut[2];
		
		return feeAmount;
	}
	
    function getAllowance(address _tokenAddress) view public returns (uint256) {
        uint256 allowance = IBEP20(_tokenAddress).allowance(msg.sender, address(this));
		return _getReverseTokenAmount(_tokenAddress, allowance);
    }
	
	function _setLastIndexFinish() internal {
        for (uint i = lastIndexFinishId; i <= lastIndexFinishId; i++){
            if(borrowData[i].borrowFinish){
				lastIndexFinishId = i + 1;
				break;
			}
        }
    }
	
	function percent(uint numerator, uint denominator, uint precision) internal pure returns(uint quotient) {
		uint _numerator  = numerator * 10 ** (precision+1);
		uint _quotient =  ((_numerator / denominator) + 5) / 10;
		return ( _quotient);
	}
	
	function _getTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		
		IBEP20 tokenAddress = IBEP20(_tokenAddress);
		uint256 tokenDecimal = tokenAddress.decimals();
		uint256 decimalDiff;
		uint256 decimalDiffConverter;
		uint256 amount;
			
		if(_weiDecimal != tokenDecimal){
			if(_weiDecimal > tokenDecimal){
				decimalDiff = _weiDecimal - tokenDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.div(decimalDiffConverter);
			} else {
				decimalDiff = tokenDecimal - _weiDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.mul(decimalDiffConverter);
			}		
		} else {
			amount = _amount;
		}
		
		uint256 _quotient = amount;
		
		return (_quotient);
    }
	
	function _getReverseTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		IBEP20 tokenAddress = IBEP20(_tokenAddress);
		uint256 tokenDecimal = tokenAddress.decimals();
		uint256 decimalDiff;
		uint256 decimalDiffConverter;
		uint256 amount;
			
		if(_weiDecimal != tokenDecimal){
			if(_weiDecimal > tokenDecimal){
				decimalDiff = _weiDecimal - tokenDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.mul(decimalDiffConverter);
			} else {
				decimalDiff = tokenDecimal - _weiDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.div(decimalDiffConverter);
			}		
		} else {
			amount = _amount;
		}
		
		uint256 _quotient = amount;
		
		return (_quotient);
    }
}