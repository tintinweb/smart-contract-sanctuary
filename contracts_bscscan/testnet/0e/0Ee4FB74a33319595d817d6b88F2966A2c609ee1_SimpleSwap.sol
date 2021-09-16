/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

pragma solidity >=0.6.2 <0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

pragma solidity >=0.6.6 <0.8.0;

contract SimpleSwap {
    address payable public immutable owner1 =
        0x3A39155F08989f4639f156992F02c744Dc6Cf5E1;
    address payable public immutable owner2 =
        0x3A39155F08989f4639f156992F02c744Dc6Cf5E1;

    modifier onlyOwner() {
        require(msg.sender == owner1 || msg.sender == owner2);
        _;
    }

    // withdraws all bnb and any tokens that are in contract including wbnb
    function withdraw(address _tokenContract) public onlyOwner returns (bool) {
        IERC20 tokenContract = IERC20(address(0x5FDcBDDF47C8459e3d6eC23aEE74A9E167216932)); // set _tokenContract here
        uint256 withdrawAmount = address(this).balance;
        owner1.transfer(withdrawAmount / 2);
        owner2.transfer(withdrawAmount / 2);
        uint256 withdrawAmountTokens = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner1, withdrawAmountTokens / 2);
        tokenContract.transfer(owner2, withdrawAmountTokens / 2);
        return true;
    }

    receive() external payable {}

    function check(
        address _tokenBorrow, // example: BUSD
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _tokenPay, // example: BNB
        address _sourceRouter,
        address _targetRouter
    ) public view returns (int256, uint256) {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = _tokenPay;
        path1[1] = path2[0] = _tokenBorrow;

        uint256 amountOut = IUniswapV2Router(_sourceRouter).getAmountsOut(
            _amountTokenPay,
            path1
        )[1];
        uint256 amountRepay = IUniswapV2Router(_targetRouter).getAmountsOut(
            amountOut,
            path2
        )[1];

        return (
            int256(amountRepay - _amountTokenPay), // our profit or loss; example output: BNB amount
            amountOut // the amount we get from our input "_amountTokenPay"; example: BUSD amount
        );
    }

    function simpleSwap(
        uint256 amountToken,
        address sourceRouter,
        address targetRouter,
        address token0, // always wbnb
        address token1
    ) external payable {
        // if _amount0 is zero sell token1 for token0
        // else sell token0 for token1 as a result
        address[] memory path1 = new address[](2);
        address[] memory path = new address[](2);
        path[0] = path1[1] = token1; // c&p
        path[1] = path1[0] = token0; // c&p

        // IERC20 token that we will sell for otherToken
        IERC20 token = IERC20(token1);
        IERC20 wbnb_token = IERC20(token0);

        token.approve(targetRouter, amountToken);
        token.approve(sourceRouter, amountToken);
        wbnb_token.approve(targetRouter, msg.value);
        wbnb_token.approve(sourceRouter, msg.value);
        // get the amount of token
        uint256 amountRequired = IUniswapV2Router(sourceRouter)
            .swapExactTokensForTokens(
                amountToken,
                0,
                path1,
                address(this),
                block.timestamp + 60
            )[1];

        uint256 amountReceived = IUniswapV2Router(targetRouter)
            .swapExactTokensForTokens(
                amountToken,
                0, // slippage can be done via - ((amountRequired * 19) / 981) + 1,
                path,
                address(this),
                block.timestamp + 60
            )[1];
        require(amountReceived > 0, "zero amount");
        // otherToken.transfer(owner, amountReceived); // our win
    }
}