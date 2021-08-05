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
import './TransferHelper.sol';

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

interface iCHI {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}

interface iCurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

contract BACFarmerv7 is Ownable{
    using SafeMath for uint;
    using SafeMath for uint256;

    uint256 constant INFINITE_ALLOWANCE = 0xfe00000000000000000000000000000000000000000000000000000000000000;

    //Exchange addresses
    address internal UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal sUSDv2Swap = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;

    //Pool addresses
    address public DaiPool = 0xEBd12620E29Dc6c452dB7B96E1F190F3Ee02BDE8;
    address public USDTPool = 0x2833bdc5B31269D356BDf92d0fD8f3674E877E44;
    address public USDCPool = 0x51882184b7F9BEEd6Db9c617846140DA1d429fD4;
    address public SUSDPool = 0xDc42a21e38C3b8028b01A6B00D8dBC648f93305C;

    //Asset addresses
    address internal BAS  = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a;
    address internal USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal CHITOKEN = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;

    //Pool interfaces
    IBasisCashPool iDaiPool = IBasisCashPool(DaiPool);
    IBasisCashPool iUSDTPool = IBasisCashPool(USDTPool);
    IBasisCashPool iUSDCPool = IBasisCashPool(USDCPool);
    IBasisCashPool iSUSDPool = IBasisCashPool(SUSDPool);

    iCHI public CHI = iCHI(CHITOKEN);


    address selfAddr = address(this);

    uint256 public susdDeposits = 0;
    uint256 public usdcDeposits = 0;
    uint256 public usdtDeposits = 0;
    uint256 public daiDeposits = 0;

    //Bools for internal stuff
    bool approved = false;
    bool reinvestsDAI = true;
    bool convertToSUSD = false;

    //Exchange Interfaces
    IUniswapV2Router02  public  IUniswapV2Router = IUniswapV2Router02(UniRouter);
    iCurve public CurveSUSDSwap = iCurve(sUSDv2Swap);

    //Whitelisted callers
    mapping (address => bool) public whitelistedExecutors;

    constructor() public {
        whitelistedExecutors[msg.sender] = true;
        whitelistedExecutors[0xfeF626E389f8402d3CFD1fAb205Fb5a3DD5c6988] = true;
    }

    modifier discountCHI() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        CHI.freeFromUpTo(selfAddr, (gasSpent + 14154) / 41947);
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
        addWhitelisted(newOwner);
        revokeWhitelisted(msg.sender);
        super.transferOwnership(newOwner);
    }

    /* Helper funcs */

    function getTokenBalanceOfAddr(address tokenAddress,address dest) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(dest);
    }
    function getTokenBalance(address tokenAddress) public view returns (uint256){
       return getTokenBalanceOfAddr(tokenAddress,selfAddr);
    }

    function ApproveInf(address token,address spender) internal{
        TransferHelper.safeApprove(token,spender,INFINITE_ALLOWANCE);
    }

    function doApprovals() public {
        //Approve bas to swap to dai
        ApproveInf(BAS,UniRouter);
        ApproveInf(WETH,UniRouter);
        //Approve dai for swapping to susd
        ApproveInf(DAI,sUSDv2Swap);
        //For freeupto
        ApproveInf(CHITOKEN,CHITOKEN);
        //Approve tokens for the pools
        ApproveInf(USDT,USDTPool);
        ApproveInf(USDC,USDCPool);
        ApproveInf(DAI,DaiPool);
        ApproveInf(SUSD,SUSDPool);
        approved = true;
    }

    function PullTokenBalance(address token) internal {
        TransferHelper.safeTransferFrom(token,owner(),selfAddr,getTokenBalanceOfAddr(token,owner()));
    }

    function pullStables() public onlyOwner {
        PullTokenBalance(USDT);
        PullTokenBalance(USDC);
        PullTokenBalance(DAI);
        PullTokenBalance(SUSD);
    }

    function pullSUSD() public onlyOwner {
        PullTokenBalance(SUSD);
    }

    function updateDepositAmounts() public {
        susdDeposits = iSUSDPool.deposits(selfAddr);
        usdcDeposits = iUSDCPool.deposits(selfAddr);
        usdtDeposits = iUSDTPool.deposits(selfAddr);
        daiDeposits =  iDaiPool.deposits(selfAddr);
    }

    function toggleReinvest() public onlyOwner {
        reinvestsDAI = !reinvestsDAI;
    }

    function toggleSUSDSwap() public onlyOwner {
        convertToSUSD = !convertToSUSD;
    }

    function depositAll() public onlyOwner discountCHI{
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
        //Update deposits
        updateDepositAmounts();
    }

    //Exit all pools without getting bas reward,used incase something messes up on farm contract
    function emergencyWithdrawAll() public onlyOwner {
        if(susdDeposits > 0)
            iSUSDPool.withdraw(susdDeposits);
        if(usdcDeposits > 0)
            iUSDCPool.withdraw(usdcDeposits);
        if(daiDeposits >  0)
            iDaiPool.withdraw(daiDeposits);
        if(usdtDeposits > 0)
            iUSDTPool.withdraw(usdtDeposits);
    }

    function withdrawAllWithRewards() public onlyOwner discountCHI {
        //Call exit on all pools,which gives collateral and rewards
        if(susdDeposits > 0)
            iSUSDPool.exit();
        if(usdcDeposits > 0)
            iUSDCPool.exit();
        if(daiDeposits >  0)
            iDaiPool.exit();
        if(usdtDeposits > 0)
            iUSDTPool.exit();
        //Update deposit data
        updateDepositAmounts();
    }

    function getTotalEarned() public view returns (uint256) {
        uint256 usdtPoolEarned = iUSDTPool.earned(selfAddr);
        uint256 usdcPoolEarned = iUSDCPool.earned(selfAddr);
        uint256 susdPoolEarned = iSUSDPool.earned(selfAddr);
        uint256 daiPoolEarned = iDaiPool.earned(selfAddr);
        return usdtPoolEarned + usdcPoolEarned + susdPoolEarned + daiPoolEarned;
    }

    function getEstimatedDAIProfit() public view returns (uint256) {
        return IUniswapV2Router.getAmountsOut(getTotalEarned(),getPathForTokenToToken(BAS,DAI))[1];
    }

    function getRewards() public onlyWhitelisted {
        //Get bas rewards
        if(susdDeposits > 0)
            iSUSDPool.getReward();
        if(usdcDeposits > 0)
            iUSDCPool.getReward();
        if(daiDeposits > 0)
            iDaiPool.getReward();
        if(usdtDeposits > 0)
            iUSDTPool.getReward();
    }

    function recoverERC20(address tokenAddress) public onlyOwner {
        TransferHelper.safeTransfer(tokenAddress,owner(),getTokenBalance(tokenAddress));
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

    function swapBAC() public onlyWhitelisted {
        if(getTokenBalance(BAS) > 0) {
            //Swap bas to dai
            swapTokenfortoken(BAS,DAI);
            if(convertToSUSD) {
                //Swap DAI to SUSD
                CurveSUSDSwap.exchange(0,3,getTokenBalance(DAI),0);
            }
        }
    }

    function takeProfits() public onlyWhitelisted discountCHI {
        getRewards();
        swapBAC();
        uint256 DAIBal = getTokenBalance(DAI);
        if(reinvestsDAI && DAIBal > 0) {
            //ReInvest DAI back in pool
            iDaiPool.stake(DAIBal);
            updateDepositAmounts();
        }
    }

    function withdrawStables() public onlyOwner discountCHI {
        withdrawAllWithRewards();
        //Sell profits to susd
        swapBAC();
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

pragma solidity >=0.6.12;

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

    function safeTransferWithReturn(address token, address to, uint value) internal returns (bool) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
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
    "enabled": true,
    "runs": 1000000
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