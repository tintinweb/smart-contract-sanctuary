/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface DollyLend {
   	function getLendId() external view returns (uint256);
   	function getAllLendIds() external view returns (uint256[] memory);
   	function getLendsByAddress(address _lendAddress) external view returns (uint256[] memory);
	
	function getLendData(uint256 _lid) external view returns (
		address, 
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

interface DollyBorrow {
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

contract DollyControllers is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
	
	uint256 private _weiDecimal = 18;
    uint256 private _divRate = 10000;
	
	address public _holdToken;
	address public _treasurryddress;
	
	DollyLend public _lendAddress;
	DollyBorrow public _borrowAddress;
	IPancakeRouter02 public _pancakeRouter;
	
	uint256 public minBorrow = 100 * 10**_weiDecimal; // Amount in USD
	uint256 public maxBorrow = 10000 * 10**_weiDecimal ;  // Amount in USD
	uint256 public minPeriod = 1; // days
	uint256 public maxPeriod = 28; // days
	uint256 public minInterestRate = 50; // div by 10000
	uint256 public maxInterestRate = 100; // div by 10000
	uint256 public borrowFee = 250; // div by 10000
	uint256 public lendFee = 250; // div by 10000
	uint256 public borrowHoldTokenAmount = 0;
	uint256 public lendHoldTokenAmount = 0;
	
	address public _wbnb;
	address public _busd;
	
	struct BorrowData {
        address account;
        address collateralToken;
        address lendToken;
        uint256 collateralAmount;
        uint256 borrowAmount;
		uint256 interestRate;
        uint256 borrowPeriod;
        uint256 borrowStart;
        uint256 borrowEnd;
        uint256 borrowBroadcast;
        bool borrowActive;
        bool borrowFinish;
    }
	
	struct LendData {
        address account;
		address lendToken;
		address collateralToken;
		uint256 lendAmount;
		uint256 interestRate;
		uint256 lendPeriod;
		uint256 lendStart;
		uint256 lendEnd;
		uint256 lendBroadcast;
		bool lendActive;
		bool lendFinish;
    }
	struct LoanAmount {
		uint256 loanAmount;
		uint256 lenderAmount;
		uint256 feeAmount;
		uint256 realLoanAmount;
		uint256 realLenderAmount;
		uint256 realFeeAmount;
    }
	
	struct CollateralToken {
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
	
	struct SendTransaction {
        uint256 balanceBeforeSendCollateral;
        uint256 balanceAfterSendCollateral;
        uint256 balanceBeforeSendLend;
        uint256 balanceAfterSendLend;
    }
	
	uint256 public collateralTokenCount;
	uint256 public lendTokenCount;
	
	address[] public collateralTokenList;
	address[] public lendTokenList;
	
	mapping (address => CollateralToken) public collateralTokenData;
	mapping (address => LendToken) public lendTokenData;
	mapping (uint256 => uint256) public borrowFromLendData;
	mapping (uint256 => uint256) public lendFromBorrowData;
		
	event PlatformConfig(address holdToken, uint256 minBorrow, uint256 maxBorrow, uint256 minPeriod, uint256 maxPeriod, uint256 minInterestRate, uint256 maxInterestRate, uint256 borrowFee, uint256 lendFee, uint256 borrowHoldTokenAmount, uint256 lendHoldTokenAmount);
	event CollateralTokenStatus(uint256 indexed index, address collateralToken, bool thisUSD, bool thisBNB, bool actived);
	event LendTokenStatus(uint256 indexed index, address lendToken, bool thisUSD, bool thisBNB, bool actived);
	event ApplyBorrow(uint256 indexed bid, address account, address collateralToken, address lendToken, uint256 collateralAmount, uint256 borrowAmount, uint256 interestRate, uint256 borrowPeriod, uint256 borrowBroadcast);
	event CancelBorrow(uint256 indexed bid);
	event ApplyLend(uint256 indexed lid, address account, address collateralToken, address lendToken, uint256 lendAmount, uint256 interestRate, uint256 lendPeriod, uint256 lendBroadcast);
	event CancelLend(uint256 indexed lid);
	event TakeLend(uint256 indexed lid, uint256 bid, uint256 lendStart);
	event TakeBorrow(uint256 indexed bid, uint256 lid, uint256 borrowStart);
	event FinishBorrow(uint256 indexed bid,bool withSell,uint256 interestFee,uint256 borrowFeeAmount,uint256 borrowPayment);
	event FinishLend(uint256 indexed lid,bool withSell,uint256 interestFee,uint256 lendFeeAmount,uint256 lendPayment);
	
	receive() external payable {
        
    }
	
    constructor (
		address holdToken
		,address lendAddress
		,address borrowAddress
		,address treasurryddress
		,address pancakeRouter
		,address wbnb
		,address busd
	) public Ownable() {
		
		_holdToken = holdToken;
		_treasurryddress = treasurryddress;
		_lendAddress = DollyLend(lendAddress);
		_borrowAddress = DollyBorrow(borrowAddress);
		
		_pancakeRouter = IPancakeRouter02(pancakeRouter);
        
		_wbnb = wbnb;
		_busd = busd;
		
		emit PlatformConfig(
			_holdToken
			, minBorrow
			, maxBorrow
			, minPeriod
			, maxPeriod
			, minInterestRate
			, maxInterestRate
			, borrowFee
			, lendFee
			, borrowHoldTokenAmount
			, lendHoldTokenAmount
		);
	}	
	
	function setHoldToken(address holdToken) external onlyOwner {
		_holdToken = holdToken;
		
		emit PlatformConfig(
			_holdToken
			, minBorrow
			, maxBorrow
			, minPeriod
			, maxPeriod
			, minInterestRate
			, maxInterestRate
			, borrowFee
			, lendFee
			, borrowHoldTokenAmount
			, lendHoldTokenAmount
		);
	}
	
	function setTreasurryddress(address treasurryddress) external onlyOwner {
		_treasurryddress = treasurryddress;
	}
	
	function setLendAddress(address lendAddress) external onlyOwner {
		_lendAddress = DollyLend(lendAddress);
	}
	
	function setBorrowAddress(address borrowAddress) external onlyOwner {
		_borrowAddress = DollyBorrow(borrowAddress);
	}
	
	function setPancakeRouter(address pancakeRouter) external onlyOwner {
		_pancakeRouter = IPancakeRouter02(pancakeRouter);
	}
	
	function setConfig(
		uint256 _minBorrow
		,uint256 _maxBorrow
		,uint256 _minPeriod
		,uint256 _maxPeriod
		,uint256 _minInterestRate
		,uint256 _maxInterestRate
		,uint256 _borrowFee
		,uint256 _lendFee
		,uint256 _borrowHoldTokenAmount
		,uint256 _lendHoldTokenAmount
	) external onlyOwner {
		require(_minBorrow > 0 && _minBorrow < _maxBorrow, 'Min Borrow must be greater than 0 and must less than max Borrow');
		require(_minPeriod > 0 && _minPeriod < _maxPeriod, 'Min Period must be greater than 0 and must less than max Period');
		require(_minPeriod % 1 == 0, "min period need to be multiple of 1 day" );
		require(_maxPeriod % 1 == 0, "max period need to be multiple of 1 day" );
		require(_minInterestRate > 0 && _minInterestRate < _maxInterestRate, 'Min InterestRate must be greater than 0 and must less than max InterestRate');
		require(_maxInterestRate < 100, 'Max InterestRate must be less than 10 (1%)');
		require(_borrowFee < 500, 'Borrow Fee must be less than 500 (5%)');
		require(_lendFee < 500, 'Lend Fee must be less than 500 (5%)');
		
		minBorrow = _minBorrow;
		maxBorrow = _maxBorrow;
		minPeriod = _minPeriod;
		maxPeriod = _maxPeriod;
		minInterestRate = _minInterestRate;
		maxInterestRate = _maxInterestRate;
		borrowFee = _borrowFee;
		lendFee = _lendFee;
		borrowHoldTokenAmount = _borrowHoldTokenAmount;
		lendHoldTokenAmount = _lendHoldTokenAmount;
		
		emit PlatformConfig(
			_holdToken
			, minBorrow
			, maxBorrow
			, minPeriod
			, maxPeriod
			, minInterestRate
			, maxInterestRate
			, borrowFee
			, lendFee
			, borrowHoldTokenAmount
			, lendHoldTokenAmount
		);
	}
	
	function getRuleConfig() view public returns (
		uint256 _minBorrow, 
		uint256 _maxBorrow,
		uint256 _minPeriod,
		uint256 _maxPeriod,
		uint256 _minInterestRate,
		uint256 _maxInterestRate
	) {		
	   return(
			minBorrow, 
			maxBorrow,
			minPeriod,
			maxPeriod,
			minInterestRate,
			maxInterestRate
		);
    }
	
	function getFeeAmountConfig() view public returns (
		address holdToken, 
		uint256 _borrowFee,
		uint256 _lendFee,
		uint256 _borrowHoldTokenAmount,
		uint256 _lendHoldTokenAmount
	) {		
	   return(
			_holdToken, 
			borrowFee,
			lendFee,
			borrowHoldTokenAmount,
			lendHoldTokenAmount
		);
    }
	
	
	function setCollateralTokenStatus(address collateralToken, bool actived, bool thisUSD, bool thisBNB) external onlyOwner{
		if(collateralTokenData[collateralToken].index > 0) {
			collateralTokenData[collateralToken].actived = actived;
			collateralTokenData[collateralToken].thisUSD = thisUSD;
			collateralTokenData[collateralToken].thisBNB = thisBNB;
			collateralTokenData[collateralToken].actived = actived;
		} else {
			collateralTokenCount = collateralTokenCount + 1;
			collateralTokenList.push(collateralToken);
			collateralTokenData[collateralToken].index = collateralTokenCount;
			collateralTokenData[collateralToken].thisUSD = thisUSD;
			collateralTokenData[collateralToken].thisBNB = thisBNB;
			collateralTokenData[collateralToken].actived = actived;
		}
		
		emit CollateralTokenStatus(
			collateralTokenData[collateralToken].index
			, collateralToken
			, thisUSD
			, thisBNB
			, actived
		);
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
		
		emit LendTokenStatus(
			lendTokenData[lendToken].index
			, lendToken
			, thisUSD
			, thisBNB
			, actived
		);
	}
	
	function applyBorrow(
		address collateralToken
		, address lendToken
		, uint256 collateralAmount
		, uint256 borrowAmount
		, uint256 interestRate
		, uint256 borrowPeriod
	) external payable returns (uint256 _id) {
		address account = msg.sender;
		_id = _applyBorrow(account, collateralToken, lendToken, collateralAmount, borrowAmount, interestRate, borrowPeriod);
	}
		
	function _applyBorrow(
		address account
		, address collateralToken
		, address lendToken
		, uint256 collateralAmount
		, uint256 borrowAmount
		, uint256 interestRate
		, uint256 borrowPeriod
	) internal returns (uint256 _id) {
		require(collateralTokenData[collateralToken].actived, 'Collateral Token are not Active or not registered');
		require(lendTokenData[lendToken].actived, 'Lend Token are not Active or not registered');
		
		uint256 userBalance = 0;
		
		if(borrowHoldTokenAmount > 0) {
			userBalance = IBEP20(_holdToken).balanceOf(account);
			userBalance = _getReverseTokenAmount(_holdToken, userBalance);
			require(userBalance >= borrowHoldTokenAmount, 'Hold Balance insufficient');
		}
		
		uint256 _borrowAmount = _getUSDAmount(lendToken, borrowAmount, lendTokenData[lendToken].thisBNB, lendTokenData[lendToken].thisUSD);
		
		require(_borrowAmount >= minBorrow, 'not meet the min borrow amount');
		require(_borrowAmount <= maxBorrow, 'not meet the max borrow amount');
		
		require(borrowPeriod >= minPeriod * 86400, 'not meet the min period');
		require(borrowPeriod % 86400 == 0, "period need to be multiple of 1 day" );
		require(borrowPeriod <= maxPeriod * 86400, 'not meet the max period');
		
		require(interestRate >= minInterestRate, 'not meet the min Interest Rate');
		require(interestRate <= maxInterestRate, 'not meet the max Interest Rate');
		
		uint256 minCollateralAmount = _getCollateralAmount(collateralToken, lendToken, borrowAmount);
		uint256 realCollateralAmount = _getTokenAmount(collateralToken, collateralAmount);
				
		if(collateralTokenData[collateralToken].thisBNB){
			userBalance = msg.value;
		} else {
			userBalance = IBEP20(collateralToken).balanceOf(account);
		}
		
		require(userBalance >= realCollateralAmount, 'Balance insufficient');
		
		if(collateralTokenData[collateralToken].thisBNB){
			collateralAmount = msg.value;
			IWETH(_wbnb).deposit{value: collateralAmount}();
			IWETH(_wbnb).transfer(address(this), collateralAmount);
		} else {
			uint256 balanceBeforeSendCollateral = IBEP20(collateralToken).balanceOf(address(this));
			IBEP20(collateralToken).safeTransferFrom(account, address(this), realCollateralAmount);
			uint256 balanceAfterSendCollateral = IBEP20(collateralToken).balanceOf(address(this));
			collateralAmount = balanceAfterSendCollateral - balanceBeforeSendCollateral;
			collateralAmount = _getReverseTokenAmount(collateralToken, collateralAmount);
		}
		
		require(collateralAmount >= minCollateralAmount, 'not meet the min Collateral Amount');
		
		_id = _borrowAddress.applyBorrow(
			account
			, collateralToken
			, lendToken
			, collateralAmount
			, borrowAmount
			, interestRate
			, borrowPeriod
		);	
		
		emit ApplyBorrow(
			_id
			,account
			,collateralToken
			,lendToken
			,collateralAmount
			,borrowAmount
			,interestRate
			,borrowPeriod
			,now
		);
	}
	
	function cancelBorrow(uint256 _bid) external {
		(address account,address collateralToken,,uint256 collateralAmount,,) = _borrowAddress.getBorrowData(_bid);
		require(msg.sender == account, 'Can cancel by Borrower Address only');
		_borrowAddress.cancelBorrow(_bid);
		
		if(collateralTokenData[collateralToken].thisBNB){
			IWETH(_wbnb).withdraw(_getTokenAmount(collateralToken, collateralAmount));
			payable(account).transfer(_getTokenAmount(collateralToken, collateralAmount));
		} else {
			IBEP20(collateralToken).safeTransfer(account, _getTokenAmount(collateralToken, collateralAmount));
		}
		
		emit CancelBorrow(_bid);
	}
	
	function applyLend(
		address lendToken
		, address collateralToken
		, uint256 lendAmount
		, uint256 interestRate
		, uint256 lendPeriod
	) external payable returns (uint256 _id) {
		address account = msg.sender;
		_id = _applyLend(account, lendToken, collateralToken, lendAmount, interestRate, lendPeriod);
	}
	
	function _applyLend(
		address account
		, address lendToken
		, address collateralToken
		, uint256 lendAmount
		, uint256 interestRate
		, uint256 lendPeriod
	) internal returns (uint256 _id) {
		require(lendTokenData[lendToken].actived, 'Token are not Active or not registered');
		require(collateralTokenData[collateralToken].actived, 'Collateral Token are not Active or not registered');
		
		uint256 userBalance = 0;
		
		if(lendHoldTokenAmount > 0) {
			userBalance = IBEP20(_holdToken).balanceOf(account);
			userBalance = _getReverseTokenAmount(_holdToken, userBalance);
			require(userBalance >= lendHoldTokenAmount, 'Hold Balance insufficient');
		}
		
		uint256 _lendAmount = _getUSDAmount(lendToken, lendAmount, lendTokenData[lendToken].thisBNB, lendTokenData[lendToken].thisUSD);
		
		require(_lendAmount >= minBorrow, 'not meet the min lend amount');
		require(_lendAmount <= maxBorrow, 'not meet the max lend amount');
		
		require(lendPeriod >= minPeriod * 86400, 'not meet the min period');
		require(lendPeriod % 86400 == 0, "period need to be multiple of 1 day" );
		require(lendPeriod <= maxPeriod * 86400, 'not meet the max period');
		
		require(interestRate >= minInterestRate, 'not meet the min Interest Rate');
		require(interestRate <= maxInterestRate, 'not meet the max Interest Rate');
		
		uint256 realLendAmount = _getTokenAmount(lendToken, lendAmount);
		
		if(lendTokenData[lendToken].thisBNB){
			userBalance = msg.value;
		} else {
			userBalance = IBEP20(lendToken).balanceOf(account);
		}
		
		require(userBalance >= realLendAmount, 'Balance insufficient');
		
		if(lendTokenData[lendToken].thisBNB){
			lendAmount = msg.value;
			IWETH(_wbnb).deposit{value: lendAmount}();
			IWETH(_wbnb).transfer(address(this), lendAmount);
		} else {
			uint256 balanceBeforeSendLend = IBEP20(lendToken).balanceOf(address(this));
			IBEP20(lendToken).safeTransferFrom(account, address(this), realLendAmount);
			uint256 balanceAfterSendLend = IBEP20(lendToken).balanceOf(address(this));
			lendAmount = balanceAfterSendLend - balanceBeforeSendLend;
			lendAmount = _getReverseTokenAmount(lendToken, lendAmount);
		}
		
		_id = _lendAddress.applyLend(
			account
			, lendToken
			, collateralToken
			, lendAmount
			, interestRate
			, lendPeriod
		);	

		emit ApplyLend(
			_id
			, account
			, collateralToken
			, lendToken
			, lendAmount
			, interestRate
			, lendPeriod
			, now
		);
	}
	
	function cancelLend(uint256 _lid) external {
		(address account,address lendToken,,uint256 lendAmount,) = _lendAddress.getLendData(_lid);
		require(msg.sender == account, 'Can cancel by Lender Address only');
		_lendAddress.cancelLend(_lid);
		
		if(lendTokenData[lendToken].thisBNB){
			IWETH(_wbnb).withdraw(_getTokenAmount(lendToken, lendAmount));
			payable(account).transfer(_getTokenAmount(lendToken, lendAmount));
		} else {
			IBEP20(lendToken).safeTransfer(account, _getTokenAmount(lendToken, lendAmount));
		}
		
		emit CancelLend(_lid);
	}
	
	function applyBorrowFromLend(
		uint256 _lid
		, uint256 collateralAmount
	) external payable {
		
		LendData memory lend;
		SendTransaction memory safeSend;
		
		address account = msg.sender;
		
		uint256 userBalance = 0;
		
		if(borrowHoldTokenAmount > 0) {
			userBalance = IBEP20(_holdToken).balanceOf(account);
			userBalance = _getReverseTokenAmount(_holdToken, userBalance);
			require(userBalance >= borrowHoldTokenAmount, 'Hold Balance insufficient');
		}
		
		(,lend.lendToken,lend.collateralToken,lend.lendAmount,lend.interestRate) = _lendAddress.getLendData(_lid);
		(uint256 borrowPeriod,,,,,) = _lendAddress.getLendPeriod(_lid);
				
		uint256 minCollateralAmount = _getCollateralAmount(lend.collateralToken, lend.lendToken, lend.lendAmount);
		uint256 realCollateralAmount = _getTokenAmount(lend.collateralToken, collateralAmount);
		uint256 realBorrowAmount = _getTokenAmount(lend.lendToken, lend.lendAmount);
		
		if(collateralTokenData[lend.collateralToken].thisBNB){
			userBalance = msg.value;
		} else {
			userBalance = IBEP20(lend.collateralToken).balanceOf(account);
		}
		
		require(userBalance >= realCollateralAmount, 'Balance insufficient');
		
		if(collateralTokenData[lend.collateralToken].thisBNB){
			collateralAmount = msg.value;
			IWETH(_wbnb).deposit{value: collateralAmount}();
			IWETH(_wbnb).transfer(address(this), collateralAmount);
		} else {
			safeSend.balanceBeforeSendCollateral = IBEP20(lend.collateralToken).balanceOf(address(this));
			IBEP20(lend.collateralToken).safeTransferFrom(account, address(this), realCollateralAmount);
			safeSend.balanceAfterSendCollateral = IBEP20(lend.collateralToken).balanceOf(address(this));
			collateralAmount = safeSend.balanceAfterSendCollateral - safeSend.balanceBeforeSendCollateral;
			collateralAmount = _getReverseTokenAmount(lend.collateralToken, collateralAmount);
		}
		
		require(collateralAmount >= minCollateralAmount, 'not meet the min Collateral Amount');
		
		if(lendTokenData[lend.lendToken].thisBNB){
			IWETH(_wbnb).withdraw(_getTokenAmount(lend.lendToken, realBorrowAmount));
			payable(account).transfer(_getTokenAmount(lend.lendToken, realBorrowAmount));
		} else {
			IBEP20(lend.lendToken).safeTransfer(account, _getTokenAmount(lend.lendToken, realBorrowAmount));
		}		
		
		uint256 _bid = _borrowAddress.applyBorrow(
			account
			, lend.collateralToken
			, lend.lendToken
			, collateralAmount
			, lend.lendAmount
			, lend.interestRate
			, borrowPeriod
		);
		
		_borrowAddress.applyLend(_bid);
		_lendAddress.applyBorrow(_lid);
		
		borrowFromLendData[_bid] = _lid;
		lendFromBorrowData[_lid] = _bid;
		
		emit ApplyBorrow(
			_bid
			,account
			,lend.collateralToken
			,lend.lendToken
			,collateralAmount
			,lend.lendAmount
			,lend.interestRate
			,borrowPeriod
			,now
		);
		
		emit TakeLend(_lid, _bid, now);
		emit TakeBorrow(_bid, _lid, now);
		
	}
	
	function applyLendFromBorrow(
		uint256 _bid
	) external payable {
		address account = msg.sender;
			
		uint256 userBalance = 0;
		
		if(lendHoldTokenAmount > 0) {
			userBalance = IBEP20(_holdToken).balanceOf(account);
			userBalance = _getReverseTokenAmount(_holdToken, userBalance);
			require(userBalance >= lendHoldTokenAmount, 'Hold Balance insufficient');
		}
		
		(address borrower,address collateralToken,address lendToken,,uint256 lendAmount,uint256 interestRate) = _borrowAddress.getBorrowData(_bid);
		(uint256 lendPeriod,,,,,) = _borrowAddress.getBorrowPeriod(_bid);
		
		uint256 realLendAmount = _getTokenAmount(lendToken, lendAmount);
		
		if(lendTokenData[lendToken].thisBNB){
			userBalance = msg.value;
		} else {
			userBalance = IBEP20(lendToken).balanceOf(account);
		}
		
		require(userBalance >= realLendAmount, 'Balance insufficient');
		
		if(lendTokenData[lendToken].thisBNB){
			realLendAmount = msg.value;
			payable(borrower).transfer(realLendAmount);
		} else {
			IBEP20(lendToken).safeTransferFrom(account, borrower, realLendAmount);
		}
		
		uint256 _lid = _lendAddress.applyLend(
			account
			, lendToken
			, collateralToken
			, lendAmount
			, interestRate
			, lendPeriod
		);		
		
		_borrowAddress.applyLend(_bid);
		_lendAddress.applyBorrow(_lid);
		
		borrowFromLendData[_bid] = _lid;
		lendFromBorrowData[_lid] = _bid;
		
		emit ApplyLend(
			_lid
			, account
			, collateralToken
			, lendToken
			, lendAmount
			, interestRate
			, lendPeriod
			, now
		);
		
		emit TakeLend(_lid, _bid, now);
		emit TakeBorrow(_bid, _lid, now);
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
		, bool withSell
	) external payable {
		BorrowData memory borrow;
		LoanAmount memory loan;
		
		(borrow.account,borrow.collateralToken,borrow.lendToken,borrow.collateralAmount,borrow.borrowAmount,) = _borrowAddress.getBorrowData(_bid);
		(,,borrow.borrowEnd,,borrow.borrowActive,borrow.borrowFinish) = _borrowAddress.getBorrowPeriod(_bid);
		
		require(borrow.borrowActive, 'cant pay, Borrow is not active');
		require(!borrow.borrowFinish, 'cant pay, Borrow is finish');
		
		uint256 currentCollateralAmount = _getCollateralAmount(borrow.collateralToken, borrow.lendToken, borrow.borrowAmount);
		
		if(withSell == true && msg.sender != borrow.account){
			if(now < borrow.borrowEnd){
				require(borrow.collateralAmount >= (currentCollateralAmount * 70 / 100), 'Not meet the requirement for forced sale collateral');	
			}
		} else {
			require(msg.sender == borrow.account, 'Can pay by Borrower Address only');	
		}
		
		uint256 _lid = borrowFromLendData[_bid];
		(address lender,address lendToken,,uint256 borrowAmount,) = _lendAddress.getLendData(_lid);
		
		uint256 interestFee = getInterestFee(_bid);
		uint256 borrowFeeAmount = 0;
		uint256 lendFeeAmount = 0;
		
		if(borrowFee > 0){
			borrowFeeAmount = interestFee * borrowFee / 10000;
		}
		
		if(lendFee > 0){
			lendFeeAmount = interestFee * lendFee / 10000;
		}
		
		loan.loanAmount = borrowAmount + interestFee + borrowFeeAmount;
		loan.feeAmount = borrowFeeAmount + lendFeeAmount;
		loan.lenderAmount = loan.loanAmount - loan.feeAmount;
		
		loan.realLoanAmount = _getTokenAmount(lendToken, loan.loanAmount);
		loan.realFeeAmount = _getTokenAmount(lendToken, loan.feeAmount);
		loan.realLenderAmount = _getTokenAmount(lendToken, loan.lenderAmount);
		
		uint256 userBalance = 0;
		if(withSell == true){
			userBalance = sellToken(lendToken,borrow.collateralToken,borrow.collateralAmount);
			if(userBalance >= loan.realLoanAmount){
				sendLendToken(lendToken, loan.realLenderAmount, lender);
						
				if(loan.realFeeAmount > 0){
					sendLendToken(lendToken, loan.realFeeAmount, _treasurryddress);
				}
				
				if((userBalance - loan.realLoanAmount) > 0){
					userBalance = sellToken(borrow.collateralToken,lendToken,(userBalance - loan.realLoanAmount));
					sendCollateralToken(borrow.collateralToken, userBalance, borrow.account);
				}				
			} else {
				sendLendToken(lendToken, userBalance, lender);
			}	
		} else {
			if(lendTokenData[lendToken].thisBNB){
				userBalance = msg.value;
				require(userBalance >= loan.realLoanAmount, 'Balance insufficient');
				
				payable(lender).transfer(loan.realLoanAmount);
				if(loan.realFeeAmount > 0){
					payable(_treasurryddress).transfer(loan.realFeeAmount);
				}
				
			} else {
				userBalance = IBEP20(lendToken).balanceOf(borrow.account);
				require(userBalance >= loan.realLoanAmount, 'Balance insufficient');
				IBEP20(lendToken).safeTransferFrom(borrow.account, address(this), loan.realLoanAmount);
				IBEP20(lendToken).safeTransfer(lender, loan.realLenderAmount);
				if(loan.realFeeAmount > 0){
					IBEP20(lendToken).safeTransfer(_treasurryddress, loan.realFeeAmount);
				}
			}
			
			sendCollateralToken(borrow.collateralToken, _getTokenAmount(borrow.collateralToken, borrow.collateralAmount), borrow.account);
		}
		
		_borrowAddress.finishBorrow(_bid);
		_lendAddress.finishLend(_lid);
		
		emit FinishBorrow(_bid, withSell, interestFee, borrowFeeAmount, now);
		emit FinishLend(_lid, withSell, interestFee, lendFeeAmount, now);
	}
	
	function sellToken(address lendToken, address collateralToken, uint256 collateralAmount) internal returns (uint256 userBalance){
		uint256 deadline = block.timestamp + 5 minutes;
		uint256 balanceBeforeSwap = IBEP20(lendToken).balanceOf(address(this));
		uint256 tokensToSwap = _getTokenAmount(collateralToken, collateralAmount);
		
		IBEP20(collateralToken).safeApprove(address(_pancakeRouter), 0);
		IBEP20(collateralToken).safeApprove(address(_pancakeRouter), tokensToSwap);
		
		if(collateralToken == _wbnb || lendToken == _wbnb){		
			address[] memory path = new address[](2);
			path[0] = address(collateralToken);
			path[1] = address(lendToken);
			_pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokensToSwap, 0, path, address(this), deadline);
		} else {
			address[] memory path = new address[](3);
			path[0] = address(collateralToken);
			path[1] = address(_wbnb);
			path[2] = address(lendToken);
			_pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokensToSwap, 0, path, address(this), deadline);
		}
		
		uint256 balanceAfterSwap = IBEP20(lendToken).balanceOf(address(this));
		
		userBalance = balanceAfterSwap - balanceBeforeSwap;
	}
	
	function sendLendToken(address lendToken, uint256 amount, address to) internal {
		if(lendTokenData[lendToken].thisBNB){
			IWETH(_wbnb).withdraw(amount);
			payable(to).transfer(amount);
		} else {
			IBEP20(lendToken).safeTransfer(to, amount);
		}
	}
	
	function sendCollateralToken(address collateralToken, uint256 amount, address to) internal {
		if(collateralTokenData[collateralToken].thisBNB){
			IWETH(_wbnb).withdraw(amount);
			payable(to).transfer(amount);
		} else {
			IBEP20(collateralToken).safeTransfer(to, amount);
		}
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
		address lendToken, 
		uint256 borrowAmount
	) public view returns (uint256){
		uint256 collateralAmount = 0;
		uint256 amount = _getTokenAmount(lendToken, borrowAmount);
		uint256[] memory getAmountsOut;
		
		if(collateralToken == _wbnb){
			address[] memory path = new address[](2);
			
			path[0] = address(lendToken);
			path[1] = address(collateralToken);
			
			getAmountsOut = _pancakeRouter.getAmountsOut(amount, path);
			collateralAmount = _getReverseTokenAmount(collateralToken, getAmountsOut[1]);
		} else {
			
			if(lendToken == _wbnb){
				address[] memory path = new address[](2);
				path[0] = address(_wbnb);
				path[1] = address(collateralToken);
				
				getAmountsOut = _pancakeRouter.getAmountsOut(amount, path);
				collateralAmount = _getReverseTokenAmount(collateralToken, getAmountsOut[1]);
			} else {
				address[] memory path = new address[](3);
				path[0] = address(lendToken);
				path[1] = address(_wbnb);
				path[2] = address(collateralToken);
				
				getAmountsOut = _pancakeRouter.getAmountsOut(amount, path);
				collateralAmount = _getReverseTokenAmount(collateralToken, getAmountsOut[2]);
			}
		}
		
		collateralAmount = collateralAmount * 220 / 100;
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