/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


// libraries

/* ---------- START OF IMPORT SafeMath.sol ---------- */




// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero,but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting with custom message on
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
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
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
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}
/* ------------ END OF IMPORT SafeMath.sol ---------- */


/* ---------- START OF IMPORT Address.sol ---------- */





library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others,`isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived,but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052,0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code,i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`,forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes,possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`,making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`,care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient,uint256 amount/*,uint256 gas*/) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls,avoid-call-value
        (bool success,) = recipient.call{ value: amount/* ,gas: gas*/}("");
        require(success,"Address: unable to send value");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason,it is bubbled up by this
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
    function functionCall(address target,bytes memory data) internal returns (bytes memory) {
        return functionCall(target,data,"Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target,data,0,errorMessage);
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
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target,data,value,"Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`],but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target,data,value,errorMessage);
    }

    function _functionCallWithValue(address target,bytes memory data,uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target),"Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32,returndata),returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
/* ------------ END OF IMPORT Address.sol ---------- */


// extensions

/* ---------- START OF IMPORT Context.sol ---------- */




abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    // @dev Returns information about the value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;// silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* ------------ END OF IMPORT Context.sol ---------- */


// interfaces

/* ---------- START OF IMPORT IFlavors.sol ---------- */




interface IFlavors {

  function isLiquidityPool(address holder) external returns (bool);

  function presaleClaim(address presaleContract, uint256 amount) external returns (bool);
  function spiltMilk_OC(uint256 amount) external;
  function creamAndFreeze_OAUTH() external payable;

  //onlyBridge
  function setBalance_OB(address holder, uint256 amount) external returns (bool);
  function addBalance_OB(address holder, uint256 amount) external returns (bool);
  function subBalance_OB(address holder, uint256 amount) external returns (bool);

  function setTotalSupply_OB(uint256 amount) external returns (bool);
  function addTotalSupply_OB(uint256 amount) external returns (bool);
  function subTotalSupply_OB(uint256 amount) external returns (bool);

  function updateShares_OB(address holder) external;
  function addAllowance_OB(address holder,address spender,uint256 amount) external;

  //onlyOwnableFlavors
  function updateBridge_OO(address new_bridge) external;
  function updateRouter_OO(address new_router) external returns (address);
  function updateCreamery_OO(address new_creamery) external;
  function updateDripper0_OO(address new_dripper0) external;
  function updateDripper1_OO(address new_dripper1) external;
  function updateIceCreamMan_OO(address new_iceCreamMan) external;

  //function updateBridge_OAD(address new_bridge,bool bridgePaused) external;
  function decimals() external view returns (uint8);
  function name() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function symbol() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

  function getFees() external view returns (
      uint16 fee_flavor0,
      uint16 fee_flavor1,
      uint16 fee_creamery,
      uint16 fee_icm,
      uint16 fee_totalBuy,
      uint16 fee_totalSell,
      uint16 FEE_DENOMINATOR
  );

  function getGas() external view returns (
      uint32 gas_dripper0,
      uint32 gas_dripper1,
      uint32 gas_icm,
      uint32 gas_creamery,
      uint32 gas_withdrawa
  );

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender, uint256 value);
}
/* ------------ END OF IMPORT IFlavors.sol ---------- */


/* ---------- START OF IMPORT IOwnableFlavors.sol ---------- */




/**
@title IOwnableFlavors
@author iceCreamMan
@notice The IOwnableFlavors interface is an interface to a
    modified stand-alone version of the standard
    Ownable.sol contract by openZeppelin.  Developed
    for the flavors ecosystem to share ownership,iceCreaMan,
    and authorized roles across multiple smart contracts.
    See ownableFlavors.sol for additional information.
 */

interface IOwnableFlavors {
    function isAdmin(address addr) external returns (bool);
    function isAuthorized(address addr) external view returns (bool);

