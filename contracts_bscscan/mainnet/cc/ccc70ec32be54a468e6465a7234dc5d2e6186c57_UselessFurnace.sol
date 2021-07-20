/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity ^0.8.5;

/**
 * Created June 21 2021
 * Developed by SafemoonMark
 * USELESS Furnace Contract to Buy / Burn USELESS
 */
// SPDX-License-Identifier: Unlicensed

/*
 * Context Contract
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

interface IERC20 {

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
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IUniswapV2Router02 {
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
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}
/**
 * 
 * BNB Sent to this contract will be used to automatically buy/burn USELESS
 * And Emits and Event to the blockchain with how much BNB was used
 * Liquidity between 10-15% - reverse SAL
 * Liquidity over 15% - buy/burn or LP extraction
 * Liquidity under 10% - inject LP from sidetokenomics or trigger SAL from previous LP Extractions
 *
 */
contract UselessFurnace is Context, Ownable {
    
  using Address for address;
  using SafeMath for uint256;
  
  // address of USELESS Smart Contract
  address payable private _uselessAddr = payable(0x2cd2664Ce5639e46c6a3125257361e01d0213657);
  // burn wallet address
  address payable private _burnWallet = payable(0x000000000000000000000000000000000000dEaD);
  // useless liquidity pool address
  address private _uselessLP = 0x08A6cD8a2E49E3411d13f9364647E1f2ee2C6380; 
  // Total Amount of BNB that has been used to Buy/Sell USELESS
  uint256 public _totalBNBUsedToBuyAndBurnUSELESS = 0;
  // Initialize Pancakeswap Router
  IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  uint256 private maxPercent = 99;
  uint256 public pairLiquidityUSELESSThreshold = 10**12;
  uint256 public pairLiquidityBNBThreshold = 10**12;
  
  bool public canPairLiquidity = true;
  bool public canPullLiquidity = true;
  uint256 public liquidityAdded = 0;
  
  uint256 public minimumLiquidityNeededToPull = 2;
  /** Expressed as 100 / x */
  uint256 public pullLiquidityRange = 5;
  /** Expressed as 100 / x */
  uint256 public buyAndBurnRange = 6;
  /** Expressed as 100 / x */
  uint256 public reverseSALRange = 10;
  
  // Tells the blockchain how much BNB was used on every Buy/Burn
  event BuyAndBurn(
    uint256 amountBurned
  );
  
  event BuyBack(
    uint256 amountBought
  );
  
  event SwapAndLiquify(
    uint256 uselessAmount,
    uint256 bnbAmount
  );
  
  event ReverseSwapAndLiquify(
    uint256 uselessAmount,
    uint256 bnbAmount
  );
  
  event LiquidityPairAdded(
      uint256 uselessamount,
      uint256 bnbAmount
  );
  
  /**
   * Automates the Buy/Burn, SAL, or reverseSAL operations based on the state of the LP
   */ 
  function automate() public onlyOwner {
    
    // determine the health of the lp
    uint256 dif = determineLPHealth();
    
    if (dif < 1) {
        dif = 1;
    }
    
    if (dif <= buyAndBurnRange) {
        // if LP is over 20% we pull liquidity if there are LP tokens available
        if (dif <= pullLiquidityRange && liquidityAdded >= minimumLiquidityNeededToPull && canPullLiquidity) {
            pullLiquidity(maxPercent.div(dif));
            dif = determineLPHealth();
        }
        // if LP is over 15% of Supply we buy burn useless or pull liquidity
        uint256 ratio = maxPercent.div(dif);
        buyAndBurn(ratio);
    } else if (dif <= reverseSALRange) {
        // if LP is between 10-15% of Supply we call reverseSAL
        reverseSwapAndLiquify();
    } else {
        // if LP is under 10% of Supply we call SAL or provide a pairing if one exists
        (bool success, uint256 uAMT, uint256 bAMT) = pairLiquidityThresholdReached();
        
        if (success && canPairLiquidity) {
            pairLiquidity(uAMT, bAMT);
        } else {
            if (uAMT <= pairLiquidityUSELESSThreshold) {
                reverseSwapAndLiquify();
            } else {
                swapAndLiquify(dif);
            }
        }
    }
  }

  /**
   * Buys USELESS Tokens and sends them to the burn wallet
   * @param percentOfBNB - Percentage of BNB Inside the contract to buy/burn with
   */ 
  function buyAndBurn(uint256 percentOfBNB) public onlyOwner {
      
     uint256 buyBurnBalance = ((address(this).balance).mul(percentOfBNB)).div(10**2);
     
     buyAndBurnUseless(buyBurnBalance);
     
     _totalBNBUsedToBuyAndBurnUSELESS = _totalBNBUsedToBuyAndBurnUSELESS.add(buyBurnBalance);
     
     emit BuyAndBurn(buyBurnBalance);
  }
  
  /**
   * Sells half of percent of USELESS in the contract address for BNB, pairs it and adds to Liquidity Pool
   * Similar to swapAndLiquify
   * @param percent - Percentage out of 100 for how much USELESS to be used in swapAndLiquify
   */
   function swapAndLiquify(uint256 percent) public onlyOwner {
       
    uint256 oldContractBalance = IERC20(_uselessAddr).balanceOf(address(this));
    
    uint256 contractBalance = (oldContractBalance.mul(percent)).div(10**2);
    
    if (contractBalance > oldContractBalance) {
        contractBalance = oldContractBalance;
    }
    
    // split the contract balance in half
    uint256 half = contractBalance.div(2);
    uint256 otherHalf = contractBalance.sub(half);

    // balance of BNB before we swap
    uint256 initialBalance = address(this).balance;

    // swap tokens for BNB
    swapTokensForBNB(half);

    // how many tokens were received from swap
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // add liquidity to Pancakeswap
    addLiquidity(otherHalf, newBalance);
        
    emit SwapAndLiquify(otherHalf, newBalance);
   }
   
   /**
   * Uses BNB in Contract to Purchase Useless, pairs with remaining BNB and adds to Liquidity Pool
   * Similar to swapAndLiquify
   */
   function reverseSwapAndLiquify() public onlyOwner {
      
    // BNB Balance before the swap
    uint256 initialBalance = address(this).balance;
    
    // USELESS Balance before the Swap
    uint256 contractBalance = IERC20(_uselessAddr).balanceOf(address(this));

    // Swap 50% of the BNB in Contract for USELESS Tokens
    justBuyBack(50);

    // how much bnb was spent on the swap
    uint256 bnbInSwap = initialBalance.sub(address(this).balance);
    
    // how many USELESS Tokens do we have now?
    uint256 currentBalance = IERC20(_uselessAddr).balanceOf(address(this));

    // Get Exact Number of USELESS We Swapped For
    uint256 diff = currentBalance.sub(contractBalance);
    
    if (bnbInSwap > address(this).balance) {
        bnbInSwap = address(this).balance;
    }
    
    // add liquidity to Pancakeswap
    addLiquidity(diff, bnbInSwap);
        
    emit ReverseSwapAndLiquify(diff, bnbInSwap);
   }
   
   /**
    * Tries and forces a liquidity pairing. Transaction will fail if thresholds are not met
    */
   function manuallyPairLiquidity() public onlyOwner {
       
       (bool success, uint256 uAMT, uint256 bAMT) = pairLiquidityThresholdReached();
       require(success, 'Liquidity Thresholds Have Not Been Reached');
       
       if (success) {
        pairLiquidity(uAMT, bAMT);
       }
   }
   
   /**
    * Pairs BNB and USELESS in the contract and adds to liquidity if we are above thresholds 
    */
   function pairLiquidity(uint256 uselessInContract, uint256 bnbInContract) private {
     
       require(bnbInContract <= address(this).balance, 'Cannot swap more than contracts supply');
       
        // get amount of useless in the pool 
        uint256 uselessLP = IERC20(_uselessAddr).balanceOf(_uselessLP);
        // amount of bnb in the pool
        uint256 bnbLP = address(_uselessLP).balance;
       
       uint256 ratio = 1; 
       uint256 uselessAmount = 1;
       uint256 bnbAmount = 1;
       
       if (uselessLP < bnbLP) {
           
           ratio = bnbLP.div(uselessLP);
           // multiply by amount of useless 
           bnbAmount = ratio.mul(uselessInContract);
           
           if (bnbAmount <= bnbInContract) {
               addLiquidity(uselessInContract, bnbAmount);
           } else {
               
               // we do not have enough in contract
               uselessAmount = bnbInContract.div(ratio);
               addLiquidity(uselessAmount, bnbAmount);
           }
           
       } else {
           
           ratio = uselessLP.div(bnbLP);
           bnbAmount = ratio.div(uselessInContract);
           
           if (bnbAmount <= bnbInContract) {
               addLiquidity(uselessInContract, bnbAmount);
           } else {
               
               // we do not have enough in contract
               uselessAmount = bnbInContract.mul(ratio);
               addLiquidity(uselessAmount, bnbAmount);
           }
       }
       emit LiquidityPairAdded(uselessAmount, bnbAmount);
   }
   
  /**
   * Returns the health of the LP, more specifically circulatingSupply / sizeof(lp)
   */ 
  function checkLPHealth() public view returns(uint256) {
      return determineLPHealth();
  }

   
   /**
    * Returns true if both useless and bnb quantities have reached their thresholds
    */
   function pairLiquidityThresholdReached() private view returns(bool, uint256, uint256) {
       
       // amount of useless in our contract
       uint256 uselessInContract = IERC20(_uselessLP).balanceOf(address(this));
       // amount of bnb in contract
       uint256 bnbInContract = address(this).balance;
       
       return(uselessInContract > pairLiquidityUSELESSThreshold && bnbInContract > pairLiquidityBNBThreshold, uselessInContract, bnbInContract);
       
   }

  /**
   * Internal Function which calls UniswapRouter function 
   */ 
  function buyAndBurnUseless(uint256 bnbAmount) private {
    
    // Uniswap pair path for BNB -> USELESS
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = _uselessAddr;
    
    // Swap BNB for USELESS
    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
        0, // accept any amount of USELESS
        path,
        _burnWallet, // Burn Address
        block.timestamp.add(300)
    );  
      
  }
  
   /**
   * Buys USELESS with BNB Stored in the contract, and stores the USELESS in the contract
   * @param ratioOfBNB - Percentage of contract's BNB to Buy
   */ 
  function justBuyBack(uint256 ratioOfBNB) private {
      
    require(ratioOfBNB <= 100, 'Cannot have a ratio over 100%');
    // calculate the amount being transfered 
    uint256 transferAMT = ((address(this).balance).mul(ratioOfBNB)).div(10**2);
    
    // Uniswap pair path for BNB -> USELESS
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = _uselessAddr;
    
    // Swap BNB for USELESS
    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: transferAMT}(
        0, // accept any amount of USELESS
        path,
        address(this), // Store in Contract
        block.timestamp.add(300)
    );  
      
    emit BuyBack(transferAMT);
  }
  
  /**
   * Swaps USELESS for BNB using the USELESS/BNB Pool
   */ 
  function swapTokensForBNB(uint256 tokenAmount) private {
    // generate the uniswap pair path for token -> weth
    address[] memory path = new address[](2);
    path[0] = _uselessAddr;
    path[1] = uniswapV2Router.WETH();

    IERC20(_uselessAddr).approve(address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // accept any amount of ETH
        path,
        address(this),
        block.timestamp
    );
    }
    /**
     * Determines the Health of the LP
     * returns the percentage of the Circulating Supply that is in the LP
     */ 
    function determineLPHealth() private view returns(uint256) {
        
        // calculate the current Circulating Supply of USELESS    
        uint256 totalSupply = 1000000000 * 10**6 * 10**9;
        // size of burn wallet
        uint256 burnWalletSize = IERC20(_uselessAddr).balanceOf(_burnWallet);
        // Circulating supply is total supply - burned supply
        uint256 circSupply = totalSupply.sub(burnWalletSize);    
        // Find the balance of USELESS in the liquidity pool
        uint256 lpBalance = IERC20(_uselessAddr).balanceOf(_uselessLP);

        return circSupply.div(lpBalance);
        
    }
    
  /**
   * Adds USELESS and BNB to the USELESS/BNB Liquidity Pool
   */ 
  function addLiquidity(uint256 uselessAmount, uint256 bnbAmount) private {
       
    IERC20(_uselessAddr).approve(address(uniswapV2Router), uselessAmount);

    // add the liquidity
    (,,uint256 amountLiquidity) = uniswapV2Router.addLiquidityETH{value: bnbAmount}(
        _uselessAddr,
        uselessAmount,
        0,
        0,
        address(this),
        block.timestamp.add(300)
    );
    
    liquidityAdded = liquidityAdded.add(amountLiquidity);
    }

    /**
     * Removes Liquidity from the pool and stores the BNB and USELESS in the contract
     */
   function pullLiquidity(uint256 percentLiquidity) public onlyOwner {
       
       uint256 pLiquidity = (liquidityAdded.mul(percentLiquidity)).div(10**2);
       
       uniswapV2Router.removeLiquidityETH(
        _uselessAddr,
        pLiquidity,
        0,
        0,
        address(this),
        block.timestamp.add(60)
        );
        
        liquidityAdded = liquidityAdded.sub(pLiquidity);
   }
    
  /**
   * @dev Returns the owner of the contract
   */
  function getOwner() external view returns (address) {
    return owner();
  }
  /**
   * Amount of BNB in this contract
   */ 
  function getContractBNBBallance() external view returns (uint256) {
    return address(this).balance;
  }
  
   /**
   * 
   * Updates the Uniswap Router and Uniswap pairing for ETH In Case of migration
   */
  function setUniswapV2Router(address _uniswapV2Router) public onlyOwner {
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
  }
  
  /**
   * Updates the Uniswap Router and Uniswap pairing for ETH In Case of migration
   */
  function setUselessLPAddress(address nUselessLP) public onlyOwner {
    _uselessLP = nUselessLP;
  }

  /**
   * Updates the Contract Address for USELESS
   */
  function setUSELESSContractAddress(address payable newUselessAddress) public onlyOwner {
    _uselessAddr = newUselessAddress;
  }
  
  function setCanPairLiquidity(bool cPL) public onlyOwner {
      canPairLiquidity = cPL;
  }
  
  function setPairLiquidityBNBThreshold(uint256 bnbTH) public onlyOwner {
      pairLiquidityBNBThreshold = bnbTH;
  }
  
  function setPairLiquidityUSELESSThreshold(uint256 uselessTH) public onlyOwner {
      pairLiquidityUSELESSThreshold = uselessTH;
  }
  
  function setCanPullLiquidity(bool canPull) public onlyOwner {
      canPullLiquidity = canPull;
  }
  
  function setMinimumLiquidityNeededToPull(uint256 nMinimum) public onlyOwner {
      minimumLiquidityNeededToPull = nMinimum;
  }
  
  function setBuyBurnRange(uint256 nRange) public onlyOwner {
      buyAndBurnRange = nRange;
  }
  
  function setPullLiquidityRange(uint256 nRange) public onlyOwner {
      pullLiquidityRange = nRange;
  }
  
  function setReverseSALRange(uint256 nRange) public onlyOwner {
      reverseSALRange = nRange;
  }
  
  /**
   * Updates the Burn Wallet Address for USELESS
   */
  function setUSELESSBurnAddress(address payable newBurnAddress) public onlyOwner {
    _burnWallet = newBurnAddress;
  }
  
  function withdraw() external onlyOwner {
	payable(msg.sender).transfer(address(this).balance);
  }
  

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
}