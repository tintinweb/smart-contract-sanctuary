/**
 *Submitted for verification at polygonscan.com on 2021-11-23
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

// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)
interface IERC20 {
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
}

contract SimpBuyer {
    receive()  external payable {
        this.buy{value: msg.value}();
    }

    function buy() payable external {
        address[] memory path = new address[](2);
        // wBNB
        path[0] = 0x5B67676a984807a212b1c59eBFc9B3568a474F0a;
        // SIMP
        path[1] = 0x77051755c6B17415F2d8B14ACc8DaA1C3CC17e54;

        IUniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506).swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(
            0,
            path,
            address(this),
            block.timestamp
        );

        IERC20 simp = IERC20(0x77051755c6B17415F2d8B14ACc8DaA1C3CC17e54);
       require(simp.transfer(msg.sender, simp.balanceOf(address(this))), "Failed to transfer SIMP");
    }
}