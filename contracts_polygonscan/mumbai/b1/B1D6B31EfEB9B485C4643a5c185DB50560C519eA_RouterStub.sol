//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./IMockERC20.sol";

contract RouterStub {


    mapping(address => address) public liquidityTokens;

    function setPair(address _tokenA,address _tokenB,address _pair) public{
        liquidityTokens[_tokenA] = _pair;
        liquidityTokens[_tokenB] = _pair;
    }

    function WETH() external pure returns (address) {
        return address(0);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256,
        address[] calldata path,
        address,
        uint256
    ) external returns (uint256[] memory) {
        IMockERC20 tokenIn = IMockERC20(path[0]);
        IMockERC20 tokenOut = IMockERC20(path[path.length - 1]);

        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.mint(msg.sender, amountIn);

        uint256[] memory result = new uint256[](10);
        return result;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256,
        uint256,
        address to,
        uint256
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        if(amountADesired > amountBDesired){
            IMockERC20(tokenA).transferFrom(msg.sender, address(this), amountBDesired);
            IMockERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
            liquidity = amountBDesired;
            amountA = amountBDesired;
            amountB = amountBDesired;
        }else{
            IMockERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
            IMockERC20(tokenB).transferFrom(msg.sender, address(this), amountADesired);
            liquidity = amountADesired;
            amountA = amountADesired;
            amountB = amountADesired;
        }
        IPair(liquidityTokens[tokenA]).mint(to, liquidity);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256,
        uint256,
        address to,
        uint256
    ) external returns (uint256 amountA, uint256 amountB) {
        IPair(liquidityTokens[tokenA]).burn(msg.sender, liquidity);
        amountA = liquidity;
        amountB = liquidity;
        IMockERC20(tokenA).mint(to, amountA);
        IMockERC20(tokenB).mint(to, amountB);
    }
}

interface IPair {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMockERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}