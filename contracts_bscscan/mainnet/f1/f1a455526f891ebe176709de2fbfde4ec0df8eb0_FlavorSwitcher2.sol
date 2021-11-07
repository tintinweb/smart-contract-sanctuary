/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// libraries
//
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

    function updateFlavor0_OAD(address new_flavor0, bool new_isCustomBuy0, address new_customBuyerContract0) external;
    function updateFlavor1_OAD(address new_flavor1, bool new_isCustomBuy1, address new_customBuyerContract1) external;

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


/* ---------- START OF IMPORT ICustomBuyer.sol ---------- */




/**
@title ICustomBuyer
@author iceCreamMan
@notice The ICustomBuyer interface is an interface to a contract that doesn't yet
    exist. In the event we want to reflect in a token that isn't purchased using
    the standard liquidity pool / router. We will make a custom contract who's
    receive function will automatically buy the token and send it back to the
    flavor dripper. This is to ensure that we have the ability to send and receive
    arbitrary data with the custom buyer contract when it does finaly exist. none of
    this functions have any purpose yet, and are simply placeholders for us to tie
    into later, should we need to.
 */

interface ICustomBuyer {
   function buyMeStuff0(uint256 balanceBefore, address dripFlavor, uint256 value) external;
   function buyMeStuff1(uint256 balanceBefore, address dripFlavor, uint256 value) external payable;



}
/* ------------ END OF IMPORT ICustomBuyer.sol ---------- */


/* ---------- START OF IMPORT IDEXFactory.sol ---------- */




interface IDEXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
/* ------------ END OF IMPORT IDEXFactory.sol ---------- */


/* ---------- START OF IMPORT IDEXPair.sol ---------- */




interface IDEXPair {
    event Approval(address indexed owner,address indexed spender,uint value);
    event Transfer(address indexed from,address indexed to,uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner,address spender) external view returns (uint);

    function approve(address spender,uint value) external returns (bool);
    function transfer(address to,uint value) external returns (bool);
    function transferFrom(address from,address to,uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner,address spender,uint value,uint deadline,uint8 v,bytes32 r,bytes32 s) external;

    event Mint(address indexed sender,uint amount0,uint amount1);
    event Burn(address indexed sender,uint amount0,uint amount1,address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0,uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0,uint amount1);
    function swap(uint amount0Out,uint amount1Out,address to,bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address,address) external;
}
/* ------------ END OF IMPORT IDEXPair.sol ---------- */


/* ---------- START OF IMPORT IFlavorDripper.sol ---------- */




interface IFlavorDripper {

    // onlyAdmin
    function setFlavorDistCriteria_OAD(uint256 minPeriod,uint256 minDistribution) external;
    function updateOwnableFlavors_OAD(address new_ownableFlavors) external;
    function process_OAD() external;


    function adminTokenWithdrawal_OAD(address token, uint256 amount) external;

    function setRelativeDripPriceNumerator_OAD(uint256 relativeDripPriceNumerator_) external;
    function setRelativeDripPriceDenominator_OAD(uint256 relativeDripPriceDenominator_) external;
    function getDripStatsAndSettings() external view returns (
        uint256 totalShares_,
        uint256 totalDividends_,
        uint256 totalDistributed_,
        uint256 dividendsPerShare_,

        uint256 totalDeposits_,
        uint256 minPeriod_,
        uint256 minDistribution_,
        uint256 additionalSeconds_,

        uint256 currentIndex_,
        uint256 relativeDripPriceNumerator_,
        uint256 relativeDripPriceDenominator_,
        bool initialized_
    );

    // public
    function getDripTokenInfo() external view returns(
        uint256 totalSupply,
        uint8 decimals,
        address dripToken_,
        string memory name,
        string memory symbol
    );

    function claimDividend() external;
    //function deposit(string memory note) external payable;

    // onlyCustomBuyer
    function customBuyerContractCallback_OCB(uint256 balanceBefore) external;

    // onlyFlavorsToken
    function process_OFT() external;
    function setShare_OFT(address shareholder,uint256 amount) external;
    function deposit_OFT(uint256 valueSent, string memory note) external;

    // onlyOwnable
    function updateFlavorsToken_OO(address new_flavorsToken) external;
    function updateFlavor_OO(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract
    ) external;
    function updateRouter_OO(address new_router) external;

    // onlyInitializer
    function initialize(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract,
        address new_ownableFlavors
    ) external;
}
/* ------------ END OF IMPORT IFlavorDripper.sol ---------- */


