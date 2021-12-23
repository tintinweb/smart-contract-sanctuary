/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT

/**
 * Revoluzion Token
 * Future ecosystem development would include swap/dex system with chart integration,
 * Portfolio viewer, dex buy/sell order and web base Play to Earn NFT game Apocalypse.
 *
 * Website : revoluzion.io
 * Whitepaper : whitepaper.revoluzion.io
 * Facebook :facebook.com/revoluziontoken/
 * Twitter : twitter.com/RevoluzionToken
 * Linkedin : linkedin.com/company/revoluzion-token/
 * GitHub : github.com/RevoluzionToken
 * Telegram : t.me/revoluziontoken
 */


pragma solidity ^0.8.0;



/** LIBRARIES **/

/**
 * @title Address library
 * 
 * @dev Collection of functions related to the address type.
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * CAUTION
 * This version of SafeMath should only be used with Solidity 0.8 or later,
 * because it relies on the compiler's built in overflow checks.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/**
 * @title Context
 * 
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
    
    /** FUNCTION **/

    /**
     * @dev Provide information of current sender.
     */
    function _msgSender() internal view virtual returns (address) {
        /**
         * @dev Returns msg.sender.
         */
        return msg.sender;
    }

    /**
     * @dev Provide information current data.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        /**
         * @dev Returns msg.data.
         */
        return msg.data;
    }

    /**
     * @dev Provide information current value.
     */
    function _msgValue() internal view virtual returns (uint256) {
        /**
         * @dev Returns msg.value.
         */
        return msg.value;
    }

}

abstract contract Auth is Context {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(_msgSender()), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

}



/** IERC20 STANDARD **/

interface IERC20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/** UNISWAP V2 INTERFACES **/

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}



/** DIVIDEND/REFLECTION DISTRIBUTOR **/

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor, Context {
    

    /* LIBRARY */
    using SafeMath for uint256;


    /* DATA */
    IERC20Extended public rewardToken;
    IUniswapV2Router02 public router;
    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    bool public initialized;
    uint256 public currentIndex;
    uint256 public minPeriod;
    uint256 public minDistribution;
    address[] public shareholders;
    
    mapping(address => uint256) public shareholderIndexes;
    mapping(address => uint256) public shareholderClaims;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends; 
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor;


    /* MODIFIER */
    modifier initializer() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(_msgSender() == _token);
        _;
    }


    /* CONSTRUCTOR */
    constructor(address rewardToken_, address router_) {
        _token = _msgSender();
        rewardToken = IERC20Extended(rewardToken_);
        router = IUniswapV2Router02(router_);

        dividendsPerShareAccuracyFactor = 10**36;
        minPeriod = 1 hours;
        minDistribution = 1 * (10**rewardToken.decimals());
    }


    /* FUNCTION */

    function unInitialized(bool initialization) external onlyToken {
        initialized = initialization;
    }

    function setTokenAddress(address token_) external initializer onlyToken {
        _token = token_;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    /**
     * @dev Set the number of shares owned by the address.
     */
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    } 

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = rewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens {
            value: _msgValue()
        } (0, path, address(this), block.timestamp);

        uint256 amount = rewardToken.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }

    /**
     * @dev Distribute dividend to the shareholders and update dividend information.
     */
    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            rewardToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    /**
     * @dev Get the cumulative dividend for the given share.
     */
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }
    
    /**
     * @dev Get unpaid dividend that needed to be distributed for the given address.
     */
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    /**
     * @dev Add the address to the array of shareholders.
     */
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    /**
     * @dev Remove the address from the array of shareholders.
     */
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function claimDividend() external {
        distributeDividend(_msgSender());
    }

}



/** DIAMOND HAND REWARDS DISTRIBUTOR **/

interface IDiamondDistributor {
    function setDiamondCriteria(uint256 _diamondCycle, uint256 _minTokenRequired) external;

