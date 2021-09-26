/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// libraries





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

// extensions




abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// interfaces




interface IFlavorsChainData {
    function chainId() external view returns (uint chainId);
    function tokenName() external view returns (string memory name);
    function tokenSymbol() external view returns (string memory symbol);
    function router() external view returns (address router);
    function wrappedNative() external view returns (address _wrappedNative);
}






/**
@title IBridge
@author Ryan Dunn
@notice The IBridge interface is an interface to
    interact with the flavors token bridge
 */

interface IBridge {
    function initialize(address ownableFlavors,address bridgeTroll) external;
    function burnItAllDown() external;
}




interface ICreamery {
    function initialize (address ownableFlavors) external;
    function launch() external;

    //function updateIceCreamMan(address newIceCreamMan) external;
    function updateOwnable(address newOwnableFlavors) external;
    function burnItAllDown() external;

}




interface IDEXFactory {
    function createPair(address tokenA,address tokenB) external returns (address pair);
}




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





interface IDEXRouter {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
/*
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
    */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken,uint amountETH,uint liquidity);
    /*
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
    */
    function quote(uint amountA,uint reserveA,uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn,uint reserveIn,uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut,uint reserveIn,uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn,address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut,address[] calldata path) external view returns (uint[] memory amounts);
  /*
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
    */
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




interface IFlavorDripper {

    /**@dev public */
    function initialize(
        address dripFlavor,
        bool isDirectBuy,
        address ownableFlavors
    ) external;
    function claimDividend() external;

    /**@dev onlyToken */
    function setFlavorDistCriteria(uint256 _minPeriod,uint256 _minDistribution) external;
    function setShare(address shareholder,uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external payable;

    /**@dev onlyOwnable */
    function updateFlavorsToken(address newFlavorsToken) external;
    function updateFlavor(address newFlavor,bool isDirectBuy) external;
    function updateRouter(address newRouter) external;
    function updateOwnable(address newOwnableFlavors) external;

    function burnItAllDown() external;
}




/**
@title IOwnableFlavors
@author Ryan Dunn
@notice The IOwnableFlavors interface is an interface to a
    modified stand-alone version of the standard
    Ownable.sol contract by openZeppelin.  Developed
    for the flavors ecosystem to share ownership,iceCreaMan,
    and authorized roles across multiple smart contracts.
    See ownableFlavors.sol for additional information.
 */

interface IOwnableFlavors {
    function initialize0(
      address flavorsChainData,
      address iceCreamMan,
      address owner,
      address token,
      address bridge,
      address bridgeTroll
    ) external;

    function initialize1(
      address flavor0,
      address flavor1,
      address dripper0,
      address dripper1,
      address creamery,
      bool isDirectBuy0,
      bool isDirectBuy1
    ) external;



    //function updateTokenAddress(address addr) external;

    //function acceptOwnership() external;
    //function transferOwnership(address addr) external;
    //function renounceOwnership() external;

    //function acceptIceCreamMan() external;
    //function transferICM(address addr) external;

    function isAuthorized(address addr) external view returns (bool);
    //function grantAuthorization(address addr) external;
    //function revokeAuthorization(address addr) external;

    function iceCreamMan() external view returns(address);
    function owner() external view returns(address);
    function flavorsToken() external view returns(address);
    function pair() external view returns(address);
    function updatePair(address pair) external;

    function bridge() external view returns(address);
    function bridgeTroll() external view returns(address);
    function router() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);

    function ownable() external view returns(address);
    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function creamery() external view returns(address);

    function pendingIceCreamMan() external view returns(address);
    function pendingOwner() external view returns(address);
    function wrappedNative() external view returns(address);

    //function updateDripper0(address addr) external returns(bool);
    //function updateDripper1(address addr) external returns(bool);
    //function updateFlavor0(address addr) external returns(bool);
    //function updateFlavor1(address addr) external returns(bool);


}

/**
@title Flavors
@author Ryan Dunn
 */

