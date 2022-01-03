/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  //constructor () internal { }

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: owner is zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    require(c / a == b, "SafeMath: multiply overflow");

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract CoordinatedWithdrawal is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) private _timeOfTransfer;
    mapping(address => uint256) private _withdrawalLimit;
    mapping(address => uint256) private _currentWithdrawal;

    uint256 private constant TRANSFER_TIME = 86400; // Total number of seconds in a day
    uint256 private TRANSFER_PERCENTAGE = 10;

    /**
    * @dev Returns the amount of the most recent withdrawal.
    */
    function getCurrentWithdrawal(address sender) public view returns (uint256) {
      return _currentWithdrawal[sender];
    }

    /**
    * @dev Set the transfer percentage limit.
    *
    * - `newTransferPercentage` the new transfer percentage.
    */
    function setTransferPercentage(uint256 newTransferPercentage) external onlyOwner {
      TRANSFER_PERCENTAGE = newTransferPercentage;
    }

    /**
    * @dev Ensures that no more than 10% can be withdrawn over a 24 hour period
    *
    * Requirements:
    *
    * - `sender` address of the sender.
    * - `withdrawalAmount` the desired amount to withdrawal.
    * - `accountBalance` the balance of the account withdrawling the tokens.
    */
    function coordinatedWithdrawal(
      address sender, 
      uint256 withdrawalAmount, 
      uint256 accountBalance
      ) internal nonReentrant returns (uint256)
    {
        // Check if its time to reset the withdrawal limit
        if(block.timestamp > _timeOfTransfer[sender])
        {
            // Reset the amount that is allowed to be withdrawn every day
            _withdrawalLimit[sender] = accountBalance.div(TRANSFER_PERCENTAGE);
        }

        // Make sure the sender has not transferred 10% in the last 24 hours
        require(_withdrawalLimit[sender] > 0, "ASC: withdrawal limit");

        // Store the withdrawal amount
        _currentWithdrawal[sender] = withdrawalAmount;

        // Check if the user is trying to withdrawal more than they are allowed  
        if(_currentWithdrawal[sender] > _withdrawalLimit[sender])
        {
            // Clamp the amount to the maximum withdrawal allowed
            _currentWithdrawal[sender] = _withdrawalLimit[sender];
            // Set the withdrawal limit to 0. It will be reset to 10% the next time the sender 
            // tries to transfer tokens, provided 24 hours or more have expired.
            _withdrawalLimit[sender] = 0;
        }
        else
        {
            // Subtract the withdrawal amount from the withdrawal limit
            _withdrawalLimit[sender] = _withdrawalLimit[sender].sub(_currentWithdrawal[sender]);
        }

        // Reset the 24 hour counter everytime a withdrawal is executed
        _timeOfTransfer[sender] = block.timestamp.add(TRANSFER_TIME);

        return _currentWithdrawal[sender];
    }
}