    function setEligibility(address holder, bool eligible) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

contract DiamondDistributor is IDiamondDistributor, Context {


    /* LIBRARY */
    using SafeMath for uint256;


    /* DATA */
    IERC20Extended public rewardToken;
    IUniswapV2Router02 public router;
    address public _token;

    struct Diamond {
        bool eligible;
        uint256 eligibleTime;
        uint256 totalRealised;
    }

    bool public initialized;
    uint256 public currentIndex;
    uint256 public diamondCycle;
    uint256 public diamondCycleStart;
    uint256 public diamondCycleEnd;
    uint256 public previousCycleEnd;
    uint256 public minTokenRequired;
    address[] public holders;

    mapping(address => uint256) public holderIndexes;
    mapping(address => Diamond) public diamonds;
    
    uint256 public totalDiamonds; 
    uint256 public totalDistributed;
    uint256 public diamondsPerHolder;
    uint256 public diamondsPerHolderAccuracyFactor;


    /* MODIFIER */
    modifier initializer() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(_msgSender() == _token);
        _;
    }


    /* CONSTRUCTOR */
    constructor(address rewardToken_, address router_) {
        _token = _msgSender();
        rewardToken = IERC20Extended(rewardToken_);
        router = IUniswapV2Router02(router_);

        diamondsPerHolderAccuracyFactor = 10**36;
        diamondCycle = 7 days;
        diamondCycleStart = block.timestamp;
        diamondCycleEnd = diamondCycleStart + diamondCycle;
        previousCycleEnd = block.timestamp - 1;
        minTokenRequired = 1 * (10**rewardToken.decimals());
    }


    /* FUNCTION */

    function unInitialized(bool initialization) external onlyToken {
        initialized = initialization;
    }

    function setTokenAddress(address token_) external initializer onlyToken {
        _token = token_;
    }

    function setDiamondCriteria(uint256 _diamondCycle, uint256 _minTokenRequired) external override onlyToken {
        diamondCycle = _diamondCycle;
        minTokenRequired = _minTokenRequired;
    }

    /**
     * @dev Set the address eligibility.
     */
    function setEligibility(address holder, bool eligible) external override onlyToken {
        if (diamonds[holder].eligible == true && diamonds[holder].eligibleTime + diamondCycle <= previousCycleEnd) {
            distributeDiamond(holder);
        }

        if (eligible == true && diamonds[holder].eligible == false) {
            addHolder(holder);
        } else if (eligible == false && diamonds[holder].eligible == true) {
            removeHolder(holder);
        }

        diamonds[holder].eligible = eligible;
    } 

