/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: undefined
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

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

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
}

interface IBalancerPool {
    function isexternalSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token)
        external
        view
        returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getNormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getController() external view returns (address);

    function setSwapFee(uint256 swapFee) external;

    function setController(address manager) external;

    function setexternalSwap(bool external_) external;

    function finalize() external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut)
        external
        view
        returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external
        view
        returns (uint256 spotPrice);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst)
        external
        view
        returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) external pure returns (uint256 spotPrice);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract DexSwapExecutor {
    enum Exchange {UNISWAP, SUSHISWAP, BALANCER, ZEROX, BANCOR}
    struct Path {
        Exchange exchange;
        address pool;
        address to;
    }
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public sushiswapV2Router = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    IUniswapV2Router02 public uniswapV2RouterInstance = IUniswapV2Router02(uniswapV2Router);
    IUniswapV2Router02 public sushiswapV2RouterInstance = IUniswapV2Router02(sushiswapV2Router);

    mapping(address => bool) public operators;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier ownerOrOperator {
        require(
            msg.sender == owner || operators[msg.sender] == true,
            "only owner or operator"
        );
        _;
    }
    
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DexSwapExecutor: EXPIRED");
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function addOperators(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators[_operators[i]] = true;
        }
    }

    function deleteOperators(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators[_operators[i]] = false;
        }
    }

    function setUniswapV2Router(address router) external onlyOwner {
        uniswapV2Router = router;
        uniswapV2RouterInstance = IUniswapV2Router02(uniswapV2Router);
    }

    function setSushiswapV2Router(address router) external onlyOwner {
        sushiswapV2Router = router;
        sushiswapV2RouterInstance = IUniswapV2Router02(sushiswapV2Router);
    }

    function _singleSwap(
        Exchange exchange,
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 deadline
    ) internal returns (uint256 amountOut) {
        if (exchange == Exchange.UNISWAP) {
            return _uniswap(uniswapV2Router,tokenIn,tokenOut,amountIn,deadline);
        } 
        if (exchange == Exchange.SUSHISWAP) {
            return _uniswap(sushiswapV2Router,tokenIn,tokenOut,amountIn,deadline);
        }
        if (exchange == Exchange.BALANCER) {
            TransferHelper.safeApprove(tokenIn,pool,type(uint256).max);
            (amountOut, ) = IBalancerPool(pool).swapExactAmountIn(
                tokenIn,
                amountIn,
                tokenOut,
                0,
                type(uint256).max // TODO: max price
            );
            return amountOut;
        }
        require(false, "DexSwapExecutor: ERR_EXCHANGE_NOT_SUPPORTED");
    }
    
    function _uniswap(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 deadline
    ) internal returns (uint256 amountOut) {
        TransferHelper.safeApprove(tokenIn,router,type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amountsOut =
        IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            deadline
        );
        return amountsOut[amountsOut.length - 1];
    }

    function _getSingleAmountOut(
        Exchange exchange,
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        if (exchange == Exchange.UNISWAP || exchange == Exchange.SUSHISWAP) {
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            //return uniswapV2RouterInstance.getAmountsOut(amountIn,path)[1];
            bytes4 selector = bytes4(keccak256(bytes('getAmountsOut(uint256,address[])')));
            bytes memory data = abi.encodeWithSelector(selector, amountIn, path);
            (bool success, bytes memory ret) = address(pool).staticcall(data);
            if (success) {
                return abi.decode(ret, (uint256[]))[1];
            }
        } 
        // if (exchange == Exchange.SUSHISWAP) {
        //     address[] memory path = new address[](2);
        //     path[0] = tokenIn;
        //     path[1] = tokenOut;
        //     return sushiswapV2RouterInstance.getAmountsOut(amountIn,path)[1];
        // } 
        if (exchange == Exchange.BALANCER) {
            IBalancerPool balancerPoolInstance = IBalancerPool(pool); // init
            uint256 tokenWeightIn = balancerPoolInstance.getNormalizedWeight(tokenIn);
            uint256 tokenWeightOut = balancerPoolInstance.getNormalizedWeight(tokenOut);
            uint256 tokenBalanceIn = balancerPoolInstance.getBalance(tokenIn);
            uint256 tokenBalanceOut = balancerPoolInstance.getBalance(tokenOut);
            uint256 swapFee = balancerPoolInstance.getSwapFee();
            return
                balancerPoolInstance.calcOutGivenIn(
                    tokenBalanceIn,
                    tokenWeightIn,
                    tokenBalanceOut,
                    tokenWeightOut,
                    amountIn,
                    swapFee
                );
        } 
        require(false, "DexSwapExecutor: ERR_EXCHANGE_NOT_SUPPORTED");
    }

    function getSingleAmountsOut(
        address tokenIn,
        uint256 amountIn,
        Path[] memory paths
    ) public view returns (uint256[] memory amountsOut) {
        uint256 len = paths.length;
        uint256 iAmountIn = amountIn;
        address iTokenIn = tokenIn;
        amountsOut = new uint256[](len);
        for (uint8 i = 0; i < len; i++) {
            Path memory path = paths[i];
            uint256 iAmountOut =
                _getSingleAmountOut(
                    path.exchange,
                    path.pool,
                    iTokenIn,
                    path.to,
                    iAmountIn
                );
            amountsOut[i] = iAmountOut;
            iAmountIn = iAmountOut;
            iTokenIn = path.to;
        }
    }

    function swapExactAmountIn(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        Path[] calldata paths,
        uint256 deadline
    )
        external
        ensure(deadline)
        ownerOrOperator
        returns (uint256[] memory amountsOut)
    {
        require(
            IERC20(tokenIn).balanceOf(address(this)) >= amountIn,
            "DexSwapExecutor: ERR_NOT_ENOUGH_BALANCE"
        );
        uint256 len = paths.length;
        amountsOut = getSingleAmountsOut(tokenIn, amountIn, paths);
        require(
            amountsOut[len - 1] >= amountOutMin,
            "DexSwapExecutor: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        uint256 iAmountIn = amountIn;
        address iTokenIn = tokenIn;
        for (uint8 i = 0; i < len; i++) {
            Path memory path = paths[i];
            uint256 iAmountOut =
                _singleSwap(
                    path.exchange,
                    path.pool,
                    iTokenIn,
                    path.to,
                    iAmountIn,
                    deadline
                );
            amountsOut[i] = iAmountOut;
            iAmountIn = iAmountOut;
            iTokenIn = path.to;
        }
    }
    
    receive() external payable {
        // do nothing
    }
    
    function destroy(address[] calldata tokens) external onlyOwner {
        if (tokens.length > 0){
            for (uint i = 0; i < tokens.length; i++){
                IERC20 token = IERC20(tokens[i]);
                uint balance = token.balanceOf(address(this));
                if (balance > 0){
                    TransferHelper.safeTransfer(tokens[i],msg.sender,balance);
                }
            }
        }
        selfdestruct(msg.sender);
    }
}