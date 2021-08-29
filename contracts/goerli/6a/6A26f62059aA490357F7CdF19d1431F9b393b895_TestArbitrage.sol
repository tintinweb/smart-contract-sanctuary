/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: IUniswapV2Pair

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

// Part: SafeMath

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// Part: TransferHelper

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: TestArbitrage.sol

contract TestArbitrage {

    using SafeMath for uint;

    modifier ensure(uint deadline) {
            require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
            _;
        }
    
    // 方便函数
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'TestArbitrage: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TestArbitrage: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // 方便函数
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TestArbitrage: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TestArbitrage: ZERO_ADDRESS');
    }

    // 方便函数
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function swap1(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address pair,
        address to,
        uint deadline
    ) external ensure(deadline) {
        // 这里主要模仿 uniswap 的写法
        // 判断谁是 token0 token1
        // 判断输入输出的数量，输出是不是在容许范围内: 从pair中获取reserve，然后计算amountOut，需要实现一个函数
        // 打钱到pair
        // 判断token0和token1,amount0Out和amount1Out，然后调用pair的swap函数进行兑换
        // Stack Too Deep:
        // you can have not more than 16 local variables (including parameters and return parameters). 
        (address token0, address token1) = sortTokens(path[0], path[1]);
        
        // IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(pair);
        
        // 防止出现 Stack Too Deep Error:
        uint reserveIn;
        uint reserveOut;
        {
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
            (reserveIn, reserveOut) = token0 == path[0] ? (reserve0, reserve1) : (reserve1, reserve0);
        }
                
        uint amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, 'TestArbitrage: amoutOut too small');

        TransferHelper.safeTransfer(path[0], pair, amountIn);
        (uint amount0Out, uint amount1Out) = token0 == path[0] ? (uint(0), amountOut) : (amountOut, uint(0));
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }


    // function swapExactTokensForTokens(
    //     uint amountIn,
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // ) external override ensure(deadline) returns (uint[] memory amounts) {
    //     amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
    //     require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
    //     TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
    //     _swap(amounts, path, to);
    // }


    // function swapTokensForTokens(
    //     uint amountIn,
    //     address[] calldata path,
    //     address[] calldata routerPath,
    //     address to,
    //     uint deadline
    // ) external ensure(deadline) returns (uint lastAmountIn) {
    //     lastAmountIn = amountIn;
    //     for (uint i; i < path.length - 1; i++) {
    //         (address input, address output, address routerAddr) = (path[i], path[i + 1], routerPath[i]);
    //         IUniswapV2Router01 router = IUniswapV2Router01(routerAddr);
    //         address[] memory thisPath = new address[](2);
    //         thisPath[0] = input;
    //         thisPath[1] = output;
    //         // amountOut = UniswapV2Library.getAmount(router.factory, lastAmountIn, [input, output]);
    //         uint[] memory amountOut = router.swapExactTokensForTokens(lastAmountIn, 0, thisPath, to, deadline);
    //         lastAmountIn = amountOut[0];
    //     }
    // }
}