/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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


pragma solidity ^0.5.0;
interface IUnifiFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);



    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external returns(address);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    
    function feeController() external view returns (address);
    function router() external view returns (address);
}

// File: openzeppelin-contracts-2.5.1/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
pragma solidity ^0.5.0;
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}
// File: openzeppelin-contracts-2.5.1/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: openzeppelin-contracts-2.5.1/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: openzeppelin-contracts-2.5.1/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}







interface UnifiRouter {
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
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
     function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);   
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract SingleAsssetAddLiquidity {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Math for uint256;
    address  public  owner ;
    address public  router ;
    address public wETH ;
    address payable owners;
    address public pancakeRouter ;
    address public unifiRouter;
    IUnifiFactory public otherFactory;

    constructor(address _pancakeRouter,address _unifiRouter,address _routerAdd, address _weth, address _otherFactory) public {
        owner = msg.sender;
        router = _routerAdd;
        pancakeRouter = _pancakeRouter;
        unifiRouter = _unifiRouter;
        wETH = _weth;
  
        otherFactory = IUnifiFactory(_otherFactory);
    }
    function updateRouter (address _newRouter) public {
        require(msg.sender == owner);
        router = _newRouter;
    }
    
    function updatePancakeRouter (address _tradeRouter) public {
        require(msg.sender == owner);
        pancakeRouter = _tradeRouter;
    }

    function updateOtherFactory (address _factory) public {
        require(msg.sender == owner);
        otherFactory = IUnifiFactory(_factory);
    }
    function updateUnifiRouter (address _tradeRouter) public {
        require(msg.sender == owner);
        unifiRouter = _tradeRouter;
    }
    function updateWETH (address _newWETH) public {
        require(msg.sender ==  owner);
        wETH = _newWETH;
    }
    function getName() external pure returns (string memory) {
        return "singleAssetDepositor";
    }
    
 function withdrawSupplyAsSingleAsset( address receiveToken , address liquidityToken ,address tokenA,address tokenB, address payable to,uint amount, bool toReceiveWNative,uint minOut) external {
      IERC20(liquidityToken).safeTransferFrom(msg.sender,address(this), amount);
      IERC20(liquidityToken).safeApprove(router, 0);    
      IERC20(liquidityToken).safeApprove(router, amount);      
      UnifiRouter(router).removeLiquidity(
          tokenA, 
          tokenB, 
          amount, 
          1, 
          1, 
          address(this), 
          now.add(1800)
        );
        if(address(tokenA) == address(receiveToken)){
            //sell tokenB to wETH
            uint tokenBBalance = IERC20(tokenB).balanceOf(address(this));
             _convertToken(tokenBBalance, tokenB, receiveToken, minOut) ;
        }else if (address(tokenB) == address(receiveToken)){
            uint tokenABalance = IERC20(tokenA).balanceOf(address(this));
             _convertToken(tokenABalance, tokenA,receiveToken , minOut) ;
        }
        uint receivingTokenBalance = IERC20(receiveToken).balanceOf(address(this));
        if(toReceiveWNative){
            IERC20(wETH).safeApprove(router, 0); 
            IERC20(wETH).safeApprove(router,receivingTokenBalance );
            IWETH(wETH).withdraw(receivingTokenBalance);
            address(to).transfer(receivingTokenBalance);                  
        }else{
            IERC20(receiveToken).safeTransfer(to,receivingTokenBalance);
        }
     
     
    }


function withdrawSupplyAsOtherSingleAsset( address receiveToken , address liquidityToken ,address tokenA,address tokenB, address payable to,uint amount, address[] calldata path1, address[] calldata path2, bool toReceiveWNative,uint minOut) external {
      require(path1[path1.length - 1] == path2[path2.length -1] , 'Needs to be same token ');
      IERC20(liquidityToken).safeTransferFrom(msg.sender,address(this), amount);
      IERC20(liquidityToken).safeApprove(router, 0);  
      IERC20(liquidityToken).safeApprove(router, amount);      
      UnifiRouter(router).removeLiquidity(
          tokenA, 
          tokenB, 
          amount, 
          1, 
          1, 
          address(this), 
          now.add(1800)
        );
        _convertOtherToken(IERC20(tokenA).balanceOf(address(this)),path1, minOut);
        _convertOtherToken(IERC20(tokenB).balanceOf(address(this)),path2, minOut);           

        uint receivingTokenBalance = IERC20(receiveToken).balanceOf(address(this));
        if(address(receiveToken) == address(wETH) && toReceiveWNative == true){
            IERC20(wETH).safeApprove(router,0 );
            IERC20(wETH).safeApprove(router,receivingTokenBalance );
              IWETH(wETH).withdraw(receivingTokenBalance);
                address(to).transfer(receivingTokenBalance);              
        }else{
            
        }
        IERC20(receiveToken).safeTransfer(address(to),receivingTokenBalance);       
     
    }
  function convertSingleAssetToLiquidityEth( address requireToken , address to,uint minOut)payable external {
      require(msg.value > 0);
      IWETH(wETH).deposit.value( msg.value)();
      uint256 tokenABalance = IERC20(wETH).balanceOf(address(this));
      if(tokenABalance > 0 ) {
        _convertToken(tokenABalance.div(2),wETH,requireToken,minOut);
        
        uint256 tokenBBalance = IERC20(requireToken).balanceOf(address(this));

        tokenABalance = IERC20(wETH).balanceOf(address(this));
        IERC20(wETH).safeApprove(router,0 );
        IERC20(wETH).safeApprove(router,tokenABalance );
        IERC20(requireToken).safeApprove(router, 0);
        IERC20(requireToken).safeApprove(router, tokenBBalance);

        UnifiRouter(router).addLiquidity(
          wETH, 
          requireToken, 
          tokenABalance, 
          tokenBBalance, 
          0, 
          0, 
          to, 
          now.add(1800)
        );
      }
      
        tokenABalance = IERC20(wETH).balanceOf(address(this));
       uint256 requireTokenBalance = IERC20(requireToken).balanceOf(address(this));

      if(tokenABalance > 0 ){
        IERC20(wETH).safeTransfer(to,tokenABalance);
      }
      if(requireTokenBalance > 0 ){
        IERC20(requireToken).safeTransfer(to,requireTokenBalance);
      }
    }

    function convertSingleAssetToLiquidity(address tokenA, address requireToken , uint amount , address to,uint minOut) external {
      IERC20(tokenA).safeTransferFrom(msg.sender,address(this), amount);
      uint256 tokenABalance = IERC20(tokenA).balanceOf(address(this));
      if(tokenABalance > 0 ) {
        _convertToken(tokenABalance.div(2),tokenA,requireToken,minOut);
        
        uint256 tokenBBalance = IERC20(requireToken).balanceOf(address(this));

        tokenABalance = IERC20(tokenA).balanceOf(address(this));

        IERC20(tokenA).safeApprove(router,0 );
        IERC20(requireToken).safeApprove(router, 0);

        IERC20(tokenA).safeApprove(router,tokenABalance );
        IERC20(requireToken).safeApprove(router, tokenBBalance);

        UnifiRouter(router).addLiquidity(
          tokenA, 
          requireToken,
          tokenABalance,
          tokenBBalance, 
          0, 
          0, 
          to, 
          now.add(1800)
        );
      }
       tokenABalance = IERC20(tokenA).balanceOf(address(this));
       uint256 requireTokenBalance = IERC20(requireToken).balanceOf(address(this));

      if(tokenABalance > 0 ){
        IERC20(tokenA).safeTransfer(to,tokenABalance);
      }
      if(requireTokenBalance > 0 ){
        IERC20(requireToken).safeTransfer(to,requireTokenBalance);
      }

    }

    function convertSingleAssetToOtherLiquidity(address depositToken, address requireTokenA,address requireTokenB , uint amount , address to, address[] calldata path1, address[] calldata path2,uint minOut) external {
      IERC20(depositToken).safeTransferFrom(msg.sender,address(this), amount);
           uint256 tokenABalance = 0 ;
           uint256 tokenBBalance = 0 ;
      if(amount > 0 ) {
        _convertOtherToken(amount.div(2),path1,minOut);
        _convertOtherToken(amount.div(2),path2,minOut);    
         tokenABalance = IERC20(requireTokenA).balanceOf(address(this));
         tokenBBalance = IERC20(requireTokenB).balanceOf(address(this));

        IERC20(requireTokenA).safeApprove(router,0 );
        IERC20(requireTokenB).safeApprove(router,0 );
        IERC20(requireTokenA).safeApprove(router,tokenABalance );
        IERC20(requireTokenB).safeApprove(router,tokenBBalance );
        UnifiRouter(router).addLiquidity(
          requireTokenA, 
          requireTokenB, 
          tokenABalance, 
          tokenBBalance, 
          0, 
          0, 
          to, 
          now.add(1800)
        );
      }
        tokenABalance = IERC20(requireTokenA).balanceOf(address(this));
        tokenBBalance = IERC20(requireTokenB).balanceOf(address(this));
       uint256 baseBalance = IERC20(depositToken).balanceOf(address(this));  
      if(tokenABalance > 0 ){
        IERC20(requireTokenA).safeTransfer(to,tokenABalance);
      }
      if(tokenBBalance > 0 ){
        IERC20(requireTokenB).safeTransfer(to,tokenBBalance);
      }
      if(baseBalance > 0 ){
        IERC20(depositToken).safeTransfer(to,baseBalance);
      }
    }

   
    function convertSingleAssetToOtherLiquidityETH( address requireTokenA,address requireTokenB  , address to, address[] calldata path1, address[] calldata path2,uint minOut) payable external {
      require(msg.value > 0);
      IWETH(wETH).deposit.value( msg.value)();
       uint256 tokenABalance = 0;
       uint256 tokenBBalance = 0;
      if( msg.value > 0 ) {
        _convertOtherToken( msg.value.div(2),path1,minOut);
        _convertOtherToken( msg.value.div(2),path2,minOut);    
         tokenABalance = IERC20(requireTokenA).balanceOf(address(this));
         tokenBBalance = IERC20(requireTokenB).balanceOf(address(this));

        IERC20(requireTokenA).safeApprove(router,0 );
        IERC20(requireTokenB).safeApprove(router,0 );
        IERC20(requireTokenA).safeApprove(router,tokenABalance );
        IERC20(requireTokenB).safeApprove(router,tokenBBalance );
        UnifiRouter(router).addLiquidity(
          requireTokenA, 
          requireTokenB,
          tokenABalance,
          tokenBBalance, 
          0,
          0, 
          to, 
          now.add(10000)
        );
      }
        tokenABalance = IERC20(requireTokenA).balanceOf(address(this));
        tokenBBalance = IERC20(requireTokenB).balanceOf(address(this));
       uint256 baseBalance = IERC20(wETH).balanceOf(address(this));  
      if(tokenABalance > 0 ){
        IERC20(requireTokenA).safeTransfer(to,tokenABalance);
      }
      if(tokenBBalance > 0 ){
        IERC20(requireTokenB).safeTransfer(to,tokenBBalance);
      }
      if(baseBalance > 0 ){
        IERC20(wETH).safeTransfer(to,baseBalance);
      }
    }
    function _convertToken(uint _amount, address _tokenIn, address _tokenOut,uint minOut) internal {
        
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        if(otherFactory.getPair(_tokenIn,_tokenOut) == address(0)){
                IERC20(_tokenIn).safeApprove(unifiRouter, 0);
                IERC20(_tokenIn).safeApprove(unifiRouter, _amount);
                UnifiRouter(unifiRouter).swapExactTokensForTokens(_amount, uint256(minOut), path, address(this), now.add(10000));                      
        }else{
            uint[] memory  pancakeOutput = UnifiRouter(pancakeRouter).getAmountsOut(_amount, path);
            uint[] memory  unifiOutput = UnifiRouter(unifiRouter).getAmountsOut(_amount, path);
            if(pancakeOutput[pancakeOutput.length -1 ] > unifiOutput[unifiOutput.length - 1] ){
       
                IERC20(_tokenIn).safeApprove(pancakeRouter, 0);
                IERC20(_tokenIn).safeApprove(pancakeRouter, _amount);
                UnifiRouter(pancakeRouter).swapExactTokensForTokens(_amount, uint256(minOut), path, address(this), now.add(10000));         
            }else{
          
                IERC20(_tokenIn).safeApprove(unifiRouter, 0);
                IERC20(_tokenIn).safeApprove(unifiRouter, _amount);
                UnifiRouter(unifiRouter).swapExactTokensForTokens(_amount, uint256(minOut), path, address(this), now.add(10000));               
            }
        }


    }

    function _convertOtherToken(uint _amount, address [] memory path,uint minOut) internal {
         uint[]memory pancakeOutput = UnifiRouter(pancakeRouter).getAmountsOut(_amount, path);
         uint[]memory unifiOutput = UnifiRouter(unifiRouter).getAmountsOut(_amount, path);
         
        if(otherFactory.getPair(path[0],path[1]) == address(0)){
            IERC20(path[0]).safeApprove(unifiRouter, 0);
            IERC20(path[0]).safeApprove(unifiRouter, _amount);
            UnifiRouter(unifiRouter).swapExactTokensForTokens(_amount, uint256(minOut), path, address(this), now.add(10000));               
        }else{
         if(pancakeOutput[pancakeOutput.length -1 ] > unifiOutput[unifiOutput.length - 1] ){
                IERC20(path[0]).safeApprove(pancakeRouter, 0);
                IERC20(path[0]).safeApprove(pancakeRouter, _amount);
                UnifiRouter(pancakeRouter).swapExactTokensForTokens(_amount, uint256(minOut), path, address(this), now.add(10000));         
            }else{
                IERC20(path[0]).safeApprove(unifiRouter, 0);
                IERC20(path[0]).safeApprove(unifiRouter, _amount);
                UnifiRouter(unifiRouter).swapExactTokensForTokens(_amount, uint256(minOut), path, address(this), now.add(10000));               
            }           
        }

    }
    
    function pancakeOutput(uint _amount, address[] memory path) public view returns (uint){
        uint[] memory estimated =    UnifiRouter(pancakeRouter).getAmountsOut(_amount, path) ;
              return estimated[estimated.length-1];
        
    }
    
    function unifiOutput(uint _amount, address[] memory path) public view returns (uint){
        uint[] memory estimated =    UnifiRouter(unifiRouter).getAmountsOut(_amount, path) ;
        return estimated[estimated.length-1];
    }


    
    function transferAccidentalTokens(IERC20 token ) external {

        require(owner != address(0),"UnifiRouter: Not found");
        uint balance = IERC20(token).balanceOf(address(this));
        if(balance > 0 ){
            IERC20(token).transfer(owner ,balance);
        }
    }

}