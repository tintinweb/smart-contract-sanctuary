/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface ISwapRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

contract FairLaunchHelper {
    address payable private owner;
    address private self;
    ISwapRouter private swapRouter;
    uint256 public constant MIN_BALANCE = 0.1 ether;
    uint256 public constant TEST_BUY_AMOUNT = 0.0001 ether;

    // Mainnet
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // Testnet
    // address private constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    // address private constant router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    uint256 private constant MAX_UINT = ~uint256(0);

    constructor() {
        owner = payable(msg.sender);
        self = address(this);
        swapRouter = ISwapRouter(router);
    }

    function getBalance() public view returns (uint256) {
        return self.balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    function buy(address tokenAddress, uint256 buyAmount, bool dryRun)
        external onlyOwner
        returns (uint256 amountBought)
    {
        require(buyAmount > 0, "Value must be greater than 0");
        require(self.balance > (MIN_BALANCE + buyAmount), "Not enough balance");

        // Test Trade
        address[] memory buyPath = new address[](2);
        buyPath[0] = WETH;
        buyPath[1] = tokenAddress;

        IERC20 token = IERC20(tokenAddress);

        if (dryRun){
            // Buy small amount of tokens
            swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: TEST_BUY_AMOUNT}(0, buyPath, self, block.timestamp);

            // Approve unlimited amount
            token.approve(router, MAX_UINT);

            // Get the current balance and try to sell
            address[] memory sellPath = new address[](2);
            sellPath[0] = tokenAddress;
            sellPath[1] = WETH;
            uint256 balance = token.balanceOf(self);

            swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(balance, 0, sellPath, self, block.timestamp);
        }

        // If we are good until here do the actual buy
        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: buyAmount }(0, buyPath, self, block.timestamp);
        amountBought = token.balanceOf(self);

        if (!dryRun) {
            // Approve unlimited amount
            token.approve(router, MAX_UINT);
        }

        return (amountBought);
    }

    function sell(address tokenAddress, uint256 amountOut) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        // Check we actually have the amount
        if (amountOut > 0) {
            require(token.balanceOf(self) > amountOut, "Not enough tokens");
        } else {
            amountOut = token.balanceOf(self);
        }

        // Sell required amount
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WETH;
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountOut, 0, path, self, block.timestamp);
    }

    function transferToOwner(uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = self.balance;
        }
        owner.transfer(amount);
    }

    receive() external payable {}
}