    function process(uint256 gas) external override onlyToken {
        uint256 holderCount = holders.length;

        if (holderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < holderCount) {
            if (currentIndex >= holderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(holders[currentIndex])) {
                distributeDiamond(holders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address holder) internal view returns (bool) {
        return diamonds[holder].eligible == true && diamonds[holder].eligibleTime + diamondCycle <= previousCycleEnd;
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = rewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens {
            value: _msgValue()
        } (0, path, address(this), block.timestamp);

        uint256 current = rewardToken.balanceOf(address(this));
        uint256 amount = current.sub(balanceBefore);

        totalDiamonds = totalDiamonds.add(amount);
        diamondsPerHolder = diamondsPerHolderAccuracyFactor.mul(current).div(holders.length);
    }


    /**
     * @dev Distribute diamond to the holders and update diamond information.
     */
    function distributeDiamond(address holder) internal {
        if (diamonds[holder].eligible == false) {
            return;
        }

        uint256 amount = getUnpaidEarnings(holder);

        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            rewardToken.transfer(holder, amount);
            diamonds[holder].eligibleTime == previousCycleEnd;
            diamonds[holder].totalRealised = diamonds[holder].totalRealised.add(amount);
        }
    }
    
    /**
     * @dev Get the cumulative dividend for the given share.
     */
    function getCumulativeDiamonds() internal returns (uint256) {

        if (block.timestamp > diamondCycleEnd) {
            previousCycleEnd = diamondCycleEnd;
            diamondCycleStart = previousCycleEnd;
            diamondCycleEnd = previousCycleEnd + diamondCycle;

            uint256 current = rewardToken.balanceOf(address(this));
            diamondsPerHolder = diamondsPerHolderAccuracyFactor.mul(current).div(holders.length);
            return diamondsPerHolder;
        }

        return diamondsPerHolder;
    }
    
    /**
     * @dev Get unpaid diamond that needed to be distributed for the given address.
     */
    function getUnpaidEarnings(address holder) internal returns (uint256) {
        if (diamonds[holder].eligible == false) {
            return 0;
        }

        return getCumulativeDiamonds();
    }

    /**
     * @dev Add the address to the array of holders.
     */
    function addHolder(address holder) internal {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
        diamonds[holder].eligibleTime == block.timestamp;
    }

    /**
     * @dev Remove the address from the array of holders.
     */
    function removeHolder(address holder) internal {
        holders[holderIndexes[holder]] = holders[holders.length - 1];
        holderIndexes[holders[holders.length - 1]] = holderIndexes[holder];
        holders.pop();
        diamonds[holder].eligibleTime == block.timestamp;
    }


}



/** REVOLUZION TOKEN **/

contract Revoluzion is IERC20Extended, Auth {


    /* LIBRARY*/
    using SafeMath for uint256;
    using Address for address;


    /* DATA */
    DividendDistributor public distributor;
    DiamondDistributor public diamond;
    IUniswapV2Router02 public router;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    address public rewardToken;
    address public pair;
    uint256 public distributorGas;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 public liquidityFee;
    uint256 public buybackFee;
    uint256 public reflectionFee;
    uint256 public marketingFee;
    uint256 public diamondFee;
    uint256 public totalFee;
    uint256 public feeDenominator;

    uint256 public targetLiquidity;
    uint256 public targetLiquidityDenominator;

    uint256 public buybackMultiplierNumerator;
    uint256 public buybackMultiplierDenominator;
    uint256 public buybackMultiplierTriggeredAt;
    uint256 public buybackMultiplierLength;
    bool public autoBuybackEnabled;
    uint256 public autoBuybackCap;
    uint256 public autoBuybackAccumulator;
    uint256 public autoBuybackAmount;
    uint256 public autoBuybackBlockPeriod;
    uint256 public autoBuybackBlockLast;
    
    bool inSwap;
    bool public swapEnabled; 
    uint256 public swapThreshold;


    /* MAPPING */
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public buyBacker;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public diamondEligibility;


    /* EVENT */
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    event TokenCreated(address indexed owner, address indexed token);

    
    /* MODIFIER */
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyBuybacker() {
        require(buyBacker[_msgSender()] == true, "Not a buybacker");
        _;
    }


    /* CONSTRUCTOR */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, DividendDistributor distributor_, DiamondDistributor diamond_, address rewardToken_, address router_, uint256[6] memory feeSettings_) payable Auth(_msgSender()) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * 10**_decimals;

        rewardToken = rewardToken_;
        router = IUniswapV2Router02(router_);
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        _initializeFees(feeSettings_);
        _initializeLiquidityBuyBack();
        _initializeDistributor(distributor_);
        _initializeDiamond(diamond_);

        distributorGas = 500000;
        swapEnabled = true;
        swapThreshold = _totalSupply / 20000; // 0.005%

        isFeeExempt[_msgSender()] = true;

        isDividendExempt[_msgSender()] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        diamondEligibility[_msgSender()] = false;
        diamondEligibility[pair] = false;
        diamondEligibility[address(this)] = false;
        diamondEligibility[DEAD] = false;
        
        buyBacker[_msgSender()] = true;

        autoLiquidityReceiver = _msgSender();
        marketingFeeReceiver = _msgSender();

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        emit TokenCreated(_msgSender(), address(this));

    }


    /* FUNCTION */

