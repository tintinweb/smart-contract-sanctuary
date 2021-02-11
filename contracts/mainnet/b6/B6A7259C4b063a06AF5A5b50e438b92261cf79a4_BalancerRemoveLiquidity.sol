/**
 *Submitted for verification at Etherscan.io on 2021-02-11
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

contract BalancerRemoveLiquidity is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;

    bool private stopped = false;
    uint16 public goodwill = 0;

    address public goodwillAddress = 0xE737b6AfEC2320f616297e59445b60a11e3eF75F;
    address private constant wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
       
    IUniswapV2Factory private constant UniSwapV2FactoryAddress = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 private constant uniswapRouter          = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IBFactory private constant BalancerFactory                 = IBFactory(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd);
 
    event RemovedLiquidity(address _toWhomToIssue, address _fromBalancerPoolAddress, address _toTokenContractAddress, uint256 _OutgoingAmount);

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

    function RemoveLiquidity(address _ToTokenContractAddress, address _FromBalancerPoolAddress, uint256 _IncomingBPT, uint256 _minTokensRec) public payable nonReentrant stopInEmergency returns (uint256) {
        require(BalancerFactory.isBPool(_FromBalancerPoolAddress), "Invalid Balancer Pool");

        address _FromTokenAddress;
        if (IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).isBound( _ToTokenContractAddress)) {
            _FromTokenAddress = _ToTokenContractAddress;
        } else if (_ToTokenContractAddress == address(0) && IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).isBound(wethTokenAddress)) {
            _FromTokenAddress = wethTokenAddress;
        } else {
            _FromTokenAddress = _getBestDeal(_FromBalancerPoolAddress, _IncomingBPT); 
        }

        return (_performRemoveLiquidity(msg.sender, _ToTokenContractAddress, _FromBalancerPoolAddress, _IncomingBPT, _FromTokenAddress, _minTokensRec));
    }

    function _performRemoveLiquidity(
        address payable _toWhomToIssue,
        address _ToTokenContractAddress,
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        address _IntermediateToken,
        uint256 _minTokensRec
    ) internal returns (uint256) {
        uint256 goodwillPortion = _transferGoodwill(_FromBalancerPoolAddress, _IncomingBPT);

        require(IERC20(_FromBalancerPoolAddress).transferFrom( msg.sender, address(this), SafeMath.sub(_IncomingBPT, goodwillPortion)));

        if (IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).isBound(_ToTokenContractAddress)) {
            return (
                _directRemoveLiquidity(
                    _FromBalancerPoolAddress,
                    _ToTokenContractAddress,
                    _toWhomToIssue,
                    SafeMath.sub(_IncomingBPT, goodwillPortion),
                    _minTokensRec
                )
            );
        }

        //exit balancer
        uint256 _returnedTokens = _exitBalancer(
            _FromBalancerPoolAddress,
            _IntermediateToken,
            SafeMath.sub(_IncomingBPT, goodwillPortion)
        );

        if (_ToTokenContractAddress == address(0)) {
            uint256 ethBought = _token2Eth(
                _IntermediateToken,
                _returnedTokens,
                _toWhomToIssue
            );

            require(ethBought >= _minTokensRec, "High slippage");
            emit RemovedLiquidity(
                _toWhomToIssue,
                _FromBalancerPoolAddress,
                _ToTokenContractAddress,
                ethBought
            );
            return ethBought;
        } else {
            uint256 tokenBought = _token2Token(
                _IntermediateToken,
                _toWhomToIssue,
                _ToTokenContractAddress,
                _returnedTokens
            );
            require(tokenBought >= _minTokensRec, "High slippage");
            emit RemovedLiquidity(
                _toWhomToIssue,
                _FromBalancerPoolAddress,
                _ToTokenContractAddress,
                tokenBought
            );
            return tokenBought;
        }
    }

    function _directRemoveLiquidity(
        address _FromBalancerPoolAddress,
        address _ToTokenContractAddress,
        address _toWhomToIssue,
        uint256 tokens2Trade,
        uint256 _minTokensRec
    ) internal returns (uint256 returnedTokens) {
        returnedTokens = _exitBalancer(_FromBalancerPoolAddress, _ToTokenContractAddress, tokens2Trade);

        require(returnedTokens >= _minTokensRec, "High slippage");

        emit RemovedLiquidity(_toWhomToIssue, _FromBalancerPoolAddress, _ToTokenContractAddress, returnedTokens);
        IERC20(_ToTokenContractAddress).transfer(_toWhomToIssue, returnedTokens);   
    }

    function _transferGoodwill(address _tokenContractAddress, uint256 tokens2Trade)internal returns (uint256 goodwillPortion) {
        if (goodwill == 0) {
            return 0;
        }

        goodwillPortion = SafeMath.div(SafeMath.mul(tokens2Trade, goodwill),10000);
        require(IERC20(_tokenContractAddress).transferFrom(msg.sender, goodwillAddress, goodwillPortion), "Error in transferring BPT:1");
        return goodwillPortion;
    }

    function _getBestDeal(address _FromBalancerPoolAddress, uint256 _IncomingBPT) internal view returns (address _token) {
        address[] memory tokens = IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).getFinalTokens();

        uint256 maxEth;

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokensForBPT = _getBPT2Token(_FromBalancerPoolAddress,_IncomingBPT,tokens[index]);

            if (tokens[index] != wethTokenAddress) {
                if (UniSwapV2FactoryAddress.getPair(tokens[index], wethTokenAddress) == address(0)) {
                    continue;
                }

                address[] memory path = new address[](2);
                path[0] = tokens[index];
                path[1] = wethTokenAddress;
                uint256 ethReturned = uniswapRouter.getAmountsOut(tokensForBPT, path)[1];

                if (maxEth < ethReturned) {
                    maxEth = ethReturned;
                    _token = tokens[index];
                }
            } else {
                if (maxEth < tokensForBPT) {
                    maxEth = tokensForBPT;
                    _token = tokens[index];
                }
            }
        }
    }

    function _getBPT2Token(address _FromBalancerPoolAddress, uint256 _IncomingBPT, address _toToken) internal view returns (uint256 tokensReturned) {
        uint256 totalSupply = IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).totalSupply();
        uint256 swapFee = IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).getSwapFee();
        uint256 totalWeight = IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).getTotalDenormalizedWeight();
        uint256 balance = IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).getBalance(_toToken);
        uint256 denorm = IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).getDenormalizedWeight(_toToken);
        tokensReturned = IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).calcSingleOutGivenPoolIn(
            balance,
            denorm,
            totalSupply,
            totalWeight,
            _IncomingBPT,
            swapFee
        );
    }

    function _exitBalancer(address _FromBalancerPoolAddress, address _ToTokenContractAddress, uint256 _amount) internal returns (uint256 returnedTokens) {
        require(IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).isBound(_ToTokenContractAddress),"Token not bound");
        uint256 minTokens = _getBPT2Token(_FromBalancerPoolAddress, _amount, _ToTokenContractAddress);
        minTokens = SafeMath.div(SafeMath.mul(minTokens, 98), 100);
        returnedTokens = IBPool_Balancer_RemoveLiquidity_V1_1(_FromBalancerPoolAddress).exitswapPoolAmountIn(_ToTokenContractAddress, _amount, minTokens);
        require(returnedTokens > 0, "Error in exiting balancer pool");
    }

    function _token2Token(address _FromTokenContractAddress, address _ToWhomToIssue, address _ToTokenContractAddress, uint256 tokens2Trade) internal returns (uint256 tokenBought) {
        TransferHelper.safeApprove(_FromTokenContractAddress, address(uniswapRouter), tokens2Trade);

        if (_FromTokenContractAddress != wethTokenAddress) {
            address[] memory path = new address[](3);
            path[0] = _FromTokenContractAddress;
            path[1] = wethTokenAddress;
            path[2] = _ToTokenContractAddress;
            tokenBought = uniswapRouter.swapExactTokensForTokens(tokens2Trade, 1, path, _ToWhomToIssue, deadline)[path.length - 1];
        } else {
            address[] memory path = new address[](2);
            path[0] = wethTokenAddress;
            path[1] = _ToTokenContractAddress;
            tokenBought = uniswapRouter.swapExactTokensForTokens(tokens2Trade, 1, path, _ToWhomToIssue, deadline)[path.length - 1];
        }

        require(tokenBought > 0, "Error in swapping ERC: 1");
    }

    function _token2Eth(address _FromTokenContractAddress, uint256 tokens2Trade, address payable _toWhomToIssue) internal returns (uint256 ethBought) {
        if (_FromTokenContractAddress == wethTokenAddress) {
            IWETH(wethTokenAddress).withdraw(tokens2Trade);
            _toWhomToIssue.transfer(tokens2Trade);
            return tokens2Trade;
        }

        IERC20(_FromTokenContractAddress).approve(address(uniswapRouter), tokens2Trade);

        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = wethTokenAddress;
        ethBought = uniswapRouter.swapExactTokensForETH(tokens2Trade, 1, path, _toWhomToIssue, deadline)[path.length - 1];

        require(ethBought > 0, "Error in swapping Eth: 1");
    }

    function setNewGoodwill(uint16 _new_goodwill) public onlyOwner {
        require(_new_goodwill >= 0 && _new_goodwill < 10000,"GoodWill Value not allowed");
        goodwill = _new_goodwill;
    }

    function setNewGoodwillAddress(address payable _newGoodwillAddress) public onlyOwner{
        goodwillAddress = _newGoodwillAddress;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner(), qty);
    }

    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        address payable _to = owner().toPayable();
        _to.transfer(contractBalance);
    }

    function() external payable {}
}