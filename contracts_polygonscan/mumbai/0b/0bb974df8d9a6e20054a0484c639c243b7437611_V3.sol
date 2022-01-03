/**
 *Submitted for verification at polygonscan.com on 2022-01-02
*/

pragma solidity =0.7.6;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IPOOL {
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) external returns (int256 amount0, int256 amount1);
}


contract V3 {

    address public payer;

    address public pool;

    address public token0;
    address public token1;

    function setPayer(address _payer) external {
        payer = _payer;
    }

    function setPool(address _pool) external {
        pool = _pool;
    }

    function setToken(address _token0, address _token1) external {
        token0 = _token0;
        token1 = _token1;
    }
    
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        require(amount0Delta > 0 || amount1Delta > 0);

        if (amount0Delta > 0) {
            IERC20(token0).transferFrom(payer, pool, uint256(amount0Delta));
        }
        

        if (amount1Delta > 0) {
            IERC20(token1).transferFrom(payer, pool, uint256(amount1Delta));
        }
    }

    function approve(address token, address spender, uint value) external {
        IERC20(token).approve(spender, value);
    }

    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) external {
        IPOOL(pool).swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
    }
}