    receive() external payable {}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    
    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }

    // ERC20 standard related functions.

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(_msgSender(), recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][_msgSender()] != _totalSupply) {
            _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }
        if (shouldAutoBuyback()) {
            triggerAutoBuyback();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        if (!diamondEligibility[sender]) {
            if (balanceOf(sender) >= diamond.minTokenRequired()) {
                try diamond.setEligibility(sender, true) {} catch {}
            } else {
                try diamond.setEligibility(sender, false) {} catch {}
            }
        }
        if (!diamondEligibility[recipient]) {
            if (balanceOf(sender) >= diamond.minTokenRequired()) {
                try diamond.setEligibility(recipient, true) {} catch {}
            } else {
                try diamond.setEligibility(recipient, false) {} catch {}
            }
        }

        try distributor.process(distributorGas) {} catch {}
        try diamond.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Conditional check related function.

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function shouldSwapBack() internal view returns (bool) {
        return _msgSender() != pair && !inSwap && swapEnabled && _balances[address(this)] >= swapThreshold;
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return _msgSender() != pair && !inSwap && autoBuybackEnabled && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number && address(this).balance >= autoBuybackAmount;
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    } 

    // Fees related functions.

    /**
     * @dev Set all the fee settings during contract initialization.
     * 
     * NOTE:
     * 0 - Liquidity fee
     * 1 - Buyback fee
     * 2 - Reflection fee
     * 3 - Marketing fee
     * 4 - Diamond fee
     * 5 - Fee denominator
     */
    function _initializeFees(uint256[6] memory feeSettings_) internal {
        _setFees(feeSettings_[0], feeSettings_[1], feeSettings_[2], feeSettings_[3], feeSettings_[4], feeSettings_[5]);
    }

    /**
     * @dev Set all the fee settings.
     */
    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _diamondFee, uint256 _feeDenominator) public authorized {
        _setFees(_liquidityFee, _buybackFee, _reflectionFee, _marketingFee, _diamondFee, _feeDenominator);
    }

    /**
     * @dev Run internally to set all the fee settings and ensure that total fee is not more than 15%. 
     */
    function _setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _diamondFee, uint256 _feeDenominator) internal {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        diamondFee = _diamondFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee).add(_diamondFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator.div(100).mul(15), "Total fee should not be greater than 15%.");
    }

    /**
     * @dev Set all the addresses that will receive fee — liquidity, marketing, diamond hand rewards.
     */
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    /**
     * @dev Set isFeeExempt boolean for the given address.
     */
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (selling) {
            return getMultipliedFee();
        }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        if (buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp) {
            uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
            uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
            return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
        }
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    // Diamond related functions.

    function _initializeDiamond(DiamondDistributor diamond_) internal {
        diamond = DiamondDistributor(diamond_);
    }

    function diamondInitialization(bool initialized) public authorized {
        diamond.unInitialized(initialized);
    }

    function setDiamondDistributor(address diamond_) public authorized {
        diamond.unInitialized(false);
        diamond.setTokenAddress(_msgSender());
        diamond = DiamondDistributor(diamond_);
    }

    /**
     * @dev Set diamondEligiblity boolean for the given address.
     */
    function setIsDiamondExempt(address holder, bool eligible) external authorized {
        diamondEligibility[holder] = eligible;

        if (eligible) {
            diamond.setEligibility(holder, false);
        } else {
            diamond.setEligibility(holder, true);
        }
    }

    function setDiamondCriteria(uint256 _diamondCycle, uint256 _minTokenRequired) external authorized {
        diamond.setDiamondCriteria(_diamondCycle, _minTokenRequired);
    }

    // Dividend related functions.

    function _initializeDistributor(DividendDistributor distributor_) internal {
        distributor = DividendDistributor(distributor_);
    }

    function distributorInitialization(bool initialized) public authorized {
        distributor.unInitialized(initialized);
    }

    function setDividendDistributor(address distributor_) public authorized {
        distributor.unInitialized(false);
        distributor.setTokenAddress(_msgSender());
        distributor = DividendDistributor(distributor_);
    }

    /**
     * @dev Set isDividendExempt boolean and dividend share for the given address.
     * 
     * REQUIREMENT:
     * - Address must not be the token address.
     * - Address must not be token pair address.
     *
     * NOTE:
     * Token address, token pair address and dead address are automatically exempted from dividend during contract initialization.
     */
    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;

        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function claimDividend() external {
        distributor.claimDividend();
    }

    // Liquidity related functions.

    function _initializeLiquidityBuyBack() internal {
        targetLiquidity = 25;
        targetLiquidityDenominator = 100;

        buybackMultiplierNumerator = 200;
        buybackMultiplierDenominator = 100;
        buybackMultiplierLength = 30 minutes;
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    // Swapback related functions.

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBDiamond = amountBNB.mul(diamondFee).div(totalBNBFee);

        try distributor.deposit {
            value: amountBNBReflection
        } () {} catch {}

        try diamond.deposit {
            value: amountBNBDiamond
        } () {} catch {}

        payable(marketingFeeReceiver).transfer(amountBNBMarketing);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{
                value: amountBNBLiquidity
            } (address(this), amountToLiquify, 0, 0, autoLiquidityReceiver, block.timestamp);
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    // Buyback related functions

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function setBuyBacker(address acc, bool add) external authorized {
        buyBacker[acc] = add; 
    }

    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }
    
    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if (autoBuybackAccumulator > autoBuybackCap) {
            autoBuybackEnabled = false;
        }
    }

    function triggerZeusBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if (triggerBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens {
            value: amount
        } (0, path, to, block.timestamp);
    }

}