contract Flavors is Context{
    using Address for address;
    using SafeMath for uint256;
    // using SafeMath32 for uint32;
    // using SafeMath16 for uint16;
    // using SafeMath8 for uint8;
    
    
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;

    uint256 public constant MAX_UINT256 = 2**256 - 1;
    uint256 _maxTx;

    ///@notice The threshold of collected Flavors token taxes when we initiate a swap back to the native coin    
    ///@dev public
    uint256 public swapThreshold;

    // Initialize our address mappings
    // mappings are used like this:
    //    mapping (address => address) liquidityPools;
    //    liquidityPools[liquidityPoolAddress] = pairedTokenAddress
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    
    // Set initial fees, fee input is 10,000x the desired fee
    // this allows for 2 decimals points of precision
    // example: if we set a fee of 200 => 200/10000 => .02 => 2%
    struct Fees { 
        uint16 flavor0;
        uint16 flavor1;
        uint16 creamery;
        uint16 icm;
        uint16 totalBuy;
        uint16 totalSell; }
    // set the variable 'fees' to type 'Fees'
    Fees public fees;
    uint16 public constant FEE_DENOMINATOR = 10_000;

    struct Gas { uint32 dripper0; uint32 dripper1; uint32 icm; uint32 creamery; uint32 withdrawal; }
    // set the variable 'gas' to type 'Gas'
    Gas public gas;
    
    uint256 public launchedAtBlock;
    uint256 public launchedAtTimestamp;

    // initialize addresses
    address public ownable;
    address public wrappedNative;
    address public iceCreamMan;
    address public flavorsChainData;
    function router() public view returns(address) { return Ownable.router(); }
    function flavor0() public view returns(address) { return Ownable.flavor0(); }
    function flavor1() public view returns(address) { return Ownable.flavor1(); }
    function dripper0() public view returns(address) { return Ownable.dripper0(); }
    function dripper1() public view returns(address) { return Ownable.dripper1(); }
    function creamery() public view returns(address) { return Ownable.creamery(); }
    function pair() public view returns(address) { return Ownable.pair(); }
    function owner() public view returns(address) { return Ownable.owner(); }
    function getOwner() public view returns (address){ return Ownable.owner(); }
    function bridge() public view returns(address) { return Ownable.bridge(); }
    function bridgeTroll() public view returns(address) { return Ownable.bridgeTroll(); }
    
    // set each variable's type to it's respectful contract
    IDEXRouter Router;
    IFlavorDripper Dripper0;
    IFlavorDripper Dripper1;
    ICreamery Creamery;
    IDEXPair Pair;
    IOwnableFlavors Ownable;
    IBridge Bridge;
    IFlavorsChainData FlavorsChainData;
    // future bridge settings
    //bool public bridgePaused = true;

    /**
    @notice Initialization entrypoint.
    @param _dripper0 Flavor Drip Contract 0
    @param _dripper1 Flavor Drip Contract 1
    @param _creamery "The Creamery" Address
    @param _ownableFlavors  Ownable Flavors Address
    @param _flavor0 Flavor0 Reward Token Address
    @param _flavor1 Flavor1 Reward Token Address
    @param _isDirectBuy0  set true for tokens that are purchased by sending native coin direct to the contract
    @param _isDirectBuy1  set true for tokens that are purchased by sending native coin direct to the contract
    @param _bridge Bridge Address
    @param initialSupply Initial Supply
    */
    function initialize (
        address _dripper0,
        address _dripper1,
        address _creamery,
        address _ownableFlavors,
        address _flavor0,
        address _flavor1,
        bool _isDirectBuy0,
        bool _isDirectBuy1,
        address _bridge,
        uint256 initialSupply,
        address _flavorsChainData
    ) public initializer {
        flavorsChainData = _flavorsChainData;
        FlavorsChainData = IFlavorsChainData(flavorsChainData);        
        name = FlavorsChainData.tokenName();
        symbol = FlavorsChainData.tokenSymbol();
        gas = Gas(
            1_000_000,
            1_000_000,
            200_000,
            200_000,
            200_000
        );
        // store the iceCreamMan
        iceCreamMan = _msgSender();
        // initialize the Ownable contract instance then we send all the addresses to the ownable contract
        // and the ownable contract initializes each contract
        _updateOwnable(_ownableFlavors);
        // store the wrappedNative token
        
        // initialize Ownable 0
        Ownable.initialize0(
            _flavorsChainData, // flavors chain specific data
            iceCreamMan,// iceCreamMan
            iceCreamMan,// owner
            address(this),// flavors token
            _bridge,// bridge
            iceCreamMan //bridgeTroll
        );
        // initialize Ownable 1
        Ownable.initialize1(
            _flavor0,// flavor0
            _flavor1,// flavor1
            _dripper0,// Dripper0
            _dripper1,// drippper1
            _creamery,// Creamery
            _isDirectBuy0,//
            _isDirectBuy1 //
        );

        wrappedNative = Ownable.wrappedNative();
        

        setTotalSupply(initialSupply.mul(10 ** decimals));
        // set a low max tx limit to prevent large buys/sells
        _maxTx = totalSupply.div(10); // 10%
        swapThreshold = totalSupply / 10_000; // 0.005%

        // set exemptions
        isFeeExempt[Ownable.bridge()] = true;
        isDividendExempt[Ownable.bridge()] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0x000000000000000000000000000000000000dEaD)] = true;
        isDividendExempt[address(0x0000000000000000000000000000000000000000)] = true;
        isDividendExempt[address(0x0000000000000000000000000000000000000001)] = true;
        isDividendExempt[address(Ownable)] = true;
        isDividendExempt[address(Bridge)] = true;

        //// transfer the initial total supply to the iceCreamMan
        balanceOf[iceCreamMan] = totalSupply;
        emit Transfer(address(0),iceCreamMan,totalSupply);
        _updateShares(iceCreamMan);
        initialized = true;
    }

    bool presalePrepped = false;

    function prepForPreSale() external onlyIceCreamMan {
        /**@NOTE REMEMBER TO RE-ENABLE THIS TODO*/
        //    require(presalePrepped == false, "FLAVORS: prepForPreSale => Already Prepped" );
        fees = Fees({
            flavor0: 0,
            flavor1: 0,
            creamery: 0,
            icm: 0,
            totalBuy: 0,
            totalSell: 0   
        });        
        _maxTx = MAX_UINT256;
        presalePrepped = true;
    }
        
    bool presaleFinalized = false;
    // end of presale helper.
    // initiates the "launch"
    // cannot be undone.
    // To be called by dev after the presale
    function finalizePreSale(/*address _presaleContract*/) external onlyIceCreamMan {
        /**@NOTE REMEMBER TO RE-ENABLE THIS TODO*/
        //require(presaleFinalized == false, "FLAVORS: finalizePreSale => Already Finalized");
        // set the fees
        fees = Fees({
            flavor0: 350,
            flavor1: 350,
            creamery: 400,
            icm: 100,
            totalBuy: 1200,
            totalSell: 3500
        });
        // set the max transaction amount
        _maxTx = totalSupply.div(20); // 5%
        // toggle the presale finalized flag
        presaleFinalized = true;
        // save the current block number
        launchedAtBlock = block.number;
        // save the current timestamp
        launchedAtTimestamp = block.timestamp;
        // launch the creamery
        Creamery.launch();
    }
    
    ///@notice Methods to read and write the State variables*/     
    ///@notice balanceOf => SET
    function setBalance(address holder,uint256 value) internal returns (bool) { balanceOf[holder] = value; return true; }

    ///@notice balanceOf => ADD
    function addBalance(address holder,uint256 value) external onlyBridge returns(bool) { return _addBalance(holder,value); }
    function _addBalance(address holder,uint256 value) internal returns(bool) { balanceOf[holder] = balanceOf[holder].add(value); return true; }

    ///@notice balanceOf => SUBTRACT
    function subBalance(address holder,uint256 value) external onlyBridge returns(bool) { return _subBalance(holder,value); }
    function _subBalance(address holder,uint256 value) internal returns(bool) { balanceOf[holder] = balanceOf[holder].sub(value); return true; }    
    
    ///@notice totalSupply => SET
    function setTotalSupply(uint256 value) internal returns (bool) { totalSupply = value; return true; }

    ///@notice totalSupply => ADD
    function addTotalSupply(uint256 value) external onlyBridge returns (bool) { return _addTotalSupply(value); }
    function _addTotalSupply(uint256 value) internal returns (bool) { totalSupply = totalSupply.add(value); return true; }
    
    ///@notice totalSupply => SUBTRACT
    function subTotalSupply(uint256 value) external onlyBridge returns (bool) { return _subTotalSupply(value); }
    function _subTotalSupply(uint256 value) internal returns (bool) { totalSupply = totalSupply.sub(value); return true; }

    bool functionLocked = false;
    modifier lockWhileUsing() { require(functionLocked == false, "FLAVORS: lockWhileUsing => function locked while in use" );        
        functionLocked = true;// set the function locked variable        
        _;  // placeholder: this is where the modified function exectues        
        functionLocked = false; // clear the function locked variable
    }
    
    bool public initialized = false;
    modifier initializer() {
        /*TODO REMEMBER TO RE-ENABLE THIS TODO
        require(initialized == false, "FLAVORS: initializer => Already Initialized" );*/
        _;  // placeholder: this is where the modified function exectues
        initialized = true;
    }

    
    /*
    // bridge on-ramp: mints new tokens to the bridge
    function creamToBridge(uint256 tokens) external onlyBridge { require(addTotalSupply(tokens)); require(addBalance(Ownable.bridge(),tokens)); }
    // bridge off-ramp:  melts tokens from the bridge
    function meltFromBridge(uint256 tokens) external onlyBridge { require(subTotalSupply(tokens)); require(subBalance(Ownable.bridge(),tokens)); }
    */

    // creams new tokens for creamAndFreeze and the bridge (future use)
    function cream(uint256 tokens) internal returns (bool) {
        // add the creamed tokens to the total supply
        require(_addTotalSupply(tokens),"FLAVORS: cream => addTotalSupply error");
        // add the creamed tokens to the contract
        require(_addBalance(address(this),tokens),"FLAVORS: cream => addBalance error");return true;        
    }
    
    /*// melts tokens from the bridge (future use)
    function melt(uint256 tokens) private returns (bool) {
        // subtract the melted tokens from the total supply
        require(subTotalSupply(tokens), "FLAVORS: melt => subTotalSupply error" );
        // remove the melted tokens from the contract
        require(subBalance(address(this),tokens), "FLAVORS: melt => subBalance error" );
        return true;
    }*/

    /**@notice Calculate the price based on Pair reserves 
        @dev does NOT return fiat price, returns price in paired token. 
        @return price of Flavors in native coin */
    function getTokenPrice() public returns(uint256) {
        // get the token addresses from LP
        address token0 = Pair.token0();   // at this point we dont know which is which
        address token1 = Pair.token1();   // at this point we dont know which is which
        // sync the lp balances
        Pair.sync();
        // get the LP reserve balances
        (uint112 reserve0,uint112 reserve1,uint32 blockTimestamp) = Pair.getReserves();
        emit GetReserves(reserve0,reserve1,blockTimestamp);
        // ensure we are checking price for the proper Pair
        if(address(token0) == address(this) && address(token1) == wrappedNative) {
            emit TokenPrice(uint256(reserve1)/uint256(reserve0));
            // clean up the temp variables for a gas refund
            delete token0;
            delete token1;
            // sort and return price            
            return(uint256(reserve1)/uint256(reserve0));
        // ensure we are checking price for the proper Pair
        } else if (address(token1) == address(this) && address(token0) == wrappedNative) {
            emit TokenPrice(uint256(reserve0)/uint256(reserve1));
            // clean up the temp variables for a gas refund
            delete token0;
            delete token1;
            // sort and return price            
            return(uint256(reserve0)/uint256(reserve1));
        } else {
            emit TokenPrice(0);
            // clean up the temp variables for a gas refund
            delete token0;
            delete token1;
            return 0;
        }
    }

    function addLiquidityETH(
        uint256 tokenAmount,
        uint256 pairedTokenAmount
    ) payable public returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    ) {
        // add the liquidity
        (amountToken,amountETH,liquidity) = Router.addLiquidityETH{value: pairedTokenAmount}(
            address(this),//    address token,
            tokenAmount,//       uint amountTokenDesired,
            0,   //       uint amountTokenMin,
            0,   //       uint amountETHMin,
            address(this),//    address to,
            block.timestamp//       uint deadline
      );
            emit LiquidityAdded(amountToken,amountETH,liquidity);
            return (amountToken,amountETH,liquidity);          
    }

