/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.12;



// Part: IERC20

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: Swap.sol

contract Swap {
    // IUniswapV2Router02 public immutable uniSwapRouter =
    //     IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 public DAI;
    IERC20 public WETH;

    address public owner;

    constructor() public {
        owner = msg.sender;
        DAI = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
        WETH = IERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferAsset(uint256 amountIn) private {
        require(WETH.balanceOf(owner) >= amountIn);
        require(WETH.approve(owner, amountIn));

        WETH.transferFrom(owner, address(this), 20);
    }

    function swap() private {}

    function execute() public onlyOwner {
        uint256 amountIn = 1000000000000000;

        transferAsset(amountIn);
        swap();
    }
}