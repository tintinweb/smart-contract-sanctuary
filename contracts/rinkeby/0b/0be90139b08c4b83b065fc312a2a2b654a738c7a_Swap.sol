/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Swap {
    IUniswapV2Router private router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address private owner;

    address private weth;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        weth = router.WETH();
    }

    function buy(address token, uint256 amountIn, uint256 amountOutMin, uint256 deadline) external onlyOwner {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        IERC20(weth).approve(address(router), amountIn);

        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    function sell(address token, uint256 amountOutMin, uint256 deadline) external onlyOwner {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;

        uint256 amountIn = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(address(router), amountIn);

        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 erc20) external onlyOwner {
        uint256 balance = erc20.balanceOf(address(this));
        erc20.transfer(msg.sender, balance);
    }

    receive() external payable {}

    fallback() external payable {}
}