//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.12;
//Import router interface
import "./IUniswapRouterV02.sol";
//Import SafeMath
import "@openzeppelin/contracts/math/SafeMath.sol";
//Import IERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//Import Ownable
import '@openzeppelin/contracts/access/Ownable.sol';

interface IBasisCashPool {
  function DURATION (  ) external view returns ( uint256 );
  function balanceOf ( address account ) external view returns ( uint256 );
  function basisCash (  ) external view returns ( address );
  function dai (  ) external view returns ( address );
  function deposits ( address ) external view returns ( uint256 );
  function earned ( address account ) external view returns ( uint256 );
  function exit (  ) external;
  function getReward (  ) external;
  function lastTimeRewardApplicable (  ) external view returns ( uint256 );
  function lastUpdateTime (  ) external view returns ( uint256 );
  function notifyRewardAmount ( uint256 reward ) external;
  function owner (  ) external view returns ( address );
  function periodFinish (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function rewardDistribution (  ) external view returns ( address );
  function rewardPerToken (  ) external view returns ( uint256 );
  function rewardPerTokenStored (  ) external view returns ( uint256 );
  function rewardRate (  ) external view returns ( uint256 );
  function rewards ( address ) external view returns ( uint256 );
  function setRewardDistribution ( address _rewardDistribution ) external;
  function stake ( uint256 amount ) external;
  function starttime (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function userRewardPerTokenPaid ( address ) external view returns ( uint256 );
  function withdraw ( uint256 amount ) external;
}
//First init pool contract interfaces
//approve all usd stablecoin to each pool
// deposit in each
// call dumpit to harvest and sell all pool deposit rewards to dai


contract BACFarmer is Ownable{
    uint constant public INF = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    //Pool addresses
    address public DaiPool = 0xEBd12620E29Dc6c452dB7B96E1F190F3Ee02BDE8;
    address public USDTPool = 0x2833bdc5B31269D356BDf92d0fD8f3674E877E44;
    address public USDCPool = 0x51882184b7F9BEEd6Db9c617846140DA1d429fD4;
    address public SUSDPool = 0xDc42a21e38C3b8028b01A6B00D8dBC648f93305C;

    //Asset addresses
    address public BAS  = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;


    //Pool interfaces
    IBasisCashPool iDaiPool = IBasisCashPool(DaiPool);
    IBasisCashPool iUSDTPool = IBasisCashPool(USDTPool);
    IBasisCashPool iUSDCPool = IBasisCashPool(USDCPool);
    IBasisCashPool iSUSDPool = IBasisCashPool(SUSDPool);


    address selfAddr = address(this);

    //Bools for internal shiz
    bool approved = false;
    bool reinvestDAi = false;


    IUniswapV2Router02  public  IUniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    //Whitelisted callers
    mapping (address => bool) public whitelistedExecutors;

    constructor() public {
        whitelistedExecutors[msg.sender] = true;
    }

    modifier onlyWhitelisted(){
        require(whitelistedExecutors[_msgSender()]);
        _;
    }

    function revokeWhitelisted(address addx) public onlyOwner {
        whitelistedExecutors[addx] = false;

    }

    function addWhitelisted(address addx) public onlyOwner {
        whitelistedExecutors[addx] = true;
    }

    function transferOwnership(address newOwner) public onlyOwner override {
        super.transferOwnership(newOwner);
        addWhitelisted(newOwner);
        revokeWhitelisted(msg.sender);
    }

    /* Helper funcs */

    function getTokenBalanceOfAddr(address tokenAddress,address dest) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(dest);
    }
    function getTokenBalance(address tokenAddress) public view returns (uint256){
       return getTokenBalanceOfAddr(tokenAddress,selfAddr);
    }


    function hasTokens(address token) internal view returns (bool) {
        return getTokenBalance(token) > 0;
    }

    function ApproveInf(address token,address spender) internal{
        IERC20(token).approve(spender,INF);
    }

    function ApproveUniRouter(address token) internal{
        ApproveInf(token,address(IUniswapV2Router));
    }

    function doApprovals() public {
        ApproveUniRouter(BAS);
        //Approve tokens for the pools
        ApproveInf(USDT,USDTPool);
        ApproveInf(USDC,USDCPool);
        ApproveInf(DAI,DaiPool);
        ApproveInf(SUSD,SUSDPool);
        approved = true;
    }

    function PullTokenBalance(address token) internal onlyOwner {
        IERC20(token).transferFrom(owner(),selfAddr,getTokenBalanceOfAddr(token,owner()));
    }

    function pullStables() public onlyOwner {
        PullTokenBalance(USDT);
        PullTokenBalance(USDC);
        PullTokenBalance(DAI);
        PullTokenBalance(SUSD);
    }

    function toggleReinvest() public onlyOwner {
        reinvestDAi = !reinvestDAi;
    }

    function depositAll() public onlyOwner {
        //Get balances
        uint256 usdtBal = getTokenBalance(USDT);
        uint256 usdcBal = getTokenBalance(USDC);
        uint256 daiBal = getTokenBalance(DAI);
        uint256 susdBal = getTokenBalance(SUSD);

        //Check balance and deposit
        if(usdtBal > 0)
            iUSDTPool.stake(usdtBal);

        if(usdcBal > 0)
            iUSDCPool.stake(usdcBal);

        if(daiBal > 0)
            iDaiPool.stake(daiBal);

        if(susdBal > 0)
            iSUSDPool.stake(susdBal);
    }

    function withdrawAll() public onlyOwner {
        //Call exit on all pools,which gives collateral and rewards
        iSUSDPool.exit();
        iUSDCPool.exit();
        iDaiPool.exit();
        iUSDTPool.exit();
    }

    function getRewards() public onlyWhitelisted {
        //Get bas rewards
        iSUSDPool.getReward();
        iUSDCPool.getReward();
        iDaiPool.getReward();
        iUSDTPool.getReward();
    }

    function recoverERC20(address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), getTokenBalance(tokenAddress));
    }

    function getPathForTokenToToken(address token1,address token2) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        return path;
    }

    function swapWithPath(address[] memory path) internal{
        uint256 token1Balance = getTokenBalance(path[0]);
        IUniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(token1Balance,0,path,selfAddr,now + 2 hours);
    }

    function swapTokenfortoken(address token1,address token2) internal{
        swapWithPath(getPathForTokenToToken(token1,token2));
    }

    function takeProfits() public onlyWhitelisted {
        getRewards();
        if(getTokenBalance(BAS) > 0)
            swapTokenfortoken(BAS,DAI);
        uint256 daiBal = getTokenBalance(DAI);
        if(reinvestDAi && daiBal > 0) {
            //ReInvest DAI back in pool
            iDaiPool.stake(daiBal);
        }
    }

    function withdrawStables() public onlyOwner {
        withdrawAll();
        //Sell profits to dai
        if(getTokenBalance(BAS) > 0) {
            swapTokenfortoken(BAS,DAI);
        }
        //Get balances
        uint256 usdtBal = getTokenBalance(USDT);
        uint256 usdcBal = getTokenBalance(USDC);
        uint256 daiBal = getTokenBalance(DAI);
        uint256 susdBal = getTokenBalance(SUSD);
        //Withdraw the stables from contract
        if(usdtBal > 0)
            recoverERC20(USDT);
        if(usdcBal > 0)
            recoverERC20(USDC);
        if(daiBal > 0)
            recoverERC20(DAI);
        if(susdBal > 0)
            recoverERC20(SUSD);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}