contract FlavorSwitcher2 is Context{
    using SafeMath for uint256;

    IDEXRouter public Router;
    IOwnableFlavors public OwnableFlavors;

    bool public initialized;
    address public wrappedNative;
    
    function resetNumDenom0() external onlyAdmin {
        resetNumDenom(OwnableFlavors.dripper0());
    }

    function resetNumDenom1() external onlyAdmin {
        resetNumDenom(OwnableFlavors.dripper1());
    }

    function resetNumDenom(address flavorDripper) internal {
        IFlavorDripper Dripper = IFlavorDripper(flavorDripper);
        (,,,,,,,,,
        uint256 relativeDripPriceNumerator_,
        uint256 relativeDripPriceDenominator_,
        ) = Dripper.getDripStatsAndSettings();
        Dripper.setRelativeDripPriceNumerator_OAD(relativeDripPriceNumerator_.mul(1e18).div(relativeDripPriceDenominator_));
        Dripper.setRelativeDripPriceDenominator_OAD(1e18);
    }
    
    function init(address ownableFlavors, address wrappedNative_, address router) external {
        require(initialized == false, "already initialized");
        initialized = true;
        wrappedNative = wrappedNative_;
        OwnableFlavors = IOwnableFlavors(ownableFlavors);
        Router = IDEXRouter(router);
    }

    function set(address ownableFlavors, address wrappedNative_, address router) external onlyAdmin {
        wrappedNative = wrappedNative_;
        OwnableFlavors = IOwnableFlavors(ownableFlavors);
        Router = IDEXRouter(router);
    }

    /**
        @param newFlavor_ the address of the new flavor
     */
    function flavorSwitch0_OAD(
        address newFlavor_
    )
        external
        onlyAdmin
    {
        resetNumDenom(OwnableFlavors.dripper0());
        flavorSwitch(
            OwnableFlavors.dripper0(),
            newFlavor_,
            OwnableFlavors.flavor0()
        );
    }

    /**
        @param newFlavor_ the address of the new flavor
     */
    function flavorSwitch1_OAD(
        address newFlavor_
    )
        external
        onlyAdmin
    {
        resetNumDenom(OwnableFlavors.dripper1());
        flavorSwitch(
            OwnableFlavors.dripper1(),
            newFlavor_,
            OwnableFlavors.flavor1()
        );
    }
    
    function getOldRelativeDripPriceNumerator(address flavorDripper) external view returns (uint256) {
        return _getOldRelativeDripPriceNumerator(flavorDripper);
    }
    
    function _getOldRelativeDripPriceNumerator(address flavorDripper) internal view returns (uint256) {
        (,,,,,,,,,uint256 oldRelativeDripPriceNumerator,,) = IFlavorDripper(flavorDripper).getDripStatsAndSettings();
        return oldRelativeDripPriceNumerator;
    }

    function flavorSwitch(
        address flavorDripper,
        address newFlavor,
        address oldFlavor
    )
        internal
    {
        IFlavorDripper FlavorDripper = IFlavorDripper(flavorDripper);
        IERC20 OldFlavor = IERC20(oldFlavor);
        
        uint256 oldRelativeDripPriceNumerator = _getOldRelativeDripPriceNumerator(flavorDripper);

        //uint8 oldDecimals = OldFlavor.decimals();

        // if it's dripper0
        if(OwnableFlavors.dripper0() == flavorDripper){
            // update the flavor with dripper0
            OwnableFlavors.updateFlavor0_OAD(newFlavor, false, address(0));
        // if it's dripper1
        } else if (OwnableFlavors.dripper1() == flavorDripper){
            // update the flavor with dripper1
            OwnableFlavors.updateFlavor1_OAD(newFlavor, false, address(0));
        }

        // withdraw the remaining drips
        FlavorDripper.adminTokenWithdrawal_OAD(oldFlavor, OldFlavor.balanceOf(address(FlavorDripper)));

        // build a trade path
        address[] memory path = new address[](3);
        path[0] = oldFlavor;
        path[1] = wrappedNative;
        path[2] = newFlavor;

        // approve the router to spend our tokens
        OldFlavor.approve(address(Router), OldFlavor.balanceOf(address(this)));
        // swap drips for the new flavor
        // and deposit into the flavorDripper contract
        Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            OldFlavor.balanceOf(address(this)),
            1,
            path,
            address(FlavorDripper),
            block.timestamp
        );


        uint256 oldRate = _getRate(oldFlavor);
        uint256 newRate = _getRate(newFlavor);
        FlavorDripper.setRelativeDripPriceNumerator_OAD(
            oldRelativeDripPriceNumerator
                .mul(oldRate)
                .div(newRate)
        );

    }

    function getRate(address dripFlavor_) external view returns(uint256) {
        IDEXPair Pair = IDEXPair(IDEXFactory(Router.factory()).getPair(dripFlavor_, wrappedNative));
        // get the token addresses from LP
        address token0 = Pair.token0();// at this point we dont know which is which
        address token1 = Pair.token1();// at this point we dont know which is which
        // get the LP reserve balances
        (uint112 reserve0, uint112 reserve1, ) = Pair.getReserves();
        // ensure we are checking price for the proper Pair
        if(token0 == dripFlavor_ && token1 == wrappedNative) {
            // sort and return rate
            return(uint256(reserve1).mul(1e18).div(uint256(reserve0)));
        } else if (token1 == dripFlavor_ && token0 == wrappedNative) {
            // sort and return rate
            return(uint256(reserve0).mul(1e18).div(uint256(reserve1)));
        } else {
            return 0;
        }
    }

    function _getRate(address dripFlavor_) internal returns(uint256) {
        IDEXPair Pair = IDEXPair(IDEXFactory(Router.factory()).getPair(dripFlavor_, wrappedNative));
        // get the token addresses from LP
        address token0 = Pair.token0();// at this point we dont know which is which
        address token1 = Pair.token1();// at this point we dont know which is which
        // sync the lp balances
        Pair.sync();
        // get the LP reserve balances
        (uint112 reserve0, uint112 reserve1, ) = Pair.getReserves();
        // ensure we are checking price for the proper Pair
        if(token0 == dripFlavor_ && token1 == wrappedNative) {
            // sort and return rate
            return(uint256(reserve1).mul(1e18).div(uint256(reserve0)));
        } else if (token1 == dripFlavor_ && token0 == wrappedNative) {
            // sort and return rate
            return(uint256(reserve0).mul(1e18).div(uint256(reserve1)));
        } else {
            return 0;
        }
    }
    modifier onlyAdmin() {require(OwnableFlavors.isAdmin(_msgSender()), "FLAVOR SWITCHER: onlyAdmin() = caller not admin");_;}
}