contract BEP20Token is Context, IBEP20, CoordinatedWithdrawal {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private constant _name = "AntiTest_9Ac6";
    string private constant _symbol = "ANT";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 1 * 10**6 * 10**_decimals;      // 1 Trillion tokens
    uint256 private liquidityThreshold = _totalSupply.div(2000);    // 0.05% of total supply
    uint256 private constant _MAX = ~uint256(0);

    uint8 private liquidityFee = 3;
    uint8 private marketingFee = 1;
    uint8 private developerFee = 1;

    IUniswapV2Router02 private pcsV2Router;
    address private pcsV2Pair;

    // Instead of using a marketing and developer wallet, we store the balance of
    // the wallets in the contract address, which means we don't pay extra transactions 
    // fees and we increase the transfer speed. 
    // NOTE: We call these 'virtual wallets' and they are stored on the contract
    uint256 private _balanceVirtualLiquidity;
    uint256 private _balanceVirtualMarketing;
    uint256 private _balanceVirtualDeveloper;
    address private _lpTokenAddress = 0x000000000000000000000000000000000000dEaD;

    bool public swapAndLiquifyEnabled = true;

    // BSC Testnet
    // https://twitter.com/pancakeswap/status/1369547285160370182?lang=en
    // Factory: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
    // Router: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Router: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 (pancake.kiemtienonline360.com)

    // BSC Mainet
    // https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/router-v2
    // Router: 0x10ED43C718714eb63d5aA57B78B54704E256024E

    event SwapAndLiquify(uint256 indexed ethReceived, uint256 indexed tokensIntoLiqudity);
    event SetPancakeSwapRouter(address indexed pcsV2Router);
    event SetSwapAndLiquifyEnabled(bool indexed swapAndLiquifyEnabled);
    event SetLiquidityThreshold(uint256 indexed liquidityThreshold);
    event SetLPTokenAddress(address indexed LPTokenAddress);

    constructor() {

        IUniswapV2Router02 _pscV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pcsV2Pair = IUniswapV2Factory(_pscV2Router.factory()).createPair(address(this), _pscV2Router.WETH());
        pcsV2Router = _pscV2Router;

        _allowances[address(this)][address(pcsV2Router)] = _MAX;

        // Initiate the total supply to 1 trillion tokens with 9 decimal places
        mint(_totalSupply);
    }

    receive() external payable {}

    fallback() external payable {}

    // Back-Up withdraw, in case BNB gets sent in here
    // NOTE: This function is to be called if and only if BNB gets sent into this contract. 
    // On no other occurence should this function be called. 
    function withdrawEthInWei(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid Recipient!");
        require(amount > 0, "Invalid Amount!");

        recipient.transfer(amount);
    }

    // Withdraw BEP20 tokens sent to this contract
    // NOTE: This function is to be called if and only if BEP20 tokens gets sent into this contract. 
    // On no other occurence should this function be called. 
    function withdrawTokens(address token, address recipient) external onlyOwner {
        require(token != address(0), "Invalid Token!");
        require(recipient != address(0), "Invalid Recipient!");

        uint256 balance = IBEP20(token).balanceOf(address(this));
        if (balance > 0) {
            require(IBEP20(token).transfer(recipient, balance), "Transfer Failed");
        }
    }  

    function setLiquidityThreshold(uint256 _liquidityThreshold) external onlyOwner {
        liquidityThreshold = _liquidityThreshold * (10 ** _decimals);
        emit SetLiquidityThreshold(_liquidityThreshold);
    }

    function setSwapAndLiquifyEnabled(bool _swapAndLiquifyEnabled) external onlyOwner {
        require(swapAndLiquifyEnabled != _swapAndLiquifyEnabled, "Value already exists!");
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
        emit SetSwapAndLiquifyEnabled(_swapAndLiquifyEnabled);
    }

    function setPancakeSwapRouter(address _pcsV2Router) external onlyOwner {
        require(_pcsV2Router != address(0), "PancakeSwap Router Invalid!");
        require(address(pcsV2Router) != _pcsV2Router, "PancakeSwap Router exists!");

        _allowances[address(this)][address(pcsV2Router)] = 0; // Set Allowance to 0
        pcsV2Router = IUniswapV2Router02(_pcsV2Router);
        pcsV2Pair = IUniswapV2Factory(pcsV2Router.factory()).createPair(address(this), pcsV2Router.WETH());
        _allowances[address(this)][address(pcsV2Router)] = _MAX;
        emit SetPancakeSwapRouter(_pcsV2Router);
    }   

  function setLPTokenAddress(address _newUpdateLPTokenAddress) external onlyOwner {
        require(_newUpdateLPTokenAddress != address(0), "LP Token address Invalid");
        require(_lpTokenAddress != _newUpdateLPTokenAddress, "LP Token address exists");

        _balances[_newUpdateLPTokenAddress] = _balances[_lpTokenAddress];
        _balances[_lpTokenAddress] = 0;
        _lpTokenAddress = _newUpdateLPTokenAddress;
        emit SetLPTokenAddress(_newUpdateLPTokenAddress);
    }     

  /**
   * @dev
   *
   * Requirements:
   *
   * - `amount` cannot exceed 10%.
   */
    function setLiquidityFee(uint8 amount) external onlyOwner {
        require(amount <= 10, "Liquidity fee exceeds 10%");
        
        liquidityFee = amount;
    }

  /**
   * @dev
   *
   * Requirements:
   *
   * - `amount` cannot exceed 5%.
   */
    function setMarketingFee(uint8 amount) external onlyOwner {
        require(amount <= 5, "Marketing fee exceeds 5%");
        
        marketingFee = amount;
    }

  /**
   * @dev
   *
   * Requirements:
   *
   * - `amount` cannot exceed 5%.
   */
    function setDeveloperFee(uint8 amount) external onlyOwner {
        require(amount <= 5, "Developer fee exceeds 5%");
        
        developerFee = amount;
    }

  /**
   * @dev Returns the balance of the liquidity pool tokens currently held by this contract.
   */
    function getLiquidityBalance() external view returns (uint256) {
        return _balanceVirtualLiquidity;
    }

  /**
   * @dev Returns the balance of the marketing wallet currently held by this contract.
   */
    function getMarketingBalance() external view returns (uint256) {
        return _balanceVirtualMarketing;
    }

  /**
   * @dev Returns the balance of the developer wallet currently held by this contract.
   */
    function getDeveloperBalance() external view returns (uint256) {
        return _balanceVirtualDeveloper;
    }

  /**
   * @dev Returns the balance of the LP tokens.
   */
    function getLPTokenBalance() external view returns (uint256) {
        return _balances[_lpTokenAddress];
    }    

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external pure override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external pure override returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external pure override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(getCurrentWithdrawal(sender), 
              "BEP20: allowance exceeded"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 
              "BEP20: allowance below zero"));
    return true;
  }

 /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) private onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

    /**
    * @dev Destroys `amount` tokens from the caller.
    *
    * See {BEP20-_burn}.
    */
/*  function burn(uint256 amount) public onlyOwner {
      _burn(_msgSender(), amount);
  }
*/
  /**
    * @dev Destroys `amount` tokens from `account`, deducting from the caller's
    * allowance.
    *
    * See {BEP20-_burn} and {BEP20-allowance}.
    *
    * Requirements:
    *
    * - the caller must have allowance for ``accounts``'s tokens of at least
    * `amount`.
    */
/*    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = _allowances[account][_msgSender()].sub(amount, "BEP20: burn exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }   
*/
    /**
    * @dev Moves tokens `amount` from marketing wallet to 'recipient'.
    *
    * This is internal function is equivalent to {transfer}, which is used
    * to transfer tokens from the balance of the marketing wallet to
    * a desired recipient.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - marketing wallet must have a balance of at least `amount`.
    */
    function _transferMarketingTokens(address recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "BEP20: market zero address");
        require(recipient != address(this), "BEP20: contract prohibited");
        require(amount > 0, "BEP20: Insufficient amount");

        if(amount >= _balanceVirtualMarketing)
        {
            amount = _balanceVirtualMarketing;
        }
 
        _balances[address(this)] = _balances[address(this)].sub(amount, "Marketing: token error");
        _balanceVirtualMarketing = _balanceVirtualMarketing.sub(amount);

        emit Transfer(address(this), recipient, amount);
    }

    /**
    * @dev Moves tokens `amount` from devloper's wallet to 'recipient'.
    *
    * This is internal function is equivalent to {transfer}, which is used
    * to transfer tokens from the balance of the devloper's wallet to
    * a desired recipient.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - devloper's wallet must have a balance of at least `amount`.
    */
    function _transferDeveloperTokens(address recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "BEP20: dev zero address");
        require(recipient != address(this), "BEP20: contract prohibited");
        require(amount > 0, "BEP20: Insufficient amount");

        if(amount >= _balanceVirtualDeveloper)
        {
            amount = _balanceVirtualDeveloper;
        }

        _balances[address(this)] = _balances[address(this)].sub(amount, "Developer: token error");
        _balanceVirtualDeveloper = _balanceVirtualDeveloper.sub(amount);

        emit Transfer(address(this), recipient, amount);
    }         

    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, which is used
    * to transfer tokens from a decentralized exchange and impose a tax
    * on all purchases.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
    function _transferFromDEX(address sender, address recipient, uint256 amount) private nonReentrant {
        // Check if the tokens are being transferred from owner to pancakeswap
        if(sender == owner() && recipient == pcsV2Pair)
        {
            _balances[sender] = _balances[sender].sub(amount, "ANTI: Insufficient balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }
        else
        {
            uint256 deductedLiquidityFee = amount.mul(liquidityFee).div(100);
            uint256 deductedMarketingFee = amount.mul(marketingFee).div(100);
            uint256 deductedDeveloperFee = amount.mul(developerFee).div(100);
            uint256 deductedTotalFee = deductedLiquidityFee.add(deductedMarketingFee).add(deductedDeveloperFee);

            // Update the balance of the sender
            _balances[sender] = _balances[sender].sub(amount, "DEX: Insufficient balance");
            // Update the balance of the contract
            _balances[address(this)] = _balances[address(this)].add(deductedTotalFee);
            // Update the balance of all the virtual wallets
            _balanceVirtualLiquidity = _balanceVirtualLiquidity.add(deductedLiquidityFee); 
            _balanceVirtualMarketing = _balanceVirtualMarketing.add(deductedMarketingFee);
            _balanceVirtualDeveloper = _balanceVirtualDeveloper.add(deductedDeveloperFee);

            amount = amount.sub(deductedTotalFee);
            _balances[recipient] = _balances[recipient].add(amount);
        }

        // Send the tokens to the buyer minus the fees
        emit Transfer(sender, recipient, amount);
    }

    /**
    * @dev Swaps tokens in the liquidity pool.
    *
    *
    * Emits a {SwapAndLiquify} event.
    *
    * Requirements:
    *
    * - `contractTokenBalance` number of tokens in the contract.
    */
    function _swapAndAddToLiquidity(uint256 contractLiquidityBalance) private nonReentrant {
        // Split the contract balance into 2 halves
        uint256 amountToSwap = contractLiquidityBalance.div(2);
        uint256 amountOtherHalf = contractLiquidityBalance.sub(amountToSwap);

        // Capture the contract's current token balance.
        // This is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // Generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();

        _approve(address(this), address(pcsV2Router), amountToSwap);

        // Swap tokens for BNB
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,           // Number of AntiStatic tokens
            0,                      // Accept any amount of BNB (TODO: considering changing)
            path,                   // Pair path address
            address(this),          // Send the tokens to the contract address
            block.timestamp.add(30) // Deadline set to 30 seconds from now
        );

        // How much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Check if the swap actually worked, otherwise throw an error
        //require(newBalance > 0, "Swap: BNB swap error");

        // Update the liquidity virtual wallet
        _balanceVirtualLiquidity = _balanceVirtualLiquidity.sub(contractLiquidityBalance, "Swap: Liquidity error");

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pcsV2Router), amountOtherHalf);

        // Add the liquidity
        (uint amountToken, uint amountBNB, uint liquidity) = pcsV2Router.addLiquidityETH{value: newBalance} (
            address(this),
            amountOtherHalf,
            0,                        // Slippage is unavoidable
            0,                        // Slippage is unavoidable
            _lpTokenAddress,          // Adress where LP tokens will be sent
            block.timestamp.add(30)   // Deadline set to 30 seconds from now
        );

        _balances[_lpTokenAddress] = _balances[_lpTokenAddress].add(amountOtherHalf);

        // Check there are no errors with the liquidity deposit
        require(liquidity > 0, "Swap: Insufficient liquidity");
        require(amountBNB > 0, "Swap: Insufficient BNB");
        require(amountToken > 0, "Swap: Insufficient tokens");

        emit SwapAndLiquify(newBalance, amountToSwap);
    }

    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer zero address");
        require(recipient != address(0), "BEP20: transfer zero address");
        require(amount > 0, "BEP20: Insufficient amount");

        // Is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // Also, don't get caught in a circular liquidity event.
        // Also, don't swap & liquify if sender is uniswap pair.
        if (_balanceVirtualLiquidity >= liquidityThreshold 
            //&& inSwapAndLiquify == _FALSE
            && sender != pcsV2Pair 
            && swapAndLiquifyEnabled) 
        {
            // Add liquidity
            _swapAndAddToLiquidity(liquidityThreshold);
        }

        // Check if the tokens are being transferred from Pancakeswap or AntiStatic
        if(sender != owner() && sender != pcsV2Pair)
        {
            amount = coordinatedWithdrawal(sender, amount, _balances[sender]);

            _balances[sender] = _balances[sender].sub(amount, "BEP20: Insufficient balance");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);              
        }
        else
        {
            _transferFromDEX(sender, recipient, amount);
        }
    }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint zero address");

    //_totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
/*  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: Insufficient balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }
*/
  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve zero address");
    require(spender != address(0), "BEP20: approve zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}