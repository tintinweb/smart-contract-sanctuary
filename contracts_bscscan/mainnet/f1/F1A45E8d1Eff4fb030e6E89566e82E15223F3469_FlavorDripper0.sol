/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// libraries

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


/* ---------- START OF IMPORT IRelativeRate.sol ---------- */




/**
    @title IRelativeRate
    @author iceCreamMan
    @notice returns the payable dividend amount relative to the value of the previous drip token
    @dev when the drip token is switched out, the value relational to the native coin is calculated
        using the getReserves method on the liquidity pool. The relative rate is calculated and stored
        in the 'relativeDripPriceNumerator'. We can apply this at the last step before transferring out the
        tokens and the relative value the holder receives will match the proper
 */

interface IRelativeRate {
    function setRelativeRateBetweenDrips(
        address old_drip,
        address new_drip,
        uint256 relativeDripPriceNumerator,
        uint256 relativeDripPriceDenominator
    ) external returns (uint256 new_relativeDripPriceNumerator);
}
/* ------------ END OF IMPORT IRelativeRate.sol ---------- */


contract FlavorDripper0 is Context{
    using SafeMath for uint256;
    using Address for address;

    address internal owner;
    address internal router;
    address internal ownable;
    address internal dripFlavor;
    address internal iceCreamMan;
    address internal flavorsToken;
    address internal wrappedNative;
    address internal customBuyerContract;

    IDEXRouter internal Router;
    IERC20 internal DripFlavor;
    IERC20 internal WrappedNative;
    IFlavors internal FlavorsToken;
    IOwnableFlavors internal Ownable;
    ICustomBuyer internal CustomBuyer;
    IRelativeRate internal RelativeRate;


    ///@notice We can support any on-chain token for reflections.
    ///@dev If the token doesn't have a standard liquidity pool or isn't on
    ///     the same router, then set 'isCustomBuy' to true. For tokens that
    ///     are purchased by sending the native token directly to a contract,
    ///     like surge, set the 'customBuyerContract' address to the token
    ///     itself. For other special cases, a middle-man purchasing contract
    ///     must be launched with custom logic to perform the non-standard
    ///     swap and send the purchased tokens back to this contract. In this
    ///     case, set the 'customBuyerContract' address to the custom purchasing
    ///     contract. The only interaction this contract will have with the
    ///     custom buyer contract, is sending the native coin via the standard
    ///     transfer method. Use the receive fallback, relay the value with
    ///     custom logic to purchase and return the token.
    bool public useExternalCalculation;
    bool internal isCustomBuy;
    bool internal useCustomBuyMethod0;
    bool internal useCustomBuyMethod1;
    bool internal initialized;
    bool internal firstFlavorUpdate = true;

    uint16 internal additionalSeconds = 30;
    uint32 internal maxIterations = 10;
    uint32 internal minPeriod = 1 hours;
    uint64 internal gas = 100_000;
    uint64 internal gas_low = 100_000;
    uint64 internal minDistribution = 1 * (10 ** 9);
    uint64 internal currentIndex;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] public holdersList;
    mapping(address => uint256) public holderIndex;
    mapping(address => uint256) public holdersLastClaim;
    mapping(address => Share) public shares;

    uint256 internal totalShares;
    uint256 internal totalDeposits;
    uint256 internal totalDividends;
    uint256 internal totalDistributed;
    uint256 internal dividendsPerShare;
    uint256 internal dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 internal relativeDripPriceNumerator = 10 ** 18;
    uint256 internal relativeDripPriceDenominator = 10 ** 18;
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
    )
    {
        return (
            totalShares,
            totalDividends,
            totalDistributed,
            dividendsPerShare,

            
            totalDeposits,
            minPeriod,
            minDistribution,
            additionalSeconds,

            currentIndex,
            relativeDripPriceNumerator,
            relativeDripPriceDenominator,
            initialized
        );
    }

    function holdersListLength() public view returns (uint256) { return (holdersList.length);}
    function getGas() external view returns(uint64 gas_, uint64 gas_low_) { return(gas,gas_low);}
    function setGas_OAD(uint64 gas_, uint64 gas_low_) external onlyAdmin { gas = gas_;gas_low = gas_low_;}
    function setMaxIterations_OAD(uint32 maxIterations_) external onlyAdmin{ maxIterations = maxIterations_;}
    function setSwapDeadlineWaitTime_OAD(uint16 _additionalSeconds) external onlyAdmin { additionalSeconds = _additionalSeconds;}

        // ERC20 data for the dripFlavor token
    function dripName() internal view returns (string memory name) { return DripFlavor.name();}
    function dripDecimals() internal view returns (uint8 decimals) { return DripFlavor.decimals();}
    function dripAddress() internal view returns(address _dripAddress) { return address(DripFlavor);}
    function dripSymbol() internal view returns (string memory symbol) { return DripFlavor.symbol();}
    function dripTotalSupply() internal view returns (uint256 totalSupply) { return DripFlavor.totalSupply();}
    function dripBalanceOf(address addr) external view returns (uint256 value) { return DripFlavor.balanceOf(addr);}

    function getDripTokenInfo() external view returns(
        uint256 totalSupply,
        uint8 decimals,
        address dripToken_,
        string memory name,
        string memory symbol
    )
    {
        return (
            dripTotalSupply(),
            dripDecimals(),
            dripAddress(),
            dripName(),
            dripSymbol()
        );
    }

    function initialize(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract,
        address new_ownableFlavors
    ) public {
        require(initialized == false, "FlavorDripper: initialize() = Already Initialized");
        initialized = true;
        _updateOwnableFlavors(new_ownableFlavors);
        _updateFlavor(new_flavor, new_isCustomBuy, new_customBuyerContract);
        _updateRouter(Ownable.router());
        _updateFlavorsToken(Ownable.flavorsToken());
        owner = Ownable.owner();
        iceCreamMan = Ownable.iceCreamMan();
        wrappedNative = Ownable.wrappedNative();
        WrappedNative = IERC20(wrappedNative);
    }

    function setFlavorDistCriteria_OAD(uint32 _minPeriod, uint32 _minDistribution) external onlyAdmin {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare_OFT(address holder, uint256 amount) external onlyFlavorsToken { _setShare(holder,amount);}
    function _setShare(address holder, uint256 amount) internal {
        uint256 holderShares = shares[holder].amount;
        if(holderShares > 0) { distributeDividend(holder,  _getUnpaidDrips(holder));}
        if(amount > 0 && holderShares == 0) { addholder(holder);} else 
        if(amount == 0 && holderShares > 0) { removeholder(holder);}
        totalShares = totalShares.sub(holderShares).add(amount);
        shares[holder].amount = amount;
        shares[holder].totalExcluded = getCumulativeDividends(amount);
    }
    

    function deposit_OFT(uint256 valueSent, string memory note) external onlyFlavorsToken {
        // store the flavor reward token before balance so we can get an accurate post trade amount
          uint256 balanceBefore = DripFlavor.balanceOf(address(this));
          uint256 value = address(this).balance;
        // for tokens with standard LP:
        if(!isCustomBuy) {
          // create an empty 2 position trading path
          address[] memory path = new address[](2);
          // trade path stop 0
          path[0] = wrappedNative;
          // trade path stop 1
          path[1] = address(DripFlavor);
          // swap for the reward flavor
          Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: value}(
              // uint amountOutMin
              0,
              // address[] calldata path,
              path,
              // address to,
              address(this),
              // uint deadline
              block.timestamp.add(additionalSeconds)
          );
        // Custom buy tokens or custom middle-man purchasing contracts
        } else if(isCustomBuy) {
            // Send the native coin direct to a custom logic buyer contract for non-standard LP swaps
            if(useCustomBuyMethod0){
                (bool success,) = payable(address(CustomBuyer)).call{value: value, gas: gas}("");
                if (success) {
                    try CustomBuyer.buyMeStuff0(balanceBefore, address(DripFlavor), value) {} catch {}
                }
            } else if(useCustomBuyMethod1){
                try CustomBuyer.buyMeStuff1{value: value}(balanceBefore, address(DripFlavor), value) {} catch {}
            }
            // AFTER THE CUSTOM BUYER CONTRACT RECEIVES THE FUNDS, IT MUST BUY THE TOKEN, THEN TRANSFER
            // IT HERE, THEN CALL 'customBuyerContractCallback()' 
        }
        // subtract the before amount from the current amount
        // to get the exact amount purchased
        uint256 amount = DripFlavor.balanceOf(address(this)).sub(balanceBefore);
        uint256 relativeAmount = getRelativeAmountIn(amount);
        // increase total Dividends by the amount we just purchased
        totalDividends = totalDividends.add(relativeAmount);
        totalDeposits = totalDeposits.add(valueSent);
        // update dividends per share
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(relativeAmount).div(totalShares));
        emit DepositReceived(_msgSender(), valueSent, "FLAVOR DRIPPER: External Payment Received", note);
    }

    function customBuyerContractCallback_OCB(uint256 balanceBefore) external onlyCustomBuyer {
        // subtract the before amount from the current amount
        // to get the exact amount purchased
        uint256 amount = DripFlavor.balanceOf(address(this)).sub(balanceBefore);
        // increase total Dividends by the amount we just purchased
        totalDividends = totalDividends.add(amount);
        // update dividends per share
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function getAddresses() external view returns(
        address router_,
        address dripFlavor_,
        address ownable_,
        address flavorsToken_,
        address wrappedNative_,
        address iceCreamMan_,
        address owner_,
        address customBuyerContract_,
        address relativeRate_
    )
    {
        return(
            router,
            dripFlavor,
            ownable,
            flavorsToken,
            wrappedNative,
            iceCreamMan,
            owner,
            customBuyerContract,
            address(RelativeRate)
        );
    }

    function getCustomBuyerInfo() external view returns(
        bool isCustomBuy_,
        bool useCustomBuyMethod0_,
        bool useCustomBuyMetho1_,
        address customBuyerContract_
    )
    {
        return (
            isCustomBuy,
            useCustomBuyMethod0,
            useCustomBuyMethod1,
            customBuyerContract
        );
    }

    function setCustomBuyer_OICM(
        bool isCustomBuy_,
        bool useCustomBuyMethod0_,
        bool useCustomBuyMethod1_,
        address customBuyerContract_
    )
        external
        onlyIceCreamMan
    {
        isCustomBuy = isCustomBuy_;
        customBuyerContract = customBuyerContract_;
        useCustomBuyMethod0 = useCustomBuyMethod0_;
        useCustomBuyMethod1 = useCustomBuyMethod1_;
    }
    
    function process_OAD() external onlyAdmin { _process();}
    function process_OFT() external onlyFlavorsToken { _process();}
    // this function was a gusslin` monster truck. but i swapped out the hemi v8 with
    // a prius window motor. now she purs like a kitten.
    function _process() internal  {
        /* GAS: read storage ONCE,
                store values to memory,
                write values to storage ONCE
                OPCODES & GAS:
                    read storage:                       SLOAD   =   200
                    write storage (existing slot):      SSTORE  =   5,000
                    write storage (new slot):           SSTORE  =   20,000
                    read memory:                        MLOAD   =   8
                    write memory:                       MSTORE  =   8
        */
        uint64 _currentIndex = currentIndex;
        uint256 _gas_low = gas_low;
        uint256 _minDistribution = minDistribution;
        uint256 _holderCount = holdersListLength();
        uint256 _iteration;
        uint256 _unpaidDrips;
        address _holder;
        // GAS: logical disjunction order matters. save gas by ordering from
        //      most likely to return false to least likely
        while( gasleft() > _gas_low && _iteration < maxIterations && _iteration < _holderCount) {
                // if we hit the end of the holders list, loop back around to the beginning
            if(_currentIndex >= _holderCount.sub(1)) { _currentIndex = 0;}
                // GAS read 'getUnpaidDrips' once, store the value, and send it to 'distributeDividend'
                // instead of having distribute dividend run _getUnpaidDrips again. JUMP is cheaper than SLOAD jabronie
                _holder = holdersList[_currentIndex];
                _unpaidDrips = _getUnpaidDrips(_holder);
                if(_unpaidDrips >= _minDistribution){
                    // distribute the holders dividends
                    distributeDividend(_holder, _unpaidDrips);
                }
                _unpaidDrips = 0;
                // increment the holder index number
            _currentIndex++;
            // increment the iteration number
            _iteration++;
        }        
        // GAS: save our temp variables to storage, now that we are done.
        currentIndex = _currentIndex;// gas 5,000
    }

    function claimDividend() public {
        address holder = _msgSender();
        distributeDividend(holder, _getUnpaidDrips(holder));
    }

    function distributeDividend(address holder, uint256 amount) internal {
        uint256 holderShares = shares[holder].amount;
        if(holderShares == 0) { return;}
        if(amount > 0) {
            // update the numbers FIRST
            totalDistributed = totalDistributed.add(amount);
            holdersLastClaim[holder] = block.timestamp;
            shares[holder].totalRealised = shares[holder].totalRealised.add(amount);
            shares[holder].totalExcluded = getCumulativeDividends(holderShares);
            uint256 relativeAmount = getRelativeAmountOut(amount);
            // THEN send the transfer, revert on failure
            require(
                DripFlavor.transfer(holder, relativeAmount),
                "FLAVOR DRIPPER: distributeDividend() = transfer to holder failed"
            );
        }
    }

    function getUnpaidDrips(address holder) public view returns (uint256) {
        return _getUnpaidDrips(holder);
    }

    function _getUnpaidDrips(address holder) internal view returns (uint256) {
        uint256 holderShares = shares[holder].amount;
        uint256 totalExcluded = shares[holder].totalExcluded;
        // if the holder has no shares, return 0
        if(holderShares == 0) { return 0;}
        // if the holder is already all paid up, return 0
        uint256 cumulativeDrips = getCumulativeDividends(holderShares);
        if(cumulativeDrips <= totalExcluded) { return 0;}
        // get the cumulative dividends and subtract the distributed dividends
        return cumulativeDrips.sub(totalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    /** @notice Add a holder to the dividend distribution list
        @param holder The address of the holder to add*/
    function addholder(address holder) internal {
        // add the new holder to the last position of the holderIndex        
        holderIndex[holder] = holdersList.length;
        // add the new holder to the last position of the holder list
        holdersList.push(holder);
    }

    /**@notice because have no easy way to remove an item in the middle of an array,
        // move the last holder in the list into the position of the one we want to remove
        // then pop() the last item off the end of the array. sounds good kthnxbye luv u.
        @param holder The address of the holder to remove
    */
    function removeholder(address holder) internal {
        // overwrite the holder we wish to remove, with the data from the last holder in the list
        holdersList[holderIndex[holder]] = holdersList[holdersList.length-1];
        // overwrite the corrresponding holderIndex we wish to remove with the data from the last holder in the list
        holderIndex[holdersList[holdersList.length-1]] = holderIndex[holder];
        // remove the last holder on the lists
        holdersList.pop();
    }
    
    function updateFlavorsToken_OO(address new_flavorsToken) external onlyOwnable { _updateFlavorsToken(new_flavorsToken);}
    function _updateFlavorsToken(address new_flavorsToken) internal {
        // temp store the old flavors token address
        address old_flavorsToken = flavorsToken;
        // store the new flavors token address
        flavorsToken = new_flavorsToken;
        // initialize the new FlavorsToken contract instance
        FlavorsToken = IFlavors(new_flavorsToken);
        // fire the flavors token updated log
        emit FlavorsTokenUpdated(old_flavorsToken,new_flavorsToken);
    }


    /**
    @notice returns the payable dividend amount relative to the value of the previous drip token
    @dev when the drip token is switched out, the value relational to the native coin is calculated
        using the getReserves method on the liquidity pool. The relative rate is calculated and stored
        in the 'relativeDripPriceNumerator'. We can apply this at the last step before transferring out the
        tokens and the relative value the holder receives will match the proper
     */

     
    function settingsRelativeRate_OAD(bool useExternalCalculation_, address relativeRateContract) external onlyAdmin {
        useExternalCalculation = useExternalCalculation_;
        RelativeRate = IRelativeRate(relativeRateContract);
    }

    function setRelativeDripPriceNumerator_OAD(uint256 relativeDripPriceNumerator_) external onlyAdmin {
        relativeDripPriceNumerator = relativeDripPriceNumerator_;
    }
    function setRelativeDripPriceDenominator_OAD(uint256 relativeDripPriceDenominator_) external onlyAdmin {
        relativeDripPriceDenominator = relativeDripPriceDenominator_;
    }


    function getRelativeAmountOut(uint256 amount) internal view returns (uint256 relativeAmount){
        return relativeAmount = amount.mul(relativeDripPriceNumerator).div(relativeDripPriceDenominator);
    }

    function getRelativeAmountIn(uint256 amount) internal view returns (uint256 relativeAmount){
        return relativeAmount = amount.mul(relativeDripPriceDenominator).div(relativeDripPriceNumerator);
    }

    function setRelativeRateBetweenDrips(address old_drip, address new_drip) internal {
        if(useExternalCalculation){
            relativeDripPriceNumerator = 
                RelativeRate.setRelativeRateBetweenDrips(
                    old_drip,
                    new_drip,                    
                    relativeDripPriceNumerator,
                    relativeDripPriceDenominator
                );
        } else {
            relativeDripPriceNumerator = _setRelativeRateBetweenDrips(old_drip, new_drip);
        }
    }

    
    function _setRelativeRateBetweenDrips(address old_drip, address new_drip) internal returns (uint256) {
        uint256 relativeRate_ = getRelativeRateBetweenDrips(old_drip, new_drip);
        return relativeDripPriceNumerator.mul(relativeRate_).div(relativeDripPriceDenominator);
    }
    

    function getRelativeRateBetweenDrips(address oldDrip, address newDrip) internal returns(uint256 relativeRate){
        return getRate(oldDrip).mul(relativeDripPriceDenominator).div(getRate(newDrip));
    }


    

    function getRate(address dripFlavor_) internal returns(uint256 rate) {
        IDEXPair Pair = IDEXPair(IDEXFactory(Router.factory()).getPair(dripFlavor_, wrappedNative));
        address token0 = Pair.token0();
        address token1 = Pair.token1();
        Pair.sync();
        (uint112 reserve0, uint112 reserve1, ) = Pair.getReserves();
        if(token0 == dripFlavor && token1 == wrappedNative) {
            return(uint256(reserve1).mul(relativeDripPriceDenominator).div(uint256(reserve0)));
        } else if (token1 == dripFlavor && token0 == wrappedNative) {
            return(uint256(reserve0).mul(relativeDripPriceDenominator).div(uint256(reserve1)));
        }
    }

    function updateFlavor_OO(address new_flavor, bool new_isCustomBuy, address new_customBuyerContract) external onlyOwnable {
        _updateFlavor(new_flavor, new_isCustomBuy, new_customBuyerContract);
    }

    
    function _updateFlavor(address new_flavor, bool new_isCustomBuy, address new_customBuyerContract) internal {
        address old_dripFlavor = dripFlavor;
        bool old_isCustomBuy = isCustomBuy;
        address old_customBuyerContract = customBuyerContract;
        // store the new dripFlavor address
        dripFlavor = new_flavor;
        // store the new isCustomBuy parameter
        isCustomBuy = new_isCustomBuy;
        // store the new customBuyerContract address
        customBuyerContract = new_customBuyerContract;
        // initialize the new DripFlavor contract instance;
        DripFlavor = IERC20(dripFlavor);
        emit FlavorDripStats(totalDistributed);
        // reset the totalDistributedd. this is just for reporting
        // not calculating dividends
        totalDistributed = 0;

        if(firstFlavorUpdate==false){
            if(!new_isCustomBuy){
                setRelativeRateBetweenDrips(old_dripFlavor, new_flavor);
            }
        }
        
        firstFlavorUpdate = false;

        // fire the flavor updated log
        emit FlavorUpdated(
          old_dripFlavor,
          old_isCustomBuy,
          old_customBuyerContract,
          new_flavor,
          new_isCustomBuy,
          new_customBuyerContract
        );
    }
    event FlavorDripStats(uint256 totalDistributed);
    
    function adminTokenWithdrawal_OAD(address token, uint256 amount) external onlyAdmin {
        IERC20 ERC20Instance = IERC20(token);
        require(ERC20Instance.balanceOf(address(this)) >= amount, "FLAVOR DRIPPER: adminTokenWithdrawal_OAD() = insufficient balance" );
        ERC20Instance.transfer(_msgSender(),amount);
        emit AdminTokenWithdrawal(_msgSender(), amount, token);
    }

    function updateRouter_OO(address new_router) external onlyOwnable { _updateRouter(new_router);}
    function _updateRouter(address new_router) internal {
        // temp store the old router address
        address old_router = router;
        // store the new router address
        router = new_router;
        // initialize the new Router contract instance;
        Router = IDEXRouter(new_router);
        // fire the router updated log
        emit RouterUpdated(old_router, new_router);
    }

    function updateOwnableFlavors_OAD(address new_ownableFlavors) external onlyAdmin { _updateOwnableFlavors(new_ownableFlavors);}
    function _updateOwnableFlavors(address new_ownableFlavors) internal {
        // temp store the old Ownable address
        address old_ownableFlavors = address(Ownable);
        // initialize the new Ownable contract instance;
        ownable = new_ownableFlavors;
        Ownable = IOwnableFlavors(new_ownableFlavors);
        // fire the Ownable updated log
        emit OwnableFlavorsUpdated(old_ownableFlavors,new_ownableFlavors);
    }

    modifier onlyFlavorsToken() { require(flavorsToken == _msgSender(), "FLAVOR DRIPPER: OnlyToken() = Caller Not Flavors Token" );_;}
    modifier onlyAdmin() { require(Ownable.isAdmin(_msgSender()), "FLAVOR DRIPPER: onlyAdmin() = caller not IceCreamMan or Owner" );_;}
    modifier onlyIceCreamMan() { require(iceCreamMan == _msgSender(), "FLAVOR DRIPPER: onlyIceCreamMan() = caller not iceCreamMan" );_;}
    modifier onlyOwnable() { require(address(Ownable) == _msgSender(), "FLAVOR DRIPPER: onlyOwnable() = Caller Not Ownable Flavors");_;}
    modifier onlyCustomBuyer() { require(address(CustomBuyer) == _msgSender(), "FLAVOR DRIPPER: onlyCustomBuyer() = Caller Not customBuyer contract" );_;}

    event FlavorUpdated(
        address old_dripFlavor,
        bool old_isCustomBuy,
        address old_customBuyerContract,
        address new_flavor,
        bool new_isCustomBuy,
        address  new_customBuyerContract
    );

    event AdminTokenWithdrawal(address withdrawalBy, uint256 amount, address token);
    event OwnableFlavorsUpdated(address old_OwnableFlavors, address new_OwnableFlavors);
    event FlavorsTokenUpdated(address old_flavorsToken, address new_flavorsToken);
    event WrappedNativeUpdated(address old_wrappedNative, address new_wrappedNative);
    event RouterUpdated(address old_router, address new_router);
    event DepositReceived(address from, uint256 amount, string note0, string note1);

    fallback() external payable { }
    receive() external payable { }
}