/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Swap {
    IUniswapV2Router private router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address private owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function swap(uint amountIn, uint amountOutMin, address[] calldata path, uint deadline) external onlyOwner {
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, deadline);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 erc20) external onlyOwner {
        uint balance = erc20.balanceOf(address(this));
        erc20.transfer(msg.sender, balance);
    }

    receive() external payable {}

    fallback() external payable {}
}