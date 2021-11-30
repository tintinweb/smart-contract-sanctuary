/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

interface IUniswapRouter {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface ISimp {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function setAccountWhitelisted(address account, bool whitelisted) external;
}

contract SimpBuyer {
    receive() external payable {
        buy(msg.sender, msg.value);
    }

    function buy(address dest, uint256 amount) internal {
        address[] memory path = new address[](2);
        // wBNB
        path[0] = 0x5B67676a984807a212b1c59eBFc9B3568a474F0a;
        // SIMP
        path[1] = 0x77051755c6B17415F2d8B14ACc8DaA1C3CC17e54;

        // Swap BNB for SIMP: this transaction will be taxed
        IUniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506).swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0,
            path,
            address(this),
            block.timestamp
        );

        ISimp simp = ISimp(0x77051755c6B17415F2d8B14ACc8DaA1C3CC17e54);

        simp.setAccountWhitelisted(address(this), true);
        // Send back SIMP: this transaction will not be taxed
        require(simp.transfer(dest, simp.balanceOf(address(this))), "Failed to transfer SIMP");
        simp.setAccountWhitelisted(address(this), false);
    }
}