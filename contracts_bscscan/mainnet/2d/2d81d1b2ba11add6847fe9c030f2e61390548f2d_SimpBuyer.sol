/**
 *Submitted for verification at BscScan.com on 2021-11-23
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
        this.buy{value: msg.value}();
    }

    function buy() payable external {
        address[] memory path = new address[](2);
        // wBNB
        path[0] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        // SIMP
        path[1] = 0xD0ACCF05878caFe24ff8b3F82F194C62Ed755707;

        // Swap BNB for SIMP: this transaction will be taxed
        IUniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E).swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(
            0,
            path,
            address(this),
            block.timestamp
        );

        ISimp simp = ISimp(0xD0ACCF05878caFe24ff8b3F82F194C62Ed755707);

        simp.setAccountWhitelisted(address(this), true);
        // Send back SIMP: this transaction will not be taxed
        require(simp.transfer(msg.sender, simp.balanceOf(address(this))), "Failed to transfer SIMP");
        simp.setAccountWhitelisted(address(this), false);
    }
}