/*
  // adding the first liquidity on the test net. i used this:
        https://pancake.kiemtienonline360.com/#/swap
0xf305d7190000000000000000000000007bd09eb9a02cb14bfe6db81a9c0a270caca16ff3000000000000000000000000000000000000000000000000000316dd60ef2200000000000000000000000000000000000000000000000000000316dd60ef22000000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000039d79ce9314ccbebfc385889cbb8d6124d6ac3320000000000000000000000000000000000000000000000000000000061481751

          Function: addLiquidityETH(address token,uint256 amountTokenDesired,uint256 amountTokenMin,uint256 amountETHMin,address to,uint256 deadline)

          MethodID: 0xf305d719
          [0]:  0000000000000000000000007bd09eb9a02cb14bfe6db81a9c0a270caca16ff3  address token
          [1]:  000000000000000000000000000000000000000000000000000316dd60ef2200  uint256 amountTokenDesired
          [2]:  000000000000000000000000000000000000000000000000000316dd60ef2200  uint256 amountTokenMin
          [3]:  0000000000000000000000000000000000000000000000000de0b6b3a7640000  uint256 amountETHMin
          [4]:  00000000000000000000000039d79ce9314ccbebfc385889cbb8d6124d6ac332  address to
          [5]:  0000000000000000000000000000000000000000000000000000000061481751  uint256 deadline
*/

    function creamAndFreeze() public payable {
        uint256 _value = msg.value;
        // must send native coin
        require (_value > 0, "FLAVORS: creamAndFreeze => value must be greater than zero" );
        // calculate the required tokens
        uint256 tokens = _value.div(getTokenPrice());
        // cream the tokens,lol wtf am a I saying
        cream(tokens);
        // add liquidity to the pool
        (,,uint256 liquidity) = addLiquidityETH(tokens,_value);
          //NOTE: Divy up the recieved lp tokens into 3 parts
          //  Because we minted the tokens that were added to the LP,
          //  We will burn that portion of the recieved LP tokens,
          //  This prevents any additional value from being claimed out of the LP,
          //  other than the value which was truely added from an external source.
        // approve the lp to transfer our lp tokens
        Pair.approve(address(Pair),liquidity);
        // transfer burnt LP
        Pair.transfer(address(0),liquidity.div(2));
        // transfer icm LP
        Pair.transfer(iceCreamMan,liquidity.mul(fees.icm).div(FEE_DENOMINATOR));
        // transfer Creamery LP
        Pair.transfer(address(Creamery),Pair.balanceOf(address(this)));
        // clean up the temp variables for a gas refund        
        delete tokens;
        delete liquidity;
    }

    function updateShares(address holder) public onlyBridge { _updateShares(holder); }
    function _updateShares(address holder) internal {
        // update the share amounts with the drip distributor contracts
        if(isDividendExempt[holder]) { try Dripper0.setShare(holder,balanceOf[holder]) {} catch {} }
        // update the share amounts with the drip distributor contracts
        if(isDividendExempt[holder]) { try Dripper1.setShare(holder,balanceOf[holder]) {} catch {} }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function approve(address spender, uint value) public returns (bool) { _approve(_msgSender(), spender, value); return true; }
    function _approve(address _owner, address spender, uint value) private { allowance[_owner][spender] = value; emit Approval(_owner, spender, value); }    
    ///@notice approve the spender address to spend tokens on behalf of the _msgSender() in the amount of MAX_UINT256
    function approveMax(address spender) public returns (bool) { return this.approve(spender, MAX_UINT256); }
    function addAllowance(address holder,address spender,uint256 amount) public onlyBridge { _addAllowance(holder,spender,amount); }
    function _addAllowance(address holder,address spender,uint256 amount) internal { allowance[holder][spender] = allowance[holder][spender].add(amount); emit Approval(holder,spender,amount); }
    function _subAllowance(address holder,address spender,uint256 amount) internal { allowance[holder][spender] = allowance[holder][spender].sub(amount, "FLAVORS: transferFrom => Insufficient Allowance" ); }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowance[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowance[_msgSender()][spender].sub(subtractedValue,
        "FLAVORS: Cannot Decrease Allowance Below Zero"));
        return true;
    }
    
    function transfer(address to, uint value) public returns (bool) {
        return transferFrom(_msgSender(), to, value);
        //return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        if (allowance[from][_msgSender()] != MAX_UINT256) {
            allowance[from][_msgSender()] = allowance[from][_msgSender()].sub(value);
        }
        return _transferFrom(from, to, value);
        //return true;
    }


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    /**@notice modified transferFrom method. handles taking the fees */
    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {        
        // verifiy the amount doesn't exceed the transfer limit
        require(amount <= _maxTx || isTxLimitExempt[from], "FLAVORS: _transferFrom => Exceeds _maxTx" );
        // check if the accumulated token qty has surpassed the threshold to swap back to the native wrapped token
        if(balanceOf[address(this)] >= swapThreshold) { swapBack(); }
        uint256 feeAmount;
        // check if address is fee exempt,take fee if not
        if(isFeeExempt[from]) { feeAmount = 0;}
        //else{ feeAmount = takeFee(to, amount); }
        else{ feeAmount = (amount.mul((to == address(Pair)) ? fees.totalSell : fees.totalBuy)).div(FEE_DENOMINATOR);}
        // subtract the balance from the sender
        require(_subBalance(from, amount), "FLAVORS: _transferFrom => Insufficient Balance" );        
        // transfer the non-fee amount to the receiver
        _addBalance(to, amount.sub(feeAmount));        
        emit Transfer(from, to, amount.sub(feeAmount));
        // add the fee balance to this contract
        _addBalance(address(this), feeAmount);
        //emit Transfer(from, address(this), feeAmount);

        
     /* // update the dividend shares with the flavor drip contracts
        _updateShares(from);
        _updateShares(to);
        // try to catch some drips, catch the error if you cant catch a drip
        try Dripper0.process{gas: gas.dripper0}(gas.dripper0) {} catch {}
        try Dripper1.process{gas: gas.dripper1}(gas.dripper1) {} catch {}
        // delete temp variables to get a gas refund
        delete feeAmount;
        // victory
      */  return true;
    }
    
    /**@notice check if we should swap the collected token fees back to the native token
       @return  returns true if all 3 conditions are met*/
      //TODO CHANGE BACK TO INTERNAL TODO
    function shouldSwapBack() public view returns (bool) {        
        // if we aren't already in a swap
        return !functionLocked
        // and if the balance of this address exceeds the swapThreshold
        && balanceOf[address(this)] >= swapThreshold;
        // then returns 'true' otherwise,returns 'false'
    }

    // swap from flavors token to the wrapped native token    
    function swapBack() internal {
        require(swapExactTokensForETHSupportingFeeOnTransferTokens(), "FLAVORS: swapBack => fail" );
        // The swap should be complete at this point, we should have a bit of the native coin in the contract        
        // calculate our fee transfer amounts
        (uint256 toDrip0, uint256 toDrip1, uint256 toICM, uint256 toCreamery) = getFeeAllotments();
        // transfer the feees to the fee receivers
        sendTaxes(toDrip0,toDrip1,toICM,toCreamery);
    }

    function getFeeAllotments() internal view returns(
        uint256 toDrip0,
        uint256 toDrip1,
        uint256 toICM,
        uint256 toCreamery
    ) {
        // allotment for buying flavor0
        toDrip0 = ((address(this)).balance).mul(fees.flavor0).div(fees.totalBuy);
        // allotment for buying flavor1
        toDrip1 = ((address(this)).balance).mul(fees.flavor1).div(FEE_DENOMINATOR);
        // allotment for the iceCreamMan
        toICM = ((address(this)).balance).mul(fees.icm).div(FEE_DENOMINATOR);
        // allotment for the Creamery
        toCreamery = ((address(this).balance)
            .mul(fees.creamery)
            .div(FEE_DENOMINATOR))
            //(subtract the gas so we can forward it)
            .sub(gas.dripper0*2)
            .sub(gas.dripper1*2)
            .sub(gas.icm*2)
            .sub(gas.creamery*2);  
        return (toDrip0, toDrip1, toICM, toCreamery);
    }

    uint256 additionalSeconds = 30;
    function swapDeadline() internal view returns (uint256) { return block.timestamp + additionalSeconds; }
    function setSwapDeadlineWaitTime(uint256 _additionalSeconds) external onlyAdmin { additionalSeconds = _additionalSeconds; }

    function sendTaxes(uint256 toDrip0, uint256 toDrip1, uint256 toICM, uint256 toCreamery) internal {
        // send fee allotment to Dripper0 contract (also buys flavorDrip0);
        Address.sendValue(payable(address(Dripper0)),toDrip0);
        // send fee allotment to Dripper1 contract (also buys flavorDrip1);
        Address.sendValue(payable(address(Dripper1)),toDrip1);
        // send fee allotment to the ICM;
        Address.sendValue(payable(iceCreamMan),toICM);
        // send fee allotment to the Creamery;
        Address.sendValue(payable(address(Creamery)),toCreamery);
    }


    function TEST_sendTaxes_Method0(uint256 toDrip0,uint256 toDrip1,uint256 toICM,uint256 toCreamery) public {
        try Dripper0.deposit{value: toDrip0, gas: gas.dripper0}() {} catch {}
        try Dripper1.deposit{value: toDrip1, gas: gas.dripper1}() {} catch {}
        payable(iceCreamMan).call{value: toICM, gas: gas.icm}( "FLAVORS: swapBack => transfer to iceCreamMan failed" );
        payable(address(Creamery)).call{value: toCreamery, gas: gas.creamery}( "FLAVORS: swapBack => transfer to creamery failed" );

        //from here: https://docs.soliditylang.org/en/v0.6.6/types.html#members-of-addresses
        //address(nameReg).call{gas: 1000000, value: 1 ether}(abi.encodeWithSignature("register(string)", "MyName"));
    }
    

    /*
    function takeFee(address to, uint256 amount) internal view returns (uint256) {
        // check if this is a buy or sell (the liquidity pool is the recipient for sells)
        bool selling = (to == address(Pair));
        // get the current fee for this transaction
        uint16 fee =  selling ? fees.totalSell : fees.totalBuy;
        // fee amount in tokens
        uint256 feeAmount = (amount.mul(fee)).div(FEE_DENOMINATOR);
        // and send the non-fee token qty back to the calling function
        return (feeAmount);
    }
    */
    function swapExactTokensForETHSupportingFeeOnTransferTokens() internal lockWhileUsing returns (bool) {
        // create a trading path for our swap.
        address[] memory path = new address[](2);
        // Path[0]: Trades the flavors token for the wrapped native token
        path[0] = address(this);
        // Path[1]: upwraps the wrapped native token to get the native coin.
        path[1] = wrappedNative;
        // swap the token to the native coin
        Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            //uint amountIn, the amount of flavors tokens to swap
            balanceOf[address(this)],
            //uint amountOutMin,
            0,
            // address[] calldata path, the trading path
            path,
            // address to, send the swapped native coin to this contract
            address(this),
            // uint deadline swap must be performed by this deadline. use the current block.timestamp
            swapDeadline()
        );
        delete path;
        return true;
    }
    
    function setMaxTx(uint256 amount) external authorized { _maxTx = amount; }
    function setIsFeeExempt(address holder, bool isExempt) external authorized { isFeeExempt[holder] = isExempt; }
    function setIsTxLimitExempt(address holder, bool isExempt) external authorized { isTxLimitExempt[holder] = isExempt; }
    function setIsDividendExempt(address holder, bool isExempt) external authorized { _setIsDividendExempt(holder,isExempt); }
    function _setIsDividendExempt(address holder, bool isExempt) internal {
        isDividendExempt[holder] = isExempt;
        if(isExempt) {
            Dripper0.setShare(holder,0);
            Dripper1.setShare(holder,0);
        }else{
            _updateShares(holder);
        }
    }

    // Tiered Sales fee
    // uint16 tieredSellFee0 = 1500; //   > 56 days  15%
    // uint16 tieredSellFee1 = 2000; //   > 28 days  20%
    // uint16 tieredSellFee2 = 2500; //   > 13 days  25%
    // uint16 tieredSellFee3 = 3000; //   >  7 days  30%
    // uint16 tieredSellFee4 = 3500; //   <  7 days  35%
    

    


    function setFees(
        uint16 flavor0_, uint16 flavor1_, uint16 creamery_, uint16 iceCreamMan_, uint16 totalBuy_, uint16 totalSell_
    ) external authorized {
        // prevent internal misuse & require flavor0Fee is less than 10%
        require(/*0 < flavor0_ && */flavor0_ <= 1000, "FLAVORS: setFees => fees.flavor0 MUST BE LESS THAN 10% (1000)" );
        // prevent internal misuse & require flavor1Fee is less than 10%
        require(/*0 < flavor1_ && */flavor1_ <= 1000, "FLAVORS: setFees => fees.flavor1 MUST BE LESS THAN 10% (1000)" );
        // prevent internal misuse & require Creamery fee is less than 10%
        require(/*50 < creamery_ && */creamery_ <= 1000, "FLAVORS: setFees => fees.creamery MUST BE LESS THAN 10% (1000)" );
        // prevent internal misuse & require icm fee is between 1% and 3%
        require(100 <= iceCreamMan_ && iceCreamMan_ <= 300, "FLAVORS: setFees => fees.icm MUST BE BETWEEN 1% (100) & 3% (300)" );
        // prevent internal misuse & require totalBuy fee is less than 20%
        require(/*50 < totalBuy_ && */totalBuy_ <= 2000, "FLAVORS: setFees => fees.totalBuy MUST BE LESS THAN 20% (2000)" );
        // prevent internal misuse & require totalSell fee is less than 40%
        require(/*50 < totalSell_ && */totalSell_ <= 4000, "FLAVORS: setFees => fees.totalSell MUST BE LESS THAN 40% (4000)" );
        fees = Fees( flavor0_, flavor1_, creamery_, iceCreamMan_, totalBuy_, totalSell_ );
        emit FeesUpdated( flavor0_, flavor1_, creamery_, iceCreamMan_, totalBuy_, totalSell_ );
    }
    
    // swap threshold is the amount of collected tokens in the contract until we initiate a 'swapBack'
    function setSwapThreshold(uint256 _amount) external authorized { swapThreshold = _amount; }

    function setGas( uint32 dripper0_, uint32 dripper1_, uint32 iceCreamMan_, uint32 creamery_, uint32 withdrawal_ ) external authorized {
        gas = Gas( dripper0_, dripper1_, iceCreamMan_, creamery_, withdrawal_);
        emit GasUpdated( dripper0_, dripper1_, iceCreamMan_, creamery_, withdrawal_ );
    }

    /**@notice externally called function to update dripper0 address.
     *  must be called by ownableFlavors Contract
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param newDripper0 new dripper0 address
     * @return true if successful*/
    function updateDripper0(address newDripper0) external onlyOwnable returns(bool) { require(_updateDripper0(newDripper0), 
        "OWNABLE: updateDripper0 => internal call to _updateDripper0 failed" ); return true;
    }

    /**@notice Internally called function to update Dripper0 address.
     *  May be called by any internal function.
     * @param newDripper0 new dripper0 address
     * @return Returns 'true' if successful.*/
    function _updateDripper0(address newDripper0) internal returns (bool) {
        // temp store the old dripper0;
        address oldDripper0 = address(Dripper0);
        // initialize the new dripper0 contract
        Dripper0 = IFlavorDripper(newDripper0);
        // set Dripper0 exclusions;
        isFeeExempt[address(Dripper0)] = true;
        isDividendExempt[address(Dripper0)] = true;
        isTxLimitExempt[address(Dripper0)] = true;
        // fire the updated Dripper0 address log
        emit Dripper0Updated(oldDripper0,newDripper0);
        // delete temp variables for a gas refund
        delete oldDripper0;
        // victory
        return true;
    }

    /**@notice externally called function to update dripper1 address.
     *  must be called by ownableFlavors Contract
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param newDripper1 new dripper1 address
     * @return true if successful*/
    function updateDripper1(address newDripper1) external onlyOwnable returns(bool) { require(_updateDripper1(newDripper1), 
        "OWNABLE: updateDripper1 => internal call to _updateDripper1 failed" ); return true; }

    /**@notice Internally called function to update Dripper1 address.
     *  May be called by any internal function.
     * @param newDripper1 new dripper1 address
     * @return Returns 'true' if successful.*/
    function _updateDripper1(address newDripper1) internal returns (bool) {
        // temp store the old dripper1;
        address oldDripper1 = address(Dripper1);
        // initialize the new dripper1 contract
        Dripper1 = IFlavorDripper(newDripper1);
        // set Dripper1 exclusions;
        isFeeExempt[address(Dripper1)] = true;
        isDividendExempt[address(Dripper1)] = true;
        isTxLimitExempt[address(Dripper1)] = true;
        // fire the updated Dripper1 address log
        emit Dripper1Updated(oldDripper1,newDripper1);
        // delete temp variables for a gas refund
        delete oldDripper1;
        // victory
        return true;
    }
    
    function updateOwnable(address newOwnableFlavors) external onlyAdmin { _updateOwnable(newOwnableFlavors); }
    function _updateOwnable(address newOwnableFlavors) internal {
        // temp store the old Ownable address
        address oldOwnableFlavors = ownable;
        // store the new router address
        ownable = newOwnableFlavors;
        // initialize the new Ownable contract instance;
        Ownable = IOwnableFlavors(newOwnableFlavors);
        // set the new ownable contract fee exemptions
        isFeeExempt[newOwnableFlavors] = true;
        isDividendExempt[newOwnableFlavors] = true;
        // fire the Ownable updated log
        emit OwnableFlavorsUpdated(oldOwnableFlavors,newOwnableFlavors);
        // delete the temp variables for a gas refund
        delete oldOwnableFlavors;
    }

    function updateCreamery(address newCreamery) external onlyOwnable returns (bool) { return _updateCreamery(newCreamery); }
    function _updateCreamery(address newCreamery) internal returns (bool) {
        // temp store the oldCreamery address
        address oldCreamery = address(Creamery);
        // init the new creamery contract
        Creamery = ICreamery(newCreamery);
        // set the creamery exempt from fees,dividends,and tx limit
        isFeeExempt[newCreamery] = true;
        isDividendExempt[newCreamery] = true;
        isTxLimitExempt[newCreamery] = true;
        // fire the creameryUpdated log
        emit CreameryUpdated(oldCreamery,newCreamery);
        // remove the temp variables for a gas refund
        delete oldCreamery;
        return true;
    }

    function updateIceCreamMan(address newIceCreamMan) external onlyOwnable {_updateIceCreamMan(newIceCreamMan);}
    function _updateIceCreamMan(address newIceCreamMan) internal {
        // temp store the old ice cream man address
        address oldIceCreamMan = iceCreamMan;
        // store the new ice cream man
        iceCreamMan = newIceCreamMan;
        // set ice cream man exemptions
        isFeeExempt[newIceCreamMan] = true;
        isTxLimitExempt[newIceCreamMan] = true;
        isDividendExempt[newIceCreamMan] = false;
        // fire the log for the new ice cream man
        emit IceCreamManTransferred(oldIceCreamMan,newIceCreamMan);
        // remove the temp variables for a gas refund
        delete oldIceCreamMan;
    }

    function updateRouter(address newRouter) external onlyOwnable returns (address) { return _updateRouter(newRouter); }
    function _updateRouter(address newRouter) internal returns (address) {
        // temp store the old router address
        address oldRouter = Ownable.router();
        // initialize the router contract
        Router = IDEXRouter(newRouter);
        // set the router maximum approval
        this.approve(newRouter,MAX_UINT256);
        // set the new router exempt from receiving flavor drips
        isDividendExempt[newRouter] = true;
        // fire the RouterUpdated log
        emit RouterUpdated(oldRouter,newRouter);
        // remove the temp variables for a gas refund
        delete oldRouter;
        // deploy the pool and return the new pair address
        wrappedNative = Ownable.wrappedNative();
        return _deployPool(newRouter,Ownable.wrappedNative());
    }

    // deploys a new pool with zero liquidity
    //function deployPool(address _router,address _pairedToken) external onlyAdmin{ _deployPool(_router,_pairedToken); }
    function _deployPool(address _router,address _pairedToken) internal returns(address) {
        // send back the new pair address
        Pair = IDEXPair(IDEXFactory(IDEXRouter(_router).factory()).createPair(_pairedToken,address(this)));
        // set the LP maximum approval
        this.approve(address(Pair),MAX_UINT256);
        // set the new liquidity pool exempt from receiving flavor drips
        isDividendExempt[address(Pair)] = true;
        // fire the pool deployed event log
        emit PoolDeployed(address(Pair),_router,_pairedToken);
        return address(Pair);
    }
    
    /*modifier onlyOwner() {
        // if ownership was renounced to the zero address...// give all the ownership duties to the iceCreamMan role,
        if(owner() == address(0)) { // give all the ownership duties to the iceCreamMan role, require(iceCreamMan == _msgSender(), "FLAVORS STATE: onlyOwner => ownership renounced,caller not iceCreamMan" );
        } else { require(owner() == _msgSender(), "FLAVORS STATE: onlyOwner => caller not Owner" ); }
        _;  // placeholder - this is where the modified function executes}*/
    
    modifier onlyBridge() { require (Ownable.bridge() == _msgSender(), "FLAVORS: onlyBridge => caller not bridge" ); _; }
    modifier onlyCreamery() { require (address(Creamery) == _msgSender(), "FLAVORS: onlyCreamery => caller not Creamery"); _; }
    modifier onlyOwnable() { require( address(Ownable) == _msgSender(), "FLAVORS: onlyOwnable => caller not ownableFlavors" ); _; }
    modifier onlyIceCreamMan() { require(Ownable.iceCreamMan() == _msgSender(), "FLAVORS: onlyIceCreamMan => caller not iceCreamMan" ); _; }
    modifier onlyAdmin() { require(Ownable.iceCreamMan() == _msgSender() || Ownable.owner() == _msgSender(), "FLAVORS: onlyAdmin => caller not IceCreamMan or Owner" ); _; }
    modifier authorized() { require(Ownable.isAuthorized(_msgSender()), "FLAVORS: authorized => caller not Authorized" ); _; }

    // Tool for performing air drops,mass token transfers,giveaways,'email marketing' style advertising.
    // The message sender must hold the tokens they are trying to send. Function locks during use.
    /**@notice airdrop tool for mass token transfers
       @dev not for dusting attacks bro.
       @notice lists must be the same length
       @notice can only be called by authorized addresses
       @param _recipients list of recipient addresses
       @param _values list of transfer amounts*/
    function sprinkleAllTheCones(
        // calldata is cheaper than memory,but cant be modified
        address[] calldata _recipients,
        uint256[] calldata _values
    ) public authorized returns (bool) { return _sprinkleAllTheCones(_recipients, _values); }
    
    uint16 maxSprinkleCount = 100;    
    function setMaxSprinkleLength (uint16 listLength) external onlyAdmin { maxSprinkleCount = listLength; }
    function _sprinkleAllTheCones(
        // calldata is cheaper than memory,but cant be modified
        address[] calldata _recipients,
        uint256[] calldata _values
    ) internal lockWhileUsing returns (bool) {
        // make sure our recipients list is the same length as the values list
        require(_recipients.length == _values.length, "FLAVORS: _sprinkleAllTheCones => recipients & values lists are not the same length" );
        require(_values.length <= maxSprinkleCount, "FLAVORS: _sprinkleAllTheCones => exceeds maxSprinkleCount" );
        // store the senders current balance in a temporary variable so we
        // dont waste gas calling to update the state on every transfer
        // This Could open a vulnerability because to save gas,we dont update 
        // the senders balance with the state until the very end. This means,
        // if we were busy processing a large batch the sender could quickly
        // spend the tokens elsewhere before we were done processing.
        // NOTE: Added a check after bulk transfer to prevent this.
        uint256 senderBalance = balanceOf[_msgSender()];
        // iterate through the list entries
        for (uint256 i = 0; i < _values.length; i++) {
            // this iterations recipient
            // prevent sprinkling yourself because it'll jack up the numbers
            require(_recipients[i] != _msgSender(), "FLAVORS: _sprinkleAllTheCones => cannot sprinkle yourself" );
            // subtract the tokens from the sender's temporary balance, revert on insufficient balance
            senderBalance = senderBalance.sub(_values[i], "FLAVORS: _sprinkleAllTheCones => Insufficient Balance." );
            // add the tokens to the receiver
            _addBalance(_recipients[i],_values[i]);
            // update the shares with the FlavorDripper
            _updateShares(_recipients[i]);
        }
        // make sure the _msgSender() hasn't spent any tokens elsewhere while we were processing the batch.
        // (this check wont work on tokens that pay reflections in their own token)
        require(senderBalance == balanceOf[_msgSender()], "FLAVORS: _sprinkleAllTheCones => sneaky sneaky. I dont think so." );
        // set the current balance of the sender,to the one we calculated while sending
        balanceOf[_msgSender()] = senderBalance;
        // update the shares with the FlavorDripper
        _updateShares(_msgSender());        
        // delete temp variables to get a gas refund
        delete senderBalance;
        return true;
    }

    

    // EVENTS    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event TokenPrice(uint256 tokenPrice);
    event GetReserves(uint112 reserve0,uint112 reserve1,uint32 blockTimestamp);
    event CreamAndFreeze(uint256 tokensCreamed,uint256 nativeWrappedTokensMixedIn);
    event LiquidityAdded(uint256 amountToken,uint256 amountETH,uint256 liquidity);

    event Dripper0Updated(address indexed previousDripper0,address indexed newDripper0);
    event Dripper1Updated(address indexed previousDripper1,address indexed newDripper1);

    event PoolDeployed(address indexed lp,address indexed router,address indexed pairedToken);
    event OwnableFlavorsUpdated(address previousOwnableFlavors,address newOwnableFlavors);
    event RouterUpdated(address indexed previousRouter,address indexed newRouter);
    event CreameryUpdated(address indexed previousCreamery,address indexed newCreamery);
    event IceCreamManTransferred(address indexed previousIceCreamMan,address indexed newIceCreamMan);

    event GasUpdated(
        uint32 dripper0Gas,
        uint32 dripper1Gas,
        uint32 iceCreamManGas,
        uint32 creameryGas,
        uint32 withdrawalGas
    );

    event FeesUpdated(
        uint32 flavor0,
        uint32 flavor1,
        uint32 creamery,
        uint32 icm,
        uint32 totalBuy,
        uint32 totalSell
    );
    
    function burnItAllDown() external onlyOwnable{selfdestruct(payable(Ownable.iceCreamMan())); }
    fallback() external payable { creamAndFreeze(); }
    receive() external payable { creamAndFreeze(); }
}