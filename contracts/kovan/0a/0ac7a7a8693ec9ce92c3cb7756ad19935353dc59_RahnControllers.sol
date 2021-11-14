/**
 *Submitted for verification at Etherscan.io on 2021-11-14
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

interface RahnPoolReward {
    function autoBountyReward(address account,uint256 _amount) external;
    function claim(address account) external;
}

interface RahnLend {
   	function getLendId() external view returns (uint256);
   	function getAllLendIds() external view returns (uint256[] memory);
   	function getLendsByAddress(address _lendAddress) external view returns (uint256[] memory);
	
	function getLendData(uint256 _lid) external view returns (
		address, 
		address,
		uint256,
		uint256
	);
	
	
	function getLendPeriod(uint256 _lid) external view returns (
		uint256, 
		uint256, 
		uint256, 
		uint256,
		bool,
		bool
	);
	
	function applyLend(
		address
		, address
		, uint256
		, uint256
		, uint256
	) external returns (uint256 _id);
		
	function cancelLend(
		uint256 _lid
	) external;
	
	function applyBorrow(
		uint256 _lid
	) external;
	
	
	function finishLend(
		uint256 _lid
	) external;
}

interface RahnBorrow {
	function getBorrowId() external view returns (uint256);	
	function getAllBorrowIds() external view returns (uint256[] memory);
	function getBorrowsByAddress(address _borrowAddress) external view returns (uint256[] memory);
		
	function getBorrowData(uint256 _bid) external view returns (
		address, 
		address, 
		address, 
		uint256, 
		uint256, 
		uint256
	);
	
	function getBorrowPeriod(uint256 _bid) external view returns (
		uint256, 
		uint256, 
		uint256, 
		uint256,
		bool,
		bool
	);
	
	function applyBorrow(
		address
		, address
		, address
		, uint256
		, uint256
		, uint256
		, uint256
	) external returns (uint256 _id);
	
	function cancelBorrow(
		uint256 _bid
	) external;

	function applyLend(
		uint256 _bid
	) external;
	
	function finishBorrow(
		uint256 _bid
	) external;
}

contract RahnControllers is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
	
	uint256 private _weiDecimal = 18;
    uint256 private _divRate = 10000;
	
	address public _rahn;
	address public _treasurryddress;
	
	RahnPoolReward public _poolAddress;
	RahnLend public _lendAddress;
	RahnBorrow public _borrowAddress;
	IPancakeRouter02 public _pancakeRouter;
	
	uint256 public minBorrow = 50 * 10**_weiDecimal; // Amount in USD
	uint256 public maxBorrow = 10000 * 10**_weiDecimal ;  // Amount in USD
	uint256 public minPeriod = 1; // days
	uint256 public maxPeriod = 28; // days
	uint256 public minInterestRate = 1; // div by 10000
	uint256 public maxInterestRate = 300; // div by 10000
	
	address public _wbnb;
	address public _busd;
	
	struct BorrowToken {
        uint256 index;
        bool thisUSD;
        bool thisBNB;
        bool actived;
    }
	
	struct LendToken {
        uint256 index;
        bool thisUSD;
		bool thisBNB;
        bool actived;
    }
	
	uint256 public borrowTokenCount;
	uint256 public lendTokenCount;
	
	address[] public borrowTokenList;
	address[] public lendTokenList;
	
	mapping (address => BorrowToken) public borrowTokenData;
	mapping (address => LendToken) public lendTokenData;
	mapping (uint256 => uint256) public borrowFromLendData;
	mapping (uint256 => uint256) public lendFromBorrowData;
	
    constructor (
		address rahn
		,address poolAddress
		,address lendAddress
		,address borrowAddress
		,address treasurryddress
		,address pancakeRouter
		,address wbnb
		,address busd
	) public Ownable() {
		
		_rahn = rahn;
		_treasurryddress = treasurryddress;
		_poolAddress = RahnPoolReward(poolAddress);
		_lendAddress = RahnLend(lendAddress);
		_borrowAddress = RahnBorrow(borrowAddress);
		
		_pancakeRouter = IPancakeRouter02(pancakeRouter);
        
		_wbnb = wbnb;
		_busd = busd;
	}	
	
	function setLendAddress(address lendAddress) external onlyOwner {
		_lendAddress = RahnLend(lendAddress);
	}
	
	function setBorrowAddress(address borrowAddress) external onlyOwner {
		_borrowAddress = RahnBorrow(borrowAddress);
	}
	
	function setPoolAddress(address poolAddress) external onlyOwner {
		_poolAddress = RahnPoolReward(poolAddress);
	}
		
	function setPancakeRouter(address pancakeRouter) external onlyOwner {
		_pancakeRouter = IPancakeRouter02(pancakeRouter);
	}
	
	function setBorrowTokenStatus(address borrowToken, bool actived, bool thisUSD, bool thisBNB) external onlyOwner{
		if(borrowTokenData[borrowToken].index > 0) {
			borrowTokenData[borrowToken].actived = actived;
			borrowTokenData[borrowToken].thisUSD = thisUSD;
			borrowTokenData[borrowToken].thisBNB = thisBNB;
			borrowTokenData[borrowToken].actived = actived;
		} else {
			borrowTokenCount = borrowTokenCount + 1;
			borrowTokenList.push(borrowToken);
			borrowTokenData[borrowToken].index = borrowTokenCount;
			borrowTokenData[borrowToken].thisUSD = thisUSD;
			borrowTokenData[borrowToken].thisBNB = thisBNB;
			borrowTokenData[borrowToken].actived = actived;
		}
	}
	
	function setLendTokenStatus(address lendToken, bool actived, bool thisUSD, bool thisBNB) external onlyOwner{
		if(lendTokenData[lendToken].index > 0) {
			lendTokenData[lendToken].thisUSD = thisUSD;
			lendTokenData[lendToken].thisBNB = thisBNB;
			lendTokenData[lendToken].actived = actived;
		} else {
			lendTokenCount = lendTokenCount + 1;
			lendTokenList.push(lendToken);
			lendTokenData[lendToken].index = lendTokenCount;
			lendTokenData[lendToken].thisUSD = thisUSD;
			lendTokenData[lendToken].thisBNB = thisBNB;
			lendTokenData[lendToken].actived = actived;
		}
	}
	
	function applyBorrow(
		address collateralToken
		, address borrowToken
		, uint256 collateralAmount
		, uint256 borrowAmount
		, uint256 interestRate
		, uint256 borrowPeriod
	) external returns (uint256 _id) {
		address account = msg.sender;
		_id = _applyBorrow(account, collateralToken, borrowToken, collateralAmount, borrowAmount, interestRate, borrowPeriod);
	}
		
	function _applyBorrow(
		address account
		, address collateralToken
		, address borrowToken
		, uint256 collateralAmount
		, uint256 borrowAmount
		, uint256 interestRate
		, uint256 borrowPeriod
	) internal returns (uint256 _id) {
		require(borrowTokenData[collateralToken].actived, 'Token are not Active or not registered');
		
		uint256 _borrowAmount = _getUSDAmount(borrowToken, borrowAmount, lendTokenData[borrowToken].thisBNB, lendTokenData[borrowToken].thisUSD);
		
		require(_borrowAmount >= minBorrow, 'not meet the min borrow amount');
		require(_borrowAmount <= maxBorrow, 'not meet the max borrow amount');
		
		require(borrowPeriod >= minPeriod * 86400, 'not meet the min period');
		require(borrowPeriod % 86400 == 0, "period need to be multiple of 1 day" );
		require(borrowPeriod <= maxPeriod * 86400, 'not meet the max period');
		
		require(interestRate >= minInterestRate, 'not meet the min Interest Rate');
		require(interestRate <= maxInterestRate, 'not meet the max Interest Rate');
		
		uint256 minCollateralAmount = _getCollateralAmount(collateralToken, borrowToken, borrowAmount);
		require(collateralAmount >= minCollateralAmount, 'not meet the min Collateral Amount');
				
		uint256 realCollateralAmount = _getTokenAmount(collateralToken, collateralAmount);
		uint256 userBalance = IBEP20(collateralToken).balanceOf(account);
		require(userBalance >= realCollateralAmount, 'Balance insufficient');
		
		IBEP20(collateralToken).safeTransferFrom(account, address(this), realCollateralAmount);
		
		_id = _borrowAddress.applyBorrow(
			account
			, collateralToken
			, borrowToken
			, collateralAmount
			, borrowAmount
			, interestRate
			, borrowPeriod
		);		
	}
	
	function cancelBorrow(uint256 _bid) external {
		(address account,address collateralToken,,uint256 collateralAmount,,) = _borrowAddress.getBorrowData(_bid);
		require(msg.sender == account, 'Can cancel by Borrower Address only');
		_borrowAddress.cancelBorrow(_bid);
		IBEP20(collateralToken).safeTransfer(account, _getTokenAmount(collateralToken, collateralAmount));
	}
	
	function applyLend(
		address lendToken
		, uint256 lendAmount
		, uint256 interestRate
		, uint256 lendPeriod
	) external returns (uint256 _id) {
		address account = msg.sender;
		_id = _applyLend(account, lendToken, lendAmount, interestRate, lendPeriod);
	}
	
	function _applyLend(
		address account
		, address lendToken
		, uint256 lendAmount
		, uint256 interestRate
		, uint256 lendPeriod
	) internal returns (uint256 _id) {
		require(lendTokenData[lendToken].actived, 'Token are not Active or not registered');
		
		uint256 _lendAmount = _getUSDAmount(lendToken, lendAmount, lendTokenData[lendToken].thisBNB, lendTokenData[lendToken].thisUSD);
		
		require(_lendAmount >= minBorrow, 'not meet the min lend amount');
		require(_lendAmount <= maxBorrow, 'not meet the max lend amount');
		
		require(lendPeriod >= minPeriod * 86400, 'not meet the min period');
		require(lendPeriod % 86400 == 0, "period need to be multiple of 1 day" );
		require(lendPeriod <= maxPeriod * 86400, 'not meet the max period');
		
		require(interestRate >= minInterestRate, 'not meet the min Interest Rate');
		require(interestRate <= maxInterestRate, 'not meet the max Interest Rate');
		
		uint256 realLendAmount = _getTokenAmount(lendToken, lendAmount);
		uint256 userBalance = IBEP20(lendToken).balanceOf(account);
		require(userBalance >= realLendAmount, 'Balance insufficient');
		
		IBEP20(lendToken).safeTransferFrom(account, address(this), realLendAmount);
		
		_id = _lendAddress.applyLend(
			account
			, lendToken
			, lendAmount
			, interestRate
			, lendPeriod
		);		
	}
	
	function cancelLend(uint256 _lid) external {
		(address account,address lendToken,uint256 lendAmount,) = _lendAddress.getLendData(_lid);
		require(msg.sender == account, 'Can cancel by Lender Address only');
		_lendAddress.cancelLend(_lid);
		IBEP20(lendToken).safeTransfer(account, _getTokenAmount(lendToken, lendAmount));
	}
	
	function applyBorrowFromLend(
		uint256 _lid
		, address collateralToken
		, uint256 collateralAmount
	) external {
		require(borrowTokenData[collateralToken].actived, 'Token are not Active or not registered');
		
		address account = msg.sender;
		
		(,address borrowToken,uint256 borrowAmount,uint256 interestRate) = _lendAddress.getLendData(_lid);
		(uint256 borrowPeriod,,,,,) = _lendAddress.getLendPeriod(_lid);
				
		uint256 minCollateralAmount = _getCollateralAmount(collateralToken, borrowToken, borrowAmount);
		require(collateralAmount >= minCollateralAmount, 'not meet the min Collateral Amount');
				
		uint256 realCollateralAmount = _getTokenAmount(collateralToken, collateralAmount);
		uint256 userBalance = IBEP20(collateralToken).balanceOf(account);
		require(userBalance >= realCollateralAmount, 'Balance insufficient');
		
		uint256 realBorrowAmount = _getTokenAmount(borrowToken, borrowAmount);
		
		uint256 _bid = _borrowAddress.applyBorrow(
			account
			, collateralToken
			, borrowToken
			, collateralAmount
			, borrowAmount
			, interestRate
			, borrowPeriod
		);
		
		_borrowAddress.applyLend(_bid);
		_lendAddress.applyBorrow(_lid);
		
		borrowFromLendData[_bid] = _lid;
		lendFromBorrowData[_lid] = _bid;
		
		IBEP20(collateralToken).safeTransferFrom(account, address(this), realCollateralAmount);
		IBEP20(borrowToken).safeTransfer(account, _getTokenAmount(borrowToken, realBorrowAmount));
	}
	
	function applyLendFromBorrow(
		uint256 _bid
	) external {
		address account = msg.sender;
					
		(address borrower,,address lendToken,,uint256 lendAmount,uint256 interestRate) = _borrowAddress.getBorrowData(_bid);
		(uint256 lendPeriod,,,,,) = _borrowAddress.getBorrowPeriod(_bid);
		
		uint256 realLendAmount = _getTokenAmount(lendToken, lendAmount);
		uint256 userBalance = IBEP20(lendToken).balanceOf(account);
		require(userBalance >= realLendAmount, 'Balance insufficient');
		
		
		uint256 _lid = _lendAddress.applyLend(
			account
			, lendToken
			, lendAmount
			, interestRate
			, lendPeriod
		);		
		
		_borrowAddress.applyLend(_bid);
		_lendAddress.applyBorrow(_lid);
		
		borrowFromLendData[_bid] = _lid;
		lendFromBorrowData[_lid] = _bid;
		
		IBEP20(lendToken).safeTransferFrom(account, address(this), realLendAmount);
		IBEP20(lendToken).safeTransfer(borrower, _getTokenAmount(lendToken, realLendAmount));
	}
	
	function getInterestFee(uint256 _bid) public view returns (uint256 interestFee){
		(,,,,uint256 borrowAmount,uint256 interestRate) = _borrowAddress.getBorrowData(_bid);
		(,uint256 borrowStart,uint256 borrowEnd,,,) = _borrowAddress.getBorrowPeriod(_bid);
	
		if(now > borrowStart){
			uint256 period = now - borrowStart;
			
			if(now > borrowEnd){
				period = borrowEnd - borrowStart;
			}
			
			interestFee = (borrowAmount * interestRate / _divRate) * ((period + 86400) / 86400);
			
			
		} else {
			interestFee = 0;
		}	
	}
	
	function payLoan(
		uint256 _bid
	) external {
		(address account,address collateralToken,,uint256 collateralAmount,,) = _borrowAddress.getBorrowData(_bid);
		(,,,,bool borrowActive,bool borrowFinish) = _borrowAddress.getBorrowPeriod(_bid);
		
		require(borrowActive, 'cant pay, Borrow is not active');
		require(!borrowFinish, 'cant pay, Borrow is finish');
		require(msg.sender == account, 'Can pay by Borrower Address only');
		
		uint256 _lid = borrowFromLendData[_bid];
		(address lender,address borrowToken,uint256 borrowAmount,) = _lendAddress.getLendData(_lid);
		
		uint256 interestFee = getInterestFee(_bid);
		uint256 totalLoan = borrowAmount + interestFee;
		
		uint256 realLoanAmount = _getTokenAmount(borrowToken, totalLoan);
		uint256 userBalance = IBEP20(borrowToken).balanceOf(account);
		require(userBalance >= realLoanAmount, 'Balance insufficient');
		
		_borrowAddress.finishBorrow(_bid);
		_lendAddress.finishLend(_lid);
		
		IBEP20(borrowToken).safeTransferFrom(account, address(this), realLoanAmount);
		IBEP20(borrowToken).safeTransfer(lender, realLoanAmount);
		IBEP20(collateralToken).safeTransfer(account, _getTokenAmount(collateralToken, collateralAmount));
	}

	function payLoanWithSell(
		uint256 _bid
	) external {
		(address account,address collateralToken,,uint256 collateralAmount,,) = _borrowAddress.getBorrowData(_bid);
		(,,,,bool borrowActive,bool borrowFinish) = _borrowAddress.getBorrowPeriod(_bid);
		
		require(borrowActive, 'cant pay, Borrow is not active');
		require(!borrowFinish, 'cant pay, Borrow is finish');
		require(msg.sender == account, 'Can pay by Borrower Address only');
		
		uint256 _lid = borrowFromLendData[_bid];
		(address lender,address borrowToken,uint256 borrowAmount,) = _lendAddress.getLendData(_lid);
		
		uint256 interestFee = getInterestFee(_bid);
		uint256 totalLoan = borrowAmount + interestFee;
		
		uint256 realLoanAmount = _getTokenAmount(borrowToken, totalLoan);
		uint256 userBalance = sellToken(borrowToken,collateralToken,collateralAmount);
		
		if(userBalance >= realLoanAmount){
			IBEP20(borrowToken).safeTransfer(account, userBalance - realLoanAmount);
			IBEP20(borrowToken).safeTransfer(lender, realLoanAmount);
		} else {
			IBEP20(borrowToken).safeTransfer(lender, realLoanAmount);
		}	
		
		_borrowAddress.finishBorrow(_bid);
		_lendAddress.finishLend(_lid);
	}
	
	function sellToken(address borrowToken, address collateralToken, uint256 collateralAmount) internal returns (uint256 userBalance){
		uint256 deadline = block.timestamp + 5 minutes;
		uint256 balanceBeforeSwap = IBEP20(borrowToken).balanceOf(address(this));
		uint256 tokensToSwap = _getTokenAmount(collateralToken, collateralAmount);
		
		IBEP20(collateralToken).safeApprove(address(_pancakeRouter), 0);
		IBEP20(collateralToken).safeApprove(address(_pancakeRouter), tokensToSwap);
		
		if(collateralToken == _wbnb){		
			address[] memory path = new address[](2);
			path[0] = address(collateralToken);
			path[1] = address(borrowToken);
			_pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokensToSwap, 0, path, address(this), deadline);
		} else {
			address[] memory path = new address[](3);
			path[0] = address(collateralToken);
			path[1] = address(_wbnb);
			path[2] = address(borrowToken);
			_pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokensToSwap, 0, path, address(this), deadline);
		}
		
		uint256 balanceAfterSwap = IBEP20(borrowToken).balanceOf(address(this));
		
		userBalance = balanceAfterSwap - balanceBeforeSwap;
	}
	
	function _getUSDAmount(address tokenAddress, uint256 tokenAmount, bool thisBNB, bool thisUSD) public view returns (uint256){
		uint256 USDAmount = 0;
		
		if(thisUSD){
			USDAmount = tokenAmount;
		} else {
			uint256 amount = _getTokenAmount(tokenAddress, tokenAmount);
			uint256[] memory getAmountsOut;
				
			if(thisBNB){
				address[] memory path = new address[](2);
				
				path[0] = address(tokenAddress);
				path[1] = address(_busd);
				
				getAmountsOut = _pancakeRouter.getAmountsOut(amount, path);
				USDAmount = _getReverseTokenAmount(_busd, getAmountsOut[1]);
			} else {
				address[] memory path = new address[](3);
				
				path[0] = address(tokenAddress);
				path[1] = address(_wbnb);
				path[2] = address(_busd);
				
				getAmountsOut = _pancakeRouter.getAmountsOut(amount, path);
				USDAmount = _getReverseTokenAmount(_busd, getAmountsOut[2]);
			}
		}
				
		return USDAmount;
	}
	
	function _getCollateralAmount(
		address collateralToken, 
		address borrowToken, 
		uint256 borrowAmount
	) public view returns (uint256){
		uint256 collateralAmount = 0;
		uint256 amount = _getTokenAmount(borrowToken, borrowAmount);
		uint256[] memory getAmountsOut;
		
		if(collateralToken == _wbnb){
			address[] memory path = new address[](2);
			
			path[0] = address(borrowToken);
			path[1] = address(collateralToken);
			
			getAmountsOut = _pancakeRouter.getAmountsOut(amount, path);
			collateralAmount = _getReverseTokenAmount(collateralToken, getAmountsOut[1]);
		} else {
			address[] memory path = new address[](3);
			
			path[0] = address(borrowToken);
			path[1] = address(_wbnb);
			path[2] = address(collateralToken);
			
			getAmountsOut = _pancakeRouter.getAmountsOut(amount, path);
			collateralAmount = _getReverseTokenAmount(collateralToken, getAmountsOut[2]);
		}
		
		collateralAmount = collateralAmount * 2;
		return collateralAmount;
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