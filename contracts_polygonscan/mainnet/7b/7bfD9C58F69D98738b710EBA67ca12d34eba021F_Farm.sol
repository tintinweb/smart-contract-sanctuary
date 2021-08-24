/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IUniswap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

contract Farm {
    IUniswap uniswap;
    address public owner = msg.sender;

    constructor(address _uniswap) public {
        uniswap = IUniswap(_uniswap);
    }

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    function swapTokenForToken(
        address token1,
        address token2,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external {
        // Add 2 token addresses to array
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;

        // Transfer token to this contract
        IERC20(token1).transferFrom(msg.sender, address(this), amountIn);

        // Allow uniswap spend token
        IERC20(token1).approve(address(uniswap), amountIn);

        // Swap token
        uniswap.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            deadline
        );
    }
}