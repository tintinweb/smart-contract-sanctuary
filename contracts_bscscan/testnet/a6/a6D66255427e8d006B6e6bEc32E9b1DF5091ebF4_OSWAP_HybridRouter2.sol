/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/router/interfaces/IOSWAP_HybridRouter2.sol


pragma solidity =0.6.11;

interface IOSWAP_HybridRouter2 {

    function registry() external view returns (address);
    function WETH() external view returns (address);

    function getPathIn(address[] calldata pair, address tokenIn) external view returns (address[] memory path);
    function getPathOut(address[] calldata pair, address tokenOut) external view returns (address[] memory path);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata pair,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external returns (address[] memory path, uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata pair,
        address tokenOut,
        address to,
        uint deadline,
        bytes calldata data
    ) external returns (address[] memory path, uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        payable
        returns (address[] memory path, uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        returns (address[] memory path, uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        returns (address[] memory path, uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        payable
        returns (address[] memory path, uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bytes calldata data
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bytes calldata data
    ) external;

    function getAmountsInStartsWith(uint amountOut, address[] calldata pair, address tokenIn, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsInEndsWith(uint amountOut, address[] calldata pair, address tokenOut, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsOutStartsWith(uint amountIn, address[] calldata pair, address tokenIn, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsOutEndsWith(uint amountIn, address[] calldata pair, address tokenOut, bytes calldata data) external view returns (uint[] memory amounts);
}


// File contracts/libraries/SafeMath.sol



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


// File contracts/libraries/Address.sol



pragma solidity =0.6.11;

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


// File contracts/interfaces/IERC20.sol


pragma solidity =0.6.11;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/interfaces/IWETH.sol


pragma solidity =0.6.11;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/router/interfaces/IOSWAP_HybridRouterRegistry.sol


pragma solidity =0.6.11;

interface IOSWAP_HybridRouterRegistry {
    event ProtocolRegister(address indexed factory, bytes32 name, uint256 fee, uint256 feeBase, uint256 typeCode);
    event PairRegister(address indexed factory, address indexed pair, address token0, address token1);
    event CustomPairRegister(address indexed pair, uint256 fee, uint256 feeBase, uint256 typeCode);

    struct Protocol {
        bytes32 name;
        uint256 fee;
        uint256 feeBase;
        uint256 typeCode;
    }
    struct Pair {
        address factory;
        address token0;
        address token1;
    }
    struct CustomPair {
        uint256 fee;
        uint256 feeBase;
        uint256 typeCode;
    }


    function protocols(address) external view returns (
        bytes32 name,
        uint256 fee,
        uint256 feeBase,
        uint256 typeCode
    );
    function pairs(address) external view returns (
        address factory,
        address token0,
        address token1
    );
    function customPairs(address) external view returns (
        uint256 fee,
        uint256 feeBase,
        uint256 typeCode
    );
    function protocolList(uint256) external view returns (address);
    function protocolListLength() external view returns (uint256);

    function governance() external returns (address);

    function registerProtocol(bytes32 _name, address _factory, uint256 _fee, uint256 _feeBase, uint256 _typeCode) external;

    function registerPair(address token0, address token1, address pairAddress, uint256 fee, uint256 feeBase, uint256 typeCode) external;
    function registerPairByIndex(address _factory, uint256 index) external;
    function registerPairsByIndex(address _factory, uint256[] calldata index) external;
    function registerPairByTokens(address _factory, address _token0, address _token1) external;
    function registerPairByTokensV3(address _factory, address _token0, address _token1, uint256 pairIndex) external;
    function registerPairsByTokens(address _factory, address[] calldata _token0, address[] calldata _token1) external;
    function registerPairsByTokensV3(address _factory, address[] calldata _token0, address[] calldata _token1, uint256[] calldata pairIndex) external;
    function registerPairByAddress(address _factory, address pairAddress) external;
    function registerPairsByAddress(address _factory, address[] memory pairAddress) external;
    function registerPairsByAddress2(address[] memory _factory, address[] memory pairAddress) external;

    function getPairTokens(address[] calldata pairAddress) external view returns (address[] memory token0, address[] memory token1);
    function getTypeCode(address pairAddress) external view returns (uint256 typeCode);
    function getFee(address pairAddress) external view returns (uint256 fee, uint256 feeBase);
}


// File contracts/commons/interfaces/IOSWAP_PausableFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_PausableFactory {
    event Shutdowned();
    event Restarted();
    event PairShutdowned(address indexed pair);
    event PairRestarted(address indexed pair);

    function governance() external view returns (address);

    function isLive() external returns (bool);
    function setLive(bool _isLive) external;
    function setLiveForPair(address pair, bool live) external;
}


// File contracts/commons/interfaces/IOSWAP_FactoryBase.sol


pragma solidity =0.6.11;

interface IOSWAP_FactoryBase is IOSWAP_PausableFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint newSize);

    function pairCreator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// File contracts/oracle/interfaces/IOSWAP_OracleFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleFactory is IOSWAP_FactoryBase {
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event OracleAdded(address indexed token0, address indexed token1, address oracle);
    event OracleScores(address indexed oracle, uint256 score);
    event Whitelisted(address indexed who, bool allow);

    function oracleLiquidityProvider() external view returns (address);

    function tradeFee() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function feePerDelegator() external view returns (uint256);
    function protocolFeeTo() external view returns (address);

    function securityScoreOracle() external view returns (address);
    function minOracleScore() external view returns (uint256);

    function oracles(address token0, address token1) external view returns (address oracle);
    function minLotSize(address token) external view returns (uint256);
    function isOracle(address) external view returns (bool);
    function oracleScores(address oracle) external view returns (uint256);

    function whitelisted(uint256) external view returns (address);
    function whitelistedInv(address) external view returns (uint256);
    function isWhitelisted(address) external returns (bool);

    function setOracleLiquidityProvider(address _oracleRouter, address _oracleLiquidityProvider) external;

    function setOracle(address from, address to, address oracle) external;
    function addOldOracleToNewPair(address from, address to, address oracle) external;
    function setTradeFee(uint256) external;
    function setProtocolFee(uint256) external;
    function setFeePerDelegator(uint256 _feePerDelegator) external;
    function setProtocolFeeTo(address) external;
    function setSecurityScoreOracle(address, uint256) external;
    function setMinLotSize(address token, uint256 _minLotSize) external;

    function updateOracleScore(address oracle) external;

    function whitelistedLength() external view returns (uint256);
    function allWhiteListed() external view returns(address[] memory list, bool[] memory allowed);
    function setWhiteList(address _who, bool _allow) external;

    function checkAndGetOracleSwapParams(address tokenA, address tokenB) external view returns (address oracle, uint256 _tradeFee, uint256 _protocolFee);
    function checkAndGetOracle(address tokenA, address tokenB) external view returns (address oracle);
}


// File contracts/router/OSWAP_HybridRouter2.sol


pragma solidity =0.6.11;







interface IOSWAP_PairV1 {
    function getReserves() external view returns (uint112, uint112, uint32);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

interface IOSWAP_PairV2 {
    function getLastBalances() external view returns (uint256, uint256);
    function getAmountOut(address tokenIn, uint256 amountIn, bytes calldata data) external view returns (uint256 amountOut);
    function getAmountIn(address tokenOut, uint256 amountOut, bytes calldata data) external view returns (uint256 amountIn);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

interface IOSWAP_PairV3 {
    function getLastBalances() external view returns (uint256, uint256);
    function getAmountOut(address tokenIn, uint256 amountIn, address trader, bytes calldata data) external view returns (uint256 amountOut);
    function getAmountIn(address tokenOut, uint256 amountOut, address trader, bytes calldata data) external view returns (uint256 amountIn);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, address trader, bytes calldata data) external;
}

interface IOSWAP_PairV4 is IOSWAP_PairV1 {
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
}

contract OSWAP_HybridRouter2 is IOSWAP_HybridRouter2 {
    using SafeMath for uint;

    address public immutable override registry;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _registry, address _WETH) public {
        registry = _registry;
        WETH = _WETH;
    }
    
    receive() external payable {
        require(msg.sender == WETH, 'TRANSFER_FAILED'); // only accept ETH via fallback from the WETH contract
    }

    function getPathIn(address[] calldata pair, address tokenIn) public override view returns (address[] memory path) {
        uint256 length = pair.length;
        require(length > 0, 'INVALID_PATH');
        path = new address[](length + 1);
        path[0] = tokenIn;
        (address[] memory token0, address[] memory token1) = IOSWAP_HybridRouterRegistry(registry).getPairTokens(pair);
        for (uint256 i = 0 ; i < length ; i++) {
            path[i + 1] = _findToken(token0[i], token1[i], tokenIn);
            tokenIn = path[i + 1];
        }
    }
    function getPathOut(address[] calldata pair, address tokenOut) public override view returns (address[] memory path) {
        uint256 length = pair.length;
        require(length > 0, 'INVALID_PATH');
        path = new address[](length + 1);
        path[path.length - 1] = tokenOut;
        (address[] memory token0, address[] memory token1) = IOSWAP_HybridRouterRegistry(registry).getPairTokens(pair);
        for (uint256 i = length - 1 ; i < length ; i--) {
            path[i] = _findToken(token0[i], token1[i], tokenOut);
            tokenOut = path[i];
        }
    }
    function _findToken(address token0, address token1, address token) internal pure returns (address){
        require(token0 != address(0) && token1 != address(0), 'PAIR_NOT_DEFINED');
        if (token0 == token)
            return token1;
        else if (token1 == token)
            return token0;
        else
            revert('PAIR_NOT_MATCH');
    }
    
    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to, address[] memory pair, bytes[] memory dataChunks) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            bool direction;
            {
                (address input, address output) = (path[i], path[i + 1]);
                (address token0,) = sortTokens(input, output);
                direction = input == token0;
            }
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = direction ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pair[i + 1] : _to;
            uint256 typeCode = protocolTypeCode(pair[i]);
            if (typeCode == 1) {
                IOSWAP_PairV1(pair[i]).swap(
                    amount0Out, amount1Out, to, new bytes(0)
                );
            } else if (typeCode == 2) {
                IOSWAP_PairV2(pair[i]).swap(
                    amount0Out, amount1Out, to, dataChunks[i]
                );
            } else if (typeCode == 3) {
                IOSWAP_PairV3(pair[i]).swap(
                    amount0Out, amount1Out, to, msg.sender, dataChunks[i]
                );
            } else if (typeCode == 4) {
                IOSWAP_PairV4(pair[i]).swap(
                    amount0Out, amount1Out, to
                );                
            }
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata pair,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external virtual override ensure(deadline) returns (address[] memory path, uint[] memory amounts) {
        path = getPathIn(pair, tokenIn);
        bytes[] memory dataChunks;
        (amounts, dataChunks) = getAmountsOut(amountIn, path, pair, data);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HybridRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair[0], amounts[0]
        );
        _swap(amounts, path, to, pair, dataChunks);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata pair,
        address tokenOut,
        address to,
        uint deadline,
        bytes calldata data
    ) external virtual override ensure(deadline) returns (address[] memory path, uint[] memory amounts) {
        path = getPathOut(pair, tokenOut);
        bytes[] memory dataChunks;
        (amounts, dataChunks) = getAmountsIn(amountOut, path, pair, data);
        require(amounts[0] <= amountInMax, 'HybridRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair[0], amounts[0]
        );
        _swap(amounts, path, to, pair, dataChunks);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (address[] memory path, uint[] memory amounts)
    {
        path = getPathIn(pair, WETH);
        bytes[] memory dataChunks;
        (amounts, dataChunks) = getAmountsOut(msg.value, path, pair, data);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HybridRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        require(IWETH(WETH).transfer(pair[0], amounts[0]), 'TRANSFER_FAILED');
        _swap(amounts, path, to, pair, dataChunks);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        virtual
        override
        ensure(deadline)
        returns (address[] memory path, uint[] memory amounts)
    {
        path = getPathOut(pair, WETH);
        bytes[] memory dataChunks;
        (amounts, dataChunks) = getAmountsIn(amountOut, path, pair, data);
        require(amounts[0] <= amountInMax, 'HybridRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair[0], amounts[0]
        );
        _swap(amounts, path, address(this), pair, dataChunks);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        virtual
        override
        ensure(deadline)
        returns (address[] memory path, uint[] memory amounts)
    {
        path = getPathOut(pair, WETH);
        bytes[] memory dataChunks;
        (amounts, dataChunks) = getAmountsOut(amountIn, path, pair, data);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HybridRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair[0], amounts[0]
        );
        _swap(amounts, path, address(this), pair, dataChunks);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (address[] memory path, uint[] memory amounts)
    {
        path = getPathIn(pair, WETH);
        bytes[] memory dataChunks;
        (amounts, dataChunks) = getAmountsIn(amountOut, path, pair, data);
        require(amounts[0] <= msg.value, 'HybridRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        require(IWETH(WETH).transfer(pair[0], amounts[0]), 'TRANSFER_FAILED');
        _swap(amounts, path, to, pair, dataChunks);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to, address[] memory pair, bytes memory data) internal virtual {
        uint256 offset;
        for (uint i; i < path.length - 1; i++) {
            // (address input, address output) = (path[i], path[i + 1]);
            /* (address token0,) = */ sortTokens(path[i], path[i + 1]);
            bool direction = path[i] < path[i + 1];
            uint amountInput = IERC20(path[i]).balanceOf(pair[i]);
            uint amountOutput;

            uint256 typeCode = protocolTypeCode(pair[i]);
            address to = i < path.length - 2 ? pair[i + 1] : _to;
            if (typeCode == 1) {
                IOSWAP_PairV1 _pair = IOSWAP_PairV1(pair[i]);
                { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = _pair.getReserves();
                (uint reserveInput, uint reserveOutput) = direction ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = amountInput.sub(reserveInput);
                (uint256 fee,uint256 feeBase) = IOSWAP_HybridRouterRegistry(registry).getFee(address(_pair));
                amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput, fee, feeBase);
                }
                (uint amount0Out, uint amount1Out) = direction ? (uint(0), amountOutput) : (amountOutput, uint(0));
                _pair.swap(amount0Out, amount1Out, to, new bytes(0));
            } 
            else if (typeCode == 4) {
                IOSWAP_PairV4 _pair = IOSWAP_PairV4(pair[i]);
                { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = _pair.getReserves();
                (uint reserveInput, uint reserveOutput) = direction ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = amountInput.sub(reserveInput);
                (uint256 fee,uint256 feeBase) = IOSWAP_HybridRouterRegistry(registry).getFee(address(_pair));
                amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput, fee, feeBase);
                }
                (uint amount0Out, uint amount1Out) = direction ? (uint(0), amountOutput) : (amountOutput, uint(0));
                _pair.swap(amount0Out, amount1Out, to);
            }             
            else {
                bytes memory next;
                (offset, next) = cut(data, offset);
                {
                (uint balance0, uint balance1) = IOSWAP_PairV2(pair[i]).getLastBalances();
                amountInput = amountInput.sub(direction ? balance0 : balance1);
                }
                if (typeCode == 2) {
                    IOSWAP_PairV2 _pair = IOSWAP_PairV2(pair[i]);
                    amountOutput = _pair.getAmountOut(path[i], amountInput, next);
                    (uint amount0Out, uint amount1Out) = direction ? (uint(0), amountOutput) : (amountOutput, uint(0));
                    _pair.swap(amount0Out, amount1Out, to, next);
                } else /*if (typeCode == 3)*/ {
                    IOSWAP_PairV3 _pair = IOSWAP_PairV3(pair[i]);
                    amountOutput = _pair.getAmountOut(path[i], amountInput, msg.sender, next);
                    (uint amount0Out, uint amount1Out) = direction ? (uint(0), amountOutput) : (amountOutput, uint(0));
                    _pair.swap(amount0Out, amount1Out, to, msg.sender, next);
                }
            }
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata pair,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external virtual override ensure(deadline) {
        address[] memory path = getPathIn(pair, tokenIn);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair[0], amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, pair, data);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'HybridRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata pair,
        address to,
        uint deadline,
        bytes calldata data
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        address[] memory path = getPathIn(pair, WETH);
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        require(IWETH(WETH).transfer(pair[0], amountIn), 'TRANSFER_FAILED');
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, pair, data);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'HybridRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata pair,
        address to,
        uint deadline,
        bytes calldata data
    )
        external
        virtual
        override
        ensure(deadline)
    {
        address[] memory path = getPathOut(pair, WETH);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair[0], amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this), pair, data);
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'HybridRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }
    function protocolTypeCode(address pair) internal view returns (uint256 typeCode) {
        typeCode =  IOSWAP_HybridRouterRegistry(registry).getTypeCode(pair);
        require(typeCode > 0 && typeCode < 4, 'PAIR_NOT_REGCONIZED');
    }
    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IOSWAP_PairV1(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint256 fee, uint256 feeBase) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(feeBase).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint256 fee, uint256 feeBase) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'HybridRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(feeBase);
        uint denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }

    // every data/payload block prefixed with uint256 size, followed by the data/payload
    function cut(bytes memory data, uint256 offset) internal pure returns (uint256 nextOffset, bytes memory out) {
        assembly {
            let total := mload(data)
            offset := add(offset, 0x20)
            if or(lt(offset, total), eq(offset, total)) {
                let size := mload(add(data, offset))
                if gt(add(offset, size), total) {
                    revert(0, 0)
                }
                let mark := mload(0x40)
                mstore(0x40, add(mark, add(size, 0x20)))
                mstore(mark, size)
                nextOffset := add(offset, size)
                out := mark

                mark := add(mark, 0x20)
                let src := add(add(data, offset), 0x20)
                for { let i := 0 } lt(i, size) { i := add(i, 0x20) } {
                    mstore(add(mark, i), mload(add(src, i)))
                }

                let i := sub(size, 0x20)
                mstore(add(mark, i), mload(add(src, i)))
            }
        }
    }

    function getAmountsOut(uint amountIn, address[] memory path, address[] calldata pair, bytes calldata data)
        internal
        view
        virtual
        returns (uint[] memory amounts, bytes[] memory dataChunks)
    {
        amounts = new uint[](path.length);
        dataChunks = new bytes[](pair.length);
        amounts[0] = amountIn;
        uint256 offset;
        for (uint i; i < path.length - 1; i++) {
            uint256 typeCode = protocolTypeCode(pair[i]);
            if (typeCode == 1) {
                (uint reserveIn, uint reserveOut) = getReserves(pair[i], path[i], path[i + 1]);
                (uint256 fee,uint256 feeBase) = IOSWAP_HybridRouterRegistry(registry).getFee(pair[i]);
                amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, fee, feeBase);
            } else {
                bytes memory next;
                (offset, next) = cut(data, offset);
                if (typeCode == 2) {
                    amounts[i + 1] = IOSWAP_PairV2(pair[i]).getAmountOut(path[i], amounts[i], next);
                } else /*if (typeCode == 3)*/ {
                    amounts[i + 1] = IOSWAP_PairV3(pair[i]).getAmountOut(path[i], amounts[i], msg.sender, next);
                }
                dataChunks[i] = next;
            }
        }
    }
    function getAmountsIn(uint amountOut, address[] memory path, address[] calldata pair, bytes calldata data)
        internal
        view
        virtual
        returns (uint[] memory amounts, bytes[] memory dataChunks)
    {
        amounts = new uint[](path.length);
        dataChunks = new bytes[](pair.length);
        amounts[amounts.length - 1] = amountOut;
        uint256 offset;
        for (uint i = path.length - 1; i > 0; i--) {
            uint256 typeCode = protocolTypeCode(pair[i - 1]);
            if (typeCode == 1) {
                (uint reserveIn, uint reserveOut) = getReserves(pair[i - 1], path[i - 1], path[i]);
                (uint256 fee,uint256 feeBase) = IOSWAP_HybridRouterRegistry(registry).getFee(pair[i - 1]);
                amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, fee, feeBase);
            } else {
                bytes memory next;
                (offset, next) = cut(data, offset);
                if (typeCode == 2) {
                    amounts[i - 1] = IOSWAP_PairV2(pair[i - 1]).getAmountIn(path[i], amounts[i], next);
                } else if (typeCode == 3) {
                    amounts[i - 1] = IOSWAP_PairV3(pair[i - 1]).getAmountIn(path[i], amounts[i], msg.sender, next);
                }
                dataChunks[i - 1] = next;
            }
        }
    }

    function getAmountsInStartsWith(uint amountOut, address[] calldata pair, address tokenIn, bytes calldata data) external view override returns (uint[] memory amounts) {
        address[] memory path = getPathIn(pair, tokenIn);
        (amounts,) = getAmountsIn(amountOut, path, pair, data);
    }
    function getAmountsInEndsWith(uint amountOut, address[] calldata pair, address tokenOut, bytes calldata data) external view override returns (uint[] memory amounts) {
        address[] memory path = getPathOut(pair, tokenOut);
        (amounts,) = getAmountsIn(amountOut, path, pair, data);
    }
    function getAmountsOutStartsWith(uint amountIn, address[] calldata pair, address tokenIn, bytes calldata data) external view override returns (uint[] memory amounts) {
        address[] memory path = getPathIn(pair, tokenIn);
        (amounts,) = getAmountsOut(amountIn, path, pair, data);
    }
    function getAmountsOutEndsWith(uint amountIn, address[] calldata pair, address tokenOut, bytes calldata data) external view override returns (uint[] memory amounts) {
        address[] memory path = getPathOut(pair, tokenOut);
        (amounts,) = getAmountsOut(amountIn, path, pair, data);
    }
}