    function upgrade(
        address owner,
        address iceCreamMan,
        address bridge,
        address flavor0,
        address flavor1,
        address dripper0,
        address dripper1,
        address creamery,
        address bridgeTroll,
        address flavorsToken,
        address flavorsChainData,
        address pair
    ) external;

    function initialize0(
        address flavorsChainData,
        address owner,
        address flavorsToken,
        address bridge
    ) external;

    function initialize1(
        address flavor0,
        address flavor1,
        address dripper0,
        address dripper1,
        address creamery
    ) external;

    function updateDripper0_OAD(
        address new_flavor0,
        bool new_isCustomBuy0,
        address new_dripper0,
        address new_customBuyerContract0
    ) external returns(bool);

    function updateDripper1_OAD(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_dripper1,
        address new_customBuyerContract1
    ) external returns(bool);

    //function updateDripper1_OAD(address addr) external;
    //function updateFlavorsToken_OAD(address new_flavorsToken) external;
    //function updateFlavor0_OA(address addr) external;
    //function updateFlavor1_OA(address addr) external;
    //function updateTokenAddress(address addr) external;
    //function acceptOwnership() external;
    //function transferOwnership(address addr) external;
    //function renounceOwnership() external;
    //function acceptIceCreamMan() external;
    //function transferICM_OICM(address addr) external;
    //function grantAuthorization(address addr) external;
    //function revokeAuthorization(address addr) external;
    //function updatePair_OAD(address pair) external;
    //function updateBridgeTroll_OAD(address new_bridgeTroll) external;
    //function updateBridge_OAD(address new_bridge, address new_bridgeTroll) external;

    function pair() external view returns(address);
    function owner() external view returns(address);
    function bridge() external view returns(address);
    function router() external view returns(address);
    function ownable() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);
    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function creamery() external view returns(address);
    function bridgeTroll() external view returns(address);
    function iceCreamMan() external view returns(address);
    function flavorsToken() external view returns(address);
    function wrappedNative() external view returns(address);
    function pending_owner() external view returns(address);
    function flavorsChainData() external view returns(address);
    function pending_iceCreamMan() external view returns(address);
    function customBuyerContract0() external view returns(address);
    function customBuyerContract1() external view returns(address);
}
/* ------------ END OF IMPORT IOwnableFlavors.sol ---------- */


/* ---------- START OF IMPORT IERC20.sol ---------- */




/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}
/* ------------ END OF IMPORT IERC20.sol ---------- */


/* ---------- START OF IMPORT IWrappedNative.sol ---------- */



interface IWrappedNative {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    // wrappedNative specific
    function deposit() external payable;
    function withdraw(uint) external;
}
/* ------------ END OF IMPORT IWrappedNative.sol ---------- */


/* ---------- START OF IMPORT IDEXRouter.sol ---------- */




interface IDEXRouter {
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
    ) external returns (uint amountA,uint amountB,uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken,uint amountETH,uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken,uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountToken,uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA,uint reserveA,uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn,uint reserveIn,uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut,uint reserveIn,uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn,address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut,address[] calldata path) external view returns (uint[] memory amounts);
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
        bool approveMax,uint8 v,bytes32 r,bytes32 s
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
/* ------------ END OF IMPORT IDEXRouter.sol ---------- */



/**
@title Creamery
@author iceCreamMan
@notice The Creamery serves as a multipurpose automated accounting department.
    - Accepts external payments from marketing partners,
    - Stores funds,
    - Processes Liquidity Injections,
    - Holds Liquidity Pool Tokens,
    - Stores recurring payment information,
    - Processes team member recurring payments,
    - processes one time payments
*/

contract Creamery is Context{
    using Address for address;
    using SafeMath for uint256;
  
    //IDEXRouter router;
    address public owner;
    address public iceCreamMan;
    address public ownable;
    address public router;
    address public flavorsToken;
    address public wrappedNative;

    IDEXRouter internal Router;
    IFlavors internal FlavorsToken;
    IOwnableFlavors internal Ownable;
    IWrappedNative internal WrappedNative;

    uint256 internal launchedAtBlock;
    uint256 internal launchedAtTimestamp;
    uint256 internal periodLength = 7 days;
    
    uint256 internal gas;

    bool internal initialized = false;
    bool internal functionLocked = false;

    uint256 internal totalWithdrawn;
    uint256 internal totalDeposits;
    uint256 internal totalSpiltMilk;
    uint256 internal totalSentToCreamAndFreeze;

    function getStats() external view returns (
        uint256 totalWithdrawn_,
        uint256 totalDeposits_,
        uint256 totalSpiltMilk_,
        uint256 totalSentToCreamAndFreeze_,
        uint256 gas_,
        uint256 launchedAtBlock_,
        uint256 launchedAtTimestamp_,
        uint256 periodLength_,
        bool initialized_
    )
    {
        return (
            totalWithdrawn,
            totalDeposits,
            totalSpiltMilk,
            totalSentToCreamAndFreeze,
            gas,
            launchedAtBlock,
            launchedAtTimestamp,
            periodLength,
            initialized
        );
    }

    function setGas_OAD(uint256 gas_) external onlyAdmin {
        gas = gas_;
    }
  
    // store an addresses authorized withdrawal amount
    // if the recurring value is true then the amount accumulates at each period rollover.
    /** @dev for recurring payments the 'recurringAmount' is 
        added to the withdrawable every period rollover
        @dev for 1-time payments the amount is added to the 'withdrawable'
    */
    mapping(address => uint256) internal recurringAmount;
    /** @dev set false for 1-time payment*/
    // withdrawable
    mapping(address => uint256) internal withdrawable;
    // lastWithdrawalPeriod
    mapping(address => uint256) internal lastPeriodCalculated;
    // the total an address has withdrawn
    mapping(address => uint256) internal withdrawn;
    
    mapping(address => uint256) internal holderPeriodLength;

    mapping(address => bool) internal recurringPayment;
    // account authorized to withdraw
    mapping(address => bool) internal withdrawAuthorized;
    
    mapping(address => uint256) internal periodStartTimestamp;

    function buildPeriodLength(
        uint256 days_,
        uint256 hours_,
        uint256 minutes_,
        uint256 seconds_
    ) internal pure returns (uint256) {
        return (
            (days_.mul(1 days))
            .add(hours_.mul(1 hours))
            .add(minutes_.mul(1 minutes))
            .add(seconds_.mul(1 seconds))
        );
    }

    function initialize (address _ownableFlavors) public {    
        require(initialized == false,"CREAMERY: initialize() = Already Initialized");
        initialized = true;
        
        ownable = _ownableFlavors;
        Ownable = IOwnableFlavors(ownable);

        owner = Ownable.owner();
        iceCreamMan = Ownable.iceCreamMan();

        flavorsToken = Ownable.flavorsToken();
        FlavorsToken = IFlavors(Ownable.flavorsToken());

        wrappedNative = Ownable.wrappedNative();
        WrappedNative = IWrappedNative(wrappedNative);

        router = Ownable.router();
        Router = IDEXRouter(router);

    }

    function launch_OFT() external onlyFlavorsToken {
        launchedAtBlock = block.number;
        launchedAtTimestamp = block.timestamp;
    }
    
    // returns
    function getAccountData(
        address _account
    ) public view returns(
        uint256 _recurringAmount,
        bool _recurringPayment,
        uint256 _withdrawable,
        uint256 _lastPeriodCalculated,
        bool _withdrawAuthorized,
        uint256 _withdrawn
    ) {
        _recurringAmount = recurringAmount[_account];
        _recurringPayment = recurringPayment[_account];
        _withdrawable = withdrawable[_account];
        _lastPeriodCalculated = lastPeriodCalculated[_account];
        _withdrawAuthorized = withdrawAuthorized[_account];
        _withdrawn = withdrawn[_account];
    }  
  
    // forces values,except for withdrawn;
    function forceAccountData_OAD(
        address _account,
        uint256 _recurringAmount,
        bool _recurringPayment,
        uint256 _withdrawable,
        uint256 _lastPeriodCalculated,
        bool _withdrawAuthorized
    ) public onlyAdmin {
        recurringAmount[_account] = _recurringAmount;
        recurringPayment[_account] = _recurringPayment;
        withdrawable[_account] = _withdrawable;
        lastPeriodCalculated[_account] = _lastPeriodCalculated;
        withdrawAuthorized[_account] = _withdrawAuthorized;
    }


    /**
    @notice Sends a percentage of the native Coins (BNB, ETH, etc) held in the Creamery
            to the flavors token contract, where they will be paired with freshly minted
            tokens and added to the liquidity pool. Since half of the value added to the 
            liquidity pool is minted during this process, half of the LP tokens will be 
            burned. The other half will be deposited in the creamery. Withdrawal of the
            creamery LP tokens can be done by either the owner or the iceCreamMan by 
            calling 'adminTokenWithdrawal_OAD' on the 'Creamery' contract.In either case, 
            when LP tokens are removed from the creamery, they areautomatically split 
            50/50 between the owner and iceCreamMan to ensure no foul play is afoot.
    @param  percentOfCreamery First, check the native coin (BNB, ETH, etc.) balance
            held in the creamery. Then enter a whole number 0-10000. This is the percent
            of coins that will be sent from the creamery, to the LP. For example, if the
            creamery holds 100 BNB, and you want to send 50 BNB to LP, thats 50% of the
            balance, so you would enter 5000. 
            input percent = percent * 10,000
    @dev    May be called by accounts on the 'admin' list. Check the "OwnableFlavors"
            contract for more details on 'admin' accounts.
    */

    function creamAndFreezePercent_OAD(uint256 percentOfCreamery) external onlyAdmin {
        checkPercent(percentOfCreamery);
        // multiply first then divide
        _creamAndFreeze((address(this).balance).mul(percentOfCreamery).div(10000), percentOfCreamery);
    }

    function creamAndFreezeAmount_OAD(uint256 amount) external onlyAdmin {
        // multiply first then divide
        _creamAndFreeze(amount, amount.mul(10000).div(address(this).balance));
    }


    /**
    @notice Internal function which executes the creamAndFreeze procedure.
    @param value Native coin qty to send. The input value is calculated from 
            the calling creamAndFreeze function
     */
    function _creamAndFreeze(uint256 value, uint256 percentOfCreamery) internal {
        uint256 balance = address(this).balance;
        // make sure the creamery has enough funds
        checkHasBalance(balance, value);
               
        // add the amount to the running total
        _addTotalWithdrawn(value);
        _addToCreamAndFreezeTotal(value);
        // send the payment to the main flavors token and add liquidity to the pool
        FlavorsToken.creamAndFreeze_OAUTH{value: value}();
        //(bool success,) = (payable(flavorsToken)).call{ gas: gas, value: value } (abi.encodeWithSignature("creamAndFreeze()"));
        //checkTransferSuccess(success);
        emit CreamAndFreeze(_msgSender(), value, percentOfCreamery, totalSentToCreamAndFreeze);
    }
        //from here: https://docs.soliditylang.org/en/v0.6.6/types.html#members-of-addresses
        //address(nameReg).call{gas: 1000000, value: 1 ether}(abi.encodeWithSignature("register(string)", "MyName"));
    
    /**
    @notice spiltMilk can be activated by any authorized address.
    @notice Buys the flavors token and then sends them to be melted.
            Increases token price, decreases total supply, decreases
            the amount of native coin in the creamery contract by 'value'    
     */
    function spiltMilk_OAD(uint256 value) external onlyAdmin {        
        // create an empty 2 position trading path
        address[] memory path = new address[](2);
        // trade path stop 0 wraps the native coin (example: BNB => WBNB)
        path[0] = wrappedNative;
        // trade path stop 1 swaps the wrapped native token for the flavors token.
        path[1] = flavorsToken;
        // perform the swap
        // swapping native coin from the creamery's balance for the flavors token,
        // and sending the flavors tokne to the flavors token contract
        uint256[] memory amounts = Router.getAmountsOut(value, path);
        Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: value}(
            // uint amountOutMin
            0,
            // address[] calldata path,
            path,
            // address to,  
            // send the purchased tokens to the flavors token contract to be melted
            address(this),
            // uint deadline
            block.timestamp
        );
        FlavorsToken.transfer(address(FlavorsToken), amounts[1]);
        FlavorsToken.spiltMilk_OC(amounts[1]);
    }


    /**
    @notice For recurring payments, this function calculates how many pay
            periods have not been added to the withdrawable balance. Then
            it multiplies by the accounts recurring payment amount. Then 
            it adds this amount to the existing withdrawable balance.
    */
    function updateWithdrawable(address _adr) internal {
        // calculate the unpaid periods. current number of elapsed periods minus the last one calculated
        uint256 unpaidPeriods = periodsElapsed().sub(lastPeriodCalculated[_adr]);
        // calculate the unpaid amount not yet added to the withdrawable balance
        uint256 amountToAdd = unpaidPeriods.mul(recurringAmount[_adr]);
        // update the last period calculated
        lastPeriodCalculated[_adr] = periodsElapsed();
        // add the calculated amount to the total withdrawable balance
        _addWithdrawable(_adr, amountToAdd);
    }


    function authorizedWithdrawal(uint256 value) public lockWhileUsing {
        address sender = _msgSender();
        // require the account is authorized to withdraw
        checkSenderIsAuthorized(sender) ;
        // if the account gets recurring withdrawals
        if(recurringPayment[sender] == true) {
            updateWithdrawable(sender);
        }
        checkValueIsAuthorized(value);
        // update the values before the transfer
        // subtract the withdrawal amount from the account's available withdrawal amount
        _subWithdrawable(sender, value);
        // update the amount this account has withdrawn
        _addWithdrawn(sender,value);
        // add the amount to the running total
        _addTotalWithdrawn(value);
        // transfer the funds
        //(,,,, uint32 withdrawalGas) = FlavorsToken.getGas();
        // transfer the funds
        Address.sendValue(payable(sender),value);
        //(bool success,) = (payable(sender)).call{ gas: withdrawalGas, value: value } ("");
        //checkTransferSuccess(success);
        // fire the log event
        emit AuthorizedWithdrawal(sender, value);
    }

    // set the payment withdrawal period length (in seconds)      // store the value
    function setStandardPeriodLength_OAD(uint256 days_, uint256 hours_, uint256 minutes_, uint256 seconds_) external onlyAdmin{
        uint256 new_waitingPeriod_seconds = buildPeriodLength(days_, hours_, minutes_, seconds_);
        uint256 old_waitingPeriod_seconds = periodLength;
        periodLength = new_waitingPeriod_seconds;
        emit WaitingPeriodChanged(_msgSender(), old_waitingPeriod_seconds, new_waitingPeriod_seconds);
    }

    function holderPeriodsElapsed(address holder) public view returns (uint256 holderPeriodsElapsed_) {
        return ((block.timestamp).sub(periodStartTimestamp[holder])).div(holderPeriodLength[holder]);
    }

    function periodsElapsed() public view returns (uint256 periodsElapsed_) {
        return ((block.timestamp).sub(launchedAtTimestamp)).div(periodLength);
    }


    /**
    @dev gives the authorized address the ability to withdraw the native coin in the set amount
    @param _amount The Authorized Amount
    @param _adr The Authorized Address
    @param isRecurring Set 'true' for recurring & 'false' for 1-time payments
    */

    function authorizePayment_OAD(
        uint256 _amount,
        address _adr,
        bool isRecurring
    ) external onlyAdmin{
        // authorize the account to withdraw
        withdrawAuthorized[_adr] = true;
        //////////////////SITUATION 1//////////////////////////////////////
        //////////////////1-time payment///////////////////////////////////
        if(isRecurring == false) {           
            // add the authorized amount to the accounts withdrawable balance
            _addWithdrawable(_adr, _amount);
            // 🔥 fire off a log and we out.
            emit PaymentAuthorized(_msgSender(),_amount,_adr, isRecurring);
            emit AuthorizedWithdrawalRemaining(_adr,withdrawable[_adr]);
        /////////////////////SITUATION 2///////////////////////////////////
        ////////////////CHANGE A RECURRING PAYMENT/////////////////////////        
        } else if (isRecurring == true) {
            if(recurringPayment[_adr] == true){
                // calculate any past periods that haven't 
                // yet been added to the withdrawable balance
                // This also updates the lastPeriodCalculated;
                updateWithdrawable(_adr);
                // store the new recurring amount.
                recurringAmount[_adr] = _amount;
                // Withdrawable payments will accrue at the new
                // rate for the entirity of the current period.
         /////////////////SITUATION 3//////////////////////////////////////
         ////////////THIS IS A NEW RECURRING PAYMENT///////////////////////
            } else if (recurringPayment[_adr] == false) {
                // set the accounts recurringPayment status to 'true'
                recurringPayment[_adr] == true;
                // store the recurring amount
                recurringAmount[_adr] = _amount;
                // set the most recent period to this period
                lastPeriodCalculated[_adr] = periodsElapsed();
                // withdrawable payments will start accruing at the 
                // next waiting period rollover.🔥 Fire a log:
                emit PaymentAuthorized(_msgSender(), _amount, _adr, isRecurring);
            }
        }
    }
    
    function nukeAccount_OAD(address account) external onlyAdmin {
        // revoke accounts withdrawal authorization
        withdrawAuthorized[account] = false;
        // set accounts recurring payment to zero
        recurringAmount[account] = 0;
        // set accounts last period collected to the current one
        lastPeriodCalculated[account] = periodsElapsed();
        // set accounts remaining withdrawable balance to zero
        withdrawable[account] = 0;
        // set accounts recurring payment to false
        recurringPayment[account] = false;
    }

    function adminWithdrawalValue_OAD(uint256 value) external onlyAdmin {
        _adminWithdrawal(value);
    }

    /** @dev divide percent by 100 to display on a dApp properly
        input percent should be the percent * 10000.
        for example: 
            5% = .05    =>    .05*10000 = 500
            So for 5% you would enter 500
    */
    function adminWithdrawalPercent_OAD(uint256 percentOfCreamery) external onlyAdmin {
        checkPercent(percentOfCreamery);
        _adminWithdrawal((address(this).balance).mul(percentOfCreamery).div(10000));
    }

    function _adminWithdrawal(uint256 value) internal {
        // revert if the creamery doesn't have enough of the native coin
        checkHasBalance(address(this).balance, value);
        // transfer the requested native token from the creamery to the admin account
        _addTotalWithdrawn(value);
        Address.sendValue(payable(_msgSender()),value);
        // 🔥 fire the log
        emit AdminWithdrawal(_msgSender(), value);
    }

    function adminTokenWithdrawal_OAD(
        address token,
        uint256 amount
    )
        public
        onlyAdmin
    {
        // initialize the ERC20 instance
        IERC20 ERC20Instance = IERC20(token);
        // make sure the creamery holds the requested balance
        checkHasBalance(ERC20Instance.balanceOf(address(this)),amount);
        /* prevent internal misuse or a comprised account and split any
            liquidity withdrawals between the iceCreamMan and owner.
        */        
        if(FlavorsToken.isLiquidityPool(token)){
            uint256 halfAmount = amount.div(2);
            ERC20Instance.transfer(iceCreamMan, halfAmount);
            ERC20Instance.transfer(owner, halfAmount);
        }

        emit AdminTokenWithdrawal(_msgSender(), amount, token);
    }


    function checkHasBalance(
        uint256 holderBalance,
        uint256 value
    )
        internal
        pure
    {
        require(
            holderBalance >= value,
            "CREAMERY: checkHasBalance() = insufficient funds"
        );
    }


    function checkSenderIsAuthorized(address msgSender) internal view {
        require (
            withdrawAuthorized[msgSender] == true,
            "CREAMERY: authorizedWithdrawal() = not authorized to withdraw"
        );
    }

    function checkValueIsAuthorized(uint256 value) internal view {
        require (
            value <= withdrawable[_msgSender()],
            "CREAMERY: authorizedWithdrawal() = insufficient funds"
        );
    }

    
    function checkTransferSuccess(bool success) internal pure {
        require(
            success,
            "CREAMERY: checkTransferSuccess() - transferFailed"
        );
     }
     
    /** @dev divide percent by 100 to display on a dApp properly
        input percent should be the percent * 10000.
        for example: 
            5% = .05    =>    .05*10000 = 500
            So for 5% you would enter 500
    */
    function checkPercent(uint256 percent) internal pure {
        require(0 <= percent && percent <= 10000,
            "CREAMERY: enter percent * 10000 For example: 5% = 500"
        );
    }

//iceCreamMan == _msgSender() || owner == _msgSender()
    ///@notice modifiers
    modifier lockWhileUsing() { require(functionLocked == false, "CREAMERY: lockWhileUsing() = function locked while in use" );functionLocked = true;_;functionLocked = false;}
    modifier onlyFlavorsToken() { require(flavorsToken == _msgSender(), "CREAMERY: onlyFlavorsToken() = caller not flavors token");_;}
    modifier onlyAuthorized() { require(Ownable.isAuthorized(_msgSender()), "CREAMERY: authorized() = caller not authorized" );_;}
    modifier onlyOwnable() { require(ownable == _msgSender(), "CREAMERY: onlyOwnable() = caller not ownableFlavors" );_;}
    modifier onlyIceCreamMan() { require(iceCreamMan == _msgSender(), "CREAMERY: onlyIceCreamMan() = caller not iceCreamMan" );_;}  
    modifier onlyAdmin() { require(Ownable.isAdmin(_msgSender()), "CREAMERY: onlyAdmin() = caller not admin" );_;}
  
    function nativeCoinBalance() public view returns (uint256) { return address(this).balance;}

    /**
    @notice external function to update the ownable address
    @notice onlyAdmin
    @dev the new address must be a valid ownableFlavors contract following the same abi or this will fail
    @param new_ownableFlavors The Address of the new ownableFlavors.sol contract    
     */
    function updateOwnable_OAD(address new_ownableFlavors) external onlyAdmin {
        _updateOwnable(new_ownableFlavors);
    }

    function _updateOwnable(address new_ownableFlavors) internal {
        emit OwnableFlavorsUpdated(address(Ownable),new_ownableFlavors);
        ownable = new_ownableFlavors;
        Ownable = IOwnableFlavors(new_ownableFlavors);
    }

    /**
      @notice external function to update the iceCreamMan address
      @notice onlyOwnableFlavors
      @dev Most calls for the iceCreamMan address are sent directly to OwnableFlavors.
           The only reason we need to store the iceCreamMan in this contract, is so
           during an OwnableFlavors contract upgrade, we can ensure the new OwnableFlavors
           contains the same iceCreamMan as before.
      @param new_iceCreamMan The address of the new iceCreamMan
    */
    function updateIceCreamMan_OO(address new_iceCreamMan) external onlyOwnable {
        emit IceCreamManUpdated(iceCreamMan, new_iceCreamMan);
        iceCreamMan = new_iceCreamMan;
    }

    /**
      @notice external function to update the owner address
      @notice onlyOwnableFlavors
      @dev Most calls for the owner address are sent directly to OwnableFlavors.
           The only reason we need to store the owner in this contract, is so
           during an OwnableFlavors contract upgrade, we can ensure the new OwnableFlavors
           contains the same owner as before.
      @param new_owner The address of the new owner
    */
    function updateOwner_OO(address new_owner) external onlyOwnable {
        emit OwnerUpdated(owner, new_owner);
        owner = new_owner;
    }
    event OwnerUpdated(address old_owner, address new_owner);
    event IceCreamManUpdated(address old_iceCreamMan, address new_iceCreamMan);
    event OwnableFlavorsUpdated(address old_ownableFlavors,address new_ownableFlavors);

    function _addWithdrawable(address acct, uint256 amount) internal { withdrawable[acct] = withdrawable[acct].add(amount);emit AddWithdrawable(acct, amount, withdrawable[acct]);}    
    function _subWithdrawable(address acct, uint256 amount) internal { withdrawable[acct] = withdrawable[acct].sub(amount,"CREAMERY: _subWithdrawable() = Insufficient Withdrawable Balance");emit SubWithdrawable(acct, amount, withdrawable[acct]);}
    function _addTotalWithdrawn(uint256 amount) internal { totalWithdrawn = totalWithdrawn.add(amount);emit GlobalWithdrawn(totalWithdrawn);}
    function _addTotalDeposits(uint256 amount) internal { totalDeposits = totalDeposits.add(amount);emit TotalDeposits(totalDeposits);}
    function _addWithdrawn(address acct, uint256 amount) internal { withdrawn[acct] = withdrawn[acct].add(amount);emit AddWithdrawn(acct, amount, withdrawn[acct]);}
    function _addToCreamAndFreezeTotal(uint256 amountAdded) internal { totalSentToCreamAndFreeze = totalSentToCreamAndFreeze.add(amountAdded);}
    function _addToSpiltMilkTotal(uint256 amountAdded) internal { totalSpiltMilk = totalSpiltMilk.add(amountAdded);}
  
    ///@notice events
    event CreamAndFreeze(address authorizedBy, uint256 nativeCoinSentToLP, uint256 percentOfCreamery, uint256 totalSentToCreamAndFreeze);
    event PaymentAuthorized(address authorizedBy, uint256 amount, address authorizedAccount, bool recurringPayment);
    event AdminWithdrawal(address withdrawalBy, uint256 value);
    event AdminTokenWithdrawal(address withdrawalBy, uint256 amount, address token);
    event AuthorizedWithdrawalRemaining(address account,uint256 amount);
    event AuthorizedWithdrawal(address account, uint256 amount);
    event DepositReceived(address from, uint256 amount, string note0, string note1);
    event AddWithdrawn(address account, uint256 justWithdrew, uint256 totalWithdrawn);
    event AddWithdrawable(address account, uint256 amountAdded, uint256 withdrawableBalance);
    event SubWithdrawable(address account, uint256 amountSubtracted, uint256 withdrawableBalance);
    event GlobalWithdrawn(uint256 amount);
    event TotalDeposits(uint256 amount);
    event WaitingPeriodChanged(address changedBy, uint256 old_waitingPeriod_seconds, uint256 new_waitingPeriod_seconds);
    
    


    function deposit(string memory note) public payable {
        _addTotalDeposits(_msgValue());
        emit DepositReceived(_msgSender(),_msgValue(),"CREAMERY: Payment Received", note);
    }


    fallback() external payable { deposit("They Didn't Leave A Note");}
    receive() external payable { deposit("They Didn't Leave A Note");}
}