/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT
// File: antihoneypot/interfaces/IUniswapRouter.sol



pragma solidity >=0.6.12;

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}
// File: antihoneypot/interfaces/IWETH.sol



pragma solidity >=0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
// File: antihoneypot/interfaces/IUniswapV2Pair.sol



pragma solidity >=0.6.12;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}
// File: antihoneypot/libraries/UniswapV2Library.sol



pragma solidity >=0.6.12;



library UniswapV2Library{
    using SafeMath for uint;

    /* Uniswap code */
    function _swap(address UnifactoryAddr,uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pairFor(UnifactoryAddr, output, path[i + 2]) : _to;
            IUniswapV2Pair(pairFor(UnifactoryAddr, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
            ))));
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    /*End uniswap code */

}
// File: antihoneypot/IERC20.sol



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


// File: antihoneypot/libraries/TransferHelper.sol



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
// File: antihoneypot/libraries/SafeMath.sol



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
// File: antihoneypot/Context.sol



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
// File: antihoneypot/libraries/Ownable.sol



pragma solidity ^0.6.0;

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
// File: antihoneypot/GetBackETHHelper.sol



pragma solidity >=0.6.12;

// Import OpenZepplin libs


// Import custom libs




// Import interfaces



contract GetBackEthHelperV3 is Ownable{

    using SafeMath for uint;
    using SafeMath for uint256;

    //Constants for direct uniswap pair swap
    address internal UniRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapRouter router = IUniswapRouter(UniRouter);
    address internal Unifactory = router.factory();

    address internal WETH = router.WETH();

    //Queue data
    address public addr = address(0);
    uint public time = 0;
    address public tokenQueued = address(0);
    address public tokenSwapTo = address(0);//Used to swap to custom pairs,for example USDC instead of TOKEN-ETH
    uint256 public QueueDelay = 200;//In seconds,200 seconds initially to avoid frontrunning
    uint256 public totalTries = 0;//Get total times queue has been called
    address internal selfAddr = address(this);

    //Fee data
    address public feeGetter = msg.sender;//Deployer is the feeGetter be default
    //Fee token data
    address public FeeDiscountToken = address(0);//Set to 0x0 addr by default
    uint256 public FeeTokenBalanceNeeded = 0; //Number of tokens in wei to hold for fee discount
    //Fee discount ratio
    uint256 public FeeDiscountRatio = 5000;//50% fee discount on holding required amount of tokens,can be changed by admin

    /// @notice Service fee at 20 % initially
    uint public FEE = 1100;
    uint constant public BASE = 10000;

    //Stats data
    uint256 public totalETHSwapped = 0;
    uint256 public totalETHFees = 0;

    address[] internal users;
    address[] internal tokens;

    //Mapping data for various stats
    mapping (address => uint256) public addrSwapStats;//Amount of eth swapped by any amount of addresses
    mapping (address => bool) public tokenSwappedSuccess;
    mapping (address => bool) public tokenTried;//token has been tried to swap
    mapping (address => bool) public tokenHasBurn;
    //Whitelisted callers
    mapping (address => bool) public whitelistedExecutors;

    //Events
    event TokenQueued(address indexed from, address indexed token, uint256 indexed time);
    event TokenSwapped(address from, address indexed to, address indexed token,uint256 timeExecuted, address tokenBPair);
    event TokenFailedToSwap(address indexed token);
    event QueueCleared(address indexed caller);
    event ServiceFeeChanged(uint256 indexed newFee);
    event FeeGetterChanged(address indexed newFeeGetter);
    event DiscountTokenChanged(address indexed token);
    event DiscountTokenBalanceChanged(uint256 requiredNew);
    event DiscountTokenRatioChanged(uint256 newRatio);
    event AddedWhitelistAddr(address addrn);
    event RevokedWhitelistAddr(address addrn);

    constructor() public {
        whitelistedExecutors[msg.sender] = true;
    }

    modifier OnlyWhitelisted(){
        require(whitelistedExecutors[_msgSender()]);
        _;
    }
          function getTokenBalance(address tokenAddress) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(address(this));
      }
    
      function getTokenBalanceOfAddr(address tokenAddress,address user) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(user);
      }
    
      function recoverERC20(address tokenAddress,address receiver) internal {
        IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
      }

    /* queue related funcs */
    function queue(address tokentoQueue, address tokenToSwapTo) external {
        require(isQueueEmpty(), "Queue Full");
        addr = msg.sender;
        time = block.timestamp + QueueDelay;
        tokenQueued = tokentoQueue;
        tokenSwapTo = tokenToSwapTo;
        totalTries++;
        emit TokenQueued(addr,tokenQueued,block.timestamp);
    }

    function checkPerm(address sender,uint timex,address token,address _tokenToSwapTo) public view returns (bool){
        return (sender == addr &&
        timex <= time  &&
        token == tokenQueued &&
        tokenSwapTo == _tokenToSwapTo &&
        (getTokenBalance(token) > 0))
        || whitelistedExecutors[sender];
    }

    function clearQueue() internal{
        time = 0;
        addr = address(0);
        tokenQueued = addr;
    }
    /* End queue funcs */

    /* Admin only functions */

    function recoverTokens(address token) external {
        require(msg.sender == owner() || msg.sender == addr);
        recoverERC20(token,msg.sender);
    }

    function clearQueueFromOwner() external OnlyWhitelisted{
        clearQueue();
        emit QueueCleared(msg.sender);
    }

    function setServicefee(uint256 fee) public onlyOwner {
        FEE = fee;
        emit ServiceFeeChanged(fee);
    }

    function setFeeGetter(address newFeeGetter) public onlyOwner{
        feeGetter = newFeeGetter;
        emit FeeGetterChanged(newFeeGetter);
    }

    function setQueueDelay(uint256 newDelay) public onlyOwner{
        QueueDelay = newDelay;
    }

    function setFeeDiscountToken(address token) public onlyOwner{
        FeeDiscountToken = token;
        emit DiscountTokenChanged(token);
    }

    function setTokensForFeeDiscount(uint256 tokenAmt) public onlyOwner{
        FeeTokenBalanceNeeded = tokenAmt;
        emit DiscountTokenBalanceChanged(tokenAmt);
    }

    function setFeeDiscountRatio(uint256 ratio) public onlyOwner {
        FeeDiscountRatio = ratio;
        emit DiscountTokenRatioChanged(ratio);
    }

    function revokeWhitelisted(address addx) public onlyOwner {
        whitelistedExecutors[addx] = false;
        emit RevokedWhitelistAddr(addx);

    }

    function addWhitelisted(address addx) public onlyOwner {
        whitelistedExecutors[addx] = true;
        emit AddedWhitelistAddr(addx);
    }

    function transferOwnership(address newOwner) public onlyOwner override {
        super.transferOwnership(newOwner);
        addWhitelisted(newOwner);
        revokeWhitelisted(msg.sender);
    }

    /* End admin only functions */

    /*Getter functions */

    function IsEligibleForFeeDiscount(address user) public view returns (bool){
        return FeeDiscountToken != address(0) &&
               getTokenBalanceOfAddr(FeeDiscountToken,user) >= FeeTokenBalanceNeeded;
    }

    function getSendAfterFee(uint256 amount,address user,uint256 fee) public view returns (uint256 amt){
        //Check if user is eligible for fee discount,if so divide it by feediscountratio ,otherwise use set fee
        uint256 internalfee = IsEligibleForFeeDiscount(user) ? fee.mul(FeeDiscountRatio).div(BASE) : fee;
        amt = amount.sub(internalfee);
    }

    function isQueueEmpty() public view returns (bool){
        return addr == address(0) || block.timestamp >= time;
    }

    function isAwaitingSwap() public view returns (bool) {
        return tokenQueued != address(0) && getTokenBalance(tokenQueued) > 0;
    }

    function shouldClearQueue() public view returns (bool) {
        return isQueueEmpty() && tokenQueued != address(0) && !isAwaitingSwap();
    }

    function getTimeLeftToTimeout() public view returns (uint256){
        if(now > time && time != 0)
            return now - time;
        return 0;
    }

    function getWETHBalance() public view returns (uint256){
        return getTokenBalance(WETH);
    }

    /**
     * @notice Full listing of all tokens queued
     * @return array blob
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @notice Full listing of all users
     * @return array blob
     */
    function getUsers() external view returns (address[] memory) {
        return users;
    }
    /* End Queue related functions */

    /* main swap code */
    receive() external payable {
        if(msg.sender != WETH && msg.sender != UniRouter){
            //Refund eth if user deposits eth
            (bool refundSuccess,)  = payable(msg.sender).call{value:selfAddr.balance}("");
            require(refundSuccess,"Refund of eth failed");
        }
    }

    function swapToETH(address tokenx) external returns (uint[] memory amounts) {
        require(checkPerm(msg.sender,block.timestamp,tokenx,WETH), "Unauthourized call");
        amounts = _swapToETH(msg.sender,tokenx,WETH);
    }

    function swapQueuedToken() public returns (uint[] memory amounts){
        require(checkPerm(msg.sender,block.timestamp,tokenQueued,tokenSwapTo), "Unauthourized call");
        amounts = _swapToETH(addr,tokenQueued,tokenSwapTo);
    }

    function _swapToETH(address destination,address tokentoSwap,address _tokenSwapTo) internal returns (uint[] memory amounts)  {
        bool toETH = _tokenSwapTo == WETH;
        address[] memory path = new address[](2);
        path[0] = tokentoSwap;
        path[1] = _tokenSwapTo;
        address UniPair = UniswapV2Library.pairFor(Unifactory, path[0], path[1]);

        uint256 balTokenBeforeSend =  getTokenBalance(path[0]);
        uint256 balTokensOnPairBeforeSend = getTokenBalanceOfAddr(path[0],UniPair);

        amounts = UniswapV2Library.getAmountsOut(Unifactory, balTokenBeforeSend, path);
        bool successTx = TransferHelper.safeTransferWithReturn(path[0], UniPair, amounts[0]);
        if(successTx) {
            //Execute swap steps if it transfered to pair successfully
            uint256 balTokensOnPairAfterSend = getTokenBalanceOfAddr(path[0],UniPair);
            uint256 balDiff = balTokensOnPairAfterSend.sub(balTokensOnPairBeforeSend);
            //Handle burn tokens this way on swap
            if(balDiff != balTokenBeforeSend){
                tokenHasBurn[tokentoSwap] = true;
                amounts = UniswapV2Library.getAmountsOut(Unifactory, balDiff, path);//Update amounts since burn happened on transfer
            }
            //This means we were able to send tokens,so swap and send weth respectively
            UniswapV2Library._swap(Unifactory,amounts, path, selfAddr);
            if(!toETH) {
                //We got tokens other than eth as return token,swap it to ETH
                //Create pair path
                address[] memory pathETH = new address[](2);
                path[0] = _tokenSwapTo;
                path[1] = WETH;
                //Get and approve token balance to router
                uint256 tokenBal = getTokenBalance(_tokenSwapTo);
                TransferHelper.safeApprove(_tokenSwapTo, UniRouter, tokenBal);
                //Get output amounts
                uint[] memory amountsToETH = UniswapV2Library.getAmountsOut(Unifactory, tokenBal, pathETH);//Update amounts since burn happened on transfer
                router.swapExactTokensForETH(
                    amountsToETH[0],
                    amountsToETH[1],
                    pathETH,
                    address(this),
                    block.timestamp
                );
            }
            //update global stats
            totalETHSwapped = totalETHSwapped.add(getWETHBalance());
            //Check if user is already recorded,if not add it to users array
            if(addrSwapStats[destination] == 0){
                users.push(destination);
            }
            //Update user swapped eth
            addrSwapStats[destination] = addrSwapStats[destination].add(getWETHBalance());

            if(toETH){
                //Withdraw eth from weth contract
                IWETH(WETH).withdraw(getWETHBalance());
            }
            else {
                //We swapped the resulting pair token to ETH via router,so update the amount of eth we got
                amounts[1] = address(this).balance;
            }

            //Send eth after withdrawing from weth contract
            sendETHAfterSwap(destination);

            //Mark token was successfully swapped
            tokenSwappedSuccess[tokentoSwap] = true;
            //Emit event
            emit TokenSwapped(msg.sender,destination,tokentoSwap,block.timestamp,_tokenSwapTo);
        }
        else {
            //Send back the tokens if we cant send it to the pair address
            recoverERC20(tokentoSwap,destination);
            //Mark token as unsuccessfully swapped
            tokenSwappedSuccess[tokentoSwap] = false;
            emit TokenFailedToSwap(tokentoSwap);
        }

        if(!tokenTried[tokentoSwap]){
            tokenTried[tokentoSwap] = true;
            //Add it to tokens
            tokens.push(tokentoSwap);
        }

        //Clear Queue at the end
        clearQueue();

        //Return amounts
        return amounts;
    }

    function sendETHAfterSwap(address sender) internal {
        uint _fee = selfAddr.balance.mul(FEE).div(BASE);
        //Send user eth after fees are subtracted
        (bool successUserTransfer,) = payable(sender).call{value:getSendAfterFee(selfAddr.balance,sender,_fee)}("");//80% of funds go back to user,depending on set fee
        //Check send was successful
        require(successUserTransfer,"ETH Transfer failed to user");
        totalETHFees = totalETHFees.add(selfAddr.balance);
        (bool successFeeTransfer,) =  payable(feeGetter).call{value:selfAddr.balance}("");//20% fee for service provider
        //Check send was successful
        require(successFeeTransfer,"ETH Transfer failed to feeGetter");
    }
}