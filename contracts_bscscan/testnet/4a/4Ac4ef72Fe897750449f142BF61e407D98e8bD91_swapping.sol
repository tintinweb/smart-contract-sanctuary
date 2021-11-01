/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

pragma solidity =0.6.6;

interface IBEP20 {
    function balanceOf(address owner) external view returns (uint);
}
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

interface IPancakePair {
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

contract swapping {
    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(address pair,uint[] memory amounts, address[] memory path, address _to) internal virtual {
        (address input, address output) = (path[0], path[1]);
        (address token0,) = sortTokens(input, output);
        uint amountOut = amounts[1];
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        IPancakePair(pair).swap(
            amount0Out, amount1Out, _to, new bytes(0)
        );
    }
    function swapExactTokensForTokens(
        address pair,
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address from,
        address to
    ) public returns (uint256 amounts) {
        amounts = getAmountsOut(pair, amountIn, path);
        require(amounts >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeApprove(path[0], pair, amountIn);
        TransferHelper.safeTransferFrom(
            path[0], from, pair, amountIn
        );
        uint[] memory amountArray = new uint[](2);
        amountArray[0] = amountIn;
        amountArray[1] = amounts;
        _swap(pair, amountArray, path, to);
    }
    
    function getAmountsOut(address pair, uint amountIn, address[] memory path) internal view returns (uint256) {
        require(path.length == 2, 'INVALID_PATH');
        (uint reserveIn, uint reserveOut) = getReserves(pair, path[0], path[1]);
        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        return amountOut;
    }
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn*998;
        uint numerator = amountInWithFee* reserveOut;
        uint denominator = reserveIn*1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }
    
    function estimateOut(IPancakePair[] memory pairs, address startToken, uint256 amountIn) public view returns(uint256)
    {
        address tokenIn = startToken;
        uint256 inAmount = amountIn;
        address[] memory path = new address[](2);
        for(uint i = 0; i < pairs.length; i++)
        {
            path[0] = pairs[i].token0();
            path[1] = pairs[i].token1();
            if(path[1] == tokenIn)
            {
                path[1] = pairs[i].token0();
                path[0] = pairs[i].token1();
            }
            inAmount = getAmountsOut(address(pairs[i]), inAmount, path);
            tokenIn = path[1];
        }
        require(path[1] == startToken,"Invalid Pairs");
        return inAmount;
    }
    
    function doSwap(IPancakePair[] memory pairs, IBEP20 startToken, uint256 amountIn, uint256 minProfit) public
    {
        uint256 outAmount = estimateOut(pairs, address(startToken), amountIn);
        require(outAmount >= amountIn+minProfit,"No profit.");
        address tokenIn = address(startToken);
        uint256 inAmount = amountIn;
        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, address(this), amountIn
        );
        address[] memory path = new address[](2);
        for(uint i = 0; i < pairs.length; i++)
        {
            path[0] = pairs[i].token0();
            path[1] = pairs[i].token1();
            if(path[1] == tokenIn)
            {
                path[1] = pairs[i].token0();
                path[0] = pairs[i].token1();
            }
            swapExactTokensForTokens(address(pairs[i]), inAmount, 0, path, address(this), address(this));
            tokenIn = path[1];
            inAmount = IBEP20(tokenIn).balanceOf(address(this));
        }
        /*if(tokenIn == address(startToken))
        {
            TransferHelper.safeTransferFrom(
                tokenIn, address(this), msg.sender, inAmount
            );
        }*/
    }
}