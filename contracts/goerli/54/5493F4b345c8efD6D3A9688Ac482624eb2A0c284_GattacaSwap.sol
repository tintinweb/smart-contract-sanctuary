pragma solidity =0.5.16;

import './IERC20.sol';
import './IUniswapV2Router02.sol';

contract GattacaSwap {
    address public factory;

    constructor(
        address _uniswap_factory_address
    ) public {
        factory = _uniswap_factory_address;
    }

    function swapMyTokens(
        address _tokenIn,
        address _tokenOut,
        address _router,
        uint _amountIn,
        uint _amountOutMin
    ) external payable {
        IERC20(_tokenIn).approve(_router, _amountIn);
        IERC20(_tokenIn).allowance(address(this), _router);

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        IUniswapV2Router02(_router).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            msg.sender,
            block.timestamp + 1000000000
        );
    }

}