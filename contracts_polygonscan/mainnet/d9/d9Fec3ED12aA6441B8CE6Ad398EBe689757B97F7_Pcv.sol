/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

pragma solidity ^0.6.6;


interface IPcv {

    function getFeeRate()  external view returns(uint256,uint256);

    function execute(address sender,address recipient,uint256 amount) external returns(uint256);

    function getTotalFee() external view returns(uint256);

}

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

interface IDp is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function decimals() external view returns (uint8);

}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

library SafeMathCopy { // To avoid namespace collision between openzeppelin safemath and dpswap safemath
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

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface IDpswapV2Pair {
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

interface IDpswapV2Factory {
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

interface IDpswapV2Router01 {
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


interface IDpswapV2Router02 is IDpswapV2Router01 {
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

interface OtherToken{

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}



interface LendErc20 {
    // Deposit ,requires token authorization
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);

}

interface LendComptroller{
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
    /**
     * PIGGY-MODIFY:
     * @notice Add assets to be included in account liquidity calculation
     * @param pTokens List of cToken market addresses to be activated
     * @return Whether to enter each corresponding market success indicator
     */
    function enterMarkets(address[] calldata pTokens) external returns (uint[] memory);


    function exitMarket(address pTokenAddress) external returns (uint);

    // Query available loan (whether it is normal 0: normal, remaining loanable amount, loan asset premium)
    function getAccountLiquidity(address account) external view returns (uint, uint, uint) ;
}

interface IdpBox {

    //Pledge poolName Pledge days
    function depositToken(uint32 _poolName, uint256  _amount) external;

    // Get order
    function orderIdsArr(address _addr)external view returns(uint256[] memory);

    //The user receives the minting revenue poolName: the number of days of the order type, orderIds: the order number
    function receiveToken(uint256[] calldata _orderIds, bool _isReceiveInvite) external;

    // Get the best single pledge amount, if you need to pledge a large amount, divide it into multiple pledges
    function getBestAmount() external view returns(uint256, uint256, uint256, uint256);

    // Get the order details and return the array value[8] != 0 means the pledge order has been redeemed
    function orderValues(uint256 _orderId) external view returns(uint256[] memory);
}


contract Pcv is IPcv,Context,IERC721Receiver{
    using SafeMathCopy for uint256;
    IDpswapV2Pair public dpswapV2Pair;
    IDpswapV2Router02 public dpswapV2Router;
    address public _core;

    uint256 public _taxFee = 50; // Handling fee rate per thousand
    uint256 public _liquidityFee = 50; // Liquidity rate per thousand
    uint256 public _feeRateDecimal = 1000;

    uint256 public _totalTaxFee; // Total fee
    uint256 public _totalLiquidity; //Total liquidity fee
    bool inSwapAndLiquify; // Lock in liquidity
    bool public autoAddLiquifyEnabled = false; // Automatically add liquidity

    uint256 public numTokensSellToAddToLiquidity; // The amount that can trigger the automatic addition of liquidity

    IDp public _dp;
    address public _owner;
    OtherToken _baseToken; //Denominated currency

    IDpswapV2Pair public dpVsdpPair; // Trading pair

    LendErc20 public lend;
    LendComptroller public lendComptroller;
    IdpBox public box;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // Optimal pledge amount
    mapping(uint32 => uint256) pledgeCycleAmount;

    constructor(address router,address pair,address core,address dp,address otherToken ) public {
        _core = core;
        dpswapV2Pair = IDpswapV2Pair(pair);
        dpswapV2Router = IDpswapV2Router02(router);
        _dp = IDp(dp);
        _owner = _msgSender();
        _baseToken = OtherToken(otherToken);
    }

    function getFeeRate() view external override returns(uint256,uint256){
        return (_taxFee,_liquidityFee);
    }

    // @return (Handling fee, liquidity fee, latest amount)
    function execute(address sender,address recipient,uint256 amount) external override  returns(uint256) {
        require(msg.sender == _core, "Pcv : caller is not core contract ");

        if(amount < 0 ){
            return (amount);
        }

        if(sender == address(dpswapV2Router) || recipient == address(dpswapV2Router)){
            return amount;
        }

        if(autoAddLiquifyEnabled){
            addLiquidityAuto(sender);
        }

        uint256 fee = amount.mul(_taxFee).div(_feeRateDecimal);
        uint256 liqFee = amount.mul(_liquidityFee).div(_feeRateDecimal);
        _totalTaxFee += fee;
        _totalLiquidity += liqFee;

        _dp.burnFrom(sender,fee+liqFee);
        _dp.mint(address(this),liqFee);
        uint256 newAmount = amount.sub(fee).sub(liqFee);

        return newAmount;
    }

    function addLiquidity(uint256 addLpAmount) external onlyOwner {
        uint256 contractTokenBalance = _dp.balanceOf(address(this));
        require(contractTokenBalance >= addLpAmount,"PCV: not enough banlance");

        if (!inSwapAndLiquify ) { // 没有锁定流动性池
            //添加流动性
            swapAndLiquify(addLpAmount);
        }
    }

    function removeLiquidityByPcv(uint removeLiquidity) external onlyOwner {
        dpswapV2Pair.approve(address(dpswapV2Router),removeLiquidity);
        uint256 oldBalance = _baseToken.balanceOf(address(this));

        dpswapV2Router.removeLiquidity(
            address(_dp),
            address(_baseToken),
            removeLiquidity,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 getBaseToken = _baseToken.balanceOf(address(this)).sub(oldBalance);
        _baseToken.approve(address(dpswapV2Router),getBaseToken);
        swapTokensForOtherToken(address(_baseToken),address(_dp),getBaseToken);

    }

    function addLiquidityAuto(address sender) internal {

        uint256 contractTokenBalance = _dp.balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != address(dpswapV2Pair)
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
    }

    function swapAndLiquify(uint256 addLpAmount) private lockTheSwap {

        uint256 half = addLpAmount.div(2);
        uint256 otherHalf = addLpAmount.sub(half);

        uint256 initialBalance = _baseToken.balanceOf(address(this));

        require(half > 0,"pav : not enough dp to swap eth");

        swapTokensForOtherToken(address(_dp),address(_baseToken),half); // 兑换usdt

        uint256 newBalance = _baseToken.balanceOf(address(this)).sub(initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        require(tokenAmount > 0 ,"pav: tokenAmount to swap eth is 0");
        // generate the dpswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(_dp);
        path[1] = dpswapV2Router.WETH();

        _dp.approve( address(dpswapV2Router), tokenAmount);

        // make the swap
        dpswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    // dp exchange usdt
    function swapTokensForOtherToken(address tokenIn,address tokenOut,uint256 amountIn) private {
        require(amountIn > 0 ,"Pcv: dpAmount to swap other token is 0");
        // generate the dpswap pair path of token -> usdt
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);

        _dp.approve( address(dpswapV2Router), amountIn);

        // make the swap
        dpswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function _addLiquidity(uint256 tokenAmount, uint256 otherAmount) private {
        // approve token transfer to cover all possible scenarios
        _dp.approve(address(dpswapV2Router), tokenAmount);
        _baseToken.approve(address(dpswapV2Router), otherAmount);

        // Add liquidity
        dpswapV2Router.addLiquidity(
            address(_dp),
            address(_baseToken),
            tokenAmount,
            otherAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp );
    }


    function addLiquidityEth(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _dp.approve(address(dpswapV2Router), tokenAmount);

        // Add liquidity
        dpswapV2Router.addLiquidityETH{value: ethAmount}(
            address(_dp),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

    }

    function setTaxFeeRate(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeeRate(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setNumTokensSellToAddToLiquidity(uint256 swapNumber) public onlyOwner {
        numTokensSellToAddToLiquidity = swapNumber;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        autoAddLiquifyEnabled = _enabled;
    }

    function getTotalFee() external view override returns(uint256){
        return _totalTaxFee;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    event addLiquidityEvent(uint256 dpAmount,uint256 otherTokenAmount);
    event SwapAndLiquify(uint256 half, uint256 newBalance, uint256 otherHalf);

    function changeOwner(address newOwner) external onlyOwner{
        require(address(newOwner) != address(0),"new owner can not be null");
        _owner = newOwner;
    }

    // Set the accuracy of the commission rate, 100 means percentile 1000 means thousandth...
    function setFeeRateDecimal(uint256 _decimals) external onlyOwner{
        _feeRateDecimal = _decimals;
    }

    function setLendContract(address lendContract) external onlyOwner{
        lend = LendErc20(lendContract);
    }

    function setLendComptroller(address comptrollerContract) external onlyOwner{
        lendComptroller = LendComptroller(comptrollerContract);
    }

    function lendDeposit(uint256 depositAmount)  external returns (uint256){
        bool res = _dp.approve(address(lend),depositAmount);
        require(res,"token approve is fail");
        lend.mint(depositAmount);
    }
    function lendWithdraw(uint256 withdrawAmount)  external returns (uint256){
        lend.redeem(withdrawAmount);
    }
    function lendLoan(uint256 loanAmount)  external returns (uint256){
        lend.borrow(loanAmount);
    }
    function LendRepay(uint256 repayAmount)  external returns (uint256){
        _dp.approve(address(lend),repayAmount);
        lend.repayBorrow(repayAmount);
    }
    function lendGetAvailableLoan() external view returns (uint256){
        (,uint256 vailableLoan,) =  lendComptroller.getAccountLiquidity(address(this));
        return vailableLoan;
    }


    function openLend() external onlyOwner returns(uint[] memory){
        address[] memory pTokens = new address[](1);
        pTokens[0] = address(lend);
        uint[] memory res =  lendComptroller.enterMarkets(pTokens);
        emit openLendEvent(res[0]);
        require(res[0] == 0,"openLend operation is fail");

    }

    event openLendEvent(uint);
    event closeLendEvent(uint);

    function closeLend() external onlyOwner returns(uint){
        uint res = lendComptroller.exitMarket(address(lend));
        emit closeLendEvent(res);
        require(res == 0,"closeLend is fail");
    }

    function setBoxContract(address boxAddr) external onlyOwner{
        box = IdpBox(boxAddr);
    }

    function boxDeposit(uint32  pledgeCycle, bool useBestAmount,uint256 amount) external onlyOwner {
        uint256 depositAmount;
        if(useBestAmount){
            depositAmount = boxGetBestAmount(pledgeCycle);
            require(depositAmount >0,"no have best amount");
        }else{
            depositAmount = amount;
        }
        uint256 balance = _dp.balanceOf(address(this));
        require(balance > depositAmount,"not enought balance to deposit");

        _dp.approve(address(box),depositAmount);
        box.depositToken(pledgeCycle,depositAmount);
    }

    function boxGetBestAmount(uint32 pledgeCycle) internal  returns(uint256){
        (uint256 bestOf7, uint256 bestOf30, uint256 bestOf90, uint256 bestOf180) = box.getBestAmount();
        pledgeCycleAmount[7] = bestOf7;
        pledgeCycleAmount[30] = bestOf30;
        pledgeCycleAmount[90] = bestOf90;
        pledgeCycleAmount[180] = bestOf180;

        return pledgeCycleAmount[pledgeCycle];
    }

    function boxWithdraw() external onlyOwner{
        uint256 [] memory orderIds = box.orderIdsArr(address(this));
        uint256 orderCount = orderIds.length;
        require(orderCount > 0,"any order to take back");

        uint256 [] memory orderValues;
        uint256 [] memory takeBackOrderIds = new uint256 [](orderCount);

        uint count = 0;
        for(uint i =0;i<orderIds.length;i++){
            orderValues = new uint256 [](1);
            orderValues =  box.orderValues(orderIds[i]);
            if(orderValues[8] == 0){
                takeBackOrderIds[count] = orderIds[i];
                count++;
            }
        }
        require(count > 0 ,"any order to take back");
        
        uint256 [] memory receiveOrderIds = new uint256 [](count);
        for(uint j = 0; j < count; j++){
            receiveOrderIds[j] = takeBackOrderIds[j];
        }
        emit boxWithdrawLog(receiveOrderIds);
        box.receiveToken(receiveOrderIds,true);
    }
    event boxWithdrawLog(uint256 [] orders);

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return _ERC721_RECEIVED;
    }

    function lendAmount(address account) external virtual view returns (uint256 status, uint256 deposit, uint256 loan, uint256 exchangeRate){
        (status,deposit,loan,exchangeRate) = lend.getAccountSnapshot(address(this));
        return   (status,deposit,loan,exchangeRate) ;
    }

    function setRouter(address router) external onlyOwner{
        require(router != address(0),"can not be zero address");
        dpswapV2Router = IDpswapV2Router02(router);
    }

    function setCore(address core) external onlyOwner{
        require(core != address(0),"can not be zero address");
        _core = core;
    }

    function setDpPair(address dpToken,address otherToken, address pair) external onlyOwner{
        require(dpToken != address(0),"can not be zero address");
        require(otherToken != address(0),"can not be zero address");
        require(pair != address(0),"can not be zero address");

        dpswapV2Pair = IDpswapV2Pair(pair);
        _dp = IDp(dpToken);
        _baseToken = OtherToken(otherToken);
    }
}