/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

pragma solidity >=0.6.2;

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

library TransferHelper {
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

interface ILiqPool {
    function token0() external view returns (address);
    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Custom {
    using SafeMath for uint;

    constructor() public payable { }

    function destroy() public {
        selfdestruct(msg.sender);
    }

    function swap_test(
        uint amountIn,
        address tokenAddr,
        address lpAddr
    ) external virtual {
        ILiqPool lp = ILiqPool(lpAddr);

        address token0 = lp.token0();

        (uint reserve0, uint reserve1,) = lp.getReserves();

        bool isInTokenPos0 = tokenAddr == token0;
        uint reserveIn  = isInTokenPos0 ? reserve0 : reserve1;
        uint reserveOut = isInTokenPos0 ? reserve0 : reserve1;
        uint amountOut  = getAmountOut(amountIn, reserveIn, reserveOut);

        IERC20(tokenAddr).transferFrom(
            msg.sender,
            lpAddr,
            amountIn
        );
        lp.swap(
            isInTokenPos0 ? 0 : amountOut,
            isInTokenPos0 ? amountOut : 0,
            msg.sender,
            new bytes(0)
        );
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) private pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(10000);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);

        amountOut = numerator / denominator;
    }
}