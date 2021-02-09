/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// SPDX-License-Identifier: unlicensed

pragma solidity ^0.5.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value); 
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { 
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account) internal pure returns (address payable){
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success,"Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom( IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn( token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance( IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn( token, abi.encodeWithSelector( token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance( IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value,"SafeERC20: decreased allowance below zero");
        callOptionalReturn( token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // solhint-disable-next-line max-line-length
            require( abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor() internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

contract Context {
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor() internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require( newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);    
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function quote( uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn( uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

interface IUniswapV2Pair {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function getReserves() external view returns ( uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function totalSupply() external view returns (uint256);
}

interface Iuniswap {
    function tokenToTokenTransferInput(    // converting ERC20 to ERC20 and transfer
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256 eth_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256 tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256 tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

interface IBFactory {
    function isBPool(address b) external view returns (bool);
}

interface IBPool {
    function joinswapExternAmountIn(address tokenIn, uint256 tokenAmountIn, uint256 minPoolAmountOut) external payable returns (uint256 poolAmountOut);
    function isBound(address t) external view returns (bool);
    function getFinalTokens() external view returns (address[] memory tokens);
    function totalSupply() external view returns (uint256);
    function getDenormalizedWeight(address token) external view returns (uint256);
    function getTotalDenormalizedWeight() external view returns (uint256);
    function getSwapFee() external view returns (uint256);
    function getBalance(address token) external view returns (uint256);
    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);
}

interface IBPool_Balancer_RemoveLiquidity_V1_1 {
    function exitswapPoolAmountIn(address tokenOut, uint256 poolAmountIn, uint256 minAmountOut) external payable returns (uint256 tokenAmountOut);
    function totalSupply() external view returns (uint256);
    function getFinalTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token)external view returns (uint256);
    function getTotalDenormalizedWeight() external view returns (uint256);
    function getSwapFee() external view returns (uint256);
    function isBound(address t) external view returns (bool);
    function getBalance(address token) external view returns (uint256);
    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),  "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"TransferHelper: TRANSFER_FAILED"); 
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }
}

interface ICurveRegistry {
    function metaPools(address tokenAddress) external view returns (address swapAddress);
    function getTokenAddress(address swapAddress) external view returns (address tokenAddress);
    function getPoolTokens(address swapAddress) external view returns (address[4] memory poolTokens);
    function isMetaPool(address swapAddress) external view returns (bool);
    function getNumTokens(address swapAddress) external view returns (uint8 numTokens);
    function isBtcPool(address swapAddress) external view returns (bool);
    function isUnderlyingToken( address swapAddress, address tokenContractAddress) external view returns (bool, uint8);
    function getIntermediateStableWithdraw(address swapAddress) external view returns (uint8 stableIndex, address stableAddress);  
}

interface yERC20 {
    function deposit(uint256 _amount) external;
}

interface ICurveSwap {
    function coins(int128 arg0) external view returns (address);
    function coins(uint256 arg0) external view returns (address);
    function balances(int128 arg0) external view returns (uint256);
    function balances(uint256 arg0) external view returns (uint256);
    function underlying_coins(int128 arg0) external view returns (address);
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
}

contract UniswapV2RemoveLiquidity is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    bool public stopped = false;
    uint16 public goodwill = 0;

    address public goodwillAddress              = address(0);
    uint256 private constant deadline           = 0xf000000000000000000000000000000000000000000000000000000000000000;
    address private constant wethTokenAddress   = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    IUniswapV2Router02 private constant uniswapV2Router         = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory private constant UniSwapV2FactoryAddress  = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
   

    
    constructor(uint16 _goodwill, address payable _goodwillAddress) public {
        goodwill = _goodwill;
        goodwillAddress = _goodwillAddress;
    }

    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function RemoveLiquidity2PairToken(address _FromUniPoolAddress, uint256 _IncomingLP) public nonReentrant stopInEmergency returns (uint256 amountA, uint256 amountB){
        IUniswapV2Pair pair = IUniswapV2Pair(_FromUniPoolAddress);

        require(address(pair) != address(0), "Error: Invalid Unipool Address");

        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(_FromUniPoolAddress).safeTransferFrom( msg.sender, address(this), _IncomingLP);

        uint256 goodwillPortion = _transferGoodwill( _FromUniPoolAddress, _IncomingLP);
 
        IERC20(_FromUniPoolAddress).safeApprove(address(uniswapV2Router), SafeMath.sub(_IncomingLP, goodwillPortion));

        if (token0 == wethTokenAddress || token1 == wethTokenAddress) {
            address _token = token0 == wethTokenAddress ? token1 : token0;
            (amountA, amountB) = uniswapV2Router.removeLiquidityETH(_token, SafeMath.sub(_IncomingLP, goodwillPortion), 1, 1, msg.sender, deadline);
        } else {
            (amountA, amountB) = uniswapV2Router.removeLiquidity( token0, token1, SafeMath.sub(_IncomingLP, goodwillPortion), 1, 1, msg.sender, deadline);
        }
    }

    function RemoveLiquidity(
        address _ToTokenContractAddress,
        address _FromUniPoolAddress,
        uint256 _IncomingLP, 
        uint256 _minTokensRec
    ) public nonReentrant stopInEmergency returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_FromUniPoolAddress);

        require(address(pair) != address(0), "Error: Invalid Unipool Address");

        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(_FromUniPoolAddress).safeTransferFrom( msg.sender, address(this), _IncomingLP);
   
        uint256 goodwillPortion = _transferGoodwill(_FromUniPoolAddress, _IncomingLP);

        IERC20(_FromUniPoolAddress).safeApprove(address(uniswapV2Router), SafeMath.sub(_IncomingLP, goodwillPortion));

        (uint256 amountA, uint256 amountB) = uniswapV2Router.removeLiquidity( token0, token1, SafeMath.sub(_IncomingLP, goodwillPortion), 1, 1, address(this), deadline);

        uint256 tokenBought;
        if (canSwapFromV2(_ToTokenContractAddress, token0) && canSwapFromV2(_ToTokenContractAddress, token1)) {
            tokenBought = swapFromV2(token0, _ToTokenContractAddress, amountA);
            tokenBought += swapFromV2(token1, _ToTokenContractAddress, amountB);
        } else if (canSwapFromV2(_ToTokenContractAddress, token0)) {
            uint256 token0Bought = swapFromV2(token1, token0, amountB);
            tokenBought = swapFromV2(token0, _ToTokenContractAddress, token0Bought.add(amountA));
        } else if (canSwapFromV2(_ToTokenContractAddress, token1)) {
            uint256 token1Bought = swapFromV2(token0, token1, amountA);
            tokenBought = swapFromV2( token1, _ToTokenContractAddress, token1Bought.add(amountB));
        }

        require(tokenBought >= _minTokensRec, "High slippage");

        if (_ToTokenContractAddress == address(0)) {
            msg.sender.transfer(tokenBought);
        } else {
            IERC20(_ToTokenContractAddress).safeTransfer(msg.sender, tokenBought);
        }

        return tokenBought;
    }

    function RemoveLiquidity2PairTokenWithPermit(
        address _FromUniPoolAddress,
        uint256 _IncomingLP,
        uint256 _approvalAmount,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair(_FromUniPoolAddress).permit(msg.sender, address(this), _approvalAmount, _deadline, v, r, s);
        (amountA, amountB) = RemoveLiquidity2PairToken(_FromUniPoolAddress, _IncomingLP);
    }

    function RemoveLiquidityWithPermit(
        address _ToTokenContractAddress,
        address _FromUniPoolAddress,
        uint256 _IncomingLP,
        uint256 _minTokensRec,
        uint256 _approvalAmount,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external stopInEmergency returns (uint256) {
        IUniswapV2Pair(_FromUniPoolAddress).permit(msg.sender, address(this), _approvalAmount, _deadline, v, r, s);
        return (RemoveLiquidity(_ToTokenContractAddress, _FromUniPoolAddress, _IncomingLP, _minTokensRec));
    }

    function swapFromV2(address _fromToken, address _toToken, uint256 amount) internal returns (uint256) {
        require(_fromToken != address(0) || _toToken != address(0), "Invalid Exchange values");
        if (_fromToken == _toToken) return amount;
        require(canSwapFromV2(_fromToken, _toToken), "Cannot be exchanged");
        require(amount > 0, "Invalid amount");

        if (_fromToken == address(0)) {
            if (_toToken == wethTokenAddress) {
                IWETH(wethTokenAddress).deposit.value(amount)();
                return amount;
            }

            address[] memory path = new address[](2);
            path[0] = wethTokenAddress;
            path[1] = _toToken;
            uint256 minTokens = uniswapV2Router.getAmountsOut(amount, path)[1];

            minTokens = SafeMath.div(SafeMath.mul(minTokens, SafeMath.sub(10000, 200)), 10000);

            uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens.value(amount)(minTokens, path, address(this), deadline);
                
            return amounts[1];
        } else if (_toToken == address(0)) {
            if (_fromToken == wethTokenAddress) {
                IWETH(wethTokenAddress).withdraw(amount);
                return amount;
            }
            address[] memory path = new address[](2);
            IERC20(_fromToken).safeApprove(address(uniswapV2Router), amount);
            path[0] = _fromToken;
            path[1] = wethTokenAddress;
            uint256 minTokens = uniswapV2Router.getAmountsOut(amount, path)[1];

            minTokens = SafeMath.div(SafeMath.mul(minTokens, SafeMath.sub(10000, 200)), 10000);

            uint256[] memory amounts = uniswapV2Router.swapExactTokensForETH(amount, minTokens, path, address(this), deadline);

            return amounts[1];
        } else {
            IERC20(_fromToken).safeApprove(address(uniswapV2Router), amount);
            uint256 returnedAmount = _swapTokenToTokenV2(_fromToken, _toToken, amount);
            require(returnedAmount > 0, "Error in swap");
            return returnedAmount;
        }
    }

    function _swapTokenToTokenV2(address _fromToken, address _toToken, uint256 amount) internal returns (uint256) {
        IUniswapV2Pair pair1 = IUniswapV2Pair(UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress));
        IUniswapV2Pair pair2 = IUniswapV2Pair(UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress));
        IUniswapV2Pair pair3 = IUniswapV2Pair(UniSwapV2FactoryAddress.getPair(_fromToken, _toToken));

        uint256[] memory amounts;

        if (_haveReserve(pair3)) {
            address[] memory path = new address[](2);
            path[0] = _fromToken;
            path[1] = _toToken;
            uint256 minTokens = uniswapV2Router.getAmountsOut(amount, path)[1];
            minTokens = SafeMath.div(SafeMath.mul(minTokens, SafeMath.sub(10000, 200)), 10000);
            amounts = uniswapV2Router.swapExactTokensForTokens(amount, minTokens, path, address(this), deadline);

            return amounts[1];
        } else if (_haveReserve(pair1) && _haveReserve(pair2)) {
            address[] memory path = new address[](3);
            path[0] = _fromToken;
            path[1] = wethTokenAddress;
            path[2] = _toToken;
            uint256 minTokens = uniswapV2Router.getAmountsOut(amount, path)[2];
            minTokens = SafeMath.div(SafeMath.mul(minTokens, SafeMath.sub(10000, 200)), 10000);
            amounts = uniswapV2Router.swapExactTokensForTokens(amount, minTokens, path, address(this), deadline);

            return amounts[2];
        }
        return 0;
    }

    function canSwapFromV2(address _fromToken, address _toToken) internal view returns (bool){
        require(_fromToken != address(0) || _toToken != address(0), "Invalid Exchange values");
 
        if (_fromToken == _toToken) return true;

        if (_fromToken == address(0) || _fromToken == wethTokenAddress) {
            if (_toToken == wethTokenAddress || _toToken == address(0))
                return true;
            IUniswapV2Pair pair = IUniswapV2Pair(UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress));
                
            if (_haveReserve(pair)) return true;

        } else if (_toToken == address(0) || _toToken == wethTokenAddress) {
            if (_fromToken == wethTokenAddress || _fromToken == address(0))
                return true;
            IUniswapV2Pair pair = IUniswapV2Pair(UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress));
                
            if (_haveReserve(pair)) return true;
            
        } else {
            IUniswapV2Pair pair1 = IUniswapV2Pair(UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress));
            IUniswapV2Pair pair2 = IUniswapV2Pair(UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress));  
            IUniswapV2Pair pair3 = IUniswapV2Pair(UniSwapV2FactoryAddress.getPair(_fromToken, _toToken));
                
            if (_haveReserve(pair1) && _haveReserve(pair2)) return true;
            if (_haveReserve(pair3)) return true;
        }

        return false;
    }

    function _haveReserve(IUniswapV2Pair pair) internal view returns (bool) {
        if (address(pair) != address(0)) {
            uint256 totalSupply = pair.totalSupply();
            if (totalSupply > 0) return true;
        }
    }

     function _transferGoodwill(address _tokenContractAddress, uint256 tokens2Trade) internal returns (uint256 goodwillPortion) {
        if (goodwill == 0) {
            return 0;
        }

        goodwillPortion = SafeMath.div(SafeMath.mul(tokens2Trade, goodwill), 10000);

        IERC20(_tokenContractAddress).safeTransfer(goodwillAddress,goodwillPortion);
    }

    function setNewGoodwill(uint16 _new_goodwill) public onlyOwner {
        require(_new_goodwill >= 0 && _new_goodwill < 10000, "GoodWill Value not allowed");
        goodwill = _new_goodwill;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.safeTransfer(owner(), qty);
    }

    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        address payable _to = owner().toPayable();
        _to.transfer(contractBalance);
    }

    function setNewGoodwillAddress(address _newGoodwillAddress) public onlyOwner{
        goodwillAddress = _newGoodwillAddress;
    